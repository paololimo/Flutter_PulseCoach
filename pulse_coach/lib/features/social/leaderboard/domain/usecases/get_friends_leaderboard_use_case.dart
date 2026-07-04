import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';

@injectable
class GetFriendsLeaderboardUseCase {
  final LeaderboardRepository _repository;
  const GetFriendsLeaderboardUseCase(this._repository);

  Future<
    Either<
      Failure,
      List<
        ({String userId, String displayHandle, int totalPoints, bool isOwn})
      >
    >
  >
  call() => _repository.getFriendsLeaderboard();
}
