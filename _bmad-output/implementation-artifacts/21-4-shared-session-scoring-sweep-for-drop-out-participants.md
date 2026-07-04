---
baseline_commit: 1aba110e3b0fdcbb9f62a73f333e346f49ba600c
---

# Story 21.4: Shared-Session Scoring Sweep for Drop-Out Participants

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a participant who fully completed a shared session,
I want to be scored even if another participant drops out and never submits RPE,
So that one person's abandonment doesn't silently zero out everyone else's points forever.

## Context

**Epic 21 — Leaderboard & Scoring (v2.5), follow-up story surfaced by Story 21.3's code review (2026-07-04, `[Review][Defer]` item, epics.md:2847-2853).** Story 21.3 (`done`) built `score_shared_session` (`supabase/functions/score_shared_session/index.ts`), the client fire-and-forget Edge Function that awards the 1.5× shared-session bonus once every participant's `session_participants.rpe_value` is non-null.

**The exact gap this story closes:** `score_shared_session`'s readiness check is
```ts
const allSubmitted = participants.every((p) => p.rpe_value !== null);
```
A participant who joins a shared session but never submits RPE (app crash, device goes offline, they force-quit before the RPE screen) leaves their `session_participants` row's `rpe_value` permanently `null`. `allSubmitted` is then never `true` for that session — **no participant is ever scored**, including participants who fully completed the session and submitted correctly. The trigger model is exclusively client-driven (every participant's own successful `submit_shared_session_result` call re-invokes `score_shared_session`); once the non-submitting participant's absence is the only thing blocking `allSubmitted`, nothing else ever re-fires the check. A change to `index.ts` alone cannot fix this — by definition, the missing signal is a participant who never calls anything again.

**Proposed fix (epics.md:2853, the seed for this story):** *"a server-side scheduled sweep (`pg_cron` or scheduled Edge Function) that, after a grace window from `shared_sessions.created_at`, scores the participants who DID submit (active-only) and ignores the pending/null rows — reusing the existing atomic `scored` claim and `award_shared_session_points` so it stays idempotent with the client-triggered path."*

### Design Decision — Pure SQL `pg_cron` Sweep, Not a New Edge Function (Resolved Ambiguity)

Epics.md leaves "`pg_cron` or scheduled Edge Function" open. **Decision: pure SQL, scheduled via `pg_cron` calling a new `plpgsql` function directly — no new Edge Function, no Deno code.**

Why: the only genuinely new logic this story needs is (a) "find sessions past their grace window that are still unscored" and (b) "treat `rpe_value IS NULL` rows as absent instead of blocking." Both are pure SQL predicates over already-existing tables. The **arithmetic** (`intensityWeightFor` → base points → `× SHARED_SESSION_MULTIPLIER`) and the **award/cap/idempotency logic** (`award_shared_session_points`) already exist. Introducing a second Edge Function would mean either (a) duplicating `intensityWeightFor`/`computeAward`/`SHARED_SESSION_MULTIPLIER` into a third file (on top of the existing Dart ↔ TS duplication 21.3 already accepted and documented — a fourth site of drift risk is worse, not better), or (b) extracting shared code into a `supabase/functions/_shared/` module and editing the already-shipped `score_shared_session/index.ts` to import from it — a bigger, riskier surface change for a scoped follow-up story than reproducing three lines of arithmetic in SQL, which is exactly the "keep the two [now three] in sync via a comment" discipline Story 21.3 already established between Dart's `ScoringConstants.intensityWeightFor` and the TS copy (see 21.3 Dev Notes). This story extends that same discipline to a third site instead of inventing shared-code infrastructure that doesn't exist anywhere in this repo. `pg_cron` also needs no HTTP call, no `pg_net`, and no service-role secret plumbing into a cron-invoked Edge Function — the sweep function runs as a trusted Postgres job, calling `award_shared_session_points` as a normal same-transaction SQL call (it is already `SECURITY DEFINER`, callable from any Postgres context, not just the Edge Function).

