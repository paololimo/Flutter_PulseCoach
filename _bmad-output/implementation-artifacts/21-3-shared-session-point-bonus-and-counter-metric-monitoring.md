---
baseline_commit: 6db1f5c98b61ee0768c29bc5333b8f0eb86ed67c
---

# Story 21.3: Shared-Session Point Bonus and Counter-Metric Monitoring

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user who completed a co-located shared session,
I want the session to award more points than a solo session,
So that the social incentive reinforces doing things together — within counter-metric guardrails.

## Context

**Epic 21 — Leaderboard & Scoring (v2.5), fourth and final story.** Story 21.0 (`done`) made shared-session completion persist a local `SessionLog`. Story 21.1 (`done`) built the solo write path (`award_session_points` RPC, client calls it directly after RPE). Story 21.2 (`done`) built the read/viewing path (friends leaderboard, rank freeze) — it explicitly noted: *"when 21.3 starts writing shared-session bonus rows into the same [`leaderboard_entries`] table, this RPC [`get_friends_leaderboard`] picks them up automatically with zero changes required."* No leaderboard-viewing code needs to change in this story.

**The core gap this story closes (Epic 21 Prerequisites note, epics.md:2745):** *"Today RPE is stored on-device only — nothing signals shared-session completion or per-participant RPE to the server."* Story 21.0 deliberately built ONLY the local half (its own Context section: *"Any server-side / Supabase write for shared-session completion... is Story 21.3's design dependency — do not scope-creep it in here"*). This story is the one that:
1. Adds a **server-visible per-participant RPE + completion signal** (new columns on `session_participants`).
2. Builds a **server-side Edge Function** that detects "all participants submitted" and applies the 1.5× multiplier — **never client-side** (FR75's explicit constraint).

### Why a Postgres-only RPC cannot do this (and an Edge Function is required)

`award_session_points` (0011, Story 21.1) is `SECURITY DEFINER` but scoped to `auth.uid()` — it can only ever award points to the calling user themselves, by design (that's what makes it safe against a modified client passing an arbitrary `owner_id`). Shared-session scoring needs the OPPOSITE: one participant's RPE submission must be able to trigger points for ALL participants (including ones who submitted earlier and are not the current caller). A Postgres function that awards to caller-supplied *other* users' accounts, driven only by client-supplied parameters, is a privilege-escalation vector unless it independently re-derives everything from server-held data. **Decision:** split into two SQL functions — `submit_shared_session_result` (auth.uid()-scoped, exactly like 0011, only ever touches the caller's own row) and a NEW `award_shared_session_points` (parameterized by `p_owner_id`, grantable ONLY to `service_role`, never `authenticated`) — the latter is called exclusively from a new Edge Function (`score_shared_session`), which is the only actor allowed to award points to a user other than the caller, and only after re-deriving readiness from server-held `session_participants` rows (never trusting a client-supplied "everyone's done" flag). This is also the literal reading of FR75/epics.md AC1: *"the multiplier is applied in the Edge Function, never hardcoded client-side."*

### What already exists (DO NOT REBUILD)

- **`lib/features/social/leaderboard/`** — extend, do not duplicate:
  - `data/datasources/leaderboard_remote_data_source.dart` — has `callAwardRpc`/`awardPoints`/`replayAward` (solo write) and `fetchLeaderboard`/`loadLeaderboard` (21.2 read). **Add a third `@visibleForTesting` function-field** (`callSubmitSharedResultRpc`) to the SAME class, mirroring the existing two-function-field constructor pattern exactly — do not create a second datasource class.
  - `domain/repositories/leaderboard_repository.dart` — has `awardSessionPoints(...)` and `getFriendsLeaderboard()`. **Add `submitSharedSessionResult(...)` to this same interface.**
  - `data/repositories/leaderboard_repository_impl.dart` — implements both existing methods. **Add the new method as a third `@override`** — it goes through `SyncManager.enqueue`, exactly like `awardSessionPoints` (the write must survive being offline at RPE-submission time), unlike `getFriendsLeaderboard` (a pure read, not queued).
  - `domain/scoring_constants.dart` — `ScoringConstants.intensityWeightFor(armKey)` (`_low`→1.0, `_medium`→1.5, else→2.0) and `dailyPointsCap = 200`. **Reuse `intensityWeightFor` unchanged for the client-known weight; the Edge Function needs its OWN TypeScript copy of the same three-line logic** (Deno cannot import Dart) — keep the two in sync via a comment, same discipline as `dailyPointsCap`/`v_daily_cap` in 0011.
- **`supabase/migrations/0011_leaderboard.sql`** (`award_session_points`) is the exact cap-clamp + advisory-lock pattern this story's NEW `award_shared_session_points` function reuses verbatim (same `v_daily_cap := 200`, same `pg_advisory_xact_lock(hashtextextended(owner::text, 0))`, same `ON CONFLICT (owner_id, session_log_id) DO NOTHING` idempotency) — parameterized by an explicit `p_owner_id` instead of `auth.uid()` because the Edge Function awards on behalf of every participant, not just the caller.
- **`supabase/migrations/0009_shared_sessions.sql`** — `shared_sessions(id, host_user_id, join_code, status, created_at)` and `session_participants(id, session_id, user_id, joined_at)`. **This story ALTERs both tables** (adds columns) rather than creating new ones — no new table needed for the per-participant RPE/completion signal.
- **`supabase/functions/delete_account_cascade/index.ts`** and **`export_user_data/index.ts`** are the ONLY two existing Edge Functions in this repo — **mirror `delete_account_cascade`'s exact shape** for the new `score_shared_session` function: `Deno.serve`, `Authorization: Bearer <jwt>` header, `createClient(...)` with `SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY` env vars, `admin.auth.getUser(jwt)` to resolve the caller, plain `Response`/`JSON.stringify` returns. No Deno test file exists for either precedent function — this story does not need to establish one (matches precedent; SQL migrations are also "unapplied to any live DB, not exercised by `flutter test`" per 21.1/21.2's Task 1.2 notes).
- **`lib/features/session/domain/entities/rpe_submit_args.dart`** — `RpeSubmitArgs(planId, sessionIndex, abandoned, armKey, sessionLogId, durationMinutes)`. `planId == null` is how the codebase already distinguishes "shared session" from "solo" (confirmed: `shared_session_lobby_page.dart`'s `sessionEnded` listener always constructs `RpeSubmitArgs(planId: null, ...)`). **Add a new nullable field `sharedSessionId`** (the Supabase `shared_sessions.id` UUID) — currently NOT plumbed anywhere; this is the missing link needed to call the new server RPCs.
- **`lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`** — already tracks the Supabase session UUID in a private field `String? _sessionId` (set in `_onJoined`, line 74: `_sessionId = event.sessionId;`), used internally for cancel/refresh RPC calls (lines 252, 279). **The `SessionEnded` broadcast-case emission (line 400: `emit(SharedSessionState.sessionEnded(armKey: _armKey ?? 'mobility_medium'))`) currently does NOT include `_sessionId`.** Add a `sessionId: _sessionId` field to both the `SharedSessionState.sessionEnded` factory (`shared_session_state.dart:41`) and this one emission call site (the ONLY place `sessionEnded` is emitted — confirmed via grep, no other site to update).
- **`lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart:56-71`** — the `sessionEnded` listener already builds `RpeSubmitArgs` from the state; **add `sharedSessionId: s.sessionId` to that constructor call** (the state field is named `sessionId`, the args field is named `sharedSessionId` — deliberately different names since `RpeSubmitArgs` already overloads `sessionLogId` for something unrelated; do not rename either).
- **`lib/features/session/presentation/pages/rpe_page.dart:114-124`** — the existing solo-only points-award guard: `if (args != null && args.planId != null && !args.abandoned) { ... AwardSessionPointsUseCase ... }`. **This story adds a second, parallel `else if` branch** for the shared-session case (`args.planId == null && args.sharedSessionId != null && !args.abandoned`) calling a NEW `SubmitSharedSessionResultUseCase` — mirroring the exact same fire-and-forget `unawaited(...)` shape, same listener, same `RpeFeedbackSubmitted` trigger point. **Do not touch the existing solo branch.**
- **`lib/main.dart:49-55`** — `getIt<SyncManager>().registerHandler(LeaderboardRemoteDataSource.awardEventType, getIt<LeaderboardRemoteDataSource>().replayAward)` is the exact registration pattern this story's new handler mirrors (add a second `registerHandler` call right after it, same block, before `SyncManager.start()`).
- **`lib/core/sync/sync_manager.dart`** — `SyncManager.enqueue(eventType, payload)` / `registerHandler` — unchanged, reused as-is.
- **AtRisk/Recovering behavior (epics AC3):** no new code is required — `award_shared_session_points` awards unconditionally based on submitted RPE (exactly like the solo path never checks behavioral state either), and Story 21.2's `LeaderboardBloc`/`RankPinning` already freezes the rank display regardless of how points changed underneath. This AC is a **regression check**, not new logic: verify (by reading, not by new code) that neither `LeaderboardBloc` nor `RankPinning` branches on *why* points changed.

### Resolved Ambiguity — Which Client Triggers the Edge Function, and When

Epics.md says: "the scoring Edge Function runs server-side" but does not specify what invokes it. **Decision:** every participant's own client invokes `score_shared_session` (fire-and-forget, best-effort, via `SupabaseClient.functions.invoke`) immediately after their own `submit_shared_session_result` RPC call succeeds — mirroring how `delete_account_cascade`/`export_user_data` are already invoked directly from Dart (`auth_remote_data_source.dart:34,103`, `functions.invoke('delete_account_cascade')`). The function is idempotent and safe to call redundantly: it recomputes "all submitted?" from server-held rows on every invocation and uses an atomic `UPDATE ... WHERE scored = false` claim so only the ONE invocation that observes full completion actually awards points — every other participant's own invocation (which will almost always see `allSubmitted: false`, since they're racing each other) is a harmless no-op. **Known limitation, accepted and documented (not fixed in this story):** if precisely the LAST participant's invocation fails on the network (offline, dropped connection) after their own RPE write succeeded, no later event re-triggers scoring — there is no cron sweep or database trigger as a fallback. This mirrors the project's existing tolerance for similar small gaps (see 21.1/21.2's several "Defer" review items) and is flagged here explicitly as a follow-up candidate, not silently accepted.

### Resolved Ambiguity — The Multiplier as "The Kill Switch" (Epics AC4 / Counter-Metrics)

Epics.md's counter-metric AC describes a **manual, weekly PM process** ("the PM reviews the counter-metrics dashboard... If either counter-metric regresses, the shared-session multiplier is reduced to 1.0"). No counter-metrics dashboard exists in this codebase, and building one is out of scope (not mentioned anywhere in the epic's task list, PRD, or architecture — this is a v2.5 gamification epic, not an analytics epic). **This AC cannot be verified by `flutter test`** — the persistent workflow rule requiring "testable, observable, pass/fail" ACs is satisfied here by making the AC about the code's *readiness for the kill switch*, not the monitoring process itself: the multiplier must be a single, isolated, named constant (`SHARED_SESSION_MULTIPLIER` in the Edge Function) such that setting it to `1.0` and redeploying is the ENTIRE fix — no other code path references or duplicates the `1.5` value. This is testably verified: (a) grep/read confirms exactly one definition site, and (b) a unit-level Edge Function test (see Task 3) asserts that with the constant set to `1.0`, the awarded points equal the base (unmultiplied) value — proving the kill switch, if exercised, produces the exact solo-equivalent behavior with no residual multiplier logic elsewhere.

