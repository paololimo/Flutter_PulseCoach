# Story 2.3: Profile Setup Screen

Status: done

## Story

As a new user,
I want to set up my fitness profile with 4 questions,
so that the system can generate a calibrated first plan within 60 seconds of completing onboarding.

## Acceptance Criteria

1. **Given** the user taps "Get Started" on onboarding Screen 3
   **When** the profile setup screen renders
   **Then** 4 fields are displayed as segmented controls: Fitness Level (Beginner / Intermediate), Primary Goal (Cardio / Strength / Mobility / Well-being), Available Time (2–5 min / 5–10 min), Physical Constraints (None / Knee issues / Back issues / Prefer indoor) (FR2, UX-DR14)

2. **Given** the profile setup screen is displayed
   **When** fewer than 4 fields are selected
   **Then** the "Start My Plan" button is disabled

3. **Given** all 4 fields have selections
   **When** the user taps "Start My Plan"
   **Then** the profile is persisted to the `user_profile` table with selected values and `onboardingCompleted = true`

4. **Given** the profile is persisted
   **When** the save operation completes
   **Then** the user is navigated to `/today` (via `context.go(AppRouter.today)` in `OnboardingPage`)

5. **Given** the profile is saved with Fitness Level = Beginner
   **When** the AI plan generation is triggered (Epic 5)
   **Then** the first plan is generated with intensity ≤ Low and session count = 3, derived from `intensityPreference = 'low'` and `weeklySessionTarget = 3` (FR12) — **plan generation itself is deferred to Story 5.5; this story ensures the correct data is persisted**

6. **Given** no account or email is required
   **When** the profile setup screen is inspected
   **Then** there is no email field, password field, or account creation prompt (NFR11, UX-DR14)

7. **Given** the `saveProfile` use case fails (DB error)
   **When** the error state is emitted
   **Then** a Snackbar shows the error message and the user remains on the profile setup screen

## Tasks / Subtasks

- [x] Task 1: Schema Migration v3 — add `availableTime` and `physicalConstraints` columns (AC: 3)
  - [x] 1.1 Add `TextColumn get availableTime => text().nullable()();` to `UserProfile` table in `lib/core/database/tables/user_profile_table.dart`
  - [x] 1.2 Add `TextColumn get physicalConstraints => text().nullable()();` to `UserProfile` table in `lib/core/database/tables/user_profile_table.dart`
  - [x] 1.3 Update `lib/core/database/app_database.dart`: bump `schemaVersion` from `2` to `3` and add migration step for `from < 3` that calls `await m.addColumn(userProfile, userProfile.availableTime);` and `await m.addColumn(userProfile, userProfile.physicalConstraints);`
  - [x] 1.4 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `user_profile_dao.g.dart` and `app_database.g.dart`

- [x] Task 2: Domain layer — entity and use case (AC: 3)
  - [x] 2.1 Create `lib/features/onboarding/domain/entities/user_profile.dart`:
    ```dart
    class UserProfile {
      final String fitnessLevel;        // 'low' | 'medium'
      final String goal;                // 'cardio' | 'strength' | 'mobility' | 'wellbeing'
      final String availableTime;       // 'short' | 'long'
      final String physicalConstraints; // 'none' | 'knee' | 'back' | 'indoor'

      const UserProfile({
        required this.fitnessLevel,
        required this.goal,
        required this.availableTime,
        required this.physicalConstraints,
      });
    }
    ```
    **Note:** This is the clean domain entity — NOT drift's `UserProfileData`. Do not confuse them.
  - [x] 2.2 Add `saveProfile` to `lib/features/onboarding/domain/repositories/onboarding_repository.dart`:
    ```dart
    Future<Either<Failure, void>> saveProfile(UserProfile profile);
    ```
    Import the new entity with `import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';`
  - [x] 2.3 Create `lib/features/onboarding/domain/usecases/save_profile.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
    import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';

    @injectable
    class SaveProfile {
      SaveProfile(this._repository);
      final OnboardingRepository _repository;

      Future<Either<Failure, void>> call(UserProfile profile) =>
          _repository.saveProfile(profile);
    }
    ```

