# Story 7.1b: `missedSessions` Decay & Reset

Status: done

## Story

As the AI engine,
I need a deterministic `missedSessions` counter derived from the daily-plan log,
So that the new `active → atRisk` rule (state-graph decision Q1) operates on a counter with reliable semantics and no stuck-state bugs.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | Cold-start, no daily-plan records | `GenerateDailyPlan` runs | `StateVector.missedSessions = 0` |
| AC2 | User has 3 daily plans in last 7d, 1 completed | `GenerateDailyPlan` runs | `missedSessions = 2` |
| AC3 | User has 7 uncompleted daily plans in the **prior 7 days** (today excluded) | `GenerateDailyPlan` runs | `missedSessions = 7` (capped only by window, not by any `expectedPerWeek` limit) |
| AC4 | User has plans spanning last 14d, all uncompleted (today excluded from count) | `GenerateDailyPlan` runs | `missedSessions = 7` — older plans outside 7-day window are excluded |
| AC5 | User has today's plan (any state) + prior 6 days had 3 missed plans | `GenerateDailyPlan` runs | `missedSessions = 3` — today's plan is NOT counted (window excludes today); prior misses preserved |
| AC6 | `StateVector.missedSessions >= 2` AND current state `active` | `BehavioralStateMachine.evaluate` runs | Transitions to `atRisk`, message `transition_active_atRisk` = *"Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi."* |
| AC7 | `StateVector.missedSessions == 1` | `BehavioralStateMachine.evaluate` runs from `active` | No transition (stays `active`) |
| AC8 | Priority test: `active`, `missedSessions = 2`, `last-2-RPE avg > 8` | Evaluate | `atRisk` wins (priority 1) over `fatigued` (priority 3) |

**Binding:** must merge in the same PR cluster as Story 7.1. If 7.1b slips or is descoped, the `active → atRisk` rule is **removed** from `behavioral_state_machine.dart` before Story 7.1 merge — no exception.

## Tasks / Subtasks

- [x] Task 1: Add `getPlansInDateRange` method to `DailyPlansDao` (AC: 1, 2, 3, 4, 5)
  - [x] In `pulse_coach/lib/core/database/daos/daily_plans_dao.dart`, add:
    ```dart
    Future<List<DailyPlan>> getPlansInDateRange(String startDate, String endDate) =>
        (select(dailyPlans)
          ..where((t) => t.planDate.isBetweenValues(startDate, endDate)))
            .get();
    ```
  - [x] No `build_runner` needed — this is a plain DAO method using Drift's `select()` API, no new annotations

- [x] Task 2: Create `MissedSessionsCalculator` (AC: 1–5)
  - [x] Create `pulse_coach/lib/ai/missed_sessions/missed_sessions_calculator.dart` — pure Dart, no Flutter imports, no injectable
    ```dart
    class MissedSessionsCalculator {
      const MissedSessionsCalculator();
      int calculate(List<bool> completionFlags) =>
          completionFlags.where((completed) => !completed).length;
    }
    ```
  - [x] `completionFlags` is the list of `isCompleted` values from plans in the 7-day window
  - [x] Cold-start: empty list → 0 naturally (AC1)

- [x] Task 3: Wire `MissedSessionsCalculator` into `GenerateDailyPlan` (AC: 1–5)
  - [x] In `pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart`, inside `_buildStateVector()`:
    - Keep `final sessions = await _db.sessionsDao.getAllSessions();` for streak (unchanged)
    - Remove the old `_calculateMissedSessions(sessions)` call
    - Add after streak calculation:
      ```dart
      // 7-day window EXCLUDING today (today's plan can't be a "miss" yet).
      final windowStart = _dateStr(DateTime.now().subtract(const Duration(days: 7)));
      final windowEnd = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
      final plansInWindow = await _db.dailyPlansDao.getPlansInDateRange(windowStart, windowEnd);
      final missedSessions = const MissedSessionsCalculator().calculate(
        plansInWindow.map((p) => p.isCompleted).toList(),
      );
      ```
  - [x] Add import for `MissedSessionsCalculator`: `import 'package:pulse_coach/ai/missed_sessions/missed_sessions_calculator.dart';`
  - [x] Remove the `_calculateMissedSessions(List<Session> sessions)` private helper method entirely (it used the sessions table; the new approach uses daily_plans table)
  - [x] No changes to `_calculateStreak(sessions)` — streak still uses `sessionsDao` (correct, unchanged)
  - [x] No DI constructor change — `MissedSessionsCalculator` instantiated inline as `const MissedSessionsCalculator()` (matches pattern of `BehavioralStateMachine` in `ai_engine_isolate.dart:40`)
  - [x] No `build_runner` needed — no DI surface change, no freezed change

