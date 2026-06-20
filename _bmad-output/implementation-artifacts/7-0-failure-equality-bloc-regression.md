# Story 7.0: Failure Equality BLoC Re-emission Regression Test

Status: done

## Story

As a developer,
I want a regression test that pins the `DailyPlanBloc` re-emission behavior when two equal `Failure` instances are emitted,
so that future edits to `Failure` equality or BLoC state shape do not silently change UI behavior on the Today screen.

## Acceptance Criteria

1. **Given** `Failure` has structural equality (`Object.hash(runtimeType, message)`, Story 6.5.3), **when** `DailyPlanState.error(failure: CacheFailure('X'), retryAttempts: 0)` is compared to an identical instance, **then** they are structurally equal — and `flutter_bloc` would drop the second emit. Locked by test `6.5-EQ-BLOC-001`. [Source: `_bmad-output/implementation-artifacts/failure-equality-bloc-regression-spec-2026-05-15.md`]

2. **Given** the `DailyPlanBloc.Error` state exposes a `retryAttempts: int` field (default `0`), **when** two `Error` states carry the same `Failure` but different `retryAttempts` values, **then** they are structurally unequal and both reach the stream. Locked by test `6.5-EQ-BLOC-002`. [Source: `_bmad-output/implementation-artifacts/failure-equality-bloc-regression-spec-2026-05-15.md`]

3. **Given** `Error(CacheFailure('X'))` and `Error(ServerFailure('X'))` (same message, different `runtimeType`), **when** equality is checked, **then** they are not equal — `runtimeType` breaks the hash. Locked by test `6.5-EQ-BLOC-003`. [Source: `_bmad-output/implementation-artifacts/failure-equality-bloc-regression-spec-2026-05-15.md`]

4. **Given** the work completes, **when** `flutter test` and `flutter analyze` run from `pulse_coach/`, **then** baseline is **388 → 391** (3 new tests) and `flutter analyze` remains at **0 issues**. [Source: `_bmad-output/implementation-artifacts/failure-equality-bloc-regression-spec-2026-05-15.md#Acceptance Criteria`]

## Tasks / Subtasks

- [x] Task 1: Add `retryAttempts: int` to `DailyPlanState.error` (AC: 2, 4)
  - [x] In `lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`, change the `error` factory to `const factory DailyPlanState.error({required Failure failure, @Default(0) int retryAttempts}) = DailyPlanError;`
  - [x] Update the two error emit call sites in `_onGenerateRequested` and `_onRegenerateRequested` to pass `retryAttempts` — see Dev Notes for the increment logic
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`
  - [x] Verify `daily_plan_bloc.freezed.dart` regenerated; verify `injection.config.dart` is byte-stable (no DI surface change)

- [x] Task 2: Update existing error tests to pass `retryAttempts` (AC: 4)
  - [x] In `test/bloc/daily_plan_bloc_test.dart`, update the two `error` state assertions (`5.5-UNIT-029`, `5.5-UNIT-031`) to include `retryAttempts: 0` (the default) — e.g., `DailyPlanState.error(failure: tFailure, retryAttempts: 0)` — without changing any other assertion logic

- [x] Task 3: Create the 3 regression tests (AC: 1, 2, 3, 4)
  - [x] Create `test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart` (new file; no `@GenerateMocks` needed — these are pure equality tests, no mock generation required)
  - [x] Write `6.5-EQ-BLOC-001`, `6.5-EQ-BLOC-002`, `6.5-EQ-BLOC-003` as described in Dev Notes

- [x] Task 4: Gate verification (AC: 4)
  - [x] Run `flutter test` from `pulse_coach/` — must show **391/391**
  - [x] Run `flutter analyze` from `pulse_coach/` — must show **0 issues**

## Dev Notes

### What This Story Is

A 0.25-day pre-task that pins the `DailyPlanBloc.Error` equality contract before Story 7.1 (`StateIndicator`) mounts a consumer. The change is surgical: one new field on a freezed state, three new equality unit tests.

**Must merge before Story 7.1.** Stories 7.0 and 7.1b can run in parallel.

### File Changes

**Modify:**
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart` — add `retryAttempts` to error factory, update emit call sites
- `pulse_coach/test/bloc/daily_plan_bloc_test.dart` — update `5.5-UNIT-029` and `5.5-UNIT-031` to include `retryAttempts: 0`

