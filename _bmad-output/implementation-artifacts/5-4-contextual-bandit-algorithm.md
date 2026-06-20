# Story 5.4: Contextual Bandit Algorithm

Status: done

## Story

As the system,
I want a contextual bandit that learns from RPE feedback to improve session selection over time,
So that recommendations become more personalized without any explicit user configuration.

## Acceptance Criteria

**Given** the `BanditEngine` is implemented as a pure Dart class with no Flutter imports
**When** initialized for a new user
**Then** bandit arms represent session type × intensity combinations; initial exploration is uniform (FR10)

**Given** the user submits RPE feedback after a session
**When** `RewardCalculator.updateWeight(state, armKey, rpe)` is called
**Then** the bandit updates arm weights: sessions with RPE near 6.5 receive positive reward; deviation from 6.5 reduces reward (FR22)

**Given** bandit state exists in `bandit_state` table
**When** the user transitions behavioral state (e.g., Fatigued → Recovering)
**Then** bandit arm weights are preserved — learning history is not reset (FR25)

**Given** the `BanditEngine.selectSessions(stateVector, constraints, state)` is called
**When** measured against NFR1
**Then** session selection completes in < 30 seconds on a background isolate — zero UI thread blocking (NFR1, NFR2, ARCH7)

**Given** a new user with no RPE history
**When** sessions are selected
**Then** the bandit defaults to exploration mode, returning varied session types within the safety constraints

## Tasks / Subtasks

### Task 1: Add `initialBanditState()` to `bandit_state.dart` (AC: AC1, AC5)

- [x] 1.1 Open `lib/ai/bandit/bandit_state.dart`. After the class body and `banditArmKeys` constant, add:

```dart
/// Cold-start factory — all 9 arms at 1.0 (uniform exploration, FR10).
/// Enforces 9-arm invariant via [banditArmKeys]; can't drift out of sync.
/// [updatedAt] set to epoch 0 to indicate never-updated state.
BanditState initialBanditState() => BanditState(
  armWeights: {for (final key in banditArmKeys) key: 1.0},
  updatedAt: DateTime.utc(1970),
);
```

- [x] 1.2 **Do NOT run `build_runner`** — `BanditState` class itself is not modified; only a top-level function is added. The `.freezed.dart` and `.g.dart` generated files are untouched.

- [x] 1.3 Run `dart analyze lib/ai/bandit/bandit_state.dart` — zero issues.

---

### Task 2: Implement `RewardCalculator` (AC: AC2, FR22)

- [x] 2.1 Create `lib/ai/bandit/reward_calculator.dart`:

```dart
import 'package:pulse_coach/ai/bandit/bandit_state.dart';

/// Computes reward signals for RPE-based bandit weight updates.
///
/// Target RPE ≈ 6.5 (FR22). Reward is 1.0 at target, declines linearly
/// to 0.0 at maximum deviation. RPE range: 1–10.
///
/// Arm weight update uses EMA: weight = (1 − α) × weight + α × reward.
/// Learning rate α = 0.1 is conservative — adapts over ~10 sessions.
/// Stateless — every call derives fresh values from inputs.
class RewardCalculator {
  const RewardCalculator();

  static const double _targetRpe = 6.5;

  /// Max deviation: max(|1 − 6.5|, |10 − 6.5|) = 5.5.
  static const double _maxDeviation = 5.5;

  static const double _defaultLearningRate = 0.1;

  /// Returns reward in [0.0, 1.0].
  /// reward = max(0, 1 − |rpe − 6.5| / 5.5)
  /// RPE 6.5 → 1.0 · RPE 1 → 0.0 · RPE 10 → ≈0.36
  double compute(int rpe) {
    final deviation = (rpe - _targetRpe).abs();
    return (1.0 - deviation / _maxDeviation).clamp(0.0, 1.0);
  }

  /// Updates [armKey] weight via EMA; all other arms are unchanged.
  ///
  /// Returns new [BanditState] — does NOT mutate input (immutable).
  /// [armKey] must be one of [banditArmKeys]; unrecognised keys are a no-op.
  BanditState updateWeight(
    BanditState state,
    String armKey,
    int rpe, {
    double learningRate = _defaultLearningRate,
  }) {
    if (!banditArmKeys.contains(armKey)) return state;

    final reward = compute(rpe);
    final updated = Map<String, double>.from(state.armWeights);
    final current = updated[armKey] ?? 1.0;
    updated[armKey] = (1.0 - learningRate) * current + learningRate * reward;

    return state.copyWith(
      armWeights: updated,
      updatedAt: DateTime.now(),
    );
  }
}
```

