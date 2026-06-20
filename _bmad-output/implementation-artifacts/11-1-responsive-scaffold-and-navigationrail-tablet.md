# Story 11.1: Responsive Scaffold & NavigationRail (Tablet)

Status: done

## Story

As a tablet user,
I want a side navigation rail instead of a bottom bar,
so that the navigation pattern is appropriate for larger screens.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The app runs on a device with screen width ≥ 600dp | When the scaffold renders | A `NavigationRail` is displayed on the left side with the same 3 destinations (Sessions, Today, Progress) with icons + labels, always expanded (not icon-only), and a drawer toggle (FR38, ARCH15, UX-DR15) |
| AC2 | The screen width < 600dp | When the scaffold renders | A `BottomNavigationBar` is displayed — current phone layout unchanged (FR37, ARCH15) |
| AC3 | The breakpoint is implemented via `LayoutBuilder` | When the device is rotated and the width crosses 600dp in either direction | Navigation switches between rail and bottom bar without data loss or rebuild — the selected tab index is preserved (ARCH15) |
| AC4 | The `NavigationRail` is displayed on tablet | On visual inspection | Rail width is ~80dp (M3 standard); icons and labels are both visible; the drawer toggle is accessible via `leading` or `header` slot |
| AC5 | The existing `AppShell` tests run after this change | On default 800dp test surface | Tests that previously found `BottomNavigationBar` are updated to either: (a) explicitly constrain surface to <600dp to test phone layout, or (b) assert `NavigationRail` at the default 800dp surface — all existing assertions remain valid under the appropriate surface width |

## Tasks / Subtasks

---

### Task 1: Add `LayoutBuilder`-based responsive logic to `AppShell` (AC1, AC2, AC3, AC4)

- [x] READ `pulse_coach/lib/shared/widgets/app_shell.dart` fully before editing.

