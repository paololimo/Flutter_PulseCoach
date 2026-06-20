---
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
lastSaved: '2026-03-27'
workflowType: 'testarch-test-design'
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/planning-artifacts/epics.md'
---

# Test Design for Architecture: Flutter_PulseCoach

**Purpose:** Architectural concerns, testability gaps, and NFR requirements for review by the development team. Serves as a contract between QA and Engineering on what must be addressed before test development begins.

**Date:** 2026-03-27
**Author:** TEA Master Test Architect
**Status:** Architecture Review Pending
**Project:** Flutter_PulseCoach
**PRD Reference:** `_bmad-output/planning-artifacts/prd.md`
**ADR Reference:** `_bmad-output/planning-artifacts/architecture.md`

---

## Executive Summary

**Scope:** System-level test design for PulseCoach — a Flutter/Dart cross-platform fitness app with on-device adaptive AI, WearOS companion, and 150-200 test campaign target.

**Business Context** (from PRD):

- **Impact:** Academic project for PoliMi DIMA exam (2025/2026) — maximum grade across 8 evaluation criteria
- **Problem:** Fragmented schedules prevent consistent exercise; existing apps require too many decisions
- **Post-Exam:** Production-quality codebase suitable for App Store publication

**Architecture** (from ADR):

- **Key Decision 1:** Clean Architecture / MVVM with feature-first folder structure
- **Key Decision 2:** On-device AI (contextual bandit + state machine + RPE loop) on Dart Isolates
- **Key Decision 3:** Offline-first with drift DB, TTL caching, deferred sync

**Expected Scale:** Single-user, on-device. No server infrastructure. ~1100 records/year max.

**Risk Summary:**

- **Total risks**: 11
- **High-priority (>=6)**: 3 risks requiring immediate mitigation
- **Test effort**: ~181 tests (~67-104 hours for 1 QA)

---

## Quick Guide

### BLOCKERS - Team Must Decide (Can't Proceed Without)

**Pre-Implementation Critical Path** — These MUST be completed before test development is effective:

1. **ASR-3: Inject Clock abstraction** — All time-dependent logic (TTL, streaks, sessions) must use an injectable Clock, not `DateTime.now()`. Without this, ~60 domain tests become non-deterministic. (recommended owner: AI Dev, Phase 1a)
2. **ASR-4: Inject seeded Random for bandit** — Epsilon-greedy exploration must use injectable `Random` with seed support. Without this, bandit behavior is non-reproducible in tests. (recommended owner: AI Dev, Phase 1a)
3. **ASR-6: WearOS communication behind interface** — Phone-side WearOS logic must be testable without a physical watch. Define `WearOsCommunicationService` interface regardless of `wear_plus` vs Kotlin implementation. (recommended owner: Dev Lead, Phase 1a spike)

**What we need from team:** Complete these 3 items in Phase 1a or test development for AI and WearOS features is blocked.

---

### HIGH PRIORITY - Team Should Validate (We Provide Recommendation, You Approve)

1. **R-001: WearOS spike** — Early spike to validate `wear_plus` capabilities; define interface boundary regardless of outcome. (Dev Lead, Phase 1a)
2. **R-002: iOS HealthKit strategy** — Accept CI limitation (no simulator testing); schedule real-device test sessions; ensure RPE-only path has full CI coverage. (QA + Dev, Phase 1b)
3. **ASR-2: All external integrations behind abstract interfaces** — Open-Meteo, ExerciseDB, Health API, sensors, GPS must all have mockable interfaces for DI. (Dev, Phase 1a)

**What we need from team:** Review recommendations and approve (or suggest changes).

---

### INFO ONLY - Solutions Provided (Review, No Decisions Needed)

1. **Test strategy**: 5-layer split — domain (~55), data (~50), bloc (~40), widget (~30), integration (~20)
2. **Tooling**: `flutter_test`, `bloc_test`, `mockito`, `integration_test` — all standard Flutter test stack
3. **CI/CD**: GitHub Actions running `flutter analyze` + `flutter test` on every push (<5 min for unit/data/bloc, <15 min full)
4. **Coverage**: ~181 test scenarios prioritized P0-P3 with risk-based classification
5. **Quality gates**: P0 = 100%, P1 >= 95%, overall >= 90%, domain coverage >= 90%