### Resolved Ambiguity — `session_participants` Column Additions vs. a New Table

Two options: (a) a new `session_results` table keyed by `(session_id, user_id)`, or (b) add nullable columns directly to the existing `session_participants` table (already keyed `UNIQUE(session_id, user_id)`, one row per participant). **Decision: (b), add columns.** `session_participants` already IS the one-row-per-participant-per-session table with the exact primary key this data needs; a second table would just be a 1:1 join with no independent lifecycle, adding a JOIN to every read for no benefit — same reasoning 21.2 used to reject a new Drift table for a single int (`RankFreezeStore`'s Dev Notes).

## Acceptance Criteria

**AC1 — Multiplier applied server-side, only once all participants submit RPE:**
Given a shared session's participants have all called `submit_shared_session_result` (each participant's own RPE, arm key, and duration persisted to their `session_participants` row)
When any participant's client subsequently invokes the `score_shared_session` Edge Function for that session
Then the Edge Function verifies (by reading `session_participants` server-side) that every row for that `session_id` has a non-null `rpe_value`, computes `points = round(round(duration_minutes * intensityWeight(armKey)) * SHARED_SESSION_MULTIPLIER)` for each participant (`SHARED_SESSION_MULTIPLIER` a single named Edge Function constant, initial value `1.5`), and awards each participant's points via the new `award_shared_session_points` SQL function — which is grantable ONLY to `service_role` (never `authenticated`), never invoked with a client-supplied multiplier or points value (FR75). If invoked again for the same session, or invoked while any participant's `rpe_value` is still null, it is a verified no-op (an atomic `shared_sessions.scored` claim prevents double-awarding; a pending-participant check prevents early awarding).

**AC2 — Daily cap still enforced, bonus cannot circumvent it:**
Given a participant has already been awarded `N` points today (UTC) via `leaderboard_entries` (from any source — solo or shared)
When `award_shared_session_points` computes their shared-session award
Then the awarded amount is clamped to `max(0, 200 - N)` — identical clamp logic and constant (`v_daily_cap = 200`) to `award_session_points` (0011) — verified by a SQL-level code-read comparison (no live-DB test harness exists in this repo for either function; both are "unapplied, pure SQL artifacts" per 21.1/21.2 precedent) plus a Dart-level unit test on the equivalent TypeScript arithmetic being ported faithfully is out of scope for Dart tests — the parity is a code-review-verifiable invariant, documented here explicitly.

