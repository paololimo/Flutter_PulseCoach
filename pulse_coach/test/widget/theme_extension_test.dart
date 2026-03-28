import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

void main() {
  group('PulseCoachTheme extension', () {
    testWidgets('dark theme extension tokens are correct', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(builder: (context) {
          final theme = Theme.of(context).extension<PulseCoachTheme>()!;
          expect(theme.primaryColor, const Color(0xFF7DD3C0));
          expect(theme.surface, const Color(0xFF0F1119));
          expect(theme.onSurface, const Color(0xFFE2E4EA));
          return const SizedBox.shrink();
        }),
      ));
    });

    testWidgets('extension is not null in dark theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(builder: (context) {
          expect(Theme.of(context).extension<PulseCoachTheme>(), isNotNull);
          return const SizedBox.shrink();
        }),
      ));
    });

    testWidgets('light theme extension is not null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(builder: (context) {
          expect(Theme.of(context).extension<PulseCoachTheme>(), isNotNull);
          return const SizedBox.shrink();
        }),
      ));
    });

    testWidgets('light theme extension tokens are correct', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(builder: (context) {
          final theme = Theme.of(context).extension<PulseCoachTheme>()!;
          expect(theme.surface, const Color(0xFFF8FFFE));
          expect(theme.surfaceContainer, const Color(0xFFEEF6F4));
          expect(theme.surfaceContainerHigh, const Color(0xFFE1F0ED));
          expect(theme.primaryColor, const Color(0xFF7DD3C0));
          expect(theme.secondary, const Color(0xFFA78BDA));
          expect(theme.tertiary, const Color(0xFFE8C87A));
          expect(theme.onSurface, const Color(0xFF1A1C1E));
          expect(theme.onSurfaceVariant, const Color(0xFF42474E));
          expect(theme.error, const Color(0xFFBA1A1A));
          return const SizedBox.shrink();
        }),
      ));
    });

    test('PulseCoachTheme.dark has all 9 color tokens', () {
      const theme = PulseCoachTheme.dark;
      expect(theme.surface, const Color(0xFF0F1119));
      expect(theme.surfaceContainer, const Color(0xFF171B26));
      expect(theme.surfaceContainerHigh, const Color(0xFF1E2333));
      expect(theme.primaryColor, const Color(0xFF7DD3C0));
      expect(theme.secondary, const Color(0xFFA78BDA));
      expect(theme.tertiary, const Color(0xFFE8C87A));
      expect(theme.onSurface, const Color(0xFFE2E4EA));
      expect(theme.onSurfaceVariant, const Color(0xFF9498A6));
      expect(theme.error, const Color(0xFFF28B82));
    });

    test('copyWith returns updated instance', () {
      const theme = PulseCoachTheme.dark;
      final updated = theme.copyWith(primaryColor: const Color(0xFFFFFFFF));
      expect(updated.primaryColor, const Color(0xFFFFFFFF));
      expect(updated.surface, theme.surface);
    });

    test('lerp returns interpolated values', () {
      const a = PulseCoachTheme.dark;
      const b = PulseCoachTheme.light;
      final atZero = a.lerp(b, 0.0);
      expect(atZero.primaryColor, a.primaryColor);
      expect(atZero.surface, a.surface);
      final atOne = a.lerp(b, 1.0);
      expect(atOne.primaryColor, b.primaryColor);
      expect(atOne.surface, b.surface);
      final atHalf = a.lerp(b, 0.5);
      expect(atHalf.surface, isNot(a.surface));
      expect(atHalf.surface, isNot(b.surface));
    });
  });
}
