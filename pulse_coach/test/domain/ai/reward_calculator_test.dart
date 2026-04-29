import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/bandit_state.dart';
import 'package:pulse_coach/ai/bandit/reward_calculator.dart';

void main() {
  const calc = RewardCalculator();

  // ── Reward computation ─────────────────────────────────────────────────────

  group('RewardCalculator.compute (FR22 — target RPE ≈ 6.5)', () {
    test('5.4-UNIT-001: RPE 6 → high reward (near target from below)', () {
      expect(calc.compute(6), closeTo(0.909, 0.001));
    });

    test('5.4-UNIT-002: RPE 7 → high reward (near target from above)', () {
      expect(calc.compute(7), closeTo(0.909, 0.001));
    });

    test('5.4-UNIT-003: RPE 1 → reward = 0.0 (maximum deviation, low end)', () {
      expect(calc.compute(1), closeTo(0.0, 0.001));
    });

    test('5.4-UNIT-004: RPE 10 → reward ≈ 0.364 (less deviation than RPE 1)', () {
      // |10 - 6.5| = 3.5; 1 - 3.5/5.5 ≈ 0.364
      expect(calc.compute(10), closeTo(0.364, 0.001));
    });

    test('5.4-UNIT-005: RPE 5 → moderate reward', () {
      // |5 - 6.5| = 1.5; 1 - 1.5/5.5 ≈ 0.727
      expect(calc.compute(5), closeTo(0.727, 0.001));
    });

    test('5.4-UNIT-006: RPE 8 → moderate reward', () {
      // |8 - 6.5| = 1.5; same as RPE 5 by symmetry around 6.5
      expect(calc.compute(8), closeTo(0.727, 0.001));
    });
  });

  // ── Weight update ──────────────────────────────────────────────────────────

  group('RewardCalculator.updateWeight (EMA with α=0.1)', () {
    BanditState baseState() => initialBanditState();

    test('5.4-UNIT-007: low RPE (1) → target arm weight decreases', () {
      final updated = calc.updateWeight(baseState(), 'cardio_high', 1);
      // weight = 0.9 * 1.0 + 0.1 * 0.0 = 0.9
      expect(updated.armWeights['cardio_high'], closeTo(0.9, 0.001));
    });

    test('5.4-UNIT-008: RPE near target (7) → target arm weight near 1.0', () {
      final updated = calc.updateWeight(baseState(), 'cardio_medium', 7);
      // weight = 0.9 * 1.0 + 0.1 * 0.909 ≈ 0.991
      expect(updated.armWeights['cardio_medium']!, greaterThan(0.98));
    });

    test('5.4-UNIT-009: updateWeight preserves all other arm weights', () {
      final updated = calc.updateWeight(baseState(), 'mobility_low', 1);
      for (final key in banditArmKeys) {
        if (key != 'mobility_low') {
          expect(updated.armWeights[key], equals(1.0),
              reason: '$key should be unchanged');
        }
      }
    });

    test('5.4-UNIT-010: unknown arm key → state returned unchanged', () {
      final state = baseState();
      final updated = calc.updateWeight(state, 'unknown_arm', 6);
      expect(updated.armWeights, equals(state.armWeights));
    });
  });
}
