---
baseline_commit: 900d718ffa986d3cd62a3947cf06e9fb15118901
---

# Story 19.0: Profile Row Creation on Signup (closes E18R-5)

Status: done

## Story

As a newly-registered user,
I want a `profiles` row to exist automatically the moment my account is created,
So that I can set my handle, choose my visibility tier, and be discoverable — and so the realtime social layer has a profile to resolve.

## Context

**Critical-path prerequisite for Epic 19.** Found by the E18R-3 live-backend spike (2026-06-24): a genuinely new user has **no `profiles` row at all**. `SocialProfileRemoteDataSource` only issues `UPDATE`s — there is no `INSERT` path and no DB trigger. A fresh user's `updateHandle` call hits `.single()` on an empty result set and throws a `PostgrestException`, making handle/visibility setup (Story 18.1) unreachable for new users. Epic 19 presence/handle-based discovery would have no profile to resolve. Same pattern as Story 18.0 (closed E16R-1 before Epic 18 built on it).

This story also folds in **E18R-6** (AC4): GoTrue returns `400 email_address_invalid` for `.dev`/no-MX email domains, but the app currently shows the generic "Accesso non riuscito. Riprova." instead of a specific localized error.

## Acceptance Criteria

**AC1 — Trigger creates profiles row on signup:**
Given a new user completes email, Apple, or Google signup
When the `auth.users` row is created by GoTrue
Then a matching `public.profiles` row is created automatically with:
- `id = auth.users.id`
- `visibility_tier = 'private'` (enum default)
- `install_cohort = 'post_v2'` (enum default)
- `display_handle = NULL`
Implemented as a Postgres `handle_new_user` trigger on `auth.users` firing AFTER INSERT — server-authoritative, fires for every provider

**AC2 — handle update succeeds for new users:**
Given the new `profiles` row exists (created by the trigger)
When the user opens the Account page and submits a handle
Then `updateHandle` succeeds: the `UPDATE ... .single()` now matches exactly one row; closes the E18R-3 finding where a fresh user's handle setup threw

**AC3 — Migration is idempotent and back-fills:**
Given migration `supabase/migrations/0008_handle_new_user_trigger.sql` is applied
When applied to a project that already has `auth.users` rows without `profiles` rows
Then it is idempotent (`CREATE OR REPLACE FUNCTION`, `DROP TRIGGER IF EXISTS`, `CREATE TRIGGER`) and back-fills a `profiles` row for any pre-existing `auth.users` lacking one; on-device verification against a live Supabase project (E18R-3 spike method) asserts that a freshly-created auth user has exactly one `profiles` row with the documented defaults

**AC4 — Localized error for invalid/no-MX email (E18R-6):**
Given signup with a no-MX or invalid email domain (e.g., GoTrue returns `400 email_address_invalid`)
When `AuthRepositoryImpl.signUp` catches the exception
Then it returns `Left(const AuthFailure('email_address_invalid'))`; `SignInSheet` detects `state.failure.message == 'email_address_invalid'` and renders `l10n.signInErrorInvalidEmail` (a new ARB key) instead of the generic `signInErrorGeneric`

**AC5 — Zero regressions:**
Given the new migration and Dart changes are added
When the suite runs from `pulse_coach/`
Then `flutter test` reports all existing tests plus new tests green; `flutter analyze lib/ test/` reports 0 issues

## Tasks / Subtasks

