---
baseline_commit: 5c7340b
---

# Story 18.0: Auth/Backup Datasource Test Hardening

Status: done

## Story

As a developer,
I want a regression test for the Drift export→restore round-trip and a safety assertion that `signOut()` runs only after a successful (200) server response,
so that the critical restore-integrity path (Story 16.3 P1 fix) and the "no partial sign-out state" safety property (Story 16.4 AC2/AC4) are protected against regression before the social layer builds on `profiles`.

## Acceptance Criteria

**AC1 — Restore round-trip regression (closes 16.3 P1 coverage gap):**
Given a populated local database is exported and then restored from the export blob
When the restore round-trip completes
Then a regression test asserts the restored data is row-for-row equivalent to the original across all 7 tables, including FK relationships and all nullable/non-nullable fields; `flutter test` reports all tests green.

**AC2 — signOut-after-200 safety assertion (closes 16.4-D2):**
Given a sign-out is requested against the auth datasource
When the server response is non-200 (failure)
Then a test asserts `signOut()` does NOT run — no partial/orphaned local state is produced.
And when the server response is 200 (success), a test asserts `signOut()` IS called.

**AC3 — Zero regressions, ledger closed:**
Given the new tests are added
When the suite runs from `pulse_coach/`
Then `flutter test` reports all existing tests plus new tests green; `flutter analyze` reports 0 issues; the action-item-ledger marks `E16R-1` and `E17R-2` as `done`.

## Tasks / Subtasks

- [x] **Task 1 — Fix missing `installCohort` serialization in `BackupLocalDataSource` (AC1)**
  - [x] 1.1 In `lib/features/auth/data/datasources/backup_local_data_source.dart`, add `installCohort` to `_userProfileToMap()`:
    ```dart
    Map<String, dynamic> _userProfileToMap(UserProfileData r) => {
      'id': r.id,
      'fitnessGoal': r.fitnessGoal,
      'weeklySessionTarget': r.weeklySessionTarget,
      'intensityPreference': r.intensityPreference,
      'environmentPreference': r.environmentPreference,
      'availableTime': r.availableTime,
      'physicalConstraints': r.physicalConstraints,
      'onboardingCompleted': r.onboardingCompleted,
      'disclaimerAccepted': r.disclaimerAccepted,
      'installCohort': r.installCohort,     // ← ADD THIS
      'createdAt': r.createdAt.toIso8601String(),
      'updatedAt': r.updatedAt.toIso8601String(),
    };
    ```
  - [x] 1.2 Add `installCohort` to `_userProfileCompanionFromMap()`:
    ```dart
    UserProfileCompanion _userProfileCompanionFromMap(Map<String, dynamic> m) =>
        UserProfileCompanion(
          id: Value(m['id'] as int),
          fitnessGoal: Value(m['fitnessGoal'] as String?),
          weeklySessionTarget: Value(m['weeklySessionTarget'] as int),
          intensityPreference: Value(m['intensityPreference'] as String?),
          environmentPreference: Value(m['environmentPreference'] as String?),
          availableTime: Value(m['availableTime'] as String?),
          physicalConstraints: Value(m['physicalConstraints'] as String?),
          onboardingCompleted: Value(m['onboardingCompleted'] as bool),
          disclaimerAccepted: Value(m['disclaimerAccepted'] as bool),
          installCohort: Value(m['installCohort'] as String?),     // ← ADD THIS
          createdAt: Value(DateTime.parse(m['createdAt'] as String)),
          updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
        );
    ```
  - [x] 1.3 Run `flutter analyze` — 0 issues.

