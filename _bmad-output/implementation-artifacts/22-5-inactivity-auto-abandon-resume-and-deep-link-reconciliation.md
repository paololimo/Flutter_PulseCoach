---
baseline_commit: c9676577bd26044e8c1688c23047603b63a5cca2
---

# Story 22.5: Inactivity Auto-Abandon, Resume and Deep-Link Reconciliation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user who left a session backgrounded,
I want the session to resume when I return in time, or be cleanly abandoned if I don't,
So that stale sessions never orphan state and returning always lands me somewhere sensible.

## Context

**Epic 22, fifth and final story.** Second and last of the epic's two notification stories — Story 22.4 shipped the notification infrastructure, permission prompt, and background-pause-only behavior; this story owns everything 22.4 explicitly deferred: **resume-on-foreground, the inactivity timeout, `backgroundedAt` persistence, auto-abandon-through-FR20, and notification-tap deep-linking.** Epic 22 is now closeable once this story ships.

The five HIGH-severity gaps this story must close (from `review-delta-notification.md`, all explicitly scoped to 22.5 by 22.4's Dev Notes):
- **1c** — the backgrounded-inactivity-timeout mechanism (no foreground service exists, so nothing can "run" while backgrounded — reconcile-on-resume is the only reliable pattern).
- **4a** — notification-tap deep-link + resume, including the already-abandoned case.
- **4b** — rapid background/foreground toggling idempotency (inactivity clock resets on each foreground).
- **4c** — auto-abandon vs. explicit-abandon tagging decision (open, resolved below).
- **4d** — single fixed notification ID + guaranteed clear + cold-start reconciliation of orphaned notifications.

### What already exists (reuse, do not rebuild)

- **`InSessionCubit.pauseTimers()`/`resumeTimers()`** (`lib/features/session/presentation/bloc/in_session_cubit.dart:74-92`) — `resumeTimers()` already exists, is idempotent (`if (_timer != null) return;`), and already no-ops if `state.isComplete`/`isAbandoned`. **This story is the first caller of `resumeTimers()` from the lifecycle path** — 22.4 deliberately never called it. Reuse verbatim.
- **`InSessionCubit.abandon()`** (`in_session_cubit.dart:192-211`) — the existing FR20 abandon flow: emits `isAbandoned: true` first (driving the `BlocListener` in `in_session_page.dart:166-195` to navigate to `AppRouter.sessionRpe`), then persists via `_persistAbandon` (`in_session_cubit.dart:213-240`), which calls `SessionLogsDao.insertLog(...)` in `InsertMode.insertOrIgnore` mode against the `UNIQUE(dailyPlanId, sessionIndex)` constraint. **This `insertOrIgnore` behavior is the safety net this story leans on**: if the cold-start reconciliation path (below) has already committed the abandon row for `(planId, sessionIndex)`, a subsequent in-process `cubit.abandon()` call's `insertLog` silently no-ops (returns `0`) instead of throwing or double-writing — so both the warm (live-cubit) and cold (DAO-direct) commit paths can safely call into the same underlying write without coordinating who "wins."
- **`SessionNotificationService.cancel()`** (`session_notification_service.dart:16,180-192`) — already implemented in 22.4 but **never called from application code yet** (22.4's Dismissed findings explicitly note "ongoing-notification-never-cancelled ... owned by Story 22.5"). This story is the first caller.
- **`SessionLogsDao.insertLog(SessionLogsCompanion)`** (`lib/core/database/daos/session_logs_dao.dart:14-17`) — reuse directly for the cold-start/no-live-cubit commit path (mirrors exactly what `InSessionCubit._persistAbandon` does at `in_session_cubit.dart:213-240`, just called from outside the cubit when no cubit instance exists).
- **`SharedPreferences` via `getIt`** (`lib/core/di/settings_module.dart:8-9`, registered `@singletonAsync`) — already the persistence mechanism for `in_session_page.dart`'s `_kRationaleShownKey`. **Reuse this exact `getIt.isRegistered<SharedPreferences>()` guard pattern** for the new `backgroundedAt` snapshot key(s) — do not introduce a new persistence layer (no new Drift table; a single JSON-encoded string value is sufficient and keeps this story's footprint small).
- **`PlannedSession.fromJson`/`.toJson()`** (`lib/features/daily_plan/domain/entities/planned_session.dart` — `@freezed` + `json_serializable`, part files already generated) — reuse directly to encode/decode the session snapshot; do not hand-roll a parallel serialization.
- **`WidgetsBindingObserver.didChangeAppLifecycleState`** (`in_session_page.dart:123-140`) — 22.4 already wires the observer and handles `AppLifecycleState.paused`. **This story adds the `AppLifecycleState.resumed` branch to the same method** — do not create a second observer.
- **`sessionDisplayName(sessionType, l10n)`** (`lib/features/today/presentation/widgets/session_card_helpers.dart:18-28`) — reuse for any notification content, same as 22.4.
- **`AppRouter.sessionActive`/`AppRouter.today`** (`lib/core/routing/app_router.dart:47,44`) and `SessionStartArgs` (`lib/features/session/domain/entities/session_start_args.dart`) — the existing deep-link navigation contract; extend `SessionStartArgs`, do not invent a parallel one.
- **`main.dart`** (`pulse_coach/lib/main.dart:12-72`) — the existing app-init sequence (`Supabase.initialize` → `Purchases.configure` → `configureDependencies()` → `runApp`). This story's cold-start reconciliation call belongs **after `configureDependencies()` succeeds and before `runApp(const PulseCoachApp())`** — DI must be ready (needs `SessionLogsDao`, `SharedPreferences`) before reconciliation can run.

### The core architectural decision: a single `SessionReconciliationService`

No existing service in this codebase does "read a persisted snapshot, decide abandon-vs-resume-window, write the DB row if abandoning." This is new and is the load-bearing piece of this story. Build **one** class, `SessionReconciliationService`, that is the single source of truth for "is there a backgrounded session, and has its timeout elapsed" — called from two call sites (cold start in `main.dart`, warm resume in `InSessionPage`), so the decision logic is never duplicated:

```dart
enum SessionReconciliationResult { none, stillWithinWindow, abandonedByTimeout }

class SessionReconciliationService {
  SessionReconciliationService(
    this._prefs,
    this._sessionLogsDao, {
    DateTime Function()? now,
    Duration timeout = const Duration(minutes: 5),
  }) : _now = now ?? DateTime.now,
       _timeout = timeout;

  final SharedPreferences _prefs;
  final SessionLogsDao _sessionLogsDao;
  final DateTime Function() _now;
  final Duration _timeout;

  static const String _kSnapshotKey = 'backgrounded_session_snapshot';

  BackgroundedSessionSnapshot? readSnapshot() { ... } // decode _kSnapshotKey, null if absent/corrupt
  Future<void> writeSnapshot(BackgroundedSessionSnapshot snapshot) => ...; // encode + prefs.setString
  Future<void> clearSnapshot() => _prefs.remove(_kSnapshotKey);

  /// Reads the persisted snapshot (if any) and, when the inactivity timeout
  /// has elapsed, authoritatively commits the abandon via a direct DAO write
  /// (idempotent: `insertOrIgnore` on `(dailyPlanId, sessionIndex)`). Does
  /// NOT clear the snapshot on `stillWithinWindow` — only a caller that
  /// actually resumes (live cubit `resumeTimers()`, or a consumed deep-link)
  /// clears it. Does NOT navigate; callers own routing.
  Future<SessionReconciliationResult> reconcile() async {
    final snapshot = readSnapshot();
    if (snapshot == null) return SessionReconciliationResult.none;

    final elapsed = _now().difference(snapshot.backgroundedAt);
    if (elapsed < _timeout) return SessionReconciliationResult.stillWithinWindow;

    if (snapshot.planId != null) {
      await _sessionLogsDao.insertLog(SessionLogsCompanion(
        dailyPlanId: Value(snapshot.planId),
        sessionIndex: Value(snapshot.sessionIndex),
        completedAt: Value(snapshot.backgroundedAt),
        createdAt: Value(snapshot.backgroundedAt),
        abandoned: const Value(true),
        elapsedSeconds: Value(snapshot.elapsedSeconds),
        currentStepIndex: Value(snapshot.currentStepIndex),
      ));
    }
    await clearSnapshot();
    return SessionReconciliationResult.abandonedByTimeout;
  }
}
```

`BackgroundedSessionSnapshot` is a small plain Dart class (not `@freezed` — this is a single internal DTO with 8 fields and manual `toJson`/`fromJson`, not worth the codegen ceremony) holding: `planId` (nullable int), `sessionIndex` (int), `session` (the `PlannedSession`, for rebuilding on deep-link), `currentStepIndex` (int), `secondsRemaining` (int), `elapsedSeconds` (int, the cubit's total elapsed-since-start at the moment of backgrounding), `backgroundedAt` (`DateTime`).

**Why this is not `@injectable`:** it needs `SessionLogsDao` (already `@injectable`-registered) but is only ever constructed at two specific call sites (`main.dart` before `runApp`, and `InSessionPage`'s lifecycle handler) with a manual `getIt<SessionLogsDao>()` / `getIt<SharedPreferences>()` lookup — following the exact "manually constructed service object" precedent `SessionNotificationService`/`HapticService`/`LiveHrService` already established, not the `get_it`/`injectable` singleton pattern (`CLAUDE.md` DI registration order is for app-wide singletons; this is not one).

### Two call sites, two responsibilities — do not conflate them

1. **`InSessionPage.didChangeAppLifecycleState(AppLifecycleState.resumed)`** — the **warm path**: the cubit is still alive in memory (process was never killed). On `resumed`:
   - Guard identically to the `paused` branch: `if (!mounted) return;`, bail if `_cubit == null` or `widget.session == null`.
   - `await` `_reconciliationService.reconcile()`.
   - If `stillWithinWindow`: call `_cubit!.resumeTimers()`, then `await _reconciliationService.clearSnapshot()`, then `unawaited(_notificationService.cancel())` (AC1: "paused session resumes, pending abandon cancelled, notification cleared").
   - If `abandonedByTimeout`: call `unawaited(_cubit!.abandon())` — the DB row is already committed by `reconcile()`, so this call's own `insertLog` harmlessly no-ops (see "safety net" note above); what matters is the **emit** of `isAbandoned: true`, which drives the existing `BlocListener` to navigate to `AppRouter.sessionRpe` exactly as a manual abandon would (see judgment call #2 below for why RPE, not Today, is correct here). Also `unawaited(_notificationService.cancel())`.
   - If `none`: no-op (nothing was ever persisted — e.g. the user backgrounded before this story's snapshot-write path existed on this session, or simply never backgrounded).
   - Do **not** guard on `cubit.state.isComplete`/`isAbandoned` before calling `reconcile()` itself (reconciliation is cheap and idempotent), but DO check `state.isComplete`/`isAbandoned` before calling `resumeTimers()`/`abandon()` — mirror the existing `paused`-branch guard shape at `in_session_page.dart:130`.

2. **Cold-start / no-live-cubit path** — a small top-level function (not a widget), e.g. `Future<void> reconcileAndHandleNotificationLaunch()` living alongside `SessionReconciliationService` (or in a new tiny `lib/features/session/presentation/utils/session_reconciliation_bootstrap.dart` — see File Structure below), called once from `main.dart` after `configureDependencies()`:
   - Construct `SessionReconciliationService` manually from `getIt<SessionLogsDao>()`/`getIt<SharedPreferences>()`.
   - Call `reconcile()` first (this alone satisfies AC2/AC6: timeout-elapsed sessions are committed and the snapshot cleared, and a force-killed process's orphaned notification/snapshot is caught on the very next cold start, before the UI even builds).
   - Then check `await LocalSessionNotificationService().plugin.getNotificationAppLaunchDetails()` (see Task breakdown — this requires exposing the launch-details check on `SessionNotificationService`, a new interface method) for `didNotificationLaunchApp == true`.
     - If true and the (now-updated) snapshot state is `stillWithinWindow` (re-read via `readSnapshot()` — `reconcile()` already ran above so a `none`/`abandonedByTimeout` snapshot has already been cleared): build a `SessionStartArgs` from the snapshot (`session`, `planId`, `sessionIndex`, plus the new `resumeStepIndex`/`resumeSecondsRemaining` fields — see below), call `AppRouter.router.go(AppRouter.sessionActive, extra: args)`, clear the snapshot, cancel the notification. `GoRouter.go()` can be called on the static `AppRouter.router` instance directly (no `BuildContext` needed — it is a plain object method) before `runApp` mounts `MaterialApp.router(routerConfig: AppRouter.router)`; the router's internal location is already updated by the time the widget tree attaches, so `MaterialApp` builds directly into the deep-linked route without an initial flash of Today. Verify this behavior empirically during implementation (pump/pumpAndSettle in a widget test) since it is the one piece of this story's design with no existing codebase precedent.
     - If true but the snapshot is now cleared/absent (`abandonedByTimeout` or `none`): do nothing extra — the app's existing `_redirect` logic already lands on `today` for a completed-onboarding user, satisfying AC4 ("tap lands on Today") for free.
     - If false (plain icon launch, no notification involved): do nothing — normal cold-start flow.
   - This function must be defensive (wrapped in `try/catch` → log + continue) exactly like the existing `Supabase.initialize`/`Purchases.configure` blocks in `main.dart` — a reconciliation failure must never block app startup (mirrors NFR9's graceful-degradation posture).

### Judgment calls made (flagged, not silently decided)

1. **Auto-abandon vs. explicit abandon: intentionally equivalent, no schema change** (resolves review-delta-notification 4c, explicitly left open by the epic for `create-story` to decide). `SessionLogs` has no column to distinguish *why* a row was abandoned (`abandoned: true` already conflates "user tapped abandon" and "countdown ran out on the old code path before this story," and the epic's second listed resolution option — "explicitly document that they are intentionally equivalent" — is chosen over adding a distinguishing column. Rationale: this is a v1/exam-scope project; the state-machine impact difference between "phone pocketed for >5 minutes" and "user explicitly quit" is a real product nuance, but resolving it correctly would require a new persisted column (`autoAbandoned BOOLEAN`), a schema-version bump (`app_database.dart` is currently at `schemaVersion = 10`), a migration step, and `BehavioralStateMachine`/bandit-reward changes to actually consume the new signal — none of which exist today and all of which are out of proportion to a single interstitial-polish story. If Paolo wants the distinct-tagging behavior later, it is a follow-up story, not a change to this one's scope.
2. **Timeout-triggered abandon (warm, live-cubit path) navigates through the existing `BlocListener` → `AppRouter.sessionRpe`, not straight to Today.** The epic's AC4 ("tap lands on Today ... not a dead session") is explicit about the **cold-start-then-notification-tap-when-already-abandoned** case only — there is no cubit/`BlocListener` alive in that case to drive any other navigation, so a direct `.go(today)` is the only option. But the **warm** in-process timeout path (user simply returns to the foregrounded app after 6+ minutes, without necessarily tapping the notification) still has a live `InSessionCubit`; calling `cubit.abandon()` reuses the *exact* existing FR20 abandon flow end-to-end (emit → `BlocListener` → `sessionRpe`), which is consistent with "the behavioral-state impact follows the FR20 flow as today" (epics AC6) and avoids inventing a second abandon-navigation path for what is, from the state machine's perspective, an ordinary abandon.
3. **Full step + exact-second resume on deep-link, not step-only or restart-from-scratch.** AC3 says the tap "resumes the paused timer" — read literally, this means the exact frozen `secondsRemaining` at the moment of backgrounding, not merely "the same phase, restarted from its full duration." This requires two small, purely additive extensions with no effect on any existing call site: (a) `InSessionCubit` gets optional `initialStepIndex`/`initialSecondsRemaining`/`initialElapsedSeconds` constructor params (all default to the current behavior when omitted — no existing constructor call anywhere in the codebase needs to change), and (b) `InSessionPage`/`SessionStartArgs` thread two new optional fields (`resumeStepIndex`, `resumeSecondsRemaining`) end-to-end and, when present, **skip the `CountdownOverlay` entirely** (a resumed session should not replay a 3-2-1 countdown — the user is returning to an already-running session, not starting a fresh one). This is the single largest net-new surface in this story; it is scoped tightly (three files touched, all additive optional parameters) specifically so it does not ripple into unrelated call sites.
4. **The default 5-minute timeout is a plain constant, not a user-configurable setting.** The epics text says "configurable inactivity timeout (default 5 minutes)" — "configurable" is read here as "configurable in code" (a named constant `SessionReconciliationService.defaultTimeout`), not as a new Settings-screen control. Nothing in `DESIGN.md`/`EXPERIENCE.md` (already established in 22.4 as having no ratified spec for this feature) or the PRD calls for user-facing timeout configuration, and Story 22.4 similarly treated its own defaults (notification importance, lock-screen visibility) as code-level judgment calls, not new UI. If Paolo wants a Settings toggle for this later, it is a trivial follow-up (the constructor param already exists).
5. **The `elapsedSeconds`/`backgroundedAt` clock uses `DateTime.now()`, not a true monotonic clock (review-delta-notification 4e, marked LOW).** `InSessionCubit` already uses wall-clock `DateTime` (via its injectable `_now` function) for its existing `elapsedSeconds`/`_startedAt` tracking (`in_session_cubit.dart:25,31,200-202`) — there is no existing monotonic-clock plumbing anywhere in this codebase to extend, and introducing one (a platform channel to Android's `SystemClock.elapsedRealtime()`) for a LOW-severity, edge-case-only concern (a user manually changing their device clock mid-session) is disproportionate to this story's scope. This mirrors the existing precedent, not a new gap introduced by this story.
6. **`getNotificationAppLaunchDetails()` is exposed as a new method on `SessionNotificationService`** (`Future<bool> didLaunchFromNotification()`), not called directly on a raw `FlutterLocalNotificationsPlugin` instance in `main.dart`. This keeps the plugin fully wrapped behind the existing service abstraction (consistent with 22.4's own rationale for the service-object pattern) and keeps `main.dart`/the bootstrap function testable against a fake `SessionNotificationService` rather than the real plugin.
7. **`onDidReceiveNotificationResponse`'s no-op stub (set in 22.4) is replaced with real routing logic in this story**, per 22.4's own Dev Notes ("Story 22.5 replaces this with real routing"). The callback fires when the app is already running (backgrounded, not killed) and the user taps the notification; it should perform the *same* reconcile-then-navigate logic as the cold-start path (item 2 above) — call `AppRouter.router.go(...)` directly from the callback (it has no `BuildContext` either, same as the cold-start case). Because `SessionNotificationService`'s constructor/`init()` currently has no reference to `SessionReconciliationService` or `AppRouter`, thread these in as extra constructor dependencies to `LocalSessionNotificationService`, or (simpler, less coupling) move the tap-handling logic to a small standalone function that both `main.dart`'s cold-start check and a lambda passed into `init()`'s `onDidReceiveNotificationResponse` can both call — prefer the standalone-function approach so `SessionNotificationService` does not need to depend on `SessionReconciliationService`/`AppRouter` in its own file. Document whichever shape is chosen in Dev Agent Record; both are reasonable, this is a minor internal wiring decision, not a product decision.

## Acceptance Criteria

**AC1 — Resume before timeout:**
Given a session was paused on backgrounding
When the app is resumed before the configurable inactivity timeout (default 5 minutes) expires
Then the paused session resumes, the pending abandon is cancelled, and the notification is cleared (FR80).

**AC2 — Timeout elapses, reconcile-on-resume:**
Given a session was paused on backgrounding
When the inactivity timeout elapses without the app being resumed
Then the abandon is authoritatively committed on next resume/cold start via reconcile-on-resume (a monotonic-ish/wall-clock `backgroundedAt` is stored; on resume, if elapsed ≥ timeout → abandon through the existing FR20 flow), and the notification is cancelled/cleared as part of the same reconciliation (FR80, review-delta-notification 1c/4e).

**AC3 — Tap while still paused → deep-link + resume:**
Given the user taps the notification
When the session is still paused (not yet timed out)
Then the tap deep-links back into the in-session route and resumes the paused timer at its exact frozen step/second (distinct from a plain app relaunch) (FR79, review-delta-notification 4a).

**AC4 — Tap after auto-abandon → lands on Today:**
Given the user taps the notification
When the session has already been auto-abandoned by the timeout
Then the tap lands on Today (not a dead session), reconciling the abandon first on cold-start taps (FR79, review-delta-notification 4a).

**AC5 — Rapid toggling is idempotent and debounced:**
Given rapid background/foreground toggling
When the app switches states repeatedly
Then pause/resume is idempotent and debounced: the inactivity clock measures time since the most-recent backgrounding (each resume cancels the pending timeout, each backgrounding restarts it), with no timer drift and no duplicate notifications (FR80, review-delta-notification 4b).

**AC6 — Force-kill / orphaned notification reconciliation:**
Given the app/process is force-killed while a session is backgrounded (orphaned notification)
When the app next cold-starts
Then it reconciles session state from the surviving DB/persisted snapshot (NFR15), finalizes the pending abandon if the timeout had passed, and clears any stale notification (single active-session guarantee) (review-delta-notification 4d).

**AC7 — Auto-abandon vs. explicit abandon tagging (resolved):**
Given a timeout-driven auto-abandon vs. an explicit user abandon
When the abandon is recorded
Then the behavioral-state impact follows the FR20 flow as today, and the two are **intentionally treated as equivalent** (no new distinguishing column/tag) — a documented decision, not a deferred one (review-delta-notification 4c). See Judgment Call #1.

## Tasks / Subtasks

---

### Task 1 — `BackgroundedSessionSnapshot` + `SessionReconciliationService` (AC1, AC2, AC5, AC6, AC7)

- [x] **1.1** Create `lib/features/session/presentation/utils/session_reconciliation_service.dart`:
  - `BackgroundedSessionSnapshot` class: fields `planId` (`int?`), `sessionIndex` (`int`), `session` (`PlannedSession`), `currentStepIndex` (`int`), `secondsRemaining` (`int`), `elapsedSeconds` (`int`), `backgroundedAt` (`DateTime`). Manual `toJson()`/`fromJson(Map<String, dynamic>)` (session field nests `session.toJson()`/`PlannedSession.fromJson(...)`; `backgroundedAt` as `.toIso8601String()`/`DateTime.parse(...)`).
  - `enum SessionReconciliationResult { none, stillWithinWindow, abandonedByTimeout }`.
  - `SessionReconciliationService` per the design above: `readSnapshot()`, `writeSnapshot(BackgroundedSessionSnapshot)`, `clearSnapshot()`, `reconcile()`. Constructor takes `SharedPreferences`, `SessionLogsDao`, optional `DateTime Function() now`, optional `Duration timeout` (default `Duration(minutes: 5)`).
  - Wrap `readSnapshot()`'s JSON decode in `try/catch` → `null` (a corrupted/old-shape stored string must never crash startup — treat as `none`).
- [x] **1.2** `InSessionCubit` gets a new public getter `int get elapsedSeconds => _startedAt == null ? 0 : _now().difference(_startedAt!).inSeconds;` (`in_session_cubit.dart`, near `pauseTimers()`). Refactor `abandon()` (`in_session_cubit.dart:200-202`) to use this getter instead of its inline computation (same value, now shared) — this is the value `InSessionPage` reads when writing the snapshot on `paused`.

---

### Task 2 — Persist the snapshot on backgrounding + resume/timeout handling in `InSessionPage` (AC1, AC2, AC3, AC5)

- [x] **2.1** In `_InSessionPageState`, add a `late final SessionReconciliationService _reconciliationService` field, constructed in `initState()` from `getIt<SessionLogsDao>()`/`getIt<SharedPreferences>()` (guard both with `getIt.isRegistered<...>()`, mirroring the existing `_notificationService`/rationale-flag guards — tests without DI registered must not crash). Follow the existing optional-constructor-param test-seam pattern (`widget.notificationService`) by adding `widget.reconciliationService` (nullable, defaults to the real construction) so widget tests can inject a fake/in-memory one.
- [x] **2.2** Extend the existing `didChangeAppLifecycleState(AppLifecycleState.paused)` branch (`in_session_page.dart:124-140`): after the existing `cubit.pauseTimers()` + `showSessionPaused(...)` calls, additionally build a `BackgroundedSessionSnapshot` (`planId: widget.planId`, `sessionIndex: widget.sessionIndex`, `session: session`, `currentStepIndex: cubit.state.currentStepIndex`, `secondsRemaining: cubit.state.secondsRemaining`, `elapsedSeconds: cubit.elapsedSeconds`, `backgroundedAt: DateTime.now()`) and `await _reconciliationService.writeSnapshot(snapshot)` (or `unawaited(...)`, matching the existing fire-and-forget style of the notification call in the same branch).
- [x] **2.3** Add a new `resumed` branch to the same `didChangeAppLifecycleState` method: guard `if (!mounted) return;` then bail if `_cubit == null || widget.session == null` (mirror the `paused` branch's early returns). Then:
  ```dart
  final result = await _reconciliationService.reconcile();
  if (!mounted) return; // re-check after the await
  switch (result) {
    case SessionReconciliationResult.stillWithinWindow:
      _cubit!.resumeTimers();
      await _reconciliationService.clearSnapshot();
      unawaited(_notificationService.cancel());
    case SessionReconciliationResult.abandonedByTimeout:
      unawaited(_cubit!.abandon());
      unawaited(_notificationService.cancel());
    case SessionReconciliationResult.none:
      break;
  }
  ```
  Do not gate this branch on `cubit.state.isComplete`/`isAbandoned` up front the way `paused` does — `resumeTimers()`/`abandon()` already no-op safely in those states (see `in_session_cubit.dart:83,193`).

---

### Task 3 — Deep-link resume: `SessionStartArgs` + `InSessionPage` + `InSessionCubit` seeding (AC3)

- [x] **3.1** Extend `SessionStartArgs` (`lib/features/session/domain/entities/session_start_args.dart`) with two new optional fields: `resumeStepIndex` (`int?`), `resumeSecondsRemaining` (`int?`), `resumeElapsedSeconds` (`int?`) — all default `null`, meaning "fresh start," preserving every existing construction site unchanged.
- [x] **3.2** Add matching optional fields to `InSessionPage` (`resumeStepIndex`, `resumeSecondsRemaining`, `resumeElapsedSeconds`, all `int?`, default `null`).
- [x] **3.3** In `AppRouter`'s `sessionActive` `GoRoute` builder (`app_router.dart:126-139`), thread the three new fields from `SessionStartArgs` into the `InSessionPage(...)` constructor call (the `extra as PlannedSession?` fallback branch, used only by tests/legacy call sites without `SessionStartArgs`, needs no change — it has no resume fields to pass).
- [x] **3.4** In `_InSessionPageState.build()` (`in_session_page.dart:150-162`): when `widget.resumeStepIndex != null` and `!_countdownDone`, skip rendering `CountdownOverlay` and instead trigger `_onCountdownComplete()` directly (e.g. via `WidgetsBinding.instance.addPostFrameCallback` on first build, guarded so it only fires once — mirror how `_onCountdownComplete` is otherwise only invoked by `CountdownOverlay`'s own callback). A resumed session must never show the 3-2-1 countdown ceremony.
- [x] **3.5** In `_onCountdownComplete()` (`in_session_page.dart:74-99`), pass `initialStepIndex: widget.resumeStepIndex`, `initialSecondsRemaining: widget.resumeSecondsRemaining`, `initialElapsedSeconds: widget.resumeElapsedSeconds` into the `InSessionCubit(...)` constructor (all `null` in the normal, non-resumed path — no behavior change there). Also **skip** `_maybeShowNotificationRationale()` when resuming (permission was already resolved before the session was ever backgrounded; re-prompting on resume would be jarring) — gate the existing call with `if (widget.resumeStepIndex == null) { unawaited(_maybeShowNotificationRationale()); }`.
- [x] **3.6** `InSessionCubit` constructor (`in_session_cubit.dart:34-54`): add optional `int? initialStepIndex`, `int? initialSecondsRemaining`, `int? initialElapsedSeconds`. When provided, seed the initial `InSessionState(steps:, currentStepIndex: initialStepIndex ?? 0, secondsRemaining: initialSecondsRemaining ?? steps.first.durationSeconds)` instead of always starting at step 0. In `start()` (`in_session_cubit.dart:57-68`), when `initialElapsedSeconds != null`, seed `_startedAt = _now().subtract(Duration(seconds: initialElapsedSeconds))` instead of `_startedAt ??= _now()` — this keeps `elapsedSeconds`/a future `abandon()`'s persisted `elapsedSeconds` value continuous across the resume rather than resetting to 0.

---

### Task 4 — Notification-tap routing + `getNotificationAppLaunchDetails` (AC3, AC4, AC6)

- [x] **4.1** Add `Future<bool> didLaunchFromNotification()` to the `SessionNotificationService` interface and `LocalSessionNotificationService` implementation (`session_notification_service.dart`), wrapping `_plugin.getNotificationAppLaunchDetails()` and returning `details?.didNotificationLaunchApp ?? false`, try/catch → `false` (mirrors every other method's error-handling shape in this file).
- [x] **4.2** Write a standalone, dependency-injected function (not a widget method) — e.g. `Future<void> handleNotificationTap({required SessionReconciliationService reconciliationService, required SessionNotificationService notificationService}) async { ... }` in the new `session_reconciliation_service.dart` file (or a small sibling file if it grows past the file-size budget — see below) that:
  - Calls `reconciliationService.reconcile()`.
  - Re-reads `reconciliationService.readSnapshot()`.
  - If a snapshot still exists (i.e. reconcile didn't just clear it as `abandonedByTimeout`, and it wasn't already `none`): build `SessionStartArgs` from the snapshot (`session`, `planId`, `sessionIndex`, `resumeStepIndex: snapshot.currentStepIndex`, `resumeSecondsRemaining: snapshot.secondsRemaining`, `resumeElapsedSeconds: snapshot.elapsedSeconds`), call `AppRouter.router.go(AppRouter.sessionActive, extra: args)`, then `await reconciliationService.clearSnapshot()` and `unawaited(notificationService.cancel())`.
  - Otherwise (no snapshot left — already abandoned or never existed): call `AppRouter.router.go(AppRouter.today)` explicitly (do not just rely on the app's default redirect — this function may run while the app is already showing some other route mid-session-flow, e.g. `sessionRpe`; an explicit `.go(today)` is unambiguous).
- [x] **4.3** Wire this function as the real `onDidReceiveNotificationResponse` callback in `LocalSessionNotificationService.init()` (replacing the 22.4 no-op `_onTap` stub, `session_notification_service.dart:59-64`) — the callback needs access to a `SessionReconciliationService` instance; construct one inline (`getIt<SessionLogsDao>()`/`getIt<SharedPreferences>()`, guarded by `isRegistered`) rather than threading it through the constructor, to avoid changing `LocalSessionNotificationService`'s existing constructor signature (no call site currently passes extra dependencies to it).
- [x] **4.4** In `main.dart`, after the existing `configureDependencies()` block succeeds (after the `getIt<SyncManager>()` wiring, before `runApp(const PulseCoachApp())`), add a new `try/catch`-wrapped block: construct a `SessionReconciliationService` + `LocalSessionNotificationService`, call `await reconciliationService.reconcile()`, then `if (await notificationService.didLaunchFromNotification())` call the same `handleNotificationTap(...)` function from 4.2. Log-and-continue on any failure (mirror the existing `Supabase.initialize`/`Purchases.configure` try/catch style at `main.dart:16-46`) — this must never block app startup.

---

### Task 5 — Tests (AC1–AC7)

- [x] **5.1** `test/unit/session_reconciliation_service_test.dart` (new; use `SharedPreferences.setMockInitialValues({})` + `SharedPreferences.getInstance()` and an in-memory `AppDatabase`/`SessionLogsDao` per the project's existing Drift-test convention — grep an existing `*_dao_test.dart` for the `NativeDatabase.memory()` setup pattern):
  ```
  [22.5-SVC-001] no snapshot persisted → reconcile() returns `none`
  [22.5-SVC-002] snapshot persisted, elapsed < timeout → reconcile() returns `stillWithinWindow`, snapshot NOT cleared, no DAO write
  [22.5-SVC-003] snapshot persisted, elapsed >= timeout → reconcile() returns `abandonedByTimeout`, snapshot cleared, SessionLogsDao row written with abandoned=true/correct elapsedSeconds/currentStepIndex
  [22.5-SVC-004] calling reconcile() twice after timeout (simulating cold-start-then-later-warm-check) → second call returns `none` (already cleared), no duplicate DAO row (also verifies insertOrIgnore safety net if a row already exists)
  [22.5-SVC-005] corrupted/malformed persisted JSON string → readSnapshot()/reconcile() returns null/none, does not throw
  [22.5-SVC-006] writeSnapshot() then readSnapshot() round-trips all fields correctly (including nested PlannedSession)
  ```
- [x] **5.2** Extend `test/widget/in_session_page_background_pause_test.dart` (or a new sibling `in_session_page_resume_test.dart` if the file would exceed a reasonable size — judgment call, keep each file focused) with a fake/in-memory `SessionReconciliationService` test seam (per Task 2.1's `widget.reconciliationService` param):
  ```
  [22.5-VIEW-001] paused then resumed before timeout → InSessionCubit's timer resumes advancing again (pump seconds, assert secondsRemaining decreases), notification service .cancel() called
  [22.5-VIEW-002] paused then resumed after timeout (fake reconciliation service reports abandonedByTimeout) → cubit emits isAbandoned, navigates to sessionRpe route, notification .cancel() called
  [22.5-VIEW-003] rapid paused→resumed→paused→resumed toggling → resumeTimers()/pauseTimers() called the expected number of times, no duplicate showSessionPaused notification IDs, no drift in secondsRemaining
  [22.5-VIEW-004] resumed with no prior paused (result `none`) → no-op, no crash
  [22.5-VIEW-005] deep-link construction (InSessionPage built with non-null resumeStepIndex/resumeSecondsRemaining) → CountdownOverlay is skipped entirely, InSessionView renders immediately showing the resumed step index and secondsRemaining value
  ```
- [x] **5.3** `test/unit/in_session_cubit_test.dart` (existing file — extend, do not duplicate): add cases for the new optional constructor params:
  ```
  [22.5-CUBIT-001] InSessionCubit constructed with initialStepIndex/initialSecondsRemaining → initial state reflects those values, not step 0 / full duration
  [22.5-CUBIT-002] InSessionCubit constructed with initialElapsedSeconds, then abandon() called → persisted elapsedSeconds continues from the seeded value (not reset to ~0)
  [22.5-CUBIT-003] existing (un-seeded) construction still behaves exactly as before (regression guard — no seeded params passed)
  ```
- [x] **5.4 — check for fallout beyond these new/extended files.** `SessionStartArgs`' three new optional fields and `InSessionPage`'s three new optional fields must not require changes at any existing construction site (`app_router.dart`, any test file constructing `InSessionPage`/`SessionStartArgs` directly) — verify by running the full suite, not by inspection alone.
- [x] **5.5** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Confirm 0 analyzer issues and no regressions against the current baseline (1366 passed / 1 skipped as of Story 22.4).

---

## Dev Notes

### Why this story closes Epic 22

Story 22.4 was deliberately narrow-scoped (see its own Dev Notes/scope-boundary section) specifically so this story could own the full reconcile-on-resume state machine without having to rework anything 22.4 shipped. Nothing in 22.4's implementation needs to change structurally — this story only *adds* a `resumed` branch to an existing method, calls two previously-unused methods (`resumeTimers()`, `notificationService.cancel()`) for the first time, and threads three new optional fields through existing constructors.

### Why a plain-class DTO (`BackgroundedSessionSnapshot`) instead of `@freezed`

This is a single internal, non-domain, non-Bloc-state value object used only to (de)serialize a `SharedPreferences` string. It never crosses a Bloc-state boundary (so the project's "Bloc states must be `@freezed`" rule does not apply to it) and has no equality/copyWith requirements beyond simple JSON round-tripping. Adding `@freezed`+`build_runner` ceremony for an 8-field internal DTO used in exactly two places would be disproportionate.

### Why no Drift table for the snapshot

A new table would need a schema-version bump (`app_database.dart` is at `schemaVersion = 10`), a migration, DAO codegen, and — critically — would not actually need to survive a full app *uninstall* (unlike `SessionLogs`, which is permanent user history data). A single `SharedPreferences` string entry is exactly proportioned to "ephemeral scratch state that must survive process death but nothing more," and mirrors the existing `_kRationaleShownKey` precedent from Story 22.4.

### On the `GoRouter.go()`-before-`runApp()` pattern

This is the one piece of this story's design with **no existing precedent in this codebase** to point to — every other `AppRouter.router` interaction happens from within an already-mounted widget tree via `context.go(...)`. Calling `AppRouter.router.go(...)` directly on the static instance before `runApp` is a well-known `go_router` pattern for cold-start deep-linking (the router object holds navigation state independent of whether it's yet attached to a `Navigator`), but it has not been exercised anywhere in this app before. Verify it behaves as expected with a dedicated widget/integration test during implementation (pump the router, assert the resulting route) rather than trusting the design doc alone — flag any surprising behavior in the Dev Agent Record.

### File Size Check

- New `session_reconciliation_service.dart`: expect ~140–180 lines (DTO + enum + service class + the standalone `handleNotificationTap` function). If this pushes past ~200 lines, split `BackgroundedSessionSnapshot`/`SessionReconciliationResult` into their own file and keep `handleNotificationTap` there too, or split `handleNotificationTap` into a second file (`notification_tap_handler.dart`) — either split is fine, just keep each file under this project's 200–400-line convention.
- `in_session_page.dart`: current 298 lines (post-22.4-review) → +~35–50 lines (`resumed` branch, reconciliation-service field/test-seam, countdown-skip logic, extra `_onCountdownComplete` params). Should land comfortably under 350; if it exceeds ~380, consider extracting the `resumed`-branch logic into a private method to keep `didChangeAppLifecycleState` itself short, not extracting to a new file (this logic is tightly coupled to `_cubit`/`_notificationService`/`_reconciliationService` instance state).
- `in_session_cubit.dart`: current 248 lines → +~15–20 lines (3 new optional constructor params, 1 new getter, `_startedAt` seeding tweak in `start()`). Comfortably within budget.
- `session_notification_service.dart`: current 200 lines → +~20–25 lines (`didLaunchFromNotification()`, real `_onTap` replacing the stub). Comfortably within budget.
- `main.dart`: current 72 lines → +~15–20 lines (one new try/catch block before `runApp`).

### Project Structure Notes

**New production files:**
- `pulse_coach/lib/features/session/presentation/utils/session_reconciliation_service.dart` (or split per File Size Check)

**Modified production files:**
- `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart` (new optional constructor params, `elapsedSeconds` getter, `_startedAt` seeding in `start()`)
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart` (`resumed` branch, reconciliation-service field + test seam, countdown-skip for deep-linked resume, extra `_onCountdownComplete` params)
- `pulse_coach/lib/features/session/presentation/utils/session_notification_service.dart` (`didLaunchFromNotification()`, real `_onTap` routing replacing 22.4's stub)
- `pulse_coach/lib/features/session/domain/entities/session_start_args.dart` (3 new optional fields)
- `pulse_coach/lib/core/routing/app_router.dart` (thread new `SessionStartArgs` fields into `InSessionPage` construction)
- `pulse_coach/lib/main.dart` (cold-start reconciliation + notification-launch-tap handling before `runApp`)

**Explicitly out of scope for this story:**
- Any new Settings-screen UI for the inactivity timeout (Judgment Call #4).
- Distinct DB tagging of auto-abandon vs. explicit abandon (Judgment Call #1 / AC7).
- A true monotonic clock / platform-channel-based `elapsedRealtime()` (Judgment Call #5).
- Any change to `BehavioralStateMachine`/bandit reward handling — this story only ensures the abandon *reaches* the existing FR20 flow; it does not touch what that flow does downstream.

### References

- [Source: epics.md#Story 22.5, lines 3027-3061 — full BDD ACs]
- [Source: epics.md#Epic 22, lines 2885-2893 — epic goal, epic-closing story]
- [Source: review-delta-notification.md — full PASS-WITH-FIXES gate review; this story owns fixes 1c, 4a, 4b, 4c, 4d, 4e]
- [Source: prd.md FR79/FR80/NFR39 — canonical requirement text (referenced, not modified, by this story)]
- [Source: 22-4-session-notification-infrastructure-permissions-and-background-pause.md — the immediately-preceding story; its "Scope boundary" section is the authoritative list of what this story must add; its Review Findings section confirms `resumeTimers()`/notification-cancel were deliberately left uncalled, owned by this story]
- [Source: lib/features/session/presentation/bloc/in_session_cubit.dart:34-92,192-240 — `pauseTimers()`/`resumeTimers()`/`abandon()`/`_persistAbandon()` to reuse/extend; existing injectable `_now` clock precedent]
- [Source: lib/features/session/presentation/pages/in_session_page.dart:45-148 — full current file post-22.4; every modification point cited above by line]
- [Source: lib/features/session/presentation/utils/session_notification_service.dart — full current file (200 lines); `cancel()`/`_onTap` to extend]
- [Source: lib/core/database/daos/session_logs_dao.dart:14-17 — `insertLog` + `insertOrIgnore` semantics, the safety net this story's dual commit paths rely on]
- [Source: lib/core/database/tables/session_logs_table.dart — no schema change needed; confirms Judgment Call #1's "no new column" decision is structurally simple to satisfy]
- [Source: lib/core/database/app_database.dart:61 — `schemaVersion = 10`, cited to show the cost of the schema-change alternative rejected in Judgment Call #1]
- [Source: lib/features/session/domain/entities/session_start_args.dart, lib/core/routing/app_router.dart:47,126-139 — the existing deep-link contract extended by this story]
- [Source: lib/features/daily_plan/domain/entities/planned_session.dart — `@freezed`+`json_serializable` `PlannedSession`, reused for snapshot (de)serialization]
- [Source: lib/core/di/settings_module.dart:8-9 — `SharedPreferences` `@singletonAsync` registration, reused via `getIt.isRegistered` guard exactly as Story 22.4 already does for `_kRationaleShownKey`]
- [Source: pulse_coach/lib/main.dart:12-72 — existing app-init sequence; this story's cold-start reconciliation call site (after `configureDependencies()`, before `runApp`)]
- [Source: pub.dev/pub-cache `flutter_local_notifications-21.0.0`, `flutter_local_notifications_platform_interface-11.0.0` (verified 2026-07-07 against installed source) — `getNotificationAppLaunchDetails()` / `NotificationAppLaunchDetails.didNotificationLaunchApp` / `.notificationResponse` confirmed present on the installed version]
- [Source: pulse_coach/test/widget/in_session_page_background_pause_test.dart — existing 22.4 widget-test harness (`_router`/`_wrap`/`_pumpPastCountdown`, `_FakeSessionNotificationService`, `TestWidgetsFlutterBinding.handleAppLifecycleStateChanged`) to extend/mirror for this story's resume tests]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5), via bmad-dev-story workflow.

### Debug Log References

- ATDD contract followed throughout: every production change was preceded by a failing test (RED, verified by running the specific test file before implementing) before writing the minimum code to pass (GREEN).
- Widget-test timing bug found during Task 2: the first `22.5-VIEW-001` attempt navigated to `sessionRpe` (abandonedByTimeout) instead of resuming, because the test's injectable clock was seeded with a fixed 2026 date while `InSessionPage._handlePaused` writes `backgroundedAt` via real `DateTime.now()` — the huge apparent elapsed time always exceeded the timeout. Fixed by seeding the test's `_ManualClock` with `DateTime.now()` at test start instead of a fixed historical date.
- `AppRouter.router.state` (via `go_router`'s `GoRouterDelegate.currentConfiguration`) throws `Bad state: No element` when read without a mounted `Navigator` — confirms the Dev Notes' warning that the pre-`runApp` `.go()` pattern has no precedent in this codebase. Worked around in `handleNotificationTap`'s unit tests by asserting on `AppRouter.router.routeInformationProvider.value.uri.path` instead, which `GoRouteInformationProvider.go()` updates synchronously regardless of whether a widget tree is attached.
- `CountdownOverlay` skip: initially triggered `_onCountdownComplete()` via `WidgetsBinding.instance.addPostFrameCallback` in `initState()` while still allowing `build()` to render `CountdownOverlay` for one frame — this left a real `Future.delayed` (from `CountdownOverlay`'s reduce-motion countdown loop) pending at test teardown. Fixed by adding an explicit early-return in `build()` (`SizedBox.shrink()`) whenever `widget.resumeStepIndex != null`, so `CountdownOverlay` is never constructed at all on a deep-linked resume.

### Completion Notes List

- **Task 1** — `SessionReconciliationService` + `BackgroundedSessionSnapshot` (new file), `InSessionCubit.elapsedSeconds` getter (`abandon()` refactored to reuse it). 8 unit tests (6 required `22.5-SVC-001..006` + 2 extra: `clearSnapshot()`, null-`planId` snapshot). Verified FK constraint required a real `DailyPlansCompanion` row (not just a bare `planId` int) for `SessionLogsDao.insertLog` in-memory tests — added via `db.dailyPlansDao.insertPlan(...)` in `setUp`.
- **Task 2** — `InSessionPage` gets `_reconciliationService` (nullable, test-seam via `widget.reconciliationService`, guarded `getIt.isRegistered` construction), `_handlePaused`/`_handleResumed` split out of `didChangeAppLifecycleState`. `_handlePaused` now also writes the snapshot; `_handleResumed` reconciles and calls `resumeTimers()`/`abandon()`/`cancel()` per AC1/AC2. 4 widget tests (`22.5-VIEW-001..004`), all in a new sibling file `in_session_page_resume_test.dart` (kept `in_session_page_background_pause_test.dart` focused on 22.4, per the story's own file-size guidance).
- **Task 3** — `SessionStartArgs`/`InSessionPage` gain `resumeStepIndex`/`resumeSecondsRemaining`/`resumeElapsedSeconds` (all optional, all-`null` = no behavior change); `AppRouter`'s `sessionActive` route threads them; `InSessionCubit` seeds initial state/`_startedAt` from them. `build()` returns `SizedBox.shrink()` (never `CountdownOverlay`) when `widget.resumeStepIndex != null`; `_onCountdownComplete()` is instead triggered once via a post-frame callback registered in `initState()`. 3 cubit tests (`22.5-CUBIT-001..003`) + 1 widget test (`22.5-VIEW-005`).
- **Task 4** — `SessionNotificationService.didLaunchFromNotification()` (new interface method + implementation, wraps `getNotificationAppLaunchDetails()`). `handleNotificationTap()` standalone function added to `session_reconciliation_service.dart` (kept in the same file — final size 165 lines, within the story's own ~200-line split threshold) and wired as the real `onDidReceiveNotificationResponse` callback (constructed inline via `getIt`, guarded), replacing 22.4's no-op `_onTap` stub. `main.dart` gets a new `try/catch`-wrapped cold-start reconciliation + notification-launch-tap block before `runApp`. 1 new unit test (`22.5-SVC-007`) + 3 `handleNotificationTap` tests (within-window resume, already-abandoned, never-existed).
- **Task 5** — Fallout check: the two existing `_FakeSessionNotificationService` implementations (`in_session_page_background_pause_test.dart`, `in_session_page_resume_test.dart`) needed a new `didLaunchFromNotification()` override each after Task 4's interface addition — added, no other existing call site required changes (`SessionStartArgs`/`InSessionPage`'s new fields are all-optional). `flutter analyze lib/ test/`: 0 issues. `flutter test`: 1388 passed / 1 skipped (baseline 1366/1 + 22 new: 8 SVC + 3 handleNotificationTap + 1 SVC-007 + 3 CUBIT + 2 elapsedSeconds + 5 VIEW), no regressions.

### File List

**New:**
- `pulse_coach/lib/features/session/presentation/utils/session_reconciliation_service.dart`
- `pulse_coach/test/unit/session_reconciliation_service_test.dart`
- `pulse_coach/test/widget/in_session_page_resume_test.dart`

**Modified:**
- `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart`
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`
- `pulse_coach/lib/features/session/presentation/utils/session_notification_service.dart`
- `pulse_coach/lib/features/session/domain/entities/session_start_args.dart`
- `pulse_coach/lib/core/routing/app_router.dart`
- `pulse_coach/lib/main.dart`
- `pulse_coach/test/bloc/in_session_cubit_test.dart`
- `pulse_coach/test/unit/session_notification_service_test.dart`
- `pulse_coach/test/widget/in_session_page_background_pause_test.dart`

### Review Findings

_Code review 2026-07-07 (3-layer adversarial: Blind Hunter / Edge Case Hunter / Acceptance Auditor, Opus 4.8). 15 raised → 12 unique; 1 decision-needed, 3 patch, 1 deferred, 7 dismissed._

- [x] [Review][Patch] Warm notification-tap double-handling race (resolved 2026-07-07 → Option 1: warm guard, lifecycle is sole owner) — Tapping the session-paused notification while `InSessionPage` is still mounted fires BOTH `AppLifecycleState.resumed` → `_handleResumed` AND the plugin `_onTap` → `handleNotificationTap`. Both consume the single `SharedPreferences` snapshot with no coordination, and interleavings conflict: (a) `_handleResumed` resumes the session in place + `clearSnapshot()`, then `handleNotificationTap.readSnapshot()` returns null → `go(today)`, navigating away from the just-resumed session (session lost); (b) on timeout, `_handleResumed` → `abandon()` → RPE flow while `handleNotificationTap` → `go(today)` — contradictory destinations depending purely on async ordering. [in_session_page.dart:202 / session_notification_service.dart:67 / session_reconciliation_service.dart:140]
- [x] [Review][Patch] AC6: stale ongoing notification not cancelled on icon-launch cold start after force-kill [pulse_coach/lib/main.dart:92] — cold start discards `reconcile()`'s result and only cancels the notification inside `handleNotificationTap` (tap path only); a force-kill + icon relaunch after the timeout commits the abandon but leaves the `ongoing:true, autoCancel:false` notification on the status bar. Fix: capture the result and `unawaited(notificationService.cancel())` on `abandonedByTimeout`.
- [x] [Review][Patch] Warm-resume inflates `elapsedSeconds` by the backgrounded interval [pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart:95] — `_startedAt` is not advanced across the paused/backgrounded window, so after a within-window warm resume `elapsedSeconds = now - _startedAt` counts dead background time, inconsistent with the cold-start deep-link path (which seeds `_startedAt = now - initialElapsedSeconds`). Affects `elapsedSeconds` recorded on a subsequently-abandoned log.
- [x] [Review][Patch] Corrupt/undeserializable snapshot is read as `none` and never cleared [pulse_coach/lib/features/session/presentation/utils/session_reconciliation_service.dart:85] — `readSnapshot()` swallows a parse error and returns null, so `reconcile()` short-circuits to `none` without abandoning, without cancelling the notification, and the corrupt key persists in `SharedPreferences` indefinitely. Fix: best-effort clear the key when a non-null raw value fails to deserialize.
- [x] [Review][Defer] Snapshot only written on `AppLifecycleState.paused`, not `hidden`/`detached` [pulse_coach/lib/features/session/presentation/pages/in_session_page.dart:160] — deferred, pre-existing (inherited lifecycle-coverage gap from Story 22.4); a fast-kill path that never transitions through `paused` persists no snapshot.

## Change Log

- 2026-07-07: Story 22.5 created via create-story workflow. Epic-closing story: owns everything Story 22.4 deliberately deferred (resume-on-foreground, inactivity timeout, `backgroundedAt` persistence, auto-abandon-through-FR20, notification-tap deep-linking). Central design decision: a single `SessionReconciliationService` (read/write a `SharedPreferences`-backed `BackgroundedSessionSnapshot`, decide none/still-within-window/abandoned-by-timeout, never navigate itself) called from exactly two sites — `InSessionPage`'s new `AppLifecycleState.resumed` branch (warm, live-cubit path) and a new pre-`runApp` cold-start check in `main.dart` plus the notification-tap callback (both no-live-cubit paths, sharing one `handleNotificationTap` function). Resolved the epic's one open decision (review-delta-notification 4c): auto-abandon and explicit abandon are intentionally treated as equivalent, no new DB column, to keep this interstitial-polish story's scope proportionate — documented as Judgment Call #1, reversible in a future story. Also specified full step+exact-second resume via new optional `InSessionCubit`/`InSessionPage`/`SessionStartArgs` fields (skipping the countdown overlay on deep-linked resume) since AC3 reads literally as resuming the frozen timer, not merely the same phase restarted.
- 2026-07-07: Story 22.5 implemented via dev-story workflow (ATDD, failing test first for every production change). All 5 tasks / 20 subtasks / 7 ACs complete. `flutter analyze lib/ test/`: 0 issues. `flutter test`: 1388 passed / 1 skipped (baseline 1366/1 + 22 new tests), no regressions. Epic 22 is now closeable.
