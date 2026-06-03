import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach_wear/communication/phone_bridge.dart';
import 'package:pulse_coach_wear/session_display_page.dart';

void main() {
  testWidgets('renders step name, formatted timer, and HR label', (tester) async {
    final controller = StreamController<SessionWearState>();

    await tester.pumpWidget(
      MaterialApp(
        home: SessionDisplayPage(
          states: controller.stream,
          initialState: const SessionWearState.active(
            stepName: 'Squat',
            secondsRemaining: 65,
            heartRate: 128,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('01:05'), findsOneWidget);
    expect(find.text('♥ 128 bpm'), findsOneWidget);

    await controller.close();
  });

  testWidgets('notifies caller when ended state is received', (tester) async {
    final controller = StreamController<SessionWearState>();
    var ended = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SessionDisplayPage(
          states: controller.stream,
          onSessionEnded: () => ended = true,
        ),
      ),
    );

    controller.add(const SessionWearState.ended());
    await tester.pump();
    await tester.pump();

    expect(ended, isTrue);

    await controller.close();
  });
}
