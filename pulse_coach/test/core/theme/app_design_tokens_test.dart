// [P2] Design token constant tests: AppSpacing, AppShapes, AppTextStyles
// AppTextStyles uses GoogleFonts so the widget binding must be initialized.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulse_coach/core/theme/app_shapes.dart';
import 'package:pulse_coach/core/theme/app_spacing.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Disable runtime font fetching in tests (avoids network calls + errors).
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  group('AppSpacing', () {
    test('[P2] 1.6-UNIT-001: spacing values match spec', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.xxl, 48.0);
    });

    test('[P2] spacing scale is strictly ascending', () {
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
      expect(AppSpacing.xl, lessThan(AppSpacing.xxl));
    });
  });

  group('AppShapes', () {
    test('[P2] 1.6-UNIT-002: radius scalar values match spec', () {
      expect(AppShapes.cardRadius, 16.0);
      expect(AppShapes.buttonRadius, 12.0);
      expect(AppShapes.inputRadius, 8.0);
    });

    test('[P2] cardBorderRadius uses card radius', () {
      expect(
        AppShapes.cardBorderRadius,
        const BorderRadius.all(Radius.circular(16.0)),
      );
    });

    test('[P2] buttonBorderRadius uses button radius', () {
      expect(
        AppShapes.buttonBorderRadius,
        const BorderRadius.all(Radius.circular(12.0)),
      );
    });

    test('[P2] inputBorderRadius uses input radius', () {
      expect(
        AppShapes.inputBorderRadius,
        const BorderRadius.all(Radius.circular(8.0)),
      );
    });
  });

  // AppTextStyles uses GoogleFonts which triggers async font loading.
  // Use testWidgets + pump() to drain the async queue and avoid test leaks.
  group('AppTextStyles', () {
    testWidgets(
      '[P2] 1.6-UNIT-003: caption meets 11sp minimum constraint',
      (tester) async {
        expect(AppTextStyles.caption.fontSize, greaterThanOrEqualTo(11.0));
        await tester.pump();
      },
    );

    testWidgets(
      '[P2] body text size hierarchy is strictly descending',
      (tester) async {
        expect(AppTextStyles.display.fontSize, greaterThan(AppTextStyles.h1.fontSize!));
        expect(AppTextStyles.h1.fontSize, greaterThan(AppTextStyles.h2.fontSize!));
        expect(AppTextStyles.h2.fontSize, greaterThan(AppTextStyles.h3.fontSize!));
        expect(AppTextStyles.h3.fontSize, greaterThan(AppTextStyles.body.fontSize!));
        expect(AppTextStyles.body.fontSize, greaterThan(AppTextStyles.bodySmall.fontSize!));
        expect(AppTextStyles.bodySmall.fontSize, greaterThan(AppTextStyles.caption.fontSize!));
        await tester.pump();
      },
    );

    testWidgets(
      '[P2] mono font size hierarchy: countdown > timerDisplay > timerSecondary > rpeNumbers',
      (tester) async {
        expect(AppTextStyles.countdown.fontSize, greaterThan(AppTextStyles.timerDisplay.fontSize!));
        expect(AppTextStyles.timerDisplay.fontSize, greaterThan(AppTextStyles.timerSecondary.fontSize!));
        expect(AppTextStyles.timerSecondary.fontSize, greaterThan(AppTextStyles.rpeNumbers.fontSize!));
        await tester.pump();
      },
    );

    testWidgets(
      '[P2] all text styles have non-null fontSize',
      (tester) async {
        expect(AppTextStyles.display.fontSize, isNotNull);
        expect(AppTextStyles.h1.fontSize, isNotNull);
        expect(AppTextStyles.h2.fontSize, isNotNull);
        expect(AppTextStyles.h3.fontSize, isNotNull);
        expect(AppTextStyles.body.fontSize, isNotNull);
        expect(AppTextStyles.bodySmall.fontSize, isNotNull);
        expect(AppTextStyles.caption.fontSize, isNotNull);
        expect(AppTextStyles.timerDisplay.fontSize, isNotNull);
        expect(AppTextStyles.countdown.fontSize, isNotNull);
        expect(AppTextStyles.rpeNumbers.fontSize, isNotNull);
        expect(AppTextStyles.timerSecondary.fontSize, isNotNull);
        await tester.pump();
      },
    );

    testWidgets(
      '[P2] all text styles have non-null fontFamily',
      (tester) async {
        expect(AppTextStyles.display.fontFamily, isNotNull);
        expect(AppTextStyles.h1.fontFamily, isNotNull);
        expect(AppTextStyles.h2.fontFamily, isNotNull);
        expect(AppTextStyles.h3.fontFamily, isNotNull);
        expect(AppTextStyles.body.fontFamily, isNotNull);
        expect(AppTextStyles.bodySmall.fontFamily, isNotNull);
        expect(AppTextStyles.caption.fontFamily, isNotNull);
        expect(AppTextStyles.timerDisplay.fontFamily, isNotNull);
        expect(AppTextStyles.countdown.fontFamily, isNotNull);
        expect(AppTextStyles.rpeNumbers.fontFamily, isNotNull);
        expect(AppTextStyles.timerSecondary.fontFamily, isNotNull);
        await tester.pump();
      },
    );
  });
}
