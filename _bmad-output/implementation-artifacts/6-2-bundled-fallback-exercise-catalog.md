# Story 6.2: Bundled Fallback Exercise Catalog

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want a curated bundled exercise catalog in `assets/data/fallback_exercises.json`,
so that the app can generate plans even when ExerciseDB is unavailable and local cache is empty.

## Acceptance Criteria

1. Given `fallback_exercises.json` exists in `assets/data/`, when parsed, then it contains at least 30 exercises: 10 mobility, 10 cardio, and 10 breathing. Each exercise has at least 3 steps and `durationMinutes` between 2 and 10 inclusive. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.2`]
2. Given the fallback is loaded, when inspected, then every fallback exercise has `indoorCompatible: true`; the fallback catalog never requires outdoor access. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.2`; `_bmad-output/planning-artifacts/ux-design-specification.md#Degraded States`]
3. Given `ExerciseRepository` is queried with empty cache and unreachable API, when the fallback is returned, then it is returned as `Right(exercises)`, not as a failure, and is indistinguishable from cached API data at the use case layer. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.2`; `_bmad-output/planning-artifacts/architecture.md#Graceful Degradation Pattern`]
4. Given the expanded fallback catalog is used by daily plan generation, when ExerciseDB is unreachable and the cache is empty, then the plan can still enrich mobility, cardio, and breathing sessions without a user-visible error state. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.1`; `_bmad-output/planning-artifacts/prd.md#FR26-FR28`; `_bmad-output/planning-artifacts/prd.md#NFR13-NFR14`]

## Tasks / Subtasks

- [x] Expand the bundled fallback catalog asset (AC: 1, 2)
  - [x] Update `pulse_coach/assets/data/fallback_exercises.json` from the current 3-record smoke-test catalog to at least 30 curated records.
  - [x] Include exactly or at least 10 records for each supported `sessionType`: `mobility`, `cardio`, `breathing`.
  - [x] Keep all fallback exercises `indoorCompatible: true`; set `outdoorCompatible` to `true` only when the exercise is also safe outdoors, but never make outdoor access required.
  - [x] Ensure every record has: `id`, `name`, `description`, `sessionType`, `steps`, `durationMinutes`, `difficulty`, `indoorCompatible`, and `outdoorCompatible`.
  - [x] Use unique stable IDs with a `fallback_` prefix and category in the ID, for example `fallback_mobility_hip_circles`.
  - [x] Keep durations in the product range 2-10 minutes and use only existing difficulty labels: `low`, `medium`, `high`.
  - [x] Keep all instructions concise, safe, equipment-free, and suitable for micro-sessions. Avoid medical, rehabilitative, or diagnosis-oriented claims.

- [x] Preserve the existing repository fallback contract (AC: 3)
  - [x] Do not replace the Story 6.1 repository flow unless a failing test proves it is necessary.
  - [x] Preserve `ExerciseRepositoryImpl.getExercisesByType`: valid cache first, remote fetch second, stale cache on remote failure, fallback asset only when cache is empty or unavailable.
  - [x] Preserve the existing `Right<List<Exercise>>` behavior when fallback data exists; expected ExerciseDB outages must not become `Left(Failure)`.
  - [x] Do not change the Drift `exercise_cache` schema for this story.
  - [x] Do not add new dependencies or remote APIs for curated fallback content.

- [x] Strengthen local datasource and asset validation tests (AC: 1, 2)
  - [x] Update `pulse_coach/test/data/datasources/exercise_local_data_source_test.dart` to load the real fallback asset and assert total count is at least 30.
  - [x] Assert counts by category: at least 10 `mobility`, 10 `cardio`, and 10 `breathing`.
  - [x] Assert every fallback exercise has at least 3 non-empty steps.
  - [x] Assert every duration is between 2 and 10 inclusive.
  - [x] Assert every exercise has `indoorCompatible == true`.
  - [x] Assert IDs are unique and stable enough for cache serialization.
  - [x] Assert only supported `sessionType` and `difficulty` values appear.

