import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_transition_key.dart';

/// Result of a BehavioralStateMachine evaluation.
///
/// [newState] is the computed next state (may equal previous if no transition occurred).
/// [transitionKey] is non-null only when state changed from previous.
class BehavioralTransition {
  final BehavioralState newState;
  final BehavioralTransitionKey? transitionKey;

  const BehavioralTransition({required this.newState, this.transitionKey});

  bool get stateChanged => transitionKey != null;
}
