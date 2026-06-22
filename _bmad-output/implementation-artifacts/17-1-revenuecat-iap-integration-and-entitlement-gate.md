---
baseline_commit: f960a53
---

# Story 17.1: RevenueCat IAP Integration and EntitlementGate

Status: done

## Story

As a developer,
I want RevenueCat integrated for cross-platform IAP and an `EntitlementGate` available to all routes and widgets,
So that Pro features can be gated consistently without inline `if (user.isPro)` checks scattered across the codebase.

## Acceptance Criteria

**AC1 — `purchases_flutter` added and `Purchases.configure(...)` called at startup (ARCH20):**
Given `purchases_flutter` is added to `pubspec.yaml`
When the app initializes (inside `main()`, before `runApp()`)
Then `Purchases.configure(PurchasesConfiguration(apiKey))` is called with the platform-specific RevenueCat API key read via `String.fromEnvironment`; the SDK is initialized before `configureDependencies()` is called — same ordering pattern as `Supabase.initialize()`

**AC2 — `EntitlementGate` resolves three tiers (ARCH20, FR59, FR62):**
Given `EntitlementGate` is implemented at `lib/core/cloud/entitlement_gate.dart` and registered as `@singleton`
When any caller invokes `entitlementGate.check(Feature.xxx)`
Then it returns one of three `SubscriptionTier` values: `accountFree`, `signedInFree`, or `pro`; the result is derived from (a) whether a Supabase auth session exists (via `SupabaseClientProvider`) and (b) whether the RevenueCat `pro` entitlement is active in the cached `CustomerInfo`

**AC3 — account-free mode always returns `accountFree` for Pro features:**
Given the device has never signed in (no Supabase session)
When `entitlementGate.check(Feature.progressHistory)` is called
Then the tier is `accountFree`; the v1 core is fully functional and no sign-in is required

**AC4 — `SubscriptionBloc` emits `error` on connectivity failure; cached entitlement is preserved (NFR34):**
Given the `SubscriptionBloc` processes a `SubscriptionCheckRequested` event
When `Purchases.getCustomerInfo()` throws a network error
Then `SubscriptionBloc` emits `error(SubscriptionFailure('...'))`;  `EntitlementGate` continues to use the last-known cached `CustomerInfo` from RevenueCat's local cache; the v1 free core is unaffected

**AC5 — `SubscriptionBloc` reads from RevenueCat local cache; no loading flash (ARCH20):**
Given `SubscriptionBloc` is registered as `@injectable` and the app launches
When `SubscriptionBloc` processes the initial `SubscriptionCheckRequested` event (dispatched in `main()` alongside `AppStarted`)
Then it emits `loaded(tier: <current tier>)` before the first route paints — revenueCat's local cache read is near-instant (<5 ms); `initial` → `loaded` transition happens within the same frame budget; no gating UI renders in `initial` state

**AC6 — `installCohort` persisted in drift `user_profile` table:**
Given a new drift migration (schema version 9)
When the migration runs
Then the `user_profile` table has a new `TEXT` column `install_cohort` (nullable); existing rows receive `'pre_v2'`; new installs write `'post_v2'` during onboarding profile save (or default to `'post_v2'` if null); the `AppDatabase.schemaVersion` is bumped to `9`

**AC7 — `flutter analyze` reports zero issues; all tests pass:**
Given the implementation is complete
When `flutter analyze` and `flutter test` run from `pulse_coach/`
Then both report zero issues and all existing 885+ tests continue to pass; new tests are green

## Tasks / Subtasks

