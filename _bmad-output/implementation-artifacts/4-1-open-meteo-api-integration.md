# Story 4.1: Open-Meteo API Integration

Status: done

## Story

As the system,
I want to fetch real-time weather (temperature, precipitation) and AQI data from Open-Meteo,
So that the AI engine can route sessions appropriately based on outdoor conditions.

## Acceptance Criteria

1. **Given** the user's approximate city-level location is available (no precise GPS)
   **When** the `WeatherRepository` calls Open-Meteo
   **Then** temperature, precipitation probability, and AQI are returned and persisted to `weather_cache` table with `cachedAt` timestamp (FR33, FR34, NFR8)

2. **Given** the API is called
   **When** the request is made
   **Then** the request includes only city-level coordinates (rounded to 1 decimal place) — no precise GPS coordinates are sent (FR35, NFR8)

3. **Given** AQI is above threshold (≥ 100 — unhealthy for sensitive groups)
   **When** the `StateVector` is built (Story 5.1)
   **Then** the `aqiLevel` field is marked as `high` and sessions are constrained to indoor (FR8) — **this story exposes `aqiValue` as int; Story 5.1 classifies it**

4. **Given** the Open-Meteo API returns an error
   **When** the repository handles the failure
   **Then** it returns `Left(ServerFailure)` — no exception propagates and the UI does not show an error (ARCH8, ARCH9)

## Tasks / Subtasks

- [x] Task 1: Add Open-Meteo URLs to `ApiConstants` (AC: 1, 2)
  - [x] 1.1 Edit `lib/core/constants/api_constants.dart`:
    ```dart
    class ApiConstants {
      // Open-Meteo Weather Forecast API (Story 4.1)
      static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';
      // Open-Meteo Air Quality API (Story 4.1)
      static const String openMeteoAqiUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
      // ExerciseDB API (Story 6.1)
    }
    ```
  - [x] No auth keys needed — Open-Meteo is a completely free API, no registration or API key required

