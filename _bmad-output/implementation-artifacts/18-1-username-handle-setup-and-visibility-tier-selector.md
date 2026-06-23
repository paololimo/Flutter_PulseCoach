---
baseline_commit: 38e3bd2
---

# Story 18.1: Username Handle Setup and VisibilityTierSelector

Status: done

## Story

As a signed-in user,
I want to set a unique username/handle and control who can see my activity,
so that I can participate in the social layer on my own terms with privacy as the default.

## Acceptance Criteria

**AC1 — Handle setup invitation on sign-in:**
Given the user is signed in and has no `display_handle` set on their `profiles` row
When they open the Account page
Then they are shown a "Set username" section prompting them to set a handle; this section is skippable (no blocking modal); the `profiles.visibility_tier` is already `private` by DB default (FR63, UX-DR30, NFR29)

**AC2 — Handle uniqueness validation:**
Given the user submits a username via the handle setup section
When the client sends a Supabase PATCH to `profiles` with the proposed `display_handle`
Then if unique: the `display_handle` column is updated, the `SocialProfileBloc` emits `loaded` with the updated profile, and a success snackbar appears; if duplicate (DB unique constraint violation, PostgrestException code 23505): the Bloc emits `error(SocialHandleTakenFailure())` and an inline validation error message is shown on the field without leaving the screen

**AC3 — VisibilityTierSelector in Profile settings:**
Given the `VisibilityTierSelector` widget renders in the Account page settings section
When the user taps one of the two tiers
Then the available tiers are: `Privato` (value: `private`, default), `Solo amici` (value: `friends_only`); tapping a tier immediately sends a Supabase PATCH to `profiles.visibility_tier`; on success, the `VisibilityCubit` updates its state; on failure, the previous selection is restored and an error snackbar is shown (UX-DR30, NFR29)

**AC4 — RLS enforces private-by-default:**
Given the `profiles` table's current RLS policies (`profiles_select_own`, `profiles_insert_own`, `profiles_update_own` from migration `0001_profiles_auth.sql`)
When any other authenticated user's client queries the `profiles` table for a row belonging to a `private` user
Then RLS returns no row — privacy is enforced at the DB level, not the client (ARCH22, NFR29); no new migration is required for this story (existing `profiles_select_own` already prevents cross-user reads)

**AC5 — Social tab placeholder in AppShell:**
Given a new `/social` route and `SocialPage` placeholder are added
When the user taps the fourth tab in the bottom navigation bar / NavigationRail
Then they navigate to the Social placeholder page; the tab icon is `Icons.people`, label `l10n.navTabSocial`; all three existing tabs (Sessions=0, Today=1, Progress=2) remain at their current indices; Social is index 3

**AC6 — Zero regressions:**
Given the new code is added
When the suite runs from `pulse_coach/`
Then `flutter test` reports all existing tests plus new tests green; `flutter analyze lib/ test/` reports 0 issues

## Tasks / Subtasks

- [x] **Task 1 — Extend failure hierarchy and re-export PostgrestException (AC2)**
  - [x] 1.1 In `lib/core/error/failures.dart`, add after `SubscriptionFailure`:
    ```dart
    class SocialFailure extends Failure {
      @override
      final String message;
      const SocialFailure(this.message);
    }

    class SocialHandleTakenFailure extends SocialFailure {
      const SocialHandleTakenFailure() : super('handle_taken');
    }
    ```
  - [x] 1.2 In `lib/core/cloud/supabase_client.dart`, add `PostgrestException` to the re-export:
    ```dart
    export 'package:supabase_flutter/supabase_flutter.dart'
        show OAuthProvider, User, PostgrestException;
    ```
    (**ARCH25 rule**: no other file in the project may import `supabase_flutter` directly; `PostgrestException` must be accessed via this file only.)
  - [x] 1.3 Run `flutter analyze` — 0 issues.

