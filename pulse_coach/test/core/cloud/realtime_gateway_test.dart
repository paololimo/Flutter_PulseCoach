// [19.1-GW-001..008] RealtimeGateway.parseBroadcast unit tests
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';

void main() {
  group('RealtimeGateway.parseBroadcast (19.1)', () {
    test('19.1-GW-001: step_advanced with valid ints → StepAdvanced', () {
      final result = RealtimeGateway.parseBroadcast(
        'step_advanced',
        {'step_index': 3, 'elapsed_seconds': 45},
      );
      expect(result,
          const BroadcastEvent.stepAdvanced(stepIndex: 3, elapsedSeconds: 45));
    });

    test('19.1-GW-002: step_advanced with missing keys → null (malformed, drop)', () {
      final result = RealtimeGateway.parseBroadcast(
        'step_advanced',
        {'step_index': 3}, // elapsed_seconds missing
      );
      expect(result, isNull);
    });

    test('19.1-GW-003: session_started → SessionStarted', () {
      final result = RealtimeGateway.parseBroadcast('session_started', {});
      expect(result, const BroadcastEvent.sessionStarted());
    });

    test('19.1-GW-004: session_ended → SessionEnded', () {
      final result = RealtimeGateway.parseBroadcast('session_ended', {});
      expect(result, const BroadcastEvent.sessionEnded());
    });

    test('19.1-GW-005: unknown event → UnknownBroadcast', () {
      final result = RealtimeGateway.parseBroadcast('ping', {});
      expect(result, const BroadcastEvent.unknown(rawEvent: 'ping'));
    });

    test('19.1-GW-006: step_advanced with wrong payload type → null', () {
      final result = RealtimeGateway.parseBroadcast(
        'step_advanced',
        {'step_index': '3', 'elapsed_seconds': '45'}, // strings, not ints
      );
      expect(result, isNull);
    });

    test('19.1-GW-007: step_advanced with step_index 0 → valid (first step)', () {
      final result = RealtimeGateway.parseBroadcast(
        'step_advanced',
        {'step_index': 0, 'elapsed_seconds': 0},
      );
      expect(result,
          const BroadcastEvent.stepAdvanced(stepIndex: 0, elapsedSeconds: 0));
    });

    test('19.1-GW-008: step_advanced with double values → coerced to int', () {
      final result = RealtimeGateway.parseBroadcast(
        'step_advanced',
        {'step_index': 3.0, 'elapsed_seconds': 45.0},
      );
      expect(result,
          const BroadcastEvent.stepAdvanced(stepIndex: 3, elapsedSeconds: 45));
    });
  });
}
