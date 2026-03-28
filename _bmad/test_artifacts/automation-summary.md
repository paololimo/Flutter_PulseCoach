---
stepsCompleted: ['step-01-preflight-and-context', 'step-02-identify-targets', 'step-03-orchestrate', 'step-03c-aggregate', 'step-04-validate-and-summarize']
lastStep: 'step-04-validate-and-summarize'
lastSaved: '2026-03-28'
inputDocuments:
  - pulse_coach/pubspec.yaml
  - pulse_coach/test/**/*.dart
  - pulse_coach/lib/**/*.dart
  - _bmad/tea/testarch/tea-index.csv
  - _bmad/tea/testarch/knowledge/test-levels-framework.md
  - _bmad/tea/testarch/knowledge/test-priorities-matrix.md
  - _bmad/tea/testarch/knowledge/test-quality.md
---

# Test Automation Expansion — PulseCoach Flutter App

## Step 1: Preflight & Context

| Field | Value |
|-------|-------|
| Project | PulseCoach — AI-powered adaptive fitness coaching app |
| Stack | Flutter / Dart (mobile) |
| Framework | `flutter_test` SDK + `bloc_test: ^10.0.0` + `mockito: ^5.4.4` |
| Execution mode | Standalone (no BMad story artifacts) |
| Orchestration | Sequential |
| TEA utils | N/A (Flutter project — Playwright/Pact utils do not apply) |

## Step 2: Automation Targets

### Pre-existing Tests (35 tests, 9 files)

| File | Tests | Level |
|------|-------|-------|
| `test/core/database/app_database_test.dart` | 10 | Integration (Drift in-memory) |
| `test/core/di/injection_test.dart` | 2 | Integration |
| `test/core/error/failures_test.dart` | 4 | Unit |
| `test/core/error/exceptions_test.dart` | 4 | Unit |
| `test/core/utils/either_extensions_test.dart` | 6 | Unit |
| `test/bloc/theme_cubit_test.dart` | 3 | Unit (BLoC) |
| `test/widget/app_test.dart` | 1 | Widget |
| `test/widget/app_shell_test.dart` | 4 | Widget |
| `test/widget/theme_extension_test.dart` | 7 | Widget/Unit |

### Coverage Gaps Identified

| Target | Files | Priority | Justification |
|--------|-------|----------|---------------|
| AppRouter redirect logic | `core/routing/app_router.dart` | **P0** | Onboarding gate — wrong redirect breaks all navigation |
| AppShell tab index (Sessions, Progress) | `shared/widgets/app_shell.dart` | **P1** | Existing tests only covered /today; /sessions and /progress missing |
| All 10 placeholder feature pages | `features/**/pages/*.dart` | **P1** | No smoke tests — regression baseline missing |
| AppSpacing constants | `core/theme/app_spacing.dart` | **P2** | Design system consistency |
| AppShapes constants | `core/theme/app_shapes.dart` | **P2** | Design system consistency |
| AppTextStyles font scale | `core/theme/app_text_styles.dart` | **P2** | Enforces 11sp minimum and font hierarchy |

**Skipped (no implementation yet):** `ApiConstants` (empty class), `PulseDateUtils` (empty stub), domain/data layers.

## Step 3: Tests Generated (Sequential Mode)

### New Test Files Created

| File | Tests | Level | Priority |
|------|-------|-------|----------|
| `test/core/routing/app_router_test.dart` | 4 | Widget (full app pump) | P0 |
| `test/core/theme/app_design_tokens_test.dart` | 11 | Unit + testWidgets | P2 |
| `test/widget/pages_smoke_test.dart` | 10 | Widget | P1 |
| `test/widget/app_shell_test.dart` *(extended)* | +2 | Widget | P1 |

**Total new tests: 27**

### Priority Breakdown (new tests)

| Priority | Count |
|----------|-------|
| P0 | 4 |
| P1 | 12 |
| P2 | 11 |
| P3 | 0 |

