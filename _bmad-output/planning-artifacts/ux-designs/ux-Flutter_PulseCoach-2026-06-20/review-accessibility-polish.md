# Accessibility Review — v1 Experience Polish (2026-07-06 Update)

**Reviewer lens:** consumer-health a11y, WCAG 2.1 AA, against the spines' own Accessibility Floor.
**Scope:** ONLY the three components added in `.decision-log.md` → "Update 2026-07-06": `FactorIconRow`, `ActiveDaysCard`, `MilestoneProgressBar`. Untouched v1/v2 material not re-reviewed.

## Verdict: PASS-WITH-FIXES

The reframes did the hard brand/a11y work well — every new element has a text/semantics equivalent, Reduce-Motion degrades to static, and the finish glow is correctly `ExcludeSemantics`. But two categories of concrete WCAG failure remain in the spec as written: (1) an interactive control (`FactorIconRow` glyph) defined below the mandated ≥48dp touch floor with no hit-area rule and no wrap/overflow rule, and (2) two non-text-contrast failures in `MilestoneProgressBar` where a mark sits over the primary fill. All are fixable in-spine before implementation; none require re-architecting the feature.

Contrast values below computed against the spine tokens (`surface #0F1119`, `on-surface-variant #9498A6`, `primary #7DD3C0`, `tertiary #E8C87A`).

---

## Findings

### [BLOCKER] FactorIconRow — tappable ~16dp glyph is below the ≥48dp touch floor, with no hit-area defined
**Where:** `DESIGN.md` → Components → **FactorIconRow** ("~16dp Lucide glyphs … `sm` (8dp) gap … Each glyph is tappable"); `EXPERIENCE.md` → Component Patterns → FactorIconRow; Accessibility Floor → "Touch targets ≥ 48dp".

The spine mandates ≥48dp touch targets for every interactive element and *explicitly enumerates* v2 surfaces that must comply — but `FactorIconRow` introduces a **new interactive control at ~16dp visual with an 8dp neighbor gap** and never states a larger hit area. As written the effective target is ~16–24dp: a direct violation of the component's own floor, and the 8dp spacing means adjacent glyphs' targets collide (mis-tap risk on the very row meant to be scannable).

There is also a design tension the spec hasn't resolved: up to 5 factors each needing a ≥48dp target = ≥240dp of interactive width *plus* gaps, on a HeroSessionCard that is already dense and already carries StateIndicator + Lottie + title + meta + ExplanationLine + Start button. A row of five 48dp targets will not fit small-phone widths (320–360dp) alongside `lg` (24dp) edge padding.

**Suggested fix (pick one, state it in the spine):**
- **Preferred:** keep the 16dp glyph visual but wrap each in a **≥48dp transparent hit target** (Flutter `min` 48×48 via `ConstrainedBox`/`IconButton` `constraints`), and either (a) allow the row to **wrap to a second line** when targets would overflow, or (b) cap the visible interactive glyphs and move overflow into a single "..." affordance. Add an explicit line: "each glyph exposes a ≥48dp hit target; the row wraps rather than truncates."
- **Alternative (removes the target problem entirely):** make the factors **non-interactive** and render the one-line factor text inline/always-present (or as a single tap on the whole row opening a small sheet listing all applied factors), so no sub-48dp control exists. This also strengthens color-independence since the text is not gated behind a per-icon tap.

### [HIGH] MilestoneProgressBar — step ticks fail 3:1 non-text contrast where they overlap the Primary fill
**Where:** `DESIGN.md` → Components → **MilestoneProgressBar** ("step-boundary tick (2dp, `on-surface-variant`)").

Step ticks are `on-surface-variant` over an `on-surface-variant`-at-low-opacity rail *and*, as the bar fills, over the `primary` aqua fill. Non-text contrast (WCAG 1.4.11, 3:1):
- tick vs unfilled rail/`surface` background: **6.55:1** — passes.
- tick (`on-surface-variant #9498A6`) vs `primary` fill (`#7DD3C0`): **1.64:1** — **fails 3:1.**

So the moment a step is completed, its boundary tick becomes effectively invisible against the fill — exactly when the user most wants to read "which checkpoints are done." A 2dp mark makes this worse at 2.0× and for low-vision users.

**Suggested fix:** render ticks in **`on-primary` (`#06231D`, ~ the dark-teal on-fill token already defined for aqua)** when they sit over the filled portion (that pairing is ~9–12:1), keeping `on-surface-variant` only for ticks over the unfilled rail; or notch the tick as a 2dp gap in the fill (background showing through) so the contrast carrier is the `surface`, not the aqua. Also bump the minimum tick weight so it survives 2.0× (≥2dp is borderline for a thin vertical mark).

### [HIGH] MilestoneProgressBar — "finish reached" state is primary-on-primary (invisible) and distinguished by color alone
**Where:** `DESIGN.md` → Components → **MilestoneProgressBar** ("checkered-flag glyph … `on-surface-variant`) that becomes `{primary}` when reached").

