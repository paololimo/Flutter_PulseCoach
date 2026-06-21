---
baseline_commit: ee33a5131686c3f81be1aa56e1383aca5942af94
---

# Story 16.4: In-App Account Deletion and Data Export

Status: done

## Story

As a user,
I want to delete my account and all associated server-side data from within the app,
so that I can exercise my GDPR right to erasure without needing to navigate to an external web flow.

## Acceptance Criteria

**AC1 — Delete Account: destructive-action confirmation dialog (FR77):**
Given the user is signed in and navigates to Settings → Account
When they tap "Elimina account"
Then a destructive-action `AlertDialog` appears with a two-step confirmation: Cancel is the dominant/primary button (`FilledButton`), and "Elimina" confirm is clearly secondary (`TextButton` with red/error color); the dialog title states "Elimina account" and the body explains the action is permanent (EXPERIENCE.md destructive-action pattern)

**AC2 — Successful deletion cascades server-side data (FR77, NFR30):**
Given the user confirms deletion
When the `DeleteAccountUseCase` is called
Then the Supabase Edge Function `delete_account_cascade` is invoked via `client.functions.invoke('delete_account_cascade')`; all server-side data (Supabase Storage backup object, auth user record; future: profiles, friendships, feed entries, leaderboard entries once those tables exist) is deleted; visible removal is immediate; the local Supabase session is cleared via `client.auth.signOut()` after the Edge Function call succeeds

**AC3 — Post-deletion navigation (FR77):**
Given the deletion call succeeds and the local session is cleared
When `AuthBloc` emits `unauthenticated`
Then a `BlocListener` in `AccountPage` catches the `unauthenticated` transition (from a `loading` → `unauthenticated` sequence triggered by `AccountDeletionRequested`) and calls `context.go(AppRouter.today)`; the user lands on the Today screen using the v1 free, offline, local-only experience; local Drift data is NOT deleted (local data belongs to the device, not the account)

**AC4 — Deletion failure shows inline error, no partial state (FR77):**
Given the deletion call fails (connectivity issue or Edge Function error)
When `AuthRemoteDataSource.deleteAccount()` throws
Then `AuthRepositoryImpl` catches and returns `Left(AuthFailure(...))`; `AuthBloc` emits `error(failure: AuthFailure(...))`; a `BlocListener` in `AccountPage` displays a `SnackBar` with the error message; the account is NOT deleted; the user can retry; no auth session is cleared

**AC5 — Data Export: share portable JSON via OS share sheet (NFR30):**
Given the user is signed in and taps "Esporta i miei dati" in Settings → Account
When `ExportDataUseCase` is called
Then the Supabase Edge Function `export_user_data` is invoked; the returned JSON containing all server-side personal data is shared via the OS share sheet using `share_plus`'s `Share.share(...)` call; `ExportDataCubit` emits `success({required String json})` and the `BlocListener` in `AccountPage` triggers `Share.share(json, subject: 'I miei dati PulseCoach')`

**AC6 — Export failure shows inline error:**
Given the export call fails
When `ExportDataCubit` processes the error
Then it emits `error({required AuthFailure failure})`; a `SnackBar` displays the error message; no partial data is shared

**AC7 — No regression:**
Given the implementation is complete
When `flutter analyze` and `flutter test` run from `pulse_coach/`
Then `flutter analyze` reports 0 issues and all 885+ existing tests pass; new tests for delete and export are green

## Tasks / Subtasks

- [x] Task 1: Scaffold Supabase Edge Functions (AC2, AC5)
  - [x] 1.1 Create `supabase/functions/delete_account_cascade/index.ts` — JWT-authenticated Deno function; uses `SUPABASE_SERVICE_ROLE_KEY` to call `supabase.auth.admin.deleteUser(userId)`; also removes `backups/{userId}/backup_v1.enc` from Storage (see Dev Notes for full implementation)
  - [x] 1.2 Create `supabase/functions/export_user_data/index.ts` — JWT-authenticated Deno function; exports auth user info as JSON; scaffolded for future social-table queries (Epic 18+) (see Dev Notes)

