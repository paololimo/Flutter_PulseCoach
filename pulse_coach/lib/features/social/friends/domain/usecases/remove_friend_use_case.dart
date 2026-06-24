import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/friends_repository.dart';

@injectable
class RemoveFriendUseCase {
  final FriendsRepository _repository;
  const RemoveFriendUseCase(this._repository);

  Future<Either<SocialFailure, Unit>> call(String friendshipId) =>
      _repository.removeFriend(friendshipId);
}
