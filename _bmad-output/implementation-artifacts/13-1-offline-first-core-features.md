# Story 13.1: Offline-First Core Features

Status: done

## Story

As a user,
I want all core features to work without network connectivity,
so that I can use PulseCoach anywhere without worrying about connectivity.

## Acceptance Criteria

**AC1 — Plan generation succeeds offline:**
Given the device has no network connectivity
When the user opens the app
Then plan generation succeeds using cached exercises, cached weather/AQI (or indoor default), and RPE history — zero error states visible (FR45, NFR13)

**AC2 — Session + RPE persist locally when offline:**
Given no network connectivity
When a session is completed and RPE is submitted
Then the session is stored locally and the bandit is updated — no data loss (FR45)

**AC3 — Progress renders from local data offline:**
Given no network connectivity
When the user navigates to Progress
Then history and charts render from local data — no "offline" error message (FR45)

**AC4 — Mid-session network loss is transparent:**
Given the app goes offline mid-session
When the session continues
Then the session completes normally — no interruption from network loss

**AC5 — E10R-1 closed (release observability for persistenceError):**
Given a `session_log` write fails at runtime
When the failure is caught by `TodaySessionCubit` or `InSessionCubit`
Then a release-level log line (`AppLogger.error`) is emitted with the failure detail — the silent-failure-in-release gap is closed

## Tasks / Subtasks

- [x] Task 1: Audit offline paths (AC1–AC4) — read-only, no new code
  - [x] 1.1 Trace AC1: `GenerateDailyPlan._buildStateVector` → `WeatherRepository` (ServerFailure → AqiLevel.low) and `_enrichPlanWithCatalog` (CacheFailure → session unchanged). Confirm both branches are reachable and already tested.
  - [x] 1.2 Trace AC2: `InSessionCubit._persistCompletion` → `SessionLogsDao.upsert` (local Drift write, no network path). Confirm no network call in the session completion + RPE submission path.
  - [x] 1.3 Trace AC3: `ProgressCubit` → `SessionLogsDao.watchLogsForPlan`, `RpeFeedbackDao` (pure local reads, no network path). Confirm no network call in the progress render path.
  - [x] 1.4 Trace AC4: `InSessionCubit` timer loop and step transitions — confirm no network call in the in-session execution path.
  - [x] 1.5 Document any network call NOT yet guarded that could cause an error state when offline (expected: none, but verify).

- [x] Task 2: Write offline-scenario test suite (AC1–AC4) — new file `test/offline/offline_core_features_test.dart`
  - [x] 2.1 AC1 test — plan gen with both weather ServerFailure and exercise ServerFailure (bundled fallback): mock `WeatherRepository` to return `Left(ServerFailure('offline'))`, mock `ExerciseRemoteDataSource` to throw `ServerException`, seed local exercise cache and weather cache rows in the in-memory DB. Call `GenerateDailyPlan.call()`. Assert `Right(GenerateDailyPlanResult(...))` is returned (no error state).
  - [x] 2.2 AC1 edge — plan gen with no exercise cache AND remote failure: all ExerciseDB calls throw `ServerException`, no rows in `exercise_cache`. Assert bundled fallback is used and plan generation still returns `Right(...)`.
  - [x] 2.3 AC2 test — session completion and RPE persistence without any network: use in-memory Drift DB, call `SessionLogsDao.upsertSessionLog` + `RpeFeedbackDao.insertFeedback` directly. Assert rows persisted correctly.
  - [x] 2.4 AC3 test — Progress query from local DB without network: seed `session_logs` and `rpe_feedback` rows in in-memory DB, call `ProgressCubit` equivalent queries directly. Assert data is returned without any `Failure`.
  - [x] 2.5 AC4 test — `InSessionCubit` step transitions with no external I/O: construct cubit with mocked repositories returning `Left(...)` for any network call. Advance timer to trigger step transition. Assert state progression is unaffected.
  - [x] 2.6 Name all tests with IDs `13.1-OFFLINE-001` through `13.1-OFFLINE-0xx` for traceability.

