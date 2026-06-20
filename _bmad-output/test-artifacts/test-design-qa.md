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

# Test Design for QA: Flutter_PulseCoach

**Purpose:** Test execution recipe for the development team. Defines what to test, how to test it, and what QA needs from other teams.

**Date:** 2026-03-27
**Author:** TEA Master Test Architect
**Status:** Draft
**Project:** Flutter_PulseCoach

**Related:** See Architecture doc (`test-design-architecture.md`) for testability concerns and architectural blockers.

---

## Executive Summary

**Scope:** 150-200 automated tests across 5 layers covering PulseCoach's on-device adaptive AI, guided session execution, multi-device layouts, and offline-first data architecture.

**Risk Summary:**

- Total Risks: 11 (3 high-priority score >=6, 4 medium, 4 low)
- Critical Categories: TECH (platform limitations), BUS (AI correctness), DATA (integrity)

**Coverage Summary:**

- P0 tests: ~42 (AI safety, data integrity, core flows)
- P1 tests: ~78 (features, integration, key UI)
- P2 tests: ~57 (secondary features, edge cases)
- P3 tests: ~4 (debug utilities)
- **Total**: ~181 tests (~67-104 hours with 1 QA)

---

## Not in Scope

| Item | Reasoning | Mitigation |
|---|---|---|
| **WearOS integration tests** | Requires physical watch; no emulator in CI | Unit tests mock interface; manual testing on device |
| **iOS HealthKit integration** | Requires real iOS device; no simulator support | RPE-only path fully tested in CI; scheduled device sessions |
| **Performance load testing** | Single-user mobile app; no server to stress | NFR1 (plan <30s) verified via instrumented timing in integration tests |
| **App Store compliance** | Pre-exam; no store publication | Post-MVP concern |
| **Full accessibility (VoiceOver/TalkBack)** | Deferred to Growth phase per PRD | NFR24-25 (touch targets, contrast) covered in widget tests |

---

## Dependencies & Test Blockers

**Source:** See Architecture doc "Quick Guide" for detailed mitigation plans.

### Development Dependencies (Pre-Implementation)

1. **ASR-3: Clock injection** — AI Dev — Phase 1a
   - QA needs all time-dependent logic to use injectable Clock
   - Without this, domain and data cache tests are non-deterministic

2. **ASR-4: Seeded Random injection** — AI Dev — Phase 1a
   - QA needs bandit epsilon-greedy to use injectable Random
   - Without this, AI behavior tests are non-reproducible

3. **ASR-6: WearOS interface** — Dev Lead — Phase 1a
   - QA needs `WearOsCommunicationService` abstract interface
   - Without this, phone-side WearOS logic is untestable

### QA Infrastructure Setup (Pre-Implementation)

1. **Test Data Factories** — QA / Dev
   - Freezed entity factories for: `UserProfile`, `DailyPlan`, `PlannedSession`, `StateVector`, `Explanation`, `RpeFeedback`, `BehavioralState`
   - Each factory provides sensible defaults with override support

2. **Test Helpers** — QA / Dev
   - `FakeClock` — controllable time for TTL and streak tests
   - `SeededRandom` — reproducible bandit behavior
   - Drift in-memory DB setup/teardown helper
   - Mock generator annotations (`@GenerateMocks`) for all repository interfaces

**Example factory pattern (Dart):**

```dart
// test/helpers/factories.dart
import 'package:pulse_coach/features/today/domain/entities/daily_plan.dart';

DailyPlan createDailyPlan({
  DateTime? date,
  List<PlannedSession>? sessions,
  BehavioralState? state,
}) {
  return DailyPlan(
    date: date ?? DateTime(2026, 3, 27),
    sessions: sessions ?? [createPlannedSession(), createPlannedSession(), createPlannedSession()],
    behavioralState: state ?? BehavioralState.active,
  );
}

PlannedSession createPlannedSession({
  String? type,
  int? durationMinutes,
  String? intensity,
  Explanation? explanation,
}) {
  return PlannedSession(
    type: type ?? 'mobility',
    durationMinutes: durationMinutes ?? 5,
    intensity: intensity ?? 'low',
    explanation: explanation ?? createExplanation(),
    isIndoor: true,
  );
}
```