**Regenerate (automatically after build_runner):**
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.freezed.dart`

**Create:**
- `pulse_coach/test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart`

**NOT touched:**
- `lib/core/error/failures.dart` — `Failure` equality stays as Story 6.5.3 shipped
- `lib/core/di/injection.config.dart` — DI surface unchanged; only internal state modified

### DailyPlanBloc.dart: Current State

```dart
// current — NO retryAttempts
const factory DailyPlanState.error({required Failure failure}) = DailyPlanError;
```

**Required change:**
```dart
// add retryAttempts with @Default(0) from freezed_annotation
const factory DailyPlanState.error({
  required Failure failure,
  @Default(0) int retryAttempts,
}) = DailyPlanError;
```

**retryAttempts increment logic** in the event handlers:

The pattern: read `retryAttempts` from the current error state if it's an error; otherwise start at 0. After `emit(loading())`, the state is `DailyPlanLoading`, so you must capture the retry count BEFORE emitting loading:

```dart
Future<void> _onGenerateRequested(
  DailyPlanGenerateRequested event,
  Emitter<DailyPlanState> emit,
) async {
  final retryAttempts = state is DailyPlanError
      ? (state as DailyPlanError).retryAttempts + 1
      : 0;
  emit(const DailyPlanState.loading());
  try {
    final result = await _generateDailyPlan.call();
    result.fold(
      (failure) => emit(DailyPlanState.error(failure: failure, retryAttempts: retryAttempts)),
      (plan) => emit(DailyPlanState.loaded(plan: plan)),
    );
  } catch (e) {
    emit(DailyPlanState.error(failure: CacheFailure(e.toString()), retryAttempts: retryAttempts));
  }
}
```

Apply the same pattern to `_onRegenerateRequested`.

### Failure Equality (Story 6.5.3)

```dart
// lib/core/error/failures.dart
abstract class Failure {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure && runtimeType == other.runtimeType && message == other.message);

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
```

`CacheFailure('X') == CacheFailure('X')` → true (same runtimeType + message)
`CacheFailure('X') == ServerFailure('X')` → **false** (different runtimeType, same message)

### CRITICAL: No `NetworkFailure` Class

The spec's test 003 mentions `NetworkFailure`, but **this class does not exist** in `lib/core/error/failures.dart`. Use `ServerFailure` instead. The existing Failure subclasses are: `ServerFailure`, `CacheFailure`, `SensorFailure`, `LocationFailure`.

### Test Implementation: The 3 Regression Tests

These are pure **state equality unit tests** — no mocks needed, no bloc_test needed:

```dart
// test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';

