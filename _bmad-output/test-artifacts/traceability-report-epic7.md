---
stepsCompleted: ['step-01-load-context', 'step-02-discover-tests', 'step-03-map-criteria', 'step-04-analyze-gaps', 'step-05-gate-decision']
lastStep: 'step-05-gate-decision'
lastSaved: '2026-05-16'
workflowType: 'bmad-testarch-trace'
scope: 'Epic 7 — Today Screen (Stories 7.0, 7.1b, 7.1, 7.2, 7.3, 7.4)'
coverageBasis: 'acceptance_criteria'
oracleResolutionMode: 'formal_requirements'
oracleConfidence: 'high'
oracleSources:
  - '_bmad-output/implementation-artifacts/7-0-failure-equality-bloc-regression.md'
  - '_bmad-output/implementation-artifacts/7-1b-missed-sessions-decay-and-reset.md'
  - '_bmad-output/implementation-artifacts/7-1-stateindicator-component.md'
  - '_bmad-output/implementation-artifacts/7-2-sessioncard-component.md'
  - '_bmad-output/implementation-artifacts/7-3-today-screen-layout-and-hero-progression.md'
  - '_bmad-output/implementation-artifacts/7-4-completionring-component-and-plan-regeneration.md'
externalPointerStatus: 'not_used'
tempCoverageMatrixPath: '/tmp/tea-trace-coverage-matrix-epic7.json'
---

# Requirements Traceability Report — Epic 7

**Generated:** 2026-05-16
**Scope:** Epic 7 — Today Screen (Story 7.0 Failure Equality Regression, Story 7.1b MissedSessions Decay, Story 7.1 StateIndicator, Story 7.2 SessionCard, Story 7.3 Today Screen Layout, Story 7.4 CompletionRing & Regeneration)
**Test suite baseline:** 388 tests (after Epic 6.5) → **515 tests total** (+127 Epic 7)
**Author:** TEA Master Test Architect

---

## Gate Decision: PASS ✅

**Rationale:** P0 coverage is N/A (no P0 ACs in Epic 7). P1 coverage is 96.7% (29/30, target ≥ 90%) → PASS threshold met. Overall coverage is 91.9% (34/37, minimum 80%). Three advisory gaps exist: 7.1b-AC4 (DAO window behavior untested), 7.3-AC2 (above-fold layout not programmatically assertable), and 7.4-AC2 (visual hierarchy design intent). All three are low-risk and non-blocking. One operational risk: `today_session_cubit_test.dart` is untracked in VCS — must be committed before Epic 8.

---

## Coverage Summary

| Metric | Value |
|---|---|
| Total ACs (Epic 7) | 37 |
| Fully covered | 34 / 37 → **91.9%** |
| Partially covered | 3 / 37 |
| Uncovered (in-scope) | 0 / 37 |
| Total tests | **515** (388 baseline + 127 Epic 7) |
| All tests passing | ✅ (verified: `flutter test` 2026-05-16) |

### Priority Coverage

| Priority | Covered / Total | % | Gate Threshold | Status |
|---|---|---|---|---|
| **P0** | **N/A** | **N/A** | 100% required | — (no P0 ACs in Epic 7) |
| **P1** | **29 / 30** | **96.7%** | ≥ 90% for PASS | ✅ MET |
| P2 | 5 / 7 | 71.4% | — | ✅ advisory only |
| P3 | 0 / 0 | N/A | — | — |

### Gate Criteria

| Criterion | Required | Actual | Status |
|---|---|---|---|
| P0 coverage | 100% | N/A (0 P0 ACs) | ✅ MET |
| P1 coverage (PASS target) | ≥ 90% | 96.7% (29/30) | ✅ MET |
| P1 coverage (minimum) | ≥ 80% | 96.7% (29/30) | ✅ MET |
| Overall coverage | ≥ 80% | 91.9% (34/37) | ✅ MET |

---

## Step 1: Context & Knowledge Base

### Coverage Oracle

| Oracle Element | Value |
|---|---|
| `coverageBasis` | `acceptance_criteria` |
| `oracleResolutionMode` | `formal_requirements` |
| `oracleConfidence` | `high` |
| `externalPointerStatus` | `not_used` |

**Oracle Sources (6 story specs, all Status: done):**
- `7-0-failure-equality-bloc-regression.md` — 4 ACs
- `7-1b-missed-sessions-decay-and-reset.md` — 8 ACs
- `7-1-stateindicator-component.md` — 11 ACs
- `7-2-sessioncard-component.md` — 4 ACs
- `7-3-today-screen-layout-and-hero-progression.md` — 6 ACs
- `7-4-completionring-component-and-plan-regeneration.md` — 4 ACs

### Epic 6 Carry-Over

From the Epic 6 traceability matrix: R-001 (4 untracked DAO test files) was present at Epic 6 closure and mandated commit before Epic 7. The automation summary from 2026-05-15 confirms the files were generated and passed — the `git status` at session start shows they remain untracked. **These must be committed alongside Epic 7 work.** See Operational Risks below.

---

## Step 2: Test Inventory

### Epic 7 Test Files

