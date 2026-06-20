# Retro Action Item Ledger

## Ledger Review Protocol

At every retro, the facilitator opens this file and adds a dated subsection titled `## Retro Review - Epic N (YYYY-MM-DD)`. For each `pending` item: reconfirm owner + target, or change status to `dropped` with rationale. For each `done` item added since last review: no action. New action items from the current retro are appended as new rows at the bottom of the relevant retro's table.

Allowed statuses: `pending`, `in-progress`, `done`, `dropped`.

## Epic 5 Retro - 2026-05-14

| # | Source Retro | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E5-P1 | Epic 5 Retro (2026-05-14) | Split future orchestration stories when they combine persistence, concurrency, DI, BLoC, and domain assembly | Amelia (Developer) | Ongoing process | done | Epic 6 delivered three well-scoped stories; confirmed in Epic 6 retro. |
| E5-P2 | Epic 5 Retro (2026-05-14) | Promote `flutter analyze` cleanup into closure criteria | Amelia (Developer) | Story 6.5.1 | done | Story 6.5.1 reduced analyzer output to zero issues on 2026-05-15. |
| E5-P3 | Epic 5 Retro (2026-05-14) | Track retro action items outside prose | Alice (Product Owner) | Story 6.5.3 | done | This ledger is the dedicated tracking artifact. |
| E5-T1 | Epic 5 Retro (2026-05-14) | Resolve real analyzer warnings: unused imports and unused local variables | Amelia (Developer) | Story 6.5.1 | done | Story 6.5.1 fixed all pre-existing analyzer warnings. |
| E5-T2 | Epic 5 Retro (2026-05-14) | Review AI state-graph product semantics before wiring Today UI | Alice (Product Owner) + Winston (Architect) | Before Story 7.1 | done | Closed 2026-05-16 (Epic 7 retro). Decisions captured in `ai-state-graph-product-decisions-2026-05-15.md` and implemented in Stories 7.1 (Q2 + Q3) and 7.1b (Q1). |
| E5-T3 | Epic 5 Retro (2026-05-14) | Make Epic 6 catalog model satisfy Epic 5 safety needs | Winston (System Architect) | Story 6.1 | done | `indoorCompatible`, `outdoorCompatible`, and real `durationMinutes` are enforced via `_enrichPlanWithCatalog`. |
| E5-T4 | Epic 5 Retro (2026-05-14) | Keep deferred explanation issues visible for Epic 7 | Sally (UX Designer) | Before Story 7.1 | done | Closed 2026-05-16 (Epic 7 retro). Decisions captured in `explanation-copy-product-decisions-2026-05-15.md`; 15 canonical Italian keys shipped in `state_messages.it.arb` via Story 7.1. |
| E5-T5 | Epic 5 Retro (2026-05-14) | ExerciseDB API isolation from weather API client | Amelia (Developer) | Story 6.1 | done | Separate base URL lives in `api_constants.dart`; no weather assumptions are inherited. |

## Epic 6 Retro - 2026-05-15

| # | Source Retro | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E6-P1 | Epic 6 Retro (2026-05-15) | Patch-validation gate after review patches touch DI, lifecycle, or cross-cutting concerns | Amelia (Developer) | Ongoing process | pending | Story 6.3 needed round 2 because round-1 patches introduced singleton-lifecycle and pubspec gaps. |
| E6-P2 | Epic 6 Retro (2026-05-15) | Action item ledger in `sprint-status.yaml` or sibling artifact | Alice (Product Owner) | Story 6.5.3 | done | This file establishes the sibling artifact. |
| E6-T1 | Epic 6 Retro (2026-05-15) | `flutter analyze` cleanup sprint to zero warnings | Amelia (Developer) | Story 6.5.1 | done | Story 6.5.1 confirmed zero analyzer issues on 2026-05-15. |
| E6-T2 | Epic 6 Retro (2026-05-15) | Fix AppShell tab order to `Sessions, Today, Progress` | Amelia (Developer) | Story 6.5.1 | done | Story 6.5.1 updated the AppShell order and related widget tests. |
| E6-T3 | Epic 6 Retro (2026-05-15) | Defense-in-depth: `sessionType` normalization and logging | Amelia (Developer) | Story 6.5.2 | done | Story 6.5.2 added normalization/logging coverage with tests `6.5-UNIT-001` through `6.5-UNIT-003`. |
| E6-T4 | Epic 6 Retro (2026-05-15) | Defense-in-depth: fallback ID uniqueness at load time | Amelia (Developer) | Story 6.5.2 | done | Story 6.5.2 added duplicate-ID handling coverage with test `6.5-UNIT-004`. |
| E6-T5 | Epic 6 Retro (2026-05-15) | AI state-graph product semantics review | Alice (Product Owner) + Winston (Architect) | Before Story 7.1 | done | Closed 2026-05-16 (Epic 7 retro). Same carry-over as E5-T2 — see that row for evidence. |
| E6-T6 | Epic 6 Retro (2026-05-15) | Explanation copy product review for Today screen | Sally (UX Designer) + Alice (Product Owner) | Before Story 7.1 | done | Closed 2026-05-16 (Epic 7 retro). Same carry-over as E5-T4 — see that row for evidence. |
| E6-T7 | Epic 6 Retro (2026-05-15) | ExerciseDB remote mapping revisit | Winston (System Architect) | Post-MVP decision | pending | Heuristic mapping is hardened but marginal; explicit product decision needed before further investment. |
| E6-T8 | Epic 6 Retro (2026-05-15) | Memoize fallback JSON decode through `loadFallbackExercisesByType` | Amelia (Developer) | When performance is measured | pending | Deferred from Story 6.2; re-evaluate when cold-start performance is surfaced in Epic 7. |

