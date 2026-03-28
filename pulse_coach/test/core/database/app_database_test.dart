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

    test('user_profile: disclaimerAccepted defaults to false on insert',
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
    });

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
      final exercise =
          await db.exerciseCacheDao.getByExerciseId('ex-001');
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

    test('schemaVersion is 2', () {
      expect(db.schemaVersion, 2);
    });
  });

  group('AppDatabase - real migration v1 → v2', () {
    test('disclaimerAccepted column added with default false', () async {
      // Build an in-memory SQLite database with the v1 schema
      // (user_profile without disclaimer_accepted) and user_version = 1.
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
      final now = DateTime.now().millisecondsSinceEpoch;
      v1Raw.execute(
        'INSERT INTO user_profile (onboarding_completed, created_at, updated_at) VALUES (0, ?, ?)',
        [now, now],
      );
      v1Raw.execute('PRAGMA user_version = 1');

      // Open as AppDatabase — drift detects user_version=1 < schemaVersion=2
      // and calls onUpgrade(m, 1, 2), which adds disclaimer_accepted column.
      final migratedDb =
          AppDatabase.forTesting(NativeDatabase.opened(v1Raw));

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
}
