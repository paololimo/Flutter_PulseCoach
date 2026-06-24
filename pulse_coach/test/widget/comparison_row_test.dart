// [18.4-WIDGET-001..003] ComparisonRow widget tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
import 'package:pulse_coach/features/social/comparison/presentation/widgets/comparison_row.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );

const _tOwnEntry = ProgressComparisonEntry(
  displayHandle: 'paolol',
  sessionsThisWeek: 2,
  minutesThisWeek: 35,
  isOwn: true,
);

const _tFriendEntry = ProgressComparisonEntry(
  displayHandle: 'alice',
  sessionsThisWeek: 1,
  minutesThisWeek: 20,
);

void main() {
  group('ComparisonRow', () {
    testWidgets(
      '18.4-WIDGET-001: own entry — highlighted (surfaceContainerHigh), shows handle + sessions/3 + minutes',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const ComparisonRow(entry: _tOwnEntry)),
        );

        // Handle shown with @ prefix
        expect(find.text('@paolol'), findsOneWidget);

        // Sessions/target shown (Italian: "2/3 sessioni")
        expect(find.textContaining('2/3'), findsOneWidget);

        // Minutes shown (Italian: "35 min")
        expect(find.textContaining('35'), findsOneWidget);

        // Card color is surfaceContainerHigh for own entry
        final card = tester.widget<Card>(find.byType(Card));
        final theme = Theme.of(
          tester.element(find.byType(ComparisonRow)),
        );
        expect(card.color, theme.colorScheme.surfaceContainerHigh);
      },
    );

    testWidgets(
      '18.4-WIDGET-002: friend entry — standard card color, shows handle + sessions + minutes',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const ComparisonRow(entry: _tFriendEntry)),
        );

        expect(find.text('@alice'), findsOneWidget);
        expect(find.textContaining('1/3'), findsOneWidget);
        expect(find.textContaining('20'), findsOneWidget);

        // Card color is surfaceContainer for friend (not surfaceContainerHigh)
        final card = tester.widget<Card>(find.byType(Card));
        final theme = Theme.of(
          tester.element(find.byType(ComparisonRow)),
        );
        expect(card.color, theme.colorScheme.surfaceContainer);
      },
    );

    testWidgets(
      '18.4-WIDGET-003: no RPE, HR, or behavioral state rendered — verify absent from widget tree',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const ComparisonRow(entry: _tOwnEntry)),
        );

        // No RPE-related text
        expect(find.textContaining('RPE'), findsNothing);
        expect(find.textContaining('rpe'), findsNothing);

        // No HR-related text or icons
        expect(find.textContaining('bpm'), findsNothing);
        expect(find.textContaining('HR'), findsNothing);
        expect(find.byIcon(Icons.favorite), findsNothing);
        expect(find.byIcon(Icons.monitor_heart), findsNothing);

        // No behavioral state text
        expect(find.textContaining('Caution'), findsNothing);
        expect(find.textContaining('AtRisk'), findsNothing);
        expect(find.textContaining('stato'), findsNothing);
      },
    );
  });
}
