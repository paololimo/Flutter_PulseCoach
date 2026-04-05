import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';

abstract class WeatherRepository {
  /// Fetches current weather and AQI, persists to cache, returns domain entity.
  /// Returns [Left(ServerFailure)] if API call fails.
  /// Returns [Left(LocationFailure)] if coordinates are unavailable.
  Future<Either<Failure, WeatherContext>> getWeatherContext();
}
