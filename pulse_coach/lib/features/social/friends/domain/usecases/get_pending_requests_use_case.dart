import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/pending_requests.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/friends_repository.dart';

@injectable
class GetPendingRequestsUseCase {
  final FriendsRepository _repository;
  const GetPendingRequestsUseCase(this._repository);

  Future<Either<SocialFailure, PendingRequests>> call() =>
      _repository.getPendingRequests();
}