| File | Tests | Level | Story Coverage |
|---|---|---|---|
| `test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart` | 3 | Unit | 7.0 |
| `test/bloc/daily_plan_bloc_test.dart` | +4 new | Unit (BLoC) | 7.0, 7.3 |
| `test/ai/missed_sessions/missed_sessions_calculator_test.dart` | 8 | Unit | 7.1b |
| `test/domain/ai/behavioral_state_machine_test.dart` | +11 new | Unit | 7.1b, 7.1 |
| `test/widget/state_indicator_test.dart` | 12 | Widget + Unit | 7.1 |
| `test/widget/session_card_test.dart` | 44 | Unit + Widget | 7.2, 7.4 |
| `test/widget/today_page_test.dart` | 14 | Widget | 7.3, 7.4 |
| `test/widget/completed_session_card_test.dart` | 5 | Widget | 7.3 |
| `test/bloc/today_session_cubit_test.dart` | 9 | Unit (Cubit) | 7.3 ⚠️ UNTRACKED |
| `test/widget/completion_ring_test.dart` | 6 | Widget | 7.4 |
| `test/data/datasources/exercise_local_data_source_test.dart` | +2 new | Unit | 6.5 (backfill) |

### Coverage Heuristics Inventory

| Heuristic | Findings |
|---|---|
| **State machine transition coverage** | All 6 rules and their guard conditions tested: Q1 (active→atRisk, 7.1b-UNIT-001..003), Q3 (atRisk/fatigued→recovering tightened, 7.1-UNIT-Q3-001..004), Q2 (recovering→fatigued, 7.1-UNIT-Q2-001..004). Priority guard tested (7.1-UNIT-Q2-004). ✅ |
| **Error-path coverage** | DailyPlanBloc error re-emission guard (6.5-EQ-BLOC-001..004), retry counter inequality (6.5-EQ-BLOC-002), cross-type failure inequality (6.5-EQ-BLOC-003). ✅ |
| **UI loading states** | Shimmer asserted (7.3-PAGE-001, 7.3-PAGE-009), `CircularProgressIndicator` absence confirmed (7.3-PAGE-006). ✅ |
| **UI empty/completion states** | All-sessions-completed state tested (7.3-PAGE-007). Error state tested (7.3-PAGE-008). ✅ |
| **Accessibility** | Semantics labels verified in session cards (7.2-WIDGET-017, 7.2-WIDGET-022), CompletionRing accessibility label (7.4-RING-005). ✅ |
| **Reduce Motion** | `MediaQuery.disableAnimationsOf` path tested (7.4-RING-004). ✅ |
| **No internal state codes in UI** | Asserted in 7.1-WIDGET-008/009, 7.1-ARB-003 (no `atRisk`, `fatigued`, etc. in rendered text). ✅ |
| **Windowing behavior (DAO)** | `DailyPlansDao.getPlansInDateRange` not directly tested — window logic delegated to Drift SQL query. No DAO-level integration test. Advisory gap. |

---

## Step 3: Traceability Matrix

### Story 7.0 — Failure Equality BLoC Regression

| AC ID | Acceptance Criterion | Priority | Tests | Level | Coverage | Notes |
|---|---|---|---|---|---|---|
| **7.0-AC1** | Two equal `CacheFailure` emissions with `retryAttempts=0` are structurally equal → `flutter_bloc` drops second emit | P1 | 6.5-EQ-BLOC-001 | Unit | **FULL** | Pins the coalescing invariant. |
| **7.0-AC2** | Same `Failure`, different `retryAttempts` → structurally unequal, both reach stream | P1 | 6.5-EQ-BLOC-002 | Unit | **FULL** | Retry counter ensures distinct emissions on retry. |
| **7.0-AC3** | `CacheFailure('X')` ≠ `ServerFailure('X')` — `runtimeType` breaks hash | P1 | 6.5-EQ-BLOC-003 | Unit | **FULL** | |
| **7.0-AC4** | Full suite passes; `flutter analyze` 0 issues; `retryAttempts` increment produces live BLoC re-emission | P1 | 6.5-EQ-BLOC-004 (review patch), full suite 515/515 | Unit (BLoC) | **FULL** | Dev record shows baseline 388→398 at story close; review patch added BLOC-004 driving actual BLoC through error→retry→error. |

**Story 7.0 coverage: 4/4 (100%)**

---

### Story 7.1b — MissedSessions Decay & Reset

| AC ID | Acceptance Criterion | Priority | Tests | Level | Coverage | Notes |
|---|---|---|---|---|---|---|
| **7.1b-AC1** | Cold-start, no plans → `missedSessions = 0` | P1 | 7.1b-CALC-001 | Unit | **FULL** | Empty list → 0 naturally. |
| **7.1b-AC2** | 3 plans, 1 completed → `missedSessions = 2` | P1 | 7.1b-CALC-002 | Unit | **FULL** | |
| **7.1b-AC3** | 7 uncompleted plans in 7d → `missedSessions = 7` | P1 | 7.1b-CALC-003 | Unit | **FULL** | |
| **7.1b-AC4** | Plans spanning 14d → only 7d window counted → `missedSessions = 7` | P1 | *(none)* | — | **PARTIAL** | `MissedSessionsCalculator` receives pre-filtered flags; windowing is in `getPlansInDateRange` SQL query. No DAO integration test. Risk R-002. |
| **7.1b-AC5** | Today's plan excluded from count; prior 6d misses preserved | P1 | 7.1b-CALC-005 | Unit | **FULL** | "today completed, 3 prior misses → 3 missed" directly tests AC. |
| **7.1b-AC6** | `missedSessions >= 2` + `active` → `atRisk`, message `transition_active_atRisk` | P1 | 7.1b-UNIT-001 | Unit | **FULL** | |
| **7.1b-AC7** | `missedSessions = 1` from `active` → no transition | P1 | 7.1b-UNIT-002 | Unit | **FULL** | |
| **7.1b-AC8** | Priority guard: `active + missed=2 + lastNAvg RPE > 8` → `atRisk` wins over `fatigued` | P1 | 7.1b-UNIT-003 | Unit | **FULL** | |