---

## Risk Assessment

**Note:** Full risk details in Architecture doc. This section summarizes risks relevant to QA test planning.

### High-Priority Risks (Score >=6)

| Risk ID | Category | Description | Score | QA Test Coverage |
|---|---|---|---|---|
| **R-001** | TECH | `wear_plus` insufficient for WearOS | **6** | Mock interface in unit tests; manual device testing |
| **R-002** | TECH | iOS HealthKit untestable in CI | **6** | Full RPE-only path coverage in CI; real-device sessions |
| **R-003** | TECH | Non-deterministic AI tests | **6** | FakeClock + SeededRandom in all domain tests |

### Medium/Low-Priority Risks

| Risk ID | Category | Description | Score | QA Test Coverage |
|---|---|---|---|---|
| R-004 | BUS | Bandit convergence fails | 4 | Parametric tests with synthetic 10-session data |
| R-005 | DATA | Drift DB data loss on lifecycle | 3 | Integration test: close/reopen app, verify data |
| R-006 | BUS | Safety rules allow dangerous recommendation | 3 | 100% unit test coverage of all safety rules (D-SF-*) |
| R-008 | OPS | 150-200 test target not achievable | 4 | Track test count per sprint; prioritize P0/P1 first |
| R-009 | TECH | Responsive layout regressions | 4 | Widget tests with constrained MediaQuery sizes |
| R-010 | DATA | Sensor noise corrupts AI context | 4 | Unit tests with noisy input data + smoothing verification |

---

## Entry Criteria

- [ ] All requirements and assumptions agreed upon by team
- [ ] ASR-3 (Clock injection) and ASR-4 (Random injection) implemented
- [ ] Test data factories created for core domain entities
- [ ] Drift in-memory DB test helper available
- [ ] Mock generator annotations configured for repository interfaces
- [ ] CI pipeline running `flutter analyze` + `flutter test`

## Exit Criteria

- [ ] All P0 tests passing (100%)
- [ ] All P1 tests passing (>=95%)
- [ ] No open high-priority bugs related to AI safety or data integrity
- [ ] Test coverage >=80% overall, >=90% for domain layer
- [ ] All safety rules have dedicated passing tests
- [ ] All state machine transitions have dedicated passing tests

---

## Test Coverage Plan

**IMPORTANT:** P0/P1/P2/P3 = **priority and risk level** (what to focus on if time-constrained), NOT execution timing. See "Execution Strategy" for when tests run.

### P0 (Critical)

**Criteria:** Blocks core functionality + High risk (>=6) + No workaround + Affects all users

