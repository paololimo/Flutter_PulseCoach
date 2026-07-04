import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/entities/leaderboard_entry.dart';

part 'leaderboard_state.freezed.dart';

@freezed
abstract class LeaderboardState with _$LeaderboardState {
  const factory LeaderboardState.initial() = _Initial;
  const factory LeaderboardState.loading() = _Loading;
  const factory LeaderboardState.loaded({
    required List<LeaderboardEntry> entries,
    required bool isFrozen,
  }) = _Loaded;
  const factory LeaderboardState.error({required Failure failure}) = _Error;
}
