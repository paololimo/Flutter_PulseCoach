-- Broaden profile discovery so that a participant in ANY friendship (pending or
-- accepted) can read the counterpart's profile. Without this, a friends_only
-- user who receives a request from a non-friends_only requester cannot read the
-- requester's profile (handle) until the friendship is accepted, leaving the
-- "Richieste in arrivo" row unrenderable. Revealing the requester's handle to
-- the addressee is intended: the requester chose to initiate the friendship.
DROP POLICY IF EXISTS "profiles_select_by_handle" ON profiles;

CREATE POLICY "profiles_select_by_handle"
  ON profiles FOR SELECT
  USING (
    display_handle IS NOT NULL
    AND auth.uid() != id
    AND (
      visibility_tier = 'friends_only'
      OR EXISTS (
        SELECT 1 FROM friendships f
        WHERE (
          (f.requester_id = auth.uid() AND f.addressee_id = profiles.id)
          OR (f.addressee_id = auth.uid() AND f.requester_id = profiles.id)
        )
      )
    )
  );
