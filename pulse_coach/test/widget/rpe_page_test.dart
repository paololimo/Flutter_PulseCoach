import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/rpe_feedback_dao.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
import 'package:pulse_coach/features/session/domain/usecases/update_bandit_reward.dart';
import 'package:pulse_coach/features/session/presentation/pages/rpe_page.dart';
import 'package:pulse_coach/features/session/presentation/widgets/rpe_input_widget.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/usecases/award_session_points_use_case.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

const _args = RpeSubmitArgs(
  planId: 1,
  sessionIndex: 0,
  abandoned: false,
  armKey: 'mobility_low',
  sessionLogId: null,
);

Widget _wrap(GoRouter router) => MaterialApp.router(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  routerConfig: router,
);

GoRouter _router({void Function(Object? extra)? onSummaryExtra}) => GoRouter(
  initialLocation: AppRouter.sessionRpe,
  routes: [
    GoRoute(
      path: AppRouter.sessionRpe,
      builder: (_, _) => const RpePage(args: _args),
    ),
    GoRoute(
      path: AppRouter.sessionSummary,
      builder: (_, state) {
        onSummaryExtra?.call(state.extra);
        return const Scaffold(body: Text('Summary target'));
      },
    ),
    GoRoute(
      path: AppRouter.today,
      builder: (_, _) => const Scaffold(body: Text('Today target')),
    ),
  ],
);

