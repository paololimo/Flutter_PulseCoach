import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/today/presentation/widgets/active_days_card.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  group('ActiveDaysCard', () {
    testWidgets(
      '22.3-CARD-001: count=0 renders a single semantics node with the '
      'zero-count caption',
      (tester) async {
        await tester.pumpWidget(_wrap(const ActiveDaysCard(count: 0)));

        expect(
          find.bySemanticsLabel('0 giorni attivi negli ultimi 30'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '22.3-CARD-002: count=17 shows the count caption and no streak/flame '
      'iconography',
      (tester) async {
        await tester.pumpWidget(_wrap(const ActiveDaysCard(count: 17)));

        expect(
          find.bySemanticsLabel('17 giorni attivi negli ultimi 30'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.local_fire_department), findsNothing);
        expect(find.byIcon(Icons.whatshot), findsNothing);
      },
    );

    testWidgets(
      '22.3-CARD-003: inner text is not independently reachable as a '
      'separate semantics node',
      (tester) async {
        await tester.pumpWidget(_wrap(const ActiveDaysCard(count: 17)));

        expect(find.bySemanticsLabel('17'), findsNothing);
        expect(
          find.bySemanticsLabel('giorni attivi negli ultimi 30'),
          findsNothing,
        );
      },
    );
  });
}
