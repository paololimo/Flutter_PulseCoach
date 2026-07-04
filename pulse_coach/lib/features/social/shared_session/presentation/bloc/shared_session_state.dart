import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';

part 'shared_session_state.freezed.dart';

@freezed
sealed class SharedSessionState with _$SharedSessionState {
  const factory SharedSessionState.initial() = _Initial;

  const factory SharedSessionState.loading() = _Loading;

  const factory SharedSessionState.lobby({
    required List<ParticipantPresence> participants,
    required bool isHost,
    required List<ExerciseStep> steps,
    String? joinCode,
    // One-shot counter bumped each time a join-code refresh fails, so the page
    // can show a transient SnackBar without leaving the lobby.
    @Default(0) int refreshErrorTick,
    bool? coLocated, // null = check pending or inconclusive (NFR33); true = within 100m
  }) = _Lobby;

  const factory SharedSessionState.inSession({
    required int stepIndex,
    required int elapsedSeconds,
    required bool isHost,
    required List<ExerciseStep> steps,
    @Default([]) List<ParticipantPresence> participants,
    String? droppedHandle,
    @Default('mobility') String sessionType,
    @Default(5) int intensity,
    @Default(20) int durationMinutes,
  }) = _InSession;

  const factory SharedSessionState.error({
    required Failure failure,
  }) = _Error;

  const factory SharedSessionState.sessionEnded({
    @Default('mobility_medium') String armKey,
    String? sessionId,
  }) = _SessionEnded;

  const factory SharedSessionState.cancelled() = _Cancelled;
}