- [x] **Task 1 — Add `purchases_flutter` and configure RevenueCat at startup (AC1)**
  - [x] 1.1 Add `purchases_flutter: ^10.3.0` to `pubspec.yaml` dependencies (^7.0.0 incompatible with freezed_annotation ^3.1.0; ^10.3.0 is the compatible latest)
  - [x] 1.2 In `main.dart`, call `Purchases.configure(PurchasesConfiguration(apiKey))` **before** `configureDependencies()`, using `String.fromEnvironment('REVENUECAT_API_KEY_ANDROID', defaultValue: '')` / `REVENUECAT_API_KEY_IOS` selected by `Platform.isAndroid`; empty-string key is tolerated by RevenueCat SDK in sandbox (free core unaffected — NFR34)
  - [x] 1.3 Run `flutter pub get`; confirm `purchases_flutter` resolves cleanly with existing deps

- [x] **Task 2 — Domain models in `lib/features/subscription/domain/` (AC2)**
  - [x] 2.1 Create `lib/features/subscription/domain/entities/subscription_tier.dart` — enum `SubscriptionTier { accountFree, signedInFree, pro }`
  - [x] 2.2 Create `lib/features/subscription/domain/entities/feature.dart` — enum `Feature { progressHistory, social, sharedSession, leaderboardScore }` (extend in later stories)
  - [x] 2.3 Create `lib/features/subscription/domain/repositories/entitlement_repository.dart` — abstract interface with `Future<bool> isPro()` and `Future<void> invalidateCache()`

- [x] **Task 3 — `EntitlementGate` in `lib/core/cloud/` (AC2, AC3)**
  - [x] 3.1 Create `lib/core/cloud/entitlement_gate.dart` as `@singleton`; fields: `SupabaseClientProvider _supabase`; inject via constructor
  - [x] 3.2 Implement `SubscriptionTier check(Feature feature)` — sync; reads `_cachedTier` field set by `refresh()`
  - [x] 3.3 Implement `Future<void> refresh()` — calls `Purchases.getCustomerInfo()` via `isProFetcher` seam, checks entitlement, reads auth via `currentUserProvider` seam; sets `_cachedTier`
  - [x] 3.4 Initial `_cachedTier` defaults to `accountFree` (safe fallback) until first `refresh()` completes
  - [x] 3.5 **BOUNDARY RULE:** `entitlement_gate.dart` does NOT import `package:pulse_coach/features/...`; reads auth state only via `SupabaseClientProvider` (ARCH25 boundary honored)

- [x] **Task 4 — `SubscriptionRemoteDataSource` and `EntitlementRepositoryImpl` (AC4)**
  - [x] 4.1 Create `lib/features/subscription/data/datasources/subscription_remote_data_source.dart` — wraps `Purchases.getCustomerInfo()`; returns `bool isPro`
  - [x] 4.2 Create `lib/features/subscription/data/repositories/entitlement_repository_impl.dart` — `@Injectable(as: EntitlementRepository)`; calls datasource; calls `entitlementGate.refresh()` (unawaited, best-effort) after a successful fetch
  - [x] 4.3 Create `lib/features/subscription/domain/usecases/check_entitlement_use_case.dart` — thin use-case calling `EntitlementRepository.isPro()`; returns `Either<Failure, bool>`

- [x] **Task 5 — `SubscriptionBloc` in `lib/features/subscription/presentation/bloc/` (AC4, AC5)**
  - [x] 5.1 Create `subscription_event.dart`, `subscription_state.dart` (freezed sealed), `subscription_bloc.dart`
  - [x] 5.2 State factories (minimum): `initial()`, `loading()`, `loaded({required SubscriptionTier tier})`, `error({required Failure failure})`
  - [x] 5.3 Event: `SubscriptionCheckRequested`
  - [x] 5.4 `SubscriptionBloc` constructor calls `add(SubscriptionCheckRequested())` immediately (self-dispatch pattern) to resolve from cache before first frame
  - [x] 5.5 `_onSubscriptionCheckRequested`: emit `loading()` → call `CheckEntitlementUseCase` → emit `loaded(tier: ...)` or `error(...)`; on error, `EntitlementGate` still holds previous cache value (NFR34)
  - [x] 5.6 Register `SubscriptionBloc` as `@injectable`; added to root `MultiBlocProvider` in `app.dart`

