# Story 11.2: Tablet Today Screen (Master-Detail)

Status: done

## Story

As a tablet user,
I want a master-detail Today screen layout,
so that I can see the session list and session detail simultaneously without navigation.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The app is on a tablet (≥ 600dp width) | When the Today screen renders | Left panel shows: state bar + CompletionRing + all sessions (hero highlighted); right panel shows: selected session detail with full AI explanation, Start button, and step preview (UX-DR15) |
| AC2 | A session is displayed in the left panel | When the user taps it | The right panel updates to show that session's detail — no full-screen navigation occurs |
| AC3 | The completion ring | When viewed on tablet Today | It is visible in the left panel header area (UX-DR15) |
| AC4 | The tablet layout is active (≥ 600dp) | On visual inspection | Left panel is ~40% width (scrollable list); right panel is ~60% width (session detail); a vertical divider separates them |
| AC5 | All sessions are completed | When tablet Today renders | Left panel shows all sessions as completed cards; right panel shows the all-done celebration state (`_AllDoneWidget`) |
| AC6 | The existing phone-layout tests run | After the responsive LayoutBuilder is added | All pre-existing tests in `today_page_test.dart` are constrained to a phone surface (<600dp) and remain valid; no regressions |

## Tasks / Subtasks

---

### Task 1: Add responsive branch in `TodayPage._buildLoaded()` (AC1, AC4)

- [x] READ `pulse_coach/lib/features/today/presentation/pages/today_page.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/features/today/presentation/pages/today_page.dart`

  Inside `_buildLoaded()`, the existing `LayoutBuilder` already provides `constraints`. Add a width check before returning the `SingleChildScrollView` phone layout:

  ```dart
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        return _TabletTodayLayout(
          plan: plan,
          sessionState: sessionState,
          loaded: loaded,
        );
      }
      // ... existing phone layout (SingleChildScrollView + Column) unchanged
    },
  );
  ```

  The phone layout code stays 100% untouched — only the new `if` branch is added.

---

### Task 2: Implement `_TabletTodayLayout` widget (AC1, AC2, AC3, AC4, AC5)

- [x] ADD private `_TabletTodayLayout` widget at the bottom of `today_page.dart` (before `_AllDoneWidget` and `_SessionEntry`).

  This widget renders a `Row` with two `Expanded` panels separated by a `VerticalDivider`:

  **Left panel (flex 4, ~40%):** scrollable list
  - Header row: `StateIndicator(state: ..., transitionKey: ...)` (expanded) + `CompletionRing(completed: ..., total: ...)`
  - `const SizedBox(height: 12)`
  - Completed sessions: `CompletedSessionCard` for each (not tappable, same as phone)
  - All non-completed sessions: `CompactSessionCard` for each, with:
    - `isSelected: i == heroIndex` — new optional parameter (see Task 3)
    - `onTap: () => context.read<TodaySessionCubit>().swapHero(i)`
    - `heroTag: 'session-tablet-${session.sessionType}-$i'`

  **Divider:** `const VerticalDivider(thickness: 1, width: 1)`

  **Right panel (flex 6, ~60%):** session detail or all-done
  - If `allDone`: `const Center(child: _AllDoneWidget())`
  - Else: `_TabletSessionDetailPanel(plan: plan, heroIndex: heroIndex, sessionState: sessionState)`

  Full widget:

  ```dart
  class _TabletTodayLayout extends StatelessWidget {
    final DailyPlan plan;
    final TodaySessionState sessionState;
    final DailyPlanLoaded loaded;

    const _TabletTodayLayout({
      required this.plan,
      required this.sessionState,
      required this.loaded,
    });

    @override
    Widget build(BuildContext context) {
      final sessions = plan.sessions;
      final total = sessions.length;
      final completedCount = sessionState.completedCount.clamp(0, total);
      final heroIndex = total == 0 ? 0 : sessionState.heroIndex.clamp(0, total - 1);
      final allDone = total == 0 || completedCount >= total;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _TabletLeftPanel(
              plan: plan,
              sessionState: sessionState,
              loaded: loaded,
              completedCount: completedCount,
              total: total,
              heroIndex: heroIndex,
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            flex: 6,
            child: allDone
                ? const Center(child: _AllDoneWidget())
                : _TabletSessionDetailPanel(
                    plan: plan,
                    heroIndex: heroIndex,
                  ),
          ),
        ],
      );
    }
  }
  ```

