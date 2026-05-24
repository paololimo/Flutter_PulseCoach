import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_session_history.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_state.dart';

// Factory (not singleton): ProgressPage provides this via BlocProvider(create:),
// which closes the cubit when the Progress tab is disposed. A singleton would be
// reused already-closed on the next visit, silently swallowing every emit and
// freezing the page on the shimmer frame. Matches the @injectable lifecycle of
// the sibling DailyPlanBloc / TodaySessionCubit.
@injectable
class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit(this._getSessionHistory) : super(const ProgressInitial());

  final GetSessionHistory _getSessionHistory;

  Future<void> load() async {
    if (!isClosed) emit(const ProgressHistoryLoading());

    final result = await _getSessionHistory();

    result.fold(
      (failure) {
        AppLogger.error(
          'getSessionHistory failed: ${failure.message}',
          name: 'ProgressCubit',
        );
        if (!isClosed) emit(ProgressHistoryError(failure));
      },
      (entries) {
        if (!isClosed) emit(ProgressHistoryLoaded(entries));
      },
    );
  }
}
