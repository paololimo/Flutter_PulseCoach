# Story 5.2: Behavioral State Machine

Status: done

## Story

As the system,
I want a deterministic behavioral state machine that tracks and transitions user state,
so that the AI engine has context about the user's current capacity before generating a plan.

## Acceptance Criteria

**Given** the `BehavioralStateMachine` is implemented as a pure Dart class
**When** `StateVector` shows RPE avg > 8 for last 2 sessions
**Then** the machine transitions to `fatigued` state (FR23)

**Given** state is `fatigued` and `missedSessions >= 2`
**When** the machine evaluates
**Then** it transitions to `atRisk` state (FR23)

**Given** state is `atRisk` or `fatigued`
**When** user completes 2 consecutive sessions with RPE ≤ 7
**Then** state transitions to `recovering` (FR23)

**Given** state is `recovering` and user completes 3 sessions with RPE avg ≤ 6.5 and streak ≥ 3
**When** the machine evaluates
**Then** state transitions back to `active` (FR23)

**Given** any state transition occurs
**When** the transition is written to the `behavioral_state` table
**Then** a human-readable transition message is returned (e.g., "You've been pushing hard. Taking it easier today.") (FR14)

**Given** the state is `recovering` or `atRisk`
**When** the safety constraint is queried from the machine
**Then** `maxIntensity` is `SessionIntensity.low` and `maxSessionCount` is 2 (FR24)

## Tasks / Subtasks

### Task 1: Implement `BehavioralTransition` value type (AC: all)

- [x] 1.1 Create `lib/ai/state_machine/behavioral_transition.dart`:
  ```dart
  import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';

  /// Result of a BehavioralStateMachine evaluation.
  ///
  /// [newState] is the computed next state (may equal previous if no transition occurred).
  /// [transitionMessage] is non-null only when state CHANGED from previous.
  ///   Used by DailyPlanGenerationPipeline (Story 5.5) to surface FR14 messages on
  ///   the Today screen and pass to ExplanationGenerator (Story 5.6).
  class BehavioralTransition {
    final BehavioralState newState;
    final String? transitionMessage;

    const BehavioralTransition({
      required this.newState,
      this.transitionMessage,
    });

    bool get stateChanged => transitionMessage != null;
  }
  ```

- [x] **No Flutter imports** — pure Dart value type.

---

### Task 2: Implement `BehavioralStateMachine` pure Dart class (AC: AC1–AC4)

