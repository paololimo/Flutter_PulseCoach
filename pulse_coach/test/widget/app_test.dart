import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(const PulseCoachApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