## Epic 7 In-Sprint Findings - 2026-05-16

In-sprint findings surfaced during on-device verification (not from a formal retro). PM (John) to triage at Epic 7 retro alongside the carry-over closures noted below.

**Carry-overs ready for closure at Epic 7 retro:** `E5-T2` + `E6-T5` (AI state-graph review) are satisfied by `ai-state-graph-product-decisions-2026-05-15.md`. `E5-T4` + `E6-T6` (explanation copy review) are satisfied by `explanation-copy-product-decisions-2026-05-15.md`. Closing these four brings the pending count from 7 → 3 before the new entry below is added (final count after Epic 7 retro triage: 4, within the 5-per-epic cap).

| # | Source | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E7-F1 | On-device verification (2026-05-16) | Daily-plan session completion does not persist across app force-stop/relaunch (ring resets 3/3 → 0/3, completed cards disappear) | Amelia (Developer) | Story 8.0 — SessionLog DAO + per-session persistence | done | Closed 2026-05-17 (Epic 8 Kickoff Triage). Story 8.0 shipped SessionLog DAO + per-session persistence (commit `b7996b7`); Story 8.2 code review (2026-05-17) added `SessionLogsDao.watchLogsForPlan(int)` + `TodaySessionCubit.planLoaded` `.skip(1)` subscription, making the DB the single source of truth across writers. Regression locked by test `8.2-CUBIT-007`. CLAUDE.md "Manual Verification Notes" reconciliation line confirms closure. |

## Epic 7 Retro - 2026-05-16

Carry-over closures recorded in Epic 5 and Epic 6 tables above (E5-T2, E5-T4, E6-T5, E6-T6 → all `done`). Status of E6-T7 and E6-T8 reconfirmed `pending` (post-MVP / perf-trigger conditions still unmet). E7-F1 promoted from `pending` to `in-progress` against Story 8.0. New action items below.

| # | Source Retro | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E7-P1 | Epic 7 Retro (2026-05-16) | i18n / `gen_l10n` migration — promote 3-story deferral to dedicated interstitial Epic 7.5 | Amelia (Developer) + Sally (UX) | Epic 7.5 (2 stories cap) | done | Closed 2026-05-16 (Epic 7.5 retro). Both stories shipped within 2-story cap: 7.5.1 wired `flutter_localizations` + `gen_l10n` (commit `0b9e6ea`); 7.5.2 migrated all Epic 7 Italian strings to ARB and deleted `state_messages.it.arb` (commit `f32ec29`); `"COMING UP"` → `"PROSSIME"`; 516/516 tests; `flutter analyze` clean. |
| E7-P2 | Epic 7 Retro (2026-05-16) | Pre-flight architect identity-vs-position review for Cubit/BLoC stories with collection-index state | Winston (Architect) during story-creation | Ongoing process | pending | Triggered on any story introducing a Cubit/BLoC where state holds an index into a collection. Avoids the Story 7.3 pattern where positional-completion bug was caught only in code review. |
| E7-P3 | Epic 7 Retro (2026-05-16) | Update Edge-Case Hunter prompt — `Hero` inside `AnimatedSwitcher` cross-fade collision check + Cubit `start()` idempotency invariant (E8-P1 extension) | Amelia (Developer) — code-review skill maintenance | Before Epic 8 starts (missed; closed at Epic 9 kickoff hard-gate per E8-P2) | done | Closed 2026-05-20. `bmad-review-edge-case-hunter/SKILL.md` Step 2 amended with a "Project-specific recurring traps" block enumerating: (a) `Hero` inside `AnimatedSwitcher` cross-fade collision (origin: Story 7.3, caught at 7.4 review); (b) Cubit/BLoC `start()` idempotency invariant + companion invariants for dispose/close, persistence-error state, and abandon-vs-complete mutual exclusion (origin: Stories 8.2/8.3/8.4; standardized as E8-P1). Block lives inside the method-driven Step 2 so it adds explicit triggers without converting the prompt into a fixed checklist. E8-P2 hard gate item (1) now satisfiable on next triage reopen. |
| E7-T1 | Epic 7 Retro (2026-05-16) | Add `vibration` package to pubspec | Amelia (Developer) | Before Story 8.3 enters sprint | done | Closed 2026-05-16 (Epic 7.5 retro). `vibration: ^3.1.8` already present in `pulse_coach/pubspec.yaml` line 50 (confirmed during Story 7.5.1 Dev Notes; precondition for Story 8.3 already satisfied). CLAUDE.md "Feature Context" line stating "not yet in pubspec" is stale and should be updated at next CLAUDE.md edit. |
| E7-T2 | Epic 7 Retro (2026-05-16) | Golden / viewport test infrastructure for above-the-fold AC verification | Dana (QA) | Epic 11 (Responsive Layout) kickoff | done | Closed by Story 10.2 (2026-05-26). `test/helpers/viewport_helper.dart` adds a reusable 360x800dp surface helper and `progress_charts_test.dart` applies it to all four Progress chart widgets, making phone-width layout regressions visible in CI. |

