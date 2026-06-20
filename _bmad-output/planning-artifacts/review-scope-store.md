# v2 PRD Review — Product Scope & App-Store Compliance

**Reviewer role:** Product-scope & app-store-compliance reviewer
**Scope:** prd.md `# v2 — Accounts, Subscriptions & Social` (FR53–FR76, NFR27–NFR34, phasing) + addendum.md
**Date:** 2026-06-20

**Verdict:** Structurally sound and shippable in phases, but two issues must be resolved before handoff: an Apple-guideline gap (in-app account deletion) and the aggressiveness of the free Progress tier. The rest is medium/low polish plus four product decisions Paolo must own.

---

## CRITICAL

### C1 — In-app account deletion not required by any FR (Apple Guideline 5.1.1(v))
**Location:** FR54–FR57 (Accounts), NFR30 (GDPR erasure)
**Note:** Apple App Store Review Guideline **5.1.1(v)** requires that any app offering **account creation** must also offer **in-app account deletion** — not merely a data-export/erasure flow or a "contact us" path. NFR30 covers GDPR right-to-erasure ("export and delete their account and all associated server data") but does not state the deletion must be **initiable and completable inside the app**. This is one of the most common rejection causes for apps adding accounts. Since v2.1 introduces accounts before the store submission in v2.2, this is a phase-blocker for v2.2 publication.
**Fix:** Add an explicit FR: *"A signed-in user can delete their account and all associated server data from within the app, without leaving the app or contacting support."* Cross-reference NFR30. Confirm the deletion is reachable from Settings (ties to FR53 navigation fix).

---

## HIGH

### H1 — Free Progress tier ("last session + weekly goal only") is a v1 downgrade and a retention risk
**Location:** FR61 (and overview point 2, line 688)
**Note:** In v1, the **full** Progress history and all four charts were **free** (Epic 10 shipped: history timeline, minutes/week, completion ring, RPE trend, session-type donut). FR61 retroactively paywalls capability that existing users already have for free. Two distinct problems:
  1. **Perceived downgrade / trust hit** — existing v1 users updating to v2 will lose features they currently use unless grandfathered. App stores and users both react badly to "you used to have this free."
  2. **Retention mechanics** — Progress history (streaks, trend, "minutes this week vs last") is exactly the habit-forming retention surface. Gating it to the most-recent-session-only for free users removes the primary reason a non-paying user re-opens the app, which can depress the top of the funnel that *feeds* Pro conversion. Gating the **social** suite behind Pro is clean and defensible; gating **basic progress history** is the aggressive part.
**Fix (decision for Paolo, present options — do not silently pick):**
  - (a) Grandfather all pre-v2 installs to full history free (recommended minimum); and/or
  - (b) Soften the free tier to e.g. *last 7 days / last 4 sessions* rather than *single last session*, keeping a usable free habit loop while reserving the **full historical timeline + advanced charts** for Pro; and/or
  - (c) Keep history free and make **social the sole Pro value** (cleanest store story, weaker monetization).
  Whatever is chosen, FR61 must state the grandfathering rule explicitly — it is currently silent on existing users.

---

## MEDIUM

### M1 — Sign in with Apple correctly required, but tie the condition to the trigger
**Location:** FR54, NFR32
**Note:** Apple Guideline **4.8** requires Sign in with Apple as an option **whenever** a third-party/social login (Google) is offered. NFR32 states it ("Sign in with Apple offered alongside Google/email"), and FR54 lists all three, so the requirement is **covered** — good. Minor: NFR32's phrasing "per Apple guidelines" is vague. Note also: email+password alone would *not* trigger 4.8; it is the **Google** option that triggers the Apple requirement. This is satisfied but worth making explicit so an engineer doesn't drop Apple login thinking email+password is sufficient.
**Fix:** Reword NFR32: *"Because Google Sign-In is offered, Sign in with Apple MUST be offered on iOS (Apple Guideline 4.8)."*

### M2 — FR70/FR71 (group-adapted difficulty + real-time multi-user sync) are under-specified for engineering
**Location:** FR70, FR71, NFR31, addendum §Shared-session
**Note:** Two separate under-specifications:
  - **FR70 group constraint:** "reusing the on-device adaptive engine under a group constraint" is a real architectural unknown. The v1 engine (`BehavioralStateMachine` + contextual bandit + per-user RPE state) is **single-user**. "Scaled to the group's lowest comfortable level honoring every participant's constraints" implies the engine accepts a *merged/min* state vector and a constraint set — a new input contract that does not exist today. This is fine to leave to architecture, but the PRD should explicitly flag it as **net-new engine capability, not a config flag**, so it isn't underestimated. The addendum already hints at this ("the engine must accept a group constraint, not a single-user state") — promote that caveat into FR70 or a note.
  - **FR71 real-time sync:** This is a genuine jump from phone↔watch. The v1 bridge is **1 device → 1 device, same owner, local transport** (`watch_connectivity` Data Layer). FR71 is **N participants, different owners, different physical devices, requires a relay** (cloud/backend or P2P). NFR31 borrows the "~1 second" bar from the phone↔watch bridge, but that bar was met over a *local* link; a cloud relay over cellular is a different reliability profile. The requirement is **bounded** in participant intent (co-located, friends only) but the *transport* is unspecified.
**Fix:** (1) Add a note to FR70 that the group constraint is a new engine input contract. (2) State in FR71/NFR31 that transport is an architecture decision and the ~1s target is **aspirational over a backend relay**, not inherited from the local bridge. (3) Consider bounding participant count explicitly (e.g., "2–N, N≤4 for v2.4") — currently unbounded.

