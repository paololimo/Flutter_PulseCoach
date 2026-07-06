# PulseCoach Design System

Extracted from `pulse_coach/lib/core/theme/` and the app's reusable widgets. This is a
descriptive spec — the source of truth is the Dart code it references. Update it when the
token files or shared components change.

## Foundations

Material 3 (`useMaterial3: true`) with a custom `ThemeExtension` (`PulseCoachTheme`) layered
on top of a seed-generated `ColorScheme`. The seed color is the brand teal `#7DD3C0`.

- Token source: `core/theme/`
  - `pulse_coach_theme.dart` — semantic color tokens (dark + light), as a `ThemeExtension`.
  - `app_theme.dart` — `AppTheme.darkTheme` / `AppTheme.lightTheme` wiring.
  - `app_text_styles.dart` — named typography scale.
  - `app_spacing.dart` — spacing scale.
  - `app_shapes.dart` — corner-radius tokens.

**Convention — every custom component reads `PulseCoachTheme`, not raw colors.** Components
resolve `Theme.of(context).extension<PulseCoachTheme>()` and `assert` it is present. Never
hardcode a `Color(0x…)` in a widget; add or reuse a token. Anything mounting these widgets in
a test/preview must register a theme carrying the `PulseCoachTheme` extension.

## Color tokens

Brand colors (`primary`, `secondary`, `tertiary`) are identical across themes; only the
surfaces and on-colors flip between dark and light.

| Token                  | Role                                   | Dark        | Light       |
|------------------------|----------------------------------------|-------------|-------------|
| `surface`              | App background / lowest surface        | `#0F1119`   | `#F8FFFE`   |
| `surfaceContainer`     | Card / container fill                   | `#171B26`   | `#EEF6F4`   |
| `surfaceContainerHigh` | Raised container (sheets, high cards)   | `#1E2333`   | `#E1F0ED`   |
| `primaryColor`         | Brand teal — primary actions, progress  | `#7DD3C0`   | `#7DD3C0`   |
| `secondary`            | Accent purple                           | `#A78BDA`   | `#A78BDA`   |
| `tertiary`             | Accent gold                             | `#E8C87A`   | `#E8C87A`   |
| `onSurface`            | Primary text / foreground               | `#E2E4EA`   | `#1A1C1E`   |
| `onSurfaceVariant`     | Secondary text, tracks, dividers        | `#9498A6`   | `#42474E`   |
| `error`                | Error state                             | `#F28B82`   | `#BA1A1A`   |

Common alpha usages seen in components: tracks/dividers `onSurfaceVariant` @ ~0.2, shimmer
highlight `onSurfaceVariant` @ 0.1.

## Typography

Two font families, declared in `pubspec.yaml` and bundled under `assets/fonts/`:

- **Plus Jakarta Sans** — all body / UI text (weights 400–800).
- **JetBrains Mono** — data and metrics only: timers, countdowns, RPE numbers, ring counters.

Named styles in `AppTextStyles` (all sizes in logical px, `height` = line-height multiplier):

| Style            | Family            | Size | Weight | Height | Use                          |
|------------------|-------------------|------|--------|--------|------------------------------|
| `countdown`      | JetBrains Mono    | 72   | 400    | 1.0    | Full-screen countdown        |
| `timerDisplay`   | JetBrains Mono    | 48   | 400    | 1.0    | In-session timer             |
| `timerSecondary` | JetBrains Mono    | 24   | 400    | 1.0    | Secondary timer readout      |
| `rpeNumbers`     | JetBrains Mono    | 20   | 400    | 1.0    | RPE numeric input            |
| `display`        | Plus Jakarta Sans | 28   | 600    | 1.2    | Screen hero titles           |
| `h1`             | Plus Jakarta Sans | 24   | 600    | 1.25   | Section / screen titles      |
| `h2`             | Plus Jakarta Sans | 20   | 600    | 1.3    | Sub-section titles           |
| `h3`             | Plus Jakarta Sans | 17   | 500    | 1.35   | Card titles                  |
| `body`           | Plus Jakarta Sans | 15   | 400    | 1.5    | Body copy                    |
| `bodySmall`      | Plus Jakarta Sans | 13   | 400    | 1.45   | Supporting copy              |
| `caption`        | Plus Jakarta Sans | 11   | 400    | 1.4    | Labels, metadata             |