- [x] **Task 2 — Comprehensive restore round-trip test (AC1)**
  - [x] 2.1 Add test `18.0-RESTORE-001` to **`test/data/auth/backup_local_data_source_test.dart`** (append after the existing `16.3-DS-005b` test, inside the existing `restoreDriftSnapshot` group):
    ```dart
    test(
      '18.0-RESTORE-001: full round-trip — all 7 tables, FK relationships, and all fields preserved',
      () async {
        final now = DateTime.utc(2026, 6, 23, 12);
        // ── seed Sessions ────────────────────────────────────────────────────
        final sessionId = await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            sessionType: 'cardio',
            intensity: const Value(6),
            durationSeconds: const Value(900),
            abandoned: const Value(false),
            completedAt: Value(now),
            createdAt: now,
          ),
        );

        // ── seed DailyPlans (within 30-day filter window) ────────────────────
        final planId = await db.into(db.dailyPlans).insert(
          DailyPlansCompanion.insert(
            planDate: '2026-06-23',
            planJson: '{"sessions":[{"type":"cardio"}]}',
            generatedAt: now,
            createdAt: now,
            isCompleted: const Value(true),
          ),
        );

        // ── seed SessionLogs (FK → DailyPlans) ──────────────────────────────
        final logId = await db.into(db.sessionLogs).insert(
          SessionLogsCompanion.insert(
            dailyPlanId: planId,
            sessionIndex: 0,
            completedAt: now,
            createdAt: now,
            abandoned: const Value(false),
            elapsedSeconds: const Value(900),
            currentStepIndex: const Value(4),
          ),
        );

        // ── seed RpeFeedback (FK → Sessions AND SessionLogs) ─────────────────
        final rpeId = await db.into(db.rpeFeedback).insert(
          RpeFeedbackCompanion.insert(
            sessionId: sessionId,
            sessionLogId: Value(logId),
            rpeValue: 7,
            recordedAt: now,
          ),
        );

        // ── seed BanditState ─────────────────────────────────────────────────
        final banditId = await db.into(db.banditState).insert(
          BanditStateCompanion.insert(
            armWeightsJson: '{"cardio":0.4,"strength":0.3,"mobility":0.3}',
            updatedAt: now,
          ),
        );

        // ── seed BehavioralState ─────────────────────────────────────────────
        final bsId = await db.into(db.behavioralState).insert(
          BehavioralStateCompanion.insert(
            currentState: 'active',
            streakCount: const Value(5),
            restingHr: const Value(62),
            stepCount: const Value(8000),
            recordedAt: now,
            updatedAt: now,
          ),
        );

        // ── seed UserProfile with all fields including installCohort ─────────
        final profileId = await db.into(db.userProfile).insert(
          UserProfileCompanion.insert(
            fitnessGoal: const Value('cardio'),
            weeklySessionTarget: const Value(4),
            intensityPreference: const Value('medium'),
            environmentPreference: const Value('indoor'),
            availableTime: const Value('5-10'),
            physicalConstraints: const Value('none'),
            onboardingCompleted: const Value(true),
            disclaimerAccepted: const Value(true),
            installCohort: const Value('pre_v2'),  // grandfathering flag — must survive restore
            createdAt: now,
            updatedAt: now,
          ),
        );

        // ── Export ───────────────────────────────────────────────────────────
        final snapshot = await sut.exportDriftSnapshot();

        expect((snapshot['userProfile'] as List), hasLength(1));
        expect((snapshot['sessions'] as List), hasLength(1));
        expect((snapshot['dailyPlans'] as List), hasLength(1));
        expect((snapshot['sessionLogs'] as List), hasLength(1));
        expect((snapshot['rpeFeedback'] as List), hasLength(1));
        expect((snapshot['banditState'] as List), hasLength(1));
        expect((snapshot['behavioralState'] as List), hasLength(1));

        // ── Clear and restore ─────────────────────────────────────────────────
        await sut.restoreDriftSnapshot(snapshot);

        // ── Verify UserProfile — all fields including installCohort ───────────
        final profiles = await db.select(db.userProfile).get();
        expect(profiles, hasLength(1));
        final p = profiles.single;
        expect(p.id, equals(profileId));
        expect(p.fitnessGoal, equals('cardio'));
        expect(p.weeklySessionTarget, equals(4));
        expect(p.intensityPreference, equals('medium'));
        expect(p.environmentPreference, equals('indoor'));
        expect(p.availableTime, equals('5-10'));
        expect(p.physicalConstraints, equals('none'));
        expect(p.onboardingCompleted, isTrue);
        expect(p.disclaimerAccepted, isTrue);
        expect(p.installCohort, equals('pre_v2'),
            reason: 'installCohort (grandfathering flag) must survive restore');
        expect(p.createdAt, equals(now));
        expect(p.updatedAt, equals(now));

        // ── Verify Sessions ───────────────────────────────────────────────────
        final sessions = await db.select(db.sessions).get();
        expect(sessions, hasLength(1));
        final s = sessions.single;
        expect(s.id, equals(sessionId));
        expect(s.sessionType, equals('cardio'));
        expect(s.intensity, equals(6));
        expect(s.durationSeconds, equals(900));
        expect(s.abandoned, isFalse);
        expect(s.completedAt, equals(now));
        expect(s.createdAt, equals(now));

        // ── Verify DailyPlans ─────────────────────────────────────────────────
        final plans = await db.select(db.dailyPlans).get();
        expect(plans, hasLength(1));
        final pl = plans.single;
        expect(pl.id, equals(planId));
        expect(pl.planDate, equals('2026-06-23'));
        expect(pl.planJson, contains('cardio'));
        expect(pl.isCompleted, isTrue);
        expect(pl.generatedAt, equals(now));
        expect(pl.createdAt, equals(now));

        // ── Verify SessionLogs (FK integrity: dailyPlanId must match restored plan id) ──
        final logs = await db.select(db.sessionLogs).get();
        expect(logs, hasLength(1));
        final l = logs.single;
        expect(l.id, equals(logId));
        expect(l.dailyPlanId, equals(planId),  // FK must point to the SAME plan id
            reason: '16.3 P1: explicit id insertion preserves FK integrity');
        expect(l.sessionIndex, equals(0));
        expect(l.abandoned, isFalse);
        expect(l.elapsedSeconds, equals(900));
        expect(l.currentStepIndex, equals(4));
        expect(l.completedAt, equals(now));
        expect(l.createdAt, equals(now));

        // ── Verify RpeFeedback ────────────────────────────────────────────────
        final rpes = await db.select(db.rpeFeedback).get();
        expect(rpes, hasLength(1));
        final r = rpes.single;
        expect(r.id, equals(rpeId));
        expect(r.sessionId, equals(sessionId));
        expect(r.sessionLogId, equals(logId));
        expect(r.rpeValue, equals(7));
        expect(r.recordedAt, equals(now));

        // ── Verify BanditState ────────────────────────────────────────────────
        final bandits = await db.select(db.banditState).get();
        expect(bandits, hasLength(1));
        final b = bandits.single;
        expect(b.id, equals(banditId));
        expect(b.armWeightsJson, contains('cardio'));
        expect(b.updatedAt, equals(now));

        // ── Verify BehavioralState ────────────────────────────────────────────
        final bss = await db.select(db.behavioralState).get();
        expect(bss, hasLength(1));
        final bs = bss.single;
        expect(bs.id, equals(bsId));
        expect(bs.currentState, equals('active'));
        expect(bs.streakCount, equals(5));
        expect(bs.restingHr, equals(62));
        expect(bs.stepCount, equals(8000));
        expect(bs.recordedAt, equals(now));
        expect(bs.updatedAt, equals(now));
      },
    );
    ```
  - [x] 2.2 Run `flutter test test/data/auth/backup_local_data_source_test.dart` — all tests green including `18.0-RESTORE-001`.

