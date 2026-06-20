# Story 7.1: StateIndicator Component

Status: done

## Story

As a user,
I want to see my current behavioral state with a plain-language explanation,
So that I understand why today's sessions are calibrated the way they are.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | `StateIndicator` is rendered with `BehavioralState.active` | No transition fired this cycle | Dot + label **"In forma"** in Primary color (`#7DD3C0`); static sub-copy *"Pronto per il piano di oggi."* displayed |
| AC2 | `StateIndicator` is rendered with `BehavioralState.fatigued` | No transition fired this cycle | Dot + label **"Sotto sforzo"** in Secondary color (`#A78BDA`); static sub-copy *"Oggi alleggeriamo per recuperare."* |
| AC3 | `StateIndicator` is rendered with `BehavioralState.atRisk` | No transition fired this cycle | Dot + label **"In ripresa"** in Tertiary color (`#E8C87A`); static sub-copy *"Ripartiamo con calma. Sessioni brevi e leggere."* |
| AC4 | `StateIndicator` is rendered with `BehavioralState.recovering` | No transition fired this cycle | Dot + label **"In recupero"** in Secondary at 70% opacity; static sub-copy *"Costruiamo il ritmo, un passo alla volta."* |
| AC5 | `atRisk` and `recovering` are visually similar | Widget renders both | Icon/glyph disambiguates: `atRisk` = warning glyph, `recovering` = restore glyph |
| AC6 | `BehavioralTransition.stateChanged == true` (i.e. `transitionMessage != null` passed to widget) | Widget renders | Static sub-copy is **replaced** by the FR14 transition message; static copy is shown only when `transitionMessage == null` |
| AC7 | `lib/l10n/state_messages.it.arb` is inspected | File is checked | Contains exactly **15 keys**: 7 `transition_{from}_{to}`, 4 `state_label_{name}`, 4 `state_static_{name}` |
| AC8 | Load-bearing Q2 invariant (state-graph decision) | Regression test runs | `transition_active_fatigued` **≠** `transition_recovering_fatigued`; if a future edit makes them equal the test must fail |
| AC9 | `BehavioralStateMachine` after Story 7.1 ships | Code is inspected | Rule set matches `ai-state-graph-product-decisions-2026-05-15.md` §"Final Rule Set" — exactly **6 prioritized rules** (Rule 4 tightened per Q3, Rule 6 added per Q2) |
| AC10 | Widget typography | Widget renders | State label: H3 = Plus Jakarta Sans Medium 17sp; sub-copy: Body Small = Plus Jakarta Sans Regular 13sp, `onSurfaceVariant` color; **no emoji** anywhere in `StateIndicator` |
| AC11 | Q2 writing rules | All strings in `state_messages.it.arb` are reviewed | All strings satisfy: seconda persona singolare; presente; constatazione + invito; ≤ 2 sentences; no internal state codes (`atRisk`, etc.); no clinical/gamified register; `!` only in `recovering → active` and `state_label_active` strings |

## Tasks / Subtasks

- [x] Task 1: Update `BehavioralStateMachine` — add Q3 tightening + Q2 rule (AC9)
  - [x] In `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart`:
    - **Replace Rule 4** (currently: `rpe.last-1 <= 7 AND rpe.last-2 <= 7`) with the Q3 tightened rule: `_lastNAvg(rpe, 3) <= 7.0 AND missedSessions == 0`. Guard: `rpe.length >= 3` (do NOT fire on insufficient data).
    - **Add Rule 6** after Rule 5 (`recovering → active`): `recovering → fatigued` when `rpe.isNotEmpty && rpe.last >= 9`. Update class-level doc comment to "6 rules".
    - Update Rule 4 transition messages to the Italian strings from the copy doc.
    - Rule 2 transition message update to Italian: `'Il corpo chiede una pausa più lunga. Riprendiamo dolcemente.'`
    - Rule 3 transition message update to Italian: `'Hai spinto forte. Oggi alleggeriamo: sessione corta.'`
    - Rule 5 transition message update to Italian: `'Sei di nuovo in forma! Riprendiamoci il piano completo.'`

- [x] Task 2: Update behavioral state machine tests (AC9 — update 5.2-UNIT-011/012, add Q3/Q2 tests)
  - [x] In `pulse_coach/test/domain/ai/behavioral_state_machine_test.dart`:
    - **Update** `5.2-UNIT-011` and `5.2-UNIT-012` fixtures: the Q3 rule now requires ≥ 3 RPE values and `missedSessions == 0`. Change fixtures to provide `rpe: [5, 5, 6]` and `missed: 0`.
    - **Add** Q3 tests group (4 new tests): `7.1-UNIT-Q3-001..004`.
    - **Add** Q2 tests group (4 new tests): `7.1-UNIT-Q2-001..004`.

