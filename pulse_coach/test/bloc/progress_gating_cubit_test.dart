// [17.2-CUBIT-001..004] ProgressGatingCubit unit tests
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/get_install_cohort_use_case.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_gating_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_gating_state.dart';

import 'progress_gating_cubit_test.mocks.dart';

@GenerateMocks([GetInstallCohortUseCase])
void main() {
  group('ProgressGatingCubit', () {
    late MockGetInstallCohortUseCase mockUseCase;

    setUp(() {
      mockUseCase = MockGetInstallCohortUseCase();
    });

    test('17.2-CUBIT-001: initial state is ProgressGatingInitial', () {
      when(mockUseCase()).thenAnswer((_) async => const Right(null));
      final cubit = ProgressGatingCubit(mockUseCase);
      expect(cubit.state, isA<ProgressGatingInitial>());
      cubit.close();
    });

    blocTest<ProgressGatingCubit, ProgressGatingState>(
      '17.2-CUBIT-002: pre_v2 cohort → ProgressGatingLoaded(isGrandfathered: true)',
      build: () {
        when(
          mockUseCase(),
        ).thenAnswer((_) async => const Right('pre_v2'));
        return ProgressGatingCubit(mockUseCase);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<ProgressGatingLoaded>().having(
          (s) => s.isGrandfathered,
          'isGrandfathered',
          isTrue,
        ),
      ],
    );

    blocTest<ProgressGatingCubit, ProgressGatingState>(
      '17.2-CUBIT-003: post_v2 cohort → ProgressGatingLoaded(isGrandfathered: false)',
      build: () {
        when(
          mockUseCase(),
        ).thenAnswer((_) async => const Right('post_v2'));
        return ProgressGatingCubit(mockUseCase);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<ProgressGatingLoaded>().having(
          (s) => s.isGrandfathered,
          'isGrandfathered',
          isFalse,
        ),
      ],
    );

    blocTest<ProgressGatingCubit, ProgressGatingState>(
      '17.2-CUBIT-004: null cohort (no profile yet) → ProgressGatingLoaded(isGrandfathered: false)',
      build: () {
        when(
          mockUseCase(),
        ).thenAnswer((_) async => const Right(null));
        return ProgressGatingCubit(mockUseCase);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<ProgressGatingLoaded>().having(
          (s) => s.isGrandfathered,
          'isGrandfathered',
          isFalse,
        ),
      ],
    );

    blocTest<ProgressGatingCubit, ProgressGatingState>(
      '17.2-CUBIT-005: use case error → ProgressGatingLoaded(isGrandfathered: false) — safe default',
      build: () {
        when(mockUseCase()).thenAnswer(
          (_) async =>
              const Left(CacheFailure('install_cohort_load_failed')),
        );
        return ProgressGatingCubit(mockUseCase);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<ProgressGatingLoaded>().having(
          (s) => s.isGrandfathered,
          'isGrandfathered',
          isFalse,
        ),
      ],
    );
  });
}