- [x] Add or update repository/use-case regression coverage (AC: 3)
  - [x] Update `pulse_coach/test/data/repositories/exercise_repository_impl_test.dart` so remote failure plus empty cache returns a category-sized fallback list, not only one hardcoded exercise.
  - [x] Cover all three fallback categories through `getExercisesByType`: `mobility`, `cardio`, and `breathing`.
  - [x] If a test uses mocks, keep at least one test path that loads the real asset through `ExerciseLocalDataSource`; this story is primarily about bundled data integrity.
  - [x] Keep the missing/invalid fallback test returning `Left(CacheFailure)` for the no-data case.

- [x] Verify plan-generation degradation remains complete (AC: 4)
  - [x] Update `pulse_coach/test/features/daily_plan/generate_daily_plan_test.dart` only if current coverage does not prove fallback-based enrichment with the expanded catalog.
  - [x] Confirm plan generation still succeeds when ExerciseDB is unavailable and cache is empty.
  - [x] Do not change `GenerateDailyPlan` behavior unless a current test fails; catalog selection and plan enrichment were already implemented in Story 6.1.

- [x] Run focused verification (AC: 1-4)
  - [x] Run `flutter test test/data/datasources/exercise_local_data_source_test.dart test/data/repositories/exercise_repository_impl_test.dart test/features/daily_plan/generate_daily_plan_test.dart` from `pulse_coach/`.
  - [x] Run full `flutter test` from `pulse_coach/` if focused tests pass.
  - [x] Run `flutter analyze` only if Dart source changes are made. If only JSON and tests change, analyze is optional but should not introduce new warnings.
  - [x] No `build_runner` is required unless the implementation changes `freezed`, `json_serializable`, Drift, or injectable source files.

## Dev Notes

### Current Code State

- `pulse_coach/assets/data/fallback_exercises.json` currently exists but contains only 3 records: one mobility, one cardio, and one breathing exercise. This satisfied Story 6.1 smoke-test degradation but fails Story 6.2's 30-exercise requirement.
- `pulse_coach/pubspec.yaml` already registers `assets/data/`, so the implementation should not need pubspec changes for the fallback asset.
- `ExerciseLocalDataSource.loadFallbackExercisesByType()` reads `assets/data/fallback_exercises.json` via `rootBundle.loadString`, decodes a JSON list, maps each entry with `Exercise.fromJson`, filters by `sessionType`, skips malformed individual records, and returns an immutable list.
- `ExerciseRepositoryImpl.getExercisesByType()` already returns fallback data as `Right(fallback)` when remote fetch fails and there is no cached data. Preserve this behavior.
- `GenerateDailyPlan` already calls `ExerciseRepository.getExercisesByType(session.sessionType)` and logs a skipped enrichment on `Left`; it does not surface expected catalog failure to UI. Do not turn fallback absence into user-visible UI work in this story.

### Data Contract For `fallback_exercises.json`

Each JSON object must match the current `Exercise` freezed entity exactly:

```json
{
  "id": "fallback_mobility_hip_circles",
  "name": "Hip Circles",
  "description": "Gentle hip mobility for short movement breaks.",
  "sessionType": "mobility",
  "steps": [
    "Stand tall with feet hip-width apart.",
    "Place hands on hips and draw slow circles.",
    "Reverse direction while keeping the movement smooth."
  ],
  "durationMinutes": 4,
  "difficulty": "low",
  "indoorCompatible": true,
  "outdoorCompatible": true
}
```

Required field rules:

- `id`: unique, stable, lowercase snake-case string. Use `fallback_<category>_<name>`.
- `sessionType`: one of `mobility`, `cardio`, `breathing`; do not add `strength` in this story even though UX later mentions a catalog category order including Strength. Epic 6.2 requires only these three categories.
- `steps`: at least 3 non-empty strings. Prefer 3-5 steps per exercise so instructions remain readable during a micro-session.
- `durationMinutes`: integer 2-10 inclusive.
- `difficulty`: one of `low`, `medium`, `high`. Breathing should usually be `low`; cardio may include `medium` and a few `high` entries if low-impact alternatives remain available.
- `indoorCompatible`: always `true`.
- `outdoorCompatible`: can be `true` for portable exercises, but no fallback exercise may require outdoor-only access.

