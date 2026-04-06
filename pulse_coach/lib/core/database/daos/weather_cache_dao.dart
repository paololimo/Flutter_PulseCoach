import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/tables/weather_cache_table.dart';

part 'weather_cache_dao.g.dart';

@DriftAccessor(tables: [WeatherCache])
class WeatherCacheDao extends DatabaseAccessor<AppDatabase>
    with _$WeatherCacheDaoMixin {
  WeatherCacheDao(super.db);

  Future<WeatherCacheData?> getLatestCache() =>
      (select(weatherCache)
            ..orderBy([(t) => OrderingTerm.desc(t.cachedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertOrReplace(WeatherCacheCompanion entry) =>
      into(weatherCache).insertOnConflictUpdate(entry);

  Future<int> deleteAll() => delete(weatherCache).go();

  /// Replaces all cached rows with a single new entry inside a transaction.
  /// Readers on the same connection see either the old or new state, never partial.
  Future<void> replaceCache(WeatherCacheCompanion entry) =>
      transaction(() async {
        await delete(weatherCache).go();
        await into(weatherCache).insert(entry);
      });
}
