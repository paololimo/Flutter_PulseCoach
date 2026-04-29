import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/bandit_state.dart';
import 'package:pulse_coach/ai/bandit/contextual_bandit.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

StateVector _sv() => const StateVector(
      restingHR: 65.0,
      stepCount: 4000,
      activityLevel: ActivityLevel.moderate,
      rpeHistory: [],
      missedSessions: 0,
      streak: 0,
      aqiLevel: AqiLevel.low,
      temperature: 20.0,
      precipitation: false,
      userProfile: UserProfile(
        fitnessLevel: 'medium',
        goal: 'cardio',
        availableTime: 'short',
        physicalConstraints: 'none',
      ),
      currentState: BehavioralState.active,
    );

BanditState _uniformState() => initialBanditState();

/// State with cardio_medium arm weight much higher — triggers pure exploitation.
BanditState _dominantState() => BanditState(
      armWeights: {
        for (final key in banditArmKeys) key: key == 'cardio_medium' ? 5.0 : 1.0,
      },
      updatedAt: DateTime.utc(1970),
    );

void main() {
  // ── initialBanditState ─────────────────────────────────────────────────────

  group('initialBanditState (AC1 — cold start, FR10)', () {
    test('5.4-UNIT-011: initial state has exactly 9 arms', () {
      expect(initialBanditState().armWeights.length, equals(9));
    });

    test('5.4-UNIT-012: initial state all arms at 1.0 (uniform exploration)', () {
      final weights = initialBanditState().armWeights;
      for (final value in weights.values) {
        expect(value, equals(1.0));
      }
    });

    test('5.4-UNIT-013: initial state keys match banditArmKeys', () {
      expect(
        initialBanditState().armWeights.keys.toSet(),
        equals(banditArmKeys.toSet()),
      );
    });
  });

  // ── selectSessions — count and coverage ───────────────────────────────────

  group('BanditEngine.selectSessions — session count', () {
    test('5.4-UNIT-014: noConstraints + uniform weights → 3 sessions returned', () {
      final engine = BanditEngine(epsilon: 0.0);
      final sessions = engine.selectSessions(_sv(), noConstraints, _uniformState());
      expect(sessions.length, equals(3));
    });

    test('5.4-UNIT-015: maxSessionCount=2 → at most 2 sessions returned', () {
      final engine = BanditEngine(epsilon: 0.0);
      const constraints = SafetyConstraints(
        maxIntensity: null,
        maxSessionCount: 2,
        outdoorAllowed: true,
      );
      final sessions = engine.selectSessions(_sv(), constraints, _uniformState());
      expect(sessions.length, lessThanOrEqualTo(2));
    });

    test('5.4-UNIT-016: no eligible arms → returns empty list', () {
      final engine = BanditEngine(epsilon: 0.0);
      // maxIntensity=low AND only 3 low arms → 3 eligible. This test uses
      // a fabricated constraint combination that leaves 0 arms: not possible
      // via SafetyConstraints alone since low always has 3 arms.
      // Instead: verify behaviour when maxSessionCount=0.
      const constraints = SafetyConstraints(
        maxIntensity: null,
        maxSessionCount: 0,
        outdoorAllowed: true,
      );
      final sessions = engine.selectSessions(_sv(), constraints, _uniformState());
      expect(sessions, isEmpty);
    });

    test('5.4-UNIT-017: no duplicate arms in a single plan', () {
      final engine = BanditEngine(random: Random(42), epsilon: 1.0);
      final sessions = engine.selectSessions(_sv(), noConstraints, _uniformState());
      final arms = sessions.map((s) => '${s.sessionType}_${_intensityName(s.intensity)}');
      expect(arms.toSet().length, equals(sessions.length));
    });
  });

  // ── selectSessions — intensity filtering ──────────────────────────────────

  group('BanditEngine.selectSessions — intensity constraint (SafetyConstraints)', () {
    test('5.4-UNIT-018: maxIntensity=low → all sessions have intensity ≤ 3', () {
      final engine = BanditEngine(epsilon: 0.0);
      const constraints = SafetyConstraints(
        maxIntensity: SessionIntensity.low,
        maxSessionCount: 3,
        outdoorAllowed: true,
      );
      final sessions = engine.selectSessions(_sv(), constraints, _uniformState());
      for (final s in sessions) {
        expect(s.intensity, lessThanOrEqualTo(3),
            reason: 'intensity ${s.intensity} exceeds low cap (≤3)');
      }
    });

    test('5.4-UNIT-019: maxIntensity=medium → no high-intensity sessions', () {
      final engine = BanditEngine(epsilon: 0.0);
      const constraints = SafetyConstraints(
        maxIntensity: SessionIntensity.medium,
        maxSessionCount: 3,
        outdoorAllowed: true,
      );
      final sessions = engine.selectSessions(_sv(), constraints, _uniformState());
      for (final s in sessions) {
        expect(s.intensity, lessThanOrEqualTo(6),
            reason: 'high-intensity session (intensity ${s.intensity}) slipped past medium cap');
      }
    });

    test('5.4-UNIT-020: maxIntensity=low → exactly 3 eligible arms → 3 sessions', () {
      final engine = BanditEngine(epsilon: 0.0);
      const constraints = SafetyConstraints(
        maxIntensity: SessionIntensity.low,
        maxSessionCount: 3,
        outdoorAllowed: true,
      );
      final sessions = engine.selectSessions(_sv(), constraints, _uniformState());
      // Only 3 low arms exist → all 3 returned
      expect(sessions.length, equals(3));
    });
  });

  // ── selectSessions — outdoor constraint ───────────────────────────────────

  group('BanditEngine.selectSessions — outdoor constraint', () {
    test('5.4-UNIT-021: outdoorAllowed=false → all sessions isIndoor=true', () {
      final engine = BanditEngine(epsilon: 0.0);
      const constraints = SafetyConstraints(
        maxIntensity: null,
        maxSessionCount: 3,
        outdoorAllowed: false,
      );
      final sessions = engine.selectSessions(_sv(), constraints, _uniformState());
      for (final s in sessions) {
        expect(s.isIndoor, isTrue,
            reason: 'outdoor session returned despite outdoorAllowed=false');
      }
    });

    test('5.4-UNIT-022: outdoorAllowed=true → sessions isIndoor=false', () {
      final engine = BanditEngine(epsilon: 0.0);
      final sessions = engine.selectSessions(_sv(), noConstraints, _uniformState());
      for (final s in sessions) {
        expect(s.isIndoor, isFalse);
      }
    });
  });

  // ── selectSessions — exploit vs explore ───────────────────────────────────

  group('BanditEngine.selectSessions — epsilon-greedy behaviour', () {
    test('5.4-UNIT-023: epsilon=0.0 → always exploits; dominant arm selected first', () {
      final engine = BanditEngine(epsilon: 0.0);
      final sessions = engine.selectSessions(_sv(), noConstraints, _dominantState());
      // cardio_medium has weight 5.0 — must be first pick in exploit mode
      expect(sessions.first.sessionType, equals('cardio'));
      expect(sessions.first.intensity, equals(6)); // medium → 6
    });

    test('5.4-UNIT-024: epsilon=1.0 → pure explore; result in eligible set', () {
      final engine = BanditEngine(random: Random(0), epsilon: 1.0);
      final sessions = engine.selectSessions(_sv(), noConstraints, _uniformState());
      final validArms = banditArmKeys.toSet();
      for (final s in sessions) {
        final armKey = '${s.sessionType}_${_intensityName(s.intensity)}';
        expect(validArms, contains(armKey));
      }
    });
  });

  // ── selectSessions — PlannedSession fields ────────────────────────────────

  group('BanditEngine.selectSessions — PlannedSession mapping', () {
    test('5.4-UNIT-025: sessionType is one of the 3 known types', () {
      final engine = BanditEngine(epsilon: 0.0);
      final sessions = engine.selectSessions(_sv(), noConstraints, _uniformState());
      for (final s in sessions) {
        expect(['mobility', 'cardio', 'breathing'], contains(s.sessionType));
      }
    });

    test('5.4-UNIT-026: durationMinutes = 10 (Story 6.x placeholder)', () {
      final engine = BanditEngine(epsilon: 0.0);
      final sessions = engine.selectSessions(_sv(), noConstraints, _uniformState());
      for (final s in sessions) {
        expect(s.durationMinutes, equals(10));
      }
    });
  });

  // ── updateReward — weight preservation (FR25) ─────────────────────────────

  group('BanditEngine.updateReward — FR25 weight preservation', () {
    test('5.4-UNIT-027: updateReward after state machine transition preserves other weights', () {
      final engine = BanditEngine(epsilon: 0.0);
      final updated = engine.updateReward(_uniformState(), 'cardio_medium', 6);
      // Only cardio_medium changes; all others stay at 1.0 (FR25 guarantee)
      for (final key in banditArmKeys) {
        if (key != 'cardio_medium') {
          expect(updated.armWeights[key], equals(1.0),
              reason: '$key should be preserved after reward update');
        }
      }
    });

    test('5.4-UNIT-028: updateReward with RPE=1 → arm weight decreases toward 0', () {
      final engine = BanditEngine(epsilon: 0.0);
      final updated = engine.updateReward(_uniformState(), 'mobility_high', 1);
      expect(updated.armWeights['mobility_high']!, lessThan(1.0));
    });
  });
}

// Helper: reverse-map intensity int back to name for assertion readability.
String _intensityName(int intensity) {
  if (intensity <= 3) return 'low';
  if (intensity <= 7) return 'medium';
  return 'high';
}
