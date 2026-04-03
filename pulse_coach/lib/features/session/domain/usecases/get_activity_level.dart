import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
import 'package:pulse_coach/features/session/domain/repositories/sensor_repository.dart';

/// Samples the accelerometer and classifies user activity level.
/// Returns [ActivityLevel] on success, [SensorFailure] if accelerometer unavailable.
/// On failure, Story 5.1 (StateVector) should treat activityLevel as null — do NOT surface error to user.
@injectable
class GetActivityLevel {
  GetActivityLevel(this._repository);
  final SensorRepository _repository;

  Future<Either<Failure, ActivityLevel>> call() =>
      _repository.fetchActivityLevel();
}
