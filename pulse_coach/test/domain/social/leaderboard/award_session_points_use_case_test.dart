import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/cloud/entitlement_gate.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/usecases/award_session_points_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';

import 'award_session_points_use_case_test.mocks.dart';

@GenerateMocks([LeaderboardRepository, EntitlementGate])
void main() {
  late MockLeaderboardRepository mockRepository;
  late MockEntitlementGate mockEntitlementGate;
  late AwardSessionPointsUseCase sut;

  setUp(() {
    mockRepository = MockLeaderboardRepository();
    mockEntitlementGate = MockEntitlementGate();
    sut = AwardSessionPointsUseCase(mockRepository, mockEntitlementGate);
    when(
      mockRepository.awardSessionPoints(
        sessionLogId: anyNamed('sessionLogId'),
        basePoints: anyNamed('basePoints'),
        awardedOnUtc: anyNamed('awardedOnUtc'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  test(
    '21.1-USECASE-001: tier pro, cardio_medium, 20min → basePoints 30',
    () async {
      when(mockEntitlementGate.currentTier).thenReturn(SubscriptionTier.pro);

      await sut.call(
        sessionLogId: 1,
        armKey: 'cardio_medium',
        durationMinutes: 20,
      );

      verify(
        mockRepository.awardSessionPoints(
          sessionLogId: 1,
          basePoints: 30,
          awardedOnUtc: anyNamed('awardedOnUtc'),
        ),
      ).called(1);
    },
  );

  test(
    '21.1-USECASE-002: tier signedInFree → awardSessionPoints never called',
    () async {
      when(
        mockEntitlementGate.currentTier,
      ).thenReturn(SubscriptionTier.signedInFree);

      await sut.call(
        sessionLogId: 1,
        armKey: 'cardio_medium',
        durationMinutes: 20,
      );

      verifyNever(
        mockRepository.awardSessionPoints(
          sessionLogId: anyNamed('sessionLogId'),
          basePoints: anyNamed('basePoints'),
          awardedOnUtc: anyNamed('awardedOnUtc'),
        ),
      );
    },
  );

  test(
    '21.1-USECASE-003: tier accountFree → awardSessionPoints never called',
    () async {
      when(
        mockEntitlementGate.currentTier,
      ).thenReturn(SubscriptionTier.accountFree);

      await sut.call(
        sessionLogId: 1,
        armKey: 'cardio_medium',
        durationMinutes: 20,
      );

      verifyNever(
        mockRepository.awardSessionPoints(
          sessionLogId: anyNamed('sessionLogId'),
          basePoints: anyNamed('basePoints'),
          awardedOnUtc: anyNamed('awardedOnUtc'),
        ),
      );
    },
  );

  test(
    '21.1-USECASE-004: tier pro, durationMinutes 0 → basePoints 0 → never called',
    () async {
      when(mockEntitlementGate.currentTier).thenReturn(SubscriptionTier.pro);

      await sut.call(
        sessionLogId: 1,
        armKey: 'cardio_medium',
        durationMinutes: 0,
      );

      verifyNever(
        mockRepository.awardSessionPoints(
          sessionLogId: anyNamed('sessionLogId'),
          basePoints: anyNamed('basePoints'),
          awardedOnUtc: anyNamed('awardedOnUtc'),
        ),
      );
    },
  );
}
