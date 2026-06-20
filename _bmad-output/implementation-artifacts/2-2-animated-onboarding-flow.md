# Story 2.2: Animated Onboarding Flow

Status: done

## Story

As a new user,
I want to see an animated introduction explaining the app concept and privacy promise,
so that I understand PulseCoach before providing my profile information.

## Acceptance Criteria

1. **Given** the onboarding flow starts after disclaimer acceptance
   **When** Screen 1 renders
   **Then** it shows the Lottie animation `onboarding_plan.json` and the headline "Move more. Decide less." with a body line explaining the autoplay concept (UX-DR13)

2. **Given** the user taps "Next" on Screen 1
   **When** Screen 2 renders
   **Then** it shows `onboarding_privacy.json` animation and "Your data stays yours." with explanation of on-device-only data (UX-DR13)

3. **Given** the user taps "Next" on Screen 2
   **When** Screen 3 renders
   **Then** it shows `onboarding_setup.json` animation and "Let's set you up in 60 seconds." with a "Get Started" CTA (UX-DR13)

4. **Given** any screen transition occurs
   **When** measured
   **Then** the transition uses a 250ms ease-in-out animation (UX-DR18)

5. **Given** the device has "Reduce Motion" enabled
   **When** onboarding renders
   **Then** Lottie animations are replaced with static frames and transitions are instant cuts (UX-DR18)

6. **Given** Lottie files fail to load
   **When** onboarding renders
   **Then** static Material icons with session-type color accents are shown as fallback (UX-DR4)

## Tasks / Subtasks

- [x] Task 1: Create minimal placeholder Lottie JSON files (AC: 1, 2, 3, 6)
  - [x] 1.1 Create `pulse_coach/assets/animations/onboarding_plan.json` — minimal valid Lottie JSON (see Dev Notes for spec). A tiny 2-frame animation with a fitness/plan icon is sufficient; aesthetics will be polished post-MVP.
  - [x] 1.2 Create `pulse_coach/assets/animations/onboarding_privacy.json` — minimal valid Lottie JSON with a lock/shield icon theme
  - [x] 1.3 Create `pulse_coach/assets/animations/onboarding_setup.json` — minimal valid Lottie JSON with a person/profile icon theme

- [x] Task 2: Extend OnboardingState and OnboardingCubit (AC: 3)
  - [x] 2.1 Add `profileSetupReady` variant to `OnboardingState` in `lib/features/onboarding/presentation/bloc/onboarding_state.dart`:
    ```dart
    const factory OnboardingState.profileSetupReady() = OnboardingProfileSetupReady;
    ```
  - [x] 2.2 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `onboarding_state.freezed.dart`
  - [x] 2.3 Add `completeOnboardingFlow()` method to `OnboardingCubit` in `lib/features/onboarding/presentation/bloc/onboarding_cubit.dart`:
    ```dart
    void completeOnboardingFlow() {
      emit(const OnboardingState.profileSetupReady());
    }
    ```
    No async needed — this is a pure UI state transition.

