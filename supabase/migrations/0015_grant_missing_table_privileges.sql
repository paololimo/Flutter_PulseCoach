-- Every table in 0001-0014 defines RLS policies but none of those migrations
-- ever issued a base-table GRANT to `authenticated` (or `anon`). RLS policies
-- only restrict rows an already-privileged role may see/touch — Postgres
-- checks table-level privilege first, independent of RLS. Without this
-- migration, a fresh database built from 0001-0014 alone rejects every
-- direct client query (`.from('...')` in the Flutter datasources) with
-- "permission denied for table ...", regardless of RLS policy content.
-- Discovered while running the Epic 21 pgTAP suite (supabase/tests/database/)
-- against a clean `supabase start` instance for the first time.
--
-- Grants below mirror exactly the operations each table's existing RLS
-- policies already support — no policy is changed, and no privilege is
-- granted beyond what a policy already gates. All grants are to
-- `authenticated` only: every existing policy assumes a logged-in
-- `auth.uid()`, so `anon` access would be vacuous at best.

GRANT SELECT, INSERT, UPDATE ON TABLE profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE friendships TO authenticated;
GRANT SELECT, INSERT, DELETE ON TABLE activity_feed TO authenticated;
GRANT SELECT ON TABLE leaderboard_entries TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE shared_sessions TO authenticated;
GRANT SELECT, INSERT ON TABLE session_participants TO authenticated;
