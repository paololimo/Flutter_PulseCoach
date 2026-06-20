# Story 8.1: CountdownOverlay

Status: done

## Story

As a user,
I want a calm 3-2-1 countdown before a session starts,
So that I have a moment to transition mentally from the planning view to the physical activity.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The user taps "Inizia sessione" on the HeroSessionCard | The transition to the session view occurs | A full-screen `CountdownOverlay` displays with 3 → 2 → 1 in `AppTextStyles.countdown` (JetBrains Mono 72sp), `PulseCoachTheme.primaryColor` background, and 400ms ease-in-out number animations (UX-DR7, UX-DR18 ritual duration) |
| AC2 | The countdown completes (3 → 2 → 1 → "GO" holds 300ms) | The overlay dismisses | The screen reveals the full-screen `InSessionPage` content (Story 8.2 placeholder is acceptable; nav bar stays hidden throughout) |
| AC3 | "Reduce Motion" is enabled (device accessibility setting) | The countdown renders | Numbers display statically — no `AnimationController` fade/scale; each number is shown for ~1 second as a static `Text`; transition to InSessionPage is an instant cut (UX-DR7, UX-DR18) |
| AC4 | The new navigation wiring is in place | `flutter test` and `flutter analyze` run | Zero-tolerance baseline preserved; test `7.3-PAGE-011` updated for navigation behavior; new `8.1-WIDGET-*` tests added |

## Tasks / Subtasks

### Task 1: Create `CountdownOverlay` widget (AC1, AC2, AC3)

- [x] CREATE `pulse_coach/lib/features/session/presentation/widgets/countdown_overlay.dart`

  **Widget signature:**
  ```dart
  class CountdownOverlay extends StatefulWidget {
    final String? sessionTitle;       // shown below countdown number (optional)
    final VoidCallback onCountdownComplete;

    const CountdownOverlay({
      required this.onCountdownComplete,
      this.sessionTitle,
      super.key,
    });
  }
  ```

  **State class:** `_CountdownOverlayState extends State<CountdownOverlay> with SingleTickerProviderStateMixin`

  **Animation setup (initState):**
  ```dart
  static const _ritualDuration = Duration(milliseconds: 400);  // UX-DR18 ritual
  static const _holdDuration   = Duration(milliseconds: 700);
  static const _goDuration     = Duration(milliseconds: 300);  // UX-DR18 go-hold

  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  int _count = 3;     // current displayed number (0 means "GO")
  bool _showGo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _ritualDuration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale   = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCountdown());
  }
  ```

  **Countdown logic (_runCountdown):**
  ```dart
  Future<void> _runCountdown() async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);  // Flutter 3.13+

    for (final count in [3, 2, 1]) {
      if (!mounted) return;
      setState(() { _count = count; _showGo = false; });

      if (reduceMotion) {
        await Future.delayed(const Duration(milliseconds: 1000));
      } else {
        await _controller.forward(from: 0);
        if (!mounted) return;
        await Future.delayed(_holdDuration);
      }
      if (!mounted) return;
    }

    // Show "GO"
    if (!mounted) return;
    setState(() { _showGo = true; });
    await Future.delayed(_goDuration);
    if (!mounted) return;

    widget.onCountdownComplete();
  }
  ```

  **dispose:**
  ```dart
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  ```

  **build — full-screen layout:**
  ```dart
  @override
  Widget build(BuildContext context) {
    final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;

    // Accessibility: live region announces each number
    final semanticLabel = _showGo
        ? l10n.countdownGoAnnounce
        : l10n.countdownSemanticAnnounce(_count.toString());

    final numberWidget = _showGo
        ? Text('GO', style: AppTextStyles.countdown.copyWith(color: Colors.white))
        : Text('$_count', style: AppTextStyles.countdown.copyWith(color: Colors.white));

    final animated = AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: numberWidget,
    );

    // For Reduce Motion: skip animation wrapper, show static widget
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      liveRegion: true,
      label: semanticLabel,
      child: Scaffold(
        backgroundColor: pulseTheme.primaryColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                reduceMotion ? numberWidget : animated,
                if (widget.sessionTitle != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.sessionTitle!,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  ```

  **Required imports:**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:pulse_coach/core/theme/app_text_styles.dart';
  import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';
  ```

  **No DI / Bloc / freezed** — pure stateful UI widget.

---

### Task 2: Update `InSessionPage` to show CountdownOverlay then placeholder (AC1, AC2)

- [x] UPDATE `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`

  Current: `StatelessWidget` with placeholder text.

  Replace entirely with:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:pulse_coach/core/theme/app_text_styles.dart';
  import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
  import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
  import 'package:pulse_coach/features/session/presentation/widgets/countdown_overlay.dart';
  import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  class InSessionPage extends StatefulWidget {
    final PlannedSession? session;

    const InSessionPage({this.session, super.key});

    @override
    State<InSessionPage> createState() => _InSessionPageState();
  }

  class _InSessionPageState extends State<InSessionPage> {
    bool _countdownDone = false;

    @override
    Widget build(BuildContext context) {
      if (!_countdownDone) {
        final l10n = AppLocalizations.of(context)!;
        final sessionTitle = widget.session != null
            ? sessionDisplayName(widget.session!.sessionType, l10n)
            : null;

        return CountdownOverlay(
          sessionTitle: sessionTitle,
          onCountdownComplete: () {
            if (mounted) setState(() => _countdownDone = true);
          },
        );
      }

      // Story 8.2 placeholder — will be replaced by the real InSessionView
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      return Scaffold(
        backgroundColor: pulseTheme.surface,
        body: Center(
          child: Text('In Session — Story 8.2', style: AppTextStyles.body),
        ),
      );
    }
  }
  ```

  **Key decisions:**
  - `PlannedSession? session` is optional — future navigation paths (e.g., from Sessions catalog) may omit it.
  - Session title is formatted via `sessionDisplayName()` from `session_card_helpers.dart` (already localised — returns "Mobilità", "Cardio", "Respirazione").
  - Story 8.2 placeholder uses `PulseCoachTheme.surface` background (not a spinner — project rule: no `CircularProgressIndicator`).

