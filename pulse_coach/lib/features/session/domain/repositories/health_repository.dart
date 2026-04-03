import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';

abstract class HealthRepository {
  /// Requests permissions if not yet granted, then fetches HR + steps.
  /// Returns [SensorFailure] if permissions denied or Health API unavailable.
  Future<Either<Failure, HealthData>> fetchHealthData();

  /// Persists [HealthData] to [behavioral_state] table.
  Future<Either<Failure, void>> saveHealthData(HealthData data);
}