**Hard rule:** `11sp` (`caption`) is the absolute minimum — never render smaller text anywhere.

## Spacing

`AppSpacing` — a 4-based scale. Prefer these constants over literal padding values.

| Token | Value | Intended use                                   |
|-------|-------|------------------------------------------------|
| `xs`  | 4     | Tight: icon+label, caption lines               |
| `sm`  | 8     | Compact: within a card, related elements       |
| `md`  | 16    | Standard: between cards, sections              |
| `lg`  | 24    | Generous: major sections, screen titles        |
| `xl`  | 32    | Breathing: top/bottom screen padding           |
| `xxl` | 48    | Major: onboarding, in-session steps            |

## Shape / radius

`AppShapes` — corner radii. Cards default to elevation `0` (flat) via `cardTheme`.

| Token          | Value | Use              |
|----------------|-------|------------------|
| `cardRadius`   | 16    | Cards, containers|
| `buttonRadius` | 12    | Buttons          |
| `inputRadius`  | 8     | Inputs, chips    |

Convenience `BorderRadius.all` constants: `cardBorderRadius`, `buttonBorderRadius`,
`inputBorderRadius`.

## Reusable components

Grouped by role. Screens (`*Page` / `*Screen`) are omitted — they compose these. Widget names
prefixed with `_` are file-private and not part of the reusable surface.

### Cards
- `HeroSessionCard` — primary "today" session card with regenerate action.
- `CompactSessionCard` — condensed upcoming-session row card.
- `CompletedSessionCard` — completed-session summary card.
- `SessionCatalogCard` — catalog browse card (with `_DifficultyDots`).
- `ActivityFeedCard` — social feed entry.
- `JoinCodeCard` — shared-session join-code display.

### Indicators & rings
- `CompletionRing` — 48×48 animated `CustomPaint` progress ring. Props: `completed`, `total`.
  Track = `onSurfaceVariant` @ 0.2, arc = `primaryColor`; pulses once on first completion;
  respects `MediaQuery.disableAnimations`; center counter uses JetBrains Mono 11/500.
- `StateIndicator` — behavioral-state badge/icon.
- `WeeklyGoalIndicator` — weekly minutes-goal progress.

### Charts (`fl_chart`)
- `CompletionRateChart`, `MinutesPerWeekChart`, `RpeTrendChart`, `SessionTypeBreakdownChart`.

### Rows & tiles
- `LeaderboardRow`, `FriendRow`, `ComparisonRow`, `SessionHistoryTile`.

### Inputs & controls
- `RPEInputWidget` — Rate-of-Perceived-Exertion selector.
- `VisibilityTierSelector` — privacy-tier picker.
- `HandleSetupSection` — social handle setup.

### Overlays & sheets
- `CountdownOverlay`, `ProUpsellSheet`, `SessionCatalogDetailSheet`, `SignInSheet`.

### Structure & utility
- `AppShell` — root scaffold: bottom tabs (`Sessions`, `Today`, `Progress` — Today is index 1)
  plus the app drawer.
- `OnboardingCarousel`, `ProfileSetupForm`, `InSessionView`, `BackupSettingsWidget`.
- `ShimmerPlaceholder` — skeleton loader. Props: `height`, `width?`, `borderRadius` (default 8).
  Uses `surfaceContainer` base with a `onSurfaceVariant` @ 0.1 highlight.

## Building on-brand UI (quick reference)

```dart
final t = Theme.of(context).extension<PulseCoachTheme>()!;

Container(
  padding: const EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: t.surfaceContainer,
    borderRadius: AppShapes.cardBorderRadius,
  ),
  child: Text('Session', style: AppTextStyles.h3.copyWith(color: t.onSurface)),
);
```

Rules of thumb: colors from `PulseCoachTheme` tokens · text from `AppTextStyles` · gaps from
`AppSpacing` · radii from `AppShapes` · metrics/timers in JetBrains Mono, everything else in
Plus Jakarta Sans · cards are flat (elevation 0).