- [x] 2.1 Create `lib/ai/state_machine/behavioral_state_machine.dart`:
  ```dart
  import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
  import 'package:pulse_coach/ai/state_machine/behavioral_transition.dart';
  import 'package:pulse_coach/ai/bandit/state_vector.dart';
  import 'package:pulse_coach/ai/safety/safety_constraints.dart';

  /// Deterministic state machine that evaluates StateVector and returns the next
  /// BehavioralState + an optional transition message.
  ///
  /// Evaluation order matters — higher-priority transitions are checked first:
  ///   1. fatigued → atRisk   (structural risk, checked before active→fatigued)
  ///   2. active → fatigued   (exertion signal)
  ///   3. atRisk/fatigued → recovering  (recovery signal)
  ///   4. recovering → active (full recovery)
  ///   (If no rule fires, current state is returned unchanged.)
  ///
  /// Stateless: every call computes from scratch given the StateVector snapshot.
  /// The CALLER (GenerateDailyPlan use case, Story 5.5) is responsible for
  /// persisting the result via BehavioralStateDao.
  class BehavioralStateMachine {
    const BehavioralStateMachine();

    /// Evaluate [stateVector] and return the resulting [BehavioralTransition].
    BehavioralTransition evaluate(StateVector stateVector) {
      final current = stateVector.currentState;
      final rpe = stateVector.rpeHistory;
      final missed = stateVector.missedSessions;
      final streak = stateVector.streak;

      // Rule 1: fatigued → atRisk
      if (current == BehavioralState.fatigued && missed >= 2) {
        return BehavioralTransition(
          newState: BehavioralState.atRisk,
          transitionMessage:
              'You\'ve been missing sessions. Scaling back to keep you safe.',
        );
      }

      // Rule 2: active → fatigued (needs last 2 RPE values)
      if (current == BehavioralState.active && _lastNAvg(rpe, 2) > 8.0) {
        return BehavioralTransition(
          newState: BehavioralState.fatigued,
          transitionMessage:
              'You\'ve been pushing hard. Taking it easier today.',
        );
      }

      // Rule 3: atRisk/fatigued → recovering (last 2 sessions RPE ≤ 7)
      if ((current == BehavioralState.atRisk ||
              current == BehavioralState.fatigued) &&
          rpe.length >= 2 &&
          rpe[rpe.length - 1] <= 7 &&
          rpe[rpe.length - 2] <= 7) {
        return BehavioralTransition(
          newState: BehavioralState.recovering,
          transitionMessage:
              'Great work staying consistent. Gradually increasing intensity.',
        );
      }

      // Rule 4: recovering → active (3 sessions avg ≤ 6.5, streak ≥ 3)
      if (current == BehavioralState.recovering &&
          streak >= 3 &&
          _lastNAvg(rpe, 3) <= 6.5) {
        return BehavioralTransition(
          newState: BehavioralState.active,
          transitionMessage:
              'You\'re back on track! Ready for your regular routine.',
        );
      }

      // No transition — return current state with no message
      return BehavioralTransition(newState: current);
    }

    /// Returns the safety constraints implied by [state].
    ///
    /// Called by SafetyRules (Story 5.3) — centralises the FR24 mapping here
    /// so both SafetyRules and tests can reference a single source of truth.
    SafetyConstraints constraintsForState(BehavioralState state) {
      switch (state) {
        case BehavioralState.atRisk:
        case BehavioralState.recovering:
          return const SafetyConstraints(
            maxIntensity: SessionIntensity.low,
            maxSessionCount: 2,
            outdoorAllowed: true, // AQI handled separately by SafetyRules
          );
        case BehavioralState.fatigued:
          return const SafetyConstraints(
            maxIntensity: SessionIntensity.medium,
            maxSessionCount: 3,
            outdoorAllowed: true,
          );
        case BehavioralState.active:
          return noConstraints;
      }
    }

    /// Computes the average of the last [n] values in [rpe].
    /// Returns 0.0 if [rpe] has fewer than [n] entries — not enough data to
    /// trigger a transition.
    double _lastNAvg(List<int> rpe, int n) {
      if (rpe.length < n) return 0.0;
      final slice = rpe.sublist(rpe.length - n);
      return slice.reduce((a, b) => a + b) / slice.length;
    }
  }
  ```

- [x] 2.2 **No Flutter imports** — pure Dart class. Run `dart analyze lib/ai/` after creation to verify.
- [x] **`constraintsForState()` is co-located here** rather than in Story 5.3 (`SafetyRules`) to keep FR24 logic with the entity that owns it. `SafetyRules` (Story 5.3) calls this method — see Dev Notes.

---

### Task 3: Write unit tests (AC: all transitions + edge cases)

- [x] 3.1 Create `test/domain/ai/behavioral_state_machine_test.dart`:

