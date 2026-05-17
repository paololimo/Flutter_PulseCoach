import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/database/app_database.dart'
    show SessionLogsCompanion;
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
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
  Timer? _timer;
  Timer? _hrTimer;
  int _consecutiveHrNullCount = 0;

  InSessionCubit({
    required List<ExerciseStep> steps,
    SessionLogsDao? sessionLogsDao,
    int? planId,
    int sessionIndex = 0,
    HapticService? hapticService,
    LiveHrService? liveHrService,
  }) : _sessionLogsDao = sessionLogsDao,
       _planId = planId,
       _sessionIndex = sessionIndex,
       _hapticService = hapticService,
       _liveHrService = liveHrService,
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
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    if (_liveHrService != null) {
      unawaited(_fetchAndEmitHr());
      _hrTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(_fetchAndEmitHr()),
      );
    }
  }

  void _tick(Timer _) {
    if (state.isComplete) return;
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
    if (_sessionLogsDao != null && _planId != null) {
      final now = DateTime.now();
      try {
        await _sessionLogsDao.insertLog(
          SessionLogsCompanion(
            dailyPlanId: Value(_planId),
            sessionIndex: Value(_sessionIndex),
            completedAt: Value(now),
            createdAt: Value(now),
          ),
        );
      } catch (e) {
        debugPrint('InSessionCubit: insertLog failed: $e');
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
    } catch (e) {
      debugPrint('InSessionCubit: fetchLiveHr failed: $e');
    }
  }

  /// Called by the Abandon button. Stops the timer and marks the session as
  /// abandoned (distinct from `isComplete`, which signals natural finish and
  /// drives the RPE navigation). Story 8.5 adds confirmation + partial
  /// session log write.
  void abandon() {
    _timer?.cancel();
    _hrTimer?.cancel();
    if (!isClosed) emit(state.copyWith(isAbandoned: true));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _hrTimer?.cancel();
    return super.close();
  }
}
