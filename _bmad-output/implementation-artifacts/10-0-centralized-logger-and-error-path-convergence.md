# Story 10.0: Centralized Logger & Error-Path Convergence

Status: done

## Story

As a developer,
I want a single structured logging facility that cubits and use cases route error paths through,
So that DAO/service failures are observable in both UI state and logs instead of being swallowed by scattered `debugPrint` / `developer.log` calls.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | A centralized logger is introduced in `lib/core/logging/` | When a DAO or service call fails inside a cubit or use case | The failure both (a) emits an observable state event (an explicit `error(Failure)` state — never `debugPrint`-only) AND (b) produces a structured log entry through the central logger (closes E8-T1) |
| AC2 | The scattered error-path logging from Stories 8.0/8.2/8.3/8.4/8.5 and 9.1/9.2/9.3 | When this story is implemented | Those call sites converge onto the central logger; no error path remains `debugPrint`-only in `lib/` source (closes E8-T1 + E9R-1) |
| AC3 | The logger | When built in debug vs release | Logging is a real sink in debug (writes to `dart:developer`) and a no-op-safe path in release — user-facing error state is emitted independently of the log sink |
| AC4 | `InSessionCubit.upsertCompletion` fails on a DAO write | When the session completes | The cubit emits `state.copyWith(persistenceError: failure, isComplete: true)` — session UX is not blocked; the error IS observable in state |
| AC5 | `TodaySessionCubit._upsertCompletion` fails | When the completion mark is written | The cubit emits `state.copyWith(persistenceError: failure)` alongside the completion state — session appears completed; error IS observable |
| AC6 | Optional-service failures (haptic, live HR, in-session page confirmation) fail | When called | They log via `AppLogger.warning` (not `error`) and continue silently — no error state emitted (silent degradation is correct per architecture) |

## Tasks / Subtasks

---

### Task 1: Create `lib/core/logging/app_logger.dart` (AC1, AC3)

- [x] CREATE `lib/core/logging/app_logger.dart`

  **Pure Dart — no Flutter imports.** `AppLogger` is a static utility; it never carries state. It wraps `dart:developer` for debug builds and is a no-op-safe call in release.

  ```dart
  import 'dart:developer' as dev;

  import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;

  /// Centralized structured logger for PulseCoach.
  ///
  /// Debug: writes to dart:developer (visible in DevTools / logcat).
  /// Release: the log call is a no-op — user-facing error state is
  /// emitted independently of this sink (AC3).
  abstract final class AppLogger {
    static void debug(
      String message, {
      String name = 'PulseCoach',
      Object? error,
      StackTrace? stackTrace,
    }) {
      if (kDebugMode) {
        dev.log(message, name: name, error: error, stackTrace: stackTrace, level: 500);
      }
    }

    static void warning(
      String message, {
      String name = 'PulseCoach',
      Object? error,
      StackTrace? stackTrace,
    }) {
      if (!kReleaseMode) {
        dev.log(message, name: name, error: error, stackTrace: stackTrace, level: 900);
      }
    }

    static void error(
      String message, {
      String name = 'PulseCoach',
      Object? error,
      StackTrace? stackTrace,
    }) {
      if (!kReleaseMode) {
        dev.log(message, name: name, error: error, stackTrace: stackTrace, level: 1000);
      }
      // In release: no-op. The caller MUST emit an explicit Failure state
      // independently. This sink must never be the sole observability mechanism.
    }
  }
  ```

  **No DI registration needed** — `AppLogger` is a static utility, not a class that gets injected. No `@singleton` / `@injectable` annotation. Import it directly where needed.

  **Import pattern** (use project-relative, not relative):
  ```dart
  import 'package:pulse_coach/core/logging/app_logger.dart';
  ```

---

### Task 2: Add `persistenceError` to `InSessionState` (AC4)

- [x] READ `lib/features/session/presentation/bloc/in_session_state.dart` fully before editing.

- [x] UPDATE `lib/features/session/presentation/bloc/in_session_state.dart`

  `InSessionState` is a plain `class` with `copyWith`. Add a nullable `persistenceError` field:

  ```dart
  import 'package:pulse_coach/core/error/failures.dart';

  // Inside InSessionState, add:
  final Failure? persistenceError;
  ```

  Add it to the constructor, `copyWith`, and `==`/`hashCode` if the class implements those. If `InSessionState` uses `@freezed`, add it as a field with `Failure? persistenceError`. If it is a plain class, add the field with `Failure? persistenceError` as a nullable parameter with default `null`.

  **NOTE**: `InSessionState` is NOT a freezed sealed class (it is a `copyWith` class). Check the actual class before editing. Do not add an `isError` variant — just a nullable field on the existing state.

