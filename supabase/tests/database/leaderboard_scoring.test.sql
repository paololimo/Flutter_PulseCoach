-- pgTAP tests closing the Epic 21 traceability gaps that are pure SQL and
-- were previously verified only by code-read trace (no live-DB harness
-- existed in this repo before this file): 21.1-AC2 (daily points cap
-- clamp) and 21.2-AC1 (friends-only RLS visibility on leaderboard_entries).
--
-- Run with `supabase test db` (requires `supabase start`, which requires
-- Docker). Not executed in the authoring environment for this change —
-- Docker/psql were unavailable there. Written against the exact schema in
-- 0001_profiles_auth.sql, 0003_friendships.sql, and 0011_leaderboard.sql.

BEGIN;
SELECT plan(7);

-- Fixture users. profiles.id references auth.users(id), so both rows are
-- needed. Handles: alice (owner under test), bob (accepted friend),
-- carol (non-friend — must never see alice's points).
INSERT INTO auth.users (id, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'alice@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'carol@test.local');

-- on_auth_user_created (0008) already inserted a bare profiles row for each
-- id above, so update it in place rather than re-inserting.
UPDATE profiles SET display_handle = 'alice', visibility_tier = 'friends_only' WHERE id = '11111111-1111-1111-1111-111111111111';
UPDATE profiles SET display_handle = 'bob', visibility_tier = 'friends_only' WHERE id = '22222222-2222-2222-2222-222222222222';
UPDATE profiles SET display_handle = 'carol', visibility_tier = 'friends_only' WHERE id = '33333333-3333-3333-3333-333333333333';

INSERT INTO friendships (requester_id, addressee_id, status) VALUES
  ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'accepted');
  -- carol is deliberately NOT a friend of alice.

-- ---------------------------------------------------------------------
-- 21.1-AC2: award_session_points clamps to the per-day cap (200)
-- ---------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);

SELECT is(
  award_session_points('sess-a', 150, '2026-07-05'),
  150,
  '21.1-AC2a: first award of the day under the cap returns the full base points'
);

SELECT is(
  award_session_points('sess-b', 100, '2026-07-05'),
  50,
  '21.1-AC2b: a second same-day award is clamped to the remaining headroom (200 - 150 = 50), not the full 100'
);

SELECT is(
  award_session_points('sess-c', 50, '2026-07-05'),
  0,
  '21.1-AC2c: once the cap is fully consumed, a further same-day award is clamped to 0'
);

SELECT is(
  award_session_points('sess-d', 80, '2026-07-06'),
  80,
  '21.1-AC2d: the cap resets on a new calendar day (awarded_on) — same owner, no headroom carried over'
);

SELECT is(
  award_session_points('sess-a', 150, '2026-07-05'),
  0,
  '21.1-AC2e: replaying an already-recorded session_log_id (idempotency key) is a no-op, not a second award'
);

RESET ROLE;

-- ---------------------------------------------------------------------
-- 21.2-AC1: get_friends_leaderboard() never surfaces a non-friend's row
-- ---------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true);

SELECT is(
  (SELECT count(*)::int FROM get_friends_leaderboard() WHERE user_id = '11111111-1111-1111-1111-111111111111'),
  0,
  '21.2-AC1a: carol (non-friend of alice) never sees alice''s row in her own leaderboard call'
);

SELECT set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);

SELECT is(
  (SELECT count(*)::int FROM get_friends_leaderboard() WHERE user_id = '11111111-1111-1111-1111-111111111111'),
  1,
  '21.2-AC1b: bob (accepted friend of alice) DOES see alice''s row — confirms the negative-path assertion above is a real filter, not universal emptiness'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