- [x] Task 3: Create `lib/l10n/state_messages.it.arb` (AC7, AC11)
  - [x] Create `pulse_coach/lib/l10n/` directory (new).
  - [x] Write the 15-key ARB file (see Dev Notes for exact content).

- [x] Task 4: Create `StateIndicator` widget (AC1–AC6, AC10)
  - [x] Create `pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart` (NEW).
  - [x] Widget signature: `StateIndicator({required BehavioralState state, String? transitionMessage})`.
  - [x] Color logic: `active` → `primaryColor`, `fatigued` → `secondary`, `atRisk` → `tertiary`, `recovering` → `secondary.withOpacity(0.70)`.
  - [x] Icon logic: `atRisk` → `Icons.warning_amber_outlined`, `recovering` → `Icons.autorenew`, others → colored filled dot (`Container` with `BoxShape.circle`).
  - [x] Copy logic: `transitionMessage != null` → show transition message; else show static copy from strings matching `state_messages.it.arb`.
  - [x] Typography: label = `TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500, fontSize: 17)`, sub-copy = `Theme.of(context).textTheme.bodySmall!.copyWith(color: pulseTheme.onSurfaceVariant)`.
  - [x] No emoji anywhere. No internal state code strings exposed.

- [x] Task 5: Write widget tests (AC1–AC11)
  - [x] Create `pulse_coach/test/widget/state_indicator_test.dart` (NEW).
  - [x] Write ~11 tests (see Dev Notes for full specs: WIDGET-001..009, ARB-001..002).

- [x] Task 6: Gate verification
  - [x] `flutter test` from `pulse_coach/` — must pass (target ≈ 412 + ~19 new - 0 net = ~431). See Dev Notes for exact count.
  - [x] `flutter analyze` from `pulse_coach/` — must show **0 issues**.

## Dev Notes

---

### What This Story Is

Story 7.1 is a **component + state machine completion** story:

1. Completes the 6-rule `BehavioralStateMachine` from the state-graph product decisions (Q3 tightening + Q2 new rule).
2. Creates the `StateIndicator` Flutter widget — a dumb, stateless component. Wiring into `TodayPage` is **Story 7.3's scope**.
3. Establishes `lib/l10n/state_messages.it.arb` as the canonical string source for all state-aware copy.

**Binding (already satisfied):** Story 7.1b shipped in the same PR cluster (done). The `active → atRisk` Rule 1 is already present in `behavioral_state_machine.dart`. Do NOT re-implement or move it.

---

### CRITICAL: BehavioralStateMachine Current State (Post 7.1b)

File: `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart`

Current rules (5 rules — post Story 7.1b):

```
Rule 1: active → atRisk   if missed >= 2           ← 7.1b added, KEEP UNCHANGED
Rule 2: fatigued → atRisk if missed >= 2           ← unchanged
Rule 3: active → fatigued if _lastNAvg(rpe,2) > 8  ← unchanged
Rule 4: atRisk/fatigued → recovering               ← NEEDS Q3 TIGHTENING in this story
         if rpe.length >= 2 && rpe[last-1] <= 7 && rpe[last-2] <= 7
Rule 5: recovering → active                        ← unchanged
         if rpe.length >= 3 && streak >= 3 && _lastNAvg(rpe,3) <= 6.5
(no Rule 6 yet)
```

After Story 7.1, the 6-rule final set:

```
Rule 1: active → atRisk   if missed >= 2                              (unchanged)
Rule 2: fatigued → atRisk if missed >= 2                              (unchanged)
Rule 3: active → fatigued if _lastNAvg(rpe,2) > 8.0                  (unchanged, update message)
Rule 4: atRisk/fatigued → recovering                                  (Q3 TIGHTENED)
         if rpe.length >= 3 && _lastNAvg(rpe,3) <= 7.0 && missed == 0
Rule 5: recovering → active                                           (unchanged, update message)
         if rpe.length >= 3 && streak >= 3 && _lastNAvg(rpe,3) <= 6.5
Rule 6: recovering → fatigued if rpe.isNotEmpty && rpe.last >= 9     (Q2 NEW)
```

---

### Rule 4 Replacement (Q3 Tightening)

**Current Rule 4 code:**
```dart
// Rule 4: atRisk/fatigued → recovering (last 2 sessions RPE ≤ 7)
if ((current == BehavioralState.atRisk ||
        current == BehavioralState.fatigued) &&
    rpe.length >= 2 &&
    rpe[rpe.length - 1] <= 7 &&
    rpe[rpe.length - 2] <= 7) {
  return const BehavioralTransition(
    newState: BehavioralState.recovering,
    transitionMessage: 'Great work staying consistent. Gradually increasing intensity.',
  );
}
```

