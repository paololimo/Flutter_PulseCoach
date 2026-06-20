# Story 3.2: Accelerometer Activity Detection

Status: done

## Story

As the system,
I want to detect user activity patterns via the device accelerometer,
So that the state vector has activity-level context even when Health API is unavailable.

## Acceptance Criteria

1. **Given** the accelerometer is available on the device
   **When** the app is in the foreground
   **Then** `SensorRepository.fetchActivityLevel()` reads accelerometer data via `sensors_plus` and classifies activity as `sedentary` / `moderate` / `active` (FR43)

2. **Given** activity is detected via accelerometer
   **When** the `StateVector` is built (Story 5.1)
   **Then** the `activityLevel` field is populated from the accelerometer classification — `GetActivityLevel` use case must be injectable and testable now

3. **Given** the accelerometer is unavailable
   **When** `SensorRepository.fetchActivityLevel()` is called
   **Then** `Left(SensorFailure('Accelerometer unavailable'))` is returned — no crash, no error UI shown to user (ARCH: never show error UI for expected degradation)

## Tasks / Subtasks

- [x] Task 1: Create `ActivityLevel` domain entity (AC: 1, 2, 3)
  - [x] 1.1 Create `lib/features/session/domain/entities/activity_level.dart`:
    ```dart
    enum ActivityLevel { sedentary, moderate, active }
    ```
  - [x] **DO NOT use freezed** — plain enum, no state management needed

- [x] Task 2: Create `SensorRepository` interface (AC: 1, 3)
  - [x] 2.1 Create `lib/features/session/domain/repositories/sensor_repository.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

    abstract class SensorRepository {
      /// Samples accelerometer for ~1 second, classifies activity.
      /// Returns [SensorFailure] if sensor unavailable or stream errors.
      Future<Either<Failure, ActivityLevel>> fetchActivityLevel();
    }
    ```

- [x] Task 3: Create `AccelerometerDataSource` (wraps `sensors_plus`) (AC: 1, 3)
  - [x] 3.1 Create `lib/features/session/data/datasources/accelerometer_data_source.dart`:
    ```dart
    import 'dart:math';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/exceptions.dart';
    import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
    import 'package:sensors_plus/sensors_plus.dart';

    @injectable
    class AccelerometerDataSource {
      static const int _sampleCount = 30;

      // Thresholds for std dev of acceleration magnitude (m/s²)
      static const double _sedentaryThreshold = 0.3;
      static const double _moderateThreshold = 1.5;

      Future<ActivityLevel> fetchActivityLevel() async {
        try {
          final samples = <double>[];
          await for (final event in accelerometerEventStream(
            samplingPeriod: SensorInterval.normalInterval,
          )) {
            final magnitude = sqrt(
              event.x * event.x + event.y * event.y + event.z * event.z,
            );
            samples.add(magnitude);
            if (samples.length >= _sampleCount) break;
          }

          // Classify by std dev of magnitudes (orientation-invariant)
          final mean = samples.reduce((a, b) => a + b) / samples.length;
          final variance = samples
                  .map((m) => (m - mean) * (m - mean))
                  .reduce((a, b) => a + b) /
              samples.length;
          final stdDev = sqrt(variance);

          if (stdDev < _sedentaryThreshold) return ActivityLevel.sedentary;
          if (stdDev < _moderateThreshold) return ActivityLevel.moderate;
          return ActivityLevel.active;
        } on SensorException {
          rethrow;
        } catch (e) {
          throw SensorException(e.toString());
        }
      }
    }
    ```
  - [x] **sensors_plus 6.1.0 API:**
    - Top-level function: `accelerometerEventStream({Duration samplingPeriod})` — NOT the deprecated `accelerometerEvents` stream
    - `SensorInterval.normalInterval` = `Duration(milliseconds: 200)` — 5 Hz, sufficient for activity classification
    - `AccelerometerEvent` fields: `x`, `y`, `z` (m/s²), `timestamp`
    - When hardware unavailable: package throws `SensorNotAvailedException` (caught by the outer catch and rethrown as `SensorException`)
  - [x] **Classification algorithm:** std dev of magnitudes over 30 samples
    - `stdDev < 0.3` → sedentary (device nearly static, only gravity)
    - `0.3 ≤ stdDev < 1.5` → moderate (light movement, walking slowly)
    - `stdDev ≥ 1.5` → active (running, vigorous movement)
    - **Orientation-invariant:** magnitude-based approach works regardless of phone orientation
  - [x] **No permissions required** — accelerometer access is unrestricted on iOS and Android; no manifest/entitlement changes needed

