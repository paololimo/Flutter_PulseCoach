import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach_wear/communication/phone_bridge.dart';
import 'package:pulse_coach_wear/main.dart';
import 'package:pulse_coach_wear/session_display_page.dart';
import 'package:pulse_coach_wear/summary_display_page.dart';
import 'package:wear_plus/wear_plus.dart';

void main() {
  testWidgets('does not revert to SessionDisplayPage after summary state', (
    tester,
  ) async {
    final messageController = StreamController<Map<String, dynamic>>();
    final bridge = PhoneBridge(
      client: _FakePhoneMessagingClient(messageController),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WearRoot(
          bridge: bridge,
          isAmbient: false,
          shape: WearShape.square,
        ),
      ),
    );

    messageController.add({
      '_path': PhoneBridge.sessionPath,
      'step': 'Squat',
      'secs': 30,
    });
    await _pumpBridgeMessage(tester);
    expect(find.byType(SessionDisplayPage), findsOneWidget);

    messageController.add({
      '_path': PhoneBridge.summaryPath,
      'sessionType': 'cardio',
      'durationMinutes': 15,
      'abandoned': false,
    });
    await _pumpBridgeMessage(tester);
    expect(find.byType(SummaryDisplayPage), findsOneWidget);

    messageController.add({
      '_path': PhoneBridge.sessionPath,
      'step': 'Late',
      'secs': 5,
    });
    await _pumpBridgeMessage(tester);

    expect(find.byType(SummaryDisplayPage), findsOneWidget);
    expect(find.byType(SessionDisplayPage), findsNothing);

    await messageController.close();
  });

  testWidgets('returns to idle after end message clears summary', (
    tester,
  ) async {
    final messageController = StreamController<Map<String, dynamic>>();
    final bridge = PhoneBridge(
      client: _FakePhoneMessagingClient(messageController),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WearRoot(
          bridge: bridge,
          isAmbient: false,
          shape: WearShape.square,
        ),
      ),
    );

    messageController.add({
      '_path': PhoneBridge.sessionPath,
      'step': 'Squat',
      'secs': 30,
    });
    await _pumpBridgeMessage(tester);
    messageController.add({
      '_path': PhoneBridge.summaryPath,
      'sessionType': 'cardio',
      'durationMinutes': 15,
      'abandoned': false,
    });
    await _pumpBridgeMessage(tester);
    messageController.add({'_path': PhoneBridge.endPath, 'done': true});
    await _pumpBridgeMessage(tester);

    expect(find.byType(PulseCoachWearHome), findsOneWidget);
    expect(find.byType(SummaryDisplayPage), findsNothing);

    await messageController.close();
  });

  testWidgets('shows new session after end', (tester) async {
    final messageController = StreamController<Map<String, dynamic>>();
    final bridge = PhoneBridge(
      client: _FakePhoneMessagingClient(messageController),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WearRoot(
          bridge: bridge,
          isAmbient: false,
          shape: WearShape.square,
        ),
      ),
    );

    messageController.add({
      '_path': PhoneBridge.sessionPath,
      'step': 'Squat',
      'secs': 30,
    });
    await _pumpBridgeMessage(tester);
    messageController.add({'_path': PhoneBridge.endPath, 'done': true});
    await _pumpBridgeMessage(tester);
    messageController.add({
      '_path': PhoneBridge.sessionPath,
      'step': 'Run',
      'secs': 45,
    });
    await _pumpBridgeMessage(tester);

    expect(find.byType(SessionDisplayPage), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);

    await messageController.close();
  });
}

Future<void> _pumpBridgeMessage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

class _FakePhoneMessagingClient implements PhoneMessagingClient {
  _FakePhoneMessagingClient(this._controller);

  final StreamController<Map<String, dynamic>> _controller;

  @override
  Stream<Map<String, dynamic>> get messageStream => _controller.stream;

  @override
  Stream<Map<String, dynamic>> get contextStream => const Stream.empty();

  @override
  Future<List<Map<String, dynamic>>> get receivedApplicationContexts async =>
      const [];
}
