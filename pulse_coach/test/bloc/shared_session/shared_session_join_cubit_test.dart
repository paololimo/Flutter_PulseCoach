// [20.3-CUBIT-001..007] SharedSessionJoinCubit tests
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/join_shared_session_use_case.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_join_cubit.dart';

@GenerateMocks([JoinSharedSessionUseCase])
import 'shared_session_join_cubit_test.mocks.dart';

final _kSession = SharedSession(
  id: 'sess-uuid',
  hostUserId: 'host-uuid',
  joinCode: 'ABC123',
  status: 'waiting',
  createdAt: DateTime(2026, 6, 26),
);

void main() {
  late MockJoinSharedSessionUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockJoinSharedSessionUseCase();
  });

  group('SharedSessionJoinCubit (20.3)', () {
    blocTest<SharedSessionJoinCubit, SharedSessionJoinState>(
      '20.3-CUBIT-001: initial state is initial',
      build: () => SharedSessionJoinCubit(mockUseCase),
      expect: () => [],
    );

    blocTest<SharedSessionJoinCubit, SharedSessionJoinState>(
      '20.3-CUBIT-002: join() success emits [joining, joined(sessionId)] (AC2)',
      build: () => SharedSessionJoinCubit(mockUseCase),
      setUp: () {
        when(mockUseCase.call(
          joinCode: anyNamed('joinCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => Right(_kSession));
      },
      act: (c) => c.join(joinCode: 'ABC123', userId: 'user-uuid'),
      expect: () => [
        const SharedSessionJoinState.joining(),
        const SharedSessionJoinState.joined(sessionId: 'sess-uuid'),
      ],
    );

    blocTest<SharedSessionJoinCubit, SharedSessionJoinState>(
      '20.3-CUBIT-003: join() SessionAlreadyStartedFailure → emits [joining, sessionAlreadyStarted] (AC3)',
      build: () => SharedSessionJoinCubit(mockUseCase),
      setUp: () {
        when(mockUseCase.call(
          joinCode: anyNamed('joinCode'),
          userId: anyNamed('userId'),
        )).thenAnswer(
            (_) async => const Left(SessionAlreadyStartedFailure()));
      },
      act: (c) => c.join(joinCode: 'ABC123', userId: 'user-uuid'),
      expect: () => [
        const SharedSessionJoinState.joining(),
        const SharedSessionJoinState.sessionAlreadyStarted(),
      ],
    );

    blocTest<SharedSessionJoinCubit, SharedSessionJoinState>(
      '20.3-CUBIT-004: join() ServerFailure → emits [joining, error] — no failure.message in state (AC4, E18R-2)',
      build: () => SharedSessionJoinCubit(mockUseCase),
      setUp: () {
        when(mockUseCase.call(
          joinCode: anyNamed('joinCode'),
          userId: anyNamed('userId'),
        )).thenAnswer(
            (_) async => const Left(ServerFailure('join_code_not_found')));
      },
      act: (c) => c.join(joinCode: 'XXXXXX', userId: 'user-uuid'),
      expect: () => [
        const SharedSessionJoinState.joining(),
        const SharedSessionJoinState.error(
          failure: ServerFailure('join_code_not_found'),
        ),
      ],
    );

    test(
      '20.3-CUBIT-005: double-tap guard — second join() during joining emits no extra states',
      () async {
        final completer = Completer<Either<Failure, SharedSession>>();
        when(mockUseCase.call(
          joinCode: anyNamed('joinCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) => completer.future);

        final cubit = SharedSessionJoinCubit(mockUseCase);
        unawaited(cubit.join(joinCode: 'ABC123', userId: 'user-uuid'));
        await Future<void>.delayed(Duration.zero);
        // Second call while in joining state must be ignored
        unawaited(cubit.join(joinCode: 'ABC123', userId: 'user-uuid'));
        await Future<void>.delayed(Duration.zero);

        completer.complete(Right(_kSession));
        await Future<void>.delayed(Duration.zero);

        // Use case called only once
        verify(mockUseCase.call(
          joinCode: anyNamed('joinCode'),
          userId: anyNamed('userId'),
        )).called(1);
        await cubit.close();
      },
    );

    blocTest<SharedSessionJoinCubit, SharedSessionJoinState>(
      '20.3-CUBIT-006: reset() from error → initial',
      build: () => SharedSessionJoinCubit(mockUseCase),
      seed: () => const SharedSessionJoinState.error(
        failure: ServerFailure('err'),
      ),
      act: (c) => c.reset(),
      expect: () => [const SharedSessionJoinState.initial()],
    );

    blocTest<SharedSessionJoinCubit, SharedSessionJoinState>(
      '20.3-CUBIT-007: reset() from sessionAlreadyStarted → initial',
      build: () => SharedSessionJoinCubit(mockUseCase),
      seed: () => const SharedSessionJoinState.sessionAlreadyStarted(),
      act: (c) => c.reset(),
      expect: () => [const SharedSessionJoinState.initial()],
    );
  });
}
