import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
import 'package:pulse_coach/features/session/presentation/bloc/rpe_feedback_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/rpe_feedback_state.dart';

const _args = RpeSubmitArgs(
  planId: 42,
  sessionIndex: 1,
  abandoned: false,
  armKey: 'cardio_high',
  sessionLogId: 9,
);

void main() {
  group('RpeFeedbackCubit', () {
    blocTest<RpeFeedbackCubit, RpeFeedbackState>(
      '9.1-CUBIT-001: submit() emits Animating then Submitted on success',
      build: () => RpeFeedbackCubit(
        dao: _FakeRpeFeedbackDao(),
        args: _args,
        animationDuration: const Duration(milliseconds: 10),
      ),
      act: (cubit) => cubit.submit(7),
      wait: const Duration(milliseconds: 30),
      expect: () => [
        isA<RpeFeedbackAnimating>().having((state) => state.rpe, 'rpe', 7),
        isA<RpeFeedbackSubmitted>(),
      ],
    );

    blocTest<RpeFeedbackCubit, RpeFeedbackState>(
      '9.1-CUBIT-002: duplicate submit before Submitted is a no-op',
      build: () => RpeFeedbackCubit(
        dao: _FakeRpeFeedbackDao(),
        args: _args,
        animationDuration: const Duration(milliseconds: 10),
      ),
      act: (cubit) {
        cubit.submit(7);
        cubit.submit(5);
      },
      wait: const Duration(milliseconds: 30),
      expect: () => [
        isA<RpeFeedbackAnimating>().having((state) => state.rpe, 'rpe', 7),
        isA<RpeFeedbackSubmitted>(),
      ],
    );

    blocTest<RpeFeedbackCubit, RpeFeedbackState>(
      '9.1-CUBIT-003: submit() emits RpeFeedbackError on DAO failure',
      build: () => RpeFeedbackCubit(
        dao: _FakeRpeFeedbackDao(shouldThrow: true),
        args: _args,
        animationDuration: const Duration(milliseconds: 10),
      ),
      act: (cubit) => cubit.submit(7),
      wait: const Duration(milliseconds: 30),
      expect: () => [
        isA<RpeFeedbackAnimating>().having((state) => state.rpe, 'rpe', 7),
        isA<RpeFeedbackError>().having(
          (state) => state.failure.message,
          'failure message',
          contains('db full'),
        ),
      ],
    );

    test(
      '9.1-CUBIT-004: close() before Submitted prevents late emits',
      () async {
        final cubit = RpeFeedbackCubit(
          dao: _FakeRpeFeedbackDao(),
          args: _args,
          animationDuration: const Duration(milliseconds: 20),
        );
        final emitted = <RpeFeedbackState>[];
        final subscription = cubit.stream.listen(emitted.add);

        cubit.submit(7);
        await cubit.close();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await subscription.cancel();

        expect(emitted, hasLength(1));
        expect(emitted.single, isA<RpeFeedbackAnimating>());
      },
    );

    test(
      '9.1-CUBIT-005: insertFeedbackIdempotent receives sessionLogId-anchored '
      'sessionId and rpeValue (D1: rpe_feedback rows anchor on session_logs.id)',
      () async {
        final dao = _FakeRpeFeedbackDao();
        final now = DateTime.utc(2026, 5, 20, 9);
        final cubit = RpeFeedbackCubit(
          dao: dao,
          args: _args,
          animationDuration: Duration.zero,
          now: () => now,
        );

        cubit.submit(7);
        await Future<void>.delayed(Duration.zero);
        await cubit.close();

        expect(dao.inserted, hasLength(1));
        final row = dao.inserted.single;
        // P1 fix: sessionId mirrors the resolved sessionLogId (here 9 from
        // the explicit args), not the planId.
        expect(row.sessionId.value, 9);
        expect(row.sessionLogId, const Value<int?>(9));
        expect(row.rpeValue.value, 7);
        expect(row.recordedAt.value, now);
      },
    );

    test(
      '9.1-CUBIT-006: close() during in-flight DAO persist suppresses '
      'Submitted (P5: AC5(b) real cancellation invariant)',
      () async {
        final dao = _SlowFakeRpeFeedbackDao(
          completion: Completer<int>(),
        );
        final cubit = RpeFeedbackCubit(
          dao: dao,
          args: _args,
          animationDuration: Duration.zero,
        );
        final emitted = <RpeFeedbackState>[];
        final subscription = cubit.stream.listen(emitted.add);

        cubit.submit(7);
        // Let the Animating emit propagate and _persist enter the DAO call.
        await Future<void>.delayed(Duration.zero);
        await cubit.close();
        // Now resolve the in-flight insert — the cubit should NOT emit
        // Submitted because isClosed gates the late emit.
        dao.completion.complete(1);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await subscription.cancel();

        expect(
          emitted.whereType<RpeFeedbackSubmitted>(),
          isEmpty,
          reason: 'no Submitted emission after close()',
        );
      },
    );

    test(
      '9.1-CUBIT-007: submit() is single-shot after error — no retry '
      '(D3: AC5(a) strict idempotency)',
      () async {
        final dao = _ToggleFakeRpeFeedbackDao();
        final cubit = RpeFeedbackCubit(
          dao: dao,
          args: _args,
          animationDuration: Duration.zero,
        );
        final emitted = <RpeFeedbackState>[];
        final subscription = cubit.stream.listen(emitted.add);

        cubit.submit(7);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        // First attempt failed: state is RpeFeedbackError. A second tap
        // would historically reset `_submitted` and re-attempt; spec-correct
        // behaviour is no-op.
        cubit.submit(5);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await subscription.cancel();
        await cubit.close();

        expect(dao.callCount, 1, reason: 'DAO must not be called twice');
        expect(
          emitted.whereType<RpeFeedbackAnimating>(),
          hasLength(1),
          reason: 'only the first Animating emit should occur',
        );
        expect(
          emitted.last,
          isA<RpeFeedbackError>(),
          reason: 'cubit stays in error state until disposed',
        );
      },
    );
  });
}

class _FakeRpeFeedbackDao extends Fake implements RpeFeedbackDao {
  final List<RpeFeedbackCompanion> inserted = [];
  final bool shouldThrow;

  _FakeRpeFeedbackDao({this.shouldThrow = false});

  @override
  Future<int> insertFeedbackIdempotent(RpeFeedbackCompanion entry) async {
    if (shouldThrow) throw Exception('db full');
    inserted.add(entry);
    return 1;
  }
}

class _SlowFakeRpeFeedbackDao extends Fake implements RpeFeedbackDao {
  final Completer<int> completion;

  _SlowFakeRpeFeedbackDao({required this.completion});

  @override
  Future<int> insertFeedbackIdempotent(RpeFeedbackCompanion entry) =>
      completion.future;
}

class _ToggleFakeRpeFeedbackDao extends Fake implements RpeFeedbackDao {
  int callCount = 0;

  @override
  Future<int> insertFeedbackIdempotent(RpeFeedbackCompanion entry) async {
    callCount += 1;
    throw Exception('db full');
  }
}