void main() {
  group('DailyPlanBloc error state equality — BLoC re-emission regression', () {
    test('6.5-EQ-BLOC-001: two consecutive equal CacheFailure emissions coalesce', () {
      // DailyPlanState.error equality is structural: equal failure + equal retryAttempts = equal state.
      // flutter_bloc drops emit(newState) when newState == currentState.
      // This test pins that invariant: if a future edit adds requestId/timestamp,
      // this test fails and forces an explicit decision.
      const s1 = DailyPlanState.error(
        failure: CacheFailure('Profile not found'),
        retryAttempts: 0,
      );
      const s2 = DailyPlanState.error(
        failure: CacheFailure('Profile not found'),
        retryAttempts: 0,
      );
      expect(s1, equals(s2));
    });

    test('6.5-EQ-BLOC-002: retry counter increments produce distinct states', () {
      // A different retryAttempts value breaks structural equality.
      // Incrementing the counter before re-emitting ensures flutter_bloc sees a new state.
      const s1 = DailyPlanState.error(
        failure: CacheFailure('Profile not found'),
        retryAttempts: 1,
      );
      const s2 = DailyPlanState.error(
        failure: CacheFailure('Profile not found'),
        retryAttempts: 2,
      );
      expect(s1, isNot(equals(s2)));
    });

    test('6.5-EQ-BLOC-003: CacheFailure and ServerFailure with same message do not coalesce', () {
      // runtimeType is part of the Failure hash (Object.hash(runtimeType, message)).
      // CacheFailure('X') != ServerFailure('X') despite equal message.
      const s1 = DailyPlanState.error(
        failure: CacheFailure('connection failed'),
        retryAttempts: 0,
      );
      const s2 = DailyPlanState.error(
        failure: ServerFailure('connection failed'),
        retryAttempts: 0,
      );
      expect(s1, isNot(equals(s2)));
    });
  });
}
```

### Updating Existing Tests (daily_plan_bloc_test.dart)

After adding `retryAttempts` to the freezed `Error` state, the two existing error-state assertions in `test/bloc/daily_plan_bloc_test.dart` will break because they use `const DailyPlanState.error(failure: tFailure)` without `retryAttempts`. Update them to:

```dart
// 5.5-UNIT-029 and 5.5-UNIT-031 — add retryAttempts: 0
const DailyPlanState.error(failure: tFailure, retryAttempts: 0),
```

### build_runner After Freezed Change

```bash
# from pulse_coach/
dart run build_runner build --delete-conflicting-outputs
```

Expect: `daily_plan_bloc.freezed.dart` regenerated. `injection.config.dart` byte-stable.

### Test Count Accounting

| State | Count |
|---|---|
| Baseline (pre-story) | 388 |
| New tests (6.5-EQ-BLOC-001..003) | +3 |
| **Target** | **391** |

Existing tests `5.5-UNIT-029` and `5.5-UNIT-031` are updated (not new) — they stay in the count as-is.

### Project Structure Notes

- New test file mirrors lib path: `lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart` → `test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart`
- The existing `test/bloc/daily_plan_bloc_test.dart` uses a flat `test/bloc/` structure (historic deviation from mirror convention). The new file follows the architecture standard (mirror path) per `project-context.md`.
- No `@GenerateMocks` annotation in the new test file — no mocks needed.

### References

- Authoritative spec: [`_bmad-output/implementation-artifacts/failure-equality-bloc-regression-spec-2026-05-15.md`]
- Failure equality implementation: [`pulse_coach/lib/core/error/failures.dart`] (Story 6.5.3)
- DailyPlanBloc current implementation: [`pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`]
- Existing BLoC tests: [`pulse_coach/test/bloc/daily_plan_bloc_test.dart`] (tests `5.5-UNIT-027..032`)
- Epic 7 binding constraint: Story 7.0 must merge **before** Story 7.1 [`_bmad-output/planning-artifacts/epics.md#Epic 7`]
- Action-item ledger entry: Epic 6.5 retro action item #4 [`_bmad-output/implementation-artifacts/action-item-ledger.md`]

### Review Findings

_Source: `/bmad-code-review` 2026-05-15 — Blind Hunter + Edge Case Hunter + Acceptance Auditor. Acceptance Auditor: PASS (all 4 AC verified, NOT-touched list respected, increment pattern matches Dev Notes)._

- [x] [Review][Patch] D1 — Added `6.5-EQ-BLOC-004` `blocTest` that drives `DailyPlanBloc` through error→retry→error and asserts distinct emissions with `retryAttempts: 1` then `retryAttempts: 2`. The new test fails if a future refactor neutralizes the increment, addressing the core regression the story title promises. [`pulse_coach/test/bloc/daily_plan_bloc_test.dart:100-118`]
- [x] [Review][Defer] D2 — Cross-handler counter conflation accepted as current behavior; explanatory comment added in the bloc near both handlers. Decision pending Story 7.1 (StateIndicator) UX semantics. [`pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart:38-43`] — also logged in `deferred-work.md`
- [x] [Review][Patch] D3 — Bumped the bloc-emitted base attempt from `0` to `1`, so the first `error` from a non-`DailyPlanError` state emits `retryAttempts: 1`. The factory `@Default(0)` stays (literal `const DailyPlanState.error(failure: x)` still produces `retryAttempts: 0`), so bloc-emitted errors are now structurally distinguishable from synthetic literals; the first→first re-emit scenario from the regression hypothesis can no longer coalesce. Updated `5.5-UNIT-029` and `5.5-UNIT-031` expectations. [`pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart:44, 72`; `pulse_coach/test/bloc/daily_plan_bloc_test.dart:68, 96`]
- [x] [Review][Defer] Concurrent event race on `state` read [`daily_plan_bloc.dart:42, 71`] — deferred, pre-existing BLoC handler pattern (no `transformer`); if Generate and Regenerate interleave, the second handler sees `Loading` and resets counter to 0. Out of scope for Story 7.0.
- [x] [Review][Defer] `Failure` equality vulnerable to intra-subclass field drift [`lib/core/error/failures.dart`] — deferred, pre-existing Story 6.5.3 design. A future `Failure` subclass adding fields without overriding `==` would silently coalesce; only cross-subclass distinction is locked by `6.5-EQ-BLOC-003`.

