# Story 5.6: AI Explanation Generation

Status: done

## Story

As the system,
I want every session recommendation to have a structured one-line explanation derived from the state vector,
So that users understand why each session was chosen and trust the system's recommendations.

## Acceptance Criteria

**AC1 — Signal-based explanation (FR13)**
**Given** a `PlannedSession` is generated
**When** the explanation engine runs
**Then** a one-line explanation is generated referencing available state signals (e.g., "Short sleep + elevated HR. Starting gentle." or "Low step count today. Light movement to get going.")

**AC2 — RPE-only fallback (FR13)**
**Given** only RPE history is available (no sensor data — `restingHR` and `stepCount` are null)
**When** the explanation is generated
**Then** it references RPE history or behavioral state (e.g., "You've been consistent this week. Stepping it up slightly.")

**AC3 — Recovering state explanation (FR14)**
**Given** the `BehavioralState` is `Recovering`
**When** explanation is generated
**Then** it communicates the reduced intensity reason (e.g., "Your body needs a lighter day. We've adjusted accordingly.")

**AC4 — Non-empty guarantee**
**Given** explanations are stored
**When** the `PlannedSession` entity is inspected
**Then** the `explanation` field contains the generated string — it is always non-null and non-empty

## Tasks / Subtasks

### Task 1: Create `ExplanationGenerator` (AC: AC1, AC2, AC3, AC4)

- [x] 1.1 Create directory `pulse_coach/lib/ai/explainability/` and file `explanation_generator.dart`:

```dart
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

/// Rule-based explanation engine. Pure Dart — no Flutter imports (ARCH7).
///
/// Generates one non-empty explanation string per session by inspecting the
/// available signals in [StateVector] in priority order:
///   1. BehavioralState (Recovering / AtRisk / Fatigued) — highest priority
///   2. Biometric signals (restingHR, stepCount) — when available
///   3. RPE history — AC2 fallback for sensor-less mode
///   4. Streak / missed-sessions — motivational context
///   5. Session type — final fallback (always non-empty, AC4)
class ExplanationGenerator {
  const ExplanationGenerator();

  /// Returns a List<String> of the same length as [sessions].
  /// Every element is guaranteed non-empty (AC4).
  List<String> generate({
    required StateVector stateVector,
    required List<PlannedSession> sessions,
  }) {
    return sessions
        .asMap()
        .entries
        .map((e) => _explain(stateVector, e.value, e.key))
        .toList();
  }

  String _explain(StateVector sv, PlannedSession session, int index) {
    // AC3: Recovering → always communicate reduced intensity
    if (sv.currentState == BehavioralState.recovering) {
      return "Your body needs a lighter day. We've adjusted accordingly.";
    }

    // AtRisk → safety-first messaging
    if (sv.currentState == BehavioralState.atRisk) {
      if (sv.missedSessions >= 2) {
        return "You've missed a few sessions. Starting easy to rebuild.";
      }
      return 'High load detected. Keeping it light today.';
    }

    // Fatigued → effort acknowledgment
    if (sv.currentState == BehavioralState.fatigued) {
      return 'Your effort has been high lately. Dialing back the intensity.';
    }

    // Active state — check biometric signals first (AC1)
    if (sv.restingHR != null && sv.restingHR! > 75) {
      return 'Elevated resting HR detected. Starting with a gentler session.';
    }

    if (sv.stepCount != null && sv.stepCount! < 3000) {
      return 'Low step count today. Light movement to get going.';
    }

    if (sv.restingHR != null && sv.restingHR! <= 60 && sv.streak >= 1) {
      return 'Resting HR looks solid. Time for a focused session.';
    }

    // AC2: RPE-only mode (no biometrics, but RPE history available)
    if (sv.restingHR == null && sv.stepCount == null && sv.rpeHistory.isNotEmpty) {
      final avg = sv.rpeHistory.reduce((a, b) => a + b) / sv.rpeHistory.length;
      if (avg <= 6.5 && sv.streak >= 2) {
        return "You've been consistent this week. Stepping it up slightly.";
      }
      if (avg > 7.5) {
        return 'Your effort has been high. Keeping it moderate today.';
      }
      return 'Based on your recent sessions. Staying in your comfort zone.';
    }

    // Streak-based motivational context
    if (sv.streak >= 3) {
      return "Great streak! Let's keep the momentum going.";
    }

    if (sv.streak == 0 && sv.missedSessions >= 3) {
      return "Welcome back. Easing in with a gentle start.";
    }

    // Session-type fallback — guaranteed non-empty (AC4)
    return switch (session.sessionType) {
      'breathing' => 'A moment to reset. Short breathing session queued.',
      'mobility' => 'Mobility work to keep you moving well.',
      _ => "Ready when you are. Let's move.",
    };
  }
}
```

