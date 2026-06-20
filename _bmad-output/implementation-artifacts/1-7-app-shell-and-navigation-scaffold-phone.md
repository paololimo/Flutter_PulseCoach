# Story 1.7: App Shell & Navigation Scaffold (Phone)

Status: done

## Story

As a developer,
I want the top-level app shell configured with `go_router` and the phone bottom navigation scaffold,
so that all features can be navigated to and the routing is established for subsequent epics.

## Acceptance Criteria

1. **Given** `MaterialApp.router` is configured in `app.dart`
   **When** the app launches
   **Then** routing is handled by `go_router` with defined routes for: `/onboarding`, `/today`, `/sessions`, `/progress`, `/session/active`, `/session/rpe`, `/session/summary`, `/settings`, `/profile`, `/privacy`

2. **Given** onboarding is complete (UserProfile row exists in DB)
   **When** the app launches
   **Then** the router redirects to `/today` (skipping `/onboarding`)

3. **Given** onboarding is not complete (no UserProfile row in DB)
   **When** the app launches
   **Then** the router redirects to `/onboarding`

4. **Given** the app shell renders the Today screen
   **When** viewed on a phone (< 600dp width)
   **Then** a `BottomNavigationBar` is shown with 3 tabs: **Today** (index 0), **Sessions** (index 1), **Progress** (index 2) — Material icons used as MVP standin for Lucide (see Dev Notes)

5. **Given** the app shell renders
   **When** the leading icon in the AppBar is tapped
   **Then** a navigation drawer opens with items: Profile, Settings, Privacy (and "Debug" in `kDebugMode` only)

6. **Given** the app shell's bottom nav shows 3 tabs
   **When** a tab is selected
   **Then** `context.go(path)` navigates to the corresponding route and the selected tab indicator updates

## Tasks / Subtasks