- [x] **Task 2 — Domain entities (AC1, AC2, AC3)**
  - [x] 2.1 Create `lib/features/social/friends/domain/entities/visibility_tier.dart`:
    ```dart
    enum VisibilityTier {
      private,
      friendsOnly;

      String toSupabaseValue() => switch (this) {
            VisibilityTier.private => 'private',
            VisibilityTier.friendsOnly => 'friends_only',
          };

      static VisibilityTier fromSupabaseValue(String value) => switch (value) {
            'friends_only' => VisibilityTier.friendsOnly,
            _ => VisibilityTier.private,
          };
    }
    ```
  - [x] 2.2 Create `lib/features/social/friends/domain/entities/social_profile.dart`:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

    part 'social_profile.freezed.dart';

    @freezed
    class SocialProfile with _$SocialProfile {
      const factory SocialProfile({
        required String userId,
        String? displayHandle,
        required VisibilityTier visibilityTier,
      }) = _SocialProfile;
    }
    ```
    (No `fromJson` on the domain entity — JSON parsing lives in the DTO. Domain entities are pure Dart, no `json_serializable`.)

- [x] **Task 3 — Repository interface + use cases (AC1, AC2, AC3)**
  - [x] 3.1 Create `lib/features/social/friends/domain/repositories/social_profile_repository.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

    abstract class SocialProfileRepository {
      Future<Either<SocialFailure, SocialProfile>> getSocialProfile();
      Future<Either<SocialFailure, SocialProfile>> updateHandle(String handle);
      Future<Either<SocialFailure, SocialProfile>> updateVisibilityTier(VisibilityTier tier);
    }
    ```
  - [x] 3.2 Create `lib/features/social/friends/domain/usecases/get_social_profile_use_case.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
    import 'package:pulse_coach/features/social/friends/domain/repositories/social_profile_repository.dart';

    @injectable
    class GetSocialProfileUseCase {
      final SocialProfileRepository _repository;
      const GetSocialProfileUseCase(this._repository);

      Future<Either<SocialFailure, SocialProfile>> call() =>
          _repository.getSocialProfile();
    }
    ```
  - [x] 3.3 Create `lib/features/social/friends/domain/usecases/update_handle_use_case.dart`:
    ```dart
    @injectable
    class UpdateHandleUseCase {
      final SocialProfileRepository _repository;
      const UpdateHandleUseCase(this._repository);

      Future<Either<SocialFailure, SocialProfile>> call(String handle) =>
          _repository.updateHandle(handle);
    }
    ```
  - [x] 3.4 Create `lib/features/social/friends/domain/usecases/update_visibility_tier_use_case.dart`:
    ```dart
    @injectable
    class UpdateVisibilityTierUseCase {
      final SocialProfileRepository _repository;
      const UpdateVisibilityTierUseCase(this._repository);

      Future<Either<SocialFailure, SocialProfile>> call(VisibilityTier tier) =>
          _repository.updateVisibilityTier(tier);
    }
    ```

- [x] **Task 4 — Data layer: DTO + remote datasource (AC1, AC2, AC3)**
  - [x] 4.1 Create `lib/features/social/friends/data/models/social_profile_dto.dart`:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

    part 'social_profile_dto.freezed.dart';
    part 'social_profile_dto.g.dart';

    @freezed
    class SocialProfileDto with _$SocialProfileDto {
      const factory SocialProfileDto({
        @JsonKey(name: 'id') required String id,
        @JsonKey(name: 'display_handle') String? displayHandle,
        @JsonKey(name: 'visibility_tier') required String visibilityTier,
      }) = _SocialProfileDto;

      factory SocialProfileDto.fromJson(Map<String, dynamic> json) =>
          _$SocialProfileDtoFromJson(json);
    }

    extension SocialProfileDtoMapper on SocialProfileDto {
      SocialProfile toDomain() => SocialProfile(
            userId: id,
            displayHandle: displayHandle,
            visibilityTier: VisibilityTier.fromSupabaseValue(visibilityTier),
          );
    }
    ```
  - [x] 4.2 Create `lib/features/social/friends/data/datasources/social_profile_remote_data_source.dart`:
    ```dart
    import 'package:flutter/foundation.dart' show visibleForTesting;
    import 'package:injectable/injectable.dart';
    // Import only from the ARCH25 boundary — never from supabase_flutter directly.
    import 'package:pulse_coach/core/cloud/supabase_client.dart'
        show PostgrestException, SupabaseClientProvider;
    import 'package:pulse_coach/features/social/friends/data/models/social_profile_dto.dart';

    @injectable
    class SocialProfileRemoteDataSource {
      final SupabaseClientProvider _supabase;

      SocialProfileRemoteDataSource(this._supabase) {
        fetchProfile = _defaultFetchProfile;
        patchProfile = _defaultPatchProfile;
      }

      /// Overridable in tests — returns the raw Supabase map for the current user's profile row.
      @visibleForTesting
      late Future<Map<String, dynamic>?> Function() fetchProfile;

      /// Overridable in tests — patches a map of columns on the current user's profile row.
      /// Returns the updated profile row on success; throws PostgrestException on failure.
      @visibleForTesting
      late Future<Map<String, dynamic>> Function(Map<String, dynamic> patch) patchProfile;

      Future<Map<String, dynamic>?> _defaultFetchProfile() async {
        final userId = _supabase.client.auth.currentUser?.id;
        if (userId == null) throw Exception('Not signed in');
        return _supabase.client
            .from('profiles')
            .select('id, display_handle, visibility_tier')
            .eq('id', userId)
            .maybeSingle();
      }

      Future<Map<String, dynamic>> _defaultPatchProfile(
          Map<String, dynamic> patch) async {
        final userId = _supabase.client.auth.currentUser?.id;
        if (userId == null) throw Exception('Not signed in');
        final result = await _supabase.client
            .from('profiles')
            .update(patch)
            .eq('id', userId)
            .select('id, display_handle, visibility_tier')
            .single();
        return result;
      }

      Future<SocialProfileDto> getSocialProfile() async {
        final row = await fetchProfile();
        if (row == null) {
          // Profile row doesn't exist yet — return a default (private, no handle)
          final userId = _supabase.client.auth.currentUser!.id;
          return SocialProfileDto(
            id: userId,
            displayHandle: null,
            visibilityTier: 'private',
          );
        }
        return SocialProfileDto.fromJson(row);
      }

      Future<SocialProfileDto> updateHandle(String handle) async {
        // PostgrestException with code '23505' = unique constraint violation (handle taken).
        final row = await patchProfile({'display_handle': handle});
        return SocialProfileDto.fromJson(row);
      }

      Future<SocialProfileDto> updateVisibilityTier(String supabaseValue) async {
        final row = await patchProfile({'visibility_tier': supabaseValue});
        return SocialProfileDto.fromJson(row);
      }
    }
    ```
    **Critical**: Never import `supabase_flutter` directly. Access `PostgrestException` only via `pulse_coach/core/cloud/supabase_client.dart` (ARCH25).

