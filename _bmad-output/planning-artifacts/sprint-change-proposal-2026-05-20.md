# Sprint Change Proposal — Epic 9 Pre-Kickoff Alignment

**Date:** 2026-05-20
**Author:** John (PM)
**Triggers:** E7.5-T1 re-targeting (Epic 8 Kickoff Triage 2026-05-17) + Epic 8 Retrospective action items (2026-05-18)
**Scope Classification:** **Moderate** — planning-artifact updates, no PRD/Architecture/UX impact, no requirements change
**Mode:** Incremental (collaborative edit-by-edit)

---

## Section 1 — Issue Summary

Two related signals converged before Epic 9 opens:

1. **E7.5-T1 re-targeting.** The 7 dead ARB `transition*` keys (added by Story 7.5.2 to `app_it.arb` / `app_en.arb`) are still not consumed by `BehavioralStateMachine` (lines 35, 44, 53, 68, 81, 94 emit hardcoded Italian literals). At Epic 8 Kickoff Triage (2026-05-17) the target moved from Epic 8.x to Epic 9.x (Option B — keep Epic 8 thematic). At Epic 8 Retro (2026-05-18) it was further refined to **"Story 9.3 stretch if `BehavioralStateMachine.evaluate()` signature is already being touched, otherwise Story 9.4 firm"**.

2. **Epic 8 Retro process learnings.** Five new ledger items emerged (E8-P1 Cubit-lifecycle AC template, E8-P2 hard gate on Epic 9 kickoff, E8-P3 schema-bump cadence cap, E8-T1 logger replacement, E8-V1 Story 8.5 device smoke) plus two carry-overs promoted to hard gates (E7-P3, E7.5-P2). All five live only in `action-item-ledger.md`; `epics.md` has no visibility on them.

**Discovery context:** Epic 8 closed on 2026-05-18 with retrospective complete. Epic 9 kickoff triage has not yet run. Without alignment, Story 9.1 spec creation (next planning step) would inherit none of these guardrails — Edge Case Hunter would re-discover them at review time, repeating the Epic 8 anti-pattern.

**Evidence:**
- `_bmad-output/implementation-artifacts/action-item-ledger.md` lines 69 (E7.5-T1), 111–113 (E8-K1/K2/triage), 129–133 (E8-P1/P2/P3/T1/V1).
- `_bmad-output/implementation-artifacts/epic-8-retro-2026-05-18.md` §"Next Epic Preview", §"Significant Discovery Assessment" (line 230: "Story 9.1 spec creation should incorporate the new AC template directly").
- `pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart` lines 35/44/53/68/81/94 (hardcoded transition literals).

---

## Section 2 — Impact Analysis

### Epic Impact

| Epic | Status | Impact |
|---|---|---|
| Epic 8 | Closed (2026-05-18) | None |
| Epic 9 | Backlog | **Story 9.1 + Story 9.3 spec scope expanded** (process-level ACs added, not requirement changes). Story 9.4 may emerge post-9.3 retro. |
| Epic 10+ | Backlog | None |

### Story Impact

| Story | Change |
|---|---|
| Story 9.1 (RPEInput Component) | +3 ACs: Cubit-lifecycle invariants (E8-P1), invariant-based ARB test guardrails (E7.5-P2 closure per E8-P2), schema-bump cadence justification (E8-P3) |
| Story 9.2 (MiniSummary & CompletionRing) | No change |
| Story 9.3 (Bandit Reward + State Machine Re-eval) | +3 ACs: Cubit-lifecycle invariants (E8-P1), E7.5-T1 stretch fold-in, Story 9.4 emergence path |
| Story 9.4 | **Not created** — emerges only if 9.3 retro confirms non-absorption of E7.5-T1, per Deferred Items Budget rule (Category A) |

### Artifact Conflicts

| Artifact | Conflict | Resolution |
|---|---|---|
| PRD (`prd.md`) | None — FR14 (transition messages) is functionally satisfied; deferral is implementation-level only | No change |
| Architecture (`architecture.md`) | None | No change |
| UX (`ux-design-specification.md`) | None — `UX-DR11 StateIndicator` invariant | No change |
| `epics.md` | Story 9.1 and 9.3 do not reflect retro decisions | **2 edits applied (this proposal)** |
| `sprint-status.yaml` | Only if Story 9.4 is added | Conditional — no change today (9.4-B decision) |
| `action-item-ledger.md` | Already canonical and current | No change |
| `CLAUDE.md` | Already updated (Cat A/B rule rewrite, Epic 8 retro carry-over annotations) | No change |
| Generated `app_localizations*.dart` | Already `.gitignore`'d (Story 8.4 P8) | No change |