- [x] Task 1: Create stub placeholder pages for all routes (AC: #1)
  - [x] CREATE `lib/features/onboarding/presentation/pages/onboarding_page.dart` — stub `Scaffold` with `AppBar(title: Text('Onboarding'))` and centered `Text('Onboarding — Story 2.x')`
  - [x] CREATE `lib/features/today/presentation/pages/today_page.dart` — stub with `Text('Today — Story 7.x')`
  - [x] CREATE `lib/features/sessions_catalog/presentation/pages/sessions_page.dart` — stub with `Text('Sessions — Story 6.x')`
  - [x] CREATE `lib/features/progress/presentation/pages/progress_page.dart` — stub with `Text('Progress — Story 10.x')`
  - [x] CREATE `lib/features/session/presentation/pages/in_session_page.dart` — stub with `Text('In Session — Story 8.x')`
  - [x] CREATE `lib/features/session/presentation/pages/rpe_page.dart` — stub with `Text('RPE — Story 9.x')`
  - [x] CREATE `lib/features/session/presentation/pages/session_summary_page.dart` — stub with `Text('Summary — Story 9.x')`
  - [x] CREATE `lib/features/settings/presentation/pages/settings_page.dart` — stub with `Text('Settings — Story 14.x')`
  - [x] CREATE `lib/features/onboarding/presentation/pages/profile_page.dart` — stub with `Text('Profile — Story 2.x')`
  - [x] CREATE `lib/features/settings/presentation/pages/privacy_page.dart` — stub with `Text('Privacy — Story 14.x')`

- [x] Task 2: CREATE `lib/shared/widgets/app_shell.dart` — phone scaffold with BottomNav + Drawer (AC: #4, #5, #6)
  - [x] `AppShell extends StatelessWidget` accepts `Widget child` parameter
  - [x] `Scaffold` with `body: child` (go_router ShellRoute passes built child)
  - [x] `AppBar` with `leading: DrawerButton()`, `title: Text('PulseCoach')` (title updated per-tab — see Dev Notes)
  - [x] `BottomNavigationBar` with 3 items: Today (`Icons.today`), Sessions (`Icons.fitness_center`), Progress (`Icons.bar_chart`) — inactive: `onSurfaceVariant`, selected: `primaryColor`
  - [x] Tab switching: `context.go('/today')`, `context.go('/sessions')`, `context.go('/progress')` — use `GoRouterState.of(context).matchedLocation` to compute `currentIndex`
  - [x] `Drawer` with `ListView` containing: `DrawerHeader`, `ListTile` for Profile (`Icons.person`), Settings (`Icons.settings`), Privacy (`Icons.privacy_tip`), and `if (kDebugMode)` → Debug `ListTile`
  - [x] Drawer navigation: `context.go('/profile')`, `context.go('/settings')`, `context.go('/privacy')` — call `Navigator.pop(context)` to close drawer first

- [x] Task 3: IMPLEMENT `lib/core/routing/app_router.dart` (AC: #1, #2, #3)
  - [x] Replace stub (2-line comment) with full `GoRouter` configuration
  - [x] `static final GoRouter router = GoRouter(...)` as top-level singleton
  - [x] `initialLocation: '/'` with top-level redirect to determine start destination
  - [x] `redirect` callback: call `getIt<AppDatabase>().userProfileDao.getProfile()` — null → `/onboarding`; not null AND location is `/onboarding` → `/today`; else return null
  - [x] Root route `/` → redirect only (no page), handled by global redirect
  - [x] `ShellRoute` for shell-wrapped tabs: routes `/today`, `/sessions`, `/progress` — `builder` returns `AppShell(child: child)`
  - [x] Top-level `GoRoute` entries (no shell): `/onboarding`, `/session/active`, `/session/rpe`, `/session/summary`, `/settings`, `/profile`, `/privacy`
  - [x] Named routes: static `const` strings for each path (see Dev Notes code example)

- [x] Task 4: MODIFY `lib/app.dart` — switch to `MaterialApp.router` (AC: #1)
  - [x] Replace `MaterialApp(home: ...)` with `MaterialApp.router(routerConfig: AppRouter.router)`
  - [x] Keep `BlocProvider<ThemeCubit>` + `BlocBuilder<ThemeCubit, ThemeMode>` wrapper from Story 1.6
  - [x] Pass `theme:`, `darkTheme:`, `themeMode:` as before — no changes to theme wiring

- [x] Task 5: Write tests (AC: #4, #5, #6)
  - [x] CREATE `test/widget/app_shell_test.dart`
    - [x] Test: phone layout shows `BottomNavigationBar` with 3 items
    - [x] Test: tapping Sessions tab calls `context.go('/sessions')`
    - [x] Test: drawer shows Profile, Settings, Privacy list tiles
    - [x] Test: Debug drawer item hidden when `kDebugMode` is false (if testable)
  - [x] Run `flutter test` — all prior 38 tests still pass + new tests pass (42 total)
  - [x] Run `flutter analyze` → 0 issues

- [x] Task 6: Update `test/widget/app_test.dart` if needed
  - [x] Story 1.6 already updated `app_test.dart` for DI-aware PulseCoachApp
  - [x] `PulseCoachApp` now uses `MaterialApp.router` — updated test to register in-memory `AppDatabase` via `AppDatabase.forTesting(NativeDatabase.memory())`

## Dev Notes

### Critical: File Actions Summary

| File | Action |
|---|---|
| `pulse_coach/lib/core/routing/app_router.dart` | IMPLEMENT — replace 2-line stub comment |
| `pulse_coach/lib/app.dart` | MODIFY — switch to `MaterialApp.router` |
| `pulse_coach/lib/shared/widgets/app_shell.dart` | CREATE — new directory + file |
| `pulse_coach/lib/features/onboarding/presentation/pages/onboarding_page.dart` | CREATE — stub page |
| `pulse_coach/lib/features/onboarding/presentation/pages/profile_page.dart` | CREATE — stub page |
| `pulse_coach/lib/features/today/presentation/pages/today_page.dart` | CREATE — stub page |
| `pulse_coach/lib/features/sessions_catalog/presentation/pages/sessions_page.dart` | CREATE — stub page |
| `pulse_coach/lib/features/progress/presentation/pages/progress_page.dart` | CREATE — stub page |
| `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart` | CREATE — stub page |
| `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart` | CREATE — stub page |
| `pulse_coach/lib/features/session/presentation/pages/session_summary_page.dart` | CREATE — stub page |
| `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart` | CREATE — stub page |
| `pulse_coach/lib/features/settings/presentation/pages/privacy_page.dart` | CREATE — stub page |
| `pulse_coach/test/widget/app_shell_test.dart` | CREATE |
| `pulse_coach/test/widget/app_test.dart` | MODIFY if router breaks smoke test |

**Do NOT touch:** `main.dart`, `injection.dart`, `injection.config.dart`, database files, error files, theme files, `theme_cubit.dart`.

**build_runner NOT required** — no new `@injectable` classes, no new drift tables, no `freezed` models.

### Critical: go_router 15.1.2 API

**Package installed:** `go_router: ^15.1.2`

```dart
// lib/core/routing/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/rpe_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/session_summary_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/settings_page.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/profile_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/privacy_page.dart';
import 'package:pulse_coach/shared/widgets/app_shell.dart';

class AppRouter {
  // Route path constants — kebab-case paths, camelCase names
  static const String onboarding     = '/onboarding';
  static const String today          = '/today';
  static const String sessions       = '/sessions';
  static const String progress       = '/progress';
  static const String sessionActive  = '/session/active';
  static const String sessionRpe     = '/session/rpe';
  static const String sessionSummary = '/session/summary';
  static const String settings       = '/settings';
  static const String profile        = '/profile';
  static const String privacy        = '/privacy';

  static final GoRouter router = GoRouter(
    initialLocation: today,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: today,
            builder: (context, state) => const TodayPage(),
          ),
          GoRoute(
            path: sessions,
            builder: (context, state) => const SessionsPage(),
          ),
          GoRoute(
            path: progress,
            builder: (context, state) => const ProgressPage(),
          ),
        ],
      ),
      GoRoute(
        path: sessionActive,
        builder: (context, state) => const InSessionPage(),
      ),
      GoRoute(
        path: sessionRpe,
        builder: (context, state) => const RpePage(),
      ),
      GoRoute(
        path: sessionSummary,
        builder: (context, state) => const SessionSummaryPage(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: privacy,
        builder: (context, state) => const PrivacyPage(),
      ),
    ],
  );

  static Future<String?> _redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final userProfile =
        await getIt<AppDatabase>().userProfileDao.getProfile();
    final onboardingComplete = userProfile != null;
    final goingToOnboarding = state.matchedLocation == onboarding;

    if (!onboardingComplete && !goingToOnboarding) return onboarding;
    if (onboardingComplete && goingToOnboarding) return today;
    return null; // no redirect
  }
}
```

**Key go_router 15.x notes:**
- `MaterialApp.router(routerConfig: AppRouter.router)` — do NOT use `routerDelegate`/`routeInformationParser` (old API)
- `ShellRoute.builder` provides `child` — the matched sub-route's widget tree
- `context.go(path)` for tab switching (replaces current stack entry in shell)
- `context.push(path)` for drawer nav that should be back-navigable
- `context.pop()` for back navigation
- `GoRouterState.of(context).matchedLocation` for current location — use in `AppShell` to compute selected tab index

### Critical: app.dart Modification

```dart
// lib/app.dart — MODIFY existing file
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';

class PulseCoachApp extends StatelessWidget {
  const PulseCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'PulseCoach',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
```

**Change from Story 1.6:** Replace `MaterialApp(home: Scaffold(...))` with `MaterialApp.router(routerConfig: AppRouter.router)`. All other wiring stays identical.

### Critical: AppShell Widget

```dart
// lib/shared/widgets/app_shell.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    AppRouter.today,
    AppRouter.sessions,
    AppRouter.progress,
  ];

  int _currentIndex(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;

    return Scaffold(
      appBar: AppBar(
        leading: const DrawerButton(),
        title: const Text('PulseCoach'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.surfaceContainer),
              child: const Text('PulseCoach'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRouter.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRouter.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRouter.privacy);
              },
            ),
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Debug'),
                onTap: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(location),
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.onSurfaceVariant,
        onTap: (index) => context.go(_tabs[index]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
        ],
      ),
    );
  }
}
```

**Icon note:** `Icons.today`, `Icons.fitness_center`, `Icons.bar_chart` are Material icon standin. Lucide icons (`lucide_icons_flutter` or similar) are NOT in `pubspec.yaml`. Do NOT add a new package in this story — Material icons are functionally correct. Lucide can be swapped in when the UX polish story is tackled.

### Critical: Stub Page Pattern

All 10 stub pages follow this exact template — no extra logic:

```dart
// Example: lib/features/today/presentation/pages/today_page.dart
import 'package:flutter/material.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Today — Story 7.x'));
  }
}
```

**Do NOT add Scaffold to stub pages** — the shell provides the scaffold for Today/Sessions/Progress. For pages outside the shell (InSessionPage, SettingsPage, etc.), DO add their own Scaffold:

```dart
// Example: lib/features/settings/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings — Story 14.x')),
    );
  }
}
```

**Shell pages** (no own Scaffold): `TodayPage`, `SessionsPage`, `ProgressPage`
**Non-shell pages** (own Scaffold + AppBar): `OnboardingPage`, `InSessionPage`, `RpePage`, `SessionSummaryPage`, `SettingsPage`, `ProfilePage`, `PrivacyPage`

### Critical: Redirect Async Caveat

The `_redirect` in AppRouter calls `userProfileDao.getProfile()` which is `async`. go_router 15.x supports `Future<String?> redirect`. This runs once at startup. No `refreshListenable` needed for this story — onboarding check happens at app launch only. Later stories (Epic 2) will refine this.

**Never** put the redirect in a `StreamBuilder` or call it manually — go_router handles invocation.

### Critical: GoRouterState in AppShell

`GoRouterState.of(context).matchedLocation` requires the `AppShell` to be inside go_router's `ShellRoute`. Because `AppShell` is the `builder` return of `ShellRoute`, `GoRouterState.of(context)` is available in `AppShell.build`. This correctly returns the currently matched sub-route path.

For tab index: `/today` → index 0, `/sessions` → index 1, `/progress` → index 2. The `_currentIndex` method uses `startsWith` to handle potential sub-routes (e.g., `/today/something`).

### Critical: Directory Creation

`lib/shared/widgets/` does **not exist** yet. Create it by creating the file — the directory is implicit:
- `lib/shared/widgets/app_shell.dart` ← this implicitly creates `lib/shared/`

Also, `lib/features/session/presentation/pages/` does not exist yet (no page stubs were created in previous stories). Same for `lib/features/sessions_catalog/`, `lib/features/progress/`, `lib/features/today/` pages directories.

### Critical: Import Style

All imports use package-style (enforced since Story 1.1):
```dart
// ✅ Always
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/shared/widgets/app_shell.dart';

// ❌ Never
import '../../core/routing/app_router.dart';
```

### Testing Requirements

```dart
// test/widget/app_shell_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/shared/widgets/app_shell.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';

// Helper: build AppShell with a test router
Widget buildTestShell({String initialLocation = '/today'}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/today', builder: (_, __) => const TodayPage()),
          GoRoute(path: '/sessions', builder: (_, __) => const SessionsPage()),
          GoRoute(path: '/progress', builder: (_, __) => const ProgressPage()),
        ],
      ),
    ],
  );
  return MaterialApp.router(
    theme: AppTheme.darkTheme,
    routerConfig: router,
  );
}

void main() {
  group('AppShell', () {
    testWidgets('shows BottomNavigationBar with 3 items', (tester) async {
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
    });

    testWidgets('shows Drawer with Profile, Settings, Privacy', (tester) async {
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DrawerButton));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
    });

    testWidgets('Today tab is selected at initial location /today', (tester) async {
      await tester.pumpWidget(buildTestShell(initialLocation: '/today'));
      await tester.pumpAndSettle();
      final bnb = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bnb.currentIndex, 0);
    });
  });
}
```

**app_test.dart update strategy:** The existing smoke test pumps `PulseCoachApp`. Since `PulseCoachApp` now uses `MaterialApp.router`, the test must allow the router's redirect to resolve. Use `tester.pumpAndSettle()` instead of `tester.pump()`. The redirect calls `userProfileDao.getProfile()` — if the test uses a real in-memory AppDatabase (as set up in Story 1.3/1.4 test helpers), this will work. If not, the simplest fix is to override `AppRouter.router` in tests or use a test-specific `GoRouter` stub. Check `test/widget/app_test.dart` first before modifying.

**Pre-existing tests to stay green:** 38 tests (28 pre-1.6 + 10 from Story 1.6).

### Architecture Compliance

| Rule | Requirement | Implementation |
|---|---|---|
| ARCH-Routing | `go_router` declarative routes | `AppRouter.router` with `GoRouter` |
| ARCH-Shell | `ShellRoute` for bottom nav | `/today`, `/sessions`, `/progress` wrapped |
| ARCH-Responsive | `LayoutBuilder` at scaffold level, 600dp breakpoint | Phone only in this story; tablet (`NavigationRail`) deferred to Epic 11 |
| ARCH-Structure | `lib/shared/widgets/` for cross-feature widgets | `app_shell.dart` in shared |
| ARCH-Structure | `lib/core/routing/app_router.dart` | Router config lives in core |
| ARCH-Anti | No Flutter imports in domain/AI | N/A — this story is pure presentation |
| ARCH-Anti | No manual `getIt.register` | N/A — no new DI registrations |

### Previous Story Intelligence (Story 1.6)

- `flutter analyze` → 0 issues after Story 1.6. Must remain 0.
- `ThemeCubit` is `@lazySingleton` (changed in Review from `@injectable`). Not relevant here but note the precedent.
- `app.dart` currently has `MaterialApp(home: Scaffold(body: Center(child: Text('PulseCoach'))))`. This is FULLY replaced by `MaterialApp.router(...)`.
- `lib/features/settings/presentation/bloc/theme_cubit.dart` exists. `lib/features/settings/presentation/pages/` does NOT exist yet — create it.
- `test/widget/app_test.dart` was already updated in Story 1.6 to handle `getIt<ThemeCubit>()`. The router introduces another DI call (`getIt<AppDatabase>()`). The app_test may need the AppDatabase registered too.
- `build_runner` NOT needed. Verify with: no `@injectable` on AppRouter, no new drift tables, no freezed models.
- Test count after Story 1.6: **38 tests**. Target after 1.7: ~43–46 tests.

### Git Intelligence (from recent commits)

- Stories 1.1–1.6 pattern: infrastructure-only, no feature logic. Story 1.7 follows same pattern — navigation shell only, all page content is stub.
- Story 1.6 introduced `app.dart` `MaterialApp` wiring pattern. Story 1.7 builds directly on top of it.
- `lib/core/routing/app_router.dart` stub was created in Story 1.1 with comment `// GoRouter configuration — implemented in Story 1.7`. This confirms the file is ready to be implemented.
- No WearOS, no sensor code — defer as always to later epics.

### Known Gap: Lucide Icons

UX spec (UX-DR4) requires Lucide icons (24dp, 1.5px stroke). The `pubspec.yaml` does NOT include a Lucide package (`lucide_icons_flutter`, `lucide_flutter`, or similar). **Do NOT add a new package in this story.** Use Material icons (`Icons.today`, `Icons.fitness_center`, `Icons.bar_chart`) as functionally equivalent standins. A future UX polish story can swap in Lucide once the package is evaluated and added to pubspec.

### References

- [Source: epics.md#Story 1.7] — User story, acceptance criteria (FR37, UX-DR4)
- [Source: architecture.md#Routing Decision] — `go_router` with shell routes, overlay routes for InSessionView
- [Source: architecture.md#Responsive Strategy] — `LayoutBuilder`, 600dp breakpoint, phone `BottomNavigationBar`
- [Source: architecture.md#Complete Project Directory Structure] — `lib/core/routing/app_router.dart`, `lib/shared/widgets/responsive_scaffold.dart`
- [Source: architecture.md#Frontend Architecture] — Shell routes for bottom nav, overlay routes for InSessionView
- [Source: ux-design-specification.md#Navigation Patterns] — 3-tab bottom nav, drawer with Profile/Settings/Privacy
- [Source: story 1-6] — app.dart wiring pattern, test count 38, import enforcement, build_runner not needed

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

- Implemented full go_router 15.x configuration in `app_router.dart` with ShellRoute for bottom-nav tabs and async redirect for onboarding check.
- Created `AppShell` widget in `lib/shared/widgets/` (new directory) with BottomNavigationBar (3 tabs), Drawer (Profile/Settings/Privacy + Debug in kDebugMode), and GoRouterState-based tab index computation.
- Created 10 stub pages: shell pages (TodayPage, SessionsPage, ProgressPage) without own Scaffold; non-shell pages (OnboardingPage, InSessionPage, RpePage, SessionSummaryPage, SettingsPage, ProfilePage, PrivacyPage) with own Scaffold + AppBar.
- Updated `app.dart` to use `MaterialApp.router(routerConfig: AppRouter.router)`, keeping all BLoC/theme wiring from Story 1.6.
- Updated `app_test.dart` to register in-memory `AppDatabase` (`AppDatabase.forTesting(NativeDatabase.memory())`) since router redirect calls `getIt<AppDatabase>()` at launch.
- Created `app_shell_test.dart` with 4 widget tests covering BottomNavigationBar, Drawer items, tab index, and tab navigation.
- All 42 tests pass (38 pre-existing + 4 new). `flutter analyze` → 0 issues.

### File List

- pulse_coach/lib/core/routing/app_router.dart (modified — full GoRouter implementation)
- pulse_coach/lib/app.dart (modified — MaterialApp.router)
- pulse_coach/lib/shared/widgets/app_shell.dart (created)
- pulse_coach/lib/features/today/presentation/pages/today_page.dart (created)
- pulse_coach/lib/features/sessions_catalog/presentation/pages/sessions_page.dart (created)
- pulse_coach/lib/features/progress/presentation/pages/progress_page.dart (created)
- pulse_coach/lib/features/onboarding/presentation/pages/onboarding_page.dart (created)
- pulse_coach/lib/features/onboarding/presentation/pages/profile_page.dart (created)
- pulse_coach/lib/features/session/presentation/pages/in_session_page.dart (created)
- pulse_coach/lib/features/session/presentation/pages/rpe_page.dart (created)
- pulse_coach/lib/features/session/presentation/pages/session_summary_page.dart (created)
- pulse_coach/lib/features/settings/presentation/pages/settings_page.dart (created)
- pulse_coach/lib/features/settings/presentation/pages/privacy_page.dart (created)
- pulse_coach/test/widget/app_shell_test.dart (created)
- pulse_coach/test/widget/app_test.dart (modified — added AppDatabase.forTesting registration)

### Review Findings

- [x] [Review][Patch] **initialLocation deviation: `/today` vs spec's `/`** — FIXED — Spec (Task 3) says `initialLocation: '/'` with a root route `/` that redirects only (no page). Implementation uses `initialLocation: today` (`/today`) with no root route `/`. Both achieve correct redirect behavior, but the spec's approach avoids a potential flash of the Today page before async redirect resolves to `/onboarding` on first launch. [app_router.dart:32]
- [x] [Review][Defer] **Async redirect fires on every navigation** — GoRouter's global `redirect` runs on every `context.go()`, querying the DB each time via `getProfile()`. Spec dev notes say "runs once at startup" which is inaccurate about go_router behavior. Negligible perf impact with in-memory SQLite now, but architecturally not ideal. Consider caching or `refreshListenable` in a future story. [app_router.dart:82-94] — deferred, architectural concern beyond story scope
- [x] [Review][Defer] **No test coverage for onboarding redirect logic (AC 2/3)** — AC 2 and AC 3 describe redirect-to-onboarding / redirect-to-today behavior, but Task 5 test requirements don't include redirect tests. Smoke test in `app_test.dart` only verifies MaterialApp renders. Adding redirect tests would strengthen coverage. — deferred, not required by story task breakdown
- [x] [Review][Defer] **Test teardown race with async redirect** — Theoretical race: if `pumpAndSettle` returns before the async redirect's `getProfile()` resolves, `tearDown` closes the DB while the query is in-flight. Safe in practice with `NativeDatabase.memory()` (synchronous), but fragile pattern. Consider awaiting router disposal before DB close. [app_test.dart:17-19] — deferred, safe with current in-memory DB

## Change Log

- 2026-03-28: Story 1.7 created — app shell and navigation scaffold (phone).
- 2026-03-28: Story 1.7 implemented — go_router configured, AppShell created, 10 stub pages created, app.dart updated to MaterialApp.router. 42 tests pass, 0 analyze issues.
