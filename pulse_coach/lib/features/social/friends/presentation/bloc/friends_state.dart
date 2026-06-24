import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/friend_item.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/pending_requests.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';

part 'friends_state.freezed.dart';

@freezed
abstract class FriendsState with _$FriendsState {
  const factory FriendsState.initial() = _Initial;
  const factory FriendsState.loading() = _Loading;
  const factory FriendsState.loaded({
    required List<FriendItem> friends,
    required PendingRequests pendingRequests,
    SocialProfile? searchResult,
    @Default(false) bool requestSent,
  }) = _Loaded;
  const factory FriendsState.error({required Failure failure}) = _Error;
}
