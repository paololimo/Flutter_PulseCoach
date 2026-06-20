# Story 2.4: Profile View & Edit

Status: done

## Story

As a returning user,
I want to view and edit my profile and goals at any time,
so that the system can adjust my plan as my fitness level or preferences change.

## Acceptance Criteria

1. **Given** the user navigates to Profile from the drawer
   **When** the profile screen renders
   **Then** all 4 profile fields are displayed as `SegmentedButton<String>` with their current values pre-selected (FR4)

2. **Given** the profile screen is displayed
   **When** the user taps a new segment in any field
   **Then** the change is persisted to the `user_profile` table immediately (no Save button required)

3. **Given** a profile field update succeeds
   **When** the save completes
   **Then** the UI reflects the new selection and no error is shown

4. **Given** a profile field update fails (DB error)
   **When** the error is emitted
   **Then** a Snackbar shows the error message and the user remains on the profile screen

5. **Given** the profile is updated
   **When** the user navigates back to Today
   **Then** plan regeneration is deferred — `TodayPage` is still a stub; this story ensures only the correct updated data is persisted (plan regeneration deferred to Story 5.5)

6. **Given** the profile screen is displayed
   **When** the user inspects the screen
   **Then** there is no Save button, no email/password/account field, and no keyboard — all input via `SegmentedButton<String>` only

## Tasks / Subtasks

- [x] Task 1: Extend `OnboardingRepository` interface with `getProfile` and `updateProfile` (AC: 1, 2)
  - [x] 1.1 Add to `lib/features/onboarding/domain/repositories/onboarding_repository.dart`:
    ```dart
    Future<Either<Failure, UserProfile>> getProfile();
    Future<Either<Failure, void>> updateProfile(UserProfile profile);
    ```
    **IMPORTANT:** `getProfile()` returns non-nullable `UserProfile` (page is only reachable post-onboarding). Returns `Left(CacheFailure('Profile not found'))` if DB row missing.

- [x] Task 2: Implement `getProfile` and `updateProfile` in `OnboardingRepositoryImpl` (AC: 1, 2, 4)
  - [x] 2.1 Add `getProfile` to `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart`:
    ```dart
    @override
    Future<Either<Failure, UserProfile>> getProfile() async {
      try {
        final data = await _db.userProfileDao.getProfile();
        if (data == null) {
          return Left(CacheFailure('Profile not found'));
        }
        return Right(UserProfile(
          fitnessLevel: data.intensityPreference ?? 'low',
          goal: data.fitnessGoal ?? 'cardio',
          availableTime: data.availableTime ?? 'short',
          physicalConstraints: data.physicalConstraints ?? 'none',
        ));
      } catch (e) {
        return Left(CacheFailure(e.toString()));
      }
    }
    ```
    **Field mapping** (DB column → domain field): `intensityPreference → fitnessLevel`, `fitnessGoal → goal`, `availableTime → availableTime`, `physicalConstraints → physicalConstraints`.
  - [x] 2.2 Add `updateProfile` to `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart`:
    ```dart
    @override
    Future<Either<Failure, void>> updateProfile(UserProfile profile) async {
      try {
        final existing = await _db.userProfileDao.getProfile();
        if (existing == null) {
          return Left(CacheFailure('Profile not found'));
        }
        await _db.userProfileDao.updateProfile(
          existing.copyWith(
            intensityPreference: Value(profile.fitnessLevel),
            fitnessGoal: Value(profile.goal),
            availableTime: Value(profile.availableTime),
            physicalConstraints: Value(profile.physicalConstraints),
            updatedAt: DateTime.now(),
          ),
        );
        return const Right(null);
      } catch (e) {
        return Left(CacheFailure(e.toString()));
      }
    }
    ```
    **CRITICAL:** Do NOT set `onboardingCompleted` or `disclaimerAccepted` here — only update the 4 profile fields and `updatedAt`. Use `Value<String?>` for nullable columns in `copyWith()` (same pattern as `saveProfile` in Story 2.3).
    Add `import 'package:drift/drift.dart';` if not already present.

- [x] Task 3: Create `GetProfile` use case (AC: 1)
  - [x] 3.1 Create `lib/features/onboarding/domain/usecases/get_profile.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
    import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';

    @injectable
    class GetProfile {
      GetProfile(this._repository);
      final OnboardingRepository _repository;

      Future<Either<Failure, UserProfile>> call() =>
          _repository.getProfile();
    }
    ```

