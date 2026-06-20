# Story 7.4: CompletionRing Component & Plan Regeneration

Status: done

## Story

As a user,
I want to see my daily session progress visually and be able to regenerate my plan,
So that I have a sense of accomplishment and can refresh sessions if they don't fit my current mood.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The `CompletionRing` small variant is in the Today screen state bar | 1 of 3 sessions is complete | The ring shows 1/3 progress — one arc segment filled in Primary color (FR15, UX-DR12) |
| AC2 | The ring is in the small (informational) variant | Viewed | It is visible but secondary — it does not compete with the hero card for visual attention (UX-DR12) |
| AC3 | "Reduce Motion" is enabled in system accessibility settings | The ring updates (session completed) | It updates without animation — arc change is instant, no pulse (UX-DR12, UX-DR18) |
| AC4 | The user taps the regenerate action (Lucide icon, secondary placement on `HeroSessionCard`) | Tapped | `DailyPlanRegenerateRequested` event is dispatched and the plan is regenerated with shimmer loading (FR11) |

## Tasks / Subtasks

---

### Task 1: Animate `CompletionRing` (AC1, AC3)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart`
  - [x] Convert from `StatelessWidget` to `StatefulWidget` with `TickerProviderStateMixin`
  - [x] Add two `AnimationController` fields:
    ```dart
    late AnimationController _arcController;    // 400ms, easeInOut
    late AnimationController _pulseController;  // 600ms, easeInOut
    ```
  - [x] Add animation fields:
    ```dart
    late Animation<double> _arcAnimation;   // double 0.0..1.0
    late Animation<double> _pulseAnimation; // double 1.0..1.08..1.0
    double _prevProgress = 0.0;
    ```
  - [x] In `initState`:
    - Create controllers with proper durations
    - Compute initial progress: `widget.total > 0 ? widget.completed / widget.total : 0.0`
    - Set `_prevProgress` to initial progress
    - Set `_arcAnimation = AlwaysStoppedAnimation(_prevProgress)` (no animation on first frame)
    - Set `_pulseAnimation`:
      ```dart
      _pulseAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
      ```
  - [x] Override `dispose`: call `_arcController.dispose()` and `_pulseController.dispose()`
  - [x] Override `didUpdateWidget`:
    ```dart
    @override
    void didUpdateWidget(CompletionRing old) {
      super.didUpdateWidget(old);
      if (old.completed == widget.completed && old.total == widget.total) return;
      final newProgress = widget.total > 0 ? widget.completed / widget.total : 0.0;
      final disableAnimations = MediaQuery.disableAnimationsOf(context);
      if (disableAnimations) {
        _arcController.stop();
        _pulseController.stop();
        setState(() {
          _arcAnimation = AlwaysStoppedAnimation(newProgress);
          _prevProgress = newProgress;
        });
      } else {
        _arcAnimation = Tween<double>(begin: _prevProgress, end: newProgress)
            .animate(CurvedAnimation(parent: _arcController, curve: Curves.easeInOut));
        _arcController.forward(from: 0).then((_) {
          _prevProgress = newProgress;
          if (widget.total > 0 && widget.completed >= widget.total && mounted) {
            _pulseController.forward(from: 0);
          }
        });
      }
    }
    ```
  - [x] In `build`, wrap with `AnimatedBuilder(animation: Listenable.merge([_arcController, _pulseController]), builder: ...)`:
    ```dart
    AnimatedBuilder(
      animation: Listenable.merge([_arcController, _pulseController]),
      builder: (context, _) {
        return Semantics(
          label: 'Progressione giornaliera: $completed di $total sessioni completate',
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: 48, height: 48,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: _arcAnimation.value.clamp(0.0, 1.0),
                  trackColor: pulseTheme.onSurfaceVariant.withValues(alpha: 0.2),
                  progressColor: pulseTheme.primaryColor,
                ),
                child: Center(
                  child: Text(
                    '${widget.completed}/${widget.total}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    ```
  - [x] **Modify `_RingPainter`** to accept `progress` (double 0.0..1.0) instead of `completed`/`total`:
    ```dart
    class _RingPainter extends CustomPainter {
      final double progress;  // 0.0 to 1.0
      final Color trackColor;
      final Color progressColor;
      // ... paint: use progress directly in sweepAngle calc
      // sweepAngle = 2 * math.pi * progress  (when progress > 0)
    }
    ```
  - [x] Update `shouldRepaint` to compare `progress` (double) instead of int fields
  - [x] Keep `import 'dart:math' as math;` at the top
  - [x] Keep `import 'package:flutter/material.dart'` and `import 'package:pulse_coach/core/theme/pulse_coach_theme.dart'`
  - [x] Add `import 'package:flutter/scheduler.dart'` is NOT needed — use `MediaQuery.disableAnimationsOf(context)` directly
  - [x] **No `@injectable`** — pure stateful widget

