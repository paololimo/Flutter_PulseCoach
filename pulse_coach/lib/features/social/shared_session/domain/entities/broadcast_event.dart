import 'package:freezed_annotation/freezed_annotation.dart';

part 'broadcast_event.freezed.dart';

@freezed
sealed class BroadcastEvent with _$BroadcastEvent {
  const factory BroadcastEvent.stepAdvanced({
    required int stepIndex,
    required int elapsedSeconds,
  }) = StepAdvanced;
  const factory BroadcastEvent.sessionStarted({
    @Default('mobility') String sessionType,
    @Default(5) int intensity,
    @Default(20) int durationMinutes,
    @Default('mobility_medium') String armKey,
  }) = SessionStarted;
  const factory BroadcastEvent.sessionEnded() = SessionEnded;
  const factory BroadcastEvent.unknown({required String rawEvent}) =
      UnknownBroadcast;
}
