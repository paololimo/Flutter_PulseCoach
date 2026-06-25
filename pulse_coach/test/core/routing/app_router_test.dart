// [P0] AppRouter redirect logic tests
// Tests the onboarding gate: no profile → /onboarding, profile → /today
// Strategy: pump PulseCoachApp with controlled database state,
// let GoRouter redirect settle, then assert the correct page renders.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/core/database/app_database.dart' hide DailyPlan;
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
import 'package:pulse_coach/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _testThemePrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

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

void _registerTodayDeps() {
  getIt.registerFactory<DailyPlanBloc>(() => _StubDailyPlanBloc());
  getIt.registerFactory<TodaySessionCubit>(
    () => TodaySessionCubit(getIt<AppDatabase>().sessionLogsDao),
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
    setUp(() async {
      final prefs = await _testThemePrefs();
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs));
      getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit(prefs));
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
        expect(find.text('I tuoi dati restano tuoi.'), findsOneWidget);
      },
    );

    testWidgets(
      '[P0] 1.7-UNIT-002: /onboarding disclaimer screen is reachable without profile',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // Medical disclaimer text confirms DisclaimerScreen rendered
        expect(find.textContaining('dispositivo medico'), findsWidgets);
      },
    );
  });

  group('AppRouter redirect — disclaimer not accepted', () {
    setUp(() async {
      final prefs = await _testThemePrefs();
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs));
      getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit(prefs));
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
      _registerTodayDeps();
    });

    testWidgets(
      '[P1] 2.1-UNIT-005: redirects to /onboarding when disclaimerAccepted is false',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        expect(find.text('I tuoi dati restano tuoi.'), findsOneWidget);
      },
    );
  });

  group('AppRouter redirect — disclaimer accepted, onboarding not complete', () {
    setUp(() async {
      final prefs = await _testThemePrefs();
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs));
      getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit(prefs));
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
      _registerTodayDeps();
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
        expect(find.text('Muoviti di più. Decidi di meno.'), findsOneWidget);
      },
    );
  });

  group('AppRouter — full profile setup flow navigates to /today (AC-2.3-4)', () {
    setUp(() async {
      // No ThemeCubit — we do not use PulseCoachApp here.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // Disclaimer accepted, onboarding not yet complete → carousel shown after init.
      await db.userProfileDao.insertProfile(
        UserProfileCompanion.insert(
          disclaimerAccepted: const Value(true),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      getIt.registerSingleton<AppDatabase>(db);
      _registerOnboardingDeps();
      _registerTodayDeps();
    });

    testWidgets(
      '[P0] AC-2.3-4: OnboardingPage BlocListener navigates to /today after saveProfile succeeds',
      (tester) async {
        // Use a fresh GoRouter (avoids static-singleton state pollution from other
        // tests). Inject disableAnimations:true via the MaterialApp builder so the
        // carousel uses jumpToPage (instant) instead of animateToPage (250ms), which
        // would otherwise require exact-duration pumping.
        final testRouter = GoRouter(
          initialLocation: '/onboarding',
          routes: [
            GoRoute(
              path: '/onboarding',
              builder: (_, _) => const OnboardingPage(),
            ),
            GoRoute(
              path: '/today',
              builder: (_, _) => const Scaffold(
                body: Center(child: Text('Today — Story 7.x')),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.darkTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: testRouter,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        );
        // checkInitialStatus → DB read → disclaimerAccepted state → carousel renders
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Move more. Decide less.'), findsOneWidget);

        // Navigate carousel (jumpToPage = instant due to disableAnimations)
        await tester.tap(find.text('Next'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();
        await tester.tap(find.text('Get Started'));
        await tester.pump();

        // ProfileSetupForm is now visible
        expect(find.text('Fitness Level'), findsOneWidget);

        // Select all 4 required fields
        await tester.tap(find.text('Beginner'));
        await tester.pump();
        await tester.tap(find.text('Cardio'));
        await tester.pump();
        await tester.tap(find.text('2–5 min'));
        await tester.pump();
        await tester.tap(find.text('None'));
        await tester.pump();

        // "Start My Plan" → saveProfile → DB write → emits onboardingComplete
        await tester.tap(find.byType(FilledButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500)); // DB write
        await tester.pump(
          const Duration(milliseconds: 100),
        ); // BlocListener + router

        // OnboardingPage.BlocListener received onboardingComplete → context.go('/today')
        expect(find.text('Today — Story 7.x'), findsOneWidget);
      },
    );
  });

  group('AppRouter redirect — onboarding complete', () {
    setUp(() async {
      final prefs = await _testThemePrefs();
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs));
      getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit(prefs));
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
      _registerTodayDeps();
    });

    testWidgets(
      '[P0] 1.7-UNIT-003: redirects to /today when onboardingCompleted is true',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // TodayPage content confirms redirect to /today fired correctly
        expect(find.text('Inizia sessione'), findsOneWidget);
      },
    );

    testWidgets(
      '[P0] 1.7-UNIT-004: shell navigation bar is visible when onboarding complete',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // AppShell BottomNavigationBar confirms we are in the shell route
        expect(find.text('Oggi'), findsOneWidget);
        expect(find.text('Sessioni'), findsOneWidget);
        expect(find.text('Progressi'), findsOneWidget);
      },
    );
  });
}

class _StubDailyPlanBloc extends Bloc<DailyPlanEvent, DailyPlanState>
    implements DailyPlanBloc {
  _StubDailyPlanBloc() : super(DailyPlanState.loaded(plan: _todayPlan())) {
    on<DailyPlanGenerateRequested>((event, emit) {});
    on<DailyPlanRegenerateRequested>((event, emit) {});
  }
}

DailyPlan _todayPlan() => DailyPlan(
  planDate: '2026-05-15',
  sessions: const [
    PlannedSession(
      sessionType: 'mobility',
      intensity: 3,
      durationMinutes: 5,
      isIndoor: true,
      explanation: 'Sciogli le spalle.',
    ),
  ],
  generatedAt: DateTime.utc(2026, 5, 15, 8),
);