- [x] Task 4: Create `SensorRepositoryImpl` (AC: 1, 3)
  - [x] 4.1 Create `lib/features/session/data/repositories/sensor_repository_impl.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/exceptions.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/session/data/datasources/accelerometer_data_source.dart';
    import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
    import 'package:pulse_coach/features/session/domain/repositories/sensor_repository.dart';

    @Injectable(as: SensorRepository)
    class SensorRepositoryImpl implements SensorRepository {
      final AccelerometerDataSource _dataSource;

      SensorRepositoryImpl(this._dataSource);

      @override
      Future<Either<Failure, ActivityLevel>> fetchActivityLevel() async {
        try {
          final level = await _dataSource.fetchActivityLevel();
          return Right(level);
        } on SensorException catch (e) {
          return Left(SensorFailure(e.message));
        } catch (e) {
          return Left(SensorFailure(e.toString()));
        }
      }
    }
    ```
  - [x] **No DB persistence** — Story 3.2 has no "store to behavioral_state" AC. Activity level is provided via use case for Story 5.1 to consume when building StateVector. (Contrast: Story 3.1 explicitly required persistence to `behavioral_state` via AC3.)

- [x] Task 5: Create `GetActivityLevel` use case (AC: 1, 2, 3)
  - [x] 5.1 Create `lib/features/session/domain/usecases/get_activity_level.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
    import 'package:pulse_coach/features/session/domain/repositories/sensor_repository.dart';

    /// Samples the accelerometer and classifies user activity level.
    /// Returns [ActivityLevel] on success, [SensorFailure] if accelerometer unavailable.
    /// On failure, Story 5.1 (StateVector) should treat activityLevel as null — do NOT surface error to user.
    @injectable
    class GetActivityLevel {
      GetActivityLevel(this._repository);
      final SensorRepository _repository;

      Future<Either<Failure, ActivityLevel>> call() =>
          _repository.fetchActivityLevel();
    }
    ```

- [x] Task 6: Regenerate DI (AC: all)
  - [x] 6.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] 6.2 Verify `injection.config.dart` registers:
    - `AccelerometerDataSource` as factory
    - `SensorRepositoryImpl` as factory for `SensorRepository`
    - `GetActivityLevel` as factory
  - [x] 6.3 **No new `@module` needed** — `AccelerometerDataSource` has no external constructor-injected types (unlike `HealthDataSource` which needed `Health` singleton)