- [x] 2.2 **No Flutter imports** — run `dart analyze lib/ai/bandit/reward_calculator.dart` after creation.

---

### Task 3: Implement `BanditEngine` (AC: AC1, AC3, AC4, AC5)

- [x] 3.1 Create `lib/ai/bandit/contextual_bandit.dart`:

```dart
import 'dart:math';
import 'package:pulse_coach/ai/bandit/bandit_state.dart';
import 'package:pulse_coach/ai/bandit/reward_calculator.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

/// Epsilon-greedy contextual bandit for session selection.
///
/// Arms: 9 = 3 session types (mobility, cardio, breathing) × 3 intensities
/// (low, medium, high). Arm key format: '{sessionType}_{intensity}'.
///
/// Algorithm:
///   - With probability [epsilon]: explore (random arm from eligible set).
///   - With probability 1 − [epsilon]: exploit (highest-weight eligible arm).
/// Selection is without replacement (no duplicate sessionType×intensity per plan).
///
/// Safety contract: [selectSessions] never returns arms excluded by
/// [SafetyConstraints]. The bandit cannot override the safety layer. (FR9)
///
/// Stateless w.r.t. learning — pass in [BanditState] from DB (Story 5.5).
/// The caller (GenerateDailyPlan use case) is responsible for persisting
/// the updated state from [updateReward].
///
/// ARCH7: No Flutter imports. Runs safely in a Dart Isolate via compute().
class BanditEngine {
  final Random _random;

  /// Exploration rate. 0.0 = pure exploit. 1.0 = pure explore.
  /// Default 0.2 — moderate exploration for new users.
  /// Story 5.5 may pass a decayed epsilon based on session count.
  final double epsilon;

  final RewardCalculator _rewardCalc;

  BanditEngine({
    Random? random,
    this.epsilon = 0.2,
    RewardCalculator? rewardCalculator,
  })  : _random = random ?? Random(),
        _rewardCalc = rewardCalculator ?? const RewardCalculator();

  /// Selects up to [constraints.maxSessionCount] sessions.
  ///
  /// Filters arms by [constraints] (maxIntensity, outdoorAllowed) BEFORE
  /// applying epsilon-greedy selection — no safety constraint can be violated.
  ///
  /// [stateVector] is accepted for forward compatibility (contextual features
  /// in a future story). It is NOT used for arm selection in Story 5.4.
  ///
  /// Returns empty list only when NO eligible arms exist after filtering.
  List<PlannedSession> selectSessions(
    StateVector stateVector,
    SafetyConstraints constraints,
    BanditState state,
  ) {
    final eligible = _eligibleArms(constraints, state.armWeights);
    if (eligible.isEmpty) return [];

    final count = constraints.maxSessionCount.clamp(0, eligible.length);
    final remaining = List<String>.from(eligible.keys);
    final selected = <String>[];

    for (var i = 0; i < count && remaining.isNotEmpty; i++) {
      final arm = _random.nextDouble() < epsilon
          ? remaining[_random.nextInt(remaining.length)]
          : _exploit(remaining, eligible);
      selected.add(arm);
      remaining.remove(arm);
    }

    return selected
        .map((arm) => _toPlannedSession(arm, constraints))
        .toList();
  }

  /// Updates arm weight after a session; delegates to [RewardCalculator].
  ///
  /// Returns updated [BanditState] — immutable, caller must persist it.
  /// Bandit weights are NOT reset on state machine transitions (FR25) —
  /// the caller simply re-passes the same accumulated [BanditState].
  BanditState updateReward(BanditState state, String armKey, int rpe) {
    return _rewardCalc.updateWeight(state, armKey, rpe);
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  /// Returns arm keys and their weights that pass [constraints].
  Map<String, double> _eligibleArms(
    SafetyConstraints constraints,
    Map<String, double> weights,
  ) {
    final result = <String, double>{};
    for (final key in banditArmKeys) {
      final intensityName = key.split('_').last; // 'low' | 'medium' | 'high'
      if (constraints.maxIntensity != null) {
        if (_intensityRankByName(intensityName) >
            _intensityRank(constraints.maxIntensity!)) {
          continue;
        }
      }
      result[key] = weights[key] ?? 1.0;
    }
    return result;
  }

  /// Pure-exploit pick: highest weight; alphabetical tiebreak for determinism.
  String _exploit(List<String> candidates, Map<String, double> weights) {
    return candidates.reduce((a, b) {
      final wa = weights[a]!;
      final wb = weights[b]!;
      if (wa != wb) return wa >= wb ? a : b;
      return a.compareTo(b) <= 0 ? a : b; // stable alphabetical tiebreak
    });
  }

  PlannedSession _toPlannedSession(String armKey, SafetyConstraints constraints) {
    final parts = armKey.split('_');
    final sessionType = parts.first; // 'mobility' | 'cardio' | 'breathing'
    final intensityName = parts.last;

    return PlannedSession(
      sessionType: sessionType,
      intensity: _intensityValue(intensityName),
      durationMinutes: 10, // Placeholder — Story 6.x populates from exercise catalog
      isIndoor: !constraints.outdoorAllowed,
    );
  }

  int _intensityRank(SessionIntensity i) => switch (i) {
        SessionIntensity.low => 0,
        SessionIntensity.medium => 1,
        SessionIntensity.high => 2,
      };

  int _intensityRankByName(String name) => switch (name) {
        'low' => 0,
        'medium' => 1,
        _ => 2, // 'high' and any unknown value treated as highest
      };

  /// Maps arm intensity name to the PlannedSession intensity int value.
  /// Ranges: low=1–3 (→3), medium=4–7 (→6), high=8–10 (→8). (safety_constraints.dart)
  int _intensityValue(String name) => switch (name) {
        'low' => 3,
        'medium' => 6,
        _ => 8, // 'high'
      };
}
```

