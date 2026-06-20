# Sprint Change Proposal
**Date:** 2026-05-24  
**Trigger:** Story 9.1 — RPEInput overflow at 360dp (on-device functional failure)  
**Branch under review:** `fix/rpe-input-overflow-360dp`  
**Scope classification:** Moderate  
**Prepared by:** Developer (Correct Course workflow)

---

## Section 1 — Issue Summary

### Problem Statement

`RPEInputWidget` rendered the 10 RPE targets as a single fixed horizontal row, as specified by UX-DR9. At the minimum hit-area floor (NFR24: 48dp per target), the row requires `10 × 48dp + 9 × 4dp gap = 516dp` of width. On the SM-A520F (360dp wide — the only physical test device in the project), this caused a **204dp overflow**: targets RPE 8, 9, and 10 were clipped off-screen and could not be tapped. This is a **functional failure of Story 9.1 AC1** — the primary feedback input of the entire adaptive coaching loop was broken on the reference phone.

### Discovery Context

Caught during Epic 9 on-device verification (2026-05-24). The bug was invisible in automated tests because `flutter_test` defaults to an 800dp-wide surface — wider than any real phone. All four existing WIDGET tests (001–004) passed throughout Epic 9 development.

### Evidence

- Git commit `979acb5` message documents the 204dp overflow, the device, and the cause.
- Regression test `9.1-WIDGET-005` (added in the same commit) reproduces the failure: at 360dp, the `Row` overflows and targets 8–10 are off-screen.
- UX spec line 613 confirms the layout intent: "10 circular buttons in a single row. Each button: 44dp diameter (≥48dp touch target with spacing)." No provision for 360–515dp phone widths was specified.

---

## Section 2 — Impact Analysis

### Checklist Results

| ID | Item | Status |
|---|---|---|
| 1.1 | Triggering story: Story 9.1 — RPEInput Component | [x] Done |
| 1.2 | Issue type: Technical limitation discovered during testing; gap in UX spec | [x] Done |
| 1.3 | Evidence: commit `979acb5`, regression `9.1-WIDGET-005`, device SM-A520F | [x] Done |
| 2.1 | Current epic (9) still completable as planned? Yes — Epic 9 is already closed | [x] Done |
| 2.2 | Epic-level changes required? Story 9.1 AC1 wording needs updating | [!] Action-needed |
| 2.3 | Future epics impacted? Epic 10 Story 10.2 already annotated (E9R-2) | [x] Done |
| 2.4 | Any epics invalidated or new ones needed? No | [N/A] |
| 2.5 | Epic sequencing change? No | [N/A] |
| 3.1 | PRD conflicts? No — FR21/NFR24 both still satisfied by two-row layout | [x] Done |
| 3.2 | Architecture conflicts? No — `LayoutBuilder` pattern is already the standard | [x] Done |
| 3.3 | UX spec conflicts? Yes — UX-DR9 specifies "single horizontal row"; fix deviates | [!] Action-needed |
| 3.4 | Other artifacts? Testing strategy (viewport test infra E7-T2/E9R-2 already in plan) | [x] Done |
| 4.1–4.4 | Path forward evaluation | [x] Done — see Section 3 |

### Epic Impact

**Epic 9 (Feedback & Adaptation)** — CLOSED. No re-opening required. The fix is committed on a feature branch and needs merge to main; no epic-level re-scoping.

**Epic 10 (Progress & History)** — No scope change. The E9R-2 annotation already in `epics.md` requires viewport/golden test infra at 360dp to be unblocked before Story 10.2 enters sprint. This remains valid and unchanged.

**Epic 11 (Responsive Layout)** — Low risk. Epic 11 targets the 600dp breakpoint (phone ↔ tablet). The RPEInput two-row degrade operates entirely within the phone layout (<600dp) and does not affect the phone/tablet switch logic.

### Artifact Conflicts

**1. `epics.md` — Story 9.1 AC1 (line ~1438)**

Current AC1 reads:
> "a single horizontal row of 10 circular tap targets (1-10) in JetBrains Mono 20sp is displayed (FR21, UX-DR9)"

