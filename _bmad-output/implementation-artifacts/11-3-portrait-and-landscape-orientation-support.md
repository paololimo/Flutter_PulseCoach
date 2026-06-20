# Story 11.3: Portrait & Landscape Orientation Support

Status: done

## Story

As a user,
I want all key screens to support both portrait and landscape orientation,
so that I can use the app comfortably in either orientation.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | Any key screen (Today, Sessions, Progress, InSessionView) | The device is rotated | Layout adapts via `OrientationBuilder` — no data loss, no overflow, no broken layouts (FR39, UX-DR16) |
| AC2 | `InSessionView` is active and the device is rotated | Orientation changes | Timer continues uninterrupted and session state is preserved |
| AC3 | Landscape orientation on a phone | The Today screen renders | Layout adjusts without content overflow (scrollable via existing phone layout) |

## Tasks / Subtasks

---

### Task 1: Add `OrientationBuilder` to `InSessionView` (AC1, AC2)

- [x] READ `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart` fully before editing. Current state: 144 lines, `StatelessWidget`, `Scaffold.body` = `SafeArea(Stack(Column(…Spacer…) + Positioned(HrBadge)))`.

- [x] UPDATE `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart`

  **Critical overflow diagnosis:** The portrait `Column` stacks ~264dp of content (title + counter + 48dp timer + progress + instruction + abandon TextButton) plus `Padding(fromLTRB(24, 32, 24, 24))`. On SM-A520F in landscape (density 3.0x → 640×360dp logical), SafeArea leaves ~288dp height. The column minimum (~320dp with insets) exceeds 288dp → RenderFlex overflow on device. The fix is a 2-column Row layout for landscape.

  Replace the current `build()` method to use `OrientationBuilder`:

  ```dart
  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final step = sessionState.currentStep;

    return Scaffold(
      backgroundColor: pulseTheme.surface,
      body: OrientationBuilder(
        builder: (ctx, orientation) => SafeArea(
          child: orientation == Orientation.landscape
              ? _landscapeBody(ctx, pulseTheme, l10n, step)
              : _portraitBody(ctx, pulseTheme, l10n, step),
        ),
      ),
    );
  }
  ```

  Extract the existing `Stack > Padding > Column` block into a private method `_portraitBody` (unchanged logic — move it verbatim):

  ```dart
  Widget _portraitBody(
    BuildContext context,
    PulseCoachTheme pulseTheme,
    AppLocalizations l10n,
    ExerciseStep step,
  ) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  step.title,
                  style: AppTextStyles.h2.copyWith(color: pulseTheme.onSurface),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.inSessionStepLabel(
                  (sessionState.currentStepIndex + 1).toString(),
                  sessionState.totalSteps.toString(),
                ),
                style: AppTextStyles.bodySmall.copyWith(
                  color: pulseTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _formatTime(sessionState.secondsRemaining),
                style: AppTextStyles.timerDisplay.copyWith(
                  color: pulseTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: (sessionState.currentStepIndex + 1) /
                    sessionState.totalSteps,
                backgroundColor: pulseTheme.surfaceContainerHigh,
                color: pulseTheme.primaryColor,
              ),
              const SizedBox(height: 32),
              Text(
                step.instruction,
                style: AppTextStyles.body.copyWith(
                  color: pulseTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              TextButton(
                onPressed: onAbandon,
                child: Text(
                  l10n.inSessionAbandonButton,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (sessionState.liveHr != null)
          Positioned(
            top: 16,
            right: 16,
            child: _HrBadge(
              bpm: sessionState.liveHr!,
              lastHrAtEpochMs: sessionState.lastHrAtEpochMs,
            ),
          ),
      ],
    );
  }
  ```

  Add the new `_landscapeBody` method:

  ```dart
  Widget _landscapeBody(
    BuildContext context,
    PulseCoachTheme pulseTheme,
    AppLocalizations l10n,
    ExerciseStep step,
  ) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left panel: step identity + timer + progress
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        step.title,
                        style: AppTextStyles.h2.copyWith(
                          color: pulseTheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.inSessionStepLabel(
                        (sessionState.currentStepIndex + 1).toString(),
                        sessionState.totalSteps.toString(),
                      ),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: pulseTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatTime(sessionState.secondsRemaining),
                      style: AppTextStyles.timerDisplay.copyWith(
                        color: pulseTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (sessionState.currentStepIndex + 1) /
                          sessionState.totalSteps,
                      backgroundColor: pulseTheme.surfaceContainerHigh,
                      color: pulseTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right panel: instruction + abandon
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      step.instruction,
                      style: AppTextStyles.body.copyWith(
                        color: pulseTheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onAbandon,
                      child: Text(
                        l10n.inSessionAbandonButton,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: pulseTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // HR badge keeps the same positioned overlay in landscape
        if (sessionState.liveHr != null)
          Positioned(
            top: 8,
            right: 8,
            child: _HrBadge(
              bpm: sessionState.liveHr!,
              lastHrAtEpochMs: sessionState.lastHrAtEpochMs,
            ),
          ),
      ],
    );
  }
  ```

  **No new imports required.** `OrientationBuilder` is in `package:flutter/material.dart` (already imported). The `ExerciseStep` type reference is already part of `InSessionState.currentStep`.

  **The `_formatTime` static method remains unchanged** at the bottom of the file.

