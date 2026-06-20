# Story 3.3: RPE-Only Fallback Mode

Status: done

## Story

As the system,
I want all core functionality to work with zero sensor data,
So that users who deny Health API permissions receive the same quality of experience as those who grant them.

## Acceptance Criteria

1. **Given** the user denies all Health API permissions
   **When** the system constructs the `StateVector` (Story 5.1)
   **Then** `restingHR`, `stepCount`, and `activityLevel` are null — the system enters RPE-only mode (FR44, NFR21)

2. **Given** the system is in RPE-only mode
   **When** a daily plan is generated
   **Then** the bandit selects sessions based on RPE history, profile, and environmental context alone — plan quality is not degraded

3. **Given** the system is in RPE-only mode
   **When** the user views the Today screen
   **Then** the StateIndicator explanation reflects available data (e.g., RPE history, profile) without referencing missing sensor data

## Tasks / Subtasks

- [x] Task 1: Create `SensorContext` domain entity (AC: 1)
  - [x] 1.1 Create `lib/features/session/domain/entities/sensor_context.dart`:
    ```dart
    import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

    /// Aggregated sensor snapshot used by StateVector (Story 5.1).
    /// All fields are nullable — null means data unavailable (sensor failed or permission denied).
    /// When all fields are null, the system operates in RPE-only mode.
    class SensorContext {
      final int? restingHr;
      final int? stepCount;
      final ActivityLevel? activityLevel;

      const SensorContext({
        this.restingHr,
        this.stepCount,
        this.activityLevel,
      });

      /// True when NO sensor data is available — RPE-only mode.
      bool get isRpeOnly =>
          restingHr == null && stepCount == null && activityLevel == null;

      /// True when at least one sensor field is populated.
      bool get hasSensorData => !isRpeOnly;
    }
    ```
  - [x] **Plain class — NO freezed.** Story 3.3 is a pure aggregation entity; immutability and copyWith are not needed here (StateVector in 5.1 will be freezed when it includes this data).
  - [x] **No DB persistence** — `SensorContext` is a transient runtime snapshot. Not stored. Story 5.1 will persist the final `StateVector` that incorporates this data.

- [x] Task 2: Create `GetSensorContext` use case (AC: 1, 2, 3)
  - [x] 2.1 Create `lib/features/session/domain/usecases/get_sensor_context.dart`:
    ```dart
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/features/session/domain/entities/sensor_context.dart';
    import 'package:pulse_coach/features/session/domain/usecases/get_activity_level.dart';
    import 'package:pulse_coach/features/session/domain/usecases/get_health_data.dart';

    /// Aggregates all sensor inputs into a single [SensorContext].
    ///
    /// NEVER returns a failure — sensor unavailability is a valid first-class state,
    /// not an error. Failures from GetHealthData and GetActivityLevel are silently
    /// converted to null fields. The caller receives a fully populated or partially/fully
    /// null SensorContext and must handle RPE-only mode accordingly.
    ///
    /// This is the single entry point for Epic 5 (StateVector) to get sensor data.
    @injectable
    class GetSensorContext {
      GetSensorContext(this._getHealthData, this._getActivityLevel);

      final GetHealthData _getHealthData;
      final GetActivityLevel _getActivityLevel;

      Future<SensorContext> call() async {
        // Run both sensor reads concurrently — independent sources, no ordering requirement
        final results = await Future.wait([
          _getHealthData(),
          _getActivityLevel(),
        ]);

        final healthResult = results[0];
        final activityResult = results[1];

        return SensorContext(
          restingHr: healthResult.fold((_) => null, (data) => data.restingHr),
          stepCount: healthResult.fold((_) => null, (data) => data.stepCount),
          activityLevel: activityResult.fold((_) => null, (level) => level),
        );
      }
    }
    ```
  - [x] **Return type is `SensorContext` (NOT `Either`)** — this is intentional. The "fallback to null" IS the success path. Epic 5 consumers should never have to fold an Either just to get nulls.
  - [x] **`Future.wait` for concurrency** — both sensor reads are independent I/O operations. Running them concurrently saves ~6s accelerometer sampling time when health data is also being fetched.
  - [x] **`results[0]` is `Either<Failure, HealthData>`**, **`results[1]` is `Either<Failure, ActivityLevel>`** — type-safe despite `dynamic` list from Future.wait. Cast is safe because order matches declaration.

- [x] Task 3: Regenerate DI (AC: all)
  - [x] 3.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] 3.2 Verify `injection.config.dart` registers `GetSensorContext` as a factory
  - [x] **No new `@module` needed** — `GetSensorContext` depends only on `GetHealthData` and `GetActivityLevel`, both already registered as factories

