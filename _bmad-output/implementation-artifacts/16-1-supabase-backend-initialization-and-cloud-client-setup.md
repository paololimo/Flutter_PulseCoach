# Story 16.1: Supabase Backend Initialization & Cloud Client Setup

Status: ready-for-dev

## Story

As a developer,
I want the Supabase EU project initialized with migrations, RLS scaffolding, and the Flutter client registered,
So that all subsequent v2 stories (16.2–16.4, 17.x, 18.x, 19.x, 20.x, 21.x) can access the cloud backend through a single, properly configured client.

## Acceptance Criteria

**AC1 — Supabase CLI init at repo root (ARCH17, NFR36):**
Given the Supabase CLI is installed and configured
When `supabase init` is run at the repo root (`Flutter_PulseCoach/`, NOT inside `pulse_coach/`)
Then a `supabase/` directory is created with `config.toml` targeting EU region `eu-central-1` (Frankfurt)

**AC2 — Initial profiles migration applied (ARCH17, ARCH25):**
Given the Supabase project is initialized
When the initial migration `supabase/migrations/0001_profiles_auth.sql` is applied
Then the `profiles` table exists with columns: `id` (uuid PK, references `auth.users`), `display_handle` (nullable text, unique), `install_cohort` (enum: pre_v2, post_v2), `visibility_tier` (enum: private, friends_only), `created_at` (timestamptz)

**AC3 — Flutter client singleton registered (ARCH25):**
Given `supabase_flutter` is added to `pubspec.yaml`
When the app initializes in `main.dart`
Then `Supabase.initialize(url: ..., anonKey: ...)` is called once, before `runApp()`, using values read from `--dart-define` constants; the initialized client is registered as a `@singleton` in `lib/core/cloud/supabase_client.dart`

**AC4 — Free core unaffected (FR56, NFR34):**
Given the client is initialized
When the app launches without any signed-in session
Then `Supabase.instance.client.auth.currentSession` is null and the app loads the v1 free core normally — no crash, no sign-in prompt, no AuthBloc mounted yet

**AC5 — All v2 client packages resolve (ARCH18):**
Given `supabase_flutter`, `flutter_secure_storage`, `sign_in_with_apple`, `google_sign_in` are added to `pubspec.yaml`
When `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` are run
Then all packages resolve without conflicts and injectable code generation completes without errors

**AC6 — No regression:**
Given the implementation is complete
When `flutter analyze` and `flutter test` run from `pulse_coach/`
Then `flutter analyze` reports 0 issues and all 859 existing tests pass

## Tasks / Subtasks

- [ ] Task 1: Supabase CLI initialization at repo root (AC1)
  - [ ] 1.1 From `Flutter_PulseCoach/` (repo root, NOT `pulse_coach/`), run `supabase init`
  - [ ] 1.2 In `supabase/config.toml`, set `project_id` to the EU Supabase project ID; confirm `db.major_version` and region settings target `eu-central-1` (Frankfurt)
  - [ ] 1.3 Create `supabase/migrations/` and `supabase/functions/` directories as specified in ARCH17

- [ ] Task 2: Create initial profiles migration (AC2)
  - [ ] 2.1 Create `supabase/migrations/0001_profiles_auth.sql`
  - [ ] 2.2 Define `CREATE TYPE install_cohort_enum AS ENUM ('pre_v2', 'post_v2');`
  - [ ] 2.3 Define `CREATE TYPE visibility_tier_enum AS ENUM ('private', 'friends_only');`
  - [ ] 2.4 Define `CREATE TABLE profiles (id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE, display_handle text UNIQUE, install_cohort install_cohort_enum NOT NULL DEFAULT 'post_v2', visibility_tier visibility_tier_enum NOT NULL DEFAULT 'private', created_at timestamptz NOT NULL DEFAULT now());`
  - [ ] 2.5 Add RLS: `ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;` + initial policy allowing each user to read/write only their own row (`auth.uid() = id`)

- [ ] Task 3: Add v2 client packages to `pulse_coach/pubspec.yaml` (AC5)
  - [ ] 3.1 Add `supabase_flutter: ^2.9.0` (or latest stable — check pub.dev at implementation time)
  - [ ] 3.2 Add `flutter_secure_storage: ^9.2.0` (or latest stable)
  - [ ] 3.3 Add `sign_in_with_apple: ^6.1.0` (or latest stable)
  - [ ] 3.4 Add `google_sign_in: ^6.2.0` (or latest stable)
  - [ ] 3.5 Run `flutter pub get` and confirm no version conflicts with existing packages

