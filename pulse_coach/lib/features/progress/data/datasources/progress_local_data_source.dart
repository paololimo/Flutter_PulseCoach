import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

@lazySingleton
class ProgressLocalDataSource {
  const ProgressLocalDataSource(
    this._sessionLogsDao,
    this._dailyPlansDao,
    this._rpeFeedbackDao,
  );

  final SessionLogsDao _sessionLogsDao;
  final DailyPlansDao _dailyPlansDao;
  final RpeFeedbackDao _rpeFeedbackDao;

  Future<List<SessionHistoryEntry>> getSessionHistory() async {
    final logs = await _sessionLogsDao.getAllLogsOrderedByDate();
    final entries = <SessionHistoryEntry>[];

    for (final log in logs) {
      final planRow = await _dailyPlansDao.getPlanById(log.dailyPlanId);
      if (planRow == null) {
        AppLogger.warning(
          'SessionLog ${log.id} references missing plan ${log.dailyPlanId} - skipping',
          name: 'ProgressLocalDataSource',
        );
        continue;
      }

      late final DailyPlan plan;
      try {
        plan = DailyPlan.fromJson(
          jsonDecode(planRow.planJson) as Map<String, dynamic>,
        );
      } catch (e, st) {
        AppLogger.error(
          'Failed to parse planJson for plan ${planRow.id}',
          name: 'ProgressLocalDataSource',
          error: e,
          stackTrace: st,
        );
        continue;
      }

      if (log.sessionIndex < 0 || log.sessionIndex >= plan.sessions.length) {
        AppLogger.warning(
          'SessionLog ${log.id}: sessionIndex ${log.sessionIndex} out of range '
          'for plan ${planRow.id} (sessions.length = ${plan.sessions.length}) - skipping',
          name: 'ProgressLocalDataSource',
        );
        continue;
      }

      final session = plan.sessions[log.sessionIndex];
      final feedback = await _rpeFeedbackDao.getBySessionLogId(log.id);

      entries.add(
        SessionHistoryEntry(
          sessionLogId: log.id,
          completedAt: log.completedAt,
          sessionType: session.sessionType,
          durationMinutes: session.durationMinutes,
          abandoned: log.abandoned,
          rpeValue: feedback?.rpeValue,
          elapsedSeconds: log.elapsedSeconds,
        ),
      );
    }

    return entries;
  }

  Future<ProgressStats> getProgressStats() async {
    final entries = await getSessionHistory();

    if (entries.isEmpty) {
      return const ProgressStats(
        completedCount: 0,
        abandonedCount: 0,
        minutesPerWeek: [],
        rpeTrend: [],
        sessionTypeCounts: {},
      );
    }

    final completed = entries.where((entry) => !entry.abandoned).toList();
    final abandoned = entries.where((entry) => entry.abandoned).toList();

    final rpePoints = completed
        .where((entry) => entry.rpeValue != null)
        .take(20)
        .map(
          (entry) => RpeDataPoint(
            completedAt: entry.completedAt,
            rpeValue: entry.rpeValue!,
          ),
        )
        .toList()
        .reversed
        .toList();

    final typeCounts = <String, int>{};
    for (final entry in entries) {
      typeCounts[entry.sessionType] = (typeCounts[entry.sessionType] ?? 0) + 1;
    }

    final weekMinutes = <String, int>{};
    final weekLabels = <String, String>{};

    for (final entry in entries) {
      final weekStart = _mondayOf(entry.completedAt);
      final weekKey =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-'
          '${weekStart.day.toString().padLeft(2, '0')}';
      final minutes = entry.abandoned
          ? (entry.elapsedSeconds ?? 0) ~/ 60
          : entry.durationMinutes;

      weekMinutes[weekKey] = (weekMinutes[weekKey] ?? 0) + minutes;
      weekLabels[weekKey] =
          '${weekStart.day.toString().padLeft(2, '0')}/'
          '${weekStart.month.toString().padLeft(2, '0')}';
    }

    final sortedKeys = weekMinutes.keys.toList()..sort();
    final last8 = sortedKeys.length > 8
        ? sortedKeys.sublist(sortedKeys.length - 8)
        : sortedKeys;

    final minutesPerWeek = last8
        .map(
          (key) => WeeklyMinutes(
            weekLabel: weekLabels[key]!,
            totalMinutes: weekMinutes[key]!,
          ),
        )
        .toList();

    return ProgressStats(
      completedCount: completed.length,
      abandonedCount: abandoned.length,
      minutesPerWeek: minutesPerWeek,
      rpeTrend: rpePoints,
      sessionTypeCounts: typeCounts,
    );
  }

  DateTime _mondayOf(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }
}
