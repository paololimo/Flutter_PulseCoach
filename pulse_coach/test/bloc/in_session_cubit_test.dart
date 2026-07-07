import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart'
    show SessionLogsCompanion;
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';

const _steps = [
  ExerciseStep(title: 'Warm-up', instruction: 'Prep', durationSeconds: 3),
  ExerciseStep(title: 'Main', instruction: 'Go', durationSeconds: 2),
  ExerciseStep(title: 'Cool-down', instruction: 'Rest', durationSeconds: 2),
];

InSessionCubit _cubit() => InSessionCubit(steps: _steps);

class _FakeSessionLogsDao extends Fake implements SessionLogsDao {
  final List<SessionLogsCompanion> insertedLogs = [];
  final List<SessionLogsCompanion> upsertedCompletions = [];

  @override
  Future<int> insertLog(SessionLogsCompanion entry) async {
    insertedLogs.add(entry);
    return 1;
  }

  @override
  Future<int> upsertCompletion(SessionLogsCompanion entry) async {
    upsertedCompletions.add(entry);
    return 1;
  }
}

class _ThrowingCompletionSessionLogsDao extends _FakeSessionLogsDao {
  @override
  Future<int> upsertCompletion(SessionLogsCompanion entry) async {
    throw StateError('db error');
  }
}

/// Drives DateTime.now() in tests where `tester.pump(Duration)` advances
/// Timer.periodic but not the wall clock.
class _ManualClock {
  DateTime current;
  _ManualClock(this.current);
  DateTime call() => current;
  void advance(Duration d) => current = current.add(d);
}

/// Holds insertLog open until the test completes the completer — lets us
/// observe state between emit and DAO resolution.
class _SlowSessionLogsDao extends Fake implements SessionLogsDao {
  final Completer<int> completer = Completer<int>();

  @override
  Future<int> insertLog(SessionLogsCompanion entry) => completer.future;
}

