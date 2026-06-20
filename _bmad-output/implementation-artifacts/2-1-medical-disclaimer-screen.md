# Story 2.1: Medical Disclaimer Screen

Status: done

## Story

As a new user,
I want to see a medical disclaimer before using any app features,
so that I understand this is not a medical device and can make an informed decision to proceed.

## Acceptance Criteria

1. **Given** the app is opened for the first time
   **When** the disclaimer screen renders
   **Then** it displays a clear, readable disclaimer stating the app is not a medical device and is not a substitute for professional medical advice

2. **Given** the disclaimer is displayed
   **When** the user taps "I Understand"
   **Then** acceptance is persisted to the local database (not in-memory only) and the user proceeds to the onboarding flow (NFR10)

3. **Given** disclaimer has been accepted
   **When** the app is re-opened
   **Then** the disclaimer screen is not shown again — the router bypasses it

4. **Given** the disclaimer screen is displayed
   **Then** there is no way to skip or dismiss it without explicitly tapping the acceptance button (FR3)

## Tasks / Subtasks

- [x] Task 1: Create domain + data layer for disclaimer acceptance (AC: 2)
  - [x] 1.1 Create `lib/features/onboarding/domain/repositories/onboarding_repository.dart` — abstract interface with `acceptDisclaimer()` and `isDisclaimerAccepted()` methods
  - [x] 1.2 Create `lib/features/onboarding/domain/usecases/accept_disclaimer.dart` — calls `onboardingRepository.acceptDisclaimer()`; returns `Either<Failure, void>`
  - [x] 1.3 Create `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart` — implements `acceptDisclaimer()`: inserts profile row via `UserProfileDao.insertProfile()` if none exists, or calls `updateProfile()` if row exists; sets `disclaimerAccepted: true`
  - [x] 1.4 Register `OnboardingRepository` / `OnboardingRepositoryImpl` with `@injectable` / `@lazySingleton`, run `dart run build_runner build --delete-conflicting-outputs`

- [x] Task 2: Create OnboardingCubit and state (AC: 2, 4)
  - [x] 2.1 Create `lib/features/onboarding/presentation/bloc/onboarding_state.dart` — `@freezed` union: `initial`, `loading`, `disclaimerPending`, `disclaimerAccepted`, `error(String message)`
  - [x] 2.2 Create `lib/features/onboarding/presentation/bloc/onboarding_cubit.dart` — `@injectable` Cubit; constructor injects `AcceptDisclaimer` and `CheckDisclaimerStatus` use cases; `acceptDisclaimer()` emits `loading` → calls use case → emits `disclaimerAccepted` or `error`; `checkInitialStatus()` skips disclaimer if already accepted
  - [x] 2.3 Register `OnboardingCubit` with `@injectable`, run build_runner

- [x] Task 3: Build DisclaimerScreen widget and wire OnboardingPage (AC: 1, 2, 4)
  - [x] 3.1 Create `lib/features/onboarding/presentation/widgets/disclaimer_screen.dart` — stateful widget; shows privacy narrative ("Your data stays yours.") + medical disclaimer text + checkbox + disabled-until-checked continue button
  - [x] 3.2 Update `lib/features/onboarding/presentation/pages/onboarding_page.dart` — StatefulWidget; provides `OnboardingCubit` via `BlocProvider.value`; calls `checkInitialStatus()` on init to skip disclaimer if already accepted; on `disclaimerAccepted` state shows next step placeholder

- [x] Task 4: Update router redirect to fix semantic correctness (AC: 3, 4)
  - [x] 4.1 Update `lib/core/routing/app_router.dart` `_redirect()`: checks `disclaimerAccepted` and `onboardingCompleted` separately; redirects to `/onboarding` if disclaimer not accepted or onboarding not complete; redirects to `/today` only when `onboardingCompleted=true`

