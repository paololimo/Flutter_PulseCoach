import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/weather/data/datasources/weather_local_data_source.dart';

class _ThrowingWeatherCacheDao extends Fake implements WeatherCacheDao {
  _ThrowingWeatherCacheDao({
    this.throwOnRead = false,
    this.throwOnWrite = false,
  });

  final bool throwOnRead;
  final bool throwOnWrite;

  @override
  Future<WeatherCacheData?> getLatestCache() async {
    if (throwOnRead) {
      throw StateError('read failed');
    }
    return null;
  }

  @override
  Future<void> replaceCache(WeatherCacheCompanion entry) async {
    if (throwOnWrite) {
      throw StateError('write failed');
    }
  }
}

void main() {
  group('WeatherLocalDataSource', () {
    late AppDatabase db;
    late WeatherLocalDataSource sut;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sut = WeatherLocalDataSource(db.weatherCacheDao);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      '4.2-LOCAL-001: getCachedWeather returns null when cache is empty',
      () async {
        final result = await sut.getCachedWeather();

        expect(result, isNull);
      },
    );

    test(
      '4.2-LOCAL-002: cacheWeather persists a snapshot mapped back to WeatherContext',
      () async {
        final cachedAt = DateTime.utc(2026, 5, 18, 9, 30);

        await sut.cacheWeather(
          latitude: 45.46,
          longitude: 9.19,
          temperature: 21.5,
          precipitationProbability: 35,
          aqiValue: 62,
          cachedAt: cachedAt,
        );

        final result = await sut.getCachedWeather();

        expect(result, isNotNull);
        expect(result!.temperature, 21.5);
        expect(result.precipitationProbability, 35);
        expect(result.aqiValue, 62);
        expect(
          result.cachedAt.millisecondsSinceEpoch,
          cachedAt.millisecondsSinceEpoch,
        );
      },
    );

    test(
      '4.2-LOCAL-003: cacheWeather replaces older rows with the latest snapshot',
      () async {
        final oldCachedAt = DateTime.utc(2026, 5, 18, 8);
        final newCachedAt = DateTime.utc(2026, 5, 18, 9);

        await sut.cacheWeather(
          latitude: 45.46,
          longitude: 9.19,
          temperature: 18,
          precipitationProbability: 10,
          aqiValue: 40,
          cachedAt: oldCachedAt,
        );
        await sut.cacheWeather(
          latitude: 45.46,
          longitude: 9.19,
          temperature: 24,
          precipitationProbability: 55,
          aqiValue: 80,
          cachedAt: newCachedAt,
        );

        final result = await sut.getCachedWeather();
        final rows = await db.select(db.weatherCache).get();

        expect(rows, hasLength(1));
        expect(result!.temperature, 24);
        expect(
          result.cachedAt.millisecondsSinceEpoch,
          newCachedAt.millisecondsSinceEpoch,
        );
      },
    );

    test(
      '4.2-LOCAL-004: getCachedWeather wraps DAO failures in CacheException',
      () async {
        final failingSut = WeatherLocalDataSource(
          _ThrowingWeatherCacheDao(throwOnRead: true),
        );

        expect(
          failingSut.getCachedWeather,
          throwsA(
            isA<CacheException>().having(
              (error) => error.message,
              'message',
              contains('Failed to read weather cache'),
            ),
          ),
        );
      },
    );

    test(
      '4.2-LOCAL-005: cacheWeather wraps DAO failures in CacheException',
      () async {
        final failingSut = WeatherLocalDataSource(
          _ThrowingWeatherCacheDao(throwOnWrite: true),
        );

        expect(
          () => failingSut.cacheWeather(
            latitude: 45.46,
            longitude: 9.19,
            temperature: 21,
            precipitationProbability: 35,
            aqiValue: 62,
            cachedAt: DateTime.utc(2026, 5, 18, 9),
          ),
          throwsA(
            isA<CacheException>().having(
              (error) => error.message,
              'message',
              contains('Failed to write weather cache'),
            ),
          ),
        );
      },
    );
  });
}
