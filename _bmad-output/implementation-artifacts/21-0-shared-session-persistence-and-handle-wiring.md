---
baseline_commit: 80cbe9f
---

# Story 21.0: Shared-Session Persistence and Handle Wiring

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a shared-session participant,
I want my completed shared session to be recorded locally and to see real @handles in the lobby,
So that the session appears in my history and scoring/leaderboard has a real session record and identity to build on.

## Context

**Epic 21 — Leaderboard & Scoring (v2.5), first story.** This is a **hard-block prerequisite**: Story 21.0 must be `done` before Story 21.1 (points system) enters the sprint (epics.md Epic 21 Prerequisites note, E9-K1/E17R-3). It closes two confirmed Epic-20 retro gaps (`epic-20-retro-2026-06-29.md`, promoted to Story 21.0 at Epic 21 kickoff triage, commit `80cbe9f`):

- **E20R-2 (local half):** shared-session completion writes **no `SessionLog` row at all**. The host's `InSessionCubit` is constructed with `sessionLogsDao: null, planId: null` (`_SharedInSessionViewState._initHostCubit`); the follower never runs an `InSessionCubit`. The RPE screen navigates with `RpeSubmitArgs(planId: null, sessionLogId: null, ...)`, so `RpeFeedbackCubit._resolveSessionLogId()` returns `null` and RPE is written with `sessionId: 0`. Net effect: a shared session never appears in Progress → Cronologia and has no local row for Epic 21 scoring to attach points to.
- **E20R-1:** the lobby shows the generic `"Participant"` fallback for the **current user's own row** instead of their real `@handle`. Root cause: `social_page.dart`'s `BlocListener<SharedSessionCreationCubit>`/`BlocListener<SharedSessionJoinCubit>` read `SocialProfileBloc.state.mapOrNull(loaded: ...)` at the moment the session is created/joined — if that bloc hasn't finished loading yet, `displayHandle` is `null` and flows all the way through `SharedSessionStartArgs` → `SharedSessionJoined` → `SharedSessionBloc._onJoined` unresolved.

**E21-K1 fire-check (Epic 21 Prerequisites note in epics.md):** Story 21.3's server-visible completion signal is an explicit **21.3** design dependency, NOT this story's scope — do not build any Supabase-side write here.