---

### Task 3: Update `app_router.dart` to pass session via `extra` (AC1)

- [x] UPDATE `pulse_coach/lib/core/routing/app_router.dart`

  Change the `sessionActive` `GoRoute` builder from:
  ```dart
  GoRoute(
    path: sessionActive,
    builder: (context, state) => const InSessionPage(),
  ),
  ```
  to:
  ```dart
  GoRoute(
    path: sessionActive,
    builder: (context, state) {
      final session = state.extra as PlannedSession?;
      return InSessionPage(session: session);
    },
  ),
  ```

  Add import at top of file (if not already present):
  ```dart
  import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
  ```

  **No other changes to the router.** `sessionActive` path (`/session/active`) is already outside the `ShellRoute` — the bottom nav bar is already hidden on this route.

---

### Task 4: Update `today_page.dart` — replace `onStart` with navigation (AC1)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/pages/today_page.dart`

  In class `_HeroZone`, method `build()`, the `HeroSessionCard` call (around line 237):

  **Before:**
  ```dart
  onStart: () =>
      context.read<TodaySessionCubit>().markSessionCompleted().ignore(),
  ```

  **After:**
  ```dart
  onStart: () => context.push(AppRouter.sessionActive, extra: session),
  ```

  Add import at the top of `today_page.dart`:
  ```dart
  import 'package:go_router/go_router.dart';
  import 'package:pulse_coach/core/routing/app_router.dart';
  ```

  **Behavioral change (expected and correct):** Tapping "Inizia sessione" now navigates to the session flow instead of immediately marking the session complete. The `CompletionRing` no longer advances on tap — it advances after the full session is completed in Story 8.2. This is the intended architecture.

  **`markSessionCompleted()` is NOT removed from `TodaySessionCubit`** — it will be called by Story 8.2's InSessionView when the session actually finishes.

---

### Task 5: Add countdown ARB keys (AC1, AC3)

- [x] UPDATE `pulse_coach/lib/l10n/app/app_en.arb`

  Add after the last key (before the closing `}`):
  ```json
  "countdownSemanticAnnounce": "Starting in {count}",
  "@countdownSemanticAnnounce": {
    "placeholders": {
      "count": {
        "type": "String"
      }
    }
  },
  "countdownGoAnnounce": "Go"
  ```

