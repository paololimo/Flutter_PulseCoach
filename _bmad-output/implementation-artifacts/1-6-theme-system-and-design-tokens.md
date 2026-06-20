# Story 1.6: Theme System & Design Tokens

Status: done

## Story

As a developer,
I want the full design token system implemented in `ThemeData` + `ThemeExtension<PulseCoachTheme>`,
so that all widgets consume the correct colors, typography, spacing, and shape values without hardcoded values.

## Acceptance Criteria

1. **Given** `PulseCoachTheme` extends `ThemeExtension<PulseCoachTheme>`
   **When** any widget calls `Theme.of(context).extension<PulseCoachTheme>()`
   **Then** all 9 color tokens are accessible: `surface (#0F1119)`, `surfaceContainer (#171B26)`, `surfaceContainerHigh (#1E2333)`, `primaryColor (#7DD3C0)`, `secondary (#A78BDA)`, `tertiary (#E8C87A)`, `onSurface (#E2E4EA)`, `onSurfaceVariant (#9498A6)`, `error (#F28B82)`

2. **Given** `AppTextStyles` is defined
   **When** a widget uses `AppTextStyles.timerDisplay`
   **Then** the style is JetBrains Mono 48sp; `AppTextStyles.countdown` is JetBrains Mono 72sp; `AppTextStyles.rpeNumbers` is JetBrains Mono 20sp; all other roles use Plus Jakarta Sans per the scale below; minimum text size is 11sp (Caption)

3. **Given** `AppSpacing` constants are defined
   **When** a widget applies `AppSpacing.md`
   **Then** the value is 16dp; all tokens (`xs`, `sm`, `md`, `lg`, `xl`, `xxl`) follow the 8dp base unit scale

4. **Given** shape tokens are defined in `AppShapes`
   **When** a card uses `AppShapes.cardRadius`
   **Then** corner radius is 16dp; buttons use 12dp; inputs/chips use 8dp

5. **Given** `ThemeCubit` emits `ThemeMode`
   **When** the cubit is instantiated
   **Then** initial state is `ThemeMode.dark`; `toggleTheme()` switches between dark and light

6. **Given** `app.dart` wires up `ThemeCubit`
   **When** `ThemeMode.dark` is active
   **Then** `MaterialApp` uses `AppTheme.darkTheme`; `PulseCoachTheme` extension is registered; no shadows — surface tint used for elevation; max 3 elevation levels

## Tasks / Subtasks

