import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/completion_rate_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/minutes_per_week_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/rpe_trend_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/session_type_breakdown_chart.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

import '../../helpers/viewport_helper.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SizedBox(height: 200, child: child)),
);

void main() {
  group('MinutesPerWeekChart - 360dp', () {
    testWidgets('10.2-WIDGET-001: renders without overflow at 360dp', (
      tester,
    ) async {
      set360dpSurface(tester);
      await tester.pumpWidget(
        _wrap(
          const MinutesPerWeekChart(
            minutesPerWeek: [
              WeeklyMinutes(weekLabel: '26/05', totalMinutes: 45),
              WeeklyMinutes(weekLabel: '02/06', totalMinutes: 60),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('CompletionRateChart - 360dp', () {
    testWidgets('10.2-WIDGET-002: renders without overflow at 360dp', (
      tester,
    ) async {
      set360dpSurface(tester);
      await tester.pumpWidget(
        _wrap(const CompletionRateChart(completedCount: 5, abandonedCount: 2)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('10.2-WIDGET-003: shows 71% for 5 completed / 2 abandoned', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const CompletionRateChart(completedCount: 5, abandonedCount: 2)),
      );
      await tester.pumpAndSettle();

      expect(find.text('71%'), findsOneWidget);
    });
  });

  group('RpeTrendChart - 360dp', () {
    testWidgets('10.2-WIDGET-004: renders without overflow at 360dp', (
      tester,
    ) async {
      set360dpSurface(tester);
      await tester.pumpWidget(
        _wrap(
          RpeTrendChart(
            rpeTrend: [
              RpeDataPoint(completedAt: DateTime(2026, 5, 20), rpeValue: 6),
              RpeDataPoint(completedAt: DateTime(2026, 5, 22), rpeValue: 7),
              RpeDataPoint(completedAt: DateTime(2026, 5, 24), rpeValue: 5),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('SessionTypeBreakdownChart - 360dp', () {
    testWidgets('10.2-WIDGET-005: renders without overflow at 360dp', (
      tester,
    ) async {
      set360dpSurface(tester);
      await tester.pumpWidget(
        _wrap(
          const SessionTypeBreakdownChart(
            sessionTypeCounts: {'cardio': 3, 'mobility': 2, 'breathing': 1},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
