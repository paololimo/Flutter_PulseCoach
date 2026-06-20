# Story 9.1: RPEInput Component

Status: done

## Story

As a user,
I want to tap a single RPE number after a session with zero friction,
So that I can close the feedback loop in under 5 seconds without navigation.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | A session completes or is abandoned | When the RPE screen renders | A single horizontal row of 10 circular tap targets (1-10) is displayed in JetBrains Mono 20sp (FR21, UX-DR9) |
| AC2 | Each tap target | When measured for touch area | Visible diameter is 44dp with effective touch area ≥ 48dp (NFR24, UX-DR9) |
| AC3 | The user taps a number | When the tap is registered | The number highlights immediately (150ms ease-out micro-animation) and the RPE value is submitted — no confirm button, no dialog (UX-DR9, UX-DR18) |
| AC4 | The RPE is submitted | When persisted | It is written to the `rpe_feedback` table with `sessionId`, `rpeValue`, and `timestamp` (FR21) |
| AC5 | The `RpeFeedbackCubit` — **E8-P1 Cubit-lifecycle invariants** | When spec is executed | (a) `submit()` is idempotent — duplicate taps within the 150ms animation window are a no-op; (b) `close()` cancels any pending async I/O; (c) `rpe_feedback` persistence-error paths emit an explicit `error(Failure)` state — NOT `debugPrint`-only (E8-T1 convergence point); (d) at least one test covers each invariant |
| AC6 | Test guardrails — **E7.5-P2 invariant pattern** | When ARB-key assertions are written | Use presence/subset invariants only — no `expect(userFacingKeys, hasLength(N))` magnitude-based assertions; verify: no key removed, all keys load, new keys for this story are present |
| AC7 | New `rpe_feedback` usage — **E8-P3 schema-bump cadence cap** | When spec is drafted | Schema bump v7 → v8 is justified: `rpe_feedback` table already exists but gains a `sessionLogId` nullable FK column so RPE rows can be traced back to the specific session-log entry; RPE feedback is the only known Epic 9 schema change and cannot be consolidated with any Epic 10+ change |
| AC8 | Navigation context from `InSessionPage` | When the `BlocListener` routes to `/session/rpe` | The `planId`, `sessionIndex`, `abandoned` flag, and `sessionType`/`intensity` arm key are passed as route `extra` so `RpePage` can perform the DB write without reaching into any upstream Cubit |

## Tasks / Subtasks

### Task 1: Add `sessionLogId` FK column to `rpe_feedback` table and migrate (AC4, AC7)

- [x] UPDATE `lib/core/database/tables/rpe_feedback_table.dart`
  - Add nullable `IntColumn get sessionLogId` — FK to `session_logs.id` (logical, no hard constraint):
    ```dart
    IntColumn get sessionLogId => integer().nullable()(); // FK to session_logs.id (logical)
    ```
  - Keep `sessionId` column unchanged (legacy FK to `sessions.id`).
  - **E8-P3 justification recorded here:** only schema change in Epic 9; RPE feedback traceability is the sole purpose; no other pending bump exists that could be consolidated.

- [x] UPDATE `lib/core/database/app_database.dart`
  - Increment `schemaVersion` from `7` to `8`.
  - Add v8 migration branch:
    ```dart
    if (from < 8) {
      await m.addColumn(rpeFeedback, rpeFeedback.sessionLogId);
    }
    ```
  - Composite upgrade path from v7 → v8 must also be covered in the migration test.

- [x] Run Drift codegen: `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`
  - Verify `RpeFeedbackCompanion` gains `sessionLogId` as an optional `Value<int?>` field.

### Task 2: Update `RpeFeedbackDao` with idempotent-insert method (AC4, AC5)

- [x] UPDATE `lib/core/database/daos/rpe_feedback_dao.dart`
  - Add `insertFeedbackIdempotent(RpeFeedbackCompanion entry)` using `InsertMode.insertOrIgnore` — safe for retry on double-tap.
  - Keep existing `insertFeedback` (used in tests and legacy paths) unchanged.
  - Optionally add a `watchForSessionLog(int sessionLogId)` stream if `RpeFeedbackCubit` needs reactive confirmation.

### Task 3: Define `RpeSubmitArgs` route contract (AC8)

- [x] CREATE `lib/features/session/domain/entities/rpe_submit_args.dart`
  ```dart
  /// Navigation contract for the /session/rpe route.
  ///
  /// Carries everything RpePage needs to persist RPE without touching upstream Cubits.
  class RpeSubmitArgs {
    final int? planId;
    final int sessionIndex;
    final bool abandoned;
    final String armKey; // '{sessionType}_{intensity}' — used by Story 9.3 reward update
    final int? sessionLogId; // session_logs.id for FK on rpe_feedback row

    const RpeSubmitArgs({
      this.planId,
      required this.sessionIndex,
      required this.abandoned,
      required this.armKey,
      this.sessionLogId,
    });
  }
  ```

- [x] UPDATE `lib/core/routing/app_router.dart`
  - Update the `sessionRpe` route builder to extract `RpeSubmitArgs` from `state.extra`:
    ```dart
    GoRoute(
      path: sessionRpe,
      builder: (context, state) {
        final args = state.extra as RpeSubmitArgs?;
        return RpePage(args: args);
      },
    ),
    ```