- [x] **Task 1 — Migration `0008_handle_new_user_trigger.sql` (AC1, AC2, AC3)**
  - [x] 1.1 Create `supabase/migrations/0008_handle_new_user_trigger.sql`:
    ```sql
    -- Story 19.0: Create a profiles row for every new auth.users row.
    -- Server-authoritative: fires for email, Apple, and Google signups.
    -- Migration is idempotent; back-fills pre-existing users on first apply.

    CREATE OR REPLACE FUNCTION public.handle_new_user()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = public
    AS $$
    BEGIN
      INSERT INTO public.profiles (id, display_handle, visibility_tier, install_cohort)
      VALUES (
        NEW.id,
        NULL,
        'private',
        'post_v2'
      )
      ON CONFLICT (id) DO NOTHING;
      RETURN NEW;
    END;
    $$;

    -- Idempotent: drop before recreating
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

    -- Back-fill: insert a profiles row for any auth.users without one
    INSERT INTO public.profiles (id, display_handle, visibility_tier, install_cohort)
    SELECT
      u.id,
      NULL,
      'private',
      'post_v2'
    FROM auth.users u
    WHERE NOT EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = u.id
    );
    ```
    **Critical — SECURITY DEFINER:** The trigger function must be `SECURITY DEFINER` so it runs with the function owner's privileges (bypassing RLS on `public.profiles`). Without it, the AFTER INSERT trigger runs in the context of the triggering operation, which is the GoTrue service role — but in Supabase, trigger functions on `auth.users` need SECURITY DEFINER + `SET search_path = public` to safely write to `public.profiles`. This is the standard Supabase pattern (same as used in most handle_new_user trigger examples in Supabase docs).

    **Critical — ON CONFLICT DO NOTHING:** Makes the INSERT idempotent if called multiple times (e.g., re-applying the migration). The back-fill at the bottom of the migration handles existing users without re-inserting.

    **Critical — Enum values:** Use string literals `'private'` and `'post_v2'` — Postgres will cast them to `visibility_tier_enum` and `install_cohort_enum` respectively (defined in `0001_profiles_auth.sql`). Do NOT use `::visibility_tier_enum` explicit casts in the trigger body; Postgres handles implicit cast from string literals to the column type.

    **Critical — Trigger on `auth.users`:** The trigger is created on `auth.users`, not `public.profiles`. This requires `postgres` superuser privileges in Supabase — apply via MCP `apply_migration` or Supabase dashboard SQL editor.

  - [x] 1.2 Verify via MCP (`mcp__supabase__apply_migration`) or dashboard:
    - Migration applies cleanly on the live EU project
    - `SELECT COUNT(*) FROM auth.users WHERE id NOT IN (SELECT id FROM public.profiles)` returns 0 (back-fill succeeded)
    - Create a new test auth user (email signup), immediately query `SELECT * FROM public.profiles WHERE id = '<new_uid>'` → exactly one row with `visibility_tier='private'`, `install_cohort='post_v2'`, `display_handle=null`

- [x] **Task 2 — E18R-6: Invalid email error detection (AC4)**
  - [x] 2.1 Modify `pulse_coach/lib/features/auth/data/repositories/auth_repository_impl.dart`, method `signUp`:
    ```dart
    @override
    Future<Either<AuthFailure, AuthUser?>> signUp({
      required String email,
      required String password,
    }) async {
      try {
        final user = await _dataSource.signUp(email: email, password: password);
        return Right(user);
      } catch (e) {
        if (e.toString().contains('email_address_invalid')) {
          return const Left(AuthFailure('email_address_invalid'));
        }
        return Left(AuthFailure(e.toString()));
      }
    }
    ```
    **Critical:** The sentinel string `'email_address_invalid'` appears in the GoTrue error response body, which supabase_flutter's `AuthException.message` carries verbatim. Using `.contains()` is robust across supabase_flutter minor versions regardless of whether the error_code is in `message` or `statusCode`.

    **Critical:** Do NOT add supabase_flutter's `AuthException` to the ARCH25 boundary exports in `supabase_client.dart` just for this check — the generic `catch (e)` with string inspection is simpler and doesn't expand the ARCH25 surface.

  - [x] 2.2 Modify `pulse_coach/lib/features/auth/presentation/widgets/sign_in_sheet.dart`, the `if (state is AuthError)` block (currently at line ~211):
    ```dart
    if (state is AuthError) ...[
      const SizedBox(height: 12),
      Text(
        state.failure.message == 'email_address_invalid'
            ? l10n.signInErrorInvalidEmail
            : l10n.signInErrorGeneric,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    ],
    ```
    **Critical:** The check is `state.failure.message == 'email_address_invalid'` — a string equality check, not a type check. `AuthState.error({required AuthFailure failure})` is the freezed variant; `state.failure` is accessible directly because `state is AuthError` (the sealed class pattern). Check the generated `auth_bloc.freezed.dart` to confirm the accessor name: it is `failure` (not `authFailure`).