- [ ] Task 4: Create `lib/core/cloud/supabase_client.dart` singleton (AC3, ARCH25)
  - [ ] 4.1 Create directory `pulse_coach/lib/core/cloud/`
  - [ ] 4.2 Create `pulse_coach/lib/core/cloud/supabase_client.dart` — annotate with `@singleton`; expose `SupabaseClient get client => Supabase.instance.client;`
  - [ ] 4.3 Add the `@injectable` annotation import — this file is the ONLY place in the project that imports `supabase_flutter` directly (enforce via class comment; other layers depend on this singleton, never on the raw client)

- [ ] Task 5: Initialize Supabase in `main.dart` (AC3, AC4)
  - [ ] 5.1 In `pulse_coach/lib/main.dart`, before `configureDependencies()` and `runApp()`, call `await Supabase.initialize(url: const String.fromEnvironment('SUPABASE_URL'), anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'));`
  - [ ] 5.2 Ensure the call is `await`-ed inside `main()` (which must be `async`)
  - [ ] 5.3 Do NOT hardcode URL or anonKey — values come from `--dart-define` at build/run time
  - [ ] 5.4 Verify: if `SUPABASE_URL` is empty string (default when `--dart-define` is not passed), `Supabase.initialize` still completes without crashing the startup flow. If it throws, wrap with a try/catch that logs the error and continues — the free core must not be blocked.

- [ ] Task 6: Regenerate injectable config and verify (AC5, AC6)
  - [ ] 6.1 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`
  - [ ] 6.2 Confirm `injection.config.dart` is updated and includes the new `SupabaseClientProvider` registration
  - [ ] 6.3 Run `flutter analyze` — must report **0 issues**
  - [ ] 6.4 Run `flutter test` — all **859 tests** must pass; no new tests are required for this infrastructure-only story

## Dev Notes

### Repo Root vs Flutter Root — Critical Distinction

`supabase init` runs at `Flutter_PulseCoach/` (the git workspace root), NOT inside `pulse_coach/`. The resulting `supabase/` directory sits alongside `pulse_coach/` and `_bmad-output/`:

```
Flutter_PulseCoach/             ← repo root, git root, where supabase init runs
├── pulse_coach/                ← Flutter app (all flutter/dart commands run here)
├── supabase/                   ← NEW: created by supabase init
│   ├── config.toml
│   ├── migrations/
│   │   └── 0001_profiles_auth.sql
│   └── functions/              ← placeholder for Edge Functions (16.3, 16.4)
└── _bmad-output/
```

All `flutter` commands continue to run from `pulse_coach/` as before.

### Architecture Boundary — Critical: No Direct supabase_flutter Imports Outside `core/cloud/`

`lib/core/cloud/` is the ONLY allowed import location for `supabase_flutter` in the entire Flutter codebase (ARCH25, architecture.md §"v2 Architectural Boundaries"). This mirrors how `lib/core/database/` is the only place that imports `drift` directly.

Features in `lib/features/auth/`, `lib/features/social/`, etc. depend on the `SupabaseClientProvider` singleton injected via `get_it`, never on `Supabase.instance` directly.

If you catch yourself writing `import 'package:supabase_flutter/supabase_flutter.dart'` outside `lib/core/cloud/`, stop — that is an architecture violation.

### Secrets: Never In Source Code

URL and anon key are injected via `--dart-define` at build/run time. They must NEVER appear in:
- `pubspec.yaml`
- `main.dart` as string literals
- Any tracked file (security rule)

Local developer pattern:
```bash
# From pulse_coach/ directory:
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

The Supabase anon key (also called "publishable key") is safe to include in client builds (it's controlled by RLS); the service-role key must NEVER appear in client code.

### `supabase_client.dart` Implementation Pattern

```dart
// lib/core/cloud/supabase_client.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@singleton
class SupabaseClientProvider {
  SupabaseClient get client => Supabase.instance.client;
}
```

Other v2 datasources will depend on `SupabaseClientProvider` via injection:
```dart
@injectable
class AuthRemoteDataSource {
  final SupabaseClientProvider _supabase;
  AuthRemoteDataSource(this._supabase);
  // use _supabase.client.auth
}
```

### `main.dart` Initialization Order

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase init before DI setup (SupabaseClientProvider singleton needs the instance ready)
  try {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  } catch (e) {
    // Log but do not crash — free core must work even if Supabase init fails
    // (e.g., empty --dart-define in dev/test environments)
    logger.warning('Supabase init failed: $e — running in offline-only mode');
  }

  await configureDependencies();
  runApp(const PulseCoachApp());
}
```

### Initial Migration SQL — Profiles Table

```sql
-- supabase/migrations/0001_profiles_auth.sql

-- Custom enums
CREATE TYPE install_cohort_enum AS ENUM ('pre_v2', 'post_v2');
CREATE TYPE visibility_tier_enum AS ENUM ('private', 'friends_only');

