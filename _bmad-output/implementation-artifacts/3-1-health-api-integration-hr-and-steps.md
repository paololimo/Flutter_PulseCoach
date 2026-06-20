# Story 3.1: Health API Integration (HR & Steps)

Status: done

## Story

As the system,
I want to read resting heart rate and daily step count from the device Health API,
so that the AI engine can incorporate physiological signals into plan generation.

## Acceptance Criteria

1. **Given** the app requests Health API permissions (HealthKit on iOS / Health Connect on Android)
   **When** the permission prompt appears
   **Then** the prompt includes the explanation "Used to personalize your sessions. Stays on your device." (NFR9)
   — **Already satisfied by spike** (iOS Info.plist, Android Health Connect config)

2. **Given** permissions are granted
   **When** `HealthRepository.fetchHealthData()` is called
   **Then** `restingHr` (bpm, nullable) and `stepCount` (daily total, nullable) are returned as a `HealthData` domain entity

3. **Given** `HealthRepository.fetchHealthData()` succeeds
   **When** `GetHealthData` use case is called
   **Then** the result is stored in the `behavioral_state` table via `HealthRepository.saveHealthData(healthData)`, with a `recordedAt` timestamp

4. **Given** the `StateVector` is constructed for plan generation (Epic 5, Story 5.1)
   **When** `GetHealthData` use case is called
   **Then** `restingHR` and `stepCount` fields in `HealthData` are available for StateVector population (FR42) — integration deferred to Story 5.1, but `GetHealthData` use case must be injectable and testable now

5. **Given** data is fetched and stored
   **When** the storage occurs
   **Then** data is stored exclusively on-device via the `behavioral_state` drift table — no network transmission (NFR7)

6. **Given** the user denies Health API permissions
   **When** `HealthRepository.fetchHealthData()` is called
   **Then** `Left(SensorFailure('Health permissions denied'))` is returned — no crash, no error UI shown to user (ARCH9)

7. **Given** the Health API throws an exception (e.g., Health Connect unavailable, HealthKit error)
   **When** `HealthDataSource` catches the exception
   **Then** it rethrows as `SensorException` (NOT `SensorFailure` — the datasource throws exceptions, the repository catches them and returns `Left(SensorFailure(...))`)

## Tasks / Subtasks

- [x] Task 0: Confirm spike work is complete (AC: 1)
  - [x] 0.1 Verify `health: ^13.3.1` in `pubspec.yaml` ✓ (done in spike)
  - [x] 0.2 Verify iOS `NSHealthShareUsageDescription` = "Used to personalize your sessions. Stays on your device." in `ios/Runner/Info.plist` ✓
  - [x] 0.3 Verify `NSHealthUpdateUsageDescription` present in `Info.plist` ✓
  - [x] 0.4 Verify Android `READ_HEART_RATE`, `READ_STEPS`, `ACTIVITY_RECOGNITION` in `AndroidManifest.xml` ✓
  - [x] 0.5 Verify Health Connect intent filter and queries block in `AndroidManifest.xml` ✓
  - [x] **No code changes needed for Task 0** — run `flutter pub get` if needed

- [x] Task 1: Add `SensorException` to core exceptions (AC: 7)
  - [x] 1.1 Open `lib/core/error/exceptions.dart`
  - [x] 1.2 Add:
    ```dart
    class SensorException implements Exception {
      final String message;
      const SensorException(this.message);
    }
    ```
  - [x] Note: `SensorFailure` already exists in `lib/core/error/failures.dart` — do NOT recreate it

- [x] Task 2: Create `HealthData` domain entity (AC: 2)
  - [x] 2.1 Create `lib/features/session/domain/entities/health_data.dart`:
    ```dart
    class HealthData {
      final int? restingHr;
      final int? stepCount;

      const HealthData({this.restingHr, this.stepCount});

      bool get hasData => restingHr != null || stepCount != null;
    }
    ```
  - [x] **DO NOT use freezed here** — `HealthData` is a simple data carrier with no state management concerns; freezed adds build_runner overhead for no benefit at this size. Plain `const` class is sufficient.

