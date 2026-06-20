# Story 7.1b — `missedSessions` Decay & Reset — Scope Document

**Date:** 2026-05-15
**Decision owner:** Paolo (Project Lead)
**Participants:** Amelia (Dev), Winston (Architect)
**Status:** Scoped — ready for `bmad-create-story`
**Binding dependency:** ships in same sprint and PR cluster as Story 7.1. If 7.1b is descoped or slips, `active → atRisk` rule from `ai-state-graph-product-decisions-2026-05-15.md` Q1 must be **removed** before 7.1 merge.

---

## Summary

`missedSessions` is currently a field on `StateVector` but its source of truth has been ambiguous. The new state-graph rule `active → atRisk` if `missedSessions >= 2` makes this ambiguity load-bearing. Story 7.1b pins down the semantic, the source, and the implementation.

**Decision in one sentence:** `missedSessions` is **computed on-the-fly from the daily-plan log**, defined as *"count of expected sessions not completed within the last 7 days"*, with no persisted column and no special cold-start logic.

---

## Decisions

### D1 — Storage: computed-on-the-fly (no persistence)

`missedSessions` is **not stored** in any Drift table. It is computed at every `GenerateDailyPlan` invocation from the existing `daily_plans` table (or equivalent log already present in Epic 5/7 schema).

**Rationale:**
- Single source of truth (daily-plan log). No reconciliation drift.
- Zero migration cost.
- Pattern reusable for future `streak` decay (same query shape).
- Cost: one indexed query per daily-plan generation. Negligible on local SQLite.

### D2 — Semantics: total miss within 7-day window

`missedSessions = COUNT(expected_session_days WHERE day ∈ [now-6d, now] AND completed = false)`

- A completed session **does not erase** prior misses in the same window. Misses age out only when they exit the 7-day window.
- A user who completes Monday then skips Tue/Wed/Thu shows `missedSessions = 3` (not 0), preserving the "disengagement" JTBD framing locked in the state-graph decision doc.
- Cap is **implicit** from the window: max value is `min(expectedPerWeek, 7)`.

### D3 — Cold-start and long absence

- **Cold start** (no daily-plan history): `missedSessions = 0` naturally — empty set has zero misses.
- **Long absence** (>7 days inactivity): window is rolling, so older absences exit automatically. No explicit "welcome back" reset logic in 7.1b.
- A possible "courtesy reset" UX prompt on app reopen after 14+ days inactivity is **out of scope** for 7.1b. If desired, file as Story 7.1c after Sally produces copy.

---

## File List

### Create
- `lib/ai/missed_sessions/missed_sessions_calculator.dart` — pure Dart. Input: `(List<DailyPlanRecord> last7Days, int expectedPerWeek, DateTime now)`. Output: `int`.
- `test/ai/missed_sessions/missed_sessions_calculator_test.dart`.

### Modify
- `lib/domain/usecases/generate_daily_plan.dart` (Story 5.5) — inject `MissedSessionsCalculator`, populate `StateVector.missedSessions` from query result.
- `test/domain/usecases/generate_daily_plan_test.dart` — add 2 cases (counter grows / counter stays bounded after long absence).
- `lib/ai/state_machine/behavioral_state_machine.dart` — add new rule `active → atRisk` if `missedSessions >= 2` (priority 1), per state-graph decision Q1. Transition message string per copy decision doc.
- `test/domain/ai/behavioral_state_machine_test.dart` — add tests for new rule (positive, negative, boundary, priority guard with `active → fatigued`).

### NOT touched
- `lib/core/database/tables/behavioral_state_table.dart` — no schema change.
- No Drift migration script.