| Test ID | Requirement | Test Level | Risk Link | Notes |
|---|---|---|---|---|
| D-AI-001 | FR10: Bandit selects valid action from state vector | Unit | R-003 | Seeded Random |
| D-AI-002 | FR10: Epsilon-greedy exploration ratio correct | Unit | R-003 | Seeded Random |
| D-AI-003 | FR22: RPE feedback updates action-value estimates | Unit | — | Core adaptation loop |
| D-AI-004 | FR12: Cold-start plan capped at Low intensity | Unit | — | Safety-critical |
| D-AI-007 | FR25: Bandit state persists across SM transitions | Unit | — | Data integrity |
| D-AI-008 | FR5: Daily plan generates 3 sessions | Unit | — | Core functionality |
| D-AI-009 | FR5: Session duration 2-10 minutes | Unit | — | Domain constraint |
| D-SF-001 | FR9: RPE >8 for 2 sessions -> block high intensity | Unit | R-006 | Safety rule |
| D-SF-002 | FR9/FR24: AtRisk -> max Low, count = 2 | Unit | R-006 | Safety rule |
| D-SF-003 | FR8/FR36: AQI >100 -> outdoor blocked | Unit | R-006 | Safety rule |
| D-SF-004 | FR9: HR >20% above baseline -> reduce intensity | Unit | R-006 | Safety rule |
| D-SF-005 | FR9: Safety overrides bandit recommendation | Unit | R-006 | Safety rule |
| D-SF-006 | FR9: Multiple safety rules -> most restrictive wins | Unit | R-006 | Safety rule |
| D-SM-001 | FR23: Active -> Fatigued transition | Unit | — | State machine |
| D-SM-002 | FR23: Fatigued -> AtRisk transition | Unit | — | State machine |
| D-SM-003 | FR23: AtRisk -> Recovering transition | Unit | — | State machine |
| D-SM-004 | FR23: Recovering -> Active transition | Unit | — | State machine |
| D-SM-005 | FR23: Determinism — same inputs, same transition | Unit | — | State machine |
| D-SM-006 | FR23: Missed sessions trigger transitions | Unit | — | State machine |
| DA-RP-004 | FR25/NFR16: Bandit state persists and loads | Unit | — | Data integrity |
| DA-CA-001 | FR46/NFR14: Weather cache valid within 1h TTL | Unit | R-003 | FakeClock |
| DA-CA-003 | FR36/NFR19: Weather stale >2h -> indoor default | Unit | R-003 | FakeClock |
| DA-CA-006 | NFR20: No cache, no API -> bundled fallback | Unit | — | Offline safety |
| DA-DB-001 | NFR15: DB survives force-close | Unit | R-005 | Data integrity |
| DA-GD-001 | NFR19: Weather: API fail -> cache -> indoor | Unit | — | Degradation chain |
| DA-GD-002 | NFR20: Exercise: API fail -> cache -> fallback | Unit | — | Degradation chain |
| BL-DP-001 | FR5: DailyPlanBloc loading -> loaded | Unit | — | Core flow |
| BL-DP-004 | FR5/FR13: Loaded state has 3 sessions + explanations | Unit | — | Core flow |
| BL-FB-001 | FR21: RPE submission triggers bandit update | Unit | — | Core loop |
| BL-OB-002 | FR3/NFR10: Disclaimer acceptance persists | Unit | — | Safety-critical |
| W-ON-003 | FR3/NFR10: Disclaimer blocks continue until accepted | Widget | — | Safety-critical |
| I-E2E-001 | FR1-3/FR5/FR12: Full onboarding -> first plan | Integration | — | Critical path |
| I-E2E-002 | FR16-22: Session start -> complete -> RPE -> update | Integration | — | Critical path |
| I-E2E-005 | FR45/NFR13: Offline plan generation | Integration | — | Offline-first |
| I-E2E-009 | FR23-24: Full state machine journey | Integration | — | State machine |
| I-E2E-017 | FR9: High RPE -> plan adjusts next day | Integration | R-006 | Safety override |
| I-E2E-020 | FR3/NFR10: Disclaimer cannot be bypassed | Integration | — | Safety-critical |

**Total P0:** ~42 tests

---

### P1 (High)

**Criteria:** Important features + Medium risk + Common workflows + Core user journeys