---

### Task 3: Add `isSelected` parameter to `CompactSessionCard` (AC1)

- [x] READ `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart`

  Add `final bool isSelected;` parameter (default `false`). When `isSelected` is true, use a slightly higher-opacity background on the `Material` and add a leading accent bar to indicate selection:

  ```dart
  class CompactSessionCard extends StatelessWidget {
    final PlannedSession session;
    final VoidCallback? onTap;
    final String? heroTag;
    final bool isSelected;        // NEW

    const CompactSessionCard({
      super.key,
      required this.session,
      this.onTap,
      this.heroTag,
      this.isSelected = false,    // NEW default
    });

    @override
    Widget build(BuildContext context) {
      // ...existing code...
      final pulseTheme = ...;
      final bgColor = isSelected
          ? pulseTheme.primaryColor.withValues(alpha: 0.15)
          : pulseTheme.surfaceContainer;

      return Semantics(
        // ...unchanged...
        child: Material(
          color: bgColor,    // was: pulseTheme.surfaceContainer
          // ...rest unchanged...
        ),
      );
    }
  }
  ```

  All existing callers pass no `isSelected` argument and default to `false` — **no regressions** in phone layout.

---

### Task 4: Implement `_TabletLeftPanel` widget (AC1, AC2, AC3)

- [x] ADD private `_TabletLeftPanel` widget in `today_page.dart`.

  ```dart
  class _TabletLeftPanel extends StatelessWidget {
    final DailyPlan plan;
    final TodaySessionState sessionState;
    final DailyPlanLoaded loaded;
    final int completedCount;
    final int total;
    final int heroIndex;

    const _TabletLeftPanel({
      required this.plan,
      required this.sessionState,
      required this.loaded,
      required this.completedCount,
      required this.total,
      required this.heroIndex,
    });

    @override
    Widget build(BuildContext context) {
      final sessions = plan.sessions;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: StateIndicator(
                    state: loaded.behavioralState,
                    transitionKey: loaded.transitionKey,
                  ),
                ),
                const SizedBox(width: 12),
                CompletionRing(completed: completedCount, total: total),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < total; i++) ...[
              if (sessionState.isCompleted(i))
                CompletedSessionCard(session: sessions[i])
              else
                CompactSessionCard(
                  session: sessions[i],
                  isSelected: i == heroIndex,
                  heroTag: 'session-tablet-${sessions[i].sessionType}-$i',
                  onTap: () =>
                      context.read<TodaySessionCubit>().swapHero(i),
                ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }
  }
  ```

---

### Task 5: Implement `_TabletSessionDetailPanel` widget (AC1, AC2)

- [x] ADD private `_TabletSessionDetailPanel` widget in `today_page.dart`.

  This is the right-panel detail view. It shows:
  1. Session name + icon (same accent color as phone)
  2. Duration + intensity row
  3. Full explanation text (no `maxLines` — the full text, untruncated)
  4. Step preview: 3 `ExerciseStep` rows from `SessionStepGenerator.generate(session, l10n)`
  5. Regenerate button (same logic as phone — dispatches `DailyPlanRegenerateRequested` via `DailyPlanBloc`)
  6. Start button (full-width `FilledButton`, navigates to `AppRouter.sessionActive`)

  ```dart
  class _TabletSessionDetailPanel extends StatelessWidget {
    final DailyPlan plan;
    final int heroIndex;

    const _TabletSessionDetailPanel({
      required this.plan,
      required this.heroIndex,
    });

    @override
    Widget build(BuildContext context) {
      final session = plan.sessions[heroIndex];
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      final l10n = AppLocalizations.of(context)!;
      final accentColor = sessionAccentColor(session.sessionType, pulseTheme);
      final displayName = sessionDisplayName(session.sessionType, l10n);
      final steps = SessionStepGenerator.generate(session, l10n);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(sessionIcon(session.sessionType), size: 36, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(displayName, style: AppTextStyles.h2),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 20,
                    semanticLabel: l10n.regenSemanticLabel,
                  ),
                  color: pulseTheme.onSurfaceVariant,
                  onPressed: () {
                    final bloc = context.read<DailyPlanBloc>();
                    if (bloc.state is DailyPlanLoaded) {
                      bloc.add(DailyPlanRegenerateRequested());
                    }
                  },
                  tooltip: l10n.regenTooltip,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Duration + Intensity
            Row(
              children: [
                Text(
                  '${session.durationMinutes} min',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  intensityLabel(session.intensity, l10n),
                  style: AppTextStyles.bodySmall.copyWith(color: accentColor),
                ),
              ],
            ),
            // Full explanation (untruncated)
            if (session.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                session.explanation,
                style: AppTextStyles.bodySmall.copyWith(
                  color: pulseTheme.onSurfaceVariant,
                ),
              ),
            ],
            // Step preview
            const SizedBox(height: 20),
            for (final step in steps) ...[
              _StepPreviewRow(step: step, accentColor: accentColor),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 20),
            // Start button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go(
                  AppRouter.sessionActive,
                  extra: SessionStartArgs(
                    session: session,
                    planId: context.read<TodaySessionCubit>().currentPlanId,
                    sessionIndex: heroIndex,
                  ),
                ),
                child: Text(l10n.startSessionButton),
              ),
            ),
          ],
        ),
      );
    }
  }
  ```

  Add `_StepPreviewRow`:

  ```dart
  class _StepPreviewRow extends StatelessWidget {
    final ExerciseStep step;
    final Color accentColor;

    const _StepPreviewRow({required this.step, required this.accentColor});

    @override
    Widget build(BuildContext context) {
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      final durationLabel = '${step.durationSeconds ~/ 60} min';

      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            durationLabel,
            style: AppTextStyles.bodySmall.copyWith(
              color: pulseTheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
  }
  ```

  **Required new import** in `today_page.dart`:
  ```dart
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
  import 'package:pulse_coach/features/session/presentation/utils/session_step_generator.dart';
  ```