---

### Task 3: Add `persistenceError` to `TodaySessionState` (AC5)

- [x] READ `lib/features/today/presentation/cubit/today_session_cubit.dart` (or its state file if separate) fully before editing.

- [x] UPDATE `TodaySessionState` to add `Failure? persistenceError` with default `null`.

  From prior review: `TodaySessionState` is a plain class:
  ```dart
  class TodaySessionState {
    // existing fields...
    final Failure? persistenceError; // new

    const TodaySessionState({
      // existing params...
      this.persistenceError,
    });

    TodaySessionState copyWith({
      // existing params...
      Failure? persistenceError, // new — IMPORTANT: use Object? sentinel pattern
                                  // if persistenceError should be clearable to null:
      Object? persistenceError = _sentinel,
    });
  }
  ```

  **IMPORTANT**: Since `persistenceError` may need to be explicitly set back to `null` (after clearing), use the sentinel pattern in `copyWith`:
  ```dart
  static const Object _sentinel = Object();

  TodaySessionState copyWith({
    // ...
    Object? persistenceError = _sentinel,
  }) {
    return TodaySessionState(
      // ...
      persistenceError: identical(persistenceError, _sentinel)
          ? this.persistenceError
          : persistenceError as Failure?,
    );
  }
  ```

---

### Task 4: Converge `debugPrint`-only DAO error paths in cubits (AC1, AC2, AC4, AC5)

For each cubit below: remove `import 'package:flutter/foundation.dart' show debugPrint;` once all `debugPrint` calls in the file are replaced.

#### 4a: `lib/features/session/presentation/bloc/in_session_cubit.dart`

- [x] READ file fully before editing.

There are 3 `debugPrint` call sites:

**Site 1 — `upsertCompletion` (line ~138):**
```dart
// BEFORE:
} catch (e) {
  debugPrint('InSessionCubit: upsertCompletion failed: $e');
}
if (!isClosed) emit(state.copyWith(isComplete: true));

// AFTER (AC4 — emit persistenceError AND isComplete):
} catch (e, st) {
  AppLogger.error(
    'upsertCompletion failed',
    name: 'InSessionCubit',
    error: e,
    stackTrace: st,
  );
  if (!isClosed) {
    emit(state.copyWith(
      persistenceError: ServerFailure('session_log_write_failed'),
      isComplete: true,
    ));
    return;
  }
}
if (!isClosed) emit(state.copyWith(isComplete: true));
```

**WAIT — careful with the flow**: the catch currently falls through to the `if (!isClosed) emit(...)` below. After the patch, if we `return` from catch, the normal `emit(isComplete: true)` won't fire. Fix: always emit isComplete regardless, with or without persistenceError:

```dart
} catch (e, st) {
  AppLogger.error(
    'upsertCompletion failed',
    name: 'InSessionCubit',
    error: e,
    stackTrace: st,
  );
  if (!isClosed) {
    emit(state.copyWith(
      persistenceError: ServerFailure('session_log_write_failed'),
      isComplete: true,
    ));
  }
  return;
}
if (!isClosed) emit(state.copyWith(isComplete: true));
```

This way:
- On success: normal path, `emit(isComplete: true)`
- On failure: `emit(persistenceError + isComplete: true)` and return

**Site 2 — `fetchLiveHr` (line ~165, AC6 — optional service, warning only):**
```dart
// BEFORE:
} catch (e) {
  debugPrint('InSessionCubit: fetchLiveHr failed: $e');
}

// AFTER:
} catch (e, st) {
  AppLogger.warning(
    'fetchLiveHr failed (optional — degrading gracefully)',
    name: 'InSessionCubit',
    error: e,
    stackTrace: st,
  );
}
```
No error state — HR is optional per architecture (silent degradation).

**Site 3 — `_persistAbandon` (line ~213, AC6 — user already navigated away):**
```dart
// BEFORE:
} catch (e) {
  debugPrint('InSessionCubit: _persistAbandon failed: $e');
}

// AFTER:
} catch (e, st) {
  AppLogger.error(
    '_persistAbandon DAO write failed',
    name: 'InSessionCubit',
    error: e,
    stackTrace: st,
  );
  // No error state: isAbandoned was already emitted before this try/catch;
  // UI has navigated away. Log is the only observability here.
}
```

