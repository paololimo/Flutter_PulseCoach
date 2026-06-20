# Story 6.3: Session Browsing Screen

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to browse available session types filtered by category,
so that I can explore what kinds of sessions PulseCoach offers.

## Acceptance Criteria

1. Given the user navigates to the Sessions tab, when the screen renders, then sessions are displayed grouped by type: Mobility, Cardio, Breathing. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.3`]
2. Given the user taps a filter chip such as "Mobility", when the filter is applied, then only sessions of that type are visible in the list. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.3`]
3. Given the sessions list is loading, when data is being fetched, then shimmer placeholders are displayed and no `CircularProgressIndicator` is used. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.3`; `_bmad-output/planning-artifacts/ux-design-specification.md#Loading States`]
4. Given the user taps a session card in the catalog, when the detail view opens, then session name, description, duration, intensity, and step list are displayed. [Source: `_bmad-output/planning-artifacts/epics.md#Story 6.3`]

## Tasks / Subtasks

- [x] Add presentation state for the catalog screen (AC: 1-3)
  - [x] Create `pulse_coach/lib/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart`.
  - [x] Create `pulse_coach/lib/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart`.
  - [x] Register the Cubit with injectable and regenerate `pulse_coach/lib/core/di/injection.config.dart`.
  - [x] Model at least these states: `initial`, `loading`, `loaded`, `error`; include selected category and grouped exercises in loaded state.
  - [x] Fetch the three supported categories through `GetExercisesByType`: `mobility`, `cardio`, `breathing`.
  - [x] Treat a category fetch failure as degraded data for that category, not a whole-screen crash, if at least one other category loads.

- [x] Replace the Sessions placeholder with the browsable catalog (AC: 1-4)
  - [x] Update `pulse_coach/lib/features/sessions_catalog/presentation/pages/sessions_page.dart` to provide and render `SessionsCatalogCubit`.
  - [x] Load catalog data once on page creation; avoid refetching every rebuild.
  - [x] Show sections in fixed order: Mobility, Cardio, Breathing.
  - [x] Add category filter chips for All, Mobility, Cardio, Breathing. This satisfies the story AC; do not add text search, favorites, bookmarks, advanced filters, or sorting.
  - [x] Render an empty/degraded category with one-line quiet text only when needed; no illustration and no retry CTA.

- [x] Add reusable catalog UI widgets (AC: 1, 3, 4)
  - [x] Create `pulse_coach/lib/features/sessions_catalog/presentation/widgets/session_catalog_card.dart`.
  - [x] Create `pulse_coach/lib/features/sessions_catalog/presentation/widgets/session_catalog_detail_sheet.dart` or equivalent detail view widget.
  - [x] Create a local shimmer/skeleton widget for catalog loading, using existing `shimmer` dependency and placeholder shapes that match category headers plus session cards.
  - [x] Card content must include type chip, title, duration, difficulty indicator, and a compact action affordance.
  - [x] Tapping the card opens the detail view; the detail must show name, description, duration, intensity/difficulty, and every step in order.
  - [x] Do not wire "Start" into the full in-session flow yet; Epic 8 owns CountdownOverlay/InSessionView/RPE/MiniSummary.

- [x] Preserve navigation and existing app-shell behavior (AC: 1)
  - [x] Keep route path `AppRouter.sessions` as `/sessions`.
  - [x] Do not change redirect/onboarding behavior in `app_router.dart`.
  - [x] Preserve the existing bottom tabs and drawer behaviors in `AppShell`; update only tests that currently assert the placeholder text.

- [x] Add focused test coverage (AC: 1-4)
  - [x] Add Cubit tests under `pulse_coach/test/bloc/sessions_catalog_cubit_test.dart` using `bloc_test` and `mockito`.
  - [x] Test loading then loaded state, selected category changes, one-category failure degradation, and all-category failure error.
  - [x] Add widget tests under `pulse_coach/test/widget/sessions_page_test.dart` for grouped rendering, filter chip behavior, shimmer loading, absence of `CircularProgressIndicator`, and detail sheet content.
  - [x] Update `pulse_coach/test/widget/app_shell_test.dart` and any smoke tests that still expect `Sessions - Story 6.x` or `Sessions — Story 6.x`.
  - [x] Keep repository/data tests unchanged unless a failing presentation test exposes a real contract issue.