- [x] Task 3: Data layer — implement saveProfile in repository (AC: 3, 7)
  - [x] 3.1 Add `saveProfile` implementation to `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart`. **Pattern mirrors `acceptDisclaimer`** — get existing profile, update or insert:
    ```dart
    @override
    Future<Either<Failure, void>> saveProfile(UserProfile profile) async {
      try {
        final existing = await _db.userProfileDao.getProfile();
        if (existing == null) {
          await _db.userProfileDao.insertProfile(
            UserProfileCompanion.insert(
              disclaimerAccepted: const Value(true),
              intensityPreference: Value(profile.fitnessLevel),
              fitnessGoal: Value(profile.goal),
              availableTime: Value(profile.availableTime),
              physicalConstraints: Value(profile.physicalConstraints),
              onboardingCompleted: const Value(true),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        } else {
          await _db.userProfileDao.updateProfile(
            existing.copyWith(
              intensityPreference: profile.fitnessLevel,
              fitnessGoal: profile.goal,
              availableTime: profile.availableTime,
              physicalConstraints: profile.physicalConstraints,
              onboardingCompleted: true,
              updatedAt: DateTime.now(),
            ),
          );
        }
        return const Right(null);
      } catch (e) {
        return Left(CacheFailure(e.toString()));
      }
    }
    ```
    Add `import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';` to the impl file.

- [x] Task 4: Update OnboardingState and OnboardingCubit (AC: 4, 7)
  - [x] 4.1 Add `onboardingComplete()` variant to `lib/features/onboarding/presentation/bloc/onboarding_state.dart`:
    ```dart
    const factory OnboardingState.onboardingComplete() = OnboardingOnboardingComplete;
    ```
  - [x] 4.2 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `onboarding_state.freezed.dart`
  - [x] 4.3 Update `lib/features/onboarding/presentation/bloc/onboarding_cubit.dart`:
    - Add `SaveProfile _saveProfile` as third constructor parameter
    - Add import: `import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart';`
    - Add import: `import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';`
    - Add method:
    ```dart
    Future<void> saveProfile(UserProfile profile) async {
      if (state is OnboardingLoading) return;
      emit(const OnboardingState.loading());
      final result = await _saveProfile(profile);
      result.fold(
        (failure) => emit(OnboardingState.error(failure.message)),
        (_) => emit(const OnboardingState.onboardingComplete()),
      );
    }
    ```
    **Final cubit constructor signature:**
    ```dart
    OnboardingCubit(
      this._acceptDisclaimer,
      this._checkDisclaimerStatus,
      this._saveProfile,
    ) : super(const OnboardingState.disclaimerPending());
    ```

- [x] Task 5: Regenerate DI after adding SaveProfile injectable (AC: 3)
  - [x] 5.1 Run `dart run build_runner build --delete-conflicting-outputs` — injectable will auto-wire `SaveProfile` into `OnboardingCubit` because both are `@injectable`. Verify `injection.config.dart` is updated.