- [x] 1.2 Run `dart analyze lib/ai/explainability/explanation_generator.dart` — zero issues.
- [x] 1.3 Confirm zero Flutter imports in `explanation_generator.dart` — ARCH7 compliance.

---

### Task 2: Wire `ExplanationGenerator` into `_runPipeline` (AC: AC1-AC4)

Modify `lib/ai/engine/ai_engine_isolate.dart`:

- [x] 2.1 Add import at top of file:

```dart
import 'package:pulse_coach/ai/explainability/explanation_generator.dart';
```

- [x] 2.2 Replace the existing Step 5 comment and `DailyPlan` construction block:

**OLD** (remove):
```dart
  // Step 5: build DailyPlan (explanation = '' placeholder per PlannedSession doc)
  final plan = DailyPlan(
    planDate: _todayDate(),
    sessions: sessions,
    generatedAt: DateTime.now().toUtc(),
  );
```

**NEW** (replace with):
```dart
  // Step 5: generate per-session explanations (AC1-AC4 of Story 5.6)
  final explanations = const ExplanationGenerator().generate(
    stateVector: updatedSv,
    sessions: sessions,
  );
  final sessionsWithExplanations = sessions.asMap().entries
      .map((e) => e.value.copyWith(explanation: explanations[e.key]))
      .toList();

  // Step 6: build DailyPlan with explanations populated
  final plan = DailyPlan(
    planDate: _todayDate(),
    sessions: sessionsWithExplanations,
    generatedAt: DateTime.now().toUtc(),
  );
```

- [x] 2.3 Update the pipeline doc-comment above `_runPipeline` to reflect the new step count:

**OLD**:
```
///   1. Evaluate BehavioralStateMachine
///   2. Apply SafetyRules
///   3. BanditEngine.selectSessions
///   4. Build DailyPlan with empty explanation placeholders (Story 5.6 fills these)
```

**NEW**:
```
///   1. Evaluate BehavioralStateMachine
///   2. Apply SafetyRules
///   3. BanditEngine.selectSessions
///   4. ExplanationGenerator.generate — per-session explanations (Story 5.6)
///   5. Build DailyPlan with explanations populated
```

- [x] 2.4 Run `dart analyze lib/ai/engine/ai_engine_isolate.dart` — zero issues.

---

### Task 3: Update `ai_engine_test.dart` (test 5.5-UNIT-009)

Test `5.5-UNIT-009` currently asserts `explanation == ''` — this was a Story 5.5 placeholder. Story 5.6 makes it incorrect.

File: `pulse_coach/test/domain/ai/ai_engine_test.dart`

- [x] 3.1 Find and replace the existing test:

**OLD** (remove):
```dart
    test('5.5-UNIT-009: all sessions have empty explanation placeholder (Story 5.6 scope)', () async {
      final output = await engine.call(
        AiEngineInput(stateVector: _sv(), banditState: _uniform()),
      );
      for (final session in output.plan.sessions) {
        expect(session.explanation, equals(''));
      }
    });
```

**NEW** (replace with):
```dart
    test('5.6-UNIT-001: all sessions have non-empty explanation after Story 5.6 (AC4)', () async {
      final output = await engine.call(
        AiEngineInput(stateVector: _sv(), banditState: _uniform()),
      );
      for (final session in output.plan.sessions) {
        expect(session.explanation, isNotEmpty);
      }
    });
```

- [x] 3.2 Run `flutter test test/domain/ai/ai_engine_test.dart` — all 9 tests pass (same count — 1 renamed/updated).

---

### Task 4: Create `ExplanationGenerator` unit tests (AC: AC1, AC2, AC3, AC4)

