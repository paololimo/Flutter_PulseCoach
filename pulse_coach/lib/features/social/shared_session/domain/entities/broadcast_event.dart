import 'package:freezed_annotation/freezed_annotation.dart';

part 'broadcast_event.freezed.dart';

@freezed
sealed class BroadcastEvent with _$BroadcastEvent {
  const factory BroadcastEvent.stepAdvanced({
    required int stepIndex,
    required int elapsedSeconds,
  }) = StepAdvanced;
  const factory BroadcastEvent.sessionStarted() = SessionStarted;
  const factory BroadcastEvent.sessionEnded() = SessionEnded;
  const factory BroadcastEvent.unknown({required String rawEvent}) =
      UnknownBroadcast;
}