The fix introduces a **conditional layout**: single row when `available ≥ 516dp`, two rows of five when `available < 516dp`. The AC as written does not allow for this — it would fail a literal reading.

**2. `ux-design-specification.md` — UX-DR9 (line ~335, ~613, ~1064)**

UX-DR9 specifies "a single row of 10 tappable numbers." Three locations in the spec enforce this: the component summary table (line 335), the spacing grid (line 613), and the full component spec (line 1064). None acknowledges the 360dp phone case.

**Complication:** The spec also contains a "Small phone (<360dp) RPE exception" at line 1717 that proposes a **different** solution — 36dp visual diameter with overlapping tap targets. The SM-A520F is exactly 360dp, which puts it outside that exception's range yet well inside the overflow zone. The two solutions are inconsistent: the spec exception applies to <360dp, while the fix addresses 360–515dp. This gap needs explicit resolution by UX (Sally).

**3. No architecture or PRD changes required.** The fix uses `LayoutBuilder`, the project's established responsive pattern. NFR24 (48dp touch targets) is preserved. FR21 (RPE 1–10 submission) is preserved.

---

## Section 3 — Recommended Approach

### Selected Path: Option 1 — Direct Adjustment

**Rationale:** The fix is already implemented, fully tested (685/685 tests pass, including the new regression), and represents the least-risk path. The functional failure (RPE 8/9/10 unreachable on the reference device) is strictly worse than the UX deviation (two rows instead of one). Rolling back would re-introduce a confirmed functional regression on the only physical device in the project.

The only open question is whether the two-row degrade is the **right UX answer** or whether Sally prefers a different treatment (e.g., the overlapping-tap-target approach from the spec exception, or a scroll). This is a product decision, not a technical one — and it does not block merging the fix.

**Effort:** Low — changes are confined to two document sections (Story 9.1 AC1, UX-DR9) and a branch merge.  
**Risk:** Low — no schema changes, no new dependencies, no new Bloc state. Existing behavior preserved on wide surfaces.  
**Timeline impact:** Zero — no Epic 10 stories are blocked.

### Not Recommended

- **Option 2 (Rollback):** Would re-introduce a functional AC1 failure. No justification.
- **Option 3 (MVP Review):** The MVP is not affected. RPE feedback works on all devices with the fix.

---

## Section 4 — Detailed Change Proposals

### 4.1 — `epics.md`: Story 9.1 AC1 — conditional layout

**Story:** Story 9.1 RPEInput Component  
**Section:** Acceptance Criteria (line ~1438)

**OLD:**
```
**When** the RPE screen renders
**Then** a single horizontal row of 10 circular tap targets (1-10) in JetBrains Mono 20sp is displayed (FR21, UX-DR9)
```

**NEW:**
```
**When** the RPE screen renders on a surface ≥ 516dp wide (tablet, landscape phone)
**Then** a single horizontal row of 10 circular tap targets (1-10) in JetBrains Mono 20sp is displayed (FR21, UX-DR9)

**When** the RPE screen renders on a surface < 516dp wide (portrait phone)
**Then** two rows of five circular tap targets (1-5, 6-10) in JetBrains Mono 20sp are displayed, each target maintaining ≥ 48dp hit area (NFR24); this is the approved degrade from UX-DR9 for phone-width screens (see E9R-3 decision)
```

**Rationale:** AC1 previously conflicted with the shipped fix. The two-row degrade is the implemented and tested behavior; the AC must reflect it. The 516dp threshold is derived from `10 × 48dp + 9 × 4dp = 516dp` — the exact minimum for a single-row layout at the NFR24 floor.

---

### 4.2 — `ux-design-specification.md`: UX-DR9 — add phone-width degrade note

**Section:** Component specification for RPEInput (line ~1064, anatomy + states)

After the existing anatomy block, add:

