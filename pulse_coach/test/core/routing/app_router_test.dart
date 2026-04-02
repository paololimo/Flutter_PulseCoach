// [P0] AppRouter redirect logic tests
// Tests the onboarding gate: no profile → /onboarding, profile → /today
// Strategy: pump PulseCoachApp with controlled database state,
// let GoRouter redirect settle, then assert the correct page renders.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/get_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/update_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';

/// Registers the onboarding DI chain needed for OnboardingPage.
/// Must be called AFTER AppDatabase is registered in getIt.
void _registerOnboardingDeps() {
  getIt.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(getIt<AppDatabase>()),
  );
  getIt.registerFactory<AcceptDisclaimer>(
    () => AcceptDisclaimer(getIt<OnboardingRepository>()),
  );
  getIt.registerFactory<CheckDisclaimerStatus>(
    () => CheckDisclaimerStatus(getIt<OnboardingRepository>()),
  );
  getIt.registerFactory<SaveProfile>(
    () => SaveProfile(getIt<OnboardingRepository>()),
  );
  getIt.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(
      getIt<AcceptDisclaimer>(),
      getIt<CheckDisclaimerStatus>(),
      getIt<SaveProfile>(),
    ),
  );
  getIt.registerFactory<GetProfile>(
    () => GetProfile(getIt<OnboardingRepository>()),
  );
  getIt.registerFactory<UpdateProfile>(
    () => UpdateProfile(getIt<OnboardingRepository>()),
  );
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(getIt<GetProfile>(), getIt<UpdateProfile>()),
  );
}

void main() {
  tearDown(() async {
    if (getIt.isRegistered<AppDatabase>()) {
      await getIt<AppDatabase>().close();
    }
    await getIt.reset();
  });

  group('AppRouter redirect — no user profile', () {
    setUp(() {
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
      getIt.registerSingleton<AppDatabase>(
        AppDatabase.forTesting(NativeDatabase.memory()),
      );
      _registerOnboardingDeps();
    });

    testWidgets(
      '[P0] 1.7-UNIT-001: redirects to /onboarding (disclaimer screen) when no profile exists',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // DisclaimerScreen headline confirms the redirect fired correctly
        expect(find.text('Your data stays yours.'), findsOneWidget);
      },
    );

    testWidgets(
      '[P0] 1.7-UNIT-002: /onboarding disclaimer screen is reachable without profile',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // Medical disclaimer text confirms DisclaimerScreen rendered
        expect(find.textContaining('not a medical device'), findsWidgets);
      },
    );
  });

  group('AppRouter redirect — disclaimer not accepted', () {
    setUp(() async {
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // Profile exists but disclaimerAccepted = false (default)
      await db.userProfileDao.insertProfile(
        UserProfileCompanion.insert(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      getIt.registerSingleton<AppDatabase>(db);
      _registerOnboardingDeps();
    });

    testWidgets(
      '[P1] 2.1-UNIT-005: redirects to /onboarding when disclaimerAccepted is false',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        expect(find.text('Your data stays yours.'), findsOneWidget);
      },
    );
  });

  group('AppRouter redirect — disclaimer accepted, onboarding not complete', () {
    setUp(() async {
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.userProfileDao.insertProfile(
        UserProfileCompanion.insert(
          disclaimerAccepted: const Value(true),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      getIt.registerSingleton<AppDatabase>(db);
      _registerOnboardingDeps();
    });

    testWidgets(
      '[P1] 2.1-UNIT-006: onboarding continues internally when disclaimerAccepted=true, onboardingCompleted=false',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        // Use pump with explicit durations instead of pumpAndSettle because
        // Lottie creates a looping AnimationController that never settles.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500)); // DB read + cubit
        await tester.pump(const Duration(milliseconds: 100)); // router redirect
        // OnboardingCarousel Screen 1 headline confirms carousel rendered
        expect(find.text('Move more. Decide less.'), findsOneWidget);
      },
    );
  });

  group('AppRouter redirect — onboarding complete', () {
    setUp(() async {
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.userProfileDao.insertProfile(
        UserProfileCompanion.insert(
          disclaimerAccepted: const Value(true),
          onboardingCompleted: const Value(true),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      getIt.registerSingleton<AppDatabase>(db);
      _registerOnboardingDeps();
    });

    testWidgets(
      '[P0] 1.7-UNIT-003: redirects to /today when onboardingCompleted is true',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // TodayPage content confirms redirect to /today fired correctly
        expect(find.text('Today — Story 7.x'), findsOneWidget);
      },
    );

    testWidgets(
      '[P0] 1.7-UNIT-004: shell navigation bar is visible when onboarding complete',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // AppShell BottomNavigationBar confirms we are in the shell route
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Sessions'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
      },
    );
  });
}
