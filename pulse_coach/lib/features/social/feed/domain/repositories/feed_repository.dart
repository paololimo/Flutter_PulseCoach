import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';

abstract class FeedRepository {
  /// Insert a new activity_feed row (share after session completion).
  Future<Either<SocialFailure, Unit>> shareFeedEntry({
    required String sessionType,
    required int durationMinutes,
    required DateTime completedAt,
  });

  /// Fetch the activity feed for the current user (own + accepted friends' entries).
  Future<Either<SocialFailure, List<FeedEntry>>> getFeed();

  /// Increment reactions on a feed entry (calls the Postgres RPC).
  Future<Either<SocialFailure, Unit>> reactToEntry(String feedEntryId);

  /// Delete own feed entry (revoke share).
  Future<Either<SocialFailure, Unit>> revokeEntry(String feedEntryId);
}
