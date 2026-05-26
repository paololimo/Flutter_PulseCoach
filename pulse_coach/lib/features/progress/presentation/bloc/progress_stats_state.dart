import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';

sealed class ProgressStatsState {
  const ProgressStatsState();
}

class ProgressStatsInitial extends ProgressStatsState {
  const ProgressStatsInitial();
}

class ProgressStatsLoading extends ProgressStatsState {
  const ProgressStatsLoading();
}

class ProgressStatsLoaded extends ProgressStatsState {
  const ProgressStatsLoaded(this.stats);

  final ProgressStats stats;
}

class ProgressStatsError extends ProgressStatsState {
  const ProgressStatsError(this.failure);

  final Failure failure;
}