- [x] Task 4: Write tests (AC: 1, 2, 3)
  - [x] 4.1 Create `test/domain/usecases/get_sensor_context_test.dart`:
    ```dart
    @GenerateMocks([GetHealthData, GetActivityLevel])
    ```
    Tests:
    - `3.3-UNIT-001`: both sources succeed → all fields populated
      - `GetHealthData` returns `Right(HealthData(restingHr: 62, stepCount: 4500))`
      - `GetActivityLevel` returns `Right(ActivityLevel.moderate)`
      - Result: `SensorContext(restingHr: 62, stepCount: 4500, activityLevel: ActivityLevel.moderate)`
      - `isRpeOnly == false`, `hasSensorData == true`
    - `3.3-UNIT-002`: health fails, activity succeeds → HR/steps null, activityLevel set
      - `GetHealthData` returns `Left(SensorFailure('Permission denied'))`
      - `GetActivityLevel` returns `Right(ActivityLevel.sedentary)`
      - Result: `SensorContext(restingHr: null, stepCount: null, activityLevel: ActivityLevel.sedentary)`
      - `isRpeOnly == false`
    - `3.3-UNIT-003`: health succeeds, activity fails → HR/steps set, activityLevel null
      - `GetHealthData` returns `Right(HealthData(restingHr: 58, stepCount: 8200))`
      - `GetActivityLevel` returns `Left(SensorFailure('Accelerometer unavailable'))`
      - Result: `SensorContext(restingHr: 58, stepCount: 8200, activityLevel: null)`
      - `isRpeOnly == false`
    - `3.3-UNIT-004`: both fail → all null — RPE-only mode confirmed
      - `GetHealthData` returns `Left(SensorFailure('Permission denied'))`
      - `GetActivityLevel` returns `Left(SensorFailure('Accelerometer unavailable'))`
      - Result: `SensorContext(restingHr: null, stepCount: null, activityLevel: null)`
      - `isRpeOnly == true`, `hasSensorData == false`
    - `3.3-UNIT-005`: health returns partial data (null fields) — steps only
      - `GetHealthData` returns `Right(HealthData(restingHr: null, stepCount: 6100))`
      - `GetActivityLevel` returns `Left(SensorFailure('Unavailable'))`
      - Result: `SensorContext(restingHr: null, stepCount: 6100, activityLevel: null)`
      - `isRpeOnly == false` (has stepCount)

  - [x] 4.2 Mock strategy: `@GenerateMocks([GetHealthData, GetActivityLevel])`
    - Both are concrete classes with `call()` methods — `mockito` handles them fine
    - Mock setup: `when(mockGetHealthData()).thenAnswer((_) async => Right(...))`
  - [x] 4.3 Run `dart run build_runner build --delete-conflicting-outputs` to generate mocks
  - [x] 4.4 Run `flutter test` — 149 total tests (5 new 3.3-UNIT tests) — all tests PASS ✅

## Dev Notes

### Epic 3 Completion — What This Story Closes

Epic 3 has built the full sensor layer:
- **Story 3.1:** `GetHealthData` → `Either<Failure, HealthData>` (HR + steps, stored in DB)
- **Story 3.2:** `GetActivityLevel` → `Either<Failure, ActivityLevel>` (accelerometer classification)
- **Story 3.3:** `GetSensorContext` → `SensorContext` (unified, null-safe aggregation, used by Epic 5)

Story 3.3 creates the **contract boundary** between Epic 3 (sensor layer) and Epic 5 (AI engine / StateVector). After this story, Epic 5 only needs to call `GetSensorContext()` and consume a `SensorContext` with nullable fields — it never needs to know about `Either`, `SensorFailure`, or individual sensor use cases.

### Why `SensorContext` Returns No Either

The core design decision: RPE-only mode (all-null SensorContext) is **not an error** — it is a **first-class operational mode** described in FR44 and NFR21. Returning `Either<Failure, SensorContext>` would imply that total sensor failure is exceptional, which it is not (e.g., simulator, denied permissions).

`GetSensorContext.call()` is guaranteed to return a `SensorContext`. The caller (Story 5.1 `DailyPlanBloc`) checks `sensorContext.isRpeOnly` and branches on plan generation strategy accordingly.

### Concurrency Design

`Future.wait([_getHealthData(), _getActivityLevel()])` runs both sensor reads simultaneously:

- **Health API read:** ~100–500ms (async HealthKit/Health Connect query)
- **Accelerometer read:** up to ~6s (30 samples × 200ms, with 5s timeout)

Without concurrency: total latency up to ~6.5s. With concurrency: ~6s (bottlenecked by accelerometer). This matters for plan generation loading time in `DailyPlanBloc`.