- [x] Task 2: Extend `AuthRepository` interface and implementation (AC2, AC5)
  - [x] 2.1 In `pulse_coach/lib/features/auth/domain/repositories/auth_repository.dart`, add:
    ```dart
    Future<Either<AuthFailure, Unit>> deleteAccount();
    Future<Either<AuthFailure, String>> exportData(); // returns JSON string
    ```
  - [x] 2.2 In `pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart`, add `deleteAccount()` and `exportData()` methods (see Dev Notes for pattern; ARCH25: use `_supabase.client.functions.invoke(...)`)
  - [x] 2.3 In `pulse_coach/lib/features/auth/data/repositories/auth_repository_impl.dart`, implement both methods with `try/catch → Left(AuthFailure(e.toString()))`

- [x] Task 3: Create `DeleteAccountUseCase` and `ExportDataUseCase` (AC2, AC5)
  - [x] 3.1 Create `pulse_coach/lib/features/auth/domain/usecases/delete_account_use_case.dart` — `@injectable`; calls `AuthRepository.deleteAccount()`
  - [x] 3.2 Create `pulse_coach/lib/features/auth/domain/usecases/export_data_use_case.dart` — `@injectable`; calls `AuthRepository.exportData()`

- [x] Task 4: Extend `AuthBloc` with `AccountDeletionRequested` event (AC2, AC3, AC4)
  - [x] 4.1 In `pulse_coach/lib/features/auth/presentation/bloc/auth_event.dart`, add:
    ```dart
    const factory AuthEvent.accountDeletionRequested() = AccountDeletionRequested;
    ```
  - [x] 4.2 In `pulse_coach/lib/features/auth/presentation/bloc/auth_bloc.dart`, inject `DeleteAccountUseCase`; add `on<AccountDeletionRequested>(_onAccountDeletion)` handler:
    - emits `loading()`
    - calls `_deleteAccount.call()`
    - on `Right(unit)`: emits `unauthenticated()`
    - on `Left(failure)`: emits `error(failure: failure)`
  - [x] 4.3 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `auth_bloc.freezed.dart`

- [x] Task 5: Create `ExportDataCubit` (AC5, AC6)
  - [x] 5.1 Create `pulse_coach/lib/features/auth/presentation/bloc/export_data_cubit.dart` — `@injectable` (transient); inject `ExportDataUseCase`; states: `initial()`, `loading()`, `success({required String json})`, `error({required AuthFailure failure})`
  - [x] 5.2 Implement `exportData()` method: emit `loading()` → call `_exportDataUseCase.call()` → fold to `success` or `error`
  - [x] 5.3 Use `@freezed` sealed class for `ExportDataState` — follow existing state pattern

- [x] Task 6: Update `AccountPage` with Delete and Export UI (AC1–AC6)
  - [x] 6.1 In `pulse_coach/lib/features/auth/presentation/pages/account_page.dart`, add inside the `authenticated` branch (below Backup tile, above Sign Out):
    - "Esporta i miei dati" `ListTile` with `Icons.download` — dispatches `ExportDataCubit.exportData()`
    - "Elimina account" `ListTile` with `Icons.delete_forever` and `Theme.of(context).colorScheme.error` color — triggers the confirmation dialog
  - [x] 6.2 Add `_showDeleteConfirmationDialog(BuildContext context)` helper:
    - Shows `AlertDialog` with `title: Text(l10n.deleteAccountDialogTitle)`
    - Two buttons: `FilledButton` "Annulla" (closes dialog), `TextButton(style: TextButton.styleFrom(foregroundColor: colorScheme.error))` "Elimina" (dispatches `AuthEvent.accountDeletionRequested()` then pops dialog)
  - [x] 6.3 Wrap body in `MultiBlocListener` (two separate `BlocListener<AuthBloc>` for `unauthenticated` and `error`):
    - unauthenticated listener → `context.go(AppRouter.today)`
    - error listener → `ScaffoldMessenger.of(context).showSnackBar(...)`
  - [x] 6.4 Add `BlocListener<ExportDataCubit, ExportDataState>` via `MultiBlocListener`:
    - On `success(json)`: call `Share.share(json, subject: l10n.exportDataShareSubject)`
    - On `error(failure)`: show `SnackBar` with failure message
  - [x] 6.5 All interactive elements retain `Semantics` labels

