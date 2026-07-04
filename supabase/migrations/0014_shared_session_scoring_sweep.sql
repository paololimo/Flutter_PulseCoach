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
    SELECT ss.id
    FROM shared_sessions ss
    WHERE ss.scored = false
      AND ss.created_at < now() - v_grace_window
      -- Only score sessions that genuinely progressed: at least one
      -- participant actually finished (submit_shared_session_result sets
      -- completed_at alongside rpe_value, 0013). This prevents claiming a
      -- session that is still in progress — or was never started — 30 min
      -- after its lobby opened. (shared_sessions.status cannot gate this:
      -- in practice it never transitions out of 'waiting' — no writer ever
      -- updates it.) The primary drop-out case is preserved: a session with
      -- ≥1 submitter and a never-submitting participant still has a
      -- completed_at row, so it is still swept. Deliberate revision of the
      -- original AC2c "claim all-null sessions to a terminal state": a
      -- session where NOBODY ever submitted is now left unclaimed and
      -- re-scanned each tick (harmless at this volume) rather than claimed
      -- prematurely — chosen in code review to never cut off a participant
      -- who is still mid-session.
      AND EXISTS (
        SELECT 1
        FROM session_participants sp
        WHERE sp.session_id = ss.id
          AND sp.completed_at IS NOT NULL
      )
  LOOP
    -- Per-session isolation: a single award_shared_session_points failure
    -- (e.g. an FK violation from a profile deleted mid-run) must not roll
    -- back the whole sweep batch nor re-poison every 5-minute tick. This
    -- BEGIN…EXCEPTION opens a subtransaction; on error its rollback also
    -- reverts this session's `scored = true` claim, so the session is
    -- retried on a later run while every other session in this batch still
    -- commits. The failure is surfaced via RAISE WARNING for observability.
    BEGIN
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

        -- awarded_on uses UTC to match the client path exactly
        -- (score_shared_session/index.ts stamps new Date().toISOString()),
        -- so both paths bucket the shared daily cap on the same calendar
        -- day regardless of the DB session timezone.
        PERFORM award_shared_session_points(
          v_participant.user_id,
          'shared:' || v_session.id::text,
          v_points,
          (now() AT TIME ZONE 'utc')::date
        );
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'sweep_unscored_shared_sessions: skipped session % (%)',
          v_session.id, SQLERRM;
    END;
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
  $$SELECT public.sweep_unscored_shared_sessions();$$
);
