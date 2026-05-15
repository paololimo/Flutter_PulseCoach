import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/error/failures.dart';
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
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

import 'today_page_test.mocks.dart';

@GenerateMocks([DailyPlanBloc])
void main() {
  late MockDailyPlanBloc dailyPlanBloc;

  setUpAll(() {
    provideDummy<DailyPlanState>(const DailyPlanState.initial());
  });

  setUp(() {
    dailyPlanBloc = MockDailyPlanBloc();
    when(dailyPlanBloc.stream).thenAnswer((_) => const Stream.empty());
    when(dailyPlanBloc.close()).thenAnswer((_) async {});
  });

  Widget wrap({
    required DailyPlanState planState,
    TodaySessionState? sessionState,
  }) {
    when(dailyPlanBloc.state).thenReturn(planState);

    final cubit = _TestingTodaySessionCubit();
    final total = switch (planState) {
      DailyPlanLoaded(:final plan) => plan.sessions.length,
      _ => sessionState?.totalSessions ?? 0,
    };
    cubit.planLoaded(total);
    if (sessionState != null) cubit.seed(sessionState);

    return MaterialApp(
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

  group('TodayPage', () {
    testWidgets('7.3-PAGE-001: loading shows shimmer and no hero', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(planState: const DailyPlanState.loading()));

      expect(find.byType(ShimmerPlaceholder), findsWidgets);
      expect(find.byType(HeroSessionCard), findsNothing);
    });

    testWidgets('7.3-PAGE-002: one loaded session shows hero only', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(1))),
      );

      expect(find.byType(HeroSessionCard), findsOneWidget);
      expect(find.text('COMING UP'), findsNothing);
      expect(find.byType(CompactSessionCard), findsNothing);
    });

    testWidgets('7.3-PAGE-003: three sessions show hero and two upcoming', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
      );

      expect(find.byType(HeroSessionCard), findsOneWidget);
      expect(find.text('COMING UP'), findsOneWidget);
      expect(find.byType(CompactSessionCard), findsNWidgets(2));
    });

    testWidgets('7.3-PAGE-004: loaded state shows StateIndicator', (
      tester,
    ) async {
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
      await tester.pumpWidget(
        wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
      );

      expect(find.byType(CompletionRing), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
    });

    testWidgets('7.3-PAGE-006: never shows CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(planState: const DailyPlanState.loading()));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('7.3-PAGE-007: all done shows completion state', (
      tester,
    ) async {
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
      '7.3-PAGE-011: mark completed progresses hero and shrinks coming-up',
      (tester) async {
        await tester.pumpWidget(
          wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
        );

        // Initial: 3 sessions → hero is Mobilità (index 0), 2 in COMING UP.
        expect(
          find.descendant(
            of: find.byType(HeroSessionCard),
            matching: find.text('Mobilità'),
          ),
          findsOneWidget,
        );
        expect(find.byType(CompactSessionCard), findsNWidgets(2));

        // Tap "Inizia sessione" to complete the hero.
        await tester.tap(find.text('Inizia sessione'));
        await tester.pumpAndSettle();

        // Cardio becomes the new hero, Breathing remains as 1 upcoming.
        expect(
          find.descendant(
            of: find.byType(HeroSessionCard),
            matching: find.text('Cardio'),
          ),
          findsOneWidget,
        );
        expect(find.byType(CompactSessionCard), findsOneWidget);
        // CompletionRing shows 1/3.
        expect(find.text('1/3'), findsOneWidget);
      },
    );

    testWidgets('7.3-PAGE-008: error state shows warning UI', (tester) async {
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
      await tester.pumpWidget(wrap(planState: const DailyPlanState.initial()));

      expect(find.byType(ShimmerPlaceholder), findsWidgets);
    });

    testWidgets('7.3-PAGE-010: tapping compact card swaps hero in-page', (
      tester,
    ) async {
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
  void seed(TodaySessionState state) => emit(state);
}
