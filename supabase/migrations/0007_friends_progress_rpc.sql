-- RPC for Story 18.4: returns progress metrics for accepted friends
-- who have visibility_tier = 'friends_only', aggregated from activity_feed
-- for the current ISO week (Mon 00:00 UTC to next Mon 00:00 UTC).
-- SECURITY DEFINER so it bypasses activity_feed/profiles RLS,
-- but enforces friendship + visibility_tier constraints explicitly.

CREATE OR REPLACE FUNCTION get_friends_progress_this_week()
RETURNS TABLE(
  friend_id      uuid,
  display_handle text,
  sessions_count bigint,
  minutes_total  bigint
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
  )
  SELECT
    p.id                                                                   AS friend_id,
    COALESCE(p.display_handle, p.id::text)                                AS display_handle,
    COUNT(af.id)                                                           AS sessions_count,
    COALESCE(SUM(af.duration_minutes)::bigint, 0::bigint)                 AS minutes_total
  FROM my_friends mf
  JOIN profiles p ON p.id = mf.friend_id
  LEFT JOIN activity_feed af
    ON  af.owner_id = p.id
    AND af.created_at >= (date_trunc('week', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC')
    AND af.created_at <  (date_trunc('week', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC') + INTERVAL '7 days'
  WHERE p.visibility_tier = 'friends_only'
  GROUP BY p.id, p.display_handle
$$;

REVOKE ALL  ON FUNCTION get_friends_progress_this_week() FROM public;
GRANT EXECUTE ON FUNCTION get_friends_progress_this_week() TO authenticated;
