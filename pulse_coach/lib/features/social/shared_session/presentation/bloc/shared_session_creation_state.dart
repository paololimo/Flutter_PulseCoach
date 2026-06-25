part of 'shared_session_creation_cubit.dart';

@freezed
sealed class SharedSessionCreationState with _$SharedSessionCreationState {
  const factory SharedSessionCreationState.initial() = _Initial;
  const factory SharedSessionCreationState.creating() = _Creating;
  const factory SharedSessionCreationState.created({
    required String sessionId,
    required String joinCode,
  }) = _Created;
  const factory SharedSessionCreationState.error({
    required Failure failure,
  }) = _Error;
}