```dart
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state_machine.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_transition.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

// ─── Fixture helpers ─────────────────────────────────────────────────────────

StateVector _sv({
  BehavioralState state = BehavioralState.active,
  List<int> rpe = const [],
  int missed = 0,
  int streak = 0,
}) =>
    StateVector(
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
    test('5.2-UNIT-001: stateChanged is false when no message', () {
      const t = BehavioralTransition(newState: BehavioralState.active);
      expect(t.stateChanged, isFalse);
      expect(t.transitionMessage, isNull);
    });

    test('5.2-UNIT-002: stateChanged is true when message provided', () {
      const t = BehavioralTransition(
        newState: BehavioralState.fatigued,
        transitionMessage: 'Pushing hard.',
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
      expect(result.transitionMessage, isNotNull);
      expect(result.stateChanged, isTrue);
    });

    test('5.2-UNIT-004: fires exactly at boundary (9, 8) avg = 8.5 > 8', () {
      final sv = _sv(state: BehavioralState.active, rpe: [9, 8]);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.fatigued));
    });

    test('5.2-UNIT-005: does NOT fire when last 2 RPE avg = 8.0 (not > 8)', () {
      final sv = _sv(state: BehavioralState.active, rpe: [8, 8]);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.active));
      expect(result.stateChanged, isFalse);
    });

    test('5.2-UNIT-006: does NOT fire with only 1 RPE entry (insufficient data)', () {
      final sv = _sv(state: BehavioralState.active, rpe: [10]);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.active));
    });

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
      final sv = _sv(state: BehavioralState.fatigued, missed: 1, rpe: [6, 6]);
      final result = machine.evaluate(sv);
      // rpe [6,6] avg = 6 ≤ 8, so active→fatigued rule also won't fire
      // fatigued→atRisk requires missed >= 2 → stays fatigued
      expect(result.newState, equals(BehavioralState.fatigued));
    });
  });

  // ── Transition: atRisk/fatigued → recovering ─────────────────────────────

  group('atRisk/fatigued → recovering', () {
    test('5.2-UNIT-011: fires from atRisk when last 2 RPE both ≤ 7', () {
      final sv = _sv(state: BehavioralState.atRisk, rpe: [5, 9, 6, 7]);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.recovering));
      expect(result.stateChanged, isTrue);
    });

    test('5.2-UNIT-012: fires from fatigued when last 2 RPE both ≤ 7', () {
      // missedSessions=0 to avoid fatigued→atRisk rule firing first
      final sv = _sv(state: BehavioralState.fatigued, rpe: [6, 7], missed: 0);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.recovering));
    });

    test('5.2-UNIT-013: does NOT fire when last RPE = 8 (> 7)', () {
      final sv = _sv(state: BehavioralState.atRisk, rpe: [6, 8]);
      expect(machine.evaluate(sv).newState, equals(BehavioralState.atRisk));
    });

    test('5.2-UNIT-014: does NOT fire with only 1 RPE entry', () {
      final sv = _sv(state: BehavioralState.atRisk, rpe: [5]);
      expect(machine.evaluate(sv).newState, equals(BehavioralState.atRisk));
    });

    test('5.2-UNIT-015: fatigued→atRisk takes priority over fatigued→recovering when missed>=2', () {
      // missed=2 triggers fatigued→atRisk first; recovering rule is NOT checked
      final sv = _sv(
        state: BehavioralState.fatigued,
        rpe: [6, 7],
        missed: 2,
      );
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.atRisk));
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

    test('5.2-UNIT-017: fires at exact boundary avg = 6.5 and streak = 3', () {
      // (6 + 7 + 7) / 3 = 6.666... — does NOT fire (> 6.5)
      // (6 + 7 + 6) / 3 = 6.333... — fires
      final sv = _sv(
        state: BehavioralState.recovering,
        rpe: [6, 7, 6],
        streak: 3,
      );
      expect(machine.evaluate(sv).newState, equals(BehavioralState.active));
    });

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
      final sv = _sv(
        state: BehavioralState.recovering,
        rpe: [6, 6],
        streak: 3,
      );
      expect(machine.evaluate(sv).newState, equals(BehavioralState.recovering));
    });
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

    test('5.2-UNIT-023: active → noConstraints (null maxIntensity, maxSessionCount 3)', () {
      final c = machine.constraintsForState(BehavioralState.active);
      expect(c.maxIntensity, isNull);
      expect(c.maxSessionCount, equals(3));
      expect(c.outdoorAllowed, isTrue);
    });

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
      expect(result.transitionMessage, isNull);
    });

    test('5.2-UNIT-026: atRisk stays atRisk when conditions for recovery not met', () {
      final sv = _sv(state: BehavioralState.atRisk, rpe: [8, 9]);
      expect(machine.evaluate(sv).newState, equals(BehavioralState.atRisk));
    });
  });
}
```

- [x] 3.2 Run `flutter test test/domain/ai/behavioral_state_machine_test.dart` — all 26 tests must pass.
- [x] 3.3 Run `flutter test` — **all tests** must pass. Starting count: **198 tests**; target: **~224 tests** (+26).

---

### Task 4: Verify `dart analyze` compliance (ARCH7)

- [x] 4.1 Run:
  ```bash
  dart analyze lib/ai/state_machine/
  ```
- [x] 4.2 Confirm zero Flutter framework imports (`package:flutter/...`) in `behavioral_state_machine.dart` and `behavioral_transition.dart`.

---

## Dev Notes

### File Placement

| File | Action | Rationale |
|---|---|---|
| `lib/ai/state_machine/behavioral_transition.dart` | **Create** | Value type returned by state machine; pure Dart, no Flutter |
| `lib/ai/state_machine/behavioral_state_machine.dart` | **Create** | Core algorithm; imports StateVector, BehavioralState, SafetyConstraints — all pure Dart |
| `test/domain/ai/behavioral_state_machine_test.dart` | **Create** | 26 unit tests |

