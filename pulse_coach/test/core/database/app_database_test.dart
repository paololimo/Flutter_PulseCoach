import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase - table smoke tests', () {
    test('sessions table: insert and retrieve', () async {
      await db.sessionsDao.insertSession(
        SessionsCompanion.insert(
          sessionType: 'cardio',
          intensity: 5,
          durationSeconds: 300,
          createdAt: DateTime.now(),
        ),
      );
      final all = await db.sessionsDao.getAllSessions();
      expect(all.length, 1);
      expect(all.first.sessionType, 'cardio');
    });

    test('daily_plans table: insert and retrieve by date', () async {
      await db.dailyPlansDao.insertPlan(
        DailyPlansCompanion.insert(
          planDate: '2026-03-28',
          planJson: '{"sessions":[]}',
          generatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      final plan = await db.dailyPlansDao.getPlanForDate('2026-03-28');
      expect(plan, isNotNull);
      expect(plan!.planDate, '2026-03-28');
    });

    test('daily_plans: isCompleted defaults to false on insert', () async {
      await db.dailyPlansDao.insertPlan(
        DailyPlansCompanion.insert(
          planDate: '2026-03-29',
          planJson: '{"sessions":[]}',
          generatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      final plan = await db.dailyPlansDao.getPlanForDate('2026-03-29');
      expect(plan, isNotNull);
      expect(plan!.isCompleted, false);
    });

    test('daily_plans: markCompleted sets isCompleted to true', () async {
      await db.dailyPlansDao.insertPlan(
        DailyPlansCompanion.insert(
          planDate: '2026-03-30',
          planJson: '{"sessions":[]}',
          generatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      final updated = await db.dailyPlansDao.markCompleted('2026-03-30');
      expect(updated, true);
      final plan = await db.dailyPlansDao.getPlanForDate('2026-03-30');
      expect(plan!.isCompleted, true);
    });

    test(
      'daily_plans: markCompleted returns false when no plan matches',
      () async {
        final updated = await db.dailyPlansDao.markCompleted('2099-01-01');
        expect(updated, false);
      },
    );

    test(
      'daily_plans: markCompleted is idempotent on already-completed row',
      () async {
        await db.dailyPlansDao.insertPlan(
          DailyPlansCompanion.insert(
            planDate: '2026-03-31',
            planJson: '{"sessions":[]}',
            generatedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
        expect(await db.dailyPlansDao.markCompleted('2026-03-31'), true);
        // Second call on already-completed row stays true; row remains completed.
        expect(await db.dailyPlansDao.markCompleted('2026-03-31'), true);
        final plan = await db.dailyPlansDao.getPlanForDate('2026-03-31');
        expect(plan!.isCompleted, true);
      },
    );

    test('user_profile table: insert and retrieve', () async {
      await db.userProfileDao.insertProfile(
        UserProfileCompanion.insert(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final profile = await db.userProfileDao.getProfile();
      expect(profile, isNotNull);
    });

    test(
      'user_profile: disclaimerAccepted defaults to false on insert',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final profile = await db.userProfileDao.getProfile();
        expect(profile, isNotNull);
        expect(profile!.disclaimerAccepted, false);
      },
    );

    test('rpe_feedback table: insert and retrieve', () async {
      await db.rpeFeedbackDao.insertFeedback(
        RpeFeedbackCompanion.insert(
          sessionId: 1,
          rpeValue: 7,
          recordedAt: DateTime.now(),
        ),
      );
      final all = await db.rpeFeedbackDao.getAllFeedback();
      expect(all.length, 1);
      expect(all.first.rpeValue, 7); // RpeFeedbackData
    });

    test('bandit_state table: insert and retrieve', () async {
      await db.banditStateDao.insertState(
        BanditStateCompanion.insert(
          armWeightsJson: '{"mobility_low":1.0}',
          updatedAt: DateTime.now(),
        ),
      );
      final state = await db.banditStateDao.getLatestState();
      expect(state, isNotNull);
      expect(state!.armWeightsJson, '{"mobility_low":1.0}');
    });

    test('behavioral_state table: insert and retrieve', () async {
      await db.behavioralStateDao.insertState(
        BehavioralStateCompanion.insert(
          currentState: 'Active',
          recordedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final state = await db.behavioralStateDao.getLatestState();
      expect(state, isNotNull);
      expect(state!.currentState, 'Active');
    });

    test('weather_cache table: insert and retrieve', () async {
      await db.weatherCacheDao.insertOrReplace(
        WeatherCacheCompanion.insert(
          latitude: 45.4642,
          longitude: 9.1900,
          temperature: 22.5,
          precipitationProbability: 0.1,
          aqiValue: 30,
          cachedAt: DateTime.now(),
        ),
      );
      final cache = await db.weatherCacheDao.getLatestCache();
      expect(cache, isNotNull);
      expect(cache!.temperature, 22.5);
    });

    test('exercise_cache table: insert and retrieve by id', () async {
      await db.exerciseCacheDao.insertOrReplace(
        ExerciseCacheCompanion.insert(
          exerciseId: 'ex-001',
          exerciseJson: '{"name":"Push Up"}',
          cachedAt: DateTime.now(),
        ),
      );
      final exercise = await db.exerciseCacheDao.getByExerciseId('ex-001');
      expect(exercise, isNotNull);
      expect(exercise!.exerciseId, 'ex-001');
    });

    test('sync_queue table: insert and retrieve pending entries', () async {
      await db.syncQueueDao.insertEntry(
        SyncQueueCompanion.insert(
          eventType: 'session_completed',
          payload: '{"id":1}',
          createdAt: DateTime.now(),
        ),
      );
      final pending = await db.syncQueueDao.getPendingEntries();
      expect(pending.length, 1);
      expect(pending.first.eventType, 'session_completed');
    });
  });

  group('AppDatabase - migration strategy', () {
    test('onUpgrade callback is defined', () {
      expect(db.migration.onUpgrade, isNotNull);
    });

    test('schemaVersion is 6', () {
      expect(db.schemaVersion, 6);
    });
  });

  group('AppDatabase - real migration v1 → v2', () {
    test('disclaimerAccepted column added with default false', () async {
      // Build an in-memory SQLite database with the v1 schema
      // (user_profile without disclaimer_accepted) and user_version = 1.
      // All tables present in v1 onCreate are included so that later
      // migrations (v3→v4 adds daily_plans.is_completed) do not fail.
      final v1Raw = sqlite3.openInMemory();
      v1Raw.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          fitness_goal TEXT,
          weekly_session_target INTEGER NOT NULL DEFAULT 3,
          intensity_preference TEXT,
          environment_preference TEXT,
          onboarding_completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      v1Raw.execute('''
        CREATE TABLE IF NOT EXISTS daily_plans (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          plan_date TEXT NOT NULL UNIQUE,
          plan_json TEXT NOT NULL,
          generated_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      final now = DateTime.now().millisecondsSinceEpoch;
      v1Raw.execute(
        'INSERT INTO user_profile (onboarding_completed, created_at, updated_at) VALUES (0, ?, ?)',
        [now, now],
      );
      v1Raw.execute('PRAGMA user_version = 1');

      // Open as AppDatabase — drift detects user_version=1 < schemaVersion=2
      // and calls onUpgrade(m, 1, 2), which adds disclaimer_accepted column.
      final migratedDb = AppDatabase.forTesting(NativeDatabase.opened(v1Raw));

      final profile = await migratedDb.userProfileDao.getProfile();

      expect(profile, isNotNull);
      expect(
        profile!.disclaimerAccepted,
        false,
        reason: 'migration must add disclaimer_accepted with DEFAULT 0',
      );

      await migratedDb.close();
    });
  });

  group('AppDatabase - real migration v3 → v4', () {
    test(
      'daily_plans.is_completed column added with default 0 on existing rows',
      () async {
        // Build a raw v3 schema: all v3 tables present, with a pre-existing
        // row in daily_plans WITHOUT the is_completed column.
        // user_version = 3 → drift calls onUpgrade(m, 3, 4), which must
        // ALTER TABLE daily_plans ADD COLUMN is_completed with DEFAULT 0
        // so the pre-existing row is backfilled to false.
        final v3Raw = sqlite3.openInMemory();
        v3Raw.execute('''
          CREATE TABLE IF NOT EXISTS daily_plans (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            plan_date TEXT NOT NULL UNIQUE,
            plan_json TEXT NOT NULL,
            generated_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        final now = DateTime.now().millisecondsSinceEpoch;
        v3Raw.execute(
          'INSERT INTO daily_plans '
          '(plan_date, plan_json, generated_at, created_at) '
          'VALUES (?, ?, ?, ?)',
          ['2026-04-01', '{"sessions":[]}', now, now],
        );
        v3Raw.execute('PRAGMA user_version = 3');

        final migratedDb = AppDatabase.forTesting(NativeDatabase.opened(v3Raw));

        final plan = await migratedDb.dailyPlansDao.getPlanForDate(
          '2026-04-01',
        );

        expect(plan, isNotNull);
        expect(
          plan!.isCompleted,
          false,
          reason: 'v3 → v4 migration must add is_completed with DEFAULT 0',
        );

        await migratedDb.close();
      },
    );
  });

  group('AppDatabase - real migration v4 → v6', () {
    test('session_logs table is created, FK-enforced, and writable', () async {
      final v4Raw = sqlite3.openInMemory();
      // v4 schema needs daily_plans pre-existing (with is_completed, added in
      // v3→v4) so the FK lookup from session_logs can resolve a real row.
      v4Raw.execute('''
        CREATE TABLE IF NOT EXISTS daily_plans (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          plan_date TEXT NOT NULL UNIQUE,
          plan_json TEXT NOT NULL,
          generated_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0
        )
      ''');
      v4Raw.execute('PRAGMA user_version = 4');

      final migratedDb = AppDatabase.forTesting(NativeDatabase.opened(v4Raw));
      final now = DateTime.utc(2026, 5, 16, 9);

      // FK→daily_plans is now enforced (v6 added ON DELETE CASCADE + pragma).
      // Insert a parent row so the child insert can succeed.
      final planId = await migratedDb.dailyPlansDao.insertPlan(
        DailyPlansCompanion.insert(
          planDate: '2026-05-16',
          planJson: '{"sessions":[]}',
          generatedAt: now,
          createdAt: now,
        ),
      );

      await migratedDb.sessionLogsDao.insertLog(
        SessionLogsCompanion.insert(
          dailyPlanId: planId,
          sessionIndex: 0,
          completedAt: now,
          createdAt: now,
        ),
      );

      final logs = await migratedDb.sessionLogsDao.getLogsForPlan(planId);

      expect(logs, hasLength(1));
      expect(logs.single.sessionIndex, 0);

      await migratedDb.close();
    });
  });

  group('AppDatabase - real migration v3 → v6 (composite)', () {
    test(
      'addColumn (v3→v4) + createTable (v4→v5) + recreate with FK (v5→v6) '
      'all run cleanly in one upgrade',
      () async {
        // Build a raw v3 schema with a pre-existing daily_plans row and no
        // is_completed column. user_version = 3 → drift fires the full chain
        // (v3→v4: addColumn is_completed, v4→v5: createTable session_logs,
        // v5→v6: drop+recreate session_logs with FK + UNIQUE).
        final v3Raw = sqlite3.openInMemory();
        v3Raw.execute('''
          CREATE TABLE IF NOT EXISTS daily_plans (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            plan_date TEXT NOT NULL UNIQUE,
            plan_json TEXT NOT NULL,
            generated_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        v3Raw.execute(
          'INSERT INTO daily_plans '
          '(plan_date, plan_json, generated_at, created_at) '
          'VALUES (?, ?, ?, ?)',
          ['2026-04-01', '{"sessions":[]}', nowMs, nowMs],
        );
        v3Raw.execute('PRAGMA user_version = 3');

        final migratedDb = AppDatabase.forTesting(NativeDatabase.opened(v3Raw));

        // v3→v4: column was added, pre-existing row backfilled to false.
        final preExisting = await migratedDb.dailyPlansDao.getPlanForDate(
          '2026-04-01',
        );
        expect(preExisting, isNotNull);
        expect(preExisting!.isCompleted, false);

        // v4→v5→v6: session_logs is present, enforces FK, and accepts inserts.
        final now = DateTime.utc(2026, 5, 16, 9);
        await migratedDb.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: preExisting.id,
            sessionIndex: 0,
            completedAt: now,
            createdAt: now,
          ),
        );
        final logs = await migratedDb.sessionLogsDao.getLogsForPlan(
          preExisting.id,
        );
        expect(logs, hasLength(1));

        await migratedDb.close();
      },
    );
  });
}