- [x] **Task 3 — Add `@visibleForTesting` hooks to `AuthRemoteDataSource` (AC2)**
  - [x] 3.1 In `lib/features/auth/data/datasources/auth_remote_data_source.dart`, follow the `cloudCohortReader/Writer` pattern from `AuthRepositoryImpl`:
    ```dart
    import 'package:flutter/foundation.dart' show visibleForTesting;
    // (add this import alongside the existing imports)
    ```
  - [x] 3.2 Add hooks in the class and refactor `deleteAccount()`:
    ```dart
    @injectable
    class AuthRemoteDataSource {
      final SupabaseClientProvider _supabase;

      AuthRemoteDataSource(this._supabase) {
        invokeDeleteAccount = _defaultInvokeDeleteAccount;
        performSignOut = _defaultPerformSignOut;
      }

      /// Overridable in tests to stub the edge function call.
      /// Returns the HTTP status code of the delete_account_cascade response.
      @visibleForTesting
      late Future<int> Function() invokeDeleteAccount;

      /// Overridable in tests to assert signOut call behavior.
      @visibleForTesting
      late Future<void> Function() performSignOut;

      Future<int> _defaultInvokeDeleteAccount() async {
        final response =
            await _supabase.client.functions.invoke('delete_account_cascade');
        if (response.status != 200) {
          throw Exception('delete_account_cascade failed: ${response.data}');
        }
        return response.status;
      }

      Future<void> _defaultPerformSignOut() =>
          _supabase.client.auth.signOut();

      // ... existing methods ...

      Future<void> deleteAccount() async {
        await invokeDeleteAccount();  // throws if non-200
        await performSignOut();
      }
    ```
  - [x] 3.3 Remove the old `deleteAccount()` body (the one with `response.status` check inline).
  - [x] 3.4 Run `flutter analyze` — 0 issues.