---

### Task 2: Add `onRegenerate` to `HeroSessionCard` (AC4)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`
  - [x] Add optional parameter to constructor:
    ```dart
    final VoidCallback? onRegenerate;
    ```
  - [x] Update constructor:
    ```dart
    const HeroSessionCard({
      super.key,
      required this.session,
      this.onStart,
      this.heroTag,
      this.onRegenerate,  // ← ADD
    });
    ```
  - [x] In the card's first `Row` (icon + title row), add an `IconButton` at the end when `onRegenerate` is non-null:
    ```dart
    Row(
      children: [
        // ... icon + title as before ...
        if (onRegenerate != null)
          Semantics(
            label: 'Rigenera il piano allenamento',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              color: pulseTheme.onSurfaceVariant,
              onPressed: onRegenerate,
              tooltip: 'Rigenera',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
      ],
    )
    ```
  - [x] **Existing tests remain green** — `onRegenerate` defaults to null, so no button is added in existing tests
  - [x] Icon: `Icons.refresh` (Material, consistent with `Icons.autorenew` usage in `state_indicator.dart:114`)
  - [x] No change to `Semantics` wrapper's `label` or `button` property (those reflect the card-level Start action, not the regenerate sub-action)

---

### Task 3: Wire regenerate through `TodayPage` (AC4)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/pages/today_page.dart`
  - [x] Add import:
    ```dart
    import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_event.dart';
    ```
    (Verify it's not already implicitly imported — if `daily_plan_bloc.dart` is already imported and events are part of that file, this import is not needed. Check: `daily_plan_event.dart` is a `part of 'daily_plan_bloc.dart'` so events are accessible via the bloc import. **No new import needed.**)
  - [x] Update `_HeroZone` to accept and pass `onRegenerate`:
    - Add `final VoidCallback? onRegenerate` field to `_HeroZone`:
      ```dart
      class _HeroZone extends StatelessWidget {
        final DailyPlan plan;
        final int heroIndex;
        final VoidCallback? onRegenerate;  // ← ADD
        const _HeroZone({
          super.key,
          required this.plan,
          required this.heroIndex,
          this.onRegenerate,  // ← ADD
        });
      ```
    - Pass it to `HeroSessionCard`:
      ```dart
      HeroSessionCard(
        session: session,
        heroTag: 'session-hero-${session.sessionType}-$heroIndex',
        onStart: () => context.read<TodaySessionCubit>().markSessionCompleted(),
        onRegenerate: onRegenerate,  // ← ADD
      )
      ```
  - [x] In `_buildLoaded`, where `_HeroZone` is constructed inside `AnimatedSwitcher`, pass the regenerate callback:
    ```dart
    _HeroZone(
      key: ValueKey('hero-${sessions[heroIndex].sessionType}-$heroIndex'),
      plan: plan,
      heroIndex: heroIndex,
      onRegenerate: () => context.read<DailyPlanBloc>().add(DailyPlanRegenerateRequested()),
    )
    ```
  - [x] **Critical:** `DailyPlanRegenerateRequested` is already defined in `daily_plan_event.dart` (part of `daily_plan_bloc.dart`). No new event needed.
  - [x] The shimmer loading is already handled by `DailyPlanLoading` state rendering `_buildShimmer` — no extra work needed for shimmer after regenerate.

---

### Task 4: Write tests (AC1, AC3, AC4)

- [x] CREATE `pulse_coach/test/widget/completion_ring_test.dart` (NEW)
  - [x] Widget wrap helper:
    ```dart
    Widget _wrap(Widget child, {bool disableAnimations = false}) =>
        MediaQuery(
          data: const MediaQueryData().copyWith(
            disableAnimations: disableAnimations,
          ),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(body: Center(child: child)),
          ),
        );
    ```
  - [x] Tests:

    | ID | Description |
    |---|---|
    | 7.4-RING-001 | Displays correct fraction text: `CompletionRing(completed: 0, total: 3)` → `find.text('0/3')` |
    | 7.4-RING-002 | Displays 1/3 text when 1 of 3 complete: `CompletionRing(completed: 1, total: 3)` → `find.text('1/3')` |
    | 7.4-RING-003 | Displays 3/3 text when all complete: `CompletionRing(completed: 3, total: 3)` → `find.text('3/3')` |
    | 7.4-RING-004 | Reduce Motion — no animation: wrap with `disableAnimations: true`, update widget from `0→1`, `pumpAndSettle`, verify no active animation controllers (use `pumpAndSettle` — with disableAnimations true it settles immediately) |
    | 7.4-RING-005 | Accessibility label: `Semantics` label contains 'Progressione giornaliera' |
    | 7.4-RING-006 | Widget renders without crash when `total == 0` (edge case: `0/0`) |

- [x] UPDATE `pulse_coach/test/widget/today_page_test.dart`
  - [x] Add mock verification helper for `add` (requires updating `@GenerateMocks` or using `verifyNever`/`verify`):
    - The `MockDailyPlanBloc` already has `add` method from `MockBloc`. Use `verify(dailyPlanBloc.add(DailyPlanRegenerateRequested()))` pattern.
    - If `add` is not stubbable, use `verify(dailyPlanBloc.add(any))` with `argThat(isA<DailyPlanRegenerateRequested>())`
  - [x] Add tests:

    | ID | Description |
    |---|---|
    | 7.4-PAGE-001 | Loaded state shows regenerate `IconButton` (find by icon `Icons.refresh`) |
    | 7.4-PAGE-002 | Tap regenerate `IconButton` dispatches `DailyPlanRegenerateRequested` to the bloc |
    | 7.4-PAGE-003 | Loading state shows NO regenerate `IconButton` (shimmer only, no `Icons.refresh`) |

- [x] UPDATE `pulse_coach/test/widget/session_card_test.dart`
  - [x] Add tests in the `HeroSessionCard` group:

    | ID | Description |
    |---|---|
    | 7.4-HERO-001 | `HeroSessionCard` with `onRegenerate: () {}` → `find.byIcon(Icons.refresh)` findsOneWidget |
    | 7.4-HERO-002 | `HeroSessionCard` without `onRegenerate` → `find.byIcon(Icons.refresh)` findsNothing |

---

### Task 5: Gate verification

- [x] `flutter analyze` from `pulse_coach/` — must show **0 issues**
- [x] `flutter test` from `pulse_coach/` — must pass (target ≈ 492 + ~11 new = ~503)

---

### Review Findings

Generated 2026-05-16 from `bmad-code-review` (Blind Hunter + Edge Case Hunter + Acceptance Auditor).

**Decision needed (UX/spec calls):** _all resolved_

- [x] [Review][Decision→Patch] **Tap target 36×36 < 48dp Material/WCAG minimum** — resolved: raise constraints to `minWidth/minHeight: 48` with inner `padding: EdgeInsets.all(6)` so the visual 20dp icon stays muted while the hit area becomes WCAG-compliant.
- [x] [Review][Decision→Defer] **`total` shrinks mid-animation → visual "drain"** — deferred: needs visual verification on physical Samsung A520F during an actual regenerate before deciding between "skip-on-total-change", "skip-on-zero", or "accept drain".

**Patch (unambiguous fixes):**

- [x] [Review][Patch] **Raise regenerate IconButton hit area to 48dp** [`hero_session_card.dart:92-107`] — Resolved from Decision #1. Replace `BoxConstraints(minWidth: 36, minHeight: 36)` with `BoxConstraints(minWidth: 48, minHeight: 48)` and set `padding: EdgeInsets.all(6)` (or `EdgeInsets.all(14)` if not using inner padding — but EdgeInsets.all(6) preserves icon visual size at 20dp + 6+6 padding = 32, ringed by the 48dp hit area). Confirm visual "muted" look unchanged.
- [x] [Review][Patch] **Stale `_prevProgress` on rapid mid-animation updates** [`completion_ring.dart:74-78`] — `_prevProgress = newProgress` only runs inside `.then(...)` callback. If `didUpdateWidget` fires twice within 400ms, the second tween begins from the original `_prevProgress` (not the current arc position) and the first `.then` later overwrites `_prevProgress` with a stale value. Fix: capture `newProgress` in a local + set `_prevProgress = newProgress` synchronously *before* `_arcController.forward`, or track an in-flight token and ignore stale `.then` resolutions.
- [x] [Review][Patch] **Stale `.then()` token can fire pulse spuriously** [`completion_ring.dart:74-78`] — `_arcController.forward(from: 0)` while a previous forward is in flight still resolves the prior `TickerFuture` with `completed` status; both `.then` callbacks reference the latest `widget.completed`/`widget.total`. Combined fix with the item above: a monotonic transition token (e.g. `_transitionId++`) checked inside `.then` before applying side effects.
- [x] [Review][Patch] **Pulse re-fires on every transition into "completed" — spec says "plays once"** [`completion_ring.dart:74-78`] — Current guard fires pulse whenever `completed >= total` after each `forward`. Toggling 2/3 → 3/3 → 2/3 → 3/3 re-pulses each time. Spec line 305 says "plays once". Fix: guard with `_prevProgress < 1.0 && newProgress >= 1.0` (only fire on first crossing into completion).
- [x] [Review][Patch] **Reduce-Motion toggled mid-animation leaves pulse scale frozen ≠ 1.0** [`completion_ring.dart:62-68`] — `_pulseController.stop()` freezes the value; `Transform.scale` keeps using `_pulseAnimation.value` (e.g. 1.05). Fix: replace `_pulseController.stop()` with `_pulseController.reset()` (or call `reset()` after stop).
- [x] [Review][Patch] **`completed > total` not defensively clamped** [`completion_ring.dart:15-19, 58`] — If parent ever passes `completed > total` (race in `TodaySessionCubit`, misuse), progress > 1.0, pulse fires, text shows "4/3". Painter clamps but widget state does not. Fix: `final completed = widget.completed.clamp(0, widget.total)` (when total > 0) used for both text and progress computation.
- [x] [Review][Patch] **Regenerate IconButton has no in-flight guard → double-tap dispatches twice** [`today_page.dart:119-121`, `hero_session_card.dart:92-107`] — During `AnimatedSwitcher` cross-fade (300ms) the old `_HeroZone` stays tappable; second tap dispatches a redundant `DailyPlanRegenerateRequested`. Fix: gate the callback at `_HeroZone` — pass `onRegenerate: null` when the bloc state is not `DailyPlanLoaded`, or wrap the dispatch in a local "in-flight" flag.
- [x] [Review][Patch] **Double `Semantics(button: true)` on regenerate IconButton** [`hero_session_card.dart:92-107`] — `IconButton` already exposes a `button` Semantics node with the tooltip as the label; wrapping in an outer `Semantics(label: 'Rigenera il piano allenamento', button: true)` produces nested semantic nodes (potential double-announce on TalkBack/VoiceOver). Fix: drop the outer `Semantics` wrapper and pass `semanticLabel: 'Rigenera il piano allenamento'` on the inner `Icon`, keeping `tooltip: 'Rigenera'`.
- [x] [Review][Patch] **RING-004 reduce-motion test is a non-test** [`completion_ring_test.dart:40-59`] — Only asserts `find.text('1/3')` after `pumpAndSettle`; would pass with animations enabled too. Fix: after the second `pumpWidget` call `await tester.pump(Duration.zero)` (no settle) and assert progress reflects 1/3 immediately, or assert `tester.binding.transientCallbackCount == 0` / no animating controller.
- [x] [Review][Patch] **PAGE-001 `find.byType(IconButton) findsOneWidget` is brittle** [`today_page_test.dart:131-134`] — Adding any future IconButton to the loaded TodayPage silently breaks this. Fix: replace with `expect(find.widgetWithIcon(IconButton, Icons.refresh), findsOneWidget)`.
- [x] [Review][Patch] **HERO-001/002 don't verify the callback actually runs** [`session_card_test.dart:244-260`] — Pure presence checks. A regression that wires `onPressed: null` instead of `onRegenerate` would still render `Icons.refresh` and pass both tests. Fix: add a third test (or fold into HERO-001) that taps the icon and asserts a captured bool turns `true`.
- [x] [Review][Patch] **`setState` inside `didUpdateWidget` (disableAnimations branch)** [`completion_ring.dart:62-68`] — Framework already schedules a rebuild after `didUpdateWidget`; calling `setState` here is unnecessary and trips debug asserts in some build phases. Fix: assign `_arcAnimation = AlwaysStoppedAnimation(newProgress)` directly without `setState`.
- [x] [Review][Patch] **`.then` callback assigns `_prevProgress` on a possibly-disposed State** [`completion_ring.dart:74-78`] — `if (mounted)` guards the pulse but not the `_prevProgress = newProgress` line above it. Currently harmless but a smell. Fix: move both side effects inside a single `if (mounted)` block.

**Deferred (pre-existing, exposed by this story):**

- [x] [Review][Defer] **`_HeroZone` empty-sessions branch is unreachable** [`today_page.dart:192-194`] — deferred, pre-existing from Story 7.3 (`_buildLoaded` short-circuits to `_AllDoneWidget` when `total == 0 || allDone`).
- [x] [Review][Defer] **`_isSamePlan` may miss distinct plans with identical `generatedAt` + `sessions.length`** [`today_page.dart:45-46`] — deferred, pre-existing from Story 7.3; exposed by the new regenerate trigger. A rapid regenerate that produces a same-timestamp same-length plan would leave `TodaySessionCubit` showing stale completed indices.

**Dismissed (4):** false-positive `onRegenerate` declaration query (field is present in diff), MediaQuery not registered in `initState` (didUpdateWidget always re-reads, runtime toggle without prop change is unlikely), `_arcAnimation` reassignment without setState (works correctly via merged listenable), `Transform.scale` initial value with `total==0` (verified safe — initial controller value 0.0 maps to scale 1.0).

---

## Dev Notes

---

### What This Story Is

Story 7.4 adds two features to close out Epic 7:
1. **Animated `CompletionRing`**: the static ring from Story 7.3 gains a 400ms arc-extension animation and a 600ms scale-pulse when all sessions complete. Reduce Motion disables both.
2. **Regenerate button**: a secondary `IconButton` on `HeroSessionCard` dispatches `DailyPlanRegenerateRequested`, reusing the existing `_onRegenerateRequested` handler in `DailyPlanBloc` that was implemented in Story 7.3.

**Do NOT:**
- Build the full animated MiniSummary with CompletionRing — that is Story 9.2's scope
- Add a "loading shimmer on explanation line only" or partial-dim loading — the whole page switches to shimmer via `DailyPlanLoading`, which is already correct
- Build the `CountdownOverlay` — that is Story 8.1's scope
- Add any navigation on regenerate tap — it dispatches the event and loading starts; no route change
- Use `@injectable` on `CompletionRing` — pure widget

---

### `CompletionRing` Animation Design

**Arc animation (400ms):**
- Triggered in `didUpdateWidget` when `completed` or `total` changes
- `_arcController.forward(from: 0)` animates `_arcAnimation` from `_prevProgress` to `newProgress`
- After completion, `.then((_) { _prevProgress = newProgress; ... })` updates the baseline
- `_RingPainter` receives `progress` (double) directly — no integer arithmetic inside the painter

**Pulse animation (600ms, single-cycle):**
- Triggered inside the `.then(...)` callback of `_arcController.forward` when `widget.completed >= widget.total && widget.total > 0`
- `_pulseController.forward(from: 0)` — it plays once and stops (not looped)
- `Transform.scale(scale: _pulseAnimation.value, ...)` wraps the entire `SizedBox`

**Why `AlwaysStoppedAnimation` on init:**
- On first render, the progress is set and painted immediately — no initial animation flicker
- `_arcAnimation = AlwaysStoppedAnimation(_prevProgress)` is read-safe by `AnimatedBuilder`

**Reduce Motion check:**
```dart
final disableAnimations = MediaQuery.disableAnimationsOf(context);
```
- `MediaQuery.disableAnimationsOf(context)` returns `true` when the OS "Reduce Motion" setting is active
- When true: stop controllers, use `AlwaysStoppedAnimation(newProgress)`, call `setState` to force repaint
- When false: use `_arcController.forward(from: 0)` as normal

**`_RingPainter` refactor:**
```dart
class _RingPainter extends CustomPainter {
  final double progress;  // 0.0 to 1.0
  final Color trackColor;
  final Color progressColor;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = progressColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
```

---

### Regenerate Button Placement Detail

The UX spec (line 1003) places the regenerate action inside `HeroSessionCard`:
> "Secondary action: 'Regenerate' TextButton (muted, top-right corner — accessible but not prominent)"

The flowchart (line 791) describes it as:
> "Tap Regenerate icon — small, top-right"

In practice, the HeroSessionCard's first `Row` is: `[Icon | Title | (Regenerate button)]`. The `Regenerate` `IconButton` is appended at the end of this Row (naturally right-aligned since `Expanded` handles the middle).

```dart
Row(
  children: [
    heroTag != null
        ? Hero(tag: heroTag!, child: Icon(...))
        : Icon(...),
    const SizedBox(width: 8),
    Expanded(
      child: Text(displayName, style: AppTextStyles.h2, ...),
    ),
    if (onRegenerate != null)
      Semantics(
        label: 'Rigenera il piano allenamento',
        button: true,
        child: IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          color: pulseTheme.onSurfaceVariant,
          onPressed: onRegenerate,
          tooltip: 'Rigenera',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
  ],
)
```

**Why `padding: EdgeInsets.zero` + `constraints`:** Prevents the default 48x48 tap area from pushing the icon visually large. The 36x36 minimum is still accessible.

**Why `onSurfaceVariant` color:** Makes the button "muted" and secondary vs the accent-colored session icon. Matches UX spec: "accessible but not prominent".

**Icon choice:** `Icons.refresh` (Material Icons). The project uses Material Icons throughout (e.g., `Icons.autorenew` in `state_indicator.dart:114`, `Icons.check_circle_outline` in `completed_session_card.dart`). Lucide Icons are listed in UX spec but are not in the pubspec — no `lucide_icons` package is installed. Use `Icons.refresh` consistently.

---

### `DailyPlanRegenerateRequested` — Already Wired

The `DailyPlanBloc._onRegenerateRequested` handler was fully implemented in Story 7.3:
- Emits `DailyPlanLoading` first
- Calls `_regenerateDailyPlan.call()`
- On success: reads behavioral state from DB, emits `DailyPlanLoaded`
- On failure: emits `DailyPlanError`

Story 7.4 only needs to add the UI trigger. No BLoC changes needed.

---

### Test Notes

**Testing animated widgets:**
- `pumpAndSettle()` waits for all animations to complete before assertions
- For `7.4-RING-004` (Reduce Motion): wrap in `MediaQuery(data: const MediaQueryData().copyWith(disableAnimations: true), ...)` — the animation controller is never started, so `pumpAndSettle` resolves immediately

**Testing regenerate tap in TodayPage:**
- `MockDailyPlanBloc.add()` needs to be stubbable for verification. Check `today_page_test.mocks.dart` — `MockDailyPlanBloc` inherits from `MockBloc<DailyPlanEvent, DailyPlanState>`. Use:
  ```dart
  when(dailyPlanBloc.add(any)).thenReturn(null);
  // ... tap regenerate ...
  verify(dailyPlanBloc.add(argThat(isA<DailyPlanRegenerateRequested>()))).called(1);
  ```
  If `add` is not easily stubbable with `when`, use `verifyNever` + tap pattern. As a fallback, test that `Icons.refresh` is tapped without crashing (smoke test).

**Session card test wrap helper:**
From `session_card_test.dart`, the existing wrap helper is:
```dart
Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
);
```

---

### Test Count Accounting

| Source | Count |
|---|---|
| Baseline (post Story 7.3) | 492 |
| `completion_ring_test.dart` (RING-001..006) | +6 |
| `today_page_test.dart` additions (PAGE-001..003) | +3 |
| `session_card_test.dart` additions (HERO-001..002) | +2 |
| **Estimated target** | **~503** |

---

### `flutter analyze` Zero-Tolerance Rules

- `TickerProviderStateMixin` requires `with TickerProviderStateMixin` on the state class, NOT on the widget
- All switch expressions on enums must remain exhaustive (no new switches added by this story)
- `AlwaysStoppedAnimation<double>(value)` is the correct type annotation — do NOT use `var`
- `MediaQuery.disableAnimationsOf(context)` is the correct modern API (not `.disableAnimations` directly on `MediaQueryData`)
- `Transform.scale` vs `ScaleTransition`: use `Transform.scale(scale: _pulseAnimation.value, ...)` inside `AnimatedBuilder` — NOT `ScaleTransition` (which drives its own controller internally and doesn't compose with `AnimatedBuilder` cleanly)
- `.clamp(0.0, 1.0)` on `_arcAnimation.value` — ensures float rounding errors don't paint outside [0,1]
- `Colors` import is not needed — all colors come from `PulseCoachTheme`
- `withValues(alpha: x)` not `.withOpacity(x)` (project uses modern non-deprecated API — see `state_indicator.dart`)

---

### Build Runner

No freezed classes are modified in this story. **`dart run build_runner build` is NOT required.**

---

### Files to Create / Modify

**New files:**
- `pulse_coach/test/widget/completion_ring_test.dart`

**Updated files:**
- `pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart` (static → animated)
- `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart` (add `onRegenerate`)
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart` (wire regenerate in `_HeroZone`)
- `pulse_coach/test/widget/today_page_test.dart` (add 3 tests: PAGE-001..003)
- `pulse_coach/test/widget/session_card_test.dart` (add 2 tests: HERO-001..002)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status: backlog → ready-for-dev)

---

### References

- `CompletionRing` current implementation (static): [`pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart`]
- `HeroSessionCard` current implementation: [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`]
- `TodayPage` and `_HeroZone` current implementation: [`pulse_coach/lib/features/today/presentation/pages/today_page.dart`]
- `DailyPlanBloc._onRegenerateRequested` (already wired): [`pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart:85-114`]
- `DailyPlanRegenerateRequested` event definition: [`pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_event.dart:11`]
- `StateIndicator` widget (pattern for `Icons.autorenew` usage): [`pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart:114`]
- `AppTheme.darkTheme` (used in widget test wraps): [`pulse_coach/lib/core/theme/app_theme.dart`]
- `PulseCoachTheme` tokens (`primaryColor`, `onSurfaceVariant`): [`pulse_coach/lib/core/theme/pulse_coach_theme.dart`]
- `TodaySessionCubit` (unchanged): [`pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`]
- UX CompletionRing spec (anatomy, animation, states): [`_bmad-output/planning-artifacts/ux-design-specification.md:1087-1107`]
- UX regenerate placement ("secondary, top-right on hero card"): [`_bmad-output/planning-artifacts/ux-design-specification.md:1003`]
- Epics.md Story 7.4 acceptance criteria: [`_bmad-output/planning-artifacts/epics.md:1165-1189`]
- Existing `today_page_test.dart` (test patterns, mock setup): [`pulse_coach/test/widget/today_page_test.dart`]
- Existing `session_card_test.dart` (wrap helper, HeroSessionCard test patterns): [`pulse_coach/test/widget/session_card_test.dart`]
- Story 7.3 dev notes (CompletionRing was intentionally static, 7.4 adds animation): [`_bmad-output/implementation-artifacts/7-3-today-screen-layout-and-hero-progression.md:291-295`]
- Story 7.3 deferred items (heroTag defer, AC2 above-fold viewport test defer): [`_bmad-output/implementation-artifacts/7-3-today-screen-layout-and-hero-progression.md:708-711`]

---

### Story 7.3 Deferred Items Resolved by This Story

From Story 7.3 code review:
- None of the 3 deferred items (heroTag Epic 8 revisit, AC2 golden-test infra, Italian i18n) are resolved by Story 7.4. They remain open deferred items.

---

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-05-16: Ran targeted red tests: `flutter test test/widget/completion_ring_test.dart test/widget/session_card_test.dart test/widget/today_page_test.dart`; failed as expected before `onRegenerate` implementation and TodayPage wiring.
- 2026-05-16: Ran targeted green tests after implementation: `flutter test test/widget/completion_ring_test.dart test/widget/session_card_test.dart test/widget/today_page_test.dart`; 63 passed.
- 2026-05-16: Ran gate validation: `flutter analyze`; no issues found.
- 2026-05-16: Ran full regression: `flutter test`; 503 tests passed.

### Completion Notes List

- Converted `CompletionRing` to a stateful animated widget with 400ms arc animation, 600ms completion pulse, reduce-motion instant updates, progress-based painter, and unchanged compact 48dp presentation.
- Added an optional muted `Icons.refresh` regenerate action to `HeroSessionCard`, preserving the existing default no-button behavior when no callback is supplied.
- Wired TodayPage regenerate action to dispatch `DailyPlanRegenerateRequested`; existing `DailyPlanLoading` shimmer handles the loading transition.
- Added widget coverage for ring text states, reduce motion, accessibility label, zero-total edge case, HeroSessionCard regenerate visibility, and TodayPage dispatch/loading behavior.

### File List

- `_bmad-output/implementation-artifacts/7-4-completionring-component-and-plan-regeneration.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart`
- `pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart`
- `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`
- `pulse_coach/test/widget/completion_ring_test.dart`
- `pulse_coach/test/widget/session_card_test.dart`
- `pulse_coach/test/widget/today_page_test.dart`

### Change Log

- 2026-05-16: Implemented Story 7.4 CompletionRing animation and plan regeneration UI; added tests and moved story to review.
