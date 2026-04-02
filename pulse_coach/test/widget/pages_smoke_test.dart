// [P1] Placeholder page smoke tests — ensures each feature page renders
// without crashing and displays the expected scaffold structure.
// All pages are placeholder UIs (Story X.x stubs); tests form a regression
// baseline for when real implementations replace them.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/profile_page.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/rpe_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/session_summary_page.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/privacy_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/settings_page.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';

Widget _wrap(Widget page) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: page),
    );

void main() {
  group('Shell tab pages — smoke tests', () {
    testWidgets(
      '[P1] 1.7-WIDGET-001: TodayPage renders without crashing',
      (tester) async {
        await tester.pumpWidget(_wrap(const TodayPage()));
        await tester.pump();
        expect(find.text('Today — Story 7.x'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 1.7-WIDGET-002: SessionsPage renders without crashing',
      (tester) async {
        await tester.pumpWidget(_wrap(const SessionsPage()));
        await tester.pump();
        expect(find.text('Sessions — Story 6.x'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 1.7-WIDGET-003: ProgressPage renders without crashing',
      (tester) async {
        await tester.pumpWidget(_wrap(const ProgressPage()));
        await tester.pump();
        expect(find.text('Progress — Story 10.x'), findsOneWidget);
      },
    );
  });

  group('Onboarding pages — smoke tests', () {
    setUp(() {
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
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
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OnboardingPage(),
        ));
        await tester.pumpAndSettle();
        // DisclaimerScreen is now the OnboardingPage content (Story 2.1)
        expect(find.text('Your data stays yours.'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 1.7-WIDGET-005: ProfilePage renders with correct AppBar title',
      (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfilePage(),
        ));
        await tester.pump();
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Profile — Story 2.x'), findsOneWidget);
      },
    );
  });

  group('Session pages — smoke tests', () {
    testWidgets(
      '[P1] 1.7-WIDGET-006: InSessionPage renders with correct AppBar title',
      (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: const InSessionPage(),
        ));
        await tester.pump();
        expect(find.text('In Session'), findsOneWidget);
        expect(find.text('In Session — Story 8.x'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 1.7-WIDGET-007: RpePage renders with correct AppBar title',
      (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: const RpePage(),
        ));
        await tester.pump();
        expect(find.text('RPE'), findsOneWidget);
        expect(find.text('RPE — Story 9.x'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 1.7-WIDGET-008: SessionSummaryPage renders with correct AppBar title',
      (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SessionSummaryPage(),
        ));
        await tester.pump();
        expect(find.text('Summary'), findsOneWidget);
        expect(find.text('Summary — Story 9.x'), findsOneWidget);
      },
    );
  });

  group('Settings pages — smoke tests', () {
    testWidgets(
      '[P1] 1.7-WIDGET-009: SettingsPage renders with correct AppBar title',
      (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SettingsPage(),
        ));
        await tester.pump();
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Settings — Story 14.x'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 1.7-WIDGET-010: PrivacyPage renders with correct AppBar title',
      (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PrivacyPage(),
        ));
        await tester.pump();
        expect(find.text('Privacy'), findsOneWidget);
        expect(find.text('Privacy — Story 14.x'), findsOneWidget);
      },
    );
  });
}