Two problems:
1. **Non-text contrast:** when reached, the flag becomes `primary` and the fill has also arrived (also `primary`) — flag vs fill = **1.00:1**, i.e. the reached-state glyph disappears into the completed fill (and the primary glow compounds it). The very state change the animation celebrates is the least legible.
2. **Color-alone state:** reached-vs-unreached is signalled by `on-surface-variant → primary` (a grey→aqua hue/tint swap). The spine bans color as the sole carrier of meaning. There *is* a redundant cue (the fill physically arriving at the marker) and a semantics equivalent ("finish reached"), which is good — but the *visual* glyph itself shouldn't lean on tint alone, especially under CVD where aqua↔grey lightness is close.

**Suggested fix:** on the reached state, either (a) fill the flag glyph with **`on-primary` dark teal** so it reads *against* the aqua fill (checkered pattern stays visible, ~9:1), or (b) keep the flag on a small `surface` chip/halo so it never sits directly on same-color fill; and add a **shape/state change** (e.g. flag outline → filled checkered) so "reached" is carried by form, not just color. Spine text should say "the reached finish marker changes shape/fill, not hue alone, and maintains ≥3:1 against the fill."

### [HIGH] FactorIconRow — no wrap/overflow or text-scale rule on an already-dense card
**Where:** `DESIGN.md` → Components → **FactorIconRow**; `EXPERIENCE.md` → Accessibility Floor → "Text scale … to 2.0× without overflow".

Every other dense element in the spine is given an explicit "wrap, don't truncate" rule at 2.0× (LeaderboardRow, FriendRow, handle wrap). `FactorIconRow` gets none, yet it is the newest, tightest addition to the most crowded card. Two overflow vectors: (1) the glyph row itself if targets are enlarged per the BLOCKER fix; (2) the **tap-revealed one-line factor text** at 2.0× on a hero card that already stacks title/meta/ExplanationLine/Start — the reveal line can push the Start button or clip. Icons also do not scale with system text scale unless coded to, so at 2.0× the row can look mismatched next to enlarged text.

**Suggested fix:** add to the spine, mirroring the LeaderboardRow rule: "FactorIconRow wraps to multiple lines rather than truncating; the tap-revealed factor text wraps and never overlaps the Start button; the row and its reveal remain within the hero card at 2.0× text scale." Confirm the reveal renders as a wrapping text block, not a fixed-width single line.

### [MED] FactorIconRow — 1.5px strokes on the gradient hero wash: verify 3:1 over the lightest wash stop
**Where:** `DESIGN.md` → Components → FactorIconRow + HeroSessionCard ("soft gradient hero wash").

`on-surface-variant` glyphs clear 3:1 over flat `surface` (6.55:1), but the FactorIconRow sits inside the HeroSessionCard, which is the one place in the app carrying a gradient wash. Thin 1.5px strokes are the least forgiving case for graphical-object contrast. AQI's `tertiary` amber tint is comfortable (**11.64:1** vs surface), so that's fine.

**Suggested fix:** add a one-line constraint: "FactorIconRow glyphs maintain ≥3:1 against the lightest stop of the hero gradient wash." If the wash lightens the local background materially, keep the row below the wash's brightest zone or verify the token holds there.

### [MED] MilestoneProgressBar — aqua-fill-on-grey-rail distinguishability under CVD / at small scale
**Where:** `DESIGN.md` → Components → MilestoneProgressBar ("Primary fill over an `on-surface-variant`-at-low-opacity rail").

Fill (`primary`) vs `surface` background is strong (10.72:1), and vs a full-opacity `on-surface-variant` rail is only 1.64:1 — but the rail is specified at *low opacity*, which raises separation against `surface`. The progress fill (as a meaningful graphical object indicating position) should keep ≥3:1 against the adjacent rail so a protanope/deuteranope can see where fill ends. This is close enough to warrant an explicit check rather than a failure.

**Suggested fix:** specify the rail opacity such that `primary` fill vs rail ≥3:1, or add a hairline `on-primary`/`surface` edge where fill meets rail. Note in the spine that fill boundary legibility must not depend on aqua↔grey hue discrimination alone (lightness delta carries it).

### [LOW] ActiveDaysCard — clean; confirm caption ≥ Caption 11sp and count is not the sole carrier
**Where:** `DESIGN.md` → Components → ActiveDaysCard; `EXPERIENCE.md` → Accessibility Floor.

This component is the strongest of the three: text/semantics equivalent is explicit ("reads its count as text 'Attivo da N giorni'"), 0/1 renders identically (no color/shape-alone state), `on-surface-variant` caption clears AA (6.55:1), and no animation beyond the standard reveal. Only housekeeping: ensure the caption label is not rendered below **Caption 11sp** (the spine's stated floor) at any scale, and that the Mono count is never the *sole* carrier of the value for AT — the accompanying "Attivo da N giorni" text already satisfies this, so keep them in a single semantics node so a screen reader reads one coherent string, not "4" then "giorni attivi" split.

---

## Confirmed-good (no action)
- **Text/semantics equivalents:** all three components get one (factor-per-glyph label, ActiveDaysCard count-as-text, MilestoneProgressBar step position + "finish reached"). Color-independence intent is correctly stated for FactorIconRow (shape-distinct glyph + tap text + label; AQI amber redundant).
- **Reduce-Motion:** finish-marker micro-animation and glow → static filled/flagged state; NFR38 60fps/degrade noted. Correct.
- **Decorative exclusion:** finish-marker glow uses `ExcludeSemantics`. Correct.
- **AQI amber tint:** redundant emphasis only, never sole carrier; contrast 11.64:1. Correct.
