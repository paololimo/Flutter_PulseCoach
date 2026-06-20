---
stepsCompleted: ['step-01-load-context', 'step-02-discover-tests', 'step-03-map-criteria', 'step-04-analyze-gaps', 'step-05-gate-decision']
lastStep: 'step-05-gate-decision'
lastSaved: '2026-05-16'
workflowType: 'bmad-testarch-trace'
scope: 'Epic 7.5 — i18n / gen_l10n Migration (Stories 7.5.1, 7.5.2)'
coverageBasis: 'acceptance_criteria'
oracleResolutionMode: 'formal_requirements'
oracleConfidence: 'high'
oracleSources:
  - '_bmad-output/implementation-artifacts/7.5-1-wire-flutter-localizations-gen-l10n.md'
  - '_bmad-output/implementation-artifacts/7.5-2-migrate-epic7-italian-strings-to-arb.md'
externalPointerStatus: 'not_used'
tempCoverageMatrixPath: '/tmp/tea-trace-coverage-matrix-epic7.5.json'
---

# Requirements Traceability Report — Epic 7.5

**Generated:** 2026-05-16
**Scope:** Epic 7.5 — i18n / gen_l10n Migration (Story 7.5.1: Wire flutter_localizations + gen_l10n; Story 7.5.2: Migrate Epic 7 Italian Strings to ARB)
**Test suite baseline:** 515 tests (after Epic 7 closure) → **520 tests total** (+5 Epic 7.5)
**Author:** TEA Master Test Architect

---

## Gate Decision: PASS ✅

**Rationale:** P0 coverage is N/A (no P0 ACs in Epic 7.5). P1 coverage is 100% (12/12, target ≥ 90%) → PASS threshold met. Overall coverage is 92.9% (13/14, minimum 80%). One advisory P2 gap exists: 7.5.2-AC1 (no programmatic grep test to catch future hardcoded Italian strings). Non-blocking. One operational risk: two test files have unstaged modifications — must be committed before Epic 8.

---

## Coverage Summary

| Metric | Value |
|---|---|
| Total ACs (Epic 7.5) | 14 |
| Fully covered | 13 / 14 → **92.9%** |
| Partially covered | 1 / 14 |
| Uncovered (in-scope) | 0 / 14 |
| Total tests | **520** (515 baseline + 5 Epic 7.5) |
| All tests passing | ✅ (verified: `flutter test` 2026-05-16) |

### Priority Coverage

| Priority | Covered / Total | % | Gate Threshold | Status |
|---|---|---|---|---|
| **P0** | **N/A** | **N/A** | 100% required | — (no P0 ACs in Epic 7.5) |
| **P1** | **12 / 12** | **100%** | ≥ 90% for PASS | ✅ MET |
| P2 | 1 / 2 | 50% | — | ✅ advisory only |
| P3 | 0 / 0 | N/A | — | — |

### Gate Criteria

| Criterion | Required | Actual | Status |
|---|---|---|---|
| P0 coverage | 100% | N/A (0 P0 ACs) | ✅ MET |
| P1 coverage (PASS target) | ≥ 90% | 100% (12/12) | ✅ MET |
| P1 coverage (minimum) | ≥ 80% | 100% (12/12) | ✅ MET |
| Overall coverage | ≥ 80% | 92.9% (13/14) | ✅ MET |

---

## Step 1: Context & Knowledge Base

### Coverage Oracle

| Oracle Element | Value |
|---|---|
| `coverageBasis` | `acceptance_criteria` |
| `oracleResolutionMode` | `formal_requirements` |
| `oracleConfidence` | `high` |
| `externalPointerStatus` | `not_used` |

**Oracle Sources (2 story specs, Status: done):**
- `7.5-1-wire-flutter-localizations-gen-l10n.md` — 7 ACs
- `7.5-2-migrate-epic7-italian-strings-to-arb.md` — 7 ACs

### Epic 7 Carry-Over