- [x] Task 3: Build OnboardingCarousel widget (AC: 1–6)
  - [x] 3.1 Create `lib/features/onboarding/presentation/widgets/onboarding_carousel.dart` — StatefulWidget that receives `OnboardingCubit` from context via `context.read`. Internals:
    - `PageController _pageController` with `initialPage: 0`
    - Local `int _currentPage = 0` with `setState` on page change
    - Read `MediaQuery.of(context).disableAnimations` to control Reduce Motion behavior
    - On page change via "Next" button: call `_pageController.animateToPage(nextPage, duration: Duration(milliseconds: 250), curve: Curves.easeInOut)` — OR instant `jumpToPage` when Reduce Motion is on
    - On "Get Started" tap (Screen 3): call `context.read<OnboardingCubit>().completeOnboardingFlow()`
  - [x] 3.2 Implement `_buildPage(int index)` private method returning a `Column` layout:
    - Top half (flex 5): Lottie animation area — use `Lottie.asset(assetPath, errorBuilder: (ctx, _, __) => _buildFallbackIcon(index))`; if Reduce Motion: wrap Lottie with `repeat: false, animate: !disableAnimations`
    - Title: Plus Jakarta Sans Display (28sp SemiBold) via `AppTextStyles.display`, `theme.onSurface` color
    - Body: 2-3 lines, `AppTextStyles.body`, `theme.onSurfaceVariant` color
    - Spacing: use `AppSpacing` tokens throughout
  - [x] 3.3 Implement page indicator dots (3 dots, current dot uses `theme.primaryColor`, others `theme.onSurfaceVariant` at 50% opacity), sized 8dp diameter, 8dp gap between
  - [x] 3.4 Implement `_buildFallbackIcon(int index)` — returns a centered Material icon with appropriate accent color:
    - Screen 0 (`onboarding_plan`): `Icons.auto_awesome` with `theme.primaryColor`
    - Screen 1 (`onboarding_privacy`): `Icons.lock_outline` with `theme.primaryColor`
    - Screen 2 (`onboarding_setup`): `Icons.person_outline` with `theme.primaryColor`
    - Icon size: 72dp; constrained to same space as Lottie area
  - [x] 3.5 Implement bottom `FilledButton`:
    - Pages 0 and 1: label "Next" → taps call `_goToNextPage()`
    - Page 2: label "Get Started" → taps call `context.read<OnboardingCubit>().completeOnboardingFlow()`
    - Full-width, 48dp height, `theme.primaryColor` background (mirror DisclaimerScreen style)
  - [x] 3.6 Wrap entire widget in `PopScope(canPop: false)` — back navigation blocked during onboarding flow (same as DisclaimerScreen)

- [x] Task 4: Update OnboardingPage to use OnboardingCarousel (AC: 1–3)
  - [x] 4.1 Update `lib/features/onboarding/presentation/pages/onboarding_page.dart` — replace the `disclaimerAccepted` placeholder:
    - `state is OnboardingDisclaimerAccepted` → render `OnboardingCarousel()` widget (replaces `Text('Onboarding continues — Story 2.2/2.3')`)
    - Add new condition: `state is OnboardingProfileSetupReady` → render `Scaffold(body: Center(child: Text('Profile Setup — Story 2.3')))` stub
    - No other changes to OnboardingPage logic

- [x] Task 5: Tests (AC: 1–6)
  - [x] 5.1 Update `test/bloc/onboarding_cubit_test.dart` — add 1 new test:
    - `2.2-UNIT-001`: `completeOnboardingFlow()` emits `profileSetupReady` state (simple sync test using `expect(cubit.state, ...)` after call)
  - [x] 5.2 Update `test/widget/onboarding_page_test.dart` — add carousel widget tests (provide mocked `OnboardingCubit` already in scope via `BlocProvider`):
    - `2.2-WIDGET-001`: When state is `disclaimerAccepted`, Screen 1 headline "Move more. Decide less." is visible
    - `2.2-WIDGET-002`: When state is `disclaimerAccepted`, "Next" button is visible on Screen 1
    - `2.2-WIDGET-003`: Tapping "Next" on Screen 1 advances to Screen 2 ("Your data stays yours." visible)
    - `2.2-WIDGET-004`: Tapping "Next" on Screen 2 advances to Screen 3 ("Let's set you up in 60 seconds." visible)
    - `2.2-WIDGET-005`: Tapping "Get Started" on Screen 3 calls `completeOnboardingFlow()` on cubit
    - `2.2-WIDGET-006`: When state is `profileSetupReady`, the stub text "Profile Setup — Story 2.3" is visible
    - **Note:** Lottie rendering in test environment will fail asset loading and show the fallback icon — this is expected behavior and verifies the fallback path (AC6)
  - [x] 5.3 Run `flutter test` to confirm all 84 existing tests still pass + new tests pass

## Dev Notes

### Current OnboardingPage Placeholder (Critical — Replace This)

`onboarding_page.dart` line 41–46 currently renders:
```dart
if (state is OnboardingDisclaimerAccepted) {
  return const Scaffold(
    body: Center(
      child: Text('Onboarding continues — Story 2.2/2.3'),
    ),
  );
}
```
Replace the `Text('Onboarding continues — Story 2.2/2.3')` with `OnboardingCarousel()`. Also add handler for `OnboardingProfileSetupReady` state.

**Do NOT change** `disclaimerPending` → `DisclaimerScreen()` flow. That is Story 2.1 work and must not regress.

