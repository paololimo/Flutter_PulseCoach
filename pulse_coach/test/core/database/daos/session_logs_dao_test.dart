import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // The session_logs.dailyPlanId FK to daily_plans.id is now enforced
  // (schemaVersion 6 + PRAGMA foreign_keys = ON), so every test must first
  // seed a real plan row and use its returned autoincrement id.
  Future<int> seedPlan(String date) async {
    final now = DateTime.utc(2026, 5, 16, 9);
    return db.dailyPlansDao.insertPlan(
      DailyPlansCompanion.insert(
        planDate: date,
        planJson: '{"sessions":[]}',
        generatedAt: now,
        createdAt: now,
      ),
    );
  }

  group('SessionLogsDao', () {
    test(
      '8.0-DAO-001: insertLog stores a row retrievable by getLogsForPlan',
      () async {
        final planId = await seedPlan('2026-05-16');
        final completedAt = DateTime.utc(2026, 5, 16, 9);

        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planId),
            sessionIndex: 1,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );

        final logs = await db.sessionLogsDao.getLogsForPlan(planId);

        expect(logs, hasLength(1));
        expect(logs.single.dailyPlanId, planId);
        expect(logs.single.sessionIndex, 1);
        expect(
          logs.single.completedAt.millisecondsSinceEpoch,
          completedAt.millisecondsSinceEpoch,
        );
        expect(
          logs.single.createdAt.millisecondsSinceEpoch,
          completedAt.millisecondsSinceEpoch,
        );
      },
    );

    test(
      '8.0-DAO-002: getLogsForPlan returns only logs for the given planId',
      () async {
        final planA = await seedPlan('2026-05-16');
        final planB = await seedPlan('2026-05-17');
        final completedAt = DateTime.utc(2026, 5, 16, 9);

        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planA),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );
        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planB),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );

        final logs = await db.sessionLogsDao.getLogsForPlan(planA);

        expect(logs, hasLength(1));
        expect(logs.single.dailyPlanId, planA);
      },
    );

    test(
      '8.0-DAO-003: getLogsForPlan returns empty list for unknown planId',
      () async {
        final logs = await db.sessionLogsDao.getLogsForPlan(404);

        expect(logs, isEmpty);
      },
    );

    test(
      '8.0-DAO-004: insertLog for two different sessions yields two logs',
      () async {
        final planId = await seedPlan('2026-05-16');
        final completedAt = DateTime.utc(2026, 5, 16, 9);

        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planId),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );
        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planId),
            sessionIndex: 2,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );

        final logs = await db.sessionLogsDao.getLogsForPlan(planId);

        expect(logs, hasLength(2));
        expect(logs.map((log) => log.sessionIndex), containsAll(<int>[0, 2]));
      },
    );

    test(
      '8.0-DAO-005: deleteLogsForPlan removes all rows for planId, returns count',
      () async {
        final planA = await seedPlan('2026-05-16');
        final planB = await seedPlan('2026-05-17');
        final completedAt = DateTime.utc(2026, 5, 16, 9);

        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planA),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );
        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planA),
            sessionIndex: 1,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );
        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planB),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );

        final removed = await db.sessionLogsDao.deleteLogsForPlan(planA);

        expect(removed, 2);
        expect(await db.sessionLogsDao.getLogsForPlan(planA), isEmpty);
        expect(await db.sessionLogsDao.getLogsForPlan(planB), hasLength(1));
      },
    );

    test(
      '8.0-DAO-006: deleteLogsForPlan on unknown planId returns 0, no error',
      () async {
        final removed = await db.sessionLogsDao.deleteLogsForPlan(404);

        expect(removed, 0);
      },
    );

    test(
      '8.0-DAO-007: UNIQUE(dailyPlanId, sessionIndex) — duplicate insert is silently ignored',
      () async {
        final planId = await seedPlan('2026-05-16');
        final completedAt = DateTime.utc(2026, 5, 16, 9);
        final companion = SessionLogsCompanion.insert(
          dailyPlanId: Value(planId),
          sessionIndex: 0,
          completedAt: completedAt,
          createdAt: completedAt,
        );

        await db.sessionLogsDao.insertLog(companion);
        // Second insert with the same (planId, sessionIndex) must not throw
        // and must not create a duplicate row.
        await db.sessionLogsDao.insertLog(companion);

        final logs = await db.sessionLogsDao.getLogsForPlan(planId);
        expect(logs, hasLength(1));
      },
    );

    test(
      '8.0-DAO-008: ON DELETE CASCADE — deleting the parent plan removes its logs',
      () async {
        final planId = await seedPlan('2026-05-16');
        final completedAt = DateTime.utc(2026, 5, 16, 9);
        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planId),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );

        await db.dailyPlansDao.deletePlan(planId);

        expect(await db.sessionLogsDao.getLogsForPlan(planId), isEmpty);
      },
    );

    test(
      '8.0-DAO-009: getLogFor returns only the matching plan and session row',
      () async {
        final planA = await seedPlan('2026-05-16');
        final planB = await seedPlan('2026-05-17');
        final completedAt = DateTime.utc(2026, 5, 16, 9);

        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planA),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );
        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planA),
            sessionIndex: 1,
            completedAt: completedAt.add(const Duration(minutes: 5)),
            createdAt: completedAt,
          ),
        );
        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planB),
            sessionIndex: 1,
            completedAt: completedAt.add(const Duration(minutes: 10)),
            createdAt: completedAt,
          ),
        );

        final log = await db.sessionLogsDao.getLogFor(planA, 1);

        expect(log, isNotNull);
        expect(log!.dailyPlanId, planA);
        expect(log.sessionIndex, 1);
        expect(
          log.completedAt.millisecondsSinceEpoch,
          completedAt.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
        );
      },
    );

    test(
      '8.0-DAO-010: getLogFor returns null for a missing session index',
      () async {
        final planId = await seedPlan('2026-05-16');
        final completedAt = DateTime.utc(2026, 5, 16, 9);

        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planId),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );

        final log = await db.sessionLogsDao.getLogFor(planId, 2);

        expect(log, isNull);
      },
    );

    test(
      '8.0-DAO-011: watchLogsForPlan emits initial rows and re-emits after insert',
      () async {
        final planId = await seedPlan('2026-05-16');
        final completedAt = DateTime.utc(2026, 5, 16, 9);

        final expectation = expectLater(
          db.sessionLogsDao.watchLogsForPlan(planId),
          emitsInOrder([
            isEmpty,
            predicate<List<SessionLog>>(
              (logs) =>
                  logs.length == 1 &&
                  logs.single.dailyPlanId == planId &&
                  logs.single.sessionIndex == 0,
              'one inserted log for the watched plan',
            ),
          ]),
        );

        await pumpEventQueue();

        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planId),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );

        await expectation;
      },
    );

    test(
      '8.5-DAO-001: insertLog stores abandoned partial-session metadata',
      () async {
        final planId = await seedPlan('2026-05-17');
        final abandonedAt = DateTime.utc(2026, 5, 17, 10);

        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion(
            dailyPlanId: Value(planId),
            sessionIndex: const Value(0),
            completedAt: Value(abandonedAt),
            createdAt: Value(abandonedAt),
            abandoned: const Value(true),
            elapsedSeconds: const Value(3),
            currentStepIndex: const Value(0),
          ),
        );

        final logs = await db.sessionLogsDao.getLogsForPlan(planId);

        expect(logs, hasLength(1));
        expect(logs.single.abandoned, isTrue);
        expect(logs.single.elapsedSeconds, 3);
        expect(logs.single.currentStepIndex, 0);
      },
    );

    test('8.5-DAO-002: completion rows default abandoned to false', () async {
      final planId = await seedPlan('2026-05-18');
      final completedAt = DateTime.utc(2026, 5, 18, 9);

      await db.sessionLogsDao.insertLog(
        SessionLogsCompanion.insert(
          dailyPlanId: Value(planId),
          sessionIndex: 0,
          completedAt: completedAt,
          createdAt: completedAt,
        ),
      );

      final logs = await db.sessionLogsDao.getLogsForPlan(planId);

      expect(logs.single.abandoned, isFalse);
      expect(logs.single.elapsedSeconds, isNull);
      expect(logs.single.currentStepIndex, isNull);
    });

    test(
      '8.5-DAO-003: upsertCompletion replaces a prior abandoned row for the same (planId, sessionIndex)',
      () async {
        final planId = await seedPlan('2026-05-19');
        final abandonAt = DateTime.utc(2026, 5, 19, 9);
        final completedAt = DateTime.utc(2026, 5, 19, 10);

        // First — abandon row.
        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion(
            dailyPlanId: Value(planId),
            sessionIndex: const Value(0),
            completedAt: Value(abandonAt),
            createdAt: Value(abandonAt),
            abandoned: const Value(true),
            elapsedSeconds: const Value(5),
            currentStepIndex: const Value(1),
          ),
        );

        // Then — retry, completes the session via upsertCompletion. UNIQUE
        // (planId, sessionIndex) means insertOrIgnore would have silently
        // dropped this; insertOrReplace overwrites the abandoned row.
        await db.sessionLogsDao.upsertCompletion(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planId),
            sessionIndex: 0,
            completedAt: completedAt,
            createdAt: completedAt,
          ),
        );

        final logs = await db.sessionLogsDao.getLogsForPlan(planId);

        expect(logs, hasLength(1));
        expect(logs.single.abandoned, isFalse);
        expect(logs.single.elapsedSeconds, isNull);
        expect(logs.single.currentStepIndex, isNull);
      },
    );

    test(
      '21.0-DAO-001: insertLog with dailyPlanId: null (shared session) round-'
      'trips via getAllLogsOrderedByDate with id populated, dailyPlanId null',
      () async {
        final completedAt = DateTime.utc(2026, 7, 1, 9);

        final id = await db.sessionLogsDao.insertLog(
          SessionLogsCompanion(
            dailyPlanId: const Value(null),
            sessionIndex: const Value(0),
            completedAt: Value(completedAt),
            createdAt: Value(completedAt),
            sessionType: const Value('cardio'),
            armKey: const Value('cardio_high'),
            durationMinutes: const Value(15),
          ),
        );

        final all = await db.sessionLogsDao.getAllLogsOrderedByDate();
        final log = all.singleWhere((l) => l.id == id);

        expect(log.id, isNot(0));
        expect(log.dailyPlanId, isNull);
        expect(log.sessionType, 'cardio');
        expect(log.armKey, 'cardio_high');
        expect(log.durationMinutes, 15);
      },
    );
  });
}
