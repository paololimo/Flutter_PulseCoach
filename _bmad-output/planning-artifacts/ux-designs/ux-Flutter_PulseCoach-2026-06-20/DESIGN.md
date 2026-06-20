---
name: PulseCoach
description: Adaptive AI movement companion. Dark-canvas, living-accents. Calm energy, never gym aggression. No streaks, no badges, no exclamation marks. v1 free/offline core + v2 optional accounts, Pro, and calm social.
status: final
updated: 2026-06-20
sources:
  - {planning_artifacts}/ux-design-specification.md
  - {planning_artifacts}/prd.md
  - pulse_coach/lib/core/theme/pulse_coach_theme.dart
colors:
  surface: '#0F1119'
  surface-container: '#171B26'
  surface-container-high: '#1E2333'
  primary: '#7DD3C0'
  on-primary: '#06231D'
  secondary: '#A78BDA'
  tertiary: '#E8C87A'
  on-surface: '#E2E4EA'
  on-surface-variant: '#9498A6'
  error: '#F28B82'
  accent-cardio: '#F0A1B0'
  surface-light: '#F8FFFE'
  surface-container-light: '#EEF6F4'
  surface-container-high-light: '#E1F0ED'
  on-surface-light: '#1A1C1E'
  on-surface-variant-light: '#42474E'
  error-light: '#BA1A1A'
  medal-gold: '#E8C87A'
  medal-silver: '#9498A6'
  medal-bronze: '#F0A1B0'
typography:
  display:
    font: 'Plus Jakarta Sans'
    weight: 600
    size: 28sp
    line: 1.2
  h1:
    font: 'Plus Jakarta Sans'
    weight: 600
    size: 24sp
    line: 1.25
  h2:
    font: 'Plus Jakarta Sans'
    weight: 600
    size: 20sp
    line: 1.3
  h3:
    font: 'Plus Jakarta Sans'
    weight: 500
    size: 17sp
    line: 1.35
  body:
    font: 'Plus Jakarta Sans'
    weight: 400
    size: 15sp
    line: 1.5
  body-small:
    font: 'Plus Jakarta Sans'
    weight: 400
    size: 13sp
    line: 1.45
  caption:
    font: 'Plus Jakarta Sans'
    weight: 400
    size: 11sp
    line: 1.4
  timer-display:
    font: 'JetBrains Mono'
    weight: 400
    size: 48sp
    line: 1.0
  timer-secondary:
    font: 'JetBrains Mono'
    weight: 400
    size: 24sp
    line: 1.0
  rpe-numbers:
    font: 'JetBrains Mono'
    weight: 400
    size: 20sp
    line: 1.0
  countdown:
    font: 'JetBrains Mono'
    weight: 400
    size: 72sp
    line: 1.0
rounded:
  chip: 8px
  button: 12px
  card: 16px
  full: 9999px
spacing:
  xs: 4dp
  sm: 8dp
  md: 16dp
  lg: 24dp
  xl: 32dp
  2xl: 48dp
components:
  - HeroSessionCard
  - CompactSessionCard
  - CompletedSessionCard
  - InSessionView
  - CountdownOverlay
  - CompletionRing
  - RPEInput
  - StateIndicator
  - ExplanationLine
  - MiniSummary
  - SignInSheet
  - ProUpsellSheet
  - FriendRow
  - ActivityFeedCard
  - LeaderboardRow
  - SharedSessionLobby
  - JoinCodeCard
  - VisibilityTierSelector
---

> **Identity reference for PulseCoach.** This file owns *how it looks*; `EXPERIENCE.md` owns *how it works* and references these tokens by name. Both spines win on conflict with any mock or import. Dark mode is the default surface; light is a setting. v1 tokens are ground-truthed against the live theme (`pulse_coach/lib/core/theme/pulse_coach_theme.dart`); v2 entries marked `[ASSUMPTION]` extend the same system and need confirmation in review.

## Brand & Style

PulseCoach is the calm counter-statement to the fitness category. Where most movement apps shout — bright reds, streak counters, "AMAZING JOB!", push nudges at 10pm — PulseCoach is quiet on purpose. The product decides, explains in one line, executes as a ritual, and resolves itself. The visual language is "Calm meets Oura": a premium wellness companion, not a personal trainer behind glass.