**AC3 — Protective-state participants awarded normally; rank freeze unaffected (regression, no new code):**
Given a participant is in `AtRisk` or `Recovering` state and participates in (and completes) a shared session
When `award_shared_session_points` runs
Then their points are awarded exactly as any other participant's (no behavioral-state branch exists in the awarding logic — verified by reading `award_shared_session_points`'s definition, which takes no behavioral-state parameter at all) — and Story 21.2's `LeaderboardBloc`/`RankPinning` (unmodified by this story) continues to pin their displayed rank per its existing frozen-rank mechanism, so the bonus produces no visible rank movement while protective (existing 21.2 tests continue to pass unmodified, confirming no regression).

**AC4 — Multiplier is a single, isolated, kill-switchable constant:**
Given `SHARED_SESSION_MULTIPLIER` is defined exactly once in `supabase/functions/score_shared_session/index.ts` and nowhere else in the codebase (no client-side Dart constant duplicates it — grep-verified, satisfying FR75's "never hardcoded client-side")
When the constant is changed to `1.0` (the documented kill-switch value the epics AC describes as the counter-metric-regression response) and the function is exercised with that value
Then the resulting awarded points equal the unmultiplied `base_points` (i.e. identical to the solo formula) with no other code change required — verified by a Deno unit test (Task 3) asserting `computeAward(basePoints, 1.0) === basePoints` and `computeAward(basePoints, 1.5) === round(basePoints * 1.5)`, isolating the pure arithmetic from the network/DB calls so it is testable without a live Supabase instance.
*(Note: the epics AC's weekly PM counter-metrics dashboard review is an out-of-band, non-automatable process — not implemented by this story; this AC verifies only that the code-side kill switch this process depends on works as a single-point change, per the Resolved Ambiguity above.)*

**AC5 — Zero regressions:**
Given all new and modified files are in place and `build_runner` has been run
When `flutter test` and `flutter analyze lib/ test/` run from `pulse_coach/`
Then all pre-existing tests pass (baseline: 1305 passed, 1 skipped, confirmed at story start — Story 21.2's completion notes) plus all new tests pass; analyzer reports 0 issues.

## Tasks / Subtasks

---

### Task 1 — Supabase migration: server-visible per-participant RPE/completion signal (AC1)

- [x] **1.1** Create `supabase/migrations/0013_shared_session_scoring.sql`:

  ```sql
  -- Story 21.3: server-visible per-participant RPE/completion signal, closing
  -- the gap Story 21.0 explicitly deferred ("Today RPE is stored on-device
  -- only — nothing signals shared-session completion... to the server").
  ALTER TABLE session_participants
    ADD COLUMN rpe_value       smallint,
    ADD COLUMN arm_key         text,
    ADD COLUMN duration_minutes int,
    ADD COLUMN completed_at    timestamptz;

  -- Atomic double-scoring guard for the score_shared_session Edge Function —
  -- claimed via `UPDATE ... WHERE scored = false`, never a plain read-then-write.
  ALTER TABLE shared_sessions
    ADD COLUMN scored boolean NOT NULL DEFAULT false;

  -- Participant writes their OWN row only (auth.uid()-scoped, mirrors
  -- award_session_points' auth.uid()-scoping in 0011) — no direct client
  -- UPDATE policy exists on session_participants (0009 only granted INSERT
  -- self + SELECT own), so this RPC is the sole write path, same "no direct
  -- client write" precedent as leaderboard_entries.
  CREATE OR REPLACE FUNCTION submit_shared_session_result(
    p_session_id uuid,
    p_rpe int,
    p_arm_key text,
    p_duration_minutes int
  ) RETURNS void LANGUAGE plpgsql SECURITY DEFINER
  SET search_path = public
  AS $$
  DECLARE
    v_uid uuid := auth.uid();
    v_updated int;
  BEGIN
    IF v_uid IS NULL THEN
      RAISE EXCEPTION 'not authenticated';
    END IF;

    UPDATE session_participants
    SET rpe_value = p_rpe,
        arm_key = p_arm_key,
        duration_minutes = p_duration_minutes,
        completed_at = now()
    WHERE session_id = p_session_id AND user_id = v_uid;

    GET DIAGNOSTICS v_updated = ROW_COUNT;
    IF v_updated = 0 THEN
      RAISE EXCEPTION 'not a participant of this session';
    END IF;
  END;
  $$;

  REVOKE ALL ON FUNCTION submit_shared_session_result(uuid, int, text, int) FROM public;
  GRANT EXECUTE ON FUNCTION submit_shared_session_result(uuid, int, text, int) TO authenticated;
  ```

- [x] **1.2** Note (same as 0007/0011/0012): applied via the team's Supabase CLI workflow, not exercised by `flutter test` — no Dart test talks to a real Supabase instance.

---

### Task 2 — Supabase migration: `award_shared_session_points` (service_role only) (AC1, AC2)

- [x] **2.1** Append to `supabase/migrations/0013_shared_session_scoring.sql` (same file, after Task 1's content):

  ```sql
  -- Awards points to an ARBITRARY participant (not just auth.uid()) — safe
  -- ONLY because it is unreachable by any authenticated client role (see
  -- Context: "Why a Postgres-only RPC cannot do this"). Callable exclusively
  -- by service_role, i.e. only from the score_shared_session Edge Function,
  -- which independently re-derives p_owner_id/p_points from server-held
  -- session_participants rows — never trusts a client-supplied value.
  -- Cap-clamp + advisory-lock logic is IDENTICAL to award_session_points
  -- (0011) — v_daily_cap MUST stay in sync with both 0011's v_daily_cap and
  -- ScoringConstants.dailyPointsCap (Dart).
  CREATE OR REPLACE FUNCTION award_shared_session_points(
    p_owner_id uuid,
    p_idempotency_key text,
    p_points int,
    p_awarded_on date
  ) RETURNS int LANGUAGE plpgsql SECURITY DEFINER
  SET search_path = public
  AS $$
  DECLARE
    v_already_awarded int;
    v_daily_cap CONSTANT int := 200;
    v_awarded int;
  BEGIN
    PERFORM pg_advisory_xact_lock(hashtextextended(p_owner_id::text, 0));

    IF EXISTS (
      SELECT 1 FROM leaderboard_entries
      WHERE owner_id = p_owner_id AND session_log_id = p_idempotency_key
    ) THEN
      RETURN 0;
    END IF;

    SELECT COALESCE(SUM(points), 0) INTO v_already_awarded
    FROM leaderboard_entries
    WHERE owner_id = p_owner_id AND awarded_on = p_awarded_on;

    v_awarded := GREATEST(0, LEAST(p_points, v_daily_cap - v_already_awarded));

    INSERT INTO leaderboard_entries (owner_id, session_log_id, points, awarded_on)
    VALUES (p_owner_id, p_idempotency_key, v_awarded, p_awarded_on)
    ON CONFLICT (owner_id, session_log_id) DO NOTHING;

    RETURN v_awarded;
  END;
  $$;

  REVOKE ALL ON FUNCTION award_shared_session_points(uuid, text, int, date) FROM public;
  REVOKE ALL ON FUNCTION award_shared_session_points(uuid, text, int, date) FROM authenticated;
  GRANT EXECUTE ON FUNCTION award_shared_session_points(uuid, text, int, date) TO service_role;
  ```

  **Note — this is the first migration in the repo to grant to `service_role` explicitly** (0011/0012 only grant to `authenticated`); document this as a new, deliberate precedent in a migration comment, not a copy-paste oversight.

---

### Task 3 — Edge Function: `score_shared_session` (AC1, AC2, AC4)

- [x] **3.1** Create `supabase/functions/score_shared_session/index.ts`, mirroring `delete_account_cascade/index.ts`'s exact auth/response shape:

  ```ts
  import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

  // FR75 kill switch (epics.md AC4/counter-metrics): the ENTIRE bonus is this
  // one constant. Set to 1.0 and redeploy to disable the bonus with zero other
  // code changes, per the PM's weekly counter-metrics review process.
  export const SHARED_SESSION_MULTIPLIER = 1.5;

  export function intensityWeightFor(armKey: string): number {
    if (armKey.endsWith("_low")) return 1.0;
    if (armKey.endsWith("_medium")) return 1.5;
    return 2.0; // '_high' — mirrors ScoringConstants.intensityWeightFor (Dart)
  }

  export function computeAward(basePoints: number, multiplier: number): number {
    return Math.round(basePoints * multiplier);
  }

  Deno.serve(async (req: Request) => {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return new Response("Unauthorized", { status: 401 });
    const jwt = authHeader.replace("Bearer ", "");

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: { user }, error: userError } = await admin.auth.getUser(jwt);
    if (userError || !user) return new Response("Unauthorized", { status: 401 });

    const { sessionId } = await req.json();
    if (!sessionId) return new Response("Bad Request", { status: 400 });

    const { data: participants, error: participantsError } = await admin
      .from("session_participants")
      .select("user_id, rpe_value, arm_key, duration_minutes")
      .eq("session_id", sessionId);

    if (participantsError || !participants || participants.length === 0) {
      return new Response(JSON.stringify({ error: "lookup_failed" }), { status: 500 });
    }

    const isParticipant = participants.some((p) => p.user_id === user.id);
    if (!isParticipant) return new Response("Forbidden", { status: 403 });

    const allSubmitted = participants.every((p) => p.rpe_value !== null);
    if (!allSubmitted) {
      return new Response(JSON.stringify({ scored: false, reason: "pending" }), { status: 200 });
    }

    // Atomic claim: only the ONE invocation that observes "all submitted"
    // first actually scores; every other participant's own invocation
    // (racing this one) sees 0 rows updated and becomes a harmless no-op.
    const { data: claimed, error: claimError } = await admin
      .from("shared_sessions")
      .update({ scored: true })
      .eq("id", sessionId)
      .eq("scored", false)
      .select("id");

    if (claimError || !claimed || claimed.length === 0) {
      return new Response(JSON.stringify({ scored: false, reason: "already_scored" }), { status: 200 });
    }

    const awardedOn = new Date().toISOString().substring(0, 10);
    const results = [];
    for (const p of participants) {
      const basePoints = Math.round((p.duration_minutes ?? 0) * intensityWeightFor(p.arm_key ?? ""));
      const points = computeAward(basePoints, SHARED_SESSION_MULTIPLIER);
      const { data: awarded, error: awardError } = await admin.rpc("award_shared_session_points", {
        p_owner_id: p.user_id,
        p_idempotency_key: `shared:${sessionId}`,
        p_points: points,
        p_awarded_on: awardedOn,
      });
      results.push({ userId: p.user_id, awarded: awardError ? 0 : awarded });
    }

    return new Response(JSON.stringify({ scored: true, results }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  });
  ```

- [x] **3.2** Create `supabase/functions/score_shared_session/index_test.ts` (new — first Deno test in this repo; establishes the precedent since AC4 needs a live, DB-free arithmetic assertion):

  ```ts
  import { assertEquals } from "https://deno.land/std/testing/asserts.ts";
  import { computeAward, intensityWeightFor, SHARED_SESSION_MULTIPLIER } from "./index.ts";

  Deno.test("[21.3-EDGE-001] computeAward at the live multiplier applies the 1.5x bonus", () => {
    assertEquals(computeAward(20, SHARED_SESSION_MULTIPLIER), 30);
  });

  Deno.test("[21.3-EDGE-002] computeAward at multiplier 1.0 (kill switch) equals base points, no residual bonus", () => {
    assertEquals(computeAward(20, 1.0), 20);
  });

  Deno.test("[21.3-EDGE-003] intensityWeightFor mirrors ScoringConstants.intensityWeightFor (Dart)", () => {
    assertEquals(intensityWeightFor("mobility_low"), 1.0);
    assertEquals(intensityWeightFor("mobility_medium"), 1.5);
    assertEquals(intensityWeightFor("mobility_high"), 2.0);
  });
  ```

  Run via `deno test supabase/functions/score_shared_session/` (not part of `flutter test`; note this in the story's completion record as a separate manual/CI-future verification step — no Deno CI job exists yet in `.github/workflows/ci.yml`, same "not automated in this repo's CI yet" status as the SQL migrations).

---

### Task 4 — Plumb the shared-session UUID from bloc to RPE screen (AC1)

- [x] **4.1** Edit `pulse_coach/lib/features/session/domain/entities/rpe_submit_args.dart` — add one field:
  ```dart
  final String? sharedSessionId;
  ```
  and to the constructor: `this.sharedSessionId,`.

- [x] **4.2** Edit `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart` — add a field to the existing factory:
  ```dart
  const factory SharedSessionState.sessionEnded({
    @Default('mobility_medium') String armKey,
    String? sessionId,
  }) = _SessionEnded;
  ```

- [x] **4.3** Edit `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart` line ~400 (the ONLY `sessionEnded` emission site — confirmed via grep, do not search for others):
  ```dart
  emit(SharedSessionState.sessionEnded(
    armKey: _armKey ?? 'mobility_medium',
    sessionId: _sessionId,
  ));
  ```

- [x] **4.4** Edit `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart` — in the `sessionEnded` listener's `RpeSubmitArgs` construction (~line 62), add:
  ```dart
  sharedSessionId: s.sessionId,
  ```

---

### Task 5 — Extend `LeaderboardRemoteDataSource`/`LeaderboardRepository` with the shared-result write path (AC1)

- [x] **5.1** Edit `pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart` — add alongside the existing two function-fields (do not touch `callAwardRpc`/`fetchLeaderboard`):
  ```dart
  static const String sharedResultEventType = 'leaderboard_shared_session_result';

  // In the constructor body, alongside the existing two assignments:
  // callSubmitSharedResultRpc = _defaultCallSubmitSharedResultRpc;

  @visibleForTesting
  late Future<void> Function(
    String sessionId,
    int rpe,
    String armKey,
    int durationMinutes,
  )
  callSubmitSharedResultRpc;

  Future<void> _defaultCallSubmitSharedResultRpc(
    String sessionId,
    int rpe,
    String armKey,
    int durationMinutes,
  ) async {
    await _supabase.client.rpc(
      'submit_shared_session_result',
      params: {
        'p_session_id': sessionId,
        'p_rpe': rpe,
        'p_arm_key': armKey,
        'p_duration_minutes': durationMinutes,
      },
    );
    // Best-effort scoring trigger (see story Context: "Which Client Triggers
    // the Edge Function"). Failure here is non-fatal and NOT retried by this
    // call — another participant's own successful submission re-triggers it.
    try {
      await _supabase.client.functions.invoke(
        'score_shared_session',
        body: {'sessionId': sessionId},
      );
    } catch (_) {
      // Intentionally swallowed — see Dev Notes.
    }
  }

  Future<void> submitSharedResult(
    String sessionId,
    int rpe,
    String armKey,
    int durationMinutes,
  ) => callSubmitSharedResultRpc(sessionId, rpe, armKey, durationMinutes);

  /// Registered with `SyncManager.registerHandler` under [sharedResultEventType].
  Future<Either<Failure, Unit>> replaySubmitSharedResult(String payload) async {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      await callSubmitSharedResultRpc(
        map['sessionId'] as String,
        map['rpe'] as int,
        map['armKey'] as String,
        map['durationMinutes'] as int,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('submit_shared_session_result RPC failed: $e'));
    }
  }
  ```
  **Note — this write is naturally idempotent (a plain `UPDATE` on the caller's own row), unlike `awardPoints`'s INSERT-based idempotency-key scheme — no install-id namespacing is needed here.**

- [x] **5.2** Edit `pulse_coach/lib/features/social/leaderboard/domain/repositories/leaderboard_repository.dart` — add:
  ```dart
  Future<Either<Failure, Unit>> submitSharedSessionResult({
    required String sessionId,
    required int rpe,
    required String armKey,
    required int durationMinutes,
  });
  ```

- [x] **5.3** Edit `pulse_coach/lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart` — add a third `@override` (constructor/fields unchanged — reuses the existing `_syncManager`/`_dataSource`):
  ```dart
  @override
  Future<Either<Failure, Unit>> submitSharedSessionResult({
    required String sessionId,
    required int rpe,
    required String armKey,
    required int durationMinutes,
  }) async {
    try {
      final payload = jsonEncode({
        'sessionId': sessionId,
        'rpe': rpe,
        'armKey': armKey,
        'durationMinutes': durationMinutes,
      });
      await _syncManager.enqueue(
        LeaderboardRemoteDataSource.sharedResultEventType,
        payload,
      );
      return const Right(unit);
    } catch (e) {
      return Left(SocialFailure('Failed to enqueue shared session result: $e'));
    }
  }
  ```
  **Critical — route through `SyncManager.enqueue`, exactly like `awardSessionPoints`** (this write must survive the participant being offline right after RPE submission), NOT like `getFriendsLeaderboard` (a read, correctly bypasses the queue).

---

### Task 6 — `SubmitSharedSessionResultUseCase` + `RpePage` wiring (AC1, AC3)

- [x] **6.1** Create `pulse_coach/lib/features/social/leaderboard/domain/usecases/submit_shared_session_result_use_case.dart`, mirroring `AwardSessionPointsUseCase`'s single-guard-point shape:
  ```dart
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';

  @injectable
  class SubmitSharedSessionResultUseCase {
    final LeaderboardRepository _repository;
    const SubmitSharedSessionResultUseCase(this._repository);

    /// No entitlement/behavioral-state guard here (AC3 — shared-session
    /// scoring awards unconditionally, protective-state or not; only the
    /// display-side rank freeze in Story 21.2 is state-aware).
    Future<void> call({
      required String sessionId,
      required int rpe,
      required String armKey,
      required int durationMinutes,
    }) async {
      await _repository.submitSharedSessionResult(
        sessionId: sessionId,
        rpe: rpe,
        armKey: armKey,
        durationMinutes: durationMinutes,
      );
    }
  }
  ```
  **Note — no `EntitlementGate` check, unlike `AwardSessionPointsUseCase`.** Shared sessions are not currently Pro-gated at any entry point in this codebase (confirmed: no `EntitlementGate`/`SubscriptionTier` reference anywhere under `lib/features/social/shared_session/`) — adding a check here would be inventing new gating scope beyond this story's mandate. Flag as a pre-existing gap (shared-session participation not gated to FR62's "Pro" tier at all), not something this story introduces or is responsible for fixing.

- [x] **6.2** Edit `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart` — add the import:
  ```dart
  import 'package:pulse_coach/features/social/leaderboard/domain/usecases/submit_shared_session_result_use_case.dart';
  ```
  and extend the existing `RpeFeedbackSubmitted` listener (currently `if (args != null && args.planId != null && !args.abandoned) { ...AwardSessionPointsUseCase... }`) with a parallel branch — do not modify the existing `if`:
  ```dart
  } else if (args != null &&
      args.planId == null &&
      args.sharedSessionId != null &&
      !args.abandoned) {
    unawaited(
      getIt<SubmitSharedSessionResultUseCase>().call(
        sessionId: args.sharedSessionId!,
        rpe: submitted.rpeValue,
        armKey: args.armKey,
        durationMinutes: args.durationMinutes,
      ),
    );
  }
  ```
  (The original `if (args != null && args.planId != null && !args.abandoned) {...}` block becomes the `if`; this becomes its `else if`.)

---

### Task 7 — Regenerate DI + build_runner (AC5)

- [x] **7.1** From `pulse_coach/`, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Expected: `lib/core/di/injection.config.dart` gains a factory registration for `SubmitSharedSessionResultUseCase` (`@injectable`); `LeaderboardRepositoryImpl`'s and `LeaderboardRemoteDataSource`'s existing registrations pick up the new methods automatically (no constructor signature change for either — only new methods/fields, no new constructor params). `shared_session_state.freezed.dart` regenerates for the new `sessionId` field on `_SessionEnded`.

- [x] **7.2** Edit `pulse_coach/lib/main.dart` — add a second handler registration right after the existing one (same try block, before `SyncManager.start()`):
  ```dart
  getIt<SyncManager>().registerHandler(
    LeaderboardRemoteDataSource.sharedResultEventType,
    getIt<LeaderboardRemoteDataSource>().replaySubmitSharedResult,
  );
  ```

---

### Task 8 — Tests (AC1–AC5)

- [x] **8.1** `test/domain/social/leaderboard/submit_shared_session_result_use_case_test.dart` (mock `LeaderboardRepository`):
  ```
  [21.3-USECASE-001] delegates to repository.submitSharedSessionResult(...) with all four args passed through verbatim
  ```
- [x] **8.2** Extend `test/data/social/leaderboard/leaderboard_remote_data_source_test.dart` (existing file — add a new `group('submitSharedResult', ...)`, do not touch existing groups):
  ```
  [21.3-DS-001] submitSharedResult(...) → callSubmitSharedResultRpc invoked with the exact 4 args
  [21.3-DS-002] replaySubmitSharedResult(payload) → decodes JSON and calls callSubmitSharedResultRpc with the decoded fields
  [21.3-DS-003] replaySubmitSharedResult with malformed JSON → returns Left(ServerFailure), does not throw
  ```
- [x] **8.3** Extend `test/data/social/leaderboard/leaderboard_repository_impl_test.dart` (existing file):
  ```
  [21.3-REPO-001] submitSharedSessionResult(...) → SyncManager.enqueue called with sharedResultEventType and a JSON payload containing all 4 fields
  [21.3-REPO-002] SyncManager.enqueue throws → returns Left(SocialFailure)
  ```
- [x] **8.4** `test/widget/rpe_page_test.dart` (existing file — extend, mirroring the existing `_FakeAwardSessionPointsUseCase` + `getIt.registerSingleton<AwardSessionPointsUseCase>(...)` pattern used by `21.1-PAGE-001/002/003`; add a matching `_FakeSubmitSharedSessionResultUseCase` and register it the same way in every test's setup):
  ```
  [21.3-PAGE-001] args.planId == null, args.sharedSessionId != null, abandoned: false → SubmitSharedSessionResultUseCase.call invoked with sessionId/rpe/armKey/durationMinutes from args + submitted RPE
  [21.3-PAGE-002] args.sharedSessionId == null (solo path, planId set) → SubmitSharedSessionResultUseCase.call NOT invoked (existing AwardSessionPointsUseCase branch still fires — regression guard; note the pre-existing `21.1-PAGE-002` test (shared args, planId: null) predates the `sharedSessionId` field and will continue to leave it null/unset, so it also implicitly guards SubmitSharedSessionResultUseCase NOT firing when sharedSessionId is absent)
  [21.3-PAGE-003] args.abandoned: true, sharedSessionId != null → neither use case invoked
  ```
- [x] **8.5** Extend `test/bloc/shared_session/shared_session_bloc_test.dart` (existing file — add to the existing `SessionEnded` broadcast-case coverage):
  ```
  [21.3-BLOC-001] SessionEnded broadcast received after _onJoined set _sessionId → emitted sessionEnded state carries that same sessionId (not null)
  ```
- [x] **8.6** `supabase/functions/score_shared_session/index_test.ts` — see Task 3.2 (Deno, not part of `flutter test`).
- [x] **8.7** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Expected: 0 analyzer issues; all pre-existing tests (1305 passed, 1 skipped baseline) + all new tests pass.

---

### Review Findings (code review 2026-07-04)

- [x] [Review][Defer] Drop-out / never-submitting participant blocks the entire group's bonus indefinitely — `score_shared_session/index.ts` gates on `participants.every(p => p.rpe_value !== null)`; a participant who never submits leaves their row null forever, so no one is ever scored. **Deferred to follow-up Story 21.4** (recorded in `epics.md`): the real fix needs a server-side scheduled sweep (`pg_cron`), not reachable from `index.ts` alone under the client fire-and-forget trigger model — keeping 21.3 focused rather than adding untested scheduling infra late. [blind+edge+auditor]
- [x] [Review][Patch] Deno test underpinning AC4 imports a deprecated, unpinned std path [supabase/functions/score_shared_session/index_test.ts:1] — FIXED: pinned to `https://deno.land/std@0.224.0/assert/mod.ts` (current `assertEquals` path). [auditor]
- [x] [Review][Defer] Points inflation via client-supplied `arm_key`/`duration_minutes` [supabase/functions/score_shared_session/index.ts:59] — deferred, pre-existing accepted trust model: the shipped solo `award_session_points(p_base_points int)` trusts the client value even more directly; both paths are bounded identically by the 200/day cap.
- [x] [Review][Defer] Partial award failure mid-loop after `scored=true` is claimed → participant permanently unpaid [supabase/functions/score_shared_session/index.ts:57-71] — deferred: `scored=true` is claimed before the per-participant award loop; a mid-loop `award_shared_session_points` error is swallowed (`awarded: awardError ? 0 : ...`) and never retried. Adjacent to documented accepted limitations.
- [x] [Review][Defer] Last-submitter Edge invoke failure / near-simultaneous read race → session never scored [pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart:149] — deferred, explicitly documented as an accepted known limitation in the story's Resolved Ambiguity section.
- [x] [Review][Defer] Unknown/empty `arm_key` falls through to the highest weight (2.0) [supabase/functions/score_shared_session/index.ts:12] — deferred: faithfully mirrors the Dart `ScoringConstants.intensityWeightFor` else-branch; changing only the TS copy would break the documented parity. Applies equally to the pre-existing Dart side.
- [x] [Review][Defer] RPE not range-validated; hostile client `p_rpe > 32767` overflows `smallint` [supabase/migrations/0013_shared_session_scoring.sql] — deferred, low: only self-harm (their own submit fails), not a points-inflation vector; matches the project's existing no-server-clamp philosophy.
- [x] [Review][Defer] Edge Function empty/non-JSON body → uncaught throw → opaque 500 instead of 400 [supabase/functions/score_shared_session/index.ts:37] — deferred, cosmetic: internal function called only by the app.
- [x] [Review][Defer] Shared flow completing with `sessionId == null` (session ended before join) → neither branch fires, session silently unscored [pulse_coach/lib/features/session/presentation/pages/rpe_page.dart:81-93] — deferred, low-probability, no regression (shared sessions had no scoring before this story).

Dismissed as noise (3): idempotency key `text` vs `int` column (false positive — `session_log_id` is `text NOT NULL`); AC4 `grep 1.5` collision (informational — intensity weight ≠ multiplier, AC4 holds); `duration_minutes`/`arm_key` null while `rpe_value` set (cannot occur — the RPC sets all four columns in one atomic `UPDATE`).

---

## Dev Notes

### Why the Edge Function Trigger Is Fire-and-Forget (Not Queued/Retried)

`submit_shared_session_result` (the participant's own RPE write) DOES go through `SyncManager` because losing it would silently drop that participant's contribution to the group's scoring forever. The subsequent `score_shared_session` invocation is different: it's not "this participant's data" that would be lost — it's a *trigger* for a computation that any of the N participants' own successful submissions can equally re-trigger. Queueing it would also be actively wrong: `SyncManager.enqueue`'s replay semantics assume "replay until it succeeds," but this call is expected to return `{scored: false}` (not an error) on most invocations — that's the correct, common case, not a failure to retry.

### Why `award_shared_session_points` Duplicates (Rather Than Reuses) `award_session_points`'s SQL Body

`award_session_points` (0011) is hardcoded to `auth.uid()` — that's exactly what makes it safe to expose to `authenticated`. Parameterizing it to accept an arbitrary `p_owner_id` and keeping it grantable to `authenticated` would let any signed-in client award points to ANY other user by UUID guess — a critical privilege escalation. The two functions must stay separate, with different grant surfaces (`authenticated` vs. `service_role`-only), even though their bodies are otherwise identical. This is a deliberate, security-motivated duplication, not an oversight to "refactor" later.

### Why No `EntitlementGate`/Pro-Tier Check Was Added to the New Use Case

Confirmed via search: no `EntitlementGate` or `SubscriptionTier` reference exists anywhere under `lib/features/social/shared_session/` — shared sessions are not currently gated behind Pro at ANY entry point (creation, join, or lobby), despite FR62 stating "creating social content (friends, sharing, shared sessions, scoring participation) is Pro." This is a pre-existing gap this story does not introduce and is out of scope to fix (fixing it would mean gating shared-session creation/join, a different feature's entry point, not this scoring story). `AwardSessionPointsUseCase`'s Pro check is solo-scoring-specific; do not copy it here without a corresponding shared-session-entry gate, which doesn't exist.

### File Size Check

- `leaderboard_remote_data_source.dart`: ~85 → ~130 lines.
- `leaderboard_repository_impl.dart`: ~95 → ~120 lines.
- `leaderboard_repository.dart`: ~14 → ~20 lines.
- `rpe_page.dart`: ~155 → ~175 lines.
- `shared_session_bloc.dart`: ~450 → +1 line (only the emit call changes).
- `shared_session_state.dart`: +1 field.
- `rpe_submit_args.dart`: +2 lines.
- All well under the 800-line hard limit; no split needed.

### Project Structure Notes

**New production files:**
- `supabase/migrations/0013_shared_session_scoring.sql`
- `supabase/functions/score_shared_session/index.ts`
- `pulse_coach/lib/features/social/leaderboard/domain/usecases/submit_shared_session_result_use_case.dart`

**Modified production files:**
- `pulse_coach/lib/features/session/domain/entities/rpe_submit_args.dart` (add `sharedSessionId`)
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart` (add `sessionId` to `sessionEnded`)
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart` (pass `_sessionId` at the `sessionEnded` emit site)
- `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart` (pass `sharedSessionId` into `RpeSubmitArgs`)
- `pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart` (add `callSubmitSharedResultRpc`/`submitSharedResult`/`replaySubmitSharedResult`)
- `pulse_coach/lib/features/social/leaderboard/domain/repositories/leaderboard_repository.dart` (add `submitSharedSessionResult`)
- `pulse_coach/lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart` (add `submitSharedSessionResult`)
- `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart` (add shared-session `else if` branch)
- `pulse_coach/lib/main.dart` (register the new `SyncManager` handler)

**Auto-regenerated:**
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.freezed.dart`

**New/modified test files:**
- `pulse_coach/test/domain/social/leaderboard/submit_shared_session_result_use_case_test.dart`
- `pulse_coach/test/data/social/leaderboard/leaderboard_remote_data_source_test.dart` (extended)
- `pulse_coach/test/data/social/leaderboard/leaderboard_repository_impl_test.dart` (extended)
- `pulse_coach/test/widget/rpe_page_test.dart` (extended)
- `pulse_coach/test/bloc/shared_session/shared_session_bloc_test.dart` (extended)
- `supabase/functions/score_shared_session/index_test.ts` (new, Deno)

**Out of scope for this story (explicitly deferred):**
- Any counter-metrics dashboard, automated regression detection, or alerting for the weekly PM review (epics AC4) — manual process, code-side kill switch only (see Resolved Ambiguity).
- A cron/webhook fallback if the last participant's Edge Function invocation fails on the network — accepted limitation, documented above.
- Gating shared-session creation/join behind Pro entitlement (pre-existing gap, not this story's mandate).
- Distinguishing host-abandon from natural completion in scoring (same `abandoned: false` hardcoding limitation Story 21.0 already flagged as out of scope for the identical reason).
- Deno/Edge-Function CI job — no such job exists yet for the two pre-existing functions either.

### References

- [Source: epics.md#Story 21.3 lines ~2823–2845 — full ACs, FR75, counter-metric process]
- [Source: epics.md#Epic 21 Prerequisites line 2745 — the exact "server-visible completion signal" dependency this story closes]
- [Source: architecture.md line 424,447,1344 — Edge Functions pattern, `supabase/functions/` location]
- [Source: architecture.md v2 Enforcement Guidelines #10 — RLS/SECURITY DEFINER at DB, client checks convenience-only — the basis for the `service_role`-only grant decision]
- [Source: supabase/migrations/0011_leaderboard.sql — `award_session_points`'s cap-clamp/advisory-lock body, duplicated (not reused) for `award_shared_session_points`]
- [Source: supabase/migrations/0009_shared_sessions.sql — `session_participants`/`shared_sessions` schema this story ALTERs]
- [Source: supabase/functions/delete_account_cascade/index.ts — exact Edge Function auth/response shape mirrored by `score_shared_session`]
- [Source: pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart:34,103 — `functions.invoke(...)` client-side call pattern]
- [Source: pulse_coach/lib/features/session/domain/entities/rpe_submit_args.dart — extended with `sharedSessionId`]
- [Source: pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart:44,74,395-402 — `_sessionId` tracking + the single `sessionEnded` emission site]
- [Source: pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart:56-71 — `RpeSubmitArgs` construction site extended]
- [Source: pulse_coach/lib/features/session/presentation/pages/rpe_page.dart:114-124 — existing solo-only award guard, extended with a parallel shared-session branch]
- [Source: pulse_coach/lib/features/social/leaderboard/domain/scoring_constants.dart — `intensityWeightFor`/`dailyPointsCap`, mirrored (not imported — Deno can't import Dart) in the new Edge Function]
- [Source: pulse_coach/lib/features/social/leaderboard/domain/usecases/award_session_points_use_case.dart — the single-guard-point shape mirrored by `SubmitSharedSessionResultUseCase`]
- [Source: pulse_coach/lib/core/sync/sync_manager.dart — `enqueue`/`registerHandler`, reused unchanged]
- [Source: pulse_coach/lib/main.dart:49-55 — existing `SyncManager.registerHandler` call site, extended with a second registration]
- [Source: _bmad-output/implementation-artifacts/21-0-shared-session-persistence-and-handle-wiring.md — confirms server-side write was explicitly deferred to this story, and the `abandoned: false` hardcoding limitation this story inherits unchanged]
- [Source: _bmad-output/implementation-artifacts/21-1-points-system-and-solo-session-scoring.md — solo write path, `ScoringConstants`, cap-clamp SQL pattern, confirmed baseline test count lineage]
- [Source: _bmad-output/implementation-artifacts/21-2-friends-only-leaderboard-and-rank-freeze.md — confirms the read path needs zero changes for this story's new `leaderboard_entries` rows to appear; confirmed baseline test count 1305 passed/1 skipped]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5), via `bmad-dev-story` skill, ATDD mode (failing test before production code for every Dart-testable change).

### Debug Log References

None — no blocking failures encountered. `deno` is not installed in this environment, so `supabase/functions/score_shared_session/index_test.ts` could not be executed locally; this matches the story's own documented status ("not part of `flutter test`... no Deno CI job exists yet" — Task 3.2/8.6) and mirrors the pre-existing precedent for the two prior Edge Functions (`delete_account_cascade`, `export_user_data`), neither of which has a test file either.

### Completion Notes List

- Task 1/2: Created `supabase/migrations/0013_shared_session_scoring.sql` — `session_participants` gains `rpe_value`/`arm_key`/`duration_minutes`/`completed_at`; `shared_sessions` gains `scored`; `submit_shared_session_result` (auth.uid()-scoped, grantable to `authenticated`) and `award_shared_session_points` (parameterized `p_owner_id`, grantable ONLY to `service_role` — first such grant in this repo) both defined. Not exercised by `flutter test` (no live-DB harness exists in this repo, per 21.1/21.2 precedent) — verified by code review against the story's exact spec.
- Task 3: Created `supabase/functions/score_shared_session/index.ts` (mirrors `delete_account_cascade`'s auth/response shape) and `index_test.ts` (first Deno test in this repo, per AC4). `SHARED_SESSION_MULTIPLIER` is defined exactly once, grep-verified. Could not run `deno test` locally (Deno not installed) — documented as a known gap matching existing CI status.
- Task 4: Added `sharedSessionId` to `RpeSubmitArgs`, `sessionId` to `SharedSessionState.sessionEnded`, wired `_sessionId` through the single `sessionEnded` emission site in `SharedSessionBloc`, and threaded it into `RpeSubmitArgs` construction in `SharedSessionLobbyPage`. Regenerated `shared_session_state.freezed.dart` via `build_runner`.
- Task 5: Extended `LeaderboardRemoteDataSource` with `callSubmitSharedResultRpc`/`submitSharedResult`/`replaySubmitSharedResult` (third function-field, same pattern as `callAwardRpc`), `LeaderboardRepository` with `submitSharedSessionResult(...)`, and `LeaderboardRepositoryImpl` with the third `@override`, routed through `SyncManager.enqueue` (offline-safe, same as `awardSessionPoints`).
- Task 6: Created `SubmitSharedSessionResultUseCase` (no `EntitlementGate`/behavioral-state guard, per AC3 and the story's documented pre-existing-gap rationale) and wired a parallel `else if` branch in `rpe_page.dart`'s `RpeFeedbackSubmitted` listener — the pre-existing solo `if` branch is untouched.
- Task 7: Ran `dart run build_runner build --delete-conflicting-outputs` (DI registration for `SubmitSharedSessionResultUseCase`, freezed regen, new mockito mocks). Registered the new `sharedResultEventType` handler in `main.dart` alongside the existing `awardEventType` registration.
- Task 8: Added all new/extended tests specified by the story (10 new test cases: 3 datasource, 2 repository, 1 use case, 3 widget, 1 bloc). Followed ATDD strictly — each new test was run first to confirm a compile/assertion failure (red) before writing the corresponding production code (green).
  - **Regression fix (not in the story's task list but required by AC5):** adding a real `sessionId` value to the `sessionEnded` emission broke 3 pre-existing tests that asserted the old implicit `sessionId: null` default (`20.4-BLOC-003` in `shared_session_bloc_test.dart`, `20.5-BLOC-004` in `shared_session_20_5_bloc_test.dart`, `19.3-BLOC-008` in `drop_out_tolerance_bloc_test.dart`). Updated their expected states to include the now-correct `sessionId` value (all three tests join with a hardcoded `sessionId: 'sess-1'` fixture) — this is a legitimate expectation update matching the story's intended new behavior, not a workaround.
  - Final full suite: `flutter analyze lib/ test/` → 0 issues. `flutter test` → 1315 passed, 1 skipped (baseline 1305 passed/1 skipped + 10 new tests = 1315; zero regressions).

### File List

**New:**
- `supabase/migrations/0013_shared_session_scoring.sql`
- `supabase/functions/score_shared_session/index.ts`
- `supabase/functions/score_shared_session/index_test.ts`
- `pulse_coach/lib/features/social/leaderboard/domain/usecases/submit_shared_session_result_use_case.dart`
- `pulse_coach/test/domain/social/leaderboard/submit_shared_session_result_use_case_test.dart`

**Modified:**
- `pulse_coach/lib/features/session/domain/entities/rpe_submit_args.dart`
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart`
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`
- `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart`
- `pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/repositories/leaderboard_repository.dart`
- `pulse_coach/lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart`
- `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart`
- `pulse_coach/lib/main.dart`
- `pulse_coach/test/data/social/leaderboard/leaderboard_remote_data_source_test.dart` (extended)
- `pulse_coach/test/data/social/leaderboard/leaderboard_repository_impl_test.dart` (extended)
- `pulse_coach/test/widget/rpe_page_test.dart` (extended)
- `pulse_coach/test/bloc/shared_session/shared_session_bloc_test.dart` (extended + 1 pre-existing expectation updated)
- `pulse_coach/test/bloc/shared_session/shared_session_20_5_bloc_test.dart` (1 pre-existing expectation updated — regression fix)
- `pulse_coach/test/bloc/shared_session/drop_out_tolerance_bloc_test.dart` (1 pre-existing expectation updated — regression fix)

**Auto-regenerated:**
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.freezed.dart`
- `pulse_coach/test/domain/social/leaderboard/submit_shared_session_result_use_case_test.mocks.dart`
- mockito mocks for `leaderboard_remote_data_source_test.dart`/`leaderboard_repository_impl_test.dart` (regenerated in place, no new files)

## Change Log

- 2026-07-04: Story 21.3 implemented — server-side shared-session scoring (migration 0013, Edge Function `score_shared_session`), shared-session UUID plumbing (bloc → RPE screen), `SubmitSharedSessionResultUseCase` + `RpePage` wiring, `SyncManager` handler registration. All 8 tasks complete. `flutter analyze` 0 issues; `flutter test` 1315 passed/1 skipped (zero regressions). Status → review.
