# Story 13.3: Data Persistence Guarantees

Status: done

## Story

As a developer,
I want explicit tests validating that all critical data survives app lifecycle events,
so that NFR15 and NFR16 are provably met and not just assumed.

## Acceptance Criteria

**AC1 — Force-close persistence (NFR15):**
Given the app is force-closed mid-session
When the app is re-opened
Then the daily plan, session history, bandit state, and behavioral state are all intact in the database (NFR15)

**AC2 — Schema migration with user data (NFR16):**
Given the app is updated to a new version with a schema migration
When the app launches post-update
Then all existing user data (sessions, RPE feedback, bandit state) is accessible and the migration succeeds without data loss (NFR16, ARCH3)

**AC3 — TTL cache integrity (NFR14):**
Given `cachedAt` timestamps exist for weather and exercise data
When the TTL check runs
Then data within TTL is served; data outside TTL triggers a background refresh if network is available (NFR14)

## Tasks / Subtasks

- [x] Task 1: Write AC1 force-close persistence tests (file-backed DB write → close → reopen)
  - [x] 1.1 `13.3-PERSIST-001`: daily plan survives DB close and reopen — write `DailyPlan` row to file-backed DB, close, reopen with new connection to same file, assert row is intact.
  - [x] 1.2 `13.3-PERSIST-002`: session + session_log survive DB close and reopen — seed a `DailyPlan` (required FK), write a `SessionLog` row, close, reopen, assert both rows intact (tests FK-enforced child).
  - [x] 1.3 `13.3-PERSIST-003`: bandit state survives DB close and reopen — write `BanditState` row, close, reopen, assert `armWeightsJson` intact.
  - [x] 1.4 `13.3-PERSIST-004`: behavioral state survives DB close and reopen — write `BehavioralState` row, close, reopen, assert `currentState` intact.
  - [x] 1.5 `13.3-PERSIST-005`: RPE feedback survives DB close and reopen — write `RpeFeedback` row, close, reopen, assert `rpeValue` intact.

- [x] Task 2: Write AC2 schema migration with live data test
  - [x] 2.1 `13.3-PERSIST-006`: v1→v8 composite migration — sessions + bandit_state + rpe_feedback data all accessible post-migration. Construct a raw sqlite3 DB at schema v1 (all tables at their pre-migration shapes, `user_version = 1`), seed rows in `sessions`, `bandit_state`, and `rpe_feedback` (without `session_log_id`), open via `AppDatabase.forTesting(NativeDatabase.opened(raw))`, assert all three data sets are readable after the full v1→v8 upgrade chain.

- [x] Task 3: Write AC3 TTL cache integrity tests (in-memory DB, DAO-level)
  - [x] 3.1 `13.3-PERSIST-007`: weather `cachedAt` within TTL — insert `WeatherCache` row with `cachedAt = now - 30min`, retrieve, assert `now - cachedAt < Duration(hours: 1)` is `true`.
  - [x] 3.2 `13.3-PERSIST-008`: weather `cachedAt` outside TTL — insert `WeatherCache` row with `cachedAt = now - 2h`, retrieve, assert `now - cachedAt < Duration(hours: 1)` is `false`.
  - [x] 3.3 `13.3-PERSIST-009`: exercise `cachedAt` within TTL — insert `ExerciseCache` row with `cachedAt = now - 12h`, retrieve, assert `now - cachedAt < Duration(hours: 24)` is `true`.
  - [x] 3.4 `13.3-PERSIST-010`: exercise `cachedAt` outside TTL — insert `ExerciseCache` row with `cachedAt = now - 26h`, retrieve, assert `now - cachedAt < Duration(hours: 24)` is `false`.

- [x] Task 4: Verify
  - [x] 4.1 Run `flutter test` from `pulse_coach/`. Target: ≥ 799 existing + 10 new = ≥ 809 total. All existing tests remain green.
  - [x] 4.2 Run `flutter analyze` from `pulse_coach/`. Must be 0 issues.

## Review Findings

_Code review 2026-06-04 (3 layers: Blind Hunter, Edge Case Hunter, Acceptance Auditor). Acceptance Auditor verdict: PASS — all 3 ACs satisfied, diff is test-only, v1 schema shape verified correct against commit `b42b57c`. `flutter test` 809/809 green and `flutter analyze` clean re-verified live during review._

