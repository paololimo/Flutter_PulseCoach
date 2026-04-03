import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

abstract class SensorRepository {
  /// Samples accelerometer for ~1 second, classifies activity.
  /// Returns [SensorFailure] if sensor unavailable or stream errors.
  Future<Either<Failure, ActivityLevel>> fetchActivityLevel();
}
