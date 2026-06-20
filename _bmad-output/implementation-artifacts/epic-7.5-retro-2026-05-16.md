# Epic 7.5 Retrospective — i18n / `gen_l10n` Migration (Interstitial)

**Date:** 2026-05-16
**Epic:** 7.5 — i18n Migration (Interstitial, scope-capped at 2 stories per Epic 7 retro decision)
**Facilitator:** Amelia (Developer)
**Participants:** Amelia (Developer), Alice (Product Owner), Charlie (Senior Dev), Winston (System Architect), Dana (QA Engineer), Paolo (Project Lead)

---

## Epic Summary

| Metric | Value |
|---|---|
| Stories Completed | 2/2 (7.5.1 wire `flutter_localizations` + `gen_l10n`, 7.5.2 migrate Epic 7 Italian strings to ARB) |
| Sprint Status Before Retro | `epic-7.5: in-progress`, both story keys `done`, retrospective `optional` |
| Sprint Status After Retro | `epic-7.5: done`, retrospective `done` |
| Test Suite | 503 → **516/516** passing (+13 tests: +1 ARB smoke from 7.5.1 + ~12 from concurrent Epic 7 traceability / TEA / `TodaySessionCubit` work folded into the same baseline window) |
| `flutter analyze` | **0 issues** preserved (zero-tolerance) |
| Code Reviews | 2 stories × Blind Hunter + Edge Case Hunter + Acceptance Auditor; both closed single-cycle with inline patches |
| Correct-Course Notes | 1 (Story 7.5.1 — AC2/AC3 amended mid-flight for Flutter 3.41.6 tooling reality) |
| Production Incidents | 0 |
| Visible UI Shift | `"COMING UP"` → `"PROSSIME"`. All other Italian copy bit-identical pre/post-migration. |
| ARB Pipeline | `flutter_localizations` + `gen_l10n` wired; ARB inputs under `lib/l10n/app/`; generated `app_localizations*.dart` `.gitignore`'d; 34 user-facing keys in `app_it.arb` |
| `state_messages.it.arb` | Deleted; 15 keys absorbed into `app_it.arb` |
| Carry-over product decisions closed | 1 (E7-P1 — i18n / `gen_l10n` migration) |
| New deferred items added | 2 (E7.5-T1 dead ARB transition keys at consumer; E7.5-P1 Flutter deprecation pre-check in story-creation; E7.5-P2 AC7-style integer-delta test-count guardrail pattern) — **3 total new items** |

**Goal Achieved:** Epic 7.5 closed the 3-story i18n deferral that had accumulated across Epic 7 (debt size justified refactor over continued accumulation, per Epic 7 retro decision). All Today-screen widget files are now ARB-resolved through `AppLocalizations.of(context)!`. The residual English `"COMING UP"` is translated. Epic 8 stories can extend the ARB pattern at marginal cost. The 7 `BehavioralStateMachine` transition keys were added to the ARB inventory but remain dead at the consumer (intentional scope cap) — explicitly tracked as a deferred item against a future Epic 8.x story rather than left as a silent Chesterton's fence.

---

## What Went Well

### 1. Scope discipline — 2-story cap honored without drift

Epic 7 retro capped this interstitial at 2 stories. Both stories shipped exactly the scope declared (wiring + migration), with the explicit scope-boundary discipline visible in both story specs ("This story does NOT…" sections). No mid-flight scope expansion. The state-machine literals stayed deferred; Paolo confirmed in this retro that not adding a 7.5.3 was the right call.

**Lesson:** When an interstitial epic ships in its capped story count, it's worth re-stating the cap in every story's "Scope Boundary" section. Both 7.5.1 and 7.5.2 did this; both held line.

### 2. Reusable test pattern documented in-spec

Story 7.5.2 Dev Notes documented the `async` + `await AppLocalizations.delegate.load(const Locale('it'))` pattern for the 12 HELPER tests inline, before implementation. The pattern is now copy-pasteable for Epic 8+ widget tests that need ARB-backed strings without a full `MaterialApp` wrapper. Dana flagged this as the reusable artifact she'll point future tests at.