### `Future.wait` Type Handling

`Future.wait` returns `List<dynamic>` when futures have different types. Safe pattern:

```dart
final results = await Future.wait([
  _getHealthData(),    // Future<Either<Failure, HealthData>>
  _getActivityLevel(), // Future<Either<Failure, ActivityLevel>>
]);

// Access by index — order is guaranteed
final healthResult = results[0] as Either<Failure, HealthData>;
final activityResult = results[1] as Either<Failure, ActivityLevel>;
```

OR use typed parallel execution:
```dart
final healthFuture = _getHealthData();
final activityFuture = _getActivityLevel();
final healthResult = await healthFuture;
final activityResult = await activityFuture;
```
Both are valid. The `Future.wait` approach is more idiomatic for N parallel tasks; the separate await approach is more type-safe. **Use the separate await approach for clarity** — avoids runtime cast:

```dart
Future<SensorContext> call() async {
  final healthFuture = _getHealthData();
  final activityFuture = _getActivityLevel();
  
  final healthResult = await healthFuture;
  final activityResult = await activityFuture;
  
  return SensorContext(
    restingHr: healthResult.fold((_) => null, (d) => d.restingHr),
    stepCount: healthResult.fold((_) => null, (d) => d.stepCount),
    activityLevel: activityResult.fold((_) => null, (l) => l),
  );
}
```

This launches both futures before the first `await`, preserving concurrency while retaining static types.

### File Structure

```
lib/features/session/
├── domain/
│   ├── entities/
│   │   ├── health_data.dart              ← EXISTING (Story 3.1)
│   │   ├── activity_level.dart           ← EXISTING (Story 3.2)
│   │   └── sensor_context.dart           ← NEW
│   └── usecases/
│       ├── get_health_data.dart          ← EXISTING (Story 3.1)
│       ├── get_activity_level.dart       ← EXISTING (Story 3.2)
│       └── get_sensor_context.dart       ← NEW

lib/core/di/
└── injection.config.dart                 ← REGENERATED

test/domain/usecases/
├── get_sensor_context_test.dart          ← NEW
└── get_sensor_context_test.mocks.dart   ← GENERATED
```

**NO CHANGES to:**
- `health_data_source.dart`, `accelerometer_data_source.dart` (data layer)
- `health_repository_impl.dart`, `sensor_repository_impl.dart` (data layer)
- `get_health_data.dart`, `get_activity_level.dart` (upstream use cases)
- `behavioral_state_table.dart`, `behavioral_state_dao.dart` (no schema changes)
- Any presentation layer files (no UI for this story)
- `AppRouter` (no new routes)
- Any platform files (`Info.plist`, `AndroidManifest.xml`)

### Existing Dependencies — Do NOT Recreate

| Symbol | File | From Story |
|--------|------|-----------|
| `HealthData` | `domain/entities/health_data.dart` | 3.1 |
| `ActivityLevel` | `domain/entities/activity_level.dart` | 3.2 |
| `GetHealthData` | `domain/usecases/get_health_data.dart` | 3.1 |
| `GetActivityLevel` | `domain/usecases/get_activity_level.dart` | 3.2 |
| `SensorFailure` | `core/error/failures.dart` | 1.5 |
| `SensorException` | `core/error/exceptions.dart` | 3.1 |

### Mocking `GetHealthData` and `GetActivityLevel`

Both are injectable concrete classes with a single `call()` method. Mockito handles them with `@GenerateMocks([GetHealthData, GetActivityLevel])`.

```dart
// In test setup
final mockGetHealthData = MockGetHealthData();
final mockGetActivityLevel = MockGetActivityLevel();
final useCase = GetSensorContext(mockGetHealthData, mockGetActivityLevel);

// Stubbing
when(mockGetHealthData()).thenAnswer((_) async => Right(HealthData(restingHr: 62, stepCount: 4500)));
when(mockGetActivityLevel()).thenAnswer((_) async => Right(ActivityLevel.moderate));

// Verify concurrency — both called exactly once per invocation
verify(mockGetHealthData()).called(1);
verify(mockGetActivityLevel()).called(1);
```

### Test Count

Starting: **141 tests** (all passing after Story 3.2)

New tests:
- `3.3-UNIT-001` through `3.3-UNIT-005`: `GetSensorContext` (5 tests)

Target: **~146 tests** (+5)

### Failure/Degradation Layering — Epic 3 Complete Picture

