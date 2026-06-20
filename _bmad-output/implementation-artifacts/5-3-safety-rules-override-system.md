# Story 5.3: Safety Rules Override System

Status: done

## Story

As the system,
I want deterministic safety rules that override bandit recommendations,
so that session intensity is automatically reduced when biometric or behavioral signals indicate risk.

## Acceptance Criteria

**Given** the `SafetyRules` is implemented as a pure Dart class
**When** RPE average of last 2 sessions is > 8
**Then** high-intensity sessions are blocked regardless of bandit recommendation (FR9)

**Given** the user is in `atRisk` state
**When** `SafetyRules.apply(stateVector)` is called
**Then** only `low` intensity sessions are permitted and session count is capped at 2 (FR9, FR24)

**Given** `AqiLevel.high` (AQI ≥ 100) is present in `StateVector`
**When** `SafetyRules.apply(stateVector)` is called
**Then** `outdoorAllowed = false` — only indoor sessions are permitted (FR8)

**Given** safety rules produce `SafetyConstraints`
**When** the bandit generates a plan (Story 5.4)
**Then** the plan returned from the AI engine respects all active safety constraints — no override is possible from the bandit layer (FR9)

## Tasks / Subtasks

### Task 1: Implement `SafetyRules` pure Dart class (AC: all)

- [x] 1.1 Create `lib/ai/safety/safety_rules.dart`:

```dart
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state_machine.dart';

/// Deterministic safety override layer between behavioral state machine and bandit.
///
/// Merges constraints from three independent sources (most restrictive wins):
///   1. Behavioral state (FR24): BehavioralStateMachine.constraintsForState()
///   2. Direct RPE signal (FR9): last-2-avg > 8 caps maxIntensity at medium
///   3. Air quality (FR8): AqiLevel.high blocks all outdoor sessions
///
/// Stateless — every call derives fresh constraints from the StateVector snapshot.
/// Called by GenerateDailyPlan use case (Story 5.5) AFTER state machine evaluation.
/// The BanditEngine (Story 5.4) CANNOT override the output of this class.
class SafetyRules {
  final BehavioralStateMachine _machine;

  const SafetyRules(this._machine);

  /// Applies all safety rules to [stateVector] and returns merged constraints.
  ///
  /// Merge semantics (most restrictive wins):
  ///   - maxIntensity: low < medium < null (null = no cap = least restrictive)
  ///   - maxSessionCount: minimum of all active rules
  ///   - outdoorAllowed: false if ANY rule prohibits outdoor
  SafetyConstraints apply(StateVector stateVector) {
    final stateConstraints =
        _machine.constraintsForState(stateVector.currentState);

    final maxIntensity = _mergedIntensity(
      stateConstraints.maxIntensity,
      stateVector.rpeHistory,
    );
    final outdoorAllowed =
        stateVector.aqiLevel != AqiLevel.high && stateConstraints.outdoorAllowed;

    return SafetyConstraints(
      maxIntensity: maxIntensity,
      maxSessionCount: stateConstraints.maxSessionCount,
      outdoorAllowed: outdoorAllowed,
    );
  }

  /// Merges the behavioral-state intensity cap with the RPE-derived cap.
  SessionIntensity? _mergedIntensity(
    SessionIntensity? stateMaxIntensity,
    List<int> rpeHistory,
  ) {
    SessionIntensity? rpeCapIntensity;
    if (_lastTwoAvg(rpeHistory) > 8.0) {
      rpeCapIntensity = SessionIntensity.medium;
    }
    return _strictest(stateMaxIntensity, rpeCapIntensity);
  }

  /// Returns the stricter of [a] and [b].
  /// Strictness order (most → least): low, medium, high, null (no cap).
  SessionIntensity? _strictest(SessionIntensity? a, SessionIntensity? b) {
    if (a == null) return b;
    if (b == null) return a;
    const order = [
      SessionIntensity.low,
      SessionIntensity.medium,
      SessionIntensity.high,
    ];
    return order.indexOf(a) <= order.indexOf(b) ? a : b;
  }

  /// Average of the last 2 RPE values. Returns 0.0 when fewer than 2 entries.
  double _lastTwoAvg(List<int> rpe) {
    if (rpe.length < 2) return 0.0;
    return (rpe[rpe.length - 1] + rpe[rpe.length - 2]) / 2.0;
  }
}
```

- [x] 1.2 **No Flutter imports** — pure Dart class. Run `dart analyze lib/ai/safety/` after creation to verify.

---

### Task 2: Write unit tests (AC: all)

