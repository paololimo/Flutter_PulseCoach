# Story 4.3: City-Level Location Resolution

Status: done

## Story

As the system,
I want to resolve the user's approximate city-level location without storing or transmitting precise coordinates,
So that Open-Meteo API calls respect the privacy requirement.

## Acceptance Criteria

1. **Given** the `geolocator` package is used
   **When** location is requested
   **Then** coordinates are rounded to 1 decimal place (~11km precision) before any use or storage (FR35, NFR8)

2. **Given** location permission is denied
   **When** the `WeatherRepository` is queried
   **Then** it returns `Left(LocationFailure)` and the system defaults to indoor sessions for plan generation (FR36)

3. **Given** location is resolved
   **When** stored in the database
   **Then** only the rounded (city-level) coordinates are stored — raw GPS data is never persisted

## Tasks / Subtasks

- [x] Task 1: Create `GeolocatorWrapper` abstraction for testability (AC: 1, 2)
  - [x] 1.1 Create `lib/core/utils/geolocator_wrapper.dart`:
    ```dart
    import 'package:geolocator/geolocator.dart';
    import 'package:injectable/injectable.dart';

    /// Abstract wrapper for Geolocator static methods — enables unit testing.
    /// Wraps the three static calls used by LocationService.
    abstract class GeolocatorWrapper {
      Future<bool> isLocationServiceEnabled();
      Future<LocationPermission> checkPermission();
      Future<LocationPermission> requestPermission();
      Future<Position> getCurrentPosition({LocationSettings? locationSettings});
    }

    @Injectable(as: GeolocatorWrapper)
    class GeolocatorWrapperImpl implements GeolocatorWrapper {
      @override
      Future<bool> isLocationServiceEnabled() =>
          Geolocator.isLocationServiceEnabled();

      @override
      Future<LocationPermission> checkPermission() =>
          Geolocator.checkPermission();

      @override
      Future<LocationPermission> requestPermission() =>
          Geolocator.requestPermission();

      @override
      Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
          Geolocator.getCurrentPosition(locationSettings: locationSettings);
    }
    ```
  - [x] 1.2 Update `lib/core/utils/location_service.dart` to inject `GeolocatorWrapper`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:geolocator/geolocator.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/core/utils/geolocator_wrapper.dart';

    @injectable
    class LocationService {
      LocationService(this._geolocator);

      final GeolocatorWrapper _geolocator;

      Future<Either<Failure, (double lat, double lon)>> getCityLevelCoordinates() async {
        try {
          final serviceEnabled = await _geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            return Left(LocationFailure('Location services are disabled'));
          }

          LocationPermission permission = await _geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await _geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              return Left(LocationFailure('Location permission denied'));
            }
          }
          if (permission == LocationPermission.deniedForever) {
            return Left(LocationFailure('Location permission permanently denied'));
          }

          final position = await _geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low, // city-level sufficient
              timeLimit: Duration(seconds: 10),
            ),
          );

          // Round to 1 decimal place — ~11km precision, city-level (NFR8, FR35)
          final lat = _roundCityLevel(position.latitude);
          final lon = _roundCityLevel(position.longitude);
          return Right((lat, lon));
        } on LocationServiceDisabledException {
          return Left(LocationFailure('Location services are disabled'));
        } catch (e) {
          return Left(LocationFailure('Location unavailable: $e'));
        }
      }

      double _roundCityLevel(double coord) => (coord * 10).round() / 10;
    }
    ```
  - [x] **`GeolocatorWrapperImpl` uses `@Injectable(as: GeolocatorWrapper)`** — consistent with project DI pattern
  - [x] **Do NOT make `GeolocatorWrapperImpl` a `@singleton`** — `LocationService` is `@injectable` (transient); wrapper follows same lifecycle

- [x] Task 2: Regenerate DI (AC: 1, 2)
  - [x] 2.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] 2.2 Verify `injection.config.dart` registers `GeolocatorWrapperImpl` as `GeolocatorWrapper`
  - [x] 2.3 Verify `LocationService` constructor signature updated in generated file
  - [x] **Do NOT manually edit `injection.config.dart`** — always regenerate

- [x] Task 3: Write unit tests (AC: 1, 2, 3)
  - [x] 3.1 Create `test/core/utils/location_service_test.dart`:
    ```dart
    // [P1] LocationService unit tests
    // Tests: city-level rounding, permission denied, service disabled, generic error
    import 'package:dartz/dartz.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:geolocator/geolocator.dart';
    import 'package:mockito/annotations.dart';
    import 'package:mockito/mockito.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/core/utils/geolocator_wrapper.dart';
    import 'package:pulse_coach/core/utils/location_service.dart';

    import 'location_service_test.mocks.dart';

    @GenerateMocks([GeolocatorWrapper])
    void main() {
      late MockGeolocatorWrapper mockGeolocator;
      late LocationService sut;

      /// Helper: create a minimal Position object for test use.
      /// geolocator Position has a factory constructor — use Position.fromMap or
      /// the named constructor depending on the installed version (^13.0.2).
      /// Check: Position(longitude: x, latitude: y, timestamp: DateTime.now(),
      ///   accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0,
      ///   headingAccuracy: 0, speed: 0, speedAccuracy: 0)
      Position makePosition(double lat, double lon) => Position(
            longitude: lon,
            latitude: lat,
            timestamp: DateTime(2026, 1, 1),
            accuracy: 100.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );

      setUp(() {
        mockGeolocator = MockGeolocatorWrapper();
        sut = LocationService(mockGeolocator);
      });

      group('LocationService.getCityLevelCoordinates', () {
        test(
          '4.3-UNIT-001: returns Left(LocationFailure) when location services are disabled',
          () async {
            when(mockGeolocator.isLocationServiceEnabled())
                .thenAnswer((_) async => false);

            final result = await sut.getCityLevelCoordinates();

            expect(result.isLeft(), isTrue);
            result.fold(
              (f) => expect(f, isA<LocationFailure>()),
              (_) => fail('Expected Left'),
            );
          },
        );

        test(
          '4.3-UNIT-002: returns Left(LocationFailure) when permission denied after request',
          () async {
            when(mockGeolocator.isLocationServiceEnabled())
                .thenAnswer((_) async => true);
            when(mockGeolocator.checkPermission())
                .thenAnswer((_) async => LocationPermission.denied);
            when(mockGeolocator.requestPermission())
                .thenAnswer((_) async => LocationPermission.denied);

            final result = await sut.getCityLevelCoordinates();

            expect(result.isLeft(), isTrue);
            result.fold(
              (f) => expect(f, isA<LocationFailure>()),
              (_) => fail('Expected Left'),
            );
          },
        );

        test(
          '4.3-UNIT-003: returns Left(LocationFailure) when permission permanently denied',
          () async {
            when(mockGeolocator.isLocationServiceEnabled())
                .thenAnswer((_) async => true);
            when(mockGeolocator.checkPermission())
                .thenAnswer((_) async => LocationPermission.deniedForever);

            final result = await sut.getCityLevelCoordinates();

            expect(result.isLeft(), isTrue);
            result.fold(
              (f) => expect(f, isA<LocationFailure>()),
              (_) => fail('Expected Left'),
            );
            verifyNever(mockGeolocator.requestPermission());
          },
        );

        test(
          '4.3-UNIT-004: returns Right with rounded coordinates when permission granted (AC1)',
          () async {
            when(mockGeolocator.isLocationServiceEnabled())
                .thenAnswer((_) async => true);
            when(mockGeolocator.checkPermission())
                .thenAnswer((_) async => LocationPermission.whileInUse);
            when(mockGeolocator.getCurrentPosition(
                    locationSettings: anyNamed('locationSettings')))
                .thenAnswer((_) async => makePosition(48.856, 2.352));

            final result = await sut.getCityLevelCoordinates();

            expect(result.isRight(), isTrue);
            final (lat, lon) = result.getOrElse(() => throw Exception());
            expect(lat, equals(48.9)); // 48.856 rounded to 1 decimal
            expect(lon, equals(2.4)); // 2.352 rounded to 1 decimal
          },
        );

        test(
          '4.3-UNIT-005: rounding is applied to negative coordinates (southern/western hemisphere)',
          () async {
            when(mockGeolocator.isLocationServiceEnabled())
                .thenAnswer((_) async => true);
            when(mockGeolocator.checkPermission())
                .thenAnswer((_) async => LocationPermission.always);
            when(mockGeolocator.getCurrentPosition(
                    locationSettings: anyNamed('locationSettings')))
                .thenAnswer((_) async => makePosition(-33.869, -70.673));

            final result = await sut.getCityLevelCoordinates();

            final (lat, lon) = result.getOrElse(() => throw Exception());
            expect(lat, equals(-33.9)); // -33.869 rounded to 1 decimal
            expect(lon, equals(-70.7)); // -70.673 rounded to 1 decimal
          },
        );

        test(
          '4.3-UNIT-006: returns Left(LocationFailure) on generic exception from getCurrentPosition',
          () async {
            when(mockGeolocator.isLocationServiceEnabled())
                .thenAnswer((_) async => true);
            when(mockGeolocator.checkPermission())
                .thenAnswer((_) async => LocationPermission.whileInUse);
            when(mockGeolocator.getCurrentPosition(
                    locationSettings: anyNamed('locationSettings')))
                .thenThrow(Exception('GPS timeout'));

            final result = await sut.getCityLevelCoordinates();

            expect(result.isLeft(), isTrue);
            result.fold(
              (f) => expect(f, isA<LocationFailure>()),
              (_) => fail('Expected Left'),
            );
          },
        );

        test(
          '4.3-UNIT-007: uses LocationAccuracy.low — city-level sufficient, no high-precision GPS (NFR8)',
          () async {
            when(mockGeolocator.isLocationServiceEnabled())
                .thenAnswer((_) async => true);
            when(mockGeolocator.checkPermission())
                .thenAnswer((_) async => LocationPermission.whileInUse);
            when(mockGeolocator.getCurrentPosition(
                    locationSettings: anyNamed('locationSettings')))
                .thenAnswer((_) async => makePosition(45.46, 9.19));

            await sut.getCityLevelCoordinates();

            final captured = verify(mockGeolocator.getCurrentPosition(
                    locationSettings: captureAnyNamed('locationSettings')))
                .captured
                .single as LocationSettings;
            expect(captured.accuracy, equals(LocationAccuracy.low));
          },
        );
      });
    }
    ```
  - [x] 3.2 Run `dart run build_runner build --delete-conflicting-outputs` to generate `location_service_test.mocks.dart`
  - [x] 3.3 Run `flutter test` — starting count: **170 tests**; target: **~177 tests** (+7)

## Dev Notes

### Critical Context: Implementation Already Exists

`LocationService` was created during Story 4.1 setup (needed as a dependency for `WeatherRepositoryImpl`). The business logic is **already correct and fully implemented** at `lib/core/utils/location_service.dart`. This story's work is:
1. **Refactor** to inject `GeolocatorWrapper` (makes the existing logic testable — Task 1)
2. **Regenerate DI** (Task 2)
3. **Write unit tests** (Task 3)

**Do NOT rewrite the business logic.** The existing permission flow, rounding math, and error handling are correct.

### The `_roundCityLevel` Math

```dart
double _roundCityLevel(double coord) => (coord * 10).round() / 10;
```

- `48.856 * 10 = 488.56` → `.round() = 489` → `/ 10 = 48.9` ✓
- `2.352 * 10 = 23.52` → `.round() = 24` → `/ 10 = 2.4` ✓
- `-33.869 * 10 = -338.69` → `.round() = -339` → `/ 10 = -33.9` ✓
- Privacy guarantee: maximum 11km offset from true location (NFR8, FR35)

### Why `GeolocatorWrapper` — Not `GeolocatorPlatform.instance`

`Geolocator` uses only static methods. The alternative (overriding `GeolocatorPlatform.instance`) requires `MockPlatformInterfaceMixin`, full implementation of every abstract method on `GeolocatorPlatform`, and is fragile across package versions. Injecting a thin `GeolocatorWrapper` interface is consistent with how `Health` is injected in `HealthDataSource` (Story 3.1) and avoids platform-level coupling in tests.

### `Position` Constructor in geolocator ^13.0.2

The `Position` class has a constructor with named parameters. If compilation fails, inspect the actual constructor in the package source:
```bash
flutter pub deps --no-dev | grep geolocator
# Then check: ~/.pub-cache/hosted/pub.dev/geolocator-13.x.x/lib/src/position.dart
```

Required fields: `longitude`, `latitude`, `timestamp`, `accuracy`, `altitude`, `altitudeAccuracy`, `heading`, `headingAccuracy`, `speed`, `speedAccuracy`. All are `double` except `timestamp: DateTime`.

### DI Registration After Refactor

After Task 1, `injection.config.dart` will register:
```dart
gh.factory<GeolocatorWrapper>(() => GeolocatorWrapperImpl());
gh.factory<LocationService>(() => LocationService(gh<GeolocatorWrapper>()));
```

`WeatherRepositoryImpl` injects `LocationService` — no change needed there. The entire chain (`WeatherRepositoryImpl` → `LocationService` → `GeolocatorWrapper`) is resolved by GetIt automatically.

### Existing Tests That Use `LocationService`

`test/data/repositories/weather_repository_impl_test.dart` mocks `LocationService` directly (via `@GenerateMocks([LocationService])`). The refactor (adding `GeolocatorWrapper` constructor parameter) does NOT break these tests — Mockito generates `MockLocationService` which overrides `getCityLevelCoordinates()` without calling the real constructor. **No changes needed to existing weather tests.**

### Files To Change

| File | Action | Reason |
|------|--------|--------|
| `lib/core/utils/geolocator_wrapper.dart` | **Create** | Abstract + concrete wrapper for DI injection |
| `lib/core/utils/location_service.dart` | **Modify** | Inject `GeolocatorWrapper` instead of static `Geolocator` calls |
| `lib/core/di/injection.config.dart` | **Regenerate** | New injectable: `GeolocatorWrapperImpl` |
| `test/core/utils/location_service_test.dart` | **Create** | 7 unit tests |
| `test/core/utils/location_service_test.mocks.dart` | **Generate** | `MockGeolocatorWrapper` via build_runner |

### Files That Must NOT Be Changed

- `weather_repository_impl.dart` — `LocationService` interface is unchanged
- `weather_repository_impl_test.dart` — mocks `LocationService` (not its internals)
- `weather_local_data_source.dart` — stores rounded coordinates passed by repository (AC3 already satisfied by design)
- `weather_cache_table.dart` — schema unchanged
- `injection_test.dart` — smoke test; will pass after build_runner regenerates DI

### AC3 Already Satisfied

"Only rounded coordinates are stored" is already guaranteed by the data flow:
1. `LocationService.getCityLevelCoordinates()` rounds before returning
2. `WeatherRepositoryImpl` passes the rounded `(lat, lon)` directly to `_local.cacheWeather(latitude: lat, longitude: lon, ...)`
3. `WeatherLocalDataSource.cacheWeather()` writes whatever is passed — never sees raw GPS

No changes needed to the storage layer.

### Test Count

Starting: **170 tests** (after Story 4.2)

New tests (Story 4.3):
- `4.3-UNIT-001`: location services disabled → `Left(LocationFailure)`
- `4.3-UNIT-002`: permission denied after re-request → `Left(LocationFailure)`
- `4.3-UNIT-003`: permission permanently denied → `Left(LocationFailure)`
- `4.3-UNIT-004`: success path → `Right` with rounded coordinates (AC1)
- `4.3-UNIT-005`: negative coordinates rounded correctly
- `4.3-UNIT-006`: generic exception from `getCurrentPosition` → `Left(LocationFailure)`
- `4.3-UNIT-007`: verifies `LocationAccuracy.low` is used (NFR8)

Target: **~177 tests** (+7)

Run `flutter test` — ALL tests must pass.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.3]
- [Source: _bmad-output/planning-artifacts/architecture.md#Location Privacy — City-level approximation only]
- [Source: pulse_coach/lib/core/utils/location_service.dart] — existing implementation
- [Source: pulse_coach/lib/core/di/injection.config.dart] — existing DI registrations
- [Source: pulse_coach/test/data/repositories/weather_repository_impl_test.dart] — existing LocationService mock (must not break)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation followed spec exactly. No build errors or test failures encountered.

### Completion Notes List

- Created `GeolocatorWrapper` abstract class + `GeolocatorWrapperImpl` using `@Injectable(as: GeolocatorWrapper)`.
- Refactored `LocationService` to inject `GeolocatorWrapper` via constructor; business logic unchanged.
- Regenerated DI: `injection.config.dart` now registers `GeolocatorWrapperImpl` as `GeolocatorWrapper` (factory) and `LocationService` with `gh<GeolocatorWrapper>()`.
- Created 7 unit tests covering all ACs: service disabled, permission denied, permission denied forever, success + rounding, negative coords, exception, accuracy level.
- All 177 tests pass (170 pre-existing + 7 new). No regressions.

### File List

- `pulse_coach/lib/core/utils/geolocator_wrapper.dart` — Created
- `pulse_coach/lib/core/utils/location_service.dart` — Modified (inject GeolocatorWrapper)
- `pulse_coach/lib/core/di/injection.config.dart` — Regenerated
- `pulse_coach/test/core/utils/location_service_test.dart` — Created
- `pulse_coach/test/core/utils/location_service_test.mocks.dart` — Generated

### Review Findings

- [x] [Review][Patch] Missing test for `denied` → `whileInUse` permission grant flow (first-launch happy path) [test/core/utils/location_service_test.dart] — fixed: added 4.3-UNIT-008
- [x] [Review][Defer] Enum `unableToDetermine` not handled — falls through to `getCurrentPosition` [lib/core/utils/location_service.dart:23-31] — deferred, pre-existing
- [x] [Review][Defer] `on LocationServiceDisabledException` catch is near-dead code with no test [lib/core/utils/location_service.dart:45] — deferred, pre-existing
- [x] [Review][Defer] No timeout on `isLocationServiceEnabled()`, `checkPermission()`, `requestPermission()` calls [lib/core/utils/location_service.dart:18-25] — deferred, pre-existing
- [x] [Review][Defer] `catch (e)` swallows all exceptions including programmer errors [lib/core/utils/location_service.dart:47] — deferred, pre-existing
- [x] [Review][Defer] Cache-hit path ignores location change within TTL window [weather_repository_impl.dart] — deferred, pre-existing (Story 4.2)

## Change Log

- 2026-04-07: Story created by SM agent. LocationService implementation already exists from Stories 4.1/4.2; story focuses on GeolocatorWrapper abstraction for testability and unit test suite.
- 2026-04-07: Implemented by dev agent. GeolocatorWrapper created, LocationService refactored, DI regenerated, 7 unit tests added. All 177 tests pass.