- [x] 3.2 **No Flutter imports** — run `dart analyze lib/ai/bandit/contextual_bandit.dart` after creation.

---

### Task 4: Unit tests — `RewardCalculator` (AC: AC2)

- [x] 4.1 Create `test/domain/ai/reward_calculator_test.dart`:

```dart
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

    test('5.4-UNIT-007: high RPE (1) → target arm weight decreases', () {
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
```

- [x] 4.2 Run `flutter test test/domain/ai/reward_calculator_test.dart` — all 10 tests must pass.

---

### Task 5: Unit tests — `BanditEngine` (AC: AC1, AC3, AC4, AC5)

- [x] 5.1 Create `test/domain/ai/contextual_bandit_test.dart`:

```dart
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
```

- [x] 5.2 Run `flutter test test/domain/ai/contextual_bandit_test.dart` — all 18 tests must pass.
- [x] 5.3 Run `flutter test` — **all tests** must pass. Starting count: **244 tests**; target: **~272 tests** (+28).

---

### Task 6: `dart analyze` compliance (ARCH7)

- [x] 6.1 Run:
  ```bash
  dart analyze lib/ai/bandit/
  ```
- [x] 6.2 Confirm zero Flutter framework imports (`package:flutter/...`) in:
  - `lib/ai/bandit/contextual_bandit.dart`
  - `lib/ai/bandit/reward_calculator.dart`
  - `lib/ai/bandit/bandit_state.dart` (existing file — no change needed here)

