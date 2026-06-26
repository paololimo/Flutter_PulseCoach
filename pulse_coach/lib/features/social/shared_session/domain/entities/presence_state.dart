import 'package:freezed_annotation/freezed_annotation.dart';

part 'presence_state.freezed.dart';

@freezed
abstract class PresenceState with _$PresenceState {
  const factory PresenceState({
    required List<ParticipantPresence> participants,
  }) = _PresenceState;
}

@freezed
abstract class ParticipantPresence with _$ParticipantPresence {
  const factory ParticipantPresence({
    required String userId,
    String? displayHandle,
    @Default(false) bool isHost,
    double? lat, // ephemeral city-level coordinate, NFR33 — never persisted to DB
    double? lon,
  }) = _ParticipantPresence;
}
