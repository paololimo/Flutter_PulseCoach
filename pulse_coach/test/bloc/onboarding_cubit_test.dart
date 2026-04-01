// [P1] OnboardingCubit unit tests
// Tests: initial state, acceptDisclaimer success, failure, double-tap safety
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_state.dart';

import 'onboarding_cubit_test.mocks.dart';

@GenerateMocks([AcceptDisclaimer, CheckDisclaimerStatus])
void main() {
  late MockAcceptDisclaimer mockAcceptDisclaimer;
  late MockCheckDisclaimerStatus mockCheckDisclaimerStatus;

  setUp(() {
    mockAcceptDisclaimer = MockAcceptDisclaimer();
    mockCheckDisclaimerStatus = MockCheckDisclaimerStatus();
    // Default: not yet accepted
    when(mockCheckDisclaimerStatus()).thenAnswer((_) async => const Right(false));
  });

  group('OnboardingCubit', () {
    test(
      '[P1] 2.1-UNIT-001: initial state is disclaimerPending',
      () {
        final cubit = OnboardingCubit(mockAcceptDisclaimer, mockCheckDisclaimerStatus);
        expect(cubit.state, const OnboardingState.disclaimerPending());
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '[P1] 2.1-UNIT-002: acceptDisclaimer emits [loading, disclaimerAccepted] on success',
      build: () {
        when(mockAcceptDisclaimer()).thenAnswer(
          (_) async => const Right(null),
        );
        return OnboardingCubit(mockAcceptDisclaimer, mockCheckDisclaimerStatus);
      },
      act: (cubit) => cubit.acceptDisclaimer(),
      expect: () => [
        const OnboardingState.loading(),
        const OnboardingState.disclaimerAccepted(),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '[P1] 2.1-UNIT-003: acceptDisclaimer emits [loading, error] on failure',
      build: () {
        when(mockAcceptDisclaimer()).thenAnswer(
          (_) async => const Left(CacheFailure('DB error')),
        );
        return OnboardingCubit(mockAcceptDisclaimer, mockCheckDisclaimerStatus);
      },
      act: (cubit) => cubit.acceptDisclaimer(),
      expect: () => [
        const OnboardingState.loading(),
        const OnboardingState.error('DB error'),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '[P1] 2.1-UNIT-007: checkInitialStatus emits disclaimerAccepted when previously accepted',
      build: () {
        when(mockCheckDisclaimerStatus()).thenAnswer(
          (_) async => const Right(true),
        );
        return OnboardingCubit(mockAcceptDisclaimer, mockCheckDisclaimerStatus);
      },
      act: (cubit) => cubit.checkInitialStatus(),
      expect: () => [
        const OnboardingState.disclaimerAccepted(),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '[P2] 2.1-UNIT-008: checkInitialStatus stays at disclaimerPending on failure',
      build: () {
        when(mockCheckDisclaimerStatus()).thenAnswer(
          (_) async => const Left(CacheFailure('DB error')),
        );
        return OnboardingCubit(mockAcceptDisclaimer, mockCheckDisclaimerStatus);
      },
      act: (cubit) => cubit.checkInitialStatus(),
      expect: () => <OnboardingState>[],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      '[P1] 2.1-UNIT-004: calling acceptDisclaimer twice sequentially emits correct states',
      build: () {
        when(mockAcceptDisclaimer()).thenAnswer(
          (_) async => const Right(null),
        );
        return OnboardingCubit(mockAcceptDisclaimer, mockCheckDisclaimerStatus);
      },
      act: (cubit) async {
        await cubit.acceptDisclaimer();
        await cubit.acceptDisclaimer();
      },
      expect: () => [
        const OnboardingState.loading(),
        const OnboardingState.disclaimerAccepted(),
        const OnboardingState.loading(),
        const OnboardingState.disclaimerAccepted(),
      ],
    );
  });
}