| Test ID | Requirement | Test Level | Risk Link | Notes |
|---|---|---|---|---|
| D-AI-005 | FR22: Bandit convergence toward 6.5 in 10 sessions | Unit | R-004 | Synthetic data |
| D-AI-006 | FR6/FR44: Context vector adapts to available inputs | Unit | — | Graceful degradation |
| D-SM-007 | FR23: RPE trend-based transitions | Unit | — | Edge case |
| D-RPE-001 | FR22: RPE reward: completed, near target = positive | Unit | — | Reward calc |
| D-RPE-002 | FR22: RPE reward: abandoned = negative | Unit | — | Reward calc |
| D-RPE-003 | FR22: RPE rolling average (3-day) | Unit | — | Smoothing |
| D-RPE-004 | PRD: RPE outlier detection (>3 jump) | Unit | — | Data quality |
| D-EX-001 | FR13: Explanation includes reason + factors | Unit | — | Explainability |
| D-EX-002 | FR14: State transition human-readable message | Unit | — | UX trust |
| D-EX-003 | FR13: Explanation reflects actual decision context | Unit | — | Explainability |
| D-UC-001 | FR5: GenerateDailyPlan orchestration | Unit | — | Use case |
| D-UC-002 | FR11: RegenerateDailyPlan | Unit | — | Use case |
| D-UC-003 | FR21: SubmitRpeFeedback | Unit | — | Use case |
| D-UC-005 | FR3: AcceptDisclaimer | Unit | — | Use case |
| D-EN-001 | DailyPlan freezed equality | Unit | — | Infrastructure |
| D-EN-002 | FR5: PlannedSession bounds + type valid | Unit | — | Domain |
| D-EN-003 | StateVector serialization round-trip | Unit | — | Infrastructure |
| DA-RP-001 | FR5: DailyPlanRepo save/retrieve | Unit | — | Data |
| DA-RP-002 | FR20: SessionRepo records completed/abandoned | Unit | — | Data |
| DA-RP-003 | FR21: RpeFeedbackRepo stores linked to session | Unit | — | Data |
| DA-RP-005 | FR23: BehavioralStateRepo persists | Unit | — | Data |
| DA-RP-007 | Either Left(Failure) on DB error | Unit | — | Error handling |
| DA-CA-002 | FR46: Weather cache stale -> fetch + update | Unit | — | Cache |
| DA-CA-004 | FR28: Exercise cache valid within 24h | Unit | — | Cache |
| DA-CA-005 | NFR20: Exercise stale, API down -> serve stale | Unit | — | Degradation |
| DA-CA-007 | ASR-3: Cache TTL uses injected Clock | Unit | R-003 | Determinism |
| DA-DS-001 | FR33-34: Weather parse correct | Unit | — | API |
| DA-DS-002 | NFR19: Weather non-200 throws ServerException | Unit | — | Error handling |
| DA-DS-003 | FR35/NFR8: City-level coordinates only | Unit | — | Privacy |
| DA-DS-004 | FR26: ExerciseDB parse correct | Unit | — | API |
| DA-DS-007 | FR44/NFR21: Health permission denied -> empty | Unit | — | Degradation |
| DA-GD-003 | NFR21: Health denied -> RPE-only mode | Unit | — | Degradation |
| DA-DI-001 | NFR23: Fail-fast timeout | Unit | — | Resilience |
| DA-DI-002 | NFR23: Cache interceptor serves on failure | Unit | — | Resilience |
| DA-DB-002 | NFR16: Schema migration preserves data | Unit | — | Data integrity |
| DA-DB-003 | NFR15: Concurrent DAO access no conflicts | Unit | — | Integrity |
| BL-DP-002 | FR5: DailyPlanBloc loading -> error | Unit | — | Error path |
| BL-DP-003 | FR11: Regenerate event triggers new plan | Unit | — | Feature |
| BL-SS-001 | FR16: SessionBloc InProgress on start | Unit | — | Session |
| BL-SS-002 | FR17: Timer advances (injected Clock) | Unit | R-003 | Session |
| BL-SS-003 | FR18: Step transitions trigger haptic event | Unit | — | Session |
| BL-SS-004 | FR20: SessionBloc Completed | Unit | — | Session |
| BL-SS-005 | FR20: SessionBloc Abandoned | Unit | — | Session |
| BL-FB-002 | FR21: RPE validated 1-10 | Unit | — | Validation |
| BL-OB-001 | FR2: OnboardingCubit profile save | Unit | — | Feature |
| BL-ST-001 | FR15: BehavioralStateCubit displays state | Unit | — | Feature |
| BL-ST-002 | FR14: Emits transition message | Unit | — | Feature |
| BL-WE-002 | NFR19: WeatherCubit offline -> cached, no error | Unit | — | Degradation |
| W-TC-001 | FR5/FR13: TodayPage renders 3 cards + explanations | Widget | — | Core UI |
| W-TC-002 | FR16: Session card tap navigates | Widget | — | Core UI |
| W-TC-003 | FR15: State indicator shows behavioral state | Widget | — | Core UI |
| W-IS-001 | FR17: Timer displays and counts | Widget | — | Session UI |
| W-IS-002 | FR17: Exercise step text visible | Widget | — | Session UI |
| W-RP-001 | FR21: RPE slider 1-10 renders | Widget | — | Feedback UI |
| W-RP-002 | FR21: RPE submit sends value | Widget | — | Feedback UI |
| W-EX-001 | FR13: ExplanationLine renders | Widget | — | Trust UI |
| W-EX-002 | FR14: StateTransitionBanner renders | Widget | — | Trust UI |
| W-RS-001 | FR37: Phone bottom tabs render | Widget | R-009 | Responsive |
| W-RS-002 | FR38: Tablet NavigationRail at >=600dp | Widget | R-009 | Responsive |
| W-AC-001 | NFR24: Touch targets >=48dp | Widget | — | Accessibility |
| W-AC-002 | NFR25: WCAG 2.1 AA contrast | Widget | — | Accessibility |
| I-E2E-003 | FR11: Regenerate -> new plan appears | Integration | — | Feature |
| I-E2E-004 | FR20-22: Abandon -> RPE -> negative reward | Integration | — | Flow |
| I-E2E-006 | FR8/FR33-34: AQI >100 -> indoor only | Integration | — | Environment |
| I-E2E-007 | NFR19: Weather API down -> cached -> indoor | Integration | — | Degradation |
| I-E2E-011 | FR12: Cold start -> onboarding -> conservative plan | Integration | — | First-time UX |
| I-E2E-012 | FR10/FR22: 10-session bandit adaptation | Integration | R-004 | AI adaptation |
| I-E2E-013 | FR44/NFR21: Health denied -> RPE-only continues | Integration | — | Degradation |
| I-E2E-014 | FR37: Phone tab navigation | Integration | — | Navigation |
| I-E2E-018 | NFR15: Close/reopen -> data intact | Integration | R-005 | Persistence |
| I-E2E-019 | FR13: Every card shows explanation | Integration | — | Explainability |