| Layer | Behavior on sensor failure |
|-------|---------------------------|
| `AccelerometerDataSource` | Throws `SensorException` |
| `HealthDataSource` | Throws `SensorException` |
| `SensorRepositoryImpl` | Catches `SensorException` → `Left(SensorFailure)` |
| `HealthRepositoryImpl` | Catches `SensorException` → `Left(SensorFailure)` |
| `GetActivityLevel` | Passes `Either` through |
| `GetHealthData` | Passes `Either` through (also persists if Right) |
| **`GetSensorContext`** | **Folds `Either` → null — returns plain `SensorContext`** |
| `DailyPlanBloc` (Story 5.1) | Checks `isRpeOnly`, uses available fields |
| UI (Story 7.x, 9.x) | Never sees exceptions — graceful degradation only |

### AC2 and AC3 — Out of Scope for Story 3.3

AC2 (daily plan generation in RPE-only mode) and AC3 (StateIndicator for RPE-only) are **Epic 5 and Epic 7 responsibilities** respectively. Story 3.3's scope within Epic 3 is **establishing the sensor contract**: creating `SensorContext` and `GetSensorContext` so that:
- Epic 5 has a clear, null-safe input for `StateVector` construction
- The "RPE-only" concept is formally defined at the domain level

Do NOT implement any `DailyPlanBloc`, `StateIndicator`, or bandit logic in this story.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic 3, Story 3.3]
- [Source: _bmad-output/planning-artifacts/architecture.md#Graceful Degradation Pattern]
- [Source: _bmad-output/implementation-artifacts/3-1-health-api-integration-hr-and-steps.md]
- [Source: _bmad-output/implementation-artifacts/3-2-accelerometer-activity-detection.md]
- [Source: pulse_coach/lib/features/session/domain/entities/health_data.dart]
- [Source: pulse_coach/lib/features/session/domain/entities/activity_level.dart]
- [Source: pulse_coach/lib/features/session/domain/usecases/get_health_data.dart]
- [Source: pulse_coach/lib/features/session/domain/usecases/get_activity_level.dart]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

No issues — clean implementation. Used separate-await concurrency pattern (type-safe) over Future.wait<dynamic> as recommended in Dev Notes.

### Completion Notes List

- ✅ Created `SensorContext` plain entity with `isRpeOnly` / `hasSensorData` getters. No freezed, no DB persistence.
- ✅ Created `GetSensorContext` use case using separate-await concurrency pattern to preserve static types while launching both futures in parallel.
- ✅ `injection.config.dart` regenerated — `GetSensorContext` registered as factory (depends on `GetHealthData` + `GetActivityLevel`, no new `@module` needed).
- ✅ 5 tests written (3.3-UNIT-001..005) covering all combinations: both succeed, health fails, activity fails, both fail (RPE-only), partial health data. All pass.
- ✅ Full regression suite: 149 tests — all passed. No regressions.

### File List

- `pulse_coach/lib/features/session/domain/entities/sensor_context.dart` (NEW)
- `pulse_coach/lib/features/session/domain/usecases/get_sensor_context.dart` (NEW)
- `pulse_coach/lib/core/di/injection.config.dart` (REGENERATED)
- `pulse_coach/test/domain/usecases/get_sensor_context_test.dart` (NEW)
- `pulse_coach/test/domain/usecases/get_sensor_context_test.mocks.dart` (GENERATED)

### Review Findings

- [x] [Review][Patch] F1: `GetSensorContext.call()` has no try-catch — violates "never fails" contract; unhandled exception from `GetHealthData` (e.g. `CacheException` from `saveHealthData`) crashes caller [get_sensor_context.dart:21-34] — FIXED: added try-catch returning all-null SensorContext
- [x] [Review][Patch] F2: No test for `GetSensorContext` when a dependency throws an exception (not returns Left) — directly validates F1 fix [get_sensor_context_test.dart] — FIXED: added 3.3-UNIT-006
- [x] [Review][Patch] F3: NaN/Infinity accelerometer event values cause silent misclassification to `ActivityLevel.active` — all comparisons with NaN return false, falls through to last return [accelerometer_data_source.dart:38-39] — FIXED: added isNaN/isInfinite guard
- [x] [Review][Defer] F4: No concurrency guard on accelerometer stream subscriptions — no concurrent callers exist today; theoretical risk only [accelerometer_data_source.dart:30-37] — deferred, pre-existing
- [x] [Review][Defer] F5: `SensorContext` has no `==`/`hashCode`/`Equatable` — spec mandates plain class, equality needed only when Epic 5 StateVector consumes it [sensor_context.dart] — deferred, by design

### Change Log

- 2026-04-04: Implemented Story 3.3 — RPE-Only Fallback Mode. Created `SensorContext` entity and `GetSensorContext` use case. Added 5 unit tests (3.3-UNIT-001..005). DI regenerated. 149 tests pass.