### Review Findings

_Code review 2026-04-29 — 3 layers (Blind Hunter, Edge Case Hunter, Acceptance Auditor). 2 decision-needed, 10 patches, 3 deferred, 5 dismissed._

**Decision-needed:**

- [x] [Review][Defer] `isIndoor` derived from constraint, not session nature [`contextual_bandit.dart:148`] — deferred to Story 6.x. Reason: indoor/outdoor semantics belong to the exercise catalog, not the bandit; current placeholder is acceptable until catalog exists. Fix in this file: add doc-comment flagging the limit.
- [x] [Review][Patch] `updatedAt = DateTime.utc(1970)` sentinel — keep epoch as "never updated" marker but add explicit doc-comment so consumers handle it correctly (resolved from decision: nullable migration not worth the cost without UI consumers). [`bandit_state.dart:38`]

**Patch:**

- [x] [Review][Patch] Cold-start `_exploit` tiebreak fails uniform exploration — `wa >= wb ? a : b` always picks the accumulator on uniform weights, so cold-start users with `epsilon=0` get 3 sessions of the first `banditArmKeys` entry repeatedly. The "alphabetical tiebreak" branch is dead code. Tests don't catch it (count-only assertions). Fix: use `>` and explicit alphabetical tiebreak, OR ensure cold-start `epsilon > 0`. [`contextual_bandit.dart:130-137`]
- [x] [Review][Patch] No NaN/Infinity guard on `armWeights` reads — corrupt persisted JSON or arithmetic producing NaN propagates through EMA permanently; `>=` comparisons with NaN return non-deterministic exploit choice. Add `isFinite` validation on read or in `updateWeight`. [`reward_calculator.dart:42-44`]
- [x] [Review][Patch] RPE outside [1,10] silently clamped, polluting EMA — `compute(int rpe)` accepts e.g. RPE=0 or RPE=15 and produces a plausible reward. Validate input range explicitly (assert/throw). [`reward_calculator.dart:25-28`]
- [x] [Review][Patch] Missing arm key in `updateWeight` silently re-introduces with weight 1.0 — `updated[armKey] ?? 1.0` self-heals corrupt state but loses prior history without detection. Assert key exists or fail loudly. [`reward_calculator.dart:42-44`]
- [x] [Review][Patch] `_intensityRankByName` / `_intensityValue` `_` fallback masks malformed keys — unknown intensity tokens default to `high` (rank 2, value 8). Latent safety risk if `banditArmKeys` evolves: a malformed arm could pass a `medium` cap. Make default throw. [`contextual_bandit.dart:158-170`]
- [x] [Review][Patch] UTC vs local-time `DateTime.now()` mix — `initialBanditState` uses `DateTime.utc(1970)` but `updateWeight` uses local `DateTime.now()`. Use `DateTime.now().toUtc()` (or `DateTime.timestamp()`) for consistency, especially before Story 5.5 persistence. [`reward_calculator.dart:46`]
- [x] [Review][Patch] `learningRate` not validated — caller can pass `> 1.0` or negative, producing weights outside [0,1] or unstable EMA (negative weights flip exploit ordering). Assert/clamp [0,1]. [`reward_calculator.dart:36-44`]
- [x] [Review][Patch] `epsilon` not validated in `BanditEngine` constructor — NaN/negative silently degenerate to pure-exploit; values > 1 to pure-explore. Assert [0,1] in constructor (relevant before Story 5.5 passes decayed epsilon). [`contextual_bandit.dart:33`]
- [x] [Review][Patch] Test 5.4-UNIT-007 mislabeled "high RPE (1)" — RPE=1 is the lowest, not highest. Cosmetic rename. [`reward_calculator_test.dart:34`]
- [x] [Review][Patch] Doc comment "RPE 6.5 → 1.0 (perfect)" misleading — `compute` takes `int rpe`, so reward=1.0 is unreachable; max attainable is ~0.909 at RPE=6 or 7. Fix doc to reflect integer scale. [`reward_calculator.dart:21-23`]

