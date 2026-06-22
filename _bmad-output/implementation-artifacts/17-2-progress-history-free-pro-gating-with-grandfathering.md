---
baseline_commit: 81c8628
---

# Story 17.2: Progress History Free/Pro Gating with Grandfathering

Status: done

## Story

As a pre-v2 user (grandfathered) or a Pro subscriber,
I want full access to my Progress history and all charts,
So that existing users are not retroactively paywalled for data they already had.

## Acceptance Criteria

**AC1 — Grandfathered user sees full Progress (FR61, ARCH25):**
Given a user whose local drift `user_profile.install_cohort` = `'pre_v2'`
When they open the Progress screen
Then the full session history timeline and all four animated charts are visible regardless of `SubscriptionBloc` tier

**AC2 — Post-v2 free user sees limited Progress (FR59, FR61, UX-DR25):**
Given a user whose local drift `user_profile.install_cohort` = `'post_v2'` AND `SubscriptionBloc` state is `loaded(tier: accountFree)` or `loaded(tier: signedInFree)`
When they open the Progress screen
Then only the current weekly goal widget is visible; the tab bar, history list, and charts are replaced by a single tappable prompt: "Lo storico completo è una funzione Pro."
And there is NO persistent lock icon, badge, or "🔒" glyph anywhere on Free screens

**AC3 — Tapping the prompt opens ProUpsellSheet (UX-DR25):**
Given a post-v2 free user is on the limited Progress screen
When they tap "Lo storico completo è una funzione Pro."
Then `ProUpsellSheet.show(context)` is called, displaying the Pro upsell bottom sheet stub (see Dev Notes §ProUpsellSheet stub)

**AC4 — Pro unlock reveals full content in-place:**
Given a post-v2 user purchases a Pro subscription (handled by Story 17.4; this story reacts to the state change)
When `SubscriptionBloc` emits `loaded(tier: pro)` (driven reactively by the root `MultiBlocProvider`)
Then the full Progress history timeline and all four animated charts appear in-place immediately — no celebration screen, no badge

**AC5 — installCohort restored from Supabase profiles on sign-in (FR61, ARCH25):**
Given a pre-v2 user who reinstalls the app (local drift now has no installCohort row or has `'post_v2'`)
When they sign in via any method (email / Apple / Google) and the `profiles` Supabase row has `install_cohort = 'pre_v2'`
Then the local `user_profile.install_cohort` is updated to `'pre_v2'` (restoring grandfathered full access); this sync is best-effort (failure must not block sign-in or the free core — NFR34)

**AC6 — installCohort written to Supabase profiles on sign-in:**
Given a signed-in user with any local `installCohort` value
When sign-in succeeds
Then the `profiles` row is upserted with the local `installCohort`; a `'pre_v2'` value in the cloud is never downgraded to `'post_v2'` (merge rule: `pre_v2` wins)

**AC7 — Zero regressions:**
Given the implementation is complete
When `flutter analyze` and `flutter test` run from `pulse_coach/`
Then both report zero issues and all existing 943 tests continue to pass; new tests are green

## Tasks / Subtasks

- [x] **Task 1 — Add `getInstallCohort()` to OnboardingRepository (AC1, AC5)**
  - [x] 1.1 Add `Future<Either<Failure, String?>> getInstallCohort()` to `lib/features/onboarding/domain/repositories/onboarding_repository.dart` (abstract method)
  - [x] 1.2 Implement in `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart`: call `_db.userProfileDao.getProfile()` → return `Right(data?.installCohort)` or `Left(CacheFailure('install_cohort_load_failed'))`

- [x] **Task 2 — `GetInstallCohortUseCase` in subscription domain (AC1)**
  - [x] 2.1 Create `lib/features/subscription/domain/usecases/get_install_cohort_use_case.dart` — `@injectable`, single call method returning `Either<Failure, String?>`; imports `OnboardingRepository` abstract (cross-feature domain dependency is allowed by clean arch; no data-layer import)
  - [x] 2.2 Register with `@injectable` and run `build_runner` at end of all tasks (not now)

- [x] **Task 3 — `updateInstallCohort` on `UserProfileDao` (AC5)**
  - [x] 3.1 Add `Future<void> updateInstallCohort(String cohort)` to `lib/core/database/daos/user_profile_dao.dart`
  - [x] 3.2 Targeted partial update via `UserProfileCompanion(installCohort: Value(cohort))`

- [x] **Task 4 — `ProgressGatingCubit` (AC1, AC2, AC4)**
  - [x] 4.1 Create `lib/features/progress/presentation/bloc/progress_gating_state.dart` — plain sealed class
  - [x] 4.2 Create `lib/features/progress/presentation/bloc/progress_gating_cubit.dart` — `@injectable`; safe default on error

