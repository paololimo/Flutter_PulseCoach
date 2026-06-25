import 'package:pulse_coach/ai/safety/group_constraint.dart';
import 'package:pulse_coach/ai/safety/participant_profile.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';

/// Deterministic group constraint resolver (FR70, ARCH24).
///
/// Stateless — no constructor parameters. Every call computes fresh from
/// the input list. No Flutter dependency; no DI registration; no isolate
/// boundary crossing.
///
/// Per-user v1 FR9/FR24 safety caps are pre-computed by the caller and
/// stored in [ParticipantProfile.safetyCapIntensity]. This class only applies
/// the group-level aggregation rules on top.
class GroupConstraintResolver {
  const GroupConstraintResolver();

  /// Computes the [GroupConstraint] for [participants].
  ///
  /// Throws [ArgumentError] if [participants] is empty.
  GroupConstraint resolve(List<ParticipantProfile> participants) {
    if (participants.isEmpty) {
      throw ArgumentError('participants must not be empty');
    }

    SessionIntensity? ceiling;
    for (final p in participants) {
      ceiling = _strictest(ceiling, p.safetyCapIntensity);
    }

    final fitnessLevel =
        participants.any((p) => p.fitnessLevel == 'low') ? 'low' : 'medium';

    final movementExclusions = Set<String>.unmodifiable(
        participants.expand((p) => p.movementExclusions));

    final durationMinutes = participants
        .map((p) => p.availableTimeMinutes)
        .reduce((a, b) => a < b ? a : b);

    return GroupConstraint(
      intensityCeiling: ceiling,
      fitnessLevel: fitnessLevel,
      movementExclusions: movementExclusions,
      durationMinutes: durationMinutes,
    );
  }

  /// Returns the stricter of [a] and [b].
  ///
  /// Strictness: low (0) < medium (1) < high (2) < null (3, least strict).
  /// Null means no cap — the other value always wins over null.
  SessionIntensity? _strictest(SessionIntensity? a, SessionIntensity? b) {
    if (a == null) return b;
    if (b == null) return a;
    return _rank(a) <= _rank(b) ? a : b;
  }

  /// Exhaustive rank — adding a new [SessionIntensity] value must fail-compile
  /// here (safety-layer discipline, same as in SafetyRules).
  int _rank(SessionIntensity i) => switch (i) {
        SessionIntensity.low => 0,
        SessionIntensity.medium => 1,
        SessionIntensity.high => 2,
      };
}