- [x] Task 1: Implement `PulseCoachTheme` ThemeExtension (AC: #1, #6)
  - [x] MODIFY `lib/core/theme/pulse_coach_theme.dart` — replace stub with full implementation
  - [x] 9 final `Color` fields (see exact hex values in Dev Notes)
  - [x] Implement `copyWith()` and `lerp()` methods (required by ThemeExtension contract)
  - [x] Provide `dark` and `light` static const instances

- [x] Task 2: Implement `AppTheme` builder (AC: #6)
  - [x] MODIFY `lib/core/theme/app_theme.dart` — replace stub with full implementation
  - [x] `darkTheme`: `ThemeData(useMaterial3: true, colorScheme: ..., extensions: [PulseCoachTheme.dark])`
  - [x] `lightTheme`: `ThemeData(useMaterial3: true, colorScheme: ..., extensions: [PulseCoachTheme.light])`
  - [x] Dark: `ColorScheme.fromSeed(seedColor: Color(0xFF7DD3C0), brightness: Brightness.dark)` with color overrides
  - [x] Light: `ColorScheme.fromSeed(seedColor: Color(0xFF7DD3C0))` (Material 3 generates light palette)
  - [x] TextTheme: apply `GoogleFonts.plusJakartaSansTextTheme()` as base; override mono styles separately
  - [x] CardTheme: `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))`
  - [x] No `shadowColor` / no elevation shadows in dark — use surface tints only

- [x] Task 3: CREATE `lib/core/theme/app_text_styles.dart` (AC: #2)
  - [x] Abstract class `AppTextStyles` with static `TextStyle` getters (no instantiation)
  - [x] JetBrains Mono styles: `timerDisplay` (48sp), `countdown` (72sp), `rpeNumbers` (20sp), `timerSecondary` (24sp)
  - [x] Plus Jakarta Sans styles: `display` (28sp SemiBold), `h1` (24sp SemiBold), `h2` (20sp SemiBold), `h3` (17sp Medium), `body` (15sp Regular), `bodySmall` (13sp Regular), `caption` (11sp Regular)
  - [x] All styles use `GoogleFonts.jetBrainsMono(...)` or `GoogleFonts.plusJakartaSans(...)` — no hardcoded fontFamily strings

- [x] Task 4: CREATE `lib/core/theme/app_spacing.dart` (AC: #3)
  - [x] Abstract class `AppSpacing` with static const double values
  - [x] `xs = 4`, `sm = 8`, `md = 16`, `lg = 24`, `xl = 32`, `xxl = 48`

- [x] Task 5: CREATE `lib/core/theme/app_shapes.dart` (AC: #4)
  - [x] Abstract class `AppShapes` with static const values
  - [x] `cardRadius = 16.0`, `buttonRadius = 12.0`, `inputRadius = 8.0`
  - [x] Provide `BorderRadius` helpers: `cardBorderRadius`, `buttonBorderRadius`, `inputBorderRadius`

- [x] Task 6: CREATE `ThemeCubit` and `ThemeState` (AC: #5)
  - [x] CREATE `lib/features/settings/presentation/bloc/theme_cubit.dart` (replacing `.gitkeep`)
  - [x] No `theme_state.dart` needed — `ThemeMode` IS the state (per Dev Notes guidance)
  - [x] `ThemeCubit extends Cubit<ThemeMode>` — initial state `ThemeMode.dark`
  - [x] Single method: `void toggleTheme()` — switches dark ↔ light
  - [x] Register with `@injectable` annotation

- [x] Task 7: MODIFY `lib/app.dart` to wire theme (AC: #6)
  - [x] Wrap `PulseCoachApp` body with `BlocBuilder<ThemeCubit, ThemeMode>`
  - [x] `MaterialApp(theme: AppTheme.lightTheme, darkTheme: AppTheme.darkTheme, themeMode: state)`
  - [x] Provide `ThemeCubit` via `BlocProvider` above `MaterialApp`
  - [x] Keep `home:` stub (navigation replaced in Story 1.7)

- [x] Task 8: Write tests (AC: #1–#6)
  - [x] CREATE `test/bloc/theme_cubit_test.dart` — test initial state, toggleTheme dark→light, toggleTheme light→dark
  - [x] CREATE `test/widget/theme_extension_test.dart` — pumpWidget with dark theme, assert extension tokens accessible and correct
  - [x] Run `flutter test` — all 38 tests pass (28 pre-existing + 10 new)
  - [x] Run `flutter analyze` → 0 issues

- [x] Task 9: Verify no build_runner needed
  - [x] build_runner WAS needed: `@injectable` on ThemeCubit required regeneration of `injection.config.dart`

### Review Findings

- [x] [Review][Decision] Light theme `ColorScheme` not aligned with `PulseCoachTheme.light` — Added `.copyWith()` to light theme referencing `PulseCoachTheme.light` fields. [app_theme.dart]
- [x] [Review][Patch] `ThemeCubit` registered as `factory` → changed to `@lazySingleton`. Regenerated `injection.config.dart`. [theme_cubit.dart, injection.config.dart]
- [x] [Review][Patch] Duplicated color hex values → `AppTheme.darkTheme` now references `PulseCoachTheme.dark` fields as single source of truth. [app_theme.dart]
- [x] [Review][Patch] `lerp` test expanded with `t=0.0`, `t=0.5`, and `t=1.0` assertions. [theme_extension_test.dart]
- [x] [Review][Patch] Light theme extension test now verifies all 9 color tokens. [theme_extension_test.dart]

## Dev Notes

### Critical: File Actions Summary

| File | Action |
|---|---|
| `pulse_coach/lib/core/theme/pulse_coach_theme.dart` | MODIFY — replace stub (2-line comment) |
| `pulse_coach/lib/core/theme/app_theme.dart` | MODIFY — replace stub (2-line comment) |
| `pulse_coach/lib/core/theme/app_text_styles.dart` | CREATE — new file |
| `pulse_coach/lib/core/theme/app_spacing.dart` | CREATE — new file |
| `pulse_coach/lib/core/theme/app_shapes.dart` | CREATE — new file |
| `pulse_coach/lib/features/settings/presentation/bloc/theme_cubit.dart` | CREATE — replace `.gitkeep` |
| `pulse_coach/lib/features/settings/presentation/bloc/theme_state.dart` | CREATE — replace `.gitkeep` |
| `pulse_coach/lib/app.dart` | MODIFY — wire ThemeCubit + AppTheme |
| `pulse_coach/test/bloc/theme_cubit_test.dart` | CREATE |
| `pulse_coach/test/widget/theme_extension_test.dart` | CREATE |

**Do NOT touch:** `main.dart`, `injection.dart`, `injection.config.dart`, database files, error files, either_extensions.dart.

### Critical: Design Token Values

```dart
// PulseCoachTheme — dark instance color values
static const dark = PulseCoachTheme(
  surface: Color(0xFF0F1119),
  surfaceContainer: Color(0xFF171B26),
  surfaceContainerHigh: Color(0xFF1E2333),
  primaryColor: Color(0xFF7DD3C0),       // aqua green — primary actions, completion ring
  secondary: Color(0xFFA78BDA),           // muted violet — Fatigued/Recovering state
  tertiary: Color(0xFFE8C87A),            // warm amber — AtRisk state, AQI warnings
  onSurface: Color(0xFFE2E4EA),           // primary text
  onSurfaceVariant: Color(0xFF9498A6),    // secondary text, AI explanation lines
  error: Color(0xFFF28B82),              // soft red — genuine errors only
);
```

**Light instance:** Use Material 3 `ColorScheme.fromSeed()` generated values — `PulseCoachTheme.light` can mirror dark token names but with M3-generated light equivalents.

### Critical: PulseCoachTheme Implementation

```dart
// lib/core/theme/pulse_coach_theme.dart
import 'package:flutter/material.dart';

class PulseCoachTheme extends ThemeExtension<PulseCoachTheme> {
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color primaryColor;
  final Color secondary;
  final Color tertiary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color error;

  const PulseCoachTheme({
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.primaryColor,
    required this.secondary,
    required this.tertiary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.error,
  });

  static const dark = PulseCoachTheme(
    surface: Color(0xFF0F1119),
    surfaceContainer: Color(0xFF171B26),
    surfaceContainerHigh: Color(0xFF1E2333),
    primaryColor: Color(0xFF7DD3C0),
    secondary: Color(0xFFA78BDA),
    tertiary: Color(0xFFE8C87A),
    onSurface: Color(0xFFE2E4EA),
    onSurfaceVariant: Color(0xFF9498A6),
    error: Color(0xFFF28B82),
  );

  static const light = PulseCoachTheme(
    surface: Color(0xFFF8FFFE),
    surfaceContainer: Color(0xFFEEF6F4),
    surfaceContainerHigh: Color(0xFFE1F0ED),
    primaryColor: Color(0xFF7DD3C0),
    secondary: Color(0xFFA78BDA),
    tertiary: Color(0xFFE8C87A),
    onSurface: Color(0xFF1A1C1E),
    onSurfaceVariant: Color(0xFF42474E),
    error: Color(0xFFBA1A1A),
  );

  @override
  PulseCoachTheme copyWith({Color? surface, ...}) { ... }

  @override
  PulseCoachTheme lerp(PulseCoachTheme? other, double t) {
    if (other == null) return this;
    return PulseCoachTheme(
      surface: Color.lerp(surface, other.surface, t)!,
      // ... lerp all 9 fields
    );
  }
}
```

### Critical: ThemeCubit Pattern (Cubit, NOT Bloc)

```dart
// lib/features/settings/presentation/bloc/theme_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@injectable
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark);

  void toggleTheme() {
    emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
```

**No `theme_state.dart` needed** — `ThemeMode` IS the state. Delete/ignore `.gitkeep` in the bloc folder. If you create `theme_state.dart` anyway for DI registration clarity, make it a simple type alias comment file only.

**Why Cubit not Bloc:** `ThemeCubit` has a single simple state value with no async operations — exactly the Cubit use case per project-context.md.

### Critical: AppTheme Builder

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

abstract class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7DD3C0),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0F1119),
      surfaceContainerLow: const Color(0xFF0F1119),
      surfaceContainer: const Color(0xFF171B26),
      surfaceContainerHigh: const Color(0xFF1E2333),
      primary: const Color(0xFF7DD3C0),
      secondary: const Color(0xFFA78BDA),
      tertiary: const Color(0xFFE8C87A),
      onSurface: const Color(0xFFE2E4EA),
      onSurfaceVariant: const Color(0xFF9498A6),
      error: const Color(0xFFF28B82),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    extensions: const [PulseCoachTheme.dark],
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 0,
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7DD3C0)),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    extensions: const [PulseCoachTheme.light],
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 0,
    ),
  );
}
```

### Critical: Typography Scale

```dart
// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTextStyles {
  // JetBrains Mono — data/metrics only
  static TextStyle get timerDisplay => GoogleFonts.jetBrainsMono(fontSize: 48, height: 1.0);
  static TextStyle get countdown    => GoogleFonts.jetBrainsMono(fontSize: 72, height: 1.0);
  static TextStyle get rpeNumbers   => GoogleFonts.jetBrainsMono(fontSize: 20, height: 1.0);
  static TextStyle get timerSecondary => GoogleFonts.jetBrainsMono(fontSize: 24, height: 1.0);

  // Plus Jakarta Sans — all body/UI text
  static TextStyle get display   => GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2);
  static TextStyle get h1        => GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25);
  static TextStyle get h2        => GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get h3        => GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w500, height: 1.35);
  static TextStyle get body      => GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45);
  static TextStyle get caption   => GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w400, height: 1.4);
  // NOTE: 11sp is the absolute minimum — never use a smaller size anywhere in the app
}
```

### Critical: Spacing & Shape Constants

```dart
// lib/core/theme/app_spacing.dart
abstract class AppSpacing {
  static const double xs  = 4;   // tight: icon+label, caption lines
  static const double sm  = 8;   // compact: within card, related elements
  static const double md  = 16;  // standard: between cards, sections
  static const double lg  = 24;  // generous: major sections, screen titles
  static const double xl  = 32;  // breathing: top/bottom screen padding
  static const double xxl = 48;  // major: onboarding, in-session steps
}

