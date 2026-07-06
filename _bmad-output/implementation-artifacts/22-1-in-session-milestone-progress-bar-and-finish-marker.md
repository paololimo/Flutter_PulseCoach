---
baseline_commit: dc67d46996be8ee1cb202c1595ea8e75f169176b
---

# Story 22.1: In-Session Milestone Progress Bar and Finish Marker

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user in an active session,
I want the progress bar to show each step boundary and a clear end marker,
So that I have visible checkpoints and a clear end goal as the session advances.

## Context

**Epic 22 — Experience Polish (v1), first story.** This is the first story of a new epic with no predecessor story to inherit learnings from. Epic 22 is a pure presentation/platform-layer polish pass over the existing v1 core — this story specifically replaces the plain `LinearProgressIndicator` inside `InSessionView` (`pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart`) with a new `MilestoneProgressBar` component. No domain/data/repository layer is touched; this is a widget-only story.

**Scope boundary — `InSessionView` only.** Two other `LinearProgressIndicator` call sites exist in the codebase (`shared_session_lobby_page.dart` and `weekly_goal_indicator.dart`) — **neither is in scope.** The epics.md ACs name `InSessionView` explicitly; the shared-session lobby's progress bar is a different, inline implementation not mentioned anywhere in Epic 22 and must be left untouched.

### What already exists (DO NOT REBUILD)