---

### Task 2: Add landscape widget tests to `in_session_view_test.dart` (AC1, AC2, AC3)

- [x] READ `pulse_coach/test/widget/in_session_view_test.dart` fully before editing. Current state: 195 lines, tests `8.2-WIDGET-001` through `8.2-WIDGET-007` and `8.4-WIDGET-001` through `8.4-WIDGET-006`. Uses `tester.view.physicalSize` + `devicePixelRatio` pattern (NOT `tester.binding.setSurfaceSize`).

- [x] UPDATE `pulse_coach/test/widget/in_session_view_test.dart`

  Add these 4 tests **inside the existing `group('InSessionView', ...)`** block, after `8.4-WIDGET-006`:

  ```dart
  testWidgets('11.3-WIDGET-001: landscape 640x360 renders without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(_view()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('11.3-WIDGET-002: landscape shows timer in left column', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(_view(seconds: 90)));
    await tester.pump();

    expect(find.text('01:30'), findsOneWidget);
  });

  testWidgets('11.3-WIDGET-003: landscape shows instruction text in right column', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(_view(step: 1)));
    await tester.pump();

    // Instruction text from step index 1 — 'Mantieni il ritmo.'
    expect(find.text('Mantieni il ritmo.'), findsOneWidget);
  });

  testWidgets('11.3-WIDGET-004: timer value is preserved when surface rotates landscape', (
    tester,
  ) async {
    // Start portrait
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(_view(seconds: 75)));
    await tester.pump();
    expect(find.text('01:15'), findsOneWidget);

    // Simulate rotation to landscape — same widget, new surface size
    tester.view.physicalSize = const Size(640, 360);
    await tester.pump();

    // Timer value unchanged — driven by sessionState parameter, not widget state
    expect(find.text('01:15'), findsOneWidget);
  });
  ```

---

### Task 3: Run tests and verify zero regressions (AC1, AC2, AC3)

- [x] Run `flutter test pulse_coach/test/widget/in_session_view_test.dart` from `pulse_coach/` — all tests must pass including the 4 new ones.
- [x] Run `flutter test` from `pulse_coach/` — full suite (currently 748 tests) must pass with target ≥ 752 total.
- [x] Run `flutter analyze` from `pulse_coach/` — zero issues.

---

## Dev Notes

### Why only `InSessionView` needs code changes

The other key screens are already landscape-compliant without additional work:

- **TodayPage** — On a landscape phone, the outer `AppShell.LayoutBuilder` sees width ≥ 600dp (SM-A520F: 640dp), so `_TabletScaffold` renders with `NavigationRail(minWidth: 80)`. The inner `TodayPage._buildLoaded()` `LayoutBuilder` then sees ~559dp (640 - 80 - 1 divider), which is < 600dp, so the **phone** scrollable `Column` renders — fully scrollable in landscape, no overflow.
- **SessionsPage** — `CustomScrollView` scrolls in all orientations; no fixed-height non-scrollable content.
- **ProgressPage** — `Column` with `DefaultTabController` + `TabBarView` containing `CustomScrollView`/`SingleChildScrollView`; scrollable in all orientations.
- **CountdownOverlay** — `Center(Column(mainAxisSize: MainAxisSize.min, ...))` — centers in all orientations, no overflow possible.

The only screen with a real landscape overflow is `InSessionView`, where the portrait `Column` with `Spacer` stacks ~320dp of content but gets only ~288dp of available height on the SM-A520F in landscape (1920×1080 pixels @ 3.0x density → 640×360dp logical, minus SafeArea insets ~72dp for status + nav bar → 288dp body height).