**Remove import**: `import 'package:flutter/foundation.dart' show debugPrint;` after all 3 replacements.

#### 4b: `lib/features/session/presentation/bloc/mini_summary_cubit.dart`

- [x] READ file fully before editing.

**Site — `load` catch (line ~59):**
```dart
// BEFORE:
debugPrint('MiniSummaryCubit: load failed: $e');
if (!isClosed) {
  emit(const MiniSummaryError(ServerFailure(_miniSummaryLoadFailedMessage)));
}

// AFTER:
AppLogger.error(
  'load failed',
  name: 'MiniSummaryCubit',
  error: e,
);
if (!isClosed) {
  emit(const MiniSummaryError(ServerFailure(_miniSummaryLoadFailedMessage)));
}
```

Already emits error state (AC1 satisfied). Just replace `debugPrint` with `AppLogger.error`.

**Remove import**: `import 'package:flutter/foundation.dart' show debugPrint;`

#### 4c: `lib/features/today/presentation/cubit/today_session_cubit.dart`

- [x] READ file fully before editing.

**Site — `_upsertCompletion` catch (line ~153, AC5):**
```dart
// BEFORE:
} catch (e) {
  debugPrint('TodaySessionCubit: upsertCompletion failed: $e');
}

// AFTER:
} catch (e, st) {
  AppLogger.error(
    '_upsertCompletion DAO write failed',
    name: 'TodaySessionCubit',
    error: e,
    stackTrace: st,
  );
  if (!isClosed) {
    emit(state.copyWith(
      persistenceError: ServerFailure('session_log_upsert_failed'),
    ));
  }
}
```

Add `import 'package:pulse_coach/core/error/failures.dart';` if not already present.

**Update `import` line**: `import 'package:flutter/foundation.dart' show debugPrint, setEquals;` → `import 'package:flutter/foundation.dart' show setEquals;` (drop `debugPrint`).

#### 4d: `lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`

- [x] READ file fully before editing.

**Site — `_parseState` fallback (line ~145):**
```dart
// BEFORE:
debugPrint(
  'DailyPlanBloc: unknown BehavioralState string "$stateStr" — '
  'falling back to active.',
);

// AFTER:
AppLogger.warning(
  'Unknown BehavioralState string "$stateStr" — falling back to active',
  name: 'DailyPlanBloc',
);
```

This is a diagnostic warning, not a failure — no error state needed.

**Update import**: `import 'package:flutter/foundation.dart' show debugPrint;` → remove entirely (or keep if `debugPrint` is used elsewhere in the file — check first).

---

### Task 5: Converge `debugPrint`-only service/page failures (AC2, AC6)

These are all **optional-service** paths where silent degradation is correct. Use `AppLogger.warning`.

#### 5a: `lib/features/session/presentation/utils/haptic_service.dart`

- [x] READ file fully before editing.
- 3 `debugPrint` sites (init, trigger, step-transition failures).
- Replace each with `AppLogger.warning(...)`.
- **Remove** `import 'package:flutter/foundation.dart' show debugPrint;`
- Add `import 'package:pulse_coach/core/logging/app_logger.dart';`

#### 5b: `lib/features/session/presentation/utils/live_hr_service.dart`

- [x] READ file fully before editing.
- 2 `debugPrint` sites (init and fetchLiveHr failures).
- Replace each with `AppLogger.warning(...)`.
- **Remove** `import 'package:flutter/foundation.dart' show debugPrint;`
- Add `import 'package:pulse_coach/core/logging/app_logger.dart';`

#### 5c: `lib/features/session/presentation/pages/in_session_page.dart`

- [x] READ file fully before editing.
- 2 `debugPrint` sites (confirmation sheet failure, abandon failure).
- These are page-level catches (not inside a cubit). Replace with `AppLogger.warning(...)`.
- **Remove** `import 'package:flutter/foundation.dart' show debugPrint;` if `debugPrint` is the only foundation import here.

---

### Task 6: Converge `developer.log` call sites onto `AppLogger` (AC2)

