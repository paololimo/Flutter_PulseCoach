import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/settings/data/repositories/ai_decision_log_repository.dart';

void main() {
  late AppDatabase db;
  late AiDecisionLogRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AiDecisionLogRepository(
      db.rpeFeedbackDao,
      db.sessionLogsDao,
      db.dailyPlansDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AiDecisionLogRepository', () {
    test(
      '14.4-REPO-001: getDecisions sorts newest feedback first and resolves arm keys',
      () async {
        final generatedAt = DateTime.utc(2026, 6, 5, 7);
        final planId = await _insertPlan(
          db,
          domain.DailyPlan(
            planDate: '2026-06-05',
            generatedAt: generatedAt,
            sessions: const [
              PlannedSession(
                sessionType: 'mobility',
                intensity: 2,
                durationMinutes: 5,
                isIndoor: true,
              ),
              PlannedSession(
                sessionType: 'cardio',
                intensity: 6,
                durationMinutes: 8,
                isIndoor: false,
              ),
              PlannedSession(
                sessionType: 'strength',
                intensity: 9,
                durationMinutes: 10,
                isIndoor: true,
              ),
            ],
          ),
        );
        final olderLogId = await _insertSessionLog(
          db,
          planId: planId,
          sessionIndex: 0,
          completedAt: DateTime.utc(2026, 6, 5, 8),
        );
        final newerLogId = await _insertSessionLog(
          db,
          planId: planId,
          sessionIndex: 2,
          completedAt: DateTime.utc(2026, 6, 5, 9),
        );

        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: olderLogId,
            sessionLogId: Value(olderLogId),
            rpeValue: 4,
            recordedAt: DateTime.utc(2026, 6, 5, 8, 5),
          ),
        );
        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: newerLogId,
            sessionLogId: Value(newerLogId),
            rpeValue: 8,
            recordedAt: DateTime.utc(2026, 6, 5, 9, 5),
          ),
        );

        final decisions = await repository.getDecisions();

        expect(decisions, hasLength(2));
        expect(decisions.map((decision) => decision.armKey), [
          'strength_high',
          'mobility_low',
        ]);
        expect(decisions.map((decision) => decision.rpeValue), [8, 4]);
        expect(decisions.map((decision) => decision.stateVector), [null, null]);
      },
    );

    test(
      '14.4-REPO-002: getDecisions falls back to unknown for missing or invalid plan context',
      () async {
        final generatedAt = DateTime.utc(2026, 6, 5, 7);
        final corruptPlanId = await db.dailyPlansDao.insertPlan(
          DailyPlansCompanion.insert(
            planDate: '2026-06-06',
            planJson: '{not-json',
            generatedAt: generatedAt,
            createdAt: generatedAt,
          ),
        );
        final corruptLogId = await _insertSessionLog(
          db,
          planId: corruptPlanId,
          sessionIndex: 0,
          completedAt: DateTime.utc(2026, 6, 6, 9),
        );

        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: 1,
            rpeValue: 5,
            recordedAt: DateTime.utc(2026, 6, 6, 10),
          ),
        );
        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: corruptLogId,
            sessionLogId: Value(corruptLogId),
            rpeValue: 7,
            recordedAt: DateTime.utc(2026, 6, 6, 11),
          ),
        );

        final decisions = await repository.getDecisions();

        expect(decisions, hasLength(2));
        expect(decisions.map((decision) => decision.armKey), [
          'unknown',
          'unknown',
        ]);
        expect(decisions.map((decision) => decision.rpeValue), [7, 5]);
      },
    );
  });
}

Future<int> _insertPlan(AppDatabase db, domain.DailyPlan plan) {
  return db.dailyPlansDao.insertPlan(
    DailyPlansCompanion.insert(
      planDate: plan.planDate,
      planJson: jsonEncode(plan.toJson()),
      generatedAt: plan.generatedAt,
      createdAt: plan.generatedAt,
    ),
  );
}

Future<int> _insertSessionLog(
  AppDatabase db, {
  required int planId,
  required int sessionIndex,
  required DateTime completedAt,
}) {
  return db.sessionLogsDao.insertLog(
    SessionLogsCompanion.insert(
      dailyPlanId: Value(planId),
      sessionIndex: sessionIndex,
      completedAt: completedAt,
      createdAt: completedAt,
    ),
  );
}