**Do NOT create `recommendation_policy.dart`** — architecture lists it in `lib/ai/state_machine/` but it relates to plan generation logic (Story 5.5). Defer.

### Import Conflict: `BehavioralState` Name Collision

Two types named `BehavioralState` exist in this codebase:
- `lib/ai/state_machine/behavioral_state.dart` — the **enum** (active, fatigued, atRisk, recovering)
- `lib/core/database/tables/behavioral_state_table.dart` — the **Drift table** class

The state machine file (`behavioral_state_machine.dart`) imports ONLY the enum — no DB dependency. When Story 5.5 wires up the use case and calls `BehavioralStateDao.insertState()`, the import alias pattern is:

```dart
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart'
    show BehavioralState;
import 'package:pulse_coach/core/database/tables/behavioral_state_table.dart'
    as db;
// Use as:  db.BehavioralStateData,  BehavioralState.active
```

This is flagged in deferred-work.md from Story 5.1 review. **Do NOT rename either class in Story 5.2** — address in Story 5.4/5.5 at DAO wiring time.

### `BehavioralStateDao` — No Changes Needed

The existing `BehavioralStateDao` already provides `insertState(BehavioralStateCompanion)` and `getLatestState()`. Story 5.2 does NOT modify the DAO. Story 5.5 (`GenerateDailyPlan` use case) is responsible for calling `insertState()` with the new state after the pipeline runs.

### Transition Message — Not Stored in DB

The `behavioral_state_table` schema does NOT have a `transitionMessage` column. The message is a TRANSIENT output of the machine returned to the use case layer, which:
1. Passes it into the generated `DailyPlan` explanation context (Story 5.6)
2. Displays it on the Today screen when state changed (FR14)

Adding a DB column is intentionally deferred — no schema migration in this story.

### `constraintsForState()` Co-location with State Machine

FR24 maps behavioral states to safety constraints. The method lives in `BehavioralStateMachine` rather than `SafetyRules` (Story 5.3) because:
- State-to-constraint mapping is a property of the STATE, not the safety subsystem
- `SafetyRules.apply(stateVector)` (Story 5.3) calls `machine.constraintsForState(stateVector.currentState)` as one of its inputs
- Tests for FR24 live in this story, preventing re-testing in 5.3

Story 5.3 (`SafetyRules`) will import `BehavioralStateMachine` or call the helper method — that's intentional coupling between two pure Dart classes.

### Evaluation Order is Critical

The state machine evaluates rules in a fixed priority order:
1. `fatigued → atRisk` (checked FIRST — prevents fatigued→recovering rule from firing when user has missed sessions)
2. `active → fatigued`
3. `atRisk/fatigued → recovering`
4. `recovering → active`

Test `5.2-UNIT-015` explicitly guards this priority. Do NOT reorder rules.

### RPE History Semantics (from Story 5.1 Dev Notes)

`rpeHistory` in `StateVector` is ordered: index 0 = oldest, last index = most recent. This story uses `rpe[rpe.length - 1]` for "most recent" and `_lastNAvg(rpe, n)` for "last N sessions average". Do NOT cap the list — it arrives pre-populated from the StateVector builder (Story 5.5).

### `_lastNAvg` Returns 0.0 for Insufficient Data

When `rpe.length < n`, `_lastNAvg` returns `0.0` which is ≤ any threshold — this means:
- `active → fatigued` does NOT fire (0.0 is not > 8.0) ✓ correct
- `recovering → active` does NOT fire (0.0 ≤ 6.5 is true, BUT rpe.length < 3 check blocks it first) ✓ correct

The `recovering → active` rule has an explicit length check (`rpe.length >= 3` implied by `_lastNAvg(rpe, 3) <= 6.5` only being evaluated when sufficient data exists — see implementation).

**Wait — this is a subtle bug potential**: `_lastNAvg(rpe, 3) <= 6.5` when `rpe.length < 3` returns `0.0 <= 6.5` = `true`. This would trigger the `recovering → active` transition incorrectly if only streak ≥ 3 with empty RPE. Fix this by checking `rpe.length >= 3` explicitly before the recovering→active rule, OR rely on the `0.0` semantics being correct (empty RPE = new user, no streak = 0, so streak ≥ 3 fails first anyway).

