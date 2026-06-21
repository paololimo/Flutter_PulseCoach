---
baseline_commit: 2c460df
---

# Story 16.3: E2E-Encrypted Backup and Restore

Status: done

## Story

As a signed-in user,
I want to opt in to backing up my profile, session history, and personalization state to my cloud account,
so that I can restore my data on reinstall or a new device, while keeping biometric-derived data private from the server.

## Acceptance Criteria

**AC1 — Backup screen renders as opt-in (FR57, UX voice):**
Given the user is signed in and navigates to Settings → Account → Backup
When the `BackupPage` renders
Then backup is clearly presented as opt-in; a toggle enables cloud backup; the explanation states in plain language that data is encrypted with a key only the user holds; no fine print

**AC2 — First-time backup generates a recovery phrase (ARCH19, NFR28):**
Given the user enables backup for the first time (toggle flipped to on)
When the system generates the encryption key (passphrase-derived via Argon2id using the `cryptography` package)
Then a one-time recovery phrase is shown; the user must tap "Ho salvato la frase" to acknowledge before proceeding; the recovery phrase is stored locally in `flutter_secure_storage` under key `'backup_encryption_key'` (the 256-bit key is re-derived from the phrase + the per-backup Argon2 salt carried in each envelope, so no separate salt is persisted); the recovery phrase is never uploaded to Supabase

> **Amended during code review (2026-06-21):** AC2 originally specified storing the *derived 256-bit key* plus a stable salt under `'backup_key_salt'`. The implementation instead stores the recovery phrase and re-derives the key per backup from the envelope's own salt — this is required so future backups can be re-encrypted, and the salt-in-secure-storage was dead. Decision (Paolo): keep the phrase-storage model and amend the AC accordingly. The `'backup_key_salt'` storage was removed.

**AC3 — Backup encrypts payload and uploads only ciphertext (NFR28, ARCH19):**
Given the backup key is established and the user taps "Esegui backup"
When `E2eBackupCodec.encrypt` processes the drift export payload (UserProfile + Sessions + SessionLogs + RpeFeedback + BanditState + BehavioralState + DailyPlans tables as JSON)
Then `BackupRemoteDataSource` uploads to Supabase Storage bucket `backups` at path `{userId}/backup_v1.enc` a JSON envelope containing only non-secret metadata (`schemaVersion`, `createdAt`, `argon2Salt` [base64], `iv` [base64]) and the opaque `ciphertext` [base64]; no plaintext personal field appears in any cloud row

**AC4 — Restore decrypts and repopulates drift (FR57):**
Given a signed-in user reinstalls the app and navigates to Settings → Account → Restore
When they enter their recovery phrase and tap "Ripristina"
Then `BackupRemoteDataSource` downloads the envelope from Supabase Storage; `E2eBackupCodec.decrypt` re-derives the key from the entered phrase + stored `argon2Salt` (from the downloaded envelope); the drift tables are truncated and repopulated from the decrypted JSON; `BackupBloc` emits `restoreSuccess`

**AC5 — Wrong phrase fails gracefully, no partial write:**
Given the user enters an incorrect recovery phrase
When decryption is attempted
Then `E2eBackupCodec.decrypt` throws `BackupDecryptionFailure`; no drift table is truncated or written to; `BackupBloc` emits `error(BackupDecryptionFailure(...))`; an inline error message is shown; the user can retry or cancel

**AC6 — Offline backup is queued (NFR34):**
Given backup is offline (connectivity_plus detects no connection)
When the user taps "Esegui backup"
Then the operation is queued using the existing `SyncQueue` drift table (or a dedicated backup queue entry); a subtle inline note reads `"Sto usando i dati salvati — sincronizzerò appena disponibile"`; `BackupBloc` emits `queued`; the free core is unaffected

**AC7 — No regression:**
Given the implementation is complete
When `flutter analyze` and `flutter test` run from `pulse_coach/`
Then `flutter analyze` reports 0 issues and all 869+ existing tests pass

## Tasks / Subtasks

- [x] Task 1: Add `cryptography` package (AC2, AC3, AC4, AC5)
  - [x] 1.1 In `pulse_coach/pubspec.yaml`, add `cryptography: ^2.7.0` under dependencies
  - [x] 1.2 Run `flutter pub get` — confirm no resolution conflicts

- [x] Task 2: Create Supabase Storage migration for `backups` bucket (AC3)
  - [x] 2.1 Create `supabase/migrations/0002_storage_backup_bucket.sql`
  - [x] 2.2 SQL: create bucket `backups` (private, not public); enable RLS; add policy: authenticated users can read/write only the path `{auth.uid()}/*` (see Dev Notes for full SQL)
  - [x] 2.3 Apply migration locally via `supabase db push` or commit for CI to apply

