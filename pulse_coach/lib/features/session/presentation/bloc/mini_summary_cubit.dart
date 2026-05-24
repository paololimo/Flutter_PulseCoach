import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
import 'package:pulse_coach/features/session/presentation/bloc/mini_summary_state.dart';

const String _miniSummaryLoadFailedMessage = 'mini_summary_load_failed';

class MiniSummaryCubit extends Cubit<MiniSummaryState> {
  final MiniSummaryArgs _args;
  final SessionLogsDao _sessionLogsDao;
  final DailyPlansDao _dailyPlansDao;
  final Duration _holdDuration;
  final Duration _fadeDuration;
  Timer? _holdTimer;
  Timer? _fadeTimer;

  MiniSummaryCubit({
    required MiniSummaryArgs args,
    required SessionLogsDao sessionLogsDao,
    required DailyPlansDao dailyPlansDao,
    Duration holdDuration = const Duration(milliseconds: 3000),
    Duration fadeDuration = const Duration(milliseconds: 300),
  }) : _args = args,
       _sessionLogsDao = sessionLogsDao,
       _dailyPlansDao = dailyPlansDao,
       _holdDuration = holdDuration,
       _fadeDuration = fadeDuration,
       super(const MiniSummaryInitial());

  Future<void> init() async {
    try {
      final (completedCount, totalSessions) = await _loadPlanData();
      if (isClosed) return;
      final newCompletedCount = completedCount;
      final increment = _args.abandoned ? 0 : 1;
      final previousCompletedCount = newCompletedCount - increment;

      emit(
        MiniSummaryLoaded(
          previousCompletedCount: _clampCount(
            previousCompletedCount,
            totalSessions,
          ),
          newCompletedCount: _clampCount(newCompletedCount, totalSessions),
          totalSessions: totalSessions,
        ),
      );
      _scheduleAutoDismiss();
    } catch (e, st) {
      // Review patch #8: keep a stable, non-leaky failure message; raw
      // exception text goes to debug logs only.
      AppLogger.error(
        'load failed',
        name: 'MiniSummaryCubit',
        error: e,
        stackTrace: st,
      );
      if (!isClosed) {
        emit(
          const MiniSummaryError(ServerFailure(_miniSummaryLoadFailedMessage)),
        );
      }
    }
  }

  Future<(int completedCount, int totalSessions)> _loadPlanData() async {
    final planId = _args.planId;
    if (planId == null) return (0, 0);

    final logs = await _sessionLogsDao.getLogsForPlan(planId);
    final completedCount = logs.where((log) => !log.abandoned).length;

    final planRow = await _dailyPlansDao.getPlanById(planId);
    var totalSessions = 0;
    if (planRow != null) {
      // Review decision #2: malformed planJson is now a hard error so the
      // user is not silently shown a 0/0 ring. Outer try/catch in init()
      // turns this into MiniSummaryError → BlocListener routes to Today.
      final planJson = jsonDecode(planRow.planJson) as Map<String, dynamic>;
      final plan = DailyPlan.fromJson(planJson);
      totalSessions = plan.sessions.length;
    }
    return (completedCount, totalSessions);
  }

  int _clampCount(int count, int totalSessions) =>
      count.clamp(0, totalSessions).toInt();

  void _scheduleAutoDismiss() {
    _holdTimer = Timer(_holdDuration, () {
      if (isClosed) return;
      emit(const MiniSummaryFading());
      _fadeTimer = Timer(_fadeDuration, () {
        if (!isClosed) emit(const MiniSummaryDone());
      });
    });
  }

  @override
  Future<void> close() {
    _holdTimer?.cancel();
    _fadeTimer?.cancel();
    return super.close();
  }
}
