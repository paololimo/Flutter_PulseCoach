import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/bandit_state.dart' as ai_bandit;
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/engine/ai_engine.dart';
import 'package:pulse_coach/ai/engine/ai_engine_isolate.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

// Fixtures
StateVector _sv({
  BehavioralState state = BehavioralState.active,
  List<int> rpeHistory = const [],
  int missedSessions = 0,
  int streak = 0,
}) => StateVector(
  restingHR: 65.0,
  stepCount: 4000,
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

ai_bandit.BanditState _uniform() => ai_bandit.initialBanditState();

void main() {
  final engine = AiEngineIsolate();

  group('AiEngineIsolate — isolate execution (AC1, ARCH7)', () {
    test('5.5-UNIT-001: returns AiEngineOutput without blocking', () async {
      final output = await engine.call(
        AiEngineInput(stateVector: _sv(), banditState: _uniform()),
      );
      expect(output, isA<AiEngineOutput>());
    });

    test('5.5-UNIT-002: output.plan is a non-null DailyPlan', () async {
      final output = await engine.call(
        AiEngineInput(stateVector: _sv(), banditState: _uniform()),
      );
      expect(output.plan.sessions, isNotEmpty);
    });

    test(
      '5.5-UNIT-003: output.plan.planDate is today in YYYY-MM-DD format',
      () async {
        final output = await engine.call(
          AiEngineInput(stateVector: _sv(), banditState: _uniform()),
        );
        final today = DateTime.now();
        final expected =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        expect(output.plan.planDate, equals(expected));
      },
    );

    test(
      '5.5-UNIT-004: output includes newBehavioralState (state machine evaluated)',
      () async {
        final output = await engine.call(
          AiEngineInput(stateVector: _sv(), banditState: _uniform()),
        );
        expect(output.newBehavioralState, isA<BehavioralState>());
      },
    );
  });

  group('AiEngineIsolate — pipeline correctness (AC2)', () {
    test(
      '5.5-UNIT-005: active state + no constraints → up to 3 sessions',
      () async {
        final output = await engine.call(
          AiEngineInput(stateVector: _sv(), banditState: _uniform()),
        );
        expect(output.plan.sessions.length, lessThanOrEqualTo(3));
        expect(output.plan.sessions.length, greaterThanOrEqualTo(1));
      },
    );

    test(
      '5.5-UNIT-006: fatigued state → state machine transitions toward atRisk or recovering',
      () async {
        final sv = _sv(state: BehavioralState.fatigued, missedSessions: 3);
        final output = await engine.call(
          AiEngineInput(stateVector: sv, banditState: _uniform()),
        );
        // fatigued + missed>=2 → atRisk (Rule 1 in BehavioralStateMachine)
        expect(output.newBehavioralState, equals(BehavioralState.atRisk));
      },
    );

    test(
      '5.5-UNIT-007: high RPE history → safety rules cap intensity (FR9)',
      () async {
        final sv = _sv(rpeHistory: [9, 9, 9, 9, 9]);
        final output = await engine.call(
          AiEngineInput(stateVector: sv, banditState: _uniform()),
        );
        // RPE avg > 8 → maxIntensity = medium → intensity ≤ 6
        for (final session in output.plan.sessions) {
          expect(session.intensity, lessThanOrEqualTo(6));
        }
      },
    );

    test('5.5-UNIT-008: high AQI → all sessions indoor', () async {
      const sv = StateVector(
        restingHR: null,
        stepCount: null,
        activityLevel: null,
        rpeHistory: [],
        missedSessions: 0,
        streak: 0,
        aqiLevel: AqiLevel.high,
        temperature: null,
        precipitation: null,
        userProfile: UserProfile(
          fitnessLevel: 'medium',
          goal: 'cardio',
          availableTime: 'short',
          physicalConstraints: 'none',
        ),
        currentState: BehavioralState.active,
      );
      final output = await engine.call(
        AiEngineInput(stateVector: sv, banditState: _uniform()),
      );
      for (final session in output.plan.sessions) {
        expect(session.isIndoor, isTrue);
      }
    });

    test(
      '5.6-UNIT-001: all sessions have non-empty explanation after Story 5.6 (AC4)',
      () async {
        final output = await engine.call(
          AiEngineInput(stateVector: _sv(), banditState: _uniform()),
        );
        for (final session in output.plan.sessions) {
          expect(session.explanation, isNotEmpty);
        }
      },
    );
  });
}
