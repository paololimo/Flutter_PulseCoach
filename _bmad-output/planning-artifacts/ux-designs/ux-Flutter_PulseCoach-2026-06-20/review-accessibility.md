# Accessibility Review — PulseCoach UX Spines (v2)

Reviewer: Accessibility reviewer (WCAG 2.1 AA + mobile a11y best practice)
Date: 2026-06-20
Scope: `DESIGN.md` (visual identity) + `EXPERIENCE.md` (behavior). Target: VoiceOver/TalkBack full coverage is in-scope for v2 store launch.
Platform context: Flutter, Material 3, dark-first, locale `it`.

All contrast ratios below computed with the WCAG 2.1 relative-luminance formula against the exact tokens in `DESIGN.md`.

---

## 1. Color Contrast

### Computed ratios (dark palette)

| Pair | Ratio | Normal (4.5) | Large/UI (3.0) |
|---|---|---|---|
| On Surface `#E2E4EA` / Surface `#0F1119` | 14.82 | PASS | PASS |
| On Surface Variant `#9498A6` / Surface | 6.55 | PASS | PASS |
| On Surface Variant / Container `#171B26` | 5.98 | PASS | PASS |
| On Surface Variant / Container High `#1E2333` | 5.43 | PASS | PASS |
| Primary aqua `#7DD3C0` / Surface | 10.72 | PASS | PASS |
| Secondary violet `#A78BDA` / Surface | 6.59 | PASS | PASS |
| Tertiary amber `#E8C87A` / Surface | 11.64 | PASS | PASS |
| Coral `#F0A1B0` / Surface | 9.36 | PASS | PASS |
| Error `#F28B82` / Surface | 7.89 | PASS | PASS |

The dark text-on-surface and accent-on-surface system is fundamentally sound. Two real problems:

### [BLOCKER] Button text on Primary aqua fill must be dark, and the spec never says so
Primary aqua `#7DD3C0` is a LIGHT accent. The default Material/instinctive choice — white or `on-surface` light-grey text on the filled Start button — fails catastrophically:
- White `#FFFFFF` on Primary aqua = **1.76:1** (FAIL, needs 4.5)
- On Surface `#E2E4EA` on Primary aqua = **1.38:1** (FAIL)
- Black `#000000` on Primary aqua = **11.95:1** (PASS)
- Surface `#0F1119` on Primary aqua = **10.72:1** (PASS)

The Start button is the single most important action in the core loop. `DESIGN.md.Components` describes "a full-width primary Start button" but specifies no `onPrimary` token. The theme must define `onPrimary` as a dark value (Surface `#0F1119` or near-black). This is the highest-impact contrast risk in the spec — flag it explicitly so it is not left to a default. The same rule applies to the soft-acknowledgement reaction glyph "in `{primary}`" if it ever sits on a light fill, and to any selected RPE button if selection is a filled-aqua treatment with a light label.

### [SHOULD] Define and verify the light-mode accent contrast; v2 raises light mode to "must not look unfinished"
Accents are declared "unchanged" between dark and light. On light surfaces (`#F8FFFE`/`#EEF6F4`) the same aqua/amber/coral will have very different — and likely much lower — contrast as foreground text/icons. `EXPERIENCE.md` itself notes v2 elevates light mode from secondary to store-quality. The light palette accent-on-surface and accent-text pairs are not tabulated anywhere and need their own AA pass before launch. In particular amber `#E8C87A` and coral `#F0A1B0` as text on a near-white surface are at high risk of failing 4.5:1.

### [CONSIDER] On Surface Variant as the signature ExplanationLine color is at the AA floor on the lightest surface
`#9498A6` on Container High = 5.43:1 — passes, but the ExplanationLine ("the product's signature element") is Body Small (13sp). It clears AA comfortably; just confirm it never drops onto an even lighter tint or below 13sp, where headroom disappears. No change required today.

---

## 2. Color Independence

The spines are unusually disciplined here: `DESIGN.md.Do's` and `EXPERIENCE.md.Accessibility Floor` both mandate "pair every color with label/icon/text," and StateIndicator explicitly "always carries a text label beside the color." Session type pairs color with a Lucide glyph + title; completion is `n/3` text; RPE is a number. Good baseline. Remaining gaps:

