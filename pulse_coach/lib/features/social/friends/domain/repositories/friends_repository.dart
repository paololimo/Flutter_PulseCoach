import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/friend_item.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/pending_requests.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';

abstract class FriendsRepository {
  Future<Either<SocialFailure, SocialProfile?>> searchByHandle(String handle);
  Future<Either<SocialFailure, PendingRequests>> getPendingRequests();
  Future<Either<SocialFailure, List<FriendItem>>> getFriends();
  Future<Either<SocialFailure, Unit>> sendFriendRequest(String addresseeId);
  Future<Either<SocialFailure, Unit>> acceptRequest(String friendshipId);
  Future<Either<SocialFailure, Unit>> declineRequest(String friendshipId);
  Future<Either<SocialFailure, Unit>> removeFriend(String friendshipId);
}
