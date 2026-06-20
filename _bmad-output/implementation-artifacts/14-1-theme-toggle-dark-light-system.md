# Story 14.1: Theme Toggle (Dark / Light / System)

Status: done

## Story

As a user,
I want to choose between dark mode, light mode, or follow my system setting,
so that the app looks right for my environment and preferences.

## Acceptance Criteria

**AC1 — 3 theme options visible in Settings (FR48):**
Given the user navigates to Settings
When the theme option is visible
Then 3 options are available: Dark, Light, System — rendered as a `SegmentedButton<ThemeMode>` in the Settings page

**AC2 — System follows device setting (UX-DR20):**
Given the user selects "System"
When `ThemeMode.system` is applied
Then the app theme follows the device's current dark/light setting

**AC3 — Dark palette (#0F1119 surface) applied:**
Given the user selects "Dark"
When the theme applies
Then the full dark palette (`#0F1119` surface) is active — this is the default on first launch

**AC4 — Light theme via `ColorScheme.fromSeed()` (UX-DR20):**
Given the user selects "Light"
When the theme applies
Then a light theme generated via `ColorScheme.fromSeed()` from the aqua green seed is applied

**AC5 — Persisted selection survives app restart:**
Given the theme is changed
When the app is closed and relaunched
Then the same theme mode is applied without re-selection — persisted via `SharedPreferences` and loaded on `ThemeCubit` init

## Tasks / Subtasks

- [x] Task 1: Add `shared_preferences` dependency and create DI module (AC5)
  - [x] 1.1 Add `shared_preferences: ^2.3.0` to `pubspec.yaml` under `dependencies`
  - [x] 1.2 Create `pulse_coach/lib/core/di/settings_module.dart` with `@module` providing `@preResolve @singleton Future<SharedPreferences>`
  - [x] 1.3 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart`

- [x] Task 2: Update `ThemeCubit` to support 3 modes + persistence (AC1–AC5)
  - [x] 2.1 Inject `SharedPreferences` via constructor
  - [x] 2.2 Replace `toggleTheme()` with `setTheme(ThemeMode mode)` that emits and persists
  - [x] 2.3 Load persisted value synchronously in constructor via a static helper `_loadSavedTheme(SharedPreferences)`

- [x] Task 3: Implement `SettingsPage` with theme selector (AC1)
  - [x] 3.1 Replace stub with a `BlocBuilder<ThemeCubit, ThemeMode>` wrapping a `Scaffold`
  - [x] 3.2 Add `SegmentedButton<ThemeMode>` with 3 segments: Dark / Light / System
  - [x] 3.3 Wire `onSelectionChanged` to `context.read<ThemeCubit>().setTheme(selected.first)`

- [x] Task 4: Add ARB keys for Settings strings
  - [x] 4.1 Add 5 keys to `app_it.arb` and `app_en.arb` (see Dev Notes — ARB keys)
  - [x] 4.2 Run `flutter pub get` to regenerate `app_localizations*.dart`

- [x] Task 5: Update and expand tests
  - [x] 5.1 `14.1-CUBIT-001`: initial state from empty prefs → `ThemeMode.dark`
  - [x] 5.2 `14.1-CUBIT-002`: initial state from saved `'light'` → `ThemeMode.light`
  - [x] 5.3 `14.1-CUBIT-003`: initial state from saved `'system'` → `ThemeMode.system`
  - [x] 5.4 `14.1-CUBIT-004`: `setTheme(ThemeMode.light)` emits light + persists `'light'` in prefs
  - [x] 5.5 `14.1-CUBIT-005`: `setTheme(ThemeMode.system)` emits system + persists `'system'` in prefs
  - [x] 5.6 `14.1-CUBIT-006`: `setTheme(ThemeMode.dark)` emits dark + persists `'dark'` in prefs
  - [x] 5.7 `14.1-WIDGET-001`: SettingsPage renders 3 theme segment labels (Scuro / Chiaro / Sistema)
  - [x] 5.8 `14.1-WIDGET-002`: tapping "Chiaro" segment triggers `setTheme(ThemeMode.light)`
  - [x] 5.9 `14.1-WIDGET-003`: current theme is reflected in SegmentedButton selected set

- [x] Task 6: Verify
  - [x] 6.1 Run `flutter test` from `pulse_coach/`. Target: ≥ 809 + 9 new = ≥ 818 total. All existing tests remain green.
  - [x] 6.2 Run `flutter analyze` from `pulse_coach/`. Must be 0 issues.

## Dev Notes

### What Is Already In Place (Do NOT Reinvent)

- **`ThemeCubit`** exists at `pulse_coach/lib/features/settings/presentation/bloc/theme_cubit.dart` — `@lazySingleton`, currently supports only a binary `toggleTheme()` dark↔light with NO persistence. **This file is an UPDATE target.**
- **`AppTheme.darkTheme`** and **`AppTheme.lightTheme`** are fully implemented at `pulse_coach/lib/core/theme/app_theme.dart` — do NOT recreate these.
- **`PulseCoachTheme`** extension with both `dark` and `light` instances at `pulse_coach/lib/core/theme/pulse_coach_theme.dart` — all colors already defined.
- **`app.dart`** already wires `BlocProvider<ThemeCubit, ThemeMode>` + `BlocBuilder` that feeds `themeMode` into `MaterialApp.router`. **No change needed to `app.dart`.**
- **`SettingsPage`** stub at `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart` — currently just a scaffold center text. **This file is an UPDATE target.**
- **Route `/settings`** is already registered in `AppRouter` and reachable from the drawer. No routing changes needed.
- **Drawer entry** "Impostazioni" already navigates to `/settings`. No drawer changes needed.
- **DI pattern**: existing `@module` examples are `network_module.dart` and `health_module.dart` in `pulse_coach/lib/core/di/`. Follow the same `@module abstract class` pattern for the new `settings_module.dart`.

### ThemeCubit — What Changes

**Before (current — binary, no persistence):**
```dart
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark);
  void toggleTheme() { emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark); }
}
```

**After (3-mode + persistence):**
```dart
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_loadSavedTheme(_prefs));

  static ThemeMode _loadSavedTheme(SharedPreferences prefs) {
    return switch (prefs.getString('theme_mode')) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark, // default + null + 'dark' all map here
    };
  }

  void setTheme(ThemeMode mode) {
    _prefs.setString('theme_mode', mode.name); // 'dark' | 'light' | 'system'
    emit(mode);
  }
}
```

Key: `mode.name` yields `'dark'`, `'light'`, `'system'` — which round-trips correctly through the `switch`.

### DI Module — Settings Module

Create `pulse_coach/lib/core/di/settings_module.dart`:
```dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class SettingsModule {
  @preResolve
  @singleton
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();
}
```

**`@preResolve`** tells injectable to `await` this future during `configureDependencies()`. Since `main.dart` already calls `await configureDependencies()`, `SharedPreferences` will be fully resolved before the app starts — no async gaps.

After creating `settings_module.dart`, run:
```
dart run build_runner build --delete-conflicting-outputs
```
This regenerates `injection.config.dart` (GENERATED — do NOT edit by hand). The generated file will gain a `gh.singleton<SharedPreferences>()` registration via the async preResolve path, and `ThemeCubit` will receive it automatically.

### SettingsPage — Implementation Shape

`ThemeCubit` is provided at the root in `app.dart` via `BlocProvider(create: (_) => getIt<ThemeCubit>())`. `context.read<ThemeCubit>()` is therefore available anywhere below `MaterialApp`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsPageTitle)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.settingsThemeSection,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.settingsThemeDark),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.settingsThemeSystem),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selected) =>
                    context.read<ThemeCubit>().setTheme(selected.first),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

`SegmentedButton` is Material 3 and available in Flutter 3.41.x. It uses theme tokens automatically — no hardcoded colors needed.

### ARB Keys — What to Add

Add to both `pulse_coach/lib/l10n/app/app_it.arb` and `pulse_coach/lib/l10n/app/app_en.arb`:

**Italian (`app_it.arb`):**
```json
"settingsPageTitle": "Impostazioni",
"settingsThemeSection": "Tema",
"settingsThemeDark": "Scuro",
"settingsThemeLight": "Chiaro",
"settingsThemeSystem": "Sistema"
```

**English (`app_en.arb`):**
```json
"settingsPageTitle": "Settings",
"settingsThemeSection": "Theme",
"settingsThemeDark": "Dark",
"settingsThemeLight": "Light",
"settingsThemeSystem": "System"
```

Note: `app_it.arb` and `app_en.arb` are the SOURCE files in `lib/l10n/app/`. The generated `app_localizations*.dart` files are in `lib/l10n/` (`.gitignore`d — regenerated on `flutter pub get`). Do NOT edit the generated files.

### Existing Tests — What to Update

The file `pulse_coach/test/bloc/theme_cubit_test.dart` currently has 3 tests that test `toggleTheme()`. Since `toggleTheme()` is being replaced by `setTheme(ThemeMode)`, **rewrite this file completely** — do not try to adapt the old binary tests. The replacement tests are specified as `14.1-CUBIT-001` through `14.1-CUBIT-006` in the Tasks section.

**Test setup for ThemeCubit tests** — use `SharedPreferences.setMockInitialValues({})` to get an in-memory prefs instance:
```dart
setUp(() async {
  SharedPreferences.setMockInitialValues({});
  prefs = await SharedPreferences.getInstance();
});
```
No extra package needed — `shared_preferences` includes the mock in its test support.

**Test file for widget tests:** Create new file `pulse_coach/test/widget/settings_page_test.dart`.

Setup pattern for `SettingsPage` widget test — ThemeCubit is provided via `BlocProvider`:
```dart
await tester.pumpWidget(
  MaterialApp(
    home: BlocProvider(
      create: (_) => ThemeCubit(prefs),
      child: const SettingsPage(),
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('it'),
  ),
);
```

### Architecture Constraints (Do Not Violate)

- `ThemeCubit` is UI-state only → stays in `presentation/bloc/`. No domain or data layer involvement for theme persistence. SharedPreferences is a direct infra concern accessed from the Cubit (acceptable for simple settings per project-context.md: "Use Cubit for simple UI-only state").
- **No `CircularProgressIndicator` or spinners** — the settings page has no async loading state (SharedPreferences is pre-loaded at init).
- **No hardcoded colors in SettingsPage** — use `Theme.of(context)` tokens only.
- **Zero warnings**: `flutter analyze` must remain clean.
- `injection.config.dart` is GENERATED — never edit it manually. Run `build_runner` after creating `settings_module.dart`.
- Generated `app_localizations*.dart` files are `.gitignore`d — run `flutter pub get` to regenerate after ARB changes.

### Current Test Baseline

As of Story 13.3 done (2026-06-04): `flutter test` passes with **809/809** tests.

New tests this story: 6 Cubit unit tests (replacing 3 existing) + 3 widget tests = net **+6** new tests.
Target after story: ≥ **815** tests (replacing 3 toggle tests with 6 new + 3 widget tests = +6 net).

### File Changes Summary

**MODIFY:**
- `pulse_coach/pubspec.yaml` — add `shared_preferences: ^2.3.0`
- `pulse_coach/lib/features/settings/presentation/bloc/theme_cubit.dart` — 3-mode + persistence
- `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart` — full implementation
- `pulse_coach/lib/l10n/app/app_it.arb` — 5 new keys
- `pulse_coach/lib/l10n/app/app_en.arb` — 5 new keys
- `pulse_coach/test/bloc/theme_cubit_test.dart` — rewrite with setTheme + persistence tests

**CREATE:**
- `pulse_coach/lib/core/di/settings_module.dart` — SharedPreferences DI module
- `pulse_coach/test/widget/settings_page_test.dart` — widget tests

**REGENERATED (do not manually edit):**
- `pulse_coach/lib/core/di/injection.config.dart` — via `build_runner`
- `pulse_coach/lib/l10n/app_localizations.dart` + `app_localizations_it.dart` + `app_localizations_en.dart` — via `flutter pub get`

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md` §Epic 14, Story 14.1
- FR48, UX-DR20: `_bmad-output/planning-artifacts/prd.md` lines ~616, ~145
- ThemeCubit (current): `pulse_coach/lib/features/settings/presentation/bloc/theme_cubit.dart`
- AppTheme: `pulse_coach/lib/core/theme/app_theme.dart`
- PulseCoachTheme extension: `pulse_coach/lib/core/theme/pulse_coach_theme.dart`
- App wiring (ThemeCubit BlocProvider): `pulse_coach/lib/app.dart`
- SettingsPage stub: `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart`
- Route constants: `pulse_coach/lib/core/routing/app_router.dart` (`AppRouter.settings = '/settings'`)
- Drawer (settings navigation entry point): `pulse_coach/lib/shared/widgets/app_shell.dart`
- DI module pattern: `pulse_coach/lib/core/di/network_module.dart`, `pulse_coach/lib/core/di/health_module.dart`
- DI entry point: `pulse_coach/lib/core/di/injection.dart`
- ARB sources: `pulse_coach/lib/l10n/app/app_it.arb`, `pulse_coach/lib/l10n/app/app_en.arb`
- Previous story (13.3): `_bmad-output/implementation-artifacts/13-3-data-persistence-guarantees.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story context engine, 2026-06-04)

### Debug Log References

- 2026-06-04: Confirmed RED for new ThemeCubit/SettingsPage tests: old constructor and missing `setTheme` failed compilation before implementation.
- 2026-06-04: Ran `flutter pub get` after adding `shared_preferences` and ARB keys.
- 2026-06-04: Ran `dart run build_runner build --delete-conflicting-outputs` to regenerate Injectable configuration after adding `SettingsModule` and the `ThemeCubit(SharedPreferences)` constructor.
- 2026-06-04: Fixed DI tests by mocking SharedPreferences before `configureDependencies()`.
- 2026-06-04: Validation passed: `flutter test` from `pulse_coach/` with 822/822 tests.
- 2026-06-04: Validation passed: `flutter analyze` from `pulse_coach/` with 0 issues.

### Completion Notes List

- Added `shared_preferences` and a pre-resolved `SettingsModule` so theme mode is available before app startup.
- Reworked `ThemeCubit` from binary toggle to persisted `ThemeMode.dark`, `ThemeMode.light`, and `ThemeMode.system` selection.
- Implemented Settings theme selection UI using localized labels and `SegmentedButton<ThemeMode>`.
- Added English and Italian Settings ARB keys and regenerated localization output.
- Replaced old toggle tests with persistence-focused cubit tests and added SettingsPage widget coverage.
- Updated existing app/router/smoke/DI tests to provide mocked SharedPreferences after the ThemeCubit constructor change.

### File List

- _bmad-output/implementation-artifacts/14-1-theme-toggle-dark-light-system.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- pulse_coach/lib/core/di/injection.config.dart
- pulse_coach/lib/core/di/settings_module.dart
- pulse_coach/lib/features/settings/presentation/bloc/theme_cubit.dart
- pulse_coach/lib/features/settings/presentation/pages/settings_page.dart
- pulse_coach/lib/l10n/app/app_en.arb
- pulse_coach/lib/l10n/app/app_it.arb
- pulse_coach/pubspec.lock
- pulse_coach/pubspec.yaml
- pulse_coach/test/bloc/theme_cubit_test.dart
- pulse_coach/test/core/di/injection_test.dart
- pulse_coach/test/core/routing/app_router_test.dart
- pulse_coach/test/widget/app_test.dart
- pulse_coach/test/widget/pages_smoke_test.dart
- pulse_coach/test/widget/settings_page_test.dart

### Change Log

- 2026-06-04: Implemented Story 14.1 theme mode selector with SharedPreferences persistence, localized Settings UI, DI registration, and full test/analyze validation.

## Review Findings

_Code review 2026-06-05 (3 adversarial layers: Blind Hunter, Edge Case Hunter, Acceptance Auditor). All 5 ACs satisfied; gates independently re-run green: `flutter analyze` = 0 issues, `flutter test` = 822/822. 3 LOW-severity quality patches, 0 decision-needed, 0 defer, 6 dismissed (verified handled)._

- [x] [Review][Patch] `setTheme` fire-and-forget `setString` — FIXED 2026-06-05: emit first for instant UI, then `unawaited(_prefs.setString(...))` with an explanatory comment. [pulse_coach/lib/features/settings/presentation/bloc/theme_cubit.dart — `setTheme`]
- [x] [Review][Patch] Asymmetric serialization contract — FIXED 2026-06-05: added an explicit `'dark' => ThemeMode.dark` arm plus a documenting comment on the `_` default. [pulse_coach/lib/features/settings/presentation/bloc/theme_cubit.dart — `_loadSavedTheme`]
- [x] [Review][Patch] Duplicated magic string `'theme_mode'` — FIXED 2026-06-05: extracted to `static const _themeModeKey`, used in both read and write paths. [pulse_coach/lib/features/settings/presentation/bloc/theme_cubit.dart]
