-- Leaderboard points ledger. Rows are written exclusively via the
-- award_session_points RPC below — there is no direct client INSERT policy,
-- because the per-day cap (UX-DR31 anti-gaming guardrail) must be enforced
-- server-side, not trusted from a client-computed value (ARCH v2 rule #10).
CREATE TABLE leaderboard_entries (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id       uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  session_log_id text        NOT NULL, -- idempotency key '{installId}:{localSessionLogId}' — the local Drift id is namespaced by a per-install random id (LeaderboardRepositoryImpl) so it stays unique across reinstalls / second devices, where the local autoincrement would otherwise restart at 1 and collide. Not an FK (session_logs is a local-only drift table).
  points         int         NOT NULL,
  awarded_on     date        NOT NULL, -- UTC calendar day used for the daily cap sum
  created_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (owner_id, session_log_id)
);

ALTER TABLE leaderboard_entries ENABLE ROW LEVEL SECURITY;

-- Friends-only visibility, identical shape to activity_feed's policy
-- (0005_activity_feed.sql) — reused here even though Story 21.2 (the
-- viewing UI) hasn't landed yet, so the RLS story is complete in one place.
CREATE POLICY "leaderboard_select_self_and_friends"
  ON leaderboard_entries FOR SELECT
  USING (
    auth.uid() = owner_id
    OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.status = 'accepted'
        AND (
          (f.requester_id = auth.uid() AND f.addressee_id = leaderboard_entries.owner_id)
          OR (f.addressee_id = auth.uid() AND f.requester_id = leaderboard_entries.owner_id)
        )
    )
  );

-- No INSERT/UPDATE/DELETE policy for clients on purpose — all writes go
-- through this SECURITY DEFINER function, which enforces the per-day cap
-- (v_daily_cap) regardless of the caller-supplied p_base_points. Keep
-- v_daily_cap in sync with ScoringConstants.dailyPointsCap (Dart, Task 2).
CREATE OR REPLACE FUNCTION award_session_points(
  p_session_log_id text,
  p_base_points int,
  p_awarded_on date
) RETURNS int LANGUAGE plpgsql SECURITY DEFINER
-- Pin search_path: a SECURITY DEFINER function runs with the definer's rights,
-- so an unqualified object reference resolving through a caller-influenced
-- search_path is an object-shadowing / privilege-escalation vector. Mirrors
-- the hardening applied to increment_feed_reaction in
-- 0006_activity_feed_reaction_hardening.sql (and 0007/0008).
SET search_path = public
AS $$
DECLARE
  v_owner uuid := auth.uid();
  v_already_awarded int;
  v_daily_cap CONSTANT int := 200;
  v_awarded int;
BEGIN
  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  -- Serialize concurrent awards for the same owner: the daily-cap
  -- read-then-insert below is otherwise racy across devices / a burst of
  -- queued offline drains — two awards for different session_log_ids on the
  -- same day could each read the same pre-insert SUM and both grant the full
  -- remaining headroom, overshooting v_daily_cap. This transaction-scoped
  -- advisory lock (released on commit) closes that window without blocking
  -- awards for other owners.
  PERFORM pg_advisory_xact_lock(hashtextextended(v_owner::text, 0));

  -- Idempotent no-op on replay (offline queue may call this more than once
  -- for the same session_log_id if a prior attempt's queue-entry deletion
  -- raced with a retry — see SyncManager.processQueue).
  IF EXISTS (
    SELECT 1 FROM leaderboard_entries
    WHERE owner_id = v_owner AND session_log_id = p_session_log_id
  ) THEN
    RETURN 0;
  END IF;

  SELECT COALESCE(SUM(points), 0) INTO v_already_awarded
  FROM leaderboard_entries
  WHERE owner_id = v_owner AND awarded_on = p_awarded_on;

  v_awarded := GREATEST(0, LEAST(p_base_points, v_daily_cap - v_already_awarded));

  INSERT INTO leaderboard_entries (owner_id, session_log_id, points, awarded_on)
  VALUES (v_owner, p_session_log_id, v_awarded, p_awarded_on)
  ON CONFLICT (owner_id, session_log_id) DO NOTHING;

  RETURN v_awarded;
END;
$$;
