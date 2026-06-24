import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/data/datasources/friends_remote_data_source.dart';
import 'package:pulse_coach/features/social/friends/data/models/social_profile_dto.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/friend_item.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/pending_requests.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/friends_repository.dart';

@Injectable(as: FriendsRepository)
class FriendsRepositoryImpl implements FriendsRepository {
  final FriendsRemoteDataSource _dataSource;
  const FriendsRepositoryImpl(this._dataSource);

  @override
  Future<Either<SocialFailure, SocialProfile?>> searchByHandle(
      String handle) async {
    try {
      final dto = await _dataSource.findByHandle(handle);
      return Right(dto?.toDomain());
    } catch (e) {
      return Left(SocialFailure('Search failed: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, PendingRequests>> getPendingRequests() async {
    try {
      final data = await _dataSource.getPendingRequests();
      final received = data.received.map(_rowToFriendItemReceived).toList();
      final sent = data.sent.map(_rowToFriendItemSent).toList();
      return Right(PendingRequests(received: received, sent: sent));
    } catch (e) {
      return Left(SocialFailure('Failed to fetch requests: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, List<FriendItem>>> getFriends() async {
    try {
      final rows = await _dataSource.getAllFriends();
      final friends = rows.map(_rowToFriendItemGeneric).toList();
      return Right(friends);
    } catch (e) {
      return Left(SocialFailure('Failed to fetch friends: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, Unit>> sendFriendRequest(
      String addresseeId) async {
    try {
      await _dataSource.addFriend(addresseeId);
      return const Right(unit);
    } catch (e) {
      return Left(SocialFailure('Failed to send request: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, Unit>> acceptRequest(String friendshipId) async {
    try {
      await _dataSource.acceptFriendship(friendshipId);
      return const Right(unit);
    } catch (e) {
      return Left(SocialFailure('Failed to accept request: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, Unit>> declineRequest(
      String friendshipId) async {
    try {
      await _dataSource.declineFriendship(friendshipId);
      return const Right(unit);
    } catch (e) {
      return Left(SocialFailure('Failed to decline request: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, Unit>> removeFriend(String friendshipId) async {
    try {
      await _dataSource.removeFriendship(friendshipId);
      return const Right(unit);
    } catch (e) {
      return Left(SocialFailure('Failed to remove friend: $e'));
    }
  }

  FriendItem _rowToFriendItemReceived(Map<String, dynamic> row) =>
      _rowToFriendItem(row, row['requester_id'] as String);

  FriendItem _rowToFriendItemSent(Map<String, dynamic> row) =>
      _rowToFriendItem(row, row['addressee_id'] as String);

  FriendItem _rowToFriendItemGeneric(Map<String, dynamic> row) =>
      _rowToFriendItem(
          row, (row['addressee_id'] ?? row['requester_id']) as String);

  /// Maps a friendship row to a [FriendItem], degrading gracefully when the
  /// joined profile is hidden by RLS (null embed), has no handle, or carries a
  /// malformed timestamp — so a single unreadable row never fails the whole list.
  FriendItem _rowToFriendItem(Map<String, dynamic> row, String otherId) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final handle = profile?['display_handle'] as String?;
    return FriendItem(
      friendshipId: row['id'] as String,
      userId: otherId,
      displayHandle: handle ?? '',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
