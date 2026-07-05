-- pgTAP test closing the Epic 21 traceability gap 21.3-AC2 (the shared-
-- session bonus is clamped by the same per-day cap as solo points) and
-- exercising submit_shared_session_result's own-row-only write scope.
--
-- Run with `supabase test db` (requires `supabase start` / Docker). Not
-- executed in the authoring environment — Docker/psql were unavailable
-- there. Written against 0009_shared_sessions.sql and
-- 0013_shared_session_scoring.sql.

BEGIN;
SELECT plan(5);

INSERT INTO auth.users (id, email) VALUES
  ('44444444-4444-4444-4444-444444444444', 'dave@test.local'),
  ('55555555-5555-5555-5555-555555555555', 'erin@test.local');

-- on_auth_user_created (0008) already inserted a bare profiles row for each
-- id above, so update it in place rather than re-inserting.
UPDATE profiles SET display_handle = 'dave' WHERE id = '44444444-4444-4444-4444-444444444444';
UPDATE profiles SET display_handle = 'erin' WHERE id = '55555555-5555-5555-5555-555555555555';

INSERT INTO shared_sessions (id, host_user_id, join_code, status) VALUES
  ('66666666-6666-6666-6666-666666666666', '44444444-4444-4444-4444-444444444444', 'JOIN01', 'in_session');

INSERT INTO session_participants (session_id, user_id) VALUES
  ('66666666-6666-6666-6666-666666666666', '44444444-4444-4444-4444-444444444444'),
  ('66666666-6666-6666-6666-666666666666', '55555555-5555-5555-5555-555555555555');

-- ---------------------------------------------------------------------
-- submit_shared_session_result: writes only the caller's own row
-- ---------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', true);

SELECT lives_ok(
  $$ SELECT submit_shared_session_result('66666666-6666-6666-6666-666666666666'::uuid, 7, 'cardio_medium', 20) $$,
  'submit_shared_session_result succeeds for a real participant submitting their own result'
);

SELECT is(
  (SELECT rpe_value FROM session_participants
   WHERE session_id = '66666666-6666-6666-6666-666666666666' AND user_id = '55555555-5555-5555-5555-555555555555'),
  NULL,
  'dave''s submission does not write erin''s (the drop-out participant''s) row — leaves it null, matching Story 21.4''s premise'
);

RESET ROLE;

-- ---------------------------------------------------------------------
-- 21.3-AC2: award_shared_session_points clamps to the same daily cap (200)
-- as award_session_points, and is callable only as service_role.
-- ---------------------------------------------------------------------
SET LOCAL ROLE service_role;

SELECT is(
  award_shared_session_points('44444444-4444-4444-4444-444444444444'::uuid, 'shared:pre-fill', 190, '2026-07-05'::date),
  190,
  '21.3-AC2a: first shared-session award of the day under the cap returns the full (bonus-multiplied) points'
);

SELECT is(
  award_shared_session_points('44444444-4444-4444-4444-444444444444'::uuid, 'shared:66666666-6666-6666-6666-666666666666', 45, '2026-07-05'::date),
  10,
  '21.3-AC2b: a same-day shared-session bonus is clamped to the remaining headroom (200 - 190 = 10), not the full 45 — the bonus cannot circumvent the cap'
);

SELECT is(
  award_shared_session_points('44444444-4444-4444-4444-444444444444'::uuid, 'shared:66666666-6666-6666-6666-666666666666', 45, '2026-07-05'::date),
  0,
  '21.3-AC2c: replaying the same idempotency key (e.g. sweep retried after a partial failure) is a no-op, not a second award'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
