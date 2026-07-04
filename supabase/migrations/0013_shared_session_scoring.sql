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

-- Awards points to an ARBITRARY participant (not just auth.uid()) — safe
-- ONLY because it is unreachable by any authenticated client role (see
-- Context: "Why a Postgres-only RPC cannot do this"). Callable exclusively
-- by service_role, i.e. only from the score_shared_session Edge Function,
-- which independently re-derives p_owner_id/p_points from server-held
-- session_participants rows — never trusts a client-supplied value.
-- Cap-clamp + advisory-lock logic is IDENTICAL to award_session_points
-- (0011) — v_daily_cap MUST stay in sync with both 0011's v_daily_cap and
-- ScoringConstants.dailyPointsCap (Dart).
--
-- Precedent note: this is the first migration in this repo to grant to
-- `service_role` explicitly (0011/0012 only grant to `authenticated`) —
-- a new, deliberate precedent, not a copy-paste oversight.
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