Replace scattered `dart:developer` imports and `developer.log(...)` calls with `AppLogger`. For each file:
- Remove `import 'dart:developer' as developer;`
- Add `import 'package:pulse_coach/core/logging/app_logger.dart';`
- Map log levels: `level: 900` or `level: 1000` calls with error/stackTrace → `AppLogger.error`; diagnostic/informational calls without error → `AppLogger.debug` or `AppLogger.warning`

#### 6a: `lib/features/daily_plan/domain/usecases/generate_daily_plan.dart` (5 sites)

- [x] READ file fully before editing.
- Lines 124, 131: corrupt data / cold-start fallback → `AppLogger.warning`
- Line 150: in-isolate debug diagnostic → `AppLogger.debug`
- Lines 337, 344: catch block with `error:` param → `AppLogger.error`
- Remove `import 'dart:developer' as developer;`

#### 6b: `lib/features/session/domain/usecases/update_bandit_reward.dart` (3 sites)

- [x] READ file fully before editing.
- Line 175: catch block in `call()` → `AppLogger.error`
- Line 198: corrupt JSON fallback → `AppLogger.warning`
- Line 209: `_validWeight` corruption recovery log (added in Story 9.3 P3) → `AppLogger.warning`
- Remove `import 'dart:developer' as developer;`

#### 6c: `lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart` (9 sites)

- [x] READ file fully before editing.
- Lines 23, 29: parse/init info → `AppLogger.debug`
- Line 57, 65: load results → `AppLogger.debug`
- Lines 113, 119, 151, 162, 170: cache/parse errors → `AppLogger.error` if they are in catch blocks with an `error:` param, otherwise `AppLogger.warning`
- Remove `import 'dart:developer' as developer;`

---

### Task 7: Unit tests for `AppLogger` + cubit state changes (AC1, AC3, AC4, AC5)

- [x] CREATE `test/core/logging/app_logger_test.dart`

  The logger wraps `dart:developer`. In tests, `kDebugMode = true` by default so the debug path is exercised. The test goal is that the API surface works and does not throw:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/core/logging/app_logger.dart';

  void main() {
    group('AppLogger', () {
      test('10.0-LOG-001: debug() does not throw', () {
        expect(() => AppLogger.debug('test', name: 'TestSuite'), returnsNormally);
      });

      test('10.0-LOG-002: warning() does not throw', () {
        expect(() => AppLogger.warning('warn', name: 'TestSuite', error: Exception('x')), returnsNormally);
      });

      test('10.0-LOG-003: error() does not throw', () {
        expect(() => AppLogger.error('err', name: 'TestSuite', error: Exception('x'), stackTrace: StackTrace.current), returnsNormally);
      });
    });
  }
  ```

- [x] UPDATE `test/bloc/in_session_cubit_test.dart` (if it exists; else create it)

  Add two regression tests for AC4:

  **10.0-CUBIT-001: `_persistCompletion` DAO failure → emits `persistenceError` AND `isComplete: true`**
  - Mock `SessionLogsDao.upsertSessionLog` to throw `Exception('db error')`
  - Trigger session completion step
  - Assert state has `persistenceError != null` AND `isComplete == true`

  **10.0-CUBIT-002: `_persistCompletion` success → `persistenceError` is null in final state**
  - Normal mock setup (DAO succeeds)
  - Assert final state has `persistenceError == null` AND `isComplete == true`

- [x] UPDATE `test/bloc/today_session_cubit_test.dart` (or relevant test file)

  Add one regression test for AC5:

  **10.0-CUBIT-003: `_upsertCompletion` DAO failure → emits `persistenceError` (session still shows completed)**
  - Mock `SessionLogsDao` to throw
  - Trigger completion
  - Assert `state.persistenceError != null`

---

### Task 8: Verification (AC2)

- [x] Run `grep -rn "debugPrint" pulse_coach/lib/ --include="*.dart"` and verify zero occurrences in `lib/` (excluding `.g.dart` and `.freezed.dart` auto-generated files, and any intentional debug output explicitly documented with a comment).
- [x] Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` — no new codegen changes expected (no freezed/injectable changes). Verify clean output.
- [x] Run `flutter analyze` — expect 0 issues.
- [x] Run `flutter test` — expect 685+ existing tests passing plus new ones.
- [x] Confirm `lib/core/logging/app_logger.dart` exists and exports `AppLogger`.

---

### Review Findings

_Adversarial code review 2026-05-24 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). Auditor: all 6 ACs PASS, build/analyze/test gates green (690 tests). 6 findings dismissed as false positives or by-design (see below)._

