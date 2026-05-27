import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/weekly_goal_indicator.dart';

import '../../helpers/viewport_helper.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('WeeklyGoalIndicator', () {
    testWidgets('10.3-WIDGET-001: renders without overflow at 360dp', (
      tester,
    ) async {
      set360dpSurface(tester);
      await tester.pumpWidget(
        _wrap(const WeeklyGoalIndicator(completedThisWeek: 1, weeklyTarget: 3)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('10.3-WIDGET-002: shows correct text for 1 of 3', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const WeeklyGoalIndicator(completedThisWeek: 1, weeklyTarget: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 di 3 sessioni questa settimana'), findsOneWidget);
    });

    testWidgets('10.3-WIDGET-003: shows encouraging text when 0 sessions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const WeeklyGoalIndicator(completedThisWeek: 0, weeklyTarget: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 di 3 sessioni questa settimana'), findsOneWidget);
      expect(
        find.text('Inizia la tua prima sessione questa settimana!'),
        findsOneWidget,
      );
    });

    testWidgets('10.3-WIDGET-004: shows completion text when target met', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const WeeklyGoalIndicator(completedThisWeek: 3, weeklyTarget: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 di 3 sessioni questa settimana'), findsOneWidget);
      expect(find.text('Obiettivo raggiunto!'), findsOneWidget);
    });

    testWidgets('10.3-WIDGET-005: LinearProgressIndicator is present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const WeeklyGoalIndicator(completedThisWeek: 2, weeklyTarget: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
