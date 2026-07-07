import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/explainability/explanation_key.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

/// Rule-based explanation engine. Pure Dart — no Flutter imports (ARCH7).
///
/// Emits one locale-independent [ExplanationKey] per session by inspecting the
/// available signals in [StateVector] in priority order:
///   1. BehavioralState (Recovering / AtRisk / Fatigued) — highest priority
///   2. Biometric signals (restingHR, stepCount) — when available
///   3. RPE history — AC2 fallback for sensor-less mode
///   4. Streak / missed-sessions — motivational context
///   5. Session type — final fallback (always resolves to text, AC4)
///
/// The key is stored in `PlannedSession.explanation` (via [generate]) and
/// resolved to a localized string in the presentation layer, so the reasoning
/// text follows the user's selected locale (E7.5-T1).
class ExplanationGenerator {
  const ExplanationGenerator();

  /// Returns a `List<String>` of stored explanation-key values, one per
  /// session (same length as [sessions]). Each is a stable, non-empty key
  /// resolved to localized text at display time (AC4).
  List<String> generate({
    required StateVector stateVector,
    required List<PlannedSession> sessions,
  }) {
    return sessions.map((s) => _explain(stateVector, s).storageValue).toList();
  }

  ExplanationKey _explain(StateVector sv, PlannedSession session) {
    // AC3: Recovering → always communicate reduced intensity
    if (sv.currentState == BehavioralState.recovering) {
      return ExplanationKey.recovering;
    }

    // AtRisk → safety-first messaging
    if (sv.currentState == BehavioralState.atRisk) {
      if (sv.missedSessions >= 2) {
        return ExplanationKey.atRiskMissed;
      }
      return ExplanationKey.atRiskHighLoad;
    }

    // Fatigued → effort acknowledgment
    if (sv.currentState == BehavioralState.fatigued) {
      return ExplanationKey.fatigued;
    }

    // Active state — check biometric signals first (AC1)
    if (sv.restingHR != null && sv.restingHR! > 75) {
      return ExplanationKey.elevatedRestingHr;
    }

    if (sv.stepCount != null && sv.stepCount! < 3000) {
      return ExplanationKey.lowSteps;
    }

    if (sv.restingHR != null && sv.restingHR! <= 60 && sv.streak >= 1) {
      return ExplanationKey.optimalRestingHr;
    }

    // AC2: RPE-only mode (no biometrics, but RPE history available)
    if (sv.restingHR == null &&
        sv.stepCount == null &&
        sv.rpeHistory.isNotEmpty) {
      final avg = sv.rpeHistory.reduce((a, b) => a + b) / sv.rpeHistory.length;
      if (avg <= 6.5 && sv.streak >= 2) {
        return ExplanationKey.consistentWeek;
      }
      if (avg > 7.5) {
        return ExplanationKey.intenseEffort;
      }
      return ExplanationKey.comfortZone;
    }

    // Streak-based motivational context
    if (sv.streak >= 3) {
      return ExplanationKey.greatStreak;
    }

    // Safety net: under normal pipeline flow, missedSessions>=3 should already
    // have transitioned currentState to atRisk (handled above). This branch is
    // kept for defense if state-machine invariant ever drifts, and to keep AC4
    // non-empty guarantee tight without depending on that invariant.
    if (sv.streak == 0 && sv.missedSessions >= 3) {
      return ExplanationKey.welcomeBack;
    }

    // Session-type fallback — guaranteed to resolve to text (AC4)
    return switch (session.sessionType) {
      'breathing' => ExplanationKey.breathingFallback,
      'mobility' => ExplanationKey.mobilityFallback,
      _ => ExplanationKey.genericFallback,
    };
  }
}
