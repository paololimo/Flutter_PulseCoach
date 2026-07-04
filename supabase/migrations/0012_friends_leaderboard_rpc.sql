-- RPC for Story 21.2: returns total points for the viewer + accepted
-- friends with visibility_tier = 'friends_only' (the viewer's own row is
-- always included regardless of their own tier). Ranking/tie-breaking and
-- rank-freeze are computed client-side (LeaderboardBloc) — this RPC only
-- returns unranked per-user totals.
CREATE OR REPLACE FUNCTION get_friends_leaderboard()
RETURNS TABLE(
  user_id       uuid,
  display_handle text,
  total_points  bigint,
  is_own        boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH current_uid AS (
    SELECT auth.uid() AS uid
  ),
  my_friends AS (
    SELECT
      CASE
        WHEN f.requester_id = (SELECT uid FROM current_uid) THEN f.addressee_id
        ELSE f.requester_id
      END AS friend_id
    FROM friendships f
    WHERE f.status = 'accepted'
      AND (
        f.requester_id = (SELECT uid FROM current_uid)
        OR f.addressee_id = (SELECT uid FROM current_uid)
      )
  ),
  visible_users AS (
    SELECT (SELECT uid FROM current_uid) AS uid, true AS is_own
    UNION
    SELECT mf.friend_id, false
    FROM my_friends mf
    JOIN profiles p ON p.id = mf.friend_id
    WHERE p.visibility_tier = 'friends_only'
  )
  SELECT
    vu.uid                                          AS user_id,
    COALESCE(p.display_handle, vu.uid::text)        AS display_handle,
    COALESCE(SUM(le.points), 0)::bigint              AS total_points,
    vu.is_own
  FROM visible_users vu
  JOIN profiles p ON p.id = vu.uid
  LEFT JOIN leaderboard_entries le ON le.owner_id = vu.uid
  GROUP BY vu.uid, p.display_handle, vu.is_own
$$;

REVOKE ALL  ON FUNCTION get_friends_leaderboard() FROM public;
GRANT EXECUTE ON FUNCTION get_friends_leaderboard() TO authenticated;
