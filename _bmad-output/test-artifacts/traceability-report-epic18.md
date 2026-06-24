# Traceability Report — Epic 18: Social Graph & Friends

**Generated:** 2026-06-24 (aggiornato post-gap-resolution)
**Gate Decision:** PASS ✅
**Test Suite at Close:** 1089 / 1089 tests passing ✅

---

## Summary

| Metrica | Valore |
|---|---|
| ACs totali | 35 |
| FULL | 32 (91%) |
| PARTIAL | 3 (advisory, P2) |
| NONE | 0 |
| Epic 18 tests | 105 in 23 file |
| Staged test files | 11 file — da committare |

### Priority Coverage

| Priority | Covered / Total | % | Status |
|---|---|---|---|
| P0 | 4/4 | **100%** | ✅ |
| P1 | 24/24 | **100%** | ✅ PASS |
| P2 | 4/7 | 57% | advisory |

---

## Story 18.0 — Auth/Backup Datasource Test Hardening

**Close count:** 987 tests | **New:** +3

| AC | Priority | Coverage | Notes |
|---|---|---|---|
| AC1: Restore round-trip (7 tables, FK, installCohort) | P1 | FULL | `18.0-RESTORE-001` |
| AC2: signOut safety (non-200 → skip, 200 → call) | P1 | FULL | `18.0-DS-001`, `18.0-DS-002` |
| AC3: Zero regressions; E16R-1/E17R-2 closed | P1 | FULL | 987 tests green |

---

## Story 18.1 — Username Handle Setup and VisibilityTierSelector

**Close count:** 999 tests | **New:** +22 (committed) +3 CUBIT staged + **+3 HandleSetupSection widget staged**

| AC | Priority | Coverage | Notes |
|---|---|---|---|
| AC1: HandleSetupSection visible/skip when no handle | P1 | **FULL** | DS/BLOC + `18.1-WIDGET-NEW-001..003` in `handle_setup_section_test.dart` ⚠️staged |
| AC2: Handle uniqueness (23505 → SocialHandleTakenFailure) | P1 | FULL | `18.1-REPO-004`, `18.1-BLOC-003` |
| AC3: VisibilityTierSelector (Privato / Solo amici; PATCH; Cubit) | **P0** | FULL | 7 test (WIDGET+CUBIT+BLOC) |
| AC4: RLS private-by-default (`profiles_select_own`) | **P0** | FULL | Migration artifact |
| AC5: Social tab @ index 3 (`Icons.people`) | P2 | PARTIAL | Route wired; no AppShell tab position test — advisory |
| AC6: Zero regressions | P1 | FULL | 999 tests green |

---

## Story 18.2 — Friend Request Flow

**Close count:** 1028 tests | **New:** +22 committed + **+8 REPO staged + +2 SocialPage staged + +2 QrCode staged**

| AC | Priority | Coverage | Notes |
|---|---|---|---|
| AC1: FriendsScreen (Pro gate, search, QR, sections) | P1 | **FULL** | FriendRow (5) + `18.2-WIDGET-NEW-001..002` in `social_page_test.dart` ⚠️staged |
| AC2: Search by handle (match/no-match/filter) | P1 | FULL | DS-001..002, REPO-001..002, BLOC-003..004 |
| AC3: Send request (pending; "Richiesta inviata") | P1 | FULL | DS-005, BLOC-005..006 |
| AC4: Accept request (→ accepted; re-fetch) | P1 | FULL | DS-006, BLOC-007 |
| AC5: Decline request (delete; disappears) | P1 | FULL | DS-007, BLOC-008 |
| AC6: Remove friend (dialog confirm; delete) | P1 | FULL | DS-008, BLOC-009 |
| AC7: QR screen (QrImageView; null handle message) | P2 | **FULL** | `18.2-WIDGET-NEW-003..004` in `qr_code_screen_test.dart` ⚠️staged |
| AC8: Migration `0003_friendships.sql` | P2 | FULL | Migration artifact |
| AC9: Zero regressions | P1 | FULL | 1028 tests green |

---

## Story 18.3 — Activity Feed with Light Reactions

**Close count:** 1045 tests | **New:** +17 committed + **+8 REPO staged + +3 MiniSummary staged**