### Task 4: Pass `RpeSubmitArgs` from `InSessionPage` on navigation (AC8)

- [x] UPDATE `lib/features/session/presentation/pages/in_session_page.dart`
  - The existing `BlocListener` on `isComplete`/`isAbandoned` already calls `context.go(AppRouter.sessionRpe)`. Extend it to carry `RpeSubmitArgs`:
    ```dart
    listener: (context, state) {
      // Extract armKey from session type + intensity; gracefully default to empty string.
      final session = widget.session;
      final armKey = session != null
          ? '${session.sessionType.name}_${_intensityName(session.intensity)}'
          : '';
      context.go(
        AppRouter.sessionRpe,
        extra: RpeSubmitArgs(
          planId: widget.planId,
          sessionIndex: widget.sessionIndex,
          abandoned: state.isAbandoned,
          armKey: armKey,
          sessionLogId: null, // Story 9.1: populated by the DAO insert in RpeFeedbackCubit
        ),
      );
    },
    ```
  - Add a private helper `_intensityName(int intensity)` that maps the `PlannedSession.intensity` int to the arm-key string (`'low'` / `'medium'` / `'high'`). Mirror the mapping from `ContextualBandit._intensityValue`.
  - **Do NOT** reach into `getIt` or any DAO in `build`; all DI remains in `initState`.

### Task 5: Create `RpeFeedbackCubit` and state (AC3, AC4, AC5)

- [x] CREATE `lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`
  ```dart
  // States: RpeFeedbackInitial | RpeFeedbackAnimating(int rpe) | RpeFeedbackSubmitted | RpeFeedbackError(Failure)
  // No freezed required for this cubit — simple sealed class or plain Cubit pattern is sufficient.
  ```
  - Constructor accepts `RpeFeedbackDao` and `RpeSubmitArgs?`.
  - **`submit(int rpe)` — E8-P1 idempotency invariant:**
    - Guard with `_submitted` bool; second call before state settles → no-op.
    - Emit `RpeFeedbackAnimating(rpe)` immediately (triggers the 150ms highlight).
    - After a 150ms delay (simulates the animation window), persist via `RpeFeedbackDao.insertFeedbackIdempotent`.
    - On success → emit `RpeFeedbackSubmitted`.
    - On failure → emit `RpeFeedbackError(ServerFailure(e.toString()))` — **never** `debugPrint`-only (E8-T1 convergence).
  - **`close()` — E8-P1 dispose invariant:**
    - Cancel any in-flight `Future` via a `CancelableOperation` or a `_closed` guard checked before late emits.
    - Confirm no emit after `close()`.

- [x] CREATE `lib/features/session/presentation/bloc/rpe_feedback_state.dart`
  - Sealed class hierarchy (plain Dart, no freezed needed):
    ```dart
    sealed class RpeFeedbackState {}
    class RpeFeedbackInitial extends RpeFeedbackState {}
    class RpeFeedbackAnimating extends RpeFeedbackState { final int rpe; RpeFeedbackAnimating(this.rpe); }
    class RpeFeedbackSubmitted extends RpeFeedbackState {}
    class RpeFeedbackError extends RpeFeedbackState { final Failure failure; RpeFeedbackError(this.failure); }
    ```

### Task 6: Build `RPEInputWidget` (AC1, AC2, AC3)

- [x] CREATE `lib/features/session/presentation/widgets/rpe_input_widget.dart`
  - Renders a `Row` of 10 `_RpeButton` items for values 1–10.
  - Each `_RpeButton`:
    - Visible diameter: 44dp (`SizedBox(width: 44, height: 44)`) inside a `GestureDetector` or `InkWell` with `splashRadius: 24` (effectively ≥ 48dp touch target via `Padding` or hit-test slop).
    - Label: `Text('$n', style: AppTextStyles.rpeNumbers)` — JetBrains Mono 20sp (use `AppTextStyles.rpeNumbers` constant from `lib/core/theme/app_text_styles.dart`).
    - Selected state: `AnimatedContainer` with `duration: const Duration(milliseconds: 150), curve: Curves.easeOut` — highlight background and/or scale (e.g., scale 1.0 → 1.2, fill with `theme.colorScheme.primary`).
    - Disabled when `selectedRpe != null` (prevents double-tap after first tap registers).
  - Accepts `int? selectedRpe` and `ValueChanged<int> onRpeSelected` — stateless; driven by `RpeFeedbackCubit`.
  - Semantic label per button: `Semantics(label: 'RPE $n', child: ...)`.

### Task 7: Replace `RpePage` placeholder with real implementation (AC1–AC5, AC8)

