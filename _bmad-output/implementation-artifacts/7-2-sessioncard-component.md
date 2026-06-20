# Story 7.2: SessionCard Component

Status: done

## Story

As a user,
I want to see session recommendations in a card that immediately conveys what to do and why,
So that I can decide whether to start in under 3 seconds.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | `HeroSessionCard` is rendered with a `PlannedSession` | Session has type, duration, intensity, and explanation | Card displays: session-type Material Icon (32dp, accent color), session display name, duration (e.g., "5 min"), intensity label (e.g., "Leggera"), AI explanation always visible (Body Small / `onSurfaceVariant`), and a "Inizia sessione" `FilledButton` CTA (FR13, UX-DR5) |
| AC2 | `HeroSessionCard` is rendered | Visual inspection | Card has 16dp padding on all sides, 16dp corner radius, `surfaceContainer` background, subtle `LinearGradient` from accent color (12% opacity, top-left) to `surfaceContainer` (bottom-right) (UX-DR5, UX-DR17) |
| AC3 | `CompactSessionCard` is rendered | Session is provided | Card shows: session-type icon (24dp, accent color), session display name, duration right-aligned, `Icons.chevron_right` — no explanation text, no Start button (UX-DR5) |
| AC4 | Session type is `'cardio'` | Card renders | Accent color is soft coral `const Color(0xFFF0A1B0)`; `'mobility'` uses Primary `#7DD3C0`; `'breathing'` uses Secondary `#A78BDA` (UX-DR1) |

## Tasks / Subtasks

- [x] Task 1: Create `session_card_helpers.dart` with shared logic (AC1, AC3, AC4)
  - [x] Create `pulse_coach/lib/features/today/presentation/widgets/session_card_helpers.dart` (NEW)
  - [x] Function `sessionAccentColor(String sessionType, PulseCoachTheme theme) → Color`:
    - `'cardio'` → `const Color(0xFFF0A1B0)`
    - `'mobility'` → `theme.primaryColor`
    - `'breathing'` → `theme.secondary`
    - unknown → `theme.onSurfaceVariant` (defensive fallback)
  - [x] Function `sessionDisplayName(String sessionType) → String`:
    - `'mobility'` → `'Mobilità'`
    - `'cardio'` → `'Cardio'`
    - `'breathing'` → `'Respirazione'`
    - unknown → `sessionType` (pass-through)
  - [x] Function `sessionIcon(String sessionType) → IconData`:
    - `'mobility'` → `Icons.self_improvement`
    - `'cardio'` → `Icons.favorite_border`
    - `'breathing'` → `Icons.air`
    - unknown → `Icons.fitness_center`
  - [x] Function `intensityLabel(int intensity) → String`:
    - 1–3 → `'Leggera'`
    - 4–7 → `'Moderata'`
    - 8–10 → `'Intensa'`
    - out of range → `'Moderata'` (defensive fallback)
  - [x] All functions are pure Dart (no Flutter Widget code), top-level functions for easy testing

- [x] Task 2: Create `HeroSessionCard` widget (AC1, AC2, AC4)
  - [x] Create `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart` (NEW)
  - [x] Widget signature: `HeroSessionCard({required PlannedSession session, VoidCallback? onStart, Key? key})`
  - [x] **Layout** (Column inside a decorated Container inside a `Semantics` wrapper):
    - Outer: `Semantics` with label `'Prossima sessione: \${displayName}, \${duration}, \${explanation}. Tocca per iniziare.'`
    - `Container` with `BoxDecoration`: `borderRadius: BorderRadius.circular(16)`, gradient (see below), no shadow
    - `Padding(padding: EdgeInsets.all(16), child: Column(...))`
    - Row: `Icon(sessionIcon(...), size: 32, color: accentColor)` + `SizedBox(width: 8)` + `Expanded(Text(displayName, style: H2 — Plus Jakarta Sans SemiBold 20sp))`
    - `SizedBox(height: 8)`
    - Row: `Text(durationLabel, style: bodySmall, color: onSurfaceVariant)` + `SizedBox(width: 12)` + `Text(intensityLabel, style: bodySmall, color: accentColor)`
    - `SizedBox(height: 8)`
    - `Text(session.explanation, style: bodySmall, color: onSurfaceVariant, maxLines: 2, overflow: TextOverflow.ellipsis)`
    - `SizedBox(height: 16)`
    - `SizedBox(width: double.infinity, child: FilledButton(onPressed: onStart, child: Text('Inizia sessione')))`
  - [x] **Gradient**: `LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentColor.withOpacity(0.12), pulseTheme.surfaceContainer])`
  - [x] Use `Theme.of(context).extension<PulseCoachTheme>()!` — assert non-null with `assert(pulseTheme != null, 'HeroSessionCard requires PulseCoachTheme extension')`
  - [x] Duration label: `'\${session.durationMinutes} min'`
  - [x] No `@injectable` / DI — pure stateless component
  - [x] No BLoC — `onStart` callback is wired by parent (Story 7.3)
  - [x] No Hero widget animation tag — Story 7.3 adds Hero tags when wiring the Today screen layout