- [x] Run verification from `pulse_coach/` (AC: 1-4)
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` after adding injectable/freezed annotations.
  - [x] Run `flutter test test/bloc/sessions_catalog_cubit_test.dart test/widget/sessions_page_test.dart test/widget/app_shell_test.dart`.
  - [x] Run full `flutter test`.
  - [x] Run `flutter analyze` and address new issues introduced by this story.

## Dev Notes

### Current Code State

- `pulse_coach/lib/features/sessions_catalog/presentation/pages/sessions_page.dart` is a placeholder: `Center(child: Text('Sessions — Story 6.x'))`. This story replaces it with the real catalog UI.
- The domain/data layer is already implemented by Stories 6.1 and 6.2:
  - `GetExercisesByType` calls `ExerciseRepository.getExercisesByType(sessionType)`.
  - `ExerciseRepositoryImpl.getExercisesByType()` returns valid cache first, remote fetch second, stale cache on remote failure, and bundled fallback only when cache is empty/unavailable.
  - `ExerciseLocalDataSource.loadFallbackExercisesByType()` loads `assets/data/fallback_exercises.json`, skips malformed fallback records individually, and filters by `sessionType`.
  - `fallback_exercises.json` now contains 30 curated records: 10 mobility, 10 cardio, 10 breathing.
- DI already registers `ExerciseRepository`, `GetExercisesByType`, and `SyncExerciseCatalog`; a new presentation Cubit registration requires code generation.
- `AppRouter.sessions` already points to `/sessions` inside the `ShellRoute`, and `AppShell` currently wraps Sessions with the bottom navigation/drawer.
- The app shell currently orders tabs as Today, Sessions, Progress even though the UX spec says Sessions, Today, Progress. Do not change tab order in this story unless the product owner explicitly scopes navigation cleanup; existing tests and manual verification are based on the current shell behavior.

### Data Contract

Use the existing `Exercise` domain entity directly in presentation:

- `id`: stable string used for keys.
- `name`: catalog card title and detail title.
- `description`: detail body text.
- `sessionType`: one of `mobility`, `cardio`, `breathing`; map to labels Mobility, Cardio, Breathing.
- `steps`: ordered detail list.
- `durationMinutes`: card/detail duration display.
- `difficulty`: display as intensity/difficulty; map `low`, `medium`, `high` to 1, 2, 3 dots.
- `indoorCompatible` / `outdoorCompatible`: not required by AC, but may be shown as subtle metadata only if it does not crowd the card.

Do not add `strength` support in this story. The UX spec mentions a broader category order including Strength, but Epic 6.3 and the current fallback/API mapping scope this screen to Mobility, Cardio, and Breathing.

### UX Requirements

- Sessions screen layout:
  - Phone: single-column vertical scroll with category headers and full-width session cards.
  - Tablet-ready behavior can be simple responsive wrapping, but full tablet NavigationRail/grid work belongs to Epic 11.
  - Category order is Mobility, Cardio, Breathing.
- Loading:
  - Use shimmer/skeleton placeholders that resemble the catalog layout.
  - Never use `CircularProgressIndicator` for this screen.
  - Flutter's current shimmer guidance recommends placeholders approximating the loading content shape; the project already depends on `shimmer: ^3.0.0`.
- Filtering:
  - The story explicitly requires filter chips. Implement only category chips, plus All if useful.
  - Do not add search. The UX spec says the catalog is small enough that browsing is sufficient and search would over-engineer this escape-valve screen.
- Detail:
  - A modal bottom sheet is the lowest-risk phone implementation; keep it scrollable for long step lists.
  - Ensure TalkBack/VoiceOver can reach the card, filter chips, close control, and every step.
- Start flow:
  - The UX spec says catalog Start eventually enters CountdownOverlay -> InSessionView -> RPE -> MiniSummary -> Today.
  - Epic 8 owns that flow. For Story 6.3, tapping a catalog card opens detail. If a visible Start button is included for visual parity, it should not fake an unimplemented session flow.

### Architecture Guardrails

- Keep Clean Architecture boundaries:
  - Domain/data code stays under `features/sessions_catalog/domain` and `features/sessions_catalog/data`.
  - Presentation Cubit/page/widgets stay under `features/sessions_catalog/presentation`.
  - Widgets may import Flutter; domain entities/use cases must stay pure Dart except existing dependencies.
- Use `Cubit` rather than `Bloc` for this screen unless implementation complexity grows materially. The screen state is UI selection plus async loading, not a rich event stream.
- Use `Either<Failure, List<Exercise>>` from the use case and fold it in the Cubit. Do not throw repository failures into the widget tree.
- Use package-relative imports.
- Use `PulseCoachTheme`, `Theme.of(context)`, and existing spacing/text style helpers where available. Do not hardcode one-off colors.
- Generated files are committed. If `@injectable` or `freezed` is used, regenerate and include `.freezed.dart` / `injection.config.dart` updates as needed.

### UPDATE File Guidance

- `pulse_coach/lib/features/sessions_catalog/presentation/pages/sessions_page.dart`
  - Current state: placeholder text only.
  - Change: provide Cubit, trigger load, render loading/loaded/error/degraded states, filters, grouped list, and detail sheet.
  - Preserve: route remains shell-compatible; no app-level redirect changes.

- `pulse_coach/lib/core/di/injection.config.dart`
  - Current state: generated injectable registrations include catalog use cases but no catalog presentation Cubit.
  - Change: regenerate after adding the Cubit registration.
  - Preserve: do not hand-edit generated registration logic.

- `pulse_coach/test/widget/app_shell_test.dart`
  - Current state: asserts tapping Sessions shows the placeholder text.
  - Change: assert the real Sessions screen renders a stable catalog heading/loading shell instead.
  - Preserve: existing tests for bottom navigation item count, drawer, and current index.

- `pulse_coach/test/widget/pages_smoke_test.dart`
  - Current state: may still document all pages as placeholders and may assert placeholder text.
  - Change: update Sessions expectations to match the real screen.
  - Preserve: smoke coverage for app routing and onboarding setup.

### NEW File Guidance

- `pulse_coach/lib/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart`
  - Owns loading all supported categories through `GetExercisesByType`.
  - Exposes a selected category and filtered/grouped view data.
  - Should not know about widgets, routes, or `BuildContext`.

- `pulse_coach/lib/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart`
  - Prefer `freezed` if matching project state patterns. Minimum variants: `initial`, `loading`, `loaded`, `error`.
  - Store enough data for widgets to render without refetching.

- `pulse_coach/lib/features/sessions_catalog/presentation/widgets/session_catalog_card.dart`
  - Pure presentational widget taking an `Exercise` and callbacks.
  - Stable dimensions/padding so loading/loaded transitions do not jump.

- `pulse_coach/lib/features/sessions_catalog/presentation/widgets/session_catalog_detail_sheet.dart`
  - Pure presentational widget taking an `Exercise`.
  - Includes a close control, metadata, description, and ordered steps.

- `pulse_coach/test/bloc/sessions_catalog_cubit_test.dart`
  - Use `@GenerateMocks([GetExercisesByType])`.
  - Cover exact state sequences and selected category changes.

- `pulse_coach/test/widget/sessions_page_test.dart`
  - Prefer injecting/providing a Cubit or fake use case so tests do not depend on network.
  - Verify grouped headers, filter chips, shimmer placeholders, no spinner, and detail content.

### Previous Story Intelligence

- Story 6.1 established the catalog data flow and important fallback behavior. Do not regress:
  - Empty remote responses route through stale-cache or fallback recovery.
  - Future `cachedAt` timestamps are stale.
  - Corrupt cached rows and malformed fallback records are skipped individually.
  - Catalog enrichment preserves AI-selected `durationMinutes`.
  - Indoor/outdoor compatibility mapping was corrected in review.
- Story 6.2 expanded the bundled fallback and added integrity tests. The Sessions UI should benefit from this asset through the repository; do not parse `fallback_exercises.json` directly in the page.
- Story 6.2 recorded deferred repository concerns that are not in this story's scope:
  - Fallback JSON uniqueness is enforced by tests, not at runtime.
  - Unknown/case-variant `sessionType` is not normalized.
  - Stale cache takes precedence over expanded fallback.
  - Fallback asset is parsed on every `loadFallbackExercisesByType` call.

### Git Intelligence

- Recent commits:
  - `fa3e467 feat(epic-6/story-6.2): bundled fallback exercise catalog`
  - `5099a22 feat(epic-6/story-6.1): ExerciseDB API integration and cache`
  - `041d316 docs: add epic 5 retrospective`
- Pattern to follow: implement narrowly scoped story files, then add focused unit/widget tests before full `flutter test`.
- Do not introduce a new package for this story. `flutter_bloc`, `freezed`, `injectable`, `mockito`, `bloc_test`, and `shimmer` are already available.

### Latest Technical Notes

- `flutter_bloc` latest stable on pub.dev is `9.1.1`; the project currently declares `flutter_bloc: ^9.1.0`, so no dependency edit is required for Cubit/BlocBuilder usage. [Source: pub.dev flutter_bloc versions, `https://pub.dev/packages/flutter_bloc/versions`]
- `shimmer` latest stable on pub.dev is `3.0.0`, matching the project's `shimmer: ^3.0.0` dependency. [Source: pub.dev shimmer versions, `https://pub.dev/packages/shimmer/versions`]
- Flutter's official shimmer cookbook describes skeleton placeholders as shapes approximating loading content, which matches the UX requirement for category header plus card placeholders. [Source: Flutter docs, `https://docs.flutter.dev/cookbook/effects/shimmer-loading`]

