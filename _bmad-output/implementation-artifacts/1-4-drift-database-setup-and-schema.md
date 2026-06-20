# Story 1.4: Drift Database Setup & Schema

Status: done

## Story

As a developer,
I want all Drift database tables, DAOs, and the initial migration schema defined,
so that all features can persist and retrieve data from a structured local database.

## Acceptance Criteria

1. **Given** the database file exists at `lib/core/database/app_database.dart`
   **When** the app starts
   **Then** a SQLite database is created with all 9 tables: `sessions`, `daily_plans`, `user_profile`, `rpe_feedback`, `bandit_state`, `behavioral_state`, `weather_cache`, `exercise_cache`, `sync_queue`

2. **Given** each table is defined with a Drift `@DataClassName` annotation
   **When** `build_runner` generates `app_database.g.dart`
   **Then** all table classes, companion classes, and DAO implementations are generated without errors

3. **Given** the database exists with schema version 1
   **When** a future migration adds a column (simulated in test)
   **Then** the `onUpgrade` callback applies the migration without data loss

4. **Given** the database is open
   **When** the app is force-closed and re-launched
   **Then** all previously persisted data is accessible and intact (NFR15)

## Tasks / Subtasks

- [x] Task 1: Implement the 9 table files in `lib/core/database/tables/` (AC: #1, #2)
  - [x] `sessions_table.dart` — Session history
  - [x] `daily_plans_table.dart` — AI daily plans
  - [x] `user_profile_table.dart` — User profile and goals
  - [x] `rpe_feedback_table.dart` — RPE feedback entries
  - [x] `bandit_state_table.dart` — Bandit arm weights
  - [x] `behavioral_state_table.dart` — Behavioral state machine state
  - [x] `weather_cache_table.dart` — Open-Meteo cache with TTL
  - [x] `exercise_cache_table.dart` — ExerciseDB cache with TTL
  - [x] `sync_queue_table.dart` — Deferred sync queue

- [x] Task 2: Implement the 9 DAO files in `lib/core/database/daos/` (AC: #1, #2)
  - [x] `sessions_dao.dart`
  - [x] `daily_plans_dao.dart`
  - [x] `user_profile_dao.dart`
  - [x] `rpe_feedback_dao.dart`
  - [x] `bandit_state_dao.dart`
  - [x] `behavioral_state_dao.dart`
  - [x] `weather_cache_dao.dart`
  - [x] `exercise_cache_dao.dart`
  - [x] `sync_queue_dao.dart`

- [x] Task 3: Implement `AppDatabase` in `lib/core/database/app_database.dart` (AC: #1, #2, #3)
  - [x] Replace the existing stub file with the full `@DriftDatabase` implementation
  - [x] Register all 9 tables and 9 DAOs
  - [x] Set `schemaVersion => 1`
  - [x] Define `MigrationStrategy` with `onCreate` and `onUpgrade`
  - [x] Annotate with `@singleton` for DI
  - [x] Add `AppDatabase.forTesting(QueryExecutor)` constructor for tests

- [x] Task 4: Run code generation (AC: #2)
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`
  - [x] Verify `lib/core/database/app_database.g.dart` is generated without errors
  - [x] Commit `app_database.g.dart` to git (generated files are committed per project rule)

- [x] Task 5: Write database tests (AC: #1, #3, #4)
  - [x] Create `test/core/database/app_database_test.dart`
  - [x] Test all 9 tables via insert + select using in-memory DB
  - [x] Test `onUpgrade` callback is defined and structured correctly
  - [x] Verify existing tests still pass: `flutter test` → 14/14 (3 preexisting + 11 new)

- [x] Task 6: Verify CI compatibility
  - [x] `flutter analyze` → 0 issues
  - [x] `flutter test` → all tests pass

## Dev Notes

### Critical: AppDatabase File Location

The stub already exists at `pulse_coach/lib/core/database/app_database.dart` with only a comment. **Replace the entire contents** of this file — do not create a new file.

### Critical: Drift 2.32.0 API Patterns

**Package versions in effect (from pubspec.yaml):**
- `drift: ^2.32.0`
- `drift_flutter: ^0.3.0`
- `drift_dev: ^2.32.0`

**AppDatabase structure (exact pattern):**

```dart
// lib/core/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/daos/sessions_dao.dart';
// ... all other dao imports
import 'package:pulse_coach/core/database/tables/sessions_table.dart';
// ... all other table imports

part 'app_database.g.dart';

@singleton
@DriftDatabase(
  tables: [
    Sessions,
    DailyPlans,
    UserProfile,
    RpeFeedback,
    BanditState,
    BehavioralState,
    WeatherCache,
    ExerciseCache,
    SyncQueue,
  ],
  daos: [
    SessionsDao,
    DailyPlansDao,
    UserProfileDao,
    RpeFeedbackDao,
    BanditStateDao,
    BehavioralStateDao,
    WeatherCacheDao,
    ExerciseCacheDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'pulse_coach_db'));

  /// Named constructor for unit tests — uses in-memory SQLite
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Stepwise migrations — add here as schemaVersion increments:
      // if (from < 2) { await m.addColumn(sessions, sessions.newColumn); }
    },
  );
}
```

**Critical points:**
- `driftDatabase(name: 'pulse_coach_db')` — from `drift_flutter`, creates the SQLite file in the app's database directory. Do NOT use `NativeDatabase.createInBackground` directly.
- `part 'app_database.g.dart';` — must be present; build_runner generates this file.
- `@singleton` **above** `@DriftDatabase` — injectable annotation, not below.
- `forTesting` constructor uses the provided executor (call with `NativeDatabase.memory()` in tests).

### Critical: Table Definitions (Exact Schema)

Each table file lives in `lib/core/database/tables/`. Use `package:` imports only. **No relative imports.**

**Naming conventions (ARCH):**
- Dart class: PascalCase (`Sessions`) → SQL table: snake_case (`sessions`)
- Dart column: camelCase (`sessionType`) → SQL column: snake_case (`session_type`)
- Data class: use `@DataClassName` when name differs from singular of table class

---

**`sessions_table.dart`**
```dart
import 'package:drift/drift.dart';

@DataClassName('Session')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionType => text()();          // 'mobility' | 'cardio' | 'breathing'
  IntColumn get intensity => integer()();           // 1–10
  IntColumn get durationSeconds => integer()();
  BoolColumn get abandoned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
```

**`daily_plans_table.dart`**
```dart
import 'package:drift/drift.dart';

@DataClassName('DailyPlan')
class DailyPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get planDate => text()();              // 'YYYY-MM-DD'
  TextColumn get planJson => text()();              // serialized plan data
  DateTimeColumn get generatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}
