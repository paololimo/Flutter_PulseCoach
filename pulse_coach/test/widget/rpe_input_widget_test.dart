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

    // Regression for the on-device overflow: on a 360dp-wide phone a single
    // row of 10 ×48dp targets (516dp) overflowed by ~204dp, clipping 8/9/10
    // off-screen. The default flutter_test surface (800dp) is wider than any
    // real phone, which is why this slipped past WIDGET-001..004.
    testWidgets(
      '9.1-WIDGET-005: no overflow and all 10 targets stay on-screen at 360dp',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(RPEInputWidget(onRpeSelected: (_) {})),
        );

        // No RenderFlex overflow was logged during layout/paint.
        expect(tester.takeException(), isNull);

        final screenWidth = tester.view.physicalSize.width;
        for (var value = 1; value <= 10; value++) {
          expect(find.text('$value'), findsOneWidget);
          final rect = tester.getRect(find.text('$value'));
          expect(
            rect.right,
            lessThanOrEqualTo(screenWidth),
            reason: 'RPE target $value is clipped off the right edge',
          );
          expect(rect.left, greaterThanOrEqualTo(0));
        }

        // Every hit target still honours the 48dp accessibility floor.
        final hitSize = tester.getSize(
          find
              .ancestor(of: find.text('7'), matching: find.byType(SizedBox))
              .first,
        );
        expect(hitSize.width, greaterThanOrEqualTo(48));
        expect(hitSize.height, greaterThanOrEqualTo(48));
      },
    );
  });
}
