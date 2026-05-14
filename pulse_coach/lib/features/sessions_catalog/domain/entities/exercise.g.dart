// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Exercise _$ExerciseFromJson(Map<String, dynamic> json) => _Exercise(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  sessionType: json['sessionType'] as String,
  steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
  durationMinutes: (json['durationMinutes'] as num).toInt(),
  difficulty: json['difficulty'] as String,
  indoorCompatible: json['indoorCompatible'] as bool,
  outdoorCompatible: json['outdoorCompatible'] as bool,
);

Map<String, dynamic> _$ExerciseToJson(_Exercise instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'sessionType': instance.sessionType,
  'steps': instance.steps,
  'durationMinutes': instance.durationMinutes,
  'difficulty': instance.difficulty,
  'indoorCompatible': instance.indoorCompatible,
  'outdoorCompatible': instance.outdoorCompatible,
};
