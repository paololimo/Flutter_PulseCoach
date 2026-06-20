# Story 6.1: ExerciseDB API Integration & Cache

Status: done

## Story

As the system,
I want to fetch exercise content from ExerciseDB and cache it in the local database,
so that sessions are populated with real exercise steps and available offline.

## Acceptance Criteria

1. Given the `ExerciseRepository` calls ExerciseDB, when exercises are fetched by session type (`mobility`, `cardio`, `breathing`), then exercise entities containing name, description, steps, duration, difficulty, and indoor/outdoor compatibility are stored in the `exercise_cache` table with `cachedAt`. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.1`]
2. Given cache exists and `cachedAt` is within 24 hours, when the repository is queried, then cached exercises are returned without a network call. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.1`; `_bmad-output/planning-artifacts/prd.md#NFR14`]
3. Given ExerciseDB is unreachable, when the repository is queried, then it falls back to local cache; if cache is empty, it loads `assets/data/fallback_exercises.json`. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.1`; `_bmad-output/planning-artifacts/architecture.md#Graceful Degradation Pattern`]
4. Given the bundled fallback is loaded, when plan generation uses it, then a complete daily plan of 3 sessions is generated and no user-visible error state is shown. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.1`; `_bmad-output/planning-artifacts/ux-design-specification.md#Degraded States`]

## Tasks / Subtasks

- [x] Create the sessions catalog domain contract (AC: 1, 3, 4)
  - [x] Add `pulse_coach/lib/features/sessions_catalog/domain/entities/exercise.dart` as a `freezed` entity with at least: `id`, `name`, `description`, `sessionType`, `steps`, `durationMinutes`, `difficulty`, `indoorCompatible`, `outdoorCompatible`.
  - [x] Use string values already used by the AI engine for `sessionType`: `mobility`, `cardio`, `breathing`. Do not introduce new labels that cannot map to `BanditEngine` arms.
  - [x] Keep the domain layer pure Dart: no Flutter imports and no DTO exposure.
  - [x] Add `ExerciseRepository` with `Future<Either<Failure, List<Exercise>>> getExercisesByType(String sessionType)` and a sync/fetch method if needed by implementation.

- [x] Implement ExerciseDB remote mapping (AC: 1)
  - [x] Add `pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart`.
  - [x] Add `pulse_coach/lib/features/sessions_catalog/data/models/exercise_model.dart`; custom parsing is acceptable because ExerciseDB payloads do not naturally contain PulseCoach-specific `durationMinutes`, `difficulty`, or indoor/outdoor fields.
  - [x] Add ExerciseDB URL constants to `pulse_coach/lib/core/constants/api_constants.dart`; keep ExerciseDB config separate from Open-Meteo.
  - [x] Reuse `dio` but do not add weather-specific assumptions to the shared `NetworkModule`.
  - [x] Map external records into PulseCoach exercises deterministically. ExerciseDB should provide raw exercise content; PulseCoach must derive missing product fields such as `sessionType`, duration, difficulty, and compatibility.

- [x] Implement local cache and fallback data source (AC: 1, 2, 3)
  - [x] Extend `pulse_coach/lib/core/database/daos/exercise_cache_dao.dart` with methods needed to read all cached rows and replace/upsert batches.
  - [x] Prefer the existing schema (`exerciseId`, `exerciseJson`, `cachedAt`) and store serialized PulseCoach exercise JSON in `exerciseJson`. Only change `exercise_cache_table.dart` if filtering in Dart is not sufficient; if the schema changes, increment `AppDatabase.schemaVersion`, add a stepwise migration, and regenerate Drift files.
  - [x] Add `pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart` to read/write cache rows and load `assets/data/fallback_exercises.json`.
  - [x] Ensure cache TTL logic is repository-owned: valid cache is `< 24h`, stale cache is still usable when remote fails, and empty cache plus remote failure loads bundled fallback.