- [x] **Task 5 — `ProUpsellSheet` stub (AC3)**
  - [x] 5.1 Create `lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart`
  - [x] 5.2 Displays fact string + `Scopri Pro` (primary) + `non ora` (secondary/text) buttons
  - [x] 5.3 No cooldown logic
  - [x] 5.4 No persistent lock icons
  - [x] 5.5 Wrapped in `Semantics`

- [x] **Task 6 — Gate `ProgressPage` UI (AC1, AC2, AC3, AC4)**
  - [x] 6.1 Added `BlocProvider<ProgressGatingCubit>` to `ProgressPage.build` MultiBlocProvider
  - [x] 6.2 Restructured `_ProgressView`: shimmer on initial, nested BlocBuilder pattern
  - [x] 6.3 Created `_ProgressLockedBanner` — tappable text, no lock icon
  - [x] 6.4 `DefaultTabController` moved inside full-access branch (`_FullProgressContent`)

- [x] **Task 7 — installCohort sync on sign-in (AC5, AC6)**
  - [x] 7.1 `AuthRepositoryImpl` constructor now takes `AppDatabase _db` and `SupabaseClientProvider _supabase`
  - [x] 7.2 `_syncInstallCohort(userId)` implemented with merge rule and try/catch
  - [x] 7.3 `unawaited(_syncInstallCohort(user.id))` in signInWithApple, signInWithGoogle, signInWithEmail
  - [x] 7.4 `@visibleForTesting` seams `cloudCohortReader`/`cloudCohortWriter` for test isolation

- [x] **Task 8 — `build_runner` and DI wiring (AC7)**
  - [x] 8.1 `dart run build_runner build` run from `pulse_coach/`
  - [x] 8.2 `injection.config.dart` confirmed to contain `GetInstallCohortUseCase`, `ProgressGatingCubit`, updated `AuthRepositoryImpl` factory
  - [x] 8.3 Generated files updated

- [x] **Task 9 — Tests (AC1–AC6, AC7)**
  - [x] 9.1 `test/bloc/progress_gating_cubit_test.dart` — 5 tests (pre_v2/post_v2/null/error/initial)
  - [x] 9.2 `test/features/subscription/get_install_cohort_use_case_test.dart` — 4 tests
  - [x] 9.3 `test/features/auth/auth_repository_impl_sync_test.dart` — 3 tests (SYNC-001..003)
  - [x] 9.4 `flutter test` — 958/958 green; `flutter analyze` 0 issues

## Dev Notes

### E9-K1 Fire-Check Results (Category B standing rule)