### Curated Catalog Guidance

- Mobility examples: neck rolls, shoulder circles, thoracic rotations, cat-cow, hip circles, ankle rocks, wrist mobility, standing side bends, hamstring sweeps, seated spinal twist.
- Cardio examples: march in place, step jacks, low-impact skaters, toe taps, side steps, shadow boxing, standing knee lifts, gentle mountain climbers, squat-to-reach, fast feet.
- Breathing examples: box breathing, 4-6 breathing, paced nasal breathing, physiological sigh, equal breathing, extended exhale, belly breathing, shoulder-drop breathing, triangle breathing, reset breath scan.
- Keep the fallback catalog equipment-free. The app must remain fully usable in a room, kitchen, office, or small indoor space.
- Avoid exercises that depend on jumping, floor contact, outdoor routes, equipment, or complex technique unless the steps give a safe low-impact version.
- Do not add user-facing claims like "treats anxiety", "fixes pain", or "rehabilitates injury". Use neutral coaching language.

### Architecture Guardrails

- Follow feature-first Clean Architecture: domain entity stays in `features/sessions_catalog/domain/entities/exercise.dart`; local asset loading stays in `features/sessions_catalog/data/datasources/exercise_local_data_source.dart`.
- Do not expose DTOs to the domain or UI. The fallback asset maps directly to the domain `Exercise` JSON contract because Story 6.1 intentionally stored serialized PulseCoach exercise JSON in `exercise_cache.exerciseJson`.
- Repository methods must continue returning `Either<Failure, T>` from `dartz`; do not throw raw exceptions past the repository boundary.
- No new state management is needed. Story 6.3 owns the Sessions browsing UI.
- No database migration is needed. The fallback catalog is a bundled asset, not a table shape change.
- Use package-relative imports if Dart tests or source files are changed.

### UPDATE File Guidance

- `pulse_coach/assets/data/fallback_exercises.json`
  - Current state: valid JSON list with 3 records.
  - Change: expand to at least 30 complete records while keeping the same schema.
  - Preserve: valid JSON, asset path, category values, `indoorCompatible: true` guarantee.

- `pulse_coach/test/data/datasources/exercise_local_data_source_test.dart`
  - Current state: verifies cached rows preserve `cachedAt` and fallback breathing asset loads at least one record.
  - Change: add asset integrity assertions for total count, category counts, steps, duration range, indoor compatibility, unique IDs, supported categories, and supported difficulties.
  - Preserve: in-memory Drift DAO test coverage for cache read/write.

- `pulse_coach/test/data/repositories/exercise_repository_impl_test.dart`
  - Current state: mock-based tests cover fresh cache, stale cache plus remote success, remote failure plus stale cache, remote failure plus fallback, and missing fallback failure.
  - Change: strengthen fallback expectations to prove category lists come back as `Right` and are not surfaced as failures.
  - Preserve: existing recovery order tests.

- `pulse_coach/test/features/daily_plan/generate_daily_plan_test.dart`
  - Current state: Story 6.1 added plan-generation coverage for catalog fallback.
  - Change: only update if necessary to prove the expanded fallback still supports complete 3-session plans.
  - Preserve: Story 5.5/6.1 contract that AI-selected `durationMinutes` are not overwritten by catalog enrichment.

### Previous Story Intelligence

- Story 6.1 created the sessions catalog domain/data layers, ExerciseDB remote mapping, local Drift-backed cache, fallback asset loading, and minimal GenerateDailyPlan enrichment.
- Story 6.1 review patched several edge cases. Do not regress them:
  - Empty remote responses must route through stale-cache or fallback recovery.
  - `syncCatalog()` uses `fetchAll()`, dedupes by ID, and replaces the whole cache.
  - Future `cachedAt` timestamps are stale, not perpetually fresh.
  - Corrupt cached rows and malformed fallback records are skipped individually.
  - Catalog enrichment must preserve AI-committed `durationMinutes`.
  - Catalog enrichment must resolve indoor/outdoor compatibility in both directions.
