# `Failure` Equality BLoC Re-emission — Regression Test Spec

**Date:** 2026-05-15
**Owner:** Amelia (Dev)
**Status:** Spec ready — task fits inside Story 7.1 or as a 0.25-day pre-task
**Source:** Epic 6.5 retro action item #4 (`epic-6.5-retro-2026-05-15.md`)

---

## Background

Story 6.5.3 introduced structural equality on the `Failure` class via `Object.hash(runtimeType, message)` (`lib/core/error/failures.dart`). Code reviewer explicitly deferred verification of BLoC re-emission behavior, noting *"error states have no UI consumer yet, premature to decide re-emission behavior before Today screen consumes them"*.

`flutter_bloc` `emit()` discards updates when `newState == oldState`. With structural equality:

```dart
emit(Error(CacheFailure('Profile not found')));
emit(Error(CacheFailure('Profile not found'))); // SAME hash+equals → DROPPED
```

If the BLoC state class derives `==` from its payload, the second `emit` is a no-op. The widget will not see the second failure even if the underlying retry attempt failed again. For `StateIndicator` and `SessionCard` (Story 7.1), this could mask repeated transient errors.

This spec defines the regression test that documents (or asserts) the intended behavior **before** the consumer mounts.

---

## Goal

Pin the behavior in a unit/widget test under `pulse_coach/test/`. Two acceptable outcomes:

1. **Confirm coalescing is desired** — write a test that asserts only one error event reaches the widget, and document the trade-off (BLoC reduces UI noise, but the widget cannot distinguish "retry failed again" from "no new attempt").
2. **Re-emit on every attempt** — change the BLoC state to wrap the failure in a class that breaks structural equality (e.g., a `requestId` or `timestamp` field), and assert two emissions are observed.

Decision below: **Outcome 1 — confirm coalescing, document trade-off, add observable counter for retries.**

---

## Decision: Outcome 1 (coalescing confirmed)

**Rationale:**
- Structural equality is the desired default for `Failure` (cheaper to compare, deterministic in tests, matches the Story 6.5.3 intent).
- The "retry failed again" case is better surfaced via a **dedicated `retryAttempts` counter on the BLoC state**, not by re-emitting the same `Failure`. The counter changes the state's structural identity and naturally re-emits, while the `Failure` payload itself stays equal.
- This keeps `Failure` semantics pure (equal failures are equal) and pushes retry telemetry to the BLoC layer where it belongs.

---

## Test Spec

### Test 1 — Coalescing baseline (documents behavior)

**File:** `test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart` (create)

```
test('6.5-EQ-BLOC-001: two consecutive equal CacheFailure emissions coalesce', () {
  // Given a DailyPlanBloc in initial state
  // When two equal CacheFailure('Profile not found') are emitted via the use case
  // Then bloc.stream emits exactly ONE Error state, not two
});
```

**Assertion:** `expectLater(bloc.stream, emitsInOrder([isA<Error>()]))` — single event.

**Acts as documentation:** if a future edit introduces a `requestId` or `timestamp` that breaks equality, this test fails and forces an explicit decision.

### Test 2 — Retry counter forces re-emission

```
test('6.5-EQ-BLOC-002: retry counter increments produce distinct states', () {
  // Given an Error state with retryAttempts=1, CacheFailure('X')
  // When use case fails again and bloc emits Error(retryAttempts=2, CacheFailure('X'))
  // Then bloc.stream emits both states (counter breaks structural equality)
});
```

**Assertion:** two distinct `Error` states observed; `Failure` payload identical, `retryAttempts` differs.

**Prerequisite:** `DailyPlanBloc`'s `Error` state must carry a `retryAttempts: int` field. If absent today, this test red-drives its addition. Add field as part of the same task (lib change: `daily_plan_bloc.dart` freezed Error variant gains `int retryAttempts`).

### Test 3 — Different Failure types do not coalesce

```
test('6.5-EQ-BLOC-003: CacheFailure and NetworkFailure with same message do not coalesce', () {
  // Given a DailyPlanBloc
  // When Error(CacheFailure('X')) then Error(NetworkFailure('X')) are emitted
  // Then bloc.stream emits both — runtimeType differs, structural equality false
});
```

**Assertion:** two distinct `Error` events observed.

This locks the `Object.hash(runtimeType, message)` invariant from Story 6.5.3 at the BLoC layer.

---

## File Changes

### Create
- `test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart` — 3 tests above.

### Modify (conditional on Test 2)
- `lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart` (freezed `Error` variant) — add `int retryAttempts` to the `Error` factory. Default `0`. Increment in the bloc's error handler.
- Regenerate freezed via `dart run build_runner build --delete-conflicting-outputs`.
- Verify `injection.config.dart` byte-stable (no DI surface change expected; this is internal state).

### NOT touched
- `lib/core/error/failures.dart` — `Failure` equality stays as Story 6.5.3 shipped.

---

## Acceptance Criteria

| AC | Then |
|---|---|
| AC1 | `6.5-EQ-BLOC-001` passes — two equal `Error(CacheFailure('X'))` coalesce |
| AC2 | `DailyPlanBloc.Error` exposes `retryAttempts: int` (default 0) |
| AC3 | `6.5-EQ-BLOC-002` passes — incrementing `retryAttempts` re-emits |
| AC4 | `6.5-EQ-BLOC-003` passes — different `Failure` runtimeType re-emits |
| AC5 | `flutter test` baseline: 388 → 391 (or 388 → 388 + 3 = **391**) |
| AC6 | `flutter analyze` remains at 0 |

---

## Effort

- 0.25 day total (test authoring + `retryAttempts` field + build_runner).

---

## Sequencing

This task **must merge before Story 7.1** because `StateIndicator` and `SessionCard` consume `DailyPlanBloc.Error`. If 7.1 is implemented first, the consumer mounts on undocumented behavior and any future change to coalescing has invisible blast radius.

Recommended order in Epic 7 sprint:
1. Failure equality regression test (this spec) — 0.25 day
2. Story 7.1b (`missedSessions` decay) — 1.5 days
3. Story 7.1 (`StateIndicator`) — 3-4 days

Items 1 and 2 can run in parallel; 3 blocks on both.

---

## Sign-off

- 💻 Amelia (Dev) — assigned.
- 👤 Paolo (Project Lead) — spec approved.

Closes Epic 6.5 retro action item #4 once the test ships green.
