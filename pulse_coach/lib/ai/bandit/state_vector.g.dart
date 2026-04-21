// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_vector.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StateVector _$StateVectorFromJson(Map<String, dynamic> json) => _StateVector(
  restingHR: (json['restingHR'] as num?)?.toDouble(),
  stepCount: (json['stepCount'] as num?)?.toInt(),
  activityLevel: $enumDecodeNullable(
    _$ActivityLevelEnumMap,
    json['activityLevel'],
  ),
  rpeHistory: (json['rpeHistory'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  missedSessions: (json['missedSessions'] as num).toInt(),
  streak: (json['streak'] as num).toInt(),
  aqiLevel: $enumDecode(_$AqiLevelEnumMap, json['aqiLevel']),
  temperature: (json['temperature'] as num?)?.toDouble(),
  precipitation: json['precipitation'] as bool?,
  userProfile: UserProfile.fromJson(
    json['userProfile'] as Map<String, dynamic>,
  ),
  currentState: $enumDecode(_$BehavioralStateEnumMap, json['currentState']),
);

Map<String, dynamic> _$StateVectorToJson(_StateVector instance) =>
    <String, dynamic>{
      'restingHR': instance.restingHR,
      'stepCount': instance.stepCount,
      'activityLevel': _$ActivityLevelEnumMap[instance.activityLevel],
      'rpeHistory': instance.rpeHistory,
      'missedSessions': instance.missedSessions,
      'streak': instance.streak,
      'aqiLevel': _$AqiLevelEnumMap[instance.aqiLevel]!,
      'temperature': instance.temperature,
      'precipitation': instance.precipitation,
      'userProfile': instance.userProfile.toJson(),
      'currentState': _$BehavioralStateEnumMap[instance.currentState]!,
    };

const _$ActivityLevelEnumMap = {
  ActivityLevel.sedentary: 'sedentary',
  ActivityLevel.moderate: 'moderate',
  ActivityLevel.active: 'active',
};

const _$AqiLevelEnumMap = {AqiLevel.low: 'low', AqiLevel.high: 'high'};

const _$BehavioralStateEnumMap = {
  BehavioralState.active: 'active',
  BehavioralState.fatigued: 'fatigued',
  BehavioralState.atRisk: 'atRisk',
  BehavioralState.recovering: 'recovering',
};