-- Profiles table (mirrors auth.users; one row per registered user)
CREATE TABLE profiles (
  id               uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_handle   text        UNIQUE,
  install_cohort   install_cohort_enum  NOT NULL DEFAULT 'post_v2',
  visibility_tier  visibility_tier_enum NOT NULL DEFAULT 'private',
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- RLS: each user reads/writes only their own row
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
```

Note: Migration naming in epics.md says `0001_profiles_auth.sql`. The architecture.md directory listing says `0001_profiles_friendships.sql` — the epics.md story AC is the authoritative source; use `0001_profiles_auth.sql`.

### No AuthBloc in This Story

Story 16.1 registers the Supabase client singleton and wires the initialization — nothing more. `AuthBloc`, `AuthEvent`, `AuthState`, `SignInSheet`, and the full auth feature module (`lib/features/auth/`) are Story 16.2's scope. Do not pre-create any of those files here.

### `flutter_secure_storage` Platform Setup

`flutter_secure_storage` requires platform-specific configuration:
- **Android**: minimum SDK 18 (already met). In `android/app/build.gradle`, confirm `minSdkVersion >= 18`. No `AndroidManifest.xml` changes needed.
- **iOS**: uses Keychain by default — no additional Info.plist entries needed for secure storage alone. (Apple Sign-In entitlement is added in Story 16.2.)

### `sign_in_with_apple` / `google_sign_in` — No UI in This Story

Adding these packages in Story 16.1 ensures they resolve and code generation works. The actual configuration (Apple entitlements in Xcode, OAuth client IDs, redirect URLs) and all UI flows belong to Story 16.2. Do not configure platform-specific files beyond what's needed to make `flutter pub get` pass.

### Free Core Invariant — Non-Negotiable

The v1 free core must work identically before and after this story, regardless of whether `--dart-define` credentials are provided. This means:
- The app MUST start with `SUPABASE_URL=""` (empty) without crashing
- No screen in the v1 flow (Today, Sessions, Progress, Onboarding, Settings, Profile, Privacy) may change behavior
- `Supabase.instance.client.auth.currentSession` being null is the expected baseline — the app was designed for this (FR56, NFR34)

### Existing Test Baseline

Previous story (15.1) left the test suite at **859 tests** (858 + NAV-005 added during review). This story is infrastructure-only with no new behavior — no new tests are required. The baseline of 859 must not regress.

### Project Structure Notes

New files in this story:
| File | Type | Notes |
|------|------|-------|
| `supabase/config.toml` | NEW | From `supabase init`; commit to git |
| `supabase/migrations/0001_profiles_auth.sql` | NEW | Initial schema + RLS |
| `supabase/functions/.gitkeep` | NEW | Placeholder; Edge Functions added in 16.3-16.4 |
| `pulse_coach/lib/core/cloud/supabase_client.dart` | NEW | `@singleton` wrapper |
| `pulse_coach/pubspec.yaml` | UPDATE | 4 new packages |
| `pulse_coach/pubspec.lock` | UPDATE | auto-updated by `flutter pub get` |
| `pulse_coach/lib/main.dart` | UPDATE | `Supabase.initialize()` call |
| `pulse_coach/lib/core/di/injection.config.dart` | UPDATE | auto-generated by build_runner |

Do NOT modify:
- Any existing feature files
- Any existing tests
- `app_router.dart` (no new routes in this story)
- Any ARB localization keys

### References

- Epic 16 goal and Story 16.1 ACs: [epics.md lines 2122–2153]
- ARCH17: Supabase CLI + EU region + migration-first approach [architecture.md §"v2 Additional Requirements"]
- ARCH18: Auth packages (`supabase_flutter`, `sign_in_with_apple`, `google_sign_in`, `flutter_secure_storage`) [architecture.md]
- ARCH25: `lib/core/cloud/supabase_client.dart` as `@singleton`; `lib/features/auth/` module structure [architecture.md §"Project Structure & Boundaries — v2 Additions"]
- ARCH26: `AuthFailure` type (new Failure subtype — belongs to Story 16.2, not here) [architecture.md]
- FR56: App fully usable without an account [epics.md line 88]
- NFR27: Secure token storage via `flutter_secure_storage` [epics.md line 157]
- NFR34: Social/cloud features degrade gracefully; v1 core always offline-first [epics.md line 168]
- NFR36: EU data residency `eu-central-1` [epics.md line 163]
- Architecture v2 import rules: `lib/core/cloud/` is the ONLY importer of `supabase_flutter` [architecture.md §"v2 Architectural Boundaries"]
- Security rule: secrets via `--dart-define` only, never in source [rules/security.md]
- Previous story (15.1): 859 test baseline confirmed, `flutter analyze` at 0 [15-1-back-navigation-from-drawer-secondary-screens.md]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
