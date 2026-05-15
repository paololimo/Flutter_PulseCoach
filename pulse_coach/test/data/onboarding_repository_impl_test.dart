// [P0/P1] OnboardingRepositoryImpl integration tests
// Tests: acceptDisclaimer (insert/update), isDisclaimerAccepted (null/false/true),
//        getProfile (CacheFailure, null-field defaults, field mapping),
//        updateProfile (missing profile, success), saveProfile (insert/update),
//        UserProfileDao.insertProfile guard (StateError)
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';

void main() {
  late AppDatabase db;
  late OnboardingRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = OnboardingRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // acceptDisclaimer
  // ---------------------------------------------------------------------------

  group('acceptDisclaimer', () {
    test(
      '[P0] 2.1-INT-001: creates a new profile with disclaimerAccepted=true when no profile exists',
      () async {
        final result = await repo.acceptDisclaimer();

        expect(result.isRight(), isTrue);
        final profile = await db.userProfileDao.getProfile();
        expect(profile, isNotNull);
        expect(profile!.disclaimerAccepted, isTrue);
      },
    );

    test(
      '[P0] 2.1-INT-002: updates existing profile to disclaimerAccepted=true',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        expect(
          (await db.userProfileDao.getProfile())!.disclaimerAccepted,
          isFalse,
        );

        final result = await repo.acceptDisclaimer();

        expect(result.isRight(), isTrue);
        expect(
          (await db.userProfileDao.getProfile())!.disclaimerAccepted,
          isTrue,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // isDisclaimerAccepted
  // ---------------------------------------------------------------------------

  group('isDisclaimerAccepted', () {
    test('[P1] 2.1-INT-003: returns false when no profile exists', () async {
      final result = await repo.isDisclaimerAccepted();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (accepted) => expect(accepted, isFalse));
    });

    test(
      '[P1] 2.1-INT-004: returns false when profile has disclaimerAccepted=false',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final result = await repo.isDisclaimerAccepted();

        result.fold((_) {}, (accepted) => expect(accepted, isFalse));
      },
    );

    test(
      '[P1] 2.1-INT-005: returns true when profile has disclaimerAccepted=true',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            disclaimerAccepted: const Value(true),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final result = await repo.isDisclaimerAccepted();

        result.fold((_) {}, (accepted) => expect(accepted, isTrue));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getProfile
  // ---------------------------------------------------------------------------

  group('getProfile', () {
    test(
      '[P0] 2.1-INT-006: returns CacheFailure when no profile exists',
      () async {
        final result = await repo.getProfile();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected Left(CacheFailure)'),
        );
      },
    );

    test(
      '[P1] 2.1-INT-007: maps null DB fields to domain defaults (low / cardio / short / none)',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final result = await repo.getProfile();

        expect(result.isRight(), isTrue);
        late UserProfile profile;
        result.fold(
          (_) => fail('Expected Right(UserProfile)'),
          (p) => profile = p,
        );
        expect(profile.fitnessLevel, 'low');
        expect(profile.goal, 'cardio');
        expect(profile.availableTime, 'short');
        expect(profile.physicalConstraints, 'none');
      },
    );

    test(
      '[P0] 2.1-INT-008: maps DB fields correctly to domain entity',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            intensityPreference: const Value('medium'),
            fitnessGoal: const Value('strength'),
            availableTime: const Value('long'),
            physicalConstraints: const Value('knee'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final result = await repo.getProfile();

        expect(result.isRight(), isTrue);
        late UserProfile profile;
        result.fold(
          (_) => fail('Expected Right(UserProfile)'),
          (p) => profile = p,
        );
        expect(profile.fitnessLevel, 'medium');
        expect(profile.goal, 'strength');
        expect(profile.availableTime, 'long');
        expect(profile.physicalConstraints, 'knee');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // updateProfile
  // ---------------------------------------------------------------------------

  group('updateProfile', () {
    const tProfile = UserProfile(
      fitnessLevel: 'medium',
      goal: 'strength',
      availableTime: 'long',
      physicalConstraints: 'knee',
    );

    test(
      '[P1] 2.4-INT-001: returns CacheFailure when no profile exists',
      () async {
        final result = await repo.updateProfile(tProfile);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected Left(CacheFailure)'),
        );
      },
    );

    test(
      '[P1] 2.4-INT-002: updates all fields correctly when profile exists',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            intensityPreference: const Value('low'),
            fitnessGoal: const Value('cardio'),
            availableTime: const Value('short'),
            physicalConstraints: const Value('none'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final result = await repo.updateProfile(tProfile);

        expect(result.isRight(), isTrue);
        final saved = await db.userProfileDao.getProfile();
        expect(saved!.intensityPreference, 'medium');
        expect(saved.fitnessGoal, 'strength');
        expect(saved.availableTime, 'long');
        expect(saved.physicalConstraints, 'knee');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // saveProfile
  // ---------------------------------------------------------------------------

  group('saveProfile', () {
    const tProfile = UserProfile(
      fitnessLevel: 'low',
      goal: 'cardio',
      availableTime: 'short',
      physicalConstraints: 'none',
    );

    test(
      '[P0] 2.3-INT-001: creates new profile with onboardingCompleted=true when no profile exists',
      () async {
        final result = await repo.saveProfile(tProfile);

        expect(result.isRight(), isTrue);
        final profile = await db.userProfileDao.getProfile();
        expect(profile, isNotNull);
        expect(profile!.onboardingCompleted, isTrue);
        expect(profile.intensityPreference, 'low');
        expect(profile.fitnessGoal, 'cardio');
        expect(profile.availableTime, 'short');
        expect(profile.physicalConstraints, 'none');
      },
    );

    test(
      '[P1] 2.3-INT-002: updates existing profile with onboardingCompleted=true',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            disclaimerAccepted: const Value(true),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final result = await repo.saveProfile(tProfile);

        expect(result.isRight(), isTrue);
        final profile = await db.userProfileDao.getProfile();
        expect(profile!.onboardingCompleted, isTrue);
        expect(profile.intensityPreference, 'low');
        expect(profile.fitnessGoal, 'cardio');
        expect(profile.availableTime, 'short');
        expect(profile.physicalConstraints, 'none');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // UserProfileDao guard
  // ---------------------------------------------------------------------------

  group('UserProfileDao guard', () {
    test(
      '[P1] DAO-001: insertProfile throws StateError when a profile already exists',
      () async {
        await db.userProfileDao.insertProfile(
          UserProfileCompanion.insert(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await expectLater(
          () => db.userProfileDao.insertProfile(
            UserProfileCompanion.insert(
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