- [x] UPDATE `lib/features/session/presentation/pages/rpe_page.dart`
  - Replace the current `Text('RPE — Story 9.x')` stub.
  - Wire `BlocProvider` for `RpeFeedbackCubit` (constructed with `getIt<RpeFeedbackDao>()` and the passed `RpeSubmitArgs`).
  - Layout: centered `Column` with:
    1. Instruction text (`l10n.rpePrompt` — see Task 8).
    2. `RPEInputWidget` bound to cubit state.
    3. `BlocListener` on `RpeFeedbackSubmitted` → `context.go(AppRouter.today)` (Story 9.2 will intercept this with MiniSummary; for now Today is the final destination).
    4. `BlocListener` on `RpeFeedbackError` → show a `SnackBar` with the failure message.
  - **No AppBar** (full-screen post-session flow per UX spec; back navigation disabled until RPE submitted or user force-presses back).
  - `Scaffold` background: `theme.colorScheme.surface` — matches in-session calm aesthetic.
  - **No confirm button, no dialog** (AC3, UX-DR9).

### Task 8: Add l10n keys for RPE screen (AC1)

- [x] UPDATE `lib/l10n/app/app_it.arb`
  ```json
  "rpePrompt": "Com'è andata?",
  "rpeSemanticLabel": "Scegli il tuo RPE: {value}",
  "@rpeSemanticLabel": {
    "placeholders": {
      "value": {"type": "int"}
    }
  }
  ```

- [x] UPDATE `lib/l10n/app/app_en.arb`
  ```json
  "rpePrompt": "How did that feel?",
  "rpeSemanticLabel": "Rate your effort: {value}",
  "@rpeSemanticLabel": {
    "placeholders": {
      "value": {"type": "int"}
    }
  }
  ```

- [x] Run `flutter pub get` to trigger `gen_l10n` and confirm `rpePrompt` and `rpeSemanticLabel` getters appear in `AppLocalizations`.

### Task 9: Register `RpeFeedbackCubit` in DI (injectable) (AC4)

- [x] UPDATE the appropriate DI module (likely `lib/core/di/injection.dart` or session-feature module) to register `RpeFeedbackCubit` as `@injectable` (not singleton — each RPE page instance gets its own).
  - Alternatively, construct it inline in `RpePage.build` if the DAO is the only dep; skip DI registration and use `getIt<RpeFeedbackDao>()` directly in the page. Choose whichever is consistent with how `InSessionCubit` is created (non-singleton, created in `_onCountdownComplete`).
  - Run `dart run build_runner build --delete-conflicting-outputs` if annotation-based.

### Task 10: Unit tests — `RpeFeedbackCubit` (AC5, E8-P1 invariants)

- [x] CREATE `test/bloc/rpe_feedback_cubit_test.dart`

  **9.1-CUBIT-001: submit() emits Animating then Submitted on success**
  - `submit(7)` → `[RpeFeedbackAnimating(7), RpeFeedbackSubmitted]`

  **9.1-CUBIT-002: submit() idempotency — second call before Submitted is a no-op**
  - Call `submit(7)`, then immediately `submit(5)` before the 150ms window completes.
  - Assert only one `RpeFeedbackAnimating(7)` emitted; `RpeFeedbackAnimating(5)` never emitted.

  **9.1-CUBIT-003: submit() emits RpeFeedbackError on DAO failure**
  - `FakeRpeFeedbackDao` throws `Exception('db full')`.
  - Assert sequence: `[RpeFeedbackAnimating(7), RpeFeedbackError]`.
  - **Verify the error state is NOT just `debugPrint`** — assert that the emitted `RpeFeedbackError.failure.message` is non-empty (E8-T1 convergence).

  **9.1-CUBIT-004: close() before Submitted — no state emitted after close**
  - Start `submit(7)`, call `close()` before 150ms elapses.
  - Assert no `RpeFeedbackSubmitted` is emitted after `close()`.

  **9.1-CUBIT-005: RpeFeedbackDao insertFeedbackIdempotent is called with correct sessionId and rpeValue**
  - Use a recording fake DAO.
  - Assert the persisted row has `rpeValue == 7`, `sessionId >= 0`, `recordedAt` is recent.

  ```dart
  // FakeRpeFeedbackDao stub (add at top of test file):
  class _FakeRpeFeedbackDao extends Fake implements RpeFeedbackDao {
    final List<RpeFeedbackCompanion> inserted = [];
    bool shouldThrow = false;

    @override
    Future<int> insertFeedbackIdempotent(RpeFeedbackCompanion entry) async {
      if (shouldThrow) throw Exception('db full');
      inserted.add(entry);
      return 1;
    }
  }
  ```

### Task 11: Widget tests — `RPEInputWidget` and `RpePage` (AC1, AC2, AC3)

- [x] CREATE `test/widget/rpe_input_widget_test.dart`

  **9.1-WIDGET-001: Renders exactly 10 buttons labeled 1–10**
  - `pumpWidget(RPEInputWidget(onRpeSelected: (_) {}))`
  - `expect(find.text('1'), findsOneWidget)` … `find.text('10')`

  **9.1-WIDGET-002: Tapping button triggers onRpeSelected with correct value**
  - Tap the button labeled '7'; verify callback receives `7`.

  **9.1-WIDGET-003: After tap, all buttons disabled (no second tap)**
  - Tap '5', then pump; verify tapping '3' does NOT call the callback again.
  - Verify `RpeFeedbackAnimating(5)` state is reflected (button '5' shows highlight style).

  **9.1-WIDGET-004: Touch target ≥ 48dp effective area (AC2)**
  - Use `tester.getSize(find.text('7'))` and confirm the rendered widget size within the row is ≥ 44dp. This is a layout assertion, not a tap-target assertion (widget tests cannot measure OS-level hit-test expansion, but can confirm the widget itself is not undersized).