**Replacement Rule 4 code (Q3):**
```dart
// Rule 4: atRisk/fatigued → recovering (3 RPE avg ≤ 7, missed == 0)
// Q3 from state-graph decision 2026-05-15: raised bar from 2 RPE to 3 avg,
// added missedSessions == 0 guard to prevent false-positive from underwork.
if ((current == BehavioralState.atRisk ||
        current == BehavioralState.fatigued) &&
    rpe.length >= 3 &&
    _lastNAvg(rpe, 3) <= 7.0 &&
    missed == 0) {
  return const BehavioralTransition(
    newState: BehavioralState.recovering,
    transitionMessage:
        'Stai tornando in ritmo. Continuiamo con calma.',
  );
}
```

**Note:** `transition_atRisk_recovering` and `transition_fatigued_recovering` use the SAME Italian string (intentional per copy doc). The hard-coded message here matches. Rule 2 and Rule 3 messages should also be updated to the canonical Italian strings (see below).

---

### Rule 6 Addition (Q2 — `recovering → fatigued`)

Add after Rule 5 (`recovering → active`), BEFORE the final no-transition return:

```dart
// Rule 6: recovering → fatigued (overload signal while recovering)
// Q2 from state-graph decision 2026-05-15: single RPE >= 9 dissonance
// while in recovering state is too punitive for atRisk but is real signal.
if (current == BehavioralState.recovering &&
    rpe.isNotEmpty &&
    rpe.last >= 9) {
  return const BehavioralTransition(
    newState: BehavioralState.fatigued,
    transitionMessage:
        'Stiamo rientrando, ma l\'ultimo sforzo è stato intenso. '
        'Torniamo a una sessione facile.',
  );
}
```

**Priority guard for Q2:** Rule 5 (`recovering → active`) appears BEFORE Rule 6 in the code. If both conditions are met (recovering, 3 RPE avg ≤ 6.5, streak ≥ 3, AND rpe.last >= 9), Rule 5 fires first. This is correct by spec: "→ active should win because it requires sustained signal."

---

### All Transition Messages to Set (Canonical Italian Strings)

After Story 7.1, all rule messages in `behavioral_state_machine.dart` must be Italian:

| Rule | Code label | Canonical Italian string |
|---|---|---|
| Rule 1 | `transition_active_atRisk` | `'Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi.'` ← **already correct from 7.1b** |
| Rule 2 | `transition_fatigued_atRisk` | `'Il corpo chiede una pausa più lunga. Riprendiamo dolcemente.'` |
| Rule 3 | `transition_active_fatigued` | `'Hai spinto forte. Oggi alleggeriamo: sessione corta.'` |
| Rule 4 | `transition_atRisk_recovering` / `transition_fatigued_recovering` | `'Stai tornando in ritmo. Continuiamo con calma.'` |
| Rule 5 | `transition_recovering_active` | `'Sei di nuovo in forma! Riprendiamoci il piano completo.'` |
| Rule 6 | `transition_recovering_fatigued` | `'Stiamo rientrando, ma l\'ultimo sforzo è stato intenso. Torniamo a una sessione facile.'` |

---

### State Machine Tests to UPDATE (5.2-UNIT-011 and 5.2-UNIT-012)

These tests currently pass with Rule 4's old logic (2 RPE ≤ 7). The Q3 tightening BREAKS them. You MUST update their fixtures in `behavioral_state_machine_test.dart`:

**5.2-UNIT-011** (currently something like `atRisk + [5, 6] → recovering`):
- Change fixture: `rpe: [5, 6, 5]` (3 values, avg ≤ 7.0), `missed: 0`

**5.2-UNIT-012** (currently `fatigued + [5, 6] → recovering`):
- Change fixture: `rpe: [5, 6, 5]` (3 values, avg ≤ 7.0), `missed: 0`

Do NOT skip or remove these tests — they must pass after your fixture updates.

---

### New State Machine Test Specs (Q3 and Q2)

Add these groups to `pulse_coach/test/domain/ai/behavioral_state_machine_test.dart`:

```dart
// ── Q3: atRisk/fatigued → recovering (tightened rule) ────────────────────────

group('atRisk/fatigued → recovering — Q3 tightened rule', () {
  test('7.1-UNIT-Q3-001: atRisk + 3 RPE avg ≤ 7 + missed=0 → recovering', () {
    final sv = _sv(state: BehavioralState.atRisk, rpe: [5, 6, 6], missed: 0);
    final result = machine.evaluate(sv);
    expect(result.newState, equals(BehavioralState.recovering));
    expect(result.stateChanged, isTrue);
  });

  test('7.1-UNIT-Q3-002: insufficient data (only 2 RPE) → no transition even with avg ≤ 7', () {
    final sv = _sv(state: BehavioralState.atRisk, rpe: [5, 6], missed: 0);
    final result = machine.evaluate(sv);
    expect(result.newState, equals(BehavioralState.atRisk));
    expect(result.stateChanged, isFalse);
  });

  test('7.1-UNIT-Q3-003: avg ≤ 7 but missed ≥ 1 → no transition', () {
    final sv = _sv(state: BehavioralState.fatigued, rpe: [5, 6, 5], missed: 1);
    final result = machine.evaluate(sv);
    expect(result.newState, equals(BehavioralState.fatigued));
    expect(result.stateChanged, isFalse);
  });

  test('7.1-UNIT-Q3-004: avg > 7 (e.g. [8, 7, 7] avg=7.33) → no transition', () {
    final sv = _sv(state: BehavioralState.atRisk, rpe: [8, 7, 7], missed: 0);
    final result = machine.evaluate(sv);
    expect(result.newState, equals(BehavioralState.atRisk));
    expect(result.stateChanged, isFalse);
  });
});

// ── Q2: recovering → fatigued (new rule) ─────────────────────────────────────

group('recovering → fatigued — Q2 new rule', () {
  test('7.1-UNIT-Q2-001: recovering + last RPE = 9 → fatigued', () {
    final sv = _sv(state: BehavioralState.recovering, rpe: [5, 6, 9], missed: 0);
    final result = machine.evaluate(sv);
    expect(result.newState, equals(BehavioralState.fatigued));
    expect(result.stateChanged, isTrue);
    expect(result.transitionMessage, isNotNull);
  });

  test('7.1-UNIT-Q2-002: recovering + last RPE = 10 → fatigued', () {
    final sv = _sv(state: BehavioralState.recovering, rpe: [5, 6, 10], missed: 0);
    final result = machine.evaluate(sv);
    expect(result.newState, equals(BehavioralState.fatigued));
    expect(result.stateChanged, isTrue);
  });

  test('7.1-UNIT-Q2-003: recovering + last RPE = 8 → no transition to fatigued', () {
    final sv = _sv(state: BehavioralState.recovering, rpe: [5, 6, 8], missed: 0, streak: 1);
    final result = machine.evaluate(sv);
    expect(result.newState, equals(BehavioralState.recovering));
    expect(result.stateChanged, isFalse);
  });

  test(
    '7.1-UNIT-Q2-004: priority guard — recovering→active fires first when both Q2 and recovery conditions met',
    () {
      // rpe.last = 9 (Q2 fires) but also 3-avg ≤ 6.5 and streak ≥ 3 (Q5 fires).
      // Rule 5 has priority 5, Rule 6 has priority 6 → Rule 5 wins → active.
      // Use rpe [4, 5, 9]: avg = 6.0 ≤ 6.5 ✓; last = 9 ≥ 9 ✓.
      final sv = _sv(state: BehavioralState.recovering, rpe: [4, 5, 9], missed: 0, streak: 3);
      final result = machine.evaluate(sv);
      expect(result.newState, equals(BehavioralState.active));
    },
  );
});
```

---

### `lib/l10n/state_messages.it.arb` — Full File Content

Create `pulse_coach/lib/l10n/state_messages.it.arb` with this exact content:

```json
{
  "@@locale": "it",
  "@@description": "StateIndicator copy — behavioral state labels, static sub-copy, and FR14 transition messages.",

  "state_label_active": "In forma",
  "state_label_fatigued": "Sotto sforzo",
  "state_label_atRisk": "In ripresa",
  "state_label_recovering": "In recupero",

  "state_static_active": "Pronto per il piano di oggi.",
  "state_static_fatigued": "Oggi alleggeriamo per recuperare.",
  "state_static_atRisk": "Ripartiamo con calma. Sessioni brevi e leggere.",
  "state_static_recovering": "Costruiamo il ritmo, un passo alla volta.",

  "transition_active_atRisk": "Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi.",
  "transition_active_fatigued": "Hai spinto forte. Oggi alleggeriamo: sessione corta.",
  "transition_fatigued_atRisk": "Il corpo chiede una pausa più lunga. Riprendiamo dolcemente.",
  "transition_recovering_fatigued": "Stiamo rientrando, ma l'ultimo sforzo è stato intenso. Torniamo a una sessione facile.",
  "transition_atRisk_recovering": "Stai tornando in ritmo. Continuiamo con calma.",
  "transition_fatigued_recovering": "Stai tornando in ritmo. Continuiamo con calma.",
  "transition_recovering_active": "Sei di nuovo in forma! Riprendiamoci il piano completo."
}
```

**Key count check:** 4 labels + 4 static + 7 transitions = **15 keys** ✓ (AC7)

**Note:** `flutter_localizations` / `gen_l10n` is **NOT** set up in this project. The ARB file is the canonical spec. The Dart code reads strings from a plain `StateMessages` helper class (see widget dev notes below) that mirrors these keys. Do NOT add `flutter_localizations` to `pubspec.yaml` in this story.

---

### `StateIndicator` Widget — Implementation Guide

**File:** `pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart`

