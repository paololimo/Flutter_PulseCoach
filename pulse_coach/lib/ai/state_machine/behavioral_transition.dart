import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';

/// Result of a BehavioralStateMachine evaluation.
///
/// [newState] is the computed next state (may equal previous if no transition occurred).
/// [transitionMessage] is non-null only when state CHANGED from previous.
///   Used by DailyPlanGenerationPipeline (Story 5.5) to surface FR14 messages on
///   the Today screen and pass to ExplanationGenerator (Story 5.6).
class BehavioralTransition {
  final BehavioralState newState;
  final String? transitionMessage;

  const BehavioralTransition({
    required this.newState,
    this.transitionMessage,
  });

  bool get stateChanged => transitionMessage != null;
}