- [x] Task 2: Add platform location permissions (AC: 2)
  - [x] 2.1 iOS — add to `ios/Runner/Info.plist` (geolocator 13.x requires this key):
    ```xml
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>PulseCoach uses your approximate city-level location to provide weather-adjusted workout recommendations.</string>
    ```
  - [x] 2.2 Android — add to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`, before `<application>`):
    ```xml
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    ```
    **Use ACCESS_COARSE_LOCATION only** — city-level precision is all we need and this avoids the stricter permission UX of ACCESS_FINE_LOCATION (NFR8)
  - [x] **Do NOT add ACCESS_FINE_LOCATION or ACCESS_BACKGROUND_LOCATION** — privacy constraint (NFR8, FR35)

- [x] Task 3: Create `LocationService` (AC: 2)
  - [x] 3.1 Create `lib/core/utils/location_service.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:geolocator/geolocator.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/exceptions.dart';
    import 'package:pulse_coach/core/error/failures.dart';

    /// Returns city-level coordinates (rounded to 1 decimal place, ~11km precision).
    /// Returns [LocationFailure] if permission is denied or location unavailable.
    /// Never returns precise GPS coordinates — privacy constraint NFR8.
    @injectable
    class LocationService {
      Future<Either<Failure, (double lat, double lon)>> getCityLevelCoordinates() async {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            return Left(LocationFailure('Location services are disabled'));
          }

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              return Left(LocationFailure('Location permission denied'));
            }
          }
          if (permission == LocationPermission.deniedForever) {
            return Left(LocationFailure('Location permission permanently denied'));
          }

          final position = await Geolocator.getCurrentPosition(
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

      double _roundCityLevel(double coord) =>
          (coord * 10).round() / 10;
    }
    ```
  - [x] **Return type is `(double, double)` record** — Dart 3 record, no need for a custom class
  - [x] **`LocationAccuracy.low`** is appropriate for city-level; avoids GPS hardware activation that ACCESS_FINE_LOCATION would require
  - [x] **Do NOT store raw coordinates** anywhere — only pass rounded values to API and DB

- [x] Task 4: Create `WeatherContext` domain entity (AC: 1, 3)
  - [x] 4.1 Create `lib/features/weather/domain/entities/weather_context.dart`:
    ```dart
    /// Immutable snapshot of current weather and air quality conditions.
    /// Used by StateVector (Story 5.1) to drive session routing decisions.
    ///
    /// [aqiValue] is raw AQI (european_aqi from Open-Meteo). Story 5.1 applies
    /// the threshold (≥ 100 = high, blocks outdoor sessions per FR8).
    ///
    /// Plain class — NOT freezed. No copyWith or JSON serialization needed at
    /// domain level; DTOs handle serialization in the data layer.
    class WeatherContext {
      final double temperature;              // °C, from Open-Meteo current.temperature_2m
      final double precipitationProbability; // 0–100%, from Open-Meteo hourly[0]
      final int aqiValue;                    // European AQI from air-quality API
      final DateTime cachedAt;               // when this snapshot was fetched

      const WeatherContext({
        required this.temperature,
        required this.precipitationProbability,
        required this.aqiValue,
        required this.cachedAt,
      });

      /// True when AQI meets the "unhealthy for sensitive groups" threshold (FR8).
      /// Story 5.1 uses this to constrain session routing to indoor only.
      bool get isAqiHigh => aqiValue >= 100;
    }
    ```
  - [x] **Plain class — NOT freezed** — same rationale as `SensorContext` in 3.3: transient runtime snapshot, no copyWith needed
  - [x] **`isAqiHigh` getter** pre-computes the threshold so Story 5.1 doesn't repeat the magic number `100`

- [x] Task 5: Create `WeatherRepository` interface (AC: 1, 4)
  - [x] 5.1 Create `lib/features/weather/domain/repositories/weather_repository.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';

    abstract class WeatherRepository {
      /// Fetches current weather and AQI, persists to cache, returns domain entity.
      /// Returns [Left(ServerFailure)] if API call fails.
      /// Returns [Left(LocationFailure)] if coordinates are unavailable.
      Future<Either<Failure, WeatherContext>> getWeatherContext();
    }
    ```

- [x] Task 6: Create `GetWeatherContext` use case (AC: 1, 4)
  - [x] 6.1 Create `lib/features/weather/domain/usecases/get_weather_context.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';
    import 'package:pulse_coach/features/weather/domain/repositories/weather_repository.dart';

    @injectable
    class GetWeatherContext {
      GetWeatherContext(this._repository);
      final WeatherRepository _repository;

      Future<Either<Failure, WeatherContext>> call() => _repository.getWeatherContext();
    }
    ```
  - [x] Thin pass-through use case — repository has all logic; use case is needed for DI and testability pattern

- [x] Task 7: Create data models (DTOs) (AC: 1)
  - [x] 7.1 Create `lib/features/weather/data/models/weather_model.dart`:
    ```dart
    /// DTO for Open-Meteo Forecast API response.
    /// Custom fromJson — NOT json_serializable — because the API nests data under
    /// 'current' and 'hourly' keys, making generated code verbose and fragile.
    class WeatherModel {
      final double temperature;
      final double precipitationProbability;

      const WeatherModel({
        required this.temperature,
        required this.precipitationProbability,
      });

      /// Parses the full Open-Meteo forecast response:
      /// {
      ///   "current": { "temperature_2m": 18.5 },
      ///   "hourly": { "precipitation_probability": [20, 30, ...] }
      /// }
      /// precipitation_probability is NOT available under 'current' — must use hourly[0]
      factory WeatherModel.fromJson(Map<String, dynamic> json) {
        final current = json['current'] as Map<String, dynamic>;
        final hourly = json['hourly'] as Map<String, dynamic>;
        final precipList = (hourly['precipitation_probability'] as List<dynamic>)
            .cast<int>();
        return WeatherModel(
          temperature: (current['temperature_2m'] as num).toDouble(),
          precipitationProbability: precipList.isNotEmpty
              ? precipList[0].toDouble()
              : 0.0,
        );
      }
    }
    ```
  - [ ] 7.2 Create `lib/features/weather/data/models/aqi_model.dart`:
    ```dart
    /// DTO for Open-Meteo Air Quality API response.
    /// Custom fromJson — same reasoning as WeatherModel (nested 'current' key).
    class AqiModel {
      final int europeanAqi;

      const AqiModel({required this.europeanAqi});

      /// Parses the full Open-Meteo air-quality response:
      /// { "current": { "european_aqi": 45 } }
      factory AqiModel.fromJson(Map<String, dynamic> json) {
        final current = json['current'] as Map<String, dynamic>;
        return AqiModel(
          europeanAqi: (current['european_aqi'] as num).toInt(),
        );
      }
    }
    ```
  - [x] **Custom `fromJson` only** — no `toJson`, no `json_serializable` annotations, no `part` directives — these DTOs are read-only parse helpers

- [x] Task 8: Create `WeatherRemoteDataSource` (AC: 1, 2)
  - [x] 8.1 Create `lib/features/weather/data/datasources/weather_remote_data_source.dart`:
    ```dart
    import 'package:dio/dio.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/constants/api_constants.dart';
    import 'package:pulse_coach/core/error/exceptions.dart';
    import 'package:pulse_coach/features/weather/data/models/aqi_model.dart';
    import 'package:pulse_coach/features/weather/data/models/weather_model.dart';

    @injectable
    class WeatherRemoteDataSource {
      WeatherRemoteDataSource(this._dio);
      final Dio _dio;

      /// Fetches weather forecast and AQI in parallel (two independent API calls).
      /// Throws [ServerException] on any network error or unexpected response.
      Future<(WeatherModel weather, AqiModel aqi)> fetchWeatherAndAqi({
        required double latitude,
        required double longitude,
      }) async {
        try {
          final weatherFuture = _dio.get(
            ApiConstants.openMeteoBaseUrl,
            queryParameters: {
              'latitude': latitude,
              'longitude': longitude,
              'current': 'temperature_2m',
              'hourly': 'precipitation_probability',
              'forecast_days': 1,
              'timezone': 'auto',
            },
          );
          final aqiFuture = _dio.get(
            ApiConstants.openMeteoAqiUrl,
            queryParameters: {
              'latitude': latitude,
              'longitude': longitude,
              'current': 'european_aqi',
            },
          );

          // Parallel network calls — both are independent
          final weatherResponse = await weatherFuture;
          final aqiResponse = await aqiFuture;

          final weather = WeatherModel.fromJson(
            weatherResponse.data as Map<String, dynamic>,
          );
          final aqi = AqiModel.fromJson(
            aqiResponse.data as Map<String, dynamic>,
          );
          return (weather, aqi);
        } on DioException catch (e) {
          throw ServerException('Open-Meteo request failed: ${e.message}');
        } catch (e) {
          throw ServerException('Unexpected error fetching weather: $e');
        }
      }
    }
    ```
  - [x] **Parallel API calls** — launch both futures before awaiting either; saves latency (~200–500ms per call)
  - [x] **Separate await pattern** (not `Future.wait`) — preserves static types, same principle as `GetSensorContext` in Story 3.3
  - [x] **DioException** — catch specifically; Dio wraps all HTTP errors (4xx, 5xx, timeouts) in `DioException`
  - [x] **Return type is record** `(WeatherModel, AqiModel)` — Dart 3 record, no intermediate class needed

- [x] Task 9: Create `WeatherLocalDataSource` (AC: 1)
  - [x] 9.1 Create `lib/features/weather/data/datasources/weather_local_data_source.dart`:
    ```dart
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/database/app_database.dart';
    import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart';
    import 'package:pulse_coach/core/database/tables/weather_cache_table.dart';
    import 'package:pulse_coach/core/error/exceptions.dart';
    import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';

    @injectable
    class WeatherLocalDataSource {
      WeatherLocalDataSource(this._dao);
      final WeatherCacheDao _dao;

      /// Reads latest cached entry. Returns null if no cache exists.
      /// Throws [CacheException] on DB error.
      Future<WeatherContext?> getCachedWeather() async {
        try {
          final row = await _dao.getLatestCache();
          if (row == null) return null;
          return WeatherContext(
            temperature: row.temperature,
            precipitationProbability: row.precipitationProbability,
            aqiValue: row.aqiValue,
            cachedAt: row.cachedAt,
          );
        } catch (e) {
          throw CacheException('Failed to read weather cache: $e');
        }
      }

      /// Persists weather snapshot to drift cache table.
      /// Throws [CacheException] on DB error.
      Future<void> cacheWeather({
        required double latitude,
        required double longitude,
        required double temperature,
        required double precipitationProbability,
        required int aqiValue,
        required DateTime cachedAt,
      }) async {
        try {
          await _dao.insertOrReplace(
            WeatherCacheCompanion.insert(
              latitude: latitude,
              longitude: longitude,
              temperature: temperature,
              precipitationProbability: precipitationProbability,
              aqiValue: aqiValue,
              cachedAt: cachedAt,
            ),
          );
        } catch (e) {
          throw CacheException('Failed to write weather cache: $e');
        }
      }
    }
    ```
  - [x] **Uses existing `WeatherCacheDao`** — do NOT create a new DAO; `WeatherCacheDao` is already generated in Story 1.4 and registered in `AppDatabase`
  - [x] **`WeatherCacheDao` API**: `getLatestCache()` → `WeatherCacheData?`, `insertOrReplace(WeatherCacheCompanion)` → `int`
  - [x] **`WeatherCacheData` fields** (from `weather_cache_table.dart`): `id`, `latitude`, `longitude`, `temperature`, `precipitationProbability`, `aqiValue`, `cachedAt`

- [x] Task 10: Create `WeatherRepositoryImpl` (AC: 1, 2, 4)
  - [x] 10.1 Create `lib/features/weather/data/repositories/weather_repository_impl.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/exceptions.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/core/utils/location_service.dart';
    import 'package:pulse_coach/features/weather/data/datasources/weather_local_data_source.dart';
    import 'package:pulse_coach/features/weather/data/datasources/weather_remote_data_source.dart';
    import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';
    import 'package:pulse_coach/features/weather/domain/repositories/weather_repository.dart';

    @Injectable(as: WeatherRepository)
    class WeatherRepositoryImpl implements WeatherRepository {
      WeatherRepositoryImpl(
        this._remote,
        this._local,
        this._locationService,
      );

      final WeatherRemoteDataSource _remote;
      final WeatherLocalDataSource _local;
      final LocationService _locationService;

      @override
      Future<Either<Failure, WeatherContext>> getWeatherContext() async {
        // Step 1: Get city-level coordinates
        final locationResult = await _locationService.getCityLevelCoordinates();
        if (locationResult.isLeft()) {
          return locationResult.fold(
            (failure) => Left(failure),
            (_) => throw StateError('unreachable'),
          );
        }
        final (lat, lon) = locationResult.getOrElse(() => throw StateError('unreachable'));

        try {
          // Step 2: Fetch from both Open-Meteo APIs in parallel
          final (weather, aqi) = await _remote.fetchWeatherAndAqi(
            latitude: lat,
            longitude: lon,
          );

          final now = DateTime.now().toUtc();

          // Step 3: Persist to drift cache (TTL check added in Story 4.2)
          await _local.cacheWeather(
            latitude: lat,
            longitude: lon,
            temperature: weather.temperature,
            precipitationProbability: weather.precipitationProbability,
            aqiValue: aqi.europeanAqi,
            cachedAt: now,
          );

          // Step 4: Return domain entity
          return Right(WeatherContext(
            temperature: weather.temperature,
            precipitationProbability: weather.precipitationProbability,
            aqiValue: aqi.europeanAqi,
            cachedAt: now,
          ));
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        } on CacheException catch (e) {
          // Cache write failure is non-fatal — log and return data anyway?
          // No: architecture rule says return Left on any uncacheable failure.
          // Story 4.2 will add stale-cache fallback; for now, propagate.
          return Left(ServerFailure('Cache write failed: ${e.message}'));
        }
      }
    }
    ```
  - [x] **`@Injectable(as: WeatherRepository)`** — registers impl as the interface, same pattern as all other repository impls in this project
  - [x] **No TTL check** in this story — Story 4.2 adds the "return cache if within 1h" optimization. Story 4.1 always fetches fresh.
  - [x] **`locationResult.getOrElse`** pattern for extracting the record from `Right` — use `fold` for cleaner code if preferred
  - [x] **Cache write failure handling** — returning `Left(ServerFailure)` keeps it simple; Story 4.2 can refine to return stale cache on write failure

- [x] Task 11: Register `Dio` in DI module (AC: 1)
  - [x] 11.1 Create `lib/core/di/network_module.dart`:
    ```dart
    import 'package:dio/dio.dart';
    import 'package:injectable/injectable.dart';

    @module
    abstract class NetworkModule {
      /// Shared Dio instance — singleton to reuse connection pools.
      /// Configured with reasonable timeouts for Open-Meteo (free API, no SLA guarantee).
      @singleton
      Dio get dio => Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/json'},
            ),
          );
    }
    ```
  - [x] **`@singleton`** — one `Dio` instance app-wide; shares connection pools, reduces overhead
  - [x] **Do NOT add interceptors for caching** — drift is the cache layer (per ARCH rule); Dio should not cache responses
  - [x] Follow the `HealthModule` pattern: `@module abstract class` with a getter — same code style as `lib/core/di/health_module.dart`

- [x] Task 12: Regenerate DI (AC: 1)
  - [x] 12.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] 12.2 Verify `injection.config.dart` registers:
    - `Dio` as singleton (from `NetworkModule`)
    - `WeatherRemoteDataSource` as factory
    - `WeatherLocalDataSource` as factory
    - `LocationService` as factory
    - `WeatherRepository` → `WeatherRepositoryImpl` as lazy singleton or factory
    - `GetWeatherContext` as factory
  - [x] 12.3 Check that `WeatherCacheDao` is NOT re-registered — it was registered in Story 1.4 via `HealthModule`... wait, actually check `health_module.dart`. It only registers `Health` and `BehavioralStateDao`. **WeatherCacheDao is accessed via `AppDatabase` directly** — check if it's already accessible as `gh<AppDatabase>().weatherCacheDao`. You may need to add `WeatherCacheDao` registration to the existing module or create a new module entry.
    - Add to `lib/core/di/health_module.dart` (or a new `DatabaseModule`):
      ```dart
      @singleton
      WeatherCacheDao weatherCacheDao(AppDatabase db) => db.weatherCacheDao;
      ```
    - Look at how `BehavioralStateDao` is registered in `health_module.dart` — follow that exact pattern

- [x] Task 13: Write tests (AC: 1, 2, 4)
  - [x] 13.1 Create `test/data/datasources/weather_remote_data_source_test.dart`:
    ```dart
    @GenerateMocks([Dio])
    ```
    Tests:
    - `4.1-UNIT-001`: success → returns `(WeatherModel, AqiModel)` with correct field values
      - Mock weather response: `{"current": {"temperature_2m": 22.5}, "hourly": {"precipitation_probability": [40, 50, 30]}}`
      - Mock AQI response: `{"current": {"european_aqi": 45}}`
      - Verify: `weather.temperature == 22.5`, `weather.precipitationProbability == 40.0`, `aqi.europeanAqi == 45`
    - `4.1-UNIT-002`: DioException on weather call → throws `ServerException`
      - Mock: weather GET throws `DioException`
      - Verify: `expect(() => remote.fetchWeatherAndAqi(...), throwsA(isA<ServerException>()))`
    - `4.1-UNIT-003`: AQI above threshold (europeanAqi = 120) → parsed correctly
      - Mock AQI response: `{"current": {"european_aqi": 120}}`
      - Verify: `aqi.europeanAqi == 120` (threshold classification is in WeatherContext.isAqiHigh, not here)
  
  - [x] 13.2 Create `test/data/repositories/weather_repository_impl_test.dart`:
    ```dart
    @GenerateMocks([WeatherRemoteDataSource, WeatherLocalDataSource, LocationService])
    ```
    Tests:
    - `4.1-UNIT-004`: location available + API succeeds → `Right(WeatherContext)`, cacheWeather called once
      - Mock location: `Right((48.8, 2.3))`
      - Mock remote: returns `(WeatherModel(temp: 20.0, precip: 30.0), AqiModel(aqi: 50))`
      - Mock local.cacheWeather: completes normally
      - Verify: result is `Right`, context has correct fields, `verify(local.cacheWeather(...)).called(1)`
    - `4.1-UNIT-005`: location denied → `Left(LocationFailure)`, remote NOT called
      - Mock location: `Left(LocationFailure('Permission denied'))`
      - Verify: result is `Left(LocationFailure)`, `verifyNever(remote.fetchWeatherAndAqi(...))`
    - `4.1-UNIT-006`: location available, API throws ServerException → `Left(ServerFailure)`
      - Mock location: `Right((48.8, 2.3))`
      - Mock remote: throws `ServerException('timeout')`
      - Verify: result is `Left(ServerFailure)`, `verifyNever(local.cacheWeather(...))`
    - `4.1-UNIT-007`: AQI = 110 (high threshold) → `WeatherContext.isAqiHigh == true`
      - Mock location + remote: AQI = 110
      - Verify: `context.isAqiHigh == true`

  - [x] 13.3 Create `test/domain/usecases/get_weather_context_test.dart`:
    ```dart
    @GenerateMocks([WeatherRepository])
    ```
    Tests:
    - `4.1-UNIT-008`: repo returns Right → use case returns Right (pass-through verified)
    - `4.1-UNIT-009`: repo returns Left(ServerFailure) → use case returns Left (pass-through verified)
  
  - [x] 13.4 Run `dart run build_runner build --delete-conflicting-outputs` to generate mocks
  - [x] 13.5 Run `flutter test` — starting count: **153 tests**; target: **~162 tests** (+9)

### Review Findings

- [x] [Review][Patch] `.cast<int>()` on `precipitation_probability` list may crash at runtime — fixed: safe `num` cast with null handling [`weather_model.dart:22`]
- [x] [Review][Patch] Missing test for `CacheException` path in `WeatherRepositoryImpl` — fixed: added test 4.1-UNIT-006b [`weather_repository_impl_test.dart`]
- [x] [Review][Patch] Unhandled second future error in parallel HTTP calls — fixed: replaced separate awaits with `Future.wait(eagerError: true)` [`weather_remote_data_source.dart`]
- [x] [Review][Defer] Singleton `Dio` shared globally — no isolation between APIs [`network_module.dart`] — deferred, becomes relevant with ExerciseDB API (Story 6.1)
- [x] [Review][Defer] `requestPermission()` called from data layer instead of presentation [`location_service.dart:23`] — deferred, no weather UI yet
- [x] [Review][Defer] `weather_cache` table grows unbounded — `insertOnConflictUpdate` with autoIncrement PK never replaces [`weather_cache_dao.dart`] — deferred, Story 4.2 TTL management

## Dev Notes

### Epic 4 Overview — What This Story Enables

Epic 4 builds the environmental context layer:
- **Story 4.1 (this):** Full weather feature stack — remote fetch, local cache, entity, use case, location service
- **Story 4.2:** TTL management — adds "return cached data if < 1h old" to `WeatherRepositoryImpl`
- **Story 4.3:** Location permission UX — verifies full geolocator permission lifecycle and privacy constraints

`WeatherContext` will be consumed by Epic 5's `StateVector` (Story 5.1) to enable:
- AQI-based session routing (indoor vs outdoor, FR8)
- Temperature and precipitation adjustments to session intensity
- The `weather/` feature is the sole supplier of environmental data to the AI engine

### Open-Meteo API — No Auth Required

Open-Meteo is a completely free, open API. **No API key**, no registration, no rate limits for reasonable usage.

**Forecast endpoint:** `GET https://api.open-meteo.com/v1/forecast`
```
?latitude=48.8&longitude=2.3
&current=temperature_2m
&hourly=precipitation_probability
&forecast_days=1
&timezone=auto
```
Response:
```json
{
  "current": {
    "time": "2026-04-05T14:00",
    "temperature_2m": 18.5
  },
  "hourly": {
    "time": ["2026-04-05T00:00", "2026-04-05T01:00", ...],
    "precipitation_probability": [10, 15, 20, ...]
  }
}
```
Use `hourly.precipitation_probability[0]` — first value is current hour.
**CRITICAL:** `precipitation_probability` is NOT under `current` in this API — it's hourly only.

