import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart' as db;
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
import 'package:pulse_coach/features/session/presentation/bloc/mini_summary_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/mini_summary_state.dart';

void main() {
  group('MiniSummaryCubit', () {
    test(
      '9.2-CUBIT-001: init() emits Loaded with completedCount and totalSessions',
      () async {
        final cubit = _buildCubit(
          logs: [_log(0), _log(1)],
          planRow: _planRow(sessionCount: 3),
        );
        final emitted = <MiniSummaryState>[];
        final subscription = cubit.stream.listen(emitted.add);

        await cubit.init();
        await Future<void>.delayed(Duration.zero);

        expect(emitted, hasLength(1));
        expect(
          emitted.single,
          isA<MiniSummaryLoaded>()
              .having((state) => state.previousCompletedCount, 'previous', 1)
              .having((state) => state.newCompletedCount, 'new', 2)
              .having((state) => state.totalSessions, 'total', 3),
        );
        await subscription.cancel();
        await cubit.close();
      },
    );

    test(
      '9.2-CUBIT-002: auto-dismiss fires Fading then Done after hold and fade',
      () async {
        final cubit = _buildCubit(
          logs: [_log(0)],
          planRow: _planRow(sessionCount: 3),
          holdDuration: const Duration(milliseconds: 10),
          fadeDuration: const Duration(milliseconds: 10),
        );
        final emitted = <MiniSummaryState>[];
        final subscription = cubit.stream.listen(emitted.add);

        await cubit.init();
        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(emitted[0], isA<MiniSummaryLoaded>());
        expect(emitted[1], isA<MiniSummaryFading>());
        expect(emitted[2], isA<MiniSummaryDone>());
        await subscription.cancel();
        await cubit.close();
      },
    );

    // 9.2-CUBIT-003 removed (review patch #6): the original test asserted the
    // same sequence as CUBIT-002 without toggling any motion flag, so it was
    // tautological. Reduce Motion is now covered at the widget layer where
    // MediaQuery.disableAnimations is actually meaningful.

    test(
      '9.2-CUBIT-004: close() before timer fires prevents Done emit',
      () async {
        final cubit = _buildCubit(
          logs: [_log(0)],
          planRow: _planRow(sessionCount: 3),
          holdDuration: const Duration(milliseconds: 80),
          fadeDuration: const Duration(milliseconds: 10),
        );
        final emitted = <MiniSummaryState>[];
        final subscription = cubit.stream.listen(emitted.add);

        await cubit.init();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await cubit.close();
        await Future<void>.delayed(const Duration(milliseconds: 120));

        expect(emitted.whereType<MiniSummaryDone>(), isEmpty);
        await subscription.cancel();
      },
    );

    test(
      '9.2-CUBIT-005: abandoned=true keeps previousCompletedCount equal to newCompletedCount',
      () async {
        final cubit = _buildCubit(
          args: _args(abandoned: true),
          logs: [_log(0)],
          planRow: _planRow(sessionCount: 3),
        );
        final emitted = <MiniSummaryState>[];
        final subscription = cubit.stream.listen(emitted.add);

        await cubit.init();
        await Future<void>.delayed(Duration.zero);

        expect(
          emitted.single,
          isA<MiniSummaryLoaded>()
              .having((state) => state.previousCompletedCount, 'previous', 1)
              .having((state) => state.newCompletedCount, 'new', 1)
              .having((state) => state.totalSessions, 'total', 3),
        );
        await subscription.cancel();
        await cubit.close();
      },
    );

    test(
      '9.2-CUBIT-006: DB failure in _loadPlanData emits MiniSummaryError',
      () async {
        final cubit = _buildCubit(shouldThrow: true);
        final emitted = <MiniSummaryState>[];
        final subscription = cubit.stream.listen(emitted.add);

        await cubit.init();
        await Future<void>.delayed(Duration.zero);

        expect(
          emitted.single,
          isA<MiniSummaryError>().having(
            (state) => state.failure.message,
            'failure message',
            // Review patch #8: stable, non-leaky message.
            'mini_summary_load_failed',
          ),
        );
        await subscription.cancel();
        await cubit.close();
      },
    );

    test(
      '9.2-CUBIT-008: malformed planJson emits MiniSummaryError (review decision #2)',
      () async {
        final corruptRow = _corruptPlanRow();
        final cubit = MiniSummaryCubit(
          args: _args(),
          sessionLogsDao: _FakeSessionLogsDao(logs: [_log(0)]),
          dailyPlansDao: _FakeDailyPlansDao(planRow: corruptRow),
        );
        final emitted = <MiniSummaryState>[];
        final subscription = cubit.stream.listen(emitted.add);

        await cubit.init();
        await Future<void>.delayed(Duration.zero);

        expect(emitted.single, isA<MiniSummaryError>());
        await subscription.cancel();
        await cubit.close();
      },
    );

    test(
      '9.2-CUBIT-007: planId==null emits Loaded(0,0,0) and still auto-dismisses',
      () async {
        final sessionLogsDao = _FakeSessionLogsDao();
        final dailyPlansDao = _FakeDailyPlansDao();
        final cubit = MiniSummaryCubit(
          args: _args(planId: null),
          sessionLogsDao: sessionLogsDao,
          dailyPlansDao: dailyPlansDao,
          holdDuration: const Duration(milliseconds: 10),
          fadeDuration: const Duration(milliseconds: 10),
        );
        final emitted = <MiniSummaryState>[];
        final subscription = cubit.stream.listen(emitted.add);

        await cubit.init();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(sessionLogsDao.callCount, 0);
        expect(dailyPlansDao.callCount, 0);
        expect(
          emitted.first,
          isA<MiniSummaryLoaded>()
              .having((state) => state.previousCompletedCount, 'previous', 0)
              .having((state) => state.newCompletedCount, 'new', 0)
              .having((state) => state.totalSessions, 'total', 0),
        );
        expect(emitted[1], isA<MiniSummaryFading>());
        expect(emitted[2], isA<MiniSummaryDone>());
        await subscription.cancel();
        await cubit.close();
      },
    );
  });
}

