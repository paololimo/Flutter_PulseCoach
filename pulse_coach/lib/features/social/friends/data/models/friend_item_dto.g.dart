// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FriendItemDto _$FriendItemDtoFromJson(Map<String, dynamic> json) =>
    _FriendItemDto(
      friendshipId: json['id'] as String,
      userId: json['other_user_id'] as String,
      displayHandle: json['display_handle'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$FriendItemDtoToJson(_FriendItemDto instance) =>
    <String, dynamic>{
      'id': instance.friendshipId,
      'other_user_id': instance.userId,
      'display_handle': instance.displayHandle,
      'created_at': instance.createdAt,
    };