```dart
import 'package:flutter/material.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

/// Displays the current behavioral state label + one-line explanation.
///
/// Pass [transitionMessage] (non-null) when a state transition fired this
/// evaluation cycle — the widget replaces static copy with the FR14 message.
/// When [transitionMessage] is null, static copy for [state] is shown.
///
/// Typography: H3 (17sp Medium) for label; Body Small (13sp Regular,
/// onSurfaceVariant color) for sub-copy. No emoji. No internal state codes.
class StateIndicator extends StatelessWidget {
  final BehavioralState state;
  final String? transitionMessage;

  const StateIndicator({
    super.key,
    required this.state,
    this.transitionMessage,
  });

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final stateColor = _stateColor(state, pulseTheme);
    final label = _stateLabel(state);
    final subCopy = transitionMessage ?? _staticCopy(state);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StateIcon(state: state, color: stateColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  color: stateColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subCopy,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _stateColor(BehavioralState state, PulseCoachTheme theme) {
    switch (state) {
      case BehavioralState.active:
        return theme.primaryColor;
      case BehavioralState.fatigued:
        return theme.secondary;
      case BehavioralState.atRisk:
        return theme.tertiary;
      case BehavioralState.recovering:
        return theme.secondary.withOpacity(0.70);
    }
  }

  String _stateLabel(BehavioralState state) {
    switch (state) {
      case BehavioralState.active:    return 'In forma';
      case BehavioralState.fatigued:  return 'Sotto sforzo';
      case BehavioralState.atRisk:    return 'In ripresa';
      case BehavioralState.recovering: return 'In recupero';
    }
  }

  String _staticCopy(BehavioralState state) {
    switch (state) {
      case BehavioralState.active:     return 'Pronto per il piano di oggi.';
      case BehavioralState.fatigued:   return 'Oggi alleggeriamo per recuperare.';
      case BehavioralState.atRisk:     return 'Ripartiamo con calma. Sessioni brevi e leggere.';
      case BehavioralState.recovering: return 'Costruiamo il ritmo, un passo alla volta.';
    }
  }
}

/// State-disambiguating icon. atRisk = warning glyph; recovering = restore glyph;
/// active/fatigued = filled colored dot.
class _StateIcon extends StatelessWidget {
  final BehavioralState state;
  final Color color;

  const _StateIcon({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BehavioralState.atRisk:
        return Icon(Icons.warning_amber_outlined, color: color, size: 20);
      case BehavioralState.recovering:
        return Icon(Icons.autorenew, color: color, size: 20);
      case BehavioralState.active:
      case BehavioralState.fatigued:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}
```

**Critical constraints:**
- No `import 'package:flutter/material.dart'` forbidden here — this is a presentation widget, Flutter imports are allowed.
- No DI (`@injectable`, `get_it`) on this widget — it is a pure stateless component.
- No `BlocBuilder` — state is passed in as a param. The Today page (Story 7.3) will wire BLoC → `StateIndicator`.
- The font family string `'PlusJakartaSans'` must match the google_fonts registration in `app_theme.dart`. Check the actual registered family name if it differs (may be `'PlusJakartaSans'` or `'Plus Jakarta Sans'`).

---

### `StateIndicator` Widget Test Specs

