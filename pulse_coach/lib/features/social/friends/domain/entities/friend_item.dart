import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_item.freezed.dart';

@freezed
abstract class FriendItem with _$FriendItem {
  const factory FriendItem({
    required String friendshipId,
    required String userId,
    required String displayHandle,
    required DateTime createdAt,
  }) = _FriendItem;
}
