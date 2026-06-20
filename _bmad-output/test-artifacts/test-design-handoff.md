---
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
lastSaved: '2026-03-27'
workflowType: 'testarch-test-design'
---

# Test Design Handoff: Flutter_PulseCoach

**Purpose:** Single-page handoff summary connecting architecture requirements, QA test plan, and sprint execution. Use this as the entry point for onboarding to the test strategy.

**Date:** 2026-03-27
**Author:** TEA Master Test Architect
**Status:** Ready for Review

---

## Deliverables

| Document | File | Audience | Status |
|---|---|---|---|
| Architecture Review | `test-design-architecture.md` | Dev Team / Architect | Complete |
| QA Test Plan | `test-design-qa.md` | QA / Dev Team | Complete |
| Handoff Summary | `test-design-handoff.md` (this file) | All Stakeholders | Complete |

---

## Test Campaign Overview

| Metric | Target |
|---|---|
| **Total Tests** | 150-200 (~181 planned) |
| **Layers** | 5 (Domain, Data, Bloc, Widget, Integration) |
| **P0 Critical** | ~42 tests |
| **P1 High** | ~78 tests |
| **P2 Medium** | ~57 tests |
| **P3 Low** | ~4 tests |
| **Estimated Effort** | 67-104 hours (1 QA) |

### Test Distribution by Layer

| Layer | Count | Focus |
|---|---|---|
| Domain (Unit) | ~60 | AI engine, safety rules, entities, use cases |
| Data (Unit) | ~50 | Repositories, DAOs, API clients, caching |
| Bloc/Cubit (Unit) | ~40 | State management, event handling, error flows |
| Widget (Component) | ~30 | UI rendering, responsive layout, accessibility |
| Integration (E2E) | ~20 | Critical user journeys, offline scenarios |

---

## Architecture Blockers (Must Resolve Before Testing)

These are the **ACTIONABLE** Architecture Support Requests (ASRs) that must be implemented before QA can write tests against the corresponding features.

| ASR | Requirement | Blocks | Priority |
|---|---|---|---|
| **ASR-3** | Inject `Clock` abstraction for all time-dependent logic | AI engine tests, session scheduling tests | P0 |
| **ASR-4** | Inject seeded `Random` for contextual bandit | AI determinism tests (D-AI-001 through D-AI-010) | P0 |
| **ASR-6** | WearOS communication behind abstract interface | WearOS mock testing in CI | P1 |
| **ASR-1** | AI engine pure Dart, no Flutter imports | Domain-layer unit testing without widget harness | P0 |
| **ASR-2** | All external integrations behind abstract interfaces | Mock injection for API, sensor, health platform tests | P0 |

### FYI (No Action Required)

| ASR | Note |
|---|---|
| ASR-5 | Drift in-memory DB for test isolation — built-in capability |
| ASR-7 | Safety rules as pure functions — already planned in architecture |

---

## Risk Summary

### High Priority (Score >= 6)

| ID | Risk | Score | Mitigation |
|---|---|---|---|
| R-001 | `wear_plus` insufficient for WearOS communication | 6 | Spike in Phase 1a; fallback to Kotlin platform channel |
| R-002 | iOS HealthKit untestable in CI | 6 | Unit tests mock interface; scheduled device testing sessions |
| R-003 | Non-deterministic AI tests (DateTime/Random) | 6 | ASR-3 + ASR-4 injection; seeded test factories |

### Medium Priority (Score 4)

| ID | Risk | Score | Mitigation |
|---|---|---|---|
| R-004 | Bandit convergence fails within 10 sessions | 4 | Statistical convergence tests with known-good datasets |
| R-008 | 150-200 test target not achievable | 4 | P0/P1 prioritized (120 tests); P2/P3 deferred if needed |
| R-009 | Responsive layout regressions | 4 | Golden file tests for 4 breakpoints |
| R-010 | Sensor noise corrupts AI context | 4 | Smoothing filter tests with synthetic noise data |

---

## Not in Scope

| Item | Reason |
|---|---|
| WearOS integration tests | Requires physical device; no CI emulator |
| iOS HealthKit integration | Requires real iOS device |
| Performance load testing | Single-user mobile app; no server |
| Security penetration testing | On-device only; no network attack surface |
| Localization testing | MVP is English-only |

---

## Sprint Execution Sequence

### Phase 1a (Foundation)
1. Implement ASR-1 through ASR-4 (architecture prerequisites)
2. Set up test infrastructure: factories, helpers, in-memory DB config
3. Begin Domain layer P0 tests (AI engine safety, core entities)

### Phase 1b (Core Features)
4. Data layer tests (repositories, caching, API clients)
5. Bloc/Cubit tests (session flow, onboarding, dashboard)
6. Domain layer P1 tests (use cases, adaptation logic)

### Phase 1c (UI & Integration)
7. Widget tests (responsive layouts, accessibility)
8. Integration tests (critical journeys: onboarding -> first session -> feedback)
9. WearOS spike resolution (ASR-6) and mock tests

### Phase 1d-1f (Hardening)
10. P2 edge-case tests, golden file tests
11. NFR verification (timing, cold start, haptic latency)
12. Manual device testing sessions (HealthKit, WearOS)

---

## Quality Gates

| Gate | Criteria | When |
|---|---|---|
| **G1: Test Infrastructure** | Factories, helpers, in-memory DB working; first 10 tests green | End of Phase 1a |
| **G2: Domain Coverage** | All P0 domain tests passing; AI determinism verified | End of Phase 1b |
| **G3: Full P0/P1** | 120+ tests passing; all P0+P1 scenarios covered | End of Phase 1c |
| **G4: Release Candidate** | 150+ tests; no P0/P1 failures; NFR thresholds met | End of Phase 1e |

---

## Key Decisions & Assumptions

1. **On-device AI testing strategy:** Test the AI engine as pure Dart functions with injected dependencies (Clock, Random, sensors). No ML framework integration — the contextual bandit is hand-coded.

2. **Offline-first testing:** Integration tests verify the app works with no network. Cache-first patterns tested at data layer with TTL assertions.

3. **WearOS testing boundary:** Unit tests mock the WearOS interface. Real device testing is manual and scheduled separately. CI never depends on a physical watch.

4. **No auth testing:** The app has no user authentication. Data is local-only. This eliminates an entire test category.

5. **Golden files for responsive UI:** Widget tests use Flutter golden file comparisons at 4 breakpoints (phone portrait, phone landscape, tablet portrait, tablet landscape).

---

## References

| Document | Path |
|---|---|
| PRD | `_bmad-output/planning-artifacts/prd.md` |
| Architecture | `_bmad-output/planning-artifacts/architecture.md` |
| Epics & Stories | `_bmad-output/planning-artifacts/epics.md` |
| UX Design Spec | `_bmad-output/planning-artifacts/ux-design-specification.md` |
| Product Brief | `_bmad-output/planning-artifacts/product-brief-Flutter_PulseCoach.md` |
| Test Architecture Doc | `_bmad-output/test-artifacts/test-design-architecture.md` |
| Test QA Doc | `_bmad-output/test-artifacts/test-design-qa.md` |
| Progress Tracker | `_bmad-output/test-artifacts/test-design-progress.md` |

---

**Generated by:** BMad TEA Agent
**Workflow:** `_bmad/tea/testarch/bmad-testarch-test-design`
