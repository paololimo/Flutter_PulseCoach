import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/friend_item.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/friends_repository.dart';

@injectable
class GetFriendsUseCase {
  final FriendsRepository _repository;
  const GetFriendsUseCase(this._repository);

  Future<Either<SocialFailure, List<FriendItem>>> call() =>
      _repository.getFriends();
}
