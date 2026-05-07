import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

/// Rule-based explanation engine. Pure Dart — no Flutter imports (ARCH7).
///
/// Generates one non-empty explanation string per session by inspecting the
/// available signals in [StateVector] in priority order:
///   1. BehavioralState (Recovering / AtRisk / Fatigued) — highest priority
///   2. Biometric signals (restingHR, stepCount) — when available
///   3. RPE history — AC2 fallback for sensor-less mode
///   4. Streak / missed-sessions — motivational context
///   5. Session type — final fallback (always non-empty, AC4)
class ExplanationGenerator {
  const ExplanationGenerator();

  /// Returns a `List<String>` of the same length as [sessions].
  /// Every element is guaranteed non-empty (AC4).
  List<String> generate({
    required StateVector stateVector,
    required List<PlannedSession> sessions,
  }) {
    return sessions.map((s) => _explain(stateVector, s)).toList();
  }

  String _explain(StateVector sv, PlannedSession session) {
    // AC3: Recovering → always communicate reduced intensity
    if (sv.currentState == BehavioralState.recovering) {
      return "Your body needs a lighter day. We've adjusted accordingly.";
    }

    // AtRisk → safety-first messaging
    if (sv.currentState == BehavioralState.atRisk) {
      if (sv.missedSessions >= 2) {
        return "You've missed a few sessions. Starting easy to rebuild.";
      }
      return 'High load detected. Keeping it light today.';
    }

    // Fatigued → effort acknowledgment
    if (sv.currentState == BehavioralState.fatigued) {
      return 'Your effort has been high lately. Dialing back the intensity.';
    }

    // Active state — check biometric signals first (AC1)
    if (sv.restingHR != null && sv.restingHR! > 75) {
      return 'Elevated resting HR detected. Starting with a gentler session.';
    }

    if (sv.stepCount != null && sv.stepCount! < 3000) {
      return 'Low step count today. Light movement to get going.';
    }

    if (sv.restingHR != null && sv.restingHR! <= 60 && sv.streak >= 1) {
      return 'Resting HR looks solid. Time for a focused session.';
    }

    // AC2: RPE-only mode (no biometrics, but RPE history available)
    if (sv.restingHR == null && sv.stepCount == null && sv.rpeHistory.isNotEmpty) {
      final avg = sv.rpeHistory.reduce((a, b) => a + b) / sv.rpeHistory.length;
      if (avg <= 6.5 && sv.streak >= 2) {
        return "You've been consistent this week. Stepping it up slightly.";
      }
      if (avg > 7.5) {
        return 'Your effort has been high. Keeping it moderate today.';
      }
      return 'Based on your recent sessions. Staying in your comfort zone.';
    }

    // Streak-based motivational context
    if (sv.streak >= 3) {
      return "Great streak! Let's keep the momentum going.";
    }

    // Safety net: under normal pipeline flow, missedSessions>=3 should already
    // have transitioned currentState to atRisk (handled above). This branch is
    // kept for defense if state-machine invariant ever drifts, and to keep AC4
    // non-empty guarantee tight without depending on that invariant.
    if (sv.streak == 0 && sv.missedSessions >= 3) {
      return "Welcome back. Easing in with a gentle start.";
    }

    // Session-type fallback — guaranteed non-empty (AC4)
    return switch (session.sessionType) {
      'breathing' => 'A moment to reset. Short breathing session queued.',
      'mobility' => 'Mobility work to keep you moving well.',
      _ => "Ready when you are. Let's move.",
    };
  }
}
