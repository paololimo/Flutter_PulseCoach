# Coverage Traceability Matrix — Epic 16
**Generated:** 2026-06-22  
**Scope:** Epic 16 — Stories 16.1, 16.2, 16.3, 16.4 (Supabase Auth, E2E Backup, Account Deletion/Export)  
**Oracle mode:** `formal_requirements` (30 ACs across 4 story files)  
**Oracle confidence:** high  
**Test suite:** `flutter test` 932/932 PASS | `flutter analyze` 0 issues  
**Epic 16 dedicated tests:** 52 total

---

## Test Inventory

| Test File | Count | Status | Test IDs |
|-----------|-------|--------|----------|
| `test/data/auth/e2e_backup_codec_test.dart` | 5 | committed | codec-001..005 |
| `test/data/auth/auth_repository_impl_test.dart` | 18 | untracked (automate 2026-06-22) | 16.1-REPO-001..009c, 16.4-REPO-001..004 |
| `test/data/auth/backup_repository_impl_test.dart` | 13 | untracked (automate 2026-06-22) | 16.3-REPO-001..008d |
| `test/data/auth/backup_local_data_source_test.dart` | 12 | untracked (automate 2026-06-22) | 16.3-DS-001..005b |
| `test/bloc/auth/delete_account_bloc_test.dart` | 2 | committed | delete-bloc-001..002 |
| `test/bloc/auth/export_data_cubit_test.dart` | 2 | committed | export-cubit-001..002 |
| **Total** | **52** | | |

---

## Traceability Matrix

### Story 16.1 — Supabase Backend Initialization & Cloud Client Setup

| # | Acceptance Criterion | Priority | Coverage | Evidence |
|---|---------------------|----------|----------|----------|
| AC1 | Supabase CLI initializes project with `supabase/config.toml` | P2 | WAIVED | Infra/CLI artifact; not testable in unit/integration suite |
| AC2 | `0001_profiles_auth.sql` migration applies without error | P2 | WAIVED | DB migration artifact; runtime-only verification |
| AC3 | `SupabaseClientProvider` singleton injectable, no compile error | P1 | FULL | `flutter build apk --debug` + 932 tests pass; DI graph verified by compilation |
| AC4 | Free-core functionality unaffected (FR56) | P0 | FULL | 932/932 tests pass (861 pre-existing + 71 new) |
| AC5 | Supabase SDK initializes before any consumer (ARCH-init order) | P1 | FULL | `flutter test` passes; `main.dart` initialization order verified by build |
| AC6 | No regression vs. pre-epic baseline | P0 | FULL | `flutter test 932/932 PASS`; `flutter analyze 0 issues` |

**Story 16.1 summary:** 4/4 testable ACs = FULL; 2 ACs WAIVED (infra)

---

### Story 16.2 — Email / Apple / Google Sign-In and Sign-Out

| # | Acceptance Criterion | Priority | Coverage | Evidence |
|---|---------------------|----------|----------|----------|
| AC1 | `SignInSheet` widget renders provider buttons | P2 | NONE | Widget test absent; UI-layer gap |
| AC2 | `AuthBloc` sealed state hierarchy (initial/loading/authenticated/unauthenticated/unconfirmed/error) exists | P1 | FULL | State classes verified by compilation + story implementation artifact; `delete_account_bloc_test` exercises `loading→unauthenticated` + `loading→error` paths |
| AC3 | `SignInWithAppleRequested` → `authenticated` or `error` state | P1 | PARTIAL | 16.1-REPO-001/002: data layer fully covered (Right/Left); AuthBloc handler has no dedicated blocTest |
| AC4 | `SignInWithGoogleRequested` → `authenticated` or `error` state | P1 | PARTIAL | 16.1-REPO-003/004: data layer covered; AuthBloc handler missing blocTest |
| AC5 | `SignInWithEmailRequested` → `authenticated` or `error` state | P1 | PARTIAL | 16.1-REPO-005/006: data layer covered; AuthBloc handler missing blocTest |
| AC6 | `SignUpWithEmailRequested` → `unconfirmed` (null user) or `authenticated` or `error` | P1 | PARTIAL | 16.1-REPO-007/007b/007c: data layer covered; AuthBloc handler missing blocTest |
| AC7 | `SignOutRequested` → `unauthenticated` state | P1 | FULL | 16.1-REPO-008/008b + `delete_account_bloc_test` success path emits `unauthenticated` |
| AC8 | Auth failure → `error` state, never crash (ARCH26) | P0 | FULL | All repo failure paths return `Left(AuthFailure)`; `delete_account_bloc_test` error path + repo 008b confirm failure→error pattern |
| AC9 | `AppStarted` → `authenticated` if session exists, else `unauthenticated` | P1 | PARTIAL | 16.1-REPO-009/009b/009c: `getSignedInUser` data layer fully covered; AuthBloc `AppStarted` handler has no blocTest |
| AC10 | No regression | P0 | FULL | `flutter test` PASS after Story 16.2 |