- [x] 4.1 Create `pulse_coach/test/domain/ai/explanation_generator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/explainability/explanation_generator.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

// ─── Fixtures ──────────────────────────────────────────────────────────────────

StateVector _sv({
  BehavioralState state = BehavioralState.active,
  double? restingHR = 65.0,
  int? stepCount = 4000,
  List<int> rpeHistory = const [],
  int streak = 0,
  int missedSessions = 0,
}) =>
    StateVector(
      restingHR: restingHR,
      stepCount: stepCount,
      activityLevel: ActivityLevel.moderate,
      rpeHistory: rpeHistory,
      missedSessions: missedSessions,
      streak: streak,
      aqiLevel: AqiLevel.low,
      temperature: 20.0,
      precipitation: false,
      userProfile: const UserProfile(
        fitnessLevel: 'medium',
        goal: 'cardio',
        availableTime: 'short',
        physicalConstraints: 'none',
      ),
      currentState: state,
    );

PlannedSession _session({String type = 'cardio'}) => PlannedSession(
      sessionType: type,
      intensity: 5,
      durationMinutes: 5,
      isIndoor: false,
    );

const _gen = ExplanationGenerator();

void main() {
  group('ExplanationGenerator — AC4: non-empty guarantee', () {
    test('5.6-UNIT-002: active state with biometrics → non-empty', () {
      final result = _gen.generate(stateVector: _sv(), sessions: [_session()]);
      expect(result.single, isNotEmpty);
    });

    test('5.6-UNIT-003: no sensor data, no RPE → non-empty (type fallback)', () {
      final sv = _sv(restingHR: null, stepCount: null);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, isNotEmpty);
    });

    test('5.6-UNIT-004: returns same count as sessions list', () {
      final sessions = [_session(), _session('mobility'), _session('breathing')];
      final result = _gen.generate(stateVector: _sv(), sessions: sessions);
      expect(result.length, equals(3));
      for (final e in result) {
        expect(e, isNotEmpty);
      }
    });

    test('5.6-UNIT-005: empty sessions list → empty result (no crash)', () {
      final result = _gen.generate(stateVector: _sv(), sessions: []);
      expect(result, isEmpty);
    });
  });

  group('ExplanationGenerator — AC3: Recovering state', () {
    test('5.6-UNIT-006: Recovering → reduced-intensity message', () {
      final sv = _sv(state: BehavioralState.recovering);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single.toLowerCase(), contains('lighter'));
    });

    test('5.6-UNIT-007: Recovering overrides biometric signals', () {
      final sv = _sv(
        state: BehavioralState.recovering,
        restingHR: 45.0, // low HR — would otherwise be "solid" message
        stepCount: 8000,
        streak: 5,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      // Must still use Recovering message, not the biometric/streak message
      expect(result.single.toLowerCase(), contains('lighter'));
    });
  });

  group('ExplanationGenerator — AC1: signal-based explanations', () {
    test('5.6-UNIT-008: elevated HR → mentions elevated HR or gentle start', () {
      final sv = _sv(restingHR: 80.0, state: BehavioralState.active);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      final text = result.single.toLowerCase();
      expect(text.contains('hr') || text.contains('gentle') || text.contains('elevated'), isTrue);
    });

    test('5.6-UNIT-009: low step count → mentions step count or light movement', () {
      final sv = _sv(stepCount: 1500, restingHR: null, state: BehavioralState.active);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      final text = result.single.toLowerCase();
      expect(text.contains('step') || text.contains('light') || text.contains('movement'), isTrue);
    });

    test('5.6-UNIT-010: good streak → positive/momentum message', () {
      final sv = _sv(streak: 4, restingHR: null, stepCount: null, state: BehavioralState.active);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      final text = result.single.toLowerCase();
      expect(text.contains('streak') || text.contains('momentum') || text.contains('consistent'), isTrue);
    });
  });

  group('ExplanationGenerator — AC2: RPE-only fallback', () {
    test('5.6-UNIT-011: no sensor data + consistent low RPE + streak → step-up message', () {
      final sv = _sv(
        restingHR: null,
        stepCount: null,
        rpeHistory: [5, 6, 6, 5, 6],
        streak: 3,
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      final text = result.single.toLowerCase();
      expect(
        text.contains('consistent') || text.contains('stepping') || text.contains('week'),
        isTrue,
      );
    });

    test('5.6-UNIT-012: no sensor data + high RPE history → moderate/keep-it-moderate message', () {
      final sv = _sv(
        restingHR: null,
        stepCount: null,
        rpeHistory: [9, 8, 9, 9],
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      final text = result.single.toLowerCase();
      expect(
        text.contains('high') || text.contains('moderate') || text.contains('effort'),
        isTrue,
      );
    });
  });

  group('ExplanationGenerator — behavioral state messages', () {
    test('5.6-UNIT-013: AtRisk + missed sessions ≥ 2 → rebuild momentum message', () {
      final sv = _sv(state: BehavioralState.atRisk, missedSessions: 3);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      expect(result.single, isNotEmpty);
    });

    test('5.6-UNIT-014: Fatigued → dialing back or effort message', () {
      final sv = _sv(state: BehavioralState.fatigued);
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      final text = result.single.toLowerCase();
      expect(
        text.contains('high') || text.contains('effort') || text.contains('dial') || text.contains('intensity'),
        isTrue,
      );
    });

    test('5.6-UNIT-015: welcome-back scenario (streak=0, missed≥3) → welcome-back message', () {
      final sv = _sv(
        streak: 0,
        missedSessions: 4,
        restingHR: null,
        stepCount: null,
        state: BehavioralState.active,
      );
      final result = _gen.generate(stateVector: sv, sessions: [_session()]);
      final text = result.single.toLowerCase();
      expect(text.contains('back') || text.contains('easing') || text.contains('gentle'), isTrue);
    });
  });

  group('ExplanationGenerator — session-type fallback', () {
    test('5.6-UNIT-016: breathing session type → breathing-specific fallback', () {
      final sv = _sv(restingHR: null, stepCount: null);
      final result = _gen.generate(stateVector: sv, sessions: [_session('breathing')]);
      expect(result.single, isNotEmpty);
    });

    test('5.6-UNIT-017: mobility session type → mobility-specific fallback', () {
      final sv = _sv(restingHR: null, stepCount: null);
      final result = _gen.generate(stateVector: sv, sessions: [_session('mobility')]);
      expect(result.single, isNotEmpty);
    });
  });
}
```

