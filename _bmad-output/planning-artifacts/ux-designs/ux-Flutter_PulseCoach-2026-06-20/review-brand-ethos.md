# Brand-Ethos Consistency Review — v2 Social & Monetization

**Reviewer role:** Brand-ethos consistency reviewer
**Date:** 2026-06-20
**Subjects:** `DESIGN.md`, `EXPERIENCE.md` (v2 additions: optional accounts, Pro paywall, calm social suite)
**Ethos source of truth:** `ux-design-specification.md` — Emotional Design Principles (§191–201), Anti-Patterns (§259–289), Emotional Journey (§144–201).

## The v1 contract being stress-tested

Five load-bearing principles from the v1 spec:

1. **Silence is a feature** — "The absence of noise — no badges, no streaks, no push notifications, no celebration screens — is itself a design choice that communicates respect." (§193)
2. **Competence over congratulation** — "Never celebrate the user — empower them." (§195)
3. **Empathy without guilt** — absence is physiological data, not failure; no shame, no comparison pressure. (§51, §264)
4. **Consistency of emotional temperature** — "No screen is louder or more energetic than any other. The app has one emotional voice, and it never raises it." (§201)
5. **Counter-metrics (PRD):** gamification must NOT increase sessions started in AtRisk/Recovering, must NOT push RPE above ~6.5, free-tier retention must not drop after the paywall.

The spines are unusually self-aware: DESIGN.md §125–127 and EXPERIENCE.md §161 explicitly name the Strava trap and pre-commit to guardrails. Most of the design is defensible. The failures are concentrated in **one structural gap (AtRisk × social) and two emotional-temperature leaks.**

---

## Finding 1 — Leaderboard + podium medals

**[OK-WITH-GUARDRAIL]** — the *framing* is reconcilable, but one mechanic actively fights the counter-metric.

What's right: friends-only (no global board), no "overtaken" alerts (EXPERIENCE §76, §105), medals reuse existing accent tokens with "no metallic gradients, no shine, no animation beyond the standard list reveal" (DESIGN §151). That is genuinely restrained — recognition, not a trophy room. Color-independence is preserved (rank number always present, §136). This survives "competence over congratulation" *as a visual object*.

The leak is **structural, not visual.** EXPERIENCE §76, §161 and Flow 5 §194 establish that **shared sessions earn MORE points than solo**, and the leaderboard surfaces a running points total. A points economy that rewards a *specific behavior* (training with others, more often) is exactly the engagement lever the counter-metrics forbid — it creates a standing incentive to start sessions for points rather than readiness. The "shared > solo" rule was presumably chosen to bias toward *together* over *more*, but it still resolves to *more sessions, ranked publicly among peers*. That is comparison pressure with extra steps.

This is not yet a [BETRAYAL] because the board is friends-only and the medals are quiet — but the points mechanic is the single most likely place overtraining and comparison anxiety leak in.

**Proposed spine edits:**
- DESIGN §217 / EXPERIENCE §76: add — *"Points are never shown as a delta, trend, or 'X to overtake'; only an absolute rank position. No points-earned toast or animation after a session (MiniSummary stays points-silent)."* This keeps points off the dopamine loop.
- EXPERIENCE §161 / §76: add explicit decay/cap reasoning — *"Points reflect participation, not volume: cap the per-day points contribution so a 4th or 5th session cannot climb the board. The board rewards showing up, not grinding."* A per-day cap directly defends "must not raise session starts."
- See Finding 4 for the AtRisk interaction, which is the larger leaderboard risk.

---

## Finding 2 — Pro paywall ("contextual & silent")

**[OK-WITH-GUARDRAIL]** — the claim mostly holds; close two small leaks.

What's right: ProUpsellSheet "appears only on a locked-feature tap" (EXPERIENCE §73, §122), explicit ban on persistent banners and proactive popups (DESIGN §231, EXPERIENCE §105), `non ora` always offered, the counter-metric guardrail against scarcity/FOMO framing is written in (§123), and Flow 4 ends "No badge appears anywhere else afterward" (§187). This is a faithful reading of "silence is a feature."

Two leaks against the *absolute* "no badges/locks scattered" promise:

- **The soft lock glyph.** EXPERIENCE §92 permits "a soft lock glyph only at the feature itself." A persistent lock icon sitting on the "Storico completo" affordance *is* a small standing visual reminder of what you can't have — a quiet badge of absence on a Free screen. v1's silence promise is specifically about what the app *doesn't* show. This is the closest thing to a betrayal in the paywall design and it's currently waved through with `[ASSUMPTION]`.
- **Repeat-prompt cadence is unspecified.** "Only on tap" prevents proactive popups, but nothing stops the sheet re-firing every single time a user taps the locked feature. A user who taps "Storico" weekly to check gets the upsell weekly — that reads as nagging even though each instance is technically contextual.

**Proposed spine edits:**
- EXPERIENCE §92: change to — *"No lock glyph on the affordance; the locked feature looks normal and reveals its Pro status only on tap (the sheet is the only place the paywall exists). Silence over signage."* If a lock affordance is deemed necessary for discoverability, downgrade it to a single recessive caption, never an icon-badge.
- EXPERIENCE §73 / §122: add — *"After `non ora`, suppress the upsell for the same feature for a cooldown window (e.g. one session of the same day); never show the same sheet twice in one session. Conversion comes from value reached, not repetition."*

---

## Finding 3 — Feed reactions ("light encouragement tap")

**[OK-WITH-GUARDRAIL]** — calm by construction, but the asymmetry of *receiving* is under-specified.

What's right: single encouragement tap, **no free-text comments**, and explicitly **"no reaction counts shown as pressure"** (DESIGN §216, EXPERIENCE §75). Killing free-text and visible counts removes the two classic social-validation loops (comment threads, like-count chasing). This is a thoughtful read of the problem.

The residual risk is the *receiver* side, which the spines describe only from the sender's view. Even without a visible count, the **arrival** of reactions is a validation signal. If reactions generate any notification, or if a user's own shared card displays "Marco and 2 others acknowledged this," you've rebuilt the validation loop the count-ban was meant to prevent — and v1 has *zero* push by design (§267, §105). "No counts shown as pressure" is doing a lot of unexamined work: shown *to whom*? A 0-reaction card next to a 5-reaction card is itself a comparison, even if no integer is printed.

**Proposed spine edits:**
- EXPERIENCE §75 / DESIGN §216: add — *"Reactions are sender→receiver private acknowledgements: the receiver sees that they were encouraged, but no aggregate, no reactor list ranking, and never a push notification (v1's zero-push promise holds for social). A card with no reactions and a card with many look identical in the feed; the absence of a reaction is never legible as a deficit."*
- Confirm in review: reactions must not feed any score or leaderboard input (otherwise they become a second points lever — re-routes back to Finding 1).

---

## Finding 4 — AtRisk / Recovering states × social  ⚠ PRIMARY GAP

**[BETRAYAL]** as currently written — by omission. This is the most serious finding.

The single most important v1 promise is **empathy without guilt during recovery**: when the user is Fatigued/AtRisk/Recovering, the app *protects* them, reduces the plan (AtRisk → 2 sessions, EXPERIENCE §88), and never pushes. The PRD counter-metric is explicit: gamification must **not increase sessions started while AtRisk/Recovering.**

Yet **nothing in either spine suppresses social pressure during a protective state.** Concretely, today's design permits:
- A user in **AtRisk** opening Social and seeing themselves drop on the friends leaderboard (because protective rest = fewer points = lower rank) — turning recovery into a *visible ranking penalty*. This is precisely the "missed-streak shaming" anti-pattern (§264) reincarnated as a leaderboard slide.
- A friend sending a **shared-session join code** (Flow 5) to someone the app has just put into AtRisk — the social pull to "show up together" (the explicit emotional climax of §194, "the session became the reason both showed up") directly contradicts the on-device decision to rest them.
- **Feed reactions / activity** nudging a recovering user back into training to stay socially present.

The two subsystems were designed in isolation: the state machine protects, the social layer pulls, and no rule mediates the conflict. When they collide, the social layer wins by default — a textbook betrayal of the recovery-empathy promise and a direct hit on the AtRisk counter-metric.

**Proposed spine edits (new subsection — this is the missing guardrail):**

Add to EXPERIENCE.md, "Shared Session & Real-Time Patterns" or a new **"Protective-State Social Suppression"** block:

> *"**Recovery overrides social, always.** While the user's behavioral state is AtRisk or Recovering, the social layer goes quiet to match the protective plan:*
> *- The leaderboard is **frozen for that user**: their rank does not fall due to reduced activity, and protective rest never reads as a ranking penalty. (Surface a single calm line if they open it: 'In recupero — la classifica ti aspetta.')*
> *- **No shared-session prompts or join nudges** are surfaced to an AtRisk/Recovering user; if a friend sends a code, joining is allowed but the lobby shows the same protective adaptation and the lower individual cap still applies (existing FR9/FR70 union rule already supports this — make it explicit).*
> *- The MiniSummary and feed never frame a light/skipped recovery session as a lost point or missed share.*
> *This is the social-layer expression of the v1 rule 'absence is data, not failure.'"*

Also add to DESIGN §235 Do/Don't: *"Social goes quiet in AtRisk/Recovering | A leaderboard slide or join-nudge during protective rest."*

Without this block, the spines cannot honestly claim to protect the AtRisk counter-metric.

---

## Finding 5 — Consistency of emotional temperature

**[OK-WITH-GUARDRAIL]** — DESIGN.md is disciplined; one screen and one flow line run hot.

What's right: DESIGN §125 restates "one emotional temperature… never raises its voice… that discipline holds even where v2 introduces accounts, a paywall, and social," and §235 bans "a louder screen for upsell or social." The medal palette, no-shine rule, and contextual paywall all hold temperature.

Two places run warmer than v1's register:

- **Flow 5 climax (EXPERIENCE §194):** "the shared session lands on the friends leaderboard worth **more** than a solo one; Giulia (3rd, bronze medal)…" — this prose is celebratory and competition-framed in a way no v1 flow climax is. v1 climaxes are deliberately flat: "Done. Adjusting intensity tomorrow," "the circle closes." Tying the emotional payoff to *ranking position and bonus points* imports the Strava temperature the same document rejects 30 lines later (§161). The intended payoff — "trained with her nephew at a level that fit her" (the *together*) — is the right, on-brand note; the points/medal framing is the off-brand one riding alongside it.
- **SharedSessionLobby** (DESIGN §218): a full-screen `surface` with participant chips, ready-states, and a shared Start is inherently more energetic than the solo flow's quiet auto-promotion. Defensible (group coordination needs presence) but it is the one screen most at risk of a "loud" feel; needs an explicit calm constraint so it doesn't drift into a hype-y lobby.

**Proposed spine edits:**
- EXPERIENCE §194: rewrite the climax to lead with togetherness and drop the points/medal as the reward — e.g. *"…Giulia just trained with her nephew at a level that fit her. The session became the reason both showed up — no pressure, only the pull of doing it together."* (Strike "worth more than a solo one" and "3rd, bronze medal" from the emotional climax; the mechanic can stay documented in §76, just not as the payoff.)
- DESIGN §218: add — *"Same calm register as the solo flow: no countdown pressure (already noted for JoinCodeCard), no 'everyone's ready!' energy, ready-states are quiet dots, shared Start uses the standard primary button. The lobby is a quiet room two people enter together, not an event."*

---

## Summary table

| # | Area | Tag | Core issue |
|---|------|-----|-----------|
| 1 | Leaderboard / points | OK-WITH-GUARDRAIL | "shared > solo" points = standing incentive to start more; add per-day cap + no points toast/delta |
| 2 | Pro paywall | OK-WITH-GUARDRAIL | persistent lock glyph = quiet badge of absence; repeat-prompt cadence unspecified |
| 3 | Feed reactions | OK-WITH-GUARDRAIL | receiver-side validation loop + push under-specified; keep zero-push, no aggregate |
| 4 | **AtRisk × social** | **BETRAYAL (by omission)** | no rule mediates protect-vs-pull; leaderboard slide + join nudges shame recovery. **Add protective-state suppression block.** |
| 5 | Emotional temperature | OK-WITH-GUARDRAIL | Flow 5 climax + SharedSessionLobby run hot; reframe payoff to *together*, constrain lobby |

---

## Verdict

**One betrayal-by-omission (no recovery-state social suppression) and one structural risk (shared>solo points) must be fixed; with those guardrails written in, v2 preserves the v1 ethos.**