The governing metaphor is **dark canvas, living accents**. The dark surface is a restful canvas; color appears only where action, state, or completion lives. Color is never decorative. Generous whitespace, soft rounded geometry, and a calm motion register carry the brand more than any single element. There is **one emotional temperature across every screen, and it never raises its voice** — no screen is louder or more energetic than another, and that discipline holds even where v2 introduces accounts, a paywall, and social.

**v2 holds the line.** Accounts, the Pro upsell, friends, and the leaderboard inherit the same calm. The paywall is contextual and silent (never a persistent banner). The leaderboard shows ranking among friends with restrained podium medals — recognition, not a trophy room. Social adds warmth (training *together*), never competitive pressure.

## Colors

The palette is restrained by rule: every colored element either **invites action** (primary), **communicates state** (secondary / tertiary), or **confirms completion** (primary). Nothing colored is purely decorative.

**Surfaces (dark, default):**
- **Surface (`#0F1119`)** — primary background. Near-black with a cool blue undertone; avoids OLED pure-black harshness.
- **Surface Container (`#171B26`)** — cards and elevated surfaces. A subtle tonal lift, not a shadow.
- **Surface Container High (`#1E2333`)** — active / selected states, input fields. One step lighter.

**Accents:**
- **Primary — Aqua (`#7DD3C0`)** — the action color: Start button, completion ring, active indicators, Mobility session accent. Energetic but calm. Used sparingly. **Aqua is a *light* accent** — text/icons placed *on* primary (e.g. the Start button label) MUST use **On Primary (`#06231D`)**, the dark teal (~12:1). White or light-grey on aqua fails contrast (~1.4–1.8:1) and is banned.
- **Secondary — Violet (`#A78BDA`)** — behavioral states (Fatigued; Recovering at 70% opacity), Breathing session accent, secondary actions.
- **Tertiary — Amber (`#E8C87A`)** — AtRisk state, AQI/attention items. Visible without alarming. *Never* used as a generic warning fill.
- **Cardio — Soft Coral (`#F0A1B0`)** — Cardio session accent and the in-session HR value. Warm energy without red-alarm association.

**Text:**
- **On Surface (`#E2E4EA`)** — primary text. Not pure white (reduces eye strain on dark). ~15:1 on Surface (AAA).
- **On Surface Variant (`#9498A6`)** — secondary text, captions, and the always-visible AI explanation lines. Readable but recessive. ~6.5:1 on Surface (AA).
- **Error — Soft Red (`#F28B82`)** — genuine errors only, used sparingly. Never for shame, never for warnings.

**Light mode (secondary, real values in code):** Surface `#F8FFFE`, Container `#EEF6F4`, Container High `#E1F0ED`, On Surface `#1A1C1E`, On Surface Variant `#42474E`, Error `#BA1A1A`. Same accents (primary/secondary/tertiary unchanged). Dark is the default and demo mode; v2's store launch raises light-mode polish from "secondary" to "must not look unfinished". **Caution (a11y):** the accents (aqua/amber/coral) are light and **fail as text colors on the near-white light surface** — in light mode use them only as fills with On Primary / dark text, or for icons/graphics meeting 3:1, never as small body text. A full light-mode contrast table is owed before light mode ships (`[NOTE FOR UX]`).

**Podium medals (v2, leaderboard top-3):** to stay inside the calm palette, medals reuse existing accent tokens rather than introducing saturated trophy colors — **gold = tertiary amber (`#E8C87A`)**, **silver = on-surface-variant (`#9498A6`)**, **bronze = coral (`#F0A1B0`)**. No metallic gradients, no shine, no animation beyond the standard list reveal.
> **Color-independence (required, per a11y review):** medals must NOT rely on fill alone — silver collides with the disabled/secondary-text grey, and amber↔coral collapse under red-green color-vision deficiency. So: (1) the **rank number is always present and prominent** (Mono, the primary carrier of standing); (2) the medal is a **distinct-shaped glyph** (🥇🥈🥉 differ by shape/ordinal) carrying a **text/semantic label** ("1° — oro / 2° — argento / 3° — bronzo"); (3) color is the third, redundant cue, never the only one.

**Avoid:** bright/saturated primaries competing for attention; red for anything but genuine errors; gradients except the single soft hero-zone wash on Today; color as the sole carrier of meaning (always pair with label/icon/text).

## Typography

**Pairing: Plus Jakarta Sans (everything readable) + JetBrains Mono (everything numeric).**