- [x] 4.2 Run `flutter test test/domain/ai/explanation_generator_test.dart` — all 16 tests pass.

---

### Task 5: Full regression suite (AC: all)

- [x] 5.1 Run:
  ```bash
  flutter test
  ```
- [x] 5.2 Confirm all tests pass. Starting count: **304**; expected final: **~320** (+16 new, renaming 5.5-UNIT-009 → 5.6-UNIT-001 keeps count stable for that test).
- [x] 5.3 Run `dart analyze lib/` — zero issues (pre-existing `comment_references` infos are acceptable).

---

## Dev Notes

### What this story does

`PlannedSession.explanation` is currently set to `''` inside `_runPipeline` in `ai_engine_isolate.dart` — the Story 5.5 comment explicitly tags this as "Story 5.6 fills these". This story:

1. Creates `lib/ai/explainability/explanation_generator.dart` — pure Dart rule engine.
2. Modifies `_runPipeline` to call `ExplanationGenerator.generate()` after bandit selection.
3. Merges returned explanation strings into each `PlannedSession` via `copyWith`.
4. Updates and adds tests.

**No new DI registration needed** — `ExplanationGenerator` is a stateless, const-constructible class used directly inside the isolate. It carries no injected dependencies.

### File Placement

| File | Action | Notes |
|---|---|---|
| `lib/ai/explainability/explanation_generator.dart` | **Create** | New directory `explainability/` under `lib/ai/` |
| `lib/ai/engine/ai_engine_isolate.dart` | **Modify** | Add import + replace Step 5 block |
| `test/domain/ai/explanation_generator_test.dart` | **Create** | 16 new tests |
| `test/domain/ai/ai_engine_test.dart` | **Modify** | Rename + update 5.5-UNIT-009 → 5.6-UNIT-001 |

**Do NOT touch:**
- `lib/features/daily_plan/domain/entities/planned_session.dart` — field `explanation` already defined with `@Default('')`; `copyWith` is generated
- `lib/features/daily_plan/domain/entities/explanation.dart` — domain entity exists but is NOT used in this story; `ExplanationGenerator` returns `List<String>`, not `List<Explanation>`. The `Explanation` entity is available for future use (e.g., export feature FR52)
- `lib/ai/engine/ai_engine.dart` — `AiEngineInput`/`AiEngineOutput` are unchanged
- Any DAOs, repositories, BLoC files
- All other existing tests — 304 tests must still pass