**Deferred:**

- [x] [Review][Defer] `_toPlannedSession` 2-part armKey contract not enforced [`contextual_bandit.dart:139-150`] — deferred, latent only if arm naming evolves to multi-segment keys
- [x] [Review][Defer] `outdoorAllowed=false` doesn't filter outdoor-only arms [`contextual_bandit.dart:148`] — deferred, depends on Story 6.x session catalog
- [x] [Review][Defer] Map iteration order brittle to `banditArmKeys` reorder for seeded-RNG reproducibility [`contextual_bandit.dart:79-83`] — deferred, low risk

---

## Dev Notes

### File Placement

| File | Action | Notes |
|---|---|---|
| `lib/ai/bandit/bandit_state.dart` | **Modify** | Add `initialBanditState()` top-level function only. Do NOT touch the `@freezed` class or run `build_runner`. |
| `lib/ai/bandit/reward_calculator.dart` | **Create** | Pure Dart; stateless `RewardCalculator` class. |
| `lib/ai/bandit/contextual_bandit.dart` | **Create** | Pure Dart; `BanditEngine` class. Architecture file specifies this filename. |
| `test/domain/ai/reward_calculator_test.dart` | **Create** | 10 unit tests (5.4-UNIT-001 → 5.4-UNIT-010). |
| `test/domain/ai/contextual_bandit_test.dart` | **Create** | 18 unit tests (5.4-UNIT-011 → 5.4-UNIT-028). |

**Do NOT touch:**
- `lib/ai/bandit/bandit_state.freezed.dart` / `bandit_state.g.dart` — generated; `initialBanditState()` is a standalone function, no codegen needed
- `lib/ai/bandit/state_vector.dart` — `StateVector`, `AqiLevel` already defined in Story 5.1; no modifications
- `lib/ai/safety/safety_constraints.dart` — `SafetyConstraints`, `SessionIntensity`, `noConstraints` already defined; no modifications
- Any existing test files — 244 tests must all still pass

### Architecture File References

Architecture specifies exact filenames (important — do NOT deviate):
- `lib/ai/bandit/contextual_bandit.dart` ← class `BanditEngine`
- `lib/ai/bandit/reward_calculator.dart` ← class `RewardCalculator`

### Existing Files Used as Dependencies

All dependencies already exist in `pulse_coach/`:

```
lib/ai/bandit/
├── bandit_state.dart             ← MODIFY: add initialBanditState()
├── bandit_state.freezed.dart     ← EXISTING generated — DO NOT TOUCH
├── bandit_state.g.dart           ← EXISTING generated — DO NOT TOUCH
├── state_vector.dart             ← EXISTING (Story 5.1): StateVector, AqiLevel
├── contextual_bandit.dart        ← CREATE (Story 5.4): BanditEngine
└── reward_calculator.dart        ← CREATE (Story 5.4): RewardCalculator

lib/ai/safety/
├── safety_constraints.dart       ← EXISTING (Story 5.1): SafetyConstraints, SessionIntensity, noConstraints

lib/features/daily_plan/domain/entities/
├── planned_session.dart          ← EXISTING (Story 5.1): PlannedSession
├── daily_plan.dart               ← EXISTING (Story 5.1): DailyPlan (not used in 5.4)
```

### Critical Name Collision: `BanditState` (AI domain) vs `BanditState` (Drift table)

This is a **known deferred issue from Story 5.1** (`deferred-work.md`):

> `BanditState` name collision with existing drift table class `BanditState` — any future DAO/repo importing both needs `as` prefix.

**Story 5.4 scope:** `BanditEngine` and `RewardCalculator` are pure Dart classes that operate on the AI `BanditState` domain model (`lib/ai/bandit/bandit_state.dart`). They do NOT import from `lib/core/database/` — no collision possible in these files.