- [x] Task 4: Add `active → atRisk` rule to `BehavioralStateMachine` (AC: 6, 7, 8)
  - [x] In `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart`:
    - Add Rule 1 BEFORE the existing Rule 1 (`fatigued → atRisk`):
      ```dart
      // Rule 1: active → atRisk (disengagement — new Q1 from state-graph decision 2026-05-15)
      if (current == BehavioralState.active && missed >= 2) {
        return const BehavioralTransition(
          newState: BehavioralState.atRisk,
          transitionMessage:
              'Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi.',
        );
      }
      ```
    - Renumber existing rules: old Rule 1 → Rule 2, old Rule 2 → Rule 3, old Rule 3 → Rule 4, old Rule 4 → Rule 5
    - Update the class-level doc comment to reflect 5 rules (note Rule 6 added by Story 7.1)
  - [x] Note: The final 6-rule set from state-graph decisions also includes Q2 (`recovering → fatigued`) and a tightened Q3 (`atRisk/fatigued → recovering`). **Those are in Story 7.1 scope, NOT 7.1b.** Do NOT implement Q2 or Q3 changes in this story — that would cause test breakage without the corresponding Story 7.1 test updates.

- [x] Task 5: Write `MissedSessionsCalculator` unit tests (AC: 1–5)
  - [x] Create `pulse_coach/test/ai/missed_sessions/missed_sessions_calculator_test.dart`
  - [x] Write 8 tests (see Dev Notes for full specs)
  - [x] No `@GenerateMocks`, no Flutter imports — pure Dart unit tests

- [x] Task 6: Add integration tests to `generate_daily_plan_test.dart` (AC: 2, 4)
  - [x] Add 2 tests to `pulse_coach/test/features/daily_plan/generate_daily_plan_test.dart`
  - [x] These tests insert daily_plan rows into the in-memory Drift DB (the test already uses `NativeDatabase.memory()`)
  - [x] See Dev Notes for full test specs

- [x] Task 7: Add state machine tests (AC: 6, 7, 8)
  - [x] Add 3 tests to `pulse_coach/test/domain/ai/behavioral_state_machine_test.dart`
  - [x] See Dev Notes for full test specs

- [x] Task 8: Gate verification
  - [x] `flutter test` from `pulse_coach/` — must show **411/411** (or current baseline + 13)
  - [x] `flutter analyze` from `pulse_coach/` — must show **0 issues**

## Dev Notes

### What This Story Is

Story 7.1b is a 1.5-day backend story that:
1. Pins the semantic and source of `missedSessions` to the `daily_plans` table (not the `sessions` table used currently)
2. Enables the new `active → atRisk` state-machine rule from state-graph Q1 decision

**Must merge in same PR cluster as Story 7.1.** If 7.1b slips, remove the `active → atRisk` rule before Story 7.1 merge. Stories 7.0 (already done) and 7.1b can run in parallel.

---

### CRITICAL: Pre-Sprint Blocker Check Results

Before implementing, verify these findings from code inspection (2026-05-15):

**✅ BLOCKER 1 PASSED:** `daily_plans_table.dart` HAS `isCompleted` boolean column with `withDefault(false)`. The DAO's `markCompleted(date)` method already sets it. The daily-plans table supports the `completionStatus` query this story requires.