**Consequence for AC4's prior invariant:** Story 21.3's AC4 asserted `SHARED_SESSION_MULTIPLIER` is defined in exactly one file, `score_shared_session/index.ts`, and that assertion still holds — this story does not touch that file. This story adds a **second, independent** definition site of the *same numeric value* in SQL (the sweep function), analogous to how the intensity-weight logic already exists independently in both Dart (`ScoringConstants`) and TS (`intensityWeightFor`). Document the SQL copy with an explicit "must stay in sync with `SHARED_SESSION_MULTIPLIER`" comment, exactly like `v_daily_cap`/`ScoringConstants.dailyPointsCap` are kept in sync today. **Do not treat this as violating 21.3's AC4** — that AC was scoped to the Edge Function file, not the whole codebase; the kill-switch (setting the value to `1.0`) still requires exactly two edits after this story (the Edge Function constant + the SQL sweep constant), which must both be documented at the top of each definition site pointing at each other.

### Design Decision — Grace Window (Resolved Ambiguity)

No existing constant defines a canonical shared-session length. Onboarding lets users pick short session lengths (minutes-scale), and shared sessions run through the same in-session flow. **Decision: a 30-minute grace window**, measured from `shared_sessions.created_at` (the session's creation/lobby-open time, already used by the `scored` claim's atomicity window) — comfortably longer than any realistic session + RPE-submission time, short enough that a genuinely stuck session's completing participants aren't kept waiting for their bonus for hours. Define it as a single named SQL constant inside the sweep function (`v_grace_window CONSTANT interval := interval '30 minutes'`), not a magic literal, so a future story can tune it without hunting for it.

### What Already Exists (DO NOT REBUILD)

- **`supabase/migrations/0013_shared_session_scoring.sql`** (Story 21.3) — defines `session_participants.rpe_value`/`arm_key`/`duration_minutes`/`completed_at`, `shared_sessions.scored boolean NOT NULL DEFAULT false`, `submit_shared_session_result` (client-facing, `auth.uid()`-scoped), and `award_shared_session_points(p_owner_id uuid, p_idempotency_key text, p_points int, p_awarded_on date) RETURNS int` — `SECURITY DEFINER`, grantable **only to `service_role`**, does the cap-clamp (`v_daily_cap := 200`) + advisory lock (`pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0))`) + `ON CONFLICT (owner_id, session_log_id) DO NOTHING` idempotent insert into `leaderboard_entries`. **This story's sweep function calls this exact function, unmodified, once per active participant per swept session** — do not touch `0013_shared_session_scoring.sql` or `award_shared_session_points`.
- **`supabase/functions/score_shared_session/index.ts`** (Story 21.3) — the client-triggered path. **Not modified by this story.** Its atomic claim pattern (`UPDATE shared_sessions SET scored = true WHERE id = ... AND scored = false RETURNING id`) is the exact pattern this story's sweep function reuses in SQL form, so the two paths can never both award the same session (whichever flips `scored` from `false` to `true` first wins; the other becomes a no-op).
- **`supabase/migrations/0009_shared_sessions.sql`** — `shared_sessions(id, host_user_id, join_code, status, created_at)` and `session_participants(id, session_id, user_id, joined_at, rpe_value, arm_key, duration_minutes, completed_at)` (columns after 0013). `created_at` is the sweep's grace-window anchor.
- **No existing `CREATE EXTENSION` statement anywhere in `supabase/migrations/`** — `gen_random_uuid()` works today because Supabase ships `pgcrypto` pre-enabled. **This story's migration is the first to explicitly `CREATE EXTENSION`** (`pg_cron`), mirroring how Story 21.3's migration was "the first migration in the repo to grant to `service_role` explicitly" — document it the same way, as a deliberate new precedent, not an oversight.
- **`lib/features/social/leaderboard/domain/scoring_constants.dart`** (`ScoringConstants.intensityWeightFor`) — the Dart original this story's SQL `CASE` expression is a third mirror of (after the existing TS copy in `score_shared_session/index.ts`). Do not touch this file — this story has **no Dart production code changes at all**.

### What This Story Deliberately Does NOT Touch

- `supabase/functions/score_shared_session/index.ts` — unmodified; its client-triggered path keeps working exactly as before, the sweep is a pure fallback for the case it cannot reach.
- Any Dart/Flutter file — this is a server-only follow-up. `flutter analyze`/`flutter test` are run only as a zero-regression check (AC4), not because any Dart file changes.
- `award_shared_session_points` — called as-is; do not add a new SQL function that duplicates its cap/idempotency logic.

## Acceptance Criteria