**Lesson:** When a story creates a non-obvious test pattern, capture it in Dev Notes verbatim — not in retro prose. The retro is too late for the next dev to consume it.

### 3. Correct-Course Note process worked under tooling friction

Flutter 3.41.6 rejected `synthetic-package` in `l10n.yaml` and conflicted with the existing `state_messages.it.arb` when ARB inputs lived in `lib/l10n/` root. Story 7.5.1 dev hit both, paused, drafted a Correct-Course Note amending AC2/AC3 to `arb-dir: lib/l10n/app` + key removal, and shipped. Code review accepted the amendment in the same cycle (Decision-needed item closed as Option 1). No blocking, no rework spiral.

**Lesson:** The "Correct-Course Note" mechanism (introduced in earlier epics) handles tooling-reality deltas cleanly. Keep it.

### 4. EN-locale semantic swap caught in review

Story 7.5.2 EN translations had `stateLabelAtRisk: "Recovering"` / `stateLabelRecovering: "Building back"` — semantically inverted vs the Italian source. Blind Hunter caught it, patch applied in-cycle. EN copy is not user-visible today (`locale: const Locale('it')` is forced), but the locked-in correct mapping prevents a future bug when `localeResolutionCallback` is wired.

**Lesson:** Bilingual ARB reviews benefit from semantic cross-check, not just key-presence check. The Acceptance Auditor returned a clean PASS; Blind Hunter is what caught the swap. Both layers paid for themselves.

### 5. `.gitignore` decision for generated files made early

Generated `app_localizations*.dart` were initially committed (per project convention for `.g.dart` / `.freezed.dart`), then code review flagged the regeneration-churn / CI-dirty-tree risk because `generate: true` produces them on every `flutter pub get`. Decision closed in-cycle: move to `.gitignore`. Avoided a near-certain "CI red on clean tree" incident in the first month of Epic 8 work.

---

## What Did Not Go Well

### 1. Story 7.5.1 AC2 deviation should have been caught in story-creation

Flutter 3.41.6 deprecated `synthetic-package` and the spec wrote it in literally. Winston had visibility into the Flutter SDK version pinned in `pubspec.yaml` during story-creation but did not cross-check known deprecations. Result: the dev hit it, paused, opened a Correct-Course Note. Process recovered cleanly, but the friction was avoidable.

**Decision (Paolo, in retro):** From Epic 8 onwards, add an explicit "Flutter deprecation pre-check" step to story-creation for stories that touch SDK-version-sensitive configuration (l10n config, build config, plugin registrations, deprecated APIs). Owned by Winston during create-story.

**Lesson:** Tooling spec drift between LLM training data and the pinned SDK version is a known failure mode. Defend against it in story-creation, not in dev execution.

### 2. AC7 integer-delta test-count guardrail is the wrong pattern

Story 7.5.1 AC7 capped new tests at `+3` (target 504–506). Actual: `+13` (516 total). The +1 in 7.5.1's own diff was correct; the other +12 came from concurrent Epic 7 traceability matrix + TEA + `TodaySessionCubit` work landing in the same baseline window. Resolution was to reconcile CLAUDE.md (503 → 516), which was correct — but the pattern itself encouraged a misleading "guardrail breach" finding in code review and required a Decision-needed cycle to resolve.

**Decision (Paolo, in retro):** Replace AC7-style integer-delta test-count caps with intent-based guardrails:
- "Zero existing tests removed" (verifiable via diff)
- "All existing tests still green" (verifiable via `flutter test` exit code)
- "New tests for this story's ACs are added and passing" (verifiable from Dev Agent Record)

An absolute delta is meaningless when concurrent uncoordinated test work is landing.

**Lesson:** Guardrails should measure invariants, not magnitudes. Magnitude-based caps falsely trip on parallel valid work.