- [x] **Task 4 — signOut-after-200 tests (AC2)**
  - [x] 4.1 Create `test/data/auth/auth_remote_data_source_test.dart`:
    ```dart
    // [18.0-DS-001..002] AuthRemoteDataSource.deleteAccount() signOut-safety assertions.
    // Uses @visibleForTesting hooks — no Supabase initialization required.
    import 'package:flutter_test/flutter_test.dart';
    import 'package:mockito/annotations.dart';
    import 'package:mockito/mockito.dart';
    import 'package:pulse_coach/core/cloud/supabase_client.dart';
    import 'package:pulse_coach/features/auth/data/datasources/auth_remote_data_source.dart';

    import 'auth_remote_data_source_test.mocks.dart';

    @GenerateMocks([SupabaseClientProvider])
    void main() {
      late MockSupabaseClientProvider mockSupabase;
      late AuthRemoteDataSource sut;

      setUp(() {
        mockSupabase = MockSupabaseClientProvider();
        sut = AuthRemoteDataSource(mockSupabase);
      });

      group('deleteAccount — signOut-after-200 safety', () {
        test(
          '18.0-DS-001: non-200 response → throws AND signOut is NOT called',
          () async {
            bool signOutCalled = false;
            // Override invokeDeleteAccount to simulate a non-200 response
            sut.invokeDeleteAccount = () async {
              throw Exception('delete_account_cascade failed: server error');
            };
            sut.performSignOut = () async {
              signOutCalled = true;
            };

            expect(
              () => sut.deleteAccount(),
              throwsA(isA<Exception>()),
            );
            // Give any async work a chance to run
            await Future<void>.delayed(Duration.zero);
            expect(
              signOutCalled,
              isFalse,
              reason: '16.4-D2: signOut must NOT run when server returns non-200',
            );
          },
        );

        test(
          '18.0-DS-002: 200 response → deleteAccount completes AND signOut IS called',
          () async {
            bool signOutCalled = false;
            sut.invokeDeleteAccount = () async => 200;
            sut.performSignOut = () async {
              signOutCalled = true;
            };

            await sut.deleteAccount();

            expect(
              signOutCalled,
              isTrue,
              reason: 'signOut must be called after successful (200) server response',
            );
          },
        );
      });
    }
    ```
  - [x] 4.2 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` to generate `auth_remote_data_source_test.mocks.dart`.
  - [x] 4.3 Run `flutter test test/data/auth/auth_remote_data_source_test.dart` — both tests green.

- [x] **Task 5 — Update action-item-ledger (AC3)**
  - [x] 5.1 In `_bmad-output/implementation-artifacts/action-item-ledger.md`, find the row for `E16R-1` and update its status to `done (Story 18.0)`. Update the row for `E17R-2` to `done (Story 18.0)`.
  - [x] 5.2 Update the `last_updated` line and Category A snapshot comment.

- [x] **Task 6 — Full suite validation (AC3)**
  - [x] 6.1 Run `flutter test` from `pulse_coach/` — all tests green (baseline 984 + new tests).
  - [x] 6.2 Run `flutter analyze` from `pulse_coach/` — 0 issues (lib/ and test/; wear/ has 89 pre-existing warnings unrelated to this story).

### Review Findings

_Code review 2026-06-23 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). Outcome: 0 decision-needed, 0 patch, 4 defer, 7 dismissed. All 3 ACs PASS — `test/data/auth/` green (51 tests), `flutter analyze lib/ test/` clean, ledger E16R-1/E17R-2 marked done._

- [x] [Review][Defer] Backup restore lacks format-version guard and defensive parsing of legacy/malformed blobs — non-nullable casts (`as bool`/`as int`), `DateTime.parse`, and `snapshot[key] as List` throw on absent/null keys; deletes run before inserts in the restore transaction, so a malformed/old blob can wipe the DB then abort [backup_local_data_source.dart:restoreDriftSnapshot] — deferred, pre-existing (not introduced by this story; only the nullable `installCohort` field was added)
- [x] [Review][Defer] Real Supabase `deleteAccount` path (`_defaultInvokeDeleteAccount` status-check + `functions.invoke`) has no direct test — 18.0-DS-001/002 override both seams, so the shipped status≠200 branch is uncovered [auth_remote_data_source.dart:_defaultInvokeDeleteAccount] — deferred, by-design seam pattern (consistent with `cloudCohortReader/Writer`)
- [x] [Review][Defer] Account deleted server-side but local session retained if `performSignOut()` throws after a 200 — no rollback/retry of local sign-out [auth_remote_data_source.dart:deleteAccount] — deferred, pre-existing and out of AC2 scope (original code had identical behavior)
- [x] [Review][Defer] `signOut()` duplicates the `_defaultPerformSignOut` one-liner — two sources of truth that could drift [auth_remote_data_source.dart:signOut] — deferred, minor cleanup

## Dev Notes

### Critical: `installCohort` Missing from Backup Serialization — Discovered Bug (Task 1)

`UserProfile.installCohort` (added in DB schema v9) is **not** serialized in `_userProfileToMap()` and **not** deserialized in `_userProfileCompanionFromMap()` in `backup_local_data_source.dart`. This means any user with `installCohort = 'pre_v2'` (the Pro subscription grandfathering flag set in Story 17.2) will **lose that value** on restore — incorrectly losing their grandfathered Pro access. **This is a data-loss bug.** Task 1 adds both the serialization fix and the regression test for it. The dev agent must NOT omit Task 1.

### Critical: `@visibleForTesting` Hook Pattern (Task 3)

The project already uses this pattern in `AuthRepositoryImpl`:
```dart
// In AuthRepositoryImpl constructor:
cloudCohortReader = _defaultCloudCohortReader;
cloudCohortWriter = _defaultCloudCohortWriter;