- [x] Task 4: Create `UpdateProfile` use case (AC: 2, 3, 4)
  - [x] 4.1 Create `lib/features/onboarding/domain/usecases/update_profile.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
    import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';

    @injectable
    class UpdateProfile {
      UpdateProfile(this._repository);
      final OnboardingRepository _repository;

      Future<Either<Failure, void>> call(UserProfile profile) =>
          _repository.updateProfile(profile);
    }
    ```

- [x] Task 5: Create `ProfileState` with freezed (AC: 1–4)
  - [x] 5.1 Create `lib/features/onboarding/presentation/bloc/profile_state.dart`:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';

    part 'profile_state.freezed.dart';

    @freezed
    class ProfileState with _$ProfileState {
      const factory ProfileState.initial() = ProfileInitial;
      const factory ProfileState.loading() = ProfileLoading;
      const factory ProfileState.loaded(UserProfile profile) = ProfileLoaded;
      const factory ProfileState.error(String message) = ProfileError;
    }
    ```
  - [x] 5.2 Run `dart run build_runner build --delete-conflicting-outputs` to generate `profile_state.freezed.dart`

- [x] Task 6: Create `ProfileCubit` (AC: 1–4)
  - [x] 6.1 Create `lib/features/onboarding/presentation/bloc/profile_cubit.dart`:
    ```dart
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
    import 'package:pulse_coach/features/onboarding/domain/usecases/get_profile.dart';
    import 'package:pulse_coach/features/onboarding/domain/usecases/update_profile.dart';
    import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_state.dart';

    @injectable
    class ProfileCubit extends Cubit<ProfileState> {
      ProfileCubit(this._getProfile, this._updateProfile)
          : super(const ProfileState.initial());

      final GetProfile _getProfile;
      final UpdateProfile _updateProfile;

      Future<void> loadProfile() async {
        emit(const ProfileState.loading());
        final result = await _getProfile();
        result.fold(
          (failure) => emit(ProfileState.error(failure.message)),
          (profile) => emit(ProfileState.loaded(profile)),
        );
      }

      Future<void> updateProfile(UserProfile profile) async {
        // Do NOT emit loading — keeps SegmentedButton UI stable during silent save
        final result = await _updateProfile(profile);
        result.fold(
          (failure) => emit(ProfileState.error(failure.message)),
          (_) => emit(ProfileState.loaded(profile)),
        );
      }
    }
    ```
    **KEY DESIGN:** `updateProfile` does NOT emit `loading` — this prevents the SegmentedButton from reverting/flickering during a save round-trip. On success, re-emits `loaded` with updated profile. On error, emits `error` (snackbar shown by listener).

- [x] Task 7: Regenerate DI (AC: all)
  - [x] 7.1 Run `dart run build_runner build --delete-conflicting-outputs` — injectable auto-wires `GetProfile` and `UpdateProfile` into `ProfileCubit`. Verify `injection.config.dart` registers `ProfileCubit` factory with both dependencies.

- [x] Task 8: Update `ProfilePage` — replace stub (AC: 1–6)
  - [x] 8.1 Rewrite `lib/features/onboarding/presentation/pages/profile_page.dart` as `StatefulWidget`, following the **exact same structural pattern as `OnboardingPage`**:
    - Get cubit from `getIt<ProfileCubit>()` in `initState`
    - Call `_cubit.loadProfile()` via `addPostFrameCallback` in `initState`
    - Wrap with `BlocProvider.value(value: _cubit, child: ...)`
    - Close cubit in `dispose()`
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:pulse_coach/core/di/injection.dart';
    import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_cubit.dart';
    import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_state.dart';
    import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
    import 'package:pulse_coach/core/theme/app_spacing.dart';
    import 'package:pulse_coach/core/theme/app_text_styles.dart';
    import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

    class ProfilePage extends StatefulWidget {
      const ProfilePage({super.key});
      @override
      State<ProfilePage> createState() => _ProfilePageState();
    }

    class _ProfilePageState extends State<ProfilePage> {
      late final ProfileCubit _cubit;
      String? _fitnessLevel;
      String? _goal;
      String? _availableTime;
      String? _physicalConstraints;

      @override
      void initState() {
        super.initState();
        _cubit = getIt<ProfileCubit>();
        WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.loadProfile());
      }

      @override
      void dispose() {
        _cubit.close();
        super.dispose();
      }

      void _onChanged(UserProfile updated) {
        setState(() {
          _fitnessLevel = updated.fitnessLevel;
          _goal = updated.goal;
          _availableTime = updated.availableTime;
          _physicalConstraints = updated.physicalConstraints;
        });
        _cubit.updateProfile(updated);
      }

      @override
      Widget build(BuildContext context) {
        return BlocProvider.value(
          value: _cubit,
          child: BlocConsumer<ProfileCubit, ProfileState>(
            listenWhen: (_, curr) => curr is ProfileLoaded || curr is ProfileError,
            listener: (context, state) {
              if (state is ProfileLoaded && _fitnessLevel == null) {
                // Initialize local state on first load only
                setState(() {
                  _fitnessLevel = state.profile.fitnessLevel;
                  _goal = state.profile.goal;
                  _availableTime = state.profile.availableTime;
                  _physicalConstraints = state.profile.physicalConstraints;
                });
              }
              if (state is ProfileError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              if (state is ProfileLoading || state is ProfileInitial) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return _buildForm(context);
            },
          ),
        );
      }

      Widget _buildForm(BuildContext context) {
        final theme = Theme.of(context).extension<PulseCoachTheme>()!;
        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Profile',
                    style: AppTextStyles.display.copyWith(color: theme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildField(
                    context,
                    label: 'Fitness Level',
                    segments: [
                      const ButtonSegment<String>(value: 'low', label: Text('Beginner')),
                      const ButtonSegment<String>(value: 'medium', label: Text('Intermediate')),
                    ],
                    selected: _fitnessLevel,
                    onChanged: (val) => _onChanged(UserProfile(
                      fitnessLevel: val,
                      goal: _goal!,
                      availableTime: _availableTime!,
                      physicalConstraints: _physicalConstraints!,
                    )),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(
                    context,
                    label: 'Primary Goal',
                    segments: [
                      const ButtonSegment<String>(value: 'cardio', label: Text('Cardio')),
                      const ButtonSegment<String>(value: 'strength', label: Text('Strength')),
                      const ButtonSegment<String>(value: 'mobility', label: Text('Mobility')),
                      const ButtonSegment<String>(value: 'wellbeing', label: Text('Well-being')),
                    ],
                    selected: _goal,
                    showSelectedIcon: false,
                    onChanged: (val) => _onChanged(UserProfile(
                      fitnessLevel: _fitnessLevel!,
                      goal: val,
                      availableTime: _availableTime!,
                      physicalConstraints: _physicalConstraints!,
                    )),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(
                    context,
                    label: 'Available Time',
                    segments: [
                      const ButtonSegment<String>(value: 'short', label: Text('2–5 min')),
                      const ButtonSegment<String>(value: 'long', label: Text('5–10 min')),
                    ],
                    selected: _availableTime,
                    onChanged: (val) => _onChanged(UserProfile(
                      fitnessLevel: _fitnessLevel!,
                      goal: _goal!,
                      availableTime: val,
                      physicalConstraints: _physicalConstraints!,
                    )),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(
                    context,
                    label: 'Physical Constraints',
                    segments: [
                      const ButtonSegment<String>(value: 'none', label: Text('None')),
                      const ButtonSegment<String>(value: 'knee', label: Text('Knee issues')),
                      const ButtonSegment<String>(value: 'back', label: Text('Back issues')),
                      const ButtonSegment<String>(value: 'indoor', label: Text('Prefer indoor')),
                    ],
                    selected: _physicalConstraints,
                    showSelectedIcon: false,
                    onChanged: (val) => _onChanged(UserProfile(
                      fitnessLevel: _fitnessLevel!,
                      goal: _goal!,
                      availableTime: _availableTime!,
                      physicalConstraints: val,
                    )),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      Widget _buildField(
        BuildContext context, {
        required String label,
        required List<ButtonSegment<String>> segments,
        required String? selected,
        required void Function(String) onChanged,
        bool showSelectedIcon = true,
      }) {
        final theme = Theme.of(context).extension<PulseCoachTheme>()!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.h3.copyWith(color: theme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<String>(
              segments: segments,
              selected: selected != null ? {selected} : const <String>{},
              onSelectionChanged: (Set<String> selection) {
                if (selection.isNotEmpty) onChanged(selection.first);
              },
              showSelectedIcon: showSelectedIcon,
              emptySelectionAllowed: true,
              multiSelectionEnabled: false,
            ),
          ],
        );
      }
    }
    ```
    **CRITICAL UX NOTES:**
    - `_fitnessLevel == null` guard in listener: only populate local state on FIRST `ProfileLoaded` (prevents reset on subsequent saves)
    - `_onChanged` is called only when all other fields are non-null (guaranteed after first load)
    - `showSelectedIcon: false` for 4-option segments (Goal, Constraints) to reduce button width
    - AppBar IS present (unlike setup screen) — Profile is a settings-like page, not part of the onboarding flow

