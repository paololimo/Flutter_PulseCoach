import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';

@injectable
class WeatherLocalDataSource {
  WeatherLocalDataSource(this._dao);
  final WeatherCacheDao _dao;

  /// Reads latest cached entry. Returns null if no cache exists.
  /// Throws [CacheException] on DB error.
  Future<WeatherContext?> getCachedWeather() async {
    try {
      final row = await _dao.getLatestCache();
      if (row == null) return null;
      return WeatherContext(
        temperature: row.temperature,
        precipitationProbability: row.precipitationProbability,
        aqiValue: row.aqiValue,
        cachedAt: row.cachedAt,
      );
    } catch (e) {
      throw CacheException('Failed to read weather cache: $e');
    }
  }

  /// Persists weather snapshot to drift cache table.
  /// Throws [CacheException] on DB error.
  Future<void> cacheWeather({
    required double latitude,
    required double longitude,
    required double temperature,
    required double precipitationProbability,
    required int aqiValue,
    required DateTime cachedAt,
  }) async {
    try {
      await _dao.replaceCache(
        WeatherCacheCompanion.insert(
          latitude: latitude,
          longitude: longitude,
          temperature: temperature,
          precipitationProbability: precipitationProbability,
          aqiValue: aqiValue,
          cachedAt: cachedAt,
        ),
      );
    } catch (e) {
      throw CacheException('Failed to write weather cache: $e');
    }
  }
}
