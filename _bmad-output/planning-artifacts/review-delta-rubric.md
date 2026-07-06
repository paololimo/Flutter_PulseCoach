# PRD Delta Review — Experience Polish (v1)

**Scope:** Only the 2026-07-06 delta — FR78–FR82 (Functional Requirements → Experience Polish v1) and NFR38–NFR39 (Non-Functional Requirements → Experience Polish v1) in `prd.md`, with `addendum.md` as supporting context. The rest of the PRD is out of scope.

**Gate verdict: PASS-WITH-FIXES**

## Overall assessment

This is a well-constructed delta. Cross-references resolve cleanly (FR13/FR14, FR20, FR23, NFR2, NFR7, NFR9 all exist and are used correctly), IDs are contiguous (FR76/FR77 precede FR78–82; NFR38–39 follow NFR37 with no gap), and the capability-vs-mechanism split is disciplined — the heavy implementation detail (net-new `flutter_local_notifications` dependency, iOS ActivityKit rationale, timeout default, single-source-of-truth wiring) correctly lives in the addendum, not in the FRs. NFR38 and NFR39 are genuinely strong: they carry product-specific bounds (60fps/16ms, reduce-motion degradation, POST_NOTIFICATIONS rationale, non-sensitive-content constraint) rather than NFR boilerplate.

What holds it back from a clean PASS is done-ness clarity on three edge/boundary conditions the FRs leave undefined (streak reset/timezone, rapid background↔foreground toggling, single-step milestone rendering) and one mis-applied `[ASSUMPTION]` tag. None are blockers; all are one-to-two-sentence fixes.

## Done-ness clarity — thin

The happy paths are testable, but several boundary conditions have no acceptance signal — and this is exactly the dimension story creation leans on.

### Findings

- **[high]** Streak reset / timezone / DST rules undefined (FR81) — "count of consecutive calendar days with at least one completed session." Which timezone defines a "calendar day" (device-local, and what happens on travel/DST)? What resets the streak — one missed day, and is a session at 00:05 vs 23:55 handled? Does an abandoned session count? An engineer cannot write acceptance tests for "consecutive" without these. *Fix:* add one sentence specifying device-local calendar day, streak breaks after one full calendar day with zero completed sessions, and reset semantics; or add a `[NOTE FOR PM]` if genuinely open.
- **[medium]** Rapid background↔foreground toggle behavior unspecified (FR80) — FR80 defines pause-on-background and resume-on-return, plus an inactivity-timeout abandon. It does not say how the timeout behaves under repeated toggling: does each foreground reset the timer, does paused time accumulate across multiple background episodes, and is there a debounce? This is the classic race the prompt flags. *Fix:* state that the inactivity timer measures cumulative (or most-recent) background dwell, and that re-entry resets it.
- **[medium]** Configurable inactivity timeout has no default/bound in the FR (FR80) — "After a configurable inactivity timeout…" The default is marked TBD in the addendum, which is fine for the *value*, but the FR is not independently testable without at least a bound (e.g., "default in the 2–10 min range, TBD"). *Fix:* carry a provisional default or explicit range into FR80, or a `[NOTE FOR PM]`.
- **[low]** Single-step (or zero-intermediate-boundary) session milestone rendering undefined (FR78) — "intermediate milestone markers at each session-step boundary." If a session has one step, there are no intermediate boundaries; the FR does not say whether the bar shows only start + finish flag, or degrades some other way. *Fix:* one clause covering the 1-step case (start + finish marker only).

## Scope honesty / assumptions — adequate

Scope decisions are stated openly: humidity exclusion (FR82) is recorded inline with a date and rationale, and the iOS limitation (FR79) is named rather than hidden. Good.

### Findings

- **[medium]** FR79 `[ASSUMPTION]` is really a scope/platform decision, not an inference — the tag introduces "Android-primary capability: on iOS … best-effort … without a guaranteed live-updating timer." That is a deliberate de-scope the team is choosing, not an unconfirmed inference about the user's intent. Mis-tagging it as `[ASSUMPTION]` weakens the signal (an `[ASSUMPTION]` invites confirm/deny; this wants acknowledgement as a decision). *Fix:* re-tag as `[NON-GOAL for MVP]` / platform-constraint decision, or `[NOTE FOR PM]` if iOS parity is still an open question. The FR81 `[ASSUMPTION]` (reuse FR23 signal) is borderline-legitimate — it is an inferred design constraint the user may not have confirmed — so leave it, though it also reads partly as a decision.
- **[low]** No Assumptions Index roundtrip — the delta adds inline `[ASSUMPTION]` tags (FR79, FR81) but the PRD has no Assumptions Index section to register them (pre-existing condition, not introduced by the delta). Mechanical, but the checklist calls for the roundtrip. *Fix:* if an index exists elsewhere, add these two; otherwise note as a known PRD-wide gap.

## Implementation leakage — strong

The FRs stay at capability altitude. Observable-behavior specifics that might look like leakage ("not swipe-dismissible" in FR79, "checkered flag" in FR78) are legitimately part of the *observable capability* and acceptance signal, not mechanism. The genuine mechanism — dependency choice (`flutter_local_notifications`), iOS Live Activities rationale, single-source-of-truth wiring to `BehavioralStateMachine`, timeout default — is all correctly quarantined in `addendum.md §Experience Polish mechanism notes`. No fixes required.

## Cross-reference integrity — strong

All referenced IDs resolve: FR13, FR14 (FR82), FR20 (FR80), FR23 (FR81), NFR2 (NFR38), NFR7 and NFR9 (NFR39). Internal delta refs (FR78↔NFR38, FR79↔FR80↔NFR39, FR81↔NFR38, FR82↔NFR38) are consistent and bidirectional. ID sequence is contiguous with no duplicates or gaps.

## Completeness of acceptance signals — adequate

- FR78: celebratory-animation accessibility is **covered** — NFR38 explicitly requires reduce-motion degradation to static equivalents for the finish animation. Good closure of a gap that often gets missed.
- FR79/FR80/NFR39: notification content-sensitivity and permission-denial paths are covered by NFR39 + FR80 graceful degradation. Solid.
- Remaining gaps are the four Done-ness findings above.

## Summary of fixes (priority order)

1. **[high]** FR81 — specify streak calendar-day timezone + reset semantics.
2. **[medium]** FR80 — define rapid toggle / timeout-accumulation behavior.
3. **[medium]** FR80 — carry a provisional default/bound for the inactivity timeout.
4. **[medium]** FR79 — re-tag the iOS `[ASSUMPTION]` as a scope/platform decision.
5. **[low]** FR78 — cover the single-step session milestone case.
6. **[low]** Register the new inline `[ASSUMPTION]` tags in an Assumptions Index (PRD-wide gap).