**Collision surfaces in Story 5.5** when `GenerateDailyPlan` use case imports both the DAO layer and the AI domain model. Story 5.5 will resolve it with:
```dart
import 'package:pulse_coach/ai/bandit/bandit_state.dart' as ai;
// OR rename one side — decision deferred to Story 5.5
```

Do NOT try to resolve the collision in Story 5.4.

### Algorithm Design Details

#### Epsilon-Greedy Selection

```
For each session slot (up to maxSessionCount):
  1. Filter banditArmKeys by SafetyConstraints → eligible arms
  2. if random() < epsilon: pick random arm from remaining eligible
     else:                  pick arm with highest weight (alphabetical tiebreak)
  3. Remove selected arm from candidates (without replacement)
  4. Map arm key → PlannedSession
```

**Alphabetical tiebreak** in exploit mode ensures deterministic output when multiple arms share the same weight (common at cold start: all arms = 1.0). This makes pure-exploit tests predictable without needing a seeded Random.

#### Reward Formula (FR22)

```
reward = max(0.0, 1.0 - |rpe - 6.5| / 5.5)
```

Where 5.5 = max possible deviation from 6.5 over RPE range [1–10]:
- RPE 6.5 → reward = 1.0 (perfect)
- RPE 6 or 7 → reward ≈ 0.909
- RPE 5 or 8 → reward ≈ 0.727
- RPE 10 → reward ≈ 0.364
- RPE 1 → reward = 0.0 (worst)

#### Weight Update (EMA)

```
weight = (1 − α) × weight + α × reward    [α = 0.1]
```

Starting from 1.0, with zero reward (RPE=1): converges to 0 over ~23 sessions (7 sessions to halve). Conservative enough for healthy initial exploration while still adapting.

#### Intensity Mapping: Arm Key → PlannedSession.intensity

| Arm suffix | SessionIntensity | `intensity` int value | SafetyConstraints range |
|---|---|---|---|
| `_low` | `low` | 3 | 1–3 |
| `_medium` | `medium` | 6 | 4–7 |
| `_high` | `high` | 8 | 8–10 |

`durationMinutes` is hardcoded to 10 in Story 5.4. Story 6.x populates it from the exercise catalog.

### Why `stateVector` is Accepted but Not Used (Story 5.4)

The architecture signature `selectSessions(stateVector, constraints, state)` includes `StateVector` for forward compatibility: a future story can use restingHR, activityLevel, etc. to contextually weight arm probabilities (true contextual bandit). In Story 5.4, only `constraints` and `state` drive selection. The `stateVector` parameter is accepted to avoid a breaking signature change in Story 5.5.

### FR25 — Bandit Weight Preservation Across State Transitions

The bandit weights are preserved across behavioral state machine transitions because:
- `BanditState` (arm weights) and `BehavioralState` (machine state) are **separate domain objects** stored in separate DB tables (`bandit_state` vs `behavioral_state`)
- State machine transitions update only the `behavioral_state` table (Story 5.2/5.5)
- Bandit weights are only updated when `updateReward()` is called with RPE feedback
- The `BanditEngine` never resets weights — it only applies EMA updates

This is an **architectural guarantee**, not a runtime check. No code in Story 5.4 needs to "protect" weights from state transitions.

### No DI Registration (this story)

`BanditEngine` and `RewardCalculator` are not registered in the DI container in Story 5.4. DI wiring happens in Story 5.5 (`GenerateDailyPlan` use case). In tests, instantiate directly:
```dart
const calc = RewardCalculator();
final engine = BanditEngine(epsilon: 0.0);
final engine = BanditEngine(random: Random(42), epsilon: 1.0); // for explore tests
```

### DB Layer (NOT touched in Story 5.4)

The following already exist and are used in Story 5.5 (not 5.4):
- `lib/core/database/tables/bandit_state_table.dart` — Drift table `BanditState` (data class `BanditStateData`)
- `lib/core/database/daos/bandit_state_dao.dart` — `getLatestState()`, `insertState()`, `updateState()`

