import 'package:drift/drift.dart';
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

  group('SyncQueueDao', () {
    test(
      '[P1] 1.4-UNIT-014: pending entries are FIFO and retry state can be updated then deleted',
      () async {
        final baseTime = DateTime.utc(2026, 5, 15, 8);

        final newestId = await db.syncQueueDao.insertEntry(
          SyncQueueCompanion.insert(
            eventType: 'session_completed',
            payload: '{"id":3}',
            createdAt: baseTime.add(const Duration(minutes: 2)),
          ),
        );
        final oldestId = await db.syncQueueDao.insertEntry(
          SyncQueueCompanion.insert(
            eventType: 'rpe_submitted',
            payload: '{"id":1}',
            createdAt: baseTime,
          ),
        );
        final middleId = await db.syncQueueDao.insertEntry(
          SyncQueueCompanion.insert(
            eventType: 'profile_updated',
            payload: '{"id":2}',
            createdAt: baseTime.add(const Duration(minutes: 1)),
          ),
        );

        final pending = await db.syncQueueDao.getPendingEntries();

        expect(
          pending.map((entry) => entry.id),
          orderedEquals([oldestId, middleId, newestId]),
        );
        expect(pending.first.retryCount, 0);

        final retryAt = baseTime.add(const Duration(minutes: 30));
        final middleEntry = pending.singleWhere(
          (entry) => entry.id == middleId,
        );
        final updated = await db.syncQueueDao.updateEntry(
          middleEntry.copyWith(retryCount: 2, nextRetryAt: Value(retryAt)),
        );

        expect(updated, isTrue);

        final afterUpdate = await db.syncQueueDao.getPendingEntries();
        final retried = afterUpdate.singleWhere(
          (entry) => entry.id == middleId,
        );
        expect(retried.retryCount, 2);
        expect(retried.nextRetryAt!.toUtc(), retryAt);

        final deletedCount = await db.syncQueueDao.deleteEntry(oldestId);
        final afterDelete = await db.syncQueueDao.getPendingEntries();

        expect(deletedCount, 1);
        expect(afterDelete.map((entry) => entry.id), [middleId, newestId]);
      },
    );
  });
}