- [x] [Review][Decision] (RESOLVED 2026-05-24 — dismissed by Paolo: code is AC-conformant, debug-only observability accepted as designed) Zero release-build observability for DAO write failures — `persistenceError` has no UI/BlocListener consumer (grep-confirmed: only the 3 source files + 2 test files reference it) AND `AppLogger.error`/`.warning` are no-ops in release (`if (!kReleaseMode)`). Per spec this is intentional (Dev Notes "No UI Surfacing in This Story" + AC3 release no-op), and all ACs pass. But the story's headline goal — "failures observable instead of swallowed" — is met only in debug. In a release build, a failed session-log write produces no log, no UI signal, and no telemetry; the user is shown the session as completed while the DB has no row. Decision: accept debug-only observability as designed, or open a follow-up for a release sink (Crashlytics/analytics) and/or a UI consumer of `persistenceError`. [blind+edge]

- [x] [Review][Patch] (APPLIED 2026-05-24 — assertions tightened to `const ServerFailure('session_log_write_failed')` / `const ServerFailure('session_log_upsert_failed')`; `failures.dart` imported in both test files; 37/37 pass) Cubit failure-path tests assert only `isNotNull` for `persistenceError`, not the exact `Failure` — the message strings (`session_log_write_failed` / `session_log_upsert_failed`) are load-bearing (they distinguish the two failure sites and would be the i18n key for any future banner), and `Failure` has structural equality, so they can be asserted exactly. [test/bloc/in_session_cubit_test.dart:135, test/bloc/today_session_cubit_test.dart:362] [edge]

- [x] [Review][Defer] Sticky `persistenceError` across `_onLogsChanged` stream ticks — once set on a failed write, `TodaySessionCubit._onLogsChanged` reconciliation emits `copyWith(...)` omitting `persistenceError`, so the sentinel preserves a stale error from session A into session B's successful-completion display. It clears only on the next full `planLoaded` (which constructs a fresh state). In `InSessionState` the clear path is dead within an instance. No live impact today (no consumer); one-line fix is to clear `persistenceError` in `_onLogsChanged`'s emit. [today_session_cubit.dart:108, in_session_cubit.dart:145] — deferred, tie to the future `persistenceError` UI-surfacing story.

**Dismissed (false positives / by-design):**
- Stream-revert "flicker" on failed Today completion — FALSE POSITIVE: a failed `upsertCompletion` writes nothing, so `watchLogsForPlan` does not fire and `_onLogsChanged` never reverts the optimistic `completedIndices`. The optimistic state persists until the next `planLoaded` (documented, AC5-conformant).
- "Divergence between the two cubits' failure paths" — FALSE POSITIVE: both optimistically show completion on write failure (`InSessionCubit` → `isComplete: true`, `TodaySessionCubit` → `completedIndices += hero`). Consistent intent.
- `10.0-CUBIT-003` "assertion may not match code" — FALSE POSITIVE: the test matches the new AC5 behavior exactly.
- `Vibration.vibrate(...).catchError` 2-arg callback — retracted by the reviewer (type-valid, correct handler).
- `_persistAbandon` logs without `persistenceError` — by-design, documented in Dev Notes "_persistAbandon — No Error State Possible" (UI already navigated away).
- Em-dash → hyphen rewrites in log strings — cosmetic, log content is not an AC.

## Dev Notes

### Why This Story Exists

E8-T1 was a Category A deliverable triggered in Epic 8 when `8.4-Defer "project-wide observability gap"` and `8.5-Patch "silent swallow of DAO failure"` were filed. The trigger condition ("first Epic 9.x story touching `lib/core/error/` or introducing a new persistence error path") fired in Story 9.1 but was only partially mitigated — only the symptom (explicit error states) was added; the centralized-logger deliverable was not built. This story closes E8-T1 and E9R-1 before Epic 10's chart/history error paths are added.

### `AppLogger` Design Constraints

1. **No Flutter widget imports** — `AppLogger` lives in `lib/core/logging/`, which is pure Dart. It may only import `dart:developer` and `package:flutter/foundation.dart` (constants only, `kDebugMode` / `kReleaseMode`).
2. **Static utility, not injectable** — Do NOT add `@singleton` / `@injectable`. Import directly.
3. **Release no-op is intentional** — The log sink is decoupled from the user-visible error state. The caller MUST emit a `Failure` state independently. This is enforced in tests (AC3).
4. **Log levels**: `debug` (500) for diagnostics, `warning` (900) for recoverable degradation, `error` (1000) for DAO/service failures that require action.