### Testing Requirements

- Cubit tests:
  - Initial state is `initial`.
  - `loadCatalog()` emits `loading` then `loaded` when all categories return `Right`.
  - Loaded state groups by Mobility, Cardio, Breathing and preserves the fixed display order.
  - Selecting a category filters visible exercises without mutating the full grouped data.
  - One category returning `Left(Failure)` still loads the available categories with degraded metadata.
  - All categories returning `Left(Failure)` emits `error`.
- Widget tests:
  - Sessions tab/page renders grouped category headers and cards.
  - Filter chip tap hides other categories and keeps selected chip visual state.
  - Loading state shows shimmer placeholders and `find.byType(CircularProgressIndicator)` is zero.
  - Card tap opens detail view with name, description, duration, difficulty, and all steps.
  - Long text does not overflow at a narrow phone width; pump at a small surface such as 360x640.
- Run from `pulse_coach/`. Existing baseline was `flutter test` passing with 346/346 before later Epic 6 test additions; Story 6.2 ended with 360/360 tests.

### Project Structure Notes

- Expected updated files:
  - `pulse_coach/lib/features/sessions_catalog/presentation/pages/sessions_page.dart`
  - `pulse_coach/lib/core/di/injection.config.dart`
  - `pulse_coach/test/widget/app_shell_test.dart`
  - `pulse_coach/test/widget/pages_smoke_test.dart` if it references the placeholder
