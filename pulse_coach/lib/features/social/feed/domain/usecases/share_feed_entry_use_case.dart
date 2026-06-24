import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/feed/domain/repositories/feed_repository.dart';

@injectable
class ShareFeedEntryUseCase {
  final FeedRepository _repository;
  const ShareFeedEntryUseCase(this._repository);

  Future<Either<SocialFailure, Unit>> call({
    required String sessionType,
    required int durationMinutes,
    required DateTime completedAt,
  }) =>
      _repository.shareFeedEntry(
        sessionType: sessionType,
        durationMinutes: durationMinutes,
        completedAt: completedAt,
      );
}