- [x] Task 6: Build ProfileSetupForm widget (AC: 1, 2, 3, 6)
  - [x] 6.1 Create `lib/features/onboarding/presentation/widgets/profile_setup_form.dart` — `StatefulWidget`:
    - 4 nullable local state variables: `String? _fitnessLevel`, `String? _goal`, `String? _availableTime`, `String? _physicalConstraints`
    - `bool get _allSelected => _fitnessLevel != null && _goal != null && _availableTime != null && _physicalConstraints != null;`
  - [x] 6.2 Layout (inside `PopScope(canPop: false)`):
    ```
    Scaffold (no AppBar, backgroundColor: theme.surface)
    └── SafeArea
        └── SingleChildScrollView
            └── Padding (horizontal: AppSpacing.lg, vertical: AppSpacing.xl)
                └── Column
                    ├── Text "Let's set up your profile" (AppTextStyles.display, theme.onSurface)
                    ├── SizedBox(height: AppSpacing.xl)
                    ├── _buildField("Fitness Level", ...)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── _buildField("Primary Goal", ...)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── _buildField("Available Time", ...)
                    ├── SizedBox(height: AppSpacing.lg)
                    ├── _buildField("Physical Constraints", ...)
                    ├── SizedBox(height: AppSpacing.xxl)
                    └── SizedBox(width: double.infinity) — FilledButton "Start My Plan"
    ```
  - [x] 6.3 Implement `_buildField(String label, SegmentedButton<String> button)` returning a `Column` with:
    - `Text(label, style: AppTextStyles.h3.copyWith(color: theme.onSurface))`
    - `SizedBox(height: AppSpacing.sm)`
    - The `SegmentedButton<String>` widget
  - [x] 6.4 Implement all 4 `SegmentedButton<String>` widgets with `emptySelectionAllowed: true`:
    - Fitness Level: `ButtonSegment(value: 'low', label: Text('Beginner'))`, `ButtonSegment(value: 'medium', label: Text('Intermediate'))`
    - Primary Goal: `ButtonSegment(value: 'cardio', label: Text('Cardio'))`, `strength`→`Strength`, `mobility`→`Mobility`, `wellbeing`→`Well-being`
    - Available Time: `ButtonSegment(value: 'short', label: Text('2–5 min'))`, `ButtonSegment(value: 'long', label: Text('5–10 min'))`
    - Physical Constraints: `none`→`None`, `knee`→`Knee issues`, `back`→`Back issues`, `indoor`→`Prefer indoor`
    - Each `onSelectionChanged` calls `setState(() => _field = selection.first)` — use `emptySelectionAllowed: true`, `multiSelectionEnabled: false` (default)
  - [x] 6.5 "Start My Plan" `FilledButton`:
    - `onPressed: _allSelected ? _onSubmit : null`
    - Disabled style: `FilledButton.styleFrom(disabledBackgroundColor: theme.primaryColor.withValues(alpha: 0.3))`
    - Loading state: when `OnboardingLoading`, show `CircularProgressIndicator` inside button (mirror `DisclaimerScreen` loading pattern)
    - Use `BlocBuilder` around the button to detect loading state
  - [x] 6.6 Implement `_onSubmit`:
    ```dart
    void _onSubmit() {
      context.read<OnboardingCubit>().saveProfile(
        UserProfile(
          fitnessLevel: _fitnessLevel!,
          goal: _goal!,
          availableTime: _availableTime!,
          physicalConstraints: _physicalConstraints!,
        ),
      );
    }
    ```
  - [x] 6.7 Import pattern (mirror `disclaimer_screen.dart`):
    ```dart
    import 'package:pulse_coach/core/theme/app_spacing.dart';
    import 'package:pulse_coach/core/theme/app_text_styles.dart';
    import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
    import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
    import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
    import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_state.dart';
    ```

- [x] Task 7: Update OnboardingPage — replace stub + add navigation (AC: 4, 7)
  - [x] 7.1 In `lib/features/onboarding/presentation/pages/onboarding_page.dart`:
    - Replace `BlocBuilder` with `BlocConsumer`:
    ```dart
    BlocConsumer<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingOnboardingComplete) {
          context.go(AppRouter.today);
        }
        if (state is OnboardingError) {
          // Error from ProfileSetupForm path — DisclaimerScreen handles its own errors
          // but show Snackbar here for saveProfile errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is OnboardingProfileSetupReady) {
          return const ProfileSetupForm();
        }
        if (state is OnboardingDisclaimerAccepted) {
          return const OnboardingCarousel();
        }
        return const DisclaimerScreen();
      },
    )
    ```
    - Replace the `Text('Profile Setup — Story 2.3')` stub with `const ProfileSetupForm()`
    - Add import: `import 'package:pulse_coach/features/onboarding/presentation/widgets/profile_setup_form.dart';`
    - Add import: `import 'package:go_router/go_router.dart';`
    - Add import: `import 'package:pulse_coach/core/routing/app_router.dart';`