- [x] **Task 6 — drift schema migration: `installCohort` column (AC6)**
  - [x] 6.1 Add `TextColumn get installCohort => text().nullable()()` to `lib/core/database/tables/user_profile_table.dart`
  - [x] 6.2 Bump `AppDatabase.schemaVersion` from `8` → `9`
  - [x] 6.3 Add `if (from < 9)` migration with table existence guard (mirrors v8 guard pattern) to `onUpgrade` in `app_database.dart`; backfills existing rows with `'pre_v2'`
  - [x] 6.4 Updated `onboarding_repository_impl.dart` (`acceptDisclaimer` + `saveProfile`) to write `installCohort: 'post_v2'` for new profile creates
  - [x] 6.5 Run `dart run build_runner build --delete-conflicting-outputs`; `app_database.g.dart` and `user_profile_table.dart` changes generated

- [x] **Task 7 — DI wiring (injectable annotations + build_runner) (AC5)**
  - [x] 7.1 Annotated: `EntitlementGate` (`@singleton`), `SubscriptionRemoteDataSource` (`@injectable`), `EntitlementRepositoryImpl` (`@Injectable(as: EntitlementRepository)`), `CheckEntitlementUseCase` (`@injectable`), `SubscriptionBloc` (`@injectable`)
  - [x] 7.2 Run `dart run build_runner build --delete-conflicting-outputs`; `injection.config.dart` updated
  - [x] 7.3 `SubscriptionBloc` added to root `MultiBlocProvider` in `app.dart`; self-dispatch in constructor handles the initial check (no extra `add()` needed in `main.dart`)

- [x] **Task 8 — Tests (AC4, AC5, AC7)**
  - [x] 8.1 Created `test/bloc/subscription_bloc_test.dart` using `bloc_test` — covers: initial state, pro path, account-free path, network error → error state
  - [x] 8.2 Created `test/data/subscription/entitlement_gate_test.dart` — covers all three tiers via `isProFetcher`/`currentUserProvider` seams; NFR34 cache preservation on error
  - [x] 8.3 Run `flutter test` — **943 tests pass** (was 932+; 11 new tests added); 0 regressions

## Review Findings

_Adversarial code review 2026-06-22 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). AC7 independently verified: `flutter analyze` = 0 issues, `flutter test` = 943 passed._

- [x] [Review][Decision→Fixed] SubscriptionBloc never emits `signedInFree` — RESOLVED (option 1, fix now). Tier resolution now flows end-to-end through the gate (canonical resolver): `CheckEntitlementUseCase` returns `SubscriptionTier`, `EntitlementRepository.currentTier()` does one awaited `gate.refresh()` and returns `gate.currentTier`, and the bloc emits `loaded(tier: tier)` directly. Bonus: collapses the double `getCustomerInfo()` (W1) and the unawaited race (W2); orphaned `subscription_remote_data_source.dart` removed. New `signedInFree` bloc test added. [subscription_bloc.dart / check_entitlement_use_case.dart / entitlement_repository_impl.dart]
- [x] [Review][Decision→Dismissed] Gate silently downgrades pro→free on a successful-but-empty fetch — DISMISSED (option 1). RevenueCat `getCustomerInfo()` throws on network failure (already caught + preserved by NFR34) and returns disk-cached entitlements when offline, so a "successful empty fetch for a genuinely-pro user" does not occur in practice; a sticky-pro safeguard would instead mask real cancellations/expirations. The existing throw-path preservation is sufficient. [entitlement_gate.dart:39-55]
- [x] [Review][Patch→Fixed] drift v8→v9 migration partial-migration column guard added — `from < 9` block now checks `PRAGMA table_info(user_profile)` for `install_cohort` before `addColumn`, mirroring the v8 guard. [app_database.dart:118-141]
- [x] [Review][Patch→Fixed] `EntitlementGate.refresh()` now logs the swallowed error via `debugPrint` while still preserving the cached tier (NFR34). [entitlement_gate.dart:50-54]
- [x] [Review][Defer] Double `Purchases.getCustomerInfo()` per check (datasource + `gate.refresh()`) — deferred, acceptable: RevenueCat local-cache read <5ms; revisit if it becomes hot. [entitlement_repository_impl.dart:16-21]
- [x] [Review][Defer] `unawaited(_gate.refresh())` race — `gate.check()` lags the bool returned to the bloc — deferred: no synchronous consumer of `check()` exists yet; revisit when gating UI lands. [entitlement_repository_impl.dart:20]
- [x] [Review][Defer] Non-onboarding profile inserts (restore/import) leave `install_cohort` NULL — neither `pre_v2` nor `post_v2`; column has no table-level default — deferred: needs restore-path audit in a later subscription story. [user_profile_table.dart / onboarding_repository_impl.dart]

