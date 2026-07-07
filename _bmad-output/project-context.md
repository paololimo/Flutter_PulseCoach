---
project_name: 'Flutter_PulseCoach'
user_name: 'Paolo'
date: '2026-03-27'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'code_quality_rules', 'workflow_rules', 'anti_patterns']
status: 'complete'
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- **Flutter SDK**: 3.41.x (stable) — Dart null safety enforced
- **flutter_bloc**: latest pub.dev — state management (Bloc for domain flows, Cubit for UI-only state)
- **drift** + **drift_flutter**: ~2.32.x — local DB; run `dart run build_runner build` to regenerate `.g.dart` files after table changes
- **freezed** + **json_serializable**: latest pub.dev — all domain entities and bloc states MUST use freezed; run `dart run build_runner build` after model changes
- **get_it** + **injectable**: latest pub.dev — DI via annotations; run `dart run build_runner build` to regenerate `injection.config.dart`
- **go_router**: latest pub.dev — declarative routing (course requirement)
- **dartz**: latest pub.dev — `Either<Failure, T>` for all repository returns
- **dio**: latest pub.dev — HTTP client with interceptors for caching/logging
- **wear_plus**: latest pub.dev — WearOS companion (medium technical risk; spike required early)
- **sensors_plus**, **health**, **geolocator**: latest pub.dev — all sensors optional with RPE-only fallback
- **fl_chart**, **lottie**, **google_fonts**: latest pub.dev — Plus Jakarta Sans + JetBrains Mono fonts
- **mockito**, **bloc_test**, **integration_test**: dev dependencies — test toolchain

> **build_runner note**: Any change to drift tables, freezed classes, or injectable registrations requires `dart run build_runner build --delete-conflicting-outputs` before the app compiles.

## Critical Implementation Rules

### Language-Specific Rules (Dart)

- **Null safety**: always enforced — never use `!` force-unwrap unless you can prove non-null at that point; prefer `?.`, `??`, or early return
- **DateTime**: always use `DateTime` (UTC internally); never store or compare as strings; drift stores as integer timestamps; UI formats via `intl` package; API sends/receives ISO 8601 strings
- **Async patterns**: use `async`/`await` for I/O (network + DB); use Dart `Isolate` or `compute()` for CPU-heavy AI computation — never block the main isolate
- **Private members**: always prefix with `_` (`_sessionRepository`, `_computeReward()`)
- **Constants**: `lowerCamelCase` (e.g., `defaultEpsilon`, `maxRpeValue`) — import from `lib/core/constants/`, never hardcode inline
- **Imports**: use package-relative imports (`import 'package:pulse_coach/...'`), not relative `../` imports, except within the same feature folder
- **JSON field naming**: Dart models use `camelCase`; use `@JsonKey(name: 'snake_case')` when the API returns snake_case fields — freezed + json_serializable handles this

### Framework-Specific Rules (Flutter + Bloc)

**Clean Architecture layers:**
- `domain/` — pure Dart only; NO Flutter imports (`import 'package:flutter/...'` is forbidden here)
- `data/` — DTOs stay in data layer; repositories map DTO → domain entity; never expose DTOs to domain or presentation
- `presentation/` — Bloc/Cubit + pages + widgets; never call use cases directly from widgets — always via Bloc events

**Bloc/Cubit split:**
- Use `Bloc` for domain flows with complex event→state logic: `SessionBloc`, `DailyPlanBloc`, `FeedbackBloc`
- Use `Cubit` for simple UI-only state: `ThemeCubit`, `OnboardingCubit`, `ProgressCubit`
- Every Bloc state MUST be a `@freezed` sealed class with minimum 4 factory constructors: `initial()`, `loading()`, `loaded(...)`, `error({required Failure failure})`
- Bloc events use past-tense naming: `SessionStarted`, `RpeFeedbackSubmitted`, `DailyPlanRegenerateRequested`

**Loading states:**
- Every async operation emits `loading` state first
- Loading UI = shimmer placeholder matching the content layout — NEVER use `CircularProgressIndicator` or spinners