- [x] Task 7: Update routing to provide `ExportDataCubit` (AC5)
  - [x] 7.1 In `pulse_coach/lib/core/routing/app_router.dart`, change the `account` route builder from `BlocProvider.value(...)` to `MultiBlocProvider(providers: [...])` to add `BlocProvider(create: (_) => getIt<ExportDataCubit>())` alongside the existing `AuthBloc.value`

- [x] Task 8: Add ARB localization keys (AC1–AC6)
  - [x] 8.1 Add to `pulse_coach/lib/l10n/app/app_it.arb` and `pulse_coach/lib/l10n/app/app_en.arb` (see Dev Notes for full key list)
  - [x] 8.2 Run `flutter pub get` to trigger `gen_l10n` regeneration

- [x] Task 9: Write tests (AC2–AC6, AC7)
  - [x] 9.1 Create `pulse_coach/test/bloc/auth/delete_account_bloc_test.dart` using `bloc_test` + `@GenerateMocks([DeleteAccountUseCase, ...existing mocks...])`:
    - Test `AccountDeletionRequested` (success) → `[loading, unauthenticated]`
    - Test `AccountDeletionRequested` (failure) → `[loading, error(AuthFailure(...))]`
  - [x] 9.2 Create `pulse_coach/test/bloc/auth/export_data_cubit_test.dart` using `bloc_test` + `@GenerateMocks([ExportDataUseCase])`:
    - Test `exportData()` (success) → `[loading, success(json: ...)]`
    - Test `exportData()` (failure) → `[loading, error(AuthFailure(...))]`

- [x] Task 10: Code generation and verification (AC7)
  - [x] 10.1 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`
  - [x] 10.2 Run `flutter analyze` — must report **0 issues**
  - [x] 10.3 Run `flutter test` — all **885+ tests** must pass; new tests green

## Dev Notes

### Critical: ARCH25 — Supabase Import Boundary

`AuthRemoteDataSource` MUST NOT import `supabase_flutter` directly. Access Supabase via `SupabaseClientProvider._supabase.client`. The `client.functions.invoke(...)` method is available through `SupabaseClient`, no additional re-export needed. Pattern:

```dart
// ✅ CORRECT — in auth_remote_data_source.dart
Future<void> deleteAccount() async {
  final response = await _supabase.client.functions.invoke('delete_account_cascade');
  if (response.status != 200) {
    throw Exception('delete_account_cascade failed: ${response.data}');
  }
  await _supabase.client.auth.signOut(); // clear local session after server deletion
}

Future<String> exportData() async {
  final response = await _supabase.client.functions.invoke('export_user_data');
  if (response.status != 200) {
    throw Exception('export_user_data failed: ${response.data}');
  }
  import 'dart:convert';
  return jsonEncode(response.data);
}
```

`FunctionsResponse.status` is an `int` HTTP status code. `FunctionsResponse.data` is `dynamic` (decoded JSON). No special type imports needed from supabase_flutter — `SupabaseClient` already exposes `.functions`.

### Edge Function: `delete_account_cascade/index.ts`

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("Unauthorized", { status: 401 });

  const jwt = authHeader.replace("Bearer ", "");
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Verify JWT and get user identity
  const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(jwt);
  if (userError || !user) return new Response("Unauthorized", { status: 401 });

  const userId = user.id;

  // Remove backup from Storage (ignore not-found errors)
  await supabaseAdmin.storage.from("backups").remove([`${userId}/backup_v1.enc`]);

  // FK ON DELETE CASCADE in Supabase DB handles profile/social rows when they exist (Epic 18+).
  // Delete the auth user — this is the cascade root.
  const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId);
  if (deleteError) {
    return new Response(JSON.stringify({ error: deleteError.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
```

