import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';
import 'package:pulse_coach/features/social/feed/domain/repositories/feed_repository.dart';

@injectable
class GetFeedUseCase {
  final FeedRepository _repository;
  const GetFeedUseCase(this._repository);

  Future<Either<SocialFailure, List<FeedEntry>>> call() =>
      _repository.getFeed();
}