## Dev Notes

### E9-K1 Fire-Check Results (Category B standing rule — run at every create-story)

**(a) DI/lifecycle/cross-cutting patches [E6-P1 scope]:**
**TRIGGERED.** This story:
- Adds a new `@singleton` to `lib/core/cloud/` (`EntitlementGate`)
- Adds a new `packages_flutter` SDK initialized in `main.dart` (boot-order sensitive, same category as `Supabase.initialize()`)
- Adds a new `@injectable SubscriptionBloc` to the root `MultiBlocProvider`
- Bumps `AppDatabase.schemaVersion` from 8 → 9

These are textbook cross-cutting concerns (DI, boot order, root widget tree, DB schema). The dev agent MUST treat `E6-P1` as active: any review patch touching DI/lifecycle/schema from this story should be applied with the same care as a migration hotfix. Do not skip `flutter test` after `build_runner`.

**(b) Category A deliverable-debt with relative trigger [E9R-4 scope, absorbed into E9-K1]:**
**E16R-1 trigger check:** The action ledger says "Schedule early in Epic 17 or as a standalone test task." Story 17.1 is the first Epic 17 story. **Recommendation:** schedule `E16R-1` (auth/backup datasource test hardening — restore round-trip test + signOut-after-200 safety assertion) as a standalone test PR immediately alongside or immediately after 17.1, before 17.2. Do NOT let it slip to 17.3+. (E16R-1 is Category A, 2/5, confirmed active.)

**(c) Cubit/BLoC collection-index pre-flight [E7-P2 scope]:**
**NOT triggered.** `SubscriptionBloc.state` holds a `SubscriptionTier` enum value, not a positional index into a collection. No identity-vs-position risk.

### Critical: `EntitlementGate` does NOT exist yet

The v2-cloud-store-config-checklist.md (E16R-3 deliverable, 2026-06-22) explicitly states:
> "Epic 16's goal named an 'EntitlementGate skeleton' but only `AuthBloc` shipped; the gate does not exist yet."

Do NOT assume any `entitlement_gate.dart` is in the codebase. `ls lib/core/cloud/` shows only: `crypto/`, `secure_local_storage.dart`, `supabase_client.dart`. The file must be created from scratch.

### Critical: `lib/features/subscription/` module does NOT exist yet

`ls lib/features/` shows: `auth/`, `daily_plan/`, `feedback/`, `onboarding/`, `progress/`, `session/`, `sessions_catalog/`, `settings/`, `today/`, `weather/`. The entire `subscription/` subtree is new.

### Critical: `purchases_flutter` is NOT in `pubspec.yaml`

`grep purchases_flutter pubspec.yaml` returns empty. Add it. Verify the latest stable version on pub.dev before pinning — as of story creation, `^7.0.0` is the expected range; confirm before writing the lock.

### Critical: `installCohort` column does NOT exist in drift

`user_profile_table.dart` has no `installCohort` field. Current `schemaVersion = 8`. This story must bump it to `9`. The migration default for existing rows is `'pre_v2'` because any device running the upgrade already had the app installed before v2 shipped — that's the correct grandfathering signal.

### ARCH Boundary: `lib/core/cloud/` import rules (ARCH25)