- [x] Task 8: Tests (AC: 1–7)
  - [x] 8.1 Update `test/bloc/onboarding_cubit_test.dart`:
    - Add `MockSaveProfile` to `@GenerateMocks([AcceptDisclaimer, CheckDisclaimerStatus, SaveProfile])` — regenerate mocks
    - Add `late MockSaveProfile mockSaveProfile;` field
    - Update `setUp()`: add `mockSaveProfile = MockSaveProfile();`
    - **CRITICAL:** Update ALL existing `OnboardingCubit(mockAcceptDisclaimer, mockCheckDisclaimerStatus)` calls to `OnboardingCubit(mockAcceptDisclaimer, mockCheckDisclaimerStatus, mockSaveProfile)` (affects tests: `2.1-UNIT-001`, `2.2-UNIT-001`, and all `blocTest` `build:` lambdas)
    - Add tests:
      - `2.3-UNIT-001`: `saveProfile(...)` emits `[loading, onboardingComplete]` on success (mock `mockSaveProfile(any)` returns `Right(null)`)
      - `2.3-UNIT-002`: `saveProfile(...)` emits `[loading, error('DB error')]` on failure (mock returns `Left(CacheFailure('DB error'))`)
  - [x] 8.2 Update `test/widget/onboarding_page_test.dart`:
    - Add `SaveProfile` to `@GenerateMocks`, add `late MockSaveProfile mockSaveProfile;`, update `setUp()`, and update all `OnboardingCubit(...)` calls in `buildPage()` and `buildCarousel()` and `buildCarouselWithBrokenAssets()` to include `mockSaveProfile`
    - Add widget tests for `ProfileSetupForm` (wrapped in `MaterialApp(theme: AppTheme.darkTheme, home: BlocProvider(..., child: ProfileSetupForm()))`):
      - `2.3-WIDGET-001`: all 4 field labels are visible ("Fitness Level", "Primary Goal", "Available Time", "Physical Constraints")
      - `2.3-WIDGET-002`: "Start My Plan" button is disabled when no selections made
      - `2.3-WIDGET-003`: After tapping one segment in each of the 4 fields, "Start My Plan" button becomes enabled
      - `2.3-WIDGET-004`: Tapping "Start My Plan" calls `cubit.saveProfile(...)` (verify via mock)
  - [x] 8.3 Update `test/core/routing/app_router_test.dart`:
    - Add `SaveProfile` registration in `_registerOnboardingDeps()`:
      ```dart
      getIt.registerFactory<SaveProfile>(
        () => SaveProfile(getIt<OnboardingRepository>()),
      );
      ```
    - Update `OnboardingCubit` factory registration:
      ```dart
      getIt.registerFactory<OnboardingCubit>(
        () => OnboardingCubit(
          getIt<AcceptDisclaimer>(),
          getIt<CheckDisclaimerStatus>(),
          getIt<SaveProfile>(),
        ),
      );
      ```
    - Add import: `import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart';`
  - [x] 8.4 Run `flutter test` — 98 tests pass (91 existing + 6 new + 1 updated schema test)

## Dev Notes

### Schema: New Columns in user_profile_table.dart

**Current schema (v2):** `id, fitnessGoal, weeklySessionTarget, intensityPreference, environmentPreference, onboardingCompleted, disclaimerAccepted, createdAt, updatedAt`

**Schema v3 additions:**
```dart
TextColumn get availableTime => text().nullable()();       // 'short' | 'long'
TextColumn get physicalConstraints => text().nullable()(); // 'none' | 'knee' | 'back' | 'indoor'
```

**Migration in app_database.dart:**
```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) {
      await m.addColumn(userProfile, userProfile.disclaimerAccepted);
    }
    if (from < 3) {
      await m.addColumn(userProfile, userProfile.availableTime);
      await m.addColumn(userProfile, userProfile.physicalConstraints);
    }
  },
);
```