- [x] [Review][Decision→Patch] TTL tests 007–010 re-implement the threshold comparison inline instead of invoking production `_isCacheValid`. Resolved: added near-boundary tests that drive the real `_isCacheValid` strict `<` edge through the repository public API — `13.3-PERSIST-013` (weather, 59min → served, no fetch) and `13.3-PERSIST-014` (exercise, 23h59m → served, no remote). Documented that the exact-`<`-vs-`<=` case cannot be pinned because production reads its own `DateTime.now()`. [pulse_coach/test/data/repositories/weather_repository_impl_test.dart, exercise_repository_impl_test.dart]
- [x] [Review][Decision→Patch] PERSIST-002/005 did not assert FK behavior. Resolved: added an FK-enforcement group — `13.3-PERSIST-011` (orphan `session_logs` insert via default insert mode → rejected with `SqliteException`, proving `PRAGMA foreign_keys = ON` + the constraint) and `13.3-PERSIST-012` (delete daily plan → `onDelete: cascade` removes child logs). [pulse_coach/test/core/database/data_persistence_test.dart]
- [x] [Review][Patch] Missing `addTearDown(db.close)` — DB connection + file-handle leak on assertion failure across PERSIST-001..005 and migration test 006. Resolved: registered `addTearDown` on every opened db (db1, db2, migratedDb); the raw sqlite3 handle is disposed via drift's `closeUnderlyingWhenDisposed`. [pulse_coach/test/core/database/data_persistence_test.dart]
- [x] [Review][Patch] PERSIST-006 did not assert the migration reached version 8. Resolved: added `PRAGMA user_version` assertion (== 8) proving the full v1→v8 chain ran before the data-only checks. [pulse_coach/test/core/database/data_persistence_test.dart:162-210]
- [x] [Review][Defer] Partial-v8 idempotency branch (`hasSessionLogId` already-present case in the `from < 8` migration step) has zero coverage [pulse_coach/lib/core/database/app_database.dart] — deferred, out of this story's scope (separate migration-edge test)
- [x] [Review][Defer] TTL tests 007–010 read live `DateTime.now()` at both insert and assert (no injected clock) [pulse_coach/test/core/database/data_persistence_test.dart:217-313] — deferred, low flakiness risk given generous margins; full fix needs clock injection

## Dev Notes

### What This Story Is and Is Not

This is **purely a test story** — no production code changes. The entire deliverable is a single new test file:
- `pulse_coach/test/core/database/data_persistence_test.dart`

No DAOs, tables, blocs, or migration code are modified. `schemaVersion` stays at `8`.

### What Is Already Tested (Do NOT Duplicate)

The existing `test/core/database/app_database_test.dart` already covers these migration paths:
- v1→v2 (disclaimerAccepted)
- v3→v4 (is_completed)
- v4→v6 (session_logs creation)
- v3→v6 composite
- v6→v7 (abandon columns)
- v3→v7 composite
- v7→v8 (session_log_id on rpe_feedback)
- v3→v8 composite

The existing weather/exercise repository tests already cover TTL repository logic:
- `4.2-UNIT-001` in `weather_repository_impl_test.dart`: fresh cache < 1h → served from cache
- `4.2-UNIT-002`: stale > 1h → network fetch triggered
- `6.1-UNIT-007` in `exercise_repository_impl_test.dart`: fresh cache → served from cache
- `6.1-UNIT-008`: stale → network fetch triggered

**Do NOT duplicate these.** Story 13.3 AC3 tests prove `cachedAt` column stores timestamps correctly at the DAO level — a complementary (not redundant) proof.

### AC1 — File-Backed DB Pattern

The `AppDatabase.forTesting(executor)` constructor (defined at `lib/core/database/app_database.dart:AppDatabase.forTesting`) accepts any `QueryExecutor`, including a file-backed `NativeDatabase(File)`. The file-backed variant is necessary for AC1 because `NativeDatabase.memory()` does not survive `close()`.

```dart
import 'dart:io';
import 'package:drift/native.dart';

AppDatabase _openFileDb(Directory dir, String name) =>
    AppDatabase.forTesting(NativeDatabase(File('${dir.path}/$name.db')));
```

Pattern for each AC1 test:
1. `setUp` creates a temp dir: `tempDir = await Directory.systemTemp.createTemp('pulse_coach_persist_test_');`
2. `tearDown` cleans up: `await tempDir.delete(recursive: true);`
3. Each test opens `db1`, writes data, calls `await db1.close()`, opens `db2` on the same file path, reads back, calls `await db2.close()`.