### OrientationBuilder vs LayoutBuilder

`OrientationBuilder` is specified in AC1 (FR39, UX-DR16) and is the correct widget. It fires on `MediaQuery` orientation changes, which is exactly what happens on device rotation. Internally it uses `LayoutBuilder`; for a full-screen widget like `InSessionView.Scaffold.body`, both would give equivalent results. Use `OrientationBuilder` as specified.

### Portrait body: zero changes

`_portraitBody` is a verbatim extraction of the existing `Stack > Padding > Column` content from `build()`. The semantics, style references, and `Spacer` behavior are all preserved. No regression risk to the 9 existing `in_session_view_test.dart` portrait tests.

### Landscape body: left/right panel design

| Panel | Contents | Rationale |
|---|---|---|
| Left (Expanded) | step title + step counter + 48dp timer + LinearProgressIndicator | The "data" side: metrics the user tracks |
| Right (Expanded) | instruction text (maxLines: 6, ellipsis) + abandon TextButton | The "action" side: what to do + exit |

`MainAxisAlignment.center` in both `Column`s centers content vertically. No `Spacer` needed since content is far shorter than available height. `maxLines: 6` on instruction text guards against pathological cases without requiring `SingleChildScrollView` inside the bounded column.

### `_HrBadge` in landscape