```

**`user_profile_table.dart`**
```dart
import 'package:drift/drift.dart';

@DataClassName('UserProfileData')
class UserProfile extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fitnessGoal => text().nullable()();
  IntColumn get weeklySessionTarget => integer().withDefault(const Constant(3))();
  TextColumn get intensityPreference => text().nullable()(); // 'low' | 'medium' | 'high'
  TextColumn get environmentPreference => text().nullable()(); // 'indoor' | 'outdoor' | 'any'
  BoolColumn get onboardingCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

**`rpe_feedback_table.dart`**
```dart
import 'package:drift/drift.dart';

@DataClassName('RpeFeedback')
class RpeFeedback extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()();           // FK to sessions.id (logical, no constraint)
  IntColumn get rpeValue => integer()();            // 1–10
  DateTimeColumn get recordedAt => dateTime()();
}
```

**`bandit_state_table.dart`**
```dart
import 'package:drift/drift.dart';

@DataClassName('BanditStateData')
class BanditState extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get armWeightsJson => text()();        // JSON: {"mobility_low": 1.0, ...}
  DateTimeColumn get updatedAt => dateTime()();
}
```

**`behavioral_state_table.dart`**
```dart
import 'package:drift/drift.dart';

@DataClassName('BehavioralStateData')
class BehavioralState extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get currentState => text()();          // 'Active' | 'Recovering' | 'AtRisk' | 'Fatigued'
  IntColumn get restingHr => integer().nullable()();
  IntColumn get stepCount => integer().nullable()();
  IntColumn get streakCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

**`weather_cache_table.dart`**
```dart
import 'package:drift/drift.dart';

