import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/usecases/update_bandit_reward.dart';
import 'package:pulse_coach/features/session/presentation/bloc/post_rpe_adaptation_cubit.dart';
import 'package:pulse_coach/features/session/presentation/bloc/post_rpe_adaptation_state.dart';

import 'post_rpe_adaptation_cubit_test.mocks.dart';

@GenerateMocks([UpdateBanditReward])
void main() {
  late MockUpdateBanditReward mockUseCase;

  setUp(() {
    mockUseCase = MockUpdateBanditReward();
  });

  PostRpeAdaptationCubit cubit({String? armKey = 'mobility_low'}) {
    return PostRpeAdaptationCubit(
      useCase: mockUseCase,
      armKey: armKey,
    );
  }

  group('PostRpeAdaptationCubit', () {
    blocTest<PostRpeAdaptationCubit, PostRpeAdaptationState>(
      '9.3-CUBIT-001: triggerUpdate is idempotent — exactly one terminal state across two calls',
      build: () {
        when(
          mockUseCase.call(
            armKey: anyNamed('armKey'),
            rpeValue: anyNamed('rpeValue'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return cubit();
      },
      act: (cubit) async {
        await cubit.triggerUpdate(7);
        await cubit.triggerUpdate(7);
      },
      // Exactly one Running + one Done emitted across both calls — proves
      // the second triggerUpdate is an observable no-op, not just that the
      // mocked use case was invoked once.
      expect: () => [
        isA<PostRpeAdaptationRunning>(),
        isA<PostRpeAdaptationDone>(),
      ],
      verify: (_) {
        verify(
          mockUseCase.call(
            armKey: anyNamed('armKey'),
            rpeValue: anyNamed('rpeValue'),
          ),
        ).called(1);
      },
    );

    blocTest<PostRpeAdaptationCubit, PostRpeAdaptationState>(
      '9.3-CUBIT-002: success emits Running then Done',
      build: () {
        when(
          mockUseCase.call(
            armKey: anyNamed('armKey'),
            rpeValue: anyNamed('rpeValue'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return cubit(armKey: 'cardio_medium');
      },
      act: (cubit) => cubit.triggerUpdate(6),
      expect: () => [
        isA<PostRpeAdaptationRunning>(),
        isA<PostRpeAdaptationDone>(),
      ],
    );

    blocTest<PostRpeAdaptationCubit, PostRpeAdaptationState>(
      '9.3-CUBIT-003: failure emits Running then Error',
      build: () {
        when(
          mockUseCase.call(
            armKey: anyNamed('armKey'),
            rpeValue: anyNamed('rpeValue'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('bandit_reward_update_failed')),
        );
        return cubit(armKey: 'breathing_low');
      },
      act: (cubit) => cubit.triggerUpdate(5),
      expect: () => [
        isA<PostRpeAdaptationRunning>(),
        isA<PostRpeAdaptationError>(),
      ],
    );

    blocTest<PostRpeAdaptationCubit, PostRpeAdaptationState>(
      '9.3-CUBIT-004: null armKey skips use case and emits Done',
      build: () => cubit(armKey: null),
      act: (cubit) => cubit.triggerUpdate(7),
      expect: () => [isA<PostRpeAdaptationDone>()],
      verify: (_) {
        verifyNever(
          mockUseCase.call(
            armKey: anyNamed('armKey'),
            rpeValue: anyNamed('rpeValue'),
          ),
        );
      },
    );

    test('9.3-CUBIT-005: no state emitted after close', () async {
      final completer = Completer<Either<Failure, Unit>>();
      when(
        mockUseCase.call(
          armKey: anyNamed('armKey'),
          rpeValue: anyNamed('rpeValue'),
        ),
      ).thenAnswer((_) => completer.future);

      final cubit = PostRpeAdaptationCubit(
        useCase: mockUseCase,
        armKey: 'mobility_low',
      );
      final states = <PostRpeAdaptationState>[];
      final subscription = cubit.stream.listen(states.add);

      unawaited(cubit.triggerUpdate(7));
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      completer.complete(const Right(unit));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(states.whereType<PostRpeAdaptationDone>(), isEmpty);
    });
  });
}
