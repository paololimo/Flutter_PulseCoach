import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
import 'package:pulse_coach/features/session/presentation/widgets/countdown_overlay.dart';
import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.darkTheme,
    home: child,
  ),
);

void main() {
  group('CountdownOverlay', () {
    testWidgets('8.1-WIDGET-001: background color matches primary color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(CountdownOverlay(onCountdownComplete: () {})),
      );

      final scaffoldFinder = find.descendant(
        of: find.byType(CountdownOverlay),
        matching: find.byType(Scaffold),
      );
      expect(scaffoldFinder, findsOneWidget);
      expect(
        tester.widget<Scaffold>(scaffoldFinder).backgroundColor,
        equals(PulseCoachTheme.dark.primaryColor),
      );
    });

    testWidgets(
      '8.1-WIDGET-002: initial display shows 3 using countdown text style',
      (tester) async {
        await tester.pumpWidget(
          _wrap(CountdownOverlay(onCountdownComplete: () {})),
        );

        final numberFinder = find.descendant(
          of: find.byType(CountdownOverlay),
          matching: find.text('3'),
        );
        expect(numberFinder, findsOneWidget);
        final text = tester.widget<Text>(numberFinder);
        expect(text.style?.fontFamily, AppTextStyles.countdown.fontFamily);
        expect(text.style?.fontSize, 72);
      },
    );

    testWidgets(
      '8.1-WIDGET-003: onCountdownComplete fires after full sequence',
      (tester) async {
        var completed = false;
        await tester.pumpWidget(
          _wrap(CountdownOverlay(onCountdownComplete: () => completed = true)),
        );

        await tester.pump();
        for (var i = 0; i < 3; i++) {
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 700));
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(completed, isTrue);
      },
    );

    testWidgets('8.1-WIDGET-004: sessionTitle appears below countdown number', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CountdownOverlay(
            sessionTitle: 'Mobilità',
            onCountdownComplete: () {},
          ),
        ),
      );

      expect(find.text('Mobilità'), findsOneWidget);
    });

    testWidgets(
      '8.1-WIDGET-005: Reduce Motion completes without animated transition',
      (tester) async {
        var completed = false;
        await tester.pumpWidget(
          _wrap(
            CountdownOverlay(onCountdownComplete: () => completed = true),
            disableAnimations: true,
          ),
        );

        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 1000));
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(completed, isTrue);
      },
    );

    testWidgets(
      '8.1-WIDGET-006: InSessionPage shows CountdownOverlay initially',
      (tester) async {
        await tester.pumpWidget(_wrap(const InSessionPage()));
        await tester.pump();

        expect(find.byType(CountdownOverlay), findsOneWidget);
      },
    );

    testWidgets(
      '8.1-WIDGET-007: InSessionPage shows InSessionView after countdown',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const InSessionPage(), disableAnimations: true),
        );
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 1000));
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(find.byType(CountdownOverlay), findsNothing);
        expect(find.byType(InSessionView), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