### [BLOCKER] Podium medals — silver and bronze tokens are non-distinct from ordinary UI colors, and the "rank number always present" rule needs to be load-bearing, not decorative
The medals reuse accent tokens: gold = amber `#E8C87A`, silver = on-surface-variant `#9498A6`, bronze = coral `#F0A1B0`.
- **Silver = `#9498A6` is literally the secondary-text / disabled token.** A color-blind user (and many sighted users) cannot tell a "silver medal" from a greyed-out glyph. There is no chroma to read.
- **Gold (amber) vs bronze (coral):** to a protan/deuteran viewer amber and coral can collapse toward the same muddy yellow-brown. The three medals are not reliably separable by color alone for red-green color-blindness — which is the exact failure WCAG 1.4.1 targets.

The spec's saving grace is "rank number always present." That makes this acceptable ONLY if rank is treated as the primary carrier and the medal as pure decoration. Concretely required:
1. The rank number (Mono) must render for ranks 1–3 too, not be replaced by the medal glyph.
2. The medal glyph must differ in SHAPE or carry a text/numeric label, not differ only in fill color (e.g. distinct glyph or a "1 · oro / 2 · argento / 3 · bronzo" label), so the distinction survives greyscale.
3. Screen readers: medal must be announced as text (see §4), never as an unlabeled colored icon.

If the design keeps an identical glyph in three near-indistinguishable fills, it fails 1.4.1 on its own; the rank number is what rescues it, so the rank number must be mandatory and visually prominent.

### [SHOULD] StateIndicator Fatigued vs Recovering are the same hue (secondary violet, one at 70% opacity)
Active=primary, Fatigued=secondary, AtRisk=tertiary, **Recovering=secondary@70%**. Fatigued and Recovering are the same violet differentiated only by opacity — not distinguishable by color, and opacity differences are unreliable on OLED/varied brightness. The text label is mandatory so 1.4.1 is technically satisfied, but two emotionally different states sharing a hue undercuts the "communicates state" rule. Lean entirely on the label (already required) and consider a distinct glyph per state so the dot is not the differentiator.

---

## 3. Touch Targets (≥48dp)

### [SHOULD] RPE two-row degrade target size is unverified at the trigger width
RPE is "40dp visual / 48dp target," degrading to two rows of five below ~516dp. The degrade preserves count but the spec never confirms the 48dp target is maintained in the two-row layout on the smallest phones (320dp). Ten 48dp targets need 480dp+gaps in one row — hence the degrade — but two rows of five on a 320dp screen (minus 24dp×2 edge padding = 272dp usable) gives ~54dp per cell before gaps, which is tight but feasible. Require an explicit guarantee that the 48dp tap target (not the 40dp visual) holds in both layouts, with adequate spacing so adjacent targets don't overlap (WCAG 2.5.8 target-spacing).

### [SHOULD] Social rows, reaction tap, and QR/join code need stated minimum sizes
`LeaderboardRow`, `FriendRow`, `ActivityFeedCard` reaction tap, and `JoinCodeCard` are new v2 surfaces with no declared touch-target size.
- FriendRow's accept/decline/remove controls and the ActivityFeedCard single reaction tap ("a soft acknowledgement glyph") are small inline affordances — these are the highest risk for sub-48dp targets. Specify ≥48dp explicitly.
- LeaderboardRow: if the whole row is tappable that's fine; if only the avatar/handle is, size it.
- JoinCodeCard: the join code should be selectable/copyable; ensure the copy affordance is ≥48dp.
- VisibilityTierSelector segmented control: 3 segments on `rounded/chip` — confirm each segment ≥48dp tall.

### [CONSIDER] CompactSessionCard is 56dp tall — fine; confirm its chevron isn't the only hit area
56dp row meets target; just ensure the tap target is the full row, not the 24dp chevron.

---

## 4. Screen Reader

