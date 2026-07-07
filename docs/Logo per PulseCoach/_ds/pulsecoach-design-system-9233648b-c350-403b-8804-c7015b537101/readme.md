# PulseCoach Design System

**PulseCoach** is an adaptive AI movement companion — the calm counter-statement to the fitness category. Where most movement apps shout (bright reds, streak counters, "AMAZING JOB!", 10pm nudges), PulseCoach is quiet on purpose: it decides, explains in one line, executes as a ritual, and resolves itself. The one-line test governs everything: *"Open the app and it already tells you what to do — and it always guesses how you feel."*

The governing metaphor is **dark canvas, living accents** — a restful near-black surface where color appears only where action, state, or completion lives. Color is never decorative. One emotional temperature across every screen; it never raises its voice. Locale is Italian (`it`). Dark is the default surface; light is a setting.

Scope: shipped **v1** (free, offline, account-free core) + designed **v2** (optional accounts, Pro, calm social).

## Sources

This system was built from these materials (store for reference — don't assume the reader has access):

- **Flutter codebase (source of truth):** GitHub `paololimo/Flutter_PulseCoach` — app at `pulse_coach/lib/`. Theme tokens in `pulse_coach/lib/core/theme/` (`pulse_coach_theme.dart`, `app_text_styles.dart`, `app_spacing.dart`, `app_shapes.dart`); reusable widgets under `pulse_coach/lib/features/*/presentation/widgets/` and `pulse_coach/lib/shared/widgets/`. Every token and component here is ground-truthed against that Dart source. Explore the repo further to build higher-fidelity work.
- **Specs:** `uploads/DESIGN.md` (visual identity spine), `uploads/EXPERIENCE.md` (experience spine), `uploads/design-system.md` (descriptive spec). Both spines win on conflict with any mock.
- **Mockups:** `uploads/key-screens.html`, `uploads/key-screens-extended.html`.

> **Font note:** the brand fonts are **Plus Jakarta Sans** (all readable/UI text) and **JetBrains Mono** (numbers only). These are the real families (bundled in the Flutter app); here they load from Google Fonts, which host the identical open-source families — no substitution. If you want the exact bundled binaries embedded instead, send the `.ttf` files.

## Content fundamentals

Copy is Italian, and the voice is **warmth over metrics, competence over congratulation**. State what's observed, then act.

- **No exclamation marks anywhere. No shame, no streaks, no missed-day counters, no motivational quotes, no urgency.** Absence is physiological data, not failure.
- **Person:** speaks *to* the user warmly and *about* the body ("Il tuo corpo ha riposato — ecco cosa gli serve ora."). First-person plural for shared intent ("Partiamo piano.").
- **Short, complete sentences.** Observe, then act: *"Sonno breve + HR a riposo elevata. Partiamo piano."*
- **The signature element is the one-line AI explanation** — always visible, never behind a tap.
- **Errors never sound like errors.** Silent degradation reads *"Sto usando i dati salvati."* (rare, inline, recessive) — never "Errore di rete".
- **Pro is contextual and silent:** *"Lo storico completo è una funzione Pro."* + `non ora`. Never an "Upgrade!" banner.
- **State-driven tone:** Active = neutral; Fatigued = factual/observational; AtRisk = caring/protective; AtRisk → *"Sei stato via 3 giorni — il corpo ha bisogno di un riavvio dolce."*; Recovering = encouraging/competent.
- **No emoji in product copy.** Section labels are the one small-caps tracking exception (`PROSSIME`, `COMING UP`).

## Visual foundations

- **Colors** — Surfaces: `#0F1119` / `#171B26` / `#1E2333`. Accents (identical in light & dark): Aqua `#7DD3C0` (action/completion/Mobility), Violet `#A78BDA` (behavioral state/Breathing), Amber `#E8C87A` (AtRisk/attention), Coral `#F0A1B0` (Cardio/HR). Text: `#E2E4EA` primary (not pure white), `#9498A6` secondary. Error `#F28B82` — genuine errors only. **Text on aqua MUST be On-Primary dark teal `#06231D`** (~12:1); white on aqua is banned. Every colored element invites action, communicates state, or confirms completion — never decoration. Color is never the sole carrier of meaning (always paired with label/icon/text).
- **Type** — Plus Jakarta Sans (geometric, warm) + JetBrains Mono (numbers only: timers, RPE, ring counter, join code — never body). Scale: Display 28 / H1 24 / H2 20 / H3 17 / Body 15 / Body-Small 13 / Caption 11 (absolute minimum). Numeric: Countdown 72 (largest in app) / Timer 48 / Timer-2 24 / RPE 20. No all-caps display, no exclamation marks.
- **Spacing** — 4-based scale (`xs`4 `sm`8 `md`16 `lg`24 `xl`32 `2xl`48). Density is **airy**: 16 card padding, 16 between cards, 24 screen edges. The Oura/Calm reference, not a dashboard.
- **Shape** — Consistently rounded, **no sharp corners**: card 16, button 12, chip/input 8, full 9999 (ring, RPE, dots, avatars, medals). Softer than Material's defaults.
- **Elevation** — Expressed as **surface tint, not shadow** (shadows are near-invisible on dark). Three levels: surface → container → container-high. Shadow is reserved for the one literal-physical moment: a bottom sheet lifting over a scrim (`var(--pc-scrim)`).
- **Backgrounds** — Flat dark canvas. **Exactly one gradient in the app:** the soft Today hero-zone wash (accent @ .12 → container). No textures, no patterns, no imagery behind content. No bluish-purple gradients.
- **Cards** — Flat (elevation 0), tinted fill, 16 radius, 16 padding, no border by default; selected state adds a faint accent outline / leading bar.
- **Motion** — Calm register. Ring arc 400ms easeInOut with a single gentle pulse on first completion; RPE select 150ms scale to 1.12; countdown beats fade+scale from 0.7. **No confetti, no celebration, no bounce, no infinite decorative loops.** Reduce-motion → durations 0, countdown becomes a static number swap, shimmer becomes static.
- **States/hover** — Buttons brighten slightly on hover and scale to 0.98 on press; cards brighten ~8% when interactive. Loading is always a **ShimmerPlaceholder** matching the content layout — never a spinner.
- **Transparency/blur** — Sparingly: scrim behind sheets (`rgba(6,7,11,.7)`), track/divider alphas (on-surface-variant @ .2), shimmer highlight @ .1. No glassmorphism.

## Iconography

PulseCoach uses **[Lucide](https://lucide.dev)** exclusively — Material Icons are explicitly NOT used (the Flutter app's Material glyphs map to their Lucide equivalents here). Lucide is line-based, 2px stroke, rounded caps/joins — a calm, consistent set that matches the soft geometry.

- **Load Lucide once per page** from CDN (`https://unpkg.com/lucide@0.469.0/dist/umd/lucide.min.js`); the `Icon` component reads real Lucide geometry from `window.lucide` and falls back to a filled dot if a glyph is missing. No PNG/SVG icon assets are bundled.
- **Key mappings:** nav → `dumbbell` (Sessions), `sun` (Today), `users` (Social), `bar-chart-3` (Progress); session types → `leaf` (Mobility), `heart` (Cardio), `wind` (Breathing); states → `alert-triangle` (AtRisk), `refresh-cw` (Recovering / regenerate); medals → `star` / `hexagon` / `diamond` (gold/silver/bronze, shape-distinct so color is never the only cue); misc → `check-circle`, `chevron-right`, `x`, `lock`, `menu`, `mail`.
- **Emoji:** never in product copy. **Unicode:** the heart `♥` is used for the in-session HR readout (coral). Difficulty is shown as filled dots, not glyphs.

**No brand logo was provided** in the sources — the app renders the wordmark "PulseCoach" in plain Plus Jakarta Sans (600) wherever a mark would go. No mark has been drawn or reconstructed; supply a logo file to add one.

## Components

React primitives (`window.PulseCoachDesignSystem_923364.<Name>`), grouped by concern. Each is ground-truthed against its Flutter widget.

- **core/** — `Icon`, `Button`, `Card`, `Chip`, `Badge`, `Switch`
- **today/** — `HeroSessionCard`, `CompactSessionCard`, `CompletedSessionCard`, `StateIndicator`, `CompletionRing`, `WeeklyGoalIndicator`
- **session/** — `RPEInput`, `CountdownOverlay`, `ShimmerPlaceholder`
- **catalog/** — `SessionCatalogCard`
- **social/** — `LeaderboardRow`, `FriendRow`, `ActivityFeedCard`, `ComparisonRow`, `VisibilityTierSelector`, `JoinCodeCard`
- **feedback/** — `ProUpsellSheet`, `SignInSheet`, `SessionHistoryTile`

**Intentional additions** (not 1:1 with a Flutter widget): `Icon` (a Lucide wrapper, since the app used Material Icons directly), and `Card` / `Badge` / `Chip` / `Switch` as thin brand-token wrappers around the Material-3 structural primitives the app themes. Everything else mirrors a named widget in the codebase.

## Index

- `styles.css` — global entry point (imports only). Consumers link this one file.
- `tokens/` — `fonts.css`, `colors.css`, `typography.css`, `spacing.css`, `shapes.css`.
- `components/<group>/` — the primitives above (`.jsx` + `.d.ts` + `.prompt.md` + one `@dsCard` per group).
- `ui_kits/pulsecoach_app/` — interactive app recreation (Today · Sessions · Social · Progress + the self-resolving session flow). See its `README.md`.
- `guidelines/` — foundation specimen cards (Colors / Type / Spacing / Brand).
- `SKILL.md` — Agent-Skills-compatible entry point.

## Do / Don't

| Do | Don't |
|---|---|
| Dark canvas, accents only on action/state/completion | Saturated primaries or red competing for attention |
| One always-visible AI explanation line | Hide the "why" behind a tap |
| Surface tint for elevation (3 levels) | Drop shadows for routine hierarchy |
| Shimmer placeholders matching content | Spinners |
| Quiet completion (gentle ring pulse) | Confetti, badges, sound, "AMAZING JOB!" |
| Contextual, silent Pro prompt | Persistent paywall banner |
| Pair every color with a label/icon/text | Convey state or type by color alone |
| On-Primary dark teal on aqua | White/light text on aqua (banned) |