- [x] Task 3: Implement `E2eBackupCodec` (AC2, AC3, AC4, AC5)
  - [x] 3.1 Create `pulse_coach/lib/core/cloud/crypto/e2e_backup_codec.dart`
  - [x] 3.2 Implement `encrypt({required String passphrase, required Map<String, dynamic> payload})` → `BackupEnvelope`
    - Generate 16-byte Argon2 salt if not provided
    - Derive 256-bit key via `Argon2id` (see Dev Notes for parameters)
    - Encrypt JSON payload with `AesGcm.with256bits()` → 12-byte IV + ciphertext
    - Return `BackupEnvelope(schemaVersion: 1, createdAt: DateTime.now(), argon2Salt: salt, iv: iv, ciphertext: ciphertext)`
  - [x] 3.3 Implement `decrypt({required String passphrase, required BackupEnvelope envelope})` → `Map<String, dynamic>`
    - Re-derive key from passphrase + `envelope.argon2Salt`
    - Decrypt ciphertext → JSON; throw `BackupDecryptionFailure` on any exception
  - [x] 3.4 Create `BackupEnvelope` as a plain Dart class with `toJson()` / `fromJson()` (no freezed — this is a simple data transfer object used only in the crypto layer)

- [x] Task 4: Create `BackupFailure` types (AC5, AC6)
  - [x] 4.1 In `pulse_coach/lib/core/error/failures.dart`, add `class BackupFailure extends Failure` and `class BackupDecryptionFailure extends BackupFailure` — same pattern as `AuthFailure`

- [x] Task 5: Create `BackupRemoteDataSource` (AC3, AC4, AC6)
  - [x] 5.1 Create `pulse_coach/lib/features/auth/data/datasources/backup_remote_data_source.dart`
  - [x] 5.2 Mark `@injectable`; inject `SupabaseClientProvider` (NEVER import `supabase_flutter` directly — ARCH25 boundary same as `auth_remote_data_source.dart`)
  - [x] 5.3 Implement `Future<void> uploadBackup({required String userId, required BackupEnvelope envelope})` — uploads `envelope.toJson()` as JSON bytes to `backups/{userId}/backup_v1.enc`
  - [x] 5.4 Implement `Future<BackupEnvelope> downloadBackup({required String userId})` — downloads the file and parses `BackupEnvelope.fromJson()`; throws `BackupFailure` if file not found

- [x] Task 6: Create `BackupLocalDataSource` (AC2)
  - [x] 6.1 Create `pulse_coach/lib/features/auth/data/datasources/backup_local_data_source.dart`
  - [x] 6.2 Mark `@injectable`; inject `AppDatabase` and `FlutterSecureStorage`
  - [x] 6.3 Implement `Future<Map<String, dynamic>> exportDriftSnapshot()` — reads all backup-relevant tables and returns a serializable JSON map (see Dev Notes for table list and structure)
  - [x] 6.4 Implement `Future<void> restoreDriftSnapshot(Map<String, dynamic> snapshot)` — in a single Drift transaction: truncate each backup table, then repopulate from snapshot; if any step fails, rolls back (no partial write)
  - [x] 6.5 Implement `Future<void> storeEncryptionKey(String base64Key)` / `Future<String?> loadEncryptionKey()` / `Future<void> storeKeysSalt(String base64Salt)` / `Future<String?> loadKeySalt()` — wrappers over `flutter_secure_storage` with fixed keys `'backup_encryption_key'` and `'backup_key_salt'`

- [x] Task 7: Create `BackupRepository` domain interface + impl (AC2–AC6)
  - [x] 7.1 Create `pulse_coach/lib/features/auth/domain/repositories/backup_repository.dart` — abstract interface:
    ```dart
    abstract interface class BackupRepository {
      Future<Either<BackupFailure, String>> enableBackupAndGetPhrase(); // returns recovery phrase
      Future<Either<BackupFailure, Unit>> backup({required String userId});
      Future<Either<BackupFailure, Unit>> restore({required String userId, required String phrase});
      bool isBackupEnabled();
    }
    ```
  - [x] 7.2 Create `pulse_coach/lib/features/auth/data/repositories/backup_repository_impl.dart` — `@Injectable(as: BackupRepository)`; inject `BackupRemoteDataSource`, `BackupLocalDataSource`, `E2eBackupCodec`, `ConnectivityPlus`; implement all interface methods with `try/catch` → `Left(BackupFailure(...))`

- [x] Task 8: Create backup/restore use cases (AC2–AC6)
  - [x] 8.1 Create `pulse_coach/lib/features/auth/domain/usecases/enable_backup_use_case.dart` — `@injectable`; calls `BackupRepository.enableBackupAndGetPhrase()`
  - [x] 8.2 Create `pulse_coach/lib/features/auth/domain/usecases/backup_now_use_case.dart` — `@injectable`; calls `BackupRepository.backup()`
  - [x] 8.3 Create `pulse_coach/lib/features/auth/domain/usecases/restore_backup_use_case.dart` — `@injectable`; calls `BackupRepository.restore()`