---

### Task 6: Update `today_page_test.dart` for responsive surface (AC6)

- [x] READ `pulse_coach/test/widget/today_page_test.dart` fully before editing.

- [x] UPDATE `pulse_coach/test/widget/today_page_test.dart`

  **Critical:** after adding the 600dp branch in `_buildLoaded()`, the default 800dp flutter_test surface triggers the tablet layout. All existing tests that assert `HeroSessionCard`, `CompactSessionCard`, `PROSSIME`, etc. will FAIL because the tablet layout doesn't render `HeroSessionCard`.

  Fix strategy: add phone/tablet surface helpers (mirrors the pattern from `app_shell_test.dart` Story 11.1):

  ```dart
  Future<void> setPhoneSurface(WidgetTester tester) =>
      tester.binding.setSurfaceSize(const Size(390, 844));

  Future<void> setTabletSurface(WidgetTester tester) =>
      tester.binding.setSurfaceSize(const Size(800, 1024));
  ```

  For **every pre-existing** `testWidgets` block:
  - Add `await setPhoneSurface(tester);` before `pumpWidget`
  - Add `addTearDown(() => tester.binding.setSurfaceSize(null));` inside the test body

  Then add **6 new tablet widget tests**:

  ```dart
  testWidgets('11.2-WIDGET-001: tablet shows two-panel layout', (tester) async {
    await setTabletSurface(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
    );
    // Left and right panels coexist — no HeroSessionCard on tablet
    expect(find.byType(HeroSessionCard), findsNothing);
    expect(find.byType(StateIndicator), findsOneWidget);
    expect(find.byType(CompletionRing), findsOneWidget);
    // The VerticalDivider marks the panel split
    expect(find.byType(VerticalDivider), findsWidgets);
  });

  testWidgets('11.2-WIDGET-002: left panel shows all 3 sessions on tablet', (tester) async {
    await setTabletSurface(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
    );
    // 3 sessions visible (2 upcoming + 1 selected) — all 3 CompactSessionCards
    expect(find.byType(CompactSessionCard), findsNWidgets(3));
  });

  testWidgets('11.2-WIDGET-003: right panel shows full explanation on tablet', (tester) async {
    await setTabletSurface(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
    );
    // Default hero is index 0 (mobility), explanation should appear untruncated
    expect(find.text('Sciogli le spalle.'), findsOneWidget);
  });

  testWidgets('11.2-WIDGET-004: right panel shows step preview rows on tablet', (tester) async {
    await setTabletSurface(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrap(planState: DailyPlanState.loaded(plan: _plan(1))),
    );
    // SessionStepGenerator always produces 3 steps: warmup + main + cooldown
    expect(find.text('Riscaldamento'), findsOneWidget);
    expect(find.text('Defaticamento'), findsOneWidget);
  });

  testWidgets('11.2-WIDGET-005: tapping session in left panel updates right panel', (tester) async {
    await setTabletSurface(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrap(planState: DailyPlanState.loaded(plan: _plan(3))),
    );
    // Initially showing hero=0 (Mobilità) in right panel
    expect(find.text('Sciogli le spalle.'), findsOneWidget);

    // Tap the Cardio CompactSessionCard in left panel
    await tester.tap(find.widgetWithText(CompactSessionCard, 'Cardio').first);
    await tester.pumpAndSettle();

    // Right panel now shows Cardio detail
    expect(find.text('Ritmo leggero.'), findsOneWidget);
    expect(find.text('Sciogli le spalle.'), findsNothing);
  });

  testWidgets('11.2-WIDGET-006: all-done state shows AllDoneWidget on tablet', (tester) async {
    await setTabletSurface(tester);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrap(
        planState: DailyPlanState.loaded(plan: _plan(3)),
        sessionState: const TodaySessionState(
          heroIndex: 2,
          completedIndices: {0, 1, 2},
          totalSessions: 3,
        ),
      ),
    );
    expect(find.text('Ottimo lavoro!'), findsOneWidget);
    expect(find.byType(CompactSessionCard), findsNothing);
  });
  ```

