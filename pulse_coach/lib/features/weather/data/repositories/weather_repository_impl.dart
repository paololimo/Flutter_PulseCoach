import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/utils/location_service.dart';
import 'package:pulse_coach/features/weather/data/datasources/weather_local_data_source.dart';
import 'package:pulse_coach/features/weather/data/datasources/weather_remote_data_source.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';
import 'package:pulse_coach/features/weather/domain/repositories/weather_repository.dart';

@Injectable(as: WeatherRepository)
class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl(this._remote, this._local, this._locationService);

  final WeatherRemoteDataSource _remote;
  final WeatherLocalDataSource _local;
  final LocationService _locationService;

  @override
  Future<Either<Failure, WeatherContext>> getWeatherContext() async {
    // Step 1: Get city-level coordinates
    final locationResult = await _locationService.getCityLevelCoordinates();
    if (locationResult.isLeft()) {
      return locationResult.fold(
        (failure) => Left(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final (lat, lon) = locationResult.getOrElse(() => throw StateError('unreachable'));

    // Step 2: Check cache TTL — return immediately if valid (< 1 hour)
    WeatherContext? cached;
    try {
      cached = await _local.getCachedWeather();
    } on CacheException {
      cached = null; // DB read failure is non-fatal — fall through to network
    }

    if (cached != null && _isCacheValid(cached.cachedAt)) {
      return Right(cached); // AC1: valid cache hit — no network call
    }

    // Step 3: Cache is stale or missing — fetch from network
    WeatherContext fresh;
    try {
      final (weather, aqi) = await _remote.fetchWeatherAndAqi(
        latitude: lat,
        longitude: lon,
      );

      fresh = WeatherContext(
        temperature: weather.temperature,
        precipitationProbability: weather.precipitationProbability,
        aqiValue: aqi.europeanAqi,
        cachedAt: DateTime.now().toUtc(),
      );
    } on ServerException catch (e) {
      // AC3: API unreachable — return stale cache if available
      if (cached != null) {
        return Right(cached); // stale data returned; Story 5.1 checks cachedAt age
      }
      return Left(ServerFailure(e.message));
    }

    // Step 4: Persist to cache — failure is non-fatal, fresh data still returned
    try {
      await _local.cacheWeather(
        latitude: lat,
        longitude: lon,
        temperature: fresh.temperature,
        precipitationProbability: fresh.precipitationProbability,
        aqiValue: fresh.aqiValue,
        cachedAt: fresh.cachedAt,
      );
    } on CacheException {
      // Cache write failed — non-fatal, return fresh data anyway
    }

    return Right(fresh); // AC2: fresh data fetched and cached
  }

  /// Cache is valid when fetched less than 1 hour ago.
  bool _isCacheValid(DateTime cachedAt) =>
      DateTime.now().toUtc().difference(cachedAt) < const Duration(hours: 1);
}
