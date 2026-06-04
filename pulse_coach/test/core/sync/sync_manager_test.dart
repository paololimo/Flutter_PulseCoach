import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';

import 'sync_manager_test.mocks.dart';

@GenerateMocks([Connectivity])
void main() {
  late AppDatabase db;
  late MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late SyncManager manager;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    connectivity = MockConnectivity();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();
    when(
      connectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    // Default offline so enqueue's opportunistic drain stays inert unless a
    // test explicitly stubs an online result.
    when(
      connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
    manager = SyncManager(db.syncQueueDao, connectivity);
  });

  tearDown(() async {
    await manager.stop();
    await connectivityController.close();
    await db.close();
  });

  group('SyncManager', () {
    test(
      '13.2-SYNC-001: enqueue stores entry with correct initial fields',
      () async {
        final before = DateTime.now().toUtc();

        await manager.enqueue('session_completed', '{"id":1}');

        final after = DateTime.now().toUtc();
        final entries = await db.syncQueueDao.getPendingEntries();
        expect(entries, hasLength(1));
        expect(entries.single.eventType, 'session_completed');
        expect(entries.single.payload, '{"id":1}');
        expect(entries.single.retryCount, 0);
        expect(
          entries.single.createdAt.toUtc(),
          _withinWindow(before, after, tolerance: const Duration(seconds: 1)),
        );
      },
    );

    test('13.2-SYNC-002: processQueue invokes handlers oldest-first', () async {
      final baseTime = DateTime.utc(2026, 6, 4, 9);
      await _seedEntry(
        db,
        eventType: 'newest',
        createdAt: baseTime.add(const Duration(minutes: 2)),
      );
      await _seedEntry(db, eventType: 'oldest', createdAt: baseTime);
      await _seedEntry(
        db,
        eventType: 'middle',
        createdAt: baseTime.add(const Duration(minutes: 1)),
      );
      final processed = <String>[];
      for (final eventType in ['oldest', 'middle', 'newest']) {
        manager.registerHandler(eventType, (payload) async {
          processed.add(eventType);
          return const Right(unit);
        });
      }

      await manager.processQueue();

      expect(processed, ['oldest', 'middle', 'newest']);
    });

    test('13.2-SYNC-003: processQueue skips future retry entries', () async {
      await _seedEntry(
        db,
        eventType: 'rpe_feedback',
        createdAt: DateTime.utc(2026, 6, 4, 9),
        nextRetryAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
      );
      var called = false;
      manager.registerHandler('rpe_feedback', (payload) async {
        called = true;
        return const Right(unit);
      });

      await manager.processQueue();

      final entries = await db.syncQueueDao.getPendingEntries();
      expect(called, isFalse);
      expect(entries, hasLength(1));
    });

    test(
      '13.2-SYNC-004: failed handler schedules first retry with backoff',
      () async {
        await _seedEntry(
          db,
          eventType: 'session_completed',
          createdAt: DateTime.utc(2026, 6, 4, 9),
        );
        manager.registerHandler(
          'session_completed',
          (payload) async => const Left(ServerFailure('offline')),
        );
        final before = DateTime.now().toUtc();

        await manager.processQueue();

        final after = DateTime.now().toUtc();
        final entry = (await db.syncQueueDao.getPendingEntries()).single;
        expect(entry.retryCount, 1);
        expect(
          entry.nextRetryAt!.toUtc(),
          _withinWindow(
            before.add(const Duration(minutes: 1)),
            after.add(const Duration(minutes: 1)),
            tolerance: const Duration(seconds: 5),
          ),
        );
      },
    );

    test('13.2-SYNC-005: retry delay caps at 60 minutes', () async {
      await _seedEntry(
        db,
        eventType: 'session_completed',
        createdAt: DateTime.utc(2026, 6, 4, 9),
        retryCount: 6,
      );
      manager.registerHandler(
        'session_completed',
        (payload) async => const Left(ServerFailure('offline')),
      );
      final before = DateTime.now().toUtc();

      await manager.processQueue();

      final after = DateTime.now().toUtc();
      final entry = (await db.syncQueueDao.getPendingEntries()).single;
      expect(entry.retryCount, 7);
      expect(
        entry.nextRetryAt!.toUtc(),
        _withinWindow(
          before.add(const Duration(minutes: 60)),
          after.add(const Duration(minutes: 60)),
          tolerance: const Duration(seconds: 10),
        ),
      );
    });

    test('13.2-SYNC-006: successful handler deletes entry', () async {
      await _seedEntry(
        db,
        eventType: 'session_completed',
        createdAt: DateTime.utc(2026, 6, 4, 9),
      );
      manager.registerHandler(
        'session_completed',
        (payload) async => const Right(unit),
      );

      await manager.processQueue();

      expect(await db.syncQueueDao.getPendingEntries(), isEmpty);
    });

    test(
      '13.2-SYNC-007: unknown event type is skipped and not deleted',
      () async {
        await _seedEntry(
          db,
          eventType: 'unknown_type',
          createdAt: DateTime.utc(2026, 6, 4, 9),
        );

        await manager.processQueue();

        final entries = await db.syncQueueDao.getPendingEntries();
        expect(entries, hasLength(1));
        expect(entries.single.eventType, 'unknown_type');
      },
    );

    test(
      '13.2-SYNC-008: start processes immediately when already connected',
      () async {
        await _seedEntry(
          db,
          eventType: 'session_completed',
          createdAt: DateTime.utc(2026, 6, 4, 9),
        );
        manager.registerHandler(
          'session_completed',
          (payload) async => const Right(unit),
        );
        when(
          connectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        await manager.start();

        expect(await db.syncQueueDao.getPendingEntries(), isEmpty);
      },
    );

    test(
      '13.2-SYNC-009: entry is dead-lettered after max retries',
      () async {
        // retryCount 9 → next failure is the 10th attempt → dropped.
        await _seedEntry(
          db,
          eventType: 'session_completed',
          createdAt: DateTime.utc(2026, 6, 4, 9),
          retryCount: 9,
        );
        manager.registerHandler(
          'session_completed',
          (payload) async => const Left(ServerFailure('offline')),
        );

        await manager.processQueue();

        expect(await db.syncQueueDao.getPendingEntries(), isEmpty);
      },
    );

    test(
      '13.2-SYNC-010: handler that throws schedules a retry (not aborted)',
      () async {
        await _seedEntry(
          db,
          eventType: 'session_completed',
          createdAt: DateTime.utc(2026, 6, 4, 9),
        );
        manager.registerHandler(
          'session_completed',
          (payload) async => throw Exception('boom'),
        );

        await manager.processQueue();

        final entry = (await db.syncQueueDao.getPendingEntries()).single;
        expect(entry.retryCount, 1);
        expect(entry.nextRetryAt, isNotNull);
      },
    );

    test('13.2-SYNC-011: enqueue drains immediately when online', () async {
      when(
        connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      var processed = false;
      manager.registerHandler('session_completed', (payload) async {
        processed = true;
        return const Right(unit);
      });

      await manager.enqueue('session_completed', '{"id":1}');
      // enqueue fires processQueue via unawaited; allow the async drain to run.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(processed, isTrue);
      expect(await db.syncQueueDao.getPendingEntries(), isEmpty);
    });
  });
}

Future<int> _seedEntry(
  AppDatabase db, {
  required String eventType,
  required DateTime createdAt,
  String payload = '{}',
  int retryCount = 0,
  DateTime? nextRetryAt,
}) {
  return db.syncQueueDao.insertEntry(
    SyncQueueCompanion.insert(
      eventType: eventType,
      payload: payload,
      createdAt: createdAt,
      retryCount: Value(retryCount),
      nextRetryAt: Value(nextRetryAt),
    ),
  );
}

Matcher _withinWindow(
  DateTime earliest,
  DateTime latest, {
  required Duration tolerance,
}) {
  return predicate<DateTime>((actual) {
    return !actual.isBefore(earliest.subtract(tolerance)) &&
        !actual.isAfter(latest.add(tolerance));
  }, 'within ${tolerance.inSeconds}s of $earliest..$latest');
}
