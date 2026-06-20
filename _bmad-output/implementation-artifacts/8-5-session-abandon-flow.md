# Story 8.5: Session Abandon Flow

Status: done

## Story

As a user,
I want to abandon a session mid-flow if needed,
so that I'm never locked into a session that isn't right for the moment.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The user taps "Abbandona" during an active session | When a confirmation is requested | A bottom sheet or dialog confirms intent with "Abbandona sessione" and "Continua" options (FR20) |
| AC2 | The user confirms abandonment | When the session is abandoned | The session is marked as abandoned in the `session_logs` table with `elapsed_seconds` and `lastCompletedStepIndex` recorded |
| AC3 | A session is abandoned | When the flow continues | The RPE input screen (`/session/rpe`) is shown for the partial session — abandonment is treated as valid data (FR20, FR21) |

## Tasks / Subtasks

### Task 1: Extend `SessionLogs` table with abandon columns (AC2)

- [x] UPDATE `lib/core/database/tables/session_logs_table.dart`
  - Add `IntColumn get elapsedSeconds` — nullable, stores how many total seconds elapsed when abandon occurred
  - Add `IntColumn get lastCompletedStepIndex` — nullable, stores `currentStepIndex` at time of abandon (zero-based)
  - Add `BoolColumn get abandoned` — non-nullable, defaults to `false` (existing rows remain valid completions)
  - Keep UNIQUE constraint on `(dailyPlanId, sessionIndex)` — it still applies to abandoned sessions too

  ```dart
  // new columns after createdAt:
  BoolColumn get abandoned => boolean().withDefault(const Constant(false))();
  IntColumn get elapsedSeconds => integer().nullable()();
  IntColumn get lastCompletedStepIndex => integer().nullable()();
  ```

- [x] Run Drift codegen: `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`
  - Confirms `SessionLogsCompanion` gains the three new optional fields
  - Drift migrations: since the app has no explicit migration strategy for dev builds, a schema bump is needed. Add `schemaVersion` increment and a `MigrationStrategy` in `AppDatabase` using `Migrator.addColumn` for the three new columns.

### Task 2: Add migration to `AppDatabase` (AC2)

- [x] UPDATE `lib/core/database/app_database.dart`
  - Increment `schemaVersion` by 1 (current value: find via grep)
  - Add `MigrationStrategy` entry (or extend existing one) using `m.addColumn` for each new column:
    - `sessionLogs`, `sessionLogs.abandoned`
    - `sessionLogs`, `sessionLogs.elapsedSeconds`
    - `sessionLogs`, `sessionLogs.lastCompletedStepIndex`
  - Pattern (Drift v2+):
    ```dart
    MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < NEW_VERSION) {
          await m.addColumn(sessionLogs, sessionLogs.abandoned);
          await m.addColumn(sessionLogs, sessionLogs.elapsedSeconds);
          await m.addColumn(sessionLogs, sessionLogs.lastCompletedStepIndex);
        }
      },
    )
    ```

### Task 3: Update `SessionLogsDao` with abandoned-insert method (AC2)

- [x] UPDATE `lib/core/database/daos/session_logs_dao.dart`
  - Add `insertAbandonedLog(SessionLogsCompanion entry)` method — same `InsertMode.insertOrIgnore` pattern as `insertLog` (idempotent; re-abandoning the same session index is a no-op)
  - **No** separate method needed: callers pass a `SessionLogsCompanion` with `abandoned: const Value(true)`, `elapsedSeconds`, and `lastCompletedStepIndex` set; `insertLog` handles both paths. Alternatively, keep a single `insertLog` method and let the companion carry the data — either approach is acceptable; prefer the single method to avoid duplicated insert logic.

### Task 4: Add `confirmAbandon()` to `InSessionCubit` (AC1, AC2, AC3)