### OnboardingState — Existing States to Preserve

Current `onboarding_state.dart` (read before touching):
```dart
@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState.loading() = OnboardingLoading;
  const factory OnboardingState.disclaimerPending() = OnboardingDisclaimerPending;
  const factory OnboardingState.disclaimerAccepted() = OnboardingDisclaimerAccepted;
  const factory OnboardingState.error(String message) = OnboardingError;
}
```
Add only `profileSetupReady`. **Do NOT remove any existing variants** — other tests and the DisclaimerScreen cubit flow depend on them all.

### OnboardingCubit — Existing Methods to Preserve

`onboarding_cubit.dart` has:
- `checkInitialStatus()` — called in `OnboardingPage.initState` to skip disclaimer if already accepted
- `acceptDisclaimer()` — called by `DisclaimerScreen` checkbox flow
- Guard against concurrent calls (`if (state is OnboardingLoading) return;`) — preserve this pattern

Add only `completeOnboardingFlow()`. No async, no `Either`, no DB interaction — pure state emit.

### Lottie Integration Pattern

`lottie: ^3.3.1` is already in `pubspec.yaml`. The `assets/animations/` folder is declared in `pubspec.yaml` and exists but is empty. All 3 JSON files must exist as valid Lottie format for the asset bundle to load.

**Minimal valid Lottie JSON** (use this pattern for placeholder files):
```json
{
  "v": "5.5.7",
  "fr": 30,
  "ip": 0,
  "op": 60,
  "w": 400,
  "h": 400,
  "nm": "onboarding_plan",
  "ddd": 0,
  "assets": [],
  "layers": []
}
```
This renders an empty animation that loops silently — adequate placeholder until real animations are sourced.

**Lottie widget usage with fallback:**
```dart
Lottie.asset(
  'assets/animations/onboarding_plan.json',
  fit: BoxFit.contain,
  repeat: !disableAnimations,  // Reduce Motion: no loop
  animate: !disableAnimations, // Reduce Motion: static frame
  errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(0),
)
```
`disableAnimations` = `MediaQuery.of(context).disableAnimations`

### Animation Timing Constants (UX-DR18)

Per UX spec: standard transition = 250ms ease-in-out. For `PageView.animateToPage`:
```dart
_pageController.animateToPage(
  nextPage,
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeInOut,
);
```
Reduce Motion (`MediaQuery.disableAnimations == true`): use `jumpToPage(nextPage)` instead — instant cut with no animation.

### Screen Content Specification (UX-DR13)

| # | Asset | Headline | Body |
|---|---|---|---|
| 1 | `onboarding_plan.json` | "Move more. Decide less." | "PulseCoach selects your sessions automatically, adapting each day to how your body actually feels." |
| 2 | `onboarding_privacy.json` | "Your data stays yours." | "All your health data lives on your device. Nothing is sent to external servers — ever." |
| 3 | `onboarding_setup.json` | "Let's set you up in 60 seconds." | "Four quick questions and PulseCoach will have your first personalized plan ready." |

These copy strings are not in the epic/UX spec verbatim — they are derived from the UX design principles. Use them directly; do not invent variations.

### Layout Specification (UX-DR13, OnboardingCarousel anatomy)

```
Scaffold (no AppBar, backgroundColor: theme.surface)
└── SafeArea
    └── Column
        ├── Flexible(flex: 5) — Lottie animation area (top 50%)
        ├── SizedBox(height: AppSpacing.xl)
        ├── Text (Display / 28sp / SemiBold) — headline
        ├── SizedBox(height: AppSpacing.md)
        ├── Text (Body / 16sp / Regular) — body copy (2-3 lines)
        ├── SizedBox(height: AppSpacing.lg)
        ├── Row — 3 dots indicator (centered)
        ├── SizedBox(height: AppSpacing.xl)
        └── SizedBox(width: double.infinity) — FilledButton Next/Get Started
```

Outer padding: `horizontal: AppSpacing.lg, vertical: AppSpacing.xl` (mirrors DisclaimerScreen).

### Design Tokens — What Already Exists

