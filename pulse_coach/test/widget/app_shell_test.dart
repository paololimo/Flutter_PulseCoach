import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/app_database.dart' hide DailyPlan;
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_session_history.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_gating_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_cubit.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/repositories/entitlement_repository.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/check_entitlement_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/get_install_cohort_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/purchase_pro_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/restore_purchases_use_case.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/app_shell.dart';

class _StubToday extends StatelessWidget {
  const _StubToday();
  @override
  Widget build(BuildContext context) => const Text('Oggi');
}

/// Stub entitlement repo: always signedInFree (no RevenueCat needed in tests).
class _StubEntitlementRepository implements EntitlementRepository {
  @override
  Future<SubscriptionTier> currentTier() async => SubscriptionTier.signedInFree;
  @override
  Future<void> invalidateCache() async {}
  @override
  Future<Either<Failure, List<ProOffer>>> getOfferings() async =>
      const Right([]);
  @override
  Future<Either<Failure, SubscriptionTier>> purchasePro(
    String packageId,
  ) async => const Right(SubscriptionTier.pro);
  @override
  Future<Either<Failure, SubscriptionTier>> restorePurchases() async =>
      const Right(SubscriptionTier.pro);
}

/// Stub onboarding repo: no profile (getInstallCohort returns null).
class _StubOnboardingRepositoryForGating implements OnboardingRepository {
  @override
  Future<Either<Failure, void>> acceptDisclaimer() async => const Right(null);
  @override
  Future<Either<Failure, bool>> isDisclaimerAccepted() async => const Right(false);
  @override
  Future<Either<Failure, void>> saveProfile(UserProfile profile) async => const Right(null);
  @override
  Future<Either<Failure, UserProfile>> getProfile() async =>
      const Left(CacheFailure('no profile'));
  @override
  Future<Either<Failure, void>> updateProfile(UserProfile profile) async =>
      const Right(null);
  @override
  Future<Either<Failure, String?>> getInstallCohort() async => const Right(null);
}

Widget _wrapWithRootBlocs(Widget child) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<SubscriptionBloc>(
        create: (_) {
          final repo = _StubEntitlementRepository();
          return SubscriptionBloc(
            CheckEntitlementUseCase(repo),
            PurchaseProUseCase(repo),
            RestorePurchasesUseCase(repo),
          );
        },
      ),
    ],
    child: child,
  );
}

Widget buildShellWithSecondaryRoutes() {
  final router = GoRouter(
    initialLocation: '/today',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/today', builder: (_, _) => const _StubToday()),
          GoRoute(path: '/sessions', builder: (_, _) => const Placeholder()),
          GoRoute(path: '/progress', builder: (_, _) => const Placeholder()),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Settings Stub')),
          body: const Text('settings-body'),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Profile Stub')),
          body: const Text('profile-body'),
        ),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Privacy Stub')),
          body: const Text('privacy-body'),
        ),
      ),
      GoRoute(
        path: '/ai-decision-log',
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('AI Decision Log Stub')),
          body: const Text('ai-decision-log-body'),
        ),
      ),
    ],
  );
  return _wrapWithRootBlocs(
    MaterialApp.router(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    ),
  );
}

Widget buildTestShell({String initialLocation = '/today'}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider<DailyPlanBloc>(
                  create: (_) => _StubDailyPlanBloc(),
                ),
                BlocProvider(create: (_) => _todaySessionCubit(1)),
              ],
              child: const TodayPage(),
            ),
          ),
          GoRoute(
            path: '/sessions',
            builder: (context, state) => SessionsPage(cubit: _catalogCubit()),
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressPage(),
          ),
        ],
      ),
    ],
  );
  return _wrapWithRootBlocs(
    MaterialApp.router(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    ),
  );
}