- [x] **Task 3 — ARB keys (AC4)**
  - [x] 3.1 In `pulse_coach/lib/l10n/app/app_en.arb`, add after `"signInErrorNoConnectivity"` key (line ~229):
    ```json
    "signInErrorInvalidEmail": "Email address not valid. Use a real address.",
    ```
  - [x] 3.2 In `pulse_coach/lib/l10n/app/app_it.arb`, add after `"signInErrorNoConnectivity"` key (line ~229):
    ```json
    "signInErrorInvalidEmail": "Indirizzo email non valido. Usa un indirizzo reale.",
    ```
  - [x] 3.3 Run `flutter pub get` from `pulse_coach/` to regenerate `app_localizations*.dart`.

- [x] **Task 4 — Tests (AC3, AC4, AC5)**
  - [x] 4.1 Update `pulse_coach/test/data/auth/auth_repository_impl_test.dart` — add two tests in the `signUp` group (after existing `19-0-REPO-002` if present, else after existing signUp tests):
    ```
    // [19.0-REPO-001] signUp — GoTrue throws 'email_address_invalid' → Left(AuthFailure('email_address_invalid'))
    // [19.0-REPO-002] signUp — other error → Left(AuthFailure(e.toString()))
    ```
    Test body pattern (mirrors existing signIn/signUp tests in the same file):
    ```dart
    group('signUp email_address_invalid (19.0)', () {
      test('19.0-REPO-001: exception with email_address_invalid → Left sentinel', () async {
        when(mockDataSource.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('email_address_invalid: invalid MX'));
        final result = await sut.signUp(email: 'bad@dev', password: 'pass');
        expect(
          result,
          equals(const Left<AuthFailure, AuthUser?>(AuthFailure('email_address_invalid'))),
        );
      });

      test('19.0-REPO-002: other exception → Left with message', () async {
        when(mockDataSource.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('network error'));
        final result = await sut.signUp(email: 'x@y.com', password: 'pass');
        result.fold(
          (f) => expect(f, isA<AuthFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
    ```

  - [x] 4.2 Create `pulse_coach/test/bloc/auth/sign_in_sheet_error_test.dart` (widget test):
    ```
    // [19.0-WIDGET-001] AuthError with 'email_address_invalid' failure → shows signInErrorInvalidEmail
    // [19.0-WIDGET-002] AuthError with generic failure → shows signInErrorGeneric
    ```
    Pattern: pump `SignInSheet` inside a `BlocProvider<AuthBloc>` seeded with `AuthState.error(failure: const AuthFailure('email_address_invalid'))`. Verify that the `signInErrorInvalidEmail` text is present and `signInErrorGeneric` is absent. Reverse for test 002.

    **Critical:** Seeding a Bloc with a pre-built state for widget tests: use `blocTest`'s `build:` + `seed:` or construct a minimal `MockAuthBloc` that returns the desired initial state. The existing `test/bloc/auth_bloc_test.dart` uses `bloc_test` + `@GenerateMocks`. For the widget test, use a `BlocProvider.value` approach with a stub that emits one state.

  - [x] 4.3 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` (only needed if Task 4.2 introduces new `@GenerateMocks` — if the widget test stubs the Bloc inline without generated mocks, skip this).
  - [x] 4.4 Run `flutter test` from `pulse_coach/` — all existing + new tests green.
  - [x] 4.5 Run `flutter analyze lib/ test/` from `pulse_coach/` — 0 issues.

## Dev Notes

### Critical: ARCH25 — supabase_flutter boundary is NOT expanded

`supabase_client.dart` currently exports `OAuthProvider`, `User`, `PostgrestException`. Do NOT add `AuthException` to this export just for the E18R-6 sentinel check. The generic `catch (e)` + `e.toString().contains('email_address_invalid')` in `auth_repository_impl.dart` achieves the same result without changing the ARCH25 boundary surface.

### Critical: trigger on `auth.users` requires superuser context

The migration creates a trigger on `auth.users` (schema `auth`). In Supabase, this requires the `postgres` role, which has CREATE TRIGGER privileges on `auth.users`. Apply via:
- `mcp__supabase__apply_migration` (recommended in this project)
- Supabase dashboard > SQL Editor

Do NOT try to apply via a regular authenticated role or via `supabase_flutter` — the migration must be applied at the infrastructure level.

### Critical: `SECURITY DEFINER` + `SET search_path = public`

Without `SECURITY DEFINER`, the trigger function runs as the `supabase_auth_admin` role (or the triggering role), which may not have INSERT privileges on `public.profiles` with RLS enabled. The `SET search_path = public` prevents search-path injection attacks (Supabase security best practice for SECURITY DEFINER functions).

### Critical: `ON CONFLICT (id) DO NOTHING` makes INSERT idempotent

The `profiles` table has `id` as PRIMARY KEY referencing `auth.users(id)`. The `ON CONFLICT (id) DO NOTHING` clause ensures that if the trigger fires twice (impossible in practice, but defensive) or if the migration is re-applied, no error is raised.

### Critical: `auth_repository_impl.dart` has `_syncInstallCohort` in sign-in but NOT in sign-up

Look at the existing `signUp` implementation: it does NOT call `_syncInstallCohort`. This is correct — at signup, there is no local drift profile yet (onboarding hasn't happened). Do NOT add `_syncInstallCohort` to the modified `signUp` method; preserve the existing behavior.

### Critical: `sign_in_sheet.dart` — `AuthError` is a sealed class variant

The `AuthState` is a `@freezed sealed class` with variants. After `if (state is AuthError)`, the `state` variable is downcast to `AuthError`, which has a `failure` field of type `AuthFailure`. Access it as `state.failure.message`. The currently rendered `signInErrorGeneric` is always shown regardless of failure type — the fix adds a conditional check before falling back to the generic message.

### Critical: Do NOT change Apple/Google signup paths

`signInWithApple`, `signInWithGoogle`, and `signInWithEmail` in `AuthRepositoryImpl` are NOT modified. Only `signUp` is changed (email signup is the only path that can return `email_address_invalid`). Apple/Google providers handle email validation on their side and never return this GoTrue error code.

### Critical: No new `Failure` subclass needed

The story does NOT add `AuthInvalidEmailFailure extends AuthFailure`. The sentinel string `'email_address_invalid'` on the existing `AuthFailure` class is sufficient and avoids expanding the failure hierarchy. The `failures.dart` file is unchanged.

### On-device verification (AC3)

The AC3 regression test is verified by the E18R-3 spike method (live Supabase + real auth user on device), not by a Flutter unit test (unit tests cannot reach the Supabase DB trigger). To verify:
1. Apply migration `0008` to the live EU project via MCP
2. Create a fresh test auth user (email signup via SignInSheet on device)
3. Immediately query `SELECT * FROM public.profiles WHERE id = '<new_uid>'`
4. Assert exactly one row with documented defaults

Record this verification in the dev notes (same format as E18R-3 spike record in `epic-18-retro-2026-06-24.md`).

### Category A fire-check (Story 19.0 entry)

**Category A snapshot entering sprint (post Epic 19 kickoff triage, 2026-06-24): 4 / 5.** Active: `E18R-1`, `E18R-2`, `E10R-2`, `E18R-4`. Closed/homed: `E18R-5` (→ Story 19.0), `E18R-6` (→ Story 19.0 AC4). Sprint gate satisfied: Story 19.0 is the first story in Epic 19. **Story 19.1 may NOT enter the sprint until Story 19.0 is `done`** (hard-block per kickoff triage).

### Project Structure — Files NEW/MODIFIED

```
supabase/migrations/
  0008_handle_new_user_trigger.sql                              # NEW