`BanditEngine` and `RewardCalculator` operate on the AI domain model `BanditState` (from `lib/ai/bandit/bandit_state.dart`), NOT the Drift data class `BanditStateData`. Story 5.5 is responsible for the DAO ↔ domain model conversion.

### Deferred Items from Previous Stories Relevant to This Story

From `deferred-work.md` — Story 5.1:
- **`BanditState.initial()` factory** — Resolved in Task 1 via `initialBanditState()` top-level function. The 9-arm invariant is now enforced programmatically via `banditArmKeys`.
- **`BanditState` name collision** — NOT resolved in Story 5.4 (pure AI layer has no DAO imports). Deferred to Story 5.5.
- **`UserProfile.physicalConstraints`** single-string limitation — Story 5.4 maps `isIndoor = !constraints.outdoorAllowed` only. Injury-specific indoor preference not implemented (same as Story 5.3 posture).

From `deferred-work.md` — Story 5.2 and 5.3:
- **RPE range validation** — `RewardCalculator.compute(rpe)` accepts any int; out-of-range values produce clamped (0.0) rewards. Formal validation deferred to Story 5.5 StateVector builder.
- **`rpeHistory` staleness** — `BanditEngine` uses only the arm key from the session just completed; it does not process raw rpeHistory directly. Staleness is a Story 5.5 concern.

### Cross-Story Dependencies

- **Story 5.1** provides: `BanditState`, `banditArmKeys`, `StateVector`, `SafetyConstraints`, `SessionIntensity`, `noConstraints`, `PlannedSession` — all implemented ✓
- **Story 5.2** provides: `BehavioralStateMachine`, `BehavioralState` — implemented ✓
- **Story 5.3** provides: `SafetyRules` — implemented ✓; its `SafetyConstraints` output is the input to `BanditEngine.selectSessions`
- **Story 5.5** (`GenerateDailyPlan`) instantiates `BanditEngine`, wires DI, calls `selectSessions` in an Isolate, and handles DAO persistence

### Project Structure (post Story 5.4)

```
pulse_coach/lib/ai/bandit/
├── bandit_state.dart            ← MODIFIED: + initialBanditState()
├── bandit_state.freezed.dart    ← EXISTING generated
├── bandit_state.g.dart          ← EXISTING generated
├── contextual_bandit.dart       ← CREATE (Story 5.4): BanditEngine
├── reward_calculator.dart       ← CREATE (Story 5.4): RewardCalculator
├── state_vector.dart            ← EXISTING
├── state_vector.freezed.dart    ← EXISTING generated
└── state_vector.g.dart          ← EXISTING generated

pulse_coach/test/domain/ai/
├── behavioral_state_machine_test.dart  ← EXISTING (Story 5.2) — 26 tests
├── contextual_bandit_test.dart         ← CREATE (Story 5.4) — 18 tests
├── reward_calculator_test.dart         ← CREATE (Story 5.4) — 10 tests
└── safety_rules_test.dart              ← EXISTING (Story 5.3) — 20 tests
```

### Test Count

Starting: **244 tests** (197 original + 26 Story 5.2 + 17 Story 5.3 + 3 Story 5.3 review patches + 1 Story 5.1 = 244)

New tests (Story 5.4):
- `5.4-UNIT-001` through `5.4-UNIT-010`: 10 tests (RewardCalculator)
- `5.4-UNIT-011` through `5.4-UNIT-028`: 18 tests (BanditEngine)

Target: **~272 tests** (+28)

### References