**Air Quality endpoint:** `GET https://air-quality-api.open-meteo.com/v1/air-quality`
```
?latitude=48.8&longitude=2.3
&current=european_aqi
```
Response:
```json
{
  "current": {
    "time": "2026-04-05T14:00",
    "european_aqi": 45
  }
}
```
`european_aqi` can be null if data unavailable for the location. Handle with null-coalescing: `(current['european_aqi'] as num?)?.toInt() ?? 0`.

### AQI Threshold — Defined Here, Classified in Story 5.1

Story 4.1 stores raw `aqiValue` (int). The `WeatherContext.isAqiHigh` getter (threshold ≥ 100) is a domain convenience, but the actual session routing based on AQI happens in Epic 5's `StateVector` construction and `SafetyRules` engine.

**Do NOT implement session routing logic in this story** — no `DailyPlanBloc`, no `StateVector`, no `SafetyRules`.

### City-Level Coordinate Rounding

```
48.8523 → 48.9   (round to 1 decimal)
2.3488  → 2.3
```

`(coord * 10).round() / 10` is the formula. Always round BEFORE passing to API and BEFORE storing in DB. Raw GPS coordinates must never appear in network requests or database rows.

### WeatherCacheTable Schema (EXISTING — Story 1.4)

```dart
class WeatherCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get temperature => real()();
  RealColumn get precipitationProbability => real()();
  IntColumn get aqiValue => integer()();
  DateTimeColumn get cachedAt => dateTime()();
}
```