- [x] Task 7: Write tests (AC: 1, 3)
  - [x] 7.1 Create `test/data/datasources/accelerometer_data_source_test.dart`:
    - Mock strategy: mock `accelerometerEventStream` via a custom stream controller
    - Tests:
      - `3.2-UNIT-001`: returns `ActivityLevel.sedentary` when std dev < 0.3 (30 uniform samples ~9.8 m/s²)
      - `3.2-UNIT-002`: returns `ActivityLevel.moderate` when std dev between 0.3 and 1.5 (mixed samples)
      - `3.2-UNIT-003`: returns `ActivityLevel.active` when std dev ≥ 1.5 (high-variance samples)
      - `3.2-UNIT-004`: throws `SensorException` when stream throws (sensor unavailable)
    - **Testing `accelerometerEventStream`:** Because it's a package-level function (not injectable), use a test-specific constructor or function injection. Create `AccelerometerDataSource` with an optional stream factory parameter:
      ```dart
      @injectable
      class AccelerometerDataSource {
        // For production: uses sensors_plus
        // For tests: accept injectable stream factory
        final Stream<AccelerometerEvent> Function({Duration samplingPeriod})? _streamFactory;

        AccelerometerDataSource({
          @factoryParam Stream<AccelerometerEvent> Function({Duration samplingPeriod})? streamFactory,
        }) : _streamFactory = streamFactory;
      ```
      Actually this adds complexity. **Simpler approach:** extract to a protected method:
      ```dart
      @injectable
      class AccelerometerDataSource {
        Stream<AccelerometerEvent> _accelerometerStream() =>
            accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval);
      }
      ```
      Then in tests, subclass and override `_accelerometerStream()`. However, `_` prefix prevents subclassing. **Best approach:** Make the stream getter `@visibleForTesting`:
      ```dart
      Stream<AccelerometerEvent> get accelerometerStream =>
          accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval);
      ```
      And in tests use a spy/subclass, OR use a wrapper function injected at construction:
      ```dart
      @injectable
      class AccelerometerDataSource {
        final Stream<AccelerometerEvent> Function()? _streamOverride;

        // Production: @injectable constructor, streamOverride defaults to null
        AccelerometerDataSource({Stream<AccelerometerEvent> Function()? streamOverride})
            : _streamOverride = streamOverride;

        Stream<AccelerometerEvent> get _stream =>
            _streamOverride?.call() ??
            accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval);
      ```
      In tests: `AccelerometerDataSource(streamOverride: () => Stream.fromIterable([...]))`.
      This is the **recommended approach** — zero additional dependencies, easily testable.

  - [x] 7.2 Create `test/data/repositories/sensor_repository_impl_test.dart`:
    - `@GenerateMocks([AccelerometerDataSource])`
    - Tests:
      - `3.2-UNIT-005`: `fetchActivityLevel()` returns `Right(ActivityLevel.active)` when datasource succeeds
      - `3.2-UNIT-006`: `fetchActivityLevel()` returns `Left(SensorFailure)` when datasource throws `SensorException`
      - `3.2-UNIT-007`: `fetchActivityLevel()` returns `Left(SensorFailure)` on unexpected exception

  - [x] 7.3 Create `test/domain/usecases/get_activity_level_test.dart`:
    - `@GenerateMocks([SensorRepository])`
    - Tests:
      - `3.2-UNIT-008`: `call()` delegates to `SensorRepository.fetchActivityLevel()`
      - `3.2-UNIT-009`: `call()` returns `Left(SensorFailure)` when repository returns failure

  - [x] 7.4 Run `dart run build_runner build --delete-conflicting-outputs` to generate mocks
  - [x] 7.5 Run `flutter test` — target **~141 tests** (+9 from 132 baseline) — all tests PASS ✅

## Dev Notes

### Feature Location Decision

Files go under `lib/features/session/` (same as Story 3.1), per architecture:
> `lib/features/session/data/datasources/sensor_data_source.dart` — "Health API (HR, steps)"

Story 3.1 deviated from architecture naming (`health_data_source.dart` instead of `sensor_data_source.dart`). Story 3.2 follows the same deviation for clarity: `accelerometer_data_source.dart`.

### sensors_plus 6.1.0 API (Already in pubspec.lock)

```dart
import 'package:sensors_plus/sensors_plus.dart';

// Top-level function (new in v5+ — replaces deprecated accelerometerEvents stream)
Stream<AccelerometerEvent> accelerometerEventStream({
  Duration samplingPeriod = SensorInterval.normalInterval,
});

// SensorInterval constants
SensorInterval.normalInterval   // ~200ms between samples (5 Hz)
SensorInterval.uiInterval       // ~60ms (16 Hz)
SensorInterval.gameInterval     // ~20ms (50 Hz)
SensorInterval.fastestInterval  // device-dependent

class AccelerometerEvent {
  final double x, y, z;   // m/s², includes gravity
  final DateTime timestamp;
}
```

**Do NOT use the deprecated `accelerometerEvents` stream** — it was removed in sensors_plus 5.x.

### No Permissions Required

Unlike Health API (Story 3.1), accelerometer access requires NO explicit user permission on:
- **iOS**: `NSMotionUsageDescription` is only needed for CMMotionActivityManager (step counting) — NOT for raw accelerometer data via `sensors_plus`
- **Android**: No `BODY_SENSORS` or other permission needed for accelerometer

**Do NOT modify any platform files** — no `Info.plist`, no `AndroidManifest.xml` changes needed.

### No DB Persistence — Key Difference from Story 3.1

Story 3.1 had AC3: "data is stored in `behavioral_state` table". Story 3.2 has NO equivalent AC.

- `GetActivityLevel` returns the classification via `Either<Failure, ActivityLevel>`
- Story 5.1 (`DailyPlanBloc`) will call both `GetHealthData` AND `GetActivityLevel` when building `StateVector`
- Story 5.1 will then persist the complete state to `behavioral_state`

**Do NOT add `activityLevel` column to `behavioral_state_table.dart`** — no schema changes, no `build_runner` drift regeneration needed for this story (only for DI regeneration).

### Failure/Exception Layering (Same as Story 3.1)

