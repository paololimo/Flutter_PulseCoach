import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart'
    show SessionLogsCompanion;
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';

class TodaySessionState {
  final int heroIndex;
  final Set<int> completedIndices;
  final int totalSessions;

  const TodaySessionState({
    this.heroIndex = 0,
    this.completedIndices = const <int>{},
    this.totalSessions = 0,
  });

  int get completedCount => completedIndices.length;

  bool isCompleted(int index) => completedIndices.contains(index);

  TodaySessionState copyWith({
    int? heroIndex,
    Set<int>? completedIndices,
    int? totalSessions,
  }) => TodaySessionState(
    heroIndex: heroIndex ?? this.heroIndex,
    completedIndices: completedIndices ?? this.completedIndices,
    totalSessions: totalSessions ?? this.totalSessions,
  );
}

@injectable
class TodaySessionCubit extends Cubit<TodaySessionState> {
  final SessionLogsDao _sessionLogsDao;
  int? _currentPlanId;

  TodaySessionCubit(this._sessionLogsDao) : super(const TodaySessionState());

  Future<void> planLoaded(int totalSessions, int? planId) async {
    if (planId == null) {
      _currentPlanId = null;
      emit(TodaySessionState(totalSessions: totalSessions));
      return;
    }

    _currentPlanId = planId;
    final logs = await _sessionLogsDao.getLogsForPlan(planId);
    if (isClosed) return;
    // Discard the result if a newer planLoaded landed while we were awaiting —
    // otherwise stale logs from a prior plan would overwrite the active state.
    if (_currentPlanId != planId) return;

    final completed = <int>{
      for (final log in logs)
        // Drop any stale rows whose index falls outside the new plan's
        // session count (covers the "regenerate produced fewer sessions" case;
        // also defends against schema drift).
        if (log.sessionIndex >= 0 && log.sessionIndex < totalSessions)
          log.sessionIndex,
    };
    final heroIndex = _pickHeroIndex(completed, totalSessions, after: -1);
    emit(
      TodaySessionState(
        heroIndex: heroIndex,
        completedIndices: completed,
        totalSessions: totalSessions,
      ),
    );
  }

  void swapHero(int tappedSessionIndex) {
    if (tappedSessionIndex < 0 ||
        tappedSessionIndex >= state.totalSessions ||
        state.isCompleted(tappedSessionIndex)) {
      return;
    }
    emit(state.copyWith(heroIndex: tappedSessionIndex));
  }

  Future<void> markSessionCompleted() async {
    if (state.totalSessions == 0 ||
        state.completedCount >= state.totalSessions ||
        state.isCompleted(state.heroIndex)) {
      return;
    }

    final planIdAtStart = _currentPlanId;
    final heroAtStart = state.heroIndex;

    if (planIdAtStart != null) {
      final now = DateTime.now();
      try {
        await _sessionLogsDao.insertLog(
          SessionLogsCompanion(
            dailyPlanId: Value(planIdAtStart),
            sessionIndex: Value(heroAtStart),
            completedAt: Value(now),
            createdAt: Value(now),
          ),
        );
      } catch (e) {
        // DB-locked / disk-full / FK constraint — degrade silently rather than
        // freeze the UI. The next planLoaded will reconcile from the source of
        // truth.
        debugPrint('TodaySessionCubit: insertLog failed: $e');
        return;
      }
      if (isClosed) return;
      // If a regenerate landed during the insert, do not mutate the new plan's
      // state with the prior plan's hero.
      if (_currentPlanId != planIdAtStart) return;
    } else {
      if (isClosed) return;
    }

    final newCompleted = <int>{...state.completedIndices, heroAtStart};
    final nextHero = _pickHeroIndex(
      newCompleted,
      state.totalSessions,
      after: heroAtStart,
    );
    emit(
      state.copyWith(
        completedIndices: newCompleted,
        heroIndex: nextHero,
      ),
    );
  }

  /// Picks the next incomplete session index, searching forward from
  /// [after] + 1 and wrapping. When every session is complete, returns the
  /// last index so the UI never points the hero at a completed session — the
  /// `allDone` branch in TodayPage takes over and the value is only used as
  /// a stable copyWith input.
  static int _pickHeroIndex(
    Set<int> completed,
    int total, {
    required int after,
  }) {
    if (total == 0) return 0;
    for (var i = after + 1; i < total; i++) {
      if (!completed.contains(i)) return i;
    }
    for (var i = 0; i < total; i++) {
      if (!completed.contains(i)) return i;
    }
    return total - 1;
  }
}
