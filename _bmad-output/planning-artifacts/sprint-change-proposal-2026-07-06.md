# Sprint Change Proposal — FR81 / NFR38 Alignment

- **Date:** 2026-07-06
- **Author:** Paolo (via Correct Course workflow)
- **Trigger type:** PRD scope alignment (artifact conflict)
- **Mode:** Batch
- **Scope classification:** Minor (documentation-only; no story exists yet)

---

## 1. Issue Summary

FR81 ("active-days" indicator on the Today tab) was authored in the 2026-07-06 "Experience Polish (v1)" PRD update with a **consecutive-calendar-day, reset-to-zero** definition. During the parallel UX pass (`ux-designs/ux-Flutter_PulseCoach-2026-06-20/`), the brand-ethos review flagged that a consecutive counter that snaps to zero after a rest day is — definitionally — the "streak" guilt mechanic the product explicitly bans ("empathy without guilt", "silence is a feature", "absence is physiological data, not failure").

The UX contract was consequently changed (Paolo's decision, recorded in the UX `.decision-log.md` entry of 2026-07-06) to a **non-resetting rolling 30-day window**: "N giorni attivi negli ultimi 30". A rest day silently ages out of the window; there is no snap-to-zero.

The UX decision log closed with an explicit flag: *"⚠️ FR81 needs a matching PRD correct-course — its current text ('consecutive calendar days… resets to zero') now diverges from the UX contract."* This proposal resolves that single open divergence.

**Evidence:**
- `prd.md:645` (FR81) — current "consecutive… resets to zero" text.
- `prd.md:693` (NFR38) — lists FR81 among "animated elements", contradicting the UX spec (ActiveDaysCard has "no animation beyond the standard card reveal").
- `ux-designs/.../DESIGN.md:132, :216, :243` — windowed 30-day definition, source of truth.
- `ux-designs/.../EXPERIENCE.md:70, :95, :112, :178` — windowed, non-streak framing.
- `ux-designs/.../.decision-log.md:80` — the reframe decision + correct-course flag.
- `ux-designs/.../review-brand-ethos-polish.md` — [HIGH] finding driving the change.

---

## 2. Impact Analysis

- **Epic impact:** None. FR81 is new (2026-07-06) and has **not yet been decomposed into any epic/story**. No sprint is in flight for it. (`epics.md:1652` mentions "streak" but refers to the separate, pre-existing **Progress** timeline epic — out of scope; see §6.)
- **Story impact:** None (no FR81 story exists).
- **Artifact conflicts:**
  - **PRD — FR81:** must be rewritten to the windowed 30-day, non-resetting definition. **(Required)**
  - **PRD — NFR38:** must drop FR81 from the "animated elements" enumeration (ActiveDaysCard is not animated) and remove residual "streak" wording. **(Required)**
  - **PRD — frontmatter `v1PolishUpdate.signal`:** contains "Today active-days streak" — minor terminology alignment. **(Optional)**
  - **`addendum.md` — FR81 mechanism note:** describes single-source-of-truth reuse; add a one-line "windowed 30-day" clarification for terminology consistency. **(Optional)**
  - **`.decision-log.md`:** append a resolution entry closing the flagged item. **(Housekeeping)**
- **Architecture impact:** None. The mechanism (reuse the FR23 activity signal; no parallel counter) is already deferred to architecture in `addendum.md` and is unchanged by the consecutive→windowed reframe.
- **UX impact:** None — UX is the source of truth being aligned to (already updated).
- **Technical impact:** None yet (no code). The windowed definition is if anything simpler to reconcile than a consecutive counter (no midnight reset job).

---

## 3. Recommended Approach

**Option 1 — Direct Adjustment.** Edit FR81 and NFR38 text in place; no renumbering, no new/removed requirements.

- **Rationale:** The change is a pure documentation alignment to a decision already ratified in the UX contract. No implementation exists to roll back (Option 2 N/A), and MVP scope is unchanged (Option 3 N/A).
- **Effort:** Low. **Risk:** Low. **Timeline impact:** None.

---

## 4. Detailed Change Proposals

### 4.1 PRD — FR81 (`prd.md:645`) — REQUIRED

**OLD:**
> - **FR81:** The Today tab displays a visible "active-days streak" — the count of consecutive calendar days (device local timezone) with at least one completed session — as a motivational element. The streak increments on the first completed session of a new local calendar day and resets to zero once a full local calendar day passes with no completed session. `[ASSUMPTION]` The streak reuses the underlying activity signal already tracked by the behavioral state machine (FR23) rather than introducing a second source of truth.

**NEW:**
> - **FR81:** The Today tab displays a calm "active-days" indicator — the number of days **within the trailing 30-day window** (device local timezone) that have at least one completed session — presented as a gentle piece of continuity state, not a streak. The count is **windowed, not consecutive**: a rest day silently ages out of the 30-day window rather than resetting the count to zero, so there is no chain to break and no reset event. After an absence the indicator simply reads a lower value, with no "streak lost" messaging, badge, flame glyph, or reset notification. `[ASSUMPTION]` The active-days count reuses the underlying activity signal already tracked by the behavioral state machine (FR23) rather than introducing a second source of truth.

**Rationale:** Aligns FR81 to the ratified UX contract (windowed 30-day, non-resetting) and removes the internal contradiction with the brand ethos flagged by the UX brand-ethos-polish review.

### 4.2 PRD — NFR38 (`prd.md:693`) — REQUIRED

**OLD:**
> - **NFR38:** New animated elements (session milestone markers and finish animation per FR78, active-days streak per FR81, decision-factor icons per FR82) honor the NFR2 60fps / ≤ 16ms frame budget and respect the OS "reduce motion" accessibility setting, degrading to static equivalents when reduced motion is enabled.

**NEW:**
> - **NFR38:** New animated elements (session milestone markers and finish animation per FR78, and decision-factor icons per FR82) honor the NFR2 60fps / ≤ 16ms frame budget and respect the OS "reduce motion" accessibility setting, degrading to static equivalents when reduced motion is enabled. The FR81 active-days indicator carries no bespoke animation beyond the standard card reveal and is therefore intentionally excluded from this list.

**Rationale:** Removes FR81 from the animated-elements set (the UX spec's ActiveDaysCard has "no animation beyond the standard card reveal") and drops the "streak" wording, keeping NFR38 accurate and consistent with the FR81 reframe.

### 4.3 PRD — frontmatter `v1PolishUpdate.signal` (`prd.md:42`) — OPTIONAL

**OLD:** `…Today active-days streak, decision-factor iconography`
**NEW:** `…Today active-days indicator, decision-factor iconography`

**Rationale:** Terminology consistency with the reframed FR81.

### 4.4 `addendum.md` — FR81 mechanism note — OPTIONAL

Append to the existing "Active-days streak (FR81)" bullet a clarifying clause: *"The metric is a rolling 30-day windowed active-days count (non-resetting), per the 2026-07-06 UX reframe — not a consecutive-day streak."* (And retitle the bullet "Active-days indicator (FR81)".)

**Rationale:** Downstream mechanism note should not reintroduce "streak"/consecutive language.

### 4.5 `.decision-log.md` — resolution entry — HOUSEKEEPING

Append an entry dated 2026-07-06 recording that the FR81/NFR38 divergence flagged by the UX pass was resolved via this correct-course (Option 1, Minor), closing the open item.

---

## 5. Implementation Handoff

- **Scope:** Minor → direct implementation.
- **Owner:** Developer/PM applies the PRD + addendum + decision-log edits above.
- **Success criteria:**
  1. FR81 text matches the windowed 30-day, non-resetting UX contract (no "consecutive"/"reset to zero"/"streak" mechanic language).
  2. NFR38 no longer lists FR81 as an animated element.
  3. No remaining "consecutive… resets to zero" phrasing for the active-days metric anywhere in `prd.md`.
  4. UX `.decision-log.md` flagged item is closed with a back-reference to this proposal.
- **No** sprint-status.yaml change (no epics/stories added, removed, or renumbered).

---

## 6. Observations (out of scope — no action in this proposal)

- `epics.md:1652` — the **Progress** epic goal ("clear view of their streak, RPE trends…") uses "streak" for the separate Progress timeline/charts feature, not the Today ActiveDaysCard (FR81). This is a pre-existing statement unrelated to this change. Flagged for Paolo's awareness; **not modified here**. Consider a future ethos pass on the Progress epic wording if desired.
- `epics.md:49, :751, :777` — "streak" appears inside the **behavioral state machine** (FR23 internal physiological signal / StateVector field). This is correct domain terminology and unrelated to the FR81 UI metric. **No change.**
