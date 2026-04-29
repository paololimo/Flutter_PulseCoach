import 'package:flutter/foundation.dart' show compute;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/ai/bandit/bandit_state.dart' as ai_bandit;
import 'package:pulse_coach/ai/bandit/contextual_bandit.dart';
import 'package:pulse_coach/ai/engine/ai_engine.dart';
import 'package:pulse_coach/ai/explainability/explanation_generator.dart';
import 'package:pulse_coach/ai/safety/safety_rules.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state_machine.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';

/// Production AI engine: runs the 4-step pipeline inside Flutter's compute().
///
/// compute() spawns a fresh Dart isolate, runs [_runPipeline] (top-level
/// function required — no closures), and returns the result to the main isolate.
/// The UI thread is never blocked. (ARCH7, NFR1, NFR2)
@Injectable(as: AiEngine)
class AiEngineIsolate implements AiEngine {
  /// Hard cap on isolate execution. NFR1 budgets plan generation at 30 s end-to-end;
  /// 25 s here leaves headroom for caller I/O and ensures the bloc never hangs in
  /// `loading` if the isolate stalls (deadlock, infinite loop, spawn failure).
  static const Duration _timeout = Duration(seconds: 25);

  @override
  Future<AiEngineOutput> call(AiEngineInput input) =>
      compute(_runPipeline, input).timeout(_timeout);
}

/// Top-level function — required by compute(). Runs in a separate Dart isolate.
///
/// Pipeline order (AC2):
///   1. Evaluate BehavioralStateMachine
///   2. Apply SafetyRules
///   3. BanditEngine.selectSessions
///   4. ExplanationGenerator.generate — per-session explanations (Story 5.6)
///   5. Build DailyPlan with explanations populated
AiEngineOutput _runPipeline(AiEngineInput input) {
  final sv = input.stateVector;

  // Step 1: state machine
  const machine = BehavioralStateMachine();
  final transition = machine.evaluate(sv);
  final newState = transition.newState;

  // Step 2: rebuild StateVector with updated state for safety rule evaluation
  final updatedSv = sv.copyWith(currentState: newState);

  // Step 3: safety rules (reuse the same machine instance from Step 1)
  final constraints = const SafetyRules(BehavioralStateMachine()).apply(updatedSv);

  // Step 4: bandit selection
  final engine = BanditEngine(epsilon: _decayedEpsilon(input.banditState));
  final sessions = engine.selectSessions(updatedSv, constraints, input.banditState);

  // Step 5: generate per-session explanations (AC1-AC4 of Story 5.6)
  final explanations = const ExplanationGenerator().generate(
    stateVector: updatedSv,
    sessions: sessions,
  );
  final sessionsWithExplanations = sessions.asMap().entries
      .map((e) => e.value.copyWith(explanation: explanations[e.key]))
      .toList();

  // Step 6: build DailyPlan with explanations populated
  final plan = DailyPlan(
    planDate: _todayDate(),
    sessions: sessionsWithExplanations,
    generatedAt: DateTime.now().toUtc(),
  );

  return AiEngineOutput(plan: plan, newBehavioralState: newState);
}

/// Epsilon decays linearly from 0.3 (0 sessions) to 0.05 (50+ sessions).
/// Encourages exploration for new users, shifts to exploitation over time.
double _decayedEpsilon(ai_bandit.BanditState state) {
  final sessionCount = state.armWeights.values
      .where((w) => w < 1.0)
      .length; // updated arms proxy for session count
  const min = 0.05;
  const max = 0.3;
  const decayOver = 50;
  final ratio = (sessionCount / decayOver).clamp(0.0, 1.0);
  return max - ratio * (max - min);
}

/// Returns today's date as 'YYYY-MM-DD'.
/// Called inside isolate — no Flutter required.
String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