- [x] UPDATE `pulse_coach/lib/l10n/app/app_it.arb`

  Add after the last key (before the closing `}`):
  ```json
  "countdownSemanticAnnounce": "Inizia tra {count}",
  "@countdownSemanticAnnounce": {
    "placeholders": {
      "count": {
        "type": "String"
      }
    }
  },
  "countdownGoAnnounce": "Vai"
  ```

  **ARB file format**: Both files use JSON — ensure the preceding key ends with a comma before these new entries.

  **After editing ARB files**, run `flutter pub get` (or any command that triggers `gen_l10n`) to regenerate `app_localizations*.dart` under `lib/l10n/`. The generated files are `.gitignore`'d; commit only the ARB source files.

---

### Task 6: Create `countdown_overlay_test.dart` (AC1, AC2, AC3, AC4)

- [x] CREATE `pulse_coach/test/widget/countdown_overlay_test.dart`

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/core/theme/app_text_styles.dart';
  import 'package:pulse_coach/core/theme/app_theme.dart';
  import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
  import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
  import 'package:pulse_coach/features/session/presentation/widgets/countdown_overlay.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  Widget _wrap(Widget child, {bool disableAnimations = false}) =>
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.darkTheme,
          home: child,
        ),
      );
  ```

  **Required tests:**

  ```
  8.1-WIDGET-001: Background color matches primary color (aqua green)
  8.1-WIDGET-002: Initial display shows "3" using countdown text style
  8.1-WIDGET-003: onCountdownComplete fires after full sequence (pump timers + animations)
  8.1-WIDGET-004: sessionTitle appears below the countdown number when provided
  8.1-WIDGET-005: Reduce Motion — onCountdownComplete fires and no animation controller runs
  8.1-WIDGET-006: InSessionPage shows CountdownOverlay initially (countdownDone == false)
  8.1-WIDGET-007: InSessionPage shows session placeholder after countdown completes
  ```

  **Test details:**

  - **8.1-WIDGET-001**: `expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, equals(PulseCoachTheme.dark.primaryColor))`. Wrap in `_wrap(CountdownOverlay(onCountdownComplete: () {}))`.

  - **8.1-WIDGET-002**: `expect(find.text('3'), findsOneWidget)`. Verify that the `Text` widget with text `'3'` uses a style with font family `'JetBrains Mono'` and font size `72.0`.
    ```dart
    final text = tester.widget<Text>(find.text('3').last);
    // The style may be in AppTextStyles.countdown directly or via copyWith
    expect(text.style?.fontSize, 72.0);
    ```

  - **8.1-WIDGET-003**:
    ```dart
    bool completed = false;
    await tester.pumpWidget(_wrap(
      CountdownOverlay(onCountdownComplete: () => completed = true),
    ));
    // Drive all pending timers and animations
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(completed, isTrue);
    ```

  - **8.1-WIDGET-004**:
    ```dart
    await tester.pumpWidget(_wrap(
      CountdownOverlay(sessionTitle: 'Mobilità', onCountdownComplete: () {}),
    ));
    expect(find.text('Mobilità'), findsOneWidget);
    ```

  - **8.1-WIDGET-005** (Reduce Motion):
    ```dart
    bool completed = false;
    await tester.pumpWidget(_wrap(
      CountdownOverlay(onCountdownComplete: () => completed = true),
      disableAnimations: true,
    ));
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(completed, isTrue);
    ```

  - **8.1-WIDGET-006**:
    ```dart
    await tester.pumpWidget(_wrap(const InSessionPage()));
    await tester.pump();  // first frame — countdown not yet done
    expect(find.byType(CountdownOverlay), findsOneWidget);
    ```

  - **8.1-WIDGET-007**:
    ```dart
    await tester.pumpWidget(_wrap(const InSessionPage(), disableAnimations: true));
    await tester.pumpAndSettle(const Duration(seconds: 10));
    // After countdown, placeholder renders
    expect(find.byType(CountdownOverlay), findsNothing);
    expect(find.text('In Session — Story 8.2'), findsOneWidget);
    ```

---

### Task 7: Update `today_page_test.dart` — fix 7.3-PAGE-011 (AC4)

- [x] UPDATE `pulse_coach/test/widget/today_page_test.dart`

  Test `7.3-PAGE-011` currently taps "Inizia sessione" and asserts ring advancement (the old `markSessionCompleted()` behavior). Since `onStart` now navigates, the test must be updated.

  **Add import:**
  ```dart
  import 'package:go_router/go_router.dart';
  import 'package:pulse_coach/core/routing/app_router.dart';
  ```

  **Add a GoRouter-backed helper alongside the existing `wrap()` function:**
  ```dart
  Widget wrapWithRouter({required DailyPlanState planState}) {
    when(dailyPlanBloc.state).thenReturn(planState);
    final cubit = _TestingTodaySessionCubit(sessionLogsDao);
    final total = switch (planState) {
      DailyPlanLoaded(:final plan) => plan.sessions.length,
      _ => 0,
    };
    cubit.planLoaded(total, null).ignore();

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<DailyPlanBloc>.value(value: dailyPlanBloc),
              BlocProvider<TodaySessionCubit>.value(value: cubit),
            ],
            child: const TodayPage(),
          ),
        ),
        GoRoute(
          path: AppRouter.sessionActive,
          builder: (_, __) =>
              const Scaffold(body: Text('session_stub')),
        ),
      ],
    );

    return MaterialApp.router(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
  ```

  **Replace the body of `7.3-PAGE-011`:**
  ```dart
  testWidgets(
    '7.3-PAGE-011: tapping Start Session navigates to session view',
    (tester) async {
      await tester.pumpWidget(
        wrapWithRouter(planState: DailyPlanState.loaded(plan: _plan(3))),
      );
      await tester.pumpAndSettle();

      // Hero is visible before navigation
      expect(find.byType(HeroSessionCard), findsOneWidget);

      await tester.tap(find.text('Inizia sessione'));
      await tester.pumpAndSettle();

      // After navigation, session stub renders (no ring advancement — correct)
      expect(find.text('session_stub'), findsOneWidget);
    },
  );
  ```

  **Note on `_TestingTodaySessionCubit`**: The existing class already accepts `SessionLogsDao` as a constructor parameter — no changes needed.

---

### Task 8: Run baseline verification (AC4)

- [x] `flutter analyze` from `pulse_coach/` → 0 issues
- [x] `flutter pub get` → regenerates `app_localizations*.dart` with new countdown keys
- [x] `flutter test` from `pulse_coach/` → ≥ 541 tests + 7 new `8.1-WIDGET-*` tests
- [x] Verify `CountdownOverlay` renders without overflow in portrait (1080×1920 @ 3.0dpr)
- [x] Verify `app_en.arb` and `app_it.arb` pass JSON validation (no trailing comma before `}`)

---

## Dev Notes

### Current State of Files Being Modified

**`lib/features/session/presentation/pages/in_session_page.dart`**
- Currently a `StatelessWidget` with `AppBar(title: Text('In Session'))` and `Center(child: Text('In Session — Story 8.x'))`.
- **Replace entirely** — Story 8.1 converts it to `StatefulWidget`. No logic to preserve.
- The `AppBar` is REMOVED — the session view is full-screen (no nav, no app bar, per UX-DR8).

**`lib/core/routing/app_router.dart`**
- `sessionActive = '/session/active'` already defined (line 27).
- `InSessionPage` is already imported (line 10).
- Add import for `PlannedSession` from daily plan domain.
- Change builder lambda only — one line change at `GoRoute(path: sessionActive, ...)`.

**`lib/features/today/presentation/pages/today_page.dart`**
- `onStart` at line 237 is the target change.
- `go_router` package is NOT currently imported in this file — add `import 'package:go_router/go_router.dart';`.
- `AppRouter` is NOT currently imported — add `import 'package:pulse_coach/core/routing/app_router.dart';`.
- `session` variable is available in `_HeroZone.build()` as: `final session = plan.sessions[heroIndex];` — pass it as `extra`.

**`lib/l10n/app/app_en.arb` / `app_it.arb`**
- Both files use JSON. The last key currently is `"intensityHigh"` (no trailing comma in the file — add a comma to that line before appending the new keys).
- Generated files (`app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_it.dart`) are auto-regenerated by `flutter pub get` and are `.gitignore`'d — do NOT hand-edit them.

### Architecture Compliance

- `CountdownOverlay` lives in `lib/features/session/presentation/widgets/` per architecture file tree (line 704 of architecture.md).
- No BLoC, no injectable, no domain calls — pure stateful widget driven by `initState` + `WidgetsBinding.addPostFrameCallback`.
- `MediaQuery.disableAnimationsOf(context)` is the correct API for Reduce Motion in Flutter 3.13+ (project uses Flutter 3.41.x).
- `AppTextStyles.countdown` already exists in `lib/core/theme/app_text_styles.dart` (JetBrains Mono, fontSize 72, height 1.0) — do NOT define a new TextStyle.
- `PulseCoachTheme.dark.primaryColor = Color(0xFF7DD3C0)` is the aqua green specified by UX-DR7.
- Route `/session/active` is already outside `ShellRoute` — nav bar is already hidden.
- No `CircularProgressIndicator` — session placeholder uses themed surface + `Text` only.

### Animation Implementation Note

The `AnimationController` drives both `_opacity` and `_scale` for each number appearance (forward from 0 → 1 in 400ms ease-in-out). Between numbers, `_controller.forward(from: 0)` resets and plays the animation for the next count. This means each number fades+scales in (400ms) and then holds visually for `_holdDuration` (700ms). There is no fade-out animation between numbers — the `setState(() { _count = count; })` call instantly replaces the number, and `_controller.forward(from: 0)` plays the new in-animation. This matches the UX spec ("400ms ease-in-out animation", "calm transition").

### Anti-Patterns to Avoid

| ❌ | ✅ |
|---|---|
| Call `markSessionCompleted()` in `onStart` | Navigate to `AppRouter.sessionActive` with `extra: session` |
| Hard-code `Color(0xFF7DD3C0)` in widget | Use `Theme.of(context).extension<PulseCoachTheme>()!.primaryColor` |
| Define custom `TextStyle` for countdown number | Use `AppTextStyles.countdown` (already exists at 72sp JetBrains Mono) |
| Add `AppBar` to the session scaffold | InSessionPage is full-screen — no AppBar, no Scaffold in CountdownOverlay top widget |
| Use `CircularProgressIndicator` for any loading state | Use themed surface + text placeholder per project rules |
| Call `setState` or `widget.onCountdownComplete()` after dispose | Guard all async continuation points with `if (!mounted) return;` |
| Use `MediaQuery.of(context).accessibilityFeatures.disableAnimations` | Use `MediaQuery.disableAnimationsOf(context)` (correct API in Flutter 3.41.x) |
| Create a new route `/session/countdown` | Use existing `/session/active` route — CountdownOverlay lives inside `InSessionPage` |
| Make `CountdownOverlay` a `StatelessWidget` | Must be `StatefulWidget` — animation state and timer lifecycle require `State` |
| Use relative imports (`../`) across features | Use package imports (`package:pulse_coach/...`) — project convention |

### Test Naming Convention

- New widget tests: `8.1-WIDGET-001` through `8.1-WIDGET-007`
- Existing cubit test `7.3-PAGE-011` is UPDATED (not renumbered — keep original ID)

### Go_router `extra` Notes

`state.extra` in go_router is typed as `Object?`. The cast `state.extra as PlannedSession?` is safe because we only navigate to `sessionActive` with a `PlannedSession?` extra. If the route is opened directly (e.g., deep link or hot restart), `extra` will be `null` — the `InSessionPage` handles null gracefully (`PlannedSession? session` is nullable).

### Test Timing Notes for Animation Tests

`pumpAndSettle(const Duration(seconds: 10))` drives the Flutter clock forward 10 real-seconds worth of async work. This is sufficient to run through the full countdown sequence (3 numbers × ~1.1s + 0.3s GO ≈ 3.6s total). Using a sufficiently large duration avoids flakiness without requiring `fake_async` for this animation-heavy widget.

### Behavioral Change Summary (Important)

Story 8.1 changes the `onStart` behavior:
- **Before**: tap "Inizia sessione" → `markSessionCompleted()` → ring advances, hero advances
- **After**: tap "Inizia sessione" → navigate to `/session/active` → CountdownOverlay renders

The `TodayPage` will no longer show ring advancement on tap. Ring advancement moves to post-session completion (Story 8.2). This is the correct production behavior. `7.3-PAGE-011` is the only test affected.

### References

- `AppTextStyles.countdown`: `pulse_coach/lib/core/theme/app_text_styles.dart:13-17`
- `PulseCoachTheme.dark.primaryColor`: `pulse_coach/lib/core/theme/pulse_coach_theme.dart:30`
- `CountdownOverlay` architecture placement: `_bmad-output/planning-artifacts/architecture.md:704`
- `sessionDisplayName()` helper: `pulse_coach/lib/features/today/presentation/widgets/session_card_helpers.dart`
- Animation pattern reference: `pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart:38-58`
- UX-DR7 spec: `_bmad-output/planning-artifacts/epics.md:131`
- UX-DR18 animation constants: `_bmad-output/planning-artifacts/epics.md:142`
- `onStart` callback target: `pulse_coach/lib/features/today/presentation/pages/today_page.dart:237`
- `sessionActive` route: `pulse_coach/lib/core/routing/app_router.dart:27,69-71`
- Test baseline: 541/541 (post Story 8.0 code review — see Story 8.0 file)

---

## Dev Agent Record

### Agent Model Used

GPT-5

### Debug Log References

- 2026-05-17: Red phase `flutter test test/widget/countdown_overlay_test.dart` failed because `countdown_overlay.dart` did not exist.
- 2026-05-17: Green phase `flutter test test/widget/countdown_overlay_test.dart` passed with 7/7 tests.
- 2026-05-17: Red phase `flutter test test/widget/today_page_test.dart --plain-name "7.3-PAGE-011"` failed before navigation wiring.
- 2026-05-17: Green phase `flutter test test/widget/today_page_test.dart --plain-name "7.3-PAGE-011"` passed after `context.push(...)` wiring.
- 2026-05-17: `flutter analyze` passed with no issues.
- 2026-05-17: `python3 -m json.tool lib/l10n/app/app_en.arb` and `app_it.arb` passed.
- 2026-05-17: `flutter test` passed with 548/548 tests.

### Completion Notes List

- Implemented full-screen `CountdownOverlay` with 3-2-1-GO flow, themed background, JetBrains Mono countdown style, live-region semantics, and reduce-motion static timing.
- Replaced `InSessionPage` placeholder app bar with countdown-first full-screen session entry and Story 8.2 placeholder after completion.
- Wired `/session/active` to accept `PlannedSession?` via `go_router` `extra`, and changed Today hero start action to navigate instead of completing the session immediately.
- Added English and Italian countdown localization keys and regenerated Flutter localization outputs.
- Added 7 `8.1-WIDGET-*` tests and updated `7.3-PAGE-011`; adjusted legacy smoke/ARB invariants to match Story 8.1 behavior.

### File List

- `pulse_coach/lib/features/session/presentation/widgets/countdown_overlay.dart` (NEW)
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart` (UPDATE — full rewrite to StatefulWidget)
- `pulse_coach/lib/core/routing/app_router.dart` (UPDATE — pass PlannedSession via extra)
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart` (UPDATE — onStart navigates instead of markSessionCompleted)
- `pulse_coach/lib/l10n/app/app_en.arb` (UPDATE — add countdown ARB keys)
- `pulse_coach/lib/l10n/app/app_it.arb` (UPDATE — add countdown ARB keys)
- `pulse_coach/lib/l10n/app_localizations.dart` (UPDATE — generated countdown localization API)
- `pulse_coach/lib/l10n/app_localizations_en.dart` (UPDATE — generated English countdown strings)
- `pulse_coach/lib/l10n/app_localizations_it.dart` (UPDATE — generated Italian countdown strings)
- `pulse_coach/test/widget/countdown_overlay_test.dart` (NEW)
- `pulse_coach/test/widget/today_page_test.dart` (UPDATE — fix 7.3-PAGE-011 + add GoRouter helper)
- `pulse_coach/test/widget/pages_smoke_test.dart` (UPDATE — session smoke test now expects countdown full-screen)
- `pulse_coach/test/widget/state_indicator_test.dart` (UPDATE — ARB key count includes countdown strings)

### Change Log

- 2026-05-17: Implemented Story 8.1 CountdownOverlay and navigation handoff; added/updated widget and localization tests; verified analyze and full test baseline.

### Review Findings

_Code review run: 2026-05-17 (blind + edge + acceptance auditor). Auditor verdict: PASS. All AC met; deviations below are non-blocking._

- [x] [Review][Patch] Replace `context.push(AppRouter.sessionActive, extra: session)` with `context.go(AppRouter.sessionActive, extra: session)` — session entry must be modal-fullscreen with no Android-back escape to Today during the 3-2-1 ritual; back affordance is owned by InSessionPage (Story 8.2). [today_page.dart:239] — **applied**
- [x] [Review][Patch] `Semantics(liveRegion: true, label: ...)` wraps the entire `Scaffold`, potentially shadowing descendant semantic nodes (e.g. session title). Scope the `Semantics` node around only the number widget. [countdown_overlay.dart:91] — **applied** (Semantics + `ExcludeSemantics` wrap only the number widget; Scaffold/session title now expose their own a11y nodes).
- [x] [Review][Patch] `find.byType(Scaffold)` and `find.text('3').last` in tests `8.1-WIDGET-001` / `8.1-WIDGET-002` can mask a duplicate-render bug. Scope finders to descendants of `CountdownOverlay` and assert `findsOneWidget` instead of relying on `.last`. [test/widget/countdown_overlay_test.dart] — **applied** (now uses `find.descendant(of: find.byType(CountdownOverlay), ...)`).
- [x] [Review][Patch] `wrapWithRouter` calls `cubit.planLoaded(total, null).ignore()` without flushing before `pumpAndSettle`; on slow CI the initial state may not be loaded when the tap occurs, causing intermittent navigation without the hero present. Flush the future or add an explicit pump pre-tap. [test/widget/today_page_test.dart:88] — **applied** (replaced async `planLoaded` with synchronous `cubit.seed(TodaySessionState(totalSessions: total))`).
- [ ] [Review][Patch][Rejected] Replace 8.1-WIDGET-003's manual `pump`/`pumpAndSettle` loop with a single `pumpAndSettle(Duration(seconds: 10))` — **rejected**: `pumpAndSettle` only advances the clock while frames are scheduled. During the 700 ms `Future.delayed` between countdown numbers no frame is pending, so a single `pumpAndSettle` returns early and the countdown never completes (test reproduces `Expected: true / Actual: <false>` at the final `expect(completed, isTrue)`). The dev's original `pumpAndSettle()` + explicit `pump(700ms)` + `pump(300ms)` pattern is the correct shape and is retained.
- [x] [Review][Defer] Deep-link / hot-restart to `/session/active` with null `state.extra` strands the user on the Story 8.2 placeholder (no back affordance, no nav bar) — deferred, Story 8.2 owns the real session view and exit affordances. [app_router.dart:71]

**Dismissed (noise / already correct / spec-intentional):**
- `markSessionCompleted()` no longer invoked on tap — intended per Behavioral Change Summary; ring advancement moves to Story 8.2.
- `MediaQuery.disableAnimationsOf(context)` captured once at countdown start — matches spec example; 3.6 s window makes mid-run toggle non-realistic.
- Multiple `onCountdownComplete` invocations on parent rebuild — guarded by `_countdownDone` + `mounted`.
- `_countdownDone` not reset in `didUpdateWidget` — current navigation uses `push` with a fresh `_InSessionPageState`; not reachable in this flow.
- `countdownSemanticAnnounce` placeholder typed as `String` — Italian/English don't need ICU plural; auditor confirmed match with spec.
- `pulseTheme` non-null bang (`!`) in widget/tests — `AppTheme.darkTheme` registers `PulseCoachTheme.dark` as an extension; test wraps use `AppTheme.darkTheme`.
- "GO" 300 ms hold is below TalkBack/VoiceOver live-region debounce — value is fixed by UX-DR18; would require a spec change.