- [x] CREATE `test/widget/rpe_page_test.dart`

  **9.1-PAGE-001: RpePage renders RPEInputWidget and prompt text**
  - Provide a `MockRpeFeedbackCubit` in initial state; verify `rpePrompt` text present and 10 buttons present.

  **9.1-PAGE-002: RpePage navigates to Today on RpeFeedbackSubmitted**
  - Emit `RpeFeedbackSubmitted`; verify `context.go(AppRouter.today)` is called (use GoRouter test observer).

  **9.1-PAGE-003: RpePage shows SnackBar on RpeFeedbackError**
  - Emit `RpeFeedbackError(ServerFailure('db full'))`; verify SnackBar appears with failure message.

### Task 12: DB migration test — v7 → v8 and v3 → v8 composite (AC7)

- [x] UPDATE `test/core/database/app_database_test.dart`

  **9.1-DB-001: Fresh install (v8) creates rpe_feedback with sessionLogId column**
  - `AppDatabase.forTesting(NativeDatabase.memory())` → verify `PRAGMA table_info(rpe_feedback)` contains `session_log_id`.

  **9.1-DB-002: Migration v7 → v8 adds sessionLogId column**
  - Open db at v7, run migration, verify column present and existing rows have `session_log_id IS NULL`.

  **9.1-DB-003: Composite migration v3 → v8 (longest real upgrade path)**
  - Simulate a user upgrading from v3 (pre-session-logs era) through all intermediate versions to v8.
  - Verify no data loss and all tables accessible.

### Task 13: E7.5-P2 invariant-style ARB test (AC6)

- [x] UPDATE `test/widget/state_indicator_test.dart` (the file that held the brittle `hasLength(50)` assertion)
  - Replace `expect(userFacingKeys, hasLength(N))` with invariant assertions:
    ```dart
    // No key removed: all previously tracked keys still present
    for (final key in _knownKeys) {
      expect(allKeys, contains(key));
    }
    // New Story 9.1 keys are present
    expect(allKeys, contains('rpePrompt'));
    expect(allKeys, contains('rpeSemanticLabel'));
    // All keys load without error (no broken placeholder syntax)
    for (final key in allKeys) {
      expect(() => _lookupKey(l10n, key), returnsNormally);
    }
    ```
  - This closes E7.5-P2 structurally at Story 9.1 merge.

### Task 14: Baseline verification

