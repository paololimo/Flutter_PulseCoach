import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/behavioral_state_dao.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/data/datasources/health_data_source.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';
import 'package:pulse_coach/features/session/domain/repositories/health_repository.dart';

@Injectable(as: HealthRepository)
class HealthRepositoryImpl implements HealthRepository {
  final HealthDataSource _dataSource;
  final BehavioralStateDao _dao;

  HealthRepositoryImpl(this._dataSource, this._dao);

  @override
  Future<Either<Failure, HealthData>> fetchHealthData() async {
    try {
      final data = await _dataSource.fetchHealthData();
      return Right(data);
    } on SensorException catch (e) {
      return Left(SensorFailure(e.message));
    } catch (e) {
      return Left(SensorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthData(HealthData data) async {
    try {
      final now = DateTime.now();
      await _dao.insertState(
        BehavioralStateCompanion(
          currentState: const Value('Active'), // placeholder; state machine in Epic 5
          restingHr: Value(data.restingHr),
          stepCount: Value(data.stepCount),
          recordedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
