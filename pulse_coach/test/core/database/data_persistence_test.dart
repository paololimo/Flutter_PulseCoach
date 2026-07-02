import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('AppDatabase - data persistence guarantees', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'pulse_coach_persist_test_',
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    AppDatabase openFileDb(String name) => AppDatabase.forTesting(
      NativeDatabase(File('${tempDir.path}/$name.db')),
    );

    test('13.3-PERSIST-001: daily plan survives DB close and reopen', () async {
      final now = DateTime.utc(2026, 6, 4, 9);

      final db1 = openFileDb('daily_plan');
      addTearDown(db1.close);
      await db1.dailyPlansDao.insertPlan(
        DailyPlansCompanion.insert(
          planDate: '2026-06-04',
          planJson: '{"sessions":[{"type":"cardio"}]}',
          generatedAt: now,
          createdAt: now,
        ),
      );
      await db1.close();

      final db2 = openFileDb('daily_plan');
      addTearDown(db2.close);
      final plan = await db2.dailyPlansDao.getPlanForDate('2026-06-04');

      expect(plan, isNotNull);
      expect(plan!.planJson, '{"sessions":[{"type":"cardio"}]}');
    });

    test(
      '13.3-PERSIST-002: session_log survives DB close and reopen with FK parent',
      () async {
        final now = DateTime.utc(2026, 6, 4, 10);

        final db1 = openFileDb('session_log');
        addTearDown(db1.close);
        final planId = await db1.dailyPlansDao.insertPlan(
          DailyPlansCompanion.insert(
            planDate: '2026-06-05',
            planJson: '{"sessions":[{"type":"mobility"}]}',
            generatedAt: now,
            createdAt: now,
          ),
        );
        await db1.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planId),
            sessionIndex: 0,
            completedAt: now,
            createdAt: now,
          ),
        );
        await db1.close();

        final db2 = openFileDb('session_log');
        addTearDown(db2.close);
        final plan = await db2.dailyPlansDao.getPlanById(planId);
        final logs = await db2.sessionLogsDao.getLogsForPlan(planId);

        expect(plan, isNotNull);
        expect(logs, hasLength(1));
        expect(logs.single.dailyPlanId, planId);
        expect(logs.single.sessionIndex, 0);
      },
    );

    test(
      '13.3-PERSIST-003: bandit state survives DB close and reopen',
      () async {
        final now = DateTime.utc(2026, 6, 4, 11);

        final db1 = openFileDb('bandit_state');
        addTearDown(db1.close);
        await db1.banditStateDao.insertState(
          BanditStateCompanion.insert(
            armWeightsJson: '{"mobility_low":1.0,"cardio_medium":0.5}',
            updatedAt: now,
          ),
        );
        await db1.close();

        final db2 = openFileDb('bandit_state');
        addTearDown(db2.close);
        final state = await db2.banditStateDao.getLatestState();

        expect(state, isNotNull);
        expect(
          state!.armWeightsJson,
          '{"mobility_low":1.0,"cardio_medium":0.5}',
        );
      },
    );

    test(
      '13.3-PERSIST-004: behavioral state survives DB close and reopen',
      () async {
        final now = DateTime.utc(2026, 6, 4, 12);

        final db1 = openFileDb('behavioral_state');
        addTearDown(db1.close);
        await db1.behavioralStateDao.insertState(
          BehavioralStateCompanion.insert(
            currentState: 'Recovering',
            recordedAt: now,
            updatedAt: now,
          ),
        );
        await db1.close();

        final db2 = openFileDb('behavioral_state');
        addTearDown(db2.close);
        final state = await db2.behavioralStateDao.getLatestState();

        expect(state, isNotNull);
        expect(state!.currentState, 'Recovering');
      },
    );

    test(
      '13.3-PERSIST-005: RPE feedback survives DB close and reopen',
      () async {
        final now = DateTime.utc(2026, 6, 4, 13);

        final db1 = openFileDb('rpe_feedback');
        addTearDown(db1.close);
        await db1.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: 42,
            rpeValue: 8,
            recordedAt: now,
          ),
        );
        await db1.close();

        final db2 = openFileDb('rpe_feedback');
        addTearDown(db2.close);
        final feedback = await db2.rpeFeedbackDao.getAllFeedback();

        expect(feedback, hasLength(1));
        expect(feedback.single.rpeValue, 8);
      },
    );
  });

  group('AppDatabase - migration data guarantees', () {
    test(
      '13.3-PERSIST-006: v1 to v9 composite migration preserves live data',
      () async {
        final raw = sqlite3.openInMemory();
        final now = DateTime.utc(2026, 6, 4, 14).millisecondsSinceEpoch;

        _createV1Schema(raw);
        raw.execute(
          'INSERT INTO sessions '
          '(id, session_type, intensity, duration_seconds, abandoned, completed_at, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?)',
          [1, 'cardio', 6, 1200, 0, now, now],
        );
        raw.execute(
          'INSERT INTO bandit_state (arm_weights_json, updated_at) '
          'VALUES (?, ?)',
          ['{"mobility_low":1.0}', now],
        );
        raw.execute(
          'INSERT INTO rpe_feedback (session_id, rpe_value, recorded_at) '
          'VALUES (?, ?, ?)',
          [1, 7, now],
        );
        raw.execute('PRAGMA user_version = 1');

        final migratedDb = AppDatabase.forTesting(NativeDatabase.opened(raw));
        addTearDown(migratedDb.close);

        // Prove the migration chain actually ran to completion: Drift bumps the
        // DB's user_version to the declared schemaVersion (10) only after the
        // full v1→v10 onUpgrade succeeds. Asserting it guards against a
        // silently-skipped or partially-applied migration that the data-only
        // checks below could miss.
        final versionRow = await migratedDb
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(versionRow.data.values.single, 10);

        final sessions = await migratedDb.sessionsDao.getAllSessions();
        final banditState = await migratedDb.banditStateDao.getLatestState();
        final feedback = await migratedDb.rpeFeedbackDao.getAllFeedback();

        expect(sessions, hasLength(1));
        expect(sessions.single.sessionType, 'cardio');
        expect(banditState, isNotNull);
        expect(banditState!.armWeightsJson, '{"mobility_low":1.0}');
        expect(feedback, hasLength(1));
        expect(feedback.single.rpeValue, 7);
        expect(feedback.single.sessionLogId, isNull);
      },
    );
  });

  group('AppDatabase - foreign key enforcement', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      '13.3-PERSIST-011: orphan session_log insert is rejected by the FK constraint',
      () async {
        final now = DateTime.utc(2026, 6, 4, 15);

        // Default insert mode (not insertOrIgnore) surfaces the violation, so a
        // dangling dailyPlanId proves PRAGMA foreign_keys = ON AND the FK exists.
        await expectLater(
          db.into(db.sessionLogs).insert(
            SessionLogsCompanion.insert(
              dailyPlanId: const Value(999999),
              sessionIndex: 0,
              completedAt: now,
              createdAt: now,
            ),
          ),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test(
      '13.3-PERSIST-012: deleting a daily plan cascades to its session_logs',
      () async {
        final now = DateTime.utc(2026, 6, 4, 16);

        final planId = await db.dailyPlansDao.insertPlan(
          DailyPlansCompanion.insert(
            planDate: '2026-06-06',
            planJson: '{"sessions":[{"type":"cardio"}]}',
            generatedAt: now,
            createdAt: now,
          ),
        );
        await db.sessionLogsDao.insertLog(
          SessionLogsCompanion.insert(
            dailyPlanId: Value(planId),
            sessionIndex: 0,
            completedAt: now,
            createdAt: now,
          ),
        );
        expect(await db.sessionLogsDao.getLogsForPlan(planId), hasLength(1));

        await db.dailyPlansDao.deletePlan(planId);

        expect(await db.sessionLogsDao.getLogsForPlan(planId), isEmpty);
      },
    );
  });

  group('AppDatabase - TTL cache timestamp integrity', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('13.3-PERSIST-007: weather cachedAt within TTL', () async {
      final cachedAt = DateTime.now().toUtc().subtract(
        const Duration(minutes: 30),
      );

      await db.weatherCacheDao.insertOrReplace(
        WeatherCacheCompanion.insert(
          latitude: 45,
          longitude: 9,
          temperature: 20,
          precipitationProbability: 0.1,
          aqiValue: 30,
          cachedAt: cachedAt,
        ),
      );

      final row = await db.weatherCacheDao.getLatestCache();
      expect(row, isNotNull);
      final age = DateTime.now().toUtc().difference(row!.cachedAt.toUtc());
      expect(
        age < const Duration(hours: 1),
        isTrue,
        reason: 'cachedAt 30min ago must be within 1h TTL',
      );
    });

    test('13.3-PERSIST-008: weather cachedAt outside TTL', () async {
      final cachedAt = DateTime.now().toUtc().subtract(
        const Duration(hours: 2),
      );

      await db.weatherCacheDao.insertOrReplace(
        WeatherCacheCompanion.insert(
          latitude: 45,
          longitude: 9,
          temperature: 20,
          precipitationProbability: 0.1,
          aqiValue: 30,
          cachedAt: cachedAt,
        ),
      );

      final row = await db.weatherCacheDao.getLatestCache();
      expect(row, isNotNull);
      final age = DateTime.now().toUtc().difference(row!.cachedAt.toUtc());
      expect(
        age < const Duration(hours: 1),
        isFalse,
        reason: 'cachedAt 2h ago must be outside 1h TTL',
      );
    });

    test('13.3-PERSIST-009: exercise cachedAt within TTL', () async {
      final cachedAt = DateTime.now().toUtc().subtract(
        const Duration(hours: 12),
      );

      await db.exerciseCacheDao.insertOrReplace(
        ExerciseCacheCompanion.insert(
          exerciseId: 'push-up',
          exerciseJson: '{"name":"Push Up"}',
          cachedAt: cachedAt,
        ),
      );

      final row = await db.exerciseCacheDao.getByExerciseId('push-up');
      expect(row, isNotNull);
      final age = DateTime.now().toUtc().difference(row!.cachedAt.toUtc());
      expect(
        age < const Duration(hours: 24),
        isTrue,
        reason: 'cachedAt 12h ago must be within 24h TTL',
      );
    });

    test('13.3-PERSIST-010: exercise cachedAt outside TTL', () async {
      final cachedAt = DateTime.now().toUtc().subtract(
        const Duration(hours: 26),
      );

      await db.exerciseCacheDao.insertOrReplace(
        ExerciseCacheCompanion.insert(
          exerciseId: 'squat',
          exerciseJson: '{"name":"Squat"}',
          cachedAt: cachedAt,
        ),
      );

      final row = await db.exerciseCacheDao.getByExerciseId('squat');
      expect(row, isNotNull);
      final age = DateTime.now().toUtc().difference(row!.cachedAt.toUtc());
      expect(
        age < const Duration(hours: 24),
        isFalse,
        reason: 'cachedAt 26h ago must be outside 24h TTL',
      );
    });
  });
}