- [x] **Task 5 — Repository impl (AC1, AC2, AC3)**
  - [x] 5.1 Create `lib/features/social/friends/data/repositories/social_profile_repository_impl.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/cloud/supabase_client.dart' show PostgrestException;
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/friends/data/datasources/social_profile_remote_data_source.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
    import 'package:pulse_coach/features/social/friends/domain/repositories/social_profile_repository.dart';

    @Injectable(as: SocialProfileRepository)
    class SocialProfileRepositoryImpl implements SocialProfileRepository {
      final SocialProfileRemoteDataSource _dataSource;
      const SocialProfileRepositoryImpl(this._dataSource);

      @override
      Future<Either<SocialFailure, SocialProfile>> getSocialProfile() async {
        try {
          final dto = await _dataSource.getSocialProfile();
          return Right(dto.toDomain());
        } catch (e) {
          return Left(SocialFailure('Failed to load profile: $e'));
        }
      }

      @override
      Future<Either<SocialFailure, SocialProfile>> updateHandle(String handle) async {
        try {
          final dto = await _dataSource.updateHandle(handle);
          return Right(dto.toDomain());
        } on PostgrestException catch (e) {
          if (e.code == '23505') return const Left(SocialHandleTakenFailure());
          return Left(SocialFailure('Handle update failed: ${e.message}'));
        } catch (e) {
          return Left(SocialFailure('Handle update failed: $e'));
        }
      }

      @override
      Future<Either<SocialFailure, SocialProfile>> updateVisibilityTier(
          VisibilityTier tier) async {
        try {
          final dto = await _dataSource.updateVisibilityTier(tier.toSupabaseValue());
          return Right(dto.toDomain());
        } catch (e) {
          return Left(SocialFailure('Visibility update failed: $e'));
        }
      }
    }
    ```

- [x] **Task 6 — SocialProfileBloc + VisibilityCubit + DI (AC1, AC2, AC3)**
  - [x] 6.1 Create `lib/features/social/friends/presentation/bloc/social_profile_event.dart`:
    ```dart
    import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

    abstract class SocialProfileEvent {
      const SocialProfileEvent();
    }

    class SocialProfileLoaded extends SocialProfileEvent {
      const SocialProfileLoaded();
    }

    class HandleUpdateRequested extends SocialProfileEvent {
      final String handle;
      const HandleUpdateRequested(this.handle);
    }

    class VisibilityTierUpdateRequested extends SocialProfileEvent {
      final VisibilityTier tier;
      const VisibilityTierUpdateRequested(this.tier);
    }
    ```
  - [x] 6.2 Create `lib/features/social/friends/presentation/bloc/social_profile_state.dart` (freezed):
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';

    part 'social_profile_state.freezed.dart';

    @freezed
    class SocialProfileState with _$SocialProfileState {
      const factory SocialProfileState.initial() = _Initial;
      const factory SocialProfileState.loading() = _Loading;
      const factory SocialProfileState.loaded({
        required SocialProfile profile,
      }) = _Loaded;
      const factory SocialProfileState.error({
        required Failure failure,
      }) = _Error;
    }
    ```
  - [x] 6.3 Create `lib/features/social/friends/presentation/bloc/social_profile_bloc.dart`:
    ```dart
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/features/social/friends/domain/usecases/get_social_profile_use_case.dart';
    import 'package:pulse_coach/features/social/friends/domain/usecases/update_handle_use_case.dart';
    import 'package:pulse_coach/features/social/friends/domain/usecases/update_visibility_tier_use_case.dart';
    import 'social_profile_event.dart';
    import 'social_profile_state.dart';

    @injectable
    class SocialProfileBloc extends Bloc<SocialProfileEvent, SocialProfileState> {
      final GetSocialProfileUseCase _getProfile;
      final UpdateHandleUseCase _updateHandle;
      final UpdateVisibilityTierUseCase _updateVisibilityTier;

      SocialProfileBloc(
        this._getProfile,
        this._updateHandle,
        this._updateVisibilityTier,
      ) : super(const SocialProfileState.initial()) {
        on<SocialProfileLoaded>(_onLoaded);
        on<HandleUpdateRequested>(_onHandleUpdate);
        on<VisibilityTierUpdateRequested>(_onVisibilityUpdate);
      }

      Future<void> _onLoaded(
          SocialProfileLoaded event, Emitter<SocialProfileState> emit) async {
        emit(const SocialProfileState.loading());
        final result = await _getProfile();
        result.fold(
          (f) => emit(SocialProfileState.error(failure: f)),
          (profile) => emit(SocialProfileState.loaded(profile: profile)),
        );
      }

      Future<void> _onHandleUpdate(
          HandleUpdateRequested event, Emitter<SocialProfileState> emit) async {
        emit(const SocialProfileState.loading());
        final result = await _updateHandle(event.handle);
        result.fold(
          (f) => emit(SocialProfileState.error(failure: f)),
          (profile) => emit(SocialProfileState.loaded(profile: profile)),
        );
      }

      Future<void> _onVisibilityUpdate(
          VisibilityTierUpdateRequested event, Emitter<SocialProfileState> emit) async {
        emit(const SocialProfileState.loading());
        final result = await _updateVisibilityTier(event.tier);
        result.fold(
          (f) => emit(SocialProfileState.error(failure: f)),
          (profile) => emit(SocialProfileState.loaded(profile: profile)),
        );
      }
    }
    ```
  - [x] 6.4 Create `lib/features/social/friends/presentation/bloc/visibility_cubit.dart`:
    ```dart
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

    /// UI-only cubit holding the currently selected visibility tier
    /// before (or immediately after) a PATCH is sent via SocialProfileBloc.
    @injectable
    class VisibilityCubit extends Cubit<VisibilityTier> {
      VisibilityCubit() : super(VisibilityTier.private);

      void select(VisibilityTier tier) => emit(tier);
    }
    ```
  - [x] 6.5 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` to generate:
    - `social_profile.freezed.dart`
    - `social_profile_dto.freezed.dart` + `social_profile_dto.g.dart`
    - `social_profile_state.freezed.dart`
    - Updated `injection.config.dart` (new injectables: `GetSocialProfileUseCase`, `UpdateHandleUseCase`, `UpdateVisibilityTierUseCase`, `SocialProfileRemoteDataSource`, `SocialProfileRepositoryImpl`, `SocialProfileBloc`, `VisibilityCubit`)
  - [x] 6.6 Run `flutter analyze` — 0 issues.

