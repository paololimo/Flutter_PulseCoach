// [16.3-DS-001..008] BackupLocalDataSource unit tests
// Uses in-memory Drift DB (NativeDatabase.memory()) and mocked FlutterSecureStorage.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/features/auth/data/datasources/backup_local_data_source.dart';

import 'backup_local_data_source_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  late AppDatabase db;
  late MockFlutterSecureStorage mockStorage;
  late BackupLocalDataSource sut;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockStorage = MockFlutterSecureStorage();
    sut = BackupLocalDataSource(db, mockStorage);
  });

  tearDown(() async {
    await db.close();
  });

  // ── 16.3-DS-001 ─────────────────────────────────────────────────────────
  group('storeEncryptionKey / loadEncryptionKey', () {
    test(
      '16.3-DS-001: write then read returns stored phrase',
      () async {
        when(
          mockStorage.write(
            key: 'backup_encryption_key',
            value: 'a1b2-c3d4',
          ),
        ).thenAnswer((_) async {});
        when(
          mockStorage.read(key: 'backup_encryption_key'),
        ).thenAnswer((_) async => 'a1b2-c3d4');

        await sut.storeEncryptionKey('a1b2-c3d4');
        final result = await sut.loadEncryptionKey();

        expect(result, equals('a1b2-c3d4'));
        verify(
          mockStorage.write(key: 'backup_encryption_key', value: 'a1b2-c3d4'),
        ).called(1);
      },
    );

    test(
      '16.3-DS-001b: loadEncryptionKey returns null when no key stored',
      () async {
        when(
          mockStorage.read(key: 'backup_encryption_key'),
        ).thenAnswer((_) async => null);

        final result = await sut.loadEncryptionKey();

        expect(result, isNull);
      },
    );
  });

  // ── 16.3-DS-002 ─────────────────────────────────────────────────────────
  group('setBackupEnabled / loadBackupEnabled', () {
    test(
      '16.3-DS-002: setBackupEnabled(true) → loadBackupEnabled returns true',
      () async {
        when(
          mockStorage.write(key: 'backup_enabled', value: 'true'),
        ).thenAnswer((_) async {});
        when(
          mockStorage.read(key: 'backup_enabled'),
        ).thenAnswer((_) async => 'true');

        await sut.setBackupEnabled(true);
        final result = await sut.loadBackupEnabled();

        expect(result, isTrue);
      },
    );

    test(
      '16.3-DS-002b: setBackupEnabled(false) → loadBackupEnabled returns false',
      () async {
        when(
          mockStorage.write(key: 'backup_enabled', value: 'false'),
        ).thenAnswer((_) async {});
        when(
          mockStorage.read(key: 'backup_enabled'),
        ).thenAnswer((_) async => 'false');

        await sut.setBackupEnabled(false);
        final result = await sut.loadBackupEnabled();

        expect(result, isFalse);
      },
    );

    test(
      '16.3-DS-002c: loadBackupEnabled when key absent → false',
      () async {
        when(
          mockStorage.read(key: 'backup_enabled'),
        ).thenAnswer((_) async => null);

        final result = await sut.loadBackupEnabled();

        expect(result, isFalse);
      },
    );
  });

  // ── 16.3-DS-003 ─────────────────────────────────────────────────────────
  group('queueBackupTask', () {
    test(
      '16.3-DS-003: inserts a backup entry into the SyncQueue table',
      () async {
        await sut.queueBackupTask(userId: 'user-999');

        final entries = await db.select(db.syncQueue).get();
        expect(entries, hasLength(1));
        expect(entries.single.eventType, equals('backup'));
        expect(entries.single.payload, contains('user-999'));
      },
    );
  });

  // ── 16.3-DS-004 ─────────────────────────────────────────────────────────
  group('exportDriftSnapshot', () {
    test(
      '16.3-DS-004: empty DB → snapshot has correct keys with empty lists',
      () async {
        final snapshot = await sut.exportDriftSnapshot();

        expect(snapshot.keys, containsAll([
          'userProfile',
          'sessions',
          'sessionLogs',
          'rpeFeedback',
          'banditState',
          'behavioralState',
          'dailyPlans',
        ]));
        for (final key in snapshot.keys) {
          expect(snapshot[key], isA<List>(), reason: '$key should be a list');
          expect((snapshot[key] as List), isEmpty, reason: '$key should be empty');
        }
      },
    );

    test(
      '16.3-DS-004b: daily plans older than 30 days are excluded from snapshot',
      () async {
        final now = DateTime.now().toUtc();
        final old = now.subtract(const Duration(days: 31));
        final recent = now.subtract(const Duration(days: 1));

        await db.into(db.dailyPlans).insert(
          DailyPlansCompanion.insert(
            planDate: '2026-05-01',
            planJson: '{"sessions":[]}',
            generatedAt: old,
            createdAt: old,
          ),
        );
        await db.into(db.dailyPlans).insert(
          DailyPlansCompanion.insert(
            planDate: '2026-06-21',
            planJson: '{"sessions":[]}',
            generatedAt: recent,
            createdAt: recent,
          ),
        );

        final snapshot = await sut.exportDriftSnapshot();

        final plans = snapshot['dailyPlans'] as List;
        expect(plans, hasLength(1));
        expect((plans.first as Map<String, dynamic>)['planDate'], equals('2026-06-21'));
      },
    );

    test(
      '16.3-DS-004c: session logs whose parent plan is filtered out are excluded',
      () async {
        final now = DateTime.now().toUtc();
        final old = now.subtract(const Duration(days: 31));

        // Old plan (will be excluded from 30-day filter)
        final oldPlanId = await db.into(db.dailyPlans).insert(
          DailyPlansCompanion.insert(
            planDate: '2026-05-01',
            planJson: '{"sessions":[]}',
            generatedAt: old,
            createdAt: old,
          ),
        );

        // Log pointing to the old plan
        await db.into(db.sessionLogs).insert(
          SessionLogsCompanion.insert(
            dailyPlanId: oldPlanId,
            sessionIndex: 0,
            completedAt: old,
            createdAt: old,
          ),
        );

        final snapshot = await sut.exportDriftSnapshot();

        final plans = snapshot['dailyPlans'] as List;
        final logs = snapshot['sessionLogs'] as List;
        expect(plans, isEmpty);
        expect(logs, isEmpty);
      },
    );
  });

  // ── 16.3-DS-005 ─────────────────────────────────────────────────────────
  group('restoreDriftSnapshot', () {
    test(
      '16.3-DS-005: export then restore round-trips userProfile and sessions',
      () async {
        // Seed a userProfile row
        await db.into(db.userProfile).insert(
          UserProfileCompanion.insert(
            weeklySessionTarget: const Value(3),
            onboardingCompleted: const Value(true),
            disclaimerAccepted: const Value(true),
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );

        // Seed a session row
        await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            sessionType: 'cardio',
            intensity: 5,
            durationSeconds: 300,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

        // Export
        final snapshot = await sut.exportDriftSnapshot();
        expect((snapshot['userProfile'] as List), hasLength(1));
        expect((snapshot['sessions'] as List), hasLength(1));

        // Clear and restore
        await db.delete(db.sessionLogs).go();
        await db.delete(db.rpeFeedback).go();
        await db.delete(db.sessions).go();
        await db.delete(db.dailyPlans).go();
        await db.delete(db.banditState).go();
        await db.delete(db.behavioralState).go();
        await db.delete(db.userProfile).go();

        final beforeRestore = await db.select(db.userProfile).get();
        expect(beforeRestore, isEmpty);

        await sut.restoreDriftSnapshot(snapshot);

        final profiles = await db.select(db.userProfile).get();
        expect(profiles, hasLength(1));
        expect(profiles.single.weeklySessionTarget, equals(3));

        final sessions = await db.select(db.sessions).get();
        expect(sessions, hasLength(1));
        expect(sessions.single.sessionType, equals('cardio'));
      },
    );

    test(
      '18.0-RESTORE-001: full round-trip — all 7 tables, FK relationships, and all fields preserved',
      () async {
        final now = DateTime.utc(2026, 6, 23, 12);
        // ── seed Sessions ──────────────────────────────────────────────────
        final sessionId = await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            sessionType: 'cardio',
            intensity: 6,
            durationSeconds: 900,
            abandoned: const Value(false),
            completedAt: Value(now),
            createdAt: now,
          ),
        );

        // ── seed DailyPlans (within 30-day filter window) ─────────────────
        final planId = await db.into(db.dailyPlans).insert(
          DailyPlansCompanion.insert(
            planDate: '2026-06-23',
            planJson: '{"sessions":[{"type":"cardio"}]}',
            generatedAt: now,
            createdAt: now,
            isCompleted: const Value(true),
          ),
        );

        // ── seed SessionLogs (FK → DailyPlans) ────────────────────────────
        final logId = await db.into(db.sessionLogs).insert(
          SessionLogsCompanion.insert(
            dailyPlanId: planId,
            sessionIndex: 0,
            completedAt: now,
            createdAt: now,
            abandoned: const Value(false),
            elapsedSeconds: const Value(900),
            currentStepIndex: const Value(4),
          ),
        );

        // ── seed RpeFeedback (FK → Sessions AND SessionLogs) ───────────────
        final rpeId = await db.into(db.rpeFeedback).insert(
          RpeFeedbackCompanion.insert(
            sessionId: sessionId,
            sessionLogId: Value(logId),
            rpeValue: 7,
            recordedAt: now,
          ),
        );

        // ── seed BanditState ───────────────────────────────────────────────
        final banditId = await db.into(db.banditState).insert(
          BanditStateCompanion.insert(
            armWeightsJson: '{"cardio":0.4,"strength":0.3,"mobility":0.3}',
            updatedAt: now,
          ),
        );

        // ── seed BehavioralState ───────────────────────────────────────────
        final bsId = await db.into(db.behavioralState).insert(
          BehavioralStateCompanion.insert(
            currentState: 'active',
            streakCount: const Value(5),
            restingHr: const Value(62),
            stepCount: const Value(8000),
            recordedAt: now,
            updatedAt: now,
          ),
        );

        // ── seed UserProfile with all fields including installCohort ───────
        final profileId = await db.into(db.userProfile).insert(
          UserProfileCompanion.insert(
            fitnessGoal: const Value('cardio'),
            weeklySessionTarget: const Value(4),
            intensityPreference: const Value('medium'),
            environmentPreference: const Value('indoor'),
            availableTime: const Value('5-10'),
            physicalConstraints: const Value('none'),
            onboardingCompleted: const Value(true),
            disclaimerAccepted: const Value(true),
            installCohort: const Value('pre_v2'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // ── Export ─────────────────────────────────────────────────────────
        final snapshot = await sut.exportDriftSnapshot();

        expect((snapshot['userProfile'] as List), hasLength(1));
        expect((snapshot['sessions'] as List), hasLength(1));
        expect((snapshot['dailyPlans'] as List), hasLength(1));
        expect((snapshot['sessionLogs'] as List), hasLength(1));
        expect((snapshot['rpeFeedback'] as List), hasLength(1));
        expect((snapshot['banditState'] as List), hasLength(1));
        expect((snapshot['behavioralState'] as List), hasLength(1));

        // ── Clear and restore ──────────────────────────────────────────────
        await sut.restoreDriftSnapshot(snapshot);

        // ── Verify UserProfile — all fields including installCohort ────────
        final profiles = await db.select(db.userProfile).get();
        expect(profiles, hasLength(1));
        final p = profiles.single;
        expect(p.id, equals(profileId));
        expect(p.fitnessGoal, equals('cardio'));
        expect(p.weeklySessionTarget, equals(4));
        expect(p.intensityPreference, equals('medium'));
        expect(p.environmentPreference, equals('indoor'));
        expect(p.availableTime, equals('5-10'));
        expect(p.physicalConstraints, equals('none'));
        expect(p.onboardingCompleted, isTrue);
        expect(p.disclaimerAccepted, isTrue);
        expect(p.installCohort, equals('pre_v2'),
            reason: 'installCohort (grandfathering flag) must survive restore');
        expect(p.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
        expect(p.updatedAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));

        // ── Verify Sessions ────────────────────────────────────────────────
        final sessions = await db.select(db.sessions).get();
        expect(sessions, hasLength(1));
        final s = sessions.single;
        expect(s.id, equals(sessionId));
        expect(s.sessionType, equals('cardio'));
        expect(s.intensity, equals(6));
        expect(s.durationSeconds, equals(900));
        expect(s.abandoned, isFalse);
        expect(s.completedAt!.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
        expect(s.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));

        // ── Verify DailyPlans ──────────────────────────────────────────────
        final plans = await db.select(db.dailyPlans).get();
        expect(plans, hasLength(1));
        final pl = plans.single;
        expect(pl.id, equals(planId));
        expect(pl.planDate, equals('2026-06-23'));
        expect(pl.planJson, contains('cardio'));
        expect(pl.isCompleted, isTrue);
        expect(pl.generatedAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
        expect(pl.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));

        // ── Verify SessionLogs (FK integrity) ─────────────────────────────
        final logs = await db.select(db.sessionLogs).get();
        expect(logs, hasLength(1));
        final l = logs.single;
        expect(l.id, equals(logId));
        expect(l.dailyPlanId, equals(planId),
            reason: '16.3 P1: explicit id insertion preserves FK integrity');
        expect(l.sessionIndex, equals(0));
        expect(l.abandoned, isFalse);
        expect(l.elapsedSeconds, equals(900));
        expect(l.currentStepIndex, equals(4));
        expect(l.completedAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
        expect(l.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));

        // ── Verify RpeFeedback ─────────────────────────────────────────────
        final rpes = await db.select(db.rpeFeedback).get();
        expect(rpes, hasLength(1));
        final r = rpes.single;
        expect(r.id, equals(rpeId));
        expect(r.sessionId, equals(sessionId));
        expect(r.sessionLogId, equals(logId));
        expect(r.rpeValue, equals(7));
        expect(r.recordedAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));

        // ── Verify BanditState ─────────────────────────────────────────────
        final bandits = await db.select(db.banditState).get();
        expect(bandits, hasLength(1));
        final b = bandits.single;
        expect(b.id, equals(banditId));
        expect(b.armWeightsJson, contains('cardio'));
        expect(b.updatedAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));

        // ── Verify BehavioralState ─────────────────────────────────────────
        final bss = await db.select(db.behavioralState).get();
        expect(bss, hasLength(1));
        final bs = bss.single;
        expect(bs.id, equals(bsId));
        expect(bs.currentState, equals('active'));
        expect(bs.streakCount, equals(5));
        expect(bs.restingHr, equals(62));
        expect(bs.stepCount, equals(8000));
        expect(bs.recordedAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
        expect(bs.updatedAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
      },
    );

    test(
      '16.3-DS-005b: restore clears existing rows before inserting snapshot data',
      () async {
        // Pre-existing row
        await db.into(db.userProfile).insert(
          UserProfileCompanion.insert(
            weeklySessionTarget: const Value(5),
            onboardingCompleted: const Value(true),
            disclaimerAccepted: const Value(true),
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );

        // Restore a snapshot with a different weekly target
        final snapshot = {
          'userProfile': [
            {
              'id': 99,
              'fitnessGoal': 'cardio',
              'weeklySessionTarget': 2,
              'intensityPreference': null,
              'environmentPreference': null,
              'availableTime': null,
              'physicalConstraints': null,
              'onboardingCompleted': true,
              'disclaimerAccepted': true,
              'createdAt': DateTime.utc(2026, 6, 1).toIso8601String(),
              'updatedAt': DateTime.utc(2026, 6, 1).toIso8601String(),
            },
          ],
          'sessions': <dynamic>[],
          'sessionLogs': <dynamic>[],
          'rpeFeedback': <dynamic>[],
          'banditState': <dynamic>[],
          'behavioralState': <dynamic>[],
          'dailyPlans': <dynamic>[],
        };

        await sut.restoreDriftSnapshot(snapshot);

        final profiles = await db.select(db.userProfile).get();
        expect(profiles, hasLength(1));
        expect(profiles.single.weeklySessionTarget, equals(2));
      },
    );
  });
}
