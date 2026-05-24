import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/database/app_database.dart'
    show SessionLogsCompanion;
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
import 'package:pulse_coach/features/session/presentation/utils/haptic_service.dart';
import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';

class InSessionCubit extends Cubit<InSessionState> {
  static const int _maxConsecutiveHrNulls = 6;

  final SessionLogsDao? _sessionLogsDao;
  final int? _planId;
  final int _sessionIndex;
  final HapticService? _hapticService;
  final LiveHrService? _liveHrService;
  // Injectable for tests: WidgetTester.pump() advances Timer.periodic but not
  // DateTime.now(), so elapsed-seconds tests must override this.
  final DateTime Function() _now;
  Timer? _timer;
  Timer? _hrTimer;
  int _consecutiveHrNullCount = 0;
  // Wall-clock anchor for `elapsedSeconds` (review D2): tick counting drifted
  // by +1 at every step boundary and undercounted backgrounded time.
  DateTime? _startedAt;
  bool _abandonRequested = false;

  InSessionCubit({
    required List<ExerciseStep> steps,
    SessionLogsDao? sessionLogsDao,
    int? planId,
    int sessionIndex = 0,
    HapticService? hapticService,
    LiveHrService? liveHrService,
    DateTime Function()? now,
  }) : _sessionLogsDao = sessionLogsDao,
       _planId = planId,
       _sessionIndex = sessionIndex,
       _hapticService = hapticService,
       _liveHrService = liveHrService,
       _now = now ?? DateTime.now,
       super(
         InSessionState(
           steps: steps,
           currentStepIndex: 0,
           secondsRemaining: steps.first.durationSeconds,
         ),
       );

  /// Starts the 1-second countdown tick. Idempotent: a second call is a no-op.
  void start() {
    if (_timer != null) return;
    _startedAt ??= _now();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    if (_liveHrService != null) {
      unawaited(_fetchAndEmitHr());
      _hrTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(_fetchAndEmitHr()),
      );
    }
  }

  /// Pauses the countdown without tearing it down — used by the page while the
  /// abandon-confirmation sheet is open (review fix: pause-on-sheet) so the
  /// session does not auto-complete underneath the modal and trigger a stale
  /// navigation.
  void pauseTimers() {
    _timer?.cancel();
    _timer = null;
    _hrTimer?.cancel();
    _hrTimer = null;
  }

  /// Resumes the countdown after [pauseTimers]. Idempotent.
  void resumeTimers() {
    if (state.isComplete || state.isAbandoned) return;
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    if (_liveHrService != null && _hrTimer == null) {
      _hrTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(_fetchAndEmitHr()),
      );
    }
  }

  void _tick(Timer _) {
    if (state.isComplete || state.isAbandoned) return;
    if (state.secondsRemaining > 0) {
      emit(state.copyWith(secondsRemaining: state.secondsRemaining - 1));
    } else {
      _advanceStep();
    }
  }

  void _advanceStep() {
    final nextIndex = state.currentStepIndex + 1;
    if (nextIndex >= state.steps.length) {
      _hapticService?.stepTransition();
      _timer?.cancel();
      _hrTimer?.cancel();
      unawaited(_persistCompletion());
    } else {
      _hapticService?.stepTransition();
      emit(
        state.copyWith(
          currentStepIndex: nextIndex,
          secondsRemaining: state.steps[nextIndex].durationSeconds,
        ),
      );
    }
  }

  Future<void> _persistCompletion() async {
    // Story 9.2 review-decision #1: the SessionLog write MUST be committed
    // before `isComplete: true` is emitted, so the downstream MiniSummary
    // read of `getLogsForPlan` sees the new row and the ring animates from
    // previousCompletedCount to newCompletedCount. The `await` below is the
    // barrier — do not move the emit above it.
    if (_sessionLogsDao != null && _planId != null) {
      final now = _now();
      try {
        await _sessionLogsDao.upsertCompletion(
          SessionLogsCompanion(
            dailyPlanId: Value(_planId),
            sessionIndex: Value(_sessionIndex),
            completedAt: Value(now),
            createdAt: Value(now),
          ),
        );
      } catch (e, st) {
        AppLogger.error(
          'upsertCompletion failed',
          name: 'InSessionCubit',
          error: e,
          stackTrace: st,
        );
        if (!isClosed) {
          emit(
            state.copyWith(
              persistenceError: const ServerFailure('session_log_write_failed'),
              isComplete: true,
            ),
          );
        }
        return;
      }
    }
    if (!isClosed) emit(state.copyWith(isComplete: true));
  }

  Future<void> _fetchAndEmitHr() async {
    try {
      final hr = await _liveHrService?.fetchLiveHr();
      if (isClosed) return;
      if (state.isComplete || state.isAbandoned) return;
      if (hr != null) {
        _consecutiveHrNullCount = 0;
        emit(
          state.copyWith(
            liveHr: hr,
            lastHrAtEpochMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        _consecutiveHrNullCount++;
        if (_consecutiveHrNullCount >= _maxConsecutiveHrNulls) {
          _hrTimer?.cancel();
          _hrTimer = null;
        }
      }
    } catch (e, st) {
      AppLogger.warning(
        'fetchLiveHr failed (optional - degrading gracefully)',
        name: 'InSessionCubit',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Called after the user confirms abandonment. Emits `isAbandoned` first so
  /// the BlocListener navigates immediately and the abandon button no longer
  /// looks tappable; persistence runs in the background.
  Future<void> abandon() async {
    if (_abandonRequested || state.isAbandoned || state.isComplete) return;
    _abandonRequested = true;
    _timer?.cancel();
    _timer = null;
    _hrTimer?.cancel();
    _hrTimer = null;

    final elapsedSeconds = _startedAt == null
        ? 0
        : _now().difference(_startedAt!).inSeconds;
    final currentStepIndex = state.currentStepIndex;

    // Emit BEFORE awaiting persistence (review fix: UI race). On persistence
    // failure we clear `_abandonRequested` so the user can retry — the
    // listener will already have navigated, but `_persistAbandon` falling back
    // logs the error.
    if (!isClosed) emit(state.copyWith(isAbandoned: true));
    await _persistAbandon(elapsedSeconds, currentStepIndex);
  }

  Future<void> _persistAbandon(int elapsedSeconds, int currentStepIndex) async {
    if (_sessionLogsDao == null || _planId == null) return;
    final now = _now();
    try {
      await _sessionLogsDao.insertLog(
        SessionLogsCompanion(
          dailyPlanId: Value(_planId),
          sessionIndex: Value(_sessionIndex),
          completedAt: Value(now),
          createdAt: Value(now),
          abandoned: const Value(true),
          elapsedSeconds: Value(elapsedSeconds),
          currentStepIndex: Value(currentStepIndex),
        ),
      );
    } catch (e, st) {
      // Clear the request flag so the user can retry abandoning from a future
      // entry point if the row needs to be written. The UI has already
      // navigated to RPE via the `isAbandoned` emit above.
      _abandonRequested = false;
      AppLogger.error(
        '_persistAbandon DAO write failed',
        name: 'InSessionCubit',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _hrTimer?.cancel();
    return super.close();
  }
}