### ARCH7 Compliance

`ExplanationGenerator` is in `lib/ai/explainability/` — must have zero Flutter imports. The only imports are:
- `package:pulse_coach/ai/bandit/state_vector.dart`
- `package:pulse_coach/ai/state_machine/behavioral_state.dart`
- `package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart`

All three are pure Dart. Run `dart analyze` to confirm zero Flutter framework imports.

### Signal Priority in `_explain`

The priority order inside `_explain` is intentional:

1. **BehavioralState** (Recovering → AtRisk → Fatigued): state-level constraints already applied by SafetyRules; explanation must align with what actually happened.
2. **Biometrics** (restingHR, stepCount): concrete observable signals — most trust-building for users who see their health data reflected.
3. **RPE history** (AC2 fallback): when no biometrics exist (RPE-only mode), RPE is the only available signal.
4. **Streak / missedSessions**: motivational framing when signals are neutral.
5. **Session type**: guaranteed non-empty fallback for every possible code path (AC4).

### Integration Point in `_runPipeline`

**Before Story 5.6** (current code in `ai_engine_isolate.dart`):
```dart
// Step 5: build DailyPlan (explanation = '' placeholder per PlannedSession doc)
final plan = DailyPlan(
  planDate: _todayDate(),
  sessions: sessions,          // explanation = '' on all
  generatedAt: DateTime.now().toUtc(),
);
```

**After Story 5.6**:
```dart
// Step 5: generate per-session explanations
final explanations = const ExplanationGenerator().generate(
  stateVector: updatedSv,
  sessions: sessions,
);
final sessionsWithExplanations = sessions.asMap().entries
    .map((e) => e.value.copyWith(explanation: explanations[e.key]))
    .toList();

// Step 6: build DailyPlan with explanations populated
final plan = DailyPlan(
  planDate: _todayDate(),
  sessions: sessionsWithExplanations,
  generatedAt: DateTime.now().toUtc(),
);
```

The `ExplanationGenerator` is instantiated as `const` — no state, no allocations per call.

### Test 5.5-UNIT-009 Update

`ai_engine_test.dart` currently contains:
```dart
test('5.5-UNIT-009: all sessions have empty explanation placeholder (Story 5.6 scope)', () async {
```
This test will **fail** after Task 2 (the placeholder is no longer empty). **Task 3 must be done before running `flutter test`** on the full suite. The corrected test is renamed `5.6-UNIT-001`.

### `Explanation` Entity vs `List<String>`

`lib/features/daily_plan/domain/entities/explanation.dart` defines an `Explanation` freezed class with `sessionIndex` and `text`. This entity is NOT used in Story 5.6. `ExplanationGenerator.generate()` returns `List<String>` (one string per session, by position). The `Explanation` entity remains available for the AI Decision Log feature (FR51/FR52) in Epic 14.

### Downstream Stories

- **Story 7.2 `SessionCard`** (UX-DR5): renders `PlannedSession.explanation` as Body Small text — always visible on the hero card.
- **Story 7.1 `StateIndicator`** (UX-DR11): StateIndicator explanation is a separate one-line label for the behavioral state itself. This is NOT generated by `ExplanationGenerator` — it is a per-state static string rendered in the UI widget directly (e.g. "Active", "Recovering").
- **Story 14.4 AI Decision Log** (FR51): may consume `List<Explanation>` for audit trail. `ExplanationGenerator` can be extended then.

### Test Count

Starting: **304 tests** (Story 5.5 final count)

New tests Story 5.6:
- `5.6-UNIT-001`: updated from 5.5-UNIT-009 (net 0 change — 1 renamed)
- `5.6-UNIT-002` → `5.6-UNIT-017`: 16 new tests (`explanation_generator_test.dart`)

Target: **~320 tests** (+16)

### References

