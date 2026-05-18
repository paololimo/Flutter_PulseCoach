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
      return 'Il tuo corpo ha bisogno di una giornata più leggera. Abbiamo regolato di conseguenza.';
    }

    // AtRisk → safety-first messaging
    if (sv.currentState == BehavioralState.atRisk) {
      if (sv.missedSessions >= 2) {
        return 'Hai saltato alcune sessioni. Riprendiamo con calma.';
      }
      return 'Carico alto rilevato. Oggi manteniamoci leggeri.';
    }

    // Fatigued → effort acknowledgment
    if (sv.currentState == BehavioralState.fatigued) {
      return 'Hai dato il massimo ultimamente. Riduciamo l\'intensità.';
    }

    // Active state — check biometric signals first (AC1)
    if (sv.restingHR != null && sv.restingHR! > 75) {
      return 'Frequenza cardiaca a riposo elevata. Iniziamo con una sessione più dolce.';
    }

    if (sv.stepCount != null && sv.stepCount! < 3000) {
      return 'Pochi passi oggi. Movimento leggero per ripartire.';
    }

    if (sv.restingHR != null && sv.restingHR! <= 60 && sv.streak >= 1) {
      return 'Frequenza cardiaca a riposo ottima. Tempo per una sessione concentrata.';
    }

    // AC2: RPE-only mode (no biometrics, but RPE history available)
    if (sv.restingHR == null && sv.stepCount == null && sv.rpeHistory.isNotEmpty) {
      final avg = sv.rpeHistory.reduce((a, b) => a + b) / sv.rpeHistory.length;
      if (avg <= 6.5 && sv.streak >= 2) {
        return 'Sei stato costante questa settimana. Alziamo leggermente l\'asticella.';
      }
      if (avg > 7.5) {
        return 'Lo sforzo è stato intenso. Oggi manteniamoci moderati.';
      }
      return 'In base alle tue ultime sessioni. Restiamo nella tua zona di comfort.';
    }

    // Streak-based motivational context
    if (sv.streak >= 3) {
      return 'Ottima serie! Continuiamo con questo ritmo.';
    }

    // Safety net: under normal pipeline flow, missedSessions>=3 should already
    // have transitioned currentState to atRisk (handled above). This branch is
    // kept for defense if state-machine invariant ever drifts, and to keep AC4
    // non-empty guarantee tight without depending on that invariant.
    if (sv.streak == 0 && sv.missedSessions >= 3) {
      return 'Bentornato. Ripartiamo dolcemente.';
    }

    // Session-type fallback — guaranteed non-empty (AC4)
    return switch (session.sessionType) {
      'breathing' => 'Un momento per rilassarti. Breve sessione di respirazione in coda.',
      'mobility' => 'Lavoro di mobilità per mantenere il movimento fluido.',
      _ => 'Quando sei pronto, partiamo.',
    };
  }
}
