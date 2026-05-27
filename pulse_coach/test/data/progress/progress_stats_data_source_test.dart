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
  group('ProgressLocalDataSource.getProgressStats', () {
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

    Future<int> seedSession({
      required String sessionType,
      required DateTime completedAt,
      int durationMinutes = 20,
      bool abandoned = false,
      int? elapsedSeconds,
      int? rpeValue,
    }) async {
      final planId = await seedPlan(
        date:
            '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-'
            '${completedAt.day.toString().padLeft(2, '0')}',
        sessions: [
          PlannedSession(
            sessionType: sessionType,
            intensity: 5,
            durationMinutes: durationMinutes,
            isIndoor: true,
          ),
        ],
      );
      final logId = await sessionLogsDao.insertLog(
        SessionLogsCompanion(
          dailyPlanId: Value(planId),
          sessionIndex: const Value(0),
          completedAt: Value(completedAt),
          createdAt: Value(completedAt),
          abandoned: Value(abandoned),
          elapsedSeconds: Value(elapsedSeconds),
        ),
      );

      if (rpeValue != null) {
        await rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: logId,
            sessionLogId: Value(logId),
            rpeValue: rpeValue,
            recordedAt: completedAt,
          ),
        );
      }

      return logId;
    }

    DateTime mondayOf(DateTime date) {
      final utc = date.toUtc();
      return DateTime.utc(utc.year, utc.month, utc.day - (utc.weekday - 1));
    }

    test(
      '10.2-DATA-001: returns empty ProgressStats when no session logs exist',
      () async {
        final result = await dataSource.getProgressStats();

        expect(result.completedCount, 0);
        expect(result.abandonedCount, 0);
        expect(result.minutesPerWeek, isEmpty);
        expect(result.rpeTrend, isEmpty);
        expect(result.sessionTypeCounts, isEmpty);
        expect(result.completedThisWeek, 0);
        expect(result.weeklyTarget, 3);
      },
    );

    test(
      '10.2-DATA-002: completedCount / abandonedCount are correct',
      () async {
        await seedSession(
          sessionType: 'cardio',
          completedAt: DateTime.utc(2026, 5, 20, 8),
        );
        await seedSession(
          sessionType: 'mobility',
          completedAt: DateTime.utc(2026, 5, 21, 8),
        );
        await seedSession(
          sessionType: 'breathing',
          completedAt: DateTime.utc(2026, 5, 22, 8),
          abandoned: true,
          elapsedSeconds: 180,
        );

        final result = await dataSource.getProgressStats();

        expect(result.completedCount, 2);
        expect(result.abandonedCount, 1);
      },
    );

    test(
      '10.2-DATA-003: rpeTrend excludes abandoned sessions and sessions with no RPE',
      () async {
        await seedSession(
          sessionType: 'cardio',
          completedAt: DateTime.utc(2026, 5, 20, 8),
          rpeValue: 6,
        );
        await seedSession(
          sessionType: 'mobility',
          completedAt: DateTime.utc(2026, 5, 21, 8),
        );
        await seedSession(
          sessionType: 'breathing',
          completedAt: DateTime.utc(2026, 5, 22, 8),
          abandoned: true,
          elapsedSeconds: 120,
        );

        final result = await dataSource.getProgressStats();

        expect(result.rpeTrend, hasLength(1));
        expect(result.rpeTrend.single.rpeValue, 6);
      },
    );

    test('10.2-DATA-004: minutesPerWeek groups by ISO week', () async {
      await seedSession(
        sessionType: 'cardio',
        completedAt: DateTime.utc(2026, 5, 19, 8),
        durationMinutes: 20,
      );
      await seedSession(
        sessionType: 'mobility',
        completedAt: DateTime.utc(2026, 5, 21, 8),
        durationMinutes: 15,
      );

      final result = await dataSource.getProgressStats();

      expect(result.minutesPerWeek, hasLength(1));
      expect(result.minutesPerWeek.single.totalMinutes, 35);
    });

    test('10.2-DATA-005: minutesPerWeek keeps at most 8 weeks', () async {
      for (var i = 0; i < 10; i++) {
        await seedSession(
          sessionType: 'cardio',
          completedAt: DateTime.utc(2026, 1, 5).add(Duration(days: i * 7)),
        );
      }

      final result = await dataSource.getProgressStats();

      expect(result.minutesPerWeek, hasLength(8));
    });

    test('10.2-DATA-006: sessionTypeCounts groups by type correctly', () async {
      await seedSession(
        sessionType: 'cardio',
        completedAt: DateTime.utc(2026, 5, 20, 8),
      );
      await seedSession(
        sessionType: 'cardio',
        completedAt: DateTime.utc(2026, 5, 21, 8),
      );
      await seedSession(
        sessionType: 'mobility',
        completedAt: DateTime.utc(2026, 5, 22, 8),
      );

      final result = await dataSource.getProgressStats();

      expect(result.sessionTypeCounts['cardio'], 2);
      expect(result.sessionTypeCounts['mobility'], 1);
    });

    test(
      '10.3-DATA-001: completedThisWeek counts only non-abandoned logs in current ISO week',
      () async {
        final weekStart = mondayOf(DateTime.now());
        await seedSession(
          sessionType: 'cardio',
          completedAt: weekStart.add(const Duration(days: 1, hours: 8)),
        );
        await seedSession(
          sessionType: 'mobility',
          completedAt: weekStart
              .subtract(const Duration(days: 7))
              .add(const Duration(hours: 8)),
        );
        await seedSession(
          sessionType: 'breathing',
          completedAt: weekStart.add(const Duration(days: 2, hours: 8)),
          abandoned: true,
          elapsedSeconds: 180,
        );

        final result = await dataSource.getProgressStats();

        expect(result.completedThisWeek, 1);
      },
    );

    test(
      '10.3-DATA-002: completedThisWeek is 0 when no sessions this week',
      () async {
        final weekStart = mondayOf(DateTime.now());
        await seedSession(
          sessionType: 'cardio',
          completedAt: weekStart
              .subtract(const Duration(days: 14))
              .add(const Duration(hours: 8)),
        );

        final result = await dataSource.getProgressStats();

        expect(result.completedThisWeek, 0);
      },
    );

    test('10.3-DATA-003: weeklyTarget is always 3', () async {
      final result = await dataSource.getProgressStats();

      expect(result.weeklyTarget, 3);
    });
  });
}