void main() {
  group('AppShell', () {
    setUp(() {
      getIt.registerFactory<ProgressCubit>(
        () => ProgressCubit(GetSessionHistory(_ProgressRepositoryStub())),
      );
      getIt.registerFactory<ProgressStatsCubit>(
        () => ProgressStatsCubit(GetProgressStats(_ProgressRepositoryStub())),
      );
      getIt.registerFactory<ProgressGatingCubit>(
        () => ProgressGatingCubit(
          GetInstallCohortUseCase(_StubOnboardingRepositoryForGating()),
        ),
      );
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('shows BottomNavigationBar with 3 items', (tester) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Oggi'), findsOneWidget);
      expect(find.text('Sessioni'), findsOneWidget);
      expect(find.text('Progressi'), findsOneWidget);
    });

    testWidgets('shows Drawer with Profile, Settings, Privacy', (tester) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DrawerButton));
      await tester.pumpAndSettle();
      expect(find.text('Profilo'), findsOneWidget);
      expect(find.text('Impostazioni'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
    });

    testWidgets('Today tab is selected at initial location /today', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildTestShell(initialLocation: '/today'));
      await tester.pumpAndSettle();
      final bnb = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bnb.currentIndex, 1);
    });

    testWidgets('tapping Sessions tab navigates to /sessions', (tester) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sessioni'));
      await tester.pumpAndSettle();
      expect(find.text('Hip Reset'), findsOneWidget);
    });

    // [P1] 1.7-UNIT-004: _currentIndex edge cases not covered above
    testWidgets('Sessions tab index is 0 at initial location /sessions', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildTestShell(initialLocation: '/sessions'));
      await tester.pumpAndSettle();
      final bnb = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bnb.currentIndex, 0);
    });

    testWidgets('Progress tab index is 2 at initial location /progress', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildTestShell(initialLocation: '/progress'));
      await tester.pumpAndSettle();
      final bnb = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bnb.currentIndex, 2);
    });

    testWidgets(
      '11.1-WIDGET-001: tablet width shows NavigationRail with 3 destinations',
      (tester) async {
        await setTabletSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildTestShell());
        await tester.pumpAndSettle();
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(find.text('Oggi'), findsOneWidget);
        expect(find.text('Sessioni'), findsOneWidget);
        expect(find.text('Progressi'), findsOneWidget);
      },
    );

    testWidgets(
      '11.1-WIDGET-002: phone width shows BottomNavigationBar, no NavigationRail',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildTestShell());
        await tester.pumpAndSettle();
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      },
    );

    testWidgets(
      '11.1-WIDGET-003: selected tab index is preserved when surface resizes across 600dp',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildTestShell(initialLocation: '/progress'));
        await tester.pumpAndSettle();
        final bnb = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bnb.currentIndex, 2);

        await tester.binding.setSurfaceSize(const Size(800, 1024));
        await tester.pump();

        expect(find.byType(NavigationRail), findsOneWidget);
        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, 2);
      },
    );

    testWidgets(
      '11.1-WIDGET-004: tablet lower breakpoint renders rail labels without overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 1024));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestShell());
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('Oggi'), findsOneWidget);
        expect(find.text('Sessioni'), findsOneWidget);
        expect(find.text('Progressi'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '15.1-NAV-001: drawer Settings tile pushes settings route with back button',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildShellWithSecondaryRoutes());
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DrawerButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Impostazioni'));
        await tester.pumpAndSettle();
        expect(find.text('Settings Stub'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);
      },
    );

    testWidgets(
      '15.1-NAV-002: drawer Profile tile pushes profile route with back button',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildShellWithSecondaryRoutes());
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DrawerButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Profilo'));
        await tester.pumpAndSettle();
        expect(find.text('Profile Stub'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);
      },
    );

    testWidgets(
      '15.1-NAV-003: drawer Privacy tile pushes privacy route with back button',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildShellWithSecondaryRoutes());
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DrawerButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Privacy'));
        await tester.pumpAndSettle();
        expect(find.text('Privacy Stub'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);
      },
    );

    testWidgets(
      '15.1-NAV-004: popping settings route restores shell BottomNavigationBar',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildShellWithSecondaryRoutes());
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DrawerButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Impostazioni'));
        await tester.pumpAndSettle();
        expect(find.text('Settings Stub'), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      },
    );

    testWidgets(
      '15.1-NAV-005: drawer AI Decision Log tile pushes route with back button',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildShellWithSecondaryRoutes());
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DrawerButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('AI Decision Log'));
        await tester.pumpAndSettle();
        expect(find.text('AI Decision Log Stub'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);
      },
    );

    testWidgets(
      '15.1-NAV-006: AC6 tab state preserved — Sessions tab stays selected after push+pop',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildShellWithSecondaryRoutes());
        await tester.pumpAndSettle();
        // Navigate to Sessions tab (index 0)
        await tester.tap(find.text('Sessioni'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
          0,
        );
        // Open drawer and push Settings
        await tester.tap(find.byType(DrawerButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Impostazioni'));
        await tester.pumpAndSettle();
        expect(find.text('Settings Stub'), findsOneWidget);
        // Pop back and verify Sessions tab index is still 0
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
          0,
        );
      },
    );

    testWidgets(
      '15.1-NAV-007: AC6 tab state preserved — Progress tab stays selected after push+pop',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(buildShellWithSecondaryRoutes());
        await tester.pumpAndSettle();
        // Navigate to Progress tab (index 2)
        await tester.tap(find.text('Progressi'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
          2,
        );
        // Open drawer and push Profile
        await tester.tap(find.byType(DrawerButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Profilo'));
        await tester.pumpAndSettle();
        expect(find.text('Profile Stub'), findsOneWidget);
        // Pop back and verify Progress tab index is still 2
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
          2,
        );
      },
    );
  });
}

