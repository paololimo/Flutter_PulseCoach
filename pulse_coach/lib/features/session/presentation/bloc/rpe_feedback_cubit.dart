import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
import 'package:pulse_coach/features/session/presentation/bloc/rpe_feedback_state.dart';

class RpeFeedbackCubit extends Cubit<RpeFeedbackState> {
  final RpeFeedbackDao _dao;
  final SessionLogsDao? _sessionLogsDao;
  final RpeSubmitArgs? _args;
  final Duration _animationDuration;
  final DateTime Function() _now;
  bool _submitted = false;
  Timer? _submitTimer;

  RpeFeedbackCubit({
    required RpeFeedbackDao dao,
    required RpeSubmitArgs? args,
    SessionLogsDao? sessionLogsDao,
    Duration animationDuration = const Duration(milliseconds: 150),
    DateTime Function()? now,
  }) : _dao = dao,
       _sessionLogsDao = sessionLogsDao,
       _args = args,
       _animationDuration = animationDuration,
       _now = now ?? DateTime.now,
       super(const RpeFeedbackInitial());

  void submit(int rpe) {
    if (_submitted || isClosed) return;
    _submitted = true;
    emit(RpeFeedbackAnimating(rpe));
    _submitTimer = Timer(_animationDuration, () {
      unawaited(_persist(rpe));
    });
  }

  Future<void> _persist(int rpe) async {
    try {
      final resolvedLogId = await _resolveSessionLogId();
      // `rpe_feedback.sessionId` historically pointed at `sessions.id`, but the
      // in-session flow now writes one `session_logs` row per run, so we
      // anchor every RPE row to that log id (mirrored in `sessionLogId` for
      // explicit traceability — E8-P3 justification).
      await _dao.insertFeedbackIdempotent(
        RpeFeedbackCompanion.insert(
          sessionId: resolvedLogId ?? 0,
          sessionLogId: Value(resolvedLogId),
          rpeValue: rpe,
          recordedAt: _now(),
        ),
      );
      if (!isClosed) emit(RpeFeedbackSubmitted(rpeValue: rpe));
    } catch (e) {
      // D3 (review): keep `_submitted = true` after error — AC5(a) makes
      // submit() single-shot. The user must dismiss the page to retry.
      if (!isClosed) emit(RpeFeedbackError(ServerFailure(e.toString())));
    }
  }

  Future<int?> _resolveSessionLogId() async {
    final explicit = _args?.sessionLogId;
    if (explicit != null) return explicit;
    final sessionLogsDao = _sessionLogsDao;
    if (sessionLogsDao == null) return null;

    final planId = _args?.planId;
    if (planId != null) {
      final log = await sessionLogsDao.getLogFor(planId, _args!.sessionIndex);
      return log?.id;
    }

    // Shared session (no DailyPlan, Story 21.0 — closes E20R-2 local half).
    // Story 20.4/20.5 deliberately never wrote a SessionLog here; create a
    // standalone row now, anchored to nothing but carrying the denormalized
    // sessionType/armKey/durationMinutes so Progress history (Task 2) can
    // render it without a DailyPlans join.
    final args = _args;
    if (args == null || args.armKey.isEmpty) return null;
    final now = _now();
    final id = await sessionLogsDao.insertLog(
      SessionLogsCompanion(
        dailyPlanId: const Value(null),
        sessionIndex: const Value(0),
        completedAt: Value(now),
        createdAt: Value(now),
        abandoned: Value(args.abandoned),
        sessionType: Value(args.armKey.split('_').first),
        armKey: Value(args.armKey),
        durationMinutes: Value(args.durationMinutes),
      ),
    );
    // insertLog uses InsertMode.insertOrIgnore, which returns 0 on a
    // suppressed UNIQUE-constraint conflict. As established in Task 1.1,
    // NULL dailyPlanId rows can never collide under UNIQUE(dailyPlanId,
    // sessionIndex) — so `id == 0` should not happen here in practice. Guard
    // anyway: a real conflict would otherwise silently anchor RPE to row 0.
    return id == 0 ? null : id;
  }

  @override
  Future<void> close() {
    _submitTimer?.cancel();
    return super.close();
  }
}