// As fields:
@visibleForTesting
late Future<String?> Function(String userId) cloudCohortReader;
```
Follow this **exactly** for `AuthRemoteDataSource`. The `late` fields without initializer are assigned in the constructor body. Tests then directly override the field:
```dart
sut.invokeDeleteAccount = () async { throw Exception('non-200'); };
sut.performSignOut = () async { signOutCalled = true; };
```
No mockito, no `@GenerateMocks` for the datasource test. The `MockSupabaseClientProvider` in the test is only needed for the `AuthRemoteDataSource` constructor (unused in the actual test paths for tasks 18.0-DS-001/002 since all live calls are overridden).

### Critical: `deleteAccount()` Refactor Preserves Existing Error Behavior

The existing `deleteAccount()` throws `Exception('delete_account_cascade failed: ${response.data}')` on non-200. After the refactor, this throw remains inside `_defaultInvokeDeleteAccount()`. From the caller's perspective (the repository and the test), the behavior is identical: a non-200 response throws an exception. The test for 18.0-DS-001 uses the `invokeDeleteAccount` hook that throws directly — same observable behavior.

### Critical: Test `18.0-DS-001` Timing

The test uses `throwsA` matcher on an async call — use `expectLater` + `throwsA` for cleaner assertion:
```dart
// Preferred pattern for async throws:
await expectLater(
  sut.deleteAccount(),
  throwsA(isA<Exception>()),
);
expect(signOutCalled, isFalse, reason: '16.4-D2: ...');
```
Do NOT use `expect(() => sut.deleteAccount(), throwsA(...))` for async — it won't actually await the future.

### Critical: `MockSupabaseClientProvider` Already Generated

`MockSupabaseClientProvider` is already in `test/data/auth/auth_repository_impl_test.mocks.dart` (from `@GenerateMocks([AuthRemoteDataSource, SupabaseClientProvider])`). The new test file adds its own `@GenerateMocks([SupabaseClientProvider])` → `auth_remote_data_source_test.mocks.dart`. Both files coexist; no conflict.

### Critical: Restore Test Uses Same In-Memory DB

`18.0-RESTORE-001` does **not** create a second DB. After `restoreDriftSnapshot()`, the same `db` is queried. `restoreDriftSnapshot()` already clears all tables in a transaction before inserting — the test relies on this behavior (which is the P1 fix itself: clear-then-insert with explicit IDs).

### Critical: DateTime Precision in Drift In-Memory Tests

Drift stores `DateTime` as integer timestamps (milliseconds). The `now` seed value should use UTC with no sub-millisecond precision. Use `DateTime.utc(2026, 6, 23, 12)` (no microseconds). When comparing: `expect(p.createdAt, equals(now))` — Drift stores/retrieves with millisecond precision so this passes when `now` has no microseconds.

### Critical: `PRAGMA foreign_keys = ON` is Set in `beforeOpen`

The `AppDatabase.migration.beforeOpen` sets `PRAGMA foreign_keys = ON`. This means the in-memory DB used in tests ALSO enforces FK constraints. `18.0-RESTORE-001` will fail (FK violation) if:
- `dailyPlanId` in `sessionLogs` doesn't match a restored `dailyPlans.id`  
- `sessionId` in `rpeFeedback` doesn't match a restored `sessions.id`
- `sessionLogId` in `rpeFeedback` doesn't match a restored `sessionLogs.id`

The 16.3 P1 fix ensures explicit `id` values are used in `_*CompanionFromMap`, so restored rows keep their original IDs and FKs remain valid.

### Critical: `build_runner` NOT Needed for Task 1, 2, 5

No freezed/injectable/drift schema changes. Only `build_runner` is needed for Task 4 (mock generation for the new test file). Run it once from `pulse_coach/` after creating `auth_remote_data_source_test.dart`.

### Critical: No Widget Tests, No Bloc Tests Needed

This story is purely data-layer test hardening. No Bloc events, no UI widgets, no route changes. Do not add widget tests.

### Critical: `import 'package:flutter/foundation.dart' show visibleForTesting;` in Datasource

`AuthRemoteDataSource` currently imports only `dart:convert`, `package:google_sign_in/...`, `package:pulse_coach/core/cloud/supabase_client.dart`, etc. Adding `package:flutter/foundation.dart` for the `@visibleForTesting` annotation is the only new import in production code. This file is in `lib/features/auth/data/datasources/` (data layer — Flutter imports are allowed here per clean architecture).

### Project Structure — Files Changed

```
lib/features/auth/data/datasources/
  auth_remote_data_source.dart         # MODIFIED (hooks + deleteAccount refactor)
  backup_local_data_source.dart        # MODIFIED (installCohort serialization fix)