- [x] 2.1 Create `test/domain/ai/safety_rules_test.dart`:

```dart
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
}
```

- [x] 2.2 Run `flutter test test/domain/ai/safety_rules_test.dart` — all 17 tests must pass.
- [x] 2.3 Run `flutter test` — **all tests** must pass. Starting count: **224 tests**; target: **~241 tests** (+17).

---

### Task 3: Verify `dart analyze` compliance (ARCH7)

- [x] 3.1 Run:
  ```bash
  dart analyze lib/ai/safety/safety_rules.dart
  ```
- [x] 3.2 Confirm zero Flutter framework imports (`package:flutter/...`) in `safety_rules.dart`.

---

### Review Findings

- [x] [Review][Decision→Resolved] `build.yaml` mantenuto e documentato in File List + Change Log. Motivazione: `explicit_to_json: true` necessario per serializzazione di `@freezed` annidati (StateVector → UserProfile). Config di progetto Epic 5 legittima.
- [x] [Review][Decision→Resolved] `AqiLevel` check convertito a switch esaustivo in `apply()` — `aqiLevel != AqiLevel.high` → `switch` exhaustive. Fail-compile su nuovi valori dell'enum (FR8 è safety-critical, non può fail-open).
- [x] [Review][Decision→Resolved] `_strictest` refactorato a switch esaustivo tramite helper `_strictnessRank` — `indexOf` su lista sostituito. Fail-compile su nuovi valori di `SessionIntensity` (coerenza con decisione D2 sul safety layer).
- [x] [Review][Patch] Docstring `apply()` riscritto — specifica esplicitamente che `maxSessionCount` deriva solo da `constraintsForState()` e che `outdoorAllowed` è un AND logico state ∧ AQI.
- [x] [Review][Patch] Aggiunti test `5.3-UNIT-018` ([8,8]+fatigued→medium) e `5.3-UNIT-019` ([8,8]+atRisk→low) — boundary `>` blindato anche quando state contribuisce.
- [x] [Review][Patch] Aggiunto test `5.3-UNIT-020` ([10,10,6,6]→no cap) — blinda che `_lastTwoAvg` usi solo gli ultimi 2, non l'intera lista.
- [x] [Review][Defer] Validazione range RPE (valori negativi / >10) [pulse_coach/lib/ai/safety/safety_rules.dart:107] — deferred, pre-existing (già tracciato in deferred-work.md per Story 5.5 StateVector builder).
- [x] [Review][Defer] RPE staleness / recency [pulse_coach/lib/ai/safety/safety_rules.dart:107] — deferred, strutturale: `rpeHistory` non ha timestamp, la regola non può filtrare entry datate. Tracciare per Story 5.5.

## Dev Notes

### File Placement

| File | Action | Rationale |
|---|---|---|
| `lib/ai/safety/safety_rules.dart` | **Create** | Core safety algorithm; pure Dart, no Flutter |
| `test/domain/ai/safety_rules_test.dart` | **Create** | 17 unit tests |

**Do NOT touch:**
- `lib/ai/safety/safety_constraints.dart` — `SafetyConstraints`, `SessionIntensity`, `noConstraints` already defined in Story 5.1; no modifications needed
- `lib/ai/safety/safety_constraints.freezed.dart` and `safety_constraints.g.dart` — generated; do not touch
- `lib/ai/state_machine/behavioral_state_machine.dart` — `BehavioralStateMachine` and `constraintsForState()` already implemented in Story 5.2; no modifications
- Any existing test files — 224 tests must all still pass after this story

### Existing Files Used as Dependencies

All dependencies already exist in `pulse_coach/`:

```
lib/ai/safety/
├── safety_constraints.dart           ← EXISTING (Story 5.1) — SafetyConstraints, SessionIntensity, noConstraints
├── safety_constraints.freezed.dart   ← EXISTING generated
├── safety_constraints.g.dart         ← EXISTING generated
└── safety_rules.dart                 ← CREATE (Story 5.3) ← this story

lib/ai/state_machine/
├── behavioral_state.dart             ← EXISTING (Story 5.1) — BehavioralState enum
├── behavioral_state_machine.dart     ← EXISTING (Story 5.2) — BehavioralStateMachine + constraintsForState()
└── behavioral_transition.dart        ← EXISTING (Story 5.2)

lib/ai/bandit/
└── state_vector.dart                 ← EXISTING (Story 5.1) — StateVector, AqiLevel
```

### Key Design: SafetyRules as a Thin Aggregation Layer

