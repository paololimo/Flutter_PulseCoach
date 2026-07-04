import 'package:pulse_coach/features/social/leaderboard/domain/entities/leaderboard_entry.dart';

/// Pure Dart rank-pinning: sorts unranked entries and, if a frozen own rank
/// is set, pins the viewer's own entry at that fixed list position instead
/// of its live sorted position — see Story 21.2's "position-pinned freeze"
/// decision. Every other entry keeps sorting live around the pinned
/// position; only the own entry's index/rank number is held fixed.
class RankPinning {
  const RankPinning._();

  static List<LeaderboardEntry> compute({
    required List<
      ({String userId, String displayHandle, int totalPoints, bool isOwn})
    >
    raw,
    int? frozenOwnRank,
  }) {
    final sorted = [...raw]..sort((a, b) {
      final byPoints = b.totalPoints.compareTo(a.totalPoints);
      if (byPoints != 0) return byPoints;
      return a.displayHandle.compareTo(b.displayHandle);
    });

    final ownIndex = sorted.indexWhere((e) => e.isOwn);
    if (ownIndex == -1 || frozenOwnRank == null) {
      return [
        for (var i = 0; i < sorted.length; i++)
          LeaderboardEntry(
            userId: sorted[i].userId,
            displayHandle: sorted[i].displayHandle,
            totalPoints: sorted[i].totalPoints,
            isOwn: sorted[i].isOwn,
            rank: i + 1,
          ),
      ];
    }

    final own = sorted.removeAt(ownIndex);
    final targetIndex = (frozenOwnRank - 1).clamp(0, sorted.length);
    sorted.insert(targetIndex, own);

    return [
      for (var i = 0; i < sorted.length; i++)
        LeaderboardEntry(
          userId: sorted[i].userId,
          displayHandle: sorted[i].displayHandle,
          totalPoints: sorted[i].totalPoints,
          isOwn: sorted[i].isOwn,
          rank: i + 1,
        ),
    ];
  }
}