WeatherCacheDao (EXISTING — Story 1.4):
- `getLatestCache()` → `Future<WeatherCacheData?>`
- `insertOrReplace(WeatherCacheCompanion)` → `Future<int>`
- `deleteAll()` → `Future<int>`

**Do NOT modify the table or DAO.** Story 4.2 will use `cachedAt` for TTL checks.

### DI Pattern — `Dio` Registration

`Dio` must be registered via a `@module` class (same pattern as `HealthModule`). Do NOT instantiate Dio directly in the datasource — it must come through DI.

After running `build_runner`, the generated `injection.config.dart` will automatically wire:
```
NetworkModule.dio (Dio singleton)
    ↓
WeatherRemoteDataSource (factory, receives Dio)
    ↓
WeatherRepositoryImpl (factory, receives WeatherRemoteDataSource + WeatherLocalDataSource + LocationService)
    ↓
GetWeatherContext (factory, receives WeatherRepository)
```

Also add `WeatherCacheDao` to `health_module.dart` (or a new module) following the `BehavioralStateDao` pattern:
```dart
@singleton
WeatherCacheDao weatherCacheDao(AppDatabase db) => db.weatherCacheDao;
```
Without this, `WeatherLocalDataSource` cannot receive `WeatherCacheDao` via injection.