// lib/core/theme/app_shapes.dart
import 'package:flutter/material.dart';
abstract class AppShapes {
  static const double cardRadius   = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius  = 8.0;

  static const cardBorderRadius   = BorderRadius.all(Radius.circular(cardRadius));
  static const buttonBorderRadius = BorderRadius.all(Radius.circular(buttonRadius));
  static const inputBorderRadius  = BorderRadius.all(Radius.circular(inputRadius));
}
```

### Critical: app.dart Wiring

```dart
// lib/app.dart — MODIFY existing file
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
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
          return MaterialApp(
            title: 'PulseCoach',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const Scaffold(
              body: Center(child: Text('PulseCoach')),
            ),
          );
        },
      ),
    );
  }
}
```

**Story 1.7 replaces `home:` with `MaterialApp.router` + go_router. Do NOT set up routing here.**

### Critical: ThemeCubit Injectable Registration

`ThemeCubit` has `@injectable` annotation — it will be auto-registered via `injection.config.dart`. However, since DI was set up in Story 1.3, verify `getIt<ThemeCubit>()` resolves after running build_runner. If injectable factories don't include ThemeCubit automatically, add `@factoryMethod` or manually register in `injection.dart` as a last resort (but annotation is preferred).

**After adding `@injectable` to ThemeCubit:**
```bash
dart run build_runner build --delete-conflicting-outputs
```
This regenerates `injection.config.dart` — commit it alongside source changes.

### Critical: Import Style (enforced since Story 1.1)

```dart
// ✅ Always
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