**ADD:**
```
**Phone-width degrade (< 516dp available width):** A single row of 10 × 48dp targets (516dp total) cannot fit a standard portrait phone without either clipping targets or breaking NFR24. When `LayoutBuilder` reports < 516dp available width, `RPEInputWidget` renders two rows of five (1–5 top, 6–10 bottom) with 8dp vertical gap between rows. Each target retains ≥ 48dp hit area. The single-row layout (UX-DR9 primary) is preserved for ≥ 516dp surfaces (tablets, landscape). Rationale: functional correctness (all values reachable) takes precedence over layout purity on narrow devices. Decision ratified by Sally (UX) + John (PM) via E9R-3.
```

**Rationale:** The spec currently only has the "single row" and the "<360dp overlapping-tap exception" — neither covers the 360–515dp phone range. This addition closes the gap and documents the decision chain.

---

### 4.3 — `ux-design-specification.md`: Line 1717 — reconcile small-phone exception

**Section:** Touch target sizing / small phone RPE exception

**OLD:**
```
**Small phone (< 360dp) RPE exception:** 10 buttons × 48dp = 480dp, exceeding screen width. Solution: visual button diameter 36dp, with overlapping tap targets that resolve to nearest button.
```

**NEW:**
```
**Phone-width RPE degrade (< 516dp available width):** 10 buttons × 48dp + 9 × 4dp gap = 516dp, exceeding all standard portrait phone widths. `RPEInputWidget` degrades to two rows of five below this threshold (see RPEInput component spec). The 36dp-visual / overlapping-tap-target approach is NOT used — the two-row layout is simpler to implement, easier to test, and avoids tap ambiguity at the cost of a single extra row of height.
```

**Rationale:** The old exception (36dp overlapping targets for <360dp) was superseded by the two-row fix that applies at ≥360dp too. Leaving both in place creates a contradictory spec. The new text removes the abandoned approach and unifies under the two-row solution.

---

## Section 5 — Implementation Handoff

### Scope Classification: **Moderate**

The implementation is complete (code + test on `fix/rpe-input-overflow-360dp`). What remains is:

| Action | Owner | Dependency | Timing |
|---|---|---|---|
| Sally + John validate two-row degrade (E9R-3) | Sally (UX) + John (PM) | None | Before/at Epic 10 kickoff |
| Merge `fix/rpe-input-overflow-360dp` → `main` | Paolo (Dev) | E9R-3 decision (or decision to merge regardless) | After E9R-3 |
| Update `epics.md` Story 9.1 AC1 (proposal 4.1) | Developer agent | E9R-3 approval | After E9R-3 |
| Update `ux-design-specification.md` UX-DR9 (proposals 4.2, 4.3) | Developer agent | E9R-3 approval | After E9R-3 |
| Unblock E7-T2 viewport/golden test infra (E9R-2) | Charlie (Senior Dev) + Dana (QA) | None | Before Story 10.2 enters sprint |

### Merge Recommendation

If E9R-3 is not resolved before Epic 10 Sprint 1 starts, **merge the branch anyway** and mark the AC1 and UX-DR9 updates as pending Sally's decision. The functional failure is the higher risk. The UX spec can be updated retroactively without re-opening any story.

### Success Criteria

1. `fix/rpe-input-overflow-360dp` merged to `main` with 685/685 tests green.
2. Story 9.1 AC1 in `epics.md` reflects the conditional layout.
3. UX-DR9 in `ux-design-specification.md` documents the phone-width degrade with E9R-3 ratification noted.
4. `action-item-ledger.md` E9R-3 status updated to `closed` with Sally+John decision recorded.
5. No regression in Epic 10 stories — viewport test infra (E9R-2) in place before Story 10.2.

---

## Checklist Completion Summary

| Section | Status |
|---|---|
| 1 — Trigger & Context | [x] All done |
| 2 — Epic Impact | [x] Done; Story 9.1 AC1 requires update |
| 3 — Artifact Conflicts | [!] UX-DR9 and Story 9.1 AC1 need updates (proposals 4.1–4.3) |
| 4 — Path Forward | [x] Option 1 selected |
| 5 — Proposal Components | [x] All sections complete |
| 6 — Final Review & Handoff | Pending user approval |