- [x] Task 3: Create `HealthRepository` interface (AC: 2, 3, 6)
  - [x] 3.1 Create `lib/features/session/domain/repositories/health_repository.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/session/domain/entities/health_data.dart';

    abstract class HealthRepository {
      /// Requests permissions if not yet granted, then fetches HR + steps.
      /// Returns [SensorFailure] if permissions denied or Health API unavailable.
      Future<Either<Failure, HealthData>> fetchHealthData();

      /// Persists [HealthData] to [behavioral_state] table.
      Future<Either<Failure, void>> saveHealthData(HealthData data);
    }
    ```

- [x] Task 4: Create `HealthDataSource` (wraps `health` package) (AC: 2, 6, 7)
  - [x] 4.1 Create `lib/features/session/data/datasources/health_data_source.dart`:
    ```dart
    import 'package:health/health.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/exceptions.dart';
    import 'package:pulse_coach/features/session/domain/entities/health_data.dart';

    @injectable
    class HealthDataSource {
      final Health _health;
      HealthDataSource(this._health);

      static const _readTypes = [
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.STEPS,
      ];

      static const _readPermissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];

      Future<HealthData> fetchHealthData() async {
        try {
          await _health.configure();
          final granted = await _health.requestAuthorization(
            _readTypes,
            permissions: _readPermissions,
          );
          if (!granted) {
            throw const SensorException('Health permissions denied');
          }

          final now = DateTime.now();
          final yesterday = now.subtract(const Duration(days: 1));
          final midnight = DateTime(now.year, now.month, now.day);

          // Resting HR: last 24h window (iOS HealthKit only; Android returns empty)
          final hrPoints = await _health.getHealthDataFromTypes(
            startTime: yesterday,
            endTime: now,
            types: [HealthDataType.RESTING_HEART_RATE],
          );

          // Steps: today midnight → now
          final stepsPoints = await _health.getHealthDataFromTypes(
            startTime: midnight,
            endTime: now,
            types: [HealthDataType.STEPS],
          );

          final restingHr = hrPoints.isEmpty
              ? null
              : (hrPoints.last.value as NumericHealthValue).numericValue.round();

          final stepCount = stepsPoints.isEmpty
              ? null
              : stepsPoints.fold<int>(
                  0,
                  (sum, p) =>
                      sum + (p.value as NumericHealthValue).numericValue.round(),
                );

          return HealthData(restingHr: restingHr, stepCount: stepCount);
        } on SensorException {
          rethrow;
        } catch (e) {
          throw SensorException(e.toString());
        }
      }
    }
    ```
  - [x] **IMPORTANT — platform behavior:**
    - `RESTING_HEART_RATE` is **iOS-only** (HealthKit). Android returns empty list — this is expected, NOT an error.
    - `STEPS` works on both iOS and Android (Health Connect).
    - Both null fields = `HealthData(restingHr: null, stepCount: null)` → RPE-only mode, not a failure.
  - [x] **IMPORTANT — `Health` DI registration:** `Health()` is a singleton from the `health` package. Register it in DI:
    ```dart
    // In lib/core/di/injection.dart or a new module file:
    @module
    abstract class HealthModule {
      @singleton
      Health get health => Health();
    }
    ```
    Create `lib/core/di/health_module.dart` with this content.

- [x] Task 5: Create `HealthRepositoryImpl` (AC: 2, 3, 5, 6)
  - [x] 5.1 Create `lib/features/session/data/repositories/health_repository_impl.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:drift/drift.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/database/app_database.dart';
    import 'package:pulse_coach/core/error/exceptions.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/session/data/datasources/health_data_source.dart';
    import 'package:pulse_coach/features/session/domain/entities/health_data.dart';
    import 'package:pulse_coach/features/session/domain/repositories/health_repository.dart';

    @Injectable(as: HealthRepository)
    class HealthRepositoryImpl implements HealthRepository {
      final HealthDataSource _dataSource;
      final AppDatabase _db;

      HealthRepositoryImpl(this._dataSource, this._db);

      @override
      Future<Either<Failure, HealthData>> fetchHealthData() async {
        try {
          final data = await _dataSource.fetchHealthData();
          return Right(data);
        } on SensorException catch (e) {
          return Left(SensorFailure(e.message));
        } catch (e) {
          return Left(SensorFailure(e.toString()));
        }
      }

      @override
      Future<Either<Failure, void>> saveHealthData(HealthData data) async {
        try {
          await _db.behavioralStateDao.insertState(
            BehavioralStateCompanion(
              currentState: const Value('Active'), // placeholder; state machine in Epic 5
              restingHr: Value(data.restingHr),
              stepCount: Value(data.stepCount),
              recordedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
          return const Right(null);
        } catch (e) {
          return Left(CacheFailure(e.toString()));
        }
      }
    }
    ```
  - [x] **IMPORTANT — `BehavioralStateCompanion` field `currentState`:** The table has `currentState` as a non-nullable `TextColumn`. Use placeholder `'Active'` for now — the behavioral state machine (Epic 5, Story 5.2) will derive the real state. This is an acknowledged compromise to satisfy the DB constraint.
  - [x] **IMPORTANT — `BehavioralStateCompanion` field `streakCount`:** Has a DB default of `0` — omit from companion to use the default.
  - [x] Import `package:drift/drift.dart` for `Value<T>` wrapper.

