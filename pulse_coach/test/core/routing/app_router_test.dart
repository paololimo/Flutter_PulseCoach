// [P0] AppRouter redirect logic tests
// Tests the onboarding gate: no profile → /onboarding, profile → /today
// Strategy: pump PulseCoachApp with controlled database state,
// let GoRouter redirect settle, then assert the correct page renders.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';

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
    });

    testWidgets(
      '[P0] 1.7-UNIT-001: redirects to /onboarding when no profile exists',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // OnboardingPage body text confirms the redirect fired correctly
        expect(find.text('Onboarding — Story 2.x'), findsOneWidget);
      },
    );

    testWidgets(
      '[P0] 1.7-UNIT-002: /onboarding page is reachable without profile',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // The OnboardingPage AppBar title is rendered
        expect(find.text('Onboarding'), findsOneWidget);
      },
    );
  });

  group('AppRouter redirect — user profile present', () {
    setUp(() async {
      getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.userProfileDao.insertProfile(
        UserProfileCompanion.insert(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      getIt.registerSingleton<AppDatabase>(db);
    });

    testWidgets(
      '[P0] 1.7-UNIT-003: redirects to /today when profile exists',
      (tester) async {
        await tester.pumpWidget(const PulseCoachApp());
        await tester.pumpAndSettle();
        // TodayPage content confirms redirect to /today fired correctly
        expect(find.text('Today — Story 7.x'), findsOneWidget);
      },
    );

    testWidgets(
      '[P0] 1.7-UNIT-004: shell navigation bar is visible when profile exists',
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