- [x] Task 9: Tests (AC: 1–6)
  - [x] 9.1 Create `test/bloc/profile_cubit_test.dart`:
    - `@GenerateMocks([GetProfile, UpdateProfile])`
    - Tests:
      - `2.4-UNIT-001`: `loadProfile()` emits `[loading, loaded(profile)]` on success
      - `2.4-UNIT-002`: `loadProfile()` emits `[loading, error('Profile not found')]` on failure
      - `2.4-UNIT-003`: `updateProfile(profile)` emits `[loaded(profile)]` on success (no loading emitted)
      - `2.4-UNIT-004`: `updateProfile(profile)` emits `[error('DB error')]` on failure
    - Run `dart run build_runner build --delete-conflicting-outputs` to generate mocks
  - [x] 9.2 Create `test/widget/profile_page_test.dart`:
    - Wrap `ProfilePage` in `MaterialApp(theme: AppTheme.darkTheme, home: ProfilePage())`
    - Use `getIt.registerFactory<ProfileCubit>(...)` with mock use cases in `setUp`
    - Tests:
      - `2.4-WIDGET-001`: Loading indicator shown while `ProfileState.loading`
      - `2.4-WIDGET-002`: All 4 field labels visible after `ProfileLoaded` (same labels as setup: "Fitness Level", "Primary Goal", "Available Time", "Physical Constraints")
      - `2.4-WIDGET-003`: Pre-selected segment matches loaded profile value (e.g., `fitnessLevel: 'low'` → 'Beginner' selected)
      - `2.4-WIDGET-004`: Tapping a segment calls `cubit.updateProfile(...)` with correct `UserProfile`
      - `2.4-WIDGET-005`: Snackbar shown on `ProfileError`
  - [x] 9.3 Update `test/core/routing/app_router_test.dart`:
    - Register `GetProfile`, `UpdateProfile`, and `ProfileCubit` in `_registerDeps()` (or equivalent helper)
    - Verify `/profile` route resolves to `ProfilePage`
  - [x] 9.4 Run `flutter test` — target ~106 tests (+8 new from this story)