- [x] Task 6: Create `GetHealthData` use case (AC: 2, 3, 4)
  - [x] 6.1 Create `lib/features/session/domain/usecases/get_health_data.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/session/domain/entities/health_data.dart';
    import 'package:pulse_coach/features/session/domain/repositories/health_repository.dart';

    /// Fetches HR + steps from Health API and persists to behavioral_state table.
    /// Returns [HealthData] on success, [SensorFailure] on permission denial or error.
    /// On failure, returns Left — caller should continue with RPE-only mode (do NOT surface error to user).
    @injectable
    class GetHealthData {
      GetHealthData(this._repository);
      final HealthRepository _repository;

      Future<Either<Failure, HealthData>> call() async {
        final result = await _repository.fetchHealthData();
        return result.fold(
          (failure) => Left(failure),
          (data) async {
            // Store to behavioral_state regardless of null fields (RPE-only mode is valid)
            await _repository.saveHealthData(data);
            return Right(data);
          },
        );
      }
    }
    ```
  - [x] **Design rationale:** `saveHealthData` is always called after a successful fetch — even if both fields are null (RPE-only). This ensures the `behavioral_state` table always has a fresh row when health was queried.

- [x] Task 7: Regenerate DI (AC: all)
  - [x] 7.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] 7.2 Verify `injection.config.dart` registers:
    - `HealthDataSource` as factory
    - `HealthRepositoryImpl` as factory for `HealthRepository`
    - `GetHealthData` as factory
    - `Health` as singleton (from `HealthModule`)
  - [x] 7.3 If `Health` singleton from `HealthModule` causes issues with `@module` abstract class, use this alternative in `injection.dart` before calling `configureDependencies()`:
    ```dart
    getIt.registerSingleton<Health>(Health());
    ```

- [x] Task 8: Write tests (AC: 2, 3, 6, 7)
  - [x] 8.1 Create `test/data/datasources/health_data_source_test.dart`:
    - `@GenerateMocks([Health])`
    - Tests:
      - `3.1-UNIT-001`: `fetchHealthData()` returns `HealthData` with parsed `restingHr` and `stepCount` when permissions granted and data available
      - `3.1-UNIT-002`: `fetchHealthData()` throws `SensorException('Health permissions denied')` when `requestAuthorization` returns false
      - `3.1-UNIT-003`: `fetchHealthData()` returns `HealthData(restingHr: null, stepCount: null)` when both data lists are empty (e.g., Android, no HR data)
      - `3.1-UNIT-004`: `fetchHealthData()` wraps unknown exceptions as `SensorException`
  - [x] 8.2 Create `test/data/repositories/health_repository_impl_test.dart`:
    - `@GenerateMocks([HealthDataSource, BehavioralStateDao])` — DAO injected directly (AppDatabase.behavioralStateDao is late final, not mockable via proxy)
    - Tests:
      - `3.1-UNIT-005`: `fetchHealthData()` returns `Right(HealthData)` when data source succeeds
      - `3.1-UNIT-006`: `fetchHealthData()` returns `Left(SensorFailure)` when data source throws `SensorException`
      - `3.1-UNIT-007`: `saveHealthData(healthData)` calls `behavioralStateDao.insertState()` with correct companion
      - `3.1-UNIT-008`: `saveHealthData(healthData)` returns `Left(CacheFailure)` when DB throws
  - [x] 8.3 Create `test/domain/usecases/get_health_data_test.dart`:
    - `@GenerateMocks([HealthRepository])`
    - Tests:
      - `3.1-UNIT-009`: `call()` fetches and then saves when fetch succeeds
      - `3.1-UNIT-010`: `call()` returns `Left(SensorFailure)` without calling save when fetch fails
  - [x] 8.4 Run `dart run build_runner build --delete-conflicting-outputs` to generate mocks
  - [x] 8.5 Run `flutter test` — target **~132 tests** (+10 from 122 baseline) — **132 tests PASS ✅**

