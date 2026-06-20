---
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
lastSaved: '2026-03-27'
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/ux-design-specification.md'
  - '_bmad-output/planning-artifacts/product-brief-Flutter_PulseCoach.md'
  - '_bmad/tea/testarch/knowledge/risk-governance.md'
  - '_bmad/tea/testarch/knowledge/test-levels-framework.md'
  - '_bmad/tea/testarch/knowledge/test-quality.md'
  - '_bmad/tea/testarch/knowledge/adr-quality-readiness-checklist.md'
---

# Test Design Progress — Flutter_PulseCoach

## Step 1: Detect Mode & Prerequisites

### Mode Selected: System-Level Test Design

**Reasoning:**
- PRD available: 52 functional requirements (10 categories), 26 non-functional requirements (5 categories)
- Architecture Document available: complete (8 steps, component design, data model, API contracts, cross-cutting concerns)
- Epics available: full breakdown with stories and acceptance criteria
- No sprint-status.yaml present → system-level mode confirmed
- Rule: when both PRD/ADR and Epics are available, prefer System-Level Mode first

### Prerequisites Verified:
- ✅ PRD: `_bmad-output/planning-artifacts/prd.md`
- ✅ Architecture: `_bmad-output/planning-artifacts/architecture.md`
- ✅ Epics: `_bmad-output/planning-artifacts/epics.md`
- ✅ UX Design Spec: `_bmad-output/planning-artifacts/ux-design-specification.md`
- ✅ Product Brief: `_bmad-output/planning-artifacts/product-brief-Flutter_PulseCoach.md`

### Input Summary:
- **Project Type:** Cross-platform mobile app (Flutter/Dart) with WearOS companion
- **Domain:** Health & Fitness / mHealth — adaptive micro-workout delivery with on-device AI
- **Complexity:** High
- **Project Context:** Greenfield

## Step 2: Load Context & Knowledge Base

### Configuration (Auto-Detected)

| Setting | Value |
|---|---|
| `test_stack_type` | mobile (Flutter/Dart) |
| `tea_use_playwright_utils` | disabled |
| `tea_use_pactjs_utils` | disabled |
| `tea_pact_mcp` | disabled |
| `tea_browser_automation` | disabled |
| `test_artifacts` | `_bmad-output/test-artifacts/` |

### Tech Stack

- Flutter/Dart, Clean Architecture / MVVM, feature-first
- `flutter_bloc`, `drift`, `go_router`, `dio`, `get_it`/`injectable`, `freezed`
- Testing: `flutter_test`, `bloc_test`, `mockito`, `integration_test`

### Integration Points

1. Open-Meteo API (weather + AQI) — REST, TTL 1h
2. ExerciseDB API (exercise catalog) — REST, TTL 24h
3. HealthKit (iOS) / Health Connect (Android) — HR, steps
4. WearOS companion — `wear_plus` / Kotlin fallback
5. Accelerometer — `sensors_plus`
6. GPS (city-level) — `geolocator`

### NFR Categories

- Performance: plan <30s, 60fps, haptic <200ms, cold start <3s
- Security/Privacy: on-device only, no auth, GDPR Art. 9
- Reliability: offline-first, TTL caching, DB persistence
- Integration resilience: fail-fast, cache-first, graceful degradation
- Accessibility: 48dp targets, WCAG 2.1 AA

### Test Campaign Target

150-200 tests: domain (~60), data (~50), bloc/cubit (~40), widget (~30), integration (~20)

### Knowledge Fragments Loaded

- `risk-governance.md` (core)
- `test-levels-framework.md` (core)
- `test-quality.md` (core)
- `adr-quality-readiness-checklist.md` (extended)

### Existing Coverage

None — greenfield project, no code or tests exist yet.

## Step 3: Testability & Risk Assessment

### Testability Review

**Controllability — Strengths:**
- DI via `get_it`/`injectable` → all deps mockable
- `Either<Failure, T>` → predictable error simulation
- Pure Dart AI engine → testable without Flutter harness
- Drift in-memory DB → isolated test execution
- `bloc_test` → structured state verification

**Testability Concerns:**
- C1: No test seeding APIs → need factory patterns + DAO helpers
- C2: WearOS requires physical device → can't automate in CI
- C3: iOS HealthKit requires real device → gated testing
- C4: Dart Isolate testing adds friction → test AI as pure functions
- C5: Sensor mocking → define abstract interfaces for all sensors

**Observability — Strengths:**
- Bloc emissions fully assertable
- Structured Explanation entity → AI decision traceability
- StateVector serializable → AI inputs transparent

**Reliability — Concerns:**
- R1: DateTime sensitivity → inject Clock interface (ASR-3)
- R2: Random in bandit → inject seeded Random (ASR-4)

### ASRs

| # | ASR | Type |
|---|---|---|
| ASR-1 | AI engine pure Dart, no Flutter imports | ACTIONABLE |
| ASR-2 | All external integrations behind abstract interfaces | ACTIONABLE |
| ASR-3 | Inject Clock abstraction for time-dependent logic | ACTIONABLE |
| ASR-4 | Inject Random with seed support for bandit | ACTIONABLE |
| ASR-5 | Drift in-memory DB for test isolation | FYI |
| ASR-6 | WearOS communication behind interface | ACTIONABLE |
| ASR-7 | Safety rules as pure functions | FYI |

### Risk Assessment Matrix

| ID | Risk | Cat | P | I | Score | Level |
|---|---|---|---|---|---|---|
| R-001 | wear_plus insufficient for WearOS | TECH | 2 | 3 | 6 | HIGH |
| R-002 | iOS HealthKit untestable in CI | TECH | 3 | 2 | 6 | HIGH |
| R-003 | Non-deterministic AI tests (DateTime/Random) | TECH | 2 | 3 | 6 | HIGH |
| R-004 | Bandit convergence fails within 10 sessions | BUS | 2 | 2 | 4 | MEDIUM |
| R-005 | Drift DB data loss on lifecycle events | DATA | 1 | 3 | 3 | LOW |
| R-006 | Safety rules allow dangerous recommendation | BUS | 1 | 3 | 3 | LOW |
| R-007 | External API changes break integration | TECH | 1 | 2 | 2 | LOW |
| R-008 | 150-200 test target not achievable | OPS | 2 | 2 | 4 | MEDIUM |
| R-009 | Responsive layout regressions | TECH | 2 | 2 | 4 | MEDIUM |
| R-010 | Sensor noise corrupts AI context | DATA | 2 | 2 | 4 | MEDIUM |
| R-011 | Deferred sync queue ordering failure | DATA | 1 | 2 | 2 | LOW |

**Gate Assessment:** No score-9 blockers. 3 HIGH risks with clear mitigations. Proceed.
