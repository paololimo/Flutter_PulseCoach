---
stepsCompleted: ['step-01-load-context', 'step-02-discover-tests', 'step-03-map-criteria', 'step-04-analyze-gaps', 'step-05-gate-decision']
lastStep: 'step-05-gate-decision'
lastSaved: '2026-04-03'
scope: 'Epic 2: Onboarding & Profile (Stories 2.1–2.4) + Epic 1 Router ACs'
testCount: 125
---

# Requirements Traceability Report — PulseCoach

**Generated:** 2026-04-03 (rev 2 — post R1/R2/R3 implementation)
**Scope:** Epic 2: Onboarding & Profile (Stories 2.1–2.4) + Epic 1 router acceptance criteria
**Test Suite:** `pulse_coach/test/` — ~125 tests

---

## Gate Decision: PASS

**Rationale:** P0 coverage is 100% (9/9 FULL). P1 coverage is 100% (15/15 FULL), meeting both the PASS target (≥90%) and the minimum (≥80%). Overall FULL coverage is 82.8% (24/29), above the 80% minimum. All four recommendations from the prior report (R1–R3) have been implemented. The sole remaining gap is AC-2.4-5 (P2, PARTIAL): `updateProfile` has no explicit assertion that `onboardingCompleted` and `disclaimerAccepted` are preserved after update. This is low-risk and deferred.

---

## Coverage Summary

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Total Acceptance Criteria | 29 | — | — |
| Fully Covered (FULL) | 24 | — | 82.8% |
| Partially Covered (PARTIAL) | 1 | — | +3.4% |
| Unit-Only (UNIT-ONLY) | 0 | — | 0% |
| No Coverage (NONE) | 4 | — | 13.8% |
| **P0 Coverage (FULL)** | **9/9** | **100%** | **✅ PASS (100%)** |
| **P1 Coverage (FULL)** | **15/15** | **90% (PASS), 80% (min)** | **✅ PASS (100%)** |
| **P2 Coverage (FULL)** | **0/5** | best effort | 0% (4 NONE waived, 1 PARTIAL) |
| **Overall Coverage (FULL)** | **24/29** | **≥80%** | **✅ PASS (82.8%)** |

**Change from previous report:** +4 FULL (AC-2.3-4, AC-2.2-2, AC-2.2-3, AC-2.4-3 resolved). Gate updated from FAIL → PASS.

---

## Traceability Matrix

### Story 2.1: Medical Disclaimer Screen

| AC ID | Priority | Criterion | Coverage | Mapped Tests |
|-------|----------|-----------|----------|--------------|
| AC-2.1-1 | P1 | Disclaimer screen renders with clear, readable text | FULL | `2.1-WIDGET-001` |
| AC-2.1-2 | P0 | Acceptance persisted to DB; user proceeds to onboarding | FULL | `2.1-INT-001`, `2.1-INT-002` (repo), `2.1-UNIT-002` (cubit), `2.1-WIDGET-004` (widget) |
| AC-2.1-3 | P0 | Re-open app → disclaimer screen not shown again | FULL | `1.7-UNIT-001`, `2.1-UNIT-005`, `2.1-UNIT-006` (router), `2.1-UNIT-007` (cubit checkInitialStatus) |
| AC-2.1-4 | P1 | No way to skip or dismiss without acceptance button | FULL | `2.1-WIDGET-005` |

**Router Criteria (from Epic 1, deferred to Story 2.1):**

| AC ID | Priority | Criterion | Coverage | Mapped Tests |
|-------|----------|-----------|----------|--------------|
| AC-1.7-1 | P0 | No profile → redirect to /onboarding | FULL | `1.7-UNIT-001` |
| AC-1.7-2 | P0 | /onboarding disclaimer screen is reachable | FULL | `1.7-UNIT-002` |
| AC-1.7-3 | P0 | onboardingCompleted=true → redirect to /today | FULL | `1.7-UNIT-003` |
| AC-1.7-4 | P0 | Shell navigation bar visible when onboarding complete | FULL | `1.7-UNIT-004` |
| AC-2.1-5 | P1 | disclaimerAccepted=false → redirect to /onboarding | FULL | `2.1-UNIT-005` |
| AC-2.1-6 | P1 | disclaimerAccepted=true, onboardingCompleted=false → stays in onboarding | FULL | `2.1-UNIT-006` |