### Value Mapping: UI Label → DB Value

| UI Label | DB Value | Column |
|---|---|---|
| Beginner | `'low'` | `intensityPreference` |
| Intermediate | `'medium'` | `intensityPreference` |
| Cardio | `'cardio'` | `fitnessGoal` |
| Strength | `'strength'` | `fitnessGoal` |
| Mobility | `'mobility'` | `fitnessGoal` |
| Well-being | `'wellbeing'` | `fitnessGoal` |
| 2–5 min | `'short'` | `availableTime` (new) |
| 5–10 min | `'long'` | `availableTime` (new) |
| None | `'none'` | `physicalConstraints` (new) |
| Knee issues | `'knee'` | `physicalConstraints` (new) |
| Back issues | `'back'` | `physicalConstraints` (new) |
| Prefer indoor | `'indoor'` | `physicalConstraints` (new) |

`weeklySessionTarget` stays at default 3 — NOT changed during profile setup. Fulfils "session count = 3" for AC5.

### Clean Architecture Scope

- **Domain entity** `UserProfile` is NEW — distinct from drift's `UserProfileData`
- **Use case** `SaveProfile` is NEW
- `OnboardingRepository` interface is EXTENDED (backward-compatible)
- `OnboardingRepositoryImpl` is EXTENDED (add `saveProfile` method)
- `OnboardingCubit` is EXTENDED (new dep + new method)
- DI: `SaveProfile` is `@injectable`, auto-wired by injectable code gen

### Critical Regression Risks

**1. OnboardingCubit constructor change (MOST CRITICAL)**
Adding `SaveProfile` as 3rd constructor parameter breaks every `OnboardingCubit(...)` instantiation in tests. Fix in ALL 3 test files:
- `test/bloc/onboarding_cubit_test.dart` — ~5 `OnboardingCubit(...)` calls
- `test/widget/onboarding_page_test.dart` — 3 calls in `buildPage()`, `buildCarousel()`, `buildCarouselWithBrokenAssets()`
- `test/core/routing/app_router_test.dart` — 1 call in `_registerOnboardingDeps()`

**2. Existing stub test 2.2-WIDGET-006**
Test `2.2-WIDGET-006` asserts `Text('Profile Setup — Story 2.3')` is visible. After this story replaces the stub with `ProfileSetupForm`, this test will FAIL. Update it: the test should now verify `ProfileSetupForm` renders (e.g., find the "Fitness Level" label or the widget type).

**3. build_runner must be run twice**
- After Task 1 (schema changes): regenerate drift code
- After Task 4.2 (freezed changes): regenerate freezed code  
- After Task 5 (injectable changes): injectable generates updated DI
- Safest: run `dart run build_runner build --delete-conflicting-outputs` once after ALL changes — but run it at minimum after each batch of model/annotation changes

### Navigation Pattern

The `OnboardingPage` must use `BlocConsumer` (not `BlocBuilder`) to handle navigation. `context.go(AppRouter.today)` is called in the `listener` callback when `state is OnboardingOnboardingComplete`. This avoids calling navigation during the build phase.

The router redirect (`_redirect`) does NOT fire automatically on DB change — it only fires on navigation attempts. So explicit `context.go(AppRouter.today)` is required.

**IMPORTANT:** After `context.go(AppRouter.today)`, the router `_redirect` checks `onboardingCompleted` in DB. Since we persist `onboardingCompleted = true` in `saveProfile`, the redirect will allow passage to `/today` without bouncing back to `/onboarding`.

### AI Plan Generation — Deferred

AC5 references FR12 (plan generation). The AI engine (Epic 5, Story 5.5) does not exist yet. For Story 2.3:
- Save profile data with correct values to DB
- Navigate to `/today` (which shows the `TodayPage` stub: `Text('Today — Story 7.x')`)
- **Do NOT implement AI plan generation in this story** — the existing `TodayPage` stub is acceptable output for now

