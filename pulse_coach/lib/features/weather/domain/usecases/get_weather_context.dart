import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';
import 'package:pulse_coach/features/weather/domain/repositories/weather_repository.dart';

@injectable
class GetWeatherContext {
  GetWeatherContext(this._repository);
  final WeatherRepository _repository;

  Future<Either<Failure, WeatherContext>> call() => _repository.getWeatherContext();
}