**Do NOT hardcode any values.** Use these existing tokens:
- `AppSpacing.xs/sm/md/lg/xl/xxl` — spacing constants
- `AppTextStyles.display/h1/h2/h3/body/caption` — text styles
- `Theme.of(context).extension<PulseCoachTheme>()!` → `theme.surface`, `theme.onSurface`, `theme.onSurfaceVariant`, `theme.primaryColor`
- All these are established in Epic 1 Stories 1.5–1.6 and already used in `DisclaimerScreen`

Import pattern (mirror `disclaimer_screen.dart`):
```dart
import 'package:pulse_coach/core/theme/app_spacing.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
```

### Clean Architecture Scope — UI Only

This story has **no domain or data layer work**. No new use cases, no repository changes, no DB migrations. The carousel is pure UI state managed by `OnboardingCubit` (per ARCH6: Cubit for UI-only state).

No `Either<Failure, T>` needed — `completeOnboardingFlow()` has no failure path. No DI registration needed for any new class. No `build_runner` needed except after modifying `onboarding_state.dart` (for freezed regeneration).

### File Structure

```
lib/features/onboarding/presentation/
├── bloc/
│   ├── onboarding_cubit.dart          ← MODIFIED (add completeOnboardingFlow)
│   ├── onboarding_state.dart          ← MODIFIED (add profileSetupReady)
│   └── onboarding_state.freezed.dart  ← REGENERATED
├── pages/
│   └── onboarding_page.dart           ← MODIFIED (carousel + profileSetupReady handler)
└── widgets/
    ├── disclaimer_screen.dart         ← NO CHANGE
    └── onboarding_carousel.dart       ← NEW

pulse_coach/assets/animations/
├── onboarding_plan.json               ← NEW (minimal placeholder)
├── onboarding_privacy.json            ← NEW (minimal placeholder)
└── onboarding_setup.json              ← NEW (minimal placeholder)
```

### Regression Risk: Existing Tests

**`test/widget/pages_smoke_test.dart`** test `1.7-WIDGET-004` asserts `OnboardingPage renders disclaimer screen`. This test seeds the DB with no profile (disclaimer not accepted), so the cubit emits `disclaimerPending` → `DisclaimerScreen` renders. This test must continue to pass unchanged — the carousel only renders for `disclaimerAccepted` state.

**`test/widget/onboarding_page_test.dart`** all 5 existing tests (`2.1-WIDGET-001` through `2.1-WIDGET-005`) test the `DisclaimerScreen` behavior. Adding carousel tests must NOT change the existing DisclaimerScreen test setup.

**`test/bloc/onboarding_cubit_test.dart`** has 8 tests (`2.1-UNIT-001` through `2.1-UNIT-008`). The new `2.2-UNIT-001` adds to this file — do not rewrite existing tests.

### DI Registration — No Changes

`OnboardingCubit` is already `@injectable`. No new injectables introduced in this story. Do NOT run `build_runner` unless `onboarding_state.dart` has been modified (for freezed regeneration only).

### Test Count Target

Starting: **84 tests** (all passing after Story 2.1 code review).
After 2.2: **~92 tests** (1 bloc test + 6 widget tests = +7 net; adjust up if additional edge cases are valuable).

### Router — No Changes

`app_router.dart` redirect logic is complete from Story 2.1. The `onboardingCompleted` flag is only set in Story 2.3. As long as `onboardingCompleted == false` and `disclaimerAccepted == true`, the router keeps the user at `/onboarding`. The `OnboardingPage` handles internal step routing (disclaimer → carousel → profile stub) — no router changes needed.

### Story 2.3 Continuity Note