| Layer | Uses |
|---|---|
| `AccelerometerDataSource` | Throws `SensorException` |
| `SensorRepositoryImpl` | Catches `SensorException`, returns `Left(SensorFailure(...))` |
| `GetActivityLevel` use case | Passes `Either` through |
| `DailyPlanBloc` (Story 5.1) | Pattern-matches `Either`, treats failure as `activityLevel = null` |
| UI | Never sees exception — graceful degradation only |

`SensorFailure` and `SensorException` already exist — do NOT recreate.

### Classification Algorithm — Design Rationale

**Why std dev of magnitudes (not mean)?**
- A phone lying still has magnitude ≈ 9.8 m/s² (gravity only), with near-zero variation
- Walking generates oscillation → high magnitude variance even if the phone is held at any angle
- Std dev is orientation-invariant — works whether phone is vertical, horizontal, or in pocket

**Why 30 samples at 200ms interval = ~6 seconds?**
- Sufficient window to distinguish a single step from sustained movement
- Not so long as to block the calling code (max ~6s for a full sample)
- `SensorInterval.normalInterval` (200ms) = 30 samples in ~6 seconds

**Thresholds (empirically established):**
- `stdDev < 0.3 m/s²` → sedentary (phone on desk, standing still)
- `0.3 ≤ stdDev < 1.5 m/s²` → moderate (slow walk, minor hand movement)
- `stdDev ≥ 1.5 m/s²` → active (brisk walk, jog, cycling)

### Testability Strategy for AccelerometerDataSource

`accelerometerEventStream()` is a package-level function — not a class method, so it cannot be mocked via `@GenerateMocks`. Solution: inject a stream factory via constructor:

```dart
@injectable
class AccelerometerDataSource {
  final Stream<AccelerometerEvent> Function()? _streamOverride;

  AccelerometerDataSource({Stream<AccelerometerEvent> Function()? streamOverride})
      : _streamOverride = streamOverride;

  Stream<AccelerometerEvent> get _stream =>
      _streamOverride?.call() ??
      accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval);
}
```

In tests:
```dart
final testEvents = [
  AccelerometerEvent(9.8, 0.0, 0.0, DateTime.now()),  // uniform → sedentary
  // ... 29 more
];
final ds = AccelerometerDataSource(
  streamOverride: () => Stream.fromIterable(testEvents),
);
```

**`@injectable` compatibility:** `get_it`/`injectable` will call `AccelerometerDataSource()` with `streamOverride: null` (default), so production DI requires no changes.

### File Structure

```
lib/features/session/
├── data/
│   ├── datasources/
│   │   ├── health_data_source.dart             ← EXISTING (Story 3.1)
│   │   └── accelerometer_data_source.dart      ← NEW
│   └── repositories/
│       ├── health_repository_impl.dart         ← EXISTING (Story 3.1)
│       └── sensor_repository_impl.dart         ← NEW
├── domain/
│   ├── entities/
│   │   ├── health_data.dart                    ← EXISTING (Story 3.1)
│   │   └── activity_level.dart                 ← NEW
│   ├── repositories/
│   │   ├── health_repository.dart              ← EXISTING (Story 3.1)
│   │   └── sensor_repository.dart              ← NEW
│   └── usecases/
│       ├── get_health_data.dart                ← EXISTING (Story 3.1)
│       └── get_activity_level.dart             ← NEW

lib/core/di/
└── injection.config.dart                       ← REGENERATED

test/data/datasources/
└── accelerometer_data_source_test.dart         ← NEW (no mock generation needed)
test/data/repositories/
├── sensor_repository_impl_test.dart            ← NEW
└── sensor_repository_impl_test.mocks.dart     ← GENERATED
test/domain/usecases/
├── get_activity_level_test.dart                ← NEW
└── get_activity_level_test.mocks.dart          ← GENERATED
```

**NO CHANGES to:**
- `health_data_source.dart`, `health_repository.dart`, `health_repository_impl.dart` (Story 3.1 files)
- `behavioral_state_table.dart` or `behavioral_state_dao.dart` (no schema changes)
- `health_module.dart` (no new DI module needed)
- Any platform files (`Info.plist`, `AndroidManifest.xml`)
- Any existing feature (`onboarding`, `today`, `progress`, etc.)
- `AppRouter` (no new routes — backend-only story)

### Test Count

Starting: **132 tests** (all passing after Story 3.1)