### Current State of `debugPrint` in the Codebase

As of 2026-05-24, `grep -rn "debugPrint" lib/ --include="*.dart"` (excluding generated files) returns **9 files** with 17 occurrences:

| File | Occurrences | Category |
|---|---|---|
| `features/daily_plan/presentation/bloc/daily_plan_bloc.dart` | 1 | Warning (fallback) |
| `features/session/presentation/bloc/in_session_cubit.dart` | 3 | Error (2 DAO) + Warning (1 optional HR) |
| `features/session/presentation/bloc/mini_summary_cubit.dart` | 1 | Error (has error state — needs logger) |
| `features/session/presentation/pages/in_session_page.dart` | 2 | Warning (page-level) |
| `features/session/presentation/utils/haptic_service.dart` | 3 | Warning (optional service) |
| `features/session/presentation/utils/live_hr_service.dart` | 2 | Warning (optional service) |
| `features/today/presentation/cubit/today_session_cubit.dart` | 1 | Error (DAO) |

All must be replaced. After this story, `grep -rn "debugPrint" lib/` (excluding generated files) must return 0.

### `developer.log` Convergence Map

| File | Sites | Action |
|---|---|---|
| `generate_daily_plan.dart` | 5 | Replace with AppLogger (warning/debug/error per level) |
| `update_bandit_reward.dart` | 3 | Replace with AppLogger (error/warning) |
| `exercise_local_data_source.dart` | 9 | Replace with AppLogger (debug/error) |

Total: 17 `debugPrint` + 17 `developer.log` = 34 convergence points across 9 files.

### Error State vs Logger — Orthogonality Rule

The logger and the error state are **independently emitted**. A failure path MUST:
1. Call `AppLogger.error(...)` (or `.warning()` for optional services)
2. AND emit the appropriate Failure state (if inside a cubit/bloc)

Neither alone is sufficient. The AC validates both channels in the tests.

### `InSessionState.persistenceError` — No UI Surfacing in This Story

Adding `persistenceError` to `InSessionState` makes the error observable in tests. The UI does NOT need to render anything for this field in Story 10.0 — the session completes regardless. UI surfacing of `persistenceError` (e.g., a subtle toast or log entry) can be added in a future story if needed. The field is there for observability and correctness guarantees.

### `InSessionCubit._persistAbandon` — No Error State Possible

The abandon flow is: `emit(isAbandoned: true)` → BlocListener navigates away → `_persistAbandon()` is called after navigation. By the time `_persistAbandon` fails, the UI has already transitioned. There is no cubit consumer left. `AppLogger.error` is the only observability mechanism here — this is an exception to AC1 and is explicitly documented.

### How to Handle `InSessionState.copyWith` Sentinel Pattern

`InSessionState` may already use a `copyWith` with positional or named nullable params. If it already has a `bool` for `isComplete`, adding `Failure? persistenceError` follows the same pattern. Use `Object? persistenceError = _sentinel` only if the field must be explicitly clearable to `null`. For simplicity, if `persistenceError` only ever goes from `null` to a value (never reset), standard `Failure? persistenceError` without sentinel is fine.

Check the actual `in_session_state.dart` to confirm the copyWith pattern before adding the field.

### Test File Structure

Follow the existing mirror structure:
```
lib/features/session/presentation/bloc/in_session_cubit.dart
→ test/bloc/in_session_cubit_test.dart (update)

lib/features/today/presentation/cubit/today_session_cubit.dart
→ test/bloc/today_session_cubit_test.dart (update)

lib/core/logging/app_logger.dart
→ test/core/logging/app_logger_test.dart (create)
```

If `test/bloc/in_session_cubit_test.dart` does not exist, check `test/widget/` for in-session tests — the cubit may be tested there. Run `find test/ -name "*in_session*"` to locate existing tests.

### Learnings from Story 9.3 Applied

- `isClosed` check before every emit — preserved in Tasks 4a/4c.
- Structured log format: always include `name:` param to identify the caller.
- No `@injectable` on new core utilities — static class pattern (same as `MissedSessionsCalculator`).
- No `print()` or `debugPrint` introduced in new code — use `AppLogger` throughout.
- `error:` param to `developer.log` was already the pattern in Stories 8.x/9.x — centralize it.