### M3 — FR62 social-gating vs FR73 — restate without redundancy/conflict risk
**Location:** FR62, FR73(a)
**Note:** FR62 gates **all** social (FR64–FR75) behind Pro. FR73 re-states that shared sessions need Pro **plus** account + friends + location. No contradiction, but FR73(a) duplicates FR62's gate, and FR62's range "(FR64–FR75)" **excludes FR63** (username/handle) and **FR76** (view leaderboard). Is setting a username (FR63) free or Pro? Is *viewing* the leaderboard (FR76) free while *earning points* (FR74/75) is Pro? The boundary is ambiguous at exactly the cheap-to-show vs paid-to-participate seam.
**Fix:** State explicitly whether FR63 (handle) and FR76 (view leaderboard) are free or Pro. Recommendation: handle creation can be free (needed for any account), but participation (friends, feed, shared sessions, scoring) is Pro — make it a sentence, not an inferred range.

---

## LOW

### L4 — Privacy nutrition labels / data-collection disclosure under-detailed for store submission
**Location:** NFR32 ("required privacy disclosures … provided")
**Note:** v1's entire brand is "no data leaves the device," so its App Privacy label was trivially "Data Not Collected." v2 collects email, username, contacts (FR64), shared progress, and location-at-session-start. The store privacy label and the in-app privacy screen (v1 Story 14.2 stated "non trasmette dati a server esterni") **both become false** for signed-in users and must be updated. This is operational, not a blocker, but easy to forget.
**Fix:** Add a note that the v1 Privacy screen copy (currently "no external server") must be revised for v2, and that the App Privacy label changes from "Data Not Collected" to a populated label.

### L5 — Contacts permission (FR64) is a known store-review friction point
**Location:** FR64
**Note:** "add friends from phone contacts" requires contacts permission, which both stores scrutinize (purpose string, no silent upload). Low risk but ensure it is **optional** alongside username/QR (it already is — FR64 lists three methods), so a reviewer denying contacts doesn't block the feature.
**Fix:** Note that contacts is one of three friend-add paths and must remain fully optional; needs a clear purpose string.

### L6 — Restore-purchases is present (good); add subscription-state-on-reinstall note
**Location:** FR60, FR57
**Note:** FR60 covers restore purchases — good, Apple requires it. Minor: with cloud accounts (FR57) and store subscriptions (FR58) as **two** separate identity/entitlement sources, the PRD doesn't say which is authoritative for Pro status (store receipt vs. account flag). Architecture concern, but worth a one-line flag.
**Fix:** Note that Pro entitlement source-of-truth (store receipt vs. server account) is an architecture decision.

---

## [ASSUMPTION] tag audit

**Count: 6 explicit `[ASSUMPTION]` tags** (FR57, FR62, FR71, FR75, the phasing-table header line 788, and the overview note line 681 referencing the convention). Treating the four FR-level + one phasing-table tag as the substantive ones:

| Tag | Location | Type | Phase-blocker? |
|---|---|---|---|
| Backup is opt-in, private/encrypted, not training data | FR57 | **Safe default** | No |
| "Social paid" = whole suite Pro; accounts/backup free | FR62 | **Real product decision** | No (but pairs with H1/M3 boundary call) |
| WearOS mirrors owning participant's synced view | FR71 | **Real product/scope decision** | **Soft blocker for v2.4** — changes the watch sync contract; listed in Open Items |
| Shared sessions award more points (formula deferred) | FR75 | **Safe default** (formula correctly deferred to design) | No |
| Suggested phase/build order | phasing table | **Real decision** (sequencing) | No — order is sound (see below) |

**Assessment:** None of the assumptions make the PRD *unsafe* to hand to architecture/epics, **provided** C1 (account deletion) and H1 (free-tier grandfathering) are resolved first — those are the true gates, and neither is currently an `[ASSUMPTION]` tag (they are gaps). The FR62 and FR71/WearOS assumptions are genuine decisions Paolo must confirm, but they can be confirmed at the start of v2.2 and v2.4 respectively rather than blocking the whole document. The "Open items for review" list (line 799) already captures the WearOS, price, and point-formula decisions correctly.

---

## Phasing-table realism & shippability

**Assessment: realistic and well-ordered.** Strengths:
- v2.0 (nav fix) is correctly carved out as ship-immediately — it's a standing v1 defect (FR53) and needs none of the backend.
- Backend foundation (v2.1) precedes monetization (v2.2) precedes social (v2.3+) — correct dependency order; you cannot gate Pro before accounts exist.
- v2.4 is correctly flagged as the highest-complexity phase (real-time + group constraint).

**Risks to flag:**
- **C1 lands in v2.2 scope, not v2.1.** Account deletion is an Apple requirement that bites at *store submission* (v2.2), but the account is *built* in v2.1. Ensure deletion ships **in v2.1 with the account**, not deferred to v2.2, or v2.2's first store submission fails review.
- **v2.4 is two hard problems in one phase** (multi-user real-time transport + group-adapted engine). Consider splitting: v2.4a = shared session with a *fixed/simplest* group plan (proves transport), v2.4b = group-adapted difficulty (proves engine). Reduces the risk of the single most complex phase stalling.
- **v2.2 = "App Store publication"** is the first time the app faces review with accounts + IAP + new privacy labels — the highest-rejection-risk milestone. C1, M1, L4, L5 all converge here. Treat v2.2 as a compliance gate, not just a feature phase.

---

## Summary of required pre-handoff actions
1. **Add in-app account-deletion FR** (C1) — blocks v2.2 store approval.
2. **Decide & document free-tier grandfathering + free Progress scope** (H1) — present options, don't silent-pick.
3. **Clarify the FR62/FR63/FR76 free-vs-Pro boundary** (M3).
4. **Flag FR70 group-constraint as net-new engine input and FR71 transport as unspecified** (M2) for architecture.
5. Confirm the WearOS-mirror assumption (FR71) before v2.4.