- [x] Task 5: Tests (AC: 1–4)
  - [x] 5.1 Create `test/bloc/onboarding_cubit_test.dart` — 4 unit tests: initial state, success path, failure path, sequential calls
  - [x] 5.2 Create `test/widget/onboarding_page_test.dart` — 5 widget tests: disclaimer visible, button disabled, checkbox enables button, tap triggers cubit, no back/skip
  - [x] 5.3 Update `test/core/routing/app_router_test.dart` — 4 new redirect scenarios (2.1-UNIT-005/006 + updated 1.7-UNIT-001/002); update `test/widget/pages_smoke_test.dart` and `test/widget/app_test.dart` for new OnboardingPage structure

## Dev Notes

### UX Design Decision — Not a Legal Wall

**Critical:** The medical disclaimer is NOT a cold standalone legal screen. Per UX spec, it is styled as **Onboarding Screen 2**: a screen with a privacy narrative ("Your data stays yours."), a one-line medical disclaimer shown inline, and a **checkbox** labeled "I understand PulseCoach is not a medical device and does not replace professional medical advice." The "Continue" button is disabled until the checkbox is checked.

This is distinct from a modal or a button labeled "I Understand" (epic language). Implement as a checkbox + disabled-continue pattern, not a big button. The copy framing is important: privacy story → disclaimer → proceed.

### Current Project State (Critical — Read Before Implementing)

The `disclaimerAccepted` column **already exists** in the DB. Schema v2 migration was committed in `26cb7aa`. The column is in `user_profile_table.dart`:
```dart
BoolColumn get disclaimerAccepted =>
    boolean().withDefault(const Constant(false))();
BoolColumn get onboardingCompleted =>
    boolean().withDefault(const Constant(false))();
```

`UserProfileDao` already has `insertProfile()` (throws if row exists) and `updateProfile()`. The onboarding repository must handle both the first-launch case (no row yet → `insertProfile`) and the case where the app crashed after partial setup (row exists with `disclaimerAccepted: false` → `updateProfile`).

The `OnboardingPage` currently shows `'Onboarding — Story 2.x'` stub. The existing router test `1.7-UNIT-001` expects this text — it will break when you replace the stub. Update the test expectation to the new disclaimer screen widget content.

### Router Redirect — Required Update

Current `app_router.dart` `_redirect()` logic:
```dart
final onboardingComplete = userProfile != null;  // WRONG — semantically incorrect
```

Semantically correct logic for after this story:
```dart
final disclaimerAccepted = userProfile?.disclaimerAccepted ?? false;
final onboardingComplete = userProfile?.onboardingCompleted ?? false;

if (!disclaimerAccepted && !goingToOnboarding) return onboarding;      // no disclaimer yet
if (disclaimerAccepted && !onboardingComplete && !goingToOnboarding) return onboarding; // mid-flow
if (onboardingComplete && (goingToOnboarding || atRoot)) return today;
return null;
```

This consolidates both "no profile" and "has profile but disclaimer not accepted" to redirect to `/onboarding`. The `OnboardingPage` handles internal step routing.

### Redirect Test Scenarios (from Epic 1 Retro)

These 4 test cases were explicitly deferred from Story 1.7 to this story:
1. **No profile** → redirect to `/onboarding` (disclaimer screen shown)
2. **Profile with `disclaimerAccepted: false`** → redirect to `/onboarding` (disclaimer screen)
3. **Profile with `disclaimerAccepted: true, onboardingCompleted: false`** → redirect to `/onboarding` (onboarding continues, disclaimer not shown)
4. **Profile with `onboardingCompleted: true`** → redirect to `/today`

Test structure mirrors existing `app_router_test.dart`: register an in-memory `AppDatabase`, seed the required profile state in `setUp`, pump `PulseCoachApp`, assert correct page content renders.

### Clean Architecture Layer Structure