### 3. Dead ARB transition keys — Chesterton's fence flagged but not closed

Story 7.5.2 added 7 `transition*` keys to `app_it.arb` / `app_en.arb` (camelCase rewrites of the 6 unique `state_messages.it.arb` transitions, total 7 entries with one synonymous duplicate). At the consumer side, `StateIndicator.transitionMessage` still receives a raw Italian literal emitted by `BehavioralStateMachine` — never the ARB lookup. The ARB keys are unreferenced by any widget code path today. Winston flagged this in retro; left unresolved it becomes a Chesterton's fence ("why are these keys here?") for a future maintainer.

**Decision (Paolo, in retro):** Tracked as deferred item **E7.5-T1** with target Story 8.x — explicit, dated, owner-assigned. Not promoted to a 7.5.3 (out of interstitial scope cap), not left silent. The expectation is that an Epic 8 or later story will migrate `BehavioralStateMachine.evaluate()` to emit ARB keys (or a state-transition enum the widget resolves to ARB), at which point the keys become live.

**Lesson:** When scope discipline forces a deferral that *plants new dead code*, the deferral must be explicit in the ledger — not implicit in the spec's "Scope Boundary" section. The latter rots; the ledger gets reviewed at every retro.

### 4. Pending deferred-item count exceeds the 5-per-epic cap going into Epic 8

Going into Epic 8 sprint planning, the pending items in `action-item-ledger.md` total (after Epic 7.5 retro closures and additions):

- E6-P1 (patch-validation gate — ongoing process)
- E6-T7 (ExerciseDB remote mapping revisit — post-MVP)
- E6-T8 (memoize fallback JSON decode — perf-trigger)
- E7-F1 (completion persistence — `in-progress`, target Story 8.0)
- E7-P2 (architect identity-vs-position review — ongoing process)
- E7-P3 (Edge-Case Hunter prompt update — before Epic 8)
- E7-T1 (`vibration` package — before Story 8.3)
- E7-T2 (golden test infra — Epic 11)
- E7.5-T1 (dead ARB transition keys — Story 8.x)
- E7.5-P1 (Flutter deprecation pre-check — ongoing process)
- E7.5-P2 (AC7 guardrail rework — before next AC7-style spec)

**Count: 11 pending.** Cap: 5.

The CLAUDE.md "Deferred Items Budget" rule applies. Strict reading: "no new stories enter the sprint until triage brings the number back to ≤ 5." Several of the items are "ongoing process" (E6-P1, E7-P2, E7.5-P1) and arguably don't compete for capacity in the same way as deliverable debt. PM (John) needs to triage at Epic 8 kickoff: close, drop, promote to a scheduled story, or formally re-scope the budget rule to distinguish "ongoing-process" from "deliverable-debt" items.

**Decision (Paolo, in retro):** Flag the breach in this retro doc. PM triage at Epic 8 kickoff is the gating action. Not a 7.5 closure blocker.

**Lesson:** The Deferred Items Budget rule (introduced in Epic 6.5 retro) is now empirically under-specified. Either it counts every `pending` row uniformly (and the rule blocks Epic 8 kickoff today), or it differentiates between "ongoing process" and "deliverable debt" (and the rule needs an explicit rewrite). Reconcile before next sprint plan.

### 5. `localeResolutionCallback` deferred a second time

Story 7.5.1 review deferred adding a `localeResolutionCallback`. Story 7.5.2 review deferred it again. The locked-in `locale: const Locale('it')` in `lib/app.dart` masks the issue today, but every story that defers the same item is one more place the lesson is forgotten. Not a critical issue (latent only when the hardcoded locale is removed), but a process signal.

**Lesson:** When a deferred item is re-deferred twice in consecutive stories with no externally-changing trigger, promote it to the ledger explicitly with a clear "activates when X" condition, rather than letting reviewers re-defer it ad hoc. Or close it.

---