- The 6.1 story explicitly deferred expanding fallback from 3 records to the full 10/10/10 catalog. That deferred work is the core scope of this story.
- Keep this story focused. Do not implement the Sessions browsing UI; that is Story 6.3.

### Latest Technical Notes

- Flutter's current official asset guidance treats JSON as a normal bundled asset and supports loading text assets through `AssetBundle.loadString` / `rootBundle.loadString`, with assets declared under the `flutter.assets` subsection of `pubspec.yaml`. The current code already follows that pattern. [Source: Flutter docs, `https://docs.flutter.dev/ui/assets/assets-and-images`; Flutter API docs, `https://api.flutter.dev/flutter/services/AssetBundle-class.html`]
- `dartz` latest stable remains `0.10.1`; the project already uses `dartz: ^0.10.1`, so no dependency change is needed for `Either`/`Right` fallback behavior. [Source: pub.dev dartz versions, `https://pub.dev/packages/dartz/versions`]
- `freezed` latest stable is `3.2.5`, matching the project dev dependency. This story should not require regenerated freezed files unless the `Exercise` entity changes, which is not expected. [Source: pub.dev freezed, `https://pub.dev/packages/freezed`]

### Testing Requirements

- Add data-driven tests against the real bundled JSON asset. Do not rely only on mocked fallback lists, because AC1 and AC2 are about actual shipped data.
- Prefer helper expectations inside the existing local datasource test file rather than creating a separate JSON parser utility solely for tests.
- Include failure messages or grouped expectations that make it easy to identify the invalid exercise ID if a record violates the schema.
- Run tests from `pulse_coach/`, not repository root.

### Project Structure Notes

- Expected updated files:
  - `pulse_coach/assets/data/fallback_exercises.json`
  - `pulse_coach/test/data/datasources/exercise_local_data_source_test.dart`
  - `pulse_coach/test/data/repositories/exercise_repository_impl_test.dart`
  - `pulse_coach/test/features/daily_plan/generate_daily_plan_test.dart` only if needed
- Expected unchanged files unless a failing test proves otherwise:
  - `pulse_coach/lib/features/sessions_catalog/domain/entities/exercise.dart`
  - `pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart`
  - `pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart`
  - `pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart`
  - Drift tables, DAOs, and generated files

### References

- `_bmad-output/planning-artifacts/epics.md#Story 6.2`
- `_bmad-output/planning-artifacts/epics.md#Epic 6`
- `_bmad-output/planning-artifacts/prd.md#Exercise Catalog`
- `_bmad-output/planning-artifacts/prd.md#NFR13-NFR14`
- `_bmad-output/planning-artifacts/architecture.md#API & Communication Patterns`
- `_bmad-output/planning-artifacts/architecture.md#Graceful Degradation Pattern`
- `_bmad-output/planning-artifacts/architecture.md#Project Structure`
- `_bmad-output/planning-artifacts/ux-design-specification.md#Degraded States`
- `_bmad-output/implementation-artifacts/6-1-exercisedb-api-integration-and-cache.md#Fallback Requirements`
- `_bmad-output/implementation-artifacts/6-1-exercisedb-api-integration-and-cache.md#Review Findings`
- Flutter assets docs: `https://docs.flutter.dev/ui/assets/assets-and-images`
- Flutter `AssetBundle` docs: `https://api.flutter.dev/flutter/services/AssetBundle-class.html`
- pub.dev dartz versions: `https://pub.dev/packages/dartz/versions`
- pub.dev freezed: `https://pub.dev/packages/freezed`

## Dev Agent Record

### Agent Model Used

GPT-5 (Codex)

### Debug Log References

- 2026-05-15: RED focused test run failed as expected because bundled fallback asset had 3 records instead of at least 30.
- 2026-05-15: GREEN focused test run passed after expanding fallback catalog and adding repository regression coverage.
- 2026-05-15: `flutter analyze test/data/datasources/exercise_local_data_source_test.dart test/data/repositories/exercise_repository_impl_test.dart` passed with no issues.
- 2026-05-15: Full `flutter test` passed with 360/360 tests after final file state.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Expanded the bundled fallback catalog to 30 curated equipment-free exercises: 10 mobility, 10 cardio, and 10 breathing.
- Preserved existing repository/source behavior; no Drift schema, production Dart, dependency, or codegen changes were needed.
- Added asset integrity coverage against the real bundled JSON and strengthened fallback repository regression coverage for all supported categories.
- Confirmed existing daily plan fallback enrichment coverage still proves plan generation succeeds without ExerciseDB/cache user-visible errors.

