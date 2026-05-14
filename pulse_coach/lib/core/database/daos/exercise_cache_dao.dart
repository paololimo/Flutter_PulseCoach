import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/exercise_cache_table.dart';

part 'exercise_cache_dao.g.dart';

@DriftAccessor(tables: [ExerciseCache])
class ExerciseCacheDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseCacheDaoMixin {
  ExerciseCacheDao(super.db);

  Future<ExerciseCacheData?> getByExerciseId(String id) => (select(
    exerciseCache,
  )..where((t) => t.exerciseId.equals(id))).getSingleOrNull();

  Future<int> insertOrReplace(ExerciseCacheCompanion entry) =>
      into(exerciseCache).insertOnConflictUpdate(entry);

  Future<List<ExerciseCacheData>> getAll() => select(exerciseCache).get();

  Future<void> insertOrReplaceBatch(List<ExerciseCacheCompanion> entries) =>
      batch((batch) => batch.insertAllOnConflictUpdate(exerciseCache, entries));

  Future<int> deleteAll() => delete(exerciseCache).go();
}