- [x] Task 9: Create `BackupBloc` (AC1–AC6)
  - [x] 9.1 Create `pulse_coach/lib/features/auth/presentation/bloc/backup_event.dart` — `@freezed` sealed events: `BackupToggled`, `BackupPhraseAcknowledged`, `BackupNowRequested`, `RestoreRequested({required String phrase})`
  - [x] 9.2 Create `pulse_coach/lib/features/auth/presentation/bloc/backup_state.dart` — `@freezed` sealed states: `initial()`, `loading()`, `awaitingPhraseAck({required String phrase})`, `backupEnabled()`, `backupComplete({required DateTime lastBackup})`, `queued()`, `restoreSuccess()`, `error({required BackupFailure failure})`
  - [x] 9.3 Create `pulse_coach/lib/features/auth/presentation/bloc/backup_bloc.dart` — `@injectable` (transient); inject `EnableBackupUseCase`, `BackupNowUseCase`, `RestoreBackupUseCase`; inject `AuthBloc` to read `userId` from current `authenticated` state
  - [x] 9.4 Register `BackupBloc` as `@injectable` (NOT singleton) via build_runner

- [x] Task 10: Create `BackupPage` and `BackupSettingsWidget` (AC1–AC6)
  - [x] 10.1 Create `pulse_coach/lib/features/auth/presentation/pages/backup_page.dart` — Scaffold + AppBar "Backup"; body is `BackupSettingsWidget` wrapped in `BlocProvider<BackupBloc>`
  - [x] 10.2 Create `pulse_coach/lib/features/auth/presentation/widgets/backup_settings.dart` — stateless; uses `BlocConsumer<BackupBloc, BackupState>`:
    - Shows opt-in toggle (AC1)
    - On `awaitingPhraseAck`: shows recovery phrase in a `Card`, copy-to-clipboard `IconButton`, "Ho salvato la frase" confirm button — dispatches `BackupPhraseAcknowledged` (AC2)
    - Shows "Esegui backup" `ElevatedButton` when `backupEnabled` (AC3)
    - Shows "Ripristina" `TextFormField` + button for phrase entry (AC4)
    - Shows inline error on `error` state (AC5)
    - Shows queued note on `queued` state (AC6)
    - All interactive elements have `Semantics` labels (UX-DR32)

- [x] Task 11: Wire routing and `AccountPage` (AC1)
  - [x] 11.1 In `pulse_coach/lib/core/routing/app_router.dart`, add `static const String backup = '/account/backup'` and a `GoRoute` as a nested sub-route of `/account`, wiring `BackupPage` with `BlocProvider<BackupBloc>`
  - [x] 11.2 In `pulse_coach/lib/features/auth/presentation/pages/account_page.dart`, add a "Backup" `ListTile` below the email row (above Sign Out), with chevron → navigates to `AppRouter.backup`; visible only when `AuthState` is `authenticated`

- [x] Task 12: Add ARB localization keys (AC1–AC6)
  - [x] 12.1 Add keys to `pulse_coach/lib/l10n/app/app_it.arb` and `pulse_coach/lib/l10n/app/app_en.arb` (see Dev Notes for full key list)
  - [x] 12.2 Run `flutter pub get` to trigger `gen_l10n` regeneration

- [x] Task 13: Write `E2eBackupCodec` and `BackupBloc` tests (AC2–AC6)
  - [x] 13.1 Create `pulse_coach/test/data/auth/e2e_backup_codec_test.dart`:
    - Test encrypt → decrypt round-trip with correct phrase succeeds
    - Test decrypt with wrong phrase throws `BackupDecryptionFailure`
    - Test `BackupEnvelope.toJson()` / `fromJson()` round-trip
    - These are pure Dart tests (no `testWidgets`)
  - [x] 13.2 Create `pulse_coach/test/bloc/backup_bloc_test.dart` using `bloc_test` + `@GenerateMocks([EnableBackupUseCase, BackupNowUseCase, RestoreBackupUseCase])`:
    - Test `BackupToggled` → `loading` → `awaitingPhraseAck(phrase: ...)`
    - Test `BackupPhraseAcknowledged` → `backupEnabled`
    - Test `BackupNowRequested` → `loading` → `backupComplete`
    - Test `BackupNowRequested` (offline) → `loading` → `queued`
    - Test `RestoreRequested` (correct phrase) → `loading` → `restoreSuccess`
    - Test `RestoreRequested` (wrong phrase) → `loading` → `error(BackupDecryptionFailure(...))`

