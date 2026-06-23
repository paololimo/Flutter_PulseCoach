// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SocialProfileDto _$SocialProfileDtoFromJson(Map<String, dynamic> json) =>
    _SocialProfileDto(
      id: json['id'] as String,
      displayHandle: json['display_handle'] as String?,
      visibilityTier: json['visibility_tier'] as String,
    );

Map<String, dynamic> _$SocialProfileDtoToJson(_SocialProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_handle': instance.displayHandle,
      'visibility_tier': instance.visibilityTier,
    };