@DataClassName('WeatherCacheData')
class WeatherCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get temperature => real()();
  RealColumn get precipitationProbability => real()();
  IntColumn get aqiValue => integer()();
  DateTimeColumn get cachedAt => dateTime()();      // TTL check: now - cachedAt < 1 hour
}
```

**`exercise_cache_table.dart`**
```dart
import 'package:drift/drift.dart';

@DataClassName('ExerciseCacheData')
class ExerciseCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get exerciseId => text()();
  TextColumn get exerciseJson => text()();          // full exercise payload as JSON
  DateTimeColumn get cachedAt => dateTime()();      // TTL check: now - cachedAt < 24 hours
}
```

**`sync_queue_table.dart`**
```dart
import 'package:drift/drift.dart';

@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventType => text()();
  TextColumn get payload => text()();               // JSON event payload
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
```

### Critical: DAO Structure (Drift 2.x Pattern)

Each DAO in `lib/core/database/daos/`. Annotate with `@DriftAccessor(tables: [...])`.

**Example — `sessions_dao.dart`** (follow this pattern for all DAOs):

```dart
import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/app_database.dart';

part 'sessions_dao.g.dart';

@DriftAccessor(tables: [Sessions])
class SessionsDao extends DatabaseAccessor<AppDatabase> with _$SessionsDaoMixin {
  SessionsDao(super.db);

  Future<List<Session>> getAllSessions() => select(sessions).get();

  Stream<List<Session>> watchAllSessions() => select(sessions).watch();

  Future<int> insertSession(SessionsCompanion entry) =>
      into(sessions).insert(entry);

  Future<bool> updateSession(Session session) =>
      update(sessions).replace(session);

