// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlannedSession _$PlannedSessionFromJson(Map<String, dynamic> json) =>
    _PlannedSession(
      sessionType: json['sessionType'] as String,
      intensity: (json['intensity'] as num).toInt(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      isIndoor: json['isIndoor'] as bool,
      explanation: json['explanation'] as String? ?? '',
    );

Map<String, dynamic> _$PlannedSessionToJson(_PlannedSession instance) =>
    <String, dynamic>{
      'sessionType': instance.sessionType,
      'intensity': instance.intensity,
      'durationMinutes': instance.durationMinutes,
      'isIndoor': instance.isIndoor,
      'explanation': instance.explanation,
    };
