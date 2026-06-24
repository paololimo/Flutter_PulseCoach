import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/friends_repository.dart';

@injectable
class AcceptRequestUseCase {
  final FriendsRepository _repository;
  const AcceptRequestUseCase(this._repository);

  Future<Either<SocialFailure, Unit>> call(String friendshipId) =>
      _repository.acceptRequest(friendshipId);
}