### Edge Function: `export_user_data/index.ts`

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("Unauthorized", { status: 401 });

  const jwt = authHeader.replace("Bearer ", "");
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(jwt);
  if (userError || !user) return new Response("Unauthorized", { status: 401 });

  // Export all server-side personal data for this user.
  // v2.1 scope: auth user metadata only. Add queries as social tables land (Epic 18+).
  const exportData = {
    exportedAt: new Date().toISOString(),
    schemaVersion: 1,
    userId: user.id,
    email: user.email,
    emailConfirmedAt: user.email_confirmed_at,
    createdAt: user.created_at,
    // Future (Epic 18+): profiles, friendships, activity_feed, leaderboard_entries
  };

  return new Response(JSON.stringify(exportData, null, 2), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
```

### `AuthBloc` — Extending Without Breaking Existing Handlers

Inject `DeleteAccountUseCase` as a new constructor parameter. Since `AuthBloc` is `@injectable`, `build_runner` will wire it automatically. Add the handler registration in the constructor body. Do NOT modify existing handlers (`_onSignOut`, etc.).

```dart
// add to constructor params:
final DeleteAccountUseCase _deleteAccount;

// add in constructor body:
on<AccountDeletionRequested>(_onAccountDeletion);

// new handler:
Future<void> _onAccountDeletion(
  AccountDeletionRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthState.loading());
  final result = await _deleteAccount.call();
  result.fold(
    (failure) => emit(AuthState.error(failure: failure)),
    (_) => emit(const AuthState.unauthenticated()),
  );
}
```

### `AccountPage` — Navigation After Deletion

`BlocConsumer.listener` triggers navigation. The challenge: both `AccountDeletionRequested` and `SignOutRequested` transition through `loading → unauthenticated`. Since navigating to `today` on sign-out is also safe (user ends up on Today screen without account, which is correct for the v1 free experience), the unified listener approach is acceptable:

```dart
// In AccountPage BlocConsumer:
listenWhen: (previous, current) => current is AuthUnauthenticated,
listener: (context, state) {
  if (state is AuthUnauthenticated) {
    context.go(AppRouter.today);
  } else if (state is AuthError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.failure.message)),
    );
  }
},
```

**Note:** This changes the current sign-out behavior slightly — sign-out will now navigate to `today` explicitly rather than staying on AccountPage. This is a UX improvement (user is taken to the main app), not a regression.

### `ExportDataCubit` State Pattern

Follow the standard sealed-class pattern used by `BackupBloc`:

```dart
// export_data_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/usecases/export_data_use_case.dart';

part 'export_data_cubit.freezed.dart';

@freezed
sealed class ExportDataState with _$ExportDataState {
  const factory ExportDataState.initial() = ExportDataInitial;
  const factory ExportDataState.loading() = ExportDataLoading;
  const factory ExportDataState.success({required String json}) = ExportDataSuccess;
  const factory ExportDataState.error({required AuthFailure failure}) = ExportDataError;
}

@injectable
class ExportDataCubit extends Cubit<ExportDataState> {
  final ExportDataUseCase _exportData;
  ExportDataCubit(this._exportData) : super(const ExportDataState.initial());

  Future<void> exportData() async {
    emit(const ExportDataState.loading());
    final result = await _exportData.call();
    result.fold(
      (failure) => emit(ExportDataState.error(failure: failure)),
      (json) => emit(ExportDataState.success(json: json)),
    );
  }
}
```

### Destructive Dialog — UX Pattern

The EXPERIENCE.md destructive-action pattern (referenced in AC1): Cancel is **dominant** (filled/primary style), Delete is **secondary** (text button with error color). This is the opposite of most defaults — intentional friction to prevent accidental deletion.

```dart
void _showDeleteConfirmationDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.deleteAccountDialogTitle),
      content: Text(l10n.deleteAccountDialogBody),
      actions: [
        // Cancel = dominant (primary) — listed first for RTL/semantic order
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.deleteAccountCancelButton),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            Navigator.of(dialogContext).pop();
            context.read<AuthBloc>().add(const AuthEvent.accountDeletionRequested());
          },
          child: Text(l10n.deleteAccountConfirmButton),
        ),
      ],
    ),
  );
}
```

### ARB Keys to Add

Add to both `app_it.arb` and `app_en.arb`:

**Italian (`app_it.arb`)**:
```json
"deleteAccountTileLabel": "Elimina account",
"deleteAccountDialogTitle": "Elimina account",
"deleteAccountDialogBody": "Questa azione è permanente. Tutti i tuoi dati cloud verranno eliminati. I dati locali rimarranno sul dispositivo.",
"deleteAccountConfirmButton": "Elimina",
"deleteAccountCancelButton": "Annulla",
"deleteAccountErrorGeneric": "Errore durante l'eliminazione dell'account. Riprova.",
"exportDataTileLabel": "Esporta i miei dati",
"exportDataShareSubject": "I miei dati PulseCoach",
"exportDataErrorGeneric": "Errore durante l'esportazione dei dati. Riprova."
```

**English (`app_en.arb`)**:
```json
"deleteAccountTileLabel": "Delete Account",
"deleteAccountDialogTitle": "Delete Account",
"deleteAccountDialogBody": "This action is permanent. All your cloud data will be deleted. Local data will remain on the device.",
"deleteAccountConfirmButton": "Delete",
"deleteAccountCancelButton": "Cancel",
"deleteAccountErrorGeneric": "Error deleting account. Please try again.",
"exportDataTileLabel": "Export My Data",
"exportDataShareSubject": "My PulseCoach Data",
"exportDataErrorGeneric": "Error exporting data. Please try again."
```

### DI Registration Order for New Components

`build_runner` handles this automatically from `@injectable` annotations. Ensure these are present:
- `DeleteAccountUseCase` — `@injectable`
- `ExportDataUseCase` — `@injectable`
- `ExportDataCubit` — `@injectable` (transient, NOT singleton)
- `AuthBloc` — already `@injectable`; build_runner will pick up the new `DeleteAccountUseCase` dependency automatically

### `share_plus` Usage

`share_plus: ^10.0.0` is already in `pubspec.yaml`. API:

```dart
import 'package:share_plus/share_plus.dart';