**Total P1:** ~78 tests

---

### P2 (Medium)

**Criteria:** Secondary features + Low risk + Edge cases + Regression prevention

| Test ID | Requirement | Test Level | Risk Link | Notes |
|---|---|---|---|---|
| D-UC-004 | FR2: SaveProfile | Unit | — | CRUD |
| D-UC-006 | FR29: GetSessionHistory | Unit | — | Feature |
| D-UC-007 | FR30-31: GetProgressStats | Unit | — | Feature |
| D-EN-004 | FR2: UserProfile validation | Unit | — | Validation |
| DA-RP-006 | FR2/FR4: UserProfileRepo CRUD | Unit | — | Data |
| DA-DS-005 | NFR20: ExerciseDB ServerException | Unit | — | Error |
| DA-DS-006 | FR42: HealthDataSource reads HR/steps | Unit | — | Sensor |
| DA-DS-008 | FR43: SensorDataSource accelerometer | Unit | — | Sensor |
| DA-DS-009 | FR35: LocationDataSource city-level | Unit | — | Location |
| DA-GD-004 | NFR21: Accelerometer unavailable -> no error | Unit | — | Degradation |
| DA-DI-003 | Logging interceptor (debug builds) | Unit | — | Infrastructure |
| DA-SQ-001 | FR47: Sync queue events enqueued in order | Unit | R-011 | Sync |
| DA-SQ-002 | FR47/NFR18: Sync queue FIFO processing | Unit | R-011 | Sync |
| DA-SQ-003 | NFR18: Sync retry with increasing delay | Unit | R-011 | Sync |
| BL-SS-006 | FR19: HR data updates when available | Unit | — | Session |
| BL-OB-003 | FR2: Incomplete profile -> validation error | Unit | — | Validation |
| BL-TH-001 | FR48: Toggle dark mode emits ThemeMode | Unit | — | Theme |
| BL-TH-002 | FR48: System theme follows device | Unit | — | Theme |
| BL-PR-001 | FR30-31: ProgressCubit loaded with chart data | Unit | — | Feature |
| BL-PR-002 | FR31: Weekly goal calculation | Unit | — | Feature |
| BL-PR-003 | FR30: Empty history handled | Unit | — | Edge case |
| BL-EX-001 | FR27: ExerciseCatalogBloc filtered by type | Unit | — | Feature |
| BL-EX-002 | FR28: Offline serves cached catalog | Unit | — | Offline |
| BL-WE-001 | FR33-34: WeatherCubit fetches weather + AQI | Unit | — | Feature |
| BL-SE-001 | FR50: SettingsCubit permissions state | Unit | — | Feature |
| W-TC-004 | FR20: Completed session card check state | Widget | — | UI |
| W-IS-003 | FR19: HR display visible when data available | Widget | — | UI |
| W-IS-004 | FR20: Abandon button triggers confirmation | Widget | — | UI |
| W-ON-001 | FR1: Onboarding swipe through screens | Widget | — | UI |
| W-ON-002 | FR2: ProfileSetupForm validates fields | Widget | — | UI |
| W-PR-001 | FR30: ProgressPage renders charts | Widget | — | UI |
| W-PR-002 | FR31: Weekly goal ring | Widget | — | UI |
| W-RS-003 | FR37: Drawer menu accessible | Widget | R-009 | Responsive |
| W-RS-004 | FR38: Tablet master-detail Today | Widget | R-009 | Responsive |
| W-RO-001 | FR39: Portrait -> landscape maintains state | Widget | R-009 | Rotation |
| W-RO-002 | FR39: InSession landscape renders | Widget | R-009 | Rotation |
| W-TH-001 | FR48: Dark mode correct colors | Widget | — | Theme |
| W-TH-002 | FR48: Light mode correct colors | Widget | — | Theme |
| W-SH-001 | FR29: SessionHistory timeline | Widget | — | UI |
| W-BR-001 | FR27: ExerciseBrowse filter works | Widget | — | UI |
| I-E2E-008 | FR26-28: Exercise catalog browse/filter/view | Integration | — | Feature |
| I-E2E-010 | FR29-32: Progress screen after 5 sessions | Integration | — | Feature |
| I-E2E-015 | FR38: Tablet NavigationRail + master-detail | Integration | R-009 | Responsive |
| I-E2E-016 | FR48: Dark mode toggle across screens | Integration | — | Theme |