| AC | Priority | Coverage | Notes |
|---|---|---|---|
| AC1: Share toggle (Pro-only; default OFF; opt-in) | P1 | **FULL** | DS/REPO + `18.3-WIDGET-NEW-001..003` in `mini_summary_page_test.dart` ⚠️staged(M) |
| AC2: No biometric in feed row (NFR29) | **P0** | FULL | `18.3-DS-001`: payload check esplicito |
| AC3: Feed renders ActivityFeedCard | P1 | FULL | DS-002, REPO-001..002, BLOC-001..002, WIDGET-001 |
| AC4: Light reaction (RPC; scale animation; no count) | P1 | FULL | 9 test (DS-003, REPO-007..008, BLOC-003..004b, WIDGET-003..005) |
| AC5: Revoke share (delete; disappears) | P1 | FULL | DS-004..004b, BLOC-005..006, WIDGET-002 |
| AC6: Migration `0005_activity_feed.sql` | P2 | FULL | Migration artifact |
| AC7: Social tab 2-tab (Amici+Feed) | P2 | PARTIAL | FeedBloc integrato; no TabBar structure test — advisory |
| AC8: Pro gate invariato | P1 | FULL | Ereditato da 18.2-WIDGET-NEW-001 |
| AC9: Zero regressions | P1 | FULL | 1045 tests green |

---

## Story 18.4 — Friends Progress Comparison

**Close count:** 1056 tests | **New:** +10 committed + **+4 REPO staged**

| AC | Priority | Coverage | Notes |
|---|---|---|---|
| AC1: ComparisonRow per friends_only friend; no RPE/HR | P1 | FULL | DS-001, REPO-001, BLOC-001, WIDGET-002..003 |
| AC2: Own entry highlighted (`surfaceContainerHigh`) | P2 | FULL | WIDGET-001 |
| AC3: Private friends invisibili (SECURITY DEFINER; RLS) | **P0** | FULL | Migration artifact + DS/REPO tests |
| AC4: Empty state (own entry + messaggio) | P1 | FULL | DS-002, BLOC-004 |
| AC5: Pro gate invariato | P1 | FULL | Ereditato da 18.2-WIDGET-NEW-001 |
| AC6: RPC `get_friends_progress_this_week` | P1 | FULL | DS-001..003, REPO-001..004 |
| AC7: SocialPage 3-tab (Amici/Feed/Confronto) | P2 | PARTIAL | ProgressComparisonBloc integrato; no 3-tab structure test — advisory |
| AC8: Zero regressions | P1 | FULL | 1056 tests green |

---

## Test Inventory (Epic 18)

```
Story 18.0:  3 tests  (1 RESTORE + 2 DS)
Story 18.1: 25 tests  (5 DS + 7 REPO + 4 BLOC + 3 CUBIT⚠️ + 3 WIDGET + 3 WIDGET-NEW⚠️)
Story 18.2: 34 tests  (8 DS + 8 REPO⚠️ + 9 BLOC + 5 WIDGET + 2 WIDGET-NEW⚠️ + 2 QR⚠️)
Story 18.3: 29 tests  (6 DS + 8 REPO⚠️ + 7 BLOC + 5 WIDGET + 3 WIDGET-NEW⚠️)
Story 18.4: 14 tests  (3 DS + 4 REPO⚠️ + 4 BLOC + 3 WIDGET)
           ───────────
Total:     105 tests

Unit (DS+REPO+BLOC+CUBIT): ~82
Component (WIDGET):        ~23
E2E/Integration:            0

⚠️ = staged in git (11 file totali — da committare)
```

---

## Gaps Summary

| Gap | AC | Priority | Coverage | Risk |
|---|---|---|---|---|
| AppShell Social tab position test | 18.1-AC5 | P2 | PARTIAL | LOW — advisory |
| Social 2-tab TabBar structure test | 18.3-AC7 | P2 | PARTIAL | LOW — advisory |
| Social 3-tab TabBar structure test | 18.4-AC7 | P2 | PARTIAL | LOW — advisory |

Tutti i gap P0 e P1 sono FULL. Gate: **PASS**.

---

## Pre-Merge Checklist

- [ ] `git add test/bloc/visibility_cubit_test.dart` (3 tests)
- [ ] `git add test/widget/handle_setup_section_test.dart` (3 tests)
- [ ] `git add test/data/social/friends_repository_impl_test.dart test/data/social/friends_repository_impl_test.mocks.dart` (8 tests)
- [ ] `git add test/widget/social_page_test.dart` (2 tests)
- [ ] `git add test/widget/qr_code_screen_test.dart` (2 tests)
- [ ] `git add test/data/social/feed_repository_impl_test.dart test/data/social/feed_repository_impl_test.mocks.dart` (8 tests)
- [ ] `git add test/widget/mini_summary_page_test.dart` (+3 nuovi test nel file)
- [ ] `git add test/data/social/progress_comparison_repository_impl_test.dart test/data/social/progress_comparison_repository_impl_test.mocks.dart` (4 tests)
- [ ] `git commit` con messaggio appropriato
- [ ] Conferma `flutter test` → 1089/1089 ✅ post-commit
