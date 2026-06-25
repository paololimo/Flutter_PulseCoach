// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SharedSessionDto _$SharedSessionDtoFromJson(Map<String, dynamic> json) =>
    _SharedSessionDto(
      id: json['id'] as String,
      hostUserId: json['host_user_id'] as String,
      joinCode: json['join_code'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$SharedSessionDtoToJson(_SharedSessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'host_user_id': instance.hostUserId,
      'join_code': instance.joinCode,
      'status': instance.status,
      'created_at': instance.createdAt,
    };