## Epic 7.5 Retro - 2026-05-16

Carry-over closures recorded in Epic 7 table above (E7-P1 → done via Epic 7.5 stories shipping; E7-T1 → done — `vibration` already in `pubspec.yaml` line 50, precondition satisfied). Status of E6-P1, E6-T7, E6-T8, E7-P2, E7-P3, E7-T2, E7-F1 reconfirmed `pending`/`in-progress` (triggers not yet met). New action items below.

**⚠️ Deferred Items Budget breach.** After Epic 7.5 retro closures + additions, pending count is **11** (E6-P1, E6-T7, E6-T8, E7-F1 [in-progress], E7-P2, E7-P3, E7-T2, E7.5-T1, E7.5-P1, E7.5-P2 = 10 `pending` + 1 `in-progress`). Cap is **5**. PM (John) triage required at Epic 8 kickoff: close, drop, promote to scheduled story, OR formally rewrite the CLAUDE.md budget rule to distinguish "ongoing-process" items from "deliverable-debt" items with separate caps. Story 8.0 should not enter sprint under a strict reading of the rule.

| # | Source Retro | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E7.5-P1 | Epic 7.5 Retro (2026-05-16) | Flutter deprecation pre-check during story-creation for SDK-version-sensitive specs | Winston (Architect) during create-story | Ongoing process | pending | Triggered on any story touching l10n config, build config, plugin registrations, or borderline-deprecated Flutter APIs. Story spec must cross-reference the pinned Flutter SDK version against known deprecations before AC text is finalized. Avoids the Story 7.5.1 `synthetic-package` mid-flight Correct-Course pattern (Flutter 3.41.6 rejects the key; LLM training data still emitted it). |
| E7.5-P2 | Epic 7.5 Retro (2026-05-16) | Rework AC7-style integer-delta test-count guardrails to invariant-based form | Amelia (Developer) during story-creation | Before next story that would specify a `+N tests` cap | pending | Replace `"test count grows by at most +N"` with three invariants: (1) zero existing tests removed, (2) all existing tests still green, (3) new tests added for this story's ACs are present and passing. Rationale: Story 7.5.1 AC7 capped at +3 but actual delta was +13 because Epic 7 traceability tests landed in the same baseline window — magnitude-based caps trip falsely on parallel valid work. |
| E7.5-T1 | Epic 7.5 Retro (2026-05-16) | Wire 7 dead ARB `transition*` keys through `BehavioralStateMachine` consumer | Amelia (Developer) + Winston (Architect) | Epic 9.x story (re-targeted from Epic 8.x at Epic 8 Kickoff Triage, 2026-05-17) | done | Closed 2026-05-22 by Story 9.3. `BehavioralStateMachine.evaluate()` now emits `BehavioralTransitionKey` values instead of hardcoded Italian literals; `StateIndicator` resolves transition keys through `AppLocalizations`; `DailyPlanBloc` exposes inferred transition keys to Today. Regression coverage updated in `behavioral_state_machine_test.dart`, `state_indicator_test.dart`, and `daily_plan_bloc_test.dart`. |

## Epic 8 Kickoff Triage - 2026-05-17

PM (John) ran triage to resolve the Deferred Items Budget breach surfaced in the Epic 7.5 retro (11 open vs cap of 5). Triage produced two outcomes: (1) E7-F1 closed as `done` because Story 8.0/8.2 shipped the deliverable + regression-locked it; (2) the CLAUDE.md budget rule was rewritten to split Category A (Deliverable Debt, capped at 5) from Category B (Ongoing Process Rules, uncapped + sunset-reviewed every 2 epics). No items were dropped to fit the original cap — the cap itself was the wrong shape.

**Post-triage state**

Category A — Deliverable Debt (5 / 5 at cap):
- `E6-T7` — ExerciseDB remote mapping revisit (post-MVP decision pending)
- `E6-T8` — Memoize fallback JSON decode (trigger: perf measurement)
- `E7-P3` — Update Edge-Case Hunter prompt for `Hero`-in-`AnimatedSwitcher` (before Epic 8 starts — treated as deliverable because it has a hard "before Epic 8" target)
- `E7-T2` — Golden / viewport test infrastructure (Epic 11 kickoff)
- `E7.5-T1` — Wire 7 dead ARB `transition*` keys through `BehavioralStateMachine` (Epic 8.x story)

Category B — Ongoing Process Rules (5 active, uncapped):
- `E6-P1` — Patch-validation gate after review patches touch DI / lifecycle / cross-cutting concerns
- `E7-P2` — Pre-flight architect identity-vs-position review for Cubit/BLoC stories with collection-index state
- `E7.5-P1` — Flutter deprecation pre-check during story-creation for SDK-version-sensitive specs
- `E7.5-P2` — Rework AC7-style integer-delta test-count guardrails to invariant-based form (fires on next story specifying a `+N tests` cap; transitions to retired when next such story uses invariants)

