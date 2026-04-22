// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/safety/safety_rules.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state_machine.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

// ─── Fixture helper ───────────────────────────────────────────────────────────

StateVector _sv({
  BehavioralState state = BehavioralState.active,
  List<int> rpe = const [],
  AqiLevel aqi = AqiLevel.low,
}) =>
    StateVector(
      restingHR: 65.0,
      stepCount: 4000,
      activityLevel: ActivityLevel.moderate,
      rpeHistory: rpe,
      missedSessions: 0,
      streak: 0,
      aqiLevel: aqi,
      temperature: 20.0,
      precipitation: false,
      userProfile: const UserProfile(
        fitnessLevel: 'medium',
        goal: 'cardio',
        availableTime: 'short',
        physicalConstraints: 'none',
      ),
      currentState: state,
    );

void main() {
  late SafetyRules rules;

  setUp(() {
    rules = SafetyRules(const BehavioralStateMachine());
  });

  // ── AQI Rule (FR8) ─────────────────────────────────────────────────────────

  group('AQI rule (FR8)', () {
    test('5.3-UNIT-001: AqiLevel.high → outdoorAllowed = false', () {
      final c = rules.apply(_sv(aqi: AqiLevel.high));
      expect(c.outdoorAllowed, isFalse);
    });

    test('5.3-UNIT-002: AqiLevel.low → outdoorAllowed = true (active state allows)', () {
      final c = rules.apply(_sv(aqi: AqiLevel.low));
      expect(c.outdoorAllowed, isTrue);
    });
  });

  // ── RPE Rule (FR9) ─────────────────────────────────────────────────────────

  group('RPE rule (FR9)', () {
    test('5.3-UNIT-003: last 2 avg = 9.0 (9, 9) → maxIntensity capped at medium', () {
      final c = rules.apply(_sv(rpe: [9, 9]));
      expect(c.maxIntensity, equals(SessionIntensity.medium));
    });

    test('5.3-UNIT-004: last 2 avg = 8.5 (9, 8) → capped at medium', () {
      final c = rules.apply(_sv(rpe: [9, 8]));
      expect(c.maxIntensity, equals(SessionIntensity.medium));
    });

    test('5.3-UNIT-005: last 2 avg = 8.0 (not > 8) → no RPE cap applied', () {
      final c = rules.apply(_sv(rpe: [8, 8]));
      expect(c.maxIntensity, isNull); // active state: noConstraints
    });

    test('5.3-UNIT-006: fewer than 2 RPE entries → no RPE cap', () {
      final c = rules.apply(_sv(rpe: [10]));
      expect(c.maxIntensity, isNull);
    });

    test('5.3-UNIT-007: empty rpeHistory → no RPE cap', () {
      final c = rules.apply(_sv(rpe: []));
      expect(c.maxIntensity, isNull);
    });
  });

  // ── Behavioral State Constraints (FR24) ────────────────────────────────────

  group('Behavioral state constraints (FR24)', () {
    test('5.3-UNIT-008: atRisk → low intensity cap, maxSessionCount = 2', () {
      final c = rules.apply(_sv(state: BehavioralState.atRisk));
      expect(c.maxIntensity, equals(SessionIntensity.low));
      expect(c.maxSessionCount, equals(2));
    });

    test('5.3-UNIT-009: recovering → low intensity cap, maxSessionCount = 2', () {
      final c = rules.apply(_sv(state: BehavioralState.recovering));
      expect(c.maxIntensity, equals(SessionIntensity.low));
      expect(c.maxSessionCount, equals(2));
    });

    test('5.3-UNIT-010: fatigued → medium intensity cap, maxSessionCount = 3', () {
      final c = rules.apply(_sv(state: BehavioralState.fatigued));
      expect(c.maxIntensity, equals(SessionIntensity.medium));
      expect(c.maxSessionCount, equals(3));
    });

    test('5.3-UNIT-011: active → no intensity cap, maxSessionCount = 3', () {
      final c = rules.apply(_sv(state: BehavioralState.active));
      expect(c.maxIntensity, isNull);
      expect(c.maxSessionCount, equals(3));
    });
  });

  // ── Combined Rules — Most Restrictive Wins ─────────────────────────────────

  group('Combined constraint merging (most restrictive wins)', () {
    test('5.3-UNIT-012: atRisk + AQI high → low intensity + outdoor blocked', () {
      final c = rules.apply(
        _sv(state: BehavioralState.atRisk, aqi: AqiLevel.high),
      );
      expect(c.maxIntensity, equals(SessionIntensity.low));
      expect(c.maxSessionCount, equals(2));
      expect(c.outdoorAllowed, isFalse);
    });

    test('5.3-UNIT-013: active + RPE > 8 + AQI high → medium cap + outdoor blocked', () {
      final c = rules.apply(
        _sv(state: BehavioralState.active, rpe: [9, 9], aqi: AqiLevel.high),
      );
      expect(c.maxIntensity, equals(SessionIntensity.medium));
      expect(c.outdoorAllowed, isFalse);
    });

    test('5.3-UNIT-014: atRisk + RPE > 8 → low wins over RPE medium (stricter)', () {
      // atRisk gives low; RPE > 8 would give medium; low is stricter → low
      final c = rules.apply(
        _sv(state: BehavioralState.atRisk, rpe: [9, 9]),
      );
      expect(c.maxIntensity, equals(SessionIntensity.low));
      expect(c.maxSessionCount, equals(2));
    });

    test('5.3-UNIT-015: recovering + RPE > 8 → low wins over RPE medium', () {
      final c = rules.apply(
        _sv(state: BehavioralState.recovering, rpe: [9, 9]),
      );
      expect(c.maxIntensity, equals(SessionIntensity.low));
    });

    test('5.3-UNIT-016: fatigued + RPE > 8 → medium (both sources agree)', () {
      final c = rules.apply(
        _sv(state: BehavioralState.fatigued, rpe: [9, 9]),
      );
      expect(c.maxIntensity, equals(SessionIntensity.medium));
    });

    test('5.3-UNIT-017: active + safe RPE + low AQI → noConstraints equivalent', () {
      final c = rules.apply(
        _sv(state: BehavioralState.active, rpe: [6, 7], aqi: AqiLevel.low),
      );
      expect(c.maxIntensity, isNull);
      expect(c.maxSessionCount, equals(3));
      expect(c.outdoorAllowed, isTrue);
    });
  });

  // ── Boundary Hardening (code review — story 5.3) ──────────────────────────

  group('RPE boundary pinning across states', () {
    test('5.3-UNIT-018: [8,8] + fatigued → medium from state, RPE does not relax', () {
      // avg = 8.0, strict > 8 means RPE rule inactive; state cap = medium.
      final c = rules.apply(_sv(state: BehavioralState.fatigued, rpe: [8, 8]));
      expect(c.maxIntensity, equals(SessionIntensity.medium));
    });

    test('5.3-UNIT-019: [8,8] + atRisk → low from state, RPE does not relax', () {
      final c = rules.apply(_sv(state: BehavioralState.atRisk, rpe: [8, 8]));
      expect(c.maxIntensity, equals(SessionIntensity.low));
    });
  });

  group('RPE slice is tail-only', () {
    test('5.3-UNIT-020: [10,10,6,6] → no cap (only last 2 averaged)', () {
      // If _lastTwoAvg ever regressed to averaging the whole list, this would
      // trigger a cap; strict tail-only must produce no cap here.
      final c = rules.apply(_sv(state: BehavioralState.active, rpe: [10, 10, 6, 6]));
      expect(c.maxIntensity, isNull);
    });
  });
}
