-- 0006: Harden activity_feed reaction writes (code review of story 18.3)
-- Closes the SECURITY DEFINER RLS-bypass on increment_feed_reaction and the
-- over-permissive direct-UPDATE policy introduced in 0005.

-- 1. Reactions are written ONLY through the hardened RPC below. Drop the
--    direct-UPDATE policy whose `WITH CHECK (true)` let any accepted friend
--    rewrite session_type / duration_minutes / completed_at on the owner's row.
DROP POLICY IF EXISTS "feed_update_reactions" ON activity_feed;

-- 2. Re-create the RPC with a pinned search_path and an in-function authorization
--    check. SECURITY DEFINER bypasses RLS, so without this guard any authenticated
--    caller who knows a feed id could increment reactions on a row they cannot read.
--    auth.uid() still resolves to the *calling* user inside a SECURITY DEFINER
--    function (it reads the per-request JWT claims), so the friendship check holds.
CREATE OR REPLACE FUNCTION increment_feed_reaction(feed_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE activity_feed af
  SET reactions = reactions + 1
  WHERE af.id = feed_id
    AND (
      auth.uid() = af.owner_id
      OR EXISTS (
        SELECT 1 FROM friendships f
        WHERE f.status = 'accepted'
          AND (
            (f.requester_id = auth.uid() AND f.addressee_id = af.owner_id)
            OR (f.addressee_id = auth.uid() AND f.requester_id = af.owner_id)
          )
      )
    );
$$;

-- 3. Only authenticated users may invoke the RPC (revoke the implicit PUBLIC grant).
REVOKE ALL ON FUNCTION increment_feed_reaction(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION increment_feed_reaction(uuid) TO authenticated;

-- 4. Indexes backing the RLS friendship subquery + newest-first feed ordering.
CREATE INDEX IF NOT EXISTS activity_feed_owner_id_idx ON activity_feed (owner_id);
CREATE INDEX IF NOT EXISTS activity_feed_created_at_idx ON activity_feed (created_at DESC);
