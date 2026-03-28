import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<List<SyncQueueEntry>> getPendingEntries() =>
      (select(syncQueue)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<int> insertEntry(SyncQueueCompanion entry) =>
      into(syncQueue).insert(entry);

  Future<bool> updateEntry(SyncQueueEntry entry) =>
      update(syncQueue).replace(entry);

  Future<int> deleteEntry(int id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();
}
