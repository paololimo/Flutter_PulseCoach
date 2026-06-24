import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/friend_item.dart';

part 'friend_item_dto.freezed.dart';
part 'friend_item_dto.g.dart';

@freezed
abstract class FriendItemDto with _$FriendItemDto {
  const factory FriendItemDto({
    @JsonKey(name: 'id') required String friendshipId,
    @JsonKey(name: 'other_user_id') required String userId,
    @JsonKey(name: 'display_handle') required String displayHandle,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _FriendItemDto;

  factory FriendItemDto.fromJson(Map<String, dynamic> json) =>
      _$FriendItemDtoFromJson(json);
}

extension FriendItemDtoMapper on FriendItemDto {
  FriendItem toDomain() => FriendItem(
        friendshipId: friendshipId,
        userId: userId,
        displayHandle: displayHandle,
        createdAt: DateTime.parse(createdAt),
      );
}