Future<void> setPhoneSurface(WidgetTester tester) =>
    tester.binding.setSurfaceSize(const Size(390, 844));

Future<void> setTabletSurface(WidgetTester tester) =>
    tester.binding.setSurfaceSize(const Size(800, 1024));

TodaySessionCubit _todaySessionCubit(int totalSessions) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final cubit = _TestingTodaySessionCubit(db);
  cubit.planLoaded(totalSessions, null).ignore();
  return cubit;
}

class _TestingTodaySessionCubit extends TodaySessionCubit {
  final AppDatabase _db;

  _TestingTodaySessionCubit(this._db) : super(_db.sessionLogsDao);

  @override
  Future<void> close() async {
    await super.close();
    await _db.close();
  }
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

SessionsCatalogCubit _catalogCubit() {
  return SessionsCatalogCubit(GetExercisesByType(_ExerciseRepositoryStub()));
}

class _ExerciseRepositoryStub implements ExerciseRepository {
  @override
  Future<Either<Failure, List<Exercise>>> getExercisesByType(
    String sessionType,
  ) async {
    return Right([
      Exercise(
        id: '$sessionType-1',
        name: sessionType == 'mobility' ? 'Hip Reset' : '$sessionType session',
        description: 'Test session',
        sessionType: sessionType,
        steps: const ['Start', 'Finish'],
        durationMinutes: 5,
        difficulty: 'low',
        indoorCompatible: true,
        outdoorCompatible: true,
      ),
    ]);
  }

  @override
  Future<Either<Failure, Unit>> syncCatalog() async => const Right(unit);
}

class _ProgressRepositoryStub implements ProgressRepository {
  @override
  Future<Either<Failure, List<SessionHistoryEntry>>> getSessionHistory() async {
    return const Right(<SessionHistoryEntry>[]);
  }

  @override
  Future<Either<Failure, ProgressStats>> getProgressStats() async {
    return const Right(
      ProgressStats(
        completedCount: 0,
        abandonedCount: 0,
        minutesPerWeek: [],
        rpeTrend: [],
        sessionTypeCounts: {},
        completedThisWeek: 0,
        weeklyTarget: 3,
      ),
    );
  }
}
