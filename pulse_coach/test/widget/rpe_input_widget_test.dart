import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/session/presentation/widgets/rpe_input_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('RPEInputWidget', () {
    testWidgets('9.1-WIDGET-001: renders 10 buttons labeled 1-10', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(RPEInputWidget(onRpeSelected: (_) {})));

      for (var value = 1; value <= 10; value++) {
        expect(find.text('$value'), findsOneWidget);
      }
    });

    testWidgets('9.1-WIDGET-002: tapping button emits selected value', (
      tester,
    ) async {
      int? selected;
      await tester.pumpWidget(
        _wrap(RPEInputWidget(onRpeSelected: (value) => selected = value)),
      );

      await tester.tap(find.text('7'));

      expect(selected, 7);
    });

    testWidgets('9.1-WIDGET-003: selected state disables later taps', (
      tester,
    ) async {
      var callCount = 0;
      await tester.pumpWidget(
        _wrap(
          RPEInputWidget(selectedRpe: 5, onRpeSelected: (_) => callCount++),
        ),
      );

      await tester.tap(find.text('3'));
      await tester.pump();

      expect(callCount, 0);
    });

    testWidgets('9.1-WIDGET-004: touch wrapper is at least 48dp', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(RPEInputWidget(onRpeSelected: (_) {})));

      final buttonSize = tester.getSize(
        find
            .ancestor(of: find.text('7'), matching: find.byType(SizedBox))
            .first,
      );

      expect(buttonSize.width, greaterThanOrEqualTo(48));
      expect(buttonSize.height, greaterThanOrEqualTo(48));
    });
  });
}
