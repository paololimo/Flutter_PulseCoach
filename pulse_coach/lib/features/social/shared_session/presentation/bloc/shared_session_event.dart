import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';

sealed class SharedSessionEvent {
  const SharedSessionEvent();
}

/// User has been placed into a shared session channel.
/// Host: isHost = true. Follower: isHost = false.
final class SharedSessionJoined extends SharedSessionEvent {
  final String sessionId;
  final bool isHost;
  final String userId;
  final String? displayHandle;
  final List<ExerciseStep> steps;

  const SharedSessionJoined({
    required this.sessionId,
    required this.isHost,
    required this.userId,
    this.displayHandle,
    required this.steps,
  });
}

/// Host taps the Start button in the lobby.
final class SessionStartTapped extends SharedSessionEvent {
  const SessionStartTapped();
}

/// Host's local timer advanced a step — only the host emits this.
/// Carries current elapsed seconds for the drift-correction payload.
final class HostStepAdvanced extends SharedSessionEvent {
  final int stepIndex;
  final int elapsedSeconds;
  const HostStepAdvanced({required this.stepIndex, required this.elapsedSeconds});
}

// Bloc-internal events — must be in the same file as the sealed base class.
// Not part of the public API; dispatched only from stream subscriptions inside
// SharedSessionBloc.

final class PresenceStateReceived extends SharedSessionEvent {
  final PresenceState presenceState;
  const PresenceStateReceived(this.presenceState);
}

final class BroadcastEventReceived extends SharedSessionEvent {
  final BroadcastEvent broadcastEvent;
  const BroadcastEventReceived(this.broadcastEvent);
}