The `intensityPreference = 'low'` (for Beginner) and `weeklySessionTarget = 3` values are persisted correctly so Epic 5 can consume them when it builds the AI engine.

### UX Constraints

- **No AppBar** — consistent with `DisclaimerScreen` and `OnboardingCarousel`
- **No keyboard** — all selections via `SegmentedButton<String>`, no `TextField` anywhere
- **No email / password / account creation** — verified by AC6, tested by `2.3-WIDGET-001`
- **PopScope(canPop: false)** — back navigation blocked throughout onboarding
- **SingleChildScrollView** — wraps the column to handle smaller screens; 4 segmented controls may overflow on very small devices without scroll
- **Error Snackbar** — on `saveProfile` failure, show snackbar via `BlocConsumer` listener in `OnboardingPage`

### File Structure

```
lib/features/onboarding/
├── domain/
│   ├── entities/
│   │   └── user_profile.dart               ← NEW (clean domain entity, 4 profile fields)
│   ├── repositories/
│   │   └── onboarding_repository.dart      ← MODIFIED (add saveProfile method)
│   └── usecases/
│       ├── accept_disclaimer.dart          ← NO CHANGE
│       ├── check_disclaimer_status.dart    ← NO CHANGE
│       └── save_profile.dart               ← NEW
├── data/
│   └── repositories/
│       └── onboarding_repository_impl.dart ← MODIFIED (implement saveProfile)
└── presentation/
    ├── bloc/
    │   ├── onboarding_cubit.dart           ← MODIFIED (add SaveProfile dep + saveProfile method)
    │   ├── onboarding_state.dart           ← MODIFIED (add onboardingComplete variant)
    │   └── onboarding_state.freezed.dart   ← REGENERATED
    ├── pages/
    │   └── onboarding_page.dart            ← MODIFIED (BlocConsumer + navigation + ProfileSetupForm)
    └── widgets/
        ├── disclaimer_screen.dart          ← NO CHANGE
        ├── onboarding_carousel.dart        ← NO CHANGE
        └── profile_setup_form.dart         ← NEW

lib/core/database/
├── tables/
│   └── user_profile_table.dart             ← MODIFIED (add availableTime, physicalConstraints)
└── app_database.dart                       ← MODIFIED (schemaVersion 3 + migration)

lib/core/di/
└── injection.config.dart                   ← REGENERATED (SaveProfile added to OnboardingCubit factory)

test/
├── bloc/onboarding_cubit_test.dart         ← MODIFIED (+SaveProfile mock, +2.3 tests, update constructors)
├── widget/onboarding_page_test.dart        ← MODIFIED (+SaveProfile mock, +2.3 tests, update constructors, update 2.2-WIDGET-006)
└── core/routing/app_router_test.dart       ← MODIFIED (register SaveProfile in _registerOnboardingDeps)
```

### Test Count Target

Starting: **91 tests** (all passing after Story 2.2)
Additions:
- `2.3-UNIT-001`: saveProfile emits [loading, onboardingComplete] on success
- `2.3-UNIT-002`: saveProfile emits [loading, error] on failure
- `2.3-WIDGET-001`: ProfileSetupForm renders 4 field labels
- `2.3-WIDGET-002`: "Start My Plan" disabled when no selections
- `2.3-WIDGET-003`: "Start My Plan" enabled when all 4 selected
- `2.3-WIDGET-004`: Tapping "Start My Plan" calls cubit.saveProfile

Target: **~97 tests** (+6 new; 2.2-WIDGET-006 is updated, not removed)

### Stub to Replace in onboarding_page.dart

Current `onboarding_page.dart` line 41–45:
```dart
if (state is OnboardingProfileSetupReady) {
  return const Scaffold(
    body: Center(child: Text('Profile Setup — Story 2.3')),
  );
}
```
Replace with `const ProfileSetupForm()` (no wrapping Scaffold needed — `ProfileSetupForm` provides its own).

### Design Tokens Used

