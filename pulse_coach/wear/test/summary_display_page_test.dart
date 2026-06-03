import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach_wear/communication/phone_bridge.dart';
import 'package:pulse_coach_wear/summary_display_page.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: ThemeData.dark(useMaterial3: true), home: child);

void main() {
  testWidgets('renders capitalized session type, duration, and RPE prompt', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryDisplayPage(
          initialState: SessionWearState.summary(
            sessionType: 'mobility',
            durationMinutes: 20,
            abandoned: false,
          ),
        ),
      ),
    );

    expect(find.text('Mobility'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);
    expect(find.text('Valuta RPE\nsul telefono'), findsOneWidget);
  });

  testWidgets('renders abandoned label for abandoned summary', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryDisplayPage(
          initialState: SessionWearState.summary(
            sessionType: 'cardio',
            durationMinutes: 15,
            abandoned: true,
          ),
        ),
      ),
    );

    expect(find.text('(abbandonata)'), findsOneWidget);
  });
}
