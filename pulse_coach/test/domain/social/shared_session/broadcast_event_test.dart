// [19.1-DOMAIN-001..005] BroadcastEvent and PresenceState pure Dart tests
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';

void main() {
  group('BroadcastEvent (19.1)', () {
    test('19.1-DOMAIN-001: stepAdvanced equality', () {
      const a = BroadcastEvent.stepAdvanced(stepIndex: 2, elapsedSeconds: 30);
      const b = BroadcastEvent.stepAdvanced(stepIndex: 2, elapsedSeconds: 30);
      expect(a, b);
    });

    test('19.1-DOMAIN-002: different events are not equal', () {
      const a = BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 10);
      const b = BroadcastEvent.sessionStarted();
      expect(a, isNot(b));
    });

    test('19.1-DOMAIN-003: sealed match covers all variants', () {
      const events = [
        BroadcastEvent.stepAdvanced(stepIndex: 0, elapsedSeconds: 0),
        BroadcastEvent.sessionStarted(),
        BroadcastEvent.sessionEnded(),
        BroadcastEvent.unknown(rawEvent: 'x'),
      ];
      for (final e in events) {
        // Exhaustive switch — compiler will error if a variant is missing
        final label = switch (e) {
          StepAdvanced() => 'step',
          SessionStarted() => 'start',
          SessionEnded() => 'end',
          UnknownBroadcast() => 'unknown',
        };
        expect(label, isA<String>());
      }
    });
  });

  group('PresenceState (19.1)', () {
    test('19.1-DOMAIN-004: empty participants list', () {
      const s = PresenceState(participants: []);
      expect(s.participants, isEmpty);
    });

    test('19.1-DOMAIN-005: participants equality', () {
      const a = PresenceState(participants: [
        ParticipantPresence(userId: 'u1', displayHandle: 'alice'),
      ]);
      const b = PresenceState(participants: [
        ParticipantPresence(userId: 'u1', displayHandle: 'alice'),
      ]);
      expect(a, b);
    });
  });
}
