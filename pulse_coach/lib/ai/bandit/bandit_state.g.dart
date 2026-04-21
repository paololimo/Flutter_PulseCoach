// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bandit_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BanditState _$BanditStateFromJson(Map<String, dynamic> json) => _BanditState(
  armWeights: (json['armWeights'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$BanditStateToJson(_BanditState instance) =>
    <String, dynamic>{
      'armWeights': instance.armWeights,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
