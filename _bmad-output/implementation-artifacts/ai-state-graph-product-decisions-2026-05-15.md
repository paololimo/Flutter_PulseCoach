# AI State-Graph Product Decisions

**Date:** 2026-05-15
**Decision owner:** Paolo (Project Lead)
**Participants:** John (PM), Winston (System Architect)
**Status:** Decided
**Closes:** Epic 5 retro carry-over → Epic 6 re-flag → Epic 6.5 retro carry-over (3 epics of slippage)
**Unblocks:** Story 7.1 (`StateIndicator`) creation

---

## Scope

Resolve the three state-graph asymmetries flagged in Story 5.2 code review and re-flagged by Epic 5, Epic 6, and Epic 6.5 retros. Decisions below modify `lib/ai/state_machine/behavioral_state_machine.dart` and the priority-ordered transition rules.

**State machine** (unchanged): `BehavioralState ∈ {active, fatigued, atRisk, recovering}`. Deterministic, stateless, pure Dart, evaluated once per daily-plan generation.

**Constraints per state** (unchanged, FR24):
| State | Max intensity | Max sessions |
|---|---|---|
| `active` | none | 3 |
| `fatigued` | medium | 3 |
| `atRisk` | low | 2 |
| `recovering` | low | 2 |

---

## Decisions

### Q1 — `active + missedSessions >= 2` escalation

**Decision:** **Add rule.** `active → atRisk` when `missedSessions >= 2`.

**Rationale (JTBD):** an `active` user who skips 2+ sessions is not fatigued — they are disengaged. On return, ambition is intact but conditioning has degraded. This is the canonical "you hurt me" injury profile. `atRisk` (low intensity, max 2 sessions) is the only state whose constraints protect this user. `fatigued` (medium intensity, 3 sessions) is too permissive.

**Conditional dependency (binding):** this rule **must merge in the same sprint and PR cluster** as **Story 7.1b — `missedSessions` Decay & Reset** (see §Story 7.1b). Without decay logic, the counter never resets, and any user with two historical absences would be permanently stuck in `atRisk`. The entry rule without the exit rule is an open graph; open graphs in production become unpayable debt.

**Implementation:**
- New rule, priority **before** Rule 2 (`active → fatigued`) — escalates structural disengagement before exertion signal.
- Transition message: *"Bentornato. Riprendiamo con calma — sessioni leggere per qualche giorno."* (Italian copy pending Sally + Alice product review; placeholder English string acceptable for first merge.)
- New tests required: positive case (`missed=2`), negative case (`missed=1`), boundary case (`missed=2` AND `last-2-RPE avg > 8` → `atRisk` wins by priority).

---

### Q2 — `recovering` demotion path

**Decision:** **Add single rule.** `recovering → fatigued` when `last RPE >= 9`.

**Rationale:**
- A user in `recovering` who records RPE 9 or 10 on a low-intensity session is in dissonance with the plan. Keeping them in `recovering` is denial — the `StateIndicator` label "recovering" would mislead.
- Target = `fatigued` (not `atRisk`): preserves graph gradualism. `recovering → atRisk` is too punitive given current constraints already cap intensity.
- **NO `missedSessions` trigger** in this rule. Cabling demotion on a counter without decay logic creates stuck-state bugs. The missed-sessions dimension is addressed by Story 7.1b's reset logic + Q1's escalation, not by a demotion rule.
- Single rule, contained blast radius, ~4 new tests.

**Caveat — pending Sally + Alice product review (explanation copy):** the `StateIndicator` copy for `fatigued`-arrived-from-`recovering` must be distinct from `fatigued`-arrived-from-`active`. If the copy review concludes the two strings are identical, Q2 reopens with target = `atRisk`. This caveat does not block Story 7.1 merge; it is logged against the explanation-copy review.

**Implementation:**
- New rule, priority **after** Rule 4 (`recovering → active`) — the recovery path stays primary; demotion only fires when explicit overload signal present.
- Transition message: placeholder pending copy review.
- Tests: positive (`current=recovering, last RPE=9`), negative (`last RPE=8`), priority guard (rule does NOT fire if `recovering → active` conditions also met — `→ active` should win because it requires sustained signal).

---

### Q3 — `atRisk/fatigued → recovering` guard asymmetry

**Decision:** **Tighten existing rule.** `atRisk OR fatigued → recovering` when:
- `last 3 RPE avg ≤ 7` (was: last 2 RPE both ≤ 7), **AND**
- `missedSessions == 0`.

**Rationale:**
- Current rule (2 RPE ≤ 7) is much weaker than the symmetric `recovering → active` (3 RPE avg ≤ 6.5 AND streak ≥ 3). The recovery transition was too cheap for the highest-alarm states.
- Asymmetry intentionally kept: going down to `recovering` is an act of **care** (low bar — recognize the attempt); going up to `active` is an act of **promotion** (high bar — sustained proof). But the "low bar" was too low. Three sessions of sub-threshold RPE is the minimum honest signal.
- `missedSessions == 0` guard eliminates the false positive "two low RPEs while skipping days" — that's underwork, not recovery.
- Streak requirement **not** added: an `atRisk` user has by definition had interruptions; demanding a streak to begin recovering is a trap.