// ❌ Never
import '../../core/theme/app_theme.dart';
```

### Critical: No Shadows in Dark Mode

Per architecture ARCH16 + UX elevation strategy:
- `elevation: 0` on cards — use `surfaceContainer` color for card backgrounds (provides visual lift without shadows)
- Never set `shadowColor` in dark theme
- 3 elevation levels max: `surface` (0xFF0F1119) → `surfaceContainer` (0xFF171B26) → `surfaceContainerHigh` (0xFF1E2333)

### Testing Requirements

**`test/bloc/theme_cubit_test.dart`:**
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';

void main() {
  group('ThemeCubit', () {
    test('initial state is ThemeMode.dark', () {
      expect(ThemeCubit().state, ThemeMode.dark);
    });

    blocTest<ThemeCubit, ThemeMode>(
      'toggleTheme emits light when dark',
      build: () => ThemeCubit(),
      act: (c) => c.toggleTheme(),
      expect: () => [ThemeMode.light],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'toggleTheme emits dark when light',
      build: () => ThemeCubit()..toggleTheme(),
      act: (c) => c.toggleTheme(),
      expect: () => [ThemeMode.dark],
    );
  });
}
```

**`test/widget/theme_extension_test.dart`:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

void main() {
  group('PulseCoachTheme extension', () {
    testWidgets('dark theme extension tokens are correct', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(builder: (context) {
          final theme = Theme.of(context).extension<PulseCoachTheme>()!;
          expect(theme.primaryColor, const Color(0xFF7DD3C0));
          expect(theme.surface, const Color(0xFF0F1119));
          expect(theme.onSurface, const Color(0xFFE2E4EA));
          return const SizedBox.shrink();
        }),
      ));
    });

    testWidgets('extension is not null in dark theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(builder: (context) {
          expect(Theme.of(context).extension<PulseCoachTheme>(), isNotNull);
          return const SizedBox.shrink();
        }),
      ));
    });
  });
}
```

**Pre-existing tests to stay green:** 28 tests (14 DB + 3 DI + 14 error/either).

### Project Structure Notes

**New files added by this story:**
```
lib/core/theme/
├── app_theme.dart          ← MODIFY (was 2-line stub)
├── pulse_coach_theme.dart  ← MODIFY (was 2-line stub)
├── app_text_styles.dart    ← CREATE
├── app_spacing.dart        ← CREATE
└── app_shapes.dart         ← CREATE