- [x] Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` — confirm no codegen errors.
- [x] Run `flutter pub get` — confirm `gen_l10n` runs and `rpePrompt` / `rpeSemanticLabel` appear in generated `AppLocalizations`.
- [x] Run `flutter test` from `pulse_coach/` — expect all existing 605 tests to pass plus the new ones.
- [x] Run `flutter analyze` — expect 0 issues.
- [x] Manual smoke test on device (when available):
  - Complete a session → RPE screen appears → tap a number → highlight animation plays → navigates to Today
  - Abandon a session → RPE screen appears → tap a number → same flow
  - Double-tap fast → only one RPE value is recorded in DB

## Dev Notes

### Critical Context: What This Story Replaces

`lib/features/session/presentation/pages/rpe_page.dart` is currently a 10-line placeholder:
```dart
class RpePage extends StatelessWidget {
  const RpePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RPE')),
      body: const Center(child: Text('RPE — Story 9.x')),
    );
  }
}
```
This is the **primary file to replace**. The route exists at `AppRouter.sessionRpe = '/session/rpe'` and is already navigated to by `InSessionPage`'s `BlocListener` on `isComplete`/`isAbandoned`.

### DB Schema Context

Current `schemaVersion = 7` (set in `app_database.dart:61`). The `rpe_feedback` table already exists from the initial schema (`onCreate` path); this story only **adds** the `sessionLogId` nullable column via migration. Existing rows will have `session_log_id = NULL`, which is correct.

The `rpe_feedback` table currently has:
- `id` (PK autoincrement)
- `session_id` (int, logical FK to `sessions.id`)
- `rpe_value` (int, 1–10)
- `recorded_at` (datetime)

After this story: gains `session_log_id` nullable int (logical FK to `session_logs.id`).

**E8-P3 explicit justification:** This is the ONLY known schema change in Epic 9. Stories 9.2 and 9.3 do not require additional table changes. Bump cannot be deferred to a later story because `RpeFeedbackCubit` needs the column at write time to enable Story 9.3's full traceability (armKey + sessionLogId → reward calculation path).

### Existing `rpe_feedback` DAO vs New `insertFeedbackIdempotent`

Existing `RpeFeedbackDao.insertFeedback` (at `daos/rpe_feedback_dao.dart:14`) uses the default insert mode. Add `insertFeedbackIdempotent` alongside it using `InsertMode.insertOrIgnore`. **Do NOT change `insertFeedback`** — it is used in `rpe_feedback_dao_test.dart` (3.3-UNIT-009) and potentially other callers.

### `RpeSubmitArgs` Navigation Pattern

Model this exactly after `SessionStartArgs` (at `lib/features/session/domain/entities/session_start_args.dart`) — a plain Dart value object passed as `state.extra` through go_router. No freezed needed.

The `armKey` field is critical for Story 9.3 (bandit reward update). `InSessionPage` must compute it from `widget.session.sessionType.name + '_' + _intensityName(widget.session.intensity)`. The intensity mapping is:
- `1` → `'low'`
- `2` → `'medium'`
- `3` → `'high'`
(Mirror of `ContextualBandit._intensityValue()` in reverse at `lib/ai/bandit/contextual_bandit.dart`.)

### `RPEInputWidget` UX Constraints (from UX Spec)

- UX-DR9 (line 133 of epics.md): 10 circular tap targets (44dp visible, 48dp effective), JetBrains Mono 20sp, immediate visual feedback, **no confirm dialog**.
- UX-DR18 (implicit from motion-reduction rule): animation must respect `MediaQuery.disableAnimations`.
- Use `AppTextStyles.rpeNumbers` (defined at `lib/core/theme/app_text_styles.dart` — JetBrains Mono, 20sp, height 1.0).
- The UX spec calls these buttons "circular" — use `CircleBorder` shape or `BoxDecoration(shape: BoxShape.circle)` with a 44dp `SizedBox`.
- After tap: scale animation from 1.0 → 1.2 OR filled-circle highlight (e.g., `theme.colorScheme.primary`). Keep it subtle — this is a calm post-session flow.
- **No AppBar on `RpePage`** — the post-session close loop is headless and auto-resolves.

### `RpeFeedbackCubit` Error Handling — E8-T1 Convergence

Stories 8.0–8.5 all used `debugPrint` as the sole error signal in Cubit persistence paths. Story 8.5 review flagged this: "User-facing copy says 'Partial progress will be recorded' but if the insert fails, the user believes their data was saved." Story 9.1 is the **E8-T1 convergence point**: all new Cubit error paths MUST:
1. Emit an explicit `error(Failure)` state (observable by `BlocListener`).
2. Show UI feedback (SnackBar or inline error text) via that listener.
3. May additionally log via `debugPrint` or a proper logger, but that is optional.

This means: if `RpeFeedbackDao.insertFeedbackIdempotent` throws, the cubit emits `RpeFeedbackError(ServerFailure(e.toString()))` and the `RpePage` BlocListener shows a SnackBar.

### Architecture Compliance

- **ARCH rule:** `RpeFeedbackCubit` is a `Cubit` (UI-only state) per the Bloc/Cubit split rule — RPE recording does not involve complex event→state domain logic.
- **DI rule:** `RpePage` may construct the Cubit inline with `getIt<RpeFeedbackDao>()` in `createState` or `initState` — consistent with how `InSessionPage` creates `InSessionCubit` in `_onCountdownComplete`. No `getIt` in `build`.
- **Domain purity:** `RpeFeedbackCubit` lives in `lib/features/session/presentation/bloc/` — acceptable since RPE is the tail of the session feature flow. If the team prefers a separate `lib/features/feedback/` feature folder, either is fine as long as the cubit does not import from `domain/` via Flutter imports.
- **No freezed for cubit states:** `InSessionState` is a plain Dart class (not freezed); follow the same pattern for `RpeFeedbackState`.
- **Generated files:** `rpe_feedback_dao.g.dart` is git-tracked. After codegen, stage the updated `.g.dart` file alongside the table/DAO changes.

### Test Infrastructure Notes

- The existing `rpe_feedback_dao_test.dart` (test ID 3.3-UNIT-009) exercises `getLastN`. It uses `AppDatabase.forTesting(NativeDatabase.memory())`. For schema migration tests, use the same pattern.
- Cubit timer/delay tests: `RpeFeedbackCubit.submit()` uses a 150ms `Future.delayed`. In tests, use `fake_async` or inject a `Duration Function()` to control time.
- For cubit tests that verify "no emit after close", use `bloc_test`'s `wait` parameter with a duration > 150ms.
- The bloc_test pattern used throughout this codebase:
  ```dart
  blocTest<RpeFeedbackCubit, RpeFeedbackState>(
    'submit(7) emits Animating then Submitted',
    build: () => RpeFeedbackCubit(dao: _FakeRpeFeedbackDao(), args: _args),
    act: (cubit) => cubit.submit(7),
    wait: const Duration(milliseconds: 200),
    expect: () => [isA<RpeFeedbackAnimating>(), isA<RpeFeedbackSubmitted>()],
  );
  ```

### Previous Story (8.5) Learnings

- **Wall-clock timing over tick counting:** Story 8.5 switched from `_tickCount` to `DateTime` wall-clock delta. For `RpeFeedbackCubit`'s 150ms animation window, use `Future.delayed` with an injectable duration — do not tick-count.
- **`_abandonRequested` guard pattern:** 8.5 used a bool flag to prevent double-submission. Copy the same `_submitted` bool pattern for `RpeFeedbackCubit.submit()`.
- **Generated ARB files:** `app_localizations*.dart` are `.gitignore`'d (closed by Story 8.4 code review P8). Never stage them — only stage `.arb` source files.
- **Confirm `git status` is clean** of any `lib/l10n/` generated files after `flutter pub get`.
- **InsertMode.insertOrIgnore idempotency:** Used in `session_logs_dao.dart` for abandon-then-complete path. Use the same mode for `insertFeedbackIdempotent`.

### E7.5-T1 Status (Dead ARB transition* keys)

The 7 `transition*` ARB keys in `app_it.arb` / `app_en.arb` (e.g., `transitionActiveAtRisk`) are present but their consumers at `lib/ai/state_machine/behavioral_state_machine.dart:35,44,53,68,81,94` still emit hardcoded Italian literals. **Story 9.1 does NOT touch `behavioral_state_machine.dart`** — E7.5-T1 is re-targeted to Story 9.3 as a stretch goal (epics.md line 1522). Do not wire these keys in this story.

### References

- Epic 9 Story 9.1 full spec: `_bmad-output/planning-artifacts/epics.md` (lines 1428–1463)
- E8-P1 Cubit lifecycle invariants: `_bmad-output/implementation-artifacts/action-item-ledger.md` (line 129)
- E8-P3 schema-bump cadence: `action-item-ledger.md` (line 131)
- E8-T1 logger replacement: `action-item-ledger.md` (line 132)
- E7.5-P2 invariant-based test guardrails: `action-item-ledger.md` (line 120)
- E8-P2 hard gate (cleared 2026-05-20): `action-item-ledger.md` (lines 130, 152–189)
- UX RPE spec: `_bmad-output/planning-artifacts/ux-design-specification.md` (UX-DR9, line 613; UX-DR18, line 386)
- `RpeFeedbackDao`: `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart`
- `RpeFeedback` table: `pulse_coach/lib/core/database/tables/rpe_feedback_table.dart`
- Current `AppDatabase` (schemaVersion=7): `pulse_coach/lib/core/database/app_database.dart`
- `AppTextStyles.rpeNumbers`: `pulse_coach/lib/core/theme/app_text_styles.dart`
- `SessionStartArgs` pattern: `pulse_coach/lib/features/session/domain/entities/session_start_args.dart`
- `InSessionPage` current BlocListener: `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart:94-99`
- `ContextualBandit` intensity mapping: `pulse_coach/lib/ai/bandit/contextual_bandit.dart:128-166`
- `banditArmKeys`: `pulse_coach/lib/ai/bandit/bandit_state.dart:30-40`
- Existing `rpe_feedback_dao_test.dart`: `pulse_coach/test/core/database/daos/rpe_feedback_dao_test.dart`
- `app_it.arb` (current 61 user-facing keys): `pulse_coach/lib/l10n/app/app_it.arb`
- Story 8.5 (previous): `_bmad-output/implementation-artifacts/8-5-session-abandon-flow.md`
- Sprint status: `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Dev Agent Record

