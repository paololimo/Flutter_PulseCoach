import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';

/// Navigation contract for /social/shared-session/lobby.
///
/// Passed via GoRouter `extra` from Story 20.1 (SharedSession creation/join).
/// Story 19.2 adds the route; Story 20.1 wires navigation to it.
class SharedSessionStartArgs {
  final String sessionId;
  final bool isHost;
  final String userId;
  final String? displayHandle;
  final List<ExerciseStep> steps;

  const SharedSessionStartArgs({
    required this.sessionId,
    required this.isHost,
    required this.userId,
    this.displayHandle,
    required this.steps,
  });
}