**Story 16.2 summary:** 4 FULL, 5 PARTIAL, 1 NONE

---

### Story 16.3 — E2E-Encrypted Backup and Restore

| # | Acceptance Criterion | Priority | Coverage | Evidence |
|---|---------------------|----------|----------|----------|
| AC1 | `BackupPage` widget renders enable/disable/backup/restore controls | P2 | NONE | Widget test absent; UI-layer gap |
| AC2 | Recovery phrase generated, stored in secure storage, never uploaded (NFR28) | P0 | FULL | 16.3-REPO-001: new phrase generated + stored + enabled; `codec-005` (no-plaintext): phrase never appears in envelope JSON; 16.3-DS-001: `storeEncryptionKey` |
| AC3 | Backup payload encrypted; only ciphertext in envelope (NFR28) | P0 | FULL | `codec-005`: no plaintext in envelope JSON; 16.3-REPO-007: encrypt→upload path; `codec-002`: encrypt/decrypt round-trip |
| AC4 | Restore downloads envelope, decrypts, repopulates Drift (FR57) | P0 | FULL | `codec-002`: round-trip decrypt; 16.3-REPO-008b: restore→`Right(unit)`; 16.3-DS-005: `restoreDriftSnapshot` round-trip |
| AC5 | Wrong phrase → `BackupDecryptionFailure`, no partial write | P0 | FULL | `codec-003`: wrong phrase throws `BackupDecryptionFailure`; 16.3-REPO-008c: wrong phrase→Left(BackupDecryptionFailure); 16.3-DS-005b: partial-write prevention |
| AC6 | Backup/restore delegates through repository correctly (FR57, ARCH layers) | P1 | FULL | 16.3-REPO-001..008d: all BackupRepositoryImpl paths; 16.3-DS-001..005b: all BackupLocalDataSource paths |
| AC7 | No regression | P0 | FULL | `flutter test` PASS after Story 16.3 |

**Story 16.3 summary:** 5/5 testable P0+P1 ACs = FULL; 1 AC NONE (widget)

---

### Story 16.4 — In-App Account Deletion and Data Export

| # | Acceptance Criterion | Priority | Coverage | Evidence |
|---|---------------------|----------|----------|----------|
| AC1 | Delete/export dialogs render on `AccountPage` | P2 | NONE | Widget test absent; UI-layer gap |
| AC2 | `AccountDeletionRequested` cascades deletion server-side (FR77, NFR30) | P0 | FULL | 16.4-REPO-001: datasource success→`Right(unit)`; `delete_account_bloc_test` success: `[loading, unauthenticated]` |
| AC3 | Post-deletion navigation clears session and routes to sign-in | P2 | NONE | Widget/navigation test absent |
| AC4 | Deletion failure → error state, no partial local state change | P0 | FULL | 16.4-REPO-002: datasource throws→`Left(AuthFailure)`; `delete_account_bloc_test` error: `[loading, error]` |
| AC5 | `ExportDataRequested` calls edge function, returns JSON blob | P1 | FULL | 16.4-REPO-003: datasource success→`Right(json)`; `export_data_cubit_test` success path |
| AC6 | Export failure → cubit error state, no crash | P1 | FULL | 16.4-REPO-004: datasource throws→`Left(AuthFailure)`; `export_data_cubit_test` failure path |
| AC7 | No regression | P0 | FULL | `flutter test 932/932` PASS |