**Story 7.1b coverage: 7/8 (87.5%) — 1 PARTIAL (7.1b-AC4)**

---

### Story 7.1 — StateIndicator Component

| AC ID | Acceptance Criterion | Priority | Tests | Level | Coverage | Notes |
|---|---|---|---|---|---|---|
| **7.1-AC1** | `active` → dot + "In forma" in Primary `#7DD3C0`; static copy "Pronto per il piano di oggi." | P1 | 7.1-WIDGET-001 | Widget | **FULL** | |
| **7.1-AC2** | `fatigued` → dot + "Sotto sforzo" in Secondary `#A78BDA`; static copy | P1 | 7.1-WIDGET-002 | Widget | **FULL** | |
| **7.1-AC3** | `atRisk` → warning glyph + "In ripresa" in Tertiary `#E8C87A`; static copy | P1 | 7.1-WIDGET-003 | Widget | **FULL** | |
| **7.1-AC4** | `recovering` → restore glyph + "In recupero" in Secondary 70%; static copy | P1 | 7.1-WIDGET-004 | Widget | **FULL** | |
| **7.1-AC5** | `atRisk` and `recovering` use different icons (visual disambiguation) | P1 | 7.1-WIDGET-007 | Widget | **FULL** | Asserts two `Icon` widgets with different `iconData`. |
| **7.1-AC6** | `transitionMessage != null` replaces static copy; `transitionMessage == null` shows static | P1 | 7.1-WIDGET-005, 7.1-WIDGET-006 | Widget | **FULL** | Both branches verified. |
| **7.1-AC7** | `state_messages.it.arb` contains exactly 15 keys (4+4+7) | P1 | 7.1-ARB-001 | Unit | **FULL** | Counts labels + statics + transitions. |
| **7.1-AC8** | `transition_active_fatigued` ≠ `transition_recovering_fatigued` (load-bearing Q2 invariant) | P1 | 7.1-ARB-002 | Unit | **FULL** | String equality pinned; test fails if copy is ever accidentally homogenized. |
| **7.1-AC9** | `BehavioralStateMachine` has exactly 6 rules matching decision doc §"Final Rule Set" | P1 | 7.1-UNIT-Q3-001..004, 7.1-UNIT-Q2-001..004 | Unit | **FULL** | Q3 tightened Rule 4 + Q2 new Rule 6 fully exercised with guard conditions and priority rules. |
| **7.1-AC10** | Typography: state label H3 17sp Plus Jakarta Sans Medium; sub-copy Body Small 13sp `onSurfaceVariant`; no emoji | P2 | 7.1-WIDGET-008 | Widget | **FULL** | Typography properties and emoji-absence verified. |
| **7.1-AC11** | No internal state codes in rendered text; Q2 writing rules (seconda persona, presente, ≤2 sentences) | P2 | 7.1-WIDGET-009, 7.1-ARB-003 | Widget + Unit | **FULL** | WIDGET-009 asserts none of `atRisk`/`fatigued`/`active`/`recovering` appear in UI text. ARB-003 scans for emoji and code strings. |

**Story 7.1 coverage: 11/11 (100%)**

---

### Story 7.2 — SessionCard Component

| AC ID | Acceptance Criterion | Priority | Tests | Level | Coverage | Notes |
|---|---|---|---|---|---|---|
| **7.2-AC1** | `HeroSessionCard` displays: session-type icon (32dp), display name, duration, intensity label, AI explanation, "Inizia sessione" `FilledButton` | P1 | 7.2-WIDGET-001..008, 7.2-HELPER-001..012, 7.2-WIDGET-025 | Unit + Widget | **FULL** | WIDGET-025 (review patch): empty explanation hides Text and omits from semantics label. All content fields exercised. |
| **7.2-AC2** | `HeroSessionCard` visual: 16dp padding, 16dp corner radius, `surfaceContainer` bg, `LinearGradient` (12% accent opacity top-left → `surfaceContainer` bottom-right) | P2 | 7.2-WIDGET-018, 7.2-WIDGET-019 | Widget | **FULL** | Padding/radius asserted via `Padding`/`BorderRadius` widget inspection. Gradient colors verified. |
| **7.2-AC3** | `CompactSessionCard` shows: icon (24dp), display name, duration right-aligned, chevron; NO explanation, NO Start button | P1 | 7.2-WIDGET-012..016, 7.2-WIDGET-021..024 | Widget | **FULL** | Negative assertions (no explanation, no button) verified. WIDGET-023 verifies Material+InkWell ink ripple is not hidden by opaque Container (review patch). |
| **7.2-AC4** | Cardio accent = `#F0A1B0`; mobility = Primary `#7DD3C0`; breathing = Secondary `#A78BDA` | P2 | 7.2-COLOR-001..004, 7.2-WIDGET-009..011 | Unit + Widget | **FULL** | Pure function tested directly; widget tests confirm rendered icon color. |

**Story 7.2 coverage: 4/4 (100%)**

---

### Story 7.3 — Today Screen Layout & Hero Progression

