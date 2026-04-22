import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state_machine.dart';

/// Deterministic safety override layer between behavioral state machine and bandit.
///
/// Merges constraints from three independent sources (most restrictive wins):
///   1. Behavioral state (FR24): BehavioralStateMachine.constraintsForState()
///   2. Direct RPE signal (FR9): last-2-avg > 8 caps maxIntensity at medium
///   3. Air quality (FR8): AqiLevel.high blocks all outdoor sessions
///
/// Stateless — every call derives fresh constraints from the StateVector snapshot.
/// Called by GenerateDailyPlan use case (Story 5.5) AFTER state machine evaluation.
/// The BanditEngine (Story 5.4) CANNOT override the output of this class.
class SafetyRules {
  final BehavioralStateMachine _machine;

  const SafetyRules(this._machine);

  /// Applies all safety rules to [stateVector] and returns merged constraints.
  ///
  /// Merge semantics:
  ///   - maxIntensity: strictest wins across state cap and RPE-derived cap
  ///     (low < medium < null, where null = no cap).
  ///   - maxSessionCount: taken entirely from `constraintsForState()`;
  ///     no rule in Story 5.3 modifies it.
  ///   - outdoorAllowed: logical AND of state constraint and AQI rule
  ///     (false if AQI is high OR state forbids outdoor).
  SafetyConstraints apply(StateVector stateVector) {
    final stateConstraints =
        _machine.constraintsForState(stateVector.currentState);

    final maxIntensity = _mergedIntensity(
      stateConstraints.maxIntensity,
      stateVector.rpeHistory,
    );
    // Exhaustive switch: adding a new AqiLevel value must force an explicit
    // decision here (safety layer — FR8 — must fail-compile, not fail-open).
    final aqiAllowsOutdoor = switch (stateVector.aqiLevel) {
      AqiLevel.low => true,
      AqiLevel.high => false,
    };
    final outdoorAllowed = aqiAllowsOutdoor && stateConstraints.outdoorAllowed;

    return SafetyConstraints(
      maxIntensity: maxIntensity,
      maxSessionCount: stateConstraints.maxSessionCount,
      outdoorAllowed: outdoorAllowed,
    );
  }

  /// Merges the behavioral-state intensity cap with the RPE-derived cap.
  SessionIntensity? _mergedIntensity(
    SessionIntensity? stateMaxIntensity,
    List<int> rpeHistory,
  ) {
    SessionIntensity? rpeCapIntensity;
    if (_lastTwoAvg(rpeHistory) > 8.0) {
      rpeCapIntensity = SessionIntensity.medium;
    }
    return _strictest(stateMaxIntensity, rpeCapIntensity);
  }

  /// Returns the stricter of [a] and [b].
  /// Strictness order (most → least): low, medium, high, null (no cap).
  SessionIntensity? _strictest(SessionIntensity? a, SessionIntensity? b) {
    if (a == null) return b;
    if (b == null) return a;
    return _strictnessRank(a) <= _strictnessRank(b) ? a : b;
  }

  /// Exhaustive rank: 0 = strictest. Adding a new SessionIntensity value must
  /// fail-compile here (safety layer — ranking must be explicit).
  int _strictnessRank(SessionIntensity i) => switch (i) {
        SessionIntensity.low => 0,
        SessionIntensity.medium => 1,
        SessionIntensity.high => 2,
      };

  /// Average of the last 2 RPE values. Returns 0.0 when fewer than 2 entries.
  double _lastTwoAvg(List<int> rpe) {
    if (rpe.length < 2) return 0.0;
    return (rpe[rpe.length - 1] + rpe[rpe.length - 2]) / 2.0;
  }
}