- [x] UPDATE `lib/features/session/presentation/bloc/in_session_cubit.dart`
  - Remove or repurpose the existing `abandon()` method — it currently stops timers and emits `isAbandoned: true` without persisting or navigating to RPE. Story 8.5 replaces its body.
  - New behavior for `abandon()`:
    1. Stop `_timer` and `_hrTimer`.
    2. Compute `elapsedSeconds` = total session seconds that have ticked (track via a counter incremented in `_tick`, or compute as sum of completed step durations minus remaining seconds of current step).
    3. Call `_persistAbandon(elapsedSeconds, state.currentStepIndex)`.
    4. Emit `state.copyWith(isAbandoned: true)` **after** persist (same pattern as `_persistCompletion`).
  - Add `_persistAbandon(int elapsedSeconds, int lastStepIndex)`:
    ```dart
    Future<void> _persistAbandon(int elapsedSeconds, int lastStepIndex) async {
      if (_sessionLogsDao != null && _planId != null) {
        final now = DateTime.now();
        try {
          await _sessionLogsDao.insertLog(
            SessionLogsCompanion(
              dailyPlanId: Value(_planId),
              sessionIndex: Value(_sessionIndex),
              completedAt: Value(now),
              createdAt: Value(now),
              abandoned: const Value(true),
              elapsedSeconds: Value(elapsedSeconds),
              lastCompletedStepIndex: Value(lastStepIndex),
            ),
          );
        } catch (e) {
          debugPrint('InSessionCubit: _persistAbandon failed: $e');
        }
      }
      if (!isClosed) emit(state.copyWith(isAbandoned: true));
    }
    ```
  - Track elapsed ticks: add `int _tickCount = 0` and increment in `_tick`. `elapsedSeconds = _tickCount` at the moment of abandon (each tick = 1 second).
  - The confirmation dialog is the **view's responsibility** (see Task 5). The cubit's `abandon()` is called only after confirmation is given — the cubit does not know about the dialog.

### Task 5: Add confirmation bottom sheet in `InSessionPage` (AC1, AC3)

- [x] UPDATE `lib/features/session/presentation/pages/in_session_page.dart`
  - Replace the current `onAbandon: () { _cubit!.abandon(); context.go(AppRouter.today); }` callback with an async handler that:
    1. Shows a `showModalBottomSheet` (or `showDialog`) with "Abbandona sessione" / "Continua" options.
    2. If user confirms → calls `_cubit!.abandon()` (which persists and emits `isAbandoned: true`).
    3. Navigation to RPE is driven by `BlocListener` on `isAbandoned` (same pattern as `isComplete` → `/session/rpe`), NOT by the button handler directly.
  - Add a second `BlocListener` (or expand `listenWhen`) to also listen for `isAbandoned`:
    ```dart
    listenWhen: (previous, current) =>
        (current.isComplete && !previous.isComplete) ||
        (current.isAbandoned && !previous.isAbandoned),
    listener: (context, state) => context.go(AppRouter.sessionRpe),
    ```
  - The bottom sheet must use l10n keys (see Task 6). It should feel recessive and calm — no destructive red, no drama.
  - **Do NOT** navigate in the button's `onPressed`; navigate only from the BlocListener. This keeps the state-driven flow consistent with `isComplete`.

### Task 6: Add l10n keys for the confirmation dialog (AC1)

- [x] UPDATE `lib/l10n/app/app_it.arb`
  - Add:
    ```json
    "inSessionAbandonConfirmTitle": "Vuoi abbandonare la sessione?",
    "inSessionAbandonConfirmBody": "Il progresso parziale verrà registrato.",
    "inSessionAbandonConfirmButton": "Abbandona sessione",
    "inSessionAbandonKeepGoingButton": "Continua"
    ```

- [x] UPDATE `lib/l10n/app/app_en.arb`
  - Add matching English keys:
    ```json
    "inSessionAbandonConfirmTitle": "Abandon this session?",
    "inSessionAbandonConfirmBody": "Partial progress will be recorded.",
    "inSessionAbandonConfirmButton": "Abandon session",
    "inSessionAbandonKeepGoingButton": "Keep going"
    ```

- [x] Run `flutter pub get` (triggers `gen_l10n`) and confirm the four new getters appear in the generated `AppLocalizations`.

### Task 7: Unit tests — `InSessionCubit` abandon path (AC2)

- [x] UPDATE `test/bloc/in_session_cubit_test.dart`
  - **8.5-CUBIT-001:** `abandon()` after 3 ticks → `isAbandoned` is true, `isComplete` is false
  - **8.5-CUBIT-002:** `abandon()` after 3 ticks → `_persistAbandon` called with `elapsedSeconds = 3` and `lastCompletedStepIndex = 0` (use a `FakeSessionLogsDao` that records calls)
  - **8.5-CUBIT-003:** `abandon()` is idempotent — calling twice does not emit a second state (guard with `isClosed`)
  - **8.5-CUBIT-004:** `abandon()` without `sessionLogsDao` (null) → still emits `isAbandoned: true` (graceful no-op for the persist step)
  - Follow existing test structure: `testWidgets` with `tester.pump(Duration(seconds: N))` for timer-driven tests.

  ```dart
  // FakeSessionLogsDao stub (add at top of test file):
  class _FakeSessionLogsDao extends Fake implements SessionLogsDao {
    final List<SessionLogsCompanion> insertedLogs = [];

    @override
    Future<int> insertLog(SessionLogsCompanion entry) async {
      insertedLogs.add(entry);
      return 1;
    }
  }
  ```