Follow the feature-first structure already established:
```
lib/features/onboarding/
├── data/
│   └── repositories/
│       └── onboarding_repository_impl.dart   ← NEW
├── domain/
│   ├── repositories/
│   │   └── onboarding_repository.dart        ← NEW (abstract interface)
│   └── usecases/
│       ├── accept_disclaimer.dart            ← NEW
│       └── check_disclaimer_status.dart      ← NEW (added during impl for AC3 correctness)
└── presentation/
    ├── bloc/
    │   ├── onboarding_cubit.dart             ← NEW
    │   └── onboarding_state.dart             ← NEW (@freezed)
    ├── pages/
    │   └── onboarding_page.dart              ← MODIFIED (was stub)
    └── widgets/
        └── disclaimer_screen.dart            ← NEW
```

**No `UserProfile` domain entity in this story.** The repository operates directly on `UserProfileData` (Drift-generated) and `UserProfileCompanion`. A proper `UserProfile` domain entity (freezed, nullable fields for partial state) may be introduced in Story 2.3 when the full profile is built. Do not preemptively add it here.

### State Management Pattern

`OnboardingCubit` is UI-only state (ARCH6 mandate). It should:
- Be `@injectable` (created per use via DI)
- Inject `AcceptDisclaimer` use case and `CheckDisclaimerStatus` use case
- Have `acceptDisclaimer()` as the main user action method
- Have `checkInitialStatus()` called by `OnboardingPage.initState` to skip disclaimer if already accepted

```dart
// Correct freezed state pattern (mirror other state files):
@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState.initial() = OnboardingInitial;
  const factory OnboardingState.loading() = OnboardingLoading;
  const factory OnboardingState.disclaimerPending() = OnboardingDisclaimerPending;
  const factory OnboardingState.disclaimerAccepted() = OnboardingDisclaimerAccepted;
  const factory OnboardingState.error(String message) = OnboardingError;
}
```

Initial state is `disclaimerPending()` (not `initial()`), so the UI renders the disclaimer immediately without flash.

### DI Registration Order

Maintain the required injection order: datasource → repository → use case → cubit.

### DisclaimerScreen Widget Design

Based on UX spec, the screen layout:
- `Scaffold` with no `AppBar` (full-screen onboarding feel)
- Top half: Privacy narrative copy ("Your data stays yours." + 2-3 lines explaining on-device only)
- Middle: Medical disclaimer text — "I understand PulseCoach is not a medical device and does not replace professional medical advice"
- Checkbox (`StatefulWidget` or managed by cubit) — starts unchecked
- Bottom: `FilledButton` "Continue" — disabled until checkbox is checked
- **No back button, no skip, no close.** `PopScope(canPop: false)` to prevent back navigation

### Either Error Handling

Use case returns `Either<Failure, void>`. Known `dartz` API (v0.10.1) quirk: `isLeft()` and `isRight()` are instance methods, not extension getters. Use `.fold()` for pattern matching in cubit.

### Test Count Target