`EXPERIENCE.md.Accessibility Floor` commits to full VoiceOver/TalkBack coverage, `Semantics` wrapping, role+state labels, live regions for CountdownOverlay and in-session step transitions, and `ExcludeSemantics` for decorative elements (Lottie, shimmer, ring arc). Strong intent. Gaps to close before that intent is verifiable:

### [BLOCKER] No live region specified for real-time SHARED-session step changes
The spine mandates live regions for the solo CountdownOverlay and in-session step transitions, but the v2 shared-session real-time sync (FR71/NFR31 — "all participants see the same step + timer within ~1s") is NOT listed as needing a live region. For a screen-reader user in a co-located shared session, the step advances because the GROUP advanced — there is no local tap to announce it. Without an explicit `liveRegion: true` (assertive/polite) on the shared step+timer, an AT user is silently left behind while peers move on. This is a v2-specific blocker: add shared-session step changes (and participant ready-state changes / participant-drop events in `SharedSessionLobby`) to the live-region list.

### [SHOULD] Medal semantics must be spoken as rank text, and the row must read coherently
LeaderboardRow is listed as carrying labels "from the start," good. Specify the exact announcement: the medal glyph must be `ExcludeSemantics` (decorative) with the rank conveyed as text — e.g. "1° posto, oro, [handle], [n] punti." Never let a screen reader hit a bare colored icon with no label. Same for the StateIndicator dot (decorative) with the state name in the label.