**What we need from team:** Just review and acknowledge.

---

## For Architects and Devs - Open Topics

### Risk Assessment

**Total risks identified**: 11 (3 high-priority score >=6, 4 medium, 4 low)

#### High-Priority Risks (Score >=6) - IMMEDIATE ATTENTION

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner | Timeline |
|---|---|---|---|---|---|---|---|---|
| **R-001** | **TECH** | `wear_plus` insufficient for WearOS communication | 2 | 3 | **6** | Early spike; define interface boundary regardless | Dev Lead | Phase 1a |
| **R-002** | **TECH** | iOS HealthKit untestable in CI (simulator limitation) | 3 | 2 | **6** | Real-device sessions; RPE-only path fully covered in CI | QA + Dev | Phase 1b |
| **R-003** | **TECH** | Non-deterministic AI tests from DateTime.now() and Random | 2 | 3 | **6** | Inject Clock + seeded Random from day 1 (ASR-3, ASR-4) | AI Dev | Phase 1a |

#### Medium-Priority Risks (Score 3-5)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner |
|---|---|---|---|---|---|---|---|
| R-004 | BUS | Bandit convergence fails within 10 sessions | 2 | 2 | 4 | Parametric tests with synthetic data; conservative epsilon | AI Dev |
| R-008 | OPS | 150-200 test target not achievable in timeline | 2 | 2 | 4 | Prioritize domain tests first; track per sprint | Team Lead |
| R-009 | TECH | Tablet/phone responsive layout regressions | 2 | 2 | 4 | Widget tests with constrained MediaQuery sizes | UI Dev |
| R-010 | DATA | Sensor noise corrupts AI context vector | 2 | 2 | 4 | Rolling average smoothing; unit tests with noisy input | AI Dev |

#### Low-Priority Risks (Score 1-2)

| Risk ID | Category | Description | Probability | Impact | Score | Action |
|---|---|---|---|---|---|---|
| R-005 | DATA | Drift DB data loss on lifecycle events | 1 | 3 | 3 | Monitor |
| R-006 | BUS | Safety rules allow dangerous recommendation | 1 | 3 | 3 | Monitor |
| R-007 | TECH | External API changes break integration | 1 | 2 | 2 | Monitor |
| R-011 | DATA | Deferred sync queue ordering failure | 1 | 2 | 2 | Monitor |

#### Risk Category Legend

- **TECH**: Technical/Architecture (integration, scalability, platform limitations)
- **DATA**: Data Integrity (loss, corruption, inconsistency)
- **BUS**: Business Impact (logic errors, safety, user experience)
- **OPS**: Operations (timeline, resource, deployment)

---

### Testability Concerns and Architectural Gaps

#### 1. Blockers to Fast Feedback (WHAT ARCHITECTURE MUST PROVIDE)

| Concern | Impact | What Architecture Must Provide | Owner | Timeline |
|---|---|---|---|---|
| **No Clock injection** | ~60 domain tests non-deterministic (TTL, streaks, timing) | Injectable `Clock` interface used by all time-dependent code | AI Dev | Phase 1a |
| **No Random injection** | Bandit tests non-reproducible | Injectable `Random` with seed support in AI engine | AI Dev | Phase 1a |
| **No WearOS interface** | Can't test WearOS communication without physical watch | `WearOsCommunicationService` abstract interface | Dev Lead | Phase 1a |

#### 2. Architectural Improvements Needed

1. **Test data factory infrastructure**
   - **Current problem**: No test data seeding mechanism exists (greenfield)
   - **Required change**: Create freezed entity factories for all domain objects (DailyPlan, Session, StateVector, UserProfile) with sensible defaults and override support
   - **Impact if not fixed**: Every test requires verbose manual construction of test data
   - **Owner**: QA / Dev
   - **Timeline**: Phase 1a (parallel with domain development)

---

### Testability Assessment Summary

#### What Works Well