  Future<int> deleteSession(int id) =>
      (delete(sessions)..where((t) => t.id.equals(id))).go();
}
```

**Key DAO patterns:**
- `part '{name}_dao.g.dart';` — one generated file per DAO
- `with _$SessionsDaoMixin` — generated mixin, name follows `_$` + DAO class name + `Mixin`
- Insert uses `SessionsCompanion` (generated companion class), not `Session` directly
- `Companion` has `Value<T>` fields; use `Value(x)` for set, `Value.absent()` for omitted

**Minimum queries per DAO for Story 1.4:**

| DAO | Required Methods |
|---|---|
| `SessionsDao` | `getAllSessions()`, `watchAllSessions()`, `insertSession()`, `updateSession()`, `deleteSession()` |
| `DailyPlansDao` | `getPlanForDate(String date)`, `insertPlan()`, `deletePlan()` |
| `UserProfileDao` | `getProfile()`, `insertProfile()`, `updateProfile()` |
| `RpeFeedbackDao` | `getAllFeedback()`, `insertFeedback()`, `getLastN(int n)` |
| `BanditStateDao` | `getLatestState()`, `insertState()`, `updateState()` |
| `BehavioralStateDao` | `getLatestState()`, `insertState()` |
| `WeatherCacheDao` | `getLatestCache()`, `insertOrReplace()`, `deleteAll()` |
| `ExerciseCacheDao` | `getByExerciseId(String id)`, `insertOrReplace()`, `deleteAll()` |
| `SyncQueueDao` | `getPendingEntries()`, `insertEntry()`, `updateEntry()`, `deleteEntry(int id)` |

### Critical: DI Registration via @singleton

`AppDatabase` must be annotated `@singleton`. After running `build_runner`:
1. `injection.config.dart` is **automatically** updated to register `AppDatabase` as a singleton.
2. **No manual `getIt.registerSingleton(AppDatabase())` call** — annotations only (Story 1.3 rule).
3. Registration order: `AppDatabase` initializes before DAOs. DAOs receive `AppDatabase` via constructor injection if annotated (Story 1.4 does not need to annotate DAOs — they are accessed via `db.sessionsDao` getters, not via getIt directly).

### Critical: DateTimeColumn Behavior

- Drift stores `DateTimeColumn` as **integer (Unix timestamp in seconds)** in SQLite by default.
- Dart code uses `DateTime` natively — Drift handles conversion automatically.
- Always pass `DateTime.now()` or `DateTime.utc(...)` — do NOT convert to int manually.
- Drift 2.x default: `dateTime()` stores as seconds since epoch. No configuration needed.

### Critical: Code Generation Command

Run from `pulse_coach/` directory (where `pubspec.yaml` lives):

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `lib/core/database/app_database.g.dart` — the `_$AppDatabase` base class
- `lib/core/database/daos/sessions_dao.g.dart` — one per DAO (9 files)
- Updated `lib/core/di/injection.config.dart` — adds AppDatabase singleton

**All generated files must be committed to git** (Story 1.1 + 1.2 rule). Generated files: `.g.dart`, `injection.config.dart`.

### Testing Requirements

**New test file:** `test/core/database/app_database_test.dart`

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase - table smoke tests', () {
    test('sessions table: insert and retrieve', () async {
      await db.sessionsDao.insertSession(
        SessionsCompanion.insert(
          sessionType: 'cardio',
          intensity: 5,
          durationSeconds: 300,
          createdAt: DateTime.now(),
        ),
      );
      final all = await db.sessionsDao.getAllSessions();
      expect(all.length, 1);
      expect(all.first.sessionType, 'cardio');
    });

    test('user_profile table: insert and retrieve', () async {
      await db.userProfileDao.insertProfile(
        UserProfileCompanion.insert(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final profile = await db.userProfileDao.getProfile();
      expect(profile, isNotNull);
    });

    // Add similar smoke tests for remaining 7 tables...
  });

  group('AppDatabase - migration strategy', () {
    test('onUpgrade callback is defined', () {
      expect(db.migration.onUpgrade, isNotNull);
    });

    test('schemaVersion is 1', () {
      expect(db.schemaVersion, 1);
    });
  });
}
```

**Test path mirrors lib/ path:** `lib/core/database/app_database.dart` → `test/core/database/app_database_test.dart`

**Existing tests must still pass:** 3 tests (2 DI + 1 smoke).

### File Locations

| File | Action |
|---|---|
| `pulse_coach/lib/core/database/app_database.dart` | MODIFY — replace stub with full implementation |
| `pulse_coach/lib/core/database/app_database.g.dart` | GENERATE via build_runner, then COMMIT |
| `pulse_coach/lib/core/database/tables/sessions_table.dart` | CREATE |
| `pulse_coach/lib/core/database/tables/daily_plans_table.dart` | CREATE |
| `pulse_coach/lib/core/database/tables/user_profile_table.dart` | CREATE |
| `pulse_coach/lib/core/database/tables/rpe_feedback_table.dart` | CREATE |
| `pulse_coach/lib/core/database/tables/bandit_state_table.dart` | CREATE |
| `pulse_coach/lib/core/database/tables/behavioral_state_table.dart` | CREATE |
| `pulse_coach/lib/core/database/tables/weather_cache_table.dart` | CREATE |
| `pulse_coach/lib/core/database/tables/exercise_cache_table.dart` | CREATE |
| `pulse_coach/lib/core/database/tables/sync_queue_table.dart` | CREATE |
| `pulse_coach/lib/core/database/daos/sessions_dao.dart` | CREATE |
| `pulse_coach/lib/core/database/daos/daily_plans_dao.dart` | CREATE |
| `pulse_coach/lib/core/database/daos/user_profile_dao.dart` | CREATE |
| `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart` | CREATE |
| `pulse_coach/lib/core/database/daos/bandit_state_dao.dart` | CREATE |
| `pulse_coach/lib/core/database/daos/behavioral_state_dao.dart` | CREATE |
| `pulse_coach/lib/core/database/daos/weather_cache_dao.dart` | CREATE |
| `pulse_coach/lib/core/database/daos/exercise_cache_dao.dart` | CREATE |
| `pulse_coach/lib/core/database/daos/sync_queue_dao.dart` | CREATE |
| `pulse_coach/lib/core/di/injection.config.dart` | AUTO-UPDATED by build_runner (commit result) |
| `pulse_coach/test/core/database/app_database_test.dart` | CREATE |

