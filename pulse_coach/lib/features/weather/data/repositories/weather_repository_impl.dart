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

    try {
      // Step 2: Fetch from both Open-Meteo APIs in parallel
      final (weather, aqi) = await _remote.fetchWeatherAndAqi(
        latitude: lat,
        longitude: lon,
      );

      final now = DateTime.now().toUtc();

      // Step 3: Persist to drift cache (TTL check added in Story 4.2)
      await _local.cacheWeather(
        latitude: lat,
        longitude: lon,
        temperature: weather.temperature,
        precipitationProbability: weather.precipitationProbability,
        aqiValue: aqi.europeanAqi,
        cachedAt: now,
      );

      // Step 4: Return domain entity
      return Right(WeatherContext(
        temperature: weather.temperature,
        precipitationProbability: weather.precipitationProbability,
        aqiValue: aqi.europeanAqi,
        cachedAt: now,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(ServerFailure('Cache write failed: ${e.message}'));
    }
  }
}