### File List

- pulse_coach/assets/data/fallback_exercises.json
- pulse_coach/test/data/datasources/exercise_local_data_source_test.dart
- pulse_coach/test/data/repositories/exercise_repository_impl_test.dart
- _bmad-output/implementation-artifacts/sprint-status.yaml
- _bmad-output/implementation-artifacts/6-2-bundled-fallback-exercise-catalog.md

## Change Log

- 2026-05-15: Created Story 6.2 developer context for bundled fallback exercise catalog expansion.
- 2026-05-15: Implemented bundled fallback exercise catalog expansion and validation tests; story ready for review.
- 2026-05-15: Code review completed (Blind Hunter + Edge Case Hunter + Acceptance Auditor). Acceptance Auditor passed all 4 ACs with no findings; 4 test-quality patches and 6 deferred pre-existing items recorded below.

### Review Findings

- [x] [Review][Patch] Assert `outdoorCompatible == true` on every fallback entry in the asset integrity test [pulse_coach/test/data/datasources/exercise_local_data_source_test.dart:UNIT-001] — field is set on all 30 entries but never validated; a future entry with `false` would silently violate the "works anywhere offline" intent of a bundled fallback.
- [x] [Review][Patch] Assert `name`, `description`, and `id` are non-empty (after trim) in the asset integrity test [pulse_coach/test/data/datasources/exercise_local_data_source_test.dart:UNIT-001] — current assertions cover `steps.isNotEmpty` and `id` uniqueness, but a future entry with `"name": "  "` would parse cleanly and surface a blank label.
- [x] [Review][Patch] In `6.2-UNIT-002`, add `verify(mockLocal.loadFallbackExercisesByType(...))` for each category so the test proves the fallback path was actually invoked [pulse_coach/test/data/repositories/exercise_repository_impl_test.dart:6.2-UNIT-002] — without this, the test would pass even if the implementation returned a hardcoded list or bypassed the documented recovery chain.
- [x] [Review][Patch] In `6.2-UNIT-002`, add `verifyNever(mockLocal.cacheExercises(any))` on the fallback path [pulse_coach/test/data/repositories/exercise_repository_impl_test.dart:6.2-UNIT-002] — guards against accidentally caching fallback data as if it were remote, which would poison the cache and mask remote failures on the next call.
- [x] [Review][Defer] Catalog uniqueness not enforced at load time in `_loadFallback` [pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart:108-128] — deferred, pre-existing Story 6.1 architecture; tests guard the shipped JSON.
- [x] [Review][Defer] Unknown/case-variant `sessionType` silently returns empty list with no normalization or logging [pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart:115] — deferred, pre-existing Story 6.1.
- [x] [Review][Defer] `Exercise.fromJson` accepts any string for `difficulty`/`sessionType` (no enum validation, no case normalization) [pulse_coach/lib/features/sessions_catalog/domain/entities/exercise.dart:6-22] — deferred, pre-existing Story 6.1.
- [x] [Review][Defer] Empty-asset vs missing-asset failure paths produce identical user-facing messages (asset-missing diagnostic is lost) [pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart:136-138] — deferred, pre-existing Story 6.1.
- [x] [Review][Defer] Stale-cache recovery short-circuits the expanded fallback entirely when any stale row exists [pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart:114-118] — deferred, pre-existing Story 6.1 design; the diff materially raises the user cost of this design (10 curated rows per category now hidden behind any single stale row).
- [x] [Review][Defer] AssetBundle JSON re-parsed on every `loadFallbackExercisesByType` call (3× per cold start if three categories requested) [pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart:96] — deferred, pre-existing Story 6.1; consider memoizing decoded list per session.