## Dev Notes

### What the Spike Already Did

The Epic 3 health spike (commits `6e3793f` and `c6ffc97`) completed all platform configuration:

| Platform | What's Done |
|---|---|
| iOS `Info.plist` | `NSHealthShareUsageDescription` = "Used to personalize your sessions. Stays on your device." |
| iOS `Info.plist` | `NSHealthUpdateUsageDescription` present |
| iOS `Runner.entitlements` | HealthKit entitlement removed (was causing conflict — confirmed by spike) |
| Android `AndroidManifest.xml` | `READ_HEART_RATE`, `READ_STEPS`, `ACTIVITY_RECOGNITION` permissions |
| Android `AndroidManifest.xml` | Health Connect intent filter + queries block |
| `pubspec.yaml` | `health: ^13.3.1`, `sensors_plus: ^6.1.0` |

**Do NOT modify any platform files** — all permissions are already in place.

### Health Package 13.x API

Package: `health: ^13.3.1` (already in pubspec.lock)

```dart
// Key API surface used in this story:
Health health = Health();
await health.configure();                          // Call once before use
bool granted = await health.requestAuthorization(
  [HealthDataType.RESTING_HEART_RATE, HealthDataType.STEPS],
  permissions: [HealthDataAccess.READ, HealthDataAccess.READ],
);
List<HealthDataPoint> points = await health.getHealthDataFromTypes(
  startTime: start,
  endTime: end,
  types: [HealthDataType.RESTING_HEART_RATE],
);
// Extract value:
int bpm = (point.value as NumericHealthValue).numericValue.round();
```

**Platform-specific behavior:**
- `RESTING_HEART_RATE` → **iOS only**. On Android, `getHealthDataFromTypes` returns `[]`. Not an error.
- `STEPS` → Both iOS and Android (Health Connect on Android 14+). On older Android without Health Connect, returns `[]`.
- `requestAuthorization` returns `false` if user denies → `SensorException` → `SensorFailure` → RPE-only mode.

### Feature Location Decision

Files go under `lib/features/session/` per architecture spec:
> `lib/features/session/data/datasources/sensor_data_source.dart`

Health is sensor data. Story 3.2 (accelerometer) also lives here as `SensorRepository`. This avoids creating a separate `health` or `sensor` feature.

### Existing DB Schema — Already Compatible

`lib/core/database/tables/behavioral_state_table.dart`:
```dart
IntColumn get restingHr => integer().nullable()();
IntColumn get stepCount => integer().nullable()();
DateTimeColumn get recordedAt => dateTime()();
DateTimeColumn get updatedAt => dateTime()();
```

`lib/core/database/daos/behavioral_state_dao.dart`:
```dart
Future<int> insertState(BehavioralStateCompanion entry) => into(behavioralState).insert(entry);
Future<BehavioralStateData?> getLatestState() => ...;  // used in Story 5.x
```

**No schema migration needed** — the table already has `restingHr` and `stepCount` columns.

### Failure/Exception Layering (Architecture Rule)

| Layer | Uses |
|---|---|
| `HealthDataSource` | Throws `SensorException` (new in Task 1) |
| `HealthRepositoryImpl` | Catches `SensorException`, returns `Left(SensorFailure(...))` |
| `GetHealthData` use case | Passes `Either` through |
| Bloc (future Epic 5) | Pattern-matches `Either`, emits state |
| UI | Never sees exceptions — graceful degradation only |

`SensorFailure` already exists in `lib/core/error/failures.dart` — do NOT recreate.