void _createV1Schema(Database raw) {
  raw.execute('''
    CREATE TABLE IF NOT EXISTS sessions (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      session_type TEXT NOT NULL,
      intensity INTEGER NOT NULL,
      duration_seconds INTEGER NOT NULL,
      abandoned INTEGER NOT NULL DEFAULT 0,
      completed_at INTEGER,
      created_at INTEGER NOT NULL
    )
  ''');
  raw.execute('''
    CREATE TABLE IF NOT EXISTS daily_plans (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      plan_date TEXT NOT NULL UNIQUE,
      plan_json TEXT NOT NULL,
      generated_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
  raw.execute('''
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
  raw.execute('''
    CREATE TABLE IF NOT EXISTS rpe_feedback (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      rpe_value INTEGER NOT NULL,
      recorded_at INTEGER NOT NULL
    )
  ''');
  raw.execute('''
    CREATE TABLE IF NOT EXISTS bandit_state (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      arm_weights_json TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  raw.execute('''
    CREATE TABLE IF NOT EXISTS behavioral_state (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      current_state TEXT NOT NULL,
      resting_hr INTEGER,
      step_count INTEGER,
      streak_count INTEGER NOT NULL DEFAULT 0,
      recorded_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  raw.execute('''
    CREATE TABLE IF NOT EXISTS weather_cache (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      temperature REAL NOT NULL,
      precipitation_probability REAL NOT NULL,
      aqi_value INTEGER NOT NULL,
      cached_at INTEGER NOT NULL
    )
  ''');
  raw.execute('''
    CREATE TABLE IF NOT EXISTS exercise_cache (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      exercise_id TEXT NOT NULL UNIQUE,
      exercise_json TEXT NOT NULL,
      cached_at INTEGER NOT NULL
    )
  ''');
  raw.execute('''
    CREATE TABLE IF NOT EXISTS sync_queue (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      event_type TEXT NOT NULL,
      payload TEXT NOT NULL,
      retry_count INTEGER NOT NULL DEFAULT 0,
      next_retry_at INTEGER,
      created_at INTEGER NOT NULL
    )
  ''');
}
