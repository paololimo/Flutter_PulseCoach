import 'package:meta/meta.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';

/// Per-participant inputs for GroupConstraintResolver.
///
/// [safetyCapIntensity] is the pre-computed individual intensity cap derived
/// by applying v1 SafetyRules (FR9/FR24) to this participant's StateVector.
/// Null means no individual cap (participant is in active state with no RPE
/// pressure).
///
/// [fitnessLevel] mirrors UserProfile.fitnessLevel: 'low' | 'medium'.
///
/// [movementExclusions] is the set of movement constraints from
/// UserProfile.physicalConstraints. 'none' → empty set;
/// 'knee' → {'knee'}, 'back' → {'back'}, 'indoor' → {'indoor'}.
///
/// [availableTimeMinutes] is the session-duration budget for this participant.
/// Derived from UserProfile.availableTime: 'short' → 20, 'long' → 45.
@immutable
class ParticipantProfile {
  final SessionIntensity? safetyCapIntensity;
  final String fitnessLevel;
  final Set<String> movementExclusions;
  final int availableTimeMinutes;

  const ParticipantProfile({
    required this.safetyCapIntensity,
    required this.fitnessLevel,
    required this.movementExclusions,
    required this.availableTimeMinutes,
  });
}