**SessionLog FK constraint:** `session_logs.daily_plan_id` has an FK to `daily_plans.id` enforced by `PRAGMA foreign_keys = ON` (set in `AppDatabase.migration.beforeOpen`). Test 13.3-PERSIST-002 must therefore write a `DailyPlan` row first and use its returned autoincrement id as `dailyPlanId`.

### AC2 — v1 Schema Construction

The v1 schema includes all tables that were part of the original `onCreate` and have never been altered by any migration. Session_logs was NOT in v1 (added in v4→v5/v6), so omit it.

```dart
import 'package:sqlite3/sqlite3.dart';

final raw = sqlite3.openInMemory();
raw.execute('''CREATE TABLE IF NOT EXISTS sessions (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  session_type TEXT NOT NULL,
  intensity INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL,
  abandoned INTEGER NOT NULL DEFAULT 0,
  completed_at INTEGER,
  created_at INTEGER NOT NULL
)''');
raw.execute('''CREATE TABLE IF NOT EXISTS daily_plans (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  plan_date TEXT NOT NULL UNIQUE,
  plan_json TEXT NOT NULL,
  generated_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)''');
raw.execute('''CREATE TABLE IF NOT EXISTS user_profile (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  fitness_goal TEXT,
  weekly_session_target INTEGER NOT NULL DEFAULT 3,
  intensity_preference TEXT,
  environment_preference TEXT,
  onboarding_completed INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
raw.execute('''CREATE TABLE IF NOT EXISTS rpe_feedback (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  rpe_value INTEGER NOT NULL,
  recorded_at INTEGER NOT NULL
)''');
raw.execute('''CREATE TABLE IF NOT EXISTS bandit_state (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  arm_weights_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL
)''');
raw.execute('''CREATE TABLE IF NOT EXISTS behavioral_state (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  current_state TEXT NOT NULL,
  resting_hr INTEGER,
  step_count INTEGER,
  streak_count INTEGER NOT NULL DEFAULT 0,
  recorded_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
raw.execute('''CREATE TABLE IF NOT EXISTS weather_cache (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  temperature REAL NOT NULL,
  precipitation_probability REAL NOT NULL,
  aqi_value INTEGER NOT NULL,
  cached_at INTEGER NOT NULL
)''');
raw.execute('''CREATE TABLE IF NOT EXISTS exercise_cache (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  exercise_id TEXT NOT NULL UNIQUE,
  exercise_json TEXT NOT NULL,
  cached_at INTEGER NOT NULL
)''');
raw.execute('''CREATE TABLE IF NOT EXISTS sync_queue (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  event_type TEXT NOT NULL,
  payload TEXT NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0,
  next_retry_at INTEGER,
  created_at INTEGER NOT NULL
)''');
raw.execute('PRAGMA user_version = 1');
```

Then seed rows for sessions, bandit_state, and rpe_feedback, open `AppDatabase.forTesting(NativeDatabase.opened(raw))`, and assert:
- `sessionsDao.getAllSessions()` — list is non-empty with the expected sessionType
- `banditStateDao.getLatestState()` — non-null with expected armWeightsJson
- `rpeFeedbackDao.getAllFeedback()` — non-empty, `sessionLogId` is null (pre-v8 rows backfilled to null)

Note: The `rpe_feedback` v8 guard in `AppDatabase.migration` handles this exact path — table exists without `session_log_id` → `addColumn` is called. The existing `9.1-DB-002` test verifies this for a simpler (v7→v8) path; `13.3-PERSIST-006` extends it to the full v1→v8 path and verifies additional tables (sessions, bandit_state).

### AC3 — TTL DAO-Level Tests

These use `NativeDatabase.memory()` (not file-backed). They prove the `cachedAt` column accurately stores and retrieves `DateTime` values so the repository layer's TTL arithmetic (`now - cachedAt < threshold`) operates on correct data.

TTL thresholds (from `project-context.md` and repository implementations):
- Weather: `1 hour` (`WeatherRepositoryImpl._isCacheValid` at `lib/features/weather/data/repositories/weather_repository_impl.dart`)
- Exercise: `24 hours` (`ExerciseRepositoryImpl._isCacheValid` at `lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart`)

