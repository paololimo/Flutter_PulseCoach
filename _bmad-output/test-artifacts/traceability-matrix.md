---
gateDecision: PASS
stepsCompleted:
  - step-01-load-context
  - step-02-discover-tests
  - step-03-map-criteria
  - step-04-analyze-gaps
  - step-05-gate-decision
lastStep: step-05-gate-decision
lastSaved: '2026-06-29'
scope: Epic 20 — Co-Located Shared Sessions (v2.4b), Stories 20.1–20.5
coverageBasis: acceptance_criteria
oracleResolutionMode: formal_requirements
oracleConfidence: high
oracleSources:
  - _bmad-output/implementation-artifacts/20-1-shared-session-creation-join-code-card-and-lobby-navigation.md
  - _bmad-output/implementation-artifacts/20-2-group-constraint-resolver-deterministic-group-plan-generation.md
  - _bmad-output/implementation-artifacts/20-3-co-location-join-flow-momentary-non-blocking-confirmation.md
  - _bmad-output/implementation-artifacts/20-4-synchronized-session-start-and-shared-in-session-view.md
  - _bmad-output/implementation-artifacts/20-5-per-participant-rpe-and-protective-state-social-suppression.md
externalPointerStatus: not_used
tempCoverageMatrixPath: /private/tmp/claude-501/-Users-paololimonta-Development-Flutter-PulseCoach/4c5227c7-507f-4e83-b12b-1b7dc45173a4/scratchpad/tea-trace-coverage-matrix-epic20.json
totalACs: 39
totalTests: 1240
epicBaseline: 1222
teaAdditions: 18
---

# Traceability Report — Epic 20: Co-Located Shared Sessions (v2.4b)

**Generated:** 2026-06-29  
**Evaluator:** Paolo  
**Oracle:** Formal acceptance criteria from 5 implementation artifact files (all `Status: done`)  
**Test baseline:** 1240 tests passing (1222 post-Epic-20 baseline + 18 TEA additions on 2026-06-29)

---

## Gate Decision: PASS

**Rationale:** P0 coverage is 100% (no P0 criteria), P1 coverage is 100% (22/22, target: 90%), and overall coverage is 90% (35/39, minimum: 80%). All 4 partial-coverage items are P2 (non-blocking).

### Gate Criteria

| Criterion | Required | Actual | Status |
|---|---|---|---|
| P0 coverage | 100% | 100% (0/0) | MET |
| P1 coverage | ≥ 90% | 100% (22/22) | MET |
| P1 coverage minimum | ≥ 80% | 100% | MET |
| Overall coverage | ≥ 80% | 90% (35/39) | MET |

---

## Coverage Summary

| Priority | Total | FULL | PARTIAL | NONE | Coverage % |
|---|---|---|---|---|---|
| P0 | 0 | — | — | — | 100% |
| P1 | 22 | 22 | 0 | 0 | **100%** |
| P2 | 17 | 13 | 4 | 0 | 76% |
| P3 | 0 | — | — | — | 100% |
| **Total** | **39** | **35** | **4** | **0** | **90%** |

---

## Test Inventory

| Category | Files | Tests |
|---|---|---|
| Unit (bloc/cubit/use-case/domain) | 10 | 71 |
| Component (widget) | 4 | 16 |
| **Epic 20 total (traced)** | **15** | **87** |
| Full suite (1240 passing) | — | 1240 |

**Commitment status:** 4 files from TEA automation run (2026-06-29) are NOT committed — see Open Finding F-20-001.

---

## Traceability Matrix

### Story 20.1 — Shared Session Creation, JoinCodeCard and Lobby Navigation

| AC ID | Description | Priority | Coverage | Test IDs |
|---|---|---|---|---|
| 20.1-AC1 | Pro user creates shared session (FR68, ARCH22) | P1 | FULL | 20.1-CUBIT-002..004, 20.1-REPO-001..002† |
| 20.1-AC2 | JoinCodeCard renders with join code + QR + refresh (UX-DR29) | P1 | FULL | join_code_card_widget_test, 20.1-BLOC-004 |
| 20.1-AC3 | "Aggiorna codice" refreshes code without new session (UX-DR29) | P2 | FULL | 20.1-BLOC-003, 20.1-REPO-003..004† |
| 20.1-AC4 | 5-minute wait message (UX-DR29) | P2 | PARTIAL | shared_session_lobby_page_test (partial) |
| 20.1-AC5 | Cancel before anyone joins (FR68) | P1 | FULL | 20.1-BLOC-001..002, 20.1-BLOC-006, 20.3-REPO-005..006† |
| 20.1-AC6 | Zero regressions | P2 | FULL | Suite-wide (1240 passing) |