- [x] **Task 7 — Social tab: route + SocialPage placeholder + AppShell update (AC5)**
  - [x] 7.1 In `lib/core/routing/app_router.dart`:
    - Add `static const String social = '/social';`
    - Add `import 'package:pulse_coach/features/social/friends/presentation/pages/social_page.dart';`
    - Inside the `ShellRoute.routes` list, add after `progress`:
      ```dart
      GoRoute(
        path: social,
        builder: (context, state) => const SocialPage(),
      ),
      ```
  - [x] 7.2 Create `lib/features/social/friends/presentation/pages/social_page.dart`:
    ```dart
    import 'package:flutter/material.dart';

    class SocialPage extends StatelessWidget {
      const SocialPage({super.key});

      @override
      Widget build(BuildContext context) {
        return const Scaffold(
          body: Center(child: Text('Social')),
        );
      }
    }
    ```
    (Intentionally minimal placeholder — Stories 18.2–18.4 build the real content.)
  - [x] 7.3 In `lib/shared/widgets/app_shell.dart`, update `_tabs` and navigation:
    ```dart
    static const _tabs = [
      AppRouter.sessions,
      AppRouter.today,
      AppRouter.progress,
      AppRouter.social,  // ← ADD (index 3)
    ];
    ```
    Add 4th `BottomNavigationBarItem` in `_PhoneScaffold`:
    ```dart
    BottomNavigationBarItem(
      icon: const Icon(Icons.people),
      label: l10n.navTabSocial,
    ),
    ```
    Add 4th `NavigationRailDestination` in `_TabletScaffold`:
    ```dart
    NavigationRailDestination(
      icon: const Icon(Icons.people),
      label: Text(l10n.navTabSocial),
    ),
    ```
    **Critical**: `BottomNavigationBar.items.length` must equal `_tabs.length` (4). Existing tabs Sessions=0, Today=1, Progress=2 are unchanged; Social=3 is new.

- [x] **Task 8 — HandleSetupSection widget in AccountPage (AC1, AC2)**
  - [x] 8.1 Create `lib/features/social/friends/presentation/widgets/handle_setup_section.dart`:
    A `StatefulWidget` containing:
    - `TextFormField` for the handle input (hint: `l10n.handleSetupPlaceholder`)
    - A save `ElevatedButton` (`l10n.handleSetupSave`) that dispatches `HandleUpdateRequested`
    - A text skip link (`l10n.handleSetupSkip`) that simply clears the expansion (no Bloc event)
    - A `BlocConsumer<SocialProfileBloc, SocialProfileState>` that shows:
      - On `error(SocialHandleTakenFailure)`: inline error text (`l10n.handleDuplicateError`) below the field
      - On `error(other)`: a `SnackBar` with the generic failure message
      - On `loaded`: a success `SnackBar` (`l10n.handleUpdateSuccess`)
    - Shimmer loading placeholder (never a spinner — project rule) when state is `loading`
    - The section is only shown when `BlocBuilder<SocialProfileBloc, SocialProfileState>` yields `loaded` with `profile.displayHandle == null`; once a handle is set, the section collapses to a read-only display
  - [x] 8.2 In `lib/features/auth/presentation/pages/account_page.dart`, add:
    - `import`s for `SocialProfileBloc`, `HandleSetupSection`, `SocialProfileLoaded`
    - Wrap the page in a `BlocProvider` providing `SocialProfileBloc` (via `getIt`) that dispatches `SocialProfileLoaded()` on creation
    - Add `HandleSetupSection()` in the account page body

