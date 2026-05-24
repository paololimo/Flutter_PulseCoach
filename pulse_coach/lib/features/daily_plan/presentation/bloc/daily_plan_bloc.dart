import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_transition_key.dart';
import 'package:pulse_coach/core/database/app_database.dart' show AppDatabase;
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
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
  const factory DailyPlanState.loaded({
    required DailyPlan plan,
    @Default(BehavioralState.active) BehavioralState behavioralState,
    // Null means "plan was not (yet) persisted to daily_plans".
    // TodaySessionCubit treats null as "skip persistence" rather than relying
    // on a `== 0` sentinel that could collide with a real autoincrement id.
    int? planDbId,
    BehavioralTransitionKey? transitionKey,
  }) = DailyPlanLoaded;
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
  final AppDatabase _db;

  DailyPlanBloc(this._generateDailyPlan, this._regenerateDailyPlan, this._db)
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
      await result.fold(
        (failure) async => emit(
          DailyPlanState.error(failure: failure, retryAttempts: retryAttempts),
        ),
        (generated) async {
          final stateRow = await _db.behavioralStateDao.getLatestState();
          final planRow = await _db.dailyPlansDao.getPlanForDate(
            generated.plan.planDate,
          );
          if (isClosed) return;
          emit(
            DailyPlanState.loaded(
              plan: generated.plan,
              behavioralState: _parseState(stateRow?.currentState),
              planDbId: planRow?.id,
              transitionKey: generated.transitionKey,
            ),
          );
        },
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
      await result.fold(
        (failure) async => emit(
          DailyPlanState.error(failure: failure, retryAttempts: retryAttempts),
        ),
        (generated) async {
          final stateRow = await _db.behavioralStateDao.getLatestState();
          final planRow = await _db.dailyPlansDao.getPlanForDate(
            generated.plan.planDate,
          );
          if (isClosed) return;
          emit(
            DailyPlanState.loaded(
              plan: generated.plan,
              behavioralState: _parseState(stateRow?.currentState),
              planDbId: planRow?.id,
              transitionKey: generated.transitionKey,
            ),
          );
        },
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

  BehavioralState _parseState(String? stateStr) {
    final parsed = switch (stateStr?.toLowerCase()) {
      'recovering' => BehavioralState.recovering,
      'atrisk' => BehavioralState.atRisk,
      'fatigued' => BehavioralState.fatigued,
      'active' || null => BehavioralState.active,
      _ => null,
    };
    if (parsed != null) return parsed;
    AppLogger.warning(
      'Unknown BehavioralState string "$stateStr" - falling back to active',
      name: 'DailyPlanBloc',
    );
    return BehavioralState.active;
  }
}