(Note: `E7-P3` is targeted at "before Epic 8 starts" with a concrete deliverable — the prompt update itself — so it sits in Category A despite the prompt-engineering shape. Once landed and the next code review uses the updated prompt without regression, it can be retired.)

Closed at triage:
- `E7-F1` — Daily-plan session completion does not persist (Story 8.0 + Story 8.2 follow-up shipped; row updated above)

**Sprint gate**

With Category A at exactly 5 and the rule rewritten, the gate that blocked Story 8.0 entry is lifted. Epic 8 sprint cleared to open. Next Category B sunset review: at Epic 9 kickoff (covering Epic 8 + Epic 9, 2-epic cadence).

**Epic 8 closure scope decision (2026-05-17, Option B)**

Epic 8 was originally scoped 8.0 → 8.5 (six stories). Stories 8.0–8.4 are shipped. The remaining work is Story 8.5 (Session Abandon Flow) — already specified in `epics.md` lines 1402–1420. `E7.5-T1` (dead ARB `transition*` keys) was a candidate for Story 8.6, but is re-targeted to Epic 9.x because:

1. It is thematically off-brand for Epic 8 ("In-Session Experience"). Forcing an i18n migration into a session-focused epic mixes concerns.
2. The dead keys are inert — `BehavioralStateMachine` still emits literals that work correctly for the locale-locked `it` user. There is no user-facing regression while it sits in Category A.
3. Keeping it in Category A as a single tracked item is cheaper than building an Epic 8.x interstitial just to host it.

Epic 8 therefore closes with **Story 8.5 only** as the remaining queue item. Sunset review (E8-K2) and any new findings will populate Epic 9 kickoff triage.

| # | Source | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E8-K1 | Epic 8 Kickoff Triage (2026-05-17) | Rewrite Deferred Items Budget rule in CLAUDE.md to split Category A (Deliverable Debt, capped at 5) from Category B (Ongoing Process Rules, uncapped + sunset-reviewed) | John (PM) | Epic 8 kickoff | done | Closed 2026-05-17. CLAUDE.md "Deferred Items Budget (process rule)" section rewritten; historical-note paragraph documents the original single-cap form and the breach that triggered the split. |
| E8-K2 | Epic 8 Kickoff Triage (2026-05-17) | First Category B sunset review | John (PM) | Epic 9 kickoff | pending | Walk Category B items (E6-P1, E7-P2, E7.5-P1, E7.5-P2, plus any added during Epic 8) and decide: still useful / now automated / safe to retire. Record rationale per item. |

## Epic 8 Retro - 2026-05-18

Carry-over updates from Epic 8 retrospective (file: `epic-8-retro-2026-05-18.md`):

- `E7-F1` reconfirmed `done` (closure mechanism is durable: Story 8.0 schema + Story 8.2 `watchLogsForPlan` stream subscription with `.skip(1)` in `TodaySessionCubit`).
- `E7-P3` remains `pending` — target "before Epic 8 starts" expired without action. **Promoted to Epic 9 kickoff hard gate under E8-P2.** Trigger condition (`Hero` inside `AnimatedSwitcher`) did not recur in Epic 8 so latent miss cost nothing this epic, but the commitment is unmet.
- `E7.5-P2` remains `pending` — *triggered and ignored* during Epic 8 (every story used `expect(userFacingKeys, hasLength(N))` magnitude-based ARB-count assertions; Story 8.5 review deferred as "pre-existing"). Target updated from "next story specifying +N tests cap" to **"Story 9.1 spec must use invariant guardrails; closes at 9.1 merge"**. Promoted to Epic 9 kickoff hard gate under E8-P2.
- `E7.5-T1` remains `pending` — target updated to **"Story 9.3 stretch (if `BehavioralStateMachine.evaluate()` signature is already being touched) or Story 9.4 firm"**.
- `E6-T7`, `E6-T8`, `E7-T2` reconfirmed `pending` (trigger conditions still unmet).
- `E6-P1`, `E7-P2`, `E7.5-P1` reconfirmed `pending` (Category B ongoing process; not triggered or partially triggered in Epic 8).

New items below.