**Responsive layout:**
- Use `LayoutBuilder` at scaffold level — single 600dp breakpoint
- `< 600dp` → phone: `BottomNavigationBar`
- `≥ 600dp` → tablet: `NavigationRail` + master-detail layout
- Shared components, different arrangement — never duplicate widget logic for phone vs tablet

**Routing (go_router):**
- All routes defined in `lib/core/routing/app_router.dart` — no inline `GoRouter` creation elsewhere
- Route paths: `kebab-case` (`/today`, `/in-session`)
- Named route constants: `camelCase` static const (`AppRoutes.inSession`)
- In-session view uses overlay route (full-screen, no nav bar)

**Theme:**
- `ThemeData` with `useMaterial3: true`, `ColorScheme.fromSeed()`, dark-first
- Custom tokens via `ThemeExtension<PulseCoachTheme>` — never hardcode colors or text styles inline
- Fonts: Plus Jakarta Sans (body), JetBrains Mono (data/metrics) — loaded via `google_fonts`

**AI Engine isolation:**
- AI engine code lives in `lib/features/today/domain/ai/` — pure Dart, no Flutter imports
- Always run via `compute()` or a long-lived `Isolate`
- Input: `StateVector` (freezed, serializable); Output: `DailyPlan` + `List<Explanation>` (freezed, serializable)
- Must be fully testable without Flutter framework

### Testing Rules

**Test organization** — mirrors `lib/` structure exactly:
- `test/domain/` (~60 tests): use cases, AI engine (bandit, state machine, safety rules, reward calc)
- `test/data/` (~50 tests): repositories, caching/TTL, offline fallback, sync queue
- `test/bloc/` (~40 tests): state emissions, event handling, error paths
- `test/widget/` (~30 tests): rendering, responsive layout (phone vs tablet), screen rotation
- `test/integration/` (~20 tests): end-to-end session flow
- Test file naming: mirror source path with `_test.dart` suffix (e.g., `lib/features/today/domain/usecases/generate_daily_plan.dart` → `test/domain/usecases/generate_daily_plan_test.dart`)

**Mock conventions:**
- Use `mockito` with `@GenerateMocks([...])` annotation — never hand-write mock classes
- Mock only at layer boundaries: mock remote datasources in repository tests, mock repositories in bloc tests
- Use `fake_async` / fake clock for TTL and time-dependent tests (bandit, TTL cache)
- Never mock the Drift database — use an in-memory `NativeDatabase.memory()` for data layer tests

**Bloc testing:**
- Use `bloc_test` package with `blocTest<BlocType, StateType>(...)` pattern
- Always test: initial state, loading emission, success emission, failure emission
- Use `emitsInOrder([...])` to verify exact state sequence

**Domain/AI testing:**
- AI engine tests run as pure Dart unit tests (no `testWidgets`, no `flutter_test` widget pump)
- Test deterministic safety rules exhaustively: high RPE → no high intensity, deload triggers, state machine transitions
- Test bandit convergence with seeded random and fixed reward sequences

**Target**: 150–200 tests minimum (DIMA exam requirement)

### Code Quality & Style Rules

**Naming conventions (enforced by `dart analyze`):**
- Classes: `UpperCamelCase` → `DailyPlanBloc`, `SessionRepositoryImpl`
- Files: `snake_case` → `daily_plan_bloc.dart`, `session_repository_impl.dart`
- Variables/parameters: `lowerCamelCase` → `sessionCount`, `rollingRpeAverage`
- Enums: type `UpperCamelCase`, values `lowerCamelCase` → `BehavioralState.active`
- Use cases: verb phrase → `GenerateDailyPlan`, `SubmitRpeFeedback`
- Repository interfaces: no suffix → `SessionRepository`; implementations: `Impl` suffix → `SessionRepositoryImpl`

