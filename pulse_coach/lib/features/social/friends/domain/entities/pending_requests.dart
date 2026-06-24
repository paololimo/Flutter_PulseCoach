import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/friend_item.dart';

part 'pending_requests.freezed.dart';

@freezed
abstract class PendingRequests with _$PendingRequests {
  const factory PendingRequests({
    required List<FriendItem> received,
    required List<FriendItem> sent,
  }) = _PendingRequests;
}
