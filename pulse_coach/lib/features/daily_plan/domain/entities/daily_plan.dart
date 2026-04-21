import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

part 'daily_plan.freezed.dart';
part 'daily_plan.g.dart';

/// The AI-generated plan for a single calendar day.
///
/// [planDate]: 'YYYY-MM-DD' — matches daily_plans_table.planDate (unique key).
/// [sessions]: 1–3 sessions. Count is constrained by SafetyConstraints.maxSessionCount.
/// [generatedAt]: isolate completion timestamp. Used with daily_plans_table.generatedAt.
///
/// Serialized as JSON → stored in daily_plans_table.planJson column.
@freezed
abstract class DailyPlan with _$DailyPlan {
  const factory DailyPlan({
    required String planDate,
    required List<PlannedSession> sessions,
    required DateTime generatedAt,
  }) = _DailyPlan;

  factory DailyPlan.fromJson(Map<String, dynamic> json) =>
      _$DailyPlanFromJson(json);
}
