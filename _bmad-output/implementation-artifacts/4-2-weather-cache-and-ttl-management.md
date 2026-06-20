# Story 4.2: Weather Cache & TTL Management

Status: done

## Story

As the system,
I want weather and AQI data to be cached with a 1-hour TTL,
So that users receive plan generation in < 500ms even when offline.

## Acceptance Criteria

1. **Given** weather data exists in `weather_cache` and `cachedAt` is within 1 hour
   **When** the `WeatherRepository` is queried
   **Then** cached data is returned immediately without a network call (NFR5, NFR14)

2. **Given** the cache is stale (> 1 hour old) and the API is reachable
   **When** the `WeatherRepository` is queried
   **Then** fresh data is fetched, persisted to cache, and returned

3. **Given** the cache is stale and the API is unreachable
   **When** the `WeatherRepository` is queried
   **Then** stale cached data is returned — sessions default to indoor if AQI data is stale > 2 hours (FR36, NFR19)

4. **Given** fresh data is fetched and cached
   **When** measured against NFR5
   **Then** subsequent offline reads return in < 500ms (verified by confirming no network call is made when cache is valid)

## Tasks / Subtasks

- [x] Task 1: Add TTL logic to `WeatherRepositoryImpl.getWeatherContext()` (AC: 1, 2, 3)
  - [x] 1.1 Replace the current "always fetch fresh" flow with a cache-first TTL strategy:
    ```dart
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

      // Step 2: Check cache TTL — return immediately if valid (< 1 hour)
      WeatherContext? cached;
      try {
        cached = await _local.getCachedWeather();
      } on CacheException {
        cached = null; // DB read failure is non-fatal — fall through to network
      }

      if (cached != null && _isCacheValid(cached.cachedAt)) {
        return Right(cached); // AC1: valid cache hit — no network call
      }

      // Step 3: Cache is stale or missing — fetch from network
      try {
        final (weather, aqi) = await _remote.fetchWeatherAndAqi(
          latitude: lat,
          longitude: lon,
        );

        final now = DateTime.now().toUtc();

        await _local.cacheWeather(
          latitude: lat,
          longitude: lon,
          temperature: weather.temperature,
          precipitationProbability: weather.precipitationProbability,
          aqiValue: aqi.europeanAqi,
          cachedAt: now,
        );

        return Right(WeatherContext(
          temperature: weather.temperature,
          precipitationProbability: weather.precipitationProbability,
          aqiValue: aqi.europeanAqi,
          cachedAt: now,
        )); // AC2: fresh data fetched and cached
      } on ServerException {
        // AC3: API unreachable — return stale cache if available
        if (cached != null) {
          return Right(cached); // stale data returned; Story 5.1 checks cachedAt age
        }
        return Left(ServerFailure('Weather unavailable and no cached data'));
      } on CacheException catch (e) {
        return Left(ServerFailure('Cache write failed: ${e.message}'));
      }
    }

    /// Cache is valid when fetched less than 1 hour ago.
    bool _isCacheValid(DateTime cachedAt) =>
        DateTime.now().toUtc().difference(cachedAt) < const Duration(hours: 1);
    ```
  - [x] **TTL constants** — use `Duration(hours: 1)` inline; do NOT add a named constant to `AppConstants` (this is repository-internal logic, not app-wide)
  - [x] **Stale fallback strategy** — when returning stale data (AC3), the `WeatherContext.cachedAt` is the original fetch time. Story 5.1's `StateVector` builder reads `cachedAt` and applies the 2-hour rule for indoor forcing. **No changes needed to `WeatherContext` entity** — `cachedAt` is already present.
  - [x] **Do NOT call `locationService` when cache is valid** — for maximum performance (AC4), location resolution is still needed to determine which cache entry is relevant. But since the table stores a single logical cache entry (city-level, 1 entry), the location is always fetched first. This matches the existing flow.
  - [x] **`CacheException` on read** is non-fatal — treat as cache miss and fall through to network. This prevents DB errors from blocking the user.