After `completeOnboardingFlow()` is called (user taps "Get Started"), `OnboardingPage` renders a stub `Text('Profile Setup — Story 2.3')`. Story 2.3 will replace this stub with the actual profile setup widget. Do NOT pre-implement any profile setup UI here.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.2]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#OnboardingCarousel]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Flow 1: Onboarding → First Plan]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#UX-DR13, UX-DR18]
- [Source: _bmad-output/planning-artifacts/architecture.md#Lottie Assets — bundled in assets/animations/]
- [Source: _bmad-output/implementation-artifacts/2-1-medical-disclaimer-screen.md#File List, Dev Notes]
- [Source: pulse_coach/lib/features/onboarding/presentation/pages/onboarding_page.dart — placeholder at line 41]
- [Source: pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_state.dart — existing states]
- [Source: pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_cubit.dart — existing methods]
- [Source: pulse_coach/lib/features/onboarding/presentation/widgets/disclaimer_screen.dart — layout/token pattern to mirror]
- [Source: pulse_coach/pubspec.yaml — lottie: ^3.3.1 confirmed present]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- **Lottie infinite ticker**: `pumpAndSettle` timed out in tests because Lottie creates a looping `AnimationController` even with a 0-layer JSON. Fixed by:
  1. Wrapping carousel tests in `MediaQuery(disableAnimations: true)` → `OnboardingCarousel` uses `jumpToPage` (instant) and Lottie is paused.
  2. Updating `app_router_test.dart` test `2.1-UNIT-006` to use explicit `pump(Duration)` calls instead of `pumpAndSettle` (Lottie cannot be disabled at full-app level in that test).

### Completion Notes List

- Implemented `OnboardingCarousel` — 3-page PageView with Lottie animations, fallback icons, page dots, 250ms ease-in-out transitions, Reduce Motion support via `MediaQuery.disableAnimations`.
- Added `profileSetupReady` state to `OnboardingState` (freezed), regenerated `.freezed.dart`.
- Added `completeOnboardingFlow()` to `OnboardingCubit` — pure sync state emit, no DB interaction.
- Updated `OnboardingPage` to render `OnboardingCarousel` for `disclaimerAccepted` state and `'Profile Setup — Story 2.3'` stub for `profileSetupReady` state.
- Created 3 minimal placeholder Lottie JSON files in `assets/animations/`.
- Test suite: 84 → 91 tests (+1 bloc, +6 widget); all 91 pass with no regressions.

### File List

- `pulse_coach/assets/animations/onboarding_plan.json` — NEW
- `pulse_coach/assets/animations/onboarding_privacy.json` — NEW
- `pulse_coach/assets/animations/onboarding_setup.json` — NEW
- `pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_state.dart` — MODIFIED
- `pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_state.freezed.dart` — REGENERATED
- `pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_cubit.dart` — MODIFIED
- `pulse_coach/lib/features/onboarding/presentation/widgets/onboarding_carousel.dart` — NEW
- `pulse_coach/lib/features/onboarding/presentation/pages/onboarding_page.dart` — MODIFIED
- `pulse_coach/test/bloc/onboarding_cubit_test.dart` — MODIFIED
- `pulse_coach/test/widget/onboarding_page_test.dart` — MODIFIED
- `pulse_coach/test/core/routing/app_router_test.dart` — MODIFIED (updated 2.1-UNIT-006 assertion)

### Review Findings

- [x] [Review][Patch] Dot indicator uses hardcoded `4` and `8` instead of `AppSpacing.xs`/`AppSpacing.sm` tokens [onboarding_carousel.dart:164-166] — fixed
- [x] [Review][Patch] Unit test `2.2-UNIT-001` creates cubit without closing it — minor stream controller leak [onboarding_cubit_test.dart:97] — fixed
- [x] [Review][Patch] No explicit assertion for Lottie fallback icon rendering in widget tests (AC6 coverage gap) — fixed: added `overrideAssetPath` @visibleForTesting param + test 2.2-WIDGET-007
- [x] [Review][Defer] `OnboardingPage` BlocBuilder fallthrough renders `DisclaimerScreen` for `loading` and `error` states — pre-existing from Story 2.1
- [x] [Review][Defer] No `Semantics` labels on page indicator dots — accessibility enhancement, not in current AC
- [x] [Review][Defer] No `Semantics` labels on Lottie animation / fallback icons — accessibility enhancement, not in current AC
- [x] [Review][Defer] `AppTextStyles.body` is 15sp vs spec layout's 16sp — pre-existing token value from Story 1.6
- [x] [Review][Defer] Manual cubit lifecycle in `OnboardingPage` (`getIt` + manual close) — pre-existing pattern from Story 2.1
- [x] [Review][Defer] Router test `2.1-UNIT-006` uses hardcoded `pump(Duration)` values — Lottie ticker limitation, documented

## Change Log

- 2026-04-01: Story 2.2 implemented — animated onboarding carousel with 3 screens, Lottie + fallback icons, Reduce Motion support, 7 new tests (91 total). Status: review.