### StateVector Integration (AC4) — Deferred to Story 5.1

`lib/ai/bandit/state_vector.dart` does not exist yet (Epic 5). AC4 is satisfied when Story 5.1 creates `StateVector` with `restingHR: int?` and `stepCount: int?` fields, and calls `GetHealthData` from the `DailyPlanBloc`. 

**For this story:** Ensure `GetHealthData` is `@injectable` and returns `Either<Failure, HealthData>` — this is the contract Story 5.1 depends on.

### `Health` DI Registration

`Health()` (from `package:health/health.dart`) needs to be a singleton in the DI container. Since it's an external type without `@injectable`, use a `@module`:

```dart
// lib/core/di/health_module.dart
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';

@module
abstract class HealthModule {
  @singleton
  Health get health => Health();
}
```

This follows the same pattern that would be used for `Dio`, `AppDatabase`, etc.

### Graceful Degradation — Never Show Error UI

When `GetHealthData` returns `Left(SensorFailure)`:
- Do NOT emit error state that causes error UI
- Log for debugging only
- Continue with RPE-only mode (`HealthData` fields null)

This is enforced by the calling code in Epic 5 — document this contract clearly in `GetHealthData` docstring (already done in Task 6).

### Error Handling Anti-Pattern to Avoid

```dart
// ❌ WRONG — datasource returning Either
class HealthDataSource {
  Future<Either<Failure, HealthData>> fetchHealthData() { ... }  // WRONG layer
}

// ✅ CORRECT — datasource throws, repository catches
class HealthDataSource {
  Future<HealthData> fetchHealthData() { ... }  // throws SensorException
}
class HealthRepositoryImpl {
  Future<Either<Failure, HealthData>> fetchHealthData() {
    try { return Right(await _source.fetchHealthData()); }
    on SensorException catch (e) { return Left(SensorFailure(e.message)); }
  }
}
```

### File Structure

```
lib/features/session/
├── data/
│   ├── datasources/
│   │   └── health_data_source.dart             ← NEW
│   └── repositories/
│       └── health_repository_impl.dart         ← NEW
├── domain/
│   ├── entities/
│   │   └── health_data.dart                    ← NEW
│   ├── repositories/
│   │   └── health_repository.dart              ← NEW
│   └── usecases/
│       └── get_health_data.dart                ← NEW

lib/core/
├── di/
│   └── health_module.dart                      ← NEW
├── error/
│   └── exceptions.dart                         ← MODIFIED (add SensorException)
│   └── failures.dart                           ← NO CHANGE (SensorFailure already present)
│   └── injection.config.dart                   ← REGENERATED

test/
├── data/
│   ├── health_data_source_test.dart            ← NEW
│   ├── health_data_source_test.mocks.dart      ← GENERATED
│   ├── health_repository_impl_test.dart        ← NEW
│   └── health_repository_impl_test.mocks.dart ← GENERATED
└── domain/
    └── usecases/
        ├── get_health_data_test.dart           ← NEW
        └── get_health_data_test.mocks.dart     ← GENERATED
```

**NO CHANGES to:**
- Any existing feature (`onboarding`, `today`, `progress`, etc.)
- `AppDatabase` schema or DAOs
- `AppRouter` (no new routes — this is a backend-only story)
- `AppShell` (no navigation changes)
- `BehavioralStateTable` or `BehavioralStateDao` (already compatible)

### Test Count

Starting: **122 tests** (all passing after Story 2.4 + review patches)

New tests:
- `3.1-UNIT-001` through `3.1-UNIT-004`: `HealthDataSource` (4 tests)
- `3.1-UNIT-005` through `3.1-UNIT-008`: `HealthRepositoryImpl` (4 tests)
- `3.1-UNIT-009` through `3.1-UNIT-010`: `GetHealthData` (2 tests)