**Dismissed (7):** counter unbounded growth (unrealistic), hashCode symmetry untested (functionally OK, `==` is what `flutter_bloc` uses), `when/maybeWhen` signature change (no in-tree callers grep-verified), `@Default(0)` masking call-site migrations (no in-tree callers), `retryAttempts` exposed but unused (Story 7.1 consumes it next), sprint-status flipped without story-doc change (false positive — story doc is in the untracked set), `identical()` on boxed ints platform-dependent (no cross-isolate state comparison).

## Dev Agent Record

### Agent Model Used

GPT-5

### Debug Log References

- 2026-05-15: Red check `flutter test test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart` failed before implementation because `DailyPlanState.error` had no `retryAttempts` named parameter.
- 2026-05-15: Ran `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`; `daily_plan_bloc.freezed.dart` regenerated and `injection.config.dart` remained byte-stable.
- 2026-05-15: Targeted regression test passed: `flutter test test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart` -> 3/3.
- 2026-05-15: Existing BLoC test passed: `flutter test test/bloc/daily_plan_bloc_test.dart` -> 6/6.
- 2026-05-15: Full regression passed: `flutter test` -> 397/397. The story's dated 391-test target is stale relative to the current repository baseline; the required +3 regression tests are included and passing.
- 2026-05-15: Static analysis passed: `flutter analyze` -> No issues found.

### Completion Notes List

- Added `retryAttempts` with default `0` to `DailyPlanState.error`.
- Captured retry count before emitting `loading` in both generate and regenerate handlers so repeated error emissions can become structurally distinct when retrying from an error state.
- Updated existing DailyPlanBloc error-state expectations to include `retryAttempts: 0`.
- Added the three pure equality regression tests locking equal failure coalescing, retry counter inequality, and runtimeType-sensitive failure equality.
- Verified full tests and analyzer pass. Current suite count is 397/397, not the older story baseline of 391/391.

### File List

- `_bmad-output/implementation-artifacts/7-0-failure-equality-bloc-regression.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.freezed.dart`
- `pulse_coach/test/bloc/daily_plan_bloc_test.dart`
- `pulse_coach/test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart`

## Change Log

- 2026-05-15: Implemented Story 7.0 failure equality BLoC regression guard and moved story to review.
- 2026-05-15: Code review (`/bmad-code-review`) — Acceptance Auditor PASS. Triage: 3 decision-needed, 0 patch, 2 defer, 7 dismissed.
  - D1: Added `6.5-EQ-BLOC-004` BLoC-level re-emission test (`test/bloc/daily_plan_bloc_test.dart`).
  - D2: Cross-handler counter conflation deferred to Story 7.1; explanatory comment added in the bloc. Logged in `deferred-work.md`.
  - D3: Bumped bloc-emitted base attempt from `0` to `1` so first-error re-emit no longer coalesces with literal `const DailyPlanState.error(failure: x)`; existing `5.5-UNIT-029` / `5.5-UNIT-031` expectations updated. Spec Dev Notes (showing `: 0`) are superseded.
  - Gate: `flutter test` 398/398 (was 397/397; +1 from D1), `flutter analyze` 0 issues. Story moved to **done**.
