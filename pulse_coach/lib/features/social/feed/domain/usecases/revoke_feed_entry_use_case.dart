import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/feed/domain/repositories/feed_repository.dart';

@injectable
class RevokeFeedEntryUseCase {
  final FeedRepository _repository;
  const RevokeFeedEntryUseCase(this._repository);

  Future<Either<SocialFailure, Unit>> call(String feedEntryId) =>
      _repository.revokeEntry(feedEntryId);
}