†Tests in uncommitted/untracked files — see F-20-001.

**Coverage heuristics:**
- Auth/authz negative paths: all 3 repository error paths tested (REPO-002, REPO-004, REPO-006)
- Error paths: cancel-before-join, delete-fails-still-cancelled, refresh-guard all covered
- UI journey: lobby widget tests cover JoinCodeCard render and cancel dialog entry point

---

### Story 20.2 — GroupConstraintResolver — Deterministic Group Plan Generation

| AC ID | Description | Priority | Coverage | Test IDs |
|---|---|---|---|---|
| 20.2-AC1 | Deterministic group rules — min/union/lowest (FR70, ARCH24) | P1 | FULL | 20.2-GCR-001..017 |
| 20.2-AC2 | Per-user FR9 safety rules applied via pre-computed cap (FR70) | P1 | FULL | 20.2-GCR-004..005 (AtRisk → group ceiling lowered) |
| 20.2-AC3 | Exhaustive test coverage ≥ 15 tests (ARCH24) | P1 | FULL | 20.2-GCR-001..017 (17 tests, all cases listed in AC met) |
| 20.2-AC4 | Zero Flutter imports in resolver/profile/constraint files (ARCH24) | P2 | FULL | flutter analyze verified at story completion |
| 20.2-AC5 | Zero regressions | P2 | FULL | Suite-wide (1183 → 1240 passing) |

**Coverage heuristics:**
- Error paths: empty-list guard (GCR-016) tested → ArgumentError
- Edge cases: single participant, all-same, heterogeneous, symmetric, all-null cap all covered
- Happy path completeness: all 4 fields (intensityCeiling, fitnessLevel, movementExclusions, durationMinutes) verified independently with boundary values

---

### Story 20.3 — Co-Location Join Flow — Momentary Non-Blocking Confirmation

| AC ID | Description | Priority | Coverage | Test IDs |
|---|---|---|---|---|
| 20.3-AC1 | Join flow entry point — button in _FriendsList (FR69) | P1 | FULL | 20.3-WIDGET-001..002 |
| 20.3-AC2 | Successful join inserts participant row, navigates to lobby (FR69, ARCH22) | P1 | FULL | 20.3-CUBIT-002..004, 20.3-REPO-007†, 20.3-JOIN-001..002 |
| 20.3-AC3 | Session-already-started guard (FR69) | P1 | FULL | 20.3-CUBIT-005, 20.3-REPO-009†, 20.3-JOIN-003 |
| 20.3-AC4 | Invalid/not-found join code error handling (FR69) | P1 | FULL | 20.3-CUBIT-006, 20.3-REPO-008† |
| 20.3-AC5 | Co-location check runs once on lobby entry (FR69, NFR33) | P2 | FULL | 20.3-BLOC-001 |
| 20.3-AC6 | Co-location boolean computed for followers (FR69, NFR33) | P2 | FULL | 20.3-BLOC-002..003 |
| 20.3-AC7 | Co-location check is non-blocking (FR69, NFR33) | P2 | FULL | 20.3-BLOC-004..005 (GPS fail → coLocated=null, lobby proceeds) |
| 20.3-AC8 | Soft visual cue shown only for co-located followers (NFR33) | P2 | PARTIAL | shared_session_lobby_page_test covers lobby states; no dedicated coLocated-true/false widget assertion |
| 20.3-AC9 | Coordinates never persisted in Supabase (NFR33) | P1 | FULL | 20.3-BLOC-001..005 (verify only trackPresence receives lat/lon, no DB call) |
| 20.3-AC10 | Zero regressions | P2 | FULL | Suite-wide (1200 → 1240 passing) |

†Tests in uncommitted/untracked files — see F-20-001.

**Coverage heuristics:**
- Error paths: SessionAlreadyStartedFailure pass-through (REPO-009†), generic exception (REPO-008†), GPS failure fallback all covered
- Auth/authz: E18R-CB2 compliance — no raw failure.message surfaced to UI; tested by CUBIT-006
- Privacy AC (AC9): coordinates-in-presence-only contract verified by BLOC co-location tests