File: `pulse_coach/test/widget/state_indicator_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/today/presentation/widgets/state_indicator.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: Padding(padding: EdgeInsets.all(16), child: child)),
    );

void main() {
  group('StateIndicator — state labels and colors (AC1–AC4)', () {
    testWidgets('7.1-WIDGET-001: active state shows "In forma"', (tester) async {
      await tester.pumpWidget(_wrap(
        const StateIndicator(state: BehavioralState.active),
      ));
      expect(find.text('In forma'), findsOneWidget);
      expect(find.text('Pronto per il piano di oggi.'), findsOneWidget);
    });

    testWidgets('7.1-WIDGET-002: fatigued state shows "Sotto sforzo"', (tester) async {
      await tester.pumpWidget(_wrap(
        const StateIndicator(state: BehavioralState.fatigued),
      ));
      expect(find.text('Sotto sforzo'), findsOneWidget);
      expect(find.text('Oggi alleggeriamo per recuperare.'), findsOneWidget);
    });

    testWidgets('7.1-WIDGET-003: atRisk state shows "In ripresa"', (tester) async {
      await tester.pumpWidget(_wrap(
        const StateIndicator(state: BehavioralState.atRisk),
      ));
      expect(find.text('In ripresa'), findsOneWidget);
      expect(find.text('Ripartiamo con calma. Sessioni brevi e leggere.'), findsOneWidget);
    });

    testWidgets('7.1-WIDGET-004: recovering state shows "In recupero"', (tester) async {
      await tester.pumpWidget(_wrap(
        const StateIndicator(state: BehavioralState.recovering),
      ));
      expect(find.text('In recupero'), findsOneWidget);
      expect(find.text('Costruiamo il ritmo, un passo alla volta.'), findsOneWidget);
    });
  });

  group('StateIndicator — copy logic (AC6)', () {
    testWidgets('7.1-WIDGET-005: no transitionMessage → static copy shown', (tester) async {
      await tester.pumpWidget(_wrap(
        const StateIndicator(state: BehavioralState.active, transitionMessage: null),
      ));
      expect(find.text('Pronto per il piano di oggi.'), findsOneWidget);
    });

    testWidgets('7.1-WIDGET-006: transitionMessage != null → transition copy replaces static', (tester) async {
      const msg = 'Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi.';
      await tester.pumpWidget(_wrap(
        const StateIndicator(state: BehavioralState.atRisk, transitionMessage: msg),
      ));
      expect(find.text(msg), findsOneWidget);
      // Static copy must NOT appear
      expect(find.text('Ripartiamo con calma. Sessioni brevi e leggere.'), findsNothing);
    });
  });

  group('StateIndicator — icon disambiguation (AC5)', () {
    testWidgets('7.1-WIDGET-007: atRisk and recovering show different icons', (tester) async {
      await tester.pumpWidget(_wrap(
        const Column(children: [
          StateIndicator(state: BehavioralState.atRisk),
          StateIndicator(state: BehavioralState.recovering),
        ]),
      ));
      // Both should render icons from Icon widget (not dots)
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.length, greaterThanOrEqualTo(2));
      // The two Icon widgets must have different icon data
      final atRiskIcon = icons[0].icon;
      final recoveringIcon = icons[1].icon;
      expect(atRiskIcon, isNot(equals(recoveringIcon)));
    });
  });

  group('StateIndicator — no internal state codes exposed (AC11)', () {
    testWidgets('7.1-WIDGET-008: no internal code "atRisk" appears in any rendered text', (tester) async {
      for (final state in BehavioralState.values) {
        await tester.pumpWidget(_wrap(StateIndicator(state: state)));
        expect(find.textContaining('atRisk'), findsNothing);
        expect(find.textContaining('fatigued'), findsNothing);
        expect(find.textContaining('active'), findsNothing);
        expect(find.textContaining('recovering'), findsNothing);
      }
    });
  });

  group('StateMessages — ARB invariants (AC7, AC8)', () {
    test('7.1-ARB-001: ARB file has exactly 15 user-facing keys', () {
      // Canonical strings from state_messages.it.arb — counted here:
      const labels = ['In forma', 'Sotto sforzo', 'In ripresa', 'In recupero'];
      const statics = [
        'Pronto per il piano di oggi.',
        'Oggi alleggeriamo per recuperare.',
        'Ripartiamo con calma. Sessioni brevi e leggere.',
        'Costruiamo il ritmo, un passo alla volta.',
      ];
      const transitions = [
        'Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi.',
        'Hai spinto forte. Oggi alleggeriamo: sessione corta.',
        'Il corpo chiede una pausa più lunga. Riprendiamo dolcemente.',
        'Stiamo rientrando, ma l\'ultimo sforzo è stato intenso. Torniamo a una sessione facile.',
        'Stai tornando in ritmo. Continuiamo con calma.', // atRisk_recovering
        'Stai tornando in ritmo. Continuiamo con calma.', // fatigued_recovering (same string)
        'Sei di nuovo in forma! Riprendiamoci il piano completo.',
      ];
      // 4 + 4 + 7 = 15
      expect(labels.length + statics.length + transitions.length, equals(15));
    });

    test(
      '7.1-ARB-002: transition_active_fatigued != transition_recovering_fatigued (load-bearing Q2 invariant)',
      () {
        const activeFatigued = 'Hai spinto forte. Oggi alleggeriamo: sessione corta.';
        const recoveringFatigued =
            'Stiamo rientrando, ma l\'ultimo sforzo è stato intenso. Torniamo a una sessione facile.';
        expect(activeFatigued, isNot(equals(recoveringFatigued)));
      },
    );
  });
}
```

---

### Font Family Name — Verify Before Using

In `app_theme.dart` / `pubspec.yaml`, the google_fonts package registers `Plus Jakarta Sans`. Verify the exact family name string used in existing `TextStyle` calls elsewhere in the project (e.g., `profile_setup_screen.dart`, etc.). If the project uses `GoogleFonts.plusJakartaSans()`, use that pattern instead of a raw `TextStyle(fontFamily: ...)`. Do not break the font loading that already works.

---

### `flutter analyze` Zero-Tolerance

Story 7.1b left the project at 0 analyzer issues. This story must preserve that:
- Add `// ignore:` only with a documented reason.
- The new widget file must have no unused imports, no late-initialized fields that could be non-null, no dead code branches.
- The `BehavioralState` switch expressions in `_stateColor`, `_stateLabel`, `_staticCopy`, `_build` must be exhaustive (no `default` fallthrough that masks future states).

---

### Build Runner

