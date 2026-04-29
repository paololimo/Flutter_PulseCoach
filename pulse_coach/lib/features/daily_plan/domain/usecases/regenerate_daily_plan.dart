import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/repositories/daily_plan_repository.dart';
import 'package:pulse_coach/features/daily_plan/domain/usecases/generate_daily_plan.dart';

/// Deletes today's cached plan then triggers full generation.
///
/// Used when the user explicitly requests regeneration (FR11) or when
/// user profile changes (Story 2.4 defer).
@injectable
class RegenerateDailyPlan {
  final DailyPlanRepository _planRepo;
  final GenerateDailyPlan _generateDailyPlan;

  RegenerateDailyPlan(this._planRepo, this._generateDailyPlan);

  Future<Either<Failure, DailyPlan>> call() async {
    final today = _todayDate();
    // Delete cached plan first; surface the failure if the delete itself fails,
    // otherwise GenerateDailyPlan would silently return the still-cached plan
    // and the user's "regenerate" would become a no-op.
    final deleted = await _planRepo.deletePlanForDate(today);
    return deleted.fold(
      Left.new,
      (_) => _generateDailyPlan.call(),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