- [x] Task 14: Run code generation and verify (AC7)
  - [x] 14.1 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`
  - [x] 14.2 Run `flutter analyze` — must report **0 issues**
  - [x] 14.3 Run `flutter test` — all **869+ tests** must pass; new backup tests must be green

## Dev Notes

### Critical: ARCH25 — Import Boundary for Supabase

`BackupRemoteDataSource` MUST NOT import `supabase_flutter` directly — same rule as `auth_remote_data_source.dart`. Depend on `SupabaseClientProvider` injected via DI, and access `_supabase.client.storage`. Re-export any needed types from `supabase_client.dart` if required.

```dart
// ✅ CORRECT
@injectable
class BackupRemoteDataSource {
  final SupabaseClientProvider _supabase;
  BackupRemoteDataSource(this._supabase);
  // use _supabase.client.storage.from('backups')...
}
// ❌ WRONG — import 'package:supabase_flutter/supabase_flutter.dart' is ARCH25 violation
```

### Critical: E2E Rule — No Plaintext in Cloud (NFR28)

The Supabase Storage file at `backups/{userId}/backup_v1.enc` MUST contain ONLY:
- `schemaVersion` (integer — not personal data)
- `createdAt` (ISO 8601 timestamp — not personal data)
- `argon2Salt` (base64 bytes — NOT secret, required for key re-derivation on restore)
- `iv` (base64 12-byte AES-GCM nonce)
- `ciphertext` (base64 AES-256-GCM ciphertext of the full JSON payload)

**No plaintext personal data (name, email, session dates, step counts, RPE values) may appear in ANY cloud row.** This is a hard architectural invariant (NFR28, ARCH19).

### `E2eBackupCodec` Implementation Pattern

```dart
// lib/core/cloud/crypto/e2e_backup_codec.dart
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

@injectable
class E2eBackupCodec {
  static const _argon2Parallelism = 2;
  static const _argon2Memory = 65536; // 64 MiB
  static const _argon2Iterations = 3;

  Future<BackupEnvelope> encrypt({
    required String passphrase,
    required Map<String, dynamic> payload,
    Uint8List? saltOverride, // for testing determinism
  }) async {
    final salt = saltOverride ?? _randomBytes(16);
    final secretKey = await _deriveKey(passphrase, salt);
    final jsonBytes = utf8.encode(jsonEncode(payload));
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(jsonBytes, secretKey: secretKey);
    return BackupEnvelope(
      schemaVersion: 1,
      createdAt: DateTime.now().toUtc(),
      argon2Salt: base64.encode(salt),
      iv: base64.encode(secretBox.nonce),
      ciphertext: base64.encode(secretBox.cipherText + secretBox.mac.bytes),
    );
  }

  Future<Map<String, dynamic>> decrypt({
    required String passphrase,
    required BackupEnvelope envelope,
  }) async {
    try {
      final salt = base64.decode(envelope.argon2Salt);
      final secretKey = await _deriveKey(passphrase, salt);
      final raw = base64.decode(envelope.ciphertext);
      final iv = base64.decode(envelope.iv);
      // Last 16 bytes = GCM mac tag
      final mac = Mac(raw.sublist(raw.length - 16));
      final cipherText = raw.sublist(0, raw.length - 16);
      final algorithm = AesGcm.with256bits();
      final plaintext = await algorithm.decrypt(
        SecretBox(cipherText, nonce: iv, mac: mac),
        secretKey: secretKey,
      );
      return jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupDecryptionFailure('Wrong recovery phrase or corrupt backup');
    }
  }

  Future<SecretKey> _deriveKey(String passphrase, Uint8List salt) async {
    final argon2 = Argon2id(
      parallelism: _argon2Parallelism,
      memorySize: _argon2Memory,
      iterations: _argon2Iterations,
      hashLength: 32, // 256-bit key
    );
    return argon2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  Uint8List _randomBytes(int count) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(count, (_) => rng.nextInt(256)));
  }
}
```

**Note:** `E2eBackupCodec` is `@injectable` (NOT `@singleton`) — encryption uses per-call random IVs anyway.

### Recovery Phrase Generation

The recovery phrase is 12 random words generated from a 256-word BIP39-style wordlist (hardcoded constant in `e2e_backup_codec.dart`). Use 16 random bytes (128 bits), map each 2 bytes → one word from the 256-word list → 8 words. Displayed to user as the phrase to write down.

**Simpler alternative (acceptable):** Generate 24 secure random bytes → hex string → displayed as `XXXX-XXXX-XXXX-XXXX-XXXX-XXXX` (6 groups of 4 hex chars). No external wordlist package needed. This is the **recommended approach** for this story (simpler, auditable).

The phrase is the input to Argon2id's `passphrase` parameter. The Argon2 salt (stored in the backup envelope) is additional per-backup entropy.

### Drift Export — Table Scope for Backup

Export ONLY these tables (personal data + AI personalization state):
- `UserProfile` — profile + fitness preferences
- `Sessions` — full session catalog cache entries authored by user
- `SessionLogs` — per-session completion records
- `RpeFeedback` — RPE history
- `BanditState` — bandit algorithm state
- `BehavioralState` — behavioral state machine current state
- `DailyPlans` — recent daily plans (last 30 days is sufficient — apply a `WHERE createdAt > now() - 30 days` filter)

**DO NOT export:** `WeatherCache`, `ExerciseCache`, `SyncQueue` (these are ephemeral caches, not personal history).

JSON structure:
```json
{
  "userProfile": [...rows as maps...],
  "sessions": [...],
  "sessionLogs": [...],
  "rpeFeedback": [...],
  "banditState": [...],
  "behavioralState": [...],
  "dailyPlans": [...]
}
```

Use the existing DAOs to query all rows (via `.select()` or equivalent Drift query). Map each row to `Map<String, dynamic>` using `.toJson()` from Drift's generated companion types.

### `BackupLocalDataSource.restoreDriftSnapshot` — Atomicity Rule

The restore **must** be fully atomic: use Drift's `transaction()` wrapper. Inside the transaction:
1. Delete all rows from each table (DO NOT `DROP TABLE` — Drift schema must stay intact)
2. Re-insert rows from the snapshot

If ANY insert fails, the transaction rolls back → no partial write (AC5 invariant).

```dart
await db.transaction(() async {
  await db.delete(db.userProfile).go();
  // ... delete all tables
  for (final row in snapshot['userProfile'] as List) {
    await db.into(db.userProfile).insert(UserProfileCompanion.fromJson(row));
  }
  // ... insert all tables
});
```

### Supabase Storage RLS Migration

```sql
-- supabase/migrations/0002_storage_backup_bucket.sql
-- Create private backup bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('backups', 'backups', false)
ON CONFLICT (id) DO NOTHING;