**Total P2:** ~57 tests (some may be combined during implementation)

---

### P3 (Low)

**Criteria:** Nice-to-have + MVP-if-time features + Debug utilities

| Test ID | Requirement | Test Level | Notes |
|---|---|---|---|
| D-AI-LOG | FR51: AI Decision Log data structure | Unit | MVP-if-time |
| D-EXPORT-001 | FR52: CSV export format correct | Unit | MVP-if-time |
| D-EXPORT-002 | FR52: JSON export format correct | Unit | MVP-if-time |
| DA-EXPORT-001 | FR52: Export repository writes file | Unit | MVP-if-time |

**Total P3:** ~4 tests

---

## Execution Strategy

**Philosophy:** Run fast tests on every push. Flutter unit/widget tests are extremely fast. Defer only integration tests to extended runs if they exceed time budget.

### Every PR: Unit + Bloc + Data Tests (<3 min)

**All domain, data, and bloc tests:**

- ~132 tests using `flutter_test`, `bloc_test`, `mockito`
- In-memory drift DB, no real I/O
- Run via `flutter test test/domain/ test/data/ test/bloc/`

**Why run in PRs:** Pure Dart, sub-second per test, immediate feedback.

### PR Extended (Before Merge): + Widget Tests (<10 min)

**Add widget tests:**

- ~29 additional tests using `flutter_test` with `WidgetTester`
- Run via `flutter test`

**Why include:** Widget tests are fast (pumped frames, no real rendering pipeline).

### Nightly: Full Suite Including Integration (<15 min)

**All tests including integration:**

- ~20 integration tests using `integration_test` package
- Requires emulator/device
- Run via `flutter test integration_test/`
- Generate coverage report: `flutter test --coverage`

**Why defer to nightly:** Integration tests require emulator boot and are slower (~30s each).

### Manual (Scheduled Sessions):

- WearOS testing on physical Android watch (Phase 1d, Phase 1f)
- iOS HealthKit testing on real iPhone (Phase 1b, Phase 1f)

---

## QA Effort Estimate

| Priority | Count | Effort Range | Notes |
|---|---|---|---|
| P0 | ~42 | ~20-30 hours | AI safety, state machine, core flows |
| P1 | ~78 | ~30-45 hours | Features, integration, key UI |
| P2 | ~57 | ~15-25 hours | Secondary features, edge cases |
| P3 | ~4 | ~2-4 hours | Debug/export utilities |
| **Total** | **~181** | **~67-104 hours** | **Spread across all phases** |

**Assumptions:**

- Includes test design, implementation, debugging, CI integration
- Excludes ongoing maintenance (~10% effort)
- Assumes test data factories and helpers ready before P0 development
- Domain tests (P0/P1) developed in parallel with AI engine (Phase 1a)

