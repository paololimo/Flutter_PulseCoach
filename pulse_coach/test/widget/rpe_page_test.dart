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
import 'package:pulse_coach/features/session/presentation/pages/rpe_page.dart';
import 'package:pulse_coach/features/session/presentation/widgets/rpe_input_widget.dart';
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

  testWidgets('9.1-PAGE-003: RpePage shows SnackBar on persistence error', (
    tester,
  ) async {
    getIt.registerSingleton<RpeFeedbackDao>(_ThrowingRpeFeedbackDao());

    await tester.pumpWidget(_wrap(_router()));
    await tester.tap(find.text('7'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(find.textContaining('db full'), findsOneWidget);
  });
}

class _ThrowingRpeFeedbackDao extends Fake implements RpeFeedbackDao {
  @override
  Future<int> insertFeedbackIdempotent(RpeFeedbackCompanion entry) {
    throw Exception('db full');
  }
}