## Previous Retrospective Follow-Through (Epic 7 → Epic 7.5)

| Epic 7 commitment | Status | Evidence |
|---|---|---|
| Create Epic 7.5 — i18n / `gen_l10n` migration interstitial (max 2 stories) | ✅ Done | This retro closes Epic 7.5. Two stories shipped, scope cap honored. **Closes E7-P1.** |
| Story 8.0 — SessionLog DAO + per-session completion persistence | ⏳ Pending | Story 8.0 not yet created. Remains the next critical-path item before Story 8.1. **E7-F1 still `in-progress`.** |
| Add `vibration` package to pubspec | ⏳ Pending | Not yet added. Required before Story 8.3 enters sprint. **E7-T1 still `pending`.** |
| Pre-flight architect identity-vs-position review for Cubit/BLoC stories | ⏳ Pending (ongoing process) | Not triggered yet (no new Cubit/BLoC story in Epic 7.5). Will activate at first Epic 8 candidate. **E7-P2 still `pending`.** |
| Edge-Case Hunter prompt update — `Hero` inside `AnimatedSwitcher` collision | ⏳ Pending | Skill prompt not yet updated. Should land before Epic 8 starts. **E7-P3 still `pending`.** |
| Golden / viewport test infrastructure for above-the-fold AC | ⏳ Pending | Coupled to Epic 11. **E7-T2 still `pending`** (intentional). |

**Pattern (carrying forward):** Epic 7's "i18n interstitial" commitment shipped exactly as designed (2-story cap, scope held). The other 5 Epic 7 commitments are mostly trigger-based (activate at a specific upcoming story or skill-maintenance event) and have not yet hit their triggers — they are correctly `pending`, not slipping.

---

## Key Insights

1. **Interstitial epics work when scope is hard-capped and every story restates the cap.** Epic 6.5 (Foundation Hardening, 4 stories) and Epic 7.5 (i18n, 2 stories) both shipped within their declared caps. The pattern is reusable: when 3+ stories defer the same debt, promote it to a capped interstitial.
2. **`Correct-Course Note` is the right pressure-release valve for tooling-reality vs spec-as-written deltas.** Story 7.5.1 used it cleanly; the alternative (block-and-replan) would have wasted a day.
3. **Magnitude-based guardrails (`+3 tests`, `+N lines`) trip on parallel work.** Replace with invariant-based guardrails (`zero removed`, `all green`, `new tests added for new ACs`).
4. **Flutter SDK deprecation drift between LLM training data and the pinned SDK is a known story-creation failure mode.** Add explicit deprecation pre-check to create-story for SDK-version-sensitive specs.
5. **Scope discipline that plants dead code creates a Chesterton's fence unless the dead code is ledger-tracked.** Story 7.5.2's 7 orphan ARB transition keys are now E7.5-T1, not a silent fence.
6. **The Deferred Items Budget rule needs disambiguation.** It empirically blocks Epic 8 kickoff under strict reading. Either rewrite the rule to distinguish "ongoing process" from "deliverable debt", or run PM triage to bring count ≤ 5 before Epic 8 sprint plan.
7. **EN ARB review pays off even when EN isn't user-visible.** Bilingual semantic swaps are easy to miss; Blind Hunter caught one in Story 7.5.2.

---

## Next Epic Preview — Epic 8: In-Session Experience

5 stories planned (8.1–8.5) plus Story 8.0 (SessionLog DAO) inserted per Epic 7 retro: `8.0 → 8.1 (CountdownOverlay) → 8.2 (InSessionView timer + step) → 8.3 (haptic feedback) → 8.4 (live HR) → 8.5 (abandon flow)`.

### Dependencies on Epic 7.5

- ✅ ARB pipeline live — all new Epic 8 user-facing copy resolves through `AppLocalizations`, no fresh hardcoded strings
- ✅ Test wrapper pattern reusable — `MaterialApp` with delegates + `await AppLocalizations.delegate.load(const Locale('it'))` for unit tests
- ⚠️ 7 `transition*` ARB keys live but unused at consumer — E7.5-T1 tracked against an Epic 8.x story to migrate `BehavioralStateMachine` literals into ARB

