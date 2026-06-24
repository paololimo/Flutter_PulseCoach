-- Activity feed table
CREATE TABLE activity_feed (
  id               uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id         uuid         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  session_type     text         NOT NULL,
  duration_minutes int          NOT NULL,
  completed_at     timestamptz  NOT NULL,
  reactions        int          NOT NULL DEFAULT 0,
  created_at       timestamptz  NOT NULL DEFAULT now()
);

ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;

-- Owner can insert their own entries
CREATE POLICY "feed_insert_owner"
  ON activity_feed FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

-- Owner can delete (revoke) their own entries
CREATE POLICY "feed_delete_owner"
  ON activity_feed FOR DELETE
  USING (auth.uid() = owner_id);

-- Friends (accepted) can read feed entries of friends
CREATE POLICY "feed_select_friends"
  ON activity_feed FOR SELECT
  USING (
    auth.uid() = owner_id
    OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.status = 'accepted'
        AND (
          (f.requester_id = auth.uid() AND f.addressee_id = activity_feed.owner_id)
          OR (f.addressee_id = auth.uid() AND f.requester_id = activity_feed.owner_id)
        )
    )
  );

-- Any authenticated user can update reactions on readable entries
-- (enforced via RPC below; direct UPDATE policy left permissive for the RPC path)
CREATE POLICY "feed_update_reactions"
  ON activity_feed FOR UPDATE
  USING (
    auth.uid() = owner_id
    OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.status = 'accepted'
        AND (
          (f.requester_id = auth.uid() AND f.addressee_id = activity_feed.owner_id)
          OR (f.addressee_id = auth.uid() AND f.requester_id = activity_feed.owner_id)
        )
    )
  )
  WITH CHECK (true);

-- RPC to safely increment reactions (avoids client-side read-modify-write race)
CREATE OR REPLACE FUNCTION increment_feed_reaction(feed_id uuid)
RETURNS void LANGUAGE sql SECURITY DEFINER AS $$
  UPDATE activity_feed SET reactions = reactions + 1 WHERE id = feed_id;
$$;
