import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/session/domain/entities/sensor_context.dart';
import 'package:pulse_coach/features/session/domain/usecases/get_activity_level.dart';
import 'package:pulse_coach/features/session/domain/usecases/get_health_data.dart';

/// Aggregates all sensor inputs into a single [SensorContext].
///
/// NEVER returns a failure — sensor unavailability is a valid first-class state,
/// not an error. Failures from GetHealthData and GetActivityLevel are silently
/// converted to null fields. The caller receives a fully populated or partially/fully
/// null SensorContext and must handle RPE-only mode accordingly.
///
/// This is the single entry point for Epic 5 (StateVector) to get sensor data.
@injectable
class GetSensorContext {
  GetSensorContext(this._getHealthData, this._getActivityLevel);

  final GetHealthData _getHealthData;
  final GetActivityLevel _getActivityLevel;

  Future<SensorContext> call() async {
    try {
      // Launch both futures before awaiting — preserves concurrency with static types
      final healthFuture = _getHealthData();
      final activityFuture = _getActivityLevel();

      final healthResult = await healthFuture;
      final activityResult = await activityFuture;

      return SensorContext(
        restingHr: healthResult.fold((_) => null, (d) => d.restingHr),
        stepCount: healthResult.fold((_) => null, (d) => d.stepCount),
        activityLevel: activityResult.fold((_) => null, (l) => l),
      );
    } catch (_) {
      // Unhandled exception from a dependency — degrade to RPE-only
      return const SensorContext();
    }
  }
}
