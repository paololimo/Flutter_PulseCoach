import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/feed/data/datasources/feed_remote_data_source.dart';
import 'package:pulse_coach/features/social/feed/data/models/feed_entry_dto.dart';
import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';
import 'package:pulse_coach/features/social/feed/domain/repositories/feed_repository.dart';

@Injectable(as: FeedRepository)
class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource _dataSource;
  const FeedRepositoryImpl(this._dataSource);

  @override
  Future<Either<SocialFailure, Unit>> shareFeedEntry({
    required String sessionType,
    required int durationMinutes,
    required DateTime completedAt,
  }) async {
    try {
      final uid = _dataSource.currentUserId;
      await _dataSource.share(
        ownerId: uid,
        sessionType: sessionType,
        durationMinutes: durationMinutes,
        completedAt: completedAt,
      );
      return const Right(unit);
    } on AuthFailureException {
      return const Left(SocialFailure('Not signed in'));
    } catch (e) {
      return Left(SocialFailure('Failed to share: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, List<FeedEntry>>> getFeed() async {
    try {
      final rows = await _dataSource.loadFeed();
      final entries = rows
          .map(_rowToDto)
          .whereType<FeedEntryDto>()
          .map((dto) => dto.toDomain())
          .toList();
      return Right(entries);
    } catch (e) {
      return Left(SocialFailure('Failed to load feed: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, Unit>> reactToEntry(String feedEntryId) async {
    try {
      await _dataSource.incrementReaction(feedEntryId);
      return const Right(unit);
    } catch (e) {
      return Left(SocialFailure('Failed to react: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, Unit>> revokeEntry(String feedEntryId) async {
    try {
      await _dataSource.revoke(feedEntryId);
      return const Right(unit);
    } catch (e) {
      return Left(SocialFailure('Failed to revoke: $e'));
    }
  }

  /// Parse joined row — profile handle may be nested under 'profiles' key.
  FeedEntryDto? _rowToDto(Map<String, dynamic> row) {
    try {
      final profileMap = row['profiles'];
      final handle = profileMap is Map<String, dynamic>
          ? profileMap['display_handle'] as String?
          : null;
      return FeedEntryDto(
        id: row['id'] as String,
        ownerId: row['owner_id'] as String,
        sessionType: row['session_type'] as String,
        durationMinutes: row['duration_minutes'] as int,
        completedAt: row['completed_at'] as String,
        createdAt: row['created_at'] as String,
        displayHandle: handle,
      );
    } catch (_) {
      return null; // degrade single bad row rather than crashing the full list
    }
  }
}