void main() {
  AppDatabase? db;

  tearDown(() async {
    await db?.close();
    db = null;
    await getIt.reset();
  });

  testWidgets('9.1-PAGE-001: RpePage renders prompt and RPE input', (
    tester,
  ) async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    getIt.registerSingleton<RpeFeedbackDao>(db!.rpeFeedbackDao);
    getIt.registerSingleton<UpdateBanditReward>(UpdateBanditReward(db!));

    await tester.pumpWidget(_wrap(_router()));
    await tester.pump();

    expect(find.text("Com'è andata?"), findsOneWidget);
    expect(find.byType(RPEInputWidget), findsOneWidget);
    for (var value = 1; value <= 10; value++) {
      expect(find.text('$value'), findsOneWidget);
    }
  });

  testWidgets('9.2-PAGE-002: RpePage navigates to summary after submit', (
    tester,
  ) async {
    Object? summaryExtra;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    getIt.registerSingleton<RpeFeedbackDao>(db!.rpeFeedbackDao);
    getIt.registerSingleton<UpdateBanditReward>(UpdateBanditReward(db!));

    await tester.pumpWidget(
      _wrap(_router(onSummaryExtra: (extra) => summaryExtra = extra)),
    );
    await tester.tap(find.text('7'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Summary target'), findsOneWidget);
    expect(summaryExtra, isA<MiniSummaryArgs>());
    final args = summaryExtra! as MiniSummaryArgs;
    expect(args.rpeValue, 7);
    expect(args.sessionType, 'mobility');
    expect(args.durationMinutes, 0);
    expect(args.abandoned, isFalse);
    expect(args.planId, 1);
  });

  testWidgets(
    '12.3-AC2-001: RpePage calls sendEndMessage after RPE submission',
    (tester) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton<RpeFeedbackDao>(db!.rpeFeedbackDao);
      getIt.registerSingleton<UpdateBanditReward>(UpdateBanditReward(db!));

      var sendEndMessageCalled = false;

      final router = GoRouter(
        initialLocation: AppRouter.sessionRpe,
        routes: [
          GoRoute(
            path: AppRouter.sessionRpe,
            builder: (_, _) => RpePage(
              args: _args,
              sendEndMessageCallback: () async {
                sendEndMessageCalled = true;
              },
            ),
          ),
          GoRoute(
            path: AppRouter.sessionSummary,
            builder: (_, _) => const Scaffold(body: Text('Summary target')),
          ),
          GoRoute(
            path: AppRouter.today,
            builder: (_, _) => const Scaffold(body: Text('Today target')),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(router));
      await tester.tap(find.text('6'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(sendEndMessageCalled, isTrue);
      expect(find.text('Summary target'), findsOneWidget);
    },
  );

  testWidgets('9.1-PAGE-003: RpePage shows SnackBar on persistence error', (
    tester,
  ) async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    getIt.registerSingleton<RpeFeedbackDao>(_ThrowingRpeFeedbackDao());
    getIt.registerSingleton<UpdateBanditReward>(UpdateBanditReward(db!));

    await tester.pumpWidget(_wrap(_router()));
    await tester.tap(find.text('7'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(find.textContaining('db full'), findsOneWidget);
  });

  testWidgets(
    '21.1-PAGE-001: solo args, RPE submitted → AwardSessionPointsUseCase.call '
    'invoked with the resolved sessionLogId/armKey/durationMinutes',
    (tester) async {
      const soloArgs = RpeSubmitArgs(
        planId: 1,
        sessionIndex: 0,
        abandoned: false,
        armKey: 'mobility_low',
        sessionLogId: 5,
        durationMinutes: 20,
      );
      db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton<RpeFeedbackDao>(db!.rpeFeedbackDao);
      getIt.registerSingleton<UpdateBanditReward>(UpdateBanditReward(db!));
      final fakeUseCase = _FakeAwardSessionPointsUseCase();
      getIt.registerSingleton<AwardSessionPointsUseCase>(fakeUseCase);

      final router = GoRouter(
        initialLocation: AppRouter.sessionRpe,
        routes: [
          GoRoute(
            path: AppRouter.sessionRpe,
            builder: (_, _) => const RpePage(args: soloArgs),
          ),
          GoRoute(
            path: AppRouter.sessionSummary,
            builder: (_, _) => const Scaffold(body: Text('Summary target')),
          ),
          GoRoute(
            path: AppRouter.today,
            builder: (_, _) => const Scaffold(body: Text('Today target')),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(router));
      await tester.tap(find.text('7'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(fakeUseCase.calls, hasLength(1));
      expect(fakeUseCase.calls.single.sessionLogId, 5);
      expect(fakeUseCase.calls.single.armKey, 'mobility_low');
      expect(fakeUseCase.calls.single.durationMinutes, 20);
    },
  );

  testWidgets(
    '21.1-PAGE-002: shared args (planId: null) → AwardSessionPointsUseCase.'
    'call NEVER invoked (AC5)',
    (tester) async {
      const sharedArgs = RpeSubmitArgs(
        planId: null,
        sessionIndex: 0,
        abandoned: false,
        armKey: 'mobility_low',
        sessionLogId: 5,
        durationMinutes: 20,
      );
      db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton<RpeFeedbackDao>(db!.rpeFeedbackDao);
      getIt.registerSingleton<UpdateBanditReward>(UpdateBanditReward(db!));
      final fakeUseCase = _FakeAwardSessionPointsUseCase();
      getIt.registerSingleton<AwardSessionPointsUseCase>(fakeUseCase);

      final router = GoRouter(
        initialLocation: AppRouter.sessionRpe,
        routes: [
          GoRoute(
            path: AppRouter.sessionRpe,
            builder: (_, _) => const RpePage(args: sharedArgs),
          ),
          GoRoute(
            path: AppRouter.sessionSummary,
            builder: (_, _) => const Scaffold(body: Text('Summary target')),
          ),
          GoRoute(
            path: AppRouter.today,
            builder: (_, _) => const Scaffold(body: Text('Today target')),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(router));
      await tester.tap(find.text('7'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(fakeUseCase.calls, isEmpty);
    },
  );

  testWidgets(
    '21.1-PAGE-003: abandoned true → AwardSessionPointsUseCase.call NEVER '
    'invoked',
    (tester) async {
      const abandonedArgs = RpeSubmitArgs(
        planId: 1,
        sessionIndex: 0,
        abandoned: true,
        armKey: 'mobility_low',
        sessionLogId: 5,
        durationMinutes: 20,
      );
      db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton<RpeFeedbackDao>(db!.rpeFeedbackDao);
      getIt.registerSingleton<UpdateBanditReward>(UpdateBanditReward(db!));
      final fakeUseCase = _FakeAwardSessionPointsUseCase();
      getIt.registerSingleton<AwardSessionPointsUseCase>(fakeUseCase);

      final router = GoRouter(
        initialLocation: AppRouter.sessionRpe,
        routes: [
          GoRoute(
            path: AppRouter.sessionRpe,
            builder: (_, _) => const RpePage(args: abandonedArgs),
          ),
          GoRoute(
            path: AppRouter.sessionSummary,
            builder: (_, _) => const Scaffold(body: Text('Summary target')),
          ),
          GoRoute(
            path: AppRouter.today,
            builder: (_, _) => const Scaffold(body: Text('Today target')),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(router));
      await tester.tap(find.text('7'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(fakeUseCase.calls, isEmpty);
    },
  );

  testWidgets(
    '21.1-PAGE-004: sessionLogId resolves to null (degraded mode, no '
    'SessionLogsDao registered) → AwardSessionPointsUseCase.call NEVER '
    'invoked',
    (tester) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton<RpeFeedbackDao>(db!.rpeFeedbackDao);
      getIt.registerSingleton<UpdateBanditReward>(UpdateBanditReward(db!));
      final fakeUseCase = _FakeAwardSessionPointsUseCase();
      getIt.registerSingleton<AwardSessionPointsUseCase>(fakeUseCase);

      // _args has planId: 1, sessionLogId: null, and no SessionLogsDao is
      // registered, so RpeFeedbackCubit._resolveSessionLogId() resolves to
      // null (degraded mode) — nothing to key the award on.
      await tester.pumpWidget(_wrap(_router()));
      await tester.tap(find.text('7'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(fakeUseCase.calls, isEmpty);
    },
  );
}

class _ThrowingRpeFeedbackDao extends Fake implements RpeFeedbackDao {
  @override
  Future<int> insertFeedbackIdempotent(RpeFeedbackCompanion entry) {
    throw Exception('db full');
  }
}

class _AwardCall {
  final int sessionLogId;
  final String armKey;
  final int durationMinutes;

  _AwardCall({
    required this.sessionLogId,
    required this.armKey,
    required this.durationMinutes,
  });
}

class _FakeAwardSessionPointsUseCase implements AwardSessionPointsUseCase {
  final List<_AwardCall> calls = [];

  @override
  Future<void> call({
    required int sessionLogId,
    required String armKey,
    required int durationMinutes,
  }) async {
    calls.add(
      _AwardCall(
        sessionLogId: sessionLogId,
        armKey: armKey,
        durationMinutes: durationMinutes,
      ),
    );
  }
}