The `supabase_client.dart` file has a comment at line 1: "only two locations in the project may import `supabase_flutter` directly: this file and `main.dart`." `entitlement_gate.dart` is in `lib/core/cloud/` — it **MAY** import `supabase_flutter` transitively via `SupabaseClientProvider` (which is injected), but it must NOT import `package:pulse_coach/features/auth/...` or any other feature. To read auth state, use `_supabase.client.auth.currentUser` (which is available via `SupabaseClientProvider.client`). No `AuthBloc` import allowed.

### Boot Order in `main.dart` (critical for AC1 and AC5)

`main.dart` current order (inferred from Epic 16 pattern):
```
1. WidgetsFlutterBinding.ensureInitialized()
2. Supabase.initialize(url: ..., publishableKey: ...)   // Epic 16.1
3. configureDependencies()                               // injectable DI
4. runApp(...)
```

Story 17.1 **inserts `Purchases.configure(...)` at step 2.5** (after Supabase, before DI):
```
1. WidgetsFlutterBinding.ensureInitialized()
2. Supabase.initialize(...)
2.5 Purchases.configure(PurchasesConfiguration(apiKey))  // NEW — 17.1
3. configureDependencies()
4. runApp(...)
```

RevenueCat SDK must be configured before `getIt<SubscriptionBloc>()` is constructed, because the Bloc constructor calls `add(SubscriptionCheckRequested())` which calls `Purchases.getCustomerInfo()`. If `Purchases.configure` hasn't been called, the SDK throws `ConfigurationError`.

### RevenueCat API Key injection pattern

Read via `String.fromEnvironment`:
```dart
final rcKey = Platform.isAndroid
    ? const String.fromEnvironment('REVENUECAT_API_KEY_ANDROID', defaultValue: '')
    : const String.fromEnvironment('REVENUECAT_API_KEY_IOS', defaultValue: '');
Purchases.configure(PurchasesConfiguration(rcKey));
```
Empty-string key → RevenueCat SDK enters "observer mode" (no purchases processed, `getCustomerInfo()` returns empty entitlements). This preserves NFR34: free core functions with zero RevenueCat configuration. The `--dart-define=REVENUECAT_API_KEY_ANDROID=<key>` pattern from the checklist is the verification path.

### RevenueCat entitlement ID

The entitlement key to check is `'pro'` (must match the entitlement identifier configured in the RevenueCat dashboard — checklist §5 confirms this). Check:
```dart
customerInfo.entitlements.active.containsKey('pro')
```

### `SubscriptionBloc` root provider placement

Add `SubscriptionBloc` to the root `MultiBlocProvider` in `lib/app.dart` alongside `AuthBloc` and `ThemeCubit`. Do NOT provide it per-route (it is app-wide state). Pattern matches how `AuthBloc` is already provided globally.

### DI Registration Order

Extend the existing order (project-context.md §Dependency injection registration order):
```
... (existing) ...
8. SupabaseClientProvider (already registered as @singleton)
9. EntitlementGate (@singleton) — depends on SupabaseClientProvider
10. SubscriptionRemoteDataSource (@injectable)
11. EntitlementRepositoryImpl (@Injectable(as: EntitlementRepository))
12. CheckEntitlementUseCase (@injectable)
13. SubscriptionBloc (@injectable)
```
Injectable resolves this order from annotations automatically — just annotate correctly.

### Bloc state pattern (from project-context.md)

`SubscriptionBloc` MUST use `@freezed` sealed state with exactly these four factory constructors:
```dart
@freezed
sealed class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState.initial() = _Initial;
  const factory SubscriptionState.loading() = _Loading;
  const factory SubscriptionState.loaded({required SubscriptionTier tier}) = _Loaded;
  const factory SubscriptionState.error({required Failure failure}) = _Error;
}
```
Events are past-tense: `SubscriptionCheckRequested`.

### `build_runner` — run once after ALL schema/model changes

