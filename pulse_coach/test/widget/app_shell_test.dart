import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/app_database.dart' hide DailyPlan;
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
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
  return MaterialApp.router(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.darkTheme,
    routerConfig: router,
  );
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