### Technical Impact

- **None on running code.** The hardcoded Italian literals in `behavioral_state_machine.dart` work correctly for the locale-locked `it` user; the dead ARB keys are inert.
- **Schema:** Story 9.1 still introduces `rpe_feedback` table (v7 → v8). No earlier-than-9.1 bump expected.
- **Test suite:** baseline 605 tests after Epic 8 close. Story 9.1's invariant-based ARB guardrails will refactor 1 existing assertion in `state_indicator_test.dart` (E7.5-P2 closure).

---

## Section 3 — Recommended Approach

**Selected option: Direct Adjustment (Option 1).**

- Modify Story 9.1 and Story 9.3 in `epics.md` to surface the retro decisions at the spec-creation entry point.
- No structural epic change. No PRD/Architecture/UX update.
- Defer Story 9.4 creation to Story 9.3 retro (Option 9.4-B). No conditional placeholder in `epics.md`.

**Rationale:**

| Criterion | Assessment |
|---|---|
| Implementation effort | Low — 2 epics.md edits, total ~20 lines of AC text |
| Timeline impact | Zero — Epic 9 kickoff date unaffected |
| Technical risk | Low — no code, no schema, no requirements |
| Team morale | Positive — surfaces accumulated learnings at the right entry point (create-story) instead of re-discovering them at review |
| Long-term sustainability | High — closes the Epic 8 "rule vs reality" drift pattern (process rules that live only in the ledger get ignored at create-story time) |
| Stakeholder expectations | Aligned — Paolo confirmed retro action items 2026-05-18; this proposal operationalizes them |

**Options not selected:**

- **Rollback (Option 2):** N/A. Epic 8 is closed, green (605/605), zero analyzer issues. Nothing to roll back.
- **MVP review (Option 3):** N/A. MVP scope is intact; this proposal is process-level, not scope-level.

---

## Section 4 — Detailed Change Proposals

### Change 4.1 — `epics.md` Story 9.1: +3 ACs

**File:** `_bmad-output/planning-artifacts/epics.md`
**Location:** End of Story 9.1's existing ACs, before `### Story 9.2` heading.

**ADDED:**

```markdown
**Given** the RPE submission Cubit (`RpeFeedbackCubit` or equivalent)
**When** spec is written under the **E8-P1 Cubit-lifecycle invariants** template
**Then** the AC set covers, at minimum: (a) `submit()` idempotency — duplicate taps within the 150ms animation window are a no-op; (b) `close()` cancels any pending stream subscription and async I/O; (c) `rpe_feedback` persistence-error paths emit an explicit `error(Failure)` state (NOT `debugPrint`-only — E8-T1 convergence point); (d) at least one test per invariant

**Given** the test guardrails for this story
**When** ARB-key assertions are written
**Then** **E7.5-P2 invariant pattern applies** — no `expect(userFacingKeys, hasLength(N))` magnitude-based assertions; use "no key removed / all keys load / new keys for this story present" invariants instead (closes E7.5-P2 hard gate per E8-P2)

**Given** the new `rpe_feedback` table (schemaVersion v7 → v8)
**When** the spec is drafted
**Then** **E8-P3 schema-bump cadence cap** is honored — the spec explicitly declares that no pending bump in Epic 9 can be consolidated with this one (RPE feedback is the only known Epic 9 schema change)
```

**Rationale:** surfaces E8-P1, E8-P2 (E7.5-P2 hard gate), E8-T1, and E8-P3 at the spec-creation entry point. Without these ACs at the epics.md level, the create-story workflow would skip them.

---

### Change 4.2 — `epics.md` Story 9.3: +3 ACs

**File:** `_bmad-output/planning-artifacts/epics.md`
**Location:** End of Story 9.3's existing ACs, before the `---` separator preceding `## Epic 10`.

**ADDED:**

