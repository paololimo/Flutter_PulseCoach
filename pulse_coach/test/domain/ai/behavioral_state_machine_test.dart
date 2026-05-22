// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state_machine.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_transition.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_transition_key.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

// ─── Fixture helpers ─────────────────────────────────────────────────────────

StateVector _sv({
  BehavioralState state = BehavioralState.active,
  List<int> rpe = const [],
  int missed = 0,
  int streak = 0,
}) => StateVector(
  restingHR: 65.0,
  stepCount: 4000,
  activityLevel: ActivityLevel.moderate,
  rpeHistory: rpe,
  missedSessions: missed,
  streak: streak,
  aqiLevel: AqiLevel.low,
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
  const machine = BehavioralStateMachine();

  // ── BehavioralTransition ──────────────────────────────────────────────────

  group('BehavioralTransition', () {
    test('5.2-UNIT-001: stateChanged is false when no transition key', () {
      const t = BehavioralTransition(newState: BehavioralState.active);
      expect(t.stateChanged, isFalse);
      expect(t.transitionKey, isNull);
    });

    test('5.2-UNIT-002: stateChanged is true when transition key provided', () {
      const t = BehavioralTransition(
        newState: BehavioralState.fatigued,
        transitionKey: BehavioralTransitionKey.activeToFatigued,
      );
      expect(t.stateChanged, isTrue);
    });
  });

  // ── Transition: active → fatigued ────────────────────────────────────────

  group('active → fatigued', () {
    test('5.2-UNIT-003: fires when last 2 RPE avg > 8 (9, 9)', () {
      final sv = _sv(state: BehavioralState.active, rpe: [7, 9, 9]);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.fatigued));
      expect(
        result.transitionKey,
        equals(BehavioralTransitionKey.activeToFatigued),
      );
      expect(result.stateChanged, isTrue);
    });

    test(
      '5.2-UNIT-004: fires when last 2 RPE avg = 8.5 (above > 8.0 threshold)',
      () {
        final sv = _sv(state: BehavioralState.active, rpe: [9, 8]);
        final result = machine.evaluate(sv);
        expect(result.newState, equals(BehavioralState.fatigued));
      },
    );

    test('5.2-UNIT-005: does NOT fire when last 2 RPE avg = 8.0 (not > 8)', () {
      final sv = _sv(state: BehavioralState.active, rpe: [8, 8]);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.active));
      expect(result.stateChanged, isFalse);
    });

    test(
      '5.2-UNIT-006: does NOT fire with only 1 RPE entry (insufficient data)',
      () {
        final sv = _sv(state: BehavioralState.active, rpe: [10]);
        final result = machine.evaluate(sv);
        expect(result.newState, equals(BehavioralState.active));
      },
    );

    test('5.2-UNIT-007: does NOT fire with empty rpeHistory', () {
      final sv = _sv(state: BehavioralState.active, rpe: []);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.active));
    });
  });

  // ── Transition: fatigued → atRisk ────────────────────────────────────────

  group('fatigued → atRisk', () {
    test('5.2-UNIT-008: fires when missedSessions >= 2', () {
      final sv = _sv(state: BehavioralState.fatigued, missed: 2);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.atRisk));
      expect(result.stateChanged, isTrue);
    });

    test('5.2-UNIT-009: fires with missedSessions = 3 (above threshold)', () {
      final sv = _sv(state: BehavioralState.fatigued, missed: 3);
      expect(machine.evaluate(sv).newState, equals(BehavioralState.atRisk));
    });

    test('5.2-UNIT-010: does NOT fire when missedSessions = 1', () {
      // rpe [8,9]: last RPE is 9 > 7, so fatigued→recovering also doesn't fire
      // fatigued→atRisk requires missed >= 2 → stays fatigued
      final sv = _sv(state: BehavioralState.fatigued, missed: 1, rpe: [8, 9]);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.fatigued));
    });
  });

  // ── Transition: active → atRisk (Story 7.1b — Q1) ───────────────────────

  group('active → atRisk (Q1)', () {
    test('7.1b-UNIT-001: fires when missedSessions >= 2 from active', () {
      final sv = _sv(state: BehavioralState.active, missed: 2);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.atRisk));
      expect(result.stateChanged, isTrue);
      expect(
        result.transitionKey,
        equals(BehavioralTransitionKey.activeToAtRisk),
      );
    });

    test(
      '7.1b-UNIT-002: does NOT fire when missedSessions = 1 from active',
      () {
        final sv = _sv(state: BehavioralState.active, missed: 1);
        final result = machine.evaluate(sv);
        expect(result.newState, equals(BehavioralState.active));
        expect(result.stateChanged, isFalse);
      },
    );

    test(
      '7.1b-UNIT-003: priority guard - active + missed=2 + high RPE -> atRisk wins over fatigued',
      () {
        final sv = _sv(state: BehavioralState.active, missed: 2, rpe: [9, 9]);
        final result = machine.evaluate(sv);
        expect(result.newState, equals(BehavioralState.atRisk));
      },
    );
  });

  // ── Transition: atRisk/fatigued → recovering ─────────────────────────────

  group('atRisk/fatigued → recovering', () {
    test('5.2-UNIT-011: fires from atRisk with 3 RPE avg ≤ 7 and missed=0', () {
      final sv = _sv(state: BehavioralState.atRisk, rpe: [5, 6, 5], missed: 0);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.recovering));
      expect(result.stateChanged, isTrue);
    });

    test(
      '5.2-UNIT-012: fires from fatigued with 3 RPE avg ≤ 7 and missed=0',
      () {
        // missedSessions=0 to avoid fatigued→atRisk rule firing first
        final sv = _sv(
          state: BehavioralState.fatigued,
          rpe: [5, 6, 5],
          missed: 0,
        );
        final result = machine.evaluate(sv);
        expect(result.newState, equals(BehavioralState.recovering));
      },
    );

    test('5.2-UNIT-013: does NOT fire when last RPE = 8 (> 7)', () {
      final sv = _sv(state: BehavioralState.atRisk, rpe: [6, 8]);
      expect(machine.evaluate(sv).newState, equals(BehavioralState.atRisk));
    });

    test('5.2-UNIT-014: does NOT fire with only 1 RPE entry', () {
      final sv = _sv(state: BehavioralState.atRisk, rpe: [5]);
      expect(machine.evaluate(sv).newState, equals(BehavioralState.atRisk));
    });

    test(
      '5.2-UNIT-015: fatigued→atRisk takes priority over fatigued→recovering when missed>=2',
      () {
        // missed=2 triggers fatigued→atRisk first; recovering rule is NOT checked
        final sv = _sv(state: BehavioralState.fatigued, rpe: [6, 7], missed: 2);
        final result = machine.evaluate(sv);
        expect(result.newState, equals(BehavioralState.atRisk));
      },
    );
  });

  group('atRisk/fatigued → recovering — Q3 tightened rule', () {
    test('7.1-UNIT-Q3-001: atRisk + 3 RPE avg ≤ 7 + missed=0 → recovering', () {
      final sv = _sv(state: BehavioralState.atRisk, rpe: [5, 6, 6], missed: 0);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.recovering));
      expect(result.stateChanged, isTrue);
    });

    test(
      '7.1-UNIT-Q3-002: only 2 RPE values → no transition even with avg ≤ 7',
      () {
        final sv = _sv(state: BehavioralState.atRisk, rpe: [5, 6], missed: 0);
        final result = machine.evaluate(sv);
        expect(result.newState, equals(BehavioralState.atRisk));
        expect(result.stateChanged, isFalse);
      },
    );

    test('7.1-UNIT-Q3-003: avg ≤ 7 but missed ≥ 1 → no transition', () {
      final sv = _sv(
        state: BehavioralState.fatigued,
        rpe: [5, 6, 5],
        missed: 1,
      );
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.fatigued));
      expect(result.stateChanged, isFalse);
    });

    test('7.1-UNIT-Q3-004: avg > 7 (e.g. [8, 7, 7]) → no transition', () {
      final sv = _sv(state: BehavioralState.atRisk, rpe: [8, 7, 7], missed: 0);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.atRisk));
      expect(result.stateChanged, isFalse);
    });
  });

  // ── Transition: recovering → active ─────────────────────────────────────

  group('recovering → active', () {
    test('5.2-UNIT-016: fires when last 3 avg ≤ 6.5 AND streak ≥ 3', () {
      final sv = _sv(
        state: BehavioralState.recovering,
        rpe: [6, 7, 6],
        streak: 3,
      );
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.active));
      expect(result.stateChanged, isTrue);
    });

    test(
      '5.2-UNIT-017: averages only the LAST 3 RPE values (ignores earlier highs)',
      () {
        // Guards the sublist(rpe.length - n) logic: earlier high RPEs [9, 9]
        // must NOT contribute. Last 3: (6 + 7 + 6) / 3 = 6.333 ≤ 6.5 → fires.
        // Note: an exact avg = 6.5 boundary is unreachable with 3 integer RPEs
        // (sum = 19.5 is impossible), so this test probes the window semantics
        // instead of the == 6.5 boundary.
        final sv = _sv(
          state: BehavioralState.recovering,
          rpe: [9, 9, 6, 7, 6],
          streak: 3,
        );
        expect(machine.evaluate(sv).newState, equals(BehavioralState.active));
      },
    );

    test('5.2-UNIT-018: does NOT fire when avg > 6.5', () {
      // (7 + 7 + 6) / 3 = 6.666... > 6.5
      final sv = _sv(
        state: BehavioralState.recovering,
        rpe: [7, 7, 6],
        streak: 3,
      );
      expect(machine.evaluate(sv).newState, equals(BehavioralState.recovering));
    });

    test('5.2-UNIT-019: does NOT fire when streak < 3', () {
      final sv = _sv(
        state: BehavioralState.recovering,
        rpe: [6, 6, 6],
        streak: 2,
      );
      expect(machine.evaluate(sv).newState, equals(BehavioralState.recovering));
    });

    test('5.2-UNIT-020: does NOT fire with fewer than 3 RPE entries', () {
      final sv = _sv(state: BehavioralState.recovering, rpe: [6, 6], streak: 3);
      expect(machine.evaluate(sv).newState, equals(BehavioralState.recovering));
    });
  });

  group('recovering → fatigued — Q2 new rule', () {
    test('7.1-UNIT-Q2-001: recovering + last RPE = 9 → fatigued', () {
      final sv = _sv(
        state: BehavioralState.recovering,
        rpe: [5, 6, 9],
        missed: 0,
      );
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.fatigued));
      expect(result.stateChanged, isTrue);
      expect(
        result.transitionKey,
        equals(BehavioralTransitionKey.recoveringToFatigued),
      );
    });

    test('7.1-UNIT-Q2-002: recovering + last RPE = 10 → fatigued', () {
      final sv = _sv(
        state: BehavioralState.recovering,
        rpe: [5, 6, 10],
        missed: 0,
      );
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.fatigued));
      expect(result.stateChanged, isTrue);
    });

    test('7.1-UNIT-Q2-003: recovering + last RPE = 8 → no transition', () {
      final sv = _sv(
        state: BehavioralState.recovering,
        rpe: [5, 6, 8],
        missed: 0,
        streak: 1,
      );
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.recovering));
      expect(result.stateChanged, isFalse);
    });

    test(
      '7.1-UNIT-Q2-004: priority guard — recovering→active fires first when both conditions match',
      () {
        final sv = _sv(
          state: BehavioralState.recovering,
          rpe: [4, 5, 9],
          missed: 0,
          streak: 3,
        );
        final result = machine.evaluate(sv);
        expect(result.newState, equals(BehavioralState.active));
      },
    );
  });

  // ── constraintsForState ──────────────────────────────────────────────────

  group('constraintsForState (FR24)', () {
    test('5.2-UNIT-021: atRisk → maxIntensity low, maxSessionCount 2', () {
      final c = machine.constraintsForState(BehavioralState.atRisk);
      expect(c.maxIntensity, equals(SessionIntensity.low));
      expect(c.maxSessionCount, equals(2));
      expect(c.outdoorAllowed, isTrue);
    });

    test('5.2-UNIT-022: recovering → maxIntensity low, maxSessionCount 2', () {
      final c = machine.constraintsForState(BehavioralState.recovering);
      expect(c.maxIntensity, equals(SessionIntensity.low));
      expect(c.maxSessionCount, equals(2));
    });

    test(
      '5.2-UNIT-023: active → noConstraints (null maxIntensity, maxSessionCount 3)',
      () {
        final c = machine.constraintsForState(BehavioralState.active);
        expect(c.maxIntensity, isNull);
        expect(c.maxSessionCount, equals(3));
        expect(c.outdoorAllowed, isTrue);
      },
    );

    test('5.2-UNIT-024: fatigued → medium intensity cap, 3 sessions', () {
      final c = machine.constraintsForState(BehavioralState.fatigued);
      expect(c.maxIntensity, equals(SessionIntensity.medium));
      expect(c.maxSessionCount, equals(3));
    });
  });

  // ── No-transition stability ───────────────────────────────────────────────

  group('No transition (state stays the same)', () {
    test('5.2-UNIT-025: active stays active when RPE normal (avg ≤ 8)', () {
      final sv = _sv(state: BehavioralState.active, rpe: [6, 7, 7]);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.active));
      expect(result.stateChanged, isFalse);
      expect(result.transitionKey, isNull);
    });

    test(
      '5.2-UNIT-026: atRisk stays atRisk when conditions for recovery not met',
      () {
        final sv = _sv(state: BehavioralState.atRisk, rpe: [8, 9]);
        expect(machine.evaluate(sv).newState, equals(BehavioralState.atRisk));
      },
    );
  });
}