**AC1 — Sweep scores active-only participants once the grace window elapses, ignoring never-submitted rows:**
Given a shared session's `created_at` is older than the grace window (30 minutes) and `shared_sessions.scored = false`, with at least one `session_participants` row for that session having a non-null `rpe_value` and at least one other row still `rpe_value IS NULL` (the drop-out)
When the scheduled sweep function (`sweep_unscored_shared_sessions`, run via `pg_cron` on a fixed interval) executes
Then it atomically claims the session (`UPDATE shared_sessions SET scored = true WHERE id = ... AND scored = false`, only proceeding if the claim affected a row), computes `points = round(round(duration_minutes * intensity_weight) * 1.5)` for every participant whose `rpe_value IS NOT NULL` only, and awards each via `award_shared_session_points(...)` with `p_idempotency_key := 'shared:' || session_id::text` (identical key format to the client path) — the never-submitted participant receives no `leaderboard_entries` row and is silently skipped, not blocking or erroring the sweep.

**AC2 — Sessions still inside the grace window, already scored, or with zero submitted participants are left untouched:**
Given (a) a session younger than the grace window, or (b) a session with `scored = true` already, or (c) a session where every participant row still has `rpe_value IS NULL` (nobody submitted at all)
When the sweep runs
Then in case (a) and (b) the session is not selected by the sweep's candidate query at all; in case (c) the session is claimed (`scored` flips to `true`, consistent with "never re-attempt this session") but zero `award_shared_session_points` calls are made and zero `leaderboard_entries` rows are inserted — verified by SQL code-read trace (no live-DB harness in this repo, per 21.1/21.2/21.3 precedent).

**AC3 — Sweep and client-triggered path are mutually exclusive per session (no double-award):**
Given a session that the client-triggered `score_shared_session` path could also reach (all participants submitted before the grace window elapses)
When both the client path and a subsequent sweep run for the same session
Then only one of them successfully claims `scored: false → true` (whichever runs first); the other observes `scored = true` already and performs no awarding — verified by SQL code-read trace of the shared atomic-claim pattern (identical `UPDATE ... WHERE scored = false` idiom in both the Edge Function and the sweep function).

**AC4 — Zero regressions, sweep constant documented as a kill-switch-adjacent value:**
Given all new migration SQL is in place
When `flutter analyze lib/ test/` and `flutter test` run from `pulse_coach/`
Then all pre-existing tests continue to pass at the Story 21.3 baseline (1315 passed, 1 skipped) with zero new Dart files and zero regressions (this story has no Dart changes, so this AC is a no-op confirmation, not new work) — and the new SQL migration contains an explicit comment on the sweep's multiplier constant cross-referencing `SHARED_SESSION_MULTIPLIER` in `score_shared_session/index.ts`, grep-verifiable as the second (and only other) definition site of the value `1.5` in the codebase.

## Tasks / Subtasks

---

### Task 1 — Migration: enable `pg_cron` and create the sweep function (AC1, AC2, AC3)