**Drift database naming:**
- Table classes: `PascalCase` extends `Table` → `class Sessions extends Table`
- Columns: `camelCase` Dart → auto-maps to `snake_case` SQL
- Foreign keys: `{referenced_table_singular}Id` → `sessionId`, `userId`
- Timestamps: always `createdAt`, `updatedAt`, `cachedAt` (standard across all tables)
- DAO classes: `{TableName}Dao` → `SessionsDao`, `BanditStateDao`

**File structure:**
- One class per file (except closely related private helpers)
- No files outside the defined feature-first hierarchy — no `lib/utils/`, no `lib/helpers/` at root
- Generated files (`.g.dart`, `.freezed.dart`, `injection.config.dart`) are committed to git

**Code style:**
- Run `flutter analyze` before any commit — zero warnings policy
- No `print()` statements in production code — use proper logging or remove
- No commented-out code blocks committed
- `analysis_options.yaml` at project root defines strict lint rules — do not suppress warnings with `// ignore:` without a comment explaining why

### Development Workflow Rules

**CI/CD (GitHub Actions):**
- Pipeline runs `flutter analyze` + `flutter test` on every push
- Both checks must pass — no merging with failing analyze or failing tests
- CI config lives in `.github/workflows/ci.yml`

**Build targets:**
- Android APK + iOS (dev profile) + WearOS APK
- No store publication pre-exam — debug/profile builds for demo
- `flutter create --platforms=android,ios --org com.pulsecoach pulse_coach` was the initialization command

**Code generation workflow** (run in this order after any model/schema change):
1. `dart run build_runner build --delete-conflicting-outputs`
2. Commit generated files (`.g.dart`, `.freezed.dart`, `injection.config.dart`) alongside source changes

**Dependency injection registration order** (matters for `get_it`):
1. `AppDatabase` (singleton)
2. DAOs
3. Remote datasources
4. Local datasources
5. Repositories
6. Use cases
7. Blocs/Cubits

**Environment config:**
- All API URLs and constants live in `lib/core/constants/api_constants.dart` — compile-time constants, no `.env` files
- All APIs are free and public (Open-Meteo, ExerciseDB) — no secrets management needed for v1

**WearOS spike:** validate `wear_plus` feasibility before building session features that depend on watch sync — medium technical risk

### Critical Don't-Miss Rules

**Error handling anti-patterns:**
| ❌ Anti-Pattern | ✅ Correct Pattern |
|---|---|
| `throw Exception('...')` in repository | `return Left(ServerFailure('...'))` |
| Raw exception propagating past data layer | Catch in repository, wrap in `Either` |
| `try/catch` in Bloc event handler for domain errors | Pattern-match the `Either` result |
| UI widget catching exceptions | Never — UI only renders state |

**State management anti-patterns:**
| ❌ Anti-Pattern | ✅ Correct Pattern |
|---|---|
| Bloc state as plain mutable class | `@freezed` sealed class with factory constructors |
| `if (mounted) setState(...)` | Bloc emits state, `BlocBuilder` rebuilds |
| Calling use case directly from widget | Dispatch Bloc event, let Bloc call use case |
| Global loading state shared across features | Each Bloc manages its own loading state |

**UI anti-patterns:**
| ❌ Anti-Pattern | ✅ Correct Pattern |
|---|---|
| `CircularProgressIndicator` / spinner | Shimmer placeholder matching content layout |
| Hardcoded color or text style | `Theme.of(context)` + `ThemeExtension<PulseCoachTheme>` |
| Duplicating widget logic for phone/tablet | Single widget tree, `LayoutBuilder` switches arrangement |
| Error UI for sensor/API unavailability | Silent degradation — sensors optional, never block UI |

**Architecture anti-patterns:**
| ❌ Anti-Pattern | ✅ Correct Pattern |
|---|---|
| `import 'package:flutter/...'` in domain/ or AI | Pure Dart only in domain and AI engine |
| DTO used in domain layer or UI | Map DTO → entity at repository boundary |
| Manual `getIt.registerSingleton(...)` calls | `@singleton` / `@injectable` annotation on class |
| Hardcoded API URL string in datasource | Import constant from `api_constants.dart` |
| In-memory-only API caching | Cache in drift with `cachedAt` column + TTL check |
| Test file in arbitrary location | Mirror `lib/` path, `_test.dart` suffix |