- [x] Task 3: Create `CompactSessionCard` widget (AC3, AC4)
  - [x] Create `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart` (NEW)
  - [x] Widget signature: `CompactSessionCard({required PlannedSession session, VoidCallback? onTap, Key? key})`
  - [x] **Layout** (`InkWell` wrapping a `Container` with `~56dp` height):
    - `Semantics` with label `'Sessione successiva: \${displayName}, \${duration}. Tocca per selezionare come prossima sessione.'`
    - `InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(...))`
    - `Container` with `BoxDecoration(color: pulseTheme.surfaceContainer, borderRadius: BorderRadius.circular(16))`
    - `Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(...))`
    - Row children:
      1. `Icon(sessionIcon(type), size: 24, color: accentColor)`
      2. `SizedBox(width: 12)`
      3. `Expanded(child: Text(displayName, style: bodyMedium, overflow: TextOverflow.ellipsis))`
      4. `Text(durationLabel, style: bodySmall, color: onSurfaceVariant)`
      5. `SizedBox(width: 4)`
      6. `Icon(Icons.chevron_right, size: 20, color: onSurfaceVariant)`
  - [x] No explanation text, no Start button — strict per AC3
  - [x] No `@injectable` / DI — pure stateless component

- [x] Task 4: Write widget tests (AC1–AC4)
  - [x] Create `pulse_coach/test/widget/session_card_test.dart` (NEW)
  - [x] See Dev Notes for full test specs (7.2-WIDGET-001 through 7.2-WIDGET-016)

- [x] Task 5: Gate verification
  - [x] `flutter test` from `pulse_coach/` — must pass (target ≈ 432 + ~16 new = ~448)
  - [x] `flutter analyze` from `pulse_coach/` — must show **0 issues**

### Review Findings

_Code review 2026-05-15 — Blind Hunter + Edge Case Hunter + Acceptance Auditor (3 layers)._

