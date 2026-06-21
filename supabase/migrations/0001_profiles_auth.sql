-- Custom enums
CREATE TYPE install_cohort_enum AS ENUM ('pre_v2', 'post_v2');
CREATE TYPE visibility_tier_enum AS ENUM ('private', 'friends_only');

-- Profiles table (mirrors auth.users; one row per registered user)
CREATE TABLE profiles (
  id               uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_handle   text        UNIQUE,
  install_cohort   install_cohort_enum  NOT NULL DEFAULT 'post_v2',
  visibility_tier  visibility_tier_enum NOT NULL DEFAULT 'private',
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- RLS: each user reads/writes only their own row
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