| # | Source Retro | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E8-P1 | Epic 8 Retro (2026-05-18) | Standardized "Cubit lifecycle invariants" AC set for create-story | Amelia (Developer) + Winston (Architect) during create-story | Ongoing process; first application Story 9.1 | pending | Triggered on any story creating or extending a Cubit/BLoC with timers, streams, or async I/O. Spec includes a fixed AC set covering: (a) `start()` idempotency — second call is no-op; (b) `dispose/close()` cancels all timers and stream subscriptions; (c) persistence-error paths emit explicit state (not `debugPrint`-only); (d) abandon/complete navigation is mutually exclusive (separate flags). At least one test per invariant. Rationale: Edge Case Hunter found `start()` non-idempotent in 8.2/8.3/8.4 consecutively; DAO errors swallowed in 5/6 stories; abandon-complete race persisted across 3 stories. |
| E8-P2 | Epic 8 Retro (2026-05-18) | Hard gate at Epic 9 kickoff: E7-P3 + E7.5-P2 closed before Story 9.1 enters sprint | John (PM) at Epic 9 kickoff triage | Epic 9 kickoff | done | Closed 2026-05-20 (Epic 9 Kickoff Triage, blocking half satisfied). (1) **E7-P3 → done** (2026-05-20): `.claude/skills/bmad-review-edge-case-hunter/SKILL.md` Step 2 amended with "Project-specific recurring traps (Flutter_PulseCoach)" sub-block covering `Hero`-in-`AnimatedSwitcher` collision check + Cubit start-idempotency invariant (plus E8-P1 companion invariants). (2) **E7.5-P2 → still pending, soft-tracking**: closes structurally at Story 9.1 merge when `state_indicator_test.dart` adopts the invariant pattern already inherited as AC in `epics.md` Story 9.1. Soft half does not block sprint entry; Story 9.1 is cleared. Both expired/ignored Epic 7.5 commitments are now either closed (E7-P3) or hard-wired into Story 9.1 ACs (E7.5-P2). |
| E8-P3 | Epic 8 Retro (2026-05-18) | Schema-bump cadence cap during story-creation | Winston (Architect) during create-story | Ongoing process | pending | Triggered on any story proposing `schemaVersion++`. Spec must explicitly declare why the bump cannot be consolidated with any pending bump in the same epic. Rationale: Story 8.0 went v4→v5 then same-day review patch forced v6 (UNIQUE+FK CASCADE), then Story 8.5 went v7. Three migrations in 48 hours forced composite migration tests to be rebuilt twice (v3→v6 then v3→v7). |
| E8-T1 | Epic 8 Retro (2026-05-18) | Project-wide logger replacement for `debugPrint` in error paths | Amelia (Developer) | First Epic 9.x story that touches `lib/core/error/` or introduces a new persistence error path | done | Closed by Story 10.0 (2026-05-24). `AppLogger` centralizes structured logging; `debugPrint` is removed from `lib/`; scattered `developer.log` call sites converge through the logger; DAO persistence failures in `InSessionCubit` and `TodaySessionCubit` emit observable `persistenceError` state while session UX continues. |
| E8-V1 | Epic 8 Retro (2026-05-18) | Story 8.5 abandon flow on-device smoke verification | Paolo (Project Lead) | Next physical device session | pending | Story 8.5 manual smoke was skipped (`adb devices` returned empty). Abandon-confirmation bottom sheet has not been physically exercised on the Samsung A520F. Not gating Epic 8 closure; flagged as residual readiness item. |

## Epic 9 Kickoff Triage - 2026-05-20

PM (John) ran the Epic 9 kickoff triage covering: (1) Category B sunset review per E8-K2 cadence; (2) verification of the E8-P2 hard gate (E7-P3 + E7.5-P2 closure status before Story 9.1 enters sprint); (3) Category A snapshot reconfirmation. Triggered by the `bmad-correct-course` Sprint Change Proposal of the same date (file: `sprint-change-proposal-2026-05-20.md`) which expanded Story 9.1 / 9.3 ACs to surface E8-P1, E8-P2, E8-P3, E7.5-T1 at the spec-creation entry point.

**Category B sunset review (6 items, 2-epic cadence per E8-K2)**

| Item | Triggered in Epic 8? | Decision | Rationale |
|---|---|---|---|
| `E6-P1` (Patch-validation gate after DI/lifecycle/cross-cutting review patches) | **Triggered-and-ignored** — Story 8.0 review patch v5→v6 (UNIQUE + FK CASCADE) was a textbook cross-cutting concern; Epic 8 retro did not flag it | Keep + **strengthen** | Same pattern as E7.5-P2 (rule with relative trigger fires unnoticed). New item `E9-K1` opened below to add an explicit fire-check at story-creation, not only at review. |
| `E7-P2` (Architect pre-flight for Cubit/BLoC with collection-index state) | Not triggered (Epic 8 = timer/HR/abandon, no index state) | Keep dormant | Re-relevant in Epic 10 (timeline = collection-index). Next sunset review at Epic 11 kickoff. |
| `E7.5-P1` (Flutter deprecation pre-check at story-creation for SDK-sensitive specs) | Not triggered (Epic 8 no l10n/build/deprecated APIs) | Keep dormant | Standing rule, low cost. Next sunset review at Epic 11 kickoff. |
| `E8-P1` (Cubit-lifecycle invariants AC template) | First application = Story 9.1 (created at Epic 8 retro) | Keep active | Operationalized via `epics.md` Story 9.1 + 9.3 ACs (edits 2026-05-20 per Sprint Change Proposal). `bmad-create-story` will inherit. |
| `E8-P2` (Hard gate Epic 9 kickoff: E7-P3 + E7.5-P2) | **Firing now** | Processed inline (see Hard Gate section below) | This triage is the gate. |
| `E8-P3` (Schema-bump cadence cap at story-creation) | Will trigger at Story 9.1 (`rpe_feedback` table v7 → v8) | Keep active | Already referenced as AC in `epics.md` Story 9.1 (edit 2026-05-20). |

**No items retired.** All Category B items have reasonable future triggers; sunset cadence respected; next review at Epic 11 kickoff.

**E8-P2 hard gate verification**