**(a) DI/lifecycle/cross-cutting patches [E6-P1 scope]:**
**TRIGGERED.** This story:
- Adds `ProgressGatingCubit` and `GetInstallCohortUseCase` to DI
- Modifies `AuthRepositoryImpl` constructor (adds `AppDatabase` + `SupabaseClientProvider` dependencies → injectable re-generates the factory)
- Adds `updateInstallCohort` to `UserProfileDao` (no build_runner re-gen needed for this method, it's a plain Dart method, not a query annotation)

DI re-generation is required. Run `build_runner` once after all source changes (not incrementally).

**(b) E16R-1 trigger check:**
E16R-1 (auth/backup datasource test hardening) was scheduled for "early in Epic 17." It was active (2/5 Category A) at triage. This story modifies `AuthRepositoryImpl` — if `E16R-1` tests are to be co-located here, do so. Otherwise schedule as a standalone PR immediately after 17.2. Do NOT let it slip past 17.3.

**(c) Cubit/BLoC collection-index pre-flight [E7-P2]:**
**NOT triggered.** `ProgressGatingCubit` holds a `bool isGrandfathered`, not a positional index.

### Critical: SubscriptionBloc is at root — do NOT re-provide it in ProgressPage

`SubscriptionBloc` is already in the root `MultiBlocProvider` in `lib/app.dart`. `ProgressPage` must read it via `context.read<SubscriptionBloc>()` or `BlocBuilder<SubscriptionBloc, SubscriptionState>()` — do NOT add another `BlocProvider<SubscriptionBloc>` inside `ProgressPage`, that would shadow the root instance and create a separate, unconfigured bloc.

### Critical: ProgressGatingCubit is @injectable (not @singleton)

Match the pattern of `ProgressCubit` and `ProgressStatsCubit` (both `@injectable`). The cubit is provided by `ProgressPage.build` via `BlocProvider(create: (_) => getIt<ProgressGatingCubit>()..load())`. It is closed when the Progress tab is disposed. A `@singleton` would produce a closed-cubit regression on re-navigation (same bug the existing cubits explicitly document).

### Critical: `getInstallCohort` path when no profile row exists

`UserProfileDao.getProfile()` returns `null` if the profile table is empty (pre-onboarding state). `GetInstallCohortUseCase` must handle `null` profile → return `Right(null)`. `ProgressGatingCubit` treats `null` cohort as `isGrandfathered: false` (safe default, not a failure).

### Critical: `_syncInstallCohort` must be unawaited and swallow all errors

Pattern from the v1 codebase: side-effect cloud syncs after sign-in are called unawaited. Example: `BackupBloc` listens to `AuthBloc` and triggers backup after sign-in, but never blocks the sign-in completion. `_syncInstallCohort` follows the same pattern:
- Call with `unawaited(_syncInstallCohort(user.id))` in each `signInWith*` method **after** `return Right(user)` is computed but before it is returned — wait, that's wrong. The function has already returned. Use:
  ```dart
  final user = await _dataSource.signInWithApple();
  unawaited(_syncInstallCohort(user.id));  // fire-and-forget before returning
  return Right(user);
  ```
- The `try/catch` in `_syncInstallCohort` wraps the ENTIRE body. A throw in `Supabase.client.from(...)` does not propagate to the caller.

### ProUpsellSheet Stub Design (Story 17.3 will extend this)

Story 17.3 owns: cooldown logic, session/day suppression, recording the dismissal timestamp. Story 17.2 creates only the stub widget that Story 17.3 will extend in-place (no skeleton rewrite needed).

The stub must:
- Show a bottom sheet (not a dialog — UX-DR25 specifies bottom sheet via `showModalBottomSheet`)
- State one fact string (not a list of features)
- Two buttons in a `Row`: `Scopri Pro` (primary) and `non ora` (secondary/text style)
- `non ora` button closes the sheet with `Navigator.pop(context)`
- `Scopri Pro` also closes the sheet for now (Story 17.4 wires the purchase flow)
- Both buttons carry `Semantics` labels (UX-DR32)

### Supabase `profiles` table structure (from `supabase/migrations/0001_profiles_auth.sql`)

```sql
CREATE TYPE install_cohort_enum AS ENUM ('pre_v2', 'post_v2');
CREATE TABLE profiles (
  id              uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  install_cohort  install_cohort_enum NOT NULL DEFAULT 'post_v2',
  ...
);
```

The client can write `'pre_v2'` or `'post_v2'` as plain strings via PostgREST — the Postgres enum accepts them. The RLS policy allows each user to read/insert/update their own row only.

Upsert call pattern (PostgREST via supabase_flutter):
```dart
await _supabase.client.from('profiles').upsert(
  {'id': userId, 'install_cohort': canonicalCohort},
  onConflict: 'id',
);
```

Read call:
```dart
final row = await _supabase.client
    .from('profiles')
    .select('install_cohort')
    .eq('id', userId)
    .maybeSingle();
final cloudCohort = row?['install_cohort'] as String?;
```

`maybeSingle()` returns null if no row exists (new sign-in where profiles row hasn't been created yet). Handle `null` → treat as `'post_v2'`.

### Merge rule for installCohort (never downgrade)

```
canonical = (cloud == 'pre_v2' || local == 'pre_v2') ? 'pre_v2' : 'post_v2'
```

This ensures a user who was pre-v2 on any device retains grandfathered access everywhere, regardless of reinstall order. Applied in `_syncInstallCohort` client-side.

### ProgressPage gating UI layout

**When `showFull = true` (grandfathered OR Pro):**
```
WeeklyGoalIndicator         ← unchanged (always visible)
TabBar (Cronologia | Grafici) ← unchanged
TabBarView [HistoryTab, ChartsTab] ← unchanged
```

**When `showFull = false` (post-v2 free):**
```
WeeklyGoalIndicator         ← unchanged
_ProgressLockedBanner       ← tappable text: "Lo storico completo è una funzione Pro."
                              (no tab bar, no lock icon, no history or charts)
```

The `_ProgressLockedBanner` must NOT look like a locked element — it is a plain text prompt per UX-DR25 "paywall speaks only through the sheet, never through ambient pressure signals."

### Reactive unlock (AC4)

When `SubscriptionBloc` emits `loaded(tier: pro)` after purchase (Story 17.4), the `BlocBuilder<SubscriptionBloc, SubscriptionState>` in `_ProgressView` will rebuild automatically because `SubscriptionBloc` is at root and its stream propagates to all descendants. No extra event needed on `ProgressGatingCubit` — the gating cubit only provides the static `isGrandfathered` fact, which does not change within a session.

### Existing ProgressPage — do NOT break

`ProgressPage` currently provides `ProgressCubit` and `ProgressStatsCubit`. These cubits are still needed and must still be provided regardless of gating state (they are used by the full-access path). Do not remove them from `MultiBlocProvider`. The gating only controls which widgets are shown, not which cubits are loaded.

`DefaultTabController(length: 2)` should only be present when the tab bar is visible (full access path). Move it inside the full-access branch, not at the top level.

### Build order for files

Create in this order to avoid import resolution issues:
1. `onboarding_repository.dart` + `onboarding_repository_impl.dart` (add getInstallCohort)
2. `user_profile_dao.dart` (add updateInstallCohort)
3. `get_install_cohort_use_case.dart`
4. `progress_gating_state.dart`
5. `progress_gating_cubit.dart`
6. `pro_upsell_sheet.dart`
7. `progress_page.dart` (update)
8. `auth_repository_impl.dart` (update)
9. `build_runner`

### Project Structure — New Files

```
lib/features/subscription/
  ├── domain/usecases/
  │   └── get_install_cohort_use_case.dart         # NEW
  └── presentation/widgets/
      └── pro_upsell_sheet.dart                    # NEW (stub)

lib/features/progress/presentation/bloc/
  ├── progress_gating_state.dart                   # NEW
  └── progress_gating_cubit.dart                  # NEW

test/
  ├── bloc/
  │   └── progress_gating_cubit_test.dart          # NEW
  ├── features/subscription/
  │   └── get_install_cohort_use_case_test.dart    # NEW
  └── features/auth/
      └── auth_repository_impl_sync_test.dart      # NEW
```

### Project Structure — Modified Files

```
lib/features/onboarding/domain/repositories/onboarding_repository.dart   # +getInstallCohort()
lib/features/onboarding/data/repositories/onboarding_repository_impl.dart # +getInstallCohort()
lib/core/database/daos/user_profile_dao.dart                              # +updateInstallCohort()
lib/features/progress/presentation/pages/progress_page.dart              # +gating UI
lib/features/auth/data/repositories/auth_repository_impl.dart            # +_syncInstallCohort()
lib/core/di/injection.config.dart                                         # GENERATED
```

### References

- Epic 17.2 ACs: `_bmad-output/planning-artifacts/epics.md#Story 17.2`
- FR61 (grandfathering): `_bmad-output/planning-artifacts/epics.md` line 95
- ARCH25 (installCohort in drift + profiles mirror): `_bmad-output/planning-artifacts/architecture.md` line 403
- UX-DR25 (ProUpsellSheet, no lock badges): `_bmad-output/planning-artifacts/epics.md` line 235
- UX-DR32 (VoiceOver/TalkBack): `_bmad-output/planning-artifacts/epics.md` line 242
- NFR34 (cloud failure must not block free core): referenced throughout
- Supabase profiles migration: `supabase/migrations/0001_profiles_auth.sql`
- `EntitlementGate` (Story 17.1): `lib/core/cloud/entitlement_gate.dart`
- `SubscriptionBloc` (Story 17.1): `lib/features/subscription/presentation/bloc/subscription_bloc.dart`
- `ProgressPage` (existing): `lib/features/progress/presentation/pages/progress_page.dart`
- `ProgressCubit` lifecycle note (why @injectable not @singleton): `lib/features/progress/presentation/bloc/progress_cubit.dart#L9-11`
- `UserProfileDao`: `lib/core/database/daos/user_profile_dao.dart`
- `OnboardingRepositoryImpl`: `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart`
- `AuthRepositoryImpl`: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Project context (DI order, Bloc/Cubit rules, test structure): `_bmad-output/project-context.md`
- Previous story dev notes (boot order, unawaited pattern): `_bmad-output/implementation-artifacts/17-1-revenuecat-iap-integration-and-entitlement-gate.md#Dev Notes`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Implemented full free/Pro gating for ProgressPage via `ProgressGatingCubit` + `SubscriptionBloc` nested BlocBuilder pattern.
- `getInstallCohort()` added to `OnboardingRepository` abstract + impl; `updateInstallCohort()` added to `UserProfileDao`.
- `GetInstallCohortUseCase` created in subscription domain (cross-feature domain dep, no data-layer import).
- `ProUpsellSheet` stub created with `Semantics` wrapping, `Scopri Pro` + `non ora` buttons.
- `AuthRepositoryImpl` extended with `_syncInstallCohort` (merge rule: pre_v2 wins), `@visibleForTesting` seams `cloudCohortReader`/`cloudCohortWriter` used for test isolation without mocking Supabase client directly.
- `DefaultTabController` moved inside `_FullProgressContent` (only present when showFull=true).
- All existing widget tests that used `ProgressPage` updated to register `ProgressGatingCubit` + `SubscriptionBloc` root provider.
- Legacy `auth_repository_impl_test.dart` updated to pass new constructor; cloud sync disabled via seams.
- 958/958 tests green; `flutter analyze` 0 issues.

### File List

**New files:**
- `lib/features/subscription/domain/usecases/get_install_cohort_use_case.dart`
- `lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart`
- `lib/features/progress/presentation/bloc/progress_gating_state.dart`
- `lib/features/progress/presentation/bloc/progress_gating_cubit.dart`
- `test/bloc/progress_gating_cubit_test.dart`
- `test/bloc/progress_gating_cubit_test.mocks.dart`
- `test/features/subscription/get_install_cohort_use_case_test.dart`
- `test/features/subscription/get_install_cohort_use_case_test.mocks.dart`
- `test/features/auth/auth_repository_impl_sync_test.dart`
- `test/features/auth/auth_repository_impl_sync_test.mocks.dart`

**Modified files:**
- `lib/features/onboarding/domain/repositories/onboarding_repository.dart`
- `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart`
- `lib/core/database/daos/user_profile_dao.dart`
- `lib/features/progress/presentation/pages/progress_page.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/core/di/injection.config.dart`
- `test/widget/progress/progress_page_test.dart`
- `test/widget/progress/progress_page_test.mocks.dart`
- `test/widget/app_shell_test.dart`
- `test/widget/pages_smoke_test.dart`
- `test/data/auth/auth_repository_impl_test.dart`
- `test/data/auth/auth_repository_impl_test.mocks.dart`

### Review Findings

_Code review 2026-06-22 (3 adversarial layers: Blind Hunter, Edge Case Hunter, Acceptance Auditor). Triage: 1 decision-needed, 2 patch, 3 defer, 8 dismissed as noise/false-positive._

- [x] [Review][Patch] SubscriptionBloc non-loaded state showed the locked banner to non-grandfathered Pro users — `progress_page.dart:63-65`. **Fixed (option 1):** `_ProgressView` now shows `_ProgressLoadingShimmer` while the subscription is `initial`/`loading`; the locked banner appears only on `error` or `loaded(free)`. (blind+edge)
- [x] [Review][Patch] AC4 reactive in-place unlock had no automated test. **Fixed:** added `17.2-WIDGET-003` — drives `signedInFree → loaded(tier: pro)` on the root `SubscriptionBloc` and asserts the `TabBar` appears in-place [`test/widget/progress/progress_page_test.dart`]. (auditor)
- [x] [Review][Patch] `_syncInstallCohort` empty `catch (_) {}` swallowed every failure silently. **Fixed:** now `catch (e)` with `debugPrint(...)` (matches the `EntitlementGate`/`main.dart` NFR34 best-effort pattern; release-stripped) [`auth_repository_impl.dart:67`]. (blind)
- [x] [Review][Defer] User-facing strings hardcoded as Italian literals bypass the gen_l10n/ARB pipeline (locked banner, ProUpsellSheet, `Cronologia`/`Grafici` tabs) [`progress_page.dart:108,143`, `pro_upsell_sheet.dart`] — deferred: matches pre-existing ProgressPage style, spec mandated literal copy, app locale-locked to `it`; folds into i18n debt (E7.5-T1). (blind+auditor)
- [x] [Review][Defer] `ProgressGatingCubit` does not recover from a transient load error within a session — an entitled grandfathered user hitting a one-time DB read error is locked until the cubit is rebuilt [`progress_gating_cubit.dart:18-20`] — deferred: by-design safe default, low probability on a single-row local read. (blind)
- [x] [Review][Defer] Test SYNC-003 asserts only `result isA<Right>`, not the swallow path's effect on local DB [`auth_repository_impl_sync_test.dart`] — deferred: low-value test-quality follow-up. (blind)

**Dismissed (false positives / handled / unreachable):** `updateInstallCohort` "clobbers all rows" (single-row invariant enforced by `insertProfile`); write-lost when no profile row (onboarding always creates the row before sign-in is reachable); cloud "poisoning" with `post_v2` (merge rule never downgrades `pre_v2`); unknown cohort string rewritten (enum-constrained to `{pre_v2,post_v2}`); concurrent sign-in race (single-shot UI); `as String?` throws on non-string (enum column); `getSingleOrNull` throws on multiple rows (single-row invariant); non-exhaustive sealed gating state (only 2 concrete states, `Initial` handled above).