**Do NOT touch:** `main.dart`, `injection.dart`, any feature files. This story is infrastructure only.

### Anti-Patterns to Avoid

| ❌ Do NOT | ✅ Do Instead |
|---|---|
| `NativeDatabase.createInBackground(File(...))` directly | `driftDatabase(name: 'pulse_coach_db')` from drift_flutter |
| Relative imports (`../tables/sessions_table.dart`) | `package:pulse_coach/core/database/tables/sessions_table.dart` |
| Insert `Session` directly | Insert `SessionsCompanion` (generated companion class) |
| Define foreign key constraints in Drift | Use logical FK (integer column), no DB-level constraint in v1 |
| `getIt.registerSingleton(AppDatabase())` | `@singleton class AppDatabase` annotation |
| Gitignore `.g.dart` files | Commit all generated files |
| Store DateTime as String | Use `DateTimeColumn` — Drift handles conversion |
| Create `AppDatabase` in tests with `driftDatabase()` | Use `AppDatabase.forTesting(NativeDatabase.memory())` |
| Skip `part` directive in DAO files | Each DAO file needs `part '{name}_dao.g.dart';` |

### Architecture Compliance

- **ARCH3:** Drift with stepwise `onUpgrade` — enforced via `MigrationStrategy` ✅
- **ARCH2:** AppDatabase registered via `@singleton` annotation — no manual `getIt` calls ✅
- **ARCH, NFR15-16:** Data survives force-close because `driftDatabase()` persists to the app's database directory ✅
- **ARCH, API Caching:** `cachedAt` timestamp column present on `weather_cache` and `exercise_cache` tables ✅
- **ARCH, Drift Naming:** Tables PascalCase → SQL snake_case; columns camelCase → SQL snake_case ✅
- **ARCH, Timestamps:** `createdAt`, `updatedAt`, `cachedAt` follow standard naming ✅

### Previous Story Intelligence (Story 1.3)

- `AppDatabase` must use `@singleton` (not `@injectable` or `@lazySingleton`) — Story 1.3 explicitly documented this for Story 1.4
- DI annotation order: `@singleton` annotation goes on the class; `@DriftDatabase(...)` also annotates the same class — both annotations are valid on the same class
- `injection.config.dart` is auto-generated by build_runner — after this story it will include `AppDatabase` registration. Commit the updated file.
- `flutter analyze` must report 0 issues — this was passing after Story 1.3 and must still pass after Story 1.4
- `package:` imports only — no relative `../` imports (Story 1.1 rule, enforced in Story 1.3)

### Known Dependency Notes

- `sqlite3_flutter_libs` (transitive dep of `drift_flutter`) resolved to an EOL-tagged version — this is a known issue from Story 1.2 code review. Do NOT attempt to change this; monitor for drift updates. Current behavior is correct.
- `dartz: ^0.10.1` — unmaintained; potential successor is `fpdart`. Not relevant to this story, but noted for context.

### References

