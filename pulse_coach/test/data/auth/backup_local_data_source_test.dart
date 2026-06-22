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