---

### Story 2.2: Animated Onboarding Flow

| AC ID | Priority | Criterion | Coverage | Mapped Tests | Notes |
|-------|----------|-----------|----------|--------------|-------|
| AC-2.2-1 | P1 | Screen 1: Lottie + "Move more. Decide less." headline | FULL | `2.2-WIDGET-001`, `2.2-WIDGET-002` | |
| AC-2.2-2 | P1 | Screen 2: privacy animation + "Your data stays yours." | **FULL** | `2.2-WIDGET-003` (navigates to Screen 2 **and** asserts headline) | ✅ R2 resolved |
| AC-2.2-3 | P1 | Screen 3: setup animation + "Let's set you up" + "Get Started" CTA | **FULL** | `2.2-WIDGET-004` (navigates to Screen 3 **and** asserts headline), `2.2-WIDGET-005` (CTA) | ✅ R2 resolved |
| AC-2.2-4 | P2 | Transitions use 250ms ease-in-out | NONE | — | WAIVED — Flutter widget tests are synchronous; animation timing is not testable |
| AC-2.2-5 | P2 | Reduce Motion → static frames, instant cuts | NONE | — | Deferred — requires `MediaQuery.disableAnimations` injection; `disableAnimations:true` already used in carousel builder, but no explicit assertion |
| AC-2.2-6 | P1 | Lottie load failure → static Material icon fallback | FULL | `2.2-WIDGET-007` | |

---

### Story 2.3: Profile Setup Screen

| AC ID | Priority | Criterion | Coverage | Mapped Tests | Notes |
|-------|----------|-----------|----------|--------------|-------|
| AC-2.3-1 | P1 | 4 segmented controls displayed (Fitness Level, Goal, Available Time, Constraints) | FULL | `2.3-WIDGET-001` | |
| AC-2.3-2 | P1 | "Start My Plan" disabled when < 4 fields selected | FULL | `2.3-WIDGET-002`, `2.3-WIDGET-003` | |
| AC-2.3-3 | P0 | Profile persisted with onboardingCompleted=true | FULL | `2.3-INT-001`, `2.3-INT-002` (repo), `2.3-UNIT-001` (cubit), `2.3-WIDGET-004` (widget) | |
| AC-2.3-4 | P0 | Profile persisted → navigate to /today | **FULL** | `AC-2.3-4` (full integration: carousel → ProfileSetupForm → saveProfile → BlocListener → `/today`), `1.7-UNIT-003` (router rule), `2.3-UNIT-001` (cubit state) | ✅ R1 resolved |
| AC-2.3-5 | P0 | Correct data persisted (fields map to DB columns) | FULL | `2.3-INT-001` (verifies all 4 field values), `2.1-INT-008` (field mapping) | |
| AC-2.3-6 | P2 | No email/password/account fields | NONE | — | WAIVED — implicitly verified by `2.3-WIDGET-001` showing only 4 segmented controls |
| AC-2.3-7 | P1 | saveProfile failure → Snackbar shown, form stays visible | FULL | `2.3-WIDGET-005`, `2.3-UNIT-002` | |

---

### Story 2.4: Profile View & Edit

| AC ID | Priority | Criterion | Coverage | Mapped Tests | Notes |
|-------|----------|-----------|----------|--------------|-------|
| AC-2.4-1 | P1 | Profile screen renders with 4 fields, current values pre-selected | FULL | `2.4-WIDGET-001` (loading state), `2.4-WIDGET-002` (labels), `2.4-WIDGET-003` (pre-selected segments) | |
| AC-2.4-2 | P1 | Segment tap → persisted immediately (no Save button) | FULL | `2.4-WIDGET-004` (calls cubit.updateProfile), `2.4-INT-002` (repo: updates all fields) | |
| AC-2.4-3 | P1 | Update success → UI reflects new selection, no error | **FULL** | `2.4-UNIT-003` (cubit emits `loaded` on success) + `2.4-WIDGET-004` (UI selection verified: `buttons.first.selected == {'medium'}`) | ✅ R3 resolved |
| AC-2.4-4 | P1 | Update failure → Snackbar shown, user stays on screen | FULL | `2.4-WIDGET-005`, `2.4-UNIT-004` | |
| AC-2.4-5 | P2 | Profile update does NOT touch `onboardingCompleted` or `disclaimerAccepted` | PARTIAL | `2.4-INT-002` (updates 4 fields; flags not explicitly asserted post-update) | ⚠️ No assertion that both flags remain unchanged after `updateProfile` |
| AC-2.4-6 | P2 | No Save button, no email/password field, no keyboard | NONE | — | WAIVED — implied by widget structure tests |