**Data/cache rules:**
- TTL: Open-Meteo cache = 1h; ExerciseDB cache = 24h; stale >2h Open-Meteo → use indoor defaults
- Cache-first serving: try network → serve cache if valid → use bundled fallback → return `Failure`
- Location: city-level approximation only — round GPS coordinates before any API call (GDPR NFR8)
- Health data: never transmit off-device; explicit consent required before accessing Health APIs

**Performance rules:**
- AI plan generation must complete in <30s (NFR1) — always on Isolate
- Haptic feedback must trigger in <200ms (NFR4) — call `HapticFeedback` directly, never through Bloc
- Cold start <3s (NFR6) — defer non-critical initialization post-first-frame via `WidgetsBinding.instance.addPostFrameCallback`

---

## Project-Specific Code-Review Traps

Recurring defect classes found repeatedly in this codebase's reviews. Reviewers (and the Edge-Case Hunter via `also_consider`) MUST check every changed diff against this list. Each trap cites its origin so the pattern is traceable. Ledger IDs: E7-P3, E8-P1, E18R-CB1, E18R-CB2, E20R-B1 (durably homed here per E22R-3, 2026-07-07 — the prior "formalized into the skill prompt" claim did not survive MCPmarket baseline skill sync).

1. **`Hero` inside `AnimatedSwitcher` (or any cross-fade) — tag collision.** During the cross-fade, the outgoing and incoming children coexist for one+ frame; two `Hero`s with the same tag alive at once throws a Hero-collision assertion / flickers. Check any `Hero` whose ancestor animates children in/out. _(Origin: Story 7.3, caught at 7.4 review.)_

2. **Cubit/BLoC lifecycle invariants** (any Cubit/BLoC with timers, streams, or async I/O):
   - `start()` / init is **idempotent** — a second call is a no-op (must `_timer?.cancel()` / guard before re-subscribing), else leaked `Timer.periodic` / phantom side effects.
   - `dispose()` / `close()` cancels **all** timers and stream subscriptions.
   - Persistence/DAO error paths emit an **explicit observable state** (e.g. `persistenceError`), never `debugPrint`/`AppLogger`-only-then-swallow.
   - Abandon vs. complete navigation is **mutually exclusive** (separate flags) — a completion `BlocListener` must not fire `go(rpe)` after `abandon()` already navigated. _(Origin: Stories 8.2/8.3/8.4; standardized as E8-P1.)_

3. **Shimmer / loading layout must be scrollable exactly like its loaded state.** A non-scrollable `Column` skeleton overflows on small viewports (≈360×640) where the loaded state (inside a `ListView`/scrollable) would not. Mount shimmer states at a real phone viewport, not the default 800×600 test surface. _(Origin: `_FriendsShimmer`; 4-epic small-device-overflow family — 9/16/17/18.)_

4. **Localized-IT on every backend-failure path — no raw `failure.message` passthrough.** Any UI that surfaces a `Failure` (SnackBar, body error view) must map it to a localized ARB string in BOTH locales; never render `failure.message` / `e.toString()` (English SDK/exception text). _(Origin: E17R-1 → E18R-2 Amici raw English; closed app-wide 2026-07-07.)_

5. **Two clients rendering the same shared state must be compared against each other.** When host/follower (or any two peers) render one synchronized state, a test or GUI-gate step MUST diff the two renderings side-by-side, not merely assert each client's internal state — a GREEN test can still assert the wrong shared direction. _(Origin: Story 20.x D3 follower count-up vs host count-down shipped GREEN.)_

---

## Usage Guidelines

**For AI Agents:**
- Read this file before implementing any code in this project
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Update this file if new patterns emerge during implementation

**For Humans:**
- Keep this file lean and focused on agent needs
- Update when technology stack or architecture decisions change
- Remove rules that become obvious over time

_Last Updated: 2026-03-27_