pulse_coach/
  lib/features/auth/data/repositories/
    auth_repository_impl.dart                                   # MODIFIED (signUp: sentinel check)

  lib/features/auth/presentation/widgets/
    sign_in_sheet.dart                                          # MODIFIED (error block: signInErrorInvalidEmail)

  lib/l10n/app/
    app_en.arb                                                  # MODIFIED (+1 key: signInErrorInvalidEmail)
    app_it.arb                                                  # MODIFIED (+1 key: signInErrorInvalidEmail)

  test/data/auth/
    auth_repository_impl_test.dart                             # MODIFIED (+2 tests: 19.0-REPO-001..002)

  test/bloc/auth/
    sign_in_sheet_error_test.dart                              # NEW (2 widget tests: 19.0-WIDGET-001..002)
```

No new domain entities, repositories, use cases, or Blocs. No `build_runner` run needed unless the widget test introduces new `@GenerateMocks` annotations.

### References

- Epic 19 ACs (epics.md line ~2504): `_bmad-output/planning-artifacts/epics.md`
- E18R-3 live spike record: `_bmad-output/implementation-artifacts/epic-18-retro-2026-06-24.md` line ~79
- Action-item ledger (E18R-5, E18R-6, kickoff triage): `_bmad-output/implementation-artifacts/action-item-ledger.md` line ~327
- `profiles` table schema: `supabase/migrations/0001_profiles_auth.sql`
- Existing auth migrations: `supabase/migrations/0001..0007`
- `SocialProfileRemoteDataSource.updateHandle` (UPDATE-only, the broken path): `pulse_coach/lib/features/social/friends/data/datasources/social_profile_remote_data_source.dart:63`
- `AuthRepositoryImpl.signUp` (file to modify): `pulse_coach/lib/features/auth/data/repositories/auth_repository_impl.dart:112`
- `SignInSheet` error block (widget to modify): `pulse_coach/lib/features/auth/presentation/widgets/sign_in_sheet.dart:211`
- `AuthState.error` accessor: `failure` field of type `AuthFailure` — see `auth_state.dart` (freezed sealed class)
- `AuthFailure` (no subclasses needed): `pulse_coach/lib/core/error/failures.dart`
- ARCH25 boundary file: `pulse_coach/lib/core/cloud/supabase_client.dart` (exports OAuthProvider, User, PostgrestException — do NOT expand)
- Existing signUp tests (pattern to follow): `pulse_coach/test/data/auth/auth_repository_impl_test.dart:144`
- `signInErrorGeneric` ARB key (existing, do not duplicate): `pulse_coach/lib/l10n/app/app_it.arb:228`
- Supabase handle_new_user trigger pattern: standard Supabase docs; SECURITY DEFINER required for cross-schema trigger functions

### Review Findings (code review 2026-06-25)

- [x] [Review][Decision] AC3 live verification — **CLOSED 2026-06-25 during review (PASS).** Executed an isolated, self-cleaning fresh-signup test against the live EU project via MCP `execute_sql` (user-approved mutation): `INSERT` a throwaway `auth.users` row → trigger fired → asserted exactly **1** `public.profiles` row with `visibility_tier='private'`, `install_cohort='post_v2'`, `display_handle IS NULL`; `DELETE` of the test user cascaded the profile away. Post-test DB state confirmed clean: users=2, profiles=2, 0 leftover test users, 0 orphans. AC3's defining assertion is now satisfied with live evidence. [auditor]
- [x] [Review][Defer] Back-fill INSERT lacks `ON CONFLICT (id) DO NOTHING` [supabase/migrations/0008_handle_new_user_trigger.sql:39] — deferred: marginal in-migration TOCTOU race vs the trigger; already applied to live prod with 0 rows back-filled. Add the clause for parity if 0008 is ever re-run on a fresh env. [blind+edge]
- [x] [Review][Defer] Invalid-email error taxonomy covers only `email_address_invalid` [pulse_coach/lib/features/auth/data/repositories/auth_repository_impl.dart:120] — deferred: out of AC4 scope. Sibling GoTrue codes (`email_exists`, `weak_password`, `signup_disabled`, rate-limit) fall through to `signInErrorGeneric`. Future enhancement. [edge]
- [x] [Review][Defer] Sentinel `'email_address_invalid'` duplicated as magic string across repo + UI [pulse_coach/lib/features/auth/presentation/widgets/sign_in_sheet.dart:214] — deferred: story intentionally used the literal (`.contains()` chosen for version-robustness per Dev Notes). Optional: extract a shared `const` to avoid silent UI degradation if the sentinel ever changes. [blind]

**Dismissed as noise (6):** missing PK on `profiles.id` (false — `id` IS PK, 0001:7); legacy cohort mislabel (back-fill matched 0 rows live, column DEFAULT is already `post_v2`, `_syncInstallCohort` self-heals genuine `pre_v2`); trigger lacks `EXCEPTION WHEN OTHERS` (no current error path — all NOT NULL cols have defaults; fail-closed is intentional, swallowing would create profile-less users and defeat the story); original error context discarded for invalid-email (intentional sentinel; generic branch preserves `e.toString()`); extra sanity equality test beyond Task 4.2 (harmless additive); `display_handle UNIQUE` collision (trigger inserts NULL, not subject to UNIQUE).

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

- **Task 1 (AC1, AC2, AC3):** Created `supabase/migrations/0008_handle_new_user_trigger.sql` with SECURITY DEFINER `handle_new_user` function, AFTER INSERT trigger on `auth.users`, and back-fill INSERT. Applied to live EU project via `execute_sql`; trigger confirmed active; back-fill: 0 users without profile.
- **Task 2 (AC4):** Modified `auth_repository_impl.dart` `signUp()` to detect `email_address_invalid` in exception message and return sentinel `Left(AuthFailure('email_address_invalid'))`. Modified `sign_in_sheet.dart` error block to conditionally show `signInErrorInvalidEmail` vs `signInErrorGeneric`.
- **Task 3 (AC4):** Added `signInErrorInvalidEmail` ARB key to `app_en.arb` and `app_it.arb`. Ran `flutter pub get` to regenerate localizations.
- **Task 4 (AC5):** Added 2 repo unit tests (19.0-REPO-001/002) and 2 widget tests (19.0-WIDGET-001/002) using `MockBloc` from bloc_test (no build_runner needed). All 1094 tests green. flutter analyze 0 issues.
- **ATDD compliance:** Failing tests written before every production code change.
- **AC3 on-device note:** Trigger verified live via MCP SQL: `on_auth_user_created` exists on `auth.users` (AFTER INSERT); back-fill query confirmed 0 unmatched users. Full on-device new-user signup verification (create user → assert profiles row) deferred to smoke test during Story 19.0 review.
- **AC3 closed during review (2026-06-25):** The deferred end-to-end assertion was executed live via MCP `execute_sql` (user-approved): an isolated fresh `auth.users` INSERT fired the trigger and produced exactly one `profiles` row with `visibility_tier='private'`, `install_cohort='post_v2'`, `display_handle=NULL`; the test user was deleted (cascade) and the DB returned to users=2/profiles=2, 0 orphans. AC3 PASS with live evidence.

### File List

- `supabase/migrations/0008_handle_new_user_trigger.sql` — NEW
- `pulse_coach/lib/features/auth/data/repositories/auth_repository_impl.dart` — MODIFIED (signUp: sentinel check)
- `pulse_coach/lib/features/auth/presentation/widgets/sign_in_sheet.dart` — MODIFIED (error block: signInErrorInvalidEmail)
- `pulse_coach/lib/l10n/app/app_en.arb` — MODIFIED (+1 key: signInErrorInvalidEmail)
- `pulse_coach/lib/l10n/app/app_it.arb` — MODIFIED (+1 key: signInErrorInvalidEmail)
- `pulse_coach/test/data/auth/auth_repository_impl_test.dart` — MODIFIED (+2 tests: 19.0-REPO-001/002)
- `pulse_coach/test/bloc/auth/sign_in_sheet_error_test.dart` — NEW (3 tests: sanity + 19.0-WIDGET-001/002)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED (19-0 → in-progress, then → review)

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2026-06-25 | 1.0.0 | Story created. | claude-sonnet-4-6 |
| 2026-06-25 | 1.1.0 | Implemented: trigger migration, signUp sentinel, ARB keys, sign_in_sheet conditional error, 4 tests (ATDD). | claude-sonnet-4-6 |
