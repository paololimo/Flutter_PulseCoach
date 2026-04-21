// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_constraints.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SafetyConstraints _$SafetyConstraintsFromJson(Map<String, dynamic> json) =>
    _SafetyConstraints(
      maxIntensity: $enumDecodeNullable(
        _$SessionIntensityEnumMap,
        json['maxIntensity'],
      ),
      maxSessionCount: (json['maxSessionCount'] as num).toInt(),
      outdoorAllowed: json['outdoorAllowed'] as bool,
    );

Map<String, dynamic> _$SafetyConstraintsToJson(_SafetyConstraints instance) =>
    <String, dynamic>{
      'maxIntensity': _$SessionIntensityEnumMap[instance.maxIntensity],
      'maxSessionCount': instance.maxSessionCount,
      'outdoorAllowed': instance.outdoorAllowed,
    };

const _$SessionIntensityEnumMap = {
  SessionIntensity.low: 'low',
  SessionIntensity.medium: 'medium',
  SessionIntensity.high: 'high',
};