---

### Story 20.4 — Synchronized Session Start and Shared InSessionView

| AC ID | Description | Priority | Coverage | Test IDs |
|---|---|---|---|---|
| 20.4-AC1 | Simultaneous inSession transition on session_started (FR71, UX-DR29) | P1 | FULL | 20.4-BLOC-001 |
| 20.4-AC2 | Follower step sync from broadcast (NFR31) | P1 | FULL | 20.4-BLOC-002 |
| 20.4-AC3 | Participant count badge (UX-DR29) | P2 | FULL | 20.4-WIDGET-001..002 |
| 20.4-AC4 | Host drives timer and broadcasts step advances (FR71) | P1 | FULL | 20.4-BLOC-003 |
| 20.4-AC5 | Host render path reuses InSessionView (UX-DR29) | P1 | FULL | 20.4-WIDGET-003..004 |
| 20.4-AC6 | Follower haptic on step transition (NFR4) | P2 | FULL | 20.4-WIDGET-005 |
| 20.4-AC7 | Follower local clock ticks between broadcasts (UX-DR29) | P2 | PARTIAL | Timer.periodic behavior partially verified by widget state; no fakeAsync tick test |
| 20.4-AC8 | sessionEnded → RPE navigation (FR72) | P1 | FULL | 20.4-BLOC-004 |
| 20.4-AC9 | Dropped-participant notice remains (NFR31) | P2 | FULL | 20.4-WIDGET-006..007 |
| 20.4-AC10 | Zero regressions | P2 | FULL | Suite-wide (1210 → 1240 passing) |

**Coverage heuristics:**
- Error paths: sessionEnded with empty armKey placeholder handled in bloc tests
- UI state: host path (InSessionView + badge), follower path (haptic + timer), dropped-participant banner all widget-tested
- Integration: HostStepAdvanced → broadcast flow covered by BLOC-003..004

---

### Story 20.5 — Per-Participant RPE and Protective-State Social Suppression

| AC ID | Description | Priority | Coverage | Test IDs |
|---|---|---|---|---|
| 20.5-AC1 | RPE flows to per-user bandit with valid arm key (FR72) | P1 | FULL | 20.5-BLOC-001..003, 20.5-WIDGET-002 |
| 20.5-AC2 | AtRisk/Recovering: no shared-session CTA on Today screen (UX-DR31) | P1 | FULL | 20.5-TODAY-001..004 |
| 20.5-AC3 | AtRisk/Recovering: leaderboard rank guard for Epic 21 (UX-DR31) | P2 | PARTIAL | _suppressSharedSessionCta function tested (TODAY-001..004); Epic 21 CTA not yet built |
| 20.5-AC4 | GroupConstraintResolver AtRisk cap applied to group plan (FR70) | P1 | FULL | 20.5-BLOC-002, 20.5-BLOC-005..007† |
| 20.5-AC5 | Group plan params distributed via broadcast (FR71) | P1 | FULL | 20.5-BLOC-001, 20.5-BLOC-004, 20.5-GW-009..013† |
| 20.5-AC6 | Steps generated from plan params, never empty in in-session view (UX-DR29) | P1 | FULL | 20.5-WIDGET-001, 20.5-WIDGET-003 |
| 20.5-AC7 | Proper armKey flows through to RPE navigation (FR72) | P1 | FULL | 20.5-BLOC-003, 20.5-WIDGET-002 |
| 20.5-AC8 | Zero regressions | P2 | FULL | Suite-wide (1240 passing) |

†Tests in uncommitted/modified files — see F-20-001.

**Coverage heuristics:**
- Error paths: DB-read failure in _onStartTapped → fail-safe to LOW (BLOC-007†); unknown behavioral state string → LOW (BLOC-008†)
- Safety-critical: AtRisk cap → group intensity LOW verified (BLOC-002, BLOC-005†)
- Type guards: parseBroadcast wrong-type fields → fallback defaults (GW-010..012†)
- Suppression contract: suppression=true for atRisk AND recovering, false for active (TODAY-001..003)

---

## Gap Analysis

### Partial-Coverage Items (P2, Non-Blocking)

