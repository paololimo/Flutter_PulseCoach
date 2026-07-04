import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_entry.freezed.dart';

@freezed
abstract class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String userId,
    required String displayHandle,
    required int totalPoints,
    required bool isOwn,
    required int rank, // 1-based, assigned client-side by RankPinning
  }) = _LeaderboardEntry;
}
