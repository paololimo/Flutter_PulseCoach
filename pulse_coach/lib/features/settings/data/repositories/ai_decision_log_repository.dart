import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/settings/data/models/ai_decision_record.dart';

@injectable
class AiDecisionLogRepository {
  AiDecisionLogRepository(
    this._rpeFeedbackDao,
    this._sessionLogsDao,
    this._dailyPlansDao,
  );

  final RpeFeedbackDao _rpeFeedbackDao;
  final SessionLogsDao _sessionLogsDao;
  final DailyPlansDao _dailyPlansDao;

  Future<List<AiDecisionRecord>> getDecisions() async {
    final feedbackRows = await _rpeFeedbackDao.getAllFeedback();
    feedbackRows.sort((a, b) {
      final byDate = b.recordedAt.compareTo(a.recordedAt);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });

    final records = <AiDecisionRecord>[];
    for (final feedback in feedbackRows) {
      records.add(
        AiDecisionRecord(
          decidedAt: feedback.recordedAt,
          armKey: await _armKeyFor(feedback.sessionLogId),
          rpeValue: feedback.rpeValue,
          stateVector: null,
        ),
      );
    }
    return records;
  }

  Future<String> _armKeyFor(int? sessionLogId) async {
    if (sessionLogId == null) return 'unknown';

    final sessionLog = await _sessionLogsDao.getLogById(sessionLogId);
    if (sessionLog == null) return 'unknown';

    final dailyPlanId = sessionLog.dailyPlanId;
    if (dailyPlanId == null) {
      // Shared session (Story 21.0): no DailyPlan to join against — the
      // armKey is denormalized directly on the row.
      return sessionLog.armKey ?? 'unknown';
    }

    final planRow = await _dailyPlansDao.getPlanById(dailyPlanId);
    if (planRow == null) return 'unknown';

    try {
      final planJson = jsonDecode(planRow.planJson) as Map<String, dynamic>;
      final plan = domain.DailyPlan.fromJson(planJson);
      final sessionIndex = sessionLog.sessionIndex;
      if (sessionIndex < 0 || sessionIndex >= plan.sessions.length) {
        return 'unknown';
      }

      final session = plan.sessions[sessionIndex];
      return '${session.sessionType}_${_intensityName(session.intensity)}';
    } catch (_) {
      return 'unknown';
    }
  }

  String _intensityName(int intensity) {
    if (intensity <= 3) return 'low';
    if (intensity <= 7) return 'medium';
    return 'high';
  }
}