**Implementation:**
- Modify existing Rule 3 (`atRisk/fatigued → recovering`). Replace `rpe[last-1] <= 7 && rpe[last-2] <= 7` with `_lastNAvg(rpe, 3) <= 7.0 && missedSessions == 0`.
- New tests: positive (3 RPE avg ≤ 7, missed=0), negative on average (avg > 7), negative on missed (avg ≤ 7 but missed ≥ 1), insufficient data (fewer than 3 RPE → no transition).
- Existing test `5.2-UNIT-011` and `5.2-UNIT-012` fixtures will need updating; the priority test `5.2-UNIT-015` remains valid.

---

## Final Rule Set (Priority Order)

After this decision lands, `BehavioralStateMachine.evaluate()` evaluates rules in this order:

1. **`active → atRisk`** if `missedSessions >= 2` *(new — Q1)*
2. **`fatigued → atRisk`** if `missedSessions >= 2` *(unchanged)*
3. **`active → fatigued`** if `_lastNAvg(rpe, 2) > 8.0` *(unchanged)*
4. **`atRisk OR fatigued → recovering`** if `_lastNAvg(rpe, 3) <= 7.0 AND missedSessions == 0` *(tightened — Q3)*
5. **`recovering → active`** if `_lastNAvg(rpe, 3) <= 6.5 AND streak >= 3 AND rpe.length >= 3` *(unchanged)*
6. **`recovering → fatigued`** if `rpe.last >= 9` *(new — Q2)*
7. *(no rule fires → return current state, no message)*

---

## Story 7.1b — `missedSessions` Decay & Reset (binding dependency)

**Confirmed:** must enter the **same sprint as Story 7.1**, merged in the same PR cluster. The Q1 rule above is **conditional** on this story shipping in the same sprint.

**Scope (minimum viable):**
- Define decay rule: `missedSessions` decrements by 1 (or resets to 0 — owner to decide) after each completed session.
- Define exit rule for `atRisk`: `atRisk → recovering` requires `missedSessions == 0` (already implied by Q3 decision above — needs verification of consistency).
- Define cold-start / long-absence behavior: user returning after >7 days inactivity (no completed sessions in window) — does counter persist or reset? Default proposal: counter persists, but explicit "welcome back" UX prompt resets it on user action. Story owner to confirm.
- Persistence: write/update column in `behavioral_state_table` (or related table) — schema decision deferred to Story 7.1b creation.

**Owner:** to be assigned at Epic 7 kickoff (likely Amelia for implementation; Alice for product framing).

**Trigger to escalate priority:** if Story 7.1b is descoped or moved out of Epic 7 sprint, Q1 decision **reverts to "do not add rule"** and `active → atRisk` is **removed** from the rule set before merge. No third option.

---

## Caveats and Open Items

| Item | Owner | Status |
|---|---|---|
| Explanation copy for `fatigued`-from-`recovering` distinct from `fatigued`-from-`active` | Sally (UX) + Alice (PO) | Pending — second product review (Epic 6.5 retro item #7). Does NOT block Story 7.1 merge. Reopens Q2 only if copies must be identical. |
| Transition message strings for new rules (Q1, Q2) | Sally + Alice | Pending — same review. Placeholder strings acceptable for first merge. |
| `StateVector` RPE range validation (negative / out-of-range guard) | Amelia | Deferred (Story 5.2 review item). Not on Epic 7 critical path. |
| AC7 wording reconciliation (Story 5.2 spec) | SM | Deferred (Story 5.2 review item). Documentation-only. |

---

## Implementation Checklist for Story 7.1 Creation

Before Story 7.1 (`StateIndicator`) story file is created:

- [x] Decisions Q1, Q2, Q3 documented (this doc).
- [ ] Story 7.1b (`missedSessions` decay) confirmed in Epic 7 sprint plan.
- [ ] Explanation copy product review (Sally + Alice) — second blocking review, separate decision doc expected.
- [ ] `Failure` equality BLoC re-emission regression test (Epic 6.5 retro action item #4) — parallel to 7.1.
- [ ] CLAUDE.md updated to reflect Epic 6.5 closure baseline (retro action item #2).

When the second product review (explanation copy) lands, cross-reference its decision doc here and confirm Q2 caveat.

---

## Decision Record

| Q | Initial John | Initial Winston | Round-2 outcome | Final (Paolo) |
|---|---|---|---|---|
| Q1 | `active → atRisk` immediate | Defer until decay exists | Winston concedes conditional on 7.1b same-sprint | **Add rule + 7.1b gemellata** |
| Q2 | `recovering → atRisk` on RPE=10 OR missed | `recovering → fatigued` on RPE≥9, no missed | John concedes target=`fatigued` + drops missed trigger | **Add rule: `recovering → fatigued` on RPE≥9** (caveat pending copy review) |
| Q3 | 2 RPE ≤ 7 + `missed==0` | 3 RPE avg ≤ 7 + `missed==0` | Convergence on `missed==0`, split on RPE count | **3 RPE avg ≤ 7 + `missed==0`** |

---

## Sign-off

- 📋 John (PM) — agreed conditional on Sally+Alice copy review confirming differentiated `fatigued` copy.
- 🏗️ Winston (Architect) — agreed conditional on Story 7.1b shipping in same Epic 7 sprint as 7.1.
- 👤 Paolo (Project Lead) — final decisions recorded above.

This document closes the Epic 5 retro carry-over "AI state-graph product semantics review" and unblocks Story 7.1 creation. Decision logged in action-item ledger.