**Resolution**: Tests `5.2-UNIT-020` guards the rpe.length < 3 case. If the streak check fires before rpe check, add an explicit `rpe.length >= 3` guard in the recovering→active condition. Developer must verify and add the guard to prevent any edge case.

### DB Schema Constraints

`behavioral_state_table.currentState` stores string values: `'Active' | 'Recovering' | 'AtRisk' | 'Fatigued'` (PascalCase). The enum values are `active, fatigued, atRisk, recovering` (camelCase). Story 5.5 is responsible for the mapping when calling `insertState()`:
```dart
// Example mapping (Story 5.5):
String _enumToDb(BehavioralState s) => switch(s) {
  BehavioralState.active     => 'Active',
  BehavioralState.fatigued   => 'Fatigued',
  BehavioralState.atRisk     => 'AtRisk',
  BehavioralState.recovering => 'Recovering',
};
```

### Existing Files That Must NOT Be Changed

- `lib/ai/state_machine/behavioral_state.dart` — enum already created in Story 5.1; no modifications
- `lib/ai/bandit/state_vector.dart` — StateVector already defined; no modifications
- `lib/ai/safety/safety_constraints.dart` — SafetyConstraints already defined; no modifications
- `lib/core/database/daos/behavioral_state_dao.dart` — DAO already exists; no modifications
- `lib/core/database/app_database.dart` — no schema changes (no migration in this story)
- Any existing test files — 198 tests must all still pass after this story

### Cross-Story Dependencies

- **Story 5.1** provides: `BehavioralState` enum, `StateVector`, `SafetyConstraints`, `SessionIntensity` — all already implemented ✓
- **Story 5.3** (`SafetyRules`) imports `BehavioralStateMachine.constraintsForState()` as one input to constraint aggregation
- **Story 5.5** (`GenerateDailyPlan`) orchestrates: calls `machine.evaluate(sv)`, receives `BehavioralTransition`, calls `BehavioralStateDao.insertState()`, passes `transitionMessage` into plan context
- **Story 5.6** (`ExplanationGenerator`) uses `transitionMessage` when generating session explanations

### Test Count

Starting: **198 tests**

New tests (Story 5.2):
- `5.2-UNIT-001` through `5.2-UNIT-026`: 26 tests

Target: **~224 tests** (+26)

### Project Structure Notes

```
pulse_coach/lib/ai/state_machine/
├── behavioral_state.dart           ← EXISTING (Story 5.1) — enum
├── behavioral_state_machine.dart   ← CREATE (Story 5.2) — algorithm
├── behavioral_transition.dart      ← CREATE (Story 5.2) — value type
└── recommendation_policy.dart      ← DEFERRED (Story 5.5)
```

### References

- FR23, FR24: [Source: _bmad-output/planning-artifacts/architecture.md — Functional Requirements]
- FR14: State transition messages displayed on Today Screen [Source: _bmad-output/planning-artifacts/architecture.md — Explainability section]
- BehavioralState enum transitions: [Source: lib/ai/state_machine/behavioral_state.dart — comments]
- BehavioralStateDao: [Source: lib/core/database/daos/behavioral_state_dao.dart]
- BehavioralState table schema: [Source: lib/core/database/tables/behavioral_state_table.dart]
- Name collision deferred note: [Source: _bmad-output/implementation-artifacts/deferred-work.md — Story 5.1 section]
- `constraintsForState` FR24: [Source: _bmad-output/planning-artifacts/epics.md — Story 5.2 AC]
- Evaluation order guard (Rule 1 before Rule 3): [Source: test 5.2-UNIT-015 — priority invariant]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- UNIT-010 spec bug: test used `rpe: [6, 6]` which triggers fatigued→recovering (Rule 3). Changed to `rpe: [8, 9]` to isolate the fatigued→atRisk boundary test. Both RPE values > 7, recovering rule cannot fire.
- Added explicit `rpe.length >= 3` guard to recovering→active rule (Rule 4) per Dev Notes warning: `_lastNAvg` returns 0.0 for insufficient data, which would satisfy `<= 6.5` check incorrectly.

### Completion Notes List

