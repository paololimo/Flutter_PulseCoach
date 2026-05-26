import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_progress_stats.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_state.dart';

// Factory (not singleton): ProgressPage provides this via BlocProvider(create:),
// which closes the cubit when the Progress tab is disposed. Matches the
// lifecycle rationale used by ProgressCubit.
@injectable
class ProgressStatsCubit extends Cubit<ProgressStatsState> {
  ProgressStatsCubit(this._getProgressStats)
    : super(const ProgressStatsInitial());

  final GetProgressStats _getProgressStats;

  Future<void> load() async {
    if (!isClosed) emit(const ProgressStatsLoading());

    final result = await _getProgressStats();

    result.fold(
      (failure) {
        AppLogger.error(
          'getProgressStats failed: ${failure.message}',
          name: 'ProgressStatsCubit',
        );
        if (!isClosed) emit(ProgressStatsError(failure));
      },
      (stats) {
        if (!isClosed) emit(ProgressStatsLoaded(stats));
      },
    );
  }
}
