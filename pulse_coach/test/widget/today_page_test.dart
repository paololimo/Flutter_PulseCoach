import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';
import 'package:pulse_coach/features/today/presentation/widgets/compact_session_card.dart';
import 'package:pulse_coach/features/today/presentation/widgets/completion_ring.dart';
import 'package:pulse_coach/features/today/presentation/widgets/hero_session_card.dart';
import 'package:pulse_coach/features/today/presentation/widgets/state_indicator.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

import 'today_page_test.mocks.dart';

@GenerateMocks([DailyPlanBloc, SessionLogsDao])
void main() {
  late MockDailyPlanBloc dailyPlanBloc;
  late MockSessionLogsDao sessionLogsDao;

  setUpAll(() {
    provideDummy<DailyPlanState>(const DailyPlanState.initial());
  });

  setUp(() {
    dailyPlanBloc = MockDailyPlanBloc();
    sessionLogsDao = MockSessionLogsDao();
    when(dailyPlanBloc.stream).thenAnswer((_) => const Stream.empty());
    when(dailyPlanBloc.close()).thenAnswer((_) async {});
  });

  Widget wrap({
    required DailyPlanState planState,
    TodaySessionState? sessionState,
  }) {
    when(dailyPlanBloc.state).thenReturn(planState);

    final cubit = _TestingTodaySessionCubit(sessionLogsDao);
    final total = switch (planState) {
      DailyPlanLoaded(:final plan) => plan.sessions.length,
      _ => sessionState?.totalSessions ?? 0,
    };
    cubit.planLoaded(total, null).ignore();
    if (sessionState != null) cubit.seed(sessionState);

    return MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<DailyPlanBloc>.value(value: dailyPlanBloc),
            BlocProvider<TodaySessionCubit>.value(value: cubit),
          ],
          child: const TodayPage(),
        ),
      ),
    );
  }

  Widget wrapWithRouter({required DailyPlanState planState}) {
    when(dailyPlanBloc.state).thenReturn(planState);

    final cubit = _TestingTodaySessionCubit(sessionLogsDao);
    final total = switch (planState) {
      DailyPlanLoaded(:final plan) => plan.sessions.length,
      _ => 0,
    };
    cubit.seed(TodaySessionState(totalSessions: total));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<DailyPlanBloc>.value(value: dailyPlanBloc),
              BlocProvider<TodaySessionCubit>.value(value: cubit),
            ],
            child: const TodayPage(),
          ),
        ),
        GoRoute(
          path: AppRouter.sessionActive,
          builder: (context, state) =>
              const Scaffold(body: Text('session_stub')),
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

  Future<void> setPhoneSurface(WidgetTester tester) =>
      tester.binding.setSurfaceSize(const Size(390, 844));

  Future<void> setTabletSurface(WidgetTester tester) =>
      tester.binding.setSurfaceSize(const Size(800, 1024));

  group('TodayPage', () {
    testWidgets('7.3-PAGE-001: loading shows shimmer and no hero', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(planState: const DailyPlanState.loading()));

      expect(find.byType(ShimmerPlaceholder), findsWidgets);
      expect(find.byType(HeroSessionCard), findsNothing);
    });

    testWidgets('7.3-PAGE-002: one loaded session shows hero only', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(1))),
      );

      expect(find.byType(HeroSessionCard), findsOneWidget);
      expect(find.text('PROSSIME'), findsNothing);
      expect(find.byType(CompactSessionCard), findsNothing);
    });

    testWidgets('7.3-PAGE-003: three sessions show hero and two upcoming', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
      );

      expect(find.byType(HeroSessionCard), findsOneWidget);
      expect(find.text('PROSSIME'), findsOneWidget);
      expect(find.byType(CompactSessionCard), findsNWidgets(2));
    });

    testWidgets('7.3-PAGE-004: loaded state shows StateIndicator', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          planState: DailyPlanState.loaded(
            plan: _plan(1),
            behavioralState: BehavioralState.recovering,
          ),
        ),
      );

      expect(find.byType(StateIndicator), findsOneWidget);
      expect(find.text('In recupero'), findsOneWidget);
    });

    testWidgets('7.3-PAGE-005: loaded state shows CompletionRing', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
      );

      expect(find.byType(CompletionRing), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
    });

    testWidgets('7.4-PAGE-001: loaded state shows regenerate IconButton', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
      );

      expect(find.widgetWithIcon(IconButton, Icons.refresh), findsOneWidget);
    });

    testWidgets(
      '7.4-PAGE-002: tapping regenerate dispatches DailyPlanRegenerateRequested',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
        );

        await tester.tap(find.byIcon(Icons.refresh));

        verify(
          dailyPlanBloc.add(argThat(isA<DailyPlanRegenerateRequested>())),
        ).called(1);
      },
    );

    testWidgets('7.4-PAGE-003: loading state hides regenerate IconButton', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(planState: const DailyPlanState.loading()));

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('7.3-PAGE-006: never shows CircularProgressIndicator', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(planState: const DailyPlanState.loading()));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('7.3-PAGE-007: all done shows completion state', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          planState: DailyPlanState.loaded(plan: _plan(3)),
          sessionState: const TodaySessionState(
            heroIndex: 2,
            completedIndices: {0, 1, 2},
            totalSessions: 3,
          ),
        ),
      );

      expect(find.byType(HeroSessionCard), findsNothing);
      expect(find.text('Ottimo lavoro!'), findsOneWidget);
      expect(
        find.text('Tutte le sessioni completate per oggi.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '7.3-PAGE-011: tapping Start Session navigates to session view',
      (tester) async {
        await setPhoneSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          wrapWithRouter(planState: DailyPlanState.loaded(plan: _plan(3))),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HeroSessionCard), findsOneWidget);

        await tester.tap(find.text('Inizia sessione'));
        await tester.pumpAndSettle();

        expect(find.text('session_stub'), findsOneWidget);
      },
    );

    testWidgets('7.3-PAGE-008: error state shows warning UI', (tester) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          planState: const DailyPlanState.error(
            failure: CacheFailure('offline'),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      expect(find.text('Impossibile caricare il piano.'), findsOneWidget);
    });

    testWidgets('7.3-PAGE-009: initial state shows shimmer', (tester) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(planState: const DailyPlanState.initial()));

      expect(find.byType(ShimmerPlaceholder), findsWidgets);
    });

    testWidgets('7.3-PAGE-010: tapping compact card swaps hero in-page', (
      tester,
    ) async {
      await setPhoneSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
      );

      expect(
        find.descendant(
          of: find.byType(HeroSessionCard),
          matching: find.text('Mobilità'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(CompactSessionCard, 'Cardio'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(HeroSessionCard),
          matching: find.text('Cardio'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('11.2-WIDGET-001: tablet shows two-panel layout', (
      tester,
    ) async {
      await setTabletSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
      );

      expect(find.byType(HeroSessionCard), findsNothing);
      expect(find.byType(StateIndicator), findsOneWidget);
      expect(find.byType(CompletionRing), findsOneWidget);
      expect(find.byType(VerticalDivider), findsWidgets);
    });

    testWidgets('11.2-WIDGET-002: left panel shows all 3 sessions on tablet', (
      tester,
    ) async {
      await setTabletSurface(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
      );

      expect(find.byType(CompactSessionCard), findsNWidgets(3));
    });

    testWidgets(
      '11.2-WIDGET-003: right panel shows full explanation on tablet',
      (tester) async {
        await setTabletSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
        );

        expect(find.text('Sciogli le spalle.'), findsOneWidget);
      },
    );

    testWidgets(
      '11.2-WIDGET-004: right panel shows step preview rows on tablet',
      (tester) async {
        await setTabletSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          wrap(planState: DailyPlanState.loaded(plan: _plan(1))),
        );

        expect(find.text('Riscaldamento'), findsOneWidget);
        expect(find.text('Defaticamento'), findsOneWidget);
      },
    );

    testWidgets(
      '11.2-WIDGET-005: tapping session in left panel updates right panel',
      (tester) async {
        await setTabletSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
        );

        expect(find.text('Sciogli le spalle.'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(CompactSessionCard, 'Cardio').first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Ritmo leggero.'), findsOneWidget);
        expect(find.text('Sciogli le spalle.'), findsNothing);
      },
    );

    testWidgets(
      '11.2-WIDGET-006: all-done state shows AllDoneWidget on tablet',
      (tester) async {
        await setTabletSurface(tester);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          wrap(
            planState: DailyPlanState.loaded(plan: _plan(3)),
            sessionState: const TodaySessionState(
              heroIndex: 2,
              completedIndices: {0, 1, 2},
              totalSessions: 3,
            ),
          ),
        );

        expect(find.text('Ottimo lavoro!'), findsOneWidget);
        expect(find.byType(CompactSessionCard), findsNothing);
      },
    );
  });
}

DailyPlan _plan(int count) {
  final sessions = [
    _session(type: 'mobility', duration: 5, explanation: 'Sciogli le spalle.'),
    _session(type: 'cardio', duration: 10, explanation: 'Ritmo leggero.'),
    _session(type: 'breathing', duration: 5, explanation: 'Respira piano.'),
  ];

  return DailyPlan(
    planDate: '2026-05-15',
    sessions: sessions.take(count).toList(),
    generatedAt: DateTime.utc(2026, 5, 15, 8),
  );
}

PlannedSession _session({
  required String type,
  required int duration,
  required String explanation,
}) => PlannedSession(
  sessionType: type,
  intensity: 3,
  durationMinutes: duration,
  isIndoor: true,
  explanation: explanation,
);

class _TestingTodaySessionCubit extends TodaySessionCubit {
  _TestingTodaySessionCubit(super.sessionLogsDao);

  void seed(TodaySessionState state) => emit(state);
}