Run after Tasks 2, 5, and 6 are complete (not after each):
```
dart run build_runner build --delete-conflicting-outputs
```
Commit the generated files: `app_database.g.dart`, `*.freezed.dart`, `*.g.dart`, `injection.config.dart`.

### Test baseline

Current test count: **885+** (as of story 16.4 completion, per 16-4 checklist). All must remain green after this story. New tests in `test/bloc/subscription_bloc_test.dart` and `test/data/subscription/entitlement_gate_test.dart`.

### Project Structure Notes

New files created by this story:
```
lib/core/cloud/
  └── entitlement_gate.dart                         # NEW @singleton

lib/features/subscription/
  ├── data/
  │   ├── datasources/
  │   │   └── subscription_remote_data_source.dart  # NEW
  │   └── repositories/
  │       └── entitlement_repository_impl.dart      # NEW
  ├── domain/
  │   ├── entities/
  │   │   ├── subscription_tier.dart                # NEW (enum)
  │   │   └── feature.dart                          # NEW (enum)
  │   ├── repositories/
  │   │   └── entitlement_repository.dart           # NEW (abstract)
  │   └── usecases/
  │       └── check_entitlement_use_case.dart       # NEW
  └── presentation/
      └── bloc/
          ├── subscription_bloc.dart                # NEW
          ├── subscription_event.dart               # NEW (part file)
          ├── subscription_state.dart               # NEW (part file)
          ├── subscription_bloc.freezed.dart        # GENERATED
          └── subscription_bloc.g.dart              # GENERATED

test/
  ├── bloc/
  │   └── subscription_bloc_test.dart               # NEW
  └── data/
      └── subscription/
          └── entitlement_gate_test.dart            # NEW
```

Modified files:
- `pubspec.yaml` — add `purchases_flutter`
- `main.dart` — add `Purchases.configure(...)`
- `lib/app.dart` — add `SubscriptionBloc` to root `MultiBlocProvider`
- `lib/core/database/tables/user_profile_table.dart` — add `installCohort`
- `lib/core/database/app_database.dart` — bump `schemaVersion` to 9, add migration
- `lib/core/di/injection.config.dart` — GENERATED (updated by build_runner)
- `lib/core/database/app_database.g.dart` — GENERATED (updated by build_runner)

### References

- Epic 17 ACs: `_bmad-output/planning-artifacts/epics.md#Story 17.1`
- Architecture subscription module: `_bmad-output/planning-artifacts/architecture.md#L1319-1322`
- Architecture EntitlementGate: `_bmad-output/planning-artifacts/architecture.md#L1306`
- Architecture gating process pattern: `_bmad-output/planning-artifacts/architecture.md#L790-806`
- Architecture v2 anti-patterns: `_bmad-output/planning-artifacts/architecture.md#L824-833`
- Architecture v2 enforcement rules (11–13): `_bmad-output/planning-artifacts/architecture.md#L815-821`
- Platform-config checklist §5 (RevenueCat): `_bmad-output/implementation-artifacts/v2-cloud-store-config-checklist.md#RevenueCat IAP — Epic 17`
- Action-item ledger E16R-1: `_bmad-output/implementation-artifacts/action-item-ledger.md#Epic 17 Kickoff Triage`
- Supabase import boundary: `lib/core/cloud/supabase_client.dart#L1`
- Project context (DI order, Bloc rules, test structure): `_bmad-output/project-context.md`
- Previous story dev notes (supabase boundary pattern): `_bmad-output/implementation-artifacts/16-4-in-app-account-deletion-and-data-export.md#Dev Notes`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Task 1: `purchases_flutter: ^7.0.0` incompatible with `freezed_annotation: ^3.1.0`; upgraded to `^10.3.0` (compatible).
- Task 3 testability: `entitlement_gate.dart` uses `@visibleForTesting` `isProFetcher` and `currentUserProvider` late fields to avoid calling the real RevenueCat SDK or `GoTrueClient` in tests (mockito `GoTruePasskeyApi` experimental warnings avoided).
- Task 6 migration: added `user_profile` table existence guard (same pattern as v8 migration) to survive partial test databases that only contain a subset of tables.
- Tests: existing tests `schemaVersion is 8` and `v1 to v8 composite migration` updated to v9; `data_persistence_test.dart` PRAGMA assertion updated to 9.