Plus Jakarta Sans is a geometric sans with slightly rounded terminals — warm and modern without being generic (Inter) or trendy (Satoshi). It carries display, headings, body, and captions. JetBrains Mono is reserved **exclusively** for numbers and timers — the timer countdown, the 3-2-1 countdown, RPE digits, in-session HR. Monospace there reads as precision and intent, never "developer tool". Mono is never used for body text.

Scale (phone): Display 28 / H1 24 / H2 20 / H3 17 / Body 15 / Body Small 13 / Caption 11. Numeric: Timer Display 48 / Timer Secondary 24 / RPE 20 / Countdown 72 (the largest text in the app). **Tablet: all sizes +~20%** (Body→17, H1→28, Timer→56). Nothing smaller than Caption 11sp anywhere. System text scale is honored to 2.0× (Timer numerals capped at 2.0× to protect small-phone layout).

No all-caps display, no exclamation marks anywhere in type. Section labels like "COMING UP" / "PROSSIME" are the one small-caps tracking exception (caption weight).

## Layout & Spacing

**Base unit 8dp.** Scale: `xs` 4 / `sm` 8 / `md` 16 / `lg` 24 / `xl` 32 / `2xl` 48. Largest gaps separate unrelated groups and frame screen titles; smallest sit between tightly related elements (icon↔label, caption lines).

**Density: airy.** Content breathes. Cards carry `md` (16dp) internal padding; cards are separated by `md` (16dp); screen edges use `lg` (24dp) horizontal padding. The impression is calm and uncluttered — the Oura/Calm reference, not a dashboard.

**Grid:**
- **Phone (<600dp):** single column, full-width cards.
- **Tablet (≥600dp):** 12-column. Today uses a ~60/40 master-detail split (hero left, Coming Up + ring right); Progress uses a dashboard grid; Sessions uses a 2-column card grid per category.
- **In-session (any):** single centered column, no grid — focused and immersive.

**Today (phone) vertical rhythm:** State bar → Hero card (above the fold, zero-scroll) → COMING UP list → CompletionRing (secondary). The first/hero session is always visible without scrolling; the rest require a light scroll by design.

## Elevation & Depth

Shadows are nearly invisible on dark surfaces, so **elevation is expressed as surface tint, not shadow.** Three levels only: base `surface` → `surface-container` (cards) → `surface-container-high` (active/selected, inputs, modals over a scrim). Hierarchy otherwise comes from layout and typography. Shadows are reserved for the rare literal-physical moment, never for routine hierarchy. The Today hero zone carries a single soft gradient wash — the only gradient in the app.

## Shapes

Consistently rounded; **no sharp corners anywhere.**
- `rounded/card` (16dp) — cards, sheets, the in-session surface. Softer than Material's 12dp default, matching the Oura/Calm feel.
- `rounded/button` (12dp) — filled and text buttons.
- `rounded/chip` (8dp) — chips, inputs, segmented controls, join-code field.
- `rounded/full` — completion ring, RPE buttons, state dots, friend avatars, medal glyphs.

Imagery and Lottie containers follow the corner radius of their card exactly.

## Components

Visual specs. Behavioral rules live in `EXPERIENCE.md.Component Patterns`. Rendered key-screen references (Today, In-Session, Social/Leaderboard+Feed, Pro upsell, Shared-session lobby): [`mockups/key-screens.html`](mockups/key-screens.html). The spine wins on conflict with any mock.

**v1 — Core (custom, identity-defining):**
- **HeroSessionCard** — `surface-container`, `rounded/card`, soft gradient hero wash. Holds StateIndicator badge (top-left), Lottie session-type icon (top-right, 32dp), title (H2), meta row (duration · indoor/outdoor · intensity, caption), ExplanationLine (always visible), and a full-width primary Start button.
- **CompactSessionCard** — `surface-container`, 56dp tall. Session-type dot + title + meta (caption) + chevron. The "COMING UP" list item.
- **CompletedSessionCard** — muted (`on-surface-variant`), checkmark, no Start. Stays visible (progress made visible), excluded from focus order.
- **InSessionView** — full-screen `surface`, no AppBar/nav. Centered Timer Display (Mono 48), current step (H2 + Body), Primary `LinearProgressIndicator`, HR top-right (Mono, coral), "End session" recessive at bottom.
- **CountdownOverlay** — full-screen, Countdown numeral (Mono 72) over `surface`. The 3-2-1 ritual; calm, no aggressive color.
- **CompletionRing** — full-round Primary arc. Small/secondary on Today (shows n/3); its emotional pulse belongs to the post-session summary, not Today.
- **RPEInput** — single row of 10 full-round buttons (Mono 20). 40dp visual / 48dp target; degrades to two rows of five below ~516dp available width. Selection *is* submission — no submit button.
- **StateIndicator** — chip-like, state-colored (Active=primary, Fatigued=secondary, AtRisk=tertiary, Recovering=secondary@70%). Always carries a text label beside the color.
- **ExplanationLine** — Body Small in `on-surface-variant`. The one-line AI reason; styled distinctly but quiet. The product's signature element.
- **MiniSummary** — centered auto-dismissing overlay (3s): type + duration + RPE + one feedback line; CompletionRing animates here.