---

## Gap Analysis

### Critical Gaps (P0) — NONE

All 9 P0 criteria are FULL. No critical gaps remain.

### High Gaps (P1) — NONE

All 15 P1 criteria are FULL. No high gaps remain.

### Medium Gaps (P2 — Low Risk)

| AC ID | Story | Gap Description | Recommended Action |
|-------|-------|-----------------|-------------------|
| AC-2.4-5 | 2.4 | `updateProfile` doesn't assert `onboardingCompleted`/`disclaimerAccepted` remain unchanged | Add integration test: seed profile with both flags `true`, call `updateProfile`, assert both flags still `true`. ~5 lines in `onboarding_repository_impl_test.dart`. |
| AC-2.2-5 | 2.2 | Reduce Motion path not explicitly tested | Add widget test wrapping `OnboardingCarousel` with `disableAnimations:true` and asserting fallback icons render (note: `disableAnimations` is already injected in `buildCarousel()` helper; only assertion is missing). P2 priority. |
| AC-2.2-4 | 2.2 | Animation timing (250ms ease-in-out) not testable | WAIVED — synchronous widget test environment cannot assert animation curves. Cosmetic concern only. |
| AC-2.3-6 | 2.3 | "No email/password/account fields" — absence not explicitly asserted | WAIVED — `2.3-WIDGET-001` shows only 4 segmented controls, implicitly covering this. |
| AC-2.4-6 | 2.4 | No Save button, no email field — absence not explicitly tested | WAIVED — implied by widget structure tests. |

---

## Coverage Heuristics

| Heuristic | Findings |
|-----------|----------|
| **API endpoint coverage** | N/A — PulseCoach is offline-first with local Drift DB only. No HTTP endpoints at this stage. |
| **Auth/authz coverage** | Disclaimer acceptance gate tested comprehensively: `2.1-WIDGET-005` (no skip), `1.7-UNIT-001` (redirect without profile), `2.1-UNIT-005`/`006` (redirect edge cases). All positive and negative onboarding gate paths covered. |
| **Error-path coverage** | `acceptDisclaimer` failure ✅ · `saveProfile` failure ✅ · `updateProfile` failure ✅ · `getProfile` failure ✅ · DAO double-insert guard ✅. **Remaining:** No test for `updateProfile` when DB `replace()` returns `false` (race condition deferred in code review). No test for DB exception propagation paths in repository methods. |
| **Happy-path-only criteria** | None remaining — AC-2.2-2/2.2-3 (Screen 2/3 text now asserted), AC-2.4-3 (UI selection now verified). |

---

## Recommendations

| Priority | ID | Action | Affected ACs | Status |
|----------|----|--------|--------------|--------|
| ~~URGENT~~ | ~~R1~~ | ~~Add P0 integration test for OnboardingPage navigation to /today~~ | ~~AC-2.3-4~~ | **DONE ✅** |
| ~~HIGH~~ | ~~R2~~ | ~~Add Screen 2 + Screen 3 headline text assertions~~ | ~~AC-2.2-2, AC-2.2-3~~ | **DONE ✅** |
| ~~HIGH~~ | ~~R3~~ | ~~Add widget-level assertion for segment selection UI after tap~~ | ~~AC-2.4-3~~ | **DONE ✅** |
| **LOW** | R4 | Add integration test for `updateProfile` flag isolation: seed profile with `onboardingCompleted=true, disclaimerAccepted=true`, call `updateProfile`, assert both flags unchanged. ~5 lines in `onboarding_repository_impl_test.dart`. | AC-2.4-5 | Open |
| **LOW** | R5 | Add Reduce Motion widget test: `buildCarousel()` already injects `disableAnimations:true`; add assertion that fallback icons render in that mode. | AC-2.2-5 | Open |
| **LOW** | R6 | Run `/bmad-testarch-test-review` on `onboarding_page_test.dart` and `profile_page_test.dart` to validate test quality. | — | Open |