### Completion Notes List

- AC1: `purchases_flutter: ^10.3.0` added; `Purchases.configure()` called in `main.dart` before `configureDependencies()`, after Supabase init, using `String.fromEnvironment` keys; empty key → observer mode (NFR34).
- AC2: `EntitlementGate` (@singleton) at `lib/core/cloud/entitlement_gate.dart`; `SubscriptionTier` and `Feature` enums in `lib/features/subscription/domain/entities/`; `check(Feature)` sync reads `_cachedTier`.
- AC3: Default `_cachedTier = SubscriptionTier.accountFree` before first `refresh()` — `accountFree` is the safe fallback.
- AC4: `SubscriptionBloc` emits `error(SubscriptionFailure)` on `CheckEntitlementUseCase` failure; `EntitlementGate._cachedTier` preserved because `refresh()` is not called on error path (unawaited call only after datasource success).
- AC5: `SubscriptionBloc` self-dispatches `SubscriptionCheckRequested` in constructor; `initial → loading → loaded` resolves from RevenueCat local cache before first frame.
- AC6: `user_profile.install_cohort` nullable TEXT column; migration v8→v9 backfills `'pre_v2'`; `onboarding_repository_impl.dart` writes `'post_v2'` for new installs; `schemaVersion = 9`.
- AC7: `flutter analyze` = 0 issues; `flutter test` = 943 passed, 0 failed (11 new tests: 4 bloc + 5 entitlement gate + 2 DB migration).

### File List

- `pubspec.yaml` — added `purchases_flutter: ^10.3.0`
- `pubspec.lock` — updated
- `lib/main.dart` — Purchases.configure() boot-order injection (after Supabase, before DI)
- `lib/app.dart` — SubscriptionBloc added to root MultiBlocProvider
- `lib/core/error/failures.dart` — SubscriptionFailure class added
- `lib/core/cloud/entitlement_gate.dart` — NEW @singleton
- `lib/core/database/tables/user_profile_table.dart` — installCohort column
- `lib/core/database/app_database.dart` — schemaVersion 9, v8→v9 migration
- `lib/core/database/app_database.g.dart` — GENERATED (drift build_runner)
- `lib/core/di/injection.config.dart` — GENERATED (injectable build_runner)
- `lib/features/subscription/domain/entities/subscription_tier.dart` — NEW
- `lib/features/subscription/domain/entities/feature.dart` — NEW
- `lib/features/subscription/domain/repositories/entitlement_repository.dart` — NEW
- `lib/features/subscription/domain/usecases/check_entitlement_use_case.dart` — NEW
- `lib/features/subscription/data/datasources/subscription_remote_data_source.dart` — NEW
- `lib/features/subscription/data/repositories/entitlement_repository_impl.dart` — NEW
- `lib/features/subscription/presentation/bloc/subscription_bloc.dart` — NEW
- `lib/features/subscription/presentation/bloc/subscription_event.dart` — NEW
- `lib/features/subscription/presentation/bloc/subscription_state.dart` — NEW
- `lib/features/subscription/presentation/bloc/subscription_bloc.freezed.dart` — GENERATED
- `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart` — installCohort: 'post_v2'
- `test/bloc/subscription_bloc_test.dart` — NEW (4 tests)
- `test/bloc/subscription_bloc_test.mocks.dart` — GENERATED
- `test/data/subscription/entitlement_gate_test.dart` — NEW (5 tests)
- `test/data/subscription/entitlement_gate_test.mocks.dart` — GENERATED
- `test/core/database/app_database_test.dart` — schemaVersion 8→9 + 2 new migration tests
- `test/core/database/data_persistence_test.dart` — schemaVersion 8→9 assertion update