- [x] Implement repository and use cases (AC: 1, 2, 3, 4)
  - [x] Add `pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart` annotated `@Injectable(as: ExerciseRepository)`.
  - [x] Add `get_exercises_by_type.dart` and `sync_exercise_catalog.dart` under `domain/usecases/`.
  - [x] Repository flow must match the established weather pattern: check valid cache first, otherwise try remote, cache fresh data, then fall back to stale cache, then fallback asset.
  - [x] Expected degradation must return `Right(exercises)` when stale cache or fallback asset exists. Do not surface expected network failure as a UI error.

- [x] Integrate enough with plan generation to prove fallback produces a complete 3-session plan (AC: 4)
  - [x] Wire `ExerciseRepository` into `GenerateDailyPlan` only as far as needed for Story 6.1 acceptance: the plan must be able to succeed with fallback catalog data when remote and cache are unavailable.
  - [x] Preserve existing graceful degradation in `GenerateDailyPlan`: sensor/weather failure already defaults safely and must not regress.
  - [x] Close the Epic 5 placeholder gap where practical: `durationMinutes` and `isIndoor` should come from catalog-compatible data, not only from `ContextualBandit._toPlannedSession` placeholders. If full catalog-aware selection is too large, document the remaining Epic 6.2/6.3 handoff explicitly in completion notes.

- [x] Add tests and regenerate code (AC: 1, 2, 3, 4)
  - [x] Add remote datasource tests under `pulse_coach/test/data/datasources/`.
  - [x] Add repository tests under `pulse_coach/test/data/repositories/` covering fresh cache hit, stale cache plus remote success, remote failure plus stale cache, and remote failure plus empty cache loading fallback.
  - [x] Add DAO/local datasource tests using `NativeDatabase.memory()`; do not mock Drift.
  - [x] Add/update `GenerateDailyPlan` tests proving no error is emitted when only fallback exercises are available.
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` after adding freezed/injectable/Drift changes.
  - [x] Run `flutter test` from `pulse_coach/`.

## Dev Notes

### Current Code State

- `pulse_coach/lib/features/sessions_catalog/` currently has only `presentation/pages/sessions_page.dart`; the data and domain layers for this feature do not exist yet.
- `exercise_cache` already exists in Drift with `exerciseId`, `exerciseJson`, and `cachedAt`; `ExerciseCacheDao` currently supports only `getByExerciseId`, `insertOrReplace`, and `deleteAll`.
- `AppDatabase` is at `schemaVersion => 3`; changing table shape requires a version bump and migration. Avoid a schema change unless the implementation truly needs it.
- `ApiConstants` has Open-Meteo constants and a Story 6.1 placeholder for ExerciseDB.
- `NetworkModule` exposes a singleton `Dio` with general timeouts. Epic 4 deferred work warns that API isolation matters when ExerciseDB is added; keep ExerciseDB base URL/config separate even if the same Dio instance is reused.
- `GenerateDailyPlan` currently generates plans from the AI engine without catalog input. `ContextualBandit._toPlannedSession` hardcodes `durationMinutes: 10` and derives `isIndoor` from safety constraints only; deferred work explicitly assigns real indoor/outdoor semantics to Story 6.x.

### Architecture Guardrails

- Follow feature-first Clean Architecture:
  - Domain: pure Dart entities, repository interface, use cases.
  - Data: DTOs, remote/local datasources, repository implementation.
  - Presentation: out of scope except for avoiding regressions in the existing Sessions placeholder.
- Repository methods must return `Either<Failure, T>` and catch data-layer exceptions. Do not throw raw exceptions past the data layer.
- Data layer may throw `ServerException` / `CacheException`; repository maps them to `Failure` only when fallback cannot recover.
- Use `@injectable` / `@singleton` annotations and regenerate `injection.config.dart`; do not manually register dependencies in `get_it`.
- Use package imports (`package:pulse_coach/...`), not relative cross-feature imports.
- No `print()` statements. Use structured failures or `dart:developer` only where existing patterns justify it.

### ExerciseDB Mapping Constraints

- ExerciseDB raw responses are not a complete PulseCoach session model. They may include exercise names, target/body part/equipment, instructions, and media fields, but they do not define PulseCoach `sessionType`, duration, difficulty, or indoor/outdoor compatibility.
- The mapper must derive PulseCoach fields deterministically:
  - `mobility`: bodyweight/stretching/core mobility oriented records.
  - `cardio`: aerobic/high-movement records that can be executed in micro-session format.
  - `breathing`: ExerciseDB may not contain breathing exercises; fallback catalog must cover this category.
  - `durationMinutes`: clamp to the product range of 2-10 minutes.
  - `difficulty`: map to stable app labels or scale used internally; do not invent user-facing copy here.
  - `indoorCompatible`: default true unless the exercise explicitly requires outdoor context.
- If remote data cannot provide a safe category, exclude that record rather than contaminating the cache.

### Fallback Requirements

- `assets/data/fallback_exercises.json` is listed in `pubspec.yaml` via `assets/data/`, but the concrete file does not exist yet.
- Story 6.2 owns the curated 30-exercise fallback catalog, but Story 6.1 AC3/AC4 requires a loadable fallback now. Add a minimal valid fallback sufficient for tests and plan generation, then document that Story 6.2 expands it to the full 10/10/10 catalog.
- Fallback must be indistinguishable from cached API data at the repository/use-case boundary: return `Right<List<Exercise>>`, not a failure.

### Previous Story Intelligence

- Epic 5 retro calls out that Story 5.5 was too dense. Keep this story focused on catalog data, cache, fallback, and the minimum plan-generation integration required by AC4.
- Epic 5 also calls out that catalog data is now the enforcement point for safety constraints. Do not leave `indoorCompatible` or duration as ambiguous placeholders in the new `Exercise` entity.
- Existing test suite baseline was `346/346` passing. `flutter analyze` was not clean and already had 38 issues; do not add new warnings.
- Today, Sessions, and Progress UI are placeholders on-device. Do not claim end-to-end Today UI validation unless the UI is actually wired in a later story.

### Latest Technical Notes

- ExerciseDB has a hosted API option at `https://oss.exercisedb.dev/api/v1/...`; the project architecture requires free public APIs with no secrets for v1, so avoid RapidAPI/key-based integration unless the product direction changes. [Source: ExerciseDB OSS docs, `https://oss.exercisedb.dev/`; AscendAPI ExerciseDB docs, `https://docs.ascendapi.com/products/edb-v1/overview`]
- Treat external ExerciseDB availability and shape as unstable at runtime. The implementation must be resilient to missing optional fields, unexpected nulls, and network failure.