### Agent Model Used

gpt-5 codex

### Debug Log References

- `flutter test test/core/database/app_database_test.dart` — confirmed v8 schema and migration tests.
- `dart run build_runner build --delete-conflicting-outputs` — regenerated Drift outputs; option is now ignored by current build_runner but build completed successfully.
- `flutter pub get` and `flutter gen-l10n` — refreshed generated localizations locally from ARB sources.
- `flutter test test/bloc/rpe_feedback_cubit_test.dart test/widget/rpe_input_widget_test.dart test/widget/rpe_page_test.dart test/widget/in_session_page_abandon_test.dart test/widget/state_indicator_test.dart test/core/database/app_database_test.dart test/widget/pages_smoke_test.dart` — targeted Story 9.1 regression set passed.
- `flutter analyze` — no issues found.
- `flutter test` — full suite passed: 633 tests.

### Completion Notes List

- Added v8 `rpe_feedback.session_log_id` nullable traceability column with migration coverage for fresh install, v7 -> v8, and v3 -> v8 composite paths.
- Added idempotent RPE persistence through `RpeFeedbackDao.insertFeedbackIdempotent` and `RpeFeedbackCubit` with duplicate-submit, close, success, and error-state guardrails.
- Added `/session/rpe` route args and passed `RpeSubmitArgs` from `InSessionPage`, including abandoned flag and `sessionType_intensity` arm key.
- Replaced the RPE placeholder page with the full post-session no-AppBar flow: prompt, 10 circular RPE targets, immediate 150ms highlight, automatic submit, Today navigation, and SnackBar error feedback.
- Kept RPE targets at 48dp hit wrappers inside a horizontally scrollable row so narrow phone layouts do not overflow while preserving the 44dp visible circles.
- Added RPE l10n source keys and converted the brittle ARB key-count assertion to presence/subset invariants.

### File List

