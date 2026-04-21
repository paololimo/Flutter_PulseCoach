// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyPlan _$DailyPlanFromJson(Map<String, dynamic> json) => _DailyPlan(
  planDate: json['planDate'] as String,
  sessions: (json['sessions'] as List<dynamic>)
      .map((e) => PlannedSession.fromJson(e as Map<String, dynamic>))
      .toList(),
  generatedAt: DateTime.parse(json['generatedAt'] as String),
);

Map<String, dynamic> _$DailyPlanToJson(_DailyPlan instance) =>
    <String, dynamic>{
      'planDate': instance.planDate,
      'sessions': instance.sessions.map((e) => e.toJson()).toList(),
      'generatedAt': instance.generatedAt.toIso8601String(),
    };