### File Structure — ALL New Files

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart              ← MODIFIED (add Open-Meteo URLs)
│   ├── di/
│   │   ├── health_module.dart              ← MODIFIED (add WeatherCacheDao registration)
│   │   ├── network_module.dart             ← NEW (Dio singleton)
│   │   └── injection.config.dart           ← REGENERATED
│   └── utils/
│       └── location_service.dart           ← NEW
│
└── features/
    └── weather/                            ← NEW FEATURE DIRECTORY
        ├── data/
        │   ├── datasources/
        │   │   ├── weather_remote_data_source.dart   ← NEW
        │   │   └── weather_local_data_source.dart    ← NEW
        │   ├── models/
        │   │   ├── weather_model.dart                ← NEW
        │   │   └── aqi_model.dart                    ← NEW
        │   └── repositories/
        │       └── weather_repository_impl.dart      ← NEW
        └── domain/
            ├── entities/
            │   └── weather_context.dart              ← NEW
            ├── repositories/
            │   └── weather_repository.dart           ← NEW
            └── usecases/
                └── get_weather_context.dart          ← NEW

test/
├── data/
│   ├── datasources/
│   │   └── weather_remote_data_source_test.dart      ← NEW
│   └── repositories/
│       └── weather_repository_impl_test.dart         ← NEW
└── domain/
    └── usecases/
        └── get_weather_context_test.dart             ← NEW