---

## Implementation Planning Handoff

| Work Item | Owner | Target Milestone | Dependencies/Notes |
|---|---|---|---|
| Test data factories (freezed entities) | Dev / QA | Phase 1a start | Before any domain tests |
| FakeClock + SeededRandom helpers | AI Dev | Phase 1a day 1 | ASR-3, ASR-4 blockers |
| Mock generator setup (`@GenerateMocks`) | Dev | Phase 1a start | `build_runner` configured |
| Domain layer tests (D-AI-*, D-SF-*, D-SM-*) | AI Dev / QA | Phase 1a | ~35 P0 tests |
| Data layer tests (DA-*) | Dev / QA | Phase 1a-1b | ~50 tests |
| Bloc layer tests (BL-*) | Dev / QA | Phase 1b-1d | ~27+ tests |
| Widget layer tests (W-*) | UI Dev / QA | Phase 1c-1e | ~29 tests |
| Integration tests (I-E2E-*) | QA | Phase 1f | ~20 tests, requires working app |
| WearOS manual testing | Dev | Phase 1d, 1f | Physical watch required |
| iOS HealthKit manual testing | Dev | Phase 1b, 1f | Physical iPhone required |
| CI pipeline: `flutter test` on push | Dev | Phase 1a | GitHub Actions |
| Coverage reporting in CI | Dev | Phase 1f | `flutter test --coverage` |

---

## Appendix A: Code Examples & Tagging

**Flutter test tags for selective execution:**

```dart
// test/domain/ai/bandit_test.dart
@Tags(['p0', 'ai', 'domain'])
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContextualBandit', () {
    late ContextualBandit bandit;
    late FakeClock clock;
    late Random random;

    setUp(() {
      clock = FakeClock(DateTime(2026, 3, 27));
      random = Random(42); // Fixed seed for reproducibility
      bandit = ContextualBandit(clock: clock, random: random);
    });

    test('selects valid action from state vector', () {
      final stateVector = createStateVector();
      final action = bandit.selectAction(stateVector);

      expect(action.sessionType, isIn(['mobility', 'cardio', 'breathing']));
      expect(action.durationMinutes, inInclusiveRange(2, 10));
      expect(action.intensity, isIn(['minimal', 'low', 'moderate', 'high']));
    });

    test('cold-start caps intensity at Low', () {
      final newUserVector = createStateVector(sessionCount: 0);
      final action = bandit.selectAction(newUserVector);

      expect(action.intensity, isIn(['minimal', 'low']));
    });
  });
}
```

**Run tests by tag:**

```bash
# P0 only
flutter test --tags p0

# P0 + P1
flutter test --tags "p0,p1"

# Domain layer only
flutter test test/domain/

# Full suite with coverage
flutter test --coverage
```

**Safety rule test example:**

```dart
@Tags(['p0', 'safety', 'domain'])
void main() {
  group('SafetyRules', () {
    test('RPE avg >8 for 2 consecutive sessions blocks high intensity', () {
      final rules = SafetyRules();
      final context = createSafetyContext(
        recentRpeValues: [8.5, 8.2],
      );

      final constraints = rules.evaluate(context);

      expect(constraints.blockedIntensities, contains('high'));
    });

    test('AQI >100 blocks outdoor sessions', () {
      final rules = SafetyRules();
      final context = createSafetyContext(aqi: 120);

      final constraints = rules.evaluate(context);

      expect(constraints.outdoorBlocked, isTrue);
    });
  });
}
```

---

## Appendix B: Knowledge Base References

- **Risk Governance**: `risk-governance.md` — Risk scoring methodology (P x I = 1-9)
- **Test Priorities Matrix**: `test-priorities-matrix.md` — P0-P3 criteria and decision tree
- **Test Levels Framework**: `test-levels-framework.md` — Unit vs Integration vs E2E selection rules
- **Test Quality**: `test-quality.md` — Determinism, isolation, explicit assertions, <300 lines, <1.5 min

---

**Generated by:** BMad TEA Agent
**Workflow:** `_bmad/tea/testarch/bmad-testarch-test-design`