- Expected new files:
  - `pulse_coach/lib/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart`
  - `pulse_coach/lib/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart`
  - `pulse_coach/lib/features/sessions_catalog/presentation/widgets/session_catalog_card.dart`
  - `pulse_coach/lib/features/sessions_catalog/presentation/widgets/session_catalog_detail_sheet.dart`
  - `pulse_coach/test/bloc/sessions_catalog_cubit_test.dart`
  - `pulse_coach/test/widget/sessions_page_test.dart`
- Expected unchanged unless tests prove otherwise:
  - `pulse_coach/lib/features/sessions_catalog/data/repositories/exercise_repository_impl.dart`
  - `pulse_coach/lib/features/sessions_catalog/data/datasources/exercise_local_data_source.dart`
  - `pulse_coach/lib/features/sessions_catalog/domain/entities/exercise.dart`
  - `pulse_coach/assets/data/fallback_exercises.json`
  - Drift tables, DAOs, and cache schema

### References

- `_bmad-output/planning-artifacts/epics.md#Epic 6`
- `_bmad-output/planning-artifacts/epics.md#Story 6.3`
- `_bmad-output/planning-artifacts/architecture.md#Project Structure`
- `_bmad-output/planning-artifacts/architecture.md#Naming Conventions`
- `_bmad-output/planning-artifacts/architecture.md#Feature Mapping`
- `_bmad-output/planning-artifacts/ux-design-specification.md#Sessions Screen Patterns`
- `_bmad-output/planning-artifacts/ux-design-specification.md#Navigation Patterns`
- `_bmad-output/planning-artifacts/ux-design-specification.md#Responsive Design & Accessibility`
- `_bmad-output/project-context.md#Critical Implementation Rules`
- `_bmad-output/implementation-artifacts/6-1-exercisedb-api-integration-and-cache.md`
- `_bmad-output/implementation-artifacts/6-2-bundled-fallback-exercise-catalog.md`
- Flutter shimmer cookbook: `https://docs.flutter.dev/cookbook/effects/shimmer-loading`
- pub.dev flutter_bloc versions: `https://pub.dev/packages/flutter_bloc/versions`
- pub.dev shimmer versions: `https://pub.dev/packages/shimmer/versions`

