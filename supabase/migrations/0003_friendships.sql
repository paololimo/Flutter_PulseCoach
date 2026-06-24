-- Friendship status enum
CREATE TYPE friendship_status_enum AS ENUM ('pending', 'accepted');

-- Friendships table
CREATE TABLE friendships (
  id           uuid                    PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id uuid                    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  addressee_id uuid                    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status       friendship_status_enum  NOT NULL DEFAULT 'pending',
  created_at   timestamptz             NOT NULL DEFAULT now(),
  CONSTRAINT friendships_no_self_loop CHECK (requester_id != addressee_id),
  CONSTRAINT friendships_unique_pair  UNIQUE (requester_id, addressee_id)
);

ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Either participant can read friendship rows they belong to
CREATE POLICY "friendships_select_participant"
  ON friendships FOR SELECT
  USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- Only requester can create a new pending friendship
CREATE POLICY "friendships_insert_requester"
  ON friendships FOR INSERT
  WITH CHECK (auth.uid() = requester_id AND status = 'pending');

-- Only addressee can update (accept) a friendship
CREATE POLICY "friendships_update_addressee"
  ON friendships FOR UPDATE
  USING (auth.uid() = addressee_id);

-- Either participant can delete (decline / remove) a friendship
CREATE POLICY "friendships_delete_participant"
  ON friendships FOR DELETE
  USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- Allow discovery of friends_only profiles by handle (for friend search)
-- Also allows reading profiles of accepted friends regardless of their current visibility tier
CREATE POLICY "profiles_select_by_handle"
  ON profiles FOR SELECT
  USING (
    display_handle IS NOT NULL
    AND auth.uid() != id
    AND (
      visibility_tier = 'friends_only'
      OR EXISTS (
        SELECT 1 FROM friendships f
        WHERE f.status = 'accepted'
          AND (
            (f.requester_id = auth.uid() AND f.addressee_id = profiles.id)
            OR (f.addressee_id = auth.uid() AND f.requester_id = profiles.id)
          )
      )
    )
  );