## Dev Notes

### Architecture: Where Does Profile Live?

The architecture spec (`architecture.md`) shows `profile_section.dart` under `features/settings/`. However, the **actual routing implementation** (Story 1.7) placed `ProfilePage` at `/profile` in `lib/features/onboarding/presentation/pages/`. The drawer in `AppShell` navigates to `/profile`.

**Decision: Keep `ProfilePage` in `features/onboarding/presentation/pages/`** — it reuses the same domain entities (`UserProfile`), repository (`OnboardingRepository`), and DB table (`user_profile`) as the onboarding feature. Moving it to `settings` would require duplicating domain/data layers. The `profile_section.dart` in settings is a deferred Story 14.x concern.

### Field Mapping: DB Column → Domain Entity

| Domain Entity (`UserProfile`) | DB Column (`UserProfileData`) | Notes |
|-------------------------------|-------------------------------|-------|
| `fitnessLevel` | `intensityPreference` | `'low'` = Beginner, `'medium'` = Intermediate |
| `goal` | `fitnessGoal` | `'cardio'`, `'strength'`, `'mobility'`, `'wellbeing'` |
| `availableTime` | `availableTime` | `'short'` = 2-5 min, `'long'` = 5-10 min |
| `physicalConstraints` | `physicalConstraints` | `'none'`, `'knee'`, `'back'`, `'indoor'` |

**DO NOT** confuse `UserProfile` (clean domain entity) with `UserProfileData` (drift-generated). `UserProfile` is in `lib/features/onboarding/domain/entities/user_profile.dart`.