| AC ID | Root Cause | Recommended Action |
|---|---|---|
| 20.1-AC4 | `_LobbyViewState._waitTimer` uses real `Timer(5min)` — hard to exercise without `fakeAsync` in a widget test | Add widget test with `fakeAsync` + fake timer; assert `sharedSessionNoOneYet` text appears after 5-minute advance |
| 20.3-AC8 | Dedicated assertion for `Icons.location_on` / `coLocated=null` hiding absent from current test suite | Add widget assertion in `shared_session_lobby_page_test.dart`: render with `coLocated=true` (follower), `coLocated=null`, and host paths |
| 20.4-AC7 | `Timer.periodic(1s)` in follower path not tickable in current unit tests | Add `fakeAsync` widget test: advance 1 second, verify displayed elapsed increments |
| 20.5-AC3 | AC is a process/future-work guarantee for Epic 21; Epic 21 CTA doesn't yet exist | Satisfied by TODAY-001..004 which test the guard function; verify compliance when Epic 21 adds any Today screen CTA |

### Coverage Heuristics

| Heuristic | Status | Notes |
|---|---|---|
| Endpoint coverage | N/A | Feature uses Supabase Realtime (broadcast/presence), not REST endpoints; not applicable |
| Auth negative-path tests | Present | Repository error paths tested for all 4 repository methods |
| Error-path coverage | Present | Network failures, DB errors, GPS failures, type-guard fallbacks all tested |
| UI journey coverage | Present | Widget tests cover join entry point, lobby states, in-session views, suppression |
| UI state coverage | Partial | 4 PARTIAL items above (timer, coLocated cue, local clock, future guard) |

---

## Open Findings

### F-20-001: TEA Test Additions Not Committed (Non-Blocking)

**Severity:** Medium  
**Status:** Open  
**Discovered:** 2026-06-29 (TEA automate run)

The TEA automation run on 2026-06-29 added 18 tests across 4 files. All 18 tests pass (verified: 1240 total). However, none are committed to version control:

| File | Git Status | Tests Added | Story Coverage |
|---|---|---|---|
| `test/bloc/shared_session/shared_session_20_5_bloc_test.dart` | M (modified) | BLOC-005..008 (4) | 20.5-AC4 (AtRisk/recovering/DB-error/unknown-state) |
| `test/core/cloud/realtime_gateway_test.dart` | M (modified) | GW-009..013 (5) | 20.5-AC5 (parseBroadcast type-guard coverage) |
| `test/data/social/shared_session_repository_impl_test.dart` | ?? (untracked) | REPO-001..009 (9) | 20.1-AC1/AC3/AC5, 20.3-AC2/AC3/AC4 |
| `test/data/social/shared_session_repository_impl_test.mocks.dart` | ?? (untracked) | generated mocks | — |

**Action required:** Run `git add` on all 4 files and commit before opening Epic 21 sprint. Pattern mirrors F-19-001 from Epic 19.

---

## Next Actions

1. **[HIGH] Commit uncommitted TEA tests** — `git add` the 4 uncommitted/untracked test files listed in F-20-001 and commit with message `test(epic-20): commit TEA automation additions`.
2. **[MEDIUM] Close 20.1-AC4 gap** — Add `fakeAsync` widget test for the 5-minute lobby wait message.
3. **[MEDIUM] Close 20.3-AC8 gap** — Add dedicated co-located visual cue widget assertions (three cases: coLocated=true/follower, coLocated=null, isHost=true).
4. **[LOW] Close 20.4-AC7 gap** — Add `fakeAsync` follower timer tick test.
5. **[LOW] Run /bmad:tea:test-review** on the Epic 20 test suite to assess test quality.

---

## Gate Decision Summary

```
✅ GATE: PASS — Epic 20 Co-Located Shared Sessions v2.4b

📊 Coverage Analysis:
- P0 Coverage: 100% (Required: 100%) → MET
- P1 Coverage: 100% (PASS target: 90%, minimum: 80%) → MET
- Overall Coverage: 90% (Minimum: 80%) → MET

✅ Decision Rationale:
P0 coverage is 100% (no P0 criteria), P1 coverage is 100% (22/22, target: 90%),
and overall coverage is 90% (35/39, minimum: 80%).
All 4 partial-coverage items are P2 non-blocking.

⚠️ Critical Gaps: 0
⚠️ Open Findings: 1 (F-20-001 — uncommitted TEA tests, non-blocking)

📂 Full Report: _bmad-output/test-artifacts/traceability-matrix.md
📂 Machine-readable: _bmad-output/test-artifacts/traceability/e2e-trace-summary.json
```
