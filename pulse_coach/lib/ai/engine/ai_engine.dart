import 'package:pulse_coach/ai/bandit/bandit_state.dart' as ai_bandit;
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';

/// Bundled input sent across isolate boundary to the AI pipeline.
///
/// Fields are sendable across `SendPort`: `StateVector` and `BanditState` are
/// freezed value classes built from primitives, enums, lists, and maps —
/// transferable by Flutter's `compute()` without explicit JSON serialization.
class AiEngineInput {
  final StateVector stateVector;
  final ai_bandit.BanditState banditState;

  const AiEngineInput({
    required this.stateVector,
    required this.banditState,
  });
}

/// Bundled result returned from the AI pipeline isolate.
///
/// [plan] is the generated DailyPlan with empty explanation placeholders.
/// [newBehavioralState] is the state machine output — caller must persist it
/// via BehavioralStateDao if it differs from the current stored state.
class AiEngineOutput {
  final DailyPlan plan;
  final BehavioralState newBehavioralState;

  const AiEngineOutput({
    required this.plan,
    required this.newBehavioralState,
  });
}

/// Contract for AI computation. Implemented by [AiEngineIsolate] in production,
/// mockable in tests.
///
/// ARCH7: No Flutter imports allowed in implementations. Pure Dart only.
abstract class AiEngine {
  Future<AiEngineOutput> call(AiEngineInput input);
}