```dart
test('13.3-PERSIST-007: weather cachedAt within TTL', () async {
  final cachedAt = DateTime.now().toUtc().subtract(const Duration(minutes: 30));
  await db.weatherCacheDao.insertOrReplace(WeatherCacheCompanion.insert(
    latitude: 45.0, longitude: 9.0,
    temperature: 20.0, precipitationProbability: 0.1,
    aqiValue: 30, cachedAt: cachedAt,
  ));
  final row = await db.weatherCacheDao.getLatestCache();
  expect(row, isNotNull);
  final age = DateTime.now().toUtc().difference(row!.cachedAt.toUtc());
  expect(age < const Duration(hours: 1), isTrue,
      reason: 'cachedAt 30min ago must be within 1h TTL');
});
```

Pattern is identical for PERSIST-008 (2h ago, expect false), PERSIST-009 (12h, exercise, expect true), PERSIST-010 (26h, exercise, expect false).

### Imports Required

```dart
import 'dart:io';                                          // for Directory, File
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';                        // NativeDatabase
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';                     // for v1 schema raw construction
```

### Current Test Baseline

As of Story 13.2 done (2026-06-04): `flutter test` passes with **799/799** tests. All 10 new tests must pass and the total must be ≥ 809.

### Project Structure Notes

New file:
- `pulse_coach/test/core/database/data_persistence_test.dart` — NEW

No changes to:
- Any production files
- `app_database.dart` (no migration change, schemaVersion stays 8)
- Any existing DAO, table, or feature code
- `sprint-status.yaml` (updated by create-story workflow)

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md` §Epic 13, Story 13.3
- NFR15 (force-close): `_bmad-output/planning-artifacts/prd.md` line ~649
- NFR16 (migration): `_bmad-output/planning-artifacts/prd.md` line ~650
- NFR14 (TTL): `_bmad-output/planning-artifacts/prd.md` line ~648
- AppDatabase + migration: `pulse_coach/lib/core/database/app_database.dart` (schemaVersion = 8)
- Existing migration tests (do not duplicate): `pulse_coach/test/core/database/app_database_test.dart`
- Weather TTL logic: `pulse_coach/lib/features/weather/data/repositories/weather_repository_impl.dart` (`_isCacheValid`, `< Duration(hours: 1)`)
- Exercise TTL logic: `pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart` (`_isCacheValid`, `< Duration(hours: 24)`)
- WeatherCacheDao: `pulse_coach/lib/core/database/daos/weather_cache_dao.dart`
- ExerciseCacheDao: `pulse_coach/lib/core/database/daos/exercise_cache_dao.dart`
- BanditStateDao: `pulse_coach/lib/core/database/daos/bandit_state_dao.dart`
- BehavioralStateDao: `pulse_coach/lib/core/database/daos/behavioral_state_dao.dart`
- SessionLogsDao: `pulse_coach/lib/core/database/daos/session_logs_dao.dart`
- RpeFeedbackDao: `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart`
- DailyPlansDao: `pulse_coach/lib/core/database/daos/daily_plans_dao.dart`
- SessionsDao: `pulse_coach/lib/core/database/daos/sessions_dao.dart`
- Previous story (13.2): `_bmad-output/implementation-artifacts/13-2-deferred-sync-queue.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story context engine, 2026-06-04)

### Debug Log References

- 2026-06-04: Added `pulse_coach/test/core/database/data_persistence_test.dart` with all 10 required persistence, migration, and TTL timestamp tests.
- 2026-06-04: Ran targeted `flutter test test/core/database/data_persistence_test.dart` — 10/10 passed.
- 2026-06-04: Ran full `flutter test` from `pulse_coach/` — 809/809 passed.
- 2026-06-04: Ran `flutter analyze` from `pulse_coach/` — no issues found.

### Implementation Plan

- Implement Story 13.3 as a test-only story, preserving production database code and `schemaVersion = 8`.
- Use file-backed Drift databases for force-close persistence coverage, raw sqlite v1 schema construction for full migration coverage, and in-memory Drift databases for DAO-level TTL timestamp integrity checks.

### Completion Notes List

- Added file-backed persistence tests proving `daily_plans`, `session_logs`, `bandit_state`, `behavioral_state`, and `rpe_feedback` survive close/reopen on the same SQLite file.
- Added a v1→v8 composite migration test proving seeded `sessions`, `bandit_state`, and legacy `rpe_feedback` remain readable after migration, with `sessionLogId` backfilled to null.
- Added DAO-level weather/exercise cache timestamp tests for within/outside TTL thresholds without duplicating repository refresh behavior tests.
- No production files were changed.

### File List

- `pulse_coach/test/core/database/data_persistence_test.dart`

### Change Log

- 2026-06-04: Added Story 13.3 data persistence guarantee tests and validated with full test suite plus analyzer.