**Not required.** No freezed classes modified, no injectable constructor changed, no Drift annotations added. The new widget is a plain `StatelessWidget`. Verify `injection.config.dart` is byte-stable after all changes.

---

### Test Count Accounting

| Source | Count |
|---|---|
| Baseline (post Story 7.1b, full suite per change log) | 412 |
| `behavioral_state_machine_test.dart` — update fixtures for 5.2-UNIT-011/012 | ±0 (replace, no net change) |
| `behavioral_state_machine_test.dart` — Q3 tests (`7.1-UNIT-Q3-001..004`) | +4 |
| `behavioral_state_machine_test.dart` — Q2 tests (`7.1-UNIT-Q2-001..004`) | +4 |
| `state_indicator_test.dart` — widget + ARB tests (`7.1-WIDGET-001..008, 7.1-ARB-001..002`) | +10 |
| **Estimated target** | **426** |

---

### Out of Scope (Explicit)

- Wiring `StateIndicator` into `TodayPage` — **Story 7.3**.
- Extending `DailyPlanState.loaded` or `DailyPlanBloc` to carry transition messages — **Story 7.3**.
- English ARB file (`state_messages.en.arb`) — explicitly out of scope for Epic 7.
- Time-of-day / weather / streak copy variants — explicitly out of scope (JTBD axis is state only).
- `flutter_localizations` / `gen_l10n` setup — out of scope; ARB is the canonical spec, strings are inline in the widget.
- CompletionRing (small variant in state bar) — **Story 7.4**.
- `retryAttempts` split in `DailyPlanBloc` — deferred to Story 7.x, not Story 7.1.

---

### Files Created / Modified

**New files:**
- `pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart`
- `pulse_coach/lib/l10n/state_messages.it.arb`
- `pulse_coach/test/widget/state_indicator_test.dart`

**Modified files:**
- `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart` (Rule 4 tightened, Rule 6 added, messages updated, doc comment updated to 6 rules)
- `pulse_coach/test/domain/ai/behavioral_state_machine_test.dart` (5.2-UNIT-011/012 fixtures updated, Q3+Q2 groups added)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status: backlog → ready-for-dev)

---

### References

- State-graph product decisions (Q1, Q2, Q3, Final Rule Set): [`_bmad-output/implementation-artifacts/ai-state-graph-product-decisions-2026-05-15.md`]
- Explanation copy decisions (Q1–Q5, all 15 canonical strings): [`_bmad-output/implementation-artifacts/explanation-copy-product-decisions-2026-05-15.md`]
- `BehavioralStateMachine` current code: [`pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart`]
- `BehavioralTransition` (stateChanged computed field): [`pulse_coach/lib/ai/state_machine/behavioral_transition.dart`]
- `BehavioralState` enum: [`pulse_coach/lib/ai/state_machine/behavioral_state.dart`]
- `PulseCoachTheme` tokens (primaryColor, secondary, tertiary, onSurfaceVariant): [`pulse_coach/lib/core/theme/pulse_coach_theme.dart`]
- `AppTheme.darkTheme` (used in widget test `_wrap`): [`pulse_coach/lib/core/theme/app_theme.dart`]
- Existing state machine tests: [`pulse_coach/test/domain/ai/behavioral_state_machine_test.dart`]
- Story 7.1b (done — missedSessions, Rule 1): [`_bmad-output/implementation-artifacts/7-1b-missed-sessions-decay-and-reset.md`]
- Story 7.0 (done — Failure equality): [`_bmad-output/implementation-artifacts/7-0-failure-equality-bloc-regression.md`]
- UX spec (StateIndicator design ref): [`_bmad-output/planning-artifacts/epics.md §UX-DR11`]

## Dev Agent Record

### Agent Model Used

GPT-5

### Debug Log References

- Red phase: `flutter test test/domain/ai/behavioral_state_machine_test.dart` failed on Q3/Q2 expectations before implementation.
- Green phase: `flutter test test/domain/ai/behavioral_state_machine_test.dart` passed after the 6-rule state machine update.
- Widget/ARB checks: `flutter test test/widget/state_indicator_test.dart` passed with 12 tests.
- Regression suite: `flutter test` passed with 432 tests.
- Static analysis: `flutter analyze` passed with 0 issues.

### Completion Notes List

- Updated `BehavioralStateMachine` to the final 6-rule set: Q3 tightened Rule 4, Q2 recovering-to-fatigued Rule 6, and canonical Italian transition messages.
- Added canonical Italian state copy in `state_messages.it.arb` with exactly 15 user-facing keys.
- Added stateless `StateIndicator` widget with state colors, glyph disambiguation for `atRisk`/`recovering`, transition-message override behavior, and theme text styles.
- Added regression tests for Q3/Q2 state-machine behavior, ARB key/string invariants, widget state rendering, icon behavior, typography, and no internal state codes.

### File List