- [x] [Review][Patch] Compact card: ink ripple hidden by opaque Container — wrapped with `Material(color, borderRadius, clipBehavior: Clip.antiAlias)` over `InkWell` [`pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart:30-72`]
- [x] [Review][Patch] Empty `explanation` produces degenerate Semantics label and blank Text line on Hero — guarded with `isNotEmpty` for both segments; covered by new test `7.2-WIDGET-025` [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart:28-30,77-84`]
- [x] [Review][Patch] Hero `displayName` H2 has no `maxLines`/`overflow` — added `maxLines: 1, overflow: TextOverflow.ellipsis` [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart:57`]
- [x] [Review][Patch] Semantics promises tap action when callback is null — added `button: canStart/canTap`, `onTap: callback` to both `Semantics` wrappers so screen-reader announcement matches actual actionability [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart:27-31`, `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart:26-30`]
- [x] [Review][Patch] Test IDs renumbered — spec's `7.2-WIDGET-001..016` IDs now map 1:1 to the spec scenarios (hero content 001-007 + visual 008-011, compact content 012-016); extras renumbered to 017-025 in separate "extended coverage" groups [`pulse_coach/test/widget/session_card_test.dart`]
- [x] [Review][Defer] Release-mode NPE if `PulseCoachTheme` extension absent — `assert(...) ; pulseThemeOrNull!` pattern strips in release. Follows spec verbatim; cross-cutting with `StateIndicator` — promote to a hardening story across all extension-dependent widgets. [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart:15-20`, `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart:15-20`] — deferred, follows spec
- [x] [Review][Defer] Hero card body not tappable yet Semantics says "Tocca per iniziare" — Story 7.3 wires the full Today screen and may add a hero-level tap surface; revisit label vs. tap target then [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart:27-31`] — deferred, Story 7.3 scope
- [x] [Review][Defer] `sessionAccentColor`/`sessionDisplayName`/`sessionIcon` are case- and whitespace-sensitive — no normalization. Epic 6.5 introduced read-path normalization upstream; risk is low but worth a defensive lower-case/trim if a future data source bypasses the normalization layer [`pulse_coach/lib/features/today/presentation/widgets/session_card_helpers.dart:4-41`] — deferred, upstream-normalized
- [x] [Review][Defer] `durationMinutes` rendered as `"$x min"` with no clamping, plural, or `>60` handling — i18n/intl is out-of-scope for Epic 7 [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart:24`, `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart:24`] — deferred, i18n out-of-scope
- [x] [Review][Defer] Brittle test selectors — `find.byType(Container).first` and `.evaluate().single` produce non-actionable diagnostics on regressions; prefer `Key`s. Tests pass, low impact [`pulse_coach/test/widget/session_card_test.dart:31,36,242,254,403`] — deferred, low impact
- [x] [Review][Defer] WCAG contrast — body text on coral-tinted top-left gradient corner is borderline (~3.7:1); intensity coral text on coral-tinted background <3:1. Colors and 12% alpha are spec-mandated [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart:34-42,70-73`] — deferred, spec-driven
- [x] [Review][Defer] Tests only exercise `AppTheme.darkTheme`; cardio's hardcoded `#F0A1B0` won't theme-switch — no regression guard for that asymmetry [`pulse_coach/test/widget/session_card_test.dart:11`] — deferred, dark-first project
- [x] [Review][Defer] No test for `sessionType = ''` empty-string — renders empty H2 and degenerate Semantics; pairs with [[empty-explanation-patch]] [`pulse_coach/test/widget/session_card_test.dart`] — deferred, low-probability input
- [x] [Review][Defer] Hero `onStart` has no debouncing / double-tap guard — Story 7.3 wires the actual handler and can add busy-state [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart:88-92`] — deferred, Story 7.3 scope

_Dismissed (11): hardcoded italiano (i18n out-of-scope Epic 7); `intensityLabel` silent fallback (defensive design per spec); cardio color hardcoded (spec literal `#F0A1B0`); `AppTextStyles.h2` vs hardcoded `TextStyle` (token abstraction è preferito); `withValues` vs `withOpacity` (code uses modern non-deprecated API); `BoxConstraints(minHeight:56)` (interpretazione corretta di "~56dp"); `clipBehavior` mancante (no overflow expected); RTL handling (it_IT only); `RepaintBoundary` mancante (premature optimization); dartdoc helpers mancanti; Compact Text senza `maxLines` esplicito (default 1 line con ellipsis OK)._

## Dev Notes

---

### What This Story Is

Story 7.2 is a **pure UI component** story. No BLoC, no repository, no use case changes. Deliver two stateless widgets (`HeroSessionCard` + `CompactSessionCard`) that accept a `PlannedSession` and render it. Wiring these into the `TodayPage` is **Story 7.3's scope**.

**Do NOT:**
- Wire anything into `TodayPage` (it stays as a placeholder until 7.3)
- Add a `completedSessionCard` widget (Story 7.3 scope — not in ACs here)
- Add Flutter `Hero` animation tags (Story 7.3 adds those when the swap interaction is built)
- Touch `DailyPlanBloc`, `DailyPlan`, or `PlannedSession` domain model
- Use `CircularProgressIndicator` — there is no loading state in these components; loading shimmer is Story 7.3

---

### PlannedSession Domain Model (READ-ONLY)

File: `pulse_coach/lib/features/daily_plan/domain/entities/planned_session.dart`

```dart
@freezed
abstract class PlannedSession with _$PlannedSession {
  const factory PlannedSession({
    required String sessionType,     // 'mobility' | 'cardio' | 'breathing'
    required int intensity,          // 1–10 (raw AI engine output)
    required int durationMinutes,    // e.g. 5, 10, 15
    required bool isIndoor,
    @Default('') String explanation, // '' is the placeholder; Story 5.6 guarantees non-empty on write
  }) = _PlannedSession;
  ...
}
```

**Critical:** `PlannedSession` has no `title` field. The "session title" in the AC is the display name derived from `sessionType`. There is also no `intensityLabel` — it must be derived from the raw `intensity` int. Both derivations live in `session_card_helpers.dart`.

---

### session_card_helpers.dart — Full Implementation

File: `pulse_coach/lib/features/today/presentation/widgets/session_card_helpers.dart`

```dart
import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

/// Accent color for a given session type.
/// Cardio: soft coral (#F0A1B0); Mobility: Primary (#7DD3C0); Breathing: Secondary (#A78BDA).
/// Unknown types fall back to onSurfaceVariant.
Color sessionAccentColor(String sessionType, PulseCoachTheme theme) {
  switch (sessionType) {
    case 'cardio':
      return const Color(0xFFF0A1B0);
    case 'mobility':
      return theme.primaryColor;
    case 'breathing':
      return theme.secondary;
    default:
      return theme.onSurfaceVariant;
  }
}

/// Italian display name for a session type.
String sessionDisplayName(String sessionType) {
  switch (sessionType) {
    case 'mobility':
      return 'Mobilità';
    case 'cardio':
      return 'Cardio';
    case 'breathing':
      return 'Respirazione';
    default:
      return sessionType;
  }
}

/// Material Icon for a session type (Lottie fallback — no session Lottie assets exist yet).
IconData sessionIcon(String sessionType) {
  switch (sessionType) {
    case 'mobility':
      return Icons.self_improvement;
    case 'cardio':
      return Icons.favorite_border;
    case 'breathing':
      return Icons.air;
    default:
      return Icons.fitness_center;
  }
}

/// Human-readable intensity label from raw 1–10 AI engine int.
/// Ranges: 1–3 = Leggera, 4–7 = Moderata, 8–10 = Intensa.
/// Out-of-range values fall back to Moderata (defensive).
String intensityLabel(int intensity) {
  if (intensity <= 3) return 'Leggera';
  if (intensity <= 7) return 'Moderata';
  if (intensity <= 10) return 'Intensa';
  return 'Moderata';
}
```

**Note:** These are top-level functions, not extension methods. They have no side effects and are trivially testable.

---

### HeroSessionCard — Full Implementation Guide

File: `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';

/// Primary session recommendation card for the Today screen hero zone.
///
/// Displays session type, duration, intensity, AI explanation, and a Start CTA.
/// Wiring to DailyPlanBloc is Story 7.3's scope — [onStart] is passed in by parent.
/// Hero animation tags are added in Story 7.3.
class HeroSessionCard extends StatelessWidget {
  final PlannedSession session;
  final VoidCallback? onStart;

  const HeroSessionCard({
    super.key,
    required this.session,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>();
    assert(pulseTheme != null, 'HeroSessionCard requires PulseCoachTheme extension');
    final theme = pulseTheme!;

    final accentColor = sessionAccentColor(session.sessionType, theme);
    final displayName = sessionDisplayName(session.sessionType);
    final icon = sessionIcon(session.sessionType);
    final durationLabel = '${session.durationMinutes} min';
    final intensityText = intensityLabel(session.intensity);

    return Semantics(
      label: 'Prossima sessione: $displayName, $durationLabel, ${session.explanation}. Tocca per iniziare.',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.12),
              theme.surfaceContainer,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 32, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    durationLabel,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: theme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    intensityText,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: accentColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                session.explanation,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: theme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStart,
                  child: const Text('Inizia sessione'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Typography decisions:**
- Display name (H2): `Plus Jakarta Sans SemiBold 20sp` — hardcoded `TextStyle` (matches the H2 token in UX spec, avoids dependency on `textTheme.headlineMedium` which may differ by MaterialApp theme config)
- Duration / Intensity / Explanation: `Theme.of(context).textTheme.bodySmall` (13sp Regular, configured globally in `AppTheme`)
- FilledButton label: inherits from `FilledButtonTheme` (M3 default — 14sp Medium)

---

### CompactSessionCard — Full Implementation Guide

File: `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';

/// Compact session item for the "COMING UP" list on the Today screen.
///
/// No explanation text. No Start button. Tappable to promote to hero (Story 7.3).
class CompactSessionCard extends StatelessWidget {
  final PlannedSession session;
  final VoidCallback? onTap;

  const CompactSessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>();
    assert(pulseTheme != null, 'CompactSessionCard requires PulseCoachTheme extension');
    final theme = pulseTheme!;

    final accentColor = sessionAccentColor(session.sessionType, theme);
    final displayName = sessionDisplayName(session.sessionType);
    final icon = sessionIcon(session.sessionType);
    final durationLabel = '${session.durationMinutes} min';

    return Semantics(
      label: 'Sessione successiva: $displayName, $durationLabel. Tocca per selezionare come prossima sessione.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 24, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  durationLabel,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: theme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20, color: theme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### Lottie Note

No session-type Lottie animation assets exist in `pulse_coach/assets/animations/` (only `onboarding_plan.json`, `onboarding_privacy.json`, `onboarding_setup.json`). Per UX spec: "If Lottie animations aren't completed in time, replace with static Lucide icons using the same session-type color accents." The project has no Lucide package — Material Icons are the correct fallback. This story uses Material Icons. When session Lottie files are delivered, they replace the `Icon` widgets with `Lottie.asset(...)` calls — the color accent logic is unchanged.

---

### Intensity Mapping Reference

| Raw `intensity` int | Display label | Source |
|---|---|---|
| 1–3 | `'Leggera'` | Matches `SessionIntensity.low` range in `contextual_bandit.dart:165` |
| 4–7 | `'Moderata'` | Matches `SessionIntensity.medium` range |
| 8–10 | `'Intensa'` | Matches `SessionIntensity.high` range |
| out-of-range | `'Moderata'` | Defensive fallback |

The `SessionIntensity` enum (`safety_constraints.dart:9`: `low`, `medium`, `high`) maps raw int→enum elsewhere in the AI engine. This widget works directly with the raw int from `PlannedSession.intensity` — no import of the AI-layer enum is needed (that enum lives in the domain/AI layer and this is presentation).

---

### Widget Test Specs — Full Coverage

File: `pulse_coach/test/widget/session_card_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/today/presentation/widgets/compact_session_card.dart';
import 'package:pulse_coach/features/today/presentation/widgets/hero_session_card.dart';
import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

PlannedSession _session({
  String type = 'mobility',
  int intensity = 3,
  int duration = 5,
  String explanation = 'Buona base di mobilità per oggi.',
}) => PlannedSession(
      sessionType: type,
      intensity: intensity,
      durationMinutes: duration,
      isIndoor: true,
      explanation: explanation,
    );

void main() {
  // ── Helper function unit tests ───────────────────────────────────────────────

  group('sessionDisplayName', () {
    test('7.2-HELPER-001: mobility → Mobilità', () {
      expect(sessionDisplayName('mobility'), equals('Mobilità'));
    });
    test('7.2-HELPER-002: cardio → Cardio', () {
      expect(sessionDisplayName('cardio'), equals('Cardio'));
    });
    test('7.2-HELPER-003: breathing → Respirazione', () {
      expect(sessionDisplayName('breathing'), equals('Respirazione'));
    });
    test('7.2-HELPER-004: unknown type → pass-through', () {
      expect(sessionDisplayName('unknown'), equals('unknown'));
    });
  });

  group('intensityLabel', () {
    test('7.2-HELPER-005: intensity 1 → Leggera', () {
      expect(intensityLabel(1), equals('Leggera'));
    });
    test('7.2-HELPER-006: intensity 3 → Leggera (boundary)', () {
      expect(intensityLabel(3), equals('Leggera'));
    });
    test('7.2-HELPER-007: intensity 4 → Moderata (boundary)', () {
      expect(intensityLabel(4), equals('Moderata'));
    });
    test('7.2-HELPER-008: intensity 7 → Moderata (boundary)', () {
      expect(intensityLabel(7), equals('Moderata'));
    });
    test('7.2-HELPER-009: intensity 8 → Intensa (boundary)', () {
      expect(intensityLabel(8), equals('Intensa'));
    });
    test('7.2-HELPER-010: intensity 10 → Intensa', () {
      expect(intensityLabel(10), equals('Intensa'));
    });
  });

  // ── HeroSessionCard widget tests ─────────────────────────────────────────────

  group('HeroSessionCard — content (AC1)', () {
    testWidgets('7.2-WIDGET-001: displays session display name', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session(type: 'mobility'))));
      expect(find.text('Mobilità'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-002: displays duration label', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session(duration: 10))));
      expect(find.text('10 min'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-003: displays intensity label (intensity=3 → Leggera)', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session(intensity: 3))));
      expect(find.text('Leggera'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-004: displays intensity label (intensity=8 → Intensa)', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session(intensity: 8))));
      expect(find.text('Intensa'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-005: displays AI explanation text', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session(explanation: 'Ottimo per recuperare energia.'))));
      expect(find.text('Ottimo per recuperare energia.'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-006: displays "Inizia sessione" CTA button', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session())));
      expect(find.text('Inizia sessione'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-007: onStart callback fires when Start button tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session(), onStart: () => tapped = true)));
      await tester.tap(find.byType(FilledButton));
      expect(tapped, isTrue);
    });
  });

  group('HeroSessionCard — no compact-only elements (AC1 exclusion)', () {
    testWidgets('7.2-WIDGET-008: no chevron icon on hero card', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session())));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });

  group('HeroSessionCard — session type colors (AC4)', () {
    testWidgets('7.2-WIDGET-009: cardio accent color is soft coral', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session(type: 'cardio'))));
      await tester.pumpAndSettle();
      // Verify the cardio Icon is rendered (color assertion via helper test is sufficient)
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-010: mobility uses primary color icon', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session(type: 'mobility'))));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-011: breathing uses secondary color icon', (tester) async {
      await tester.pumpWidget(_wrap(HeroSessionCard(session: _session(type: 'breathing'))));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.air), findsOneWidget);
    });
  });

  // ── CompactSessionCard widget tests ──────────────────────────────────────────

  group('CompactSessionCard — content (AC3)', () {
    testWidgets('7.2-WIDGET-012: displays session display name', (tester) async {
      await tester.pumpWidget(_wrap(CompactSessionCard(session: _session(type: 'cardio'))));
      expect(find.text('Cardio'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-013: displays duration', (tester) async {
      await tester.pumpWidget(_wrap(CompactSessionCard(session: _session(duration: 15))));
      expect(find.text('15 min'), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-014: shows chevron icon', (tester) async {
      await tester.pumpWidget(_wrap(CompactSessionCard(session: _session())));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('7.2-WIDGET-015: no "Inizia sessione" button', (tester) async {
      await tester.pumpWidget(_wrap(CompactSessionCard(session: _session())));
      expect(find.text('Inizia sessione'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('7.2-WIDGET-016: no explanation text visible', (tester) async {
      await tester.pumpWidget(_wrap(
        CompactSessionCard(session: _session(explanation: 'Questo non deve apparire.')),
      ));
      expect(find.text('Questo non deve apparire.'), findsNothing);
    });
  });

  // ── sessionAccentColor unit test (AC4 — color values) ──────────────────────

  group('sessionAccentColor (AC4)', () {
    const theme = PulseCoachTheme.dark;

    test('7.2-COLOR-001: cardio → soft coral #F0A1B0', () {
      expect(sessionAccentColor('cardio', theme), equals(const Color(0xFFF0A1B0)));
    });

    test('7.2-COLOR-002: mobility → primaryColor #7DD3C0', () {
      expect(sessionAccentColor('mobility', theme), equals(PulseCoachTheme.dark.primaryColor));
    });

    test('7.2-COLOR-003: breathing → secondary #A78BDA', () {
      expect(sessionAccentColor('breathing', theme), equals(PulseCoachTheme.dark.secondary));
    });

    test('7.2-COLOR-004: unknown type → onSurfaceVariant (defensive)', () {
      expect(sessionAccentColor('unknown', theme), equals(PulseCoachTheme.dark.onSurfaceVariant));
    });
  });
}
```

---

### Test Count Accounting

| Source | Count |
|---|---|
| Baseline (post Story 7.1, full suite) | 432 |
| `session_card_test.dart` — helper unit tests (HELPER-001..010) | +10 |
| `session_card_test.dart` — `HeroSessionCard` widget tests (WIDGET-001..011) | +11 |
| `session_card_test.dart` — `CompactSessionCard` widget tests (WIDGET-012..016) | +5 |
| `session_card_test.dart` — `sessionAccentColor` unit tests (COLOR-001..004) | +4 |
| **Estimated target** | **462** |

---

### flutter analyze: Zero-Tolerance Rules

- All `switch` statements on `sessionType` (a `String`) use `default` for unknown types — this is correct and intentional.
- No `withOpacity` deprecation: `accentColor.withOpacity(0.12)` is the correct API in Flutter 3.41.x.
- All imports must use package-relative form: `import 'package:pulse_coach/...'`.
- No unused imports. Run `flutter analyze` and fix any issues before committing.

---

### Build Runner

**Not required.** No freezed classes created or modified, no injectable annotations changed, no Drift table changes. The new widgets are plain `StatelessWidget` classes. Verify `injection.config.dart` is byte-stable after all changes.

---

### Out of Scope (Explicit)

- `CompletedSessionCard` — not in Story 7.2 ACs; will be added in Story 7.3 when wiring the full Today screen layout
- Flutter `Hero` animation tags — added in Story 7.3 (swap interaction)
- Shimmer loading placeholder — Story 7.3
- `TodayPage` updates — Story 7.3
- Real Lottie session type animations — not yet available; Material Icons are the correct fallback
- `DailyPlanBloc` integration — Story 7.3
- English ARB or additional locale strings for session names — out of scope for Epic 7

---

### Files to Create / Modify

**New files:**
- `pulse_coach/lib/features/today/presentation/widgets/session_card_helpers.dart`
- `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`
- `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart`
- `pulse_coach/test/widget/session_card_test.dart`

**Modified files:**
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status: backlog → ready-for-dev)

---

### References

- `PlannedSession` domain model: [`pulse_coach/lib/features/daily_plan/domain/entities/planned_session.dart`]
- `PulseCoachTheme` tokens (primaryColor, secondary, onSurfaceVariant, surfaceContainer): [`pulse_coach/lib/core/theme/pulse_coach_theme.dart`]
- `AppTheme.darkTheme` (used in widget test `_wrap`): [`pulse_coach/lib/core/theme/app_theme.dart`]
- `StateIndicator` widget (pattern reference for PulseCoachTheme extension lookup): [`pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart`]
- UX spec §Custom Components §HeroSessionCard: [`_bmad-output/planning-artifacts/ux-design-specification.md:992-1060`]
- Epics §Story 7.2: [`_bmad-output/planning-artifacts/epics.md:1109-1131`]
- UX-DR5 definition (SessionCard spec): [`_bmad-output/planning-artifacts/epics.md:129`]
- UX-DR17 (shape tokens — 16dp card radius, 12dp button): [`_bmad-output/planning-artifacts/epics.md:141`]
- `SessionIntensity` enum (low/medium/high ranges): [`pulse_coach/lib/ai/safety/safety_constraints.dart:9`] and [`pulse_coach/lib/ai/bandit/contextual_bandit.dart:161-165`]
- `CardThemeData` config (16dp radius already in AppTheme): [`pulse_coach/lib/core/theme/app_theme.dart:30-35`]
- Story 7.1 (StateIndicator — closest sibling component): [`_bmad-output/implementation-artifacts/7-1-stateindicator-component.md`]
- Story 7.3 context (what SessionCard wires into): [`_bmad-output/planning-artifacts/epics.md:1133-1163`]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter test test/widget/session_card_test.dart` — red phase failed before widget/helper files existed.
- `dart format lib/features/today/presentation/widgets/session_card_helpers.dart lib/features/today/presentation/widgets/hero_session_card.dart lib/features/today/presentation/widgets/compact_session_card.dart test/widget/session_card_test.dart`
- `flutter test test/widget/session_card_test.dart` — passed 40 tests.
- `flutter test` — passed 472 tests.
- `flutter analyze` — No issues found.

### Completion Notes List

- Added shared session-card helper functions for accent colors, display names, icons, and defensive intensity labels.
- Added `HeroSessionCard` with 32dp session icon, display name, duration, intensity, explanation text, gradient card surface, semantics label, and full-width `Inizia sessione` CTA.
- Added `CompactSessionCard` with 24dp icon, compact tappable row, duration, chevron, semantics label, and no hero-only explanation or CTA.
- Added focused widget/helper tests covering AC1–AC4, including layout contracts, color mappings, semantic labels, callback behavior, and defensive helper fallbacks.

### File List

- `_bmad-output/implementation-artifacts/7-2-sessioncard-component.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/features/today/presentation/widgets/session_card_helpers.dart`
- `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`
- `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart`
- `pulse_coach/test/widget/session_card_test.dart`

### Change Log

- 2026-05-15: Implemented Story 7.2 SessionCard components and tests; validated with `flutter test` and `flutter analyze`.