**⚠️ BLOCKER 2 DEVIATION:** `UserProfile` does NOT have `expectedPerWeek`. The scope document's `MissedSessionsCalculator` signature included `int expectedPerWeek` as a cap, but AC3 explicitly says: "capped only by window, not by `expectedPerWeek`". **Resolution:** drop the `expectedPerWeek` param entirely. The 7-day window applied at the DAO level already provides the implicit cap. The calculator interface is simplified to `calculate(List<bool> completionFlags) → int`.

---

### Current Code: What to Preserve and What to Replace

**`generate_daily_plan.dart` — `_buildStateVector()` method (lines 203–271):**

Current state of the sessions / missed computation:
```dart
// Session history — for streak and missedSessions
final sessions = await _db.sessionsDao.getAllSessions();
final streak = _calculateStreak(sessions);
final missedSessions = _calculateMissedSessions(sessions);
```

**Preserve:** `_calculateStreak(sessions)` and the `sessionsDao.getAllSessions()` call — streak still works from the sessions table. Do NOT remove the `sessions` variable.

**Replace:** `_calculateMissedSessions(sessions)` call + the entire private `_calculateMissedSessions(List<Session> sessions)` method (lines 347–359). It currently counts 7 calendar days with no completed session from the sessions table. Story 7.1b replaces it with the daily-plans-table approach.

