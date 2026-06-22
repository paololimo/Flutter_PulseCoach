// [17.2-UC-001..004] GetInstallCohortUseCase unit tests
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/get_install_cohort_use_case.dart';

import 'get_install_cohort_use_case_test.mocks.dart';

@GenerateMocks([OnboardingRepository])
void main() {
  group('GetInstallCohortUseCase', () {
    late MockOnboardingRepository mockRepo;
    late GetInstallCohortUseCase sut;

    setUp(() {
      mockRepo = MockOnboardingRepository();
      sut = GetInstallCohortUseCase(mockRepo);
    });

    test(
      '17.2-UC-001: pre_v2 cohort → Right("pre_v2")',
      () async {
        when(mockRepo.getInstallCohort()).thenAnswer(
          (_) async => const Right('pre_v2'),
        );

        final result = await sut();

        expect(result, equals(const Right<Failure, String?>('pre_v2')));
      },
    );

    test(
      '17.2-UC-002: post_v2 cohort → Right("post_v2")',
      () async {
        when(mockRepo.getInstallCohort()).thenAnswer(
          (_) async => const Right('post_v2'),
        );

        final result = await sut();

        expect(result, equals(const Right<Failure, String?>('post_v2')));
      },
    );

    test(
      '17.2-UC-003: null cohort (no profile) → Right(null)',
      () async {
        when(mockRepo.getInstallCohort()).thenAnswer(
          (_) async => const Right(null),
        );

        final result = await sut();

        expect(result, equals(const Right<Failure, String?>(null)));
      },
    );

    test(
      '17.2-UC-004: repository failure → Left(CacheFailure)',
      () async {
        when(mockRepo.getInstallCohort()).thenAnswer(
          (_) async =>
              const Left(CacheFailure('install_cohort_load_failed')),
        );

        final result = await sut();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<CacheFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