### Task 8: Widget test — confirmation dialog appears and routes (AC1, AC3)

- [x] UPDATE `test/widget/in_session_view_test.dart` (or create `test/widget/in_session_page_abandon_test.dart`)
  - **8.5-VIEW-001:** Tapping "Abbandona" shows the bottom sheet / dialog
  - **8.5-VIEW-002:** Tapping "Continua" in the bottom sheet dismisses it without calling `onAbandon`
  - **8.5-VIEW-003:** Tapping "Abbandona sessione" in the bottom sheet calls `onAbandon` once
  - Use `MockGoRouter` or a `GoRouter` with a test observer to verify navigation target.
  - `InSessionView` currently accepts `VoidCallback onAbandon` — tests for the view remain straightforward. The dialog logic lives in `InSessionPage`, so test that separately with a real or mocked router.

### Task 9: Baseline verification (AC1, AC2, AC3)

- [x] Run `flutter test` from `pulse_coach/` — expect all existing 566 tests to pass plus the new ones
- [x] Run `flutter analyze` — expect 0 issues
- [ ] Manual smoke test on device — **N/A: skipped**, no attached Android device at the time of implementation (review code-review reconciliation 2026-05-17). Steps to run when a device is available:
  - Start a session → tap "Abbandona" → confirm bottom sheet appears
  - Tap "Continua" → sheet dismisses, session resumes
  - Tap "Abbandona" again → confirm → navigates to RPE screen
  - Verify a row with `abandoned = 1` exists in the DB (use debug print or SQLite viewer)

## Dev Notes

### Current State of Files Being Modified

**`in_session_cubit.dart` (line 130-138) — current `abandon()` body:**
```dart
void abandon() {
  _timer?.cancel();
  _hrTimer?.cancel();
  if (!isClosed) emit(state.copyWith(isAbandoned: true));
}
```
This must gain: (a) elapsed-seconds tracking via `_tickCount`, (b) `_persistAbandon` call, (c) `isAbandoned` emission moved to after the persist (async, same pattern as `_persistCompletion`). The method becomes `Future<void> abandon()` — caller does not need to await it but should use `unawaited()` if called from sync context (see `_persistCompletion` pattern at line 86).

**`in_session_page.dart` (line 98-103) — current `onAbandon` callback:**
```dart
onAbandon: () {
  _cubit!.abandon();
  context.go(AppRouter.today);
},
```
This is the **exact** code to replace. After Story 8.5:
- The callback shows the confirmation bottom sheet (async handler).
- Navigation is driven by BlocListener on `isAbandoned` → routes to `AppRouter.sessionRpe` (NOT `AppRouter.today`).

**`session_logs_table.dart` — currently has no `abandoned`, `elapsedSeconds`, or `lastCompletedStepIndex` columns.** Adding nullable/defaulted columns requires both the table definition AND a migration so existing installs don't crash.

### Architecture Compliance

- **ARCH9 (graceful degradation):** `_persistAbandon` follows the same try/catch/debugPrint pattern as `_persistCompletion`. Never throws; failure is logged only.
- **Idempotent inserts:** `InsertMode.insertOrIgnore` already applied in `insertLog` — if the user somehow triggers abandon twice before the first completes, the second insert is silently dropped. UNIQUE(dailyPlanId, sessionIndex) prevents double-logging.
- **State-driven navigation:** All navigation inside `InSessionPage` must be driven by `BlocListener` state transitions, not by button handlers. This is the established pattern (see `isComplete` listener at `in_session_page.dart:89-94`).
- **No `getIt` in build:** `InSessionPage` already follows this rule — `getIt` is only called in `initState` and `_onCountdownComplete`, not in `build`. Maintain this.
- **l10n:** All user-facing strings must go through `AppLocalizations`. No hardcoded Italian in widget code.
- **Drift codegen:** After any schema change, `dart run build_runner build --delete-conflicting-outputs` must be run. The `.g.dart` companion files are git-tracked (unlike `app_localizations*.dart` which are not).

### Drift Migration Notes

Check `lib/core/database/app_database.dart` for the current `schemaVersion`. Increment by 1. If there is no existing `MigrationStrategy`, add one. If there is one, add the new `from < N` branch. Pattern used in this codebase:

```dart
@override
int get schemaVersion => CURRENT + 1; // bump

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < CURRENT + 1) {
      await m.addColumn(sessionLogs, sessionLogs.abandoned);
      await m.addColumn(sessionLogs, sessionLogs.elapsedSeconds);
      await m.addColumn(sessionLogs, sessionLogs.lastCompletedStepIndex);
    }
  },
);
```

The `generateDailyPlan` streak calculation at `generate_daily_plan.dart:344-359` already filters `abandoned == false` for streak purposes — confirm this still works correctly with the new column (it should, since existing rows default `abandoned = false`).

### UX Guidance (from UX spec)

- The confirmation must be **recessive and calm** — this is not a destructive action screen. No red colors, no alarming copy.
- "Keep going" is the **primary / emphasized** option; "Abandon session" is the secondary/destructive-toned option (lower prominence).
- A `showModalBottomSheet` is preferred over `showDialog` per the epics spec ("bottom sheet or dialog"), but either is acceptable for MVP.
- After abandonment, the flow continues to RPE — abandonment is **data, not failure** (FR21). The RPE page is already at `AppRouter.sessionRpe` (placeholder, Story 9.x); navigation must route there, not to Today.

### Test Infrastructure

Existing test pattern for cubit timer tests:
```dart
testWidgets('...', (tester) async {
  final cubit = InSessionCubit(steps: _steps);
  cubit.start();
  await tester.pump(const Duration(seconds: N));
  expect(cubit.state.someField, expectedValue);
  await cubit.close();
});
```
Use `_FakeSessionLogsDao` (see Task 7) to verify persist calls without a real database.

### Previous Story Intelligence (8.4)

- The `_initFuture` double-init guard pattern (from 8.3 code review) is already applied to `HealthLiveHrService`. Follow the same "init-once, share in-flight future" pattern if you add any async initialization.
- Generated `app_localizations*.dart` files are `.gitignore`'d — do **not** stage them. Only stage `.arb` files.
- Story 8.4 code review P8 confirmed: the git index was cleaned of tracked generated files. Confirm `git status` shows no untracked `.dart` files under `lib/l10n/` after `flutter pub get`.

### References

- Epic 8 story definition: `_bmad-output/planning-artifacts/epics.md` (Epic 8 → Story 8.5)
- FR20, FR21: `_bmad-output/planning-artifacts/prd.md` (Feedback & Adaptation Loop section)
- UX abandon flow: `_bmad-output/planning-artifacts/ux-design-specification.md` (In-Session Experience section)
- Current `InSessionCubit`: `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart`
- Current `InSessionState`: `pulse_coach/lib/features/session/presentation/bloc/in_session_state.dart`
- Current `InSessionPage`: `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`
- Current `InSessionView`: `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart`
- `SessionLogs` table: `pulse_coach/lib/core/database/tables/session_logs_table.dart`
- `SessionLogsDao`: `pulse_coach/lib/core/database/daos/session_logs_dao.dart`
- Story 8.4 (previous): `_bmad-output/implementation-artifacts/8-4-live-heart-rate-display.md`
- Cubit tests pattern: `pulse_coach/test/bloc/in_session_cubit_test.dart`
- View tests pattern: `pulse_coach/test/widget/in_session_view_test.dart`

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-05-17: Red check confirmed missing abandon fields / async cubit API / confirmation UI before implementation.
- 2026-05-17: `dart run build_runner build --delete-conflicting-outputs` completed from `pulse_coach/`; build_runner warned that the option is ignored by the installed version.
- 2026-05-17: `flutter pub get` completed and generated `AppLocalizations` getters for the four abandon confirmation keys.
- 2026-05-17: `adb devices` returned no attached devices, so device manual smoke was not available in this environment.

### Implementation Plan

- Extend `session_logs` with defaulted `abandoned` and nullable partial-progress metadata, then gate v7 migration so fresh v5/v6 recreation paths do not double-add columns.
- Keep the DAO insertion surface as `insertLog(SessionLogsCompanion)` to preserve the existing `InsertMode.insertOrIgnore` idempotency path for both completed and abandoned logs.
- Move abandon handling into `InSessionCubit.abandon()` as an async persist-then-emit flow with elapsed tick tracking and a guard against duplicate abandon calls.
- Add the confirmation bottom sheet in `InSessionPage`, using l10n strings and state-driven navigation to `/session/rpe` through the existing `BlocListener` pattern.