// Called from BlocListener when ExportDataState is success:
await Share.share(
  state.json,
  subject: l10n.exportDataShareSubject,
);
```

No additional pubspec changes needed.

### Local Drift Data NOT Deleted

The `deleteAccount` flow MUST NOT touch any Drift table. No `db.delete(...)` calls in `DeleteAccountUseCase`, `AuthRepositoryImpl`, or `AuthRemoteDataSource`. This is a hard requirement: local v1 data (sessions, plans, profile, RPE) belongs to the device, not the account.

### What NOT to Implement in This Story

- **Social data erasure cascade** (profiles table, friendships, activity_feed, leaderboard_entries) — these tables do not exist yet; will be added in Epic 18+. The `delete_account_cascade` Edge Function must be written with a comment noting the future extension point.
- **Account deletion offline queuing** — not in scope; if offline, show error and let the user retry. Deletion is too destructive to queue.
- **Incremental export or streaming** — full one-shot JSON only.
- **BackupBloc changes** — no changes to the backup feature.
- **Passphrase/key cleanup on deletion** — deleting Supabase account voids the backup anyway; local `flutter_secure_storage` cleanup is nice-to-have but out of scope (user will reinstall or can ignore stale keys).

### Previous Story Baseline (Story 16.3)

- Auth feature layer complete: `AuthBloc`, `AuthRepository`, `AuthRepositoryImpl`, `AuthRemoteDataSource`, `AccountPage`, `SignInSheet`
- `BackupBloc`, `BackupRepository`, `BackupPage` all complete and wired
- `AccountPage` currently shows: email row + Backup tile + Sign Out tile (authenticated only)
- `app_router.dart` account route uses `BlocProvider.value` — must upgrade to `MultiBlocProvider` in Task 7
- `supabase/functions/` directory exists (currently has only `.gitkeep`)
- `supabase/migrations/` directory exists with `0001_auth_tables.sql` and `0002_storage_backup_bucket.sql`
- ARCH25 boundary enforced: only `supabase_client.dart` and `main.dart` import `supabase_flutter` directly
- Test baseline: **885 tests passing** (882 from 16.3 + 3 from code review patches)
- `share_plus: ^10.0.0` already in `pubspec.yaml`

### Project Structure Notes

New files:
| File | Type |
|------|------|
| `supabase/functions/delete_account_cascade/index.ts` | NEW — Deno Edge Function |
| `supabase/functions/export_user_data/index.ts` | NEW — Deno Edge Function |
| `pulse_coach/lib/features/auth/domain/usecases/delete_account_use_case.dart` | NEW |
| `pulse_coach/lib/features/auth/domain/usecases/export_data_use_case.dart` | NEW |
| `pulse_coach/lib/features/auth/presentation/bloc/export_data_cubit.dart` | NEW — `@injectable` transient |
| `pulse_coach/test/bloc/auth/delete_account_bloc_test.dart` | NEW — 2 `blocTest` cases |
| `pulse_coach/test/bloc/auth/export_data_cubit_test.dart` | NEW — 2 `blocTest` cases |

Updated files:
| File | Change |
|------|--------|
| `pulse_coach/lib/features/auth/domain/repositories/auth_repository.dart` | Add `deleteAccount()`, `exportData()` |
| `pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart` | Add `deleteAccount()`, `exportData()` methods |
| `pulse_coach/lib/features/auth/data/repositories/auth_repository_impl.dart` | Implement `deleteAccount()`, `exportData()` |
| `pulse_coach/lib/features/auth/presentation/bloc/auth_event.dart` | Add `accountDeletionRequested()` |
| `pulse_coach/lib/features/auth/presentation/bloc/auth_bloc.dart` | Inject `DeleteAccountUseCase`, add handler |
| `pulse_coach/lib/features/auth/presentation/bloc/auth_bloc.freezed.dart` | Auto-regenerated |
| `pulse_coach/lib/features/auth/presentation/pages/account_page.dart` | Add Export + Delete tiles + dialog + BlocConsumer + BlocListener |
| `pulse_coach/lib/core/routing/app_router.dart` | Change account route to `MultiBlocProvider` |
| `pulse_coach/lib/l10n/app/app_it.arb` | Add 9 new keys |
| `pulse_coach/lib/l10n/app/app_en.arb` | Add 9 new keys |
| `pulse_coach/lib/core/di/injection.config.dart` | Auto-generated by build_runner |

Do NOT modify:
- `BackupBloc`, `BackupRepository`, `BackupPage`, `BackupSettings` — backup feature is complete
- Any v1 feature files (today, sessions, progress, session, daily_plan, etc.)
- Drift table schema or migrations (no new Supabase DB tables in v2.1 scope)

### References

- Epic 16 / Story 16.4 ACs: [epics.md lines 2222–2249]
- FR77 (in-app account deletion): [epics.md line 121]
- NFR30 (GDPR export + erasure cascade): [epics.md line 160]
- ARCH23 (GDPR machinery — `delete_account_cascade`, `export_user_data`): [architecture.md line 200]
- ARCH25 (supabase_flutter import boundary): [architecture.md lines 764, 1313]
- Edge Functions file layout: [architecture.md lines 1344–1347]
- Previous story baseline: [16-3-e2e-encrypted-backup-and-restore.md]
- Auth layer: [16-2-email-apple-google-sign-in-and-sign-out.md]
- Project patterns: [project-context.md]

### Review Findings

Adversarial code review (Blind Hunter + Edge Case Hunter + Acceptance Auditor), 2026-06-21. All AC1–AC7 PASS; all hard constraints (ARCH25, Drift untouched, dialog styling, cubit transient) satisfied. 889 tests green, 0 analyzer issues. 0 patch / 0 decision-needed findings. 3 low-severity items deferred (8 dismissed as by-design or false positives).

- [x] [Review][Defer] `delete_account_cascade` ignores all `storage.remove` errors (not just not-found) — possible orphaned encrypted backup [supabase/functions/delete_account_cascade/index.ts:19] — deferred: Low (E2E-encrypted blob, key device-only; auth user — cascade root — still deleted). Changing to block-on-error contradicts the spec author's explicit "ignore errors" choice → human decision.
- [x] [Review][Defer] No automated test asserts `signOut()` runs only after a 200 (AC2/AC4 "no partial state" safety property untested at datasource layer) [pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart:71] — deferred: Low, task list only specified bloc/cubit tests.
- [x] [Review][Defer] New ARB keys `deleteAccountErrorGeneric`/`exportDataErrorGeneric` are unused; SnackBars show raw exception text (consistent with app-wide pattern; the `AuthError` listener is shared with sign-out so generic copy cannot be cleanly wired) [pulse_coach/lib/features/auth/presentation/pages/account_page.dart:34] — deferred: Low, cosmetic/UX, matches existing convention.

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Fixed `auth_bloc_test.dart`, `pages_smoke_test.dart`, `settings_page_test.dart`: all existing stubs needed `DeleteAccountUseCase` (7th positional arg) and `_StubAuthRepository` needed `deleteAccount()` + `exportData()` implementations after `AuthBloc` constructor changed.
- Used `MultiBlocListener` in `AccountPage` (3 listeners: `AuthBloc` unauthenticated, `AuthBloc` error, `ExportDataCubit`) rather than `BlocConsumer` to keep build/listen separation clean.

### Completion Notes List

- Implemented all 10 tasks covering Supabase Edge Functions, AuthRepository extension, use cases, AuthBloc event, ExportDataCubit, AccountPage UI, routing, ARB keys, tests, and verification.
- 4 new tests added (2 for `AccountDeletionRequested` in `AuthBloc`, 2 for `ExportDataCubit.exportData`). All 889 tests pass.
- `flutter analyze` reports 0 issues.
- ARCH25 boundary maintained: `AuthRemoteDataSource` accesses Supabase only via `_supabase.client.functions.invoke(...)`.
- Local Drift data NOT touched by deletion flow as required.
- Destructive-action dialog pattern: `FilledButton` Cancel (dominant) + `TextButton` with error color Delete (secondary).
- Sign-out and account deletion both navigate to Today on `unauthenticated` — acceptable UX improvement per AC3 notes.

### File List

- `supabase/functions/delete_account_cascade/index.ts` — NEW
- `supabase/functions/export_user_data/index.ts` — NEW
- `pulse_coach/lib/features/auth/domain/repositories/auth_repository.dart` — MODIFIED
- `pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart` — MODIFIED
- `pulse_coach/lib/features/auth/data/repositories/auth_repository_impl.dart` — MODIFIED
- `pulse_coach/lib/features/auth/domain/usecases/delete_account_use_case.dart` — NEW
- `pulse_coach/lib/features/auth/domain/usecases/export_data_use_case.dart` — NEW
- `pulse_coach/lib/features/auth/presentation/bloc/auth_event.dart` — MODIFIED
- `pulse_coach/lib/features/auth/presentation/bloc/auth_bloc.dart` — MODIFIED
- `pulse_coach/lib/features/auth/presentation/bloc/auth_bloc.freezed.dart` — AUTO-GENERATED
- `pulse_coach/lib/features/auth/presentation/bloc/export_data_cubit.dart` — NEW
- `pulse_coach/lib/features/auth/presentation/bloc/export_data_cubit.freezed.dart` — AUTO-GENERATED
- `pulse_coach/lib/features/auth/presentation/pages/account_page.dart` — MODIFIED
- `pulse_coach/lib/core/routing/app_router.dart` — MODIFIED
- `pulse_coach/lib/l10n/app/app_it.arb` — MODIFIED (9 new keys)
- `pulse_coach/lib/l10n/app/app_en.arb` — MODIFIED (9 new keys)
- `pulse_coach/lib/core/di/injection.config.dart` — AUTO-GENERATED
- `pulse_coach/test/bloc/auth/delete_account_bloc_test.dart` — NEW
- `pulse_coach/test/bloc/auth/delete_account_bloc_test.mocks.dart` — AUTO-GENERATED
- `pulse_coach/test/bloc/auth/export_data_cubit_test.dart` — NEW
- `pulse_coach/test/bloc/auth/export_data_cubit_test.mocks.dart` — AUTO-GENERATED
- `pulse_coach/test/bloc/auth_bloc_test.dart` — MODIFIED (added DeleteAccountUseCase mock)
- `pulse_coach/test/bloc/auth_bloc_test.mocks.dart` — AUTO-GENERATED
- `pulse_coach/test/widget/pages_smoke_test.dart` — MODIFIED (stub updated)
- `pulse_coach/test/widget/settings_page_test.dart` — MODIFIED (stub updated)

### Change Log

- 2026-06-21: Story 16.4 implemented — in-app account deletion (delete_account_cascade Edge Function, AuthBloc.AccountDeletionRequested, destructive dialog) and data export (export_user_data Edge Function, ExportDataCubit, Share.share). 9 new ARB keys per locale. 4 new tests. 889 tests passing, 0 analyzer issues.