| AC ID | Acceptance Criterion | Priority | Tests | Level | Coverage | Notes |
|---|---|---|---|---|---|---|
| **7.3-AC1** | 3-session plan: layout top-to-bottom = state bar (`StateIndicator` + `CompletionRing`), hero `HeroSessionCard`, "COMING UP" header, 2 `CompactSessionCard` items | P1 | 7.3-PAGE-003, 7.3-PAGE-004, 7.3-PAGE-005 | Widget | **FULL** | PAGE-003 verifies hero + 2 upcoming cards. PAGE-004 confirms `StateIndicator` rendered. PAGE-005 confirms `CompletionRing` rendered. |
| **7.3-AC2** | Hero card, "Inizia sessione" button, and AI explanation are all visible without scrolling | P2 | 7.3-PAGE-002 (implicit) | Widget | **PARTIAL** | Widget test pumps widget in bounded frame; scrollability assertion not explicit. "Above fold" is a device-level guarantee not programmatically verifiable in unit/widget tests. Advisory only. |
| **7.3-AC3** | Session 1 completed → session 2 becomes hero; session 3 in COMING UP | P1 | 7.3-UNIT-009, 7.3-UNIT-010, 7.3-PAGE-011 | Unit + Widget | **FULL** | Cubit identity tracking (`completedIndices` set) ensures correct session becomes hero. PAGE-011 verifies hero/coming-up counts after marking complete. |
| **7.3-AC4** | All 3 completed → "Ottimo lavoro! Tutte le sessioni completate per oggi." completion state, no `HeroSessionCard` | P1 | 7.3-PAGE-007 | Widget | **FULL** | |
| **7.3-AC5** | Loading → shimmer placeholders, no `CircularProgressIndicator` | P1 | 7.3-PAGE-001, 7.3-PAGE-006, 7.3-PAGE-009 | Widget | **FULL** | Three angles: initial loading state, never-CircularProgressIndicator, initial-state shimmer. |
| **7.3-AC6** | `CompactSessionCard` tap → tapped session becomes hero; previous hero moves to COMING UP; no navigation | P1 | 7.3-PAGE-010, 7.3-UNIT-006..008 | Widget + Unit | **FULL** | PAGE-010: tap compact card → hero swaps. UNIT-006: valid index accepted. UNIT-007: out-of-range ignored. UNIT-008: completed index ignored. |

**Story 7.3 coverage: 5/6 (83.3%) — 1 PARTIAL (7.3-AC2)**

---

### Story 7.4 — CompletionRing Component & Plan Regeneration

| AC ID | Acceptance Criterion | Priority | Tests | Level | Coverage | Notes |
|---|---|---|---|---|---|---|
| **7.4-AC1** | `CompletionRing` small variant shows 1/3 arc segment filled in Primary color | P1 | 7.4-RING-001..003 | Widget | **FULL** | RING-001 (0/3), RING-002 (1/3), RING-003 (3/3) verify fraction text; arc progress verified via `CustomPaint` (`_RingPainter`). |
| **7.4-AC2** | Ring is secondary to hero card — does not compete for visual attention | P2 | *(advisory)* | — | **PARTIAL** | Visual hierarchy is a design intent criterion; no programmatic test can assert "secondary prominence". Device visual inspection is the verification method. |
| **7.4-AC3** | "Reduce Motion" enabled → ring updates instantly, no animation | P1 | 7.4-RING-004 | Widget | **FULL** | `MediaQuery.disableAnimationsOf` path tested; asserts `transientCallbackCount == 0` after update (no pending animation frames). |
| **7.4-AC4** | Regenerate `IconButton` tap → `DailyPlanRegenerateRequested` dispatched; shimmer loading shown | P1 | 7.4-PAGE-001, 7.4-PAGE-002, 7.4-PAGE-003, 7.4-HERO-001..003 | Widget | **FULL** | PAGE-001: button visible in loaded state. PAGE-002: tap dispatches event (mockBloc verified). PAGE-003: button hidden during loading. HERO-001..003: button presence, absence, and callback on card directly. |

**Story 7.4 coverage: 3/4 (75%) — 1 PARTIAL (7.4-AC2)**

---

## Step 2b: Full Test ID Inventory (Epic 7 new tests)

### Story 7.0 — Failure Equality BLoC Regression (4 tests)

| Test ID | Description | Level | File |
|---|---|---|---|
| 6.5-EQ-BLOC-001 | Two equal `CacheFailure` errors → structural equality (flutter_bloc coalescing invariant) | Unit | `test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart` |
| 6.5-EQ-BLOC-002 | `retryAttempts: 1` vs `retryAttempts: 2` → not equal | Unit | `test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart` |
| 6.5-EQ-BLOC-003 | `CacheFailure('X')` vs `ServerFailure('X')` → not equal (runtimeType breaks hash) | Unit | `test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart` |
| 6.5-EQ-BLOC-004 | BLoC drives error→retry→error; distinct emissions verified (`retryAttempts: 1`, `retryAttempts: 2`) | Unit (BLoC) | `test/bloc/daily_plan_bloc_test.dart` |

### Story 7.1b — MissedSessions Decay & Reset (11 tests)

| Test ID | Description | Level | File |
|---|---|---|---|
| 7.1b-CALC-001 | Empty list → 0 missed | Unit | `test/ai/missed_sessions/missed_sessions_calculator_test.dart` |
| 7.1b-CALC-002 | 3 plans, 1 completed → 2 missed | Unit | `test/ai/missed_sessions/missed_sessions_calculator_test.dart` |
| 7.1b-CALC-003 | 7 uncompleted → 7 | Unit | `test/ai/missed_sessions/missed_sessions_calculator_test.dart` |
| 7.1b-CALC-004 | All completed → 0 missed | Unit | `test/ai/missed_sessions/missed_sessions_calculator_test.dart` |
| 7.1b-CALC-005 | Today completed, 3 prior misses → 3 missed (today excluded) | Unit | `test/ai/missed_sessions/missed_sessions_calculator_test.dart` |
| 7.1b-CALC-006 | Exactly 1 missed | Unit | `test/ai/missed_sessions/missed_sessions_calculator_test.dart` |
| 7.1b-CALC-007 | Exactly 2 missed (threshold for `atRisk` rule) | Unit | `test/ai/missed_sessions/missed_sessions_calculator_test.dart` |
| 7.1b-CALC-008 | Idempotent — same flags produce same result | Unit | `test/ai/missed_sessions/missed_sessions_calculator_test.dart` |
| 7.1b-UNIT-001 | `active + missedSessions >= 2` → `atRisk` with transition message | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1b-UNIT-002 | `active + missedSessions = 1` → no transition | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1b-UNIT-003 | Priority guard: `active + missed=2 + RPE avg > 8` → `atRisk` wins over `fatigued` | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |

### Story 7.1 — StateIndicator Component (18 tests: 8 SM + 10 widget/ARB)

| Test ID | Description | Level | File |
|---|---|---|---|
| 7.1-UNIT-Q3-001 | `atRisk + 3 RPE avg ≤ 7 + missed=0` → `recovering` | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1-UNIT-Q3-002 | Only 2 RPE values → no transition even with avg ≤ 7 | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1-UNIT-Q3-003 | avg ≤ 7 but missed ≥ 1 → no transition | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1-UNIT-Q3-004 | avg > 7 (`[8,7,7]` avg=7.33) → no transition | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1-UNIT-Q2-001 | `recovering + last RPE = 9` → `fatigued` | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1-UNIT-Q2-002 | `recovering + last RPE = 10` → `fatigued` | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1-UNIT-Q2-003 | `recovering + last RPE = 8` → no transition to fatigued | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1-UNIT-Q2-004 | Priority guard: `recovering→active` (Rule 5) fires first when both Q2 and Q5 conditions met | Unit | `test/domain/ai/behavioral_state_machine_test.dart` |
| 7.1-WIDGET-001 | `active` → "In forma" + static copy | Widget | `test/widget/state_indicator_test.dart` |
| 7.1-WIDGET-002 | `fatigued` → "Sotto sforzo" + static copy | Widget | `test/widget/state_indicator_test.dart` |
| 7.1-WIDGET-003 | `atRisk` → "In ripresa" + static copy | Widget | `test/widget/state_indicator_test.dart` |
| 7.1-WIDGET-004 | `recovering` → "In recupero" + static copy | Widget | `test/widget/state_indicator_test.dart` |
| 7.1-WIDGET-005 | `transitionMessage = null` → static copy shown | Widget | `test/widget/state_indicator_test.dart` |
| 7.1-WIDGET-006 | `transitionMessage != null` → transition copy replaces static | Widget | `test/widget/state_indicator_test.dart` |
| 7.1-WIDGET-007 | `atRisk` and `recovering` show different `Icon` widgets | Widget | `test/widget/state_indicator_test.dart` |
| 7.1-WIDGET-008 | Typography spec: H3 17sp weight/size, bodySmall 13sp, no emoji | Widget | `test/widget/state_indicator_test.dart` |
| 7.1-WIDGET-009 | No internal state codes (`atRisk`, `active`, etc.) in any rendered text | Widget | `test/widget/state_indicator_test.dart` |
| 7.1-ARB-001 | ARB file has exactly 15 user-facing keys (4+4+7) | Unit | `test/widget/state_indicator_test.dart` |
| 7.1-ARB-002 | `transition_active_fatigued` ≠ `transition_recovering_fatigued` | Unit | `test/widget/state_indicator_test.dart` |
| 7.1-ARB-003 | Copy excludes internal state codes and emoji | Unit | `test/widget/state_indicator_test.dart` |

### Story 7.2 — SessionCard Component (44 tests)

| Test ID | Description | Level | File |
|---|---|---|---|
| 7.2-HELPER-001..012 | `sessionDisplayName`, `intensityLabel` pure function contracts and boundaries | Unit | `test/widget/session_card_test.dart` |
| 7.2-COLOR-001..004 | `sessionAccentColor` per type (cardio/mobility/breathing/unknown) | Unit | `test/widget/session_card_test.dart` |
| 7.2-WIDGET-001..011 | `HeroSessionCard`: display name, duration, intensity, explanation, CTA button, icon color per type | Widget | `test/widget/session_card_test.dart` |
| 7.4-HERO-001..003 | `HeroSessionCard`: regenerate button presence/absence/callback (review patch) | Widget | `test/widget/session_card_test.dart` |
| 7.2-WIDGET-012..016 | `CompactSessionCard`: display name, duration, chevron, no button, no explanation | Widget | `test/widget/session_card_test.dart` |
| 7.2-WIDGET-017..020 | `HeroSessionCard`/`CompactSessionCard`: semantic labels, padding/radius, gradient | Widget | `test/widget/session_card_test.dart` |
| 7.2-WIDGET-021..024 | `CompactSessionCard`: tap callback, semantic label, Material surface, padding | Widget | `test/widget/session_card_test.dart` |
| 7.2-WIDGET-025 | `HeroSessionCard`: empty explanation hides Text, omits from Semantics (review patch) | Widget | `test/widget/session_card_test.dart` |

### Story 7.3 — Today Screen Layout & Hero Progression (31 tests)