From the Epic 7 traceability report: R-001 (4 untracked DAO test files from Epic 6) and R-002 (`today_session_cubit_test.dart` untracked) were flagged as COMMIT REQUIRED before Epic 8. Status at Epic 7.5: both appear resolved (committed in Story 7.5.x window — test suite baseline correctly shows 515/520 and untracked DAO files no longer appear in git status for the pulse_coach/test directory).

---

## Step 2: Test Inventory

### Epic 7.5 Test Files

| File | Tests | Level | Story Coverage |
|---|---|---|---|
| `test/widget/app_test.dart` | +1 new (7.5-L10N-001) | Widget | 7.5.1-AC4 |
| `test/l10n/app_localizations_smoke_test.dart` | 4 total (1 from 7.5.1 smoke + 3 from 7.5.2) | Widget + Unit | 7.5.1-AC6, 7.5.2-AC4 |
| `test/widget/state_indicator_test.dart` | updated: 7.1-ARB-001/002/003 (delegates + camelCase) | Unit | 7.5.2-AC2, AC5, AC6 |
| `test/widget/today_page_test.dart` | updated: PROSSIME assertions | Widget | 7.5.2-AC3 |
| `test/widget/session_card_test.dart` | updated: `_wrap()` + delegates, HELPER tests → async | Widget + Unit | 7.5.2-AC1 (indirect) |
| `test/widget/completed_session_card_test.dart` | updated: delegates added | Widget | 7.5.2-AC1 (indirect) |
| `test/widget/completion_ring_test.dart` | updated: delegates added | Widget | 7.5.2-AC1 (indirect) |
| `test/widget/pages_smoke_test.dart` | updated: delegates added | Widget | 7.5.2-AC1 (indirect) |
| `test/widget/app_shell_test.dart` | updated: delegates for shell-mounted TodayPage | Widget | 7.5.2-AC1 (indirect) |

### Coverage Heuristics Inventory

| Heuristic | Findings |
|---|---|
| **gen_l10n pipeline integration** | End-to-end: ARB → gen_l10n → AppLocalizations → widget tree verified by smoke test + 7.5-L10N-001. ✅ |
| **Locale forcing** | `locale: const Locale('it')` asserted in 7.5-L10N-001; `localizationsDelegates` and `supportedLocales` also verified. ✅ |
| **EN/IT parity** | 7.5-L10N-002 pins that both ARB files expose the same user-facing key set. ✅ |
| **Placeholder metadata safety** | 7.5-L10N-003 verifies every `{placeholder}` token has matching `@key.placeholders` metadata in both locales and that they agree cross-locale. ✅ |
| **Legacy file removal** | 7.5-L10N-004 directly asserts `state_messages.it.arb` no longer exists on filesystem. ✅ |
| **ARB key count invariant** | 7.1-ARB-001 (updated) asserts `hasLength(34)` — pins the content completeness requirement. ✅ |
| **Q2 copy invariant** | 7.1-ARB-002 (updated) asserts `transitionActiveFatigued != transitionRecoveringFatigued` in camelCase. ✅ |
| **Absence of hardcoded diacritics** | No programmatic test — verified via dev-time grep at story close. Advisory gap. See 7.5.2-AC1. ⚠️ |
| **BehavioralStateMachine transition strings** | 6 Italian literals still hardcoded in `behavioral_state_machine.dart`. The 7 `transition*` ARB keys are dead code at consumer side. Deferred per scope boundary. ⚠️ |

---

## Step 3: Traceability Matrix

### Story 7.5.1 — Wire flutter_localizations + gen_l10n