## Dev Agent Record

### Agent Model Used

GPT-5 (Codex)

### Debug Log References

- 2026-05-15: `dart run build_runner build --delete-conflicting-outputs` completed; generated Freezed, Mockito, and Injectable outputs.
- 2026-05-15: `flutter test test/bloc/sessions_catalog_cubit_test.dart test/widget/sessions_page_test.dart test/widget/app_shell_test.dart test/widget/pages_smoke_test.dart` passed.
- 2026-05-15: Full `flutter test` passed with 370/370 tests.
- 2026-05-15: `flutter analyze` reports 38 pre-existing baseline issues and no issues in Story 6.3 files after fixes.

### Implementation Plan

- Implemented a `SessionsCatalogCubit` that loads Mobility, Cardio, and Breathing through `GetExercisesByType`, preserving fixed category order and degrading single-category failures when other categories load.
- Replaced the Sessions placeholder with a catalog view using filter chips, grouped sections, shimmer skeleton loading, session cards, and a modal detail sheet.
- Kept app-shell routing and tab behavior unchanged; updated tests that previously asserted placeholder text.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Added injectable Cubit state management for the sessions catalog with Freezed state variants `initial`, `loading`, `loaded`, and `error`.
- Implemented browsable Sessions UI with All/Mobility/Cardio/Breathing filters, fixed category ordering, quiet degraded/empty category text, shimmer placeholders, and detail sheet content for description, duration, intensity, and ordered steps.
- Added Cubit and widget coverage for success, filtering, partial degradation, total failure, loading skeletons without spinners, detail sheet rendering, shell navigation, and smoke behavior.

### File List

