-- shared_sessions: one row per hosted group session
CREATE TABLE IF NOT EXISTS shared_sessions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  join_code    TEXT NOT NULL UNIQUE,
  status       TEXT NOT NULL DEFAULT 'waiting'
                 CHECK (status IN ('waiting', 'in_session', 'ended')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE shared_sessions ENABLE ROW LEVEL SECURITY;

-- Host can insert their own sessions
CREATE POLICY "shared_sessions_insert_own" ON shared_sessions
  FOR INSERT TO authenticated
  WITH CHECK (host_user_id = auth.uid());

-- Host can read their own sessions
CREATE POLICY "shared_sessions_select_host" ON shared_sessions
  FOR SELECT TO authenticated
  USING (host_user_id = auth.uid());

-- Host can update their own session (status + join_code refresh)
CREATE POLICY "shared_sessions_update_host" ON shared_sessions
  FOR UPDATE TO authenticated
  USING (host_user_id = auth.uid())
  WITH CHECK (host_user_id = auth.uid());

-- Host can delete their own session (cancel flow)
CREATE POLICY "shared_sessions_delete_host" ON shared_sessions
  FOR DELETE TO authenticated
  USING (host_user_id = auth.uid());

-- session_participants: one row per participant per session
CREATE TABLE IF NOT EXISTS session_participants (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   UUID NOT NULL REFERENCES shared_sessions(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (session_id, user_id)
);

ALTER TABLE session_participants ENABLE ROW LEVEL SECURITY;

-- Participants can insert themselves (Story 20.3 wires this)
CREATE POLICY "session_participants_insert_self" ON session_participants
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Participants can read rows in sessions they belong to
CREATE POLICY "session_participants_select_own" ON session_participants
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR session_id IN (
      SELECT id FROM shared_sessions WHERE host_user_id = auth.uid()
    )
  );