**Story 16.4 summary:** 4/4 testable P0+P1 ACs = FULL; 2 ACs NONE (widget/nav)

---

## Coverage Summary by Priority

### P0 — 12/12 = 100% FULL ✅

All security, correctness, and regression ACs fully covered.

### P1 — 7/12 = 58% FULL ❌

| AC | Status | Gap |
|----|--------|-----|
| 16.1-AC3 SupabaseClientProvider injectable | FULL | — |
| 16.1-AC5 SDK init order | FULL | — |
| 16.2-AC2 AuthBloc state hierarchy | FULL | — |
| 16.2-AC3 SignInWithApple BLoC path | PARTIAL | No blocTest for handler |
| 16.2-AC4 SignInWithGoogle BLoC path | PARTIAL | No blocTest for handler |
| 16.2-AC5 SignInWithEmail BLoC path | PARTIAL | No blocTest for handler |
| 16.2-AC6 SignUpWithEmail BLoC path | PARTIAL | No blocTest for handler |
| 16.2-AC7 SignOut → unauthenticated | FULL | — |
| 16.2-AC9 AppStarted BLoC path | PARTIAL | No blocTest for handler |
| 16.3-AC6 Backup/restore delegation | FULL | — |
| 16.4-AC5 ExportData success | FULL | — |
| 16.4-AC6 ExportData failure | FULL | — |

### P2 — informational

2 WAIVED (infra/CLI), 4 NONE (widget/navigation layer)

---

## Overall

| Priority | FULL | PARTIAL | NONE | WAIVED | FULL% |
|----------|------|---------|------|--------|-------|
| P0 (12) | 12 | 0 | 0 | 0 | **100%** ✅ |
| P1 (12) | 7 | 5 | 0 | 0 | **58%** ❌ |
| P2 (6) | 0 | 0 | 4 | 2 | n/a |
| **Total (30)** | **19** | **5** | **4** | **2** | **68%** |

---

## Gate Decision: FAIL

| Criterion | Threshold | Actual | Status |
|-----------|-----------|--------|--------|
| P0 FULL% | 100% | 100% | ✅ PASS |
| P1 FULL% | ≥80% | 58% | ❌ FAIL |

**Rationale:** P0 is clean — all 12 critical security/correctness/regression ACs are fully covered. The FAIL originates entirely in P1: 5 AuthBloc sign-in event-handler paths (Story 16.2 AC3/AC4/AC5/AC6/AC9) have complete data-layer coverage but no `blocTest` verifying state emission sequences from the BLoC. The data layer correctness is proven; the BLoC orchestration layer is not independently verified.

**Remediation:** Add `pulse_coach/test/bloc/auth/auth_bloc_sign_in_test.dart` with ~7 `blocTest` cases:
1. `AppStarted` + existing session → `[loading, authenticated(user)]`
2. `AppStarted` + no session → `[loading, unauthenticated]`
3. `SignInWithAppleRequested` success → `[loading, authenticated(user)]`
4. `SignInWithAppleRequested` failure → `[loading, error(message)]`
5. `SignInWithGoogleRequested` success → `[loading, authenticated(user)]`
6. `SignInWithEmailRequested` success → `[loading, authenticated(user)]`
7. `SignUpWithEmailRequested` + null user → `[loading, unconfirmed]`

Adding these 7 tests raises P1 to 12/12 = 100%, reopening the gate as PASS.

**Gate re-open condition:** `auth_bloc_sign_in_test.dart` committed + `flutter test` green + P1 re-verified ≥ 80%.
