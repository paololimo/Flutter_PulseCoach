import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/progress/data/datasources/progress_local_data_source.dart';

void main() {
  group('ProgressLocalDataSource', () {
    late AppDatabase db;
    late SessionLogsDao sessionLogsDao;
    late DailyPlansDao dailyPlansDao;
    late RpeFeedbackDao rpeFeedbackDao;
    late ProgressLocalDataSource dataSource;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sessionLogsDao = SessionLogsDao(db);
      dailyPlansDao = DailyPlansDao(db);
      rpeFeedbackDao = RpeFeedbackDao(db);
      dataSource = ProgressLocalDataSource(
        sessionLogsDao,
        dailyPlansDao,
        rpeFeedbackDao,
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedPlan({
      required String date,
      required List<PlannedSession> sessions,
    }) {
      final generatedAt = DateTime.utc(2026, 5, 24, 7);
      final plan = domain.DailyPlan(
        planDate: date,
        sessions: sessions,
        generatedAt: generatedAt,
      );
      return dailyPlansDao.insertPlan(
        DailyPlansCompanion.insert(
          planDate: plan.planDate,
          planJson: jsonEncode(plan.toJson()),
          generatedAt: generatedAt,
          createdAt: generatedAt,
        ),
      );
    }

    Future<int> seedLog({
      required int planId,
      required DateTime completedAt,
      int sessionIndex = 0,
      bool abandoned = false,
      int? elapsedSeconds,
    }) {
      return sessionLogsDao.insertLog(
        SessionLogsCompanion(
          dailyPlanId: Value(planId),
          sessionIndex: Value(sessionIndex),
          completedAt: Value(completedAt),
          createdAt: Value(completedAt),
          abandoned: Value(abandoned),
          elapsedSeconds: Value(elapsedSeconds),
        ),
      );
    }

    test(
      '10.1-DATA-001: returns empty list when no session logs exist',
      () async {
        final result = await dataSource.getSessionHistory();

        expect(result, isEmpty);
      },
    );

    test(
      '10.1-DATA-002: returns one entry for a completed session with RPE',
      () async {
        final planId = await seedPlan(
          date: '2026-05-24',
          sessions: const [
            PlannedSession(
              sessionType: 'cardio',
              intensity: 5,
              durationMinutes: 20,
              isIndoor: true,
            ),
          ],
        );
        final completedAt = DateTime.utc(2026, 5, 24, 8, 30);
        final logId = await seedLog(planId: planId, completedAt: completedAt);
        await rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: 1,
            sessionLogId: Value(logId),
            rpeValue: 7,
            recordedAt: completedAt,
          ),
        );

        final result = await dataSource.getSessionHistory();

        expect(result, hasLength(1));
        expect(result.single.sessionLogId, logId);
        expect(
          result.single.completedAt.millisecondsSinceEpoch,
          completedAt.millisecondsSinceEpoch,
        );
        expect(result.single.sessionType, 'cardio');
        expect(result.single.durationMinutes, 20);
        expect(result.single.abandoned, isFalse);
        expect(result.single.rpeValue, 7);
        expect(result.single.elapsedSeconds, isNull);
      },
    );

    test(
      '10.1-DATA-003: returns entry with abandoned=true and elapsedSeconds for abandoned session',
      () async {
        final planId = await seedPlan(
          date: '2026-05-25',
          sessions: const [
            PlannedSession(
              sessionType: 'mobility',
              intensity: 3,
              durationMinutes: 12,
              isIndoor: true,
            ),
          ],
        );
        final abandonedAt = DateTime.utc(2026, 5, 25, 9);
        await seedLog(
          planId: planId,
          completedAt: abandonedAt,
          abandoned: true,
          elapsedSeconds: 185,
        );

        final result = await dataSource.getSessionHistory();

        expect(result, hasLength(1));
        expect(result.single.abandoned, isTrue);
        expect(result.single.rpeValue, isNull);
        expect(result.single.elapsedSeconds, 185);
      },
    );

    test(
      '10.1-DATA-004: skips session log whose planId references a missing plan',
      () async {
        await db.customStatement('PRAGMA foreign_keys = OFF');
        await seedLog(planId: 9999, completedAt: DateTime.utc(2026, 5, 26, 10));
        await db.customStatement('PRAGMA foreign_keys = ON');

        final result = await dataSource.getSessionHistory();

        expect(result, isEmpty);
      },
    );

    test('10.1-DATA-005: orders entries most-recent-first', () async {
      final planA = await seedPlan(
        date: '2026-05-27',
        sessions: const [
          PlannedSession(
            sessionType: 'breathing',
            intensity: 2,
            durationMinutes: 5,
            isIndoor: true,
          ),
        ],
      );
      final planB = await seedPlan(
        date: '2026-05-28',
        sessions: const [
          PlannedSession(
            sessionType: 'cardio',
            intensity: 6,
            durationMinutes: 18,
            isIndoor: false,
          ),
        ],
      );
      final older = DateTime.utc(2026, 5, 27, 8);
      final newer = DateTime.utc(2026, 5, 28, 8);
      await seedLog(planId: planA, completedAt: older);
      await seedLog(planId: planB, completedAt: newer);

      final result = await dataSource.getSessionHistory();

      expect(result, hasLength(2));
      expect(result[0].completedAt.isAfter(result[1].completedAt), isTrue);
      expect(result.map((entry) => entry.sessionType), ['cardio', 'breathing']);
    });

    test(
      '10.1-DATA-006: skips log whose sessionIndex is out of range for its plan',
      () async {
        final planId = await seedPlan(
          date: '2026-05-29',
          sessions: const [
            PlannedSession(
              sessionType: 'cardio',
              intensity: 5,
              durationMinutes: 20,
              isIndoor: true,
            ),
          ],
        );
        // Plan has a single session (index 0); index 5 is out of range.
        await seedLog(
          planId: planId,
          completedAt: DateTime.utc(2026, 5, 29, 8),
          sessionIndex: 5,
        );

        final result = await dataSource.getSessionHistory();

        expect(result, isEmpty);
      },
    );

    test(
      '10.1-DATA-007: skips log whose plan has unparseable planJson',
      () async {
        final generatedAt = DateTime.utc(2026, 5, 30, 7);
        final planId = await dailyPlansDao.insertPlan(
          DailyPlansCompanion.insert(
            planDate: '2026-05-30',
            planJson: 'not-valid-json{',
            generatedAt: generatedAt,
            createdAt: generatedAt,
          ),
        );
        await seedLog(planId: planId, completedAt: DateTime.utc(2026, 5, 30, 8));

        final result = await dataSource.getSessionHistory();

        expect(result, isEmpty);
      },
    );
  });
}