- [x] Task 2: Fix unbounded `weather_cache` table growth (deferred from Story 4.1 review) (AC: 1, 2)
  - [x] 2.1 Add atomic replace method to `WeatherCacheDao` (`lib/core/database/daos/weather_cache_dao.dart`):
    ```dart
    /// Atomically clears all cached rows and inserts the new entry.
    /// Uses a transaction so there is never a moment with zero cached rows.
    Future<void> replaceCache(WeatherCacheCompanion entry) =>
        transaction(() async {
          await delete(weatherCache).go();
          await into(weatherCache).insert(entry);
        });
    ```
  - [x] 2.2 Update `WeatherLocalDataSource.cacheWeather()` to call `replaceCache` instead of `insertOrReplace`:
    ```dart
    Future<void> cacheWeather({...}) async {
      try {
        await _dao.replaceCache(
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
    ```
  - [x] **Do NOT modify `weather_cache_table.dart`** — schema unchanged, no migration needed
  - [x] **`insertOrReplace` remains in DAO** — used by the existing unit tests from Story 4.1; removing it would break tests

- [x] Task 3: Write unit tests (AC: 1, 2, 3, 4)
  - [x] 3.1 Add TTL tests to `test/data/repositories/weather_repository_impl_test.dart` (extend existing file):
    ```dart
    // Additional mock needed:
    // @GenerateMocks([WeatherRemoteDataSource, WeatherLocalDataSource, LocationService])
    // already declared in this file from Story 4.1 — no @GenerateMocks change needed
    ```
    Tests:
    - `4.2-UNIT-001`: fresh cache (< 1h old) → `Right(cachedContext)` returned, `fetchWeatherAndAqi` NOT called
      - Mock location: `Right((48.8, 2.3))`
      - Mock `getCachedWeather()`: returns `WeatherContext(cachedAt: DateTime.now().toUtc().subtract(Duration(minutes: 30)), ...)`
      - Verify: result is `Right`, `verifyNever(remote.fetchWeatherAndAqi(...))`
    - `4.2-UNIT-002`: stale cache (> 1h old), API reachable → fresh data fetched, `cacheWeather` called once, returns fresh context
      - Mock `getCachedWeather()`: returns `WeatherContext(cachedAt: DateTime.now().toUtc().subtract(Duration(hours: 2)), ...)`
      - Mock remote: returns valid weather+aqi
      - Verify: `cacheWeather` called once, result is `Right` with fresh `cachedAt`
    - `4.2-UNIT-003`: no cache, API reachable → fresh data fetched and returned
      - Mock `getCachedWeather()`: returns null
      - Mock remote: returns valid weather+aqi
      - Verify: result is `Right`, `cacheWeather` called once
    - `4.2-UNIT-004`: stale cache, API unreachable → stale context returned (AC3)
      - Mock `getCachedWeather()`: returns stale `WeatherContext` (cachedAt: 3h ago)
      - Mock remote: throws `ServerException('timeout')`
      - Verify: result is `Right(staleContext)`, `cacheWeather` NOT called
    - `4.2-UNIT-005`: no cache, API unreachable → `Left(ServerFailure)` (AC3 boundary)
      - Mock `getCachedWeather()`: returns null
      - Mock remote: throws `ServerException('timeout')`
      - Verify: result is `Left(ServerFailure)`

  - [x] 3.2 Add DAO test for `replaceCache` to `test/core/database/daos/weather_cache_dao_test.dart` (check if file exists; create if not):
    - `4.2-UNIT-006`: `replaceCache` with existing row → exactly 1 row in table after call
      - This test requires an in-memory Drift DB (use `NativeDatabase.memory()` or the pattern from existing DAO tests in the project)
      - **Check how Story 1.4 tests the DAO** before writing — look for existing `*_dao_test.dart` files to copy the setup pattern

  - [x] 3.3 Run `dart run build_runner build --delete-conflicting-outputs` (only if `@GenerateMocks` changed — for `replaceCache` in DAO, no mock regeneration needed)
  - [x] 3.4 Run `flutter test` — starting count: **162 tests**; target: **~168 tests** (+6)

## Dev Notes

### What Story 4.1 Built (Context for This Story)

Story 4.1 created the complete weather feature stack. The `WeatherRepositoryImpl` currently **always fetches from the network** — the comment at line 40 explicitly says "TTL check added in Story 4.2". This story's primary change is modifying that single file.

**Current `WeatherRepositoryImpl.getWeatherContext()` flow (Story 4.1):**
1. Get coordinates
2. Fetch from network (always)
3. Persist to cache
4. Return domain entity

**New flow after Story 4.2:**
1. Get coordinates
2. Read cache → if < 1h old → return immediately (**no network**)
3. If stale/missing → fetch from network
4. If network fails → return stale cache (or Left if no cache)

### TTL Design Decisions