### Category A Deliverable Closure

After this story ships:
- Mark `E8-T1` as `done` in `action-item-ledger.md`
- Mark `E9R-1` as `done` in `action-item-ledger.md`
- Category A count drops by 2 (from 4 active to 2 active: `E6-T7`, `E6-T8`, `E7-T2`)

### References

- Epic 10 Story 10.0 spec: `_bmad-output/planning-artifacts/epics.md` lines 1544–1564
- E8-T1 action item: `_bmad-output/implementation-artifacts/action-item-ledger.md` (pending)
- E9R-1 action item: `_bmad-output/implementation-artifacts/action-item-ledger.md` (pending)
- Epic 9 retrospective: `_bmad-output/implementation-artifacts/epic-9-retro-2026-05-24.md`
- Previous story 9.3: `_bmad-output/implementation-artifacts/9-3-bandit-reward-update-and-state-machine-re-evaluation.md`
- Existing `core/error/`: `pulse_coach/lib/core/error/failures.dart`, `pulse_coach/lib/core/error/exceptions.dart`
- `InSessionCubit`: `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart`
- `InSessionState`: `pulse_coach/lib/features/session/presentation/bloc/in_session_state.dart` (or inline in cubit)
- `MiniSummaryCubit`: `pulse_coach/lib/features/session/presentation/bloc/mini_summary_cubit.dart`
- `TodaySessionCubit`: `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`
- `DailyPlanBloc`: `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`
- `HapticService`: `pulse_coach/lib/features/session/presentation/utils/haptic_service.dart`
- `LiveHrService`: `pulse_coach/lib/features/session/presentation/utils/live_hr_service.dart`
- `InSessionPage`: `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`
- `GenerateDailyPlan`: `pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart`
- `UpdateBanditReward`: `pulse_coach/lib/features/session/domain/usecases/update_bandit_reward.dart`
- `ExerciseLocalDataSource`: `pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart`
- Sprint status: `_bmad-output/implementation-artifacts/sprint-status.yaml`
- Project context (rules): `_bmad-output/project-context.md`

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-05-24: Red tests added and confirmed failing for missing `AppLogger` and missing `persistenceError` state fields.
- 2026-05-24: `grep -rn "debugPrint" pulse_coach/lib/ --include="*.dart"` returned zero matches.
- 2026-05-24: `dart run build_runner build --delete-conflicting-outputs` completed successfully; the current build_runner version warned that the option was ignored, and no generated-file diff remained.
- 2026-05-24: `flutter analyze` completed with "No issues found!".
- 2026-05-24: `flutter test` completed with 690 passing tests.

### Completion Notes List

- Added `AppLogger` as a static structured logger with debug, warning, and error levels, using `dart:developer` outside release and no DI registration.
- Added `persistenceError` to `InSessionState` and `TodaySessionState` so DAO write failures remain observable while the session completion UX continues.
- Replaced all `debugPrint` call sites in `lib/` with `AppLogger` and converged scattered `developer.log` usage in daily-plan, bandit-reward, and exercise-cache paths.
- Added regression coverage for logger API calls, InSession DAO completion failure/success, and Today DAO completion failure with completed-session state preserved.
- Closed ledger items `E8-T1` and `E9R-1` in `action-item-ledger.md`.

### File List

- `_bmad-output/implementation-artifacts/10-0-centralized-logger-and-error-path-convergence.md`
- `_bmad-output/implementation-artifacts/action-item-ledger.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/core/logging/app_logger.dart`
- `pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart`
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`
- `pulse_coach/lib/features/session/domain/usecases/update_bandit_reward.dart`
- `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart`
- `pulse_coach/lib/features/session/presentation/bloc/in_session_state.dart`
- `pulse_coach/lib/features/session/presentation/bloc/mini_summary_cubit.dart`
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`
- `pulse_coach/lib/features/session/presentation/utils/haptic_service.dart`
- `pulse_coach/lib/features/session/presentation/utils/live_hr_service.dart`
- `pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart`
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`
- `pulse_coach/test/bloc/in_session_cubit_test.dart`
- `pulse_coach/test/bloc/today_session_cubit_test.dart`
- `pulse_coach/test/core/logging/app_logger_test.dart`

### Change Log

- 2026-05-24: Implemented centralized logger and converged error-path logging for Story 10.0; added persistence-error observability and regression tests; moved story to review.