| AC ID | Acceptance Criterion | Priority | Tests | Level | Coverage | Notes |
|---|---|---|---|---|---|---|
| **7.5.1-AC1** | `pubspec.yaml` has `flutter_localizations: sdk: flutter` + `flutter: generate: true` | P1 | Smoke test, 7.5-L10N-001 (indirect — compilation fails if missing) | Widget | **FULL** | If flutter_localizations were absent, AppLocalizations class wouldn't exist → all l10n tests fail to compile. Pipeline success is the test. |
| **7.5.1-AC2** | `l10n.yaml` declares `arb-dir: lib/l10n/app`, `template-arb-file: app_en.arb`, `output-dir: lib/l10n`; `synthetic-package` omitted (Correct-Course Note) | P1 | 7.5-L10N-002, 7.5-L10N-003 (indirect) | Unit | **FULL** | Misconfigured l10n.yaml → gen_l10n produces wrong output → ARB parity/metadata tests fail. Pipeline success proves config correctness. |
| **7.5.1-AC3** | `lib/l10n/app/app_en.arb` + `lib/l10n/app/app_it.arb` exist with `@@locale` + `appTitle` | P1 | 7.5-L10N-002 | Unit | **FULL** | EN/IT key parity test reads both files. `appTitle` key present implicitly (gen_l10n generates `appTitle` method used in smoke test). |
| **7.5.1-AC4** | `lib/app.dart` carries `localizationsDelegates`, `supportedLocales`, `locale: const Locale('it')` | P1 | 7.5-L10N-001 | Widget | **FULL** | Direct assertion: `app.locale == Locale('it')`, `contains(AppLocalizations.delegate)`, `containsAll([en, it])`. |
| **7.5.1-AC5** | `lib/l10n/state_messages.it.arb` left untouched in this story | P2 | — | — | **FULL** | Scope guard: file intact at 7.5.1 close (verified via git diff). Superseded by 7.5.2-AC4 (deletion). |
| **7.5.1-AC6** | Smoke test `test/l10n/app_localizations_smoke_test.dart` pumps `MaterialApp` with delegates and asserts `appTitle` resolves to Italian | P1 | `testWidgets('AppLocalizations resolves appTitle in Italian')` | Widget | **FULL** | `expect(find.text('PulseCoach'), findsOneWidget)`. |
| **7.5.1-AC7** | `flutter test` grows by ≤3 tests (503 baseline → 504–506); `flutter analyze` 0 issues | P1 | Full suite 516/516 | — | **FULL** | 515→516 (+1 smoke test). Analyze 0. Baseline in CLAUDE.md reconciled to 516. |

**Story 7.5.1 coverage: 7/7 (100%)**

---

### Story 7.5.2 — Migrate Epic 7 Italian Strings to ARB

| AC ID | Acceptance Criterion | Priority | Tests | Level | Coverage | Notes |
|---|---|---|---|---|---|---|
| **7.5.2-AC1** | Zero Italian diacritics/hardcoded 3+ char strings in 7 Epic 7 widget files (`grep -nrE "(à\|è\|é\|ì\|ò\|ù)" lib/features/today/`) | P2 | *(none — dev-time grep only)* | — | **PARTIAL** | Migration confirmed via grep at story close. No automated test asserts absence of hardcoded Italian — future contributors could re-introduce without test failure. Advisory gap (P=1 I=1 Score=1). |
| **7.5.2-AC2** | `app_it.arb` has ≥34 user-facing keys (15 from state_messages + 18 new + 1 appTitle) | P1 | 7.1-ARB-001 (updated: `hasLength(34)`, camelCase `containsAll`) | Unit | **FULL** | Exact count pinned at 34. Test fails on any addition or removal without updating the assertion. |
| **7.5.2-AC3** | "COMING UP" → `"PROSSIME"` resolved via `AppLocalizations.comingUpHeader` | P1 | 7.3-PAGE-002 (`find.text('PROSSIME')` when 1 session — `findsNothing`), 7.3-PAGE-003 (`findsOneWidget` when 3 sessions) | Widget | **FULL** | Two angles: single-session plan (no COMING UP section), 3-session plan (PROSSIME visible). |
| **7.5.2-AC4** | `lib/l10n/state_messages.it.arb` deleted | P1 | 7.5-L10N-004 | Unit | **FULL** | `expect(File('lib/l10n/state_messages.it.arb').existsSync(), isFalse)` — direct filesystem assertion. |
| **7.5.2-AC5** | `7.1-ARB-001` updated: reads `lib/l10n/app/app_it.arb`, asserts `hasLength(34)`, camelCase `containsAll` list | P1 | 7.1-ARB-001 (updated) | Unit | **FULL** | Path updated to `app_it.arb`; count updated to 34; all key names in `containsAll` converted to camelCase (`transitionActiveAtRisk`, etc.). |
| **7.5.2-AC6** | `7.1-ARB-002` updated: reads `app_it.arb`, uses camelCase key lookups | P1 | 7.1-ARB-002 (updated) | Unit | **FULL** | `arb['transitionActiveFatigued'] != arb['transitionRecoveringFatigued']` — Q2 invariant preserved. |
| **7.5.2-AC7** | `flutter test` ≥516 passing; `flutter analyze` 0 issues | P1 | Full suite 520/520 | — | **FULL** | 516→520 (+4 new tests in 7.5.2). Analyze 0. |