- _bmad-output/implementation-artifacts/6-3-session-browsing-screen.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- pulse_coach/lib/core/di/injection.config.dart
- pulse_coach/lib/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart
- pulse_coach/lib/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart
- pulse_coach/lib/features/sessions_catalog/presentation/bloc/sessions_catalog_state.freezed.dart
- pulse_coach/lib/features/sessions_catalog/presentation/pages/sessions_page.dart
- pulse_coach/lib/features/sessions_catalog/presentation/widgets/session_catalog_card.dart
- pulse_coach/lib/features/sessions_catalog/presentation/widgets/session_catalog_detail_sheet.dart
- pulse_coach/test/bloc/sessions_catalog_cubit_test.dart
- pulse_coach/test/bloc/sessions_catalog_cubit_test.mocks.dart
- pulse_coach/test/widget/app_shell_test.dart
- pulse_coach/test/widget/pages_smoke_test.dart
- pulse_coach/test/widget/sessions_page_test.dart
- pulse_coach/test/widget/sessions_page_test.mocks.dart

## Change Log

- 2026-05-15: Created Story 6.3 developer context for the Sessions browsing screen.
- 2026-05-15: Implemented Sessions browsing catalog UI, presentation Cubit, generated DI/state/test outputs, and focused test coverage.
- 2026-05-15: Code review completed (Blind Hunter + Edge Case Hunter + Acceptance Auditor).
- 2026-05-15: Code review round 2 — surfaced singleton lifecycle regression introduced by round-1 patches and the pubspec/font asset gap from the parallel theme refactor.
- 2026-05-15: Round 2 patches applied — `SessionsPage` is now `StatefulWidget` with `initState`-driven load and `BlocProvider.value`; local font assets (Plus Jakarta Sans, JetBrains Mono) bundled and declared in `pubspec.yaml`. Full suite passes 371/371.

### Review Findings

- [x] [Review][Decision] DI scope for `SessionsCatalogCubit` — currently `factory` (`injection.config.dart`); combined with `BlocProvider.create` resolving on every shell tab switch, the catalog refetches and the user-selected filter resets each time the user leaves and returns to the Sessions tab. Decide: keep factory (state loss is acceptable), promote to `lazySingleton`, or add a load-once guard at the page level.
- [x] [Review][Decision] Unknown `sessionType` fallback — `_categoryFor` in both `session_catalog_card.dart` and `session_catalog_detail_sheet.dart` silently relabels any unrecognized `sessionType` (e.g. `strength`, case variants, empty) as "Mobility". Decide: label as raw value, hide the chip, or assert-and-skip in the Cubit before reaching widgets.
- [x] [Review][Patch] Externally-provided cubit closed by `BlocProvider.create` [pulse_coach/lib/features/sessions_catalog/presentation/pages/sessions_page.dart:~595]
- [x] [Review][Patch] `loadCatalog()` is re-invoked on every `BlocProvider.create` — add a load-once guard (only call if state is `initial`) [sessions_page.dart:~599]
- [x] [Review][Patch] `try/catch` in `_loadCategory` wraps every exception as `CacheFailure(error.toString())`, masking the real cause and discarding stack [sessions_catalog_cubit.dart:~78-86]
- [x] [Review][Patch] Loop continues fetching after the cubit is closed — add `if (isClosed) return;` inside the per-category loop [sessions_catalog_cubit.dart:~66-100]
- [x] [Review][Patch] All categories succeeding with empty lists is currently emitted as `error` instead of a real empty/loaded state [sessions_catalog_cubit.dart:~95-98]
- [x] [Review][Patch] Raw `Failure.message` leaks into user-facing error copy — use static quiet text [sessions_page.dart:~824-833]
- [x] [Review][Patch] Hardcoded `Colors.white` inside `_SkeletonBlock` — use a theme surface token [sessions_page.dart:~805]
- [x] [Review][Patch] "Steps" heading rendered even when `exercise.steps` is empty — guard with `if (steps.isNotEmpty)` [session_catalog_detail_sheet.dart:~73-93]
- [x] [Review][Patch] Difficulty fallback silently maps unknown/empty values to "Low" / 1 dot — render an explicit unknown marker instead [session_catalog_card.dart:~964-968, session_catalog_detail_sheet.dart:~1118-1124]
- [x] [Review][Defer] Concurrent `loadCatalog()` calls have no in-flight guard [sessions_catalog_cubit.dart] — deferred, no current retry path triggers it
- [x] [Review][Defer] Filter chip taps during the loading state are silently dropped [sessions_catalog_cubit.dart:selectCategory] — deferred, minor UX
- [x] [Review][Defer] `durationMinutes = 0` / negative displayed verbatim on card/sheet/Semantics [session_catalog_card.dart, session_catalog_detail_sheet.dart] — deferred, data-integrity gap, not in current AC
- [x] [Review][Defer] Empty `description` renders a zero-height blank in detail sheet [session_catalog_detail_sheet.dart:~64-69] — deferred, minor UX
- [x] [Review][Defer] Richer Semantics for filter chips (radio group), category headers (`header: true`), and decorative difficulty dots (`ExcludeSemantics`) [sessions_page.dart, session_catalog_card.dart] — deferred, basic accessibility reach already implemented
- [x] [Review][Defer] Widget test 6.3-WIDGET-003 relies on sequential category-load ordering [test/widget/sessions_page_test.dart] — deferred, passes today
- [x] [Review][Defer] `app_shell_test.dart` constructs a fresh cubit on each `GoRouter` navigation [test/widget/app_shell_test.dart] — deferred, test hygiene
- [x] [Review][Defer] `WIDGET-002` taps "Cardio" chip without `ensureVisible` [test/widget/sessions_page_test.dart] — deferred, currently fits on the test surface
- [x] [Review][Defer] `groupedExercises` map reference is shared across emitted states (built mutably, exposed without defensive copy) [sessions_catalog_cubit.dart, sessions_catalog_state.dart] — deferred, no current mutating consumer