ios/Runner/Info.plist                        ← MODIFIED (NSLocationWhenInUseUsageDescription)
android/app/src/main/AndroidManifest.xml    ← MODIFIED (ACCESS_COARSE_LOCATION)
```

**NO CHANGES to:**
- `weather_cache_table.dart`, `weather_cache_dao.dart` (existing, Story 1.4)
- `app_database.dart` (WeatherCache already registered)
- Any presentation layer files (no UI for this epic)
- `AppRouter` (no new routes)
- `failures.dart`, `exceptions.dart` — `ServerFailure`, `LocationFailure`, `ServerException`, `LocationException` all exist
- `SensorContext`, `GetSensorContext` (Epic 3 — do not touch)
- `HealthModule` constructor (only add `weatherCacheDao` getter)

### Existing Symbols — Do NOT Recreate

| Symbol | File | From Story |
|--------|------|-----------|
| `WeatherCache` (Drift table) | `core/database/tables/weather_cache_table.dart` | 1.4 |
| `WeatherCacheDao` | `core/database/daos/weather_cache_dao.dart` | 1.4 |
| `WeatherCacheData` | auto-generated | 1.4 |
| `WeatherCacheCompanion` | auto-generated | 1.4 |
| `ServerFailure` | `core/error/failures.dart` | 1.5 |
| `LocationFailure` | `core/error/failures.dart` | 1.5 |
| `ServerException` | `core/error/exceptions.dart` | 3.1 |
| `CacheException` | `core/error/exceptions.dart` | 1.5 |
| `LocationException` | `core/error/exceptions.dart` | 1.5 |
| `BehavioralStateDao` | (DI registered in `health_module.dart`) | 1.4 |

### Mocking Dio in Tests

`Dio` is not easily mockable with `@GenerateMocks([Dio])` because Dio has complex internals. Instead, mock `WeatherRemoteDataSource` itself in repository tests. For datasource tests, use `mockito` on `Dio`:

```dart
@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late WeatherRemoteDataSource dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = WeatherRemoteDataSource(mockDio);
  });

  test('4.1-UNIT-001: success returns correct WeatherModel and AqiModel', () async {
    when(mockDio.get(
      ApiConstants.openMeteoBaseUrl,
      queryParameters: anyNamed('queryParameters'),
    )).thenAnswer((_) async => Response(
      data: {
        'current': {'temperature_2m': 22.5},
        'hourly': {'precipitation_probability': [40, 50, 30]},
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: ApiConstants.openMeteoBaseUrl),
    ));
    when(mockDio.get(
      ApiConstants.openMeteoAqiUrl,
      queryParameters: anyNamed('queryParameters'),
    )).thenAnswer((_) async => Response(
      data: {'current': {'european_aqi': 45}},
      statusCode: 200,
      requestOptions: RequestOptions(path: ApiConstants.openMeteoAqiUrl),
    ));

    final (weather, aqi) = await dataSource.fetchWeatherAndAqi(
      latitude: 48.8,
      longitude: 2.3,
    );

    expect(weather.temperature, 22.5);
    expect(weather.precipitationProbability, 40.0);
    expect(aqi.europeanAqi, 45);
  });
}
```

### Learnings from Epic 3 (Apply Here)

- **Never throw from use case** — repository absorbs all exceptions and returns `Either`. Use case is a thin pass-through.
- **Parallel futures with separate awaits** — launch both `_dio.get()` futures before first `await` to get parallelism while preserving static types (avoids `Future.wait<dynamic>` cast issues — same lesson as Story 3.3).
- **Try-catch on exception types only** — repository catches `ServerException` and `CacheException`; use case catches nothing.
- **Test both success and failure paths** — always include at minimum: happy path, primary failure (API error), secondary failure (location denied).
- **No try-catch without a reason** — Story 3.3 review (F1) found a missing try-catch that caused a "never fails" contract violation. Ensure `WeatherRepositoryImpl` wraps remote call in try-catch.

### Test Count

Starting: **153 tests** (all passing after Story 3.3)

New tests (Story 4.1):
- `4.1-UNIT-001..003`: `WeatherRemoteDataSource` (3 tests)
- `4.1-UNIT-004..007`: `WeatherRepositoryImpl` (4 tests)
- `4.1-UNIT-008..009`: `GetWeatherContext` (2 tests)

Target: **~162 tests** (+9)

Run `flutter test` — ALL 162 tests must pass before marking story done.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Epic 4, Story 4.1]
- [Source: _bmad-output/planning-artifacts/architecture.md#Technical Stack — Open-Meteo Integration]
- [Source: _bmad-output/planning-artifacts/architecture.md#File Structure — lib/features/weather/]
- [Source: _bmad-output/planning-artifacts/architecture.md#Failure Types]
- [Source: _bmad-output/implementation-artifacts/3-3-rpe-only-fallback-mode.md#Dev Notes]
- [Source: pulse_coach/lib/core/database/tables/weather_cache_table.dart]
- [Source: pulse_coach/lib/core/database/daos/weather_cache_dao.dart]
- [Source: pulse_coach/lib/core/error/failures.dart]
- [Source: pulse_coach/lib/core/error/exceptions.dart]
- [Source: pulse_coach/lib/core/di/health_module.dart]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed `WeatherLocalDataSource` compilation error: `WeatherCacheCompanion` requires import of `package:pulse_coach/core/database/app_database.dart` (generated type lives in `app_database.g.dart`). Added `drift/drift.dart` + `app_database.dart` imports; removed `weather_cache_table.dart` import.

### Completion Notes List

- Task 1: Added `openMeteoBaseUrl` and `openMeteoAqiUrl` constants to `ApiConstants`.
- Task 2: Added `NSLocationWhenInUseUsageDescription` to iOS `Info.plist` and `ACCESS_COARSE_LOCATION` to Android `AndroidManifest.xml`. No fine/background location added (NFR8 compliance).
- Task 3: Created `LocationService` with city-level rounding (`(coord*10).round()/10`), `LocationAccuracy.low`, handles disabled service, denied/deniedForever permission.
- Task 4: Created `WeatherContext` (plain class, not freezed) with `isAqiHigh` getter (threshold ≥ 100).
- Task 5: Created `WeatherRepository` abstract interface.
- Task 6: Created `GetWeatherContext` thin pass-through use case.
- Task 7: Created `WeatherModel.fromJson` (uses `hourly.precipitation_probability[0]`) and `AqiModel.fromJson` (null-safe `european_aqi`).
- Task 8: Created `WeatherRemoteDataSource` with parallel Dio calls (separate-await pattern, not `Future.wait`).
- Task 9: Created `WeatherLocalDataSource` using existing `WeatherCacheDao`.
- Task 10: Created `WeatherRepositoryImpl` — location-first flow, parallel API calls, drift cache persistence, proper `ServerException`/`CacheException` handling.
- Task 11: Created `NetworkModule` with `@singleton Dio` (10s connect, 15s receive timeout).
- Task 12: Added `weatherCacheDao` to `HealthModule`. Ran `build_runner` — all 6 DI registrations verified in `injection.config.dart`.
- Task 13: 9 unit tests (4.1-UNIT-001..009) written and passing. Total: **162 tests** (153 → 162, +9).

### File List

- `pulse_coach/lib/core/constants/api_constants.dart` — MODIFIED (added openMeteoBaseUrl, openMeteoAqiUrl)
- `pulse_coach/lib/core/di/health_module.dart` — MODIFIED (added weatherCacheDao getter)
- `pulse_coach/lib/core/di/network_module.dart` — NEW (Dio singleton)
- `pulse_coach/lib/core/di/injection.config.dart` — REGENERATED
- `pulse_coach/lib/core/utils/location_service.dart` — NEW
- `pulse_coach/lib/features/weather/domain/entities/weather_context.dart` — NEW
- `pulse_coach/lib/features/weather/domain/repositories/weather_repository.dart` — NEW
- `pulse_coach/lib/features/weather/domain/usecases/get_weather_context.dart` — NEW
- `pulse_coach/lib/features/weather/data/models/weather_model.dart` — NEW
- `pulse_coach/lib/features/weather/data/models/aqi_model.dart` — NEW
- `pulse_coach/lib/features/weather/data/datasources/weather_remote_data_source.dart` — NEW
- `pulse_coach/lib/features/weather/data/datasources/weather_local_data_source.dart` — NEW
- `pulse_coach/lib/features/weather/data/repositories/weather_repository_impl.dart` — NEW
- `pulse_coach/ios/Runner/Info.plist` — MODIFIED (NSLocationWhenInUseUsageDescription)
- `pulse_coach/android/app/src/main/AndroidManifest.xml` — MODIFIED (ACCESS_COARSE_LOCATION)
- `pulse_coach/test/data/datasources/weather_remote_data_source_test.dart` — NEW
- `pulse_coach/test/data/datasources/weather_remote_data_source_test.mocks.dart` — GENERATED
- `pulse_coach/test/data/repositories/weather_repository_impl_test.dart` — NEW
- `pulse_coach/test/data/repositories/weather_repository_impl_test.mocks.dart` — GENERATED
- `pulse_coach/test/domain/usecases/get_weather_context_test.dart` — NEW
- `pulse_coach/test/domain/usecases/get_weather_context_test.mocks.dart` — GENERATED

### Review Findings

_TBD_

### Change Log

- 2026-04-05: Story 4.1 implemented — full weather feature stack: LocationService, WeatherContext entity, WeatherRepository interface, GetWeatherContext use case, WeatherModel/AqiModel DTOs, WeatherRemoteDataSource (parallel Dio), WeatherLocalDataSource (drift cache), WeatherRepositoryImpl, NetworkModule (Dio singleton), platform permissions (iOS/Android). 9 unit tests added (162 total). DI regenerated and verified.