- `get_it` + `injectable` DI provides excellent mockability at every boundary
- `Either<Failure, T>` pattern makes error paths explicit and testable
- Pure Dart AI engine (no Flutter imports) is testable with standard `dart:test`
- `drift` supports in-memory databases for fast, isolated test execution
- `freezed` immutability eliminates shared mutable state between tests
- `bloc_test` provides structured state emission verification
- Feature-first Clean Architecture creates clean dependency boundaries

#### Accepted Trade-offs (No Action Required)

- **No WearOS emulator testing in CI** — WearOS features tested via mocked interface in unit tests; manual testing on physical device for integration
- **No iOS HealthKit in CI** — RPE-only fallback path is fully testable; real-device sessions scheduled separately
- **No production monitoring** — acceptable for academic project; Flutter DevTools sufficient

---

### Risk Mitigation Plans (High-Priority Risks >=6)

#### R-001: WearOS Feasibility (Score: 6) - HIGH

**Mitigation Strategy:**

1. Run `wear_plus` spike in Phase 1a to validate phone-watch communication
2. Define `WearOsCommunicationService` abstract interface regardless of spike outcome
3. If `wear_plus` insufficient, implement minimal Kotlin native module behind same interface
4. Phone-side tests always mock the interface — implementation is swappable

**Owner:** Dev Lead
**Timeline:** Phase 1a (first week)
**Status:** Planned
**Verification:** Spike report with go/no-go decision; interface defined and mockable in tests

#### R-002: iOS HealthKit Testing (Score: 6) - HIGH

**Mitigation Strategy:**

1. Ensure `HealthDataSource` interface is mockable — all health data tests use mocks in CI
2. RPE-only fallback path (FR44) has full unit + integration test coverage
3. Schedule 2 real-device testing sessions (Phase 1b, Phase 1f) for HealthKit-specific paths
4. Document which tests require real device in test metadata

**Owner:** QA + Dev
**Timeline:** Phase 1b (real-device sessions)
**Status:** Planned
**Verification:** RPE-only path passes in CI; HealthKit paths verified on real device

#### R-003: Non-Deterministic AI Tests (Score: 6) - HIGH

**Mitigation Strategy:**

1. Implement `Clock` interface (or use `clock` package) in Phase 1a before any AI code
2. All AI engine code receives `Clock` via constructor injection — never calls `DateTime.now()` directly
3. Implement `SeededRandom` wrapper injected into bandit — never uses `Random()` directly
4. All domain tests use `FakeClock` and fixed-seed `Random`

**Owner:** AI Dev
**Timeline:** Phase 1a (day 1 of AI engine implementation)
**Status:** Planned
**Verification:** Zero flaky domain tests across 10 consecutive CI runs

---

### Assumptions and Dependencies

#### Assumptions

1. Flutter SDK 3.41.x stable is available and compatible with all listed packages
2. `drift` in-memory database accurately reflects production SQLite behavior for test purposes
3. Team of 2-3 developers can maintain ~181 tests alongside feature development
4. `bloc_test` `blocTest()` helper sufficient for all state management testing needs

#### Dependencies

1. `wear_plus` spike results — Required by end of Phase 1a (informs WearOS architecture)
2. ExerciseDB API stability — Bundled fallback exercises mitigate this; no hard dependency
3. Test data factories — Required before Phase 1a domain tests begin

#### Risks to Plan

- **Risk**: Team size drops to 2 (third member not confirmed)
  - **Impact**: Test campaign velocity reduced; may need to defer P2/P3 tests
  - **Contingency**: Prioritize P0/P1 tests (120 tests); P2/P3 deferred to Phase 1f

---

**End of Architecture Document**

**Next Steps for Development Team:**

1. Review Quick Guide (BLOCKERS / HIGH PRIORITY / INFO ONLY) and prioritize ASR-3, ASR-4, ASR-6
2. Assign owners for high-priority risk mitigations (R-001, R-002, R-003)
3. Validate assumptions about Flutter SDK and package compatibility
4. Begin WearOS spike in Phase 1a

**Next Steps for QA:**

1. Wait for Clock/Random injection to be implemented (ASR-3, ASR-4)
2. Refer to companion QA doc (`test-design-qa.md`) for test scenarios and coverage plan
3. Begin test data factory development in parallel with domain layer