- [x] Task 3: Close E10R-1 — release observability for `persistenceError` (AC5)
  - [x] 3.1 Read `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart` and `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart` to understand where `persistenceError` is set.
  - [x] 3.2 In `TodaySessionCubit._onLogsChanged` (around line 170 in `today_session_cubit.dart`): ensure that when `persistenceError` is set, `AppLogger.error(...)` is called with the failure detail. Currently the cubit sets the error but only logs at `warning` level (or not at all at release). Add or promote to `AppLogger.error` with `name: 'TodaySessionCubit'`.
  - [x] 3.3 In `InSessionCubit._persistCompletion`: similarly ensure `AppLogger.error(...)` fires when the session log write fails, with `name: 'InSessionCubit'`.
  - [x] 3.4 Add test `13.1-E10R1-001`: `TodaySessionCubit` with mocked `SessionLogsDao` that throws → `persistenceError` set in state AND `AppLogger.error` called.
  - [x] 3.5 Verify `AppLogger.error` behavior at release — check `pulse_coach/lib/core/logging/app_logger.dart` to confirm the error level is not a no-op in release mode. If it is, add a release-mode sink (at minimum a `debugPrint` guard or a stub — document the gap clearly in `action-item-ledger.md` if a full Crashlytics integration is out of scope for this story).

- [x] Task 4: Verify all existing tests still pass
  - [x] 4.1 Run `flutter test` from `pulse_coach/`. Target: ≥ 771 existing + new offline tests (≥ 778 total). All existing tests must remain green.
  - [x] 4.2 Run `flutter analyze` from `pulse_coach/`. Must be 0 issues.

## Dev Notes

### What Is Already Implemented (Do Not Reinvent)

The offline-first behavior is substantially already in place. This story is primarily a **testing + audit + E10R-1 closure** story, not a new-feature story.

**Already offline-safe (verified by code audit):**

| Path | File | How |
|---|---|---|
| Weather offline | `weather_repository_impl.dart` | `ServerException` → returns stale cache if available, else `Left(ServerFailure)` |
| Weather indoor default | `generate_daily_plan.dart:253-256` | `weatherResult.fold((_) => AqiLevel.low, ...)` — explicit indoor default |
| Exercise offline | `exercise_repository_impl.dart` | cache-first → bundled fallback → `Left(CacheFailure)` |
| Catalog enrichment failure | `generate_daily_plan.dart:149-155` | `result.fold(failure: return session, ...)` — enrichment failure is a warning, not a blocking error |
| Session + RPE persistence | `SessionLogsDao`, `RpeFeedbackDao` | pure local Drift writes, no network path |
| Progress reads | `ProgressCubit` | pure local Drift reads, no network path |
| In-session timer | `InSessionCubit` | local state machine + Drift writes, no network path |

**Existing test coverage (do not duplicate):**

- `5.5-UNIT-013` in `generate_daily_plan_test.dart` — weather failure → AqiLevel.low, plan generated
- `4.1-UNIT-006` in `weather_repository_impl_test.dart` — location available, API throws → `Left(ServerFailure)`
- Several exercise repository tests covering ServerException + stale cache scenarios

### E10R-1 Closure

E10R-1 (from the Epic 10 retro, `action-item-ledger.md`) requires that when a `session_log` write fails at runtime, the failure is not completely silent in release builds. The current behavior: `TodaySessionCubit` emits `persistenceError` into state (which the UI *could* surface) but `AppLogger` is a debug-only stub — no release log or telemetry exists.

The minimum viable fix for this story: ensure `AppLogger.error(...)` is called when the persistence error is set, so that when a real log sink is attached (Crashlytics, analytics) it will fire. The full Crashlytics integration is explicitly out of scope for v1; document this clearly.