| Test ID | Description | Level | File |
|---|---|---|---|
| 7.3-UNIT-001 | `DailyPlanState.loaded` defaults `behavioralState` to `active` | Unit | `test/bloc/daily_plan_bloc_test.dart` |
| 7.3-UNIT-002 | `DailyPlanGenerateRequested` emits latest behavioral state from DAO | Unit (BLoC) | `test/bloc/daily_plan_bloc_test.dart` |
| 7.3-UNIT-003 | `DailyPlanGenerateRequested` parses `atRisk` behavioral state correctly | Unit (BLoC) | `test/bloc/daily_plan_bloc_test.dart` |
| 7.3-UNIT-004 | `TodaySessionCubit` initial state: empty indices, 0 completions | Unit | `test/bloc/today_session_cubit_test.dart` ⚠️ |
| 7.3-UNIT-005 | `planLoaded(3)` resets hero to 0 and clears completedIndices | Unit | `test/bloc/today_session_cubit_test.dart` ⚠️ |
| 7.3-UNIT-006 | `swapHero(2)` sets heroIndex to 2 (valid incomplete) | Unit | `test/bloc/today_session_cubit_test.dart` ⚠️ |
| 7.3-UNIT-007 | `swapHero(-1)` and `swapHero(3)` ignored (out-of-range) | Unit | `test/bloc/today_session_cubit_test.dart` ⚠️ |
| 7.3-UNIT-008 | `swapHero(0)` ignored when index 0 is already completed | Unit | `test/bloc/today_session_cubit_test.dart` ⚠️ |
| 7.3-UNIT-009 | `markSessionCompleted`: completed index recorded, hero advances | Unit | `test/bloc/today_session_cubit_test.dart` ⚠️ |
| 7.3-UNIT-010 | `markSessionCompleted`: advances to next incomplete, skipping completed | Unit | `test/bloc/today_session_cubit_test.dart` ⚠️ |
| 7.3-UNIT-011 | `markSessionCompleted`: duplicate completion ignored (guard) | Unit | `test/bloc/today_session_cubit_test.dart` ⚠️ |
| 7.3-UNIT-012 | `markSessionCompleted`: no-op on zero-session plan | Unit | `test/bloc/today_session_cubit_test.dart` ⚠️ |
| 7.3-PAGE-001 | Loading state: shimmer shown, no hero card | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-002 | 1 session loaded: hero only, no COMING UP | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-003 | 3 sessions loaded: hero + 2 compact upcoming | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-004 | Loaded state renders `StateIndicator` | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-005 | Loaded state renders `CompletionRing` | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-006 | `CircularProgressIndicator` never shown | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-007 | All sessions completed → completion message shown, no hero | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-008 | Error state renders warning UI | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-009 | Initial state shows shimmer | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-010 | Tapping compact card swaps hero in-page | Widget | `test/widget/today_page_test.dart` |
| 7.3-PAGE-011 | Marking complete advances hero, shrinks COMING UP | Widget | `test/widget/today_page_test.dart` |
| 7.3-COMPLETED-001 | `CompletedSessionCard`: displays session name | Widget | `test/widget/completed_session_card_test.dart` |
| 7.3-COMPLETED-002 | `CompletedSessionCard`: displays duration | Widget | `test/widget/completed_session_card_test.dart` |
| 7.3-COMPLETED-003 | `CompletedSessionCard`: shows check icon | Widget | `test/widget/completed_session_card_test.dart` |
| 7.3-COMPLETED-004 | `CompletedSessionCard`: non-interactive (no tap handler) | Widget | `test/widget/completed_session_card_test.dart` |
| 7.3-COMPLETED-005 | `CompletedSessionCard`: hides AI explanation text | Widget | `test/widget/completed_session_card_test.dart` |

### Story 7.4 — CompletionRing & Plan Regeneration (9 new tests; 7.4-HERO tests counted in Story 7.2)

| Test ID | Description | Level | File |
|---|---|---|---|
| 7.4-PAGE-001 | Loaded state shows regenerate `IconButton` | Widget | `test/widget/today_page_test.dart` |
| 7.4-PAGE-002 | Tapping regenerate dispatches `DailyPlanRegenerateRequested` | Widget | `test/widget/today_page_test.dart` |
| 7.4-PAGE-003 | Loading state hides regenerate `IconButton` | Widget | `test/widget/today_page_test.dart` |
| 7.4-RING-001 | `CompletionRing` shows "0/3" fraction text | Widget | `test/widget/completion_ring_test.dart` |
| 7.4-RING-002 | `CompletionRing` shows "1/3" fraction text | Widget | `test/widget/completion_ring_test.dart` |
| 7.4-RING-003 | `CompletionRing` shows "3/3" fraction text | Widget | `test/widget/completion_ring_test.dart` |
| 7.4-RING-004 | Reduce Motion: update is instant, no pending animation frames | Widget | `test/widget/completion_ring_test.dart` |
| 7.4-RING-005 | Accessibility: `Semantics` progress label exposed | Widget | `test/widget/completion_ring_test.dart` |
| 7.4-RING-006 | `total = 0` renders without error | Widget | `test/widget/completion_ring_test.dart` |

---

## Step 4: Gap Analysis

### Critical Gaps (P0 Uncovered): 0

No P0 ACs exist in Epic 7.

### High Gaps (P1 Uncovered): 0

No P1 ACs are fully uncovered.

### P1 Partially Covered: 1

| AC ID | Gap | Risk Score | Recommended Action |
|---|---|---|---|
| **7.1b-AC4** | `DailyPlansDao.getPlansInDateRange` 7-day window not tested — windowing enforced by Drift SQL query without a DAO-level integration test | P=2 I=2 Score=4 → MONITOR | Add `daily_plans_dao_test.dart` with in-memory Drift test verifying plans outside 7d window are excluded. Target: before Epic 8. |

### P2 Partially Covered: 2 (Advisory, Non-Blocking)