- **`InSessionState`** (`lib/features/session/presentation/bloc/in_session_state.dart`) already exposes everything needed: `currentStepIndex`, `totalSteps` (getter, `steps.length`), and `isComplete`. **Critical nuance:** `InSessionCubit._advanceStep()` (`in_session_cubit.dart:103-119`) never increments `currentStepIndex` past the last valid index — on the final step's timer expiry it sets `isComplete: true` while `currentStepIndex` stays at `steps.length - 1`. This means the fraction `(currentStepIndex + 1) / totalSteps` is already `1.0` at completion; **the finish marker's reached/unreached visual state must be driven by `sessionState.isComplete`, not by the fill fraction alone** (a fraction of `1.0` can theoretically occur mid-session-logic-error, but the bloc's actual behavior means fraction hits 1.0 only exactly when `isComplete` flips true — still, key off `isComplete` explicitly for clarity and correctness, not fraction equality).
- **`CompletionRing`** (`lib/features/today/presentation/widgets/completion_ring.dart`) is the **exact pattern to mirror** for this component's animation architecture: a `StatefulWidget` + `TickerProviderStateMixin`, one `AnimationController` for the settle/reveal tween, `didUpdateWidget` computing old-vs-new state and starting the tween only on the actual transition (not on every rebuild), a monotonically incremented `_transitionId` to invalidate stale in-flight `TickerFuture` callbacks, and — critically — checking `MediaQuery.disableAnimationsOf(context)` in `didUpdateWidget` to skip straight to an `AlwaysStoppedAnimation` at the target value when reduce-motion is on. Reuse this exact skeleton for `MilestoneProgressBar`'s finish-marker settle tween (~300–400ms ease-out, per FR78/DESIGN.md).
- **`CustomPainter`** (`_RingPainter` in the same file) is the only existing `CustomPaint` usage in the codebase — mirror it for painting the milestone rail/fill/notches (a `CustomPainter` is the natural fit here too: a rail + fill + per-boundary notches/ticks is straightforward `Canvas` drawing, cheaper than stacking N `Container` widgets for notches).
- **Reduce-motion + `ExcludeSemantics` pattern**: `countdown_overlay.dart` (`reduceMotion = MediaQuery.disableAnimationsOf(context)` gate, `Semantics(...child: ExcludeSemantics(child: reduceMotion ? staticWidget : animatedWidget))`) and `rpe_input_widget.dart` are the two existing precedents — follow the same shape: a `Semantics` node carrying the textual step-position/finish-reached label, wrapping an `ExcludeSemantics`-wrapped visual (the animated settle must not be independently announced — EXPERIENCE.md Accessibility Floor).
- **`PulseCoachTheme`** (`lib/core/theme/pulse_coach_theme.dart`) exposes `primaryColor`, `onSurfaceVariant`, `surfaceContainerHigh` — **but has no `onPrimary` field.** DESIGN.md specifies the reached finish marker as an `{on-primary}` filled glyph. Use `Theme.of(context).colorScheme.onPrimary` (standard Material 3 `ColorScheme`, since `useMaterial3: true` is already set app-wide) for that one color — do not add a new field to `PulseCoachTheme` for a single usage.
- **ARB l10n keys** (`lib/l10n/app/app_it.arb` / `app_en.arb`) already has `inSessionStepLabel` (`"{current} di {total}"`) rendered as a separate `Text` above the progress bar in `in_session_view.dart:61-69` — **do not duplicate this text inside the new semantics label**; the `MilestoneProgressBar`'s own `Semantics` label is for screen-reader consumption of the *bar itself* (which is a distinct node from the visible step-count `Text`), so word it distinctly (e.g. exposing "step N of M, finish reached: yes/no") rather than repeating the exact same string twice in the semantics tree.

### Coordination note — finish-marker settle vs. immediate RPE navigation

`InSessionPage`'s `BlocListener` (`in_session_page.dart:105-134`) navigates to the RPE screen (`context.go(AppRouter.sessionRpe, ...)`) as soon as `isComplete` flips `true` — there is **no added delay** in the existing architecture, and this story must not introduce one (out of scope; no AC requests it). In practice the finish marker's settle animation plays during whatever route-transition duration `go_router`/`MaterialPage` already uses for the outgoing page, which is incidental, not deliberately timed. This satisfies AC4 ("the two completion beats never stack") as written: this story does not add glow/confetti/sound to the finish marker, so there is nothing to stack with the separate `CompletionRing` pulse that happens later, after RPE submission, on an entirely different screen (`MiniSummary`). Do not attempt to synchronize or delay navigation to "let the settle finish" — that would be scope creep beyond the ACs.

## Acceptance Criteria

**AC1 — Milestone rail replaces the plain progress bar:**
Given a multi-step guided session is in progress
When `InSessionView` renders the progress track
Then the plain `LinearProgressIndicator` is replaced by a `MilestoneProgressBar` in which each session-step boundary is a 2dp notch/gap in the Primary fill plus an `onSurfaceVariant` tick on the still-unfilled rail, so a boundary stays visible as the fill passes it (FR78, DESIGN.md MilestoneProgressBar).

**AC2 — Boundary notches stay visible; finish marker is a neutral glyph:**
Given the session progresses through its steps
When the fill passes a step boundary
Then the boundary notch remains distinguishable by shape/gap (never a same-hue tick lost on the fill), and the finish marker renders as a small neutral end glyph (soft filled dot / check — **not** a checkered flag or any racing/victory metaphor).

**AC3 — Finish marker reached-state transition (shape, not hue, carries meaning):**
Given the final step completes
When the finish marker is reached (`sessionState.isComplete == true`)
Then it transitions from an `onSurfaceVariant` **outline** (unreached) to an `{on-primary}` **filled** glyph (reached) — reached-vs-unreached differs by **shape**, not hue alone — and settles quietly into place (~300–400ms ease-out position/scale) with **no glow, no confetti, no particles, no sound**.

**AC4 — Completion beats never stack:**
Given the finish-marker settle and the MiniSummary `CompletionRing` pulse
When the session ends
Then the two completion beats never stack — the single emotional close remains the `CompletionRing` pulse (on a later, separate screen), and the finish marker is a quiet checkpoint close only. This story must not add any glow/confetti/sound to the finish marker (see Coordination note above for why no navigation-timing change is needed to satisfy this).

**AC5 — Single-step sessions show only start + finish:**
Given a single-step session (`totalSteps == 1`, no intermediate step boundaries)
When the `MilestoneProgressBar` renders
Then only the start and finish markers are shown (no intermediate notches).

**AC6 — Reduce motion honored + frame budget:**
Given the OS "reduce motion" setting is enabled (`MediaQuery.disableAnimationsOf(context) == true`)
When the finish marker is reached
Then the settle tween is skipped and the marker renders directly in its static filled state; the milestone bar's paint work honors the NFR2 60fps / ≤ 16ms frame budget (no per-frame allocations in the `CustomPainter.paint`, `shouldRepaint` compares only the fields that affect the visual).

**AC7 — Screen-reader semantics:**
Given a screen reader is active
When the `MilestoneProgressBar` is focused
Then it exposes the current step position (e.g. step N of M) + whether the finish is reached, as text via a single `Semantics` node, and the finish-marker settle animation itself is wrapped in `ExcludeSemantics` (decorative motion is not independently announced).

**AC8 — Zero regressions:**
Given all new/modified files are in place and `build_runner` has been run if needed
When `flutter analyze lib/ test/` and `flutter test` run from `pulse_coach/`
Then all pre-existing tests pass (adjusted where they asserted the now-removed `LinearProgressIndicator` — see Task 3) plus all new tests pass; analyzer reports 0 issues.

## Tasks / Subtasks

---

### Task 1 — `MilestoneProgressBar` widget (AC1, AC2, AC3, AC5, AC6, AC7)

- [x] **1.1** Create `pulse_coach/lib/features/session/presentation/widgets/milestone_progress_bar.dart`:
  - Public constructor params: `currentStepIndex` (int), `totalSteps` (int), `isComplete` (bool).
  - `StatefulWidget` + `TickerProviderStateMixin` (mirror `CompletionRing`'s `_CompletionRingState` shape):
    - One `AnimationController` (`_settleController`, duration 300–400ms, e.g. 350ms) driving a `Tween<double>` (0.0 → 1.0) with `Curves.easeOut`, used to interpolate the finish marker's scale (e.g. 0.7 → 1.0) and/or position settle.
    - `didUpdateWidget`: compute `wasComplete = oldWidget.isComplete`, `isComplete = widget.isComplete`. If transitioning `false → true`:
      - If `MediaQuery.disableAnimationsOf(context)` is true: `_settleController.value = 1.0` directly (no `.forward()` call) — static filled state, no tween (AC6).
      - Else: `_settleController.forward(from: 0)`.
    - No pulse/glow/particle controller — this widget has exactly one animation (the settle), unlike `CompletionRing` which has two (arc + pulse). Do not add a second animation controller "for consistency" with `CompletionRing` — that pulse belongs to `CompletionRing`, not here (AC4).
  - **Painting** — a `CustomPainter` (e.g. `_MilestonePainter`) receiving `progress` (`(currentStepIndex + 1) / totalSteps`, clamped 0.0–1.0), `totalSteps`, `primaryColor`, `railColor` (`onSurfaceVariant` at low opacity, mirror `CompletionRing`'s `.withValues(alpha: 0.2)` — **use `withValues`, not the deprecated `withOpacity`**), and `notchColor` (`onSurfaceVariant`):
    - Draw the unfilled rail full-width, `rounded/full` (use `StrokeCap.round` or a rounded `RRect`), at low-opacity `onSurfaceVariant`.
    - Draw the Primary fill on top, width = `progress * trackWidth`.
    - For each of the `totalSteps - 1` interior boundaries (skip entirely when `totalSteps <= 1`, satisfying AC5 — a single-step session has zero interior boundaries by construction), draw a small notch: a short perpendicular gap/tick at that boundary's x-position. Where the boundary falls under the (already-passed) fill, the notch must still read as a **gap/shape difference in the fill**, not a same-hue tick that disappears — implement as a literal 2dp transparent gap cut into the fill rect (draw the fill as several small rects with gaps at each boundary, rather than one continuous rect) so it holds up regardless of `primaryColor`'s exact hue (DESIGN.md explicitly calls out the "avoids the ~1.6:1 primary-on-primary contrast failure" reasoning — a gap in geometry, not a color contrast, is the fix).
    - The finish marker itself is **not** part of this `CustomPainter` — render it as a separate small `Widget` (e.g. an `Icon`-free painted dot/check via `CustomPaint` or a tiny `DecoratedBox`/`CustomPaint` circle) positioned at the rail's end, so its `Transform.scale`/settle animation can be driven by `AnimatedBuilder` independent of the rail repaint. Use a simple filled circle with an inset checkmark-like shape, or a plain filled/outlined circle (soft dot) — avoid importing a new icon package for this (no Lucide dependency exists yet; that's introduced in Story 22.2, out of scope here).
    - `shouldRepaint`: compare `progress`, `totalSteps`, and the three colors only (mirror `_RingPainter.shouldRepaint`).
  - **Finish marker paint**: outline (`onSurfaceVariant`, unfilled) when `!isComplete`; filled (`Theme.of(context).colorScheme.onPrimary` fill, on a small `Theme.of(context).colorScheme.primary`-ish or neutral background per DESIGN.md "≥3:1 on the Primary fill" — pick a simple filled circle in `onPrimary` sitting on the Primary-filled end of the rail) when `isComplete`. Drive its scale via `AnimatedBuilder` listening to `_settleController`.
  - **Semantics** (AC7): wrap the whole widget in one `Semantics(label: <ARB string>, child: ExcludeSemantics(child: <the painted row>))`. Do not expose the rail/notches/finish marker as separate semantics nodes — one label covers "step N of M" + "finish reached: yes/no" (see Task 2 for the exact ARB string).
  - Keep the file within the 200–400 line guideline; if the painter grows large, it may live in the same file as a private class (matches `completion_ring.dart`'s single-file convention) — do not split into a separate file for a component this size.

- [x] **1.2** Wire into `in_session_view.dart`: replace both `LinearProgressIndicator` call sites (portrait, line ~78, and landscape, line ~168) with:
  ```dart
  MilestoneProgressBar(
    currentStepIndex: sessionState.currentStepIndex,
    totalSteps: sessionState.totalSteps,
    isComplete: sessionState.isComplete,
  ),
  ```
  Remove the now-unused direct `LinearProgressIndicator` usages; no other changes to `in_session_view.dart`'s structure (padding/spacing around the bar stays as-is unless the new widget's intrinsic height differs enough to need a `SizedBox` height adjustment — check visually/in tests).

---

### Task 2 — ARB semantics label (AC7)

- [x] **2.1** Add a new ARB key to both `lib/l10n/app/app_it.arb` and `lib/l10n/app/app_en.arb` (placed near the existing `inSessionStepLabel` entry) for the `MilestoneProgressBar`'s semantics label, parameterized by current/total step and a reached flag, e.g.:
  - Italian: `"milestoneProgressBarSemanticLabel": "Passo {current} di {total}, traguardo {reached}"` with a `select`/two-string approach for the reached/not-reached wording (or two separate keys `milestoneProgressBarReachedLabel` / `milestoneProgressBarUnreachedLabel` if simpler than an ICU `select` — either is acceptable; keep parity between `it`/`en`).
  - English equivalent with matching `@`-metadata block (placeholders declared, matching the existing `@inSessionStepLabel` metadata shape at `app_it.arb:99-108`).
  - Run `flutter gen_l10n` (or simply `flutter pub get` / `flutter run`, which regenerates via the `l10n.yaml`-configured pipeline) so `AppLocalizations` picks up the new getter — **not** `build_runner` (ARB codegen is a separate pipeline from Drift/freezed/injectable, confirmed by `l10n.yaml` at the project root).

---

### Task 3 — Update the pre-existing test that asserts the removed widget (AC8)

- [x] **3.1** `test/widget/in_session_view_test.dart` has an existing test, **`8.2-WIDGET-003: LinearProgressIndicator is present`** (line 88-95), which will fail once Task 1.2 lands (`find.byType(LinearProgressIndicator)` will find zero widgets). Update this test to assert `find.byType(MilestoneProgressBar)` instead (rename the test description to reflect the new component, e.g. `22.1-WIDGET-000: MilestoneProgressBar replaces LinearProgressIndicator`). Do not delete the test outright — it is exactly the kind of regression check Task 3 exists to keep, just pointed at the new widget.
- [x] **3.2** Add `isComplete` support to the existing `_view()` test helper (currently only takes `step`/`seconds`/`liveHr`) so completion-state tests can construct an `InSessionState(isComplete: true, ...)` without duplicating the whole helper.

---

### Task 4 — `MilestoneProgressBar` unit/widget tests (AC1–AC7)

- [x] **4.1** Create `test/widget/milestone_progress_bar_test.dart`:
  ```
  [22.1-MILE-001] totalSteps=3, currentStepIndex=0, isComplete=false → widget renders without exception; Semantics label mentions step 1 of 3
  [22.1-MILE-002] totalSteps=3, currentStepIndex=1 → progress fraction reflects step 2 of 3 (verify via the exposed Semantics label text, not painter internals)
  [22.1-MILE-003] totalSteps=1, currentStepIndex=0, isComplete=false → only start+finish markers implied (no interior notch data point to assert on directly at the widget level beyond: no exception, single-step case renders)
  [22.1-MILE-004] isComplete: false → true transition (via pumpWidget rebuild) → Semantics label updates to reflect "finish reached"
  [22.1-MILE-005] reduce motion enabled (wrap in MediaQuery(data: MediaQueryData(disableAnimations: true)) ) + isComplete transition false → true → no exception, finish marker renders in static filled state immediately (pump a single frame, don't need to pumpAndSettle across the tween since there is none)
  [22.1-MILE-006] finish-marker settle animation region is wrapped in ExcludeSemantics (assert via find.byType(ExcludeSemantics) is present as a descendant)
  [22.1-MILE-007] widget renders on a 360x640 surface (small phone) without overflow, mirroring the existing in_session_view_test.dart pattern (tester.view.physicalSize)
  ```
  Follow the existing test file conventions in the codebase (`_wrap()` helper providing `MaterialApp` + `AppLocalizations` delegates + `AppTheme.darkTheme`, per `in_session_view_test.dart:35-41`).

- [x] **4.2** Extend `test/widget/in_session_view_test.dart` with a completion-state case:
  ```
  [22.1-WIDGET-001] sessionState.isComplete: true → MilestoneProgressBar is present and receives isComplete: true (verify via tester.widget<MilestoneProgressBar>(...).isComplete)
  ```

- [x] **4.3** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Expected: 0 analyzer issues; all pre-existing tests (baseline: **1323 passed, 1 skipped**, recorded at this story's creation on commit `dc67d46`) pass with the Task 3 adjustment, plus all new tests pass.

---

### Review Findings

_Code review 2026-07-06 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). 4 patch, 1 defer, 1 dismissed._

- [x] [Review][Patch] Finish-marker settle animation double-maps the 0.7→1.0 range — `_settleAnimation` Tween is `begin: 0.7, end: 1.0` AND `paint()` computes `scale = 0.7 + 0.3 * settleValue`, so the marker only pops 0.91→1.0 (~9%) instead of the intended 0.7→1.0 (30%). Fixed: Tween now emits the raw 0.0→1.0 range (`begin: 0.0`) so `0.7 + 0.3 * settleValue` yields the intended 0.7→1.0 scale. [milestone_progress_bar.dart:33,195]
- [x] [Review][Patch] `paint()` allocates `Paint` objects and a `List<double>` on every invocation — during the 350ms settle `shouldRepaint` returns true each frame, making these per-frame allocations that contradict AC6's explicit "no per-frame allocations in the CustomPainter.paint". Fixed: hoisted the six `Paint`s to static fields (color set at paint time) and removed the `boundaries` list by iterating boundaries inline. [milestone_progress_bar.dart:147,152,178]
- [x] [Review][Patch] Current-boundary notch/gap chosen by floating-point rounding — `fillWidth = progress * trackWidth` (order `(A/B)*C`) vs boundary `x = trackWidth * i / totalSteps` (order `(C*A)/B`) differ by ~1 ULP for the boundary at `i == currentStepIndex + 1`, and the strict split `x < fillWidth` (fill loop) vs `x >= fillWidth` (notch loop) resolves it by luck, so the current-position marker renders inconsistently across steps/devices. Fixed: boundary `x` now computed as `i / totalSteps * trackWidth`, matching `fillWidth`'s operation order so the current boundary compares exactly equal. [milestone_progress_bar.dart:150,157,183]
- [x] [Review][Patch] `TickerProviderStateMixin` used for a single `AnimationController` — should be `SingleTickerProviderStateMixin` (lighter, and asserts against accidental extra tickers). Fixed. [milestone_progress_bar.dart:22]
- [x] [Review][Defer] `trackWidth <= 0` (available width < 16dp = `2 * _finishMarkerRadius`) is unguarded, yielding a negative-width rail rect and a left-of-origin marker — no crash, and unreachable in the current `InSessionView` layout (bar sits in a padded bounded `Column`/`Expanded`). — deferred, robustness-only, not triggerable at runtime. [milestone_progress_bar.dart:141]

## Dev Notes

### Why a `CustomPainter`, Not Stacked `Container`/`Row` Widgets for Notches

`CompletionRing`'s `_RingPainter` is the only precedent for hand-painted progress visuals in this codebase, and a milestone rail with N variable-count notches is exactly the kind of thing that gets messy as stacked positioned widgets (especially handling the "notch is a literal gap in the fill" requirement — trivial to draw as adjacent rects with gaps in a `Canvas`, awkward to fake with widget layout). Mirror the existing pattern rather than inventing a widget-composition approach.

### Why `isComplete`, Not Progress-Fraction Equality, Drives the Finish Marker

Confirmed by reading `InSessionCubit._advanceStep()`: the cubit never emits a `currentStepIndex` beyond `steps.length - 1`; on the final step's expiry it only flips `isComplete: true` while holding the index. So `(currentStepIndex + 1) / totalSteps` reaches `1.0` from the very last regular tick (before completion) as well as at completion — it does not distinguish "the fill has visually caught up but the session isn't marked complete" from "the session is actually complete." Since these currently coincide in this codebase's bloc logic, gating strictly on the explicit `isComplete` boolean (not fraction) is both more correct and more robust to any future bloc change.

### No New Icon Package

DESIGN.md's finish-marker spec ("soft filled dot / check") does not require importing Lucide — that dependency is introduced in Story 22.2 (`FactorIconRow`), out of scope here. Draw the finish marker as a simple filled/outlined circle (optionally with an inset check-like path) directly in `CustomPaint`, avoiding a new dependency for a single glyph.

### `withValues`, Not `withOpacity`

`CompletionRing` already uses `Color.withValues(alpha: ...)` (not the deprecated `withOpacity`) — match this for the rail's low-opacity `onSurfaceVariant` background, since `flutter_lints` will likely flag `withOpacity` as deprecated on the current Flutter SDK (3.41.x).

### File Size Check

- New `milestone_progress_bar.dart`: expect roughly 150–220 lines (widget + state + one small painter), comfortably within the 200–400 line guideline.
- `in_session_view.dart`: 277 → net roughly unchanged (~2 `LinearProgressIndicator` blocks of ~6 lines each replaced by ~5-line `MilestoneProgressBar` calls); no growth concern.

### Project Structure Notes

**New production files:**
- `pulse_coach/lib/features/session/presentation/widgets/milestone_progress_bar.dart`

**Modified production files:**
- `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart` (both `LinearProgressIndicator` call sites → `MilestoneProgressBar`)
- `pulse_coach/lib/l10n/app/app_it.arb` (new semantics label key(s))
- `pulse_coach/lib/l10n/app/app_en.arb` (new semantics label key(s), matching metadata)

**Auto-regenerated (via `flutter gen_l10n`/`flutter pub get`, not `build_runner`):**
- `.dart_tool/flutter_gen/...` generated `app_localizations*.dart` (gitignored per repo convention — do not attempt to hand-edit or commit these)

**New/modified test files:**
- `pulse_coach/test/widget/milestone_progress_bar_test.dart` (new)
- `pulse_coach/test/widget/in_session_view_test.dart` (extended + one existing test repointed, Task 3)

**Explicitly out of scope for this story:**
- `shared_session_lobby_page.dart`'s inline `LinearProgressIndicator` (different component, not named in Epic 22's ACs).
- `weekly_goal_indicator.dart`'s `LinearProgressIndicator` (Progress tab, unrelated feature).
- Any Lucide icon dependency (Story 22.2).
- Any change to `InSessionCubit`/`InSessionState`/`InSessionPage` navigation timing (see Coordination note above).

### References

- [Source: epics.md#Story 22.1 lines 2895–2929 — full BDD ACs, FR78, NFR38, DESIGN.md/EXPERIENCE.md cross-refs]
- [Source: epics.md#Epic 22 lines 2885–2893 — epic goal, prerequisites, "no streak/guilt mechanic" framing]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md line 208 — InSessionView layout, MilestoneProgressBar replacing the plain LinearProgressIndicator]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md line 209 — full MilestoneProgressBar visual spec: notch/gap geometry, finish-marker outline→filled shape transition, settle timing, reduce-motion static fallback]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md line 242 (Do's and Don'ts table) — "no glow, no confetti, no particles, no sound" for the finish marker]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/EXPERIENCE.md line 156 — color-independence: notches as fill gaps not same-hue ticks, finish marker shape (outline→filled) not hue, ≥3:1 on-primary fill]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/EXPERIENCE.md line 159 — screen-reader requirement: MilestoneProgressBar exposes step position + finish-reached as text; settle animation uses ExcludeSemantics]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/EXPERIENCE.md line 160 — Reduce Motion: finish-marker settle → static filled state; NFR38 60fps/≤16ms budget]
- [Source: lib/features/session/presentation/bloc/in_session_state.dart — `currentStepIndex`/`totalSteps`/`isComplete` fields consumed by this story]
- [Source: lib/features/session/presentation/bloc/in_session_cubit.dart:103-119 — `_advanceStep()`, confirms `currentStepIndex` never exceeds `steps.length - 1`, `isComplete` is the sole completion signal]
- [Source: lib/features/session/presentation/pages/in_session_page.dart:105-134 — BlocListener navigates to RPE screen immediately on `isComplete`, no delay to add/preserve]
- [Source: lib/features/today/presentation/widgets/completion_ring.dart — animation architecture (AnimationController + didUpdateWidget transition-gating + `_transitionId` staleness guard + `MediaQuery.disableAnimationsOf` reduce-motion branch) and `CustomPainter` pattern to mirror]
- [Source: lib/features/session/presentation/widgets/countdown_overlay.dart:45,83,101-104 — reduce-motion + Semantics/ExcludeSemantics pairing precedent]
- [Source: lib/core/theme/pulse_coach_theme.dart — available theme tokens (`primaryColor`, `onSurfaceVariant`, `surfaceContainerHigh`); no `onPrimary` field, use `Theme.of(context).colorScheme.onPrimary` instead]
- [Source: lib/l10n/app/app_it.arb:86-110 — existing `inSession*` ARB key conventions, `inSessionStepLabel` placeholder-metadata shape to mirror]
- [Source: test/widget/in_session_view_test.dart:88-95 — the pre-existing test that will fail once the plain LinearProgressIndicator is removed (Task 3)]
- [Source: test/widget/completion_ring_test.dart — existing test conventions for an animated theme-driven widget, useful reference for Task 4's structure]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5

### Debug Log References

None — implementation proceeded without blockers.

### Completion Notes List

- Followed ATDD: wrote `test/widget/milestone_progress_bar_test.dart` first (confirmed RED — `MilestoneProgressBar` did not exist), then implemented the widget to make the 7 tests pass (GREEN).
- Created `MilestoneProgressBar` (`lib/features/session/presentation/widgets/milestone_progress_bar.dart`) mirroring `CompletionRing`'s `TickerProviderStateMixin` + single `AnimationController` (350ms ease-out settle) + reduce-motion gate in `didUpdateWidget`. Painting done in a private `_MilestonePainter` `CustomPainter`: rail + fill drawn as multiple rects with 2dp gaps at interior step boundaries (so the notch reads as a geometric gap, not a same-hue tick lost on the fill), plus a separate finish-marker circle (outline when `!isComplete`, filled `onPrimary`-on-`primaryColor` when `isComplete`) driven by the settle animation's value. `shouldRepaint` compares only the fields feeding the paint.
- Single-step sessions (`totalSteps == 1`) draw zero interior boundaries by construction (loop is skipped when `totalSteps <= 1`), satisfying AC5.
- Reduce motion (`MediaQuery.disableAnimationsOf`) sets `_settleController.value = 1.0` directly instead of calling `.forward()`, so no ticker is scheduled (verified via `transientCallbackCount == 0` in test 22.1-MILE-005).
- Semantics: single `Semantics` node with a label from two new ARB keys (`milestoneProgressBarUnreachedLabel` / `milestoneProgressBarReachedLabel`), wrapping an `ExcludeSemantics`-wrapped painted row, so the settle animation is not independently announced (AC7).
- Used `Theme.of(context).colorScheme.onPrimary` for the reached finish-marker glyph fill, per Dev Notes (no new `PulseCoachTheme` field added for a single usage).
- Wired `MilestoneProgressBar` into both `InSessionView` call sites (portrait + landscape), replacing the plain `LinearProgressIndicator`; no other structural changes to `in_session_view.dart`.
- Added `milestoneProgressBarUnreachedLabel` / `milestoneProgressBarReachedLabel` ARB keys (IT + EN, with matching placeholder metadata) and regenerated localizations via `flutter gen-l10n` / `flutter pub get` (not `build_runner` — confirmed separate pipeline per `l10n.yaml`).
- Task 3: repointed the pre-existing `8.2-WIDGET-003` test to `22.1-WIDGET-000` (asserts `LinearProgressIndicator` is gone and `MilestoneProgressBar` is present instead of only checking the old widget's presence); extended the shared `_view()` test helper with an `isComplete` parameter.
- Task 4: added 7 new widget tests in `milestone_progress_bar_test.dart` (`22.1-MILE-001`..`007`) covering step-position semantics, single-step rendering, the `isComplete` false→true transition, reduce-motion static fallback, `ExcludeSemantics` wrapping, and a 360×640 overflow check; added `22.1-WIDGET-001` to `in_session_view_test.dart` asserting `isComplete` is forwarded to the child widget.
- Verification: `flutter analyze lib/ test/` → 0 issues. `flutter test` → 1331 passed, 1 skipped (baseline was 1323 passed/1 skipped; net +8 new tests, no regressions).

### File List

- `pulse_coach/lib/features/session/presentation/widgets/milestone_progress_bar.dart` (new)
- `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart` (modified — both `LinearProgressIndicator` call sites replaced)
- `pulse_coach/lib/l10n/app/app_it.arb` (modified — new semantics label keys)
- `pulse_coach/lib/l10n/app/app_en.arb` (modified — new semantics label keys, matching metadata)
- `pulse_coach/test/widget/milestone_progress_bar_test.dart` (new)
- `pulse_coach/test/widget/in_session_view_test.dart` (modified — Task 3 test repointed + `isComplete` helper param + new `22.1-WIDGET-001` test)

## Change Log

- 2026-07-06: Implemented `MilestoneProgressBar` (Task 1), added ARB semantics labels (Task 2), repointed the pre-existing `LinearProgressIndicator` regression test (Task 3), and added new widget tests (Task 4). All ACs satisfied; `flutter analyze` 0 issues; `flutter test` 1331 passed / 1 skipped (baseline 1323/1, +8 new tests, no regressions). Status moved to review.
