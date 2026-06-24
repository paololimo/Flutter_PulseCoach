import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';

/// Returns (sessions: int, minutes: int) for the current ISO week from local drift.
@injectable
class GetOwnWeeklySummaryUseCase {
  final ProgressRepository _repository;
  const GetOwnWeeklySummaryUseCase(this._repository);

  Future<Either<Failure, ({int sessions, int minutes})>> call() async {
    final result = await _repository.getProgressStats();
    return result.fold(
      Left.new,
      (stats) => Right((
        sessions: stats.completedThisWeek,
        minutes: _thisWeekMinutes(stats.minutesPerWeek),
      )),
    );
  }

  int _thisWeekMinutes(List<WeeklyMinutes> minutesPerWeek) {
    if (minutesPerWeek.isEmpty) return 0;
    final now = DateTime.now().toUtc();
    // Monday of current ISO week (weekday 1 = Monday, 7 = Sunday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final label =
        '${monday.day.toString().padLeft(2, '0')}/${monday.month.toString().padLeft(2, '0')}';
    // minutesPerWeek is oldest-first; last entry is the most recent week
    if (minutesPerWeek.last.weekLabel == label) {
      return minutesPerWeek.last.totalMinutes;
    }
    return 0;
  }
}