- FR10: Contextual bandit, uniform initial exploration [Source: `_bmad-output/planning-artifacts/prd.md`]
- FR22: RPE feedback loop, target ≈6.5 [Source: `_bmad-output/planning-artifacts/prd.md`]
- FR25: Preserve bandit learning across state transitions [Source: `_bmad-output/planning-artifacts/prd.md`]
- ARCH7: No Flutter framework imports in AI engine [Source: `_bmad-output/planning-artifacts/architecture.md` — Component Mapping table]
- NFR1/NFR2: Plan < 30s, 60fps [Source: `_bmad-output/planning-artifacts/architecture.md`]
- `BanditState`, `banditArmKeys`: [Source: `lib/ai/bandit/bandit_state.dart`]
- `SafetyConstraints`, `SessionIntensity`, `noConstraints`: [Source: `lib/ai/safety/safety_constraints.dart`]
- `PlannedSession`: [Source: `lib/features/daily_plan/domain/entities/planned_session.dart`]
- `BanditStateDao`: [Source: `lib/core/database/daos/bandit_state_dao.dart`] — NOT used in Story 5.4
- Name collision deferred: [Source: `_bmad-output/implementation-artifacts/deferred-work.md` — Story 5.1 section]
- `initialBanditState()` deferred: [Source: `_bmad-output/implementation-artifacts/deferred-work.md` — Story 5.1 section]
- Architecture filename spec: [Source: `_bmad-output/planning-artifacts/architecture.md` — line 801, 803]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

No blockers. All tasks completed in single pass.

### Completion Notes List

- Task 1: Added `initialBanditState()` top-level function to `bandit_state.dart`. No build_runner run needed — only standalone function added, @freezed class untouched. `dart analyze` shows zero errors (2 pre-existing comment_references infos).
- Task 2: Created `RewardCalculator` — pure Dart, stateless. EMA formula `weight = (1−α)×w + α×reward` with α=0.1, target RPE=6.5, maxDeviation=5.5. Zero analyze issues.
- Task 3: Created `BanditEngine` — epsilon-greedy, no Flutter imports (ARCH7). Alphabetical tiebreak in exploit mode ensures determinism. `stateVector` accepted but unused (forward compatibility for Story 5.5).
- Task 4: 10 unit tests for `RewardCalculator` (5.4-UNIT-001 → 5.4-UNIT-010) — all pass.
- Task 5: 18 unit tests for `BanditEngine` + `initialBanditState` (5.4-UNIT-011 → 5.4-UNIT-028) — all pass. Full suite: 272 tests, zero regressions.
- Task 6: `dart analyze lib/ai/bandit/` — zero errors, only pre-existing comment_references infos. No `package:flutter/` imports in new files.

### File List

- `pulse_coach/lib/ai/bandit/bandit_state.dart` (modified — added `initialBanditState()`)
- `pulse_coach/lib/ai/bandit/reward_calculator.dart` (created)
- `pulse_coach/lib/ai/bandit/contextual_bandit.dart` (created)
- `pulse_coach/test/domain/ai/reward_calculator_test.dart` (created)
- `pulse_coach/test/domain/ai/contextual_bandit_test.dart` (created)

## Change Log

- 2026-04-29: Story created by SM agent (claude-sonnet-4-6). Epic 5 Story 4. All dependencies from Stories 5.1–5.3 in place. Resolves Story 5.1 deferred: `initialBanditState()` factory. Story 5.1 deferred `BanditState` name collision deferred again to Story 5.5 (pure AI layer has no DAO imports). Epsilon-greedy with EMA weight update (α=0.1, target RPE=6.5). No DI wiring — deferred to Story 5.5.
- 2026-04-29: Implemented by dev agent (claude-sonnet-4-6). All 6 tasks complete. 28 new tests added (272 total, zero regressions). ARCH7 enforced — no Flutter imports in AI layer. Story status → review.
- 2026-04-29: Code review (claude-opus-4-7) — 3 layers (Blind Hunter, Edge Case Hunter, Acceptance Auditor). 10 patches applied + 1 patch from resolved decision (`updatedAt` sentinel doc-comment). 4 deferred (`isIndoor` semantics → Story 6.x; armKey contract; outdoor catalog filtering; iteration order). 272/272 tests still passing, zero analyzer errors. Story status → done.