- [Source: epics.md#Story 1.4] — User story statement and acceptance criteria
- [Source: architecture.md#Data Architecture] — Drift `~2.32.x`, stepwise migrations, `cachedAt` TTL pattern
- [Source: architecture.md#Drift Database Naming] — Table/column/DAO naming conventions
- [Source: architecture.md#Complete Project Directory Structure] — `lib/core/database/` layout with all 9 table and DAO files
- [Source: architecture.md#Enforcement Guidelines] — Rule #5: no manual getIt calls; Rule #7: all API cache in drift with `cachedAt`
- [Source: architecture.md#Implementation Patterns] — `DateTimeColumn` stores as integer timestamp
- [Source: story 1-3#Dev Notes#DI Annotation Reference] — `@singleton` for AppDatabase; registration order
- [Source: story 1-3#Architecture Compliance] — `@singleton for AppDatabase (Story 1.4 will use this pattern)`
- [Source: deferred-work.md] — `sqlite3_flutter_libs` EOL note; do not change
- [Source: architecture.md#Commands] — `dart run build_runner build --delete-conflicting-outputs`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed `@DataClassName('RpeFeedback')` → `@DataClassName('RpeFeedbackData')` in `rpe_feedback_table.dart` to avoid name collision between table class `RpeFeedback` and the generated data class.
- DAOs require direct table imports (in addition to `app_database.dart`) for `@DriftAccessor` resolution in Drift 2.x code generation.
- `injection_test.dart` updated to mock `path_provider` channel required by `driftDatabase()` in test environment.
- Used `super.executor` super-parameter syntax in `AppDatabase.forTesting` to satisfy `use_super_parameters` lint rule.

### Completion Notes List

- Implemented all 9 Drift table files with correct schema, `@DataClassName` annotations, and `DateTimeColumn` types.
- Implemented all 9 DAO files with required query methods per story spec; each DAO directly imports its table file for `@DriftAccessor` resolution.
- `AppDatabase` fully implemented with `@singleton`, all 9 tables + DAOs, `schemaVersion = 1`, stepwise `MigrationStrategy`, and `forTesting` constructor.
- Code generation via `dart run build_runner build --delete-conflicting-outputs` completed successfully; `app_database.g.dart` and 9 `*_dao.g.dart` files generated.
- `injection.config.dart` auto-updated to register `AppDatabase` as singleton.
- 11 new smoke + migration tests added; all 14 tests pass (11 new + 3 preexisting).
- `flutter analyze` → 0 issues.

### File List

- `pulse_coach/lib/core/database/app_database.dart` — MODIFIED (full implementation replacing stub)
- `pulse_coach/lib/core/database/app_database.g.dart` — GENERATED by build_runner
- `pulse_coach/lib/core/database/tables/sessions_table.dart` — CREATED
- `pulse_coach/lib/core/database/tables/daily_plans_table.dart` — CREATED
- `pulse_coach/lib/core/database/tables/user_profile_table.dart` — CREATED
- `pulse_coach/lib/core/database/tables/rpe_feedback_table.dart` — CREATED
- `pulse_coach/lib/core/database/tables/bandit_state_table.dart` — CREATED
- `pulse_coach/lib/core/database/tables/behavioral_state_table.dart` — CREATED
- `pulse_coach/lib/core/database/tables/weather_cache_table.dart` — CREATED
- `pulse_coach/lib/core/database/tables/exercise_cache_table.dart` — CREATED
- `pulse_coach/lib/core/database/tables/sync_queue_table.dart` — CREATED
- `pulse_coach/lib/core/database/daos/sessions_dao.dart` — CREATED
- `pulse_coach/lib/core/database/daos/sessions_dao.g.dart` — GENERATED
- `pulse_coach/lib/core/database/daos/daily_plans_dao.dart` — CREATED
- `pulse_coach/lib/core/database/daos/daily_plans_dao.g.dart` — GENERATED
- `pulse_coach/lib/core/database/daos/user_profile_dao.dart` — CREATED
- `pulse_coach/lib/core/database/daos/user_profile_dao.g.dart` — GENERATED
- `pulse_coach/lib/core/database/daos/rpe_feedback_dao.dart` — CREATED
- `pulse_coach/lib/core/database/daos/rpe_feedback_dao.g.dart` — GENERATED
- `pulse_coach/lib/core/database/daos/bandit_state_dao.dart` — CREATED
- `pulse_coach/lib/core/database/daos/bandit_state_dao.g.dart` — GENERATED
- `pulse_coach/lib/core/database/daos/behavioral_state_dao.dart` — CREATED
- `pulse_coach/lib/core/database/daos/behavioral_state_dao.g.dart` — GENERATED
- `pulse_coach/lib/core/database/daos/weather_cache_dao.dart` — CREATED
- `pulse_coach/lib/core/database/daos/weather_cache_dao.g.dart` — GENERATED
- `pulse_coach/lib/core/database/daos/exercise_cache_dao.dart` — CREATED
- `pulse_coach/lib/core/database/daos/exercise_cache_dao.g.dart` — GENERATED
- `pulse_coach/lib/core/database/daos/sync_queue_dao.dart` — CREATED
- `pulse_coach/lib/core/database/daos/sync_queue_dao.g.dart` — GENERATED
- `pulse_coach/lib/core/di/injection.config.dart` — AUTO-UPDATED (AppDatabase singleton registration added)
- `pulse_coach/test/core/database/app_database_test.dart` — CREATED
- `pulse_coach/test/core/di/injection_test.dart` — MODIFIED (added path_provider mock + TestWidgetsFlutterBinding)

### Review Findings

- [x] [Review][Patch] **UserProfile: add guard in DAO** — `insertProfile()` now checks `getProfile() != null` and throws `StateError` if a profile already exists. Fixed.
- [x] [Review][Patch] **DailyPlans.planDate: add `.unique()` constraint** — Added `unique()` to `planDate` column definition. Build_runner re-run completed. Fixed.
- [x] [Review][Defer] **AC3: migration test does not simulate actual upgrade** — at schemaVersion 1, no real migration exists to test. Add a proper migration simulation test when schemaVersion is incremented. [app_database_test.dart:140-142] — deferred, becomes actionable at schemaVersion 2
- [x] [Review][Patch] **ExerciseCache.exerciseId not declared unique** — `insertOnConflictUpdate` resolves conflicts on the primary key (autoIncrement `id`), not on `exerciseId`. Two inserts with the same `exerciseId` create duplicate rows; `getByExerciseId()` then throws `StateError` via `getSingleOrNull()`. Fix: add `.unique()` to `exerciseId` column. [exercise_cache_table.dart:6, exercise_cache_dao.dart:17]
- [x] [Review][Defer] **SyncQueue.getPendingEntries() has no nextRetryAt filter** — entries scheduled for future retry are returned immediately. Future story should add `WHERE nextRetryAt IS NULL OR nextRetryAt <= now()` filter. [sync_queue_dao.dart:12-15] — deferred, future sync feature scope
- [x] [Review][Defer] **Domain value CHECK constraints missing** — `rpeValue` (1-10), `sessionType` (enum), `intensity` (1-10), `currentState` (enum), `intensityPreference` (enum), `environmentPreference` (enum) accept arbitrary values at DB level. Validation belongs at application/domain layer in v1. [multiple table files] — deferred, v1 uses logical constraints only per arch decision
- [x] [Review][Defer] **No @disposeMethod on AppDatabase for GetIt disposal** — `getIt.reset()` won't call `db.close()`. Not impactful in production (singleton for app lifetime) but relevant for test cleanup. [app_database.dart:27] — deferred, nice-to-have for test hygiene
- [x] [Review][Defer] **RpeFeedback.sessionId has no index** — queries filtering by sessionId will full-table-scan. Add index when query patterns are established. [rpe_feedback_table.dart:6] — deferred, optimize when query patterns emerge
- [x] [Review][Defer] **SyncQueue.retryCount has no upper bound** — no max retry limit at DB level. Application-level retry cap should be implemented in sync feature. [sync_queue_table.dart:8] — deferred, Epic 13 scope

## Change Log

- 2026-03-28: Story 1.4 implemented — 9 Drift tables, 9 DAOs, AppDatabase with @singleton, build_runner code generation, 11 database tests added, injection_test updated for path_provider mock. All 14 tests pass, 0 analyze issues.