### `updateProfile` vs `saveProfile` — Critical Difference

| | `saveProfile` (Story 2.3) | `updateProfile` (Story 2.4) |
|--|---------------------------|------------------------------|
| Sets `onboardingCompleted` | `true` | **NOT touched** |
| Sets `disclaimerAccepted` | `true` | **NOT touched** |
| Handles null existing row | Inserts new row | Returns `CacheFailure` |

`updateProfile` must NEVER change `onboardingCompleted` or `disclaimerAccepted` — the router redirect relies on these flags.

### UI State Management: Local State vs Bloc State

`ProfilePage` uses **local widget state** (`_fitnessLevel`, `_goal`, etc.) to drive `SegmentedButton` selections. The bloc state is:
1. **Source of truth at load time**: `ProfileLoaded` populates local state ONCE (guarded by `_fitnessLevel == null`)
2. **Error notification only** after initial load: `ProfileError` triggers Snackbar via `BlocConsumer` listener

This approach prevents UI flickering: if `updateProfile` emitted `loading`, the SegmentedButton would briefly lose its selection. Instead, `updateProfile` emits only `loaded` (success) or `error` (failure), with local state always maintaining the optimistic selection.

### `copyWith` with Nullable Columns (Drift)

For nullable `TextColumn` in drift's `copyWith`, use `Value<String?>`:
```dart
existing.copyWith(
  intensityPreference: Value(profile.fitnessLevel),  // Value<String?>
  fitnessGoal: Value(profile.goal),
  availableTime: Value(profile.availableTime),
  physicalConstraints: Value(profile.physicalConstraints),
  updatedAt: DateTime.now(),  // non-nullable, plain type OK
)
```
Pattern established in Story 2.3 — see `onboarding_repository_impl.dart:saveProfile()`.

### AppBar Presence (Differs from Onboarding)

`ProfilePage` **has an `AppBar`** with back button (automatic from Navigator). This is intentional — profile editing is a navigational screen accessed from the drawer, not part of the locked-down onboarding flow.

Contrast with `ProfileSetupForm` (Story 2.3): no AppBar, `PopScope(canPop: false)` — onboarding cannot be back-navigated.

### Plan Regeneration — Deferred

AC5 references the "daily plan is regenerated" behavior. The AI engine (Epic 5, Story 5.5) does not exist yet. For Story 2.4:
- Update profile data in DB with correct values ✓
- Navigate back (via AppBar back button) to Today stub ✓
- **Do NOT implement plan regeneration** — `TodayPage` is `Text('Today — Story 7.x')` stub

When Story 5.5 implements `GenerateDailyPlan`, the plan regeneration on profile update will be wired there.

### Design Tokens

Same tokens as `ProfileSetupForm`:
- `AppSpacing.sm/lg/xl` from `lib/core/theme/app_spacing.dart`
- `AppTextStyles.display/h3` from `lib/core/theme/app_text_styles.dart`
- `Theme.of(context).extension<PulseCoachTheme>()!` → `theme.onSurface`
- Padding: `horizontal: AppSpacing.lg, vertical: AppSpacing.xl` (consistent with all form screens)

### SegmentedButton — 4-Option Fields

Fields with 4 options (`Primary Goal`, `Physical Constraints`) must use `showSelectedIcon: false` to reduce button width — same constraint as `ProfileSetupForm`. Material 3 `SegmentedButton` from `package:flutter/material.dart`.

### Injectable DI Pattern

Both `GetProfile` and `UpdateProfile` are `@injectable` — injectable code gen auto-wires them into `ProfileCubit`:
```dart
@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._getProfile, this._updateProfile) // auto-wired
```

No manual DI registration needed. Verify `injection.config.dart` after `build_runner`.

### `OnboardingCubit` — NO CHANGES

Story 2.4 does NOT modify `OnboardingCubit`, `OnboardingState`, or any onboarding tests. The separate `ProfileCubit` avoids any regression risk to the onboarding flow.

### File Structure