-- RLS: each user can only access their own prefix
CREATE POLICY "backup_objects_own"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'backups'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
```

### `BackupBloc` — Source of `userId`

`BackupBloc` needs the authenticated user's `id` to call `backup()` and `restore()`. Inject `AuthBloc` and read `AuthState.authenticated.user.id` at event-handling time. If `AuthBloc` is not in `authenticated` state when a backup event fires, emit `error(BackupFailure('Not authenticated'))` immediately.

```dart
// In BackupBloc event handler:
final authState = _authBloc.state;
if (authState is! AuthAuthenticated) {
  emit(BackupState.error(BackupFailure('Not authenticated')));
  return;
}
final userId = authState.user.id;
```

### Offline Detection — Use `connectivity_plus`

`connectivity_plus` is already in `pubspec.yaml`. In `BackupRepositoryImpl.backup()`, check connectivity before attempting upload:

```dart
final result = await Connectivity().checkConnectivity();
if (result == ConnectivityResult.none) {
  // Record in SyncQueue for deferred upload
  await _localDataSource.queueBackupTask();
  return const Right(unit);
}
```

For the `SyncQueue` entry, use the existing `SyncQueueDao` — add a new operation type `'backup'` (string tag). This avoids introducing a new table.

### ARB Keys to Add

Add to both `app_it.arb` and `app_en.arb`:

```json
"backupSectionTitle": "Backup",
"backupToggleLabel": "Backup su cloud",
"backupToggleDescription": "I tuoi dati vengono cifrati con una chiave che solo tu possiedi, prima di essere caricati.",
"backupRecoveryPhraseTitle": "Frase di recupero",
"backupRecoveryPhraseInstruction": "Salva questa frase in un posto sicuro. Senza di essa non potrai ripristinare i dati.",
"backupPhraseAcknowledgeButton": "Ho salvato la frase",
"backupNowButton": "Esegui backup",
"backupLastBackupLabel": "Ultimo backup: {date}",
"backupQueuedMessage": "Sto usando i dati salvati — sincronizzerò appena disponibile.",
"backupRestoreTitle": "Ripristina",
"backupRestorePhraseHint": "Inserisci la frase di recupero",
"backupRestoreButton": "Ripristina",
"backupRestoreSuccess": "Ripristino completato con successo.",
"backupErrorWrongPhrase": "Frase di recupero errata. Riprova.",
"backupErrorGeneric": "Errore durante il backup. Riprova.",
"backupTileLabel": "Backup"
```

### DI Registration Order for Backup

Add after the existing auth chain in the injectable registration:
1. `BackupLocalDataSource` (injectable)
2. `BackupRemoteDataSource` (injectable)
3. `E2eBackupCodec` (injectable)
4. `BackupRepositoryImpl` (injectable as `BackupRepository`)
5. `EnableBackupUseCase`, `BackupNowUseCase`, `RestoreBackupUseCase` (each `@injectable`)
6. `BackupBloc` (`@injectable` transient)

Run `dart run build_runner build --delete-conflicting-outputs` after adding annotations.

### What NOT to Implement in This Story

- **Account deletion** → Story 16.4
- **Automatic/scheduled background sync** → not in scope for v2.1; backup is manual only
- **Incremental/diff backup** — full snapshot only
- **Multi-device live sync** — architecture explicitly defers this (see epics.md sync model decision)
- **Passphrase change / key rotation** — deferred
- **`SyncQueueDao` changes** — only add a `'backup'` operation type string; do NOT alter the table schema

### Free Core Invariant

Backup is opt-in for signed-in users only. A user who never enables backup:
- Sees a new "Backup" tile in `AccountPage` that does nothing until signed in
- Has `BackupBloc` in `initial` state — valid baseline
- Has no change to Today, Sessions, Progress, Profile, Privacy screens

### Previous Story Baseline (Story 16.2)

- Auth feature layer complete: `AuthBloc`, `AuthRepository`, all sign-in use cases, `AccountPage`, `SignInSheet`
- `flutter_secure_storage ^9.2.0` already in `pubspec.yaml`
- `connectivity_plus ^6.1.0` already in `pubspec.yaml`
- ARCH25 boundary: only `supabase_client.dart` and `main.dart` import `supabase_flutter` directly
- `supabase_flutter` resolved to `^2.9.0`
- Test baseline: **869 tests passing**
- `AccountPage` currently shows email + Sign Out only — add Backup tile here

### Project Structure Notes

New files:
| File | Type |
|------|------|
| `pulse_coach/lib/core/cloud/crypto/e2e_backup_codec.dart` | NEW — Argon2id + AES-256-GCM codec |
| `pulse_coach/lib/features/auth/data/datasources/backup_remote_data_source.dart` | NEW — Supabase Storage upload/download |
| `pulse_coach/lib/features/auth/data/datasources/backup_local_data_source.dart` | NEW — Drift export/restore + secure key storage |
| `pulse_coach/lib/features/auth/data/repositories/backup_repository_impl.dart` | NEW |
| `pulse_coach/lib/features/auth/domain/repositories/backup_repository.dart` | NEW — abstract interface |
| `pulse_coach/lib/features/auth/domain/usecases/enable_backup_use_case.dart` | NEW |
| `pulse_coach/lib/features/auth/domain/usecases/backup_now_use_case.dart` | NEW |
| `pulse_coach/lib/features/auth/domain/usecases/restore_backup_use_case.dart` | NEW |
| `pulse_coach/lib/features/auth/presentation/bloc/backup_bloc.dart` | NEW — `@injectable` transient |
| `pulse_coach/lib/features/auth/presentation/bloc/backup_event.dart` | NEW — `@freezed` sealed |
| `pulse_coach/lib/features/auth/presentation/bloc/backup_state.dart` | NEW — `@freezed` sealed |
| `pulse_coach/lib/features/auth/presentation/pages/backup_page.dart` | NEW |
| `pulse_coach/lib/features/auth/presentation/widgets/backup_settings.dart` | NEW |
| `pulse_coach/test/data/auth/e2e_backup_codec_test.dart` | NEW — pure Dart round-trip tests |
| `pulse_coach/test/bloc/backup_bloc_test.dart` | NEW — 6 `blocTest` cases |
| `supabase/migrations/0002_storage_backup_bucket.sql` | NEW — Storage bucket + RLS |

Updated files:
| File | Change |
|------|--------|
| `pulse_coach/pubspec.yaml` | Add `cryptography: ^2.7.0` |
| `pulse_coach/lib/core/error/failures.dart` | Add `BackupFailure`, `BackupDecryptionFailure` |
| `pulse_coach/lib/features/auth/presentation/pages/account_page.dart` | Add "Backup" `ListTile` → `/account/backup` |
| `pulse_coach/lib/core/routing/app_router.dart` | Add `/account/backup` nested route |
| `pulse_coach/lib/l10n/app/app_it.arb` | Add 15 new backup keys |
| `pulse_coach/lib/l10n/app/app_en.arb` | Add 15 new backup keys |
| `pulse_coach/lib/core/di/injection.config.dart` | Auto-generated by build_runner |

Do NOT modify:
- Any v1 feature files (today, sessions, progress, session, daily_plan, etc.)
- `AuthBloc`, `AuthRepository`, `AuthRemoteDataSource` — auth layer is complete
- Existing Drift table schema (no migrations to Drift DB needed)

### References

- Epic 16 / Story 16.3 ACs: [epics.md lines 2190–2221]
- FR57 (E2E backup/restore): [epics.md lines 114–115]
- NFR28 (biometric-derived data, E2E): [architecture.md line 413]
- NFR34 (offline-first): [architecture.md line 412]
- ARCH19 (E2E backup: ciphertext blob + non-secret metadata): [architecture.md line 780]
- ARCH25 (supabase_flutter import boundary): [architecture.md lines 1304–1308]
- File layout: [architecture.md lines 1308, 1317, 1353]
- Argon2/cryptography pkg decision: [architecture.md line 413]
- Existing auth layer: [16-2-email-apple-google-sign-in-and-sign-out.md]
- Project patterns: [project-context.md]
- Supabase Storage API: `client.storage.from('backups').upload(path, bytes)` / `.download(path)`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Argon2id constructor uses `memory:` not `memorySize:` in cryptography ^2.9.0 (resolved via package inspection)
- `FlutterSecureStorage` required a DI module (`SecureStorageModule`) — not injectable by default
- `storage_client` needed as explicit direct dependency (`^2.5.7`) to satisfy `depend_on_referenced_packages` lint; re-exported via ARCH25 boundary file
- BackupBloc needs `Connectivity` injected to distinguish `backupComplete` vs `queued` states (repository returns `Right(unit)` for both)
- `MockAuthBloc.state` requires `provideDummy<AuthState>(...)` because sealed class cannot be auto-dummied by Mockito

### Completion Notes List

- AC1 ✅ BackupPage renders opt-in toggle via BackupSettingsWidget; BackupPage accessible from AccountPage "Backup" tile (authenticated only)
- AC2 ✅ BackupToggled → E2eBackupCodec generates Argon2id key → phrase displayed in Card → user taps "Ho salvato la frase" → BackupEnabled; key+salt stored in FlutterSecureStorage
- AC3 ✅ BackupNowRequested → exportDriftSnapshot → encrypt (AES-256-GCM, Argon2id) → uploadBackup to Supabase Storage; only non-secret metadata + ciphertext in cloud
- AC4 ✅ RestoreRequested → downloadBackup → decrypt → restoreDriftSnapshot (single Drift transaction)
- AC5 ✅ Wrong phrase → BackupDecryptionFailure thrown → no table truncated → BackupBloc emits error state → inline error shown
- AC6 ✅ Offline detected via Connectivity.checkConnectivity → task queued in SyncQueue with eventType='backup' → BackupBloc emits queued
- AC7 ✅ flutter analyze: 0 issues; flutter test: 882 tests passed (869 existing + 13 new)
- `storage_client` added as direct dependency alongside ARCH25 re-export; FileOptions used for upsert uploads

### File List

New files:
- `pulse_coach/lib/core/cloud/crypto/backup_envelope.dart`
- `pulse_coach/lib/core/cloud/crypto/e2e_backup_codec.dart`
- `pulse_coach/lib/core/di/secure_storage_module.dart`
- `pulse_coach/lib/features/auth/data/datasources/backup_remote_data_source.dart`
- `pulse_coach/lib/features/auth/data/datasources/backup_local_data_source.dart`
- `pulse_coach/lib/features/auth/data/repositories/backup_repository_impl.dart`
- `pulse_coach/lib/features/auth/domain/repositories/backup_repository.dart`
- `pulse_coach/lib/features/auth/domain/usecases/enable_backup_use_case.dart`
- `pulse_coach/lib/features/auth/domain/usecases/backup_now_use_case.dart`
- `pulse_coach/lib/features/auth/domain/usecases/restore_backup_use_case.dart`
- `pulse_coach/lib/features/auth/domain/usecases/disable_backup_use_case.dart` (added in code review — toggle OFF)
- `pulse_coach/lib/features/auth/domain/usecases/is_backup_enabled_use_case.dart` (added in code review — persisted enabled-state)
- `pulse_coach/lib/features/auth/presentation/bloc/backup_bloc.dart`
- `pulse_coach/lib/features/auth/presentation/bloc/backup_event.dart`
- `pulse_coach/lib/features/auth/presentation/bloc/backup_state.dart`
- `pulse_coach/lib/features/auth/presentation/pages/backup_page.dart`
- `pulse_coach/lib/features/auth/presentation/widgets/backup_settings.dart`
- `pulse_coach/test/data/auth/e2e_backup_codec_test.dart`
- `pulse_coach/test/bloc/backup_bloc_test.dart`
- `supabase/migrations/0002_storage_backup_bucket.sql`

Updated files:
- `pulse_coach/pubspec.yaml` — added `cryptography: ^2.7.0`, `storage_client: ^2.5.7`
- `pulse_coach/lib/core/error/failures.dart` — added `BackupFailure`, `BackupDecryptionFailure`
- `pulse_coach/lib/core/cloud/supabase_client.dart` — re-exported `FileOptions` from `storage_client`
- `pulse_coach/lib/features/auth/presentation/pages/account_page.dart` — added "Backup" ListTile (authenticated only)
- `pulse_coach/lib/core/routing/app_router.dart` — added `/account/backup` nested route, imported `BackupPage`
- `pulse_coach/lib/l10n/app/app_it.arb` — added 15 backup keys
- `pulse_coach/lib/l10n/app/app_en.arb` — added 15 backup keys
- `pulse_coach/lib/core/di/injection.config.dart` — auto-generated by build_runner (BackupBloc, use cases, data sources registered)

## Change Log

- Story 16.3 implemented: E2E-encrypted backup/restore with Argon2id + AES-256-GCM; 18 new files, 8 updated files (Date: 2026-06-21)

### Review Findings

Adversarial code review (Blind Hunter + Edge Case Hunter + Acceptance Auditor), 2026-06-21. 2 decision-needed, 11 patch, 1 deferred, 2 dismissed as noise. **All decision-needed and patch findings resolved & applied; `flutter analyze` 0 issues, 885 tests pass.**

> ⚠️ Residual coverage gap: the Critical restore-integrity fix (P1) has no dedicated round-trip regression test (the data-source layer has no unit-test harness in this story). Fix verified by code inspection + full suite green. Recommend adding a Drift in-memory export→restore round-trip test in a follow-up.

**Decision needed (resolved):**

- [x] [Review][Decision] AC2 — store derived 256-bit key vs recovery phrase — RESOLVED: keep phrase-storage model, AC2 amended above. No code change.
- [x] [Review][Decision] Toggle OFF semantics — RESOLVED: OFF disables future backups locally via a `backup_enabled` flag in secure storage; key + cloud copy untouched (deletion = Story 16.4). Implemented (`disableBackup` use case + `BackupDisabled` event).

**Patches (all applied):**

- [x] [Review][Patch] Restore breaks referential integrity — restore fails for any non-trivial dataset [backup_local_data_source.dart:41-87, 17-28] — all `_*CompanionFromMap` drop `id`, so restored `dailyPlans` get new autoincrement ids while `sessionLogs.dailyPlanId` (hard FK, `references(DailyPlans,#id)`, with `PRAGMA foreign_keys=ON`) carry old ids → FK violation → full rollback. Compounded by the 30-day filter on `dailyPlans` export vs unfiltered `sessionLogs` → orphaned logs guarantee the violation. `rpeFeedback` logical FKs are silently corrupted. **Critical.** Fix: insert with explicit `id` values + cascade-filter child rows to only-included parents (or drop the 30-day filter).
- [x] [Review][Patch] enableBackup overwrites existing key without guard → orphans cloud backup [backup_repository_impl.dart:28-41] — `storeEncryptionKey(phrase)` overwrites unconditionally; re-enabling generates a new phrase and makes existing cloud backups permanently undecryptable. **High.** Add an existing-key guard.
- [x] [Review][Patch] Enabled-state not persisted [backup_repository_impl.dart:94-102; backup_settings.dart] — `isBackupEnabled()` is hardcoded `return false`; the toggle derives state only from transient BLoC state and never reads the stored key on load, so it shows OFF after reopening even when a key exists (and invites the destructive re-toggle above). **High.** Implement real key-presence check / load on bloc init.
- [x] [Review][Patch] Dead salt storage [backup_repository_impl.dart:36; backup_local_data_source.dart:97-103] — salt stored at enable time is never reused (`backup()` generates a fresh random salt each call; `loadKeySalt` has no callers). **Medium.** Remove or wire it.
- [x] [Review][Patch] Re-entrancy on backup/restore/toggle [backup_bloc.dart event handlers; backup_settings.dart] — default concurrent transformer; Restore button and toggle are not disabled while in-flight → concurrent restore transactions / multiple generated phrases. **Medium.** Add `droppable()` and in-flight guards.
- [x] [Review][Patch] downloadBackup error conflation + no offline restore guard [backup_remote_data_source.dart:801-810; backup_repository_impl.dart:72-92] — every error (network/auth/parse) rethrown as "Backup file not found" with raw exception appended; restore has no offline check (backup does). **Medium.** Distinguish not-found vs network; add offline handling for restore.
- [x] [Review][Patch] Storage RLS policy hardening [supabase/migrations/0002_storage_backup_bucket.sql] — `FOR ALL` with only a `USING` clause and no `TO authenticated`; relies on implicit `WITH CHECK` and NULL semantics for the access boundary. **Medium.** Add explicit `WITH CHECK` and `TO authenticated`.
- [x] [Review][Patch] backupComplete timestamp fabricated + queued/complete ambiguity [backup_bloc.dart; backup_repository_impl.dart:46-51] — emits `DateTime.now()` instead of `envelope.createdAt`; repository's offline path returns `Right(unit)` indistinguishable from a real upload, and the bloc's own offline check can disagree → success shown for a queued backup. **Low.** Make the connectivity decision once and return a distinct queued result.
- [x] [Review][Patch] schemaVersion never validated [e2e_backup_codec.dart / backup_envelope.dart] — read but unchecked; a future v2 envelope parses as v1 with a cryptic failure. **Low.** Add a version guard.
- [x] [Review][Patch] SyncQueue 'backup' entry not actionable [backup_local_data_source.dart:105-113] — `queueBackupTask` inserts `payload: '{}'` with no userId, so a future deferred-sync worker cannot reconstruct the target. **Low.**
- [x] [Review][Patch] decrypt RangeError mislabeled [e2e_backup_codec.dart] — ciphertext < 16 bytes triggers `sublist` RangeError, caught and reported as "wrong recovery phrase" (atomicity is safe). **Low.** Optional: distinguish corrupt-backup from wrong-phrase.

**Deferred:**

- [x] [Review][Defer] exportDriftSnapshot loads all tables into memory + double base64 [backup_local_data_source.dart:16-39] — no size bound / streaming. Spec mandates full-snapshot design and the dataset is bounded (30-day plans); deferred as a scale limitation, not in story scope.