- Created `BehavioralTransition` pure Dart value type with `stateChanged` derived getter
- Created `BehavioralStateMachine` with 4 priority-ordered rules and `constraintsForState()` FR24 mapping
- All 4 rules covered: active→fatigued, fatigued→atRisk, atRisk/fatigued→recovering, recovering→active
- Zero Flutter imports in both production files (`flutter analyze` confirmed clean)
- 26 new unit tests (5.2-UNIT-001 through 5.2-UNIT-026): 26/26 passed
- Full regression suite: 224/224 passed (198 existing + 26 new)

### File List

- `pulse_coach/lib/ai/state_machine/behavioral_transition.dart` (created)
- `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart` (created)
- `pulse_coach/test/domain/ai/behavioral_state_machine_test.dart` (created)

### Review Findings

- [x] [Review][Patch] UNIT-017 mislabels boundary and duplicates UNIT-016 [test/domain/ai/behavioral_state_machine_test.dart:320–329] — Title claims "fires at exact boundary avg = 6.5" but `[6,7,6]` averages 6.33. The `== 6.5` boundary is unreachable with 3 integer RPEs (sum 19.5 is impossible). Rename to reflect actual coverage or remove as duplicate of UNIT-016.
- [x] [Review][Patch] UNIT-004 "boundary" label misleading [test/domain/ai/behavioral_state_machine_test.dart:217] — avg 8.5 is not the boundary of `> 8.0`; the true boundary is `= 8.0` (already covered by UNIT-005). Rename the test title.
- [x] [Review][Patch] `_lastNAvg` crashes on `n <= 0` [lib/ai/state_machine/behavioral_state_machine.dart:111–115] — With `n=0`, `[].sublist(0).reduce(...)` throws `Bad state: No element`. Contract says "returns 0.0 for insufficient data" — false for n≤0. Add explicit guard `if (n <= 0) return 0.0;`.
- [x] [Review][Defer] StateVector lacks RPE range validation [lib/ai/bandit/state_vector.dart] — deferred, pre-existing (Story 5.1 design). Negative/out-of-range RPE would silently trigger wrong transitions. Add invariant in StateVector.
- [x] [Review][Defer] `missedSessions` decay/reset logic [cross-story] — deferred to Story 5.5. User may be stuck in `atRisk` after genuine recovery if StateVector snapshot doesn't decay missed counter.
- [x] [Review][Defer] AC7 wording tension [spec:AC section] — deferred, spec-level. AC says "transition is written to behavioral_state table" but Dev Notes defer persistence to Story 5.5. Intentional but phrasing should be reconciled.
- [x] [Review][Defer] Product review: state-graph asymmetries — deferred to Epic 5 product review. `active + missed≥2` never escalates to `atRisk`; `recovering` has no demotion path for high-RPE / missed sessions; `atRisk→recovering` lacks streak/missed guard (asymmetric vs `recovering→active`). All spec-compliant but potentially unsafe in practice.

## Change Log

- 2026-04-21: Story created by SM agent (claude-sonnet-4-6). Epic 5 Story 2. All Story 5.1 domain models in place. State machine is pure Dart with no DB dependency; persistence wired in Story 5.5. `constraintsForState()` co-located with state machine to own FR24 mapping. Name collision between `BehavioralState` enum and `BehavioralState` Drift table class is a known deferred issue (from 5.1 review); addressed at Story 5.5 DAO wiring time with import alias pattern.
- 2026-04-21: Story implemented by claude-sonnet-4-6. Created BehavioralTransition value type, BehavioralStateMachine pure Dart class with 4 priority-ordered transition rules and constraintsForState() FR24 mapping. 26 unit tests created; 224/224 total tests pass. Added explicit `rpe.length >= 3` guard (Dev Notes edge case) and fixed spec bug in UNIT-010 (RPE vector changed from [6,6] to [8,9] to isolate fatigued→atRisk boundary test). Zero Flutter imports confirmed.
- 2026-04-21: Code review by claude-opus-4-7 (3 parallel reviewers: Blind Hunter, Edge Case Hunter, Acceptance Auditor). 3 patches applied: (1) `_lastNAvg` gains `n <= 0` guard to prevent `Bad state: No element` crash; (2) UNIT-004 renamed ("fires when last 2 RPE avg = 8.5"); (3) UNIT-017 rewritten to probe sublist-window semantics (fixture now [9,9,6,7,6]) instead of an unreachable exact-6.5 boundary. 4 items deferred to `deferred-work.md` (StateVector RPE validation, missedSessions decay logic, AC7 wording, state-graph asymmetries). 224/224 tests still passing. Status → done.
