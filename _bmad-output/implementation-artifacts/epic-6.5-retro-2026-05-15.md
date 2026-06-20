# Epic 6.5 Retrospective — Foundation Hardening (Interstitial)

**Date:** 2026-05-15
**Epic:** 6.5 — Foundation Hardening (Interstitial)
**Facilitator:** Amelia (Developer)
**Participants:** Amelia (Developer), Alice (Product Owner), Charlie (Senior Dev), Winston (System Architect), Dana (QA Engineer), Paolo (Project Lead)

---

## Epic Summary

| Metric | Value |
|---|---|
| Stories Completed | 4/4 (6.5.1, 6.5.2, 6.5.3, 6.5.4) |
| Sprint Status Before Retro | `epic-6.5: in-progress`, all story keys `done`, retrospective `optional` |
| Sprint Status After Retro | `epic-6.5: done`, retrospective `done` |
| Test Suite | 371 → **388/388** passing |
| `flutter analyze` | 38 issues → **0 issues** |
| Code Reviews | 4 stories × Blind Hunter + Edge Case Hunter + Acceptance Auditor; all closed in single cycle with inline patches |
| Production Incidents | 0 |
| Visible UI Change | AppShell tab order corrected to `Sessions, Today, Progress` per UX spec |
| Story 6.5.4 Commits | 6 isolated `chore(deps)` commits, one per cluster |

**Goal Achieved:** Epic 6.5 closed the foundation gaps that two consecutive retros (Epic 5, Epic 6) failed to resolve in prose. `flutter analyze` is at zero. AppShell matches the UX spec. Catalog has defensive normalization and ID dedup. A real action-item ledger artifact exists. Six dependency major-version clusters are upgraded with per-cluster commits and gate enforcement.

---

## What Went Well

### 1. Process Commitments Shipped When Scoped as Stories With AC

Epic 5 retro and Epic 6 retro both committed to `flutter analyze` cleanup and action-item tracking. Both retros failed to deliver. Epic 6.5 succeeded by scoping each commitment as a story with explicit acceptance criteria. Story 6.5.1 closed analyze. Story 6.5.3 created `action-item-ledger.md`.

**Lesson:** Prose commitments in retros don't ship. Story-with-AC commitments do. Future retros should generate stories, not bullet points.

### 2. Story 6.5.4 — Per-Cluster Discipline Exemplary

Six dependency major bumps. Six isolated commits (`eb1302f`, `2a0c917`, `29f0b23`, `8cffd4f`, `83c5fad`, `e47ef29`). `flutter analyze + flutter test` gate enforced after every cluster. Cluster B (`get_it` + `injectable` + `injectable_generator`) included `dart run build_runner build` with byte-identical `injection.config.dart` output verification.

**Lesson:** When you have N independent migration risks, force N commits. This is the template for all future dependency work.

### 3. `Failure` Equality Implemented Carefully With Round-1 Patches Absorbed

Story 6.5.3 added structural equality via `Object.hash(runtimeType, message)` with 9 equality tests (`6.5-EQ-001..009`) covering transitivity, hashCode inequality, and null/type checks. Code review proposed three patches; all applied inline in the same review cycle. No round-2.

**Lesson:** When the test suite covers structural invariants exhaustively, code review converges faster.

### 4. Action-Item Ledger Is Real

`_bmad-output/implementation-artifacts/action-item-ledger.md` contains 16 tracked entries with source retro, owner, target story/epic, and status. Includes the Ledger Review Protocol for future retros.

**Lesson:** Tracking artifacts that close out a known process gap don't need to be elegant — they need to exist.

### 5. Test Suite Growth Was Honest

371 → 388. Each new test (`6.5-UNIT-001..004`, `6.5-EQ-001..009`) covers a specific defensive guard or invariant introduced in this epic. No decorative tests.

---

## What Did Not Go Well

### 1. Defense-in-Depth Is Still Asymptotic — Story 6.5.2 Added 6 Deferred Items