- [x] **Task 9 — VisibilityTierSelector widget (AC3)**
  - [x] 9.1 Create `lib/features/social/friends/presentation/widgets/visibility_tier_selector.dart`:
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
    import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
    import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
    import 'package:pulse_coach/features/social/friends/presentation/bloc/visibility_cubit.dart';

    class VisibilityTierSelector extends StatelessWidget {
      const VisibilityTierSelector({super.key});

      @override
      Widget build(BuildContext context) {
        return BlocBuilder<VisibilityCubit, VisibilityTier>(
          builder: (context, selected) {
            return SegmentedButton<VisibilityTier>(
              segments: [
                ButtonSegment(
                  value: VisibilityTier.private,
                  label: Text(AppLocalizations.of(context)!.visibilityTierPrivate),
                ),
                ButtonSegment(
                  value: VisibilityTier.friendsOnly,
                  label: Text(AppLocalizations.of(context)!.visibilityTierFriendsOnly),
                ),
              ],
              selected: {selected},
              onSelectionChanged: (Set<VisibilityTier> newSelection) {
                final tier = newSelection.first;
                context.read<VisibilityCubit>().select(tier);
                context.read<SocialProfileBloc>().add(
                      VisibilityTierUpdateRequested(tier),
                    );
              },
            );
          },
        );
      }
    }
    ```
    Use `SegmentedButton` (Material 3, already in the project via `useMaterial3: true`). No external library needed.
  - [x] 9.2 In `lib/features/auth/presentation/pages/account_page.dart`, add:
    - Provide `VisibilityCubit` (via `getIt`) in the page's `MultiBlocProvider`
    - Seed `VisibilityCubit` initial value from `SocialProfileBloc`'s loaded state when a profile is already set
    - Add `VisibilityTierSelector()` below the handle setup section under a "Visibilità profilo" / "Profile Visibility" label
    - `BlocListener<SocialProfileBloc, SocialProfileState>` already handles `VisibilityTierUpdateRequested` errors (show snackbar, revert `VisibilityCubit` to previous tier)

- [x] **Task 10 — ARB keys (AC1, AC2, AC3, AC5)**
  - [x] 10.1 In `lib/l10n/app/app_en.arb`, add before the closing `}`:
    ```json
    "navTabSocial": "Social",
    "visibilityTierPrivate": "Private",
    "visibilityTierFriendsOnly": "Friends only",
    "handleSetupTitle": "Set your username",
    "handleSetupPlaceholder": "e.g. paolol",
    "handleSetupSave": "Save",
    "handleSetupSkip": "Skip for now",
    "handleDuplicateError": "This username is already taken.",
    "handleUpdateSuccess": "Username saved."
    ```
  - [x] 10.2 In `lib/l10n/app/app_it.arb`, add before the closing `}`:
    ```json
    "navTabSocial": "Social",
    "visibilityTierPrivate": "Privato",
    "visibilityTierFriendsOnly": "Solo amici",
    "handleSetupTitle": "Imposta il tuo nome utente",
    "handleSetupPlaceholder": "es. paolol",
    "handleSetupSave": "Salva",
    "handleSetupSkip": "Salta per ora",
    "handleDuplicateError": "Questo nome utente è già in uso.",
    "handleUpdateSuccess": "Nome utente salvato."
    ```
  - [x] 10.3 Run `flutter pub get` (triggers `gen_l10n`) to regenerate `app_localizations*.dart` under `lib/l10n/`. The generated files are `.gitignore`'d — do not commit them.

- [x] **Task 11 — Tests (AC2, AC3, AC6)**
  - [x] 11.1 Create `test/data/social/social_profile_remote_data_source_test.dart`:
    Tests using `@visibleForTesting` seams (same pattern as `auth_remote_data_source_test.dart` in Story 18.0):
    ```dart
    // [18.1-DS-001] getSocialProfile — row exists → returns DTO
    // [18.1-DS-002] getSocialProfile — no row → returns default private DTO
    // [18.1-DS-003] updateHandle — success → returns updated DTO
    // [18.1-DS-004] updateHandle — 23505 exception propagated (caught in repository layer)
    // [18.1-DS-005] updateVisibilityTier — success → returns updated DTO
    ```
    Override `fetchProfile` and `patchProfile` hooks; no Supabase initialization required. Use `MockSupabaseClientProvider` only to satisfy constructor; actual calls go through the overridden hooks.
  - [x] 11.2 Create `test/bloc/social_profile_bloc_test.dart`:
    Use `@GenerateMocks([SocialProfileRepository])` and `bloc_test` package:
    ```dart
    // [18.1-BLOC-001] SocialProfileLoaded → [loading, loaded(profile)]
    // [18.1-BLOC-002] HandleUpdateRequested(unique) → [loading, loaded(updatedProfile)]
    // [18.1-BLOC-003] HandleUpdateRequested(taken) → [loading, error(SocialHandleTakenFailure)]
    // [18.1-BLOC-004] VisibilityTierUpdateRequested → [loading, loaded(updatedProfile)]
    ```
  - [x] 11.3 Create `test/widget/visibility_tier_selector_test.dart`:
    ```dart
    // [18.1-WIDGET-001] renders two segments (Private, Friends Only)
    // [18.1-WIDGET-002] tapping Friends Only dispatches VisibilityTierUpdateRequested(friendsOnly)
    // [18.1-WIDGET-003] tapping Private dispatches VisibilityTierUpdateRequested(private)
    ```
  - [x] 11.4 Run `dart run build_runner build --delete-conflicting-outputs` to generate mock files.
  - [x] 11.5 Run `flutter test` — all existing tests plus new tests green.
  - [x] 11.6 Run `flutter analyze lib/ test/` — 0 issues.

## Dev Notes

### Critical: ARCH25 — Never Import supabase_flutter Directly

The project has a hard architectural rule (ARCH25) that only two files may import `supabase_flutter` directly: `lib/core/cloud/supabase_client.dart` and `main.dart`. The datasource in Task 4 needs `PostgrestException` to detect handle-taken errors. **Solution**: add `PostgrestException` to the re-export in `supabase_client.dart` (Task 1.2), then import it via `pulse_coach/core/cloud/supabase_client.dart` only.

### Critical: PostgrestException Code for Unique Violation

Supabase PostgREST returns HTTP 409 and throws `PostgrestException` with `code == '23505'` when a UNIQUE constraint is violated. The `display_handle` column in the `profiles` table has `UNIQUE` enforced at the DB level (migration `0001_profiles_auth.sql`, line 8: `display_handle text UNIQUE`). The repository catches this code and maps it to `SocialHandleTakenFailure` (no generic message needed — the UI looks for the specific type).

### Critical: profiles Table Already Exists — No New Migration Needed for This Story

Migration `0001_profiles_auth.sql` already creates the `profiles` table with `display_handle text UNIQUE`, `visibility_tier visibility_tier_enum NOT NULL DEFAULT 'private'`, and the three self-access RLS policies. **Do NOT create a new migration for Story 18.1.** The existing table schema satisfies all ACs. The `friendships` table + friends-discovery RLS policy (`profiles_select_by_handle`) will be added in Story 18.2's migration.

### Critical: VisibilityCubit Seed from SocialProfileBloc State

When the Account page loads, `SocialProfileBloc` dispatches `SocialProfileLoaded` and eventually emits `loaded(profile)`. At that point, `VisibilityCubit` must be seeded with `profile.visibilityTier` so the `VisibilityTierSelector` shows the current saved tier, not always "Private". Do this with a `BlocListener<SocialProfileBloc, SocialProfileState>` that calls `context.read<VisibilityCubit>().select(profile.visibilityTier)` when the state becomes `loaded`.

### Critical: AppShell Tab Index Preservation

The existing `_tabs` list order is `[sessions, today, progress]` → indices 0, 1, 2. Adding `social` at index 3 is safe. **Do not reorder existing tabs** — `CLAUDE.md` states "tab order is now `Sessions, Today, Progress` (matching UX spec)" and has been verified on device. The `_currentIndex` method uses `startsWith`, so ensure `/social` does not prefix-match any existing route (it doesn't).

### Critical: VisibilityTierSelector Error Revert Pattern

When `VisibilityTierUpdateRequested` is dispatched and the Bloc returns an error, the `VisibilityCubit` has already been updated to the new tier (optimistic UI). The `BlocListener` on `SocialProfileBloc` must revert the `VisibilityCubit` to the previous tier on error. Keep a local `_previousTier` variable in the widget state or use the Bloc's last `loaded` state to restore. Pattern:
```dart
// In BlocListener:
if (state is _Error) {
  // Revert to last known good tier from the previously loaded profile
  final lastLoaded = /* current loaded profile from bloc state or local variable */;
  context.read<VisibilityCubit>().select(lastLoaded.visibilityTier);
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### Critical: Domain Entity Has No fromJson

`SocialProfile` (domain entity) does NOT have `fromJson` — domain entities are pure Dart (no `json_serializable`). Only `SocialProfileDto` (data layer) has `fromJson`. The repo calls `dto.toDomain()` at the data→domain boundary. Do not add `fromJson` to `SocialProfile`.

### Critical: build_runner Required Twice

Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` **twice** in this story:
1. After Task 6 (to generate freezed/injectable/json_serializable for the new social models + bloc state)
2. After Task 11 (to generate mock files for tests)

Order matters — generate production code first, then test mocks.

### Pattern Reference: @visibleForTesting Seam

For `SocialProfileRemoteDataSource`, use the same hook pattern established in Story 18.0:
- Constructor assigns default implementations to `late` fields
- Tests override the fields directly (no mockito for the datasource itself)
- `MockSupabaseClientProvider` is only needed to satisfy the constructor — it's never called in tests since all Supabase calls go through the overridden hooks

Pattern is in `lib/features/auth/data/datasources/auth_remote_data_source.dart` lines 21–32 and Story 18.0 dev notes.

### Pattern Reference: SegmentedButton for VisibilityTierSelector

Use Material 3 `SegmentedButton<VisibilityTier>` — available in Flutter SDK 3.41.x. No additional package needed. Project already uses `useMaterial3: true` in `ThemeData`. `SegmentedButton` follows theme tokens automatically — do not hardcode colors or text styles.

### Gating: Handle Setup and Visibility Tier Are signedInFree

Per the three-tier gating rule (architecture "Process Patterns — v2"):
- `account-free` → v1 core only
- `signed-in free` → + backup/restore, **set handle**, **view leaderboard ranking**
- `Pro` → + friends, feed, shared sessions, scoring

Handle setup and visibility tier setting are `signedInFree`. **Do NOT add an `EntitlementGate` check** for these operations. The Supabase `profiles_update_own` RLS already enforces that only the authenticated user can write. The handle and visibility fields are on the user's own profile row — no Pro gate required.

### Failure Type Pattern

`SocialHandleTakenFailure extends SocialFailure` — the UI pattern-matches on the failure type (not the message string) to show the right error:
```dart
if (failure is SocialHandleTakenFailure) {
  // Show inline field error: l10n.handleDuplicateError
} else {
  // Show snackbar with generic failure message
}
```

### No Social Tab Content in This Story

`SocialPage` is intentionally empty (`Center(child: Text('Social'))`). Stories 18.2–18.4 build the friends list, activity feed, and comparison views. Do not pre-implement any of those in 18.1.

### Project Structure — Files NEW/MODIFIED

```
lib/core/error/
  failures.dart                                        # MODIFIED (+SocialFailure, +SocialHandleTakenFailure)

lib/core/cloud/
  supabase_client.dart                                 # MODIFIED (+PostgrestException re-export)

lib/core/routing/
  app_router.dart                                      # MODIFIED (+social route + import)

lib/shared/widgets/
  app_shell.dart                                       # MODIFIED (+social tab)

lib/features/social/friends/
  domain/entities/
    visibility_tier.dart                               # NEW
    social_profile.dart                                # NEW
    social_profile.freezed.dart                        # GENERATED
  domain/repositories/
    social_profile_repository.dart                     # NEW
  domain/usecases/
    get_social_profile_use_case.dart                   # NEW
    update_handle_use_case.dart                        # NEW
    update_visibility_tier_use_case.dart               # NEW
  data/models/
    social_profile_dto.dart                            # NEW
    social_profile_dto.freezed.dart                    # GENERATED
    social_profile_dto.g.dart                          # GENERATED
  data/datasources/
    social_profile_remote_data_source.dart             # NEW
  data/repositories/
    social_profile_repository_impl.dart                # NEW
  presentation/bloc/
    social_profile_event.dart                          # NEW
    social_profile_state.dart                          # NEW
    social_profile_state.freezed.dart                  # GENERATED
    social_profile_bloc.dart                           # NEW
    visibility_cubit.dart                              # NEW
  presentation/pages/
    social_page.dart                                   # NEW
  presentation/widgets/
    handle_setup_section.dart                          # NEW
    visibility_tier_selector.dart                      # NEW

lib/l10n/app/
  app_en.arb                                           # MODIFIED (+9 keys)
  app_it.arb                                           # MODIFIED (+9 keys)

lib/features/auth/presentation/pages/
  account_page.dart                                    # MODIFIED (+HandleSetupSection, +VisibilityTierSelector, +SocialProfileBloc provider, +VisibilityCubit provider)

lib/core/di/
  injection.config.dart                                # GENERATED (updated DI)

test/data/social/
  social_profile_remote_data_source_test.dart          # NEW (5 tests: 18.1-DS-001..005)
test/bloc/
  social_profile_bloc_test.dart                        # NEW (4 tests: 18.1-BLOC-001..004)
test/widget/
  visibility_tier_selector_test.dart                   # NEW (3 tests: 18.1-WIDGET-001..003)
```

### Category A Fire-Check (Story Entry)

**Category A snapshot before this story: 2/5** (`E10R-2` non-UTC week-bucketing test, `E17R-1` paywall i18n).

No Category A deliverable-debt item is triggered by Story 18.1 (no new persistence error paths, no cross-cubit index state, no new DAO). The ongoing process fire-check (E9-K1) finds nothing to escalate. Sprint cleared.

### References

- Epic 18.1 ACs: `_bmad-output/planning-artifacts/epics.md` line 2394
- Social schema overview: `_bmad-output/planning-artifacts/architecture.md` line 401
- ARCH25 boundary (supabase_flutter import rule): `lib/core/cloud/supabase_client.dart` lines 1–5
- `profiles` table schema + RLS: `supabase/migrations/0001_profiles_auth.sql`
- Three-tier gating rule: `_bmad-output/planning-artifacts/architecture.md` line 793
- `EntitlementGate` pattern: `lib/core/cloud/entitlement_gate.dart`
- Feature enum: `lib/features/subscription/domain/entities/feature.dart`
- Existing failure hierarchy: `lib/core/error/failures.dart`
- `@visibleForTesting` seam pattern (reference): `lib/features/auth/data/datasources/auth_remote_data_source.dart` lines 21–32
- AppShell tab order constraint: `CLAUDE.md` Manual Verification Notes ("tab order is now Sessions, Today, Progress")
- ARB/l10n pipeline: `pulse_coach/lib/l10n/app/` (app_en.arb, app_it.arb); generated files .gitignore'd
- v2 naming patterns (Supabase columns snake_case → Dart camelCase via @JsonKey): architecture.md line 738
- Story 18.0 seam pattern (for test reference): `_bmad-output/implementation-artifacts/18-0-auth-backup-datasource-test-hardening.md` Tasks 3–4

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `abstract class` required for single-factory `@freezed` classes in freezed 3.2.x (vs just `class`). Fixed for `SocialProfile` and `SocialProfileDto`.
- `SocialProfileRepositoryImpl` missing import of `social_profile_dto.dart` for the `toDomain()` extension — added.
- DS-002 test: `MissingStubError` is an `Error` not `Exception`; updated assertion to `throwsA(anything)`.
- Widget test: needed `GlobalCupertinoLocalizations.delegate` alongside `GlobalMaterialLocalizations.delegate` for Italian locale.

### Completion Notes List

- **Task 1**: Added `SocialFailure` + `SocialHandleTakenFailure` to `failures.dart`; added `PostgrestException` to `supabase_client.dart` re-export. `flutter analyze` 0 issues.
- **Task 2**: `VisibilityTier` enum with `toSupabaseValue`/`fromSupabaseValue`; `SocialProfile` abstract freezed entity (no `fromJson` — domain layer only).
- **Task 3**: `SocialProfileRepository` abstract + 3 use cases (`GetSocialProfileUseCase`, `UpdateHandleUseCase`, `UpdateVisibilityTierUseCase`) all `@injectable`.
- **Task 4**: `SocialProfileDto` abstract freezed + `json_serializable` + `toDomain()` extension; `SocialProfileRemoteDataSource` with `@visibleForTesting` `fetchProfile`/`patchProfile` hooks.
- **Task 5**: `SocialProfileRepositoryImpl @Injectable(as: SocialProfileRepository)` — maps `PostgrestException` code `23505` to `SocialHandleTakenFailure`.
- **Task 6**: `SocialProfileBloc` + `VisibilityCubit`; `build_runner` generated freezed/injectable/json files.
- **Task 7**: `/social` route + `SocialPage` placeholder; AppShell `_tabs` updated to 4 items (Social at index 3); both `_PhoneScaffold` and `_TabletScaffold` updated.
- **Task 8**: `HandleSetupSection` `StatefulWidget` with `BlocConsumer<SocialProfileBloc>` — inline error for `SocialHandleTakenFailure`, snackbar for generic errors, success snackbar on `loaded`, shimmer loading, collapses when handle already set.
- **Task 9**: `VisibilityTierSelector` with `SegmentedButton<VisibilityTier>` (Material 3); `AccountPage` refactored to `StatefulWidget` content class tracking `_lastKnownTier` for error revert.
- **Task 10**: 9 ARB keys added to `app_en.arb` + `app_it.arb`; `flutter pub get` regenerated l10n.
- **Task 11**: 12 new tests (5 datasource, 4 bloc, 3 widget) all green. Full suite: 999/999 green. `flutter analyze` 0 issues.

### File List

lib/core/error/failures.dart
lib/core/cloud/supabase_client.dart
lib/core/routing/app_router.dart
lib/shared/widgets/app_shell.dart
lib/features/social/friends/domain/entities/visibility_tier.dart
lib/features/social/friends/domain/entities/social_profile.dart
lib/features/social/friends/domain/repositories/social_profile_repository.dart
lib/features/social/friends/domain/usecases/get_social_profile_use_case.dart
lib/features/social/friends/domain/usecases/update_handle_use_case.dart
lib/features/social/friends/domain/usecases/update_visibility_tier_use_case.dart
lib/features/social/friends/data/models/social_profile_dto.dart
lib/features/social/friends/data/datasources/social_profile_remote_data_source.dart
lib/features/social/friends/data/repositories/social_profile_repository_impl.dart
lib/features/social/friends/presentation/bloc/social_profile_event.dart
lib/features/social/friends/presentation/bloc/social_profile_state.dart
lib/features/social/friends/presentation/bloc/social_profile_bloc.dart
lib/features/social/friends/presentation/bloc/visibility_cubit.dart
lib/features/social/friends/presentation/pages/social_page.dart
lib/features/social/friends/presentation/widgets/handle_setup_section.dart
lib/features/social/friends/presentation/widgets/visibility_tier_selector.dart
lib/features/auth/presentation/pages/account_page.dart
lib/l10n/app/app_en.arb
lib/l10n/app/app_it.arb
lib/core/di/injection.config.dart
test/data/social/social_profile_remote_data_source_test.dart
test/data/social/social_profile_remote_data_source_test.mocks.dart
test/bloc/social_profile_bloc_test.dart
test/bloc/social_profile_bloc_test.mocks.dart
test/widget/visibility_tier_selector_test.dart
test/widget/visibility_tier_selector_test.mocks.dart

## Change Log

- Implemented Story 18.1: social domain layer (SocialFailure, SocialProfile, SocialProfileRepository, 3 use cases, DTO, datasource, repository impl), SocialProfileBloc + VisibilityCubit, HandleSetupSection widget, VisibilityTierSelector widget, Social tab at index 3 in AppShell, 9 ARB keys (EN + IT), 12 new tests. 999/999 green, 0 analyzer issues. (Date: 2026-06-23)

## Review Findings

_Code review 2026-06-23 (Blind Hunter + Edge Case Hunter + Acceptance Auditor, Opus). 1 decision-needed (resolved → patch), 10 patch, 0 defer, 6 dismissed as noise._

- [x] [Review][Patch] Handle input validation (resolved from decision-needed) — add client-side rules: trim + length 3–20, charset `[a-z0-9_]`, lowercase normalization, localized inline error. (blind+edge) [handle_setup_section.dart:108]

- [x] [Review][Patch] Spurious success snackbar on every `loaded` state — listener shows `handleUpdateSuccess` on page open AND on every visibility-tier change (shared bloc, no event-source discrimination). Also flashes the handle shimmer on visibility change. (blind+edge+auditor, HIGH) [handle_setup_section.dart:44]
- [x] [Review][Patch] Internal/untranslated exception text leaked to user — `failure.message` rendered raw in snackbar ("Exception: Not signed in", "Handle update failed: <e>"). Show a generic localized error instead. (blind+edge, MED) [handle_setup_section.dart:39]
- [x] [Review][Patch] `currentUser!` force-unwrap in `getSocialProfile` null-row branch throws an opaque TypeError if the session expired. Use a graceful guard. (blind+edge, MED) [social_profile_remote_data_source.dart, null-row branch]
- [x] [Review][Patch] Repository error-mapping is untested — the `23505` → `SocialHandleTakenFailure` mapping is never exercised end-to-end (DS-004 throws a plain `Exception`, not `PostgrestException`; DS-002 asserts `throwsA(anything)` around the force-unwrap defect). Add repository-layer unit tests. (blind, MED) [test/data/social/social_profile_remote_data_source_test.dart]
- [x] [Review][Patch] Cross-listener revert: a handle-update error reverts the `VisibilityCubit`; a visibility error before the first successful load reverts to `private` (never-fetched tier). Guard the account-page listener by intent. (edge+auditor, LOW) [account_page.dart:85]
- [x] [Review][Patch] "Skip for now" only clears the text field — it never dismisses/collapses the section, contradicting the label. (blind+edge+auditor, LOW) [handle_setup_section.dart:118]
- [x] [Review][Patch] Hardcoded Italian label `'Visibilità profilo'` bypasses the l10n pipeline (no ARB key, no EN counterpart). Add ARB key + use `l10n`. (blind, LOW) [account_page.dart:146]
- [x] [Review][Patch] Unused `required bool isLoading` parameter in `_buildForm` — dead parameter. Remove it and its call-site args. (auditor, LOW) [handle_setup_section.dart:86]
- [x] [Review][Patch] Rapid visibility toggles fire concurrent PATCHes with no in-flight guard/debounce; out-of-order responses can leave a stale selection. (edge, LOW) [visibility_tier_selector.dart, onSelectionChanged]

_Dismissed (false positives / not actionable): DTO `visibility_tier` null-crash (DB column is `NOT NULL DEFAULT 'private'`); `context.read` after dispose (BlocListener is lifecycle-safe); `fromSupabaseValue` coercion (only 2 enum values exist); `VisibilityCubit` factory desync (no second consumer in this story); `SegmentedButton.first` fragility (empty selection disallowed by default); import-ordering nit (`flutter analyze` clean)._