void main() {
  group('InSessionCubit', () {
    testWidgets('8.2-CUBIT-001: initial state', (tester) async {
      final cubit = _cubit();

      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.secondsRemaining, _steps[0].durationSeconds);
      expect(cubit.state.isComplete, isFalse);

      await cubit.close();
    });

    testWidgets('8.2-CUBIT-002: tick decrements secondsRemaining', (
      tester,
    ) async {
      final cubit = _cubit()..start();

      await tester.pump(const Duration(seconds: 1));

      expect(cubit.state.secondsRemaining, _steps[0].durationSeconds - 1);
      await cubit.close();
    });

    testWidgets('8.2-CUBIT-003: step advances after timer shows 00:00', (
      tester,
    ) async {
      final cubit = _cubit()..start();

      // duration N ticks reach secondsRemaining=0 (the 00:00 frame); the
      // (N+1)-th tick advances to the next step. See 8.2-CUBIT-007 for the
      // explicit 00:00 frame assertion.
      await tester.pump(Duration(seconds: _steps[0].durationSeconds + 1));

      expect(cubit.state.currentStepIndex, 1);
      expect(cubit.state.secondsRemaining, _steps[1].durationSeconds);
      await cubit.close();
    });

    testWidgets('8.2-CUBIT-004: all steps complete emits isComplete', (
      tester,
    ) async {
      final cubit = _cubit()..start();
      // Each step now consumes durationSeconds + 1 ticks (the extra tick is
      // the visible 00:00 frame before advancing).
      final totalSeconds = _steps.fold<int>(
        0,
        (sum, step) => sum + step.durationSeconds + 1,
      );

      await tester.pump(Duration(seconds: totalSeconds));
      await tester.pump();

      expect(cubit.state.isComplete, isTrue);
      await cubit.close();
    });

    testWidgets(
      '10.0-CUBIT-001: completion DAO failure emits persistenceError and isComplete',
      (tester) async {
        final dao = _ThrowingCompletionSessionLogsDao();
        final cubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 42,
        )..start();
        final totalSeconds = _steps.fold<int>(
          0,
          (sum, step) => sum + step.durationSeconds + 1,
        );

        await tester.pump(Duration(seconds: totalSeconds));
        await tester.pump();

        expect(cubit.state.isComplete, isTrue);
        expect(
          cubit.state.persistenceError,
          const ServerFailure('session_log_write_failed'),
        );
        await cubit.close();
      },
    );

    testWidgets(
      '10.0-CUBIT-002: completion DAO success leaves persistenceError null',
      (tester) async {
        final dao = _FakeSessionLogsDao();
        final cubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 42,
        )..start();
        final totalSeconds = _steps.fold<int>(
          0,
          (sum, step) => sum + step.durationSeconds + 1,
        );

        await tester.pump(Duration(seconds: totalSeconds));
        await tester.pump();

        expect(cubit.state.isComplete, isTrue);
        expect(cubit.state.persistenceError, isNull);
        await cubit.close();
      },
    );

    testWidgets('8.2-CUBIT-007: timer renders 00:00 before advancing', (
      tester,
    ) async {
      final cubit = _cubit()..start();

      // After N ticks the first step has decremented from N→0 (the 00:00
      // frame). The next tick is what advances to step 2 — confirm we are
      // still on step 0 here.
      await tester.pump(Duration(seconds: _steps[0].durationSeconds));

      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.secondsRemaining, 0);
      await cubit.close();
    });

    testWidgets('8.2-CUBIT-005: close cancels timer without error', (
      tester,
    ) async {
      final cubit = _cubit()..start();

      await cubit.close();
      await tester.pump(const Duration(seconds: 10));

      expect(cubit.isClosed, isTrue);
    });

    testWidgets(
      '8.2-CUBIT-006: abandon emits isAbandoned (not isComplete) and stops timer',
      (tester) async {
        final cubit = _cubit()..start();

        await cubit.abandon();
        final stateAfterAbandon = cubit.state;
        await tester.pump(const Duration(seconds: 10));

        expect(cubit.state.isAbandoned, isTrue);
        // isComplete must remain false so the RPE-bound BlocListener does not
        // fire on abandon (avoids double navigation RPE + Today).
        expect(cubit.state.isComplete, isFalse);
        expect(
          cubit.state.currentStepIndex,
          stateAfterAbandon.currentStepIndex,
        );
        expect(
          cubit.state.secondsRemaining,
          stateAfterAbandon.secondsRemaining,
        );
        await cubit.close();
      },
    );

    testWidgets('8.5-CUBIT-001: abandon after 3 ticks marks abandoned only', (
      tester,
    ) async {
      final cubit = _cubit()..start();

      await tester.pump(const Duration(seconds: 3));
      await cubit.abandon();

      expect(cubit.state.isAbandoned, isTrue);
      expect(cubit.state.isComplete, isFalse);
      await cubit.close();
    });

    testWidgets(
      '8.5-CUBIT-002: abandon persists wall-clock elapsed seconds and current step',
      (tester) async {
        final dao = _FakeSessionLogsDao();
        final clock = _ManualClock(DateTime.utc(2026, 5, 17, 9));
        final cubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 42,
          sessionIndex: 1,
          now: clock.call,
        )..start();

        await tester.pump(const Duration(seconds: 3));
        clock.advance(const Duration(seconds: 3));
        await cubit.abandon();

        expect(dao.insertedLogs, hasLength(1));
        final inserted = dao.insertedLogs.single;
        expect(inserted.dailyPlanId, const Value(42));
        expect(inserted.sessionIndex, const Value(1));
        expect(inserted.abandoned, const Value(true));
        expect(inserted.elapsedSeconds, const Value(3));
        // Renamed from lastCompletedStepIndex (review D1): the cubit records
        // the CURRENT step at the moment of abandon, not the last completed.
        expect(inserted.currentStepIndex, const Value(0));
        await cubit.close();
      },
    );

    testWidgets(
      '8.5-CUBIT-005: abandon at start (no elapsed time) writes elapsedSeconds=0 with currentStepIndex=0',
      (tester) async {
        final dao = _FakeSessionLogsDao();
        final clock = _ManualClock(DateTime.utc(2026, 5, 17, 9));
        final cubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 42,
          now: clock.call,
        )..start();

        // No time advance — abandon immediately after start.
        await cubit.abandon();

        expect(dao.insertedLogs, hasLength(1));
        expect(dao.insertedLogs.single.elapsedSeconds, const Value(0));
        expect(dao.insertedLogs.single.currentStepIndex, const Value(0));
        await cubit.close();
      },
    );

    testWidgets(
      '8.5-CUBIT-006: abandon does NOT use upsertCompletion path (only insertLog)',
      (tester) async {
        final dao = _FakeSessionLogsDao();
        final cubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 42,
        )..start();

        await tester.pump(const Duration(seconds: 1));
        await cubit.abandon();

        expect(dao.insertedLogs, hasLength(1));
        // Completion path is untouched on abandon — the upsert is reserved
        // for actual session completion (review BLOCKER #1 fix).
        expect(dao.upsertedCompletions, isEmpty);
        await cubit.close();
      },
    );

    testWidgets(
      '8.5-CUBIT-007: emits isAbandoned BEFORE awaiting persistence (UI race fix)',
      (tester) async {
        final dao = _SlowSessionLogsDao();
        final cubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 42,
        )..start();

        await tester.pump(const Duration(seconds: 1));
        final abandonFuture = cubit.abandon();
        // Allow the synchronous emit to land but don't yet drain the await on
        // the DAO — state should already report isAbandoned.
        await tester.pump();
        expect(
          cubit.state.isAbandoned,
          isTrue,
          reason: 'isAbandoned must be emitted before persistence resolves',
        );
        dao.completer.complete(1);
        await abandonFuture;
        await cubit.close();
      },
    );

    testWidgets('8.5-CUBIT-003: abandon is idempotent', (tester) async {
      final dao = _FakeSessionLogsDao();
      final cubit = InSessionCubit(
        steps: _steps,
        sessionLogsDao: dao,
        planId: 42,
      )..start();

      await tester.pump(const Duration(seconds: 1));
      await cubit.abandon();
      await tester.pump();
      final stateAfterFirstAbandon = cubit.state;
      await cubit.abandon();
      await tester.pump();

      expect(dao.insertedLogs, hasLength(1));
      expect(cubit.state, stateAfterFirstAbandon);

      await cubit.close();
    });

    testWidgets(
      '8.5-CUBIT-004: abandon without SessionLogsDao still emits abandoned',
      (tester) async {
        final cubit = _cubit()..start();

        await tester.pump(const Duration(seconds: 1));
        await cubit.abandon();

        expect(cubit.state.isAbandoned, isTrue);
        expect(cubit.state.isComplete, isFalse);
        await cubit.close();
      },
    );

    testWidgets(
      '22.5-CUBIT-004: elapsedSeconds getter reflects wall-clock time since '
      'start() (before any abandon/completion)',
      (tester) async {
        final clock = _ManualClock(DateTime.utc(2026, 7, 7, 9));
        final cubit = InSessionCubit(steps: _steps, now: clock.call)..start();

        expect(cubit.elapsedSeconds, 0);
        clock.advance(const Duration(seconds: 4));
        expect(cubit.elapsedSeconds, 4);

        await cubit.close();
      },
    );

    testWidgets(
      '22.5-CUBIT-005: elapsedSeconds is 0 before start() is called',
      (tester) async {
        final cubit = _cubit();

        expect(cubit.elapsedSeconds, 0);

        await cubit.close();
      },
    );

    testWidgets(
      '22.5-CUBIT-006: reseedElapsed re-anchors elapsedSeconds, discarding '
      'wall-clock time accrued while backgrounded (review F2 fix)',
      (tester) async {
        final dao = _FakeSessionLogsDao();
        final clock = _ManualClock(DateTime.utc(2026, 7, 7, 9));
        final cubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 42,
          now: clock.call,
        )..start();

        // 10s elapsed pre-background.
        clock.advance(const Duration(seconds: 10));
        expect(cubit.elapsedSeconds, 10);

        // App backgrounded for a long, unrelated wall-clock stretch (e.g. 3
        // minutes) — without reseedElapsed, elapsedSeconds would inflate by
        // the full background duration on resume.
        clock.advance(const Duration(minutes: 3));

        // Warm resume re-anchors to the snapshot's persisted elapsedSeconds
        // (10, taken at the moment of backgrounding), not the 190s that
        // wall-clock math alone would now report.
        cubit.reseedElapsed(10);

        expect(cubit.elapsedSeconds, 10);

        clock.advance(const Duration(seconds: 5));
        expect(cubit.elapsedSeconds, 15);

        await cubit.abandon();
        expect(dao.insertedLogs.single.elapsedSeconds, const Value(15));

        await cubit.close();
      },
    );

    testWidgets(
      '22.5-CUBIT-001: constructed with initialStepIndex/'
      'initialSecondsRemaining → initial state reflects those values, not '
      'step 0 / full duration',
      (tester) async {
        final cubit = InSessionCubit(
          steps: _steps,
          initialStepIndex: 1,
          initialSecondsRemaining: 1,
        );

        expect(cubit.state.currentStepIndex, 1);
        expect(cubit.state.secondsRemaining, 1);

        await cubit.close();
      },
    );

    testWidgets(
      '22.5-CUBIT-002: constructed with initialElapsedSeconds, then abandon() '
      'called → persisted elapsedSeconds continues from the seeded value '
      '(not reset to ~0)',
      (tester) async {
        final dao = _FakeSessionLogsDao();
        final clock = _ManualClock(DateTime.utc(2026, 7, 7, 9));
        final cubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 42,
          now: clock.call,
          initialElapsedSeconds: 100,
        )..start();

        clock.advance(const Duration(seconds: 5));
        await cubit.abandon();

        expect(dao.insertedLogs, hasLength(1));
        expect(dao.insertedLogs.single.elapsedSeconds, const Value(105));

        await cubit.close();
      },
    );

    testWidgets(
      '22.5-CUBIT-003: existing (un-seeded) construction still behaves '
      'exactly as before (regression guard — no seeded params passed)',
      (tester) async {
        final cubit = _cubit();

        expect(cubit.state.currentStepIndex, 0);
        expect(cubit.state.secondsRemaining, _steps[0].durationSeconds);

        await cubit.close();
      },
    );

    testWidgets(
      '8.5-CUBIT-008: pauseTimers + resumeTimers preserves countdown state',
      (tester) async {
        final cubit = _cubit()..start();
        await tester.pump(const Duration(seconds: 1));
        final pausedRemaining = cubit.state.secondsRemaining;

        cubit.pauseTimers();
        await tester.pump(const Duration(seconds: 5));

        // No tick fired while paused.
        expect(cubit.state.secondsRemaining, pausedRemaining);

        cubit.resumeTimers();
        await tester.pump(const Duration(seconds: 1));

        expect(cubit.state.secondsRemaining, pausedRemaining - 1);
        await cubit.close();
      },
    );

    testWidgets(
      '8.5-CUBIT-009: regression — abandon then complete same session goes through completion path',
      (tester) async {
        final dao = _FakeSessionLogsDao();
        final clock = _ManualClock(DateTime.utc(2026, 5, 17, 9));
        final firstCubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 7,
          sessionIndex: 0,
          now: clock.call,
        )..start();
        await tester.pump(const Duration(seconds: 2));
        clock.advance(const Duration(seconds: 2));
        await firstCubit.abandon();
        await firstCubit.close();

        // Same (planId=7, sessionIndex=0) — completion path on retry.
        final secondCubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: dao,
          planId: 7,
          sessionIndex: 0,
          now: clock.call,
        )..start();
        // Drive all steps to natural completion.
        final totalSeconds = _steps.fold<int>(
          0,
          (sum, step) => sum + step.durationSeconds + 1,
        );
        await tester.pump(Duration(seconds: totalSeconds));
        await tester.pump();

        // The completion call goes through upsertCompletion, NOT insertLog
        // (which would have been silently ignored by insertOrIgnore + UNIQUE
        // and left the abandoned row as the source of truth).
        expect(dao.upsertedCompletions, hasLength(1));
        expect(dao.upsertedCompletions.single.sessionIndex, const Value(0));
        await secondCubit.close();
      },
    );
  });
}