New tests:
- `3.2-UNIT-001` through `3.2-UNIT-004`: `AccelerometerDataSource` (4 tests)
- `3.2-UNIT-005` through `3.2-UNIT-007`: `SensorRepositoryImpl` (3 tests)
- `3.2-UNIT-008` through `3.2-UNIT-009`: `GetActivityLevel` (2 tests)

Target: **~141 tests** (+9)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic 3, Story 3.2]
- [Source: _bmad-output/planning-artifacts/architecture.md#Sensor Integration, Graceful Degradation]
- [Source: _bmad-output/implementation-artifacts/3-1-health-api-integration-hr-and-steps.md#Dev Notes]
- [Source: pulse_coach/pubspec.yaml — sensors_plus: ^6.1.0 (spike done)]
- [Source: pulse_coach/lib/core/error/exceptions.dart — SensorException already defined]
- [Source: pulse_coach/lib/core/error/failures.dart — SensorFailure already defined]
- [Source: pulse_coach/lib/features/session/data/datasources/health_data_source.dart — pattern to follow]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- **DI typedef fix:** `injectable_generator` could not resolve `Stream<AccelerometerEvent> Function()` as a constructor param type. Resolution: added `typedef AccelerometerStreamFactory` and split into default constructor (production, `@injectable`) and named constructor `.withOverride()` (test-only). No impact on runtime behavior.
- **Test UNIT-002 float precision:** initial test used 9.5/10.1 values → exact `stdDev = 0.3` which failed due to floating-point `sqrt(0.09) < 0.3`. Fixed to 9.3/10.3 → `stdDev = 0.5`.

### Completion Notes List

- Created `ActivityLevel` enum (plain, no freezed) per story spec
- Created `SensorRepository` abstract interface with `fetchActivityLevel()` returning `Either<Failure, ActivityLevel>`
- Created `AccelerometerDataSource` using `accelerometerEventStream` (sensors_plus 6.1.0 API); classification via std dev of 30 magnitude samples; testability via `.withOverride()` named constructor
- Created `SensorRepositoryImpl` mapping `SensorException → Left(SensorFailure)`, unexpected exceptions also mapped to `Left(SensorFailure)` — no crash, no UI error
- Created `GetActivityLevel` use case passing `Either` through from repository
- Regenerated DI: `AccelerometerDataSource`, `SensorRepositoryImpl` (as `SensorRepository`), `GetActivityLevel` all registered as factories
- All 9 new tests (3.2-UNIT-001..009) pass; full suite: 141/141 ✅

### File List

- `pulse_coach/lib/features/session/domain/entities/activity_level.dart` (new)
- `pulse_coach/lib/features/session/domain/repositories/sensor_repository.dart` (new)
- `pulse_coach/lib/features/session/data/datasources/accelerometer_data_source.dart` (new)
- `pulse_coach/lib/features/session/data/repositories/sensor_repository_impl.dart` (new)
- `pulse_coach/lib/features/session/domain/usecases/get_activity_level.dart` (new)
- `pulse_coach/lib/core/di/injection.config.dart` (regenerated)
- `pulse_coach/test/data/datasources/accelerometer_data_source_test.dart` (new)
- `pulse_coach/test/data/repositories/sensor_repository_impl_test.dart` (new)
- `pulse_coach/test/data/repositories/sensor_repository_impl_test.mocks.dart` (generated)
- `pulse_coach/test/domain/usecases/get_activity_level_test.dart` (new)
- `pulse_coach/test/domain/usecases/get_activity_level_test.mocks.dart` (generated)

### Review Findings

- [x] [Review][Decision] AC3 failure message mismatch — resolved: normalize to fixed message `'Accelerometer unavailable'` in SensorRepositoryImpl to match AC3 spec
- [x] [Review][Patch] Empty/short stream causes StateError — fixed: added minimum sample guard (_minSampleCount=10), throws SensorException on insufficient data [accelerometer_data_source.dart:45]
- [x] [Review][Patch] No timeout on stream consumption — fixed: added 5s timeout via Stream.timeout() [accelerometer_data_source.dart:37]
- [x] [Review][Defer] Boundary value tests missing — no tests at exact thresholds (stdDev == 0.3, == 1.5); current tests use values clearly within each band [accelerometer_data_source_test.dart] — deferred, nice-to-have improvement

### Change Log

- 2026-04-03: Story 3.2 implemented — AccelerometerDataSource, SensorRepository, SensorRepositoryImpl, GetActivityLevel use case; DI regenerated; 9 unit tests added (141 total)