- `_bmad-output/implementation-artifacts/9-1-rpeinput-component.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/core/database/app_database.dart`
- `pulse_coach/lib/core/database/app_database.g.dart`
- `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart`
- `pulse_coach/lib/core/database/tables/rpe_feedback_table.dart`
- `pulse_coach/lib/core/routing/app_router.dart`
- `pulse_coach/lib/features/session/domain/entities/rpe_submit_args.dart`
- `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`
- `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_state.dart`
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`
- `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart`
- `pulse_coach/lib/features/session/presentation/widgets/rpe_input_widget.dart`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/test/bloc/rpe_feedback_cubit_test.dart`
- `pulse_coach/test/core/database/app_database_test.dart`
- `pulse_coach/test/widget/in_session_page_abandon_test.dart`
- `pulse_coach/test/widget/pages_smoke_test.dart`
- `pulse_coach/test/widget/rpe_input_widget_test.dart`
- `pulse_coach/test/widget/rpe_page_test.dart`
- `pulse_coach/test/widget/state_indicator_test.dart`

### Change Log

- 2026-05-20: Implemented Story 9.1 RPE input flow, v8 RPE feedback migration, idempotent Cubit persistence, route args, l10n keys, and guardrail tests.
- 2026-05-21: Code-review findings recorded (Blind + Edge + Acceptance Auditor layers).
- 2026-05-21: Code-review patches applied — all 16 patch findings (P1–P12, D1–D4 converted) resolved. `flutter test` 636/636 green; `flutter analyze` clean. Story moved to `done`.

### Review Findings

**2026-05-21 — Code review (Blind Hunter + Edge Case Hunter + Acceptance Auditor)**

#### Decision-needed (resolved 2026-05-21 → converted to patch)

- [x] [Review][Patch] **D1 → P13 (High) — Wire `sessionLogId` in `RpeFeedbackCubit`** — Resolution: lookup the latest `session_logs` row for `(planId, sessionIndex)` via `SessionLogsDao` before insert; set `RpeFeedbackCompanion.sessionLogId` accordingly. Restores the E8-P3 traceability justification. `lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`.
- [x] [Review][Patch] **D2 → P14 (High) — Replace `InsertMode.insertOrIgnore` with DAO check-then-insert guard** — Resolution: in `RpeFeedbackDao.insertFeedbackIdempotent`, query for an existing row matching `(sessionId, sessionLogId)` (or `(sessionId, recordedAt)` when `sessionLogId` is null) and skip the insert when present. No schema bump — preserves E8-P3 cap. `lib/core/database/daos/rpe_feedback_dao.dart`.
- [x] [Review][Patch] **D3 → P15 (Medium) — Remove `_submitted = false` reset on error** — Resolution: spec-correct single-shot cubit. After `RpeFeedbackError` the cubit stays in error state; the user must dismiss and re-enter `RpePage` (or D4-fix re-renders with selection reset). Add a test asserting that a second `submit()` after error is a no-op. `lib/features/session/presentation/bloc/rpe_feedback_cubit.dart:52`.
- [x] [Review][Patch] **D4 → P16 (Medium) — Replace `SingleChildScrollView` with sized layout** — Resolution: use `LayoutBuilder` + computed circle diameter to fit 10 targets in the available width while preserving the 44dp visible / 48dp effective minimums. Restores AC1 letteral compliance. `lib/features/session/presentation/widgets/rpe_input_widget.dart:20-44`.

#### Patch (unambiguous fixes)

