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
      if (!isClosed) emit(const RpeFeedbackSubmitted());
    } catch (e) {
      // D3 (review): keep `_submitted = true` after error — AC5(a) makes
      // submit() single-shot. The user must dismiss the page to retry.
      if (!isClosed) emit(RpeFeedbackError(ServerFailure(e.toString())));
    }
  }

  Future<int?> _resolveSessionLogId() async {
    final explicit = _args?.sessionLogId;
    if (explicit != null) return explicit;
    final planId = _args?.planId;
    final sessionLogsDao = _sessionLogsDao;
    if (planId == null || sessionLogsDao == null) return null;
    final log = await sessionLogsDao.getLogFor(planId, _args!.sessionIndex);
    return log?.id;
  }

  @override
  Future<void> close() {
    _submitTimer?.cancel();
    return super.close();
  }
}
