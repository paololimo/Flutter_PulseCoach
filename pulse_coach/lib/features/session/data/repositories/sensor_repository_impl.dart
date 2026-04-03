import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/data/datasources/accelerometer_data_source.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
import 'package:pulse_coach/features/session/domain/repositories/sensor_repository.dart';

@Injectable(as: SensorRepository)
class SensorRepositoryImpl implements SensorRepository {
  final AccelerometerDataSource _dataSource;

  SensorRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, ActivityLevel>> fetchActivityLevel() async {
    try {
      final level = await _dataSource.fetchActivityLevel();
      return Right(level);
    } on SensorException catch (_) {
      return const Left(SensorFailure('Accelerometer unavailable'));
    } catch (_) {
      return const Left(SensorFailure('Accelerometer unavailable'));
    }
  }
}