- `_bmad-output/implementation-artifacts/7-1-stateindicator-component.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart`
- `pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart`
- `pulse_coach/lib/l10n/state_messages.it.arb`
- `pulse_coach/test/domain/ai/behavioral_state_machine_test.dart`
- `pulse_coach/test/widget/state_indicator_test.dart`

### Change Log

- 2026-05-15: Implemented Story 7.1 StateIndicator component and final behavioral state-machine rules; validated with full test suite and analyzer.
- 2026-05-15: Code review (Blind Hunter + Edge Case Hunter + Acceptance Auditor) — 3 patches, 9 deferred, 7 dismissed. No AC violations.

### Review Findings

_Code review 2026-05-15 — Blind Hunter (adversarial) + Edge Case Hunter + Acceptance Auditor. Acceptance Auditor verdict: AC1–AC11 satisfied, no blocking violations._

**Patches (fixable now, unambiguous):**

- [x] [Review][Patch] Defensive assert on `PulseCoachTheme` extension lookup — replace null-bang with `assert(... != null, '...')` for clearer diagnostic if ever rendered outside `AppTheme` [`pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart:21`]
- [x] [Review][Patch] Rename `testerText` to `_testerText` (prefix with underscore) — top-level non-private helper pollutes test symbol space [`pulse_coach/test/widget/state_indicator_test.dart:18`]
- [x] [Review][Patch] Expand emoji regex in `7.1-ARB-003` to also cover `U+2600–U+27BF` (misc symbols/dingbats) — current range `U+1F300–U+1FAFF` misses ✓/⚠/❤ [`pulse_coach/test/widget/state_indicator_test.dart:246`]

**Deferred (real but not actionable in this story):**

- [x] [Review][Defer] Rule 5 priority guard wins over Rule 6 — user with `streak >= 3` and last RPE 9–10 still sees `"Sei di nuovo in forma!"`. Matches decision doc `ai-state-graph-product-decisions-2026-05-15.md` "Final Rule Set" — recorded for future product reconsideration [`behavioral_state_machine.dart` Rule 5/6] — deferred, intentional per decision doc
- [x] [Review][Defer] Rule 4 3-RPE window can include a recent overload (e.g. `[9, 6, 6]` avg=7.0 → recovering) — Q3 spec didn't address residual-overload-in-window case [`behavioral_state_machine.dart:60-72`] — deferred, would require decision-doc update
- [x] [Review][Defer] State-machine source hardcodes Italian transition strings duplicating `state_messages.it.arb` — accepted by spec Dev Notes (`gen_l10n` not yet wired) but creates two sources of truth; AC8 invariant only protects the ARB side [`behavioral_state_machine.dart:42-93`] — deferred, pre-existing per spec
- [x] [Review][Defer] a11y: `_StateIcon` returns plain `Container` dots for `active`/`fatigued` with no `Semantics` label — screen readers get only the text label; AC5 only mandated visual disambiguation [`state_indicator.dart:107-115`] — deferred, no AC requirement
- [x] [Review][Defer] `BehavioralStateMachine.evaluate()` idempotency under repeated calls with unchanged inputs is not test-covered [`behavioral_state_machine_test.dart`] — deferred, no current bug
- [x] [Review][Defer] ARB-loading tests use relative path `File('lib/l10n/state_messages.it.arb')` — works from `pulse_coach/` (baseline) but fails if cwd is repo root or IDE test runner directory [`state_indicator_test.dart:27`] — deferred, baseline CWD documented in CLAUDE.md
- [x] [Review][Defer] Coverage gaps: exact boundary `_lastNAvg(rpe,3) == 7.0`; `missed >= 2` with Rule 4; `AppTextStyles.h3.height=1.35` regression guard; `_StateIcon` `BoxShape.circle` shape assertion; ARB duplicate-key detection [tests] — deferred, low-risk gaps
- [x] [Review][Defer] Test helper fragility: `_text`/`testerText` use `.single` which crashes obscurely on duplicate labels; `7.1-WIDGET-007` indexes icons positionally by tree-walk order [`state_indicator_test.dart:14-23, 155-166`] — deferred, no current bug
- [x] [Review][Defer] Magic alpha value `0.70` for `recovering` color duplicated between widget and test [`state_indicator.dart` + `state_indicator_test.dart`] — deferred, micro-nit

**Dismissed as noise (not recorded as items):** 7 — alleged ARB↔code string divergence (auditor verified match); claim that `5.2-UNIT-013` fixture is unsafe (Rule 4 length-guard blocks before `missed`); "raised bar" comment opinion; Rule 6 adjacent-literal concatenation (compiles to same string as ARB); ARB has only 7 transition keys (matches the 7 reachable transitions); ASCII vs typographic apostrophe (currently consistent in both files); Rule 5 winning over Rule 6 framed as a code bug (it is the decision-doc'd priority).
