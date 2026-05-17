import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/database/app_database.dart'
    show SessionLogsCompanion;
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';

class InSessionCubit extends Cubit<InSessionState> {
  final SessionLogsDao? _sessionLogsDao;
  final int? _planId;
  final int _sessionIndex;
  Timer? _timer;

  InSessionCubit({
    required List<ExerciseStep> steps,
    SessionLogsDao? sessionLogsDao,
    int? planId,
    int sessionIndex = 0,
  }) : _sessionLogsDao = sessionLogsDao,
       _planId = planId,
       _sessionIndex = sessionIndex,
       super(
         InSessionState(
           steps: steps,
           currentStepIndex: 0,
           secondsRemaining: steps.first.durationSeconds,
         ),
       );

  /// Starts the 1-second countdown tick. Call once from State.initState equivalent.
  void start() {
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
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
      _timer?.cancel();
      unawaited(_persistCompletion());
    } else {
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

  /// Called by the Abandon button. Stops the timer and marks the session as
  /// abandoned (distinct from `isComplete`, which signals natural finish and
  /// drives the RPE navigation). Story 8.5 adds confirmation + partial
  /// session log write.
  void abandon() {
    _timer?.cancel();
    if (!isClosed) emit(state.copyWith(isAbandoned: true));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
