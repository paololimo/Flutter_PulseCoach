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
  }) = _Lobby;

  const factory SharedSessionState.inSession({
    required int stepIndex,
    required int elapsedSeconds,
    required bool isHost,
    required List<ExerciseStep> steps,
    @Default([]) List<ParticipantPresence> participants,
    String? droppedHandle,
  }) = _InSession;

  const factory SharedSessionState.error({
    required Failure failure,
  }) = _Error;

  const factory SharedSessionState.sessionEnded() = _SessionEnded;
}