lib/features/settings/presentation/bloc/
├── theme_cubit.dart        ← CREATE (replaces .gitkeep)
└── (no theme_state.dart needed)

test/bloc/
└── theme_cubit_test.dart   ← CREATE

test/widget/
└── theme_extension_test.dart ← CREATE
```

**Alignment with architecture folder spec:**
- `lib/core/theme/app_theme.dart` ✅ (architecture lists this file)
- `lib/core/theme/pulse_coach_theme.dart` ✅ (architecture lists this file)
- `lib/features/settings/presentation/bloc/theme_cubit.dart` ✅ (architecture lists this file)
- `test/bloc/theme_cubit_test.dart` ✅ (mirrors `lib/features/settings/presentation/bloc/`)

### Previous Story Intelligence (Story 1.5)

- `flutter analyze` was 0 issues after Story 1.5 — must remain 0 after Story 1.6
- `package:pulse_coach/...` imports enforced — apply to all new theme files
- `dartz` `isLeft()`/`isRight()` are instance methods, not extension properties — not relevant here but keep in mind for future stories
- Failure/Exception classes are plain Dart, NOT freezed — pattern consistency: ThemeCubit state is also plain (`ThemeMode` enum, no freezed)
- Generated files (`injection.config.dart`) are committed alongside source changes — do same if build_runner runs
- Test count after Story 1.5: 28 tests — increment from here

### Git Intelligence (from recent commits)

- Story 1.1–1.5 all followed pattern: infrastructure-only, no feature code
- Story 1.5 added 14 tests (from 14→28); this story should add ~6–8 more
- No WearOS/sensor code yet — defer `wear_plus` spike to later epics
- `lib/app.dart` currently has bare `MaterialApp(useMaterial3: true)` — safe to fully replace contents

### Architecture Compliance

| Rule | Requirement | How |
|---|---|---|
| ARCH-Theme | `ThemeData` + `ThemeExtension<PulseCoachTheme>` | PulseCoachTheme with 9 tokens |
| ARCH-M3 | `useMaterial3: true`, dark-first | AppTheme.darkTheme as default |
| ARCH-Fonts | Plus Jakarta Sans + JetBrains Mono via google_fonts | AppTextStyles using GoogleFonts |
| ARCH-Cubit | `ThemeCubit` for UI-only state | Cubit<ThemeMode> in settings/bloc/ |
| ARCH16 | No shadows in dark — surface tint elevation | `elevation: 0`, use surfaceContainer colors |
| UI-Anti | Never hardcode colors/text styles | Always `Theme.of(ctx).extension<PulseCoachTheme>()` |

### References

- [Source: epics.md#Story 1.6] — User story, acceptance criteria (UX-DR1, UX-DR2, UX-DR3, UX-DR17, ARCH16)
- [Source: ux-design-specification.md#Color System] — All 9 hex values, semantic mapping, dark/light philosophy
- [Source: ux-design-specification.md#Typography System] — Full type scale with weights, sizes, fonts
- [Source: ux-design-specification.md#Spacing & Layout Foundation] — 8dp base unit, all 6 spacing tokens
- [Source: ux-design-specification.md#Shape Strategy] — card 16dp, button 12dp, input/chip 8dp
- [Source: ux-design-specification.md#Elevation Strategy (dark mode)] — no shadows, 3 tint levels
- [Source: architecture.md#Theme Architecture] — `ThemeData + ThemeExtension<PulseCoachTheme>`, `ColorScheme.fromSeed()`, dark-first
- [Source: architecture.md#State Management Split] — `ThemeCubit` in settings/presentation/bloc/
- [Source: architecture.md#Complete Project Directory Structure] — all file paths listed
- [Source: project-context.md#Framework-Specific Rules] — Cubit for UI-only, no hardcoded colors, useMaterial3: true
- [Source: project-context.md#UI anti-patterns] — hardcoded color → ThemeExtension, spinner → shimmer
- [Source: story 1-5] — package import enforcement, analyze 0 issues, test count baseline 28

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `app_test.dart` needed update: `PulseCoachApp` now requires `getIt<ThemeCubit>()`, so the smoke test must register `ThemeCubit` manually via `getIt.registerFactory` before pumping the widget.
- `build_runner` WAS required despite Task 9 saying otherwise: adding `@injectable` to `ThemeCubit` triggers regeneration of `injection.config.dart`.

### Completion Notes List

- Implemented full `PulseCoachTheme` ThemeExtension with 9 color tokens, `copyWith()`, `lerp()`, and `dark`/`light` static const instances.
- Implemented `AppTheme` with `darkTheme` (M3 dark, `ColorScheme.fromSeed` overrides, no shadows, `elevation: 0`) and `lightTheme`.
- Created `AppTextStyles` with 4 JetBrains Mono + 7 Plus Jakarta Sans static getters; all via `GoogleFonts`.
- Created `AppSpacing` (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48).
- Created `AppShapes` (cardRadius=16, buttonRadius=12, inputRadius=8) with `BorderRadius` helpers.
- Created `ThemeCubit extends Cubit<ThemeMode>` with `@injectable`, initial state `ThemeMode.dark`, `toggleTheme()`.
- Updated `app.dart` with `BlocProvider<ThemeCubit>` + `BlocBuilder<ThemeCubit, ThemeMode>` wiring `AppTheme.darkTheme`/`lightTheme`.
- Ran `build_runner` to regenerate `injection.config.dart` including `ThemeCubit` factory.
- All 38 tests pass (28 pre-existing + 10 new); `flutter analyze` → 0 issues.

### File List

- `pulse_coach/lib/core/theme/pulse_coach_theme.dart` (modified)
- `pulse_coach/lib/core/theme/app_theme.dart` (modified)
- `pulse_coach/lib/core/theme/app_text_styles.dart` (created)
- `pulse_coach/lib/core/theme/app_spacing.dart` (created)
- `pulse_coach/lib/core/theme/app_shapes.dart` (created)
- `pulse_coach/lib/features/settings/presentation/bloc/theme_cubit.dart` (created)
- `pulse_coach/lib/app.dart` (modified)
- `pulse_coach/lib/core/di/injection.config.dart` (regenerated by build_runner)
- `pulse_coach/test/bloc/theme_cubit_test.dart` (created)
- `pulse_coach/test/widget/theme_extension_test.dart` (created)
- `pulse_coach/test/widget/app_test.dart` (modified — updated for DI-aware app.dart)

## Change Log

- 2026-03-28: Implemented Story 1.6 — full theme system: PulseCoachTheme (9 tokens), AppTheme (dark/light), AppTextStyles, AppSpacing, AppShapes, ThemeCubit, app.dart wiring. 38 tests pass, 0 analyze issues.
