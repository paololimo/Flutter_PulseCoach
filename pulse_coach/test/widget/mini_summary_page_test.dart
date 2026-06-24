import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/app_database.dart' as db;
import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
import 'package:pulse_coach/features/session/presentation/pages/session_summary_page.dart';
import 'package:pulse_coach/features/today/presentation/widgets/completion_ring.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

const _args = MiniSummaryArgs(
  rpeValue: 7,
  sessionType: 'mobility',
  durationMinutes: 12,
  abandoned: false,
  planId: 42,
);

Widget _wrap(GoRouter router, {bool disableAnimations = true}) =>
    MaterialApp.router(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
    );

GoRouter _router({MiniSummaryArgs? args = _args}) => GoRouter(
  initialLocation: AppRouter.sessionSummary,
  routes: [
    GoRoute(
      path: AppRouter.sessionSummary,
      builder: (_, _) => MiniSummaryPage(args: args),
    ),
    GoRoute(
      path: AppRouter.today,
      builder: (_, _) => const Scaffold(body: Text('Today target')),
    ),
  ],
);

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('9.2-PAGE-001: renders summary content', (tester) async {
    _registerDaos(logs: [_log(0), _log(1)], sessionCount: 3);

    await tester.pumpWidget(_wrap(_router()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Fatto!'), findsOneWidget);
    expect(find.text('Mobilità'), findsOneWidget);
    expect(find.text('12 min'), findsOneWidget);
    expect(find.text('7/10'), findsOneWidget);
    expect(
      find.text("Registrato. Aggiustiamo l'intensità domani."),
      findsOneWidget,
    );
  });

  testWidgets('9.2-PAGE-002: abandoned session shows ended header', (
    tester,
  ) async {
    _registerDaos(logs: [_log(0, abandoned: true)], sessionCount: 3);

    await tester.pumpWidget(
      _wrap(
        _router(
          args: const MiniSummaryArgs(
            rpeValue: 6,
            sessionType: 'cardio',
            durationMinutes: 5,
            abandoned: true,
            planId: 42,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sessione finita'), findsOneWidget);
  });

  testWidgets('9.2-PAGE-003: MiniSummaryDone navigates to Today', (
    tester,
  ) async {
    _registerDaos(logs: [_log(0)], sessionCount: 1);

    await tester.pumpWidget(_wrap(_router()));
    await tester.pump(const Duration(milliseconds: 3300));
    await tester.pumpAndSettle();

    expect(find.text('Today target'), findsOneWidget);
  });

  testWidgets('9.2-PAGE-004: MiniSummaryFading lowers FadeTransition opacity', (
    tester,
  ) async {
    _registerDaos(logs: [_log(0)], sessionCount: 3);

    await tester.pumpWidget(_wrap(_router(), disableAnimations: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 100));

    final fades = tester.widgetList<FadeTransition>(
      find.byType(FadeTransition),
    );
    expect(fades.any((fade) => fade.opacity.value < 1.0), isTrue);
  });

  testWidgets('9.2-PAGE-005: CompletionRing receives loaded completed/total', (
    tester,
  ) async {
    _registerDaos(logs: [_log(0), _log(1)], sessionCount: 3);

    await tester.pumpWidget(_wrap(_router()));
    await tester.pump();
    await tester.pump();

    final ring = tester.widget<CompletionRing>(find.byType(CompletionRing));
    expect(ring.completed, 2);
    expect(ring.total, 3);
  });

  testWidgets('9.2-PAGE-006: null args bounce to Today without crash', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_router(args: null)));
    await tester.pumpAndSettle();

    expect(find.text('Today target'), findsOneWidget);
  });

  testWidgets(
    '9.2-PAGE-007: ring starts at previousCompletedCount then animates to '
    'newCompletedCount (review patch #3 — AC2)',
    (tester) async {
      _registerDaos(logs: [_log(0), _log(1)], sessionCount: 3);

      await tester.pumpWidget(_wrap(_router()));
      // First pump: cubit init() resolves, Loaded state emits, BlocBuilder
      // mounts _AnimatedRingTransition with completed=previousCount=1.
      await tester.pump();

      final firstRing = tester.widget<CompletionRing>(
        find.byType(CompletionRing),
      );
      expect(firstRing.completed, 1, reason: 'starts at previousCompletedCount');
      expect(firstRing.total, 3);

      // Second pump: post-frame callback flips _displayedCount to newCount.
      await tester.pump();

      final secondRing = tester.widget<CompletionRing>(
        find.byType(CompletionRing),
      );
      expect(secondRing.completed, 2, reason: 'animates to newCompletedCount');
    },
  );

  testWidgets(
    '9.2-PAGE-008: ring keeps showing newCompletedCount during Fading '
    "(review patch #2 — doesn't snap to 0/0)",
    (tester) async {
      _registerDaos(logs: [_log(0), _log(1), _log(2)], sessionCount: 3);

      await tester.pumpWidget(_wrap(_router(), disableAnimations: false));
      await tester.pump();
      await tester.pump();
      // Drive cubit past the 3000ms hold so Fading emits.
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump();

      final ring = tester.widget<CompletionRing>(find.byType(CompletionRing));
      expect(ring.completed, 3, reason: 'ring retains loaded count during fade');
      expect(ring.total, 3);
    },
  );

  testWidgets(
    '9.2-PAGE-009: Reduce Motion — fade is instant and still navigates to '
    'Today (review patch #5 — AC4)',
    (tester) async {
      _registerDaos(logs: [_log(0)], sessionCount: 3);

      await tester.pumpWidget(_wrap(_router(), disableAnimations: true));
      await tester.pump();
      // Hold expires → Fading. With Reduce Motion the listener navigates to
      // Today immediately without waiting for the 300ms fade timer.
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();

      expect(find.text('Today target'), findsOneWidget);
    },
  );

  testWidgets(
    '9.2-PAGE-011: final-session transition reaches (N-1)/N → N/N — the '
    'CompletionRing pulse-trigger condition (review patch #4 — AC3)',
    (tester) async {
      // 3 logs, 3 total → previousCompletedCount=2, newCompletedCount=3.
      // This is the exact `!wasCompleted && isCompleted` trigger inside
      // CompletionRing.didUpdateWidget. We assert the integration produces
      // those values; CompletionRing's own unit tests cover the pulse
      // animation itself.
      _registerDaos(logs: [_log(0), _log(1), _log(2)], sessionCount: 3);

      await tester.pumpWidget(_wrap(_router(), disableAnimations: false));
      await tester.pump();

      final firstRing = tester.widget<CompletionRing>(
        find.byType(CompletionRing),
      );
      expect(firstRing.completed, 2, reason: 'starts at (N-1)/N = 2/3');
      expect(firstRing.total, 3);

      await tester.pump();

      final secondRing = tester.widget<CompletionRing>(
        find.byType(CompletionRing),
      );
      expect(secondRing.completed, 3, reason: 'transitions to N/N = 3/3');
      expect(secondRing.total, 3);
    },
  );

  testWidgets(
    '9.2-PAGE-010: MiniSummaryError short-circuits to Today (review patch #1)',
    (tester) async {
      // Inject a corrupt plan row so MiniSummaryCubit.init throws and emits
      // MiniSummaryError; the page listener must route to Today rather than
      // trap the user behind PopScope.
      getIt.registerSingleton<SessionLogsDao>(_FakeSessionLogsDao([_log(0)]));
      getIt.registerSingleton<DailyPlansDao>(
        _FakeDailyPlansDao(_corruptPlanRow()),
      );

      await tester.pumpWidget(_wrap(_router()));
      await tester.pumpAndSettle();

      expect(find.text('Today target'), findsOneWidget);
    },
  );

  testWidgets(
    '18.3-WIDGET-NEW-001: no SubscriptionBloc in context → share toggle hidden',
    (tester) async {
      _registerDaos(logs: [_log(0)], sessionCount: 3);

      await tester.pumpWidget(_wrap(_router()));
      await tester.pump();

      expect(find.byType(SwitchListTile), findsNothing);
    },
  );

  testWidgets(
    '18.3-WIDGET-NEW-002: Pro subscription → share toggle visible, default OFF',
    (tester) async {
      _registerDaos(logs: [_log(0)], sessionCount: 3);

      await tester.pumpWidget(
        BlocProvider<SubscriptionBloc>.value(
          value: _FakeSubscriptionBloc(
            const SubscriptionState.loaded(tier: SubscriptionTier.pro),
          ),
          child: _wrap(_router()),
        ),
      );
      await tester.pump();

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isFalse);
    },
  );

  testWidgets(
    '18.3-WIDGET-NEW-003: Pro subscription → tap share toggle → value becomes ON',
    (tester) async {
      _registerDaos(logs: [_log(0)], sessionCount: 3);

      await tester.pumpWidget(
        BlocProvider<SubscriptionBloc>.value(
          value: _FakeSubscriptionBloc(
            const SubscriptionState.loaded(tier: SubscriptionTier.pro),
          ),
          child: _wrap(_router()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isTrue);
    },
  );
}

// 9.2-PAGE-011 declared below — pulse coverage for AC3 (review patch #4).

db.DailyPlan _corruptPlanRow() {
  final generatedAt = DateTime.utc(2026, 5, 21, 8);
  return db.DailyPlan(
    id: 42,
    planDate: '2026-05-21',
    planJson: '{not json',
    generatedAt: generatedAt,
    createdAt: generatedAt,
    isCompleted: false,
  );
}

void _registerDaos({
  required List<db.SessionLog> logs,
  required int sessionCount,
}) {
  getIt.registerSingleton<SessionLogsDao>(_FakeSessionLogsDao(logs));
  getIt.registerSingleton<DailyPlansDao>(
    _FakeDailyPlansDao(_planRow(sessionCount: sessionCount)),
  );
}

db.SessionLog _log(int sessionIndex, {bool abandoned = false}) => db.SessionLog(
  id: sessionIndex + 1,
  dailyPlanId: 42,
  sessionIndex: sessionIndex,
  completedAt: DateTime.utc(2026, 5, 21, 9, sessionIndex),
  createdAt: DateTime.utc(2026, 5, 21, 9, sessionIndex),
  abandoned: abandoned,
);

db.DailyPlan _planRow({required int sessionCount}) {
  final generatedAt = DateTime.utc(2026, 5, 21, 8);
  final plan = domain.DailyPlan(
    planDate: '2026-05-21',
    sessions: List.generate(
      sessionCount,
      (_) => const PlannedSession(
        sessionType: 'mobility',
        intensity: 4,
        durationMinutes: 12,
        isIndoor: true,
      ),
    ),
    generatedAt: generatedAt,
  );
  return db.DailyPlan(
    id: 42,
    planDate: '2026-05-21',
    planJson: jsonEncode(plan.toJson()),
    generatedAt: generatedAt,
    createdAt: generatedAt,
    isCompleted: false,
  );
}

class _FakeSessionLogsDao extends Fake implements SessionLogsDao {
  final List<db.SessionLog> logs;

  _FakeSessionLogsDao(this.logs);

  @override
  Future<List<db.SessionLog>> getLogsForPlan(int planId) async => logs;
}

class _FakeDailyPlansDao extends Fake implements DailyPlansDao {
  final db.DailyPlan planRow;

  _FakeDailyPlansDao(this.planRow);

  @override
  Future<db.DailyPlan?> getPlanById(int id) async => planRow;
}

class _FakeSubscriptionBloc extends Fake implements SubscriptionBloc {
  final SubscriptionState _state;
  _FakeSubscriptionBloc(this._state);

  @override
  SubscriptionState get state => _state;

  @override
  Stream<SubscriptionState> get stream => const Stream.empty();

  @override
  bool get isClosed => false;

  @override
  void add(SubscriptionEvent event) {}
}
