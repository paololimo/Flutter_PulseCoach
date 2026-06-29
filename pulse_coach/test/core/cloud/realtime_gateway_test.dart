// [19.1-GW-001..008, 20.5-GW-009..013] RealtimeGateway.parseBroadcast unit tests
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

  group('RealtimeGateway.parseBroadcast session_started type-guards (20.5)', () {
    test(
        '20.5-GW-009: session_started with valid full payload → all fields extracted',
        () {
      final result = RealtimeGateway.parseBroadcast('session_started', {
        'session_type': 'cardio',
        'intensity': 6,
        'duration_minutes': 30,
        'arm_key': 'cardio_custom',
      });
      expect(
        result,
        const BroadcastEvent.sessionStarted(
          sessionType: 'cardio',
          intensity: 6,
          durationMinutes: 30,
          armKey: 'cardio_custom',
        ),
      );
    });

    test(
        '20.5-GW-010: session_type wrong type (int) → falls back to mobility',
        () {
      final result = RealtimeGateway.parseBroadcast('session_started', {
        'session_type': 42,
        'intensity': 5,
        'arm_key': 'should_still_parse',
      });
      expect(result, isA<BroadcastEvent>());
      result!.mapOrNull(
        sessionStarted: (e) => expect(e.sessionType, 'mobility'),
      );
    });

    test(
        '20.5-GW-011: intensity wrong type (String) → falls back to 5, armKey derives mobility_medium',
        () {
      final result = RealtimeGateway.parseBroadcast('session_started', {
        'intensity': 'high',
      });
      result!.mapOrNull(
        sessionStarted: (e) {
          expect(e.intensity, 5);
          expect(e.armKey, 'mobility_medium');
        },
      );
    });

    test(
        '20.5-GW-012: arm_key wrong type (int) → derived from intensity 3 → mobility_low',
        () {
      final result = RealtimeGateway.parseBroadcast('session_started', {
        'intensity': 3,
        'arm_key': 999,
      });
      result!.mapOrNull(
        sessionStarted: (e) => expect(e.armKey, 'mobility_low'),
      );
    });

    test(
        '20.5-GW-013: intensity 8 with missing arm_key → defaultName high → mobility_high',
        () {
      final result = RealtimeGateway.parseBroadcast('session_started', {
        'intensity': 8,
      });
      result!.mapOrNull(
        sessionStarted: (e) {
          expect(e.intensity, 8);
          expect(e.armKey, 'mobility_high');
        },
      );
    });
  });
}
