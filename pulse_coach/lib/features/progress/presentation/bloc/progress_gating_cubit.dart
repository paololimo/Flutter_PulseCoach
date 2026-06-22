import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_gating_state.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/get_install_cohort_use_case.dart';

// Factory (not singleton): ProgressPage provides this via BlocProvider(create:),
// which closes the cubit when the Progress tab is disposed.
@injectable
class ProgressGatingCubit extends Cubit<ProgressGatingState> {
  ProgressGatingCubit(this._getInstallCohort)
      : super(const ProgressGatingInitial());

  final GetInstallCohortUseCase _getInstallCohort;

  Future<void> load() async {
    final result = await _getInstallCohort();
    result.fold(
      (_) {
        // Safe default: never grant access on error.
        if (!isClosed) emit(const ProgressGatingLoaded(isGrandfathered: false));
      },
      (cohort) {
        if (!isClosed) {
          emit(ProgressGatingLoaded(isGrandfathered: cohort == 'pre_v2'));
        }
      },
    );
  }
}