Target: **~132 tests** (+10)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic 3, Story 3.1]
- [Source: _bmad-output/planning-artifacts/architecture.md#Sensor Integration, Repository Pattern, Testing Standards]
- [Source: pulse_coach/lib/core/database/tables/behavioral_state_table.dart]
- [Source: pulse_coach/lib/core/database/daos/behavioral_state_dao.dart]
- [Source: pulse_coach/lib/core/error/failures.dart — SensorFailure already defined]
- [Source: pulse_coach/pubspec.yaml — health: ^13.3.1 (spike done)]
- [Source: pulse_coach/ios/Runner/Info.plist — NSHealthShareUsageDescription (spike done)]
- [Source: pulse_coach/android/app/src/main/AndroidManifest.xml — READ_HEART_RATE, READ_STEPS (spike done)]
- [Source: _bmad-output/implementation-artifacts/2-4-profile-view-and-edit.md#Dev Notes — injectable DI pattern]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Task 1: `SensorException` was already present in `exceptions.dart` from an earlier sprint — no changes needed.
- Task 5/8: `AppDatabase.behavioralStateDao` is a `late final` field in drift-generated code — cannot be mocked via `@GenerateMocks([AppDatabase])`. Solution: refactored `HealthRepositoryImpl` to accept `BehavioralStateDao` directly, and registered it as a `@singleton` in `HealthModule` via `db.behavioralStateDao`. This also enables clean mock injection in tests.
- Task 8.1: `HealthDataUnit.BEATS_PER_MIN` doesn't exist in health 13.3.1; correct enum is `HealthDataUnit.BEATS_PER_MINUTE`.

### Completion Notes List

- All 8 tasks completed; all ACs verified.
- `SensorException` was pre-existing — Task 1 was a no-op verification.
- `HealthRepositoryImpl` constructor takes `BehavioralStateDao` (not `AppDatabase`) for clean testability; DI provides it via `HealthModule.behavioralStateDao(AppDatabase db)`.
- `HealthModule` registers both `Health` (singleton) and `BehavioralStateDao` (singleton from `AppDatabase`).
- 10 new unit tests added (3.1-UNIT-001 through 3.1-UNIT-010); all pass.
- Full test suite: 132 tests, 0 failures, 0 regressions.
- No platform file changes (spike already complete).
- No UI changes (backend-only story).

### File List

lib/features/session/domain/entities/health_data.dart (NEW)
lib/features/session/domain/repositories/health_repository.dart (NEW)
lib/features/session/domain/usecases/get_health_data.dart (NEW)
lib/features/session/data/datasources/health_data_source.dart (NEW)
lib/features/session/data/repositories/health_repository_impl.dart (NEW)
lib/core/di/health_module.dart (NEW)
lib/core/di/injection.config.dart (REGENERATED)
test/data/datasources/health_data_source_test.dart (NEW)
test/data/datasources/health_data_source_test.mocks.dart (GENERATED)
test/data/repositories/health_repository_impl_test.dart (NEW)
test/data/repositories/health_repository_impl_test.mocks.dart (GENERATED)
test/domain/usecases/get_health_data_test.dart (NEW)
test/domain/usecases/get_health_data_test.mocks.dart (GENERATED)

### Review Findings

- [x] [Review][Defer] F1: `saveHealthData` failure silently swallowed in `GetHealthData.call()` — `await _repository.saveHealthData(data)` result is discarded; a `Left(CacheFailure)` is dropped and `Right(data)` returned as if persistence succeeded. AC3 requires data to be stored; the spec flags save-failure handling as an open question. [get_health_data.dart:21] — deferred: Epic 5 AI engine definirà la strategia di error handling per la persistenza; decidere ora anticipa logica non ancora progettata
- [x] [Review][Patch] F2: Two separate `DateTime.now()` calls in `saveHealthData` produce potentially different timestamps for `recordedAt` and `updatedAt` — FIXED: extracted to single variable [health_repository_impl.dart:39-40]
- [x] [Review][Defer] F3: `hrPoints.last` does not guarantee most recent data point if health package returns unsorted results [health_data_source.dart:51] — deferred, spec-prescribed code pattern
- [x] [Review][Defer] F4: `configure()` called on every `fetchHealthData()` invocation; benign but suboptimal on Android [health_data_source.dart:23] — deferred, spec-prescribed code pattern

### Change Log

- 2026-04-03: Story 3.1 implemented — Health API integration (HR & Steps) with HealthDataSource, HealthRepositoryImpl, GetHealthData use case, HealthModule DI, and 10 unit tests (132 total). No platform config changes needed (spike complete).
