import 'package:meta/meta.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';

/// Deterministic group-level constraint computed by GroupConstraintResolver.
///
/// Derived from all participants' ParticipantProfiles via:
///   - [intensityCeiling] = min(safetyCapIntensity for all) (FR70, ARCH24)
///   - [fitnessLevel]     = lowest(fitnessLevel for all) (FR70)
///   - [movementExclusions] = union(movementExclusions for all) (FR70)
///   - [durationMinutes] = min(availableTimeMinutes for all) (FR70)
///
/// Null [intensityCeiling] means no intensity restriction for the group.
@immutable
class GroupConstraint {
  final SessionIntensity? intensityCeiling;
  final String fitnessLevel;
  final Set<String> movementExclusions;
  final int durationMinutes;

  const GroupConstraint({
    required this.intensityCeiling,
    required this.fitnessLevel,
    required this.movementExclusions,
    required this.durationMinutes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupConstraint &&
          intensityCeiling == other.intensityCeiling &&
          fitnessLevel == other.fitnessLevel &&
          _setsEqual(movementExclusions, other.movementExclusions) &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode => Object.hash(
        intensityCeiling,
        fitnessLevel,
        Object.hashAll(movementExclusions.toList()..sort()),
        durationMinutes,
      );

  static bool _setsEqual(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
