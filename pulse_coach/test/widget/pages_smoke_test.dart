// [P1] Placeholder page smoke tests — ensures each feature page renders
// without crashing and displays the expected scaffold structure.
// All pages are placeholder UIs (Story X.x stubs); tests form a regression
// baseline for when real implementations replace them.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/database/app_database.dart' hide DailyPlan;
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
import 'package:pulse_coach/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/get_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/update_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse_coach/features/auth/domain/usecases/get_signed_in_user_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_apple_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/delete_account_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_up_with_email_use_case.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/profile_page.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_session_history.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
import 'package:pulse_coach/features/session/domain/usecases/update_bandit_reward.dart';
import 'package:pulse_coach/features/session/presentation/pages/rpe_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/session_summary_page.dart';
import 'package:pulse_coach/features/session/presentation/widgets/countdown_overlay.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/privacy_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/settings_page.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget page) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  home: Scaffold(body: page),
);

void main() {
  group('Shell tab pages — smoke tests', () {
    testWidgets('[P1] 1.7-WIDGET-001: TodayPage renders without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_todayPageWithProviders()));
      await tester.pump();
      expect(find.text('Inizia sessione'), findsOneWidget);
    });

    testWidgets('[P1] 1.7-WIDGET-002: SessionsPage renders without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(SessionsPage(cubit: _catalogCubit())));
      await tester.pumpAndSettle();
      expect(find.text('Hip Reset'), findsOneWidget);
    });

    testWidgets('[P1] 1.7-WIDGET-003: ProgressPage renders without crashing', (
      tester,
    ) async {
      getIt.registerFactory<ProgressCubit>(
        () => ProgressCubit(GetSessionHistory(_ProgressRepositoryStub())),
      );
      getIt.registerFactory<ProgressStatsCubit>(
        () => ProgressStatsCubit(GetProgressStats(_ProgressRepositoryStub())),
      );
      addTearDown(getIt.reset);

      await tester.pumpWidget(_wrap(const ProgressPage()));
      await tester.pumpAndSettle();
      expect(
        find.text('Nessuna sessione ancora. Inizia la tua prima oggi!'),
        findsOneWidget,
      );
    });
  });

  group('Onboarding pages — smoke tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs));
      getIt.registerSingleton<AppDatabase>(
        AppDatabase.forTesting(NativeDatabase.memory()),
      );
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
    });

    tearDown(() async {
      if (getIt.isRegistered<AppDatabase>()) {
        await getIt<AppDatabase>().close();
      }
      await getIt.reset();
    });

    testWidgets(
      '[P1] 1.7-WIDGET-004: OnboardingPage renders disclaimer screen',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const OnboardingPage()),
        );
        await tester.pumpAndSettle();
        // DisclaimerScreen is now the OnboardingPage content (Story 2.1)
        expect(find.text('Your data stays yours.'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 1.7-WIDGET-005: ProfilePage renders with correct AppBar title',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const ProfilePage()),
        );
        await tester.pumpAndSettle();
        // AppBar title is always visible (loading or form state)
        expect(find.text('Profile'), findsOneWidget);
      },
    );
  });

  group('Session pages — smoke tests', () {
    testWidgets(
      '[P1] 1.7-WIDGET-006: InSessionPage renders countdown full-screen',
      (tester) async {
        await tester.pumpWidget(_wrap(const InSessionPage()));
        await tester.pump();
        expect(find.byType(CountdownOverlay), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.byType(AppBar), findsNothing);
      },
    );

    testWidgets('[P1] 1.7-WIDGET-007: RpePage renders post-session RPE input', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton(db.rpeFeedbackDao);
      getIt.registerSingleton(UpdateBanditReward(db));
      addTearDown(() async {
        await db.close();
        await getIt.reset();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.darkTheme,
          // P4 fix: RpePage redirects to /today on null args; provide
          // realistic extras so the smoke test exercises the rendered UI.
          home: const RpePage(
            args: RpeSubmitArgs(
              planId: 1,
              sessionIndex: 0,
              abandoned: false,
              armKey: 'mobility_low',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppBar), findsNothing);
      expect(find.text("Com'è andata?"), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('[P1] 1.7-WIDGET-008: MiniSummaryPage renders without AppBar', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton(db.sessionLogsDao);
      getIt.registerSingleton(db.dailyPlansDao);
      addTearDown(() async {
        await db.close();
        await getIt.reset();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.darkTheme,
          home: const MiniSummaryPage(
            args: MiniSummaryArgs(
              rpeValue: 7,
              sessionType: 'mobility',
              durationMinutes: 12,
              abandoned: false,
              planId: 1,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Fatto!'), findsOneWidget);
    });
  });

  group('Settings pages — smoke tests', () {
    testWidgets(
      '[P1] 1.7-WIDGET-009: SettingsPage renders with correct AppBar title',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final authBloc = _StubAuthBloc();
        addTearDown(() async => authBloc.close());
        await tester.pumpWidget(
          _wrap(
            MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => ThemeCubit(prefs)),
                BlocProvider<AuthBloc>.value(value: authBloc),
              ],
              child: const SettingsPage(),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Impostazioni'), findsOneWidget);
        expect(find.text('Tema'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 1.7-WIDGET-010: PrivacyPage renders with correct AppBar title',
      (tester) async {
        await tester.pumpWidget(_wrap(const PrivacyPage()));
        await tester.pump();
        expect(find.text('Privacy'), findsOneWidget);
        expect(find.text('Dati solo sul dispositivo'), findsOneWidget);
      },
    );
  });
}

Widget _todayPageWithProviders() {
  return MultiBlocProvider(
    providers: [
      BlocProvider<DailyPlanBloc>(create: (_) => _StubDailyPlanBloc()),
      BlocProvider(create: (_) => _todaySessionCubit(1)),
    ],
    child: const TodayPage(),
  );
}

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

class _StubAuthBloc extends AuthBloc {
  _StubAuthBloc()
      : super(
          GetSignedInUserUseCase(_StubAuthRepository()),
          SignInWithAppleUseCase(_StubAuthRepository()),
          SignInWithGoogleUseCase(_StubAuthRepository()),
          SignInWithEmailUseCase(_StubAuthRepository()),
          SignUpWithEmailUseCase(_StubAuthRepository()),
          SignOutUseCase(_StubAuthRepository()),
          DeleteAccountUseCase(_StubAuthRepository()),
        );
}

class _StubAuthRepository implements AuthRepository {
  @override
  Future<Either<AuthFailure, AuthUser>> signInWithApple() async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithGoogle() async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, AuthUser?>> signUp({
    required String email,
    required String password,
  }) async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, Unit>> signOut() async =>
      const Left(AuthFailure('stub'));

  @override
  Future<AuthUser?> getSignedInUser() async => null;

  @override
  Future<Either<AuthFailure, Unit>> deleteAccount() async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, String>> exportData() async =>
      const Left(AuthFailure('stub'));
}