**Why the change:** The sessions-table approach counts ALL calendar days, including days where no plan was ever generated. The daily-plans-table approach counts only days where a plan existed but was not completed — semantically correct for the "disengagement" JTBD framing (a user who never opened the app on a day isn't "missing" a planned session).

---

### New File: `MissedSessionsCalculator`

```dart
// pulse_coach/lib/ai/missed_sessions/missed_sessions_calculator.dart

class MissedSessionsCalculator {
  const MissedSessionsCalculator();

  int calculate(List<bool> completionFlags) =>
      completionFlags.where((completed) => !completed).length;
}
```

- Pure Dart only. No Flutter imports. No injectable. No freezed.
- Create the directory `lib/ai/missed_sessions/` (new subfolder under `lib/ai/`).
- `completionFlags` is extracted from Drift `DailyPlan` rows at the call site via `.map((p) => p.isCompleted).toList()`.

---

### New DAO Method: `DailyPlansDao.getPlansInDateRange`

**WARNING: naming collision.** The Drift data class for `DailyPlans` table is `DailyPlan` (from `@DataClassName('DailyPlan')`) — the same name as the domain entity in `features/daily_plan/domain/entities/daily_plan.dart`. In `generate_daily_plan.dart`, the domain entity is already aliased as `import ... as domain`. The Drift `DailyPlan` type is unambiguous from `package:pulse_coach/core/database/app_database.dart`. Ensure the import is correct before referencing `DailyPlan` in the new code.

```dart
// pulse_coach/lib/core/database/daos/daily_plans_dao.dart — add this method:
Future<List<DailyPlan>> getPlansInDateRange(String startDate, String endDate) =>
    (select(dailyPlans)
      ..where((t) => t.planDate.isBetweenValues(startDate, endDate)))
        .get();
```

Both `startDate` and `endDate` are `'YYYY-MM-DD'` strings — same format as the existing `planDate` column and the `_dateStr()` helper in `GenerateDailyPlan`. Lexicographic string comparison works correctly for ISO date strings.

---

### `BehavioralStateMachine` — Current vs. Required

**Current rules (4):**
1. `fatigued → atRisk` if `missed >= 2`
2. `active → fatigued` if `_lastNAvg(rpe, 2) > 8.0`
3. `atRisk/fatigued → recovering` if last 2 RPE both ≤ 7
4. `recovering → active` if last 3 avg ≤ 6.5 AND streak ≥ 3

**After 7.1b (5 rules — only add Rule 1):**
1. *(NEW)* `active → atRisk` if `missedSessions >= 2`
2. `fatigued → atRisk` if `missedSessions >= 2`
3. `active → fatigued` if `_lastNAvg(rpe, 2) > 8.0`
4. `atRisk/fatigued → recovering` if last 2 RPE both ≤ 7 ← **UNCHANGED in 7.1b**
5. `recovering → active` if last 3 avg ≤ 6.5 AND streak ≥ 3

**Final 6-rule set (after BOTH 7.1b AND 7.1):**
1. `active → atRisk` if `missedSessions >= 2` ← 7.1b adds this
2. `fatigued → atRisk` if `missedSessions >= 2`
3. `active → fatigued` if `_lastNAvg(rpe, 2) > 8.0`
4. `atRisk/fatigued → recovering` if `_lastNAvg(rpe, 3) <= 7.0 AND missedSessions == 0` ← 7.1 tightens this (Q3)
5. `recovering → active` if last 3 avg ≤ 6.5 AND streak ≥ 3
6. `recovering → fatigued` if `rpe.last >= 9` ← 7.1 adds this (Q2)

**Do NOT implement rules 4 (tightened) or 6 in this story.** Those are Story 7.1 scope. Implementing them here would break 5.2-UNIT-011 and 5.2-UNIT-012 without the corresponding test updates (which belong in Story 7.1).

---

### `MissedSessionsCalculator` Test Specs

File: `pulse_coach/test/ai/missed_sessions/missed_sessions_calculator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/missed_sessions/missed_sessions_calculator.dart';

void main() {
  const calc = MissedSessionsCalculator();

  // AC1: cold start — no plans → 0
  test('7.1b-CALC-001: empty list returns 0', () {
    expect(calc.calculate([]), equals(0));
  });

  // AC2: 3 plans, 1 completed, 2 uncompleted → 2
  test('7.1b-CALC-002: 3 plans 1 completed → 2 missed', () {
    expect(calc.calculate([true, false, false]), equals(2));
  });

  // AC3: 7 plans all uncompleted → 7
  test('7.1b-CALC-003: 7 plans all uncompleted → 7', () {
    expect(calc.calculate(List.filled(7, false)), equals(7));
  });

  // AC4: window is applied at DAO level; calculator just counts false flags
  // This test verifies the calculator doesn't apply any cap
  test('7.1b-CALC-004: all completed → 0 missed', () {
    expect(calc.calculate([true, true, true, true, true, true, true]), equals(0));
  });

  // AC5: recent completion does NOT erase prior misses
  test('7.1b-CALC-005: today completed, 3 prior misses → 3 missed', () {
    // Window has today (completed) + 3 uncompleted earlier
    expect(calc.calculate([false, false, false, true]), equals(3));
  });

  // Boundary: exactly 1 missed
  test('7.1b-CALC-006: exactly 1 missed', () {
    expect(calc.calculate([true, true, false]), equals(1));
  });

  // Boundary: exactly 2 missed (state-machine threshold)
  test('7.1b-CALC-007: exactly 2 missed (threshold for atRisk rule)', () {
    expect(calc.calculate([false, false, true, true, true]), equals(2));
  });

  // Idempotency: calling twice returns same result
  test('7.1b-CALC-008: idempotent — same flags produce same result', () {
    final flags = [false, false, true];
    expect(calc.calculate(flags), equals(calc.calculate(flags)));
  });
}
```

---

### `GenerateDailyPlan` Integration Test Specs

File: `pulse_coach/test/features/daily_plan/generate_daily_plan_test.dart` — add to existing `GenerateDailyPlan — session metrics (AC8)` group (or a new group).

These tests use the in-memory Drift DB (`db = AppDatabase.forTesting(NativeDatabase.memory())`) already set up in `setUp()`. Insert rows directly via `db.dailyPlansDao`.

```dart
group('GenerateDailyPlan — missedSessions from daily_plans table (Story 7.1b)', () {
  test(
    '7.1b-GDP-001: 2 uncompleted plans in last 7d → missedSessions = 2',
    () async {
      setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any)).thenAnswer((_) async => const Right(null));

      // Insert 2 uncompleted daily plans within the 7-day window
      final now = DateTime.now().toUtc();
      await db.dailyPlansDao.insertPlan(DailyPlansCompanion(
        planDate: Value(_dateOffset(-1)),
        planJson: const Value('{}'),
        generatedAt: Value(now),
        createdAt: Value(now),
      ));
      await db.dailyPlansDao.insertPlan(DailyPlansCompanion(
        planDate: Value(_dateOffset(-2)),
        planJson: const Value('{}'),
        generatedAt: Value(now),
        createdAt: Value(now),
      ));

      AiEngineInput? captured;
      when(mockAiEngine.call(any)).thenAnswer((inv) async {
        captured = inv.positionalArguments.first as AiEngineInput;
        return tOutput;
      });

      await sut.call();

      expect(captured!.stateVector.missedSessions, equals(2));
    },
  );

  test(
    '7.1b-GDP-002: plans older than 7d excluded from count',
    () async {
      setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any)).thenAnswer((_) async => const Right(null));

      // Insert 1 uncompleted plan within window + 1 uncompleted plan outside window (8d ago)
      final now = DateTime.now().toUtc();
      await db.dailyPlansDao.insertPlan(DailyPlansCompanion(
        planDate: Value(_dateOffset(-3)),
        planJson: const Value('{}'),
        generatedAt: Value(now),
        createdAt: Value(now),
      ));
      await db.dailyPlansDao.insertPlan(DailyPlansCompanion(
        planDate: Value(_dateOffset(-8)), // outside 7-day window
        planJson: const Value('{}'),
        generatedAt: Value(now),
        createdAt: Value(now),
      ));

      AiEngineInput? captured;
      when(mockAiEngine.call(any)).thenAnswer((inv) async {
        captured = inv.positionalArguments.first as AiEngineInput;
        return tOutput;
      });

      await sut.call();

      // Only the plan 3 days ago is in window → missedSessions = 1
      expect(captured!.stateVector.missedSessions, equals(1));
    },
  );
});
```

Add this helper at the bottom of the test file (alongside the existing `_todayDate()` helper):
```dart
String _dateOffset(int daysOffset) {
  final dt = DateTime.now().add(Duration(days: daysOffset));
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
```

Add `import 'package:drift/drift.dart' show Value;` to the test file imports. `DailyPlansCompanion` is available through the existing `import 'package:pulse_coach/core/database/app_database.dart'` (generated companion classes are exported via `app_database.g.dart`).

---

### State Machine Test Specs

File: `pulse_coach/test/domain/ai/behavioral_state_machine_test.dart` — add a new group after the existing groups.

```dart
// ── NEW: Transition: active → atRisk (Story 7.1b — Q1) ──────────────────────

group('active → atRisk (Q1)', () {
  test('7.1b-UNIT-001: fires when missedSessions >= 2 from active', () {
    final sv = _sv(state: BehavioralState.active, missed: 2);
    final result = machine.evaluate(sv);
    expect(result.newState, equals(BehavioralState.atRisk));
    expect(result.stateChanged, isTrue);
    expect(result.transitionMessage, isNotNull);
    expect(
      result.transitionMessage,
      contains('Ci sei mancato'),
    );
  });

  test('7.1b-UNIT-002: does NOT fire when missedSessions = 1 from active', () {
    final sv = _sv(state: BehavioralState.active, missed: 1);
    final result = machine.evaluate(sv);
    expect(result.newState, equals(BehavioralState.active));
    expect(result.stateChanged, isFalse);
  });

  test(
    '7.1b-UNIT-003: priority guard — active + missed=2 + high RPE → atRisk wins over fatigued',
    () {
      // Rule 1 (active→atRisk) has priority over Rule 3 (active→fatigued).
      // rpe=[9,9]: _lastNAvg(rpe, 2) = 9.0 > 8.0 would fire fatigued rule.
      // But missed=2 triggers atRisk rule first (priority 1).
      final sv = _sv(state: BehavioralState.active, missed: 2, rpe: [9, 9]);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.atRisk));
    },
  );
});
```

---

### Existing Tests That Remain Valid (No Update Needed)

The following existing tests still pass after Story 7.1b changes:

- `5.2-UNIT-003..007`: `active → fatigued` — no missed sessions in fixture (default 0) ✅
- `5.2-UNIT-008..010`: `fatigued → atRisk` — unchanged rule ✅
- `5.2-UNIT-011..015`: `atRisk/fatigued → recovering` — Rule 3 (Q3) is NOT tightened in 7.1b. These tests remain valid as-is. ✅
- `5.2-UNIT-016..020`: `recovering → active` — unchanged rule ✅
- `5.2-UNIT-021..026`: constraints + no-transition stability ✅
- `5.5-UNIT-020`: `missedSessions = 0 for new user` — in-memory DB has no daily_plan rows → `getPlansInDateRange` returns empty list → `MissedSessionsCalculator.calculate([]) = 0` ✅

**Note:** `5.2-UNIT-011` and `5.2-UNIT-012` will break only when Story 7.1 tightens Rule 3 (Q3). They are NOT broken by Story 7.1b. Confirm both still pass after 7.1b gate check.

---

### Test Count Accounting

| Source | Count |
|---|---|
| Baseline (post Story 7.0, current) | 398 |
| `missed_sessions_calculator_test.dart` (new, 8 tests) | +8 |
| `generate_daily_plan_test.dart` (+2 integration tests) | +2 |
| `behavioral_state_machine_test.dart` (+3 rule tests) | +3 |
| **Target** | **411** |

The scope document states baseline 388 → 401 (+13). The real baseline is 398 (Story 7.0 added tests beyond the original projection). The +13 delta is correct; target is 411.

---

### Build Runner

**Not required.** No freezed classes modified, no injectable constructor changed, no `@DriftQuery` annotations added. The new `MissedSessionsCalculator` is a plain Dart class. The new `getPlansInDateRange` DAO method uses Drift's `select()` API directly. Verify `injection.config.dart` is byte-stable after implementing.

---

### DI Registration (No Change)

`GenerateDailyPlan` constructor is NOT changed — `MissedSessionsCalculator` is instantiated inline as `const MissedSessionsCalculator()`, matching the pattern of `const BehavioralStateMachine()` in `ai_engine_isolate.dart`. No new DI entry needed.

---

### Out of Scope (Explicit)

Per `story-7.1b-scope-2026-05-15.md`:
- Q2 rule (`recovering → fatigued` on `rpe.last >= 9`) — Story 7.1
- Q3 tightening (`atRisk/fatigued → recovering` → 3 RPE avg + `missedSessions == 0`) — Story 7.1
- "Welcome back" courtesy reset after long absence — possible Story 7.1c, requires Sally copy
- `streak` decay with same pattern — future story
- UI surfacing of `missedSessions` directly — `StateIndicator` (Story 7.1) consumes `BehavioralState`
- Any Drift migration script
- Performance optimization of the daily-plan query

### Project Structure Notes

- New file `lib/ai/missed_sessions/missed_sessions_calculator.dart` — mirrors existing `lib/ai/state_machine/`, `lib/ai/bandit/`, etc. subdirectory pattern under `lib/ai/`
- New test file `test/ai/missed_sessions/missed_sessions_calculator_test.dart` — mirrors lib path per project convention
- `DailyPlan` naming conflict: Drift data class from `app_database.dart` vs domain entity from `features/daily_plan/domain/entities/daily_plan.dart as domain`. The new DAO method and calculator call site deal only with Drift's `DailyPlan` — ensure no import confusion in `generate_daily_plan.dart` (domain entity is already aliased as `domain.DailyPlan`)
- `_dateOffset` helper in generate_daily_plan_test.dart: add alongside the existing `_todayDate()` at the bottom of the file

### References

- Scope document: [`_bmad-output/implementation-artifacts/story-7.1b-scope-2026-05-15.md`]
- State-graph decisions (Q1, Q2, Q3, Final Rule Set): [`_bmad-output/implementation-artifacts/ai-state-graph-product-decisions-2026-05-15.md`]
- `BehavioralStateMachine` current code: [`pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart`]
- `GenerateDailyPlan` use case: [`pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart`]
- `DailyPlansDao`: [`pulse_coach/lib/core/database/daos/daily_plans_dao.dart`]
- `DailyPlans` table schema: [`pulse_coach/lib/core/database/tables/daily_plans_table.dart`]
- Existing state machine tests: [`pulse_coach/test/domain/ai/behavioral_state_machine_test.dart`]
- Existing GDP tests: [`pulse_coach/test/features/daily_plan/generate_daily_plan_test.dart`]
- Sprint binding constraints: [`_bmad-output/planning-artifacts/epics.md#Epic 7`]
- Story 7.0 (done, merged): [`_bmad-output/implementation-artifacts/7-0-failure-equality-bloc-regression.md`]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-05-15: Targeted red test run failed as expected before implementation: missing `MissedSessionsCalculator`, `active -> atRisk` assertions failing, and daily-plan missed count still sourced from sessions.
- 2026-05-15: Targeted green test run passed for calculator, `GenerateDailyPlan`, and state machine files.
- 2026-05-15: Full `flutter test` from `pulse_coach/` passed: 411/411.
- 2026-05-15: `flutter analyze` from `pulse_coach/` passed: No issues found.

### Completion Notes List

- Added daily-plan date range retrieval through `DailyPlansDao.getPlansInDateRange`.
- Added `MissedSessionsCalculator` and wired `GenerateDailyPlan` to compute `missedSessions` from `daily_plans.isCompleted` within the inclusive 7-day window.
- Preserved streak calculation from `sessionsDao` and removed the old sessions-table missed-session helper.
- Added the Story 7.1b Q1 `active -> atRisk` rule ahead of high-RPE fatigue evaluation, with the required Italian transition message.
- Added 13 tests covering calculator boundaries, daily-plan integration window semantics, and state-machine priority behavior.

### File List

- `_bmad-output/implementation-artifacts/7-1b-missed-sessions-decay-and-reset.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/ai/missed_sessions/missed_sessions_calculator.dart`
- `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart`
- `pulse_coach/lib/core/database/daos/daily_plans_dao.dart`
- `pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart`
- `pulse_coach/test/ai/missed_sessions/missed_sessions_calculator_test.dart`
- `pulse_coach/test/domain/ai/behavioral_state_machine_test.dart`
- `pulse_coach/test/features/daily_plan/generate_daily_plan_test.dart`

### Change Log

- 2026-05-15: Implemented Story 7.1b missed-session decay/reset semantics and moved story to review.
- 2026-05-15: Code review run (Blind Hunter + Edge Case Hunter + Acceptance Auditor). Auditor: 8/8 AC satisfied, 0 deviations. Adversarial findings recorded below.
- 2026-05-15: Review patch applied — window now EXCLUDES today (`[today-7, today-1]`). AC3/AC4/AC5 wording updated to reflect new semantics. Added regression test `7.1b-GDP-003`. Full suite: 412/412 passing. `flutter analyze`: 0 issues. Story moved to `done`.

### Review Findings

- [x] [Review][Patch][Applied 2026-05-15] **Same-day regenerate inflates `missedSessions` by 1 (today's existing plan is counted as missed)** — `windowEnd = _todayDate()` is inclusive of today, and the calculator counts every `!isCompleted` plan. On first-of-day generation today's plan row does not yet exist (correct). On a same-day regenerate, today's row exists with `isCompleted=false` and is counted as a miss, which can prematurely trip `active → atRisk` once one prior uncompleted day is present. The spec's AC2/AC4 examples are internally consistent with today being included, so the implementation faithfully matches the spec — but the regenerate edge case may not be what was intended. Sources: blind, edge. Locations: `pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart:257-267`, `pulse_coach/lib/ai/missed_sessions/missed_sessions_calculator.dart:4-5`.

- [x] [Review][Defer] **DST / local-vs-UTC date boundary risk** [`generate_daily_plan.dart:257-260`] — deferred, pre-existing. `windowStart = DateTime.now().subtract(Duration(days: 6))` uses wall-clock time; across an Italian DST transition this can shift the calendar day by ±1. `_dateStr` reads `.year/.month/.day` of a local DateTime while other code paths sometimes call `.toUtc()`. Same pattern is already used elsewhere in the file. Fix requires a project-wide date-utility cleanup. Sources: blind, edge.

- [x] [Review][Defer] **`isCompleted` is the sole source of truth — orphan/abandoned-plan semantics unverified** [`generate_daily_plan.dart:254-267`] — deferred, pre-existing. Old `_calculateMissedSessions` explicitly excluded `s.abandoned == true` sessions. New logic reads only `daily_plans.isCompleted`. If a session is abandoned mid-flow, the daily plan likely stays `isCompleted=false` and the user is penalized as if disengaged. Needs a separate audit of the completion-flow contract (`markCompleted` call sites). Sources: blind.

- [x] [Review][Defer] **Italian transition message stands alone among English messages in the file** [`behavioral_state_machine.dart:35`] — deferred, pre-existing localization debt. The new Rule 1 message is the Italian copy required by the state-graph decision doc, while existing Rule 2/3/4/5 messages are still English placeholders. The whole file needs i18n extraction (likely a future story). Spec mandates the exact Italian text for Rule 1, so it cannot be "fixed" in isolation. Sources: blind.

- [x] [Review][Defer] **GDP integration tests are timezone-fragile near midnight** [`generate_daily_plan_test.dart:_dateOffset` helper, GDP-001/002] — deferred, pre-existing pattern. Tests use real `DateTime.now()` for both window math and inserted `planDate` values. Test stays internally consistent (both sides use local), but a build straddling midnight or running in CI under a different TZ could produce off-by-one window inclusion. Fix needs an injectable clock; the rest of the suite uses the same pattern. Sources: blind, edge.

#### Dismissed as noise (15)

Not written as action items — captured here for traceability:

- "Days with no plan are not counted as missed" — **by design** per spec Dev Notes (JTBD framing: never-opened day ≠ missed session).
- "No `atRisk → active` reset when `missedSessions` decays" — **out of scope** (Q3 tightening is Story 7.1).
- "Multiple plans on the same date inflate count" — **impossible**: `planDate` has `.unique()` in the table schema (`daily_plans_table.dart:6`).
- "`MissedSessionsCalculator` is over-engineered for a one-liner" — style preference; matches existing `lib/ai/*` subfolder convention and the `const BehavioralStateMachine()` instantiation pattern.
- "Lexicographic string compare on `YYYY-MM-DD`" — safe for zero-padded ISO dates; invariant already established at write sites.
- "DAO param-order swap (`endDate < startDate`)" — defensive paranoia; single caller, parameters are derived inline.
- "Calculator has no result upper bound" — natural cap is window length (7) enforced at DAO level.
- "`getPlansInDateRange` inclusive semantics undocumented" — covered indirectly by GDP-002 (-8d row excluded).
- "5.2-UNIT-015 priority test now technically redundant / no recovering+missed coverage" — minor test-shape observation, not a defect.
- "`_dateOffset` test helper mixes local-string `planDate` with `.toUtc()` timestamps" — internally consistent; same as production code.
- "Sprint-status `last_updated` comment style inconsistent" — cosmetic.
- "Reformatting churn in `behavioral_state_machine_test.dart`" — cosmetic.
- "Class-level doc comment ambiguity on Rule 2 priority phrasing" — cosmetic.
- "Cold-start invariant no longer guarded by a dedicated test" — covered by AC1 + CALC-001 + `_buildStateVector` returning empty list naturally.
- "Calculator hides 7-day window contract from future callers" — single internal caller; not a public API.