---

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | Cold-start, no daily-plan records | `GenerateDailyPlan` runs | `StateVector.missedSessions = 0` |
| AC2 | User has 3 daily plans in last 7d, 1 completed | `GenerateDailyPlan` runs | `missedSessions = 2` |
| AC3 | User has 7 daily plans in last 7d, all uncompleted | `GenerateDailyPlan` runs | `missedSessions = 7` (capped only by window, not by `expectedPerWeek`) |
| AC4 | User has 14 daily plans in last 14d, all uncompleted | `GenerateDailyPlan` runs | `missedSessions = 7` (older 7 days are outside the window) |
| AC5 | User completes session today, prior 6 days had 3 misses | `GenerateDailyPlan` runs | `missedSessions = 3` (recent completion does NOT erase prior misses in window) |
| AC6 | `StateVector.missedSessions >= 2` AND current state `active` | `BehavioralStateMachine.evaluate` runs | Transitions to `atRisk`, message *"Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi."* |
| AC7 | `StateVector.missedSessions == 1` | `BehavioralStateMachine.evaluate` runs from `active` | No transition (stays `active`) |
| AC8 | Priority test: `active`, `missedSessions = 2`, `last-2-RPE avg > 8` | Evaluate | `atRisk` wins (priority 1) over `fatigued` (priority 3) |

---

## Test Count

- `missed_sessions_calculator_test.dart`: **8 unit tests** — AC1–AC5, plus boundary tests (`missed = 1`, `missed = 2`, `missed = expectedPerWeek`), plus idempotency test (running twice with no time change returns same count).
- `generate_daily_plan_test.dart`: **+2** integration tests.
- `behavioral_state_machine_test.dart`: **+3** tests covering AC6, AC7, AC8.

**Total:** +13 tests. Baseline 388 → **401**.

---

## Effort Estimate

| Task | Effort |
|---|---|
| `MissedSessionsCalculator` + tests | 0.5 day |
| Wire into `GenerateDailyPlan` use case + tests | 0.5 day |
| New rule `active → atRisk` in state machine + tests + transition message wiring | 0.25 day |
| Integration verification + buffer | 0.25 day |
| **Total** | **~1.5 days dev** |

Sits comfortably in the same sprint as Story 7.1 (~3-4 days estimated for UI work).

---

## Pre-Sprint Verification (blocker check)

**Before committing 7.1b to the Epic 7 sprint**, confirm:

1. Does `daily_plans` table (or the Epic 5/7 equivalent) expose per-day `completionStatus` with the granularity needed for `WHERE completed = false AND date IN window`?
   - **If yes**: 7.1b proceeds as scoped.
   - **If no**: a 2-hour "7.1b-pre" task is needed to expose the column / migration. This must be scoped before sprint start, not discovered mid-sprint.
2. Confirm `expectedPerWeek` is available on `UserProfile` (it should be — Epic 2). If not, fold its addition into 7.1b-pre.

**Owner of verification:** Amelia, before Epic 7 sprint planning.

---

## Out of Scope (explicit)

- "Welcome back" courtesy reset after long absence — possible Story 7.1c, requires Sally copy.
- `streak` decay with same pattern — future story, design-compatible but not implemented here.
- Performance optimization of the daily-plan query — current SQLite local cost is negligible; optimize when profiling shows a need.
- UI surfacing of `missedSessions` directly — `StateIndicator` (Story 7.1) consumes the resulting `BehavioralState`, not the raw counter.

---

## Decision Record

| Q | Amelia | Winston | Final (Paolo) |
|---|---|---|---|
| Q1 semantics | Decrement-by-1 saturating | Reset-to-0 on completion, 7d window | **Total miss in 7d window (Amelia)** — preserves JTBD framing of disengagement |
| Q2 cold-start | Counter persists, capped at `expectedPerWeek` | Dissolved by rolling window | **Rolling window (Winston) — no special logic** |
| Q3 storage | Computed-on-the-fly | Computed-on-the-fly | **Computed-on-the-fly** ✅ |

---

## Sign-off

- 💻 Amelia (Dev) — agreed; AC IDs and test count locked.
- 🏗️ Winston (Architect) — agreed; no persistence, no migration, pattern reusable for `streak`.
- 👤 Paolo (Project Lead) — final decisions recorded above.

This scope is ready for `bmad-create-story` to author `story-7.1b-missed-sessions-decay.md` under `_bmad-output/implementation-artifacts/`. Story file creation owned by the user (per CLAUDE memory note: only edit `epics.md`, never pre-create files in `implementation-artifacts/`).