### Completion Notes List

- Added `abandoned`, `elapsedSeconds`, and `lastCompletedStepIndex` to `SessionLogs` and regenerated Drift artifacts.
- Bumped `AppDatabase.schemaVersion` to 7 with migration coverage for v6 to v7 and composite upgrade paths.
- Implemented partial-session abandon persistence in `InSessionCubit`, including graceful no-op when `SessionLogsDao` or `planId` is unavailable.
- Added calm l10n-backed abandon confirmation bottom sheet; "Continua" dismisses and confirmed abandon routes to RPE via state listener.
- Added cubit, DAO, migration, and page-level widget tests for abandon metadata, idempotency, confirmation, dismiss, and RPE routing.
- Updated existing tests affected by the expanded `SessionLog` generated constructor and ARB key count.
- Verified `flutter test --timeout 120s` passes with 605 tests.
- Verified `flutter analyze` reports no issues.
- Manual smoke test was skipped because `adb devices` showed no attached Android device.

### File List

- `_bmad-output/implementation-artifacts/8-5-session-abandon-flow.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/core/database/app_database.dart`
- `pulse_coach/lib/core/database/app_database.g.dart`
- `pulse_coach/lib/core/database/tables/session_logs_table.dart`
- `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart`
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/test/bloc/in_session_cubit_test.dart`
- `pulse_coach/test/bloc/today_session_cubit_test.dart`
- `pulse_coach/test/core/database/app_database_test.dart`
- `pulse_coach/test/core/database/daos/session_logs_dao_test.dart`
- `pulse_coach/test/widget/in_session_page_abandon_test.dart`
- `pulse_coach/test/widget/state_indicator_test.dart`

### Change Log

- 2026-05-17: Implemented Story 8.5 session abandon flow, persistence metadata, confirmation UI, l10n, migrations, generated Drift code, and tests.

### Review Findings

_Code review (2026-05-17) — 3 parallel reviewers (Blind Hunter, Edge Case Hunter, Acceptance Auditor). 18 distinct findings after dedupe: 2 decision-needed · 10 patch · 2 deferred · 4 dismissed._

#### Decision-needed (RESOLVED 2026-05-17)

- [x] [Review][Decision] **Resolved — option (a):** renamed Drift column / Dart field to `currentStepIndex`. Value kept as `state.currentStepIndex` at moment of abandon. Migration v6→v7 updated, generated `.g.dart` regenerated, all tests updated. `lastCompletedStepIndex` off-by-one semantics — column is named "last completed" but cubit writes `state.currentStepIndex` (the *currently in-progress* step). Test `8.5-CUBIT-002` confirms: after 3s on step 0, asserts `lastCompletedStepIndex == 0` even though step 0 is not yet completed. Also misleading on abandon-during-countdown (writes 0 when no step was started). Options: (a) keep value, rename column to `currentStepIndex`; (b) write `currentStepIndex - 1` (nullable / -1 sentinel) and keep the column name; (c) leave as-is and document the semantics in a comment. [`in_session_cubit.dart:_persistAbandon`, `session_logs_table.dart:13`]
- [x] [Review][Decision] **Resolved — option (b):** switched to wall-clock `DateTime` delta computed at abandon. `_startedAt` captured in `start()`; `_now()` injectable via constructor for tests (`tester.pump(Duration)` does not advance real `DateTime.now`, so a `_ManualClock` is used in `8.5-CUBIT-002` etc.). `_tickCount` removed entirely. `_tickCount` semantics — `_tickCount++` runs in `_tick` regardless of branch, so it bumps on the "advance step" no-decrement branch too (phantom tick at every step boundary). Also: app-background pauses the periodic timer, so `elapsedSeconds` actually measures *foreground ticks*, not wall-clock. Options: (a) keep as-is, rename field to `foregroundTickSeconds`; (b) switch to `DateTime` wall-clock delta computed at abandon time; (c) keep tick-based but only increment in the decrement branch (still foreground-only). [`in_session_cubit.dart:_tick`]

#### Patch

- [x] [Review][Patch] **BLOCKER** — Abandoned row blocks subsequent completion of same session via UNIQUE constraint + `InsertMode.insertOrIgnore`. User flow: start N → abandon → restart N → complete → silent no-op insert, completion lost, DB keeps only the abandoned row. [`session_logs_dao.dart:insertLog`, `in_session_cubit.dart:_persistCompletion`]
- [x] [Review][Patch] **BLOCKER** — `TodaySessionCubit._completedFromLogs` does not filter on `log.abandoned`. Every abandoned session is counted as completed by completion ring, `completedIndices`, hero-index advance, and "all done" branch — directly contradicts story intent (partial-progress without crediting). [`today_session_cubit.dart:101-110`]
- [x] [Review][Patch] Race: `abandon()` cancels timers, then awaits `_persistAbandon`, then emits `isAbandoned`. If DAO is slow, UI button remains clickable and the listener navigates only on the late emit (perceived hang). Emit `isAbandoned` (or a transient state that disables the button) *before* awaiting persistence. [`in_session_cubit.dart:abandon`]
- [x] [Review][Patch] Idempotency guard is one-way: if `_persistAbandon` throws, `_abandonRequested = true` is sticky and `isAbandoned` is never emitted — abandon button permanently no-ops with no user feedback. Reset the flag in the catch block (or emit an error state). [`in_session_cubit.dart:abandon`, `_persistAbandon`]
- [x] [Review][Patch] Silent swallow of DAO failure: `_persistAbandon` catches and only calls `debugPrint`, which is a no-op in release. User-facing copy says "Partial progress will be recorded" — if the insert fails, the user believes their data was saved. Use the project logger and/or surface an error state. [`in_session_cubit.dart:_persistAbandon`]
- [x] [Review][Patch] `unawaited(_confirmAndAbandon(context))` discards thrown exceptions from the sheet flow. Wrap in `try/catch` (or attach `.catchError`) so failures aren't end-to-end blind. [`in_session_page.dart:onAbandon`]
- [x] [Review][Patch] Stale context across await + concurrent natural-completion race: if the timer reaches the last step while the confirmation sheet is open, `BlocListener` navigates to RPE while the sheet is still mounted, leaving an orphan sheet or `pop` on a replaced route. Pause the periodic timer when the sheet opens, or auto-pop the sheet from the listener on `isComplete`. [`in_session_page.dart:_confirmAndAbandon`]
- [x] [Review][Patch] Restore v3→v7 composite migration test. Previously the test exercised v3→v6 in one chain; the rewrite splits it into "v3 → v6" and "v6 → v7" tests — the longest real upgrade path (existing v3 user on the new build) is no longer covered. [`app_database_test.dart`]
- [x] [Review][Patch] Sheet buttons have no debounce. Two rapid taps on "Abbandona sessione" call `pop(true)` twice — the second pop unwinds the underlying `InSessionPage` route before `_cubit?.abandon()` runs. Disable buttons on first tap (`bool _popping`). [`in_session_page.dart:_confirmAndAbandon`]
- [x] [Review][Patch] Add regression tests: (1) abandon-then-complete same session — verify completion is recorded and `TodaySessionCubit` reflects it (covers the two BLOCKERs); (2) abandon during countdown — verify either correct semantics or a guard that skips the insert. [`test/bloc/in_session_cubit_test.dart`, `test/bloc/today_session_cubit_test.dart`, `test/widget/in_session_page_abandon_test.dart`]
- [x] [Review][Patch] Task 9 ("Manual verification") in this story is checked `[x]` but Completion Notes record "manual smoke test was skipped because `adb devices` showed no attached Android device". Uncheck the parent task or annotate it as N/A so the spec doesn't overstate completion. [`8-5-session-abandon-flow.md` Task 9]

#### Deferred

- [x] [Review][Defer] ARB key count assertion `expect(userFacingKeys, hasLength(50))` is brittle — any future ARB key addition breaks the test for no semantic reason. Pre-existing pattern, not introduced by this story. [`test/widget/state_indicator_test.dart`] — deferred, pre-existing
- [x] [Review][Defer] `addColumn` cannot retro-apply the `CHECK ("abandoned" IN (0,1))` constraint that fresh installs get in the generated CREATE TABLE. Migrated v6→v7 databases will lack the CHECK invariant — low-severity schema drift, no current consumer relies on it. [`app_database.dart:onUpgrade`] — deferred, low severity

#### Dismissed (4)

- Button hierarchy "inverted" (Continua = FilledButton, Abbandona sessione = TextButton) — actually correct per spec (Continua is the primary/safe action).
- Migration non-atomic with three `addColumn` calls — Drift wraps each `MigrationStrategy.onUpgrade` step in a transaction internally; standard pattern.
- `_FakeSessionLogsDao extends Fake` would throw on unimplemented methods — acceptable test isolation pattern.
- Concurrent abandon + natural-completion race "handled" path — already covered by the timer-pause patch above; flagging twice would be duplication.