- **1-hour TTL** — defined in epics as the target. `Duration(hours: 1)` is used inline in `_isCacheValid()`. No global constant needed (see anti-pattern rules).
- **2-hour stale threshold** — NOT enforced in the repository. The repository returns stale data as-is; the `cachedAt` timestamp is already in `WeatherContext`. Story 5.1's `StateVector` builder is responsible for reading `cachedAt` and enforcing the "force indoor if stale > 2h" rule (FR36, NFR19). **Do NOT add this logic here.**
- **Single-row cache** — the table is logically a single-slot cache (one weather snapshot for the user's current city). The `getLatestCache()` DAO already returns the most recent row by `cachedAt DESC`. Story 4.2 adds `replaceCache()` to guarantee the table never grows beyond 1 row.

### Cache Miss Scenarios

| Scenario | Cached? | Stale? | API? | Result |
|----------|---------|--------|------|--------|
| First launch | No | — | OK | Fetch + cache + return fresh |
| First launch | No | — | Fails | `Left(ServerFailure)` |
| Within 1h | Yes | No | — | Return cache immediately |
| After 1h | Yes | Yes | OK | Fetch + replace cache + return fresh |
| After 1h | Yes | Yes | Fails | Return stale (cachedAt preserved) |
| After 1h | No (cleared) | — | Fails | `Left(ServerFailure)` |

### Existing Files — Changes Required

| File | Change | Reason |
|------|--------|--------|
| `lib/features/weather/data/repositories/weather_repository_impl.dart` | Rewrite `getWeatherContext()` + add `_isCacheValid()` | Core TTL logic (Task 1) |
| `lib/core/database/daos/weather_cache_dao.dart` | Add `replaceCache()` method | Fix unbounded growth (Task 2) |
| `lib/features/weather/data/datasources/weather_local_data_source.dart` | Update `cacheWeather()` to call `replaceCache` | Fix unbounded growth (Task 2) |

### Files That Must NOT Be Changed

- `weather_cache_table.dart` — schema unchanged, no DB migration needed
- `weather_context.dart` — domain entity unchanged; `cachedAt` already there
- `weather_repository.dart` — interface unchanged
- `get_weather_context.dart` — use case unchanged (thin pass-through)
- `weather_remote_data_source.dart` — network layer unchanged
- `app_database.dart` — no new tables or DAOs
- Any iOS/Android platform files
- `injection.config.dart` — no new injectables, no build_runner run needed
- `failures.dart`, `exceptions.dart` — all needed types exist

### Pattern Precedent — `getCachedWeather()` Already Exists

`WeatherLocalDataSource.getCachedWeather()` was already created in Story 4.1 but **never called** in the repository (repository only wrote to cache). Story 4.2 is the first consumer of this method.

```dart
// Story 4.1 created this — use it directly:
Future<WeatherContext?> getCachedWeather() async { ... }
```

### The `insertOrReplace` Bug (Deferred from Story 4.1 Review)

From Story 4.1 Review Finding (deferred): _"`weather_cache` table grows unbounded — `insertOnConflictUpdate` with autoIncrement PK never replaces"_

Root cause: `insertOnConflictUpdate` only replaces when a UNIQUE constraint is violated. With `autoIncrement()` PK, every insert has a new unique ID — so conflict never occurs, and the table accumulates rows forever.

Fix: `replaceCache()` transaction in the DAO — atomically deletes all rows then inserts one. `getLatestCache()` still works correctly (only row = latest).

### Test Setup Pattern — In-Memory Drift DB

For the DAO test (`4.2-UNIT-006`), check the existing pattern used in Epic 1 DAO tests. Look for files matching `test/core/database/daos/*_dao_test.dart`. The pattern should be:

```dart
// Typical Drift in-memory test setup (verify actual file before copying):
late AppDatabase db;
late WeatherCacheDao dao;

setUp(() {
  db = AppDatabase(NativeDatabase.memory());
  dao = db.weatherCacheDao;
});

tearDown(() async => db.close());
```

If no DAO tests exist in the project (Story 1.4 may have skipped them), skip `4.2-UNIT-006` and only write the repository tests (5 tests, target ~167).

### Test Count

Starting: **162 tests** (after Story 4.1)

New tests (Story 4.2):
- `4.2-UNIT-001..005`: `WeatherRepositoryImpl` TTL scenarios (5 tests)
- `4.2-UNIT-006`: `WeatherCacheDao.replaceCache` (1 test — if DAO test infrastructure exists)

Target: **~167–168 tests** (+5–6)

Run `flutter test` — ALL tests must pass.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.2]
- [Source: _bmad-output/planning-artifacts/architecture.md#API Caching — Drift tables with cachedAt timestamp]
- [Source: _bmad-output/planning-artifacts/architecture.md#Graceful Degradation Pattern]
- [Source: _bmad-output/implementation-artifacts/4-1-open-meteo-api-integration.md#Review Findings — unbounded table growth]
- [Source: _bmad-output/implementation-artifacts/4-1-open-meteo-api-integration.md#Task 10 — WeatherRepositoryImpl comment "TTL check added in Story 4.2"]
- [Source: pulse_coach/lib/features/weather/data/repositories/weather_repository_impl.dart]
- [Source: pulse_coach/lib/core/database/daos/weather_cache_dao.dart]
- [Source: pulse_coach/lib/features/weather/data/datasources/weather_local_data_source.dart]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — implementation proceeded without blockers.

### Completion Notes List

- Task 1: Rewrote `WeatherRepositoryImpl.getWeatherContext()` with cache-first TTL strategy. Added `_isCacheValid()` private method using `Duration(hours: 1)` inline. Stale-data fallback (AC3) returns original `WeatherContext` with preserved `cachedAt`. `CacheException` on read is non-fatal (treated as cache miss). All 5 AC scenarios covered.
- Task 2: Added `replaceCache()` transactional method to `WeatherCacheDao` — atomically deletes all rows then inserts one, guaranteeing ≤1 row. Updated `WeatherLocalDataSource.cacheWeather()` to call `replaceCache` instead of `insertOrReplace`. `insertOrReplace` retained in DAO (used by Story 4.1 tests).
- Task 3: Added 5 TTL tests (4.2-UNIT-001..005) to `weather_repository_impl_test.dart`. Updated 4 existing 4.1 tests to stub `getCachedWeather()` (now called by the new flow). Created `test/core/database/daos/weather_cache_dao_test.dart` with 1 DAO test (4.2-UNIT-006) using in-memory Drift DB. Final count: 162 → 169 tests, all green.

### File List

- `pulse_coach/lib/features/weather/data/repositories/weather_repository_impl.dart` (modified)
- `pulse_coach/lib/core/database/daos/weather_cache_dao.dart` (modified)
- `pulse_coach/lib/features/weather/data/datasources/weather_local_data_source.dart` (modified)
- `pulse_coach/test/data/repositories/weather_repository_impl_test.dart` (modified)
- `pulse_coach/test/core/database/daos/weather_cache_dao_test.dart` (created)

### Review Findings

- [x] [Review][Defer] AC3: 2h AQI indoor-default logic not implemented — deferred to Story 5.1. Indoor-forcing on stale AQI > 2h belongs to StateVector builder, not repository. Repository correctly returns stale data with cachedAt intact as input for 5.1. Comment at line 70 documents intent.
- [x] [Review][Patch] ServerException message lost — restored `catch (e)` binding, returns `e.message` [weather_repository_impl.dart:67] ✓ fixed
- [x] [Review][Patch] replaceCache doc comment overstates atomicity — reworded to accurate description [weather_cache_dao.dart:23] ✓ fixed
- [x] [Review][Patch] Cache write failure discards fresh data — restructured to build WeatherContext before cache write; CacheException now non-fatal [weather_repository_impl.dart:44-82] ✓ fixed
- [x] [Review][Patch] Missing test for CacheException from getCachedWeather — added 4.2-UNIT-007, updated 4.1-UNIT-006b expectation [weather_repository_impl_test.dart] ✓ fixed
- [x] [Review][Defer] Cache served for wrong location after user moves — no lat/lon comparison between cached and current coordinates [weather_repository_impl.dart:39] — deferred, pre-existing design trade-off (single-entry cache per spec)
- [x] [Review][Defer] DateTime.now() in _isCacheValid — no clock injection [weather_repository_impl.dart:79] — deferred, pre-existing architectural pattern
- [x] [Review][Defer] Drift DateTime UTC round-trip inconsistency — isUtc flag differs between fresh fetch and DB read [weather_local_data_source.dart:23] — deferred, pre-existing

## Change Log

- 2026-04-06: Implemented Story 4.2 — Weather Cache & TTL Management. Replaced always-fetch strategy with cache-first 1-hour TTL; added atomic `replaceCache()` DAO method to fix unbounded table growth; added 7 new tests (5 repository TTL scenarios + 1 DAO test + updated 4 existing tests for new flow). All 169 tests pass.
