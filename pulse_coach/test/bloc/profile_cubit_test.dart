// [P1] ProfileCubit unit tests
// Tests: loadProfile success/failure, updateProfile success/failure (no loading emitted)
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/get_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/update_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_state.dart';

import 'profile_cubit_test.mocks.dart';

@GenerateMocks([GetProfile, UpdateProfile])
void main() {
  late MockGetProfile mockGetProfile;
  late MockUpdateProfile mockUpdateProfile;

  const tProfile = UserProfile(
    fitnessLevel: 'low',
    goal: 'cardio',
    availableTime: 'short',
    physicalConstraints: 'none',
  );

  setUp(() {
    mockGetProfile = MockGetProfile();
    mockUpdateProfile = MockUpdateProfile();
  });

  group('ProfileCubit', () {
    blocTest<ProfileCubit, ProfileState>(
      '[P1] 2.4-UNIT-001: loadProfile emits [loading, loaded(profile)] on success',
      build: () {
        when(mockGetProfile()).thenAnswer((_) async => const Right(tProfile));
        return ProfileCubit(mockGetProfile, mockUpdateProfile);
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState.loading(),
        const ProfileState.loaded(tProfile),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      '[P1] 2.4-UNIT-002: loadProfile emits [loading, error] on failure',
      build: () {
        when(mockGetProfile()).thenAnswer(
          (_) async => const Left(CacheFailure('Profile not found')),
        );
        return ProfileCubit(mockGetProfile, mockUpdateProfile);
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState.loading(),
        const ProfileState.error('Profile not found'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      '[P1] 2.4-UNIT-003: updateProfile emits [loaded(profile)] on success (no loading emitted)',
      build: () {
        when(mockUpdateProfile(tProfile)).thenAnswer(
          (_) async => const Right(null),
        );
        return ProfileCubit(mockGetProfile, mockUpdateProfile);
      },
      act: (cubit) => cubit.updateProfile(tProfile),
      expect: () => [const ProfileState.loaded(tProfile)],
    );

    blocTest<ProfileCubit, ProfileState>(
      '[P1] 2.4-UNIT-004: updateProfile emits [error] on failure',
      build: () {
        when(mockUpdateProfile(tProfile)).thenAnswer(
          (_) async => const Left(CacheFailure('DB error')),
        );
        return ProfileCubit(mockGetProfile, mockUpdateProfile);
      },
      act: (cubit) => cubit.updateProfile(tProfile),
      expect: () => [const ProfileState.error('DB error')],
    );
  });
}