**Key files to read before Task 3:**
- `pulse_coach/lib/core/logging/app_logger.dart` — understand current release behavior
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart` — `persistenceError` set around line 170
- `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart` (or `in_session_bloc.dart`) — `persistenceError` in `InSessionState`

### Offline Test Pattern

Use in-memory Drift: `AppDatabase.forTesting(NativeDatabase.memory())` for all DAO-level tests.
Use mockito for repository-layer tests: `@GenerateMocks([WeatherRepository, ExerciseRepository, ...])`

The test file goes in `test/offline/offline_core_features_test.dart`. Mirror the existing pattern from `test/core/database/daos/sync_queue_dao_test.dart` for DAO tests and `test/features/daily_plan/generate_daily_plan_test.dart` for use-case tests.

Test ID numbering: `13.1-OFFLINE-001` through `13.1-OFFLINE-006` for the 6 scenario tests in Task 2, plus `13.1-E10R1-001` for Task 3.4.

### Architecture Constraints

- No new packages needed. `connectivity_plus` is **not** required for this story — offline behavior is achieved through graceful `DioException`/`ServerException` handling already in place. Network-state monitoring (if needed for the sync trigger) belongs to Story 13.2.
- All writes to `session_logs`, `rpe_feedback`, `daily_plans`, `bandit_state`, `behavioral_state` use local Drift — no network path exists to guard.
- The `SyncQueue` table is already defined in the DB schema (`sync_queue_table.dart`, `sync_queue_dao.dart`) but `SyncManager` is NOT yet implemented. Story 13.1 does not implement `SyncManager` — that is Story 13.2. Do not enqueue anything in `SyncQueue` in this story.
- Do not add `connectivity_plus` to `pubspec.yaml` in this story.

### Project Structure Notes

New test file location: `pulse_coach/test/offline/offline_core_features_test.dart`
The `offline/` subfolder is new — create it. It mirrors the naming of `test/integration/` for scenario-level tests.

No new `lib/` files are expected. If E10R-1 requires a new log sink stub, add it to `pulse_coach/lib/core/logging/` (existing module).

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md` §Epic 13, Story 13.1 (lines 1788–1811)
- Offline behavior requirements: PRD FR45, NFR13, NFR14, NFR23 (`prd.md`)
- Weather repo: `pulse_coach/lib/features/weather/data/repositories/weather_repository_impl.dart`
- Exercise repo: `pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart`
- Daily plan gen: `pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart` (weather indoor default at line 253, catalog enrichment failure at line 149)
- E10R-1 context: `_bmad-output/implementation-artifacts/action-item-ledger.md` §Epic 10 retro items
- Sync queue schema (DO NOT implement `SyncManager` here): `pulse_coach/lib/core/database/tables/sync_queue_table.dart`, `pulse_coach/lib/core/database/daos/sync_queue_dao.dart`
- Existing offline tests to NOT duplicate: `test/features/daily_plan/generate_daily_plan_test.dart` test `5.5-UNIT-013`; `test/data/repositories/weather_repository_impl_test.dart` test `4.1-UNIT-006`
- Test pattern reference: `test/core/database/daos/sync_queue_dao_test.dart`
- AppLogger: `pulse_coach/lib/core/logging/app_logger.dart`

## Review Findings

_Code review 2026-06-04 (BMad adversarial 3-layer: Blind Hunter + Edge Case Hunter + Acceptance Auditor)._

### Patch (actionable now)