`SafetyRules` is deliberately thin — it does NOT reimplement the state→constraint mapping. That logic lives entirely in `BehavioralStateMachine.constraintsForState()` (Story 5.2). `SafetyRules` only adds two things:
1. **RPE override** (FR9): independent of state, checking raw RPE directly
2. **AQI override** (FR8): blocks outdoor regardless of state

**Why RPE is checked independently of state:**
The state machine transitions are PRIOR-state aware (e.g., `active→fatigued` fires when RPE avg > 8). But `SafetyRules` applies at plan-time; the `currentState` in the incoming `StateVector` may not yet reflect the latest RPE evaluation (Story 5.5 is responsible for this ordering). The explicit RPE check in `SafetyRules` acts as a fail-safe: even if the state hasn't transitioned yet, high RPE still blocks high-intensity.

### Merge Semantics: Strictest Wins

`maxIntensity` ordering (most → least restrictive): `low` > `medium` > `null` (no cap).

| stateConstraint.maxIntensity | RPE cap | Result |
|---|---|---|
| `null` (active) | none | `null` |
| `null` (active) | `medium` (RPE > 8) | `medium` |
| `medium` (fatigued) | `medium` (RPE > 8) | `medium` |
| `low` (atRisk) | `medium` (RPE > 8) | `low` ← strictest wins |
| `low` (recovering) | none | `low` |

`outdoorAllowed` is a simple AND: `stateConstraints.outdoorAllowed && aqiLevel != AqiLevel.high`. In practice `stateConstraints.outdoorAllowed` is always `true` from `constraintsForState()` — AQI blocking is the only source of `false`.

`maxSessionCount` comes entirely from `constraintsForState()` — no additional rule modifies it in Story 5.3.

### AqiLevel Semantics

```dart
// From lib/ai/bandit/state_vector.dart:
enum AqiLevel { low, high }
// AqiLevel.high = AQI >= 100 (derived at use case layer from WeatherContext.aqiValue)
```

`SafetyRules` uses `stateVector.aqiLevel == AqiLevel.high` (or equivalently `!= AqiLevel.low`). The threshold mapping (`>=100`) happens upstream in the StateVector builder (Story 5.5).

### No Constructor Injection into DI (this story)

`SafetyRules` is a pure Dart class with a `const` constructor. DI registration (`@injectable` or `@singleton`) is NOT added in this story — that is deferred to Story 5.5 which wires the full pipeline. In tests, instantiate directly:

```dart
final rules = SafetyRules(const BehavioralStateMachine());
```

### FR9 — "No Override Possible" Guarantee

AC4 states the bandit CANNOT override safety constraints. This is enforced architecturally in Story 5.5: `BanditEngine.selectSessions(stateVector, constraints)` receives `SafetyConstraints` as an input parameter and must filter candidates accordingly. `SafetyRules` itself doesn't "enforce" this — it just produces the constraints. The Story 5.4/5.5 dev notes will specify the bandit's responsibility. AC4 is verified by integration/use-case test in Story 5.5.

### Deferred Items from Previous Stories Relevant to This Story

From `deferred-work.md` — Story 5.1:
- `UserProfile.physicalConstraints` is a single string: cannot co-express "indoor preference" + injury constraint simultaneously. Downstream: `SafetyRules` has no field in `StateVector` for injury type. Story 5.3 ignores injury-specific rules. This is acceptable per current spec.

From `deferred-work.md` — Story 5.2:
- `StateVector.rpeHistory` has no range validation (expected 1–10). Out-of-range RPE could trigger wrong constraints. Validation deferred to Story 5.5 StateVector builder; `SafetyRules` takes RPE at face value.
- State-graph asymmetries (e.g., `atRisk→recovering` has no streak guard). `SafetyRules` correctly uses whatever `currentState` is present in `StateVector` — it doesn't try to re-evaluate transitions.

### Test Fixture Note

Tests use real `BehavioralStateMachine` (not a mock) because it's pure Dart and deterministic — no side effects, no I/O. This is the established pattern from Story 5.2. Do not introduce mocks for `BehavioralStateMachine` in this story.

### Cross-Story Dependencies

- **Story 5.1** provides: `SafetyConstraints`, `SessionIntensity`, `noConstraints`, `StateVector`, `AqiLevel`, `BehavioralState` — all implemented ✓
- **Story 5.2** provides: `BehavioralStateMachine`, `constraintsForState()` — implemented ✓
- **Story 5.4** (`BanditEngine`) receives `SafetyConstraints` from this class as input to `selectSessions()`
- **Story 5.5** (`GenerateDailyPlan`) instantiates and calls `SafetyRules.apply()` after state machine evaluation; wires DI