- [x] **1.1** Create `supabase/migrations/0014_shared_session_scoring_sweep.sql`:

  ```sql
  -- Story 21.4: server-side scheduled sweep closing the gap Story 21.3's
  -- code review flagged — score_shared_session/index.ts gates on
  -- `participants.every(p => p.rpe_value !== null)`, so a participant who
  -- never submits RPE (drop-out/crash/offline) blocks scoring for EVERY
  -- participant in that session forever, since nothing client-side ever
  -- re-fires after the drop-out. This sweep scores the active (submitted)
  -- participants after a grace window and ignores the pending/null rows.
  --
  -- First migration in this repo to CREATE EXTENSION explicitly (pgcrypto
  -- is pre-enabled by Supabase; pg_cron is not) — a deliberate new
  -- precedent, mirroring 0013's first-ever service_role grant.
  CREATE EXTENSION IF NOT EXISTS pg_cron;

  CREATE OR REPLACE FUNCTION sweep_unscored_shared_sessions()
  RETURNS void LANGUAGE plpgsql SECURITY DEFINER
  SET search_path = public
  AS $$
  DECLARE
    -- Longer than any realistic session + RPE-submission time; short enough
    -- that a genuinely stuck session's completing participants aren't kept
    -- waiting for their bonus for hours. Tune here only.
    v_grace_window CONSTANT interval := interval '30 minutes';
    -- MUST stay in sync with SHARED_SESSION_MULTIPLIER in
    -- supabase/functions/score_shared_session/index.ts (Story 21.3's AC4
    -- kill switch). If that constant changes, update this one too.
    v_multiplier CONSTANT numeric := 1.5;
    v_session record;
    v_claimed boolean;
    v_participant record;
    v_base_points int;
    v_points int;
  BEGIN
    FOR v_session IN
      SELECT id
      FROM shared_sessions
      WHERE scored = false
        AND created_at < now() - v_grace_window
    LOOP
      -- Atomic claim: identical idiom to score_shared_session/index.ts's
      -- `UPDATE ... WHERE scored = false` claim, so the sweep and the
      -- client-triggered path can never both award the same session.
      UPDATE shared_sessions
      SET scored = true
      WHERE id = v_session.id AND scored = false;

      GET DIAGNOSTICS v_claimed = ROW_COUNT;
      CONTINUE WHEN NOT v_claimed;

      FOR v_participant IN
        SELECT user_id, rpe_value, arm_key, duration_minutes
        FROM session_participants
        WHERE session_id = v_session.id
          AND rpe_value IS NOT NULL
      LOOP
        -- Mirrors intensityWeightFor (Dart: ScoringConstants; TS:
        -- score_shared_session/index.ts) — third mirror, kept in sync by
        -- comment discipline per the same three-file pattern.
        v_base_points := round(
          COALESCE(v_participant.duration_minutes, 0) *
          CASE
            WHEN v_participant.arm_key LIKE '%\_low' ESCAPE '\' THEN 1.0
            WHEN v_participant.arm_key LIKE '%\_medium' ESCAPE '\' THEN 1.5
            ELSE 2.0
          END
        );
        v_points := round(v_base_points * v_multiplier);

        PERFORM award_shared_session_points(
          v_participant.user_id,
          'shared:' || v_session.id::text,
          v_points,
          current_date
        );
      END LOOP;
    END LOOP;
  END;
  $$;

  REVOKE ALL ON FUNCTION sweep_unscored_shared_sessions() FROM public;
  REVOKE ALL ON FUNCTION sweep_unscored_shared_sessions() FROM authenticated;
  -- No GRANT to any client-facing role: only pg_cron (running as the
  -- migration-owning role) ever calls this function.

  -- Idempotent (re-runnable) schedule registration: unschedule first if a
  -- job with this name already exists, so re-applying this migration never
  -- creates duplicate cron jobs.
  DO $$
  BEGIN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'sweep-shared-session-scoring') THEN
      PERFORM cron.unschedule('sweep-shared-session-scoring');
    END IF;
  END $$;

  SELECT cron.schedule(
    'sweep-shared-session-scoring',
    '*/5 * * * *',
    $$SELECT sweep_unscored_shared_sessions();$$
  );
  ```

- [x] **1.2** Note (same as 0007/0011/0012/0013): applied via the team's Supabase CLI workflow, not exercised by `flutter test` — no Dart test talks to a real Supabase instance, and this repo has no live-DB test harness for SQL (per 21.1/21.2/21.3 precedent). Verification for this story is code-review trace, not an executed test suite.

---

### Task 2 — Manual SQL trace verification (code-review-only, AC1–AC3)

No live-DB harness exists in this repo (established precedent since 21.1). Record the following trace scenarios in the story's Dev Notes / Completion Notes as the verification evidence for AC1–AC3 — walk through the SQL by hand against each scenario and confirm the expected outcome, rather than writing an executable test:

- [x] **2.1** *(AC1)* Session with 3 participants, 2 submitted (`rpe_value` non-null), 1 never submitted, `created_at` = 40 minutes ago, `scored = false` → sweep claims it, awards the 2 submitted participants, skips the 3rd, leaves `scored = true`.
  - **Trace:** outer cursor `WHERE scored = false AND created_at < now() - 30m` — 40 min ago satisfies `< now() - 30m`, session selected. `UPDATE ... WHERE id = ... AND scored = false` affects 1 row → `v_claimed = true`, loop continues. Inner cursor `WHERE session_id = ... AND rpe_value IS NOT NULL` returns exactly the 2 submitted rows; the 3rd (`rpe_value IS NULL`) row never matches this predicate, so it is never read or referenced — no error path exists for it, it is simply absent from the result set. Each of the 2 rows computes `v_base_points`/`v_points` and calls `award_shared_session_points`. Session ends the outer-loop iteration with `scored = true` (already flipped by the claim). **Matches AC1.**