### Review Findings (Round 2)

- [x] [Review][Decision] Font assets missing for the `google_fonts` → local-font migration — resolved: downloaded `Plus Jakarta Sans` (Regular/Medium/SemiBold/Bold/ExtraBold) and `JetBrains Mono` (Regular/Medium/Bold) into `assets/fonts/`, declared a full `fonts:` block in `pubspec.yaml` with explicit weights, and removed the duplicate `assets/fonts/` asset directory entry (fonts are declared, not bundled as raw assets).
- [x] [Review][Patch] `BlocProvider(create: getIt<SessionsCatalogCubit>())` closes the `@lazySingleton` cubit on page dispose — fixed by converting `SessionsPage` to `StatefulWidget`, resolving the cubit in `initState`, and using `BlocProvider.value` in `build()` so disposal no longer closes the singleton. [sessions_page.dart]
- [x] [Review][Patch] `_ensureLoaded` no longer invoked from `build()` — load-once guard now runs in `initState`. [sessions_page.dart]
- [x] [Review][Defer] Cubit `.where((e) => e.sessionType == sessionType)` is case- and whitespace-sensitive; upstream variants (`'Mobility'`, `'mobility '`, `'MOBILITY'`) are silently dropped with no telemetry [sessions_catalog_cubit.dart:~31-33] — deferred, current fallback/API data emits exact lowercase
- [x] [Review][Defer] `Semantics` label hardcodes "minutes" plural — reads as "1 minutes" for `durationMinutes == 1` [session_catalog_card.dart] — deferred, minor accessibility nit
- [x] [Review][Defer] `pumpPage` constructs a `SessionsCatalogCubit` per test without `addTearDown(cubit.close)`; tests leak open stream subscriptions [test/widget/sessions_page_test.dart] — deferred, test hygiene
- [x] [Review][Defer] `6.3-WIDGET-006` compares `tester.getRect(...)` logical pixels against `tester.view.physicalSize` physical pixels; works only because `devicePixelRatio = 1` [test/widget/sessions_page_test.dart] — deferred, test correctness nit
- [x] [Review][Defer] `AppTheme.lightTheme` uses `ThemeData().textTheme` (implicit-light) asymmetrically vs `ThemeData(brightness: Brightness.dark).textTheme` for dark — fragile if Flutter ever flips the default brightness [lib/core/theme/app_theme.dart] — deferred, theme-refactor scope
