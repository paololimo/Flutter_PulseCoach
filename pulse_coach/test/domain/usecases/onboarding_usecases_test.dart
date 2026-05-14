// Onboarding use case unit tests — all 5 thin-delegate use cases in one file
// AcceptDisclaimer, CheckDisclaimerStatus, GetProfile, SaveProfile, UpdateProfile
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/get_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/update_profile.dart';

import 'onboarding_usecases_test.mocks.dart';

@GenerateMocks([OnboardingRepository])
void main() {
  late MockOnboardingRepository mockRepo;

  const tProfile = UserProfile(
    fitnessLevel: 'medium',
    goal: 'cardio',
    availableTime: 'short',
    physicalConstraints: 'none',
  );
  const tCacheFailure = CacheFailure('DB error');

  setUp(() {
    mockRepo = MockOnboardingRepository();
  });

  // ─── AcceptDisclaimer ──────────────────────────────────────────────────────

  group('AcceptDisclaimer', () {
    test(
      '[P1] 2.1-UNIT-009: call() delegates to repository.acceptDisclaimer and returns Right on success',
      () async {
        when(mockRepo.acceptDisclaimer())
            .thenAnswer((_) async => const Right(null));

        final result = await AcceptDisclaimer(mockRepo).call();

        expect(result.isRight(), isTrue);
        verify(mockRepo.acceptDisclaimer()).called(1);
      },
    );

    test(
      '[P1] 2.1-UNIT-010: call() propagates Left(CacheFailure) on repository failure',
      () async {
        when(mockRepo.acceptDisclaimer())
            .thenAnswer((_) async => const Left(tCacheFailure));

        final result = await AcceptDisclaimer(mockRepo).call();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<CacheFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );
  });

  // ─── CheckDisclaimerStatus ─────────────────────────────────────────────────

  group('CheckDisclaimerStatus', () {
    test(
      '[P1] 2.1-UNIT-011: call() returns Right(true) when disclaimer is accepted',
      () async {
        when(mockRepo.isDisclaimerAccepted())
            .thenAnswer((_) async => const Right(true));

        final result = await CheckDisclaimerStatus(mockRepo).call();

        expect(result, equals(const Right<Failure, bool>(true)));
        verify(mockRepo.isDisclaimerAccepted()).called(1);
      },
    );

    test(
      '[P1] 2.1-UNIT-012: call() returns Right(false) when disclaimer is not yet accepted',
      () async {
        when(mockRepo.isDisclaimerAccepted())
            .thenAnswer((_) async => const Right(false));

        final result = await CheckDisclaimerStatus(mockRepo).call();

        expect(result, equals(const Right<Failure, bool>(false)));
      },
    );

    test(
      '[P1] 2.1-UNIT-013: call() propagates Left(CacheFailure) on repository failure',
      () async {
        when(mockRepo.isDisclaimerAccepted())
            .thenAnswer((_) async => const Left(tCacheFailure));

        final result = await CheckDisclaimerStatus(mockRepo).call();

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ─── GetProfile ────────────────────────────────────────────────────────────

  group('GetProfile', () {
    test(
      '[P1] 2.4-UNIT-005: call() returns Right(UserProfile) on success',
      () async {
        when(mockRepo.getProfile())
            .thenAnswer((_) async => const Right(tProfile));

        final result = await GetProfile(mockRepo).call();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (p) => expect(p.fitnessLevel, equals('medium')),
        );
        verify(mockRepo.getProfile()).called(1);
      },
    );

    test(
      '[P1] 2.4-UNIT-006: call() propagates Left(CacheFailure) when profile not found',
      () async {
        when(mockRepo.getProfile())
            .thenAnswer((_) async => const Left(tCacheFailure));

        final result = await GetProfile(mockRepo).call();

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ─── SaveProfile ───────────────────────────────────────────────────────────

  group('SaveProfile', () {
    test(
      '[P1] 2.3-UNIT-003: call(profile) delegates to repository.saveProfile and returns Right on success',
      () async {
        when(mockRepo.saveProfile(tProfile))
            .thenAnswer((_) async => const Right(null));

        final result = await SaveProfile(mockRepo).call(tProfile);

        expect(result.isRight(), isTrue);
        verify(mockRepo.saveProfile(tProfile)).called(1);
      },
    );

    test(
      '[P1] 2.3-UNIT-004: call(profile) propagates Left(CacheFailure) on failure',
      () async {
        when(mockRepo.saveProfile(tProfile))
            .thenAnswer((_) async => const Left(tCacheFailure));

        final result = await SaveProfile(mockRepo).call(tProfile);

        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ─── UpdateProfile ─────────────────────────────────────────────────────────

  group('UpdateProfile', () {
    test(
      '[P1] 2.4-UNIT-007: call(profile) delegates to repository.updateProfile and returns Right on success',
      () async {
        when(mockRepo.updateProfile(tProfile))
            .thenAnswer((_) async => const Right(null));

        final result = await UpdateProfile(mockRepo).call(tProfile);

        expect(result.isRight(), isTrue);
        verify(mockRepo.updateProfile(tProfile)).called(1);
      },
    );

    test(
      '[P1] 2.4-UNIT-008: call(profile) propagates Left(CacheFailure) on failure',
      () async {
        when(mockRepo.updateProfile(tProfile))
            .thenAnswer((_) async => const Left(tCacheFailure));

        final result = await UpdateProfile(mockRepo).call(tProfile);

        expect(result.isLeft(), isTrue);
      },
    );
  });
}