**Do NOT hardcode any values.** Tokens from existing Epic 1 work:
- `AppSpacing.xs/sm/md/lg/xl/xxl` from `lib/core/theme/app_spacing.dart`
- `AppTextStyles.display/h3/body` from `lib/core/theme/app_text_styles.dart`
- `Theme.of(context).extension<PulseCoachTheme>()!` → `theme.surface`, `theme.onSurface`, `theme.primaryColor`

Outer padding mirror: `horizontal: AppSpacing.lg, vertical: AppSpacing.xl` (same as `DisclaimerScreen` and `OnboardingCarousel`)

### SegmentedButton Notes

Use Material 3 `SegmentedButton<String>` (not `ToggleButtons` — that's Material 2):
```dart
SegmentedButton<String>(
  segments: [
    ButtonSegment<String>(value: 'low', label: Text('Beginner')),
    ButtonSegment<String>(value: 'medium', label: Text('Intermediate')),
  ],
  selected: _fitnessLevel != null ? {_fitnessLevel!} : const <String>{},
  onSelectionChanged: (Set<String> selection) {
    if (selection.isNotEmpty) setState(() => _fitnessLevel = selection.first);
  },
  emptySelectionAllowed: true,
  multiSelectionEnabled: false,
)
```
`SegmentedButton` is in `package:flutter/material.dart` — no extra package needed. The segments with 4 options (Primary Goal, Physical Constraints) will wrap — use `showSelectedIcon: false` to reduce button width. The `AppTheme.darkTheme` Material 3 theme will auto-style the segments with correct primary color.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Flow 1 Onboarding, UX-DR14]
- [Source: _bmad-output/planning-artifacts/architecture.md#lib/features/onboarding/ file tree]
- [Source: _bmad-output/implementation-artifacts/2-2-animated-onboarding-flow.md#Dev Notes, File List, Review Findings]
- [Source: pulse_coach/lib/core/database/tables/user_profile_table.dart — existing columns]
- [Source: pulse_coach/lib/core/database/app_database.dart — schemaVersion 2, migration pattern]
- [Source: pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_cubit.dart — existing methods/constructor]
- [Source: pulse_coach/lib/features/onboarding/presentation/pages/onboarding_page.dart — stub at line 41]
- [Source: pulse_coach/lib/features/onboarding/data/repositories/onboarding_repository_impl.dart — acceptDisclaimer pattern]
- [Source: pulse_coach/lib/features/onboarding/presentation/widgets/disclaimer_screen.dart — layout/token/loading pattern]
- [Source: pulse_coach/lib/core/routing/app_router.dart — redirect logic, onboardingCompleted flag]
- [Source: pulse_coach/test/bloc/onboarding_cubit_test.dart — existing constructor calls to update]
- [Source: pulse_coach/test/widget/onboarding_page_test.dart — existing constructor calls + 2.2-WIDGET-006 to update]
- [Source: pulse_coach/test/core/routing/app_router_test.dart — _registerOnboardingDeps to update]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

No significant debug issues encountered. The main finding was that `UserProfileData.copyWith()` for nullable columns uses `Value<String?>` pattern (not plain types), consistent with the existing generated code — the implementation was corrected accordingly.

### Completion Notes List

- Schema v3: Added `availableTime` and `physicalConstraints` nullable text columns to `UserProfile` table; migration step added for `from < 3`.
- Domain: Created `UserProfile` clean domain entity and `SaveProfile` use case (both completely separate from drift's `UserProfileData`).
- Data: `OnboardingRepositoryImpl.saveProfile()` follows the same insert-or-update pattern as `acceptDisclaimer()`. Uses `Value<String?>` for nullable fields in `copyWith()`.
- Cubit: `OnboardingCubit` now accepts `SaveProfile` as 3rd constructor parameter; `saveProfile()` method emits `loading → onboardingComplete` or `loading → error`.
- UI: `ProfileSetupForm` is a `StatefulWidget` with 4 `SegmentedButton<String>` fields; "Start My Plan" disabled until all 4 are selected; `BlocConsumer` in `OnboardingPage` handles navigation to `/today` on `onboardingComplete` and Snackbar on error.
- DI: `injection.config.dart` auto-regenerated by injectable — `SaveProfile` correctly wired into `OnboardingCubit`.
- Tests: All 6 new tests pass. Updated all `OnboardingCubit(...)` calls in 5 test files. Updated `schemaVersion is 3` test. Total: 98 tests passing.

### File List

pulse_coach/lib/core/database/tables/user_profile_table.dart
pulse_coach/lib/core/database/app_database.dart
pulse_coach/lib/core/database/app_database.g.dart
pulse_coach/lib/core/di/injection.config.dart
pulse_coach/lib/features/onboarding/domain/entities/user_profile.dart
pulse_coach/lib/features/onboarding/domain/repositories/onboarding_repository.dart
pulse_coach/lib/features/onboarding/domain/usecases/save_profile.dart
pulse_coach/lib/features/onboarding/data/repositories/onboarding_repository_impl.dart
pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_state.dart
pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_state.freezed.dart
pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_cubit.dart
pulse_coach/lib/features/onboarding/presentation/pages/onboarding_page.dart
pulse_coach/lib/features/onboarding/presentation/widgets/profile_setup_form.dart
pulse_coach/test/bloc/onboarding_cubit_test.dart
pulse_coach/test/bloc/onboarding_cubit_test.mocks.dart
pulse_coach/test/widget/onboarding_page_test.dart
pulse_coach/test/widget/onboarding_page_test.mocks.dart
pulse_coach/test/widget/pages_smoke_test.dart
pulse_coach/test/widget/app_test.dart
pulse_coach/test/core/routing/app_router_test.dart
pulse_coach/test/core/database/app_database_test.dart

### Review Findings

- [x] [Review][Patch] Builder fallthrough: loading/error states render DisclaimerScreen instead of ProfileSetupForm — violates AC7. Fixed: added `buildWhen` to BlocConsumer. [onboarding_page.dart:44-45]
- [x] [Review][Patch] SegmentedButton deselection visual/state mismatch — fixed: empty selection now sets state to null. [profile_setup_form.dart, 4 occurrences]
- [x] [Review][Patch] Missing widget test for error snackbar on saveProfile failure — fixed: added 2.3-WIDGET-005 test. [onboarding_page_test.dart]
- [x] [Review][Defer] No validation of string values in UserProfile entity — domain entity accepts arbitrary strings, only UI constrains values via SegmentedButton. Consider enums or constructor validation. [user_profile.dart:1-13] — deferred, design improvement
- [x] [Review][Defer] Domain entity field names don't match DB column names — fitnessLevel→intensityPreference, goal→fitnessGoal. Intentional per spec value mapping but confusing for future developers. [onboarding_repository_impl.dart:58-59] — deferred, pre-existing schema design
- [x] [Review][Defer] OnboardingCarousel._goToNextPage has no bounds check — method relies on caller to prevent out-of-bounds call. [onboarding_carousel.dart:78-89] — deferred, story 2-2 scope
- [x] [Review][Defer] Test helpers buildCarousel/buildCarouselWithBrokenAssets don't dispose cubit — BlocProvider.value does not auto-close. [onboarding_page_test.dart:52-88] — deferred, story 2-2 scope
- [x] [Review][Defer] Raw exception e.toString() surfaces in snackbar — CacheFailure wraps raw DB exception, leaked to UI. [onboarding_repository_impl.dart:82] — deferred, pre-existing pattern from story 2-1
- [x] [Review][Defer] No widget-level test for navigation to /today on onboardingComplete — requires GoRouter test infrastructure. — deferred, integration test scope

## Change Log

- 2026-04-01: Story 2.3 implemented — schema v3 migration, UserProfile domain entity, SaveProfile use case, ProfileSetupForm widget with 4 SegmentedButton fields, BlocConsumer navigation to /today on completion. 98 tests passing (+7 net: 6 new + 1 updated).