**v1 — Material 3 (structural, theme-tokens only):** `NavigationBar`, `NavigationRail`, `AppBar`, `Card`, `FilterChip`, `FilledButton`, `TextButton`, `BottomSheet`, `Switch`, `SnackBar` (no action button), `Dialog` (destructive only), `LinearProgressIndicator`, `PageView`. **Not used:** Material Icons (→ Lucide), `Slider` (→ RPEInput), `FloatingActionButton`, M2 `BottomNavigationBar`, `TabBar`.

**v2 — Accounts & Pro `[ASSUMPTION]`:**
- **SignInSheet** — `surface-container-high` BottomSheet. Three calm options stacked: Continua con Apple, Continua con Google, Email. No imagery, no marketing. Always reachable, never forced (v1 works without it).
- **ProUpsellSheet** — compact `surface-container-high` sheet shown *only* on a locked-feature tap. One calm line stating what's Pro + primary `Scopri Pro` + recessive `non ora`. No persistent badges anywhere else. Primary accent used once.

**v2 — Social `[ASSUMPTION]`:**
- **FriendRow** — full-round avatar + handle (Body) + status/action (request accept/decline, or "co-located" badge). Hairline divider, no fill.
- **ActivityFeedCard** — `surface-container`. Friend's shared completion: avatar + handle + one-line session summary (type · duration) + relative time (caption). No biometric detail, ever. Supports **light reactions** (a single calm encouragement tap, e.g. a soft acknowledgement glyph in `{primary}`) — no free-text comments, no reaction counts shown as pressure.
- **LeaderboardRow** — **rank number (Mono) is the primary carrier of standing** + shape-distinct medal glyph w/ label for top-3 + avatar + handle + points (Mono). Current user's row uses `surface-container-high`. No "overtaken" treatment, no biometric detail, **no points-delta toast/animation** (points settle silently). A small caption notes shared sessions earn more points. Min row height honors 48dp; remains legible at 2.0× text scale (wrap, don't truncate the handle).
- **SharedSessionLobby** — `surface` full-screen. Participant chips (avatar + name + ready state), the group-adapted plan preview, a one-line adaptation explanation ("Adattata per tutti — intensità più bassa comoda, niente carico sul ginocchio"), shared Start.
- **JoinCodeCard** — `surface-container`, `rounded/card`. Large join code (Mono) + QR. Calm, no countdown pressure.
- **VisibilityTierSelector** — segmented control (`rounded/chip`): Privato (default) / Solo amici / Per elemento. Privacy-by-default is visually pre-selected.

## Do's and Don'ts

| Do | Don't |
|---|---|
| Dark canvas, accents only on action/state/completion | Saturated primaries or red competing for attention |
| One always-visible AI explanation line per recommendation | Hide the "why" behind a tap |
| Surface-tint for elevation (3 levels) | Drop shadows for routine hierarchy |
| Shimmer placeholders matching the content layout | `CircularProgressIndicator` / spinners |
| Quiet completion: ring closes with a gentle pulse | Confetti, badges, sound, "AMAZING JOB!" |
| Contextual, silent Pro prompt on locked-feature tap | Persistent paywall banner or proactive popups |
| Restrained podium medals reusing accent tokens | Metallic-gradient trophies, shine, celebration animation |
| Friends-only ranking + points | Global boards, biometric detail, "you've been overtaken" |
| Pair every color with a label/icon/text | Convey state or type by color alone |
| One emotional temperature on every screen | A louder screen for upsell or social |