| Sub-condition | Status at triage | Closure path | Blocks Story 9.1 sprint entry? |
|---|---|---|---|
| E7-P3 — Edge-Case Hunter prompt update (Hero-in-AnimatedSwitcher + Cubit start-idempotency checks) | `done` (closed 2026-05-20 by Amelia — `.claude/skills/bmad-review-edge-case-hunter/SKILL.md` Step 2 amended with "Project-specific recurring traps" block covering both checks) | Closed inline. | No — closed |
| E7.5-P2 — invariant-based ARB test guardrails | `pending` (target = "applied at Story 9.1 spec, closes at 9.1 merge") | Already inherited as AC in `epics.md` Story 9.1 (edit 2026-05-20). Closes structurally when Story 9.1 merges with the invariant pattern in `state_indicator_test.dart`. | Soft — closes at 9.1 merge, not blocking sprint entry |

**Hard gate verdict at this triage:** ~~**NOT PASSED.**~~ → **PASSED (E7-P3 sub-condition)** as of 2026-05-20. E7-P3 closed by Amelia; the Edge-Case Hunter prompt now carries both checks. E7.5-P2 remains soft (closes at Story 9.1 merge, not blocking sprint entry). **E8-P2 → done** for the blocking half; the soft half tracks structurally with Story 9.1. Story 9.1 is now cleared to enter sprint.

**Category A snapshot (post-triage)**

5 / 5 at cap, unchanged from Epic 8 retro readiness assessment:
- `E6-T7` — ExerciseDB remote mapping revisit (post-MVP)
- `E6-T8` — memoize fallback JSON decode (perf-trigger)
- `E7-T2` — golden/viewport test infrastructure (Epic 11 kickoff)
- `E7.5-T1` — ARB transition keys wiring (Story 9.3 stretch / 9.4 firm, per Epic 8 retro re-target)
- `E8-T1` — logger replacement for `debugPrint` in error paths (first Epic 9.x story touching `lib/core/error/` or new persistence error path)

**Cannot add new Category A items until one closes.** E7.5-T1 is the most likely near-term closure (Story 9.3 spec window).

**Unblock sequence**

```
NOW: triage outcome recorded in this ledger entry
  ↓
NEXT: Amelia closes E7-P3 (edit Edge-Case Hunter skill prompt)
  ↓
THEN: John re-opens this triage to confirm E8-P2 → done
  ↓
THEN: bmad-create-story for Story 9.1 (inherits E8-P1, E7.5-P2, E8-P3 from epics.md)
```

**Triage outcome — final (2026-05-20, same-day continuation)**

E7-P3 closed by Amelia within the same triage session via edit to `.claude/skills/bmad-review-edge-case-hunter/SKILL.md`. Triage re-opened inline by John (PM) and:

- E8-P2 row above flipped from `pending` → `done` (blocking half). Soft half (E7.5-P2) remains `pending` and closes structurally at Story 9.1 merge — non-blocking for sprint entry.
- **Story 9.1 is cleared to enter sprint.** Next action: `bmad-create-story` for Story 9.1, which will inherit E8-P1 (Cubit-lifecycle invariants), E7.5-P2 (invariant-based test guardrails), and E8-P3 (schema-bump cadence justification) from the expanded ACs in `epics.md` (2026-05-20 edits).
- Empirical smoke check of the updated Edge-Case Hunter prompt: deferred to the first Epic 9 code review that touches `AnimatedSwitcher`/`Hero` or a Cubit with `start()` — Story 9.1's `RpeFeedbackCubit` is a likely candidate.


| # | Source | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E9-K1 | Epic 9 Kickoff Triage (2026-05-20) | Strengthen `E6-P1` with an explicit fire-check at story-creation, not only at code-review | John (PM) + Amelia (Developer) during create-story | Ongoing process | pending | Story 8.0 review patch v5→v6 (UNIQUE + FK CASCADE) was a textbook cross-cutting concern that should have fired E6-P1; the rule fired silently and was not addressed. Same anti-pattern as E7.5-P2 (triggered-and-ignored). Add a fire-check at `bmad-create-story` time: if the spec proposes review-patches likely touching DI/lifecycle/cross-cutting concerns, surface E6-P1 explicitly in the spec template. Category B (ongoing process), uncapped. |

---

## Epic 9 Retro - 2026-05-24

Retro for Epic 9 (Feedback & Adaptation Loop, 3 stories). Full document: `epic-9-retro-2026-05-24.md`. Paolo (Project Lead) confirmed four decisions; recorded below.

**Closures / status changes from this retro:**

- **E7.5-T1 → `done`** (already flipped 2026-05-22 by Story 9.3; reconfirmed here). 7 dead ARB `transition*` keys wired via `BehavioralTransitionKey` end-to-end. **Frees one Category A slot.**
- **E8-T1 → promoted to a scheduled Epic 10 story** (see `epics.md` Story 10.0). Was *triggered-and-ignored* in Epic 9: Story 9.1 was the trigger ("first Epic 9.x story introducing a new persistence error path") but only the symptom was mitigated (explicit error states) — the centralized-logger deliverable was not built. Stays Category A until the story ships.
- **E7-T2 → re-targeted from Epic 11 to "before Story 10.2"** (see action item E9R-2). Viewport/golden test infra at 360dp; the RPE overflow (`9.1-WIDGET-005`) is the precedent — widget tests at the default 800dp surface miss phone-width layout failures.

**New action items:**