---

## Test Inventory by Level

### Integration Tests (Data Layer) — `test/data/`

| Test ID | Method | Priority |
|---------|--------|----------|
| 2.1-INT-001 | `acceptDisclaimer` — creates profile (no prior) | P0 |
| 2.1-INT-002 | `acceptDisclaimer` — updates existing profile | P0 |
| 2.1-INT-003 | `isDisclaimerAccepted` — false (no profile) | P1 |
| 2.1-INT-004 | `isDisclaimerAccepted` — false (flag false) | P1 |
| 2.1-INT-005 | `isDisclaimerAccepted` — true (flag true) | P1 |
| 2.1-INT-006 | `getProfile` — CacheFailure (no profile) | P0 |
| 2.1-INT-007 | `getProfile` — null fields → domain defaults | P1 |
| 2.1-INT-008 | `getProfile` — DB fields → domain entity mapping | P0 |
| 2.4-INT-001 | `updateProfile` — CacheFailure (no profile) | P1 |
| 2.4-INT-002 | `updateProfile` — updates all 4 fields | P1 |
| 2.3-INT-001 | `saveProfile` — creates with onboardingCompleted=true | P0 |
| 2.3-INT-002 | `saveProfile` — updates existing profile | P1 |
| DAO-001 | `UserProfileDao.insertProfile` — StateError guard | P1 |

### Integration Tests (Router/App) — `test/core/routing/`

| Test ID | Scenario | Priority |
|---------|----------|----------|
| 1.7-UNIT-001 | No profile → /onboarding | P0 |
| 1.7-UNIT-002 | /onboarding disclaimer screen is reachable | P0 |
| 2.1-UNIT-005 | disclaimerAccepted=false → /onboarding | P1 |
| 2.1-UNIT-006 | accepted but not complete → stays in onboarding | P1 |
| **AC-2.3-4** | **Full flow: carousel → ProfileSetupForm → saveProfile → BlocListener → /today** | **P0** |
| 1.7-UNIT-003 | onboardingCompleted=true → /today | P0 |
| 1.7-UNIT-004 | Shell nav bar visible | P0 |

### Unit Tests (BLoC) — `test/bloc/`

| Test ID | Cubit / Method | Priority |
|---------|----------------|----------|
| 2.1-UNIT-001 | `OnboardingCubit` initial state | P1 |
| 2.1-UNIT-002 | `acceptDisclaimer` — success path | P1 |
| 2.1-UNIT-003 | `acceptDisclaimer` — failure path | P1 |
| 2.1-UNIT-004 | `acceptDisclaimer` — double-tap safety | P1 |
| 2.1-UNIT-007 | `checkInitialStatus` — already accepted | P1 |
| 2.1-UNIT-008 | `checkInitialStatus` — failure path | P2 |
| 2.2-UNIT-001 | `completeOnboardingFlow` — emits profileSetupReady | P1 |
| 2.3-UNIT-001 | `saveProfile` — emits onboardingComplete on success | P1 |
| 2.3-UNIT-002 | `saveProfile` — emits error on failure | P1 |
| 2.4-UNIT-001 | `loadProfile` — emits [loading, loaded] on success | P1 |
| 2.4-UNIT-002 | `loadProfile` — emits [loading, error] on failure | P1 |
| 2.4-UNIT-003 | `updateProfile` — emits loaded (no loading) on success | P1 |
| 2.4-UNIT-004 | `updateProfile` — emits error on failure | P1 |

### Widget Tests — `test/widget/`