### Critical Path Before Story 8.1

1. **PM (John) triage Deferred Items Budget breach.** 11 pending vs cap 5. Either close/drop/promote items to bring count ≤ 5, or formally rewrite the rule to distinguish ongoing-process from deliverable-debt. *Gates Epic 8 sprint plan under strict reading of CLAUDE.md.*
2. **Story 8.0 — SessionLog DAO + per-session completion persistence.** Closes E7-F1. Folds in `_isSamePlan` heuristic refactor.
3. **`vibration` package to pubspec.** Required before Story 8.3.
4. **Edge-Case Hunter skill prompt update** — `Hero` + `AnimatedSwitcher` cross-fade collision check.

### Non-blocking but recommended

- Add Flutter-deprecation pre-check to architect's create-story workflow (E7.5-P1).
- Re-spec AC7-style test-count guardrails to invariant-based form (E7.5-P2) before next AC that would use one.

---

## Action Items

### Process (this retro adds 3 items)

1. **Flutter deprecation pre-check during story-creation for SDK-version-sensitive specs.**
   Owner: Winston (Architect) during create-story.
   Trigger: any story touching l10n config, build config, plugin registrations, deprecated/borderline-deprecated Flutter APIs.
   Success criteria: story spec cross-references pinned Flutter SDK version against known deprecations before AC text is finalized. Avoids the Story 7.5.1 `synthetic-package` mid-flight Correct-Course pattern.
   Ledger entry: **E7.5-P1** (pending).

2. **Rework AC7-style integer-delta test-count guardrails to invariant-based form.**
   Owner: Amelia (Developer) during story-creation.
   Trigger: next story that would otherwise specify a `+N tests` cap.
   Success criteria: replaces `"test count grows by at most +N"` with three invariants:
   - "Zero existing tests removed."
   - "All existing tests still green (`flutter test` exit 0)."
   - "New tests added for this story's ACs are present and passing."
   Rationale: integer deltas trip falsely on parallel valid test work (Story 7.5.1 went +13 vs cap +3 because Epic 7 traceability tests landed in the same baseline window).
   Ledger entry: **E7.5-P2** (pending).

3. **Track 7 dead ARB `transition*` keys explicitly until consumer wiring lands.**
   Owner: Amelia (Developer).
   Trigger: an Epic 8.x story that migrates `BehavioralStateMachine` transition message emission from hardcoded literals to ARB keys (or to an enum that `StateIndicator` resolves via ARB).
   Success criteria: `lib/ai/state_machine/behavioral_state_machine.dart` lines 35, 44, 53, 68, 81, 94 emit ARB-resolved transition keys (or a non-string transition enum); the 7 `transition*` keys in `app_it.arb` / `app_en.arb` are referenced by at least one widget code path.
   Rationale: scope cap of Epic 7.5 was correct (no 7.5.3); but the orphaned keys must not be silent Chesterton's fences.
   Ledger entry: **E7.5-T1** (pending).

### Carry-Over Closures (apply to ledger after retro)

4. **Close in `action-item-ledger.md`:**
   - **E7-P1 → done** (closed by Epic 7.5 — both stories shipped, ARB pipeline live, all Epic 7 hardcoded Italian strings migrated, "COMING UP" → "PROSSIME"). Evidence: this retro doc + git commits `0b9e6ea` (Story 7.5.1) and `f32ec29` (Story 7.5.2) and `c0db190` (post-merge l10n smoke + traceability artifacts).

### Process / Budget Triage (gating Epic 8 kickoff)