- [x] UPDATE `pulse_coach/lib/shared/widgets/app_shell.dart`

  Replace the flat `Scaffold` with a `LayoutBuilder` wrapper that switches between phone and tablet layouts at 600dp:

  ```dart
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _TabletScaffold(
            currentIndex: currentIndex,
            onTabSelected: (i) => context.go(_tabs[i]),
            child: child,
          );
        }
        return _PhoneScaffold(
          currentIndex: currentIndex,
          onTabSelected: (i) => context.go(_tabs[i]),
          child: child,
        );
      },
    );
  }
  ```

  Extract `_PhoneScaffold` as a private `StatelessWidget` that wraps the current `Scaffold` with `BottomNavigationBar`. Move all drawer + AppBar logic into a shared helper or duplicate into both scaffold variants — the drawer content is identical between phone and tablet.

  For `_TabletScaffold`, the layout is a `Scaffold` with `body: Row(children: [NavigationRail(...), Expanded(child: child)])`. The `AppBar` + `Drawer` remain present on the tablet scaffold (the drawer toggle sits in the NavigationRail's `leading` slot as an `IconButton(icon: Icon(Icons.menu), onPressed: Scaffold.of(context).openDrawer)`).

  **NavigationRail destination order** matches `_tabs` = [sessions (index 0), today (index 1), progress (index 2)] — same as the existing `BottomNavigationBar`.

  **Key constraint:** Do NOT use `NavigationBar` (M3) as the replacement for `BottomNavigationBar` — the current code uses `BottomNavigationBar` (M2 variant) and the existing tests assert against it. Switch only the tablet path; leave the phone path using `BottomNavigationBar` unchanged to avoid breaking existing phone tests.

---

### Task 2: Update `app_shell_test.dart` for the new responsive behaviour (AC5)

- [x] READ `pulse_coach/test/widget/app_shell_test.dart` fully before editing.

- [x] UPDATE `pulse_coach/test/widget/app_shell_test.dart`

  **Critical:** the default `flutter_test` surface is **800×600dp** (logical pixels). After adding `LayoutBuilder` with a 600dp breakpoint, **all existing tests that assert `BottomNavigationBar` will FAIL** because the 800dp-wide surface triggers the tablet path and shows `NavigationRail` instead.

  Fix strategy — constrain phone tests to a sub-600dp surface using `tester.binding.setSurfaceSize`:

  ```dart
  // Add this helper at the bottom of the test file:
  Future<void> setPhoneSurface(WidgetTester tester) =>
      tester.binding.setSurfaceSize(const Size(390, 844));

  Future<void> setTabletSurface(WidgetTester tester) =>
      tester.binding.setSurfaceSize(const Size(800, 1024));
  ```

  For every existing `testWidgets` that asserts `BottomNavigationBar`:
  - Add `await setPhoneSurface(tester);` before `pumpWidget`
  - Add `addTearDown(() => tester.binding.resetSurfaceSize());` inside the test

  Then add **3 new tablet tests** (tag `11.1-WIDGET-001`, `11.1-WIDGET-002`, `11.1-WIDGET-003`):

  ```dart
  testWidgets('11.1-WIDGET-001: tablet width shows NavigationRail with 3 destinations', (tester) async {
    await setTabletSurface(tester);
    addTearDown(() => tester.binding.resetSurfaceSize());
    await tester.pumpWidget(buildTestShell());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Sessioni'), findsOneWidget);
    expect(find.text('Progressi'), findsOneWidget);
  });

  testWidgets('11.1-WIDGET-002: phone width shows BottomNavigationBar, no NavigationRail', (tester) async {
    await setPhoneSurface(tester);
    addTearDown(() => tester.binding.resetSurfaceSize());
    await tester.pumpWidget(buildTestShell());
    await tester.pumpAndSettle();
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('11.1-WIDGET-003: selected tab index is preserved when surface resizes across 600dp', (tester) async {
    await setPhoneSurface(tester);
    addTearDown(() => tester.binding.resetSurfaceSize());
    await tester.pumpWidget(buildTestShell(initialLocation: '/progress'));
    await tester.pumpAndSettle();
    // Verify correct index on phone
    final bnb = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(bnb.currentIndex, 2);
    // Switch to tablet surface
    await tester.binding.setSurfaceSize(const Size(800, 1024));
    await tester.pump();
    // NavigationRail should now be visible with progress destination highlighted
    expect(find.byType(NavigationRail), findsOneWidget);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 2);
  });
  ```

---

### Task 3: Run tests and verify zero regressions (AC2, AC5)

- [x] Run `flutter test pulse_coach/test/widget/app_shell_test.dart` from `pulse_coach/` — all tests must pass.
- [x] Run `flutter test` from `pulse_coach/` — full suite (currently 685 tests) must pass with the new tests added (target: ≥ 688 total).
- [x] Run `flutter analyze` from `pulse_coach/` — zero issues.

---

## Dev Notes

### What `AppShell` does today (full read required before editing)

`pulse_coach/lib/shared/widgets/app_shell.dart` (107 lines) is a single `StatelessWidget` wired as the `ShellRoute` builder in `go_router`. It renders:
- `Scaffold` with `AppBar` (DrawerButton + title "PulseCoach")
- `Drawer` with Profile / Settings / Privacy / (debug) entries
- `body: child` (the current route page)
- `bottomNavigationBar: BottomNavigationBar` with 3 items: Sessions (index 0), Today (index 1), Progress (index 2)
- Navigation state is derived from `GoRouterState.of(context).matchedLocation` via `_currentIndex(String location)` — a pure function, not stored in widget state
- The `_tabs` list and `_currentIndex` method are both static-scope on the widget

This is a **purely presentation-layer** widget. No BLoC/Cubit dependency. No `getIt` usage. No async operations.

### Architecture directive: `app_shell.dart` vs `responsive_scaffold.dart`

The architecture document (`architecture.md` line 816) plans `lib/shared/widgets/responsive_scaffold.dart` as the canonical responsive scaffold file. However, the actual implementation was created as `app_shell.dart` in Epic 1. **Do not rename or move the file** — that would break the ShellRoute builder reference in `app_router.dart` and all test imports. Implement the 600dp LayoutBuilder logic in-place in `app_shell.dart`. If a future refactor renames it, that is a separate story.

### Tablet scaffold layout pattern (ARCH15, UX-DR15)

From UX spec (`ux-design-specification.md` lines 1562–1566):
- `NavigationRail` on the left edge
- Icons + labels, always expanded (not collapsed to icon-only mode)
- Today as default selected destination (same as phone: `_tabs[1]`)
- Rail width: 80dp (M3 standard)
- Drawer toggle accessible on the tablet scaffold

From architecture spec (`architecture.md` line 257):
- `LayoutBuilder` at scaffold level — the layout decision is made once at the top, not inside child components
- Shared components (`child`), different arrangement — the page widget tree (`child`) is the same on both layouts

The tablet `Scaffold` body pattern:
```dart
body: Row(
  children: [
    NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTabSelected,
      labelType: NavigationRailLabelType.all,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: Scaffold.of(context).openDrawer,
        ),
      ),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.fitness_center), label: Text('Sessioni')),
        NavigationRailDestination(icon: Icon(Icons.today), label: Text('Oggi')),
        NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Progressi')),
      ],
    ),
    const VerticalDivider(thickness: 1, width: 1),
    Expanded(child: child),
  ],
),
```

Use `l10n` labels (already imported in `app_shell.dart`): `l10n.navTabSessions`, `l10n.navTabToday`, `l10n.navTabProgress` — same keys used in `BottomNavigationBar`.

### Drawer toggle on tablet

When using `NavigationRail`, the `Scaffold.of(context).openDrawer()` call inside the rail's `leading` builder requires a `Builder` widget to get the correct `Scaffold` context (the `NavigationRail` is inside the body of the `Scaffold`, not at the `Scaffold` level). The `DrawerButton` widget in the `AppBar.leading` handles this automatically on phone; for tablet you must do it manually via `Builder`.

### Test surface size: the critical regression trap

The flutter_test default surface is **800dp wide** (logical pixels). After adding the 600dp breakpoint:
- Tests without an explicit surface size constraint will run on an 800dp surface → they will see `NavigationRail`, not `BottomNavigationBar`
- All 5 existing `app_shell_test.dart` tests assert `BottomNavigationBar` → **they will all fail**
- Fix: wrap each existing phone-layout test with `setPhoneSurface(tester)` + `addTearDown(resetSurfaceSize)`

The `viewport_helper.dart` created in Story 10.2 (`test/helpers/viewport_helper.dart`) provides `set360dpSurface()` for 360dp-wide testing. For this story the helper pattern is the same — use `tester.binding.setSurfaceSize(const Size(390, 844))` inline or extract to a local helper. Do NOT import `viewport_helper.dart` from the progress tests into the app_shell_test unless it exports the exact size needed.

### Rotation / breakpoint crossing without data loss (AC3)

"No data loss" means the current tab selection is preserved across the breakpoint crossing. Since tab selection is derived from `GoRouterState.of(context).matchedLocation` (pure function, not stored in widget state), it is automatically preserved — the route location persists through the router, not the widget tree. No special state-management work is needed. The `LayoutBuilder` re-renders on constraint change, but `_currentIndex(location)` returns the same value.

### No changes to go_router, app_router.dart, or any page

This story touches ONLY `app_shell.dart` and `app_shell_test.dart`. The `ShellRoute` builder signature does not change. All page widgets (`TodayPage`, `SessionsPage`, `ProgressPage`) are completely unaffected.

### No Drift / build_runner changes

This story introduces no new data models, freezed classes, or injectable registrations. No `dart run build_runner build` is required.

### Flutter analyze must remain at 0 issues

Run `flutter analyze` from `pulse_coach/` before calling the story done. The `NavigationRail` widget does not require any lint suppressions under the current `analysis_options.yaml`.

### Project Structure Notes

- File to modify: `pulse_coach/lib/shared/widgets/app_shell.dart`
- Test file to update: `pulse_coach/test/widget/app_shell_test.dart`
- No new files required (architecture planned `responsive_scaffold.dart` and `adaptive_navigation.dart` as separate files, but implementing in-place in the existing `app_shell.dart` is simpler and avoids touching the go_router ShellRoute wiring)
- Tab order: Sessions (0), Today (1), Progress (2) — same on both phone and tablet

### References

- [Source: architecture.md line 257] Responsive strategy: `LayoutBuilder` at scaffold level, single 600dp breakpoint
- [Source: architecture.md line 816] Planned file: `lib/shared/widgets/responsive_scaffold.dart`
- [Source: ux-design-specification.md lines 1544, 1562–1566] Breakpoint at 600dp; `NavigationRail` specs (icons+labels, always expanded, 80dp width, drawer toggle)
- [Source: ux-design-specification.md lines 1781–1785] LayoutBuilder usage guidance; shared components, different arrangement
- [Source: project-context.md] Responsive layout: `LayoutBuilder`, single 600dp breakpoint, phone uses `BottomNavigationBar`, tablet uses `NavigationRail` + master-detail
- [Source: epics.md lines 1648–1667] Story 11.1 ACs: NavigationRail on tablet ≥600dp, BottomNavigationBar on phone <600dp, no data loss on rotation
- [Source: prd.md lines 596–598] FR37 (phone bottom nav), FR38 (tablet NavigationRail + master-detail), FR39 (orientation support — deferred to Story 11.3)

### Epic 11 Kickoff: Category B Sunset Review (Due)

Per `action-item-ledger.md` line 244, the **Category B sunset review** was scheduled for Epic 11 kickoff (deferred per E8-K2 2-epic cadence). Items to review: `E6-P1`, `E7-P2`, `E7.5-P1`, `E7.5-P2`, `E9-K1`, `E9R-4`/`E10R-3`. **This story file is not the place to execute that review** — the PM (John) should run the sunset review via `bmad-correct-course` or directly in the action-item-ledger before or at the start of story development, not inside the story implementation.

Category A open items (for awareness): `E6-T7` (ExerciseDB mapping), `E6-T8` (memoize fallback JSON decode). Neither blocks this story.

## Review Findings

_Code review 2026-05-28 (bmad-code-review, 3 adversarial layers). Verified locally: `flutter analyze` clean on `app_shell.dart`; `app_shell_test.dart` 9/9 pass incl. 11.1-WIDGET-001/002/003. All 5 ACs PASS per Acceptance Auditor._

- [x] [Review][Patch] Dual drawer triggers on tablet — RESOLVED: dropped the `NavigationRail` `leading` menu `IconButton`; the `AppBar` `DrawerButton` is now the single drawer toggle on tablet (AC4 still satisfied via the AppBar). (blind+edge)
- [x] [Review][Patch] NavigationRail selected-color divergence — RESOLVED: rail now sets `selectedIconTheme`/`selectedLabelTextStyle` to `theme.primaryColor` and `unselected*` to `theme.onSurfaceVariant`, matching the phone `BottomNavigationBar` branding across the 600dp breakpoint. (blind)
- [x] [Review][Defer] Breakpoint uses `constraints.maxWidth` (not `shortestSide`) — a large phone in landscape (>=600dp wide) flips to the tablet rail [app_shell.dart:30] — by design per spec AC1/example; orientation handling (FR39) is scoped to Story 11.3. (blind+edge)
- [x] [Review][Defer] NavigationRail label overflow unverified in the 600–700dp band — `labelType.all` + long IT labels ("Sessioni"/"Progressi") at `minWidth: 80`; tests only cover 800dp [app_shell_test.dart `setTabletSurface`]. Confirm via the mandatory on-device protocol at a ~600–700dp width before sign-off. (blind+edge)

Dismissed as noise (6): eager `Scaffold.of(context).openDrawer` tear-off (rebinds each build, correct under the `Builder`); `Scaffold.of` lookup (Builder is correctly nested under the tablet Scaffold); `_currentIndex` on non-tab routes (Profile/Settings/Privacy are outside the ShellRoute; `< 0 → 0` fallback anyway); missing `SafeArea` on tablet `Row` (AppBar already absorbs the top inset); `setSurfaceSize(null)` vs spec's `resetSurfaceSize()` (documented functional equivalent — binding lacks `resetSurfaceSize`); theme-fetched-but-unused (folded into the color-divergence decision).

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-05-28: Read project context, sprint status, story file, `app_shell.dart`, and `app_shell_test.dart`.
- 2026-05-28: Red phase confirmed with new tablet tests failing because `NavigationRail` was not rendered yet.
- 2026-05-28: `flutter test test/widget/app_shell_test.dart` passed: 9/9 tests.
- 2026-05-28: `flutter test` passed: 742/742 tests.
- 2026-05-28: `flutter analyze` passed: No issues found.

### Completion Notes List

- Implemented `LayoutBuilder` breakpoint logic in `AppShell` at 600dp.
- Preserved phone navigation with the existing `BottomNavigationBar` and extracted it into `_PhoneScaffold`.
- Added tablet layout with `NavigationRail`, 3 localized destinations, 80dp minimum width, visible labels, shared drawer, and rail menu button opening the drawer.
- Added responsive widget coverage for tablet rail rendering, phone bottom navigation rendering, and selected index preservation across a phone-to-tablet resize.
- Used `tester.binding.setSurfaceSize(null)` for cleanup because this Flutter binding does not expose `resetSurfaceSize()`.

### File List

- pulse_coach/lib/shared/widgets/app_shell.dart
- pulse_coach/test/widget/app_shell_test.dart
- _bmad-output/implementation-artifacts/11-1-responsive-scaffold-and-navigationrail-tablet.md
- _bmad-output/implementation-artifacts/sprint-status.yaml

### Change Log

- 2026-05-28: Implemented responsive AppShell tablet NavigationRail support and updated widget tests.
