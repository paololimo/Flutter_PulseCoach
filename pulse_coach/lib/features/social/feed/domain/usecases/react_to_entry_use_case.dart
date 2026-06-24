import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/feed/domain/repositories/feed_repository.dart';

@injectable
class ReactToEntryUseCase {
  final FeedRepository _repository;
  const ReactToEntryUseCase(this._repository);

  Future<Either<SocialFailure, Unit>> call(String feedEntryId) =>
      _repository.reactToEntry(feedEntryId);
}