| AC ID | Gap | Severity | Detail |
|---|---|---|---|
| **7.3-AC2** | "Hero above fold without scroll" — no explicit scroll-assertion in widget tests | LOW | Widget tests render in bounded frame; scroll correctness requires device or integration testing. Not blocking for PASS gate. |
| **7.4-AC2** | "Ring is secondary to hero card" — visual hierarchy design intent | LOW | No programmatic test can assert "secondary prominence". Verified via device visual inspection per CLAUDE.md §On-Device UI Verification Protocol. |

### Heuristic Advisory Notes (Non-Blocking)

| Advisory | Severity | Detail |
|---|---|---|
| **`completedIndices` and `heroIndex` can diverge under rapid multi-tap** | LOW | `TodaySessionCubit` does not have a concurrent-tap guard (user taps two compact cards before state rebuilds). Out-of-scope for current story; deferred. |
| **`DailyPlanBloc._parseState` duplication** | LOW | `_parseState` helper in `DailyPlanBloc` duplicates same logic in `GenerateDailyPlan`. Single source of truth deferred per dev notes. |
| **Rule 5 priority over Rule 6 edge case** | LOW | User with `streak >= 3` and last RPE=9–10 sees "Sei di nuovo in forma!" — matches decision doc "→ active should win" but may feel wrong. Deferred per decision doc. |

### Operational Risks

| Risk ID | Category | Description | P | I | Score | Action | Owner |
|---|---|---|---|---|---|---|---|
| R-001 | TECH | 4 untracked DAO test files from Epic 6 carry-over (`bandit_state_dao_test`, `behavioral_state_dao_test`, `rpe_feedback_dao_test`, `sync_queue_dao_test`) — still untracked at Epic 7 close | 2 | 2 | 4 | COMMIT NOW | Before Epic 8 |
| R-002 | TECH | `today_session_cubit_test.dart` is untracked (`??` in git status) — 9 passing tests not in VCS | 2 | 2 | 4 | COMMIT NOW | Before Epic 8 |

---

## Step 5: Gate Decision Detail

### Decision: PASS ✅

| Gate Rule | Condition | Actual | Result |
|---|---|---|---|
| Rule 1: P0 coverage | = 100% | N/A (0 P0 ACs) | ✅ PASS |
| Rule 2: Overall coverage | ≥ 80% | 91.9% (34/37) | ✅ PASS |
| Rule 3: P1 coverage minimum | ≥ 80% | 96.7% (29/30) | ✅ PASS |
| Rule 4: P1 coverage target | ≥ 90% | 96.7% (29/30) | ✅ PASS → PASS decision |

---

## Test Count Timeline

| Milestone | Count |
|---|---|
| Pre-Epic 7 baseline (after Epic 6.5) | 388 |
| After Story 7.0 (4 new: EQ-BLOC-001..004) | ~398 |
| After Story 7.1b + 7.1 (31 new: CALC + SM + WIDGET/ARB) | ~429 |
| After Story 7.2 (44 new: HELPER + COLOR + WIDGET + HERO) | ~473 |
| After Story 7.3 (31 new: UNIT + PAGE + COMPLETED) | ~504 |
| After Story 7.4 (6 new: RING + backfill run +11) | **515** |

---

## Recommendations

| Priority | Action | Rationale |
|---|---|---|
| **CRITICAL** | Commit `today_session_cubit_test.dart` before Epic 8 begins | Untracked in VCS (`??`), 9 P1 tests passing locally but at risk of loss on branch reset — same pattern as Epic 6 DAO test issue |
| **CRITICAL** | Commit the 4 untracked DAO test files (carry-over from Epic 6) | `bandit_state_dao_test`, `behavioral_state_dao_test`, `rpe_feedback_dao_test`, `sync_queue_dao_test` — also still untracked |
| HIGH | Add `daily_plans_dao_test.dart` with window behavior test for `getPlansInDateRange` | Covers 7.1b-AC4 gap: verify plans outside 7-day window are excluded by SQL query |
| MEDIUM | Run on-device verification per CLAUDE.md §On-Device UI Verification Protocol | Today screen (TodayPage, CompletionRing, StateIndicator, hero progression) has not been validated on physical device yet |
| LOW | Run `/bmad-testarch-trace` again after Epic 8 (In-Session Flow) | RPE submission, session start, and post-session tracking introduce new flows requiring fresh AC traceability |

---

## Test Execution Reference

```bash
# Run all tests (515 tests)
cd pulse_coach && flutter test

# Run Epic 7 — Story 7.0 (Failure equality regression)
flutter test test/features/daily_plan/presentation/bloc/daily_plan_bloc_failure_equality_test.dart \
             test/bloc/daily_plan_bloc_test.dart

# Run Epic 7 — Story 7.1b (MissedSessions)
flutter test test/ai/missed_sessions/missed_sessions_calculator_test.dart \
             test/domain/ai/behavioral_state_machine_test.dart

# Run Epic 7 — Story 7.1 (StateIndicator)
flutter test test/widget/state_indicator_test.dart

# Run Epic 7 — Story 7.2 (SessionCard)
flutter test test/widget/session_card_test.dart

# Run Epic 7 — Story 7.3 (Today Screen)
flutter test test/widget/today_page_test.dart \
             test/widget/completed_session_card_test.dart \
             test/bloc/today_session_cubit_test.dart

# Run Epic 7 — Story 7.4 (CompletionRing + Regeneration)
flutter test test/widget/completion_ring_test.dart

# IMMEDIATE: Commit untracked test files before Epic 8
git add pulse_coach/test/bloc/today_session_cubit_test.dart \
        pulse_coach/test/core/database/daos/bandit_state_dao_test.dart \
        pulse_coach/test/core/database/daos/behavioral_state_dao_test.dart \
        pulse_coach/test/core/database/daos/rpe_feedback_dao_test.dart \
        pulse_coach/test/core/database/daos/sync_queue_dao_test.dart
```