```
lib/features/onboarding/
├── domain/
│   ├── repositories/
│   │   └── onboarding_repository.dart      ← MODIFIED (add getProfile, updateProfile)
│   └── usecases/
│       ├── get_profile.dart                ← NEW
│       └── update_profile.dart             ← NEW
├── data/
│   └── repositories/
│       └── onboarding_repository_impl.dart ← MODIFIED (implement getProfile, updateProfile)
└── presentation/
    ├── bloc/
    │   ├── profile_cubit.dart              ← NEW
    │   ├── profile_state.dart              ← NEW
    │   └── profile_state.freezed.dart      ← GENERATED
    └── pages/
        └── profile_page.dart               ← MODIFIED (replace stub)

lib/core/di/
└── injection.config.dart                   ← REGENERATED (ProfileCubit factory added)

test/
├── bloc/
│   ├── profile_cubit_test.dart             ← NEW
│   └── profile_cubit_test.mocks.dart       ← GENERATED
├── widget/
│   └── profile_page_test.dart              ← NEW
└── core/routing/
    └── app_router_test.dart                ← MODIFIED (register ProfileCubit, GetProfile, UpdateProfile)
```

**NO CHANGES** to:
- `OnboardingCubit`, `OnboardingState` (no modifications)
- `AppShell` (drawer already navigates to `/profile`)
- `AppRouter` (route `/profile` → `ProfilePage` already exists)
- `UserProfile` domain entity
- `UserProfileDao`
- `AppDatabase`

### Test Count

Starting: **98 tests** (all passing after Story 2.3)

New tests:
- `2.4-UNIT-001`: loadProfile emits [loading, loaded(profile)] on success
- `2.4-UNIT-002`: loadProfile emits [loading, error] on failure
- `2.4-UNIT-003`: updateProfile emits [loaded(profile)] on success (no loading)
- `2.4-UNIT-004`: updateProfile emits [error] on failure
- `2.4-WIDGET-001`: Loading indicator while ProfileLoading
- `2.4-WIDGET-002`: 4 field labels visible after ProfileLoaded
- `2.4-WIDGET-003`: Pre-selected segment matches loaded profile value
- `2.4-WIDGET-004`: Tapping segment calls cubit.updateProfile(...)
- `2.4-WIDGET-005`: Snackbar shown on ProfileError