- [x] [Review][Patch] **P1 (Critical) — `sessionId` column receives `planId`** — `RpeFeedbackCompanion(sessionId: _args?.planId ?? 0)` writes the *plan* id into a column documented as a logical FK to `sessions.id`; on null args writes `0`, producing an orphan indistinguishable from a real session. Story 9.3 reward update will read garbage. `lib/features/session/presentation/bloc/rpe_feedback_cubit.dart:43`.
- [x] [Review][Patch] **P2 (High) — Missing `mounted` guards and `listenWhen` previous→current comparison** — `RpePage` BlocListeners call `context.go(today)` and `ScaffoldMessenger.of(context).showSnackBar(...)` without `if (!context.mounted) return;`. `listenWhen: (_, current) => current is RpeFeedbackSubmitted` ignores `previous`, so any rebuild re-delivering Submitted re-navigates. `lib/features/session/presentation/pages/rpe_page.dart` BlocListener blocks.
- [x] [Review][Patch] **P3 (High) — Migration `addColumn` lacks column-exists check** — `if (from < 8)` only verifies the *table* exists, not the *column*. A partially-applied prior v8 (process killed mid-`onUpgrade` after `addColumn` but before `user_version` write) makes the next launch throw `duplicate column name`. Wrap `addColumn` in a `PRAGMA table_info` check or a try/catch on `DatabaseException`. `lib/core/database/app_database.dart:92-103`.
- [x] [Review][Patch] **P4 (High) — Deep-link to `/session/rpe` with no `extra` silently persists garbage** — `RpePage` accepts `args == null`; cubit writes `sessionId: 0, sessionLogId: null, armKey: ''`. Add a guard in `RpePage`/cubit: if `args == null`, redirect to `today` (or show an error state) — do not persist. `lib/core/routing/app_router.dart:85-87`, `lib/features/session/presentation/pages/rpe_page.dart`.
- [x] [Review][Patch] **P5 (Medium) — AC5(b) test does not verify close cancels in-flight DAO persist** — `9.1-CUBIT-004` closes during the 20ms animation window — it verifies the *timer* is cancelled, not that an in-flight `_persist` future is no-op'd. Add a test where the DAO future completes after `close()` and assert no `RpeFeedbackSubmitted` is emitted. `test/bloc/rpe_feedback_cubit_test.dart:73-91`.
- [x] [Review][Patch] **P6 (Medium) — `_intensityName` silently buckets out-of-range intensities** — `<= 1 → low`, `== 2 → medium`, `else → high`. Intensity 0 collapses with 1; intensity 99 silently becomes `high`. Either assert `1 <= intensity <= 3` or emit a warning + empty `armKey` so Story 9.3 bandit space is not polluted. `lib/features/session/presentation/pages/in_session_page.dart:125-129`.
- [x] [Review][Patch] **P7 (Medium) — `armKey == ''` when `widget.session == null`** — Empty arm key is silently submitted into bandit reward path. Guard: skip RPE persist or use a sentinel + log. `lib/features/session/presentation/pages/in_session_page.dart:97-103`.
- [x] [Review][Patch] **P8 (Medium) — No `PopScope` for hardware back on `RpePage`** — Android back returns to `/session/in-session` whose cubit has already emitted `isComplete`; listener re-navigates to RPE with fresh extra, potential loop. Also lets the user escape RPE without submitting. Add `PopScope(canPop: false)` or auto-submit-then-pop. `lib/features/session/presentation/pages/rpe_page.dart`.
- [x] [Review][Patch] **P9 (Low) — Router cast `state.extra as RpeSubmitArgs?` throws on wrong type** — A non-null non-`RpeSubmitArgs` extra (older code path, deep link) raises a runtime cast error instead of degrading to `null`. Use `state.extra is RpeSubmitArgs ? state.extra as RpeSubmitArgs : null`. `lib/core/routing/app_router.dart:85-87`.
- [x] [Review][Patch] **P10 (Low) — Migration test hand-rolls a v7 schema** — `9.1-DB-002` constructs `CREATE TABLE rpe_feedback (...)` manually then opens with `forTesting`; it does not exercise the production v7 `onCreate` path, so a real shape drift would slip through. Use the actual v7 onCreate via a `MigrationStrategy` test helper or snapshot DB. `test/core/database/app_database_test.dart`.
- [x] [Review][Patch] **P11 (Low) — v3→v8 composite test does not assert `session_log_id IS NULL` on migrated rows** — Closes the "preserve old data with null FK" invariant at the read layer. `test/core/database/app_database_test.dart:308-310`.
- [x] [Review][Patch] **P12 (Low) — `armKey` uses `${session.sessionType}` instead of `.name`** — Currently works because `PlannedSession.sessionType` is a `String`, but spec Task 4 prescribes `.name` so a future enum refactor would silently break. `lib/features/session/presentation/pages/in_session_page.dart:99`.

#### Deferred (pre-existing or out of scope)

- [x] [Review][Defer] **DF1 — textScaler ≥ 2.0 may clip '10' inside 48dp circle** [`rpe_input_widget.dart`] — accessibility edge, file as a11y follow-up.
- [x] [Review][Defer] **DF2 — Pointer events on a different button during the 16ms rebuild lag may flicker** [`rpe_input_widget.dart`] — visual only, `_submitted` catches double-tap.
- [x] [Review][Defer] **DF3 — `selectedRpe` deselects visually during brief `Submitted` state before nav** [`rpe_page.dart`] — sub-frame flicker.
- [x] [Review][Defer] **DF4 — Smoke test `find.text('10')` is brittle (matches any literal "10")** [`test/widget/pages_smoke_test.dart:185`].
- [x] [Review][Defer] **DF5 — `Semantics(selected: true)` not announced via `liveRegion: true`** [`rpe_input_widget.dart`] — TalkBack may not re-announce; a11y backlog.
- [x] [Review][Defer] **DF6 — RTL: scroll origin not reversed for RTL locales** [`rpe_input_widget.dart`] — app is `it`-locked.
- [x] [Review][Defer] **DF7 — `_submitTimer` reference not nulled on error reset; rapid re-submit could race two timers** [`rpe_feedback_cubit.dart:34`] — latency only matters for long animation durations in tests.
- [x] [Review][Defer] **DF8 — Smoke test getIt registration is teardown-order-dependent** [`test/widget/pages_smoke_test.dart`] — works today.
- [x] [Review][Defer] **DF9 — Retry-after-close race; cubit is already dying** [`rpe_feedback_cubit.dart:50-55`] — low impact.

#### Dismissed (noise / false positive / handled elsewhere)

- `AppLocalizations.of(context)!` force-unwrap is the codebase standard pattern.
- Sprint-status YAML edit mixed into the diff is expected by the BMad workflow.
- Drift-generated `copyWith` nullable semantics: not actionable, generated code.
- `9.1-PAGE-003` test "missing from diff" is a visibility artefact — `test/widget/rpe_page_test.dart` is a new file listed in the File List.
- EN ARB variant of `rpeSemanticLabel` untested — app is locale-locked to `it`.