| # | Source | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E9R-1 | Epic 9 Retro (2026-05-24) | Schedule centralized-logger story (closes E8-T1) | Amelia (Developer) | Epic 10 (Story 10.0, scheduled in `epics.md`) | done | Closed by Story 10.0 (2026-05-24). Centralized logger shipped; DAO/service error paths now log via `AppLogger` and persistence-write failures are observable in cubit state where required. |
| E9R-2 | Epic 9 Retro (2026-05-24) | Unblock E7-T2 viewport/golden test infra before Story 10.2 | Charlie (Senior Dev) + Dana (QA) | Before Story 10.2 enters sprint | done | Closed by Story 10.2 (2026-05-26). The reusable `set360dpSurface()` helper is committed under `test/helpers/viewport_helper.dart`; 360dp assertions cover `MinutesPerWeekChart`, `CompletionRateChart`, `RpeTrendChart`, and `SessionTypeBreakdownChart`. |
| E9R-3 | Epic 9 Retro (2026-05-24) | Validate UX-DR9 two-row RPE degrade | Sally (UX) + John (PM) | Before/at Epic 10 kickoff | done | Sprint Change Proposal (2026-05-24) ratified two-row degrade as the approved solution. `epics.md` Story 9.1 AC1 and `ux-design-specification.md` UX-DR9 updated; `fix/rpe-input-overflow-360dp` merged to main. |
| E9R-4 | Epic 9 Retro (2026-05-24) | Extend the E9-K1 fire-check to Category A deliverables with relative triggers | John (PM) + Amelia (Developer) during create-story | Ongoing process | pending | E8-T1 was a Category A *deliverable* triggered-and-ignored — the E9-K1 fire-check (originally scoped to cross-cutting process rules) must also surface deliverable-debt items whose relative trigger fires at story-creation. Category B (ongoing process), uncapped. |

**Carry-over reconfirmed:**

- **Epic 8 action #7** (Story 8.5 abandon-flow on-device smoke) — still `pending`, owner Paolo, next physical device session. NOT covered by E9R-2 (viewport tests do not exercise the abandon-confirmation bottom-sheet interaction). Residual manual-device item.

**Category A snapshot (post Story 10.2):** E7.5-T1, E8-T1, E7-T2, and E9R-2 are closed. Active: `E6-T7`, `E6-T8`. UX-DR9 validation (E9R-3) is a product-decision deferral. Net within the 5 cap. Next Category B sunset review at **Epic 11 kickoff** per E8-K2.

---

## Epic 10 Retro - 2026-05-27

Retrospective for Epic 10 (Progress & History). All 4 stories done; on-device verification PASS on SM-A520F (full On-Device UI Verification Protocol). Retro doc: `epic-10-retro-2026-05-27.md`.

**New action items:**

| # | Source | Description | Owner | Target | Status | Notes |
|---|---|---|---|---|---|---|
| E10R-1 | Epic 10 Retro (2026-05-27) | Release-build observability for DAO write failures: add a release log sink (Crashlytics/analytics) and/or a UI consumer of `persistenceError` | Amelia (Developer) | Future Progress/observability story | pending | Category A. Story 10.0 shipped `AppLogger` as a debug-only no-op with no UI consumer of `persistenceError` — accepted as-designed for the milestone (Paolo, 2026-05-24), but in release a failed `session_log` write is fully silent (no log, no UI, no telemetry) while the user sees the session as completed. Absorbs two deferred items: sticky `persistenceError` clear across `_onLogsChanged` ticks (10.0) and perpetual-shimmer-on-`ProgressStatsError` (10.3). |
| E10R-2 | Epic 10 Retro (2026-05-27) | Non-UTC (CET/CEST) regression test for `_mondayOf` / `minutesPerWeek` week bucketing | Dana (QA) + Amelia (Developer) | Before/with next Progress story | pending | Category A. Story 10.3 unified `_mondayOf` to UTC (correct per project "DateTime UTC internally" rule), shifting 10.2 weekly-minutes buckets for non-UTC devices — a Mon 00:30 local session (Sun 22:30 UTC) buckets into the prior week. No dedicated non-UTC test was added; this is the actual target user's timezone. |
| E10R-3 | Epic 10 Retro (2026-05-27) | Keep the E9R-4 create-story fire-check for Category A deliverables — validated effective | John (PM) + Amelia (Developer) during create-story | Ongoing process | pending | Category B (ongoing). E8-T1 (the textbook triggered-and-ignored Category A deliverable) was closed this epic by explicit scheduling as Story 10.0 — evidence the fire-check works. Merges intent with E9R-4. |

**Closures / status changes from this retro:**

- **Epic 8 action #7** (Story 8.5 abandon-flow on-device smoke) → **close.** Executed on device 2026-05-27 during Epic 10 verification (start → Abbandona → confirm sheet → RPE → summary → abandoned `session_log` written). Residual manual-device item cleared.

**Category A snapshot (post Epic 10 retro): 4 / 5.** Active: `E6-T7`, `E6-T8`, `E10R-1`, `E10R-2`. Within cap. Closed in the Epic 10 window: `E7.5-T1`, `E8-T1`, `E7-T2`, `E9R-2`. Minor deferrals recorded without a slot: N+1 query in `getSessionHistory` (10.1), `.toLocal()` date rendering near midnight (10.1, systemic).