The story whose explicit goal was to triage the deferred backlog produced 6 new deferred items:

- Asymmetric normalization: read path lowercases `sessionType`, but cached rows and asset JSON are not normalized on write
- Dedup bypassed by id case-variants or whitespace-padded ids (`"x"` vs `"x "` vs `"X"` survive)
- Empty-id record treated as single dedup key — first empty-id wins, rest silently dropped
- Empty-string sessionType produces UI message with double space (`'No exercises available for  (offline...)'`)
- Test `6.5-UNIT-004` does not assert the `developer.log` warning for duplicates
- No unit test covers the empty-string early-return branch in either method

**Impact:** Hardening with sub-strata left uncovered. Each round of defense-in-depth pays partial.

**Lesson (Paolo flag #2):** "Partial debt" is the recurring failure mode. The defense-in-depth pattern always leaves the next sub-stratum exposed. The fix is not "harden harder" — it is "define an acceptance threshold for debt and enforce it".

### 2. `Failure` Structural Equality Has Latent Downstream Effect

Changing `Failure` from identity equality to `runtimeType + message` may suppress BLoC error-state re-emission when two `CacheFailure('Profile not found')` are emitted consecutively. The reviewer explicitly deferred verification: *"error states have no UI consumer yet, premature to decide re-emission behavior before Today screen consumes them"*.

**Impact:** Latent. Will surface in Epic 7 when `StateIndicator` and `SessionCard` consume `Failure` from BLoCs. Discovery in user-visible UI is the wrong moment.

**Lesson (Paolo flag #3):** Equality changes have invisible blast radius. Add a regression test now, not when Today screen renders error states.

### 3. Two Carry-Over Product Reviews Still Pending — Three Epics Slipped

Epic 5 retro committed:
- AI state-graph product semantics review (Alice + Winston)
- Explanation copy product review for Today screen (Sally + Alice)

Epic 6 retro re-flagged both as critical-path before Epic 7. Epic 6.5 did not schedule either. Three consecutive epics of slippage.

**Impact:** Story 7.1 (`StateIndicator`) is **non-implementable** without these decisions. The story renders states (`active + missedSessions >= 2`, `recovering`, `atRisk → recovering`) that have no product semantics, with copy that has no editorial decision.

**Lesson (Paolo flag #4):** Product decisions don't slip because the team forgets — they slip because no story forces them. Technical stories don't unblock stakeholder decisions; only scheduled product sessions do.

### 4. `fl_chart` and `google_fonts` — Major Bumps on Unused Direct Dependencies

Story 6.5.4 cluster E and cluster F bumped two packages that have zero `import` statements in `lib/` or `test/`. Migration cost paid for unused weight.

**Decision (Paolo):** Keep both for now. `fl_chart` is planned for Epic 10 (Progress charts). `google_fonts` is candidate-for-removal once Epic 10 confirms local fonts are sufficient.

**Lesson:** A `chore(deps): prune unused` audit should precede a major-version sweep. Cheaper than upgrading something you're about to delete.

### 5. AppShell `_currentIndex` Fallback Default Changed

Post-reorder, `_currentIndex` fallback (`idx<0 → 0`) now lands unknown routes on Sessions instead of Today. Flagged as deferred during 6.5.1 review ("no current consumer"). Epic 7 introduces new routes and analytics first-run state that may observe this.

**Impact:** Latent. Behavior contract change unannotated.

**Lesson:** Reorder changes have downstream observable effects beyond the obvious (tab labels). Document the contract change explicitly.

### 6. CLAUDE.md Is Stale

Reports `flutter analyze was not clean: 38 issues` and `346/346 tests`. Reality post Epic 6.5: 0 issues, 388/388. CLAUDE.md is the durable context document for future sessions — stale equals actively misleading.

**Lesson:** CLAUDE.md update belongs in the retro itself, as the final task of epic closure, not "whenever someone notices".

### 7. Patch-Validation Gate (Epic 6 Commitment) — Partially Adopted

Epic 6 retro action item #1 committed to a patch-validation gate for review patches touching DI/lifecycle/cross-cutting concerns. Stories 6.5.1, 6.5.2, and 6.5.3 absorbed review patches inline without explicit gate documentation in dev logs. The gate isn't broken — it just isn't formalized in the process.

**Lesson:** Process commitments need a visible checklist artifact, not just team agreement.

---

## Previous Retrospective Follow-Through

| Epic 6 Commitment | Status | Evidence |
|---|---|---|
| Patch-validation gate (DI / lifecycle patches) | ⚠️ Partial | Patches absorbed inline; no formal checklist in dev logs |
| Action item ledger | ✅ Done | Story 6.5.3 created `action-item-ledger.md` |
| `flutter analyze` → 0 | ✅ Done | Story 6.5.1 |
| AppShell tab order → `Sessions, Today, Progress` | ✅ Done | Story 6.5.1 |
| `sessionType` normalization + logging | ⚠️ Partial | Read path only; write path / asset / cache rows not normalized |
| Fallback ID uniqueness at load | ⚠️ Partial | Exact-match only; case/whitespace variants bypass |
| AI state-graph product review | ❌ Pending | Carry-over from Epic 5 |
| Explanation copy product review | ❌ Pending | Carry-over from Epic 5 |
| ExerciseDB remote mapping revisit | ⏳ Deferred | Trigger condition (post-MVP) not yet met |
| Memoize fallback JSON decode | ⏳ Deferred | Trigger condition (Today screen perf data) not yet met |

**Pattern (carrying forward from Epic 6 retro analysis):** Technical commitments scoped as story AC ship. Product commitments requiring stakeholder decisions slip across epics. Defense-in-depth commitments ship partial.

---

## Key Insights

1. **Story-with-AC ships; prose commitments don't.** Epic 6.5 is empirical proof. Future retro action items should generate stories with AC or scheduled sessions, not bullet points.
2. **Defense-in-depth has no natural terminus.** Without an explicit acceptance threshold, every hardening pass leaves a sub-stratum. The pattern is the failure mode, not the execution.
3. **Equality changes have invisible blast radius.** `Failure` structural equality is correct in isolation, observable only at the consumer. Regression tests must precede the consumer.
4. **Product decisions need product sessions.** Tech stories are not a mechanism for unblocking stakeholder decisions. Three epics of slippage prove this.
5. **Context documents (CLAUDE.md) decay between epics.** Update belongs in epic closure, not "as needed".
6. **Per-cluster commit discipline (Story 6.5.4) is the dependency-management template.** N independent migration risks = N commits with gates.

---

## Next Epic Preview — Epic 7: Today Screen

Epic 7 has 4 stories planned: `StateIndicator`, `SessionCard`, Today screen layout + hero progression, `CompletionRing` + plan regeneration. This is the first epic to close the loop from `DailyPlanBloc` (Epic 5) to user-visible UI.

### Dependencies on Epic 6.5

- ✅ AppShell tab order — Today at index 1 (correct)
- ✅ `flutter analyze` baseline at 0 — zero-tolerance enforceable
- ✅ Plus Jakarta Sans / JetBrains Mono bundled locally (Epic 6.3)
- ✅ Catalog data enrichment (`_enrichPlanWithCatalog`, Epic 6.1) — `SessionCard` consumes
- ⚠️ `Failure` structural equality — BLoC error states mounted on Today screen will be first real consumer
- ⚠️ AppShell `_currentIndex` default fallback — Today screen's deep-link / analytics first-run state may observe

### Preparation Needed (in priority order)

| Item | Owner | Success Criteria | Priority |
|---|---|---|---|
| AI state-graph product semantics review session | Alice (PO) + Winston (Architect) | Decision doc under `_bmad-output/`: `active + missedSessions >= 2` escalation, `recovering` demotion, `atRisk → recovering` guard | **CRITICAL — blocks Story 7.1 creation** |
| Explanation copy product review session | Sally (UX) + Alice (PO) | Decision doc under `_bmad-output/`: placeholder vs templated vs state-aware copy for `StateIndicator` | **CRITICAL — blocks Story 7.1 creation** |
| `Failure` equality regression test for BLoC re-emission | Amelia (Developer) | Test asserts (or documents) BLoC behavior when two equal `Failure` are emitted; red → green | High — before Story 7.1 merge |
| Deferred Items Budget definition for Epic 7 | Alice (PO) + Paolo | Numeric threshold per story / per epic; review enforcement protocol | High — at Epic 7 kickoff |
| Symmetric normalization decision (write path) | Amelia (Developer) | Either implement write-path normalization with round-trip test, or document explicit deferral with rationale | Medium — can land in Epic 7 Story 1 |
| CLAUDE.md update | Amelia (Developer) | Reflects 388/388, 0 analyze, AppShell `Sessions, Today, Progress` order, current visible UI status | Medium — closure of this retro |

### Critical Path Before Epic 7

1. **AI state-graph product review session** — schedule and complete
2. **Explanation copy product review session** — schedule and complete
3. **Failure equality BLoC regression test** — red → green
4. **Deferred Items Budget defined and agreed** — process artifact
5. **CLAUDE.md updated** — final closure task

---

## Action Items

### Process (Root Cause — Paolo Flag)

1. **Deferred Items Budget per epic.**
   Owner: Alice (Product Owner) + Paolo (Project Lead)
   Success criteria: before Epic 7 kickoff, define a numeric threshold (e.g., "max 3 deferred items per story, max 10 per epic"). When a story is about to exceed budget, code review forces a decision: scope into the story, scope into a dedicated story, or document an explicit signed exception.
   Rationale: Four consecutive epics of deferred-growth. The pattern is not "execute better stories" — it's "make the debt limit observable". Paolo flag #4.

2. **CLAUDE.md update as final task of every epic closure.**
   Owner: Amelia (Developer)
   Success criteria: the last step of each retrospective updates CLAUDE.md (test count, analyze count, visible UI status, baseline). Triggered by retro completion, not epic kickoff.
   Rationale: CLAUDE.md is durable cross-session context. Stale = actively misleading future agents.

3. **Patch-validation gate formalized (Epic 6 carry-over).**
   Owner: Amelia (Developer)
   Success criteria: dev log of every story records "patch-validation gate: ran [specific tests] after applying patches touching [files]" — visible artifact in story dev notes.
   Rationale: Epic 6 commitment partially adopted but not visible. Make it auditable.

### Technical (Critical Path Before Epic 7)

4. **`Failure` equality BLoC re-emission regression test.**
   Owner: Amelia (Developer)
   Success criteria: a widget/bloc test that verifies (or documents) BLoC behavior when two `CacheFailure('X')` are emitted consecutively. Red → green before Story 7.1 merge.
   Rationale: Paolo flag #3. The reviewer of 6.5.3 explicitly deferred this. Convert "latent risk" into "documented behavior".

5. **Symmetric `sessionType` normalization decision.**
   Owner: Amelia (Developer)
   Success criteria: either implement write-path normalization (cached rows + asset JSON) with round-trip test, OR document explicit deferral with rationale and review trigger. No third option.
   Rationale: Paolo flag #2. Force a decision; stop the "partial guard" pattern.

### Carry-Over Product Reviews (BLOCKING Epic 7)

6. **AI state-graph product semantics review — SCHEDULE NOW.**
   Owner: Alice (Product Owner) + Winston (System Architect)
   Deadline: before Story 7.1 creation
   Success criteria: decision document under `_bmad-output/` for `active + missedSessions >= 2` escalation, `recovering` demotion, `atRisk → recovering` guard.
   Rationale: Three epics of slippage. Story 7.1 is non-implementable without these decisions.

7. **Explanation copy product review — SCHEDULE NOW.**
   Owner: Sally (UX Designer) + Alice (Product Owner)
   Deadline: before Story 7.1 creation
   Success criteria: decision document under `_bmad-output/` on placeholder vs templated vs state-aware copy for `StateIndicator`.
   Rationale: Same slippage pattern. Today screen is the consumer; no copy = no UI.

### Deferred (Documented, Not Critical Path)

8. **Prune unused direct dependencies (`fl_chart`, `google_fonts`).**
   Owner: Amelia (Developer)
   Trigger: post Epic 10 confirmation that `fl_chart` is needed and `google_fonts` is replaceable by local fonts.
   Rationale: Paid migration cost on unused weight in Story 6.5.4 clusters E and F. Paolo decision: keep for Epic 10 reuse, prune candidate post-Epic-10.

9. **AppShell `_currentIndex` default fallback behavior contract.**
   Owner: Amelia (Developer)
   Trigger: when Epic 7 introduces new routes or analytics first-run state.
   Rationale: Reorder changed observable behavior on unknown routes; no current consumer, latent for Epic 7.

---

## Significant Discovery Assessment

**Epic 7 plan updates required:** No fundamental rewrite. The 4 stories planned in `epics.md` for Epic 7 remain valid.

**Real Epic 7 blockers:**
1. Action items #6 and #7 (product reviews) — Story 7.1 cannot be created without these decisions.
2. Action item #4 (Failure equality regression test) — can run parallel to Story 7.1 but must land before merge.
3. Action item #1 (Deferred Items Budget) — must be defined at Epic 7 kickoff, not mid-epic.

**Non-blocking but recommended:**
- Action item #5 (symmetric normalization) — can be first task of an Epic 7 story or a 6.5.5 suffix story.
- Action item #2 (CLAUDE.md update) — final closure task of this retro.

---

## Readiness Assessment

| Area | Status | Notes |
|---|---|---|
| Story Completion | Pass | 4/4 Epic 6.5 stories `done` |
| Automated Tests | Pass | `flutter test`: 388/388 |
| Static Analysis | Pass | 0 issues (zero-tolerance now enforceable) |
| Device Smoke Validation | Partial | AppShell reorder verified; Today/Progress still placeholder |
| Stakeholder Acceptance | Pass | Paolo (Project Lead) confirmed action items |
| Carry-Over Product Decisions | **BLOCKED** | Two product reviews still unscheduled |
| Process Hygiene | Improved | Ledger created; Deferred Items Budget pending definition |
| Technical Debt | Managed but partial | 6 new deferred items from Story 6.5.2; pattern requires budget intervention |

**Verdict:** Epic 6.5 is **technically complete**. Epic 7 cannot kick off cleanly until the two product reviews (action items #6, #7) land. Action item #4 (Failure equality test) is recommended in parallel with Story 7.1 work.

---

## Team Agreements

- Process commitments are stories with AC, not bullet points in retros. Three epics of evidence.
- Deferred Items have a budget. Defense-in-depth without a threshold accumulates forever.
- Product decisions are scheduled sessions, not implicit dependencies of technical work.
- Per-cluster commits with gate enforcement is the template for dependency upgrades (Story 6.5.4 model).
- Equality changes get regression tests before the consumer mounts them.
- CLAUDE.md is updated as the final task of every epic closure.
- Code-review patches that touch DI / lifecycle / cross-cutting concerns get documented gate validation in story dev logs.

---

## Handoff

Epic 6.5 is closed. Epic 7 (Today Screen) can proceed once the critical-path items land:

1. AI state-graph product review session — decision documented
2. Explanation copy product review session — decision documented
3. `Failure` equality BLoC regression test — red → green
4. Deferred Items Budget defined and agreed
5. CLAUDE.md updated to reflect post-Epic-6.5 baseline

The technical foundation is ready. The remaining blockers are stakeholder decisions and one regression test.
