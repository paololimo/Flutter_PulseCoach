// [18.1-BLOC-001..004] SocialProfileBloc tests.
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/social_profile_repository.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/get_social_profile_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/update_handle_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/update_visibility_tier_use_case.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';

import 'social_profile_bloc_test.mocks.dart';

@GenerateMocks([SocialProfileRepository])
void main() {
  late MockSocialProfileRepository mockRepo;
  late GetSocialProfileUseCase getProfile;
  late UpdateHandleUseCase updateHandle;
  late UpdateVisibilityTierUseCase updateVisibility;

  const tProfile = SocialProfile(
    userId: 'user-123',
    displayHandle: null,
    visibilityTier: VisibilityTier.private,
  );

  const tUpdatedProfile = SocialProfile(
    userId: 'user-123',
    displayHandle: 'paolol',
    visibilityTier: VisibilityTier.private,
  );

  const tFriendsOnlyProfile = SocialProfile(
    userId: 'user-123',
    displayHandle: null,
    visibilityTier: VisibilityTier.friendsOnly,
  );

  setUp(() {
    mockRepo = MockSocialProfileRepository();
    getProfile = GetSocialProfileUseCase(mockRepo);
    updateHandle = UpdateHandleUseCase(mockRepo);
    updateVisibility = UpdateVisibilityTierUseCase(mockRepo);
  });

  SocialProfileBloc buildBloc() =>
      SocialProfileBloc(getProfile, updateHandle, updateVisibility);

  group('SocialProfileLoaded', () {
    blocTest<SocialProfileBloc, SocialProfileState>(
      '18.1-BLOC-001: emits [loading, loaded(profile)]',
      build: buildBloc,
      setUp: () {
        when(mockRepo.getSocialProfile())
            .thenAnswer((_) async => const Right(tProfile));
      },
      act: (bloc) => bloc.add(const SocialProfileLoaded()),
      expect: () => [
        const SocialProfileState.loading(),
        const SocialProfileState.loaded(profile: tProfile),
      ],
    );
  });

  group('HandleUpdateRequested', () {
    blocTest<SocialProfileBloc, SocialProfileState>(
      '18.1-BLOC-002: unique handle → emits [loading, loaded(updatedProfile)]',
      build: buildBloc,
      setUp: () {
        when(mockRepo.updateHandle('paolol'))
            .thenAnswer((_) async => const Right(tUpdatedProfile));
      },
      act: (bloc) => bloc.add(const HandleUpdateRequested('paolol')),
      expect: () => [
        const SocialProfileState.loading(),
        const SocialProfileState.loaded(profile: tUpdatedProfile),
      ],
    );

    blocTest<SocialProfileBloc, SocialProfileState>(
      '18.1-BLOC-003: taken handle → emits [loading, error(SocialHandleTakenFailure)]',
      build: buildBloc,
      setUp: () {
        when(mockRepo.updateHandle('taken'))
            .thenAnswer((_) async => const Left(SocialHandleTakenFailure()));
      },
      act: (bloc) => bloc.add(const HandleUpdateRequested('taken')),
      expect: () => [
        const SocialProfileState.loading(),
        const SocialProfileState.error(failure: SocialHandleTakenFailure()),
      ],
    );
  });

  group('VisibilityTierUpdateRequested', () {
    blocTest<SocialProfileBloc, SocialProfileState>(
      '18.1-BLOC-004: visibility update → emits [loading, loaded(updatedProfile)]',
      build: buildBloc,
      setUp: () {
        when(mockRepo.updateVisibilityTier(VisibilityTier.friendsOnly))
            .thenAnswer((_) async => const Right(tFriendsOnlyProfile));
      },
      act: (bloc) =>
          bloc.add(const VisibilityTierUpdateRequested(VisibilityTier.friendsOnly)),
      expect: () => [
        const SocialProfileState.loading(),
        const SocialProfileState.loaded(profile: tFriendsOnlyProfile),
      ],
    );
  });
}
