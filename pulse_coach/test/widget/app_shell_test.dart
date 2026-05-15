import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';
import 'package:pulse_coach/shared/widgets/app_shell.dart';

Widget buildTestShell({String initialLocation = '/today'}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const TodayPage(),
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
  return MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router);
}

void main() {
  group('AppShell', () {
    testWidgets('shows BottomNavigationBar with 3 items', (tester) async {
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
    });

    testWidgets('shows Drawer with Profile, Settings, Privacy', (tester) async {
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DrawerButton));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
    });

    testWidgets('Today tab is selected at initial location /today', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestShell(initialLocation: '/today'));
      await tester.pumpAndSettle();
      final bnb = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bnb.currentIndex, 1);
    });

    testWidgets('tapping Sessions tab navigates to /sessions', (tester) async {
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sessions'));
      await tester.pumpAndSettle();
      expect(find.text('Hip Reset'), findsOneWidget);
    });

    // [P1] 1.7-UNIT-004: _currentIndex edge cases not covered above
    testWidgets('Sessions tab index is 0 at initial location /sessions', (
      tester,
    ) async {
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
      await tester.pumpWidget(buildTestShell(initialLocation: '/progress'));
      await tester.pumpAndSettle();
      final bnb = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bnb.currentIndex, 2);
    });
  });
}

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