5. **PM (John) — Deferred Items Budget triage before Epic 8 sprint plan.**
   Owner: PM (John).
   Trigger: Epic 8 sprint kickoff.
   Success criteria: pending count in `action-item-ledger.md` is ≤ 5, OR the rule itself is formally rewritten in CLAUDE.md to distinguish "ongoing-process items" from "deliverable-debt items" with separate caps.
   Current count: 11. Excess: 6.

---

## Significant Discovery Assessment

**Epic 8 plan updates required:** No fundamental change to Stories 8.0–8.5 acceptance criteria. Three process-level discoveries to apply:

- Add deprecation pre-check to create-story (E7.5-P1).
- Replace integer-delta test-count guardrails with invariants (E7.5-P2) when next applicable AC is written.
- Track ARB transition-key wiring as an explicit Epic 8.x scope candidate (E7.5-T1).

`epics.md` does not need a structural change. The Deferred Items Budget breach is the one gating concern.

---

## Readiness Assessment

| Area | Status | Notes |
|---|---|---|
| Story Completion | Pass | 2/2 Epic 7.5 stories `done` |
| Automated Tests | Pass | `flutter test`: 516/516; +1 ARB smoke from 7.5.1 |
| Static Analysis | Pass | 0 issues (zero-tolerance preserved across both stories) |
| ARB Pipeline | Pass | `gen_l10n` wired; ARB inputs under `lib/l10n/app/`; generated outputs in `.gitignore`; `app_it.arb` carries 34 user-facing keys |
| Visible UI Delta | Pass | Only `"COMING UP"` → `"PROSSIME"`; on-device verification confirms all other Italian copy unchanged |
| Stakeholder Acceptance | Pass | Paolo (Project Lead) confirmed action items + deferred-item triage approach in this retro |
| Carry-Over Product Decisions | Pass | E7-P1 closed; no new product-decision debt added in Epic 7.5 |
| Process Hygiene | **At risk** | Deferred Items Budget at 11 pending vs cap 5. PM triage required at Epic 8 kickoff. |
| Technical Debt | Managed | 7 dead ARB transition keys explicitly tracked (E7.5-T1) instead of left silent |

**Verdict:** Epic 7.5 is **technically complete**. The one process concern (Deferred Items Budget breach) is gating Epic 8 sprint planning but does not block Epic 7.5 closure. Story 8.0 cannot enter sprint until PM triage resolves the budget.

---

## Team Agreements

- Interstitial epics must restate their story-count cap in every story's "Scope Boundary" section (the discipline that held Epic 7.5 to 2 stories).
- Correct-Course Notes are the supported mechanism for spec-vs-tooling deltas; do not block-and-replan when a Correct-Course Note + code-review acceptance can land in the same cycle.
- AC7-style test-count guardrails are deprecated. New ACs use invariant-based test guardrails.
- Story-creation for SDK-version-sensitive specs includes a Flutter deprecation pre-check.
- Scope-driven deferrals that plant new dead code must be ledger-tracked explicitly (not implicit in "Scope Boundary" prose).
- The Deferred Items Budget rule will be revisited at Epic 8 kickoff to disambiguate "ongoing-process" vs "deliverable-debt" items, OR triage will bring the count to ≤ 5 before Story 8.0 enters sprint.

---

## Handoff

Epic 7.5 is closed. Epic 8 (In-Session Experience) requires the following before Story 8.1 enters sprint:

1. **PM (John) Deferred Items Budget triage** — current 11 pending vs cap 5
2. **Story 8.0 — SessionLog DAO + per-session completion persistence** (closes E7-F1)
3. **`vibration` package added to pubspec** (Story 8.3 prerequisite)
4. **Edge-Case Hunter skill prompt update** — `Hero` + `AnimatedSwitcher` collision check (E7-P3)

Then Stories 8.1 → 8.5 in their planned order, with the new process guardrails (Flutter deprecation pre-check, invariant-based test guardrails) applied during their story-creation.

The ARB pipeline is live. The Today screen is fully localized. Only `"PROSSIME"` shifted on screen; everything else is bit-identical and 516/516 tests confirm it.