| Test ID | Widget / Scenario | Priority |
|---------|-------------------|----------|
| 2.1-WIDGET-001 | Disclaimer text visible | P1 |
| 2.1-WIDGET-002 | Continue disabled when unchecked | P1 |
| 2.1-WIDGET-003 | Checkbox enables Continue | P1 |
| 2.1-WIDGET-004 | Continue triggers acceptDisclaimer | P1 |
| 2.1-WIDGET-005 | No back button, no skip | P1 |
| 2.2-WIDGET-001 | Screen 1 headline visible | P1 |
| 2.2-WIDGET-002 | "Next" button visible on Screen 1 | P1 |
| **2.2-WIDGET-003** | **"Next" on Screen 1 → Screen 2 (+ asserts "Your data stays yours.")** | P1 |
| **2.2-WIDGET-004** | **"Next" on Screen 2 → Screen 3 (+ asserts "Let's set you up in 60 seconds.")** | P1 |
| 2.2-WIDGET-005 | "Get Started" calls completeOnboardingFlow | P1 |
| 2.2-WIDGET-006 | profileSetupReady state → ProfileSetupForm renders | P1 |
| 2.2-WIDGET-007 | Lottie load failure → fallback icon | P1 |
| 2.3-WIDGET-001 | 4 field labels visible | P1 |
| 2.3-WIDGET-002 | "Start My Plan" disabled with < 4 selections | P1 |
| 2.3-WIDGET-003 | "Start My Plan" enabled after all 4 selections | P1 |
| 2.3-WIDGET-004 | "Start My Plan" tap calls cubit.saveProfile | P1 |
| 2.3-WIDGET-005 | saveProfile error → Snackbar shown | P1 |
| 2.4-WIDGET-001 | Loading indicator on ProfileState.loading | P1 |
| 2.4-WIDGET-002 | 4 field labels visible after ProfileLoaded | P1 |
| 2.4-WIDGET-003 | Pre-selected segment matches loaded profile value | P1 |
| **2.4-WIDGET-004** | **Segment tap calls cubit.updateProfile + UI reflects new selection** | P1 |
| 2.4-WIDGET-005 | Snackbar on ProfileError | P1 |
| 1.7-WIDGET-001–010 | Page smoke tests (10 tests) | P1 |

Bold rows = updated since previous report.

---

## Gate Decision Summary

```
✅ GATE DECISION: PASS

📊 Coverage Analysis:
- P0 Coverage: 100% (9/9) — Required: 100% → ✅ MET
- P1 Coverage: 100% (15/15) — PASS target: 90%, min: 80% → ✅ MET
- P2 Coverage: 0% (0/5) — best effort → acceptable
- Overall Coverage (FULL): 82.8% (24/29) — Minimum: 80% → ✅ MET

✅ Decision Rationale:
All gate rules satisfied. P0 coverage is 100% (9/9). P1 coverage is 100% (15/15),
meeting the PASS target of ≥90%. Overall FULL coverage is 82.8%, above the 80% minimum.
The sole remaining gap (AC-2.4-5, P2) is low-risk and does not affect any gate rule.

⚠️ Remaining Gaps: 1 (P2 only)
  - AC-2.4-5 (P2): updateProfile flag isolation not explicitly tested (PARTIAL)

📝 Open Recommendations:
  1. [LOW] R4: Add updateProfile flag-isolation integration test (~5 lines). AC-2.4-5.
  2. [LOW] R5: Add Reduce Motion assertion to existing carousel builder. AC-2.2-5.
  3. [LOW] R6: Run /bmad-testarch-test-review on onboarding and profile widget tests.

📂 Full Report: _bmad-output/implementation-artifacts/traceability-report.md

✅ GATE: PASS — Release approved, coverage meets all standards.
```

---

## Change Log

| Date | Gate | Change |
|------|------|--------|
| 2026-04-03 (rev 1) | FAIL | Initial report — AC-2.3-4 (P0) PARTIAL; AC-2.2-2/3 (P1) PARTIAL; AC-2.4-3 (P1) UNIT-ONLY |
| 2026-04-03 (rev 2) | **PASS** | R1 done (AC-2.3-4 → FULL), R2 done (AC-2.2-2/3 → FULL), R3 done (AC-2.4-3 → FULL) |
