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
  // Non-null for host; null for followers (set in Story 20.3)
  final String? joinCode;

  const SharedSessionJoined({
    required this.sessionId,
    required this.isHost,
    required this.userId,
    this.displayHandle,
    required this.steps,
    this.joinCode,
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

/// Host signals that the session is complete (all steps done or manual end).
/// Only the host dispatches this; the bloc guards against non-host dispatch.
/// Story 20.4 wires the InSessionCubit's completion callback to dispatch this.
final class SessionEndRequested extends SharedSessionEvent {
  const SessionEndRequested();
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

/// Host refreshes the join code without creating a new session (AC3).
final class SharedSessionJoinCodeRefreshed extends SharedSessionEvent {
  const SharedSessionJoinCodeRefreshed();
}

/// Host cancels the lobby before anyone joins (AC5).
final class SharedSessionCancelled extends SharedSessionEvent {
  const SharedSessionCancelled();
}