**Story 7.5.2 coverage: 6/7 (85.7%) — 1 PARTIAL (7.5.2-AC1)**

---

## Step 2b: Full Test ID Inventory (Epic 7.5 new tests)

### Story 7.5.1 — Wire flutter_localizations + gen_l10n (1 new test)

| Test ID | Description | Level | File |
|---|---|---|---|
| *(smoke)* — `testWidgets('AppLocalizations resolves appTitle in Italian')` | Pumps `MaterialApp` with Italian locale + delegates; asserts `find.text('PulseCoach')` | Widget | `test/l10n/app_localizations_smoke_test.dart` |

### Story 7.5.2 — Migrate Epic 7 Italian Strings to ARB (4 new tests)

| Test ID | Description | Level | File |
|---|---|---|---|
| `7.5-L10N-001` | App widget forces `locale: const Locale('it')`, registers `AppLocalizations.delegate`, supports en+it | Widget | `test/widget/app_test.dart` |
| `7.5-L10N-002` | English and Italian ARB files expose the same user-facing key set | Unit | `test/l10n/app_localizations_smoke_test.dart` |
| `7.5-L10N-003` | ARB placeholder metadata (`@key.placeholders`) matches `{token}` occurrences in both locales and agrees cross-locale | Unit | `test/l10n/app_localizations_smoke_test.dart` |
| `7.5-L10N-004` | `lib/l10n/state_messages.it.arb` no longer exists on filesystem | Unit | `test/l10n/app_localizations_smoke_test.dart` |

### Updated Tests (body modified, IDs preserved)

| Test ID | Change | File |
|---|---|---|
| `7.1-ARB-001` | Path `app_it.arb`, `hasLength(34)`, camelCase `containsAll` list | `test/widget/state_indicator_test.dart` |
| `7.1-ARB-002` | Key names `transitionActiveFatigued`, `transitionRecoveringFatigued` (camelCase) | `test/widget/state_indicator_test.dart` |
| `7.1-ARB-003` | `_wrap()` + delegates added; loop body unchanged | `test/widget/state_indicator_test.dart` |
| 7.3-PAGE-002/003 | `find.text('PROSSIME')` replaces `find.text('COMING UP')` | `test/widget/today_page_test.dart` |

---

## Step 4: Gap Analysis

### Critical Gaps (P0 Uncovered): 0

No P0 ACs exist in Epic 7.5.

### High Gaps (P1 Uncovered): 0

All 12 P1 ACs are fully covered.

### P2 Partially Covered: 1 (Advisory, Non-Blocking)

| AC ID | Gap | Risk Score | Recommended Action |
|---|---|---|---|
| **7.5.2-AC1** | No programmatic test verifies absence of hardcoded Italian diacritics in Epic 7 widget files. The grep was a dev-time verification only — a future commit could re-introduce hardcoded strings without CI catching it. | P=1 I=1 Score=1 → DOCUMENT | Add a unit test in `test/l10n/app_localizations_smoke_test.dart` that reads the 7 widget source files and asserts zero matches for Italian diacritics pattern. Low priority — target Epic 8 setup window. |