Starting: 42 tests (from Story 1.7).
After 2.1: **82 tests** (exceeded target of 52-56 due to more comprehensive coverage).

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Onboarding Flow — Screen 2]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Design Tokens]
- [Source: _bmad-output/planning-artifacts/architecture.md#Dependency Injection, State Management, Repository Pattern]
- [Source: _bmad-output/implementation-artifacts/epic-1-retro-2026-03-28.md#Schema Gap: disclaimerAccepted + Redirect Logic]
- [Source: _bmad-output/implementation-artifacts/1-7-app-shell-and-navigation-scaffold-phone.md#Dev Notes]
- [Source: pulse_coach/lib/core/database/tables/user_profile_table.dart — disclaimerAccepted column exists]
- [Source: pulse_coach/lib/core/routing/app_router.dart — redirect needs update]
- [Source: pulse_coach/test/core/routing/app_router_test.dart — test 1.7-UNIT-001 will break]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- build_runner ran successfully 4 times (after tasks 1, 2, 3/mocks, 4/mocks-CheckDisclaimerStatus)
- `app_router_test.dart` required registering OnboardingCubit DI chain in all test groups — GoRouter briefly mounts OnboardingPage even when navigating to /today due to async redirect
- `CheckDisclaimerStatus` use case added (not in original story spec) to support `checkInitialStatus()` in cubit for AC3: disclaimer screen must not show again after acceptance
- Old test 1.7-UNIT-001 expectation updated (stub text → disclaimer screen content)
- `pages_smoke_test.dart` and `app_test.dart` required DI setup for OnboardingCubit

### Completion Notes List

- ✅ Task 1: OnboardingRepository (abstract + impl), AcceptDisclaimer use case, DI registration
- ✅ Task 2: OnboardingState (@freezed), OnboardingCubit (@injectable), CheckDisclaimerStatus use case added for initial state check
- ✅ Task 3: DisclaimerScreen (StatefulWidget, checkbox+button, PopScope(canPop:false)), OnboardingPage (StatefulWidget, calls checkInitialStatus on init)
- ✅ Task 4: Router redirect updated to use disclaimerAccepted + onboardingCompleted separately
- ✅ Task 5: 82 tests total (40 new/updated), all passing, 0 regressions

### File List

lib/features/onboarding/domain/repositories/onboarding_repository.dart
lib/features/onboarding/domain/usecases/accept_disclaimer.dart
lib/features/onboarding/domain/usecases/check_disclaimer_status.dart
lib/features/onboarding/data/repositories/onboarding_repository_impl.dart
lib/features/onboarding/presentation/bloc/onboarding_state.dart
lib/features/onboarding/presentation/bloc/onboarding_state.freezed.dart
lib/features/onboarding/presentation/bloc/onboarding_cubit.dart
lib/features/onboarding/presentation/widgets/disclaimer_screen.dart
lib/features/onboarding/presentation/pages/onboarding_page.dart
lib/core/routing/app_router.dart
test/bloc/onboarding_cubit_test.dart
test/bloc/onboarding_cubit_test.mocks.dart
test/widget/onboarding_page_test.dart
test/widget/onboarding_page_test.mocks.dart
test/widget/app_test.dart
test/widget/pages_smoke_test.dart
test/widget/pages_smoke_test.mocks.dart
test/core/routing/app_router_test.dart

### Review Findings

- [x] [Review][Patch] No error UI feedback to user on acceptDisclaimer failure — added BlocListener with SnackBar [disclaimer_screen.dart]
- [x] [Review][Patch] `OnboardingState.initial()` is dead code — removed unused variant, regenerated freezed [onboarding_state.dart]
- [x] [Review][Patch] DI registration mismatch: `lazySingleton` in prod vs `factory` in tests — changed to `registerLazySingleton` [app_router_test.dart, app_test.dart, pages_smoke_test.dart]
- [x] [Review][Patch] No test for `checkInitialStatus` happy path — added blocTest 2.1-UNIT-007 [onboarding_cubit_test.dart]
- [x] [Review][Patch] No test for `checkInitialStatus` failure path — added blocTest 2.1-UNIT-008 [onboarding_cubit_test.dart]
- [x] [Review][Patch] No guard against concurrent `acceptDisclaimer` invocations — added early return guard [onboarding_cubit.dart]
- [x] [Review][Patch] Checkbox GestureDetector double-toggle risk — set Checkbox.onChanged to null, GestureDetector handles toggle [disclaimer_screen.dart]
- [x] [Review][Patch] Unused `@GenerateMocks` in pages_smoke_test.dart — removed annotation and unused imports [pages_smoke_test.dart]
- [x] [Review][Defer] Router redirect queries DB on every navigation event — pre-existing, not introduced by this story; cache onboarding status in memory [app_router.dart:91]

### Change Log

- 2026-03-29: Implemented Story 2.1 — Medical Disclaimer Screen. Added full onboarding feature layer (domain/data/presentation), updated router redirect semantic correctness, 82 tests passing.
- 2026-04-01: Code review complete. 8 patch findings, 1 deferred, 6 dismissed.
