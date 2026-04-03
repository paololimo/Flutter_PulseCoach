import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

/// Aggregated sensor snapshot used by StateVector (Story 5.1).
/// All fields are nullable — null means data unavailable (sensor failed or permission denied).
/// When all fields are null, the system operates in RPE-only mode.
class SensorContext {
  final int? restingHr;
  final int? stepCount;
  final ActivityLevel? activityLevel;

  const SensorContext({
    this.restingHr,
    this.stepCount,
    this.activityLevel,
  });

  /// True when NO sensor data is available — RPE-only mode.
  bool get isRpeOnly =>
      restingHr == null && stepCount == null && activityLevel == null;

  /// True when at least one sensor field is populated.
  bool get hasSensorData => !isRpeOnly;
}