### Heuristic Advisory Notes (Non-Blocking)

| Advisory | Severity | Detail |
|---|---|---|
| **`BehavioralStateMachine` 6 hardcoded Italian transition strings** | LOW | `behavioral_state_machine.dart` lines 35, 44, 53, 68, 81, 94 still return raw Italian string literals. The 7 `transition*` ARB keys generated in `app_it.arb` are currently dead code — `StateIndicator.transitionMessage` receives the string from `BehavioralTransition`, not from AppLocalizations. Deferred per Story 7.5.2 scope boundary. Must be resolved before introducing a second locale. |
| **ARB invariant test uses CWD-relative path** | LOW | `File('lib/l10n/app/app_it.arb')` requires `flutter test` to be invoked from `pulse_coach/`. Pre-existing hazard inherited from the old `state_messages.it.arb` path. Deferred. |
| **7.1-ARB-003 implicit scope creep** | LOW | The loop now scans all user-facing values (semantics labels, button copy, headers), not just state-graph copy. A future legitimate string containing `"active"` would fail spuriously. Deferred fragility note. |

### Operational Risks

| Risk ID | Category | Description | P | I | Score | Action | Owner |
|---|---|---|---|---|---|---|---|
| R-001 | TECH | `test/l10n/app_localizations_smoke_test.dart` and `test/widget/app_test.dart` show unstaged modifications (`M` in git status) — uncommitted changes | 2 | 2 | 4 | COMMIT NOW | Before Epic 8 |
| R-002 | TECH | `BehavioralStateMachine` 6 Italian transition literals — 7 `transition*` ARB keys are dead code at consumer side | 1 | 2 | 2 | TRACK | Epic 8+ (before multi-locale) |

---

## Step 5: Gate Decision Detail

### Decision: PASS ✅

| Gate Rule | Condition | Actual | Result |
|---|---|---|---|
| Rule 1: P0 coverage | = 100% | N/A (0 P0 ACs) | ✅ PASS |
| Rule 2: Overall coverage | ≥ 80% | 92.9% (13/14) | ✅ PASS |
| Rule 3: P1 coverage minimum | ≥ 80% | 100% (12/12) | ✅ PASS |
| Rule 4: P1 coverage target | ≥ 90% | 100% (12/12) | ✅ PASS → PASS decision |

---

## Test Count Timeline

| Milestone | Count |
|---|---|
| Pre-Epic 7.5 baseline (after Epic 7 closure) | 515 |
| After Story 7.5.1 (1 new: smoke appTitle) | **516** |
| After Story 7.5.2 (4 new: L10N-001..004) | **520** |

---

## Recommendations

| Priority | Action | Rationale |
|---|---|---|
| **CRITICAL** | Commit `test/l10n/app_localizations_smoke_test.dart` and `test/widget/app_test.dart` unstaged changes before Epic 8 | Both files show " M" in git status — passing tests not fully persisted in VCS |
| HIGH | Add programmatic grep test for 7.5.2-AC1 | Catches future re-introduction of hardcoded Italian strings in widget files. 5-line test in `app_localizations_smoke_test.dart`. |
| MEDIUM | Migrate `BehavioralStateMachine` transition strings to AppLocalizations | 7 `transition*` ARB keys are currently dead code. Must be resolved before adding a second active locale. Track as Epic 8+ deferred item. |
| LOW | Run `/bmad-testarch-trace` again after Epic 8 (In-Session Flow + SessionLog DAO) | RPE submission, session start, session-completion persistence introduce new flows requiring fresh AC traceability |

---

## Test Execution Reference