Remains `Positioned(top: 8, right: 8)` inside the `Stack`. The position offset is reduced from `top: 16, right: 16` to `top: 8, right: 8` to respect the smaller padding applied in landscape (`EdgeInsets.symmetric(horizontal: 16, vertical: 12)` vs portrait's `fromLTRB(24, 32, 24, 24)`).

### State preservation on rotation (AC2)

`_InSessionPageState` (the `StatefulWidget` wrapping `InSessionView`) holds `_cubit` as an instance field. Flutter preserves `State` objects across orientation changes because `FlutterActivity` handles `configChanges="orientation|..."` without recreating the activity (see `AndroidManifest.xml` line 19). The `InSessionCubit`'s `StreamSubscription`-based timer continues uninterrupted. No code change required — this already works.

`11.3-WIDGET-004` validates the principle: `InSessionView` is `StatelessWidget` and all display is driven by the `sessionState` parameter. Surface size change triggers a rebuild but does not reset the parameter — the timer value is preserved.

### Test surface size pattern used in this project

Previous stories (8.2, 8.4, 11.1, 11.2) use two different APIs for surface size in tests:

| API | Usage in this project | Notes |
|---|---|---|
| `tester.view.physicalSize` + `tester.view.devicePixelRatio` | `in_session_view_test.dart` (stories 8.2, 8.4) | Use `addTearDown(tester.view.resetPhysicalSize)` |
| `tester.binding.setSurfaceSize(const Size(...))` | `today_page_test.dart`, `app_shell_test.dart` | Use `addTearDown(() => tester.binding.setSurfaceSize(null))` |

**CRITICAL:** Follow the existing pattern in the target test file. `in_session_view_test.dart` uses `tester.view.physicalSize` — use that API for the new tests (NOT `setSurfaceSize`).

### No build_runner, no ARB keys, no new files

- No freezed classes, drift tables, or injectable registrations changed.
- No new ARB translation keys needed.
- `dart run build_runner build` is NOT required.
- No new files created — all changes are in existing files.

### flutter analyze: zero tolerance

The new private methods `_portraitBody` and `_landscapeBody` take non-const parameters so they cannot have `const` constructors. They are instance methods on `InSessionView` (a `StatelessWidget`), which is the correct pattern. No `// ignore:` suppression should be needed.

### Project Structure Notes

- **File modified**: `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart`
- **Test file updated**: `pulse_coach/test/widget/in_session_view_test.dart`
- No new files created.

### References

- [Source: epics.md lines 1688–1708] Story 11.3 ACs: OrientationBuilder, no data loss, InSessionView timer preservation, landscape phone no overflow
- [Source: epics.md line 140] UX-DR16: OrientationBuilder, no data loss on rotation
- [Source: epics.md line 60] FR39: All key screens support both portrait and landscape
- [Source: architecture.md line 257] Responsive Strategy: LayoutBuilder at scaffold level, 600dp breakpoint, shared components
- [Source: pulse_coach/android/app/src/main/AndroidManifest.xml line 19] `configChanges="orientation|..."` — Flutter activity handles rotation without recreating; State objects preserved
- [Source: in_session_view_test.dart] Existing pattern: `tester.view.physicalSize` + `devicePixelRatio` (NOT `setSurfaceSize`)
- [Source: pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart] Current portrait layout: `Scaffold > SafeArea > Stack > Padding(fromLTRB(24,32,24,24)) > Column(…Spacer…) + Positioned(HrBadge)`
- [Source: pulse_coach/lib/core/theme/app_text_styles.dart] `timerDisplay.fontSize = 48`, `h2.fontSize = 20`, `body.fontSize = 15` — used in height budget calculation
- [Source: 11-2-tablet-today-screen-master-detail.md Dev Notes] `setSurfaceSize(null)` not `resetSurfaceSize()` pattern; confirmed via Story 11.1 review

## Dev Agent Record

### Agent Model Used

Codex (GPT-5)

### Debug Log References

- `flutter test test/widget/in_session_view_test.dart` failed before production changes on `11.3-WIDGET-002` because `OrientationBuilder` was absent.
- `flutter test test/widget/in_session_view_test.dart` passed after implementation: 18/18 tests.
- `flutter test` passed: 753/753 tests.
- `flutter analyze` passed: no issues found.

### Implementation Plan

- Extract the existing portrait `Stack` layout from `InSessionView.build()` into `_portraitBody` without changing its behavior.
- Wrap `Scaffold.body` in `OrientationBuilder` and route landscape builds to a compact two-column layout.
- Preserve timer/session display from `sessionState` so rotation rebuilds do not reset displayed session state.
- Add widget coverage for landscape rendering, explicit `OrientationBuilder` usage, landscape timer/instruction visibility, and timer preservation across a simulated rotation.

### Completion Notes List

- Implemented landscape support for `InSessionView` using `OrientationBuilder`.
- Added a landscape two-column layout that keeps step identity/timer/progress on the left and instruction/abandon action on the right.
- Preserved portrait layout behavior by extracting the original body into `_portraitBody`.
- Added five widget tests: the four requested landscape/timer tests plus one AC1-focused `OrientationBuilder` assertion needed to produce a valid red phase.

### File List

- `_bmad-output/implementation-artifacts/11-3-portrait-and-landscape-orientation-support.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart`
- `pulse_coach/test/widget/in_session_view_test.dart`

### Change Log

- 2026-05-29: Implemented Story 11.3 portrait/landscape orientation support for `InSessionView`, added widget tests, and validated with targeted tests, full suite, and analyzer.

## Review Findings

_Code review 2026-05-29 (3 layers: Blind Hunter, Edge Case Hunter, Acceptance Auditor). All 3 ACs PASS; 753/753 tests + analyze clean independently reproduced._

- [x] [Review][Decision→Patch] Orientation bodies are not scrollable — overflow risk under large accessibility text scaling and very short landscape surfaces (split-screen/foldable). **Resolved (2026-05-30):** both `_portraitBody` and `_landscapeBody` now wrapped in a shared `_scrollable()` helper (`LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight: maxHeight)` + `IntrinsicHeight`), the same pattern used in `today_page`. Layout/`Spacer` behavior preserved when content fits; degrades to scroll when it exceeds. [in_session_view.dart `_scrollable`/`_portraitBody`/`_landscapeBody`]
- [x] [Review][Patch] Left landscape column `step.title` lacks `maxLines`/`overflow` — asymmetric with right column instruction (`maxLines: 6, ellipsis`). **Resolved (2026-05-30):** added `maxLines: 2, overflow: TextOverflow.ellipsis` to the landscape left-column title. [pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart `_landscapeBody` left column title]
- [x] [Review][Defer] `totalSteps == 0` → division-by-zero in `LinearProgressIndicator.value` + `RangeError` on `currentStep` [in_session_view.dart, in_session_state.dart:27] — deferred, pre-existing (carried verbatim into both branches; `SessionStepGenerator` always returns 3 steps, currently unreachable)
- [x] [Review][Defer] HR badge `Positioned(top: 8, right: 8)` may overlap centered content in very short landscape [in_session_view.dart `_landscapeBody`] — deferred, low risk (badge small, content centered; only pathological short heights)
- [x] [Review][Defer] No landscape test exercises a long title/instruction to validate the `maxLines`/overflow boundary [test/widget/in_session_view_test.dart] — deferred, test-coverage gap (all fixtures use short strings)
- [x] [Review][Defer] Progress bar treats the current in-progress step as complete via `(currentStepIndex + 1) / totalSteps` [in_session_view.dart] — deferred, pre-existing product-decision behavior, not introduced by this change
