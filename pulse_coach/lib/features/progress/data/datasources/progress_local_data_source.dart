import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
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
}