```bash
# Run all tests (520 tests)
cd pulse_coach && flutter test

# Run Epic 7.5 — L10N pipeline tests
flutter test test/l10n/app_localizations_smoke_test.dart \
             test/widget/app_test.dart

# Run updated ARB invariant tests
flutter test test/widget/state_indicator_test.dart

# Run Today Page (PROSSIME assertion)
flutter test test/widget/today_page_test.dart

# IMMEDIATE: Commit unstaged test files
git add pulse_coach/test/l10n/app_localizations_smoke_test.dart \
        pulse_coach/test/widget/app_test.dart
```

---

## Coverage Map by Story

```
Epic 7.5 i18n / gen_l10n Migration — Coverage Map

Story 7.5.1 — Wire flutter_localizations + gen_l10n
  ✅ AC-7.5.1-AC1  pubspec: flutter_localizations + generate: true [P1]
  ✅ AC-7.5.1-AC2  l10n.yaml config (Correct-Course: arb-dir: lib/l10n/app) [P1]
  ✅ AC-7.5.1-AC3  ARB stub files in lib/l10n/app/ [P1]
  ✅ AC-7.5.1-AC4  app.dart: delegates + supportedLocales + locale it [P1]
  ✅ AC-7.5.1-AC5  state_messages.it.arb untouched (scope guard) [P2]
  ✅ AC-7.5.1-AC6  Smoke test resolves appTitle in Italian [P1]
  ✅ AC-7.5.1-AC7  flutter test 516/516, analyze 0 [P1]

Story 7.5.2 — Migrate Epic 7 Italian Strings to ARB
  ⚠️ AC-7.5.2-AC1  Zero diacritics in 7 widget files [P2] PARTIAL
  ✅ AC-7.5.2-AC2  app_it.arb has 34 user-facing keys [P1]
  ✅ AC-7.5.2-AC3  "COMING UP" → "PROSSIME" via AppLocalizations [P1]
  ✅ AC-7.5.2-AC4  state_messages.it.arb deleted [P1]
  ✅ AC-7.5.2-AC5  7.1-ARB-001 updated (app_it.arb, hasLength(34), camelCase) [P1]
  ✅ AC-7.5.2-AC6  7.1-ARB-002 updated (camelCase keys, Q2 invariant) [P1]
  ✅ AC-7.5.2-AC7  flutter test 520/520, analyze 0 [P1]

TOTAL: 13/14 FULL ✅ | 1/14 PARTIAL ⚠️ | 520 tests | 0 unresolved P0/P1 gaps
```

---

## Gate Summary

```
🚦 GATE DECISION: PASS ✅

📊 Coverage Analysis:
  - P0 Coverage:       N/A (0 P0 ACs)   Required: 100%    → MET ✅
  - P1 Coverage:       100% (12/12)     PASS target: 90%  → MET ✅
  - Overall Coverage:  92.9% (13/14)    Minimum: 80%      → MET ✅

⚠️  P2 Partial Gaps: 1 (advisory, non-blocking)
  1. [LOW] 7.5.2-AC1 — No programmatic grep test for hardcoded Italian diacritics.
     Score=1 → DOCUMENT. Add 5-line unit test in smoke_test.dart before Epic 8.

📋 Advisory Notes (non-blocking): 3
  1. [LOW] BehavioralStateMachine 6 Italian literals — 7 transition* ARB keys dead code.
  2. [LOW] ARB test uses CWD-relative path — pre-existing hazard.
  3. [LOW] 7.1-ARB-003 implicit scope creep — deferred fragility.

🚨 Operational Risks (COMMIT REQUIRED before Epic 8):
  R-001: test/l10n/app_localizations_smoke_test.dart and test/widget/app_test.dart
         have unstaged modifications (M in git status)

📂 Full Report: _bmad-output/test-artifacts/traceability-matrix.md
Also saved as: _bmad-output/test-artifacts/traceability-report-epic7.5.md

✅ GATE: PASS — Epic 7.5 i18n migration meets all release quality thresholds.
   13/14 acceptance criteria fully covered (92.9%).
   520/520 tests passing. Epic 7.5 release APPROVED pending commit of
   2 unstaged test files.
```
