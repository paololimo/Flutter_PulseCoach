import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';

abstract class LeaderboardRepository {
  Future<Either<Failure, Unit>> awardSessionPoints({
    required int sessionLogId,
    required int basePoints,
    required DateTime awardedOnUtc,
  });

  Future<
    Either<
      Failure,
      List<
        ({String userId, String displayHandle, int totalPoints, bool isOwn})
      >
    >
  >
  getFriendsLeaderboard();

  Future<Either<Failure, Unit>> submitSharedSessionResult({
    required String sessionId,
    required int rpe,
    required String armKey,
    required int durationMinutes,
  });
}
