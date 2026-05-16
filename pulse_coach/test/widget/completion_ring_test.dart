import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/today/presentation/widgets/completion_ring.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: const MediaQueryData().copyWith(disableAnimations: disableAnimations),
  child: MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.darkTheme,
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('CompletionRing', () {
    testWidgets('7.4-RING-001: displays 0/3 fraction text', (tester) async {
      await tester.pumpWidget(
        _wrap(const CompletionRing(completed: 0, total: 3)),
      );

      expect(find.text('0/3'), findsOneWidget);
    });

    testWidgets('7.4-RING-002: displays 1/3 fraction text', (tester) async {
      await tester.pumpWidget(
        _wrap(const CompletionRing(completed: 1, total: 3)),
      );

      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('7.4-RING-003: displays 3/3 fraction text', (tester) async {
      await tester.pumpWidget(
        _wrap(const CompletionRing(completed: 3, total: 3)),
      );

      expect(find.text('3/3'), findsOneWidget);
    });

    testWidgets('7.4-RING-004: reduce motion updates without settling delay', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CompletionRing(completed: 0, total: 3),
          disableAnimations: true,
        ),
      );

      await tester.pumpWidget(
        _wrap(
          const CompletionRing(completed: 1, total: 3),
          disableAnimations: true,
        ),
      );
      // Single frame, no settle: arc must already reflect the new value
      // because Reduce Motion bypasses the arc animation entirely.
      await tester.pump();

      expect(find.text('1/3'), findsOneWidget);
      expect(
        tester.binding.transientCallbackCount,
        equals(0),
        reason: 'no animation should be in flight when Reduce Motion is on',
      );
    });

    testWidgets('7.4-RING-005: exposes accessibility progress label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const CompletionRing(completed: 1, total: 3)),
      );

      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      expect(
        semantics.any(
          (widget) =>
              widget.properties.label?.contains('Progressione giornaliera') ??
              false,
        ),
        isTrue,
      );
    });

    testWidgets('7.4-RING-006: renders when total is zero', (tester) async {
      await tester.pumpWidget(
        _wrap(const CompletionRing(completed: 0, total: 0)),
      );

      expect(find.text('0/0'), findsOneWidget);
    });
  });
}