### Required Test Scenarios

- Remote datasource:
  - Success parses raw ExerciseDB records into safe `ExerciseModel` objects.
  - `DioException` maps to `ServerException`.
  - Malformed payload maps to `ServerException` or is filtered predictably; do not allow `TypeError` to escape.
- Local datasource / DAO:
  - Batch cache write followed by read returns all rows.
  - `cachedAt` is preserved and used by repository TTL logic.
  - Fallback JSON loads from `assets/data/fallback_exercises.json`.
- Repository:
  - Valid cache `< 24h` returns cache and never calls remote.
  - Stale cache plus reachable remote returns fresh data and writes cache.
  - Remote failure plus stale cache returns stale cache.
  - Remote failure plus empty cache returns fallback data as `Right`.
  - Missing/invalid fallback with no cache returns `Left(CacheFailure)` or equivalent failure.
- Plan generation:
  - With remote unavailable and empty cache, fallback exercises still allow a 3-session daily plan without user-visible error.

## Project Structure Notes

- Expected new files:
  - `pulse_coach/lib/features/sessions_catalog/domain/entities/exercise.dart`
  - `pulse_coach/lib/features/sessions_catalog/domain/repositories/exercise_repository.dart`
  - `pulse_coach/lib/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart`
  - `pulse_coach/lib/features/sessions_catalog/domain/usecases/sync_exercise_catalog.dart`
  - `pulse_coach/lib/features/sessions_catalog/data/models/exercise_model.dart`
  - `pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart`
  - `pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart`
  - `pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart`
  - `pulse_coach/assets/data/fallback_exercises.json`
