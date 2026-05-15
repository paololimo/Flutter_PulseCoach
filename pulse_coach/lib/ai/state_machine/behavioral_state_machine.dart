import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_transition.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';

/// Deterministic state machine that evaluates StateVector and returns the next
/// BehavioralState + an optional transition message.
///
/// Evaluation order matters — higher-priority transitions are checked first:
///   1. active → atRisk     (disengagement, checked before active→fatigued)
///   2. fatigued → atRisk   (structural risk, checked before recovery)
///   3. active → fatigued   (exertion signal)
///   4. atRisk/fatigued → recovering  (recovery signal)
///   5. recovering → active (full recovery)
///   (If no rule fires, current state is returned unchanged.)
///
/// Stateless: every call computes from scratch given the StateVector snapshot.
/// The CALLER (GenerateDailyPlan use case, Story 5.5) is responsible for
/// persisting the result via BehavioralStateDao.
class BehavioralStateMachine {
  const BehavioralStateMachine();

  /// Evaluate [stateVector] and return the resulting [BehavioralTransition].
  BehavioralTransition evaluate(StateVector stateVector) {
    final current = stateVector.currentState;
    final rpe = stateVector.rpeHistory;
    final missed = stateVector.missedSessions;
    final streak = stateVector.streak;

    // Rule 1: active → atRisk (disengagement — Q1 from 2026-05-15 decision)
    if (current == BehavioralState.active && missed >= 2) {
      return const BehavioralTransition(
        newState: BehavioralState.atRisk,
        transitionMessage:
            'Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi.',
      );
    }

    // Rule 2: fatigued → atRisk
    if (current == BehavioralState.fatigued && missed >= 2) {
      return const BehavioralTransition(
        newState: BehavioralState.atRisk,
        transitionMessage:
            'You\'ve been missing sessions. Scaling back to keep you safe.',
      );
    }

    // Rule 3: active → fatigued (needs last 2 RPE values)
    if (current == BehavioralState.active && _lastNAvg(rpe, 2) > 8.0) {
      return const BehavioralTransition(
        newState: BehavioralState.fatigued,
        transitionMessage: 'You\'ve been pushing hard. Taking it easier today.',
      );
    }

    // Rule 4: atRisk/fatigued → recovering (last 2 sessions RPE ≤ 7)
    if ((current == BehavioralState.atRisk ||
            current == BehavioralState.fatigued) &&
        rpe.length >= 2 &&
        rpe[rpe.length - 1] <= 7 &&
        rpe[rpe.length - 2] <= 7) {
      return const BehavioralTransition(
        newState: BehavioralState.recovering,
        transitionMessage:
            'Great work staying consistent. Gradually increasing intensity.',
      );
    }

    // Rule 5: recovering → active (3 sessions avg ≤ 6.5, streak ≥ 3)
    // Explicit rpe.length >= 3 guard: _lastNAvg returns 0.0 for insufficient
    // data, which would satisfy the <= 6.5 check incorrectly.
    if (current == BehavioralState.recovering &&
        rpe.length >= 3 &&
        streak >= 3 &&
        _lastNAvg(rpe, 3) <= 6.5) {
      return const BehavioralTransition(
        newState: BehavioralState.active,
        transitionMessage:
            'You\'re back on track! Ready for your regular routine.',
      );
    }

    // No transition — return current state with no message
    return BehavioralTransition(newState: current);
  }

  /// Returns the safety constraints implied by [state].
  ///
  /// Called by SafetyRules (Story 5.3) — centralises the FR24 mapping here
  /// so both SafetyRules and tests can reference a single source of truth.
  SafetyConstraints constraintsForState(BehavioralState state) {
    switch (state) {
      case BehavioralState.atRisk:
      case BehavioralState.recovering:
        return const SafetyConstraints(
          maxIntensity: SessionIntensity.low,
          maxSessionCount: 2,
          outdoorAllowed: true,
        );
      case BehavioralState.fatigued:
        return const SafetyConstraints(
          maxIntensity: SessionIntensity.medium,
          maxSessionCount: 3,
          outdoorAllowed: true,
        );
      case BehavioralState.active:
        return noConstraints;
    }
  }

  /// Computes the average of the last [n] values in [rpe].
  /// Returns 0.0 if [n] <= 0 or if [rpe] has fewer than [n] entries —
  /// i.e. not enough data to trigger a transition.
  double _lastNAvg(List<int> rpe, int n) {
    if (n <= 0 || rpe.length < n) return 0.0;
    final slice = rpe.sublist(rpe.length - n);
    return slice.reduce((a, b) => a + b) / slice.length;
  }
}