**Category B sunset review:** deferred to **Epic 11 kickoff** per E8-K2 2-epic cadence (not owed at this retro). Items to review then: `E6-P1`, `E7-P2`, `E7.5-P1`, `E7.5-P2`, `E9-K1`, `E9R-4`/`E10R-3`.

---

## Epic 11 Category B Sunset Review — 2026-06-02 (E11R-2)

Ran during the Epic 11 retrospective (Paolo + Amelia, on John's behalf). This review was **overdue** — owed at Epic 11 kickoff per the E8-K2 2-epic cadence (last run at Epic 9 kickoff) but not executed; Story 11.1 explicitly punted it to the PM and it was never picked up. Closes action **E11R-2**. Each of the 6 standing Category B items was walked against Epic 11 (UI/responsive: no DI/lifecycle changes, no l10n/build/deprecated-API touches, **but** Cubit collection-index state was consumed — `TodaySessionCubit.heroIndex` read into the new tablet layout).

| Item | Triggered in Epic 11? | Verdict | Rationale |
|---|---|---|---|
| `E6-P1` (patch-validation gate after DI/lifecycle/cross-cutting review patches) | No — Epic 11 review patches were UI-layout only (`_scrollable()` helper, selected-color, drawer toggle) | **Keep dormant** | Clear future trigger, low standing cost. No DI/lifecycle/cross-cutting patch landed this epic. |
| `E7-P2` (architect pre-flight identity-vs-position for Cubit/BLoC with collection-index state) | **Yes — triggered, honored late.** Story 11.2 read `heroIndex` (collection index) into `_TabletTodayLayout`; **CR112-001** (tablet `heroIndex` not completion-aware) is exactly the positional-state edge this rule targets — caught at code review, not at story-creation pre-flight | **Keep + fold into the fire-check** | The rule worked at review but the create-story pre-flight did not fire. This is the same "relative trigger fires unnoticed at creation" pattern E9-K1 was opened to fix → covered by consolidating into the E9-K1 fire-check (below). |
| `E7.5-P1` (Flutter deprecation pre-check for SDK-sensitive specs at create-story) | No — Epic 11 had no l10n config, build config, plugin registration, or deprecated-API surface (zero new ARB keys, zero `build_runner`) | **Keep dormant** | Standing rule, low cost; re-relevant the next time a spec touches SDK-sensitive config. |
| `E7.5-P2` (rework `+N tests` magnitude caps to invariant-based guardrails) | n/a — no `+N` magnitude cap was specified | **RETIRE — structurally satisfied** | The magnitude-cap anti-pattern is gone. Since Story 9.1, specs use lower-bound targets ("target ≥ N total") + "all existing tests green" rather than "grows by at most +N"; Epic 11 stories (11.1 "≥ 688", 11.2 "≥ 748", 11.3 "≥ 752") all use the invariant/lower-bound form. The guardrail is now the default; no magnitude cap has tripped falsely since adoption. |
| `E9-K1` (explicit fire-check at create-story for cross-cutting review-patch concerns, not only at review) | Partially — see `E7-P2` row (index-state pre-flight did not fire at creation) | **Keep as the canonical fire-check; ABSORB `E9R-4` + `E10R-3`** | E9-K1, E9R-4, and E10R-3 are the same "surface relative-trigger items at `bmad-create-story` time" rule at widening scopes (cross-cutting patches → Category A deliverables → validated-effective). Consolidate into one ongoing rule to cut Category B clutter. Scope of the merged rule: at create-story, surface (a) likely DI/lifecycle/cross-cutting review-patches [E6-P1/E9-K1], (b) Category A deliverable-debt with a relative trigger firing now [E9R-4/E10R-3], and (c) Cubit/BLoC collection-index pre-flight [E7-P2]. |
| `E9R-4` / `E10R-3` (extend fire-check to Category A deliverables) | Validated effective in Epic 10 (E8-T1 closed by explicit scheduling) | **RETIRE as standalone — merged into `E9-K1`** | Intent preserved inside the consolidated E9-K1 fire-check. E10R-3 already self-described as "merges intent with E9R-4"; this folds both into one canonical item. |

**Outcome:** 6 items → **3 active standing rules** (`E6-P1`, `E7-P2`, `E7.5-P1`) + **1 consolidated fire-check** (`E9-K1`, now absorbing E9R-4/E10R-3 and the E7-P2 index-state pre-flight). **Retired:** `E7.5-P2` (structurally satisfied), `E9R-4` + `E10R-3` (merged into E9-K1). Next sunset review: **Epic 13 kickoff** (2-epic cadence; Epic 12 + Epic 13).

**Category A snapshot (Epic 11 retro):** active `E6-T7`, `E6-T8`, `E10R-1`, `E10R-2` (4/5). New A-class, hardware-gated: `E11R-3` (tablet on-device verification — closes deferred 11.1 label-band + 11.2-AC4) and `E11R-PREP` (**DONE 2026-06-02** — Wear OS Large Round AVD created, API 36, `emulator-5554` boots and `flutter devices` recognizes it as a watch). `CR112-002` (hardcoded cardio accent) is a further A candidate. Triage at Epic 12 kickoff: `E11R-3` is blocked only on a tablet/large-screen target and may be parked with rationale rather than counted as active work, keeping the cap honest.