### Project Structure

```
pulse_coach/lib/ai/safety/
├── safety_constraints.dart           ← EXISTING (Story 5.1)
├── safety_constraints.freezed.dart   ← EXISTING generated
├── safety_constraints.g.dart         ← EXISTING generated
└── safety_rules.dart                 ← CREATE (Story 5.3)

pulse_coach/test/domain/ai/
├── behavioral_state_machine_test.dart ← EXISTING (Story 5.2) — 26 tests
└── safety_rules_test.dart             ← CREATE (Story 5.3) — 17 tests
```

### Test Count

Starting: **224 tests** (198 original + 26 from Story 5.2)

New tests (Story 5.3):
- `5.3-UNIT-001` through `5.3-UNIT-017`: 17 tests

Target: **~241 tests** (+17)

### References

- FR8: AQI outdoor blocking [Source: `_bmad-output/planning-artifacts/architecture.md` — Component Mapping table]
- FR9: Safety rules override layer [Source: `_bmad-output/planning-artifacts/architecture.md` — Component Mapping table]
- FR24: State → intensity mapping [Source: `_bmad-output/planning-artifacts/epics.md` — Story 5.2 AC]
- `SafetyConstraints`, `SessionIntensity`, `noConstraints`: [Source: `lib/ai/safety/safety_constraints.dart`]
- `BehavioralStateMachine.constraintsForState()`: [Source: `lib/ai/state_machine/behavioral_state_machine.dart:82`]
- `AqiLevel` enum and threshold semantics: [Source: `lib/ai/bandit/state_vector.dart:11`]
- `constraintsForState()` co-location rationale: [Source: `_bmad-output/implementation-artifacts/5-2-behavioral-state-machine.md` — Dev Notes: constraintsForState Co-location]
- Deferred: UserProfile.physicalConstraints limitation: [Source: `_bmad-output/implementation-artifacts/deferred-work.md` — Story 5.1 section]
- Deferred: RPE range validation: [Source: `_bmad-output/implementation-artifacts/deferred-work.md` — Story 5.2 section]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation was straightforward; all 17 tests passed on first run.

### Completion Notes List

- Created `lib/ai/safety/safety_rules.dart`: pure Dart class, no Flutter imports, `dart analyze` clean.
- Created `test/domain/ai/safety_rules_test.dart`: 17 unit tests (5.3-UNIT-001 → 5.3-UNIT-017), all passing.
- Full regression suite: 241 tests passed (224 baseline + 17 new), zero regressions.
- All 4 ACs satisfied: RPE > 8 caps at medium, atRisk → low + maxSessionCount=2, AQI.high → outdoorAllowed=false, constraints structurally bandit-proof (enforced architecturally in Story 5.5).

### File List

- `pulse_coach/lib/ai/safety/safety_rules.dart` (created)
- `pulse_coach/test/domain/ai/safety_rules_test.dart` (created)
- `pulse_coach/build.yaml` (created) — configures `json_serializable.explicit_to_json: true` globally; required for correct serialization of nested `@freezed` classes (e.g. `StateVector` with nested `UserProfile`). Project-level config introduced during Epic 5.

## Change Log

- 2026-04-21: Story created by SM agent (claude-sonnet-4-6). Epic 5 Story 3. All dependencies from Stories 5.1–5.2 in place. SafetyRules is a thin aggregation layer: behavioral-state constraints (from BehavioralStateMachine.constraintsForState), RPE override (FR9), and AQI override (FR8). Merge semantics: most restrictive wins for intensity; boolean AND for outdoorAllowed. DI wiring deferred to Story 5.5.
- 2026-04-22: Story implemented by dev agent (claude-sonnet-4-6). Created SafetyRules and 17 unit tests. All 241 tests pass.
- 2026-04-22: Code review (claude-opus-4-7). Added `build.yaml` to File List — configures `json_serializable.explicit_to_json: true` globally, required for correct serialization of nested `@freezed` classes (StateVector → UserProfile). Legitimate Epic 5 project-level config, not scope creep.
- 2026-04-22: Code review hardening — (1) `AqiLevel` check convertito a switch esaustivo (fail-compile su enum growth, FR8 safety-critical); (2) `_strictest` refactorato via helper `_strictnessRank` con switch esaustivo (stesso razionale); (3) docstring `apply()` riscritto; (4) aggiunti test 5.3-UNIT-018/019/020. Tests: 241 → 244. `dart analyze` clean. Status → done.