---

### Task 7: Run tests and verify zero regressions (AC6)

- [x] Run `flutter test pulse_coach/test/widget/today_page_test.dart` from `pulse_coach/` — all tests must pass.
- [x] Run `flutter test` from `pulse_coach/` — full suite (currently 742 tests) must pass with new tests (target: ≥ 748 total).
- [x] Run `flutter analyze` from `pulse_coach/` — zero issues.

---

## Dev Notes

### Current TodayPage architecture (read before editing)

`pulse_coach/lib/features/today/presentation/pages/today_page.dart` (293 lines) is a `StatelessWidget` that:
- Listens to `DailyPlanBloc` via `BlocConsumer` and delegates to `TodaySessionCubit` on new plan load
- `_buildLoaded()` already contains a `LayoutBuilder` (originally for `ConstrainedBox` `minHeight`) — **reuse these `constraints` for the responsive branch instead of adding a second nested `LayoutBuilder`**
- Phone layout: `SingleChildScrollView` → `Column` with StateIndicator + CompletionRing header row, completed cards, `AnimatedSwitcher` hero zone, upcoming `CompactSessionCard` list
- The `_HeroZone` private widget renders `HeroSessionCard` with the `onStart` handler; it is ONLY used on phone — the tablet layout does NOT use `_HeroZone` or `HeroSessionCard`
- `_AllDoneWidget` is reused on both phone (inside `AnimatedSwitcher`) and tablet (in right panel)

### Why HeroSessionCard is not in the tablet layout

On phone, `HeroSessionCard` shows the hero session with a gradient background and truncated explanation (maxLines: 2). On tablet, the right panel (`_TabletSessionDetailPanel`) is a dedicated detail view that shows the full untruncated explanation and step preview. `HeroSessionCard` would be visually redundant and the truncation would conflict with AC1's "full AI explanation" requirement. Do not use `HeroSessionCard` in `_TabletTodayLayout`.

### CompactSessionCard `isSelected` visual treatment

The selected card in the left panel gets `bgColor = primaryColor.withValues(alpha: 0.15)` — a subtle tint that matches the app's accent without looking like a button. The `isSelected` parameter defaults to `false`, so all existing `CompactSessionCard` usages (phone layout + upcoming list) are unaffected.

### SessionStepGenerator import

`SessionStepGenerator` lives at `pulse_coach/lib/features/session/presentation/utils/session_step_generator.dart` and `ExerciseStep` at `pulse_coach/lib/features/session/domain/entities/exercise_step.dart`. Both are pure Dart — no Flutter imports — safe to use in `today_page.dart`. The generator uses `AppLocalizations` (already imported in `today_page.dart`).

### Step duration display

`ExerciseStep.durationSeconds` is an `int`. Display as minutes: `'${step.durationSeconds ~/ 60} min'`. A 5-minute session yields warmup=60s, cooldown=60s, main=180s → displayed as "1 min", "1 min", "3 min". This is correct; step preview is indicative, not exact.

### TodaySessionCubit: heroIndex drives right-panel selection

`TodaySessionCubit.heroIndex` already stores the "selected" session index. Tapping a `CompactSessionCard` in the left panel calls `swapHero(index)` (already implemented, same as phone behavior). No new cubit state or events are needed.