- [x] [Review][Patch] Constrain always-on release error logging (resolved from Decision D1 → "vincola ora") — aggregated the per-record `AppLogger.error` calls in both `getCachedExercisesByType` (corrupt cache rows) and `loadFallbackExercisesByType` (malformed fallback records) into a single post-loop summary log, so a corrupt cache/fallback file can no longer emit one release log line per bad record. [pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart]
- [x] [Review][Patch] AC5 untested for `InSessionCubit` — added `13.1-E10R1-002`: wires a throwing `SessionLogsDao` + `planId` into `InSessionCubit`, runs to completion, asserts `persistenceError == ServerFailure('session_log_write_failed')` and `AppLogger.error` fired with `name: 'InSessionCubit'`, `level: 1000`. [test/offline/offline_core_features_test.dart]
- [x] [Review][Patch] `13.1-OFFLINE-002` now proves the bundled-fallback path — added a repository-level assertion that `ExerciseRepositoryImpl.getExercisesByType('cardio')` recovers non-empty cardio exercises from `assets/data/fallback_exercises.json` (confirmed loadable under `flutter test`). [test/offline/offline_core_features_test.dart]
- [x] [Review][Patch] `13.1-OFFLINE-001` now proves the stale cache is used — added a repository-level assertion that the 25h-stale `cached-cardio` entry is returned by the recovery path; remote `verify` bumped to `.called(2)`. [test/offline/offline_core_features_test.dart]

### Deferred

- [x] [Review][Defer] Release `dev.log` branch is structurally untestable in the debug test harness [app_logger.dart:78] — `flutter test` runs with `kReleaseMode == false`; `13.1-E10R1-001` verifies the `debugSink` seam (`level == 1000`), not the real release `dev.log`. The seam approach is the accepted compromise; consider renaming/commenting the test so it does not overclaim "release-level" verification. — deferred, test-harness limitation.
- [x] [Review][Defer] AC1 "RPE history" generation input is not exercised [test/offline/offline_core_features_test.dart:89-94] — the AI engine is mocked by design, so any RPE-history read inside generation is bypassed; coverage (if any) lives in existing `generate_daily_plan` tests. — deferred, pre-existing / out of this suite's scope.

### Dismissed (5)

In-session timer `pump(2s)/pump(4s)` tests are deterministic given equal 1s steps (off-by-one flake concern not reproducible); `debugSink` global is correctly reset in this file's `tearDown`; `debug()/warning()` sink firing unconditionally is the intended test seam; `OFFLINE-003/004` single-row round-trip is sufficient for AC2/AC3 scope; `_ThrowingLiveHrService` sync-throw is caught by the `await ... fetchLiveHr()` try at `in_session_cubit.dart:161`.

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story context engine, 2026-06-04)

### Debug Log References

- 2026-06-04: `flutter test test/offline/offline_core_features_test.dart` — red before logger test hook/mock generation, then green with 7/7 tests.
- 2026-06-04: `dart run build_runner build --delete-conflicting-outputs` — generated `offline_core_features_test.mocks.dart`; build_runner reported the repo's existing ignored flag warning and json_annotation constraint warning.
- 2026-06-04: `flutter analyze` — no issues found.
- 2026-06-04: `flutter test` — all tests passed, 787/787.

### Completion Notes List

- Audited AC1–AC4 offline paths: plan generation degrades weather failures to `AqiLevel.low`, catalog enrichment failures do not block returned plans, session/RPE persistence is local Drift-only, Progress history reads local DAO data, and the in-session timer/step path has no network dependency.
- Added a scenario-level offline suite covering plan generation with stale cache recovery, bundled fallback catalog recovery, local session + RPE persistence, local Progress history rendering, and mid-session optional HR I/O failure transparency.
- Closed E10R-1 by making `AppLogger.error` emit through `dart:developer` in release builds and adding a test-only sink to verify `TodaySessionCubit` logs persistence failures when it sets `persistenceError`.
- Verified existing `TodaySessionCubit` and `InSessionCubit` completion failure paths already call `AppLogger.error` with the correct logger names; no cubit behavior changes were required.

### File List

- `_bmad-output/implementation-artifacts/13-1-offline-first-core-features.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/core/logging/app_logger.dart`
- `pulse_coach/test/offline/offline_core_features_test.dart`
- `pulse_coach/test/offline/offline_core_features_test.mocks.dart`

### Change Log

- 2026-06-04: Implemented Story 13.1 offline verification suite and E10R-1 release-level persistence error observability.