test/data/auth/
  backup_local_data_source_test.dart   # MODIFIED (+18.0-RESTORE-001)
  auth_remote_data_source_test.dart    # NEW
  auth_remote_data_source_test.mocks.dart  # GENERATED

_bmad-output/implementation-artifacts/
  action-item-ledger.md               # MODIFIED (E16R-1, E17R-2 → done)
```

### References

- Epics 18.0 ACs: `_bmad-output/planning-artifacts/epics.md` line 2372
- Action-item-ledger E16R-1/E17R-2: `_bmad-output/implementation-artifacts/action-item-ledger.md`
- Story 16.3 P1 fix details: `_bmad-output/implementation-artifacts/16-3-e2e-encrypted-backup-and-restore.md` (Review Findings, first finding)
- `@visibleForTesting` hook pattern: `lib/features/auth/data/repositories/auth_repository_impl.dart` lines 25–31
- `BackupLocalDataSource` serialization: `lib/features/auth/data/datasources/backup_local_data_source.dart` lines 134–161
- `UserProfile` table schema (includes `installCohort`): `lib/core/database/tables/user_profile_table.dart`
- Existing restore tests (16.3-DS-005/005b): `test/data/auth/backup_local_data_source_test.dart` lines 226–326
- `AuthRemoteDataSource.deleteAccount()` current shape: `lib/features/auth/data/datasources/auth_remote_data_source.dart` lines 71–78
- DB schema v9 (installCohort migration): `lib/core/database/app_database.dart` lines 118–142
- `AppDatabase.forTesting()` constructor: `lib/core/database/app_database.dart` line 58
- Test pattern for in-memory Drift DB: `test/data/auth/backup_local_data_source_test.dart` lines 15–28

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Task 2: `SessionsCompanion.insert` — `abandoned` field uses `Value<bool>` (has a default), while `intensity`/`durationSeconds` are required primitives. Story spec used `const Value(...)` wrappers for all three; corrected to match actual Drift schema.
- Task 2: DateTime round-trip — Drift stores as ms-since-epoch and reconstructs in local timezone; `equals(now)` UTC vs local comparison fails. Switched all DateTime asserts to `.millisecondsSinceEpoch` comparison.

### Completion Notes List

- ✅ Task 1: Fixed `installCohort` data-loss bug in `backup_local_data_source.dart` — added field to both `_userProfileToMap()` and `_userProfileCompanionFromMap()`. Users with `installCohort='pre_v2'` (grandfathered Pro subscribers) no longer lose that flag on restore.
- ✅ Task 2: Added `18.0-RESTORE-001` — full 7-table round-trip test with FK integrity verification and all fields including `installCohort`. All 12 backup tests green.
- ✅ Task 3: Refactored `AuthRemoteDataSource.deleteAccount()` using `@visibleForTesting` hook pattern (`invokeDeleteAccount` + `performSignOut` late fields). Matches existing `cloudCohortReader/Writer` pattern in `AuthRepositoryImpl`.
- ✅ Task 4: Created `auth_remote_data_source_test.dart` with `18.0-DS-001` (non-200 → throws, no signOut) and `18.0-DS-002` (200 → signOut called). Used `expectLater` + `throwsA` for correct async assertion. Both tests green.
- ✅ Task 5: Updated `action-item-ledger.md` — `E16R-1` and `E17R-2` marked `done (Story 18.0)`. Category A snapshot updated to 1/5 active.
- ✅ Task 6: 987 tests green (984 baseline + 3 new). `lib/` and `test/` at 0 analyze issues.

### File List

- `pulse_coach/lib/features/auth/data/datasources/backup_local_data_source.dart` (MODIFIED — installCohort serialization fix)
- `pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart` (MODIFIED — @visibleForTesting hooks + deleteAccount refactor)
- `pulse_coach/test/data/auth/backup_local_data_source_test.dart` (MODIFIED — +18.0-RESTORE-001)
- `pulse_coach/test/data/auth/auth_remote_data_source_test.dart` (NEW)
- `pulse_coach/test/data/auth/auth_remote_data_source_test.mocks.dart` (GENERATED)
- `_bmad-output/implementation-artifacts/action-item-ledger.md` (MODIFIED — E16R-1, E17R-2 → done)

## Change Log

- 2026-06-23: Story 18.0 implemented — fixed `installCohort` data-loss bug in backup serialization; added 18.0-RESTORE-001 full round-trip test (all 7 tables, FK integrity, all fields); refactored `AuthRemoteDataSource.deleteAccount()` with `@visibleForTesting` hooks; added 18.0-DS-001/002 signOut-after-200 safety assertions; closed E16R-1 and E17R-2 in action-item-ledger. 987 tests green, lib/test analyze clean.