MiniSummaryCubit _buildCubit({
  MiniSummaryArgs? args,
  List<db.SessionLog> logs = const [],
  db.DailyPlan? planRow,
  bool shouldThrow = false,
  Duration holdDuration = const Duration(seconds: 3),
  Duration fadeDuration = const Duration(milliseconds: 300),
}) {
  return MiniSummaryCubit(
    args: args ?? _args(),
    sessionLogsDao: _FakeSessionLogsDao(logs: logs, shouldThrow: shouldThrow),
    dailyPlansDao: _FakeDailyPlansDao(planRow: planRow),
    holdDuration: holdDuration,
    fadeDuration: fadeDuration,
  );
}

MiniSummaryArgs _args({bool abandoned = false, int? planId = 42}) =>
    MiniSummaryArgs(
      rpeValue: 7,
      sessionType: 'cardio',
      durationMinutes: 12,
      abandoned: abandoned,
      planId: planId,
    );

db.SessionLog _log(int sessionIndex, {bool abandoned = false}) => db.SessionLog(
  id: sessionIndex + 1,
  dailyPlanId: 42,
  sessionIndex: sessionIndex,
  completedAt: DateTime.utc(2026, 5, 21, 9, sessionIndex),
  createdAt: DateTime.utc(2026, 5, 21, 9, sessionIndex),
  abandoned: abandoned,
);

db.DailyPlan _planRow({required int sessionCount}) {
  final generatedAt = DateTime.utc(2026, 5, 21, 8);
  final plan = domain.DailyPlan(
    planDate: '2026-05-21',
    sessions: List.generate(
      sessionCount,
      (_) => const PlannedSession(
        sessionType: 'cardio',
        intensity: 5,
        durationMinutes: 12,
        isIndoor: true,
      ),
    ),
    generatedAt: generatedAt,
  );
  return db.DailyPlan(
    id: 42,
    planDate: '2026-05-21',
    planJson: jsonEncode(plan.toJson()),
    generatedAt: generatedAt,
    createdAt: generatedAt,
    isCompleted: false,
  );
}

db.DailyPlan _corruptPlanRow() {
  final generatedAt = DateTime.utc(2026, 5, 21, 8);
  return db.DailyPlan(
    id: 42,
    planDate: '2026-05-21',
    planJson: '{not json',
    generatedAt: generatedAt,
    createdAt: generatedAt,
    isCompleted: false,
  );
}

class _FakeSessionLogsDao extends Fake implements SessionLogsDao {
  final List<db.SessionLog> logs;
  final bool shouldThrow;
  int callCount = 0;

  _FakeSessionLogsDao({this.logs = const [], this.shouldThrow = false});

  @override
  Future<List<db.SessionLog>> getLogsForPlan(int planId) async {
    callCount += 1;
    if (shouldThrow) throw Exception('db error');
    return logs;
  }
}

class _FakeDailyPlansDao extends Fake implements DailyPlansDao {
  final db.DailyPlan? planRow;
  int callCount = 0;

  _FakeDailyPlansDao({this.planRow});

  @override
  Future<db.DailyPlan?> getPlanById(int id) async {
    callCount += 1;
    return planRow;
  }
}
