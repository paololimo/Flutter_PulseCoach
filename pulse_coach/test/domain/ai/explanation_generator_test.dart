import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/explainability/explanation_generator.dart';
import 'package:pulse_coach/ai/explainability/explanation_key.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

// ─── Fixtures ──────────────────────────────────────────────────────────────────

StateVector _sv({
  BehavioralState state = BehavioralState.active,
  double? restingHR = 65.0,
  int? stepCount = 4000,
  List<int> rpeHistory = const [],
  int streak = 0,
  int missedSessions = 0,
}) => StateVector(
  restingHR: restingHR,
  stepCount: stepCount,
  activityLevel: ActivityLevel.moderate,
  rpeHistory: rpeHistory,
  missedSessions: missedSessions,
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

PlannedSession _session({String type = 'cardio'}) => PlannedSession(
  sessionType: type,
  intensity: 5,
  durationMinutes: 5,
  isIndoor: false,
);

const _gen = ExplanationGenerator();

// The generator emits locale-independent ExplanationKey names (E7.5-T1); the
// presentation layer resolves them to localized strings. Tests assert the key,
// not any language's text.
void main() {
  group('ExplanationGenerator — AC4: non-empty guarantee', () {
    test('5.6-UNIT-002: active state with biometrics → non-empty key', () {
      final result = _gen.generate(stateVector: _sv(), sessions: [_session()]);
      expect(result.single, isNotEmpty);
      expect(ExplanationKey.tryParse(result.single), isNotNull);
    });

    test('5.6-UNIT-003: no sensor data, no RPE → type fallback key', () {
      final sv = _sv(restingHR: null, stepCount: null);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.genericFallback.name);
    });

    test('5.6-UNIT-004: returns same count as sessions list, all known keys', () {
      final sessions = [
        _session(),
        _session(type: 'mobility'),
        _session(type: 'breathing'),
      ];
      final result = _gen.generate(stateVector: _sv(), sessions: sessions);
      expect(result.length, equals(3));
      for (final e in result) {
        expect(ExplanationKey.tryParse(e), isNotNull);
      }
    });

    test('5.6-UNIT-005: empty sessions list → empty result (no crash)', () {
      final result = _gen.generate(stateVector: _sv(), sessions: []);
      expect(result, isEmpty);
    });
  });

  group('ExplanationGenerator — AC3: Recovering state', () {
    test('5.6-UNIT-006: Recovering → recovering key', () {
      final sv = _sv(state: BehavioralState.recovering);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.recovering.name);
    });

    test('5.6-UNIT-007: Recovering overrides biometric signals', () {
      final sv = _sv(
        state: BehavioralState.recovering,
        restingHR: 45.0, // low HR — would otherwise be "solid" message
        stepCount: 8000,
        streak: 5,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      // Must still use Recovering key, not the biometric/streak one
      expect(result.single, ExplanationKey.recovering.name);
    });
  });

  group('ExplanationGenerator — AC1: signal-based explanations', () {
    test('5.6-UNIT-008: elevated HR → elevatedRestingHr key', () {
      final sv = _sv(restingHR: 80.0, state: BehavioralState.active);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.elevatedRestingHr.name);
    });

    test('5.6-UNIT-009: low step count → lowSteps key', () {
      final sv = _sv(
        stepCount: 1500,
        restingHR: null,
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.lowSteps.name);
    });

    test('5.6-UNIT-010: good streak → greatStreak key', () {
      final sv = _sv(
        streak: 4,
        restingHR: null,
        stepCount: null,
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.greatStreak.name);
    });
  });

  group('ExplanationGenerator — AC2: RPE-only fallback', () {
    test('5.6-UNIT-011: consistent low RPE + streak → consistentWeek key', () {
      final sv = _sv(
        restingHR: null,
        stepCount: null,
        rpeHistory: [5, 6, 6, 5, 6],
        streak: 3,
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.consistentWeek.name);
    });

    test('5.6-UNIT-012: high RPE history → intenseEffort key', () {
      final sv = _sv(
        restingHR: null,
        stepCount: null,
        rpeHistory: [9, 8, 9, 9],
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.intenseEffort.name);
    });
  });

  group('ExplanationGenerator — behavioral state messages', () {
    test('5.6-UNIT-013: AtRisk + missed ≥ 2 → atRiskMissed key', () {
      final sv = _sv(state: BehavioralState.atRisk, missedSessions: 3);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.atRiskMissed.name);
    });

    test('5.6-UNIT-014: Fatigued → fatigued key', () {
      final sv = _sv(state: BehavioralState.fatigued);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.fatigued.name);
    });

    test('5.6-UNIT-015: welcome-back scenario (streak=0, missed≥3)', () {
      final sv = _sv(
        streak: 0,
        missedSessions: 4,
        restingHR: null,
        stepCount: null,
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.welcomeBack.name);
    });
  });

  group('ExplanationGenerator — boundary values', () {
    test('5.6-UNIT-018: HR exactly 75.0 → not elevated (boundary)', () {
      final sv = _sv(restingHR: 75.0, state: BehavioralState.active);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, isNot(ExplanationKey.elevatedRestingHr.name));
    });

    test('5.6-UNIT-019: HR exactly 60.0 with streak=1 → optimalRestingHr', () {
      final sv = _sv(restingHR: 60.0, streak: 1, state: BehavioralState.active);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.optimalRestingHr.name);
    });

    test('5.6-UNIT-020: stepCount exactly 3000 → not low (boundary)', () {
      final sv = _sv(
        stepCount: 3000,
        restingHR: null,
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, isNot(ExplanationKey.lowSteps.name));
    });

    test('5.6-UNIT-021: RPE avg exactly 6.5 with streak=2 → consistentWeek', () {
      final sv = _sv(
        restingHR: null,
        stepCount: null,
        rpeHistory: [6, 7, 6, 7], // avg = 6.5
        streak: 2,
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.consistentWeek.name);
    });

    test('5.6-UNIT-022: RPE avg exactly 7.5 → comfortZone (> is exclusive)', () {
      final sv = _sv(
        restingHR: null,
        stepCount: null,
        rpeHistory: [7, 8, 7, 8], // avg = 7.5
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.comfortZone.name);
    });

    test('5.6-UNIT-023: streak exactly 3 → greatStreak (boundary)', () {
      final sv = _sv(
        streak: 3,
        restingHR: null,
        stepCount: null,
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.greatStreak.name);
    });

    test('5.6-UNIT-024: AtRisk + missed exactly 2 → atRiskMissed (boundary)', () {
      final sv = _sv(state: BehavioralState.atRisk, missedSessions: 2);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.atRiskMissed.name);
    });

    test('5.6-UNIT-025: AtRisk + missed exactly 1 → atRiskHighLoad (boundary)', () {
      final sv = _sv(state: BehavioralState.atRisk, missedSessions: 1);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, ExplanationKey.atRiskHighLoad.name);
    });
  });

  group('ExplanationGenerator — session-type fallback', () {
    test('5.6-UNIT-016: breathing session type → breathingFallback key', () {
      final sv = _sv(restingHR: null, stepCount: null);
      final result = _gen.generate(
        stateVector: sv,
        sessions: [_session(type: 'breathing')],
      );
      expect(result.single, ExplanationKey.breathingFallback.name);
    });

    test('5.6-UNIT-017: mobility session type → mobilityFallback key', () {
      final sv = _sv(restingHR: null, stepCount: null);
      final result = _gen.generate(
        stateVector: sv,
        sessions: [_session(type: 'mobility')],
      );
      expect(result.single, ExplanationKey.mobilityFallback.name);
    });
  });
}
