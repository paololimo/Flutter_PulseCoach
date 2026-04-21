import 'package:freezed_annotation/freezed_annotation.dart';

part 'safety_constraints.freezed.dart';
part 'safety_constraints.g.dart';

/// Categorical session intensity for safety filtering.
/// Maps to the DB `intensity` int column (1–10):
///   low = 1–3, medium = 4–7, high = 8–10 (Story 5.3 enforces the mapping).
enum SessionIntensity { low, medium, high }

/// Output of the SafetyRules engine (Story 5.3).
///
/// [maxIntensity] null = no intensity restriction (normal state).
/// [maxSessionCount] capped at 2 when state is AtRisk/Recovering (FR24).
/// [outdoorAllowed] false when AQI >= 100 (FR8).
///
/// Passed to BanditEngine.selectSessions() (Story 5.4) to filter candidates.
@freezed
abstract class SafetyConstraints with _$SafetyConstraints {
  const factory SafetyConstraints({
    required SessionIntensity? maxIntensity,
    required int maxSessionCount,
    required bool outdoorAllowed,
  }) = _SafetyConstraints;

  factory SafetyConstraints.fromJson(Map<String, dynamic> json) =>
      _$SafetyConstraintsFromJson(json);
}

/// No restrictions — used as baseline when user state is Active and AQI is low.
const SafetyConstraints noConstraints = SafetyConstraints(
  maxIntensity: null,
  maxSessionCount: 3,
  outdoorAllowed: true,
);