---

## Coverage Map by Story

```
Epic 7 Today Screen — Coverage Map

Story 7.0 — Failure Equality BLoC Regression
  ✅ AC-7.0-AC1  Equal CacheFailure emissions coalesce [P1]
  ✅ AC-7.0-AC2  Different retryAttempts → distinct states [P1]
  ✅ AC-7.0-AC3  CacheFailure ≠ ServerFailure despite equal message [P1]
  ✅ AC-7.0-AC4  Full suite passes with retryAttempts guard [P1]

Story 7.1b — MissedSessions Decay & Reset
  ✅ AC-7.1b-AC1  Cold-start → missedSessions = 0 [P1]
  ✅ AC-7.1b-AC2  3 plans, 1 completed → 2 missed [P1]
  ✅ AC-7.1b-AC3  7 uncompleted → 7 [P1]
  ⚠️ AC-7.1b-AC4  14d window → only 7d counted [P1] PARTIAL
  ✅ AC-7.1b-AC5  Today excluded from count [P1]
  ✅ AC-7.1b-AC6  missed >= 2 + active → atRisk [P1]
  ✅ AC-7.1b-AC7  missed = 1 → no transition [P1]
  ✅ AC-7.1b-AC8  Priority guard: atRisk wins over fatigued [P1]

Story 7.1 — StateIndicator Component
  ✅ AC-7.1-AC1   active → "In forma", Primary color [P1]
  ✅ AC-7.1-AC2   fatigued → "Sotto sforzo", Secondary [P1]
  ✅ AC-7.1-AC3   atRisk → "In ripresa", Tertiary [P1]
  ✅ AC-7.1-AC4   recovering → "In recupero", Secondary 70% [P1]
  ✅ AC-7.1-AC5   atRisk/recovering icon disambiguation [P1]
  ✅ AC-7.1-AC6   transitionMessage replaces static copy [P1]
  ✅ AC-7.1-AC7   15 ARB keys [P1]
  ✅ AC-7.1-AC8   transition_active_fatigued ≠ transition_recovering_fatigued [P1]
  ✅ AC-7.1-AC9   6-rule state machine [P1]
  ✅ AC-7.1-AC10  Typography spec [P2]
  ✅ AC-7.1-AC11  No internal codes, Q2 writing rules [P2]

Story 7.2 — SessionCard Component
  ✅ AC-7.2-AC1   HeroSessionCard content [P1]
  ✅ AC-7.2-AC2   HeroSessionCard visual: padding, radius, gradient [P2]
  ✅ AC-7.2-AC3   CompactSessionCard content [P1]
  ✅ AC-7.2-AC4   Accent colors per session type [P2]

Story 7.3 — Today Screen Layout & Hero Progression
  ✅ AC-7.3-AC1   Layout: state bar, hero, COMING UP, 2 compacts [P1]
  ⚠️ AC-7.3-AC2   Hero card above fold (no scroll needed) [P2] PARTIAL
  ✅ AC-7.3-AC3   Session progression after completion [P1]
  ✅ AC-7.3-AC4   All completed → completion state [P1]
  ✅ AC-7.3-AC5   Loading → shimmer, no CircularProgressIndicator [P1]
  ✅ AC-7.3-AC6   Compact card tap → hero swap [P1]

Story 7.4 — CompletionRing & Plan Regeneration
  ✅ AC-7.4-AC1   CompletionRing shows arc progress [P1]
  ⚠️ AC-7.4-AC2   Ring is secondary to hero card [P2] PARTIAL (design intent)
  ✅ AC-7.4-AC3   Reduce Motion → instant update [P1]
  ✅ AC-7.4-AC4   Regenerate tap → event dispatched + shimmer [P1]

TOTAL: 34/37 FULL ✅ | 3/37 PARTIAL ⚠️ | 515 tests | 0 unresolved P0/P1 gaps
```

---

## Gate Summary

```
🚦 GATE DECISION: PASS ✅

📊 Coverage Analysis:
  - P0 Coverage:       N/A (0 P0 ACs)   Required: 100%    → MET ✅
  - P1 Coverage:       96.7% (29/30)    PASS target: 90%  → MET ✅
  - Overall Coverage:  91.9% (34/37)    Minimum: 80%      → MET ✅

⚠️  P1 Partial Gaps: 1
  1. [MEDIUM] 7.1b-AC4 — DailyPlansDao.getPlansInDateRange 7d window not
     integration-tested. Score=4 → MONITOR. Add daily_plans_dao_test.dart
     before Epic 8.

📋 Advisory Gaps (P2, non-blocking): 2
  1. [LOW] 7.3-AC2 — "Hero above fold" not programmatically assertable.
     Score=2 → DOCUMENT.
  2. [LOW] 7.4-AC2 — "Ring is secondary" is a design intent criterion.
     Score=1 → DOCUMENT.

🚨 Operational Risks (COMMIT REQUIRED before Epic 8):
  R-001: 4 untracked DAO test files (Epic 6 carry-over)
  R-002: today_session_cubit_test.dart untracked (?? in git status)

📂 Full Report: _bmad-output/test-artifacts/traceability-matrix.md
Also saved as: _bmad-output/test-artifacts/traceability-report-epic7.md

✅ GATE: PASS — Today Screen (Epic 7) meets all release quality thresholds.
   34/37 Epic 7 acceptance criteria fully covered (91.9%).
   515/515 tests passing. Epic 7 release APPROVED pending commit of
   5 untracked test files.
```
