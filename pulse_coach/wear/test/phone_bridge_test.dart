import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach_wear/communication/phone_bridge.dart';

void main() {
  test('parses active session messages', () async {
    final controller = StreamController<Map<String, dynamic>>();
    final bridge = PhoneBridge(client: _FakePhoneMessagingClient(controller));

    final states = <SessionWearState>[];
    final subscription = bridge.states.listen(states.add);

    controller.add({
      '_path': PhoneBridge.sessionPath,
      'step': 'Squat',
      'secs': 42,
      'hr': 128,
    });
    await pumpEventQueue();

    expect(states.single.stepName, 'Squat');
    expect(states.single.secondsRemaining, 42);
    expect(states.single.heartRate, 128);
    expect(states.single.isEnded, isFalse);

    await subscription.cancel();
    await bridge.dispose();
    await controller.close();
  });

  test('ignores unknown paths and malformed payloads without crashing', () async {
    final controller = StreamController<Map<String, dynamic>>();
    final bridge = PhoneBridge(client: _FakePhoneMessagingClient(controller));

    final states = <SessionWearState>[];
    final subscription = bridge.states.listen(states.add);

    controller.add({'_path': '/unknown', 'step': 'Ignored', 'secs': 1});
    controller.add({'_path': PhoneBridge.sessionPath, 'step': 4, 'secs': 'bad'});
    await pumpEventQueue();

    expect(states, isEmpty);

    await subscription.cancel();
    await bridge.dispose();
    await controller.close();
  });

  test('emits ended state for session end messages', () async {
    final controller = StreamController<Map<String, dynamic>>();
    final bridge = PhoneBridge(client: _FakePhoneMessagingClient(controller));

    final states = <SessionWearState>[];
    final subscription = bridge.states.listen(states.add);

    controller.add({'_path': PhoneBridge.endPath, 'done': true});
    await pumpEventQueue();

    expect(states.single.isEnded, isTrue);

    await subscription.cancel();
    await bridge.dispose();
    await controller.close();
  });
}

class _FakePhoneMessagingClient implements PhoneMessagingClient {
  _FakePhoneMessagingClient(this._controller);

  final StreamController<Map<String, dynamic>> _controller;

  @override
  Stream<Map<String, dynamic>> get messageStream => _controller.stream;
}
