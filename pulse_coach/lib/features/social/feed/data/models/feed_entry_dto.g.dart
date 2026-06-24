// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeedEntryDto _$FeedEntryDtoFromJson(Map<String, dynamic> json) =>
    _FeedEntryDto(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      sessionType: json['session_type'] as String,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      completedAt: json['completed_at'] as String,
      createdAt: json['created_at'] as String,
      displayHandle: json['display_handle'] as String?,
    );

Map<String, dynamic> _$FeedEntryDtoToJson(_FeedEntryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'session_type': instance.sessionType,
      'duration_minutes': instance.durationMinutes,
      'completed_at': instance.completedAt,
      'created_at': instance.createdAt,
      'display_handle': instance.displayHandle,
    };