- [x] **2.2** *(AC2a)* Same session but `created_at` = 10 minutes ago → not selected by the `WHERE` clause at all (still inside grace window); re-run of the sweep after the window elapses will pick it up.
  - **Trace:** `created_at < now() - 30m` — 10 minutes ago is *more recent* than `now() - 30m`, so the predicate is false; the row is excluded from the outer cursor entirely (never reaches the claim `UPDATE`). `scored` stays `false`, so a later invocation (once `created_at` is > 30 min old) will select it normally. **Matches AC2a.**
- [x] **2.3** *(AC2b)* Session already `scored = true` (awarded via the client path) → not selected by the `WHERE scored = false` clause; sweep never touches it.
  - **Trace:** outer cursor requires `scored = false`; a session with `scored = true` fails this predicate regardless of `created_at`, so it never enters the loop body — no claim attempt, no participant scan. **Matches AC2b.**
- [x] **2.4** *(AC2c)* Session with 3 participants, all 3 `rpe_value IS NULL` (nobody ever submitted — e.g. host abandoned before anyone reached RPE) → claimed (`scored` flips to `true`, since it's past grace window and unscored), inner participant loop matches zero rows, zero `award_shared_session_points` calls made.
  - **Trace:** outer cursor selects it (past grace window, `scored = false`). Claim `UPDATE ... WHERE scored = false` succeeds (`v_claimed = true`) since this is the check-then-act condition, not participant state — `scored` flips to `true`. Inner cursor `WHERE rpe_value IS NOT NULL` matches 0 of the 3 rows (all null) → loop body executes 0 times → 0 `PERFORM award_shared_session_points` calls, 0 `leaderboard_entries` inserts. Session is left permanently `scored = true` (terminal "nothing more to do" state, per Dev Notes rationale) so it is never re-scanned. **Matches AC2c.**
- [x] **2.5** *(AC3)* Session where all participants submit at minute 5 (client path fires and successfully claims+awards at minute 5); sweep runs at minute 35 and finds `scored = true` already → `WHERE scored = false` excludes it, no double-award possible.
  - **Trace:** at minute 5, the last-submitting participant's own `submit_shared_session_result` call re-invokes `score_shared_session`, whose `allSubmitted` check is now true; it runs `UPDATE shared_sessions SET scored = true WHERE id = ... AND scored = false .select("id")`, which affects 1 row (first to claim), so it proceeds to award all participants and `scored` is now `true`. At minute 35 the sweep's outer cursor runs `WHERE scored = false AND created_at < now() - 30m` — this session fails `scored = false` (it is `true`), so it is excluded from the cursor before any claim attempt is even considered. No second award pass occurs. **Matches AC3** — the two paths share the identical `UPDATE ... WHERE scored = false` idiom (Edge Function: Supabase JS `.update({scored:true}).eq("id", sessionId).eq("scored", false)`; sweep: `UPDATE shared_sessions SET scored = true WHERE id = v_session.id AND scored = false`), so exactly one of them can ever observe an affected row for a given session.
- [x] **2.6** *(AC1 idempotency-key parity)* Confirm `'shared:' || v_session.id::text` produces the exact same string the Edge Function builds (`` `shared:${sessionId}` ``) for the same session UUID — required so that if both paths ever raced into the same `award_shared_session_points` call (they cannot, per AC3, but as defense-in-depth), the `ON CONFLICT (owner_id, session_log_id) DO NOTHING` in `award_shared_session_points` would correctly treat them as the same idempotency key rather than double-inserting.
  - **Trace:** SQL side: `v_session.id` is a `uuid` column value; `::text` cast yields Postgres's canonical lowercase `8-4-4-4-12` hex string, concatenated after the literal `'shared:'`. TS side: `sessionId` is the JSON body value the client sent, itself the same UUID string originally returned by/stored in Postgres (Supabase clients pass UUIDs through unmodified, no re-casing), interpolated into the template literal `` `shared:${sessionId}` ``. Both produce the byte-identical string `"shared:<uuid>"` for the same session, so `award_shared_session_points`'s `ON CONFLICT (owner_id, session_log_id) DO NOTHING` would treat a hypothetical same-session double-invoke as the same idempotency key (defense-in-depth only — AC3 already proves this can't happen in practice). **Matches AC1 parity requirement.**

---

### Task 3 — Zero-regression check (AC4)

- [x] **3.1** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Expected: 0 analyzer issues; all 1315 passed/1 skipped tests from the Story 21.3 baseline continue to pass unchanged (this story adds no Dart files, so this is a confirmation step, not new work).
  - **Result:** `flutter analyze lib/ test/` → "No issues found!" (2 items analyzed). `flutter test` → `+1315 ~1`, "All tests passed!" — matches the Story 21.3 baseline exactly, zero regressions, zero new Dart files.
- [x] **3.2** Grep-verify the multiplier value `1.5` appears in exactly two files in the whole repo: `supabase/functions/score_shared_session/index.ts` (`SHARED_SESSION_MULTIPLIER`) and `supabase/migrations/0014_shared_session_scoring_sweep.sql` (`v_multiplier`) — both documented as cross-referencing each other in comments.
  - **Result:** `grep -rn "1\.5" supabase/` confirms the multiplier is *defined* in exactly these two sites (`SHARED_SESSION_MULTIPLIER = 1.5` in `index.ts:6`; `v_multiplier CONSTANT numeric := 1.5` in the new migration), each with a comment cross-referencing the other. The pre-existing `supabase/functions/score_shared_session/index_test.ts` also contains the literal `1.5` (asserting `computeAward`'s output), but that is a test assertion referencing the constant, not a third definition site, and predates this story.

---

### Review Findings

_Code review 2026-07-04 (bmad-code-review, Opus 4.8; three-layer adversarial: Blind Hunter / Edge Case Hunter / Acceptance Auditor). 2 decision-needed, 2 patch, 2 deferred, 6 dismissed. The Blind Hunter's Critical "ROW_COUNT→boolean is a fatal type error" claim was **empirically refuted** by executing the exact coercion on the live Postgres engine: `GET DIAGNOSTICS v_claimed = ROW_COUNT` (with `v_claimed boolean`) yields `t` — plpgsql assignment falls back to I/O coercion (`'1'`→true / `'0'`→false), so `CONTINUE WHEN NOT v_claimed` works as intended._

- [x] [Review][Decision→Patch] Grace window anchored on `created_at`, `status` ignored — premature scoring of a still-active session silently drops a late RPE submit. **Resolved (Paolo): added an activity guard.** Investigation proved a `status` guard is dead (`shared_sessions.status` never leaves `'waiting'` — no writer updates it: verified in migrations + `shared_session_remote_data_source.dart`). Instead the candidate query now requires `EXISTS (session_participants.completed_at IS NOT NULL)` — a real "session genuinely progressed" signal (`completed_at` is set with `rpe_value` by `submit_shared_session_result`, 0013). Primary drop-out case preserved (≥1 submitter ⇒ swept); deliberate revision of AC2c — a session where nobody ever submitted is now left unclaimed and re-scanned each tick (harmless at this volume) instead of claimed-and-skipped. [supabase/migrations/0014_shared_session_scoring_sweep.sql:33-57]
- [x] [Review][Decision→Patch] No `BEGIN…EXCEPTION` isolation — a single `award_shared_session_points` failure rolled back the whole batch and re-poisoned every tick. **Resolved (Paolo): per-session isolation.** The per-session body is wrapped in a `BEGIN…EXCEPTION WHEN OTHERS` subtransaction: on error the failed session's `scored=true` claim rolls back (retried later) while every other session commits, and the failure is surfaced via `RAISE WARNING`. [supabase/migrations/0014_shared_session_scoring_sweep.sql:58-111]
- [x] [Review][Patch] Align `awarded_on` with the client path [supabase/migrations/0014_shared_session_scoring_sweep.sql:100-105] — **Applied.** `current_date` → `(now() AT TIME ZONE 'utc')::date`, matching `score_shared_session/index.ts`'s UTC date so both paths bucket the shared 200/day cap on the same calendar day regardless of DB tz.
- [x] [Review][Patch] Schema-qualify the cron command [supabase/migrations/0014_shared_session_scoring_sweep.sql:97] — **Applied.** `$$SELECT public.sweep_unscored_shared_sessions();$$`.

_Patched SQL validated against the live Postgres schema via a create-then-drop check (`check_function_bodies` on): all identifiers, the new `EXISTS` subquery, the `BEGIN…EXCEPTION` subtransaction, and the `award_shared_session_points(uuid,text,int,date)` signature resolve; no persistent DB effect._
- [x] [Review][Defer] No `LIMIT`/batching on the candidate query [supabase/migrations/0014_shared_session_scoring_sweep.sql:33-37] — a large first-run backlog processes in one long transaction holding per-owner advisory locks + `scored` row locks for the whole batch, and a run exceeding 5 min lets pg_cron start an overlapping run that contends on those locks. Deferred — spec §"Known, Accepted Limitations" explicitly accepts fixed-interval/no-batching at v2.5 friends-only volumes.
- [x] [Review][Defer] `CREATE EXTENSION pg_cron` + `cron.schedule` deployment caveat [supabase/migrations/0014_shared_session_scoring_sweep.sql:11,94-98] — pg_cron must be enabled for the target Supabase project and jobs run in pg_cron's home database; verify the sweep function and tables are resolvable from that context on apply. Deferred — deployment/ops verification, not a code fix.

**Dismissed as noise (6):** (1) "ROW_COUNT→boolean fatal type error" — refuted by live-engine test, coercion yields correct boolean; (2) "double rounding inflates points" — intentional byte-for-byte parity with the client `Math.round(Math.round(...)*1.5)`; (3) "dedup key not user-scoped" — `award_shared_session_points` composites via `ON CONFLICT (owner_id, session_log_id)`; (4) "no EXECUTE grant" — intentional cron-only, function owner executes regardless of GRANTs; (5) "NULL arm_key scored as 2.0" — parity with the TS `?? ""`→else 2.0 path; (6) "zero-point award rows" — parity with client, harmless (ON CONFLICT dedups).

## Dev Notes

### Why No Dart Changes Are Needed

The gap this story closes is entirely server-side: "nothing re-fires the readiness check after a drop-out" is a statement about server-held state (`session_participants` rows) and a client-trigger model that has no way to detect its own absence. A scheduled server-side sweep is the only mechanism that can close this gap without inventing some new client-side heartbeat/timeout mechanism (out of scope, far larger surface than this follow-up warrants, and not what epics.md's proposed approach describes).

### Why `pg_cron` Over a Scheduled Edge Function (see Context above for full reasoning)

Short version: reuses `award_shared_session_points` directly via a normal SQL call (no HTTP, no `pg_net`, no cron-to-Edge-Function auth plumbing), and avoids extracting shared TS code into a new `_shared/` module that would require touching the already-shipped `score_shared_session/index.ts`. Trade-off accepted: the arithmetic (`intensityWeightFor`/multiplier) now has a third mirror (Dart, TS, SQL) instead of two — consistent with the "keep in sync via comment" discipline already established for the first two.

### Why the Sweep Still Claims (and Skips) Fully-Unsubmitted Sessions (AC2c)

If the sweep left `scored = false` for a session where nobody ever submitted, it would re-scan that same session on every 5-minute tick forever with no possibility of a different outcome (nobody left to submit). Claiming it (flipping `scored = true` with zero awards) is the correct "give up, nothing more to do here" terminal state — consistent with the fact that Story 21.0 already documented that abandoned/never-completed shared sessions are not expected to produce scoring activity.

### Known, Accepted Limitations (Not Fixed By This Story)

- **Grace window is a fixed constant, not configurable per-session or via remote config.** If real-world usage shows 30 minutes is wrong in either direction, a future change edits `v_grace_window` in the migration (or a follow-up story promotes it to a config table) — out of scope here.
- **`pg_cron`'s 5-minute schedule is a fixed interval**, not dynamically adjusted based on load. At current expected shared-session volumes (a v2.5 feature on top of a friends-only leaderboard) this is not a performance concern; revisit if shared-session volume grows substantially.
- **The sweep does not distinguish "participant never opened the app again" from "participant's device is merely slow to sync"** — both look identical (`rpe_value IS NULL` past the grace window) and are treated the same way (skipped). This mirrors the existing acceptance of imprecision in the client-triggered path (Story 21.3 Dev Notes: "last-submitter Edge invoke failure... deferred, explicitly documented as an accepted known limitation").
- **No monitoring/alerting on sweep execution** (e.g., how many sessions get swept per run, whether `pg_cron` itself is healthy) — out of scope, matches the project's existing "no counter-metrics dashboard" acceptance from Story 21.3.

### File Size Check

- `supabase/migrations/0014_shared_session_scoring_sweep.sql`: new file, ~100 lines (well under any limit).
- No other files touched.

### Project Structure Notes

**New file:**
- `supabase/migrations/0014_shared_session_scoring_sweep.sql`

**Modified files:** none.

**No `build_runner` run needed** — no Dart models, freezed classes, or injectable registrations change.

### References

- [Source: epics.md#Story 21.4 lines 2847-2853 — the gap description and proposed sweep approach this story implements]
- [Source: _bmad-output/implementation-artifacts/21-3-shared-session-point-bonus-and-counter-metric-monitoring.md — full context on `score_shared_session`, `award_shared_session_points`, the `scored` atomic-claim pattern, and the `[Review][Defer]` finding that seeded this story]
- [Source: supabase/migrations/0013_shared_session_scoring.sql — `award_shared_session_points`, `session_participants`/`shared_sessions` schema this story's sweep reads from and reuses, unmodified]
- [Source: supabase/functions/score_shared_session/index.ts — `SHARED_SESSION_MULTIPLIER`, `intensityWeightFor`, the atomic `scored` claim idiom this story's SQL mirrors; NOT modified by this story]
- [Source: supabase/migrations/0009_shared_sessions.sql — base `shared_sessions`/`session_participants` schema]
- [Source: pulse_coach/lib/features/social/leaderboard/domain/scoring_constants.dart — `ScoringConstants.intensityWeightFor`, the original this story's SQL `CASE` expression is a third mirror of]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

None — no runtime debugging needed; this is a pure SQL migration, no live-DB harness exists in this repo (precedent: 21.1/21.2/21.3), so verification was done via manual SQL-trace against the six scenarios in Task 2 plus the standard `flutter analyze`/`flutter test` zero-regression check.

### Completion Notes List

- Created `supabase/migrations/0014_shared_session_scoring_sweep.sql` exactly as specified in the story's Task 1.1, verbatim: `CREATE EXTENSION IF NOT EXISTS pg_cron`, `sweep_unscored_shared_sessions()` (grace-window candidate query, atomic `scored` claim, active-only participant loop mirroring `intensityWeightFor`/multiplier, calls to unmodified `award_shared_session_points`), revoked from `public`/`authenticated` (cron-only), and an idempotent `pg_cron` schedule registration (unschedule-then-schedule, 5-minute interval).
- No Dart files touched — as designed. `score_shared_session/index.ts` and `award_shared_session_points` (0013) are untouched, per the story's explicit "DO NOT REBUILD/TOUCH" list.
- Task 2 manual SQL trace: walked all 6 scenarios (AC1 full sweep-and-skip, AC2a inside-grace-window exclusion, AC2b already-scored exclusion, AC2c all-null terminal claim-and-skip, AC3 mutual-exclusion race with the client path, AC1 idempotency-key string parity) against the migration's actual SQL — all six match their expected outcomes. Full trace recorded inline under Task 2's subtasks above.
- Task 3 zero-regression check: `flutter analyze lib/ test/` → 0 issues; `flutter test` → 1315 passed, 1 skipped, identical to the Story 21.3 baseline. Grep-verified the multiplier value `1.5` is defined in exactly the two intended sites (`index.ts`'s `SHARED_SESSION_MULTIPLIER`, the new migration's `v_multiplier`), each cross-referencing the other in comments; the pre-existing `index_test.ts` literal is a test assertion, not a third definition site.
- All 4 acceptance criteria satisfied: AC1 (sweep scores active-only, skips null rows) and AC2 (grace-window/already-scored/all-null handling) verified via Task 2 trace scenarios 2.1/2.2/2.3/2.4; AC3 (mutual exclusion with client path) verified via trace scenario 2.5; AC4 (zero regressions + kill-switch documentation) verified via Task 3.

### File List

- `supabase/migrations/0014_shared_session_scoring_sweep.sql` (new)

## Change Log

- 2026-07-04: Story 21.4 implemented — added `supabase/migrations/0014_shared_session_scoring_sweep.sql` (pg_cron-scheduled `sweep_unscored_shared_sessions()` function). No Dart changes. All 4 ACs verified via manual SQL trace (AC1–AC3) and `flutter analyze`/`flutter test` zero-regression check (AC4). Status moved to review.