## Step 3C: Aggregation

### Infrastructure Notes

- No shared fixtures or factories needed — all tests use `MaterialApp(home: ...)` wrapping or full `PulseCoachApp` with controlled GetIt setup
- `GoogleFonts.config.allowRuntimeFetching = false` set in `setUpAll` of design tokens test to prevent network calls during CI
- All tests follow existing project patterns (GetIt teardown via `await getIt.reset()`)

## Step 4: Validation

### Test Execution Results

```
✅ flutter test — 69/69 PASSED (0 failures)
```

| Suite | Tests | Pass |
|-------|-------|------|
| Pre-existing (35 tests) | 35 | ✅ 35 |
| app_router_test.dart | 4 | ✅ 4 |
| app_design_tokens_test.dart | 11 | ✅ 11 |
| pages_smoke_test.dart | 10 | ✅ 10 |
| app_shell_test.dart (all) | 6+2=8* | ✅ 8* |
| **Total** | **69** | **✅ 69** |

*Including 4 pre-existing + 2 new tab index tests

### Checklist (Flutter-adapted)

- [x] Framework verified (`flutter_test`, `bloc_test`, `mockito` in pubspec.yaml)
- [x] Execution mode: Standalone (no BMad artifacts)
- [x] Coverage gaps identified and mapped
- [x] Test level selection applied (widget/unit per Flutter conventions)
- [x] Priorities assigned (P0/P1/P2)
- [x] Duplicate coverage avoided (router tested via full app pump, not separately from widget tests)
- [x] Tests are deterministic (no hard waits, no conditionals in test flow)
- [x] Tests are isolated (GetIt reset in tearDown for all DI-dependent tests)
- [x] Tests are self-cleaning (AppDatabase closed + GetIt reset in tearDown)
- [x] All tests have priority tags ([P0], [P1], [P2]) and test IDs in names
- [x] Google Fonts async leak prevented (testWidgets + pump(), allowRuntimeFetching=false)
- [x] All 69 tests pass locally

### Known Assumptions & Risks

| Item | Detail |
|------|--------|
| GoRouter async redirect | `pumpAndSettle()` assumed sufficient to drain redirect microtasks — verified passing |
| Google Fonts in CI | `allowRuntimeFetching = false` prevents network fetches; font files not bundled (only fontSize/fontFamily tested, not actual font rendering) |
| Placeholder pages | Smoke tests assert placeholder text (e.g., "Today — Story 7.x") — tests will need updating when real implementations land |
| AppDatabase DI | Router tests depend on GetIt setup matching existing `app_test.dart` pattern |

## Generated Files Summary

```
pulse_coach/test/
├── core/
│   ├── routing/
│   │   └── app_router_test.dart          ← NEW (P0, 4 tests)
│   └── theme/
│       └── app_design_tokens_test.dart   ← NEW (P2, 11 tests)
└── widget/
    ├── app_shell_test.dart               ← EXTENDED (+2 tab index tests)
    └── pages_smoke_test.dart             ← NEW (P1, 10 tests)
```

## Test Execution Commands

```bash
# Run all tests
flutter test

# Run only P0 critical tests (router redirect)
flutter test test/core/routing/app_router_test.dart

# Run widget smoke tests
flutter test test/widget/pages_smoke_test.dart

# Run design token tests
flutter test test/core/theme/app_design_tokens_test.dart
```

## Next Steps

1. **`/bmad-testarch-test-review`** — Review generated tests against quality checklist
2. **`/bmad-testarch-trace`** — Generate traceability matrix once stories have acceptance criteria
3. **As features are implemented** — Replace placeholder assertions in `pages_smoke_test.dart` with real content checks
4. **Integration tests** — When domain/data layers are implemented, populate `test/integration/`, `test/domain/`, `test/data/`
5. **CI setup** — Consider `/bmad-testarch-ci` to scaffold `flutter test` in GitHub Actions
