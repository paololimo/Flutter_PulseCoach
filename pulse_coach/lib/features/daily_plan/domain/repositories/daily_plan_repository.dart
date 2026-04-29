import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';

abstract class DailyPlanRepository {
  /// Returns the plan for [planDate] ('YYYY-MM-DD'), or null if not cached.
  Future<Either<Failure, DailyPlan?>> getPlanForDate(String planDate);

  /// Persists [plan]. If a plan for the same [planDate] already exists,
  /// replaces it (upsert semantics via delete + insert).
  Future<Either<Failure, void>> savePlan(DailyPlan plan);

  /// Deletes the plan for [planDate] if it exists. No-op if not found.
  Future<Either<Failure, void>> deletePlanForDate(String planDate);
}
