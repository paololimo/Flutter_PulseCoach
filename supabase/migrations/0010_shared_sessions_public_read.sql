-- Allow any authenticated user to SELECT shared_sessions.
-- The join_code is a capability token; no PII is exposed by this table
-- (host_user_id is a UUID, not a username or email address).
-- Required for Story 20.3 follower join-code lookup (FR69).
CREATE POLICY "shared_sessions_select_by_code" ON shared_sessions
  FOR SELECT TO authenticated
  USING (true);