```markdown
**Given** the `BehavioralStateMachine.evaluate()` re-trigger logic (this story's core change)
**When** spec is written under the **E8-P1 Cubit-lifecycle invariants** template
**Then** the state-machine invocation Cubit/use-case covers: idempotency on re-entry, cancellation on dispose, explicit error state on Isolate failure (E8-T1 convergence)

**Given** `BehavioralStateMachine.evaluate()` signature is being touched in this story
**When** the spec is drafted
**Then** **E7.5-T1 is folded in as a stretch goal** — wire the 7 dead ARB `transition*` keys (`app_it.arb` / `app_en.arb`) through the consumer at lines `lib/ai/state_machine/behavioral_state_machine.dart:35,44,53,68,81,94`, replacing hardcoded Italian literals with `AppLocalizations` keys (or a `BehavioralTransition.transitionKey` enum the widget resolves). Stretch-allowable **only** if it does not expand epic scope; otherwise defer to Story 9.4 firm

**Given** E7.5-T1 is deferred from Story 9.3 stretch
**When** Story 9.3 retro confirms non-absorption
**Then** PM (John) creates a Story 9.4 at that point with E7.5-T1 as its sole scope (no placeholder is kept in `epics.md` until non-absorption is confirmed, per Deferred Items Budget rule)
```

**Rationale:** operationalizes E7.5-T1's "9.3 stretch / 9.4 firm" branch as an AC-level decision gate. Decision 9.4-B (no upfront placeholder) is documented in the AC itself to prevent future "where is Story 9.4?" confusion.

---

### Change 4.3 — Story 9.4 placeholder: NOT CREATED

**Decision:** Option **9.4-B** — Story 9.4 emerges only if Story 9.3 retro confirms non-absorption.

**Rationale:**
- Avoids a conditional story that may never execute (noise).
- Aligns with the Deferred Items Budget rule's Category A discipline ("no silent re-defer").
- The branching logic now lives explicitly in Story 9.3 AC (Change 4.2), so the absence of an epics.md placeholder is intentional, not an omission.

---

### Change 4.4 — Traceability matrix: NO CHANGE

**Decision:** Leave the Epic 9 traceability matrix line (`Epic 9: 9.1-9.3 | FR21-24 | NFR1 | UX-DR9-10, UX-DR12 | ARCH7`) untouched.

**Rationale:** FR14 is functionally satisfied today (transition messages render in Italian to the locale-locked user). The deferred wiring of ARB keys is implementation-level, not requirement-level. Adding FR14 to Epic 9's row would imply a *new* requirement-coverage commitment that doesn't exist.

---

## Section 5 — Implementation Handoff

**Scope classification: Moderate** (planning-artifact reorganization, no requirements/architecture/UX change).

**Handoff recipients:**

| Role | Responsibility |
|---|---|
| **PM (John)** — completed in this proposal | Edits 4.1 and 4.2 applied to `epics.md` during this skill run. |
| **Amelia (Developer) — at Story 9.1 create-story** | Inherit E8-P1 AC template, E7.5-P2 invariant pattern, E8-P3 schema-bump justification directly from epics.md Story 9.1. Draft `RpeFeedbackCubit` spec accordingly. |
| **Amelia + Winston (Architect) — at Story 9.3 create-story** | Inherit E8-P1 AC template for state-machine invocation. Decide stretch fold-in of E7.5-T1 based on whether `BehavioralStateMachine.evaluate()` signature is touched. |
| **PM (John) — at Epic 9 kickoff triage** | Run Category B sunset review per E8-K2. Verify E7-P3 closed (Edge-Case Hunter prompt update) before Story 9.1 enters sprint (E8-P2 hard gate). |
| **PM (John) — at Story 9.3 retro** | If E7.5-T1 not absorbed, create Story 9.4 with E7.5-T1 as sole scope. |
| **Paolo (Project Lead) — next physical device session** | Execute E8-V1 (Story 8.5 abandon-flow on-device smoke). Non-gating. |

**Success criteria:**

1. ✅ `epics.md` Story 9.1 and 9.3 carry the new ACs (verified in this run).
2. ⏳ Story 9.1 spec, when created, includes a Cubit-lifecycle AC set and uses invariant-based ARB guardrails.
3. ⏳ Story 9.3 spec, when created, explicitly states whether E7.5-T1 is folded in as stretch or deferred to 9.4.
4. ⏳ Epic 9 kickoff triage confirms E7-P3 closed and E7.5-P2 applicable to Story 9.1.

---

## Approval

**Approved by:** Paolo (Project Lead), 2026-05-20, via `bmad-correct-course` incremental approval flow.

**Edits applied this session:**
- `_bmad-output/planning-artifacts/epics.md` Story 9.1 — +3 ACs (Change 4.1)
- `_bmad-output/planning-artifacts/epics.md` Story 9.3 — +3 ACs (Change 4.2)

**No changes:** PRD, Architecture, UX, sprint-status.yaml, action-item-ledger.md, CLAUDE.md.

---