### No build_runner changes

No new freezed classes, drift tables, or injectable registrations. `dart run build_runner build` is NOT required.

### No new ARB keys

All strings used by `_TabletSessionDetailPanel` and `_StepPreviewRow` come from existing ARB keys:
- `l10n.startSessionButton` — "Inizia sessione"
- `l10n.regenSemanticLabel`, `l10n.regenTooltip` — regenerate button
- `l10n.inSessionWarmupTitle` — "Riscaldamento"
- `l10n.inSessionCooldownTitle` — "Defaticamento"
- `l10n.sessionNameMobility/Cardio/Breathing` — via `sessionDisplayName()`
- `l10n.intensityLow/Medium/High` — via `intensityLabel()`
Step titles come from `SessionStepGenerator` which uses these same keys.

### Test surface size: the critical regression trap

`today_page_test.dart` currently has 13 `testWidgets` blocks (IDs: `7.3-PAGE-001` through `7.3-PAGE-011`, `7.4-PAGE-001` through `7.4-PAGE-003`). All are on the default 800dp surface. After the responsive branch, they will all render the tablet layout and fail assertions about `HeroSessionCard`. Fix every one with `await setPhoneSurface(tester)` + `addTearDown(() => tester.binding.setSurfaceSize(null))` before calling `pumpWidget`.

Do NOT use `tester.binding.resetSurfaceSize()` — it doesn't exist in the Flutter test binding. Use `setSurfaceSize(null)` instead (same functional result, as confirmed in Story 11.1 review notes).

### VerticalDivider in tablet Row

The `VerticalDivider(thickness: 1, width: 1)` requires the parent `Row` to have `crossAxisAlignment: CrossAxisAlignment.stretch` to fill the full height. Without `stretch`, the divider collapses to zero height.

### Flex split: 4/6 not 40%/60% hardcoded

Use `Expanded(flex: 4, ...)` and `Expanded(flex: 6, ...)` rather than `SizedBox(width: ...)`. This ensures the layout adapts to any tablet width above 600dp, including wide tablets and foldables.

### AnimatedSwitcher in phone layout remains untouched

The `AnimatedSwitcher` that wraps `_HeroZone` on phone is inside the phone branch (`constraints.maxWidth < 600`). The tablet layout does NOT use `AnimatedSwitcher` — the right panel re-renders directly when `heroIndex` changes via `BlocBuilder<TodaySessionCubit, TodaySessionState>`. This is intentional: the 300ms cross-fade makes sense for the phone's single hero card, but the tablet right-panel is a detail view that should update immediately on selection.

### `wrapWithRouter` helper in tests

The test file has a second helper `wrapWithRouter` used only for `7.3-PAGE-011`. Apply the same `setPhoneSurface` fix to that test and keep using `wrapWithRouter` for the Start-button navigation test. For the new `11.2-WIDGET-006` start-button test, use `wrapWithRouter` variant with tablet surface size.

Actually: `11.2-WIDGET-006` above uses `wrap(...)` (not `wrapWithRouter`) intentionally — it only checks the all-done state, not navigation. Add a separate `11.2-WIDGET-007` test for tablet Start button navigation using `wrapWithRouter` if desired (optional, adds safety coverage). Keep the AC-mandatory tests at WIDGET-001 through WIDGET-006.

### flutter analyze: zero tolerance

Run `flutter analyze` from `pulse_coach/` after implementation. The new private widgets must not introduce any lint violations. Key things to watch:
- `ExerciseStep` import must use `package:pulse_coach/...` not relative `../`
- `SessionStepGenerator.generate()` is a static method — no instance needed
- `_StepPreviewRow` is a private `StatelessWidget`, no `const` constructor issue since it takes non-const `Color`

### Project Structure Notes

- **File modified**: `pulse_coach/lib/features/today/presentation/pages/today_page.dart`
- **File modified**: `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart` (add `isSelected` param only)
- **Test file updated**: `pulse_coach/test/widget/today_page_test.dart`
- **No new files created** — all new widgets are private classes at the bottom of `today_page.dart`
- Architecture planned `responsive_scaffold.dart` — not relevant here; tablet Today logic lives inside the feature's own page file

### References