### [SHOULD] CompletedSessionCard is "excluded from focus order" — verify it is still discoverable, not silenced
`DESIGN.md` and `EXPERIENCE.md` both say CompletedSessionCard is "excluded from focus order." For a sighted user "progress made visible" works; for an AT user, removing completed sessions from traversal can hide the very progress the design wants visible. Recommendation: keep it OUT of interactive/focus order (it's read-only, correct) but ensure it remains reachable in the accessibility tree as a non-interactive labeled element (e.g. "Sessione completata: [type]") — `ExcludeSemantics` would over-hide it. Distinguish "not focusable as a control" from "not present to AT."

### [SHOULD] SignInSheet / ProUpsellSheet / SharedSessionLobby / JoinCodeCard need explicit semantics + modal focus trapping
Listed as carrying labels from the start — good. Add the specifics: each BottomSheet must trap focus (focus moves into the sheet on open, back-gesture/escape announced, focus returns to the triggering control on dismiss). ProUpsellSheet's `Scopri Pro` / `non ora` need role=button + the one-line Pro fact as the accessible context. JoinCodeCard's QR is decorative for AT — the join code text must be the accessible path (a blind user cannot scan a QR), and ideally a "share code" action is exposed.

### [CONSIDER] ActivityFeedCard reaction state
The single reaction tap should announce its toggled state ("hai reagito" / pressed) so an AT user knows the tap registered, since there is deliberately no count shown as feedback.

---

## 5. Reduce Motion / Text Scale

### [SHOULD] Reduce-Motion coverage omits new v2 motion surfaces
The Reduce-Motion rule (durations→0, countdown static, hero/ring instant, shimmer/Lottie static) is written for v1. v2 adds: leaderboard "standard list reveal" animation, shared-session participant chips appearing, real-time step transitions, MiniSummary/ring. Confirm the list reveal and any shared-session entrance animation honor `MediaQuery.disableAnimations` / `reduceMotion`. The medal spec already says "no animation beyond the standard list reveal" — that reveal must still be suppressed under Reduce Motion.

### [SHOULD] Text scale to 2.0× is unverified on dense v2 rows
"Text scale honored to 2.0× without overflow" is the rule. The new dense rows — LeaderboardRow (rank + medal + avatar + handle + points, several Mono numerics + text on one line) and FriendRow — are the most likely to overflow at 2.0×. Mono points + Mono rank + long handle at 200% on a 320dp phone is a real overflow risk. Require these rows to wrap/reflow (not truncate the rank or points) at 2.0×. Timer-numeral 2.0× cap is fine and already specified.

### [CONSIDER] JoinCodeCard "large join code (Mono)" at 2.0×
A large Mono code scaled 2× plus a QR on one card may overflow small phones; confirm reflow.

---

## 6. Cognitive / Affective

The calm, no-pressure ethos is largely an accessibility ASSET: linear in-session flow (no branching), one required input, no time pressure, no shame, plain-language one-line explanations, privacy-by-default. These directly help users with cognitive and anxiety-related disabilities. Two ethos-driven risks:

### [BLOCKER-adjacent → SHOULD] "Silent degradation" can hide important state from AT users
The State Patterns repeatedly prescribe silent degradation: "Sensor/API unavailable → Silent degradation… at most a recessive inline line, never modal," "Locked (Pro)… no badges scattered," "sync issues only in Settings, never blocking." For sighted users this is calm; for screen-reader users a recessive inline line that is visually de-emphasized can be skipped or unannounced, and a silently-degraded plan (e.g. "using saved data") may never reach the user. Requirement: anything that changes what the plan IS or why (degraded data source, AtRisk reduction to 2 sessions, group-adapted downgrade) must be in the accessibility tree as readable text even when visually recessive — calm ≠ inaudible. The "Sto usando i dati salvati" line and the shared-session adaptation reason must be AT-reachable, not just low-contrast decoration.

### [CONSIDER] No-confirmation patterns are good, but RPE "selection is submission" needs an AT-clear label
"One tap = submission, no confirm" is excellent cognitively. For AT, ensure each RPE button's label conveys both value and that tapping submits ("Sforzo 6, tocca per registrare") so a screen-reader user isn't surprised that a single tap is final and dismisses the screen.

### [CONSIDER] AtRisk silent reduction to 2 sessions
Return-after-absence reduces to 2 sessions with an empathetic line and "no counter." Good. Just ensure the empathetic StateIndicator + reason line are announced on Today open (live/polite) so an AT user understands WHY the plan looks lighter, rather than perceiving missing content.

---

## Summary of Findings

| # | Sev | Finding |
|---|---|---|
| 1.1 | BLOCKER | Primary Start button needs DARK `onPrimary` text; white/light-grey on aqua = 1.4–1.8:1 (fails). Spec defines no onPrimary token. |
| 2.1 | BLOCKER | Podium medals not color-distinct (silver = secondary-text grey; amber/coral collapse for red-green CVD). Rank number must be mandatory + prominent; medal must differ by shape/label, not fill alone. |
| 4.1 | BLOCKER | No live region specified for real-time SHARED-session step changes — AT users silently left behind when the group advances. |
| 6.1 | SHOULD | "Silent degradation" must remain AT-reachable as readable text; calm ≠ inaudible. |
| 1.2 | SHOULD | Light-mode accent contrast untabulated; v2 raises light mode to store-quality — amber/coral as text on near-white at risk. |
| 2.2 | SHOULD | Fatigued vs Recovering share violet hue (opacity-only) — lean on label + add per-state glyph. |
| 3.1 | SHOULD | RPE 48dp target must be guaranteed in two-row degrade + target spacing (2.5.8). |
| 3.2 | SHOULD | LeaderboardRow/FriendRow/reaction tap/JoinCodeCard/VisibilitySelector need explicit ≥48dp targets. |
| 4.2 | SHOULD | Medal semantics must speak rank as text; decorative glyph excluded. |
| 4.3 | SHOULD | CompletedSessionCard: out of focus order but keep present/labeled in AT tree. |
| 4.4 | SHOULD | v2 sheets/lobby need focus trapping + QR-is-decorative (code text is the AT path). |
| 5.1 | SHOULD | Reduce-Motion must cover v2 list reveal + shared-session entrances. |
| 5.2 | SHOULD | Text scale 2.0× overflow risk on dense LeaderboardRow/FriendRow — require reflow. |
| 1.3 / 3.3 / 4.5 / 5.3 / 6.2 / 6.3 | CONSIDER | ExplanationLine headroom; chevron hit area; reaction toggle state; JoinCode at 2×; RPE submit label; AtRisk reason announced. |

---

**Verdict:** Strong calm-first foundation with genuinely accessible bones, but NOT store-ready until three blockers are fixed — dark `onPrimary` button text, color-independent podium medals (mandatory rank number), and a live region for real-time shared-session step changes.
