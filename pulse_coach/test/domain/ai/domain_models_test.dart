// Domain Model Tests — Story 5.1
// Tests: equality, copyWith, JSON round-trips, edge cases, no Flutter imports
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/bandit_state.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/explanation.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

/// Shared test fixture — used across multiple tests to avoid repetition.
StateVector _makeStateVector({
  List<int> rpeHistory = const [],
  BehavioralState currentState = BehavioralState.active,
  AqiLevel aqiLevel = AqiLevel.low,
  int streak = 3,
}) => StateVector(
  restingHR: 62.0,
  stepCount: 4500,
  activityLevel: ActivityLevel.moderate,
  rpeHistory: rpeHistory,
  missedSessions: 0,
  streak: streak,
  aqiLevel: aqiLevel,
  temperature: 21.0,
  precipitation: false,
  userProfile: const UserProfile(
    fitnessLevel: 'medium',
    goal: 'cardio',
    availableTime: 'short',
    physicalConstraints: 'none',
  ),
  currentState: currentState,
);

void main() {
  group('BehavioralState', () {
    test('5.1-UNIT-001: has all four required values', () {
      expect(
        BehavioralState.values,
        containsAll([
          BehavioralState.active,
          BehavioralState.fatigued,
          BehavioralState.atRisk,
          BehavioralState.recovering,
        ]),
      );
    });
  });

  group('AqiLevel', () {
    test('5.1-UNIT-002: has low and high values', () {
      expect(AqiLevel.values, containsAll([AqiLevel.low, AqiLevel.high]));
    });
  });

  group('StateVector', () {
    test('5.1-UNIT-003: equality — two identical StateVectors are equal', () {
      final a = _makeStateVector();
      final b = _makeStateVector();
      expect(a, equals(b));
    });

    test(
      '5.1-UNIT-004: copyWith — mutating one field does not affect others',
      () {
        final original = _makeStateVector(streak: 3);
        final updated = original.copyWith(streak: 7);
        expect(updated.streak, equals(7));
        expect(updated.restingHR, equals(original.restingHR));
        expect(updated.rpeHistory, equals(original.rpeHistory));
      },
    );

    test(
      '5.1-UNIT-005: empty rpeHistory is valid — new user, no sessions yet',
      () {
        final sv = _makeStateVector(rpeHistory: []);
        expect(sv.rpeHistory, isEmpty);
      },
    );

    test('5.1-UNIT-006: nullable fields accept null values', () {
      const sv = StateVector(
        restingHR: null,
        stepCount: null,
        activityLevel: null,
        rpeHistory: [],
        missedSessions: 0,
        streak: 0,
        aqiLevel: AqiLevel.low,
        temperature: null,
        precipitation: null,
        userProfile: UserProfile(
          fitnessLevel: 'low',
          goal: 'wellbeing',
          availableTime: 'long',
          physicalConstraints: 'indoor',
        ),
        currentState: BehavioralState.active,
      );
      expect(sv.restingHR, isNull);
      expect(sv.stepCount, isNull);
      expect(sv.activityLevel, isNull);
    });

    test(
      '5.1-UNIT-007: JSON round-trip — all fields survive serialization',
      () {
        final original = _makeStateVector(
          rpeHistory: [7, 6, 8],
          currentState: BehavioralState.recovering,
          aqiLevel: AqiLevel.high,
        );
        final json = original.toJson();
        final restored = StateVector.fromJson(json);
        expect(restored, equals(original));
      },
    );
  });

  group('BanditState', () {
    test('5.1-UNIT-008: JSON round-trip — arm weights map preserved', () {
      final state = BanditState(
        armWeights: {for (final k in banditArmKeys) k: 1.0},
        updatedAt: DateTime(2026, 4, 12),
      );
      final restored = BanditState.fromJson(state.toJson());
      expect(restored.armWeights, equals(state.armWeights));
      expect(restored.updatedAt, equals(state.updatedAt));
    });

    test(
      '5.1-UNIT-008b: JSON round-trip — UTC DateTime preserves isUtc flag',
      () {
        final state = BanditState(
          armWeights: {'mobility_low': 1.0},
          updatedAt: DateTime.utc(2026, 4, 12, 10, 30),
        );
        final restored = BanditState.fromJson(state.toJson());
        expect(restored.updatedAt, equals(state.updatedAt));
        expect(
          restored.updatedAt.isUtc,
          isTrue,
          reason: 'UTC timestamps must survive round-trip without TZ drift',
        );
      },
    );

    test('5.1-UNIT-009: banditArmKeys has exactly 9 entries', () {
      expect(banditArmKeys, hasLength(9));
      expect(banditArmKeys, contains('mobility_low'));
      expect(banditArmKeys, contains('breathing_high'));
    });

    test('5.1-UNIT-010: copyWith — updatedAt change preserves weights', () {
      final original = BanditState(
        armWeights: {'mobility_low': 1.5, 'cardio_medium': 0.8},
        updatedAt: DateTime(2026, 1, 1),
      );
      final updated = original.copyWith(updatedAt: DateTime(2026, 4, 12));
      expect(updated.armWeights, equals(original.armWeights));
      expect(updated.updatedAt, equals(DateTime(2026, 4, 12)));
    });
  });

  group('SafetyConstraints', () {
    test(
      '5.1-UNIT-011: noConstraints — null maxIntensity, outdoorAllowed true',
      () {
        expect(noConstraints.maxIntensity, isNull);
        expect(noConstraints.outdoorAllowed, isTrue);
        expect(noConstraints.maxSessionCount, equals(3));
      },
    );

    test(
      '5.1-UNIT-012: JSON round-trip — null maxIntensity handled correctly',
      () {
        const sc = SafetyConstraints(
          maxIntensity: null,
          maxSessionCount: 3,
          outdoorAllowed: true,
        );
        final restored = SafetyConstraints.fromJson(sc.toJson());
        expect(restored.maxIntensity, isNull);
        expect(restored.outdoorAllowed, isTrue);
      },
    );

    test('5.1-UNIT-013: maxIntensity low — survives JSON round-trip', () {
      const sc = SafetyConstraints(
        maxIntensity: SessionIntensity.low,
        maxSessionCount: 2,
        outdoorAllowed: false,
      );
      final restored = SafetyConstraints.fromJson(sc.toJson());
      expect(restored.maxIntensity, equals(SessionIntensity.low));
      expect(restored.maxSessionCount, equals(2));
      expect(restored.outdoorAllowed, isFalse);
    });
  });

  group('DailyPlan and PlannedSession', () {
    test(
      '5.1-UNIT-014: DailyPlan JSON round-trip — nested sessions preserved',
      () {
        final plan = DailyPlan(
          planDate: '2026-04-12',
          sessions: [
            const PlannedSession(
              sessionType: 'mobility',
              intensity: 3,
              durationMinutes: 20,
              isIndoor: false,
            ),
            const PlannedSession(
              sessionType: 'breathing',
              intensity: 2,
              durationMinutes: 10,
              isIndoor: true,
              explanation: 'Recovery day. Light breathing session.',
            ),
          ],
          generatedAt: DateTime(2026, 4, 12, 8, 0),
        );
        final restored = DailyPlan.fromJson(plan.toJson());
        expect(restored.planDate, equals('2026-04-12'));
        expect(restored.sessions, hasLength(2));
        expect(
          restored.sessions[1].explanation,
          equals('Recovery day. Light breathing session.'),
        );
      },
    );

    test(
      '5.1-UNIT-015: PlannedSession explanation defaults to empty string',
      () {
        const session = PlannedSession(
          sessionType: 'cardio',
          intensity: 5,
          durationMinutes: 30,
          isIndoor: false,
        );
        expect(session.explanation, equals(''));
      },
    );
  });

  group('Explanation', () {
    test('5.1-UNIT-016: JSON round-trip — sessionIndex and text preserved', () {
      const ex = Explanation(
        sessionIndex: 0,
        text: 'High steps today. Cardio session.',
      );
      final restored = Explanation.fromJson(ex.toJson());
      expect(restored.sessionIndex, equals(0));
      expect(restored.text, equals('High steps today. Cardio session.'));
    });
  });
}