- [Source: epics.md lines 1668–1687] Story 11.2 ACs: master-detail layout, left panel content, right panel content, tap-to-select, completion ring placement
- [Source: ux-design-specification.md lines 729–732] Tablet Today master-detail spec: left = state bar + all sessions (hero highlighted), right = detail + explanation + Start, CompletionRing in left header
- [Source: ux-design-specification.md lines 1546–1549] Architecture layout description: two-column tablet Today
- [Source: architecture.md line 257] Responsive strategy: `LayoutBuilder` at scaffold level, single 600dp breakpoint, shared components different arrangement
- [Source: project-context.md] Responsive: LayoutBuilder, 600dp breakpoint; Shimmer not spinner for loading; no HeroSessionCard duplication
- [Source: 11-1-responsive-scaffold-and-navigationrail-tablet.md] `setSurfaceSize(null)` pattern (not `resetSurfaceSize()`), `setPhoneSurface`/`setTabletSurface` helpers pattern
- [Source: pulse_coach/lib/features/session/presentation/utils/session_step_generator.dart] `SessionStepGenerator.generate(session, l10n)` → 3-step list (warmup 20%, main 60%, cooldown 20%)
- [Source: pulse_coach/lib/features/today/presentation/pages/today_page.dart] Current `_buildLoaded()` LayoutBuilder structure; `_AllDoneWidget` reuse; phone session loop patterns

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter test test/widget/today_page_test.dart` (RED): failed on tablet expectations before implementation.
- `flutter test test/widget/today_page_test.dart`: passed, 20/20.
- `flutter test test/widget/session_card_test.dart`: passed, 44/44 after preserving existing compact-card padding contract.
- `flutter test`: passed, 748/748.
- `flutter analyze`: passed, no issues found.

### Completion Notes List

- Added a >=600dp TodayPage tablet branch that renders a 4/6 master-detail layout with a vertical divider.
- Implemented tablet left panel with StateIndicator, CompletionRing, completed cards, and all incomplete sessions as selectable CompactSessionCards.
- Implemented tablet right detail panel with full session explanation, step preview rows from SessionStepGenerator, regenerate action, and Start button routing.
- Added CompactSessionCard `isSelected` support with selected tint and leading accent bar while preserving existing default behavior and padding.
- Constrained existing TodayPage widget tests to phone surfaces and added six tablet widget tests covering layout, session list, explanation, step preview, selection, and all-done state.

### File List

- pulse_coach/lib/features/today/presentation/pages/today_page.dart
- pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart
- pulse_coach/test/widget/today_page_test.dart
- _bmad-output/implementation-artifacts/11-2-tablet-today-screen-master-detail.md
- _bmad-output/implementation-artifacts/sprint-status.yaml

### Change Log

- 2026-05-29: Implemented tablet Today master-detail layout and responsive widget coverage for Story 11.2.

### Review Findings

Code review 2026-05-29 (3-layer adversarial: Blind Hunter + Edge Case Hunter + Acceptance Auditor). Outcome: **0 decision-needed, 0 patch, 2 defer, 10 dismissed**. All ACs (AC1–AC6) verified PASS. No blocking issues.

- [x] [Review][Defer] Tablet `heroIndex` clamp not completion-aware [today_page.dart `_TabletTodayLayout.build`] — deferred, optional hardening; currently UNREACHABLE (cubit `_pickHeroIndex`/`_onLogsChanged`/`swapHero` guarantee the hero never sits on a completed-but-not-all session; the `allDone` branch covers the all-complete case). Logged as CR112-001 in `deferred-work.md`.
- [x] [Review][Defer] `sessionAccentColor` hardcodes cardio accent `Color(0xFFF0A1B0)` [session_card_helpers.dart] — deferred, pre-existing helper unchanged by this story. Logged as CR112-002 in `deferred-work.md`.

Dismissed as noise (not defects): "0 min" step preview (generator floors every phase at 60s via `max(phaseMin, …)`, so `~/ 60 ≥ 1` always); right-panel reactivity (works via page-level `BlocBuilder`, verified by 11.2-WIDGET-005); hero-tag collision (tablet uses `session-tablet-*`); `!` bangs and regenerate guard (standard/consistent patterns); inline `600`/`flex 4-6` (documented breakpoint, spec-prescribed); detail-panel internal bounds check (parent clamps); `total==0` → `_AllDoneWidget` (unreachable); step-minutes ≠ session-duration (indicative by design); trailing `SizedBox`; optional `11.2-WIDGET-007` (was optional).
