import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/usecases/generate_daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/usecases/regenerate_daily_plan.dart';

part 'daily_plan_bloc.freezed.dart';
part 'daily_plan_event.dart';

// ─── State ────────────────────────────────────────────────────────────────────

@freezed
sealed class DailyPlanState with _$DailyPlanState {
  const factory DailyPlanState.initial() = DailyPlanInitial;
  const factory DailyPlanState.loading() = DailyPlanLoading;
  const factory DailyPlanState.loaded({required DailyPlan plan}) = DailyPlanLoaded;
  const factory DailyPlanState.error({
    required Failure failure,
    @Default(0) int retryAttempts,
  }) = DailyPlanError;
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

@injectable
class DailyPlanBloc extends Bloc<DailyPlanEvent, DailyPlanState> {
  final GenerateDailyPlan _generateDailyPlan;
  final RegenerateDailyPlan _regenerateDailyPlan;

  DailyPlanBloc(this._generateDailyPlan, this._regenerateDailyPlan)
      : super(const DailyPlanState.initial()) {
    on<DailyPlanGenerateRequested>(_onGenerateRequested);
    on<DailyPlanRegenerateRequested>(_onRegenerateRequested);
  }

  // Bloc-emitted `retryAttempts` counts attempts (first error = 1), and is
  // shared across Generate and Regenerate — a `RegenerateRequested` after a
  // failed `GenerateRequested` increments the same counter. Pending Story 7.1
  // (StateIndicator), where UX semantics will fix whether the field should
  // split per-handler.
  Future<void> _onGenerateRequested(
    DailyPlanGenerateRequested event,
    Emitter<DailyPlanState> emit,
  ) async {
    final retryAttempts = state is DailyPlanError
        ? (state as DailyPlanError).retryAttempts + 1
        : 1;
    emit(const DailyPlanState.loading());
    try {
      final result = await _generateDailyPlan.call();
      result.fold(
        (failure) => emit(
          DailyPlanState.error(
            failure: failure,
            retryAttempts: retryAttempts,
          ),
        ),
        (plan) => emit(DailyPlanState.loaded(plan: plan)),
      );
    } catch (e) {
      emit(
        DailyPlanState.error(
          failure: CacheFailure(e.toString()),
          retryAttempts: retryAttempts,
        ),
      );
    }
  }

  Future<void> _onRegenerateRequested(
    DailyPlanRegenerateRequested event,
    Emitter<DailyPlanState> emit,
  ) async {
    final retryAttempts = state is DailyPlanError
        ? (state as DailyPlanError).retryAttempts + 1
        : 1;
    emit(const DailyPlanState.loading());
    try {
      final result = await _regenerateDailyPlan.call();
      result.fold(
        (failure) => emit(
          DailyPlanState.error(
            failure: failure,
            retryAttempts: retryAttempts,
          ),
        ),
        (plan) => emit(DailyPlanState.loaded(plan: plan)),
      );
    } catch (e) {
      emit(
        DailyPlanState.error(
          failure: CacheFailure(e.toString()),
          retryAttempts: retryAttempts,
        ),
      );
    }
  }
}
