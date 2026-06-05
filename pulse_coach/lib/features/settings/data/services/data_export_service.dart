import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pulse_coach/features/progress/data/datasources/progress_local_data_source.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/settings/data/models/ai_decision_record.dart';
import 'package:pulse_coach/features/settings/data/repositories/ai_decision_log_repository.dart';
import 'package:share_plus/share_plus.dart';

@injectable
class DataExportService {
  DataExportService(this._progressDataSource, this._decisionLogRepository);

  final ProgressLocalDataSource _progressDataSource;
  final AiDecisionLogRepository _decisionLogRepository;

  Future<void> exportJson() async {
    final sessions = await _progressDataSource.getSessionHistory();
    final decisions = await _decisionLogRepository.getDecisions();
    final payload = <String, Object?>{
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'sessions': sessions.map(_sessionToJson).toList(),
      'weeklySummaries': _weeklySummaries(sessions),
      'aiDecisions': decisions.map(_decisionToJson).toList(),
    };

    final file = await _writeTempFile(
      filename: 'pulsecoach_export_${_timestamp()}.json',
      contents: jsonEncode(payload),
    );
    try {
      await Share.shareXFiles([
        XFile(file.path, name: 'pulsecoach_export.json'),
      ]);
    } finally {
      await _deleteTempFile(file);
    }
  }

  Future<void> exportCsv() async {
    final sessions = await _progressDataSource.getSessionHistory();
    final rows = [
      'date,type,duration_minutes,rpe,abandoned',
      ...sessions.map(_sessionToCsvRow),
    ];

    final file = await _writeTempFile(
      filename: 'pulsecoach_export_${_timestamp()}.csv',
      contents: rows.join('\n'),
    );
    try {
      await Share.shareXFiles([
        XFile(file.path, name: 'pulsecoach_export.csv', mimeType: 'text/csv'),
      ]);
    } finally {
      await _deleteTempFile(file);
    }
  }

  Future<File> _writeTempFile({
    required String filename,
    required String contents,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    return file.writeAsString(contents);
  }

  Future<void> _deleteTempFile(File file) async {
    try {
      await file.delete();
    } catch (_) {
      // Best-effort cleanup; the file lives in the OS cache directory and
      // will be reclaimed by the platform even if deletion fails here.
    }
  }

  Map<String, Object?> _sessionToJson(SessionHistoryEntry entry) => {
    'date': entry.completedAt.toIso8601String(),
    'type': entry.sessionType,
    'durationMinutes': entry.durationMinutes,
    'rpe': entry.rpeValue,
    'abandoned': entry.abandoned,
  };

  Map<String, Object?> _decisionToJson(AiDecisionRecord record) => {
    'decidedAt': record.decidedAt.toIso8601String(),
    'armKey': record.armKey,
    'rpeValue': record.rpeValue,
  };

  List<Map<String, Object?>> _weeklySummaries(
    List<SessionHistoryEntry> sessions,
  ) {
    final grouped = <DateTime, List<SessionHistoryEntry>>{};
    for (final session in sessions) {
      final weekStart = _mondayOf(session.completedAt);
      grouped.putIfAbsent(weekStart, () => []).add(session);
    }

    final weekStarts = grouped.keys.toList()..sort();
    return weekStarts.map((weekStart) {
      final entries = grouped[weekStart]!;
      final completedSessions = entries.where((entry) => !entry.abandoned);
      final abandonedSessions = entries.where((entry) => entry.abandoned);
      final totalMinutes = entries.fold<int>(
        0,
        (total, entry) =>
            total +
            (entry.abandoned
                ? (entry.elapsedSeconds ?? 0) ~/ 60
                : entry.durationMinutes),
      );

      return {
        'weekOf': DateFormat('yyyy-MM-dd').format(weekStart),
        'completedSessions': completedSessions.length,
        'abandonedSessions': abandonedSessions.length,
        'totalMinutes': totalMinutes,
      };
    }).toList();
  }

  String _sessionToCsvRow(SessionHistoryEntry entry) {
    final rpe = entry.rpeValue?.toString() ?? '';
    return [
      entry.completedAt.toIso8601String(),
      entry.sessionType,
      entry.durationMinutes.toString(),
      rpe,
      entry.abandoned.toString(),
    ].join(',');
  }

  String _timestamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  DateTime _mondayOf(DateTime date) {
    final utc = date.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day - (utc.weekday - 1));
  }
}