Target: **~107 tests** (+9 new)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4]
- [Source: _bmad-output/planning-artifacts/prd.md#FR4]
- [Source: _bmad-output/implementation-artifacts/2-3-profile-setup-screen.md#Dev Notes]
- [Source: pulse_coach/lib/features/onboarding/domain/entities/user_profile.dart]
- [Source: pulse_coach/lib/features/onboarding/domain/repositories/onboarding_repository.dart]
- [Source: pulse_coach/lib/features/onboarding/data/repositories/onboarding_repository_impl.dart]
- [Source: pulse_coach/lib/features/onboarding/presentation/pages/onboarding_page.dart — StatefulWidget + BlocProvider.value pattern]
- [Source: pulse_coach/lib/features/onboarding/presentation/widgets/profile_setup_form.dart — SegmentedButton pattern]
- [Source: pulse_coach/lib/features/onboarding/presentation/bloc/onboarding_cubit.dart — injectable pattern]
- [Source: pulse_coach/lib/core/database/tables/user_profile_table.dart — column names]
- [Source: pulse_coach/lib/core/database/daos/user_profile_dao.dart — getProfile, updateProfile methods]
- [Source: pulse_coach/lib/shared/widgets/app_shell.dart — drawer Profile → /profile route]
- [Source: pulse_coach/lib/core/routing/app_router.dart — /profile → ProfilePage already registered]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

- Implemented `getProfile` and `updateProfile` in `OnboardingRepositoryImpl` with correct field mapping (intensityPreference→fitnessLevel, fitnessGoal→goal, availableTime, physicalConstraints). `updateProfile` never touches `onboardingCompleted` or `disclaimerAccepted`.
- Created `GetProfile` and `UpdateProfile` use cases with `@injectable` annotation; auto-wired into `ProfileCubit` via injectable code gen.
- Created `ProfileState` (freezed sealed: initial/loading/loaded/error) and `ProfileCubit` with no-loading-emit on update (prevents SegmentedButton flicker).
- Rewrote `ProfilePage` as `StatefulWidget` using BlocConsumer pattern: local state drives SegmentedButton selections (populated once on first ProfileLoaded), Snackbar shown on ProfileError.
- Generated `profile_state.freezed.dart` and `injection.config.dart` via build_runner. ProfileCubit factory registered with both deps.
- 9 new tests (4 bloc unit + 5 widget). Fixed `pages_smoke_test.dart` to register new DI deps and updated outdated 1.7-WIDGET-005 expectation. Used `captureAny` for UserProfile verification (no `==` on entity).
- Final test count: 108 (+10 from 98 baseline; +1 from smoke test fix that was already failing).

### File List

- `lib/features/onboarding/domain/repositories/onboarding_repository.dart` (modified — added getProfile, updateProfile signatures)
- `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart` (modified — implemented getProfile, updateProfile)
- `lib/features/onboarding/domain/usecases/get_profile.dart` (new)
- `lib/features/onboarding/domain/usecases/update_profile.dart` (new)
- `lib/features/onboarding/presentation/bloc/profile_state.dart` (new)
- `lib/features/onboarding/presentation/bloc/profile_state.freezed.dart` (generated)
- `lib/features/onboarding/presentation/bloc/profile_cubit.dart` (new)
- `lib/features/onboarding/presentation/pages/profile_page.dart` (modified — replaced stub with full implementation)
- `lib/core/di/injection.config.dart` (regenerated — ProfileCubit factory added)
- `test/bloc/profile_cubit_test.dart` (new)
- `test/bloc/profile_cubit_test.mocks.dart` (generated)
- `test/widget/profile_page_test.dart` (new)
- `test/widget/profile_page_test.mocks.dart` (generated)
- `test/widget/pages_smoke_test.dart` (modified — register ProfileCubit deps, update 1.7-WIDGET-005)
- `test/core/routing/app_router_test.dart` (modified — register GetProfile, UpdateProfile, ProfileCubit)

### Review Findings

- [x] [Review][Patch] Null-bang crash when builder renders form in ProfileError state — `_buildForm` is reachable when state is `ProfileError` (builder only guards `ProfileLoading`/`ProfileInitial`), but local fields (`_goal!`, `_availableTime!`, etc.) are still null. Any segment tap crashes with `Null check operator used on a null value`. Fix: handle `ProfileError` in builder to show error UI instead of the form. [profile_page.dart:builder]
- [x] [Review][Patch] Emit after cubit.close() throws StateError — If user taps a segment then navigates away, `_cubit.close()` runs in `dispose()` while the async `updateProfile` future is still in flight. When it completes and calls `emit`, Bloc throws `StateError: Cannot emit new states after calling close`. Fix: add `if (!isClosed)` guard before each `emit` in `ProfileCubit`. [profile_cubit.dart:updateProfile]
- [x] [Review][Patch] DAO updateProfile return value (bool) ignored — `UserProfileDao.updateProfile` returns `Future<bool>` (`replace` returns false if no row was updated). The repository discards this and returns `Right(null)`. Fix: check the bool and return `CacheFailure` if false. [onboarding_repository_impl.dart:updateProfile]
- [x] [Review][Defer] Race condition on rapid segment taps without debounce/cancellation — concurrent `updateProfile` calls can interleave and emit stale state. Low risk for local DB. [profile_cubit.dart:updateProfile] — deferred, pre-existing pattern
- [x] [Review][Defer] Listener guard prevents re-sync after error recovery — `_fitnessLevel == null` guard means subsequent `ProfileLoaded` emissions after first load are ignored. No current code path triggers re-load, so latent only. [profile_page.dart:listener] — deferred, pre-existing pattern
- [x] [Review][Defer] UserProfile has no ==/hashCode — Bloc deduplication relies on equality; `UserProfile` uses identity equality. Not introduced by this story. [user_profile.dart] — deferred, pre-existing entity
- [x] [Review][Defer] Raw error messages leaked to UI — `e.toString()` passed through `CacheFailure` to Snackbar. Users may see internal error details. Project-wide pattern. [onboarding_repository_impl.dart] — deferred, pre-existing pattern
- [x] [Review][Defer] Read-then-write without transaction in updateProfile — `getProfile()` and `updateProfile()` are two separate DB operations. Low risk for single-user local DB. [onboarding_repository_impl.dart:updateProfile] — deferred, pre-existing pattern

## Change Log

- 2026-04-02: Story 2.4 created — profile view/edit with ProfileCubit, GetProfile/UpdateProfile use cases, immediate persistence pattern.
- 2026-04-02: Story 2.4 implemented — ProfileCubit, ProfileState, GetProfile/UpdateProfile use cases, full ProfilePage rewrite, 9 new tests (108 total). Status: review.