**What is already built (DO NOT REBUILD):**
- `SessionLogsDao` (`lib/core/database/daos/session_logs_dao.dart`) — `insertLog` (insertOrIgnore), `upsertCompletion` (insertOrReplace), `getLogFor`, `getAllLogsOrderedByDate`, `watchLogsForPlan`. No new DAO methods are needed — `insertLog` with a `SessionLogsCompanion` already accepts every field this story needs once the schema is extended (Task 1).
- `RpeFeedbackCubit._resolveSessionLogId()` (`lib/features/session/presentation/bloc/rpe_feedback_cubit.dart:66`) — already resolves an explicit `sessionLogId`, or looks one up via `(planId, sessionIndex)` for solo sessions. This is the exact seam this story extends for the `planId == null` (shared) branch — **do not** duplicate this logic in `InSessionCubit` or the shared session bloc/page.
- `RpePage` (`lib/features/session/presentation/pages/rpe_page.dart:51`) already injects `SessionLogsDao` into `RpeFeedbackCubit` unconditionally (`getIt.isRegistered<SessionLogsDao>() ? getIt<SessionLogsDao>() : null`) for **both** solo and shared sessions — it is the single screen both roles pass through. This is why Task 3 (write the log in `RpeFeedbackCubit`) is the correct single touch-point: it covers host AND follower with one change, instead of separately wiring the host's `InSessionCubit` (which the follower doesn't have) and inventing a parallel path for the follower.
- `SharedSessionBloc._resolveCoLocation` (`shared_session_bloc.dart:110`) — the exact pattern to mirror for async, non-blocking, "resolve after lobby entry, then re-track Presence" (Task 4 does the same thing for the own-handle resolution).
- `ProgressLocalDataSource.getSessionHistory()` (`lib/features/progress/data/datasources/progress_local_data_source.dart:24`) — currently **skips** any `SessionLog` whose `dailyPlanId` doesn't resolve to a `DailyPlan` row (treats it as a data-integrity warning). Task 2 adds an explicit branch for `dailyPlanId == null` (a legitimate shared-session row, not corruption) instead of loosening that warning path.
- `GetSocialProfileUseCase` (`lib/features/social/friends/domain/usecases/get_social_profile_use_case.dart`) — already `@injectable`, already used elsewhere. Just inject it into `SharedSessionBloc`.
- `_ParticipantRow` in `shared_session_lobby_page.dart:359` already renders `handle != null ? '@$handle' : l10n.sharedSessionParticipantUnknown` — the UI fallback for "no handle" already exists and is correct for OTHER participants who are genuinely unresolved. This story fixes the upstream data (the current user's own handle), not this rendering.

**What this story builds:**
1. **Schema migration v9 → v10** (`app_database.dart`, `session_logs_table.dart`): `SessionLogs.dailyPlanId` becomes nullable (shared sessions have no `DailyPlan`); three new nullable columns — `sessionType`, `armKey`, `durationMinutes` — are added so a shared-session row carries enough denormalized data for Progress history to render without a `DailyPlans` join.
2. `ProgressLocalDataSource.getSessionHistory()`: branch on `log.dailyPlanId == null` and build the `SessionHistoryEntry` directly from the log's own `sessionType`/`durationMinutes`, skipping the `DailyPlansDao` join.
3. `RpeFeedbackCubit._resolveSessionLogId()`: when `planId == null` (shared session) and no explicit `sessionLogId` was passed, insert a standalone `SessionLog` row (dailyPlanId: null) using `RpeSubmitArgs.armKey`/`durationMinutes`/`abandoned`, and use its id to anchor the RPE row — closing E20R-2's local half.
4. `SharedSessionBloc`: inject `GetSocialProfileUseCase`; when `SharedSessionJoined.displayHandle` is null, resolve it in the background (non-blocking, mirrors `_resolveCoLocation`) and re-track Presence once resolved — closing E20R-1.
5. `build_runner` regeneration (`.g.dart` for the DB, `injection.config.dart` for the new bloc constructor arg).

**What this story does NOT include:**
- Any server-side / Supabase write for shared-session completion (that is Story 21.3's design dependency, per the Epic 21 Prerequisites note — do not scope-creep it in here).
- Distinguishing "host abandoned" from "all steps completed" in the persisted `abandoned` flag. The shared-session protocol funnels BOTH through the identical `SessionEndRequested` → `session_ended` broadcast → `sessionEnded` state path, and `shared_session_lobby_page.dart`'s listener already hardcodes `abandoned: false` in the `RpeSubmitArgs` it builds (pre-existing, Story 20.4 decision). This story persists whatever `abandoned` value is already available in `RpeSubmitArgs` — it does **not** add a new broadcast field or distinguish the reason. That is a separate, larger protocol change and is explicitly out of scope here.
- Follower-initiated abandon (there is no abandon button in `_buildFollowerView` today — pre-existing, out of scope).
- Points/leaderboard logic (Story 21.1, still `backlog`).
- Reconnect/late-join session metadata gaps (already a documented Story 20.5 deferral).

## Acceptance Criteria

**AC1 — SessionLog persisted on RPE submit for a shared session (closes E20R-2 local half):**
Given a shared session has ended (all steps complete, or the host ended it) and the participant reaches the RPE screen
When the RPE is submitted
Then `RpeFeedbackCubit._resolveSessionLogId()` inserts a `SessionLogsCompanion` row with `dailyPlanId: null`, `sessionIndex: 0`, `completedAt`/`createdAt` set to now, `abandoned` from `RpeSubmitArgs.abandoned`, `sessionType` derived from `RpeSubmitArgs.armKey.split('_').first`, `armKey` from `RpeSubmitArgs.armKey`, `durationMinutes` from `RpeSubmitArgs.durationMinutes`; the returned row id is used as `sessionLogId` on the `rpe_feedback` insert (non-null) — mirroring the solo flow's anchoring contract.

**AC2 — Shared session appears in Progress history:**
Given a participant completed a shared session (AC1 persisted a row)
When they open Progress → Cronologia
Then `ProgressLocalDataSource.getSessionHistory()` includes a `SessionHistoryEntry` for that row (built from the log's own `sessionType`/`durationMinutes`, no `DailyPlansDao` lookup) with its RPE value, exactly like a solo session's entry.

**AC3 — Current user's own @handle resolves in the lobby (closes E20R-1):**
Given a user creates or joins a shared session and `SharedSessionJoined.displayHandle` is null (the `SocialProfileBloc` hadn't finished loading at create/join time)
When `SharedSessionBloc._onJoined` runs
Then it calls `GetSocialProfileUseCase.call()`; on success it updates `_myDisplayHandle` and calls `_gateway.trackPresence(...)` again with the resolved handle (preserving `isHost` and any already-known lat/lon); the lobby's participant list (driven by `PresenceStateReceived`) subsequently shows `@handle` for the current user instead of `l10n.sharedSessionParticipantUnknown`.

**AC4 — Handle resolution never blocks lobby entry:**
Given `SharedSessionBloc._onJoined` is resolving the own handle asynchronously (AC3)
When the handle is not yet available (or the lookup fails)
Then the `SharedSessionState.lobby` emission happens immediately, unaffected — the async resolution runs `unawaited`, exactly like the existing `_resolveCoLocation` co-location check; a failed lookup (`Left(SocialFailure)`) is swallowed silently (no error state, no retry) and the row simply keeps the `sharedSessionParticipantUnknown` fallback.

**AC5 — Zero regressions:**
Given all new and modified files are in place and `build_runner` has been run
When `flutter test` and `flutter analyze lib/ test/` run from `pulse_coach/`
Then all pre-existing tests pass (baseline ≥ 1245 per the Epic 20 close — confirm the exact count with `flutter test` before starting) plus all new tests pass; analyzer reports 0 issues.

## Tasks / Subtasks

---

### Task 1 — Schema migration v9 → v10: nullable `dailyPlanId` + denormalized columns (AC1, AC2)

**Why:** `SessionLogs.dailyPlanId` is currently a required (`NOT NULL`) FK to `DailyPlans` with `ON DELETE CASCADE`. A shared session has no local `DailyPlan` row, so it must be able to insert `dailyPlanId: null`. There is also no column on `SessionLogs` today to carry `sessionType`/`durationMinutes`/`armKey` — those are normally read by joining `DailyPlans.planJson`, which doesn't exist for shared sessions.

- [x] **1.1** Edit `pulse_coach/lib/core/database/tables/session_logs_table.dart`:

  Replace:
  ```dart
  IntColumn get dailyPlanId =>
      integer().references(DailyPlans, #id, onDelete: KeyAction.cascade)();
  ```
  With:
  ```dart
  // Nullable as of Story 21.0: shared sessions have no local DailyPlan row.
  IntColumn get dailyPlanId => integer()
      .nullable()
      .references(DailyPlans, #id, onDelete: KeyAction.cascade)();
  ```

  Add three new nullable columns after `currentStepIndex`:
  ```dart
  // Story 21.0 — denormalized fields for shared sessions (which have no
  // DailyPlan to join against for sessionType/duration). Always null for
  // solo sessions; those still resolve via the DailyPlans join.
  TextColumn get sessionType => text().nullable()();
  TextColumn get armKey => text().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  ```

  **Critical — `uniqueKeys` stays exactly as-is** (`{dailyPlanId, sessionIndex}`). Do NOT change it. SQLite's `UNIQUE` treats every `NULL` as distinct from every other `NULL` (standard SQL semantics), so multiple shared-session rows — ALL of which will have `dailyPlanId: null, sessionIndex: 0` — never collide under this constraint. This is why `SessionLogsDao.insertLog` (which uses `InsertMode.insertOrIgnore`) is safe to reuse unmodified in Task 3; no new DAO method is needed.

- [x] **1.2** Edit `pulse_coach/lib/core/database/app_database.dart`:

  Bump the version:
  ```dart
  @override
  int get schemaVersion => 10;
  ```

  Add the migration block inside `onUpgrade`, after the existing `if (from < 9) { ... }` block:
  ```dart
  if (from < 10) {
    // SQLite cannot ALTER a column's NOT NULL/FK constraint or add it to an
    // existing UNIQUE index in place — the table must be rebuilt. Unlike the
    // v5→v6 migration (which safely dropped session_logs because it only
    // held ephemeral alpha data), this table now holds real user history, so
    // existing rows MUST be preserved via rename + recreate + copy + drop.
    //
    // Guarded for partial-upgrade survival (same pattern as the v8/v9 blocks
    // above): if the process is killed mid-migration, a naive unconditional
    // rename would throw "table session_logs_v9 already exists" on retry.
    final backupExists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name = 'session_logs_v9'",
    ).get();
    await customStatement('PRAGMA foreign_keys = OFF');
    if (backupExists.isEmpty) {
      await customStatement(
        'ALTER TABLE session_logs RENAME TO session_logs_v9',
      );
    }
    final newTableExists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name = 'session_logs'",
    ).get();
    if (newTableExists.isEmpty) {
      await m.createTable(sessionLogs);
      await customStatement('''
        INSERT INTO session_logs (
          id, daily_plan_id, session_index, completed_at, created_at,
          abandoned, elapsed_seconds, current_step_index
        )
        SELECT
          id, daily_plan_id, session_index, completed_at, created_at,
          abandoned, elapsed_seconds, current_step_index
        FROM session_logs_v9
      ''');
    }
    await customStatement('DROP TABLE IF EXISTS session_logs_v9');
    await customStatement('PRAGMA foreign_keys = ON');
  }
  ```

  **Critical — new columns are omitted from the `INSERT`/`SELECT` column lists on purpose:** `session_type`, `arm_key`, `duration_minutes` are nullable with no default, so every copied (pre-existing, solo) row gets `NULL` for them automatically — which is correct, since solo sessions resolve those fields via the `DailyPlans` join, not these columns.

  **Critical — `beforeOpen` already sets `PRAGMA foreign_keys = ON`** after every open. The explicit `OFF`/`ON` toggle inside this migration block is required regardless, because the rename+recreate happens *during* `onUpgrade`, before `beforeOpen` runs, and SQLite would otherwise block the rename while the old table has an active FK relationship from `daily_plans` (referential integrity checks on DDL).

- [x] **1.3** Run `dart run build_runner build --delete-conflicting-outputs` (also covers Task 5) — regenerates `session_logs_table` codegen bits inside `app_database.g.dart` and the `SessionLogsCompanion`/`SessionLog` data classes with the new nullable `dailyPlanId` and three new fields.

---

### Task 2 — `ProgressLocalDataSource`: render shared-session rows without a `DailyPlan` join (AC2)

**Why:** `getSessionHistory()` currently does `_dailyPlansDao.getPlanById(log.dailyPlanId)` unconditionally and **skips** the row (logs a warning) when the plan is missing. After Task 1, `log.dailyPlanId` can legitimately be `null` for a shared session — that is not data corruption and must not be skipped.

- [x] **2.1** Edit `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`.

  In `getSessionHistory()`, inside the `for (final log in logs)` loop, add a branch **before** the existing `_dailyPlansDao.getPlanById(...)` call:
  ```dart
  for (final log in logs) {
    if (log.dailyPlanId == null) {
      // Shared session (Story 21.0): no DailyPlan to join against.
      // sessionType/durationMinutes are denormalized directly on the row.
      final feedback = await _rpeFeedbackDao.getBySessionLogId(log.id);
      entries.add(
        SessionHistoryEntry(
          sessionLogId: log.id,
          completedAt: log.completedAt,
          sessionType: log.sessionType ?? 'mobility',
          durationMinutes: log.durationMinutes ?? 0,
          abandoned: log.abandoned,
          rpeValue: feedback?.rpeValue,
          elapsedSeconds: log.elapsedSeconds,
        ),
      );
      continue;
    }

    final planRow = await _dailyPlansDao.getPlanById(log.dailyPlanId!);
    // ... existing solo-session code below is otherwise UNCHANGED, except
    // every remaining `log.dailyPlanId` reference in this branch must use
    // `log.dailyPlanId!` (now-nullable field, but this branch already
    // proved it's non-null via the `continue` above).
  ```

  **Critical — `log.sessionType ?? 'mobility'` / `log.durationMinutes ?? 0` fallback:** These should never actually be null for a row written by Task 3 (which always supplies both), but the `??` guards against a hypothetical future direct DB write that omits them — cheap defensive default, not a sign anything is expected to be missing in practice.

  **Note — no changes needed in `getProgressStats()`:** it consumes `SessionHistoryEntry` (already flattened), not raw `SessionLog` rows, so it works unchanged once `getSessionHistory()` returns shared-session entries.

---

### Task 3 — `RpeFeedbackCubit`: persist a standalone `SessionLog` for shared sessions (AC1)

**Why:** This is the single correct touch-point (see Context: `RpePage` already runs for both host and follower). `_resolveSessionLogId()` currently returns `null` whenever `planId == null` — that's the shared-session case, and it's exactly the gap to close.

- [x] **3.1** Edit `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`.

  Replace:
  ```dart
  Future<int?> _resolveSessionLogId() async {
    final explicit = _args?.sessionLogId;
    if (explicit != null) return explicit;
    final planId = _args?.planId;
    final sessionLogsDao = _sessionLogsDao;
    if (planId == null || sessionLogsDao == null) return null;
    final log = await sessionLogsDao.getLogFor(planId, _args!.sessionIndex);
    return log?.id;
  }
  ```
  With:
  ```dart
  Future<int?> _resolveSessionLogId() async {
    final explicit = _args?.sessionLogId;
    if (explicit != null) return explicit;
    final sessionLogsDao = _sessionLogsDao;
    if (sessionLogsDao == null) return null;

    final planId = _args?.planId;
    if (planId != null) {
      final log = await sessionLogsDao.getLogFor(planId, _args!.sessionIndex);
      return log?.id;
    }

    // Shared session (no DailyPlan, Story 21.0 — closes E20R-2 local half).
    // Story 20.4/20.5 deliberately never wrote a SessionLog here; create a
    // standalone row now, anchored to nothing but carrying the denormalized
    // sessionType/armKey/durationMinutes so Progress history (Task 2) can
    // render it without a DailyPlans join.
    final args = _args;
    if (args == null || args.armKey.isEmpty) return null;
    final now = _now();
    final id = await sessionLogsDao.insertLog(
      SessionLogsCompanion(
        dailyPlanId: const Value(null),
        sessionIndex: const Value(0),
        completedAt: Value(now),
        createdAt: Value(now),
        abandoned: Value(args.abandoned),
        sessionType: Value(args.armKey.split('_').first),
        armKey: Value(args.armKey),
        durationMinutes: Value(args.durationMinutes),
      ),
    );
    // insertLog uses InsertMode.insertOrIgnore, which returns 0 on a
    // suppressed UNIQUE-constraint conflict. As established in Task 1.1,
    // NULL dailyPlanId rows can never collide under UNIQUE(dailyPlanId,
    // sessionIndex) — so `id == 0` should not happen here in practice. Guard
    // anyway: a real conflict would otherwise silently anchor RPE to row 0.
    return id == 0 ? null : id;
  }
  ```

  **Critical — `args.armKey.split('_').first` for `sessionType`:** This is an existing codebase convention, not a new pattern — `rpe_page.dart`'s `MiniSummaryArgs(sessionType: args.armKey.split('_').first, ...)` already does exactly this split. `armKey` is always `'{sessionType}_{intensityName}'` (e.g. `'mobility_low'`) per `SharedSessionBloc._onStartTapped`; `sessionType` itself (`'mobility'|'cardio'|'breathing'`) never contains an underscore, so the split is safe.

  **Critical — no import changes needed:** `Value` (from `package:drift/drift.dart`) and `SessionLogsCompanion` (from `app_database.dart`) are already imported in this file.

---

### Task 4 — `SharedSessionBloc`: resolve the current user's own `@handle` (AC3, AC4)

**Why:** `_onJoined` stores `event.displayHandle` (which can be `null`) directly into `_myDisplayHandle` and tracks Presence with it immediately. If the caller (`social_page.dart`) couldn't resolve the handle before navigating, it stays null for the rest of the session unless resolved here.

- [x] **4.1** Edit `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`.

  Add the import:
  ```dart
  import 'package:pulse_coach/features/social/friends/domain/usecases/get_social_profile_use_case.dart';
  ```

  Add the field and extend the constructor:
  ```dart
  final GetSocialProfileUseCase _getSocialProfileUseCase;

  SharedSessionBloc(
    this._gateway,
    this._deleteUseCase,
    this._refreshUseCase,
    this._locationService,
    this._db,
    this._getSocialProfileUseCase, // NEW — resolves own handle when null (E20R-1)
  ) : super(const SharedSessionState.initial()) {
    // ... existing `on<...>` registrations unchanged ...
  }
  ```

  **Critical — `injection.config.dart` regenerates automatically** after `build_runner` (Task 5). Do NOT manually edit it. `GetSocialProfileUseCase` is already `@injectable`, so `get_it` can resolve it with no additional registration.

- [x] **4.2** In `_onJoined`, add the resolution call alongside the existing co-location one:

  Find:
  ```dart
  emit(SharedSessionState.lobby(
    participants: const [],
    isHost: event.isHost,
    steps: event.steps,
    joinCode: event.joinCode,
  ));

  unawaited(_resolveCoLocation(event));
  ```
  Replace with:
  ```dart
  emit(SharedSessionState.lobby(
    participants: const [],
    isHost: event.isHost,
    steps: event.steps,
    joinCode: event.joinCode,
  ));

  unawaited(_resolveCoLocation(event));
  unawaited(_resolveOwnHandle(event));
  ```

- [x] **4.3** Add the `_resolveOwnHandle` method near `_resolveCoLocation`:

  ```dart
  // Resolves the current user's own @handle when the nav arg didn't carry one
  // (SocialProfileBloc hadn't finished loading at create/join time — E20R-1).
  // Runs off the lobby-entry path so entry is never blocked (AC4), mirroring
  // _resolveCoLocation's non-blocking pattern.
  Future<void> _resolveOwnHandle(SharedSessionJoined event) async {
    if (event.displayHandle != null) return;
    final result = await _getSocialProfileUseCase.call();
    if (isClosed || !_joined) return;
    final handle = result.fold((_) => null, (profile) => profile.displayHandle);
    if (handle == null) return;
    _myDisplayHandle = handle;
    await _gateway.trackPresence(
      userId: event.userId,
      displayHandle: handle,
      isHost: _isHost,
      lat: _myLat,
      lon: _myLon,
    );
  }
  ```

  **Critical — failure is silently swallowed (`result.fold((_) => null, ...)`):** A `Left(SocialFailure)` (network error, etc.) must NOT emit an error state or retry — the lobby already rendered with the `sharedSessionParticipantUnknown` fallback (AC4); this is the same fail-open posture as `_resolveCoLocation`'s `posResult.fold<(double, double)?>((_) => null, (c) => c)`.

  **Critical — `isClosed || !_joined` guard:** identical reasoning to `_resolveCoLocation` — the bloc may have been torn down or the channel left while awaiting the network call; do not call `trackPresence` after that.

---

### Task 5 — Regenerate code + update DI-affected tests (AC5)

- [x] **5.1** From `pulse_coach/`, run:
  ```bash
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  ```

  **Expected regenerated files:**
  - `lib/core/database/app_database.g.dart` — new nullable `dailyPlanId`, new `sessionType`/`armKey`/`durationMinutes` columns on `SessionLogs`/`SessionLogsCompanion`/`SessionLog`.
  - `lib/core/di/injection.config.dart` — `SharedSessionBloc` factory gains `gh<_iNNN.GetSocialProfileUseCase>()` as the 6th arg.

- [x] **5.2** Update every test file that constructs `SharedSessionBloc(...)` positionally with 5 args to pass a 6th (mock or real) `GetSocialProfileUseCase`:
  - `test/bloc/shared_session/shared_session_bloc_test.dart` (16 call sites — same pattern throughout, safe for a single find/replace)
  - `test/bloc/shared_session/shared_session_cancel_refresh_bloc_test.dart`
  - `test/bloc/shared_session/shared_session_bloc_co_location_test.dart`
  - `test/bloc/shared_session/drop_out_tolerance_bloc_test.dart`
  - `test/bloc/shared_session/shared_session_20_5_bloc_test.dart`

  For each, add a `MockGetSocialProfileUseCase` (generate via `@GenerateMocks([GetSocialProfileUseCase])` in whichever file doesn't already have a mocks source covering it — check `shared_session_bloc_test.mocks.dart` first) and stub a default:
  ```dart
  when(mockGetSocialProfile.call())
      .thenAnswer((_) async => const Right(SocialProfile(
            userId: 'stub',
            displayHandle: null,
            visibilityTier: VisibilityTier.friendsOnly, // match existing enum values used elsewhere in these tests
          )));
  ```
  passed as the 6th constructor arg everywhere `SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db)` currently appears (append `, mockGetSocialProfile`).

  **Note:** widget tests (`test/widget/shared_session/*`) use `MockSharedSessionBloc()` (a full bloc mock, not the real constructor) and are **unaffected** — do not touch them for this change.

---

### Task 6 — Tests (AC1, AC2, AC3, AC4, AC5)

- [x] **6.1** `test/core/database/app_database_test.dart`:
  - Update `test('schemaVersion is 9', ...)` → `10`.
  - Add `group('AppDatabase - real migration v9 → v10 (Story 21.0)')` with:
    ```
    [21.0-DB-001] v9 raw schema with an existing (dailyPlanId-anchored) session_logs row → migrates to v10 → old row preserved with sessionType/armKey/durationMinutes == null, dailyPlanId unchanged
    [21.0-DB-002] fresh v10 database → insertLog with dailyPlanId: null, sessionIndex: 0 succeeds and round-trips sessionType/armKey/durationMinutes
    [21.0-DB-003] two separate inserts with dailyPlanId: null, sessionIndex: 0 → both succeed (UNIQUE constraint does not treat NULL == NULL) — locks in the Task 1.1 safety argument
    ```
    Follow the exact raw-`sqlite3.openInMemory()` + `PRAGMA user_version` pattern already used for the v8→v9 and v6→v7 groups in this file (see lines 619–685 and 565–617) — build a v9 `session_logs` table (8 columns, as it exists today, WITHOUT the 3 new columns), insert one pre-existing solo row, set `user_version = 9`, open via `AppDatabase.forTesting(NativeDatabase.opened(...))`, then assert.

- [x] **6.2** `test/core/database/daos/session_logs_dao_test.dart`: add a case inserting a row with `dailyPlanId: const Value(null)` and confirm `getAllLogsOrderedByDate()` returns it correctly (id populated, dailyPlanId null).

- [x] **6.3** `test/data/progress/progress_local_data_source_test.dart` (confirmed path):
  ```
  [21.0-PROGRESS-001] getSessionHistory() with a dailyPlanId: null log row → returns a SessionHistoryEntry using the row's own sessionType/durationMinutes, no DailyPlansDao call
  [21.0-PROGRESS-002] getSessionHistory() mixed solo + shared rows → both appear, ordered by completedAt desc as before
  ```

- [x] **6.4** `test/bloc/rpe_feedback_cubit_test.dart` (confirmed path):
  ```
  [21.0-RPE-001] RpeSubmitArgs(planId: null, sessionLogId: null, armKey: 'mobility_low', durationMinutes: 20, abandoned: false) submitted → a SessionLog row is inserted with dailyPlanId: null, sessionType: 'mobility', armKey: 'mobility_low', durationMinutes: 20; rpe_feedback row inserted with sessionLogId == the returned id (non-null)
  [21.0-RPE-002] same as above but sessionLogsDao is null (not registered) → resolves to null gracefully, RPE still written with sessionId: 0 (existing degraded-mode behavior, unchanged)
  ```

  **Note on test doubles:** this file currently only has a `_FakeRpeFeedbackDao` (line 195) — there is no existing fake for `SessionLogsDao`, and the `AppDatabase` import at the top of the file is currently unused (pre-existing, unrelated — do not "fix" it as part of this story beyond what your own new code needs). For `[21.0-RPE-001]`, prefer wiring a **real** `AppDatabase.forTesting(NativeDatabase.memory())` and its real `sessionLogsDao` (add the `package:drift/native.dart` import) rather than hand-writing a new fake — a real round-trip insert + read-back is the strongest verification of the `dailyPlanId: null` + `UNIQUE` behavior this task depends on.

- [x] **6.5** `test/bloc/shared_session/shared_session_bloc_test.dart` (new group):
  ```
  [21.0-BLOC-001] SharedSessionJoined(displayHandle: null) → GetSocialProfileUseCase.call() invoked; on Right(profile with displayHandle: 'alice') → gateway.trackPresence called again with displayHandle: 'alice', isHost matching event.isHost
  [21.0-BLOC-002] SharedSessionJoined(displayHandle: 'bob') (already resolved) → GetSocialProfileUseCase.call() is NEVER invoked
  [21.0-BLOC-003] SharedSessionJoined(displayHandle: null), GetSocialProfileUseCase.call() returns Left(failure) → no error state emitted; lobby state remains from the initial emission
  [21.0-BLOC-004] bloc closed before GetSocialProfileUseCase.call() resolves → trackPresence is NOT called again (isClosed guard)
  ```

- [x] **6.6** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Expected: 0 analyzer issues; all pre-existing tests + all new tests pass.

---

## Review Findings

_Code review 2026-07-02 (bmad-code-review, 3 parallel adversarial layers: Blind Hunter, Edge Case Hunter, Acceptance Auditor; model claude-opus-4-8). 2 patch (HIGH), 1 defer (LOW), 3 dismissed. **Both patches applied and verified**: `flutter analyze lib/ test/` → 0 issues; `flutter test` → 1259 passed (1257 baseline + 2 new regression tests: `21.0-DB-004` for the migration, `21.0-BLOC-005` for the handle race), 0 failed._

- [x] [Review][Patch] (FIXED 2026-07-02) `_resolveCoLocation` clobbers the freshly-resolved own @handle back to null — defeats AC3 [pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart:124] — `_onJoined` runs `_resolveCoLocation` and `_resolveOwnHandle` concurrently (both `unawaited`). `_resolveOwnHandle` sets `_myDisplayHandle` and re-tracks presence with the resolved handle, but `_resolveCoLocation` re-tracks with `displayHandle: event.displayHandle` — the ORIGINAL nav-arg, which is `null` in the exact E20R-1 scenario this story fixes. On a location-enabled device where GPS resolves after the profile lookup, co-location's `trackPresence` overwrites the handle back to null, reverting the lobby row to `sharedSessionParticipantUnknown`. Found independently by Edge Case Hunter + Acceptance Auditor, confirmed by source read. Fix: `_resolveCoLocation` must send `displayHandle: _myDisplayHandle` (consistent with how it already reads `_isHost`/`_myLat`/`_myLon`), not `event.displayHandle`. Add a regression test with `getCityLevelCoordinates` stubbed to `Right(...)` so the concurrent re-track path is actually exercised (current bloc tests stub it to `Left`, so 21.0-BLOC-001 cannot catch this).
- [x] [Review][Patch] (FIXED 2026-07-02) Migration v9→v10 can silently destroy all session history if the process is killed between `createTable` and the row copy [pulse_coach/lib/core/database/app_database.dart:175] — `onUpgrade` is NOT wrapped in a transaction (verified in drift 2.33 `db_base.dart:118-142`: it runs inside `BeforeOpenRunner` with no enclosing transaction — which is also why the FK PRAGMA toggle here is effective and why the v8/v9 partial-upgrade guards exist). Statements autocommit individually. Failure interleaving: kill after `createTable(session_logs)` commits but before `INSERT … SELECT … FROM session_logs_v9` completes → on retry `session_logs` exists (empty) so `newTableExists.isEmpty` is false → the whole create+copy block is skipped → `DROP TABLE IF EXISTS session_logs_v9` runs unconditionally → real user history permanently lost. The guard covers the rename step but not the create→copy pair. Found by Blind Hunter + Edge Case Hunter. Fix: make the copy idempotent and gate the drop on it — e.g. keep `createTable` guarded, run `INSERT OR IGNORE INTO session_logs (…) SELECT … FROM session_logs_v9` whenever the backup still exists (re-runs harmlessly since ids collide under the PK), and only then `DROP`. Add a `[21.0-DB-004]` test simulating the resumed-after-partial-copy state (session_logs empty + session_logs_v9 populated, user_version still 9) → data preserved.
- [x] [Review][Defer] Abandoned shared-session rows would report 0 weekly minutes (elapsedSeconds never persisted) [pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart:86] — deferred, latent. The shared-session `SessionLog` is inserted without `elapsedSeconds`, so `getProgressStats` (`progress_local_data_source.dart:143-145`) would compute `(elapsedSeconds ?? 0) ~/ 60 == 0` for an abandoned entry. Not reachable today: shared sessions hardcode `abandoned: false` (Story 20.4 decision, restated in this story's Dev Notes), so they take the `durationMinutes` branch. Becomes a live data-quality bug the moment host-abandon fidelity is wired (the same future protocol change already flagged out-of-scope here). Revisit alongside that work.

## Dev Notes

### Why `RpeFeedbackCubit` and Not `InSessionCubit`/`SharedSessionBloc` for the Write

The host's `InSessionCubit` (`_SharedInSessionViewState._initHostCubit`) is deliberately built with `sessionLogsDao: null, planId: null` — wiring a real DAO there would only cover the **host**, not the follower (who never runs an `InSessionCubit` at all; `_buildFollowerView` is a pure display widget with no completion callback). Writing the log in `RpeFeedbackCubit` instead covers both roles with a single change, because `RpePage`/`RpeFeedbackCubit` is the one screen every participant — host or follower — passes through after `sessionEnded`. This also sidesteps the exact host/follower-asymmetry trap the Epic 20 retro flagged as `E20R-B1` ("compare host vs follower renderings, not just internal state") — there is no separate follower code path to forget here.

### NULL Semantics on the `UNIQUE(dailyPlanId, sessionIndex)` Constraint

Standard SQL (and SQLite specifically) treats every `NULL` in a `UNIQUE` index as distinct from every other `NULL` — two rows with `dailyPlanId: NULL, sessionIndex: 0` do **not** violate the constraint. This is why no schema change to `uniqueKeys` and no new DAO method are needed to support many shared-session rows all sharing `dailyPlanId: null, sessionIndex: 0`. This is non-obvious and worth double-checking against the actual `sqlite3` behavior in Task 6.1's `[21.0-DB-003]` test rather than trusting the general SQL rule alone.

### `abandoned` Flag Fidelity Is Not Improved by This Story

`shared_session_lobby_page.dart`'s `sessionEnded` listener hardcodes `abandoned: false` in the `RpeSubmitArgs` it builds, regardless of whether the session ended via all-steps-complete or a host abandon (`_onHostAbandon` dispatches the identical `SessionEndRequested` event as natural completion). This story persists whatever `abandoned` value already flows through `RpeSubmitArgs` — it does not add a new signal to distinguish the two cases. A host-abandoned shared session will currently still be recorded as `abandoned: false`. Flagging this explicitly so it isn't mistaken for something Task 3 was supposed to fix; changing it would require a broadcast protocol change (a new payload field on `session_ended`) and is out of scope.

### `SessionType` Derivation Convention (`armKey.split('_').first`)

Not a new pattern — `rpe_page.dart` already does `sessionType: args.armKey.split('_').first` when building `MiniSummaryArgs`. Task 3 reuses the exact same derivation rather than adding a new `sessionType` field to `RpeSubmitArgs`, keeping the nav-arg surface unchanged.

### Migration Partial-Failure Guard (Task 1.2)

This codebase has an established convention (see the existing v8 and v9 `onUpgrade` blocks in `app_database.dart`) of guarding schema migrations against a process kill mid-upgrade leaving the DB in a state where blindly re-running the migration throws (e.g. "duplicate column" or, here, "table already exists"). The v9→v10 migration is more involved than a simple `addColumn` (it renames, recreates, copies, and drops), so the guard checks for the backup table's existence AND the new table's existence independently before acting, so any of the three possible kill-points (before rename, after rename but before recreate+copy, after recreate+copy but before drop) resume correctly on the next app launch.

### File Size Check

- `shared_session_bloc.dart`: 426 lines → +~20 lines (Task 4) ≈ 446 lines.
- `rpe_feedback_cubit.dart`: 81 lines → +~25 lines (Task 3) ≈ 106 lines.
- `progress_local_data_source.dart`: 172 lines → +~15 lines (Task 2) ≈ 187 lines.
- `app_database.dart`: 151 lines → +~30 lines (Task 1.2) ≈ 181 lines.
All well under the project's 800-line hard limit.

### Project Structure Notes

**Modified production files:**
- `lib/core/database/tables/session_logs_table.dart`
- `lib/core/database/app_database.dart`
- `lib/features/progress/data/datasources/progress_local_data_source.dart`
- `lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`
- `lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`

**Auto-regenerated files (do not edit manually):**
- `lib/core/database/app_database.g.dart`
- `lib/core/di/injection.config.dart`

**Modified test files:**
- `test/core/database/app_database_test.dart`
- `test/core/database/daos/session_logs_dao_test.dart`
- `test/bloc/shared_session/shared_session_bloc_test.dart`
- `test/bloc/shared_session/shared_session_cancel_refresh_bloc_test.dart`
- `test/bloc/shared_session/shared_session_bloc_co_location_test.dart`
- `test/bloc/shared_session/drop_out_tolerance_bloc_test.dart`
- `test/bloc/shared_session/shared_session_20_5_bloc_test.dart`
- `test/data/progress/progress_local_data_source_test.dart`
- `test/bloc/rpe_feedback_cubit_test.dart`

### References

- [Source: epics.md#Story 21.0 lines ~2747–2770 — full ACs]
- [Source: epics.md#Epic 21 Prerequisites lines ~2742–2745 — hard-block + 21.3 dependency note]
- [Source: action-item-ledger.md — E20R-1, E20R-2, E20R-B1 entries + Epic 21 kickoff triage promotion]
- [Source: _bmad-output/implementation-artifacts/epic-20-retro-2026-06-29.md — root-cause writeup for both gaps]
- [Source: lib/features/session/presentation/bloc/rpe_feedback_cubit.dart:66 — `_resolveSessionLogId`, the extension point]
- [Source: lib/features/session/presentation/pages/rpe_page.dart:51 — single RpePage construction site, host+follower shared]
- [Source: lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart:446 — `_initHostCubit` with `sessionLogsDao: null`]
- [Source: lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart:65,110 — `_onJoined`, `_resolveCoLocation` pattern to mirror]
- [Source: lib/core/database/daos/session_logs_dao.dart — `insertLog`/`upsertCompletion`/`getAllLogsOrderedByDate`]
- [Source: lib/core/database/tables/session_logs_table.dart — current schema, `uniqueKeys`]
- [Source: lib/core/database/app_database.dart:61,64-143 — schemaVersion, onUpgrade chain v2–v9, migration guard conventions]
- [Source: lib/features/progress/data/datasources/progress_local_data_source.dart:24-79 — `getSessionHistory()` join + skip-on-missing-plan logic]
- [Source: lib/features/social/friends/domain/usecases/get_social_profile_use_case.dart — `GetSocialProfileUseCase.call()`]
- [Source: test/core/database/app_database_test.dart — established raw-sqlite3 migration test pattern, esp. lines 619–685 (v8→v9) and 462–509 (v4→v6 composite)]
- [Source: _bmad-output/implementation-artifacts/20-5-per-participant-rpe-and-protective-state-social-suppression.md — prior story's dev notes on `_armKey`/`sessionType` derivation and the "steps generated at page level" precedent]

## Dev Agent Record

### Agent Model Used

claude-sonnet-5

### Debug Log References

None — no blocking failures during implementation.

### Completion Notes List

- Task 1 (schema v9→v10): `session_logs_table.dart` made `dailyPlanId` nullable, added `sessionType`/`armKey`/`durationMinutes`; `app_database.dart` migration guarded against both partial mid-migration kill (existing backup-table pattern) and minimal test databases that omit `session_logs` entirely (extended the guard beyond the story's exact snippet, since the v7/v8 raw-schema regression tests in `app_database_test.dart` construct fixtures without a `session_logs` table — the unconditional rename in the story's literal code would have thrown on those). `build_runner` regenerated `app_database.g.dart`.
- Task 2: `ProgressLocalDataSource.getSessionHistory()` now branches on `log.dailyPlanId == null` before the `DailyPlansDao` join, building `SessionHistoryEntry` from the row's own denormalized fields.
- Task 3: `RpeFeedbackCubit._resolveSessionLogId()` extended for the shared-session case (`planId == null`), inserting a standalone `SessionLog` row via the existing `SessionLogsDao.insertLog` (no new DAO method needed, per Task 1.1's NULL-uniqueness argument — verified in `[21.0-DB-003]`).
- Task 4: `SharedSessionBloc` now takes a 6th constructor arg (`GetSocialProfileUseCase`) and resolves the current user's own handle asynchronously via `_resolveOwnHandle`, mirroring `_resolveCoLocation`'s non-blocking/fail-open pattern.
- Task 5: `build_runner` regenerated `injection.config.dart` (confirmed the `SharedSessionBloc` factory gained the 6th `GetSocialProfileUseCase` arg). All 5 test files listed in the story plus `shared_session_20_5_bloc_test.dart` (which declares its own separate `@GenerateNiceMocks` list, not covered by the shared `.mocks.dart` files) were updated with a `MockGetSocialProfileUseCase` stub.
- Task 6: added all specified tests (`21.0-DB-001..003`, `21.0-DAO-001`, `21.0-PROGRESS-001..002`, `21.0-RPE-001..002`, `21.0-BLOC-001..004`).
- **Collateral fixes beyond the story's file list** (all required to keep `flutter analyze`/`flutter test` green after making `dailyPlanId` nullable, per AC5's zero-regression bar — not scope creep, just fallout from the schema change touching a field several other files reference):
  - `lib/features/settings/data/repositories/ai_decision_log_repository.dart`: `_armKeyFor` now guards `sessionLog.dailyPlanId == null` and returns the row's own denormalized `armKey` for shared sessions instead of attempting a `DailyPlansDao` join with a null id.
  - Several pre-existing tests (`test/core/database/data_persistence_test.dart`, `test/data/auth/backup_local_data_source_test.dart`, `test/data/repositories/ai_decision_log_repository_test.dart`, `test/core/database/daos/session_logs_dao_test.dart`) constructed `SessionLogsCompanion(.insert)` with a raw `int` for `dailyPlanId`; now that the field is `Value<int?>`, these were wrapped in `Value(...)`.
  - `test/core/database/data_persistence_test.dart`'s `13.3-PERSIST-006` hardcoded the expected post-migration `PRAGMA user_version` as `9`; updated to `10`.
- Full regression: `flutter analyze lib/ test/` → 0 issues. `flutter test` → 1257 passed (1245 baseline + 12 new), 0 failed, 1 pre-existing skip.

### File List

**Modified production files:**
- `pulse_coach/lib/core/database/tables/session_logs_table.dart`
- `pulse_coach/lib/core/database/app_database.dart`
- `pulse_coach/lib/core/database/app_database.g.dart` (regenerated)
- `pulse_coach/lib/core/di/injection.config.dart` (regenerated)
- `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart`
- `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`
- `pulse_coach/lib/features/settings/data/repositories/ai_decision_log_repository.dart` (collateral — nullable `dailyPlanId` guard)

**Modified/added test files:**
- `pulse_coach/test/core/database/app_database_test.dart`
- `pulse_coach/test/core/database/daos/session_logs_dao_test.dart`
- `pulse_coach/test/core/database/data_persistence_test.dart` (collateral)
- `pulse_coach/test/data/progress/progress_local_data_source_test.dart`
- `pulse_coach/test/data/auth/backup_local_data_source_test.dart` (collateral)
- `pulse_coach/test/data/repositories/ai_decision_log_repository_test.dart` (collateral)
- `pulse_coach/test/bloc/rpe_feedback_cubit_test.dart`
- `pulse_coach/test/bloc/shared_session/shared_session_bloc_test.dart`
- `pulse_coach/test/bloc/shared_session/shared_session_cancel_refresh_bloc_test.dart`
- `pulse_coach/test/bloc/shared_session/shared_session_cancel_refresh_bloc_test.mocks.dart` (regenerated)
- `pulse_coach/test/bloc/shared_session/shared_session_bloc_co_location_test.dart`
- `pulse_coach/test/bloc/shared_session/drop_out_tolerance_bloc_test.dart`
- `pulse_coach/test/bloc/shared_session/shared_session_20_5_bloc_test.dart`
- `pulse_coach/test/bloc/shared_session/shared_session_20_5_bloc_test.mocks.dart` (regenerated)

## Change Log

- 2026-07-01: Implemented Story 21.0 — schema migration v9→v10 (nullable `SessionLogs.dailyPlanId` + `sessionType`/`armKey`/`durationMinutes`), Progress history rendering for shared sessions without a `DailyPlan` join, standalone `SessionLog` persistence on shared-session RPE submit (closes E20R-2 local half), and async own-`@handle` resolution in `SharedSessionBloc` (closes E20R-1). 12 new tests added; full regression suite green (1257/1257, 0 analyzer issues).
