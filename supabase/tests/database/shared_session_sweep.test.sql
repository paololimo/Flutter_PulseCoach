-- pgTAP tests closing the Epic 21 traceability gaps 21.4-AC1, AC2, AC3 —
-- the drop-out scoring sweep. Previously verified only by code-read trace
-- (explicitly documented in the story as the accepted method, since this
-- repo has no live-DB harness). This file provides that harness.
--
-- Run with `supabase test db` (requires `supabase start` / Docker). Not
-- executed in the authoring environment — Docker/psql were unavailable
-- there. Written against 0009_shared_sessions.sql,
-- 0013_shared_session_scoring.sql, and 0014_shared_session_scoring_sweep.sql.

BEGIN;
SELECT plan(6);

INSERT INTO auth.users (id, email) VALUES
  ('77777777-7777-7777-7777-777777777777', 'frank@test.local'),
  ('88888888-8888-8888-8888-888888888888', 'gina@test.local'),
  ('99999999-9999-9999-9999-999999999999', 'hank@test.local');

-- on_auth_user_created (0008) already inserted a bare profiles row for each
-- id above, so update it in place rather than re-inserting.
UPDATE profiles SET display_handle = 'frank' WHERE id = '77777777-7777-7777-7777-777777777777';
UPDATE profiles SET display_handle = 'gina' WHERE id = '88888888-8888-8888-8888-888888888888';
UPDATE profiles SET display_handle = 'hank' WHERE id = '99999999-9999-9999-9999-999999999999';

-- Session A: past the 30-min grace window, one submitter (frank) + one
-- drop-out (gina, rpe_value still null) — the exact 21.4 gap scenario.
INSERT INTO shared_sessions (id, host_user_id, join_code, status, created_at) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', '77777777-7777-7777-7777-777777777777', 'SWEEPA', 'in_session', now() - interval '45 minutes');

INSERT INTO session_participants (session_id, user_id, rpe_value, arm_key, duration_minutes, completed_at) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', '77777777-7777-7777-7777-777777777777', 6, 'cardio_medium', 20, now() - interval '40 minutes');
INSERT INTO session_participants (session_id, user_id) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', '88888888-8888-8888-8888-888888888888'); -- gina: never submitted

-- Session B: still inside the grace window — must NOT be touched at all.
INSERT INTO shared_sessions (id, host_user_id, join_code, status, created_at) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000002', '99999999-9999-9999-9999-999999999999', 'SWEEPB', 'in_session', now() - interval '5 minutes');
INSERT INTO session_participants (session_id, user_id, rpe_value, arm_key, duration_minutes, completed_at) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000002', '99999999-9999-9999-9999-999999999999', 5, 'mobility_low', 15, now() - interval '2 minutes');

-- Session C: past the grace window, already scored by the client path —
-- the sweep must not double-award it.
INSERT INTO shared_sessions (id, host_user_id, join_code, status, created_at, scored) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000003', '77777777-7777-7777-7777-777777777777', 'SWEEPC', 'in_session', now() - interval '45 minutes', true);
INSERT INTO session_participants (session_id, user_id, rpe_value, arm_key, duration_minutes, completed_at) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000003', '77777777-7777-7777-7777-777777777777', 8, 'breathing_low', 10, now() - interval '40 minutes');

SELECT sweep_unscored_shared_sessions();

-- ---------------------------------------------------------------------
-- 21.4-AC1: active-only participant is scored; the never-submitted
-- participant is silently skipped, not blocking the sweep.
-- ---------------------------------------------------------------------
SELECT ok(
  EXISTS (
    SELECT 1 FROM leaderboard_entries
    WHERE owner_id = '77777777-7777-7777-7777-777777777777'
      AND session_log_id = 'shared:aaaaaaaa-0000-0000-0000-000000000001'
  ),
  '21.4-AC1a: frank (submitted, session A) is awarded points by the sweep'
);

SELECT is(
  (SELECT count(*)::int FROM leaderboard_entries WHERE owner_id = '88888888-8888-8888-8888-888888888888'),
  0,
  '21.4-AC1b: gina (never submitted, session A) receives NO leaderboard_entries row'
);

SELECT is(
  (SELECT scored FROM shared_sessions WHERE id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  true,
  '21.4-AC1c: session A is claimed (scored = true) after the sweep runs'
);

-- ---------------------------------------------------------------------
-- 21.4-AC2: a session still inside the grace window is left untouched.
-- ---------------------------------------------------------------------
SELECT is(
  (SELECT scored FROM shared_sessions WHERE id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  false,
  '21.4-AC2: session B (inside grace window) is not claimed by the sweep'
);

-- ---------------------------------------------------------------------
-- 21.4-AC3: a session already scored by the client path is never
-- re-awarded by the sweep (mutual exclusivity via the atomic claim).
-- ---------------------------------------------------------------------
SELECT is(
  (SELECT count(*)::int FROM leaderboard_entries
   WHERE owner_id = '77777777-7777-7777-7777-777777777777'
     AND session_log_id = 'shared:aaaaaaaa-0000-0000-0000-000000000003'),
  0,
  '21.4-AC3: session C (already scored=true before the sweep ran) is never awarded by the sweep — no double-award'
);

-- Re-running the sweep must also be a no-op for session A (idempotency of
-- the whole sweep, not just the award RPC) — confirms the atomic claim
-- prevents a second pass from re-processing an already-claimed session.
SELECT sweep_unscored_shared_sessions();

SELECT is(
  (SELECT count(*)::int FROM leaderboard_entries WHERE owner_id = '77777777-7777-7777-7777-777777777777'
     AND session_log_id = 'shared:aaaaaaaa-0000-0000-0000-000000000001'),
  1,
  '21.4-AC3 (re-run): a second sweep pass does not create a duplicate award for the already-claimed session A'
);

SELECT * FROM finish();
ROLLBACK;