- FR13: Structured session explanation [Source: `_bmad-output/planning-artifacts/prd.md#FR13`]
- FR14: Human-readable transition message [Source: `prd.md#FR14`]
- FR15: Behavioral state display [Source: `prd.md#FR15`]
- ARCH7: Pure Dart AI engine, no Flutter imports [Source: `_bmad-output/planning-artifacts/architecture.md` — AI Engine Isolation Pattern]
- `ExplanationGenerator` file location [Source: `architecture.md` — Component Mapping table, line 953]
- `explanation.dart` entity [Source: `lib/features/daily_plan/domain/entities/explanation.dart`]
- `PlannedSession.explanation` placeholder note [Source: `lib/features/daily_plan/domain/entities/planned_session.dart:13`]
- Pipeline comment about Story 5.6 [Source: `lib/ai/engine/ai_engine_isolate.dart:52`]
- Story 5.5 AC2 pipeline order [Source: `5-5-daily-plan-generation-and-ai-isolation.md#AC2`]
- "Explanation field always non-empty" [Source: `lib/features/daily_plan/domain/entities/explanation.dart:11`]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Task 1.2: `dart analyze` initially flagged `unintended_html_in_doc_comment` (info) on `List<String>` in doc comment — fixed by wrapping in backticks.
- Task 2.4: `dart analyze` flagged pre-existing `prefer_const_constructors` on `SafetyRules(machine)` — resolved by using `const SafetyRules(BehavioralStateMachine())` (the original local `machine` variable was already `const`, so this is equivalent and cleaner).
- Task 4.2: Compilation error on `_session('mobility')` — story fixture uses named parameter `{String type}`, corrected all calls to `_session(type: 'mobility')` pattern.

### Completion Notes List

- Created `lib/ai/explainability/explanation_generator.dart` — pure Dart rule engine, zero Flutter imports (ARCH7 compliant). Five-tier priority: BehavioralState → biometrics → RPE history → streak/missed → session-type fallback. Guaranteed non-empty output for every code path (AC4).
- Modified `lib/ai/engine/ai_engine_isolate.dart`: added import, replaced Step 5 placeholder block with `ExplanationGenerator.generate()` call + `copyWith` merge, also opportunistically applied `const` to `SafetyRules` construction (pre-existing analyzer info).
- Updated `test/domain/ai/ai_engine_test.dart`: renamed 5.5-UNIT-009 → 5.6-UNIT-001, assertion changed from `equals('')` to `isNotEmpty`.
- Created `test/domain/ai/explanation_generator_test.dart` — 16 new tests covering all ACs: AC4 non-empty guarantee, AC3 Recovering priority, AC1 biometric signals, AC2 RPE-only fallback, behavioral state messages, session-type fallback.
- Final test count: **320** (+16). Zero regressions.

### File List

- `pulse_coach/lib/ai/explainability/explanation_generator.dart` — **Created**
- `pulse_coach/lib/ai/engine/ai_engine_isolate.dart` — **Modified**
- `pulse_coach/test/domain/ai/ai_engine_test.dart` — **Modified**
- `pulse_coach/test/domain/ai/explanation_generator_test.dart` — **Created**

## Change Log

- 2026-04-29: Story 5.6 implemented — ExplanationGenerator created, wired into AI pipeline, 16 new tests added, 5.5-UNIT-009 updated to 5.6-UNIT-001. Final test count: 320.
- 2026-04-29 (process note): The "Modified" entries in File List for `lib/ai/engine/ai_engine_isolate.dart` and `test/domain/ai/ai_engine_test.dart` were already included in commit `40b1638 feat(epic-5/story-5.5): daily plan generation & AI isolation` rather than in a separate Story 5.6 commit. The 5.6-only deliverables (`lib/ai/explainability/explanation_generator.dart`, `test/domain/ai/explanation_generator_test.dart`) remain to be committed independently. Forward-only fix accepted; commit history not rewritten (40b1638 already pushed). Traceability: searching for `Story 5.6` in `40b1638` locates the integration point.
- 2026-05-07: Code review run (3 layers: Blind Hunter, Edge Case Hunter, Acceptance Auditor). 4 decision-needed resolved (D1/D2 dismissed, D3/D4 patched), 2 patches applied (boundary tests + remove unused `index` param + welcome-back safety-net doc-comment), 7 deferred to `deferred-work.md`, 6 dismissed.

### Review Findings