- Expected updated files:
  - `pulse_coach/lib/core/constants/api_constants.dart`
  - `pulse_coach/lib/core/database/daos/exercise_cache_dao.dart`
  - `pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart` only if needed for AC4.
  - Generated files after build_runner: `*.freezed.dart`, `*.g.dart`, `injection.config.dart`, and Drift generated files if DAO/table shape changes.

### Review Findings

_Code review 2026-05-15 (Blind Hunter + Edge Case Hunter + Acceptance Auditor)._

- [x] [Review][Patch] Catalog enrichment must not overwrite AI-committed `durationMinutes` — fill-only contract [pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart:121-132]. Resolved from D1 (2026-05-15): AI engine in Story 5.5 sets `durationMinutes` intentionally from profile `availableTime`; catalog must only fill placeholders, not override. Implementation: change `_enrichPlanWithCatalog` to keep `session.durationMinutes` as-is and only borrow `preferred.durationMinutes` when the AI has not committed a value (e.g. when the AI's value equals the Epic 5 placeholder default or when a future contract makes the field nullable). Update test `6.1-UNIT-012` to assert AI durations are preserved.

- [x] [Review][Patch] Empty remote response bypasses stale cache — fix recovery order [pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart:34-72]. If remote returns 200 with `[]` (or zero mappable records), the `on ServerException` branch is skipped, so `_recoverFromFallbacks` never runs and the fallback asset is preferred over a stale (but real) cache. Treat empty mapped result like a server failure and route through `_recoverFromFallbacks`.
- [x] [Review][Patch] Remote fetch issues full-catalog GET per sessionType — wasteful and produces partial cache writes [pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart; pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart:74-96]. `ExerciseDB` returns the whole catalog; the data source filters client-side and `syncCatalog` calls it 3× with no filter on the URL. Add a single `fetchAll()`, dedupe by `exerciseId`, and cache once.
- [x] [Review][Patch] `syncCatalog` hits remote for `breathing` knowing it will return `[]` [exercise_repository_impl.dart:76-83]. Mapper cannot derive `sessionType=='breathing'` from ExerciseDB (per Dev Notes), so the breathing iteration is a guaranteed-empty round-trip. Either skip `breathing` in `syncCatalog`, or refactor to the single `fetchAll()` patch above.
- [x] [Review][Patch] Clock skew / future `cachedAt` keeps cache "fresh" forever [exercise_repository_impl.dart:98-104]. If a row's `cachedAt` is ahead of `DateTime.now().toUtc()` (NTP correction, manual clock change), `difference()` returns a negative duration, which is `< 24h`. Clamp future timestamps to "stale" before the comparison.
- [x] [Review][Patch] One corrupt cached row poisons the entire cache for all session types [pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart:20-35]. `jsonDecode`/`Exercise.fromJson` failure on any single row throws and the whole call returns `CacheException`. Map row-by-row with per-row try/catch; log and skip bad rows.
- [x] [Review][Patch] One malformed fallback record poisons the whole fallback list [exercise_local_data_source.dart loadFallbackExercisesByType]. Same row-by-row mapping fix as above; with only 3 shipped records, a single bad entry kills the whole degraded path.
- [x] [Review][Patch] `_enrichPlanWithCatalog` only ever flips `isIndoor` to `true`, never to `false` [generate_daily_plan.dart:121-132]. `final isIndoor = session.isIndoor || !preferred.outdoorCompatible;` — if AI scheduled indoor but the selected exercise is outdoor-only (`indoorCompatible: false`), the plan keeps `isIndoor: true` and shows an exercise that cannot be performed indoors. Flip both directions, or drop the exercise during selection.
- [x] [Review][Patch] Stale rows never purged across syncs [exercise_repository_impl.dart:74-96]. `insertAllOnConflictUpdate` keeps removed-from-API rows forever; combined with the oldest-`cachedAt` validity rule, a stale survivor can mark the whole bucket stale or serve content removed upstream. In `syncCatalog`, `deleteAll()` before batch insert.
- [x] [Review][Patch] `_enrichPlanWithCatalog` swallows `Left` from catalog silently [generate_daily_plan.dart:121]. `result.fold((_) => session, ...)` — no `developer.log`. When the catalog is offline the enrichment silently no-ops and engineers get no signal. Add a log on the Left arm.
- [x] [Review][Patch] Dead `on ServerException { rethrow; }` clause + stacktrace dropped [pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart]. The branch is unreachable given preceding `on DioException`; the trailing `catch (e)` swallows `st`. Remove the dead branch; capture stack with `catch (e, st)` and pass to `ServerException`.
- [x] [Review][Patch] Test `6.1-UNIT-007` does not assert the returned payload [pulse_coach/test/data/repositories/exercise_repository_impl_test.dart]. Asserts only `result.isRight()` and `verifyNever(...)`; a bug returning `Right([])` would pass. Add a value-level assertion that the cached exercises are returned.
- [x] [Review][Defer] `getCachedExercisesByType` reads all rows and JSON-decodes on every call [exercise_local_data_source.dart:21] — deferred, schema-level optimization belongs to Story 6.2/6.3.
- [x] [Review][Defer] Substring-matching false positives in `_deriveSessionType` / `_deriveCompatibility` (e.g. "running form drill", "pull up" vs "pull-up") [exercise_model.dart] — deferred, curated catalog in Story 6.2 supersedes heuristics.
- [x] [Review][Defer] `_difficultyForIntensity` accepts out-of-range intensity silently [generate_daily_plan.dart] — deferred, pre-existing.
- [x] [Review][Defer] `_buildDescription` interpolates raw API string into user-visible text without sanitization [exercise_model.dart] — deferred, hardening pass.
- [x] [Review][Defer] `developer.log(..., error: e)` for corrupt `BanditState` JSON may include user behavioral data in production logs [generate_daily_plan.dart:263-268] — deferred, pre-existing outside Story 6.1 scope.
- [x] [Review][Defer] Concurrent miss-and-refresh single-flight for `getExercisesByType` across types — deferred, subsumed by the planned single-`fetchAll()` patch.
- [x] [Review][Defer] Fallback `durationMinutes` not clamped at the `Exercise.fromJson` boundary — deferred, author-controlled JSON; revisit when Story 6.2 expands the fallback set.
- [x] [Review][Defer] `exerciseDbBaseUrl` has no env override [api_constants.dart] — deferred, project policy uses compile-time constants for v1.
- [x] [Review][Defer] `_selectExerciseForSession` returns `candidates.first` and is non-deterministic in selection order [generate_daily_plan.dart] — deferred, marginal until Today UI is wired in Epic 7.
- [x] [Review][Defer] Stale cache served indefinitely without freshness signal to UI [exercise_repository_impl.dart:106-125] — deferred, observability work, no UI consumer yet.
- [x] [Review][Defer] Test `6.1-UNIT-006` conflates "no session-type match" with "malformed" [exercise_remote_data_source_test.dart] — deferred, test quality; will revisit with curated mapper in Story 6.2.
- [x] [Review][Defer] Domain `Exercise` carries `toJson`/`fromJson` used as the cache schema [exercise.dart + exercise_local_data_source.dart] — deferred, architectural separation between domain entity and cache DTO.
- [x] [Review][Defer] An `Exercise` with `indoorCompatible: false && outdoorCompatible: false` is not excluded on load [exercise.dart fromJson] — deferred, structurally unreachable from the remote mapper; defend in depth later.

## References

- `_bmad-output/planning-artifacts/epics.md#Story 6.1`
- `_bmad-output/planning-artifacts/prd.md#FR26-FR28`
- `_bmad-output/planning-artifacts/prd.md#NFR14`
- `_bmad-output/planning-artifacts/prd.md#NFR20`
- `_bmad-output/planning-artifacts/prd.md#NFR23`
- `_bmad-output/planning-artifacts/architecture.md#API & Communication Patterns`
- `_bmad-output/planning-artifacts/architecture.md#Graceful Degradation Pattern`
- `_bmad-output/planning-artifacts/architecture.md#Project Structure`
- `_bmad-output/planning-artifacts/ux-design-specification.md#Degraded States`
- `_bmad-output/implementation-artifacts/epic-5-retro-2026-05-14.md#Next Epic Preview - Epic 6`
- `_bmad-output/implementation-artifacts/deferred-work.md#Deferred from: code review of story 4-1-open-meteo-api-integration`
- `_bmad-output/implementation-artifacts/deferred-work.md#Deferred from: code review of 5-4-contextual-bandit-algorithm`
- ExerciseDB OSS docs: `https://oss.exercisedb.dev/`
- AscendAPI ExerciseDB docs: `https://docs.ascendapi.com/products/edb-v1/overview`

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `dart run build_runner build --delete-conflicting-outputs`
- `flutter test test/core/database/daos/exercise_cache_dao_test.dart test/data/datasources/exercise_local_data_source_test.dart test/data/datasources/exercise_remote_data_source_test.dart test/data/repositories/exercise_repository_impl_test.dart test/features/daily_plan/generate_daily_plan_test.dart`
- `flutter analyze lib/features/sessions_catalog lib/features/daily_plan/domain/usecases/generate_daily_plan.dart lib/core/constants/api_constants.dart lib/core/database/daos/exercise_cache_dao.dart lib/core/di/health_module.dart`
- `flutter test`

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Implemented the `sessions_catalog` domain and data layers with a `freezed` `Exercise` entity, ExerciseDB remote mapping, local Drift-backed cache reads/writes, and bundled fallback catalog loading.
- Kept the existing `exercise_cache` schema intact by storing serialized PulseCoach exercise JSON in `exerciseJson`; cache TTL remains repository-owned with `< 24h` fast-path, stale-cache recovery, and fallback asset recovery.
- Added a minimal fallback catalog with `mobility`, `cardio`, and `breathing` exercises to satisfy Story 6.1 degradation requirements; Story 6.2 still owns expanding this to the curated 10/10/10 catalog.
- Integrated `ExerciseRepository` into `GenerateDailyPlan` to replace placeholder duration/environment values with catalog-backed data when available, while preserving graceful degradation when catalog lookup fails.
- Added DAO, local datasource, remote datasource, repository, and daily-plan fallback tests; targeted analyze is clean for the changed surface and the full Flutter test suite passes.

### File List

- pulse_coach/assets/data/fallback_exercises.json
- pulse_coach/lib/core/constants/api_constants.dart
- pulse_coach/lib/core/database/daos/exercise_cache_dao.dart
- pulse_coach/lib/core/di/health_module.dart
- pulse_coach/lib/core/di/injection.config.dart
- pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart
- pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart
- pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart
- pulse_coach/lib/features/sessions_catalog/data/models/exercise_model.dart
- pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart
- pulse_coach/lib/features/sessions_catalog/domain/entities/exercise.dart
- pulse_coach/lib/features/sessions_catalog/domain/entities/exercise.freezed.dart
- pulse_coach/lib/features/sessions_catalog/domain/entities/exercise.g.dart
- pulse_coach/lib/features/sessions_catalog/domain/repositories/exercise_repository.dart
- pulse_coach/lib/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart
- pulse_coach/lib/features/sessions_catalog/domain/usecases/sync_exercise_catalog.dart
- pulse_coach/test/core/database/daos/exercise_cache_dao_test.dart
- pulse_coach/test/data/datasources/exercise_local_data_source_test.dart
- pulse_coach/test/data/datasources/exercise_remote_data_source_test.dart
- pulse_coach/test/data/datasources/exercise_remote_data_source_test.mocks.dart
- pulse_coach/test/data/repositories/exercise_repository_impl_test.dart
- pulse_coach/test/data/repositories/exercise_repository_impl_test.mocks.dart
- pulse_coach/test/features/daily_plan/generate_daily_plan_test.dart
- pulse_coach/test/features/daily_plan/generate_daily_plan_test.mocks.dart

## Change Log

- 2026-05-14: Implemented Story 6.1 ExerciseDB integration, cache/fallback flow, and minimal plan-generation catalog enrichment; regenerated injectable/freezed/json/mockito outputs and added regression coverage.
