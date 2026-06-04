import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

const _session = PlannedSession(
  sessionType: 'cardio',
  intensity: 3,
  durationMinutes: 1,
  isIndoor: true,
);

GoRouter _router({void Function(Object? extra)? onRpeExtra}) => GoRouter(
  initialLocation: AppRouter.sessionActive,
  routes: [
    GoRoute(
      path: AppRouter.sessionActive,
      builder: (_, _) => const InSessionPage(session: _session),
    ),
    GoRoute(
      path: AppRouter.sessionRpe,
      builder: (_, state) {
        onRpeExtra?.call(state.extra);
        return const Scaffold(body: Text('RPE target'));
      },
    ),
  ],
);

Widget _wrap(GoRouter router) => MaterialApp.router(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  routerConfig: router,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
);

Future<void> _pumpPastCountdown(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3400));
  await tester.pump();
}

Future<void> _pumpToNaturalCompletion(WidgetTester tester) async {
  // A 1-minute PlannedSession still expands to three 60-second phases. Each
  // phase spends one extra tick at 00:00 before advancing.
  await tester.pump(const Duration(seconds: 183));
  await tester.pump();
}

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  group('InSessionPage abandon flow', () {
    testWidgets('8.5-VIEW-001: tapping Abbandona shows confirmation sheet', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_router()));
      await _pumpPastCountdown(tester);

      await tester.tap(find.text('Abbandona'));
      await tester.pumpAndSettle();

      expect(find.text('Vuoi abbandonare la sessione?'), findsOneWidget);
      expect(
        find.text('Il progresso parziale verrà registrato.'),
        findsOneWidget,
      );
      expect(find.text('Continua'), findsOneWidget);
      expect(find.text('Abbandona sessione'), findsOneWidget);
    });

    testWidgets('8.5-VIEW-002: Continua dismisses sheet and stays in session', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_router()));
      await _pumpPastCountdown(tester);

      await tester.tap(find.text('Abbandona'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continua'));
      await tester.pumpAndSettle();

      expect(find.text('Vuoi abbandonare la sessione?'), findsNothing);
      expect(find.text('RPE target'), findsNothing);
      expect(find.text('Abbandona'), findsOneWidget);
    });

    testWidgets(
      '8.5-VIEW-003: confirming abandonment routes to RPE through state listener',
      (tester) async {
        Object? rpeExtra;
        await tester.pumpWidget(
          _wrap(_router(onRpeExtra: (extra) => rpeExtra = extra)),
        );
        await _pumpPastCountdown(tester);

        await tester.tap(find.text('Abbandona'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abbandona sessione'));
        await tester.pumpAndSettle();

        expect(find.text('RPE target'), findsOneWidget);
        expect(rpeExtra, isA<RpeSubmitArgs>());
        final args = rpeExtra! as RpeSubmitArgs;
        expect(args.sessionIndex, 0);
        expect(args.abandoned, isTrue);
        expect(args.durationMinutes, 1);
        // P6 fix: intensity 3 falls in the low band (1..3) per
        // safety_constraints.dart, mirroring ContextualBandit._intensityValue.
        expect(args.armKey, 'cardio_low');

        await tester.pump(const Duration(seconds: 60));
      },
    );

    testWidgets(
      '8.2-VIEW-004: natural completion routes to RPE through state listener',
      (tester) async {
        Object? rpeExtra;
        await tester.pumpWidget(
          _wrap(_router(onRpeExtra: (extra) => rpeExtra = extra)),
        );
        await _pumpPastCountdown(tester);

        await _pumpToNaturalCompletion(tester);

        expect(find.text('RPE target'), findsOneWidget);
        expect(rpeExtra, isA<RpeSubmitArgs>());
        final args = rpeExtra! as RpeSubmitArgs;
        expect(args.sessionIndex, 0);
        expect(args.abandoned, isFalse);
        expect(args.durationMinutes, 1);
        expect(args.armKey, 'cardio_low');

        await tester.pump(const Duration(seconds: 60));
      },
    );
  });
}