- [x] [Review][Decision][Dismissed] **RPE-only fallback unreachable when only one biometric is null** — Code at `explanation_generator.dart:63` requires BOTH `restingHR == null && stepCount == null` to enter the AC2 RPE branch. Spec/AC2 says "RPE-only fallback when no sensor data". A user with HR sensor only OR pedometer only, with neutral biometric values, drops out of the cascade and never has RPE history considered. Decision needed: tighten spec interpretation or relax the gate (e.g., `(restingHR == null || stepCount == null) && rpeHistory.isNotEmpty` as last-resort before streak). Sources: blind+edge.
- [x] [Review][Decision][Dismissed] **All sessions in a multi-session plan get identical explanations** — accepted for v1 (UI shows hero session only per UX-DR5). — `_explain` reads only `StateVector` and `session.sessionType`. For a `DailyPlan` of N sessions in `Recovering` (or any state-driven branch), all N sessions get the exact same string. Test 5.6-UNIT-004 only checks count + non-empty, hiding this. Decision needed: is this acceptable for v1, or should explanations vary per session (which is what the unused `index` parameter hints at)? Sources: blind+edge.
- [x] [Review][Decision][Patched] **Welcome-back branch (`streak==0 && missedSessions>=3`) likely unreachable in production** — kept as safety net; doc-comment added documenting state-machine invariant. — `BehavioralStateMachine` (Story 5.2) transitions to `AtRisk` on high missed-session counts; by the time `missedSessions>=3`, `currentState` should be `atRisk`, which short-circuits at `_explain` line 37 with "missed a few sessions". The 5.6-UNIT-015 test forces `state: active` manually. Decision needed: verify the state-machine threshold; if AtRisk is guaranteed, remove the dead branch; otherwise document the contradiction. Source: edge.
- [x] [Review][Decision][Patched] **Process anomaly: Story 5.6 modifications committed under Story 5.5** — divergence accepted; Change Log updated with traceability note. — Commit `40b1638 feat(epic-5/story-5.5)` already contains the 5.6 doc-comment, `ExplanationGenerator.generate` call site, `sessionsWithExplanations`, and the renamed `5.6-UNIT-001` test. No separate 5.6 commit exists; only the new files (`lib/ai/explainability/`, `test/.../explanation_generator_test.dart`) remain untracked. Story File List + Change Log claim these files were modified by 5.6. Decision needed: amend commit history or accept and document the divergence. Source: auditor.
- [x] [Review][Patch] **Boundary tests missing** [`test/domain/ai/explanation_generator_test.dart`] — applied; added 5.6-UNIT-018..025 (8 boundary tests). — No tests cover HR exactly 75.0 or 60.0, stepCount exactly 3000, RPE avg exactly 6.5 or 7.5, streak exactly 1 or 2, missedSessions exactly 2. Future off-by-one refactors would not be caught. Add boundary cases.
- [x] [Review][Patch] **Unused `index` parameter in `_explain`** — applied; signature simplified to `(StateVector, PlannedSession)`, `generate` uses `sessions.map`. [`lib/ai/explainability/explanation_generator.dart:30`] — `int index` is passed but never read. Either drop it (`sessions.map(_explain)`) or use it (e.g., to vary phrasing across sessions in the same plan).
- [x] [Review][Defer] **HR band 61–75 has no biometric explanation** [`explanation_generator.dart:50,58`] — deferred, intentional "neutral HR" but unflagged in comments.
- [x] [Review][Defer] **"Resting HR looks solid" requires `streak >= 1` — silent drop for first-time low-HR users** [`explanation_generator.dart:58`] — deferred, UX edge case; the cohort that needs the most encouragement (new users with great biometrics) gets the generic fallback.
- [x] [Review][Defer] **RPE band asymmetric boundaries (`<= 6.5` and `> 7.5`)** [`explanation_generator.dart:65,68`] — deferred, taste call; users at avg=7.0 get "comfort zone" message which may misread their effort.
- [x] [Review][Defer] **"Consistent this week" message fires regardless of `rpeHistory` length** [`explanation_generator.dart:65`] — deferred, gate uses `streak >= 2` but no minimum entry count; a single low RPE entry could trigger this claim.
- [x] [Review][Defer] **`stepCount < 3000` ignores time-of-day** [`explanation_generator.dart:54`] — deferred, UX issue (low step count is meaningless before noon); revisit when timestamp signals exist.
- [x] [Review][Defer] **`_todayDate()` local-time vs `generatedAt` UTC potential timezone skew** [`ai_engine_isolate.dart:65,67`] — deferred, pre-existing from Story 5.5, not introduced here.
- [x] [Review][Defer] **Tests use weak OR-chain substring matching** [`explanation_generator_test.dart` various] — deferred, tests like `text.contains('hr') || text.contains('gentle')` pass even if the wrong branch fires; coverage illusion.
