-- Story 19.0: Create a profiles row for every new auth.users row.
-- Server-authoritative: fires for email, Apple, and Google signups.
-- Migration is idempotent; back-fills pre-existing users on first apply.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_handle, visibility_tier, install_cohort)
  VALUES (
    NEW.id,
    NULL,
    'private',
    'post_v2'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Idempotent: drop before recreating
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Back-fill: insert a profiles row for any auth.users without one
INSERT INTO public.profiles (id, display_handle, visibility_tier, install_cohort)
SELECT
  u.id,
  NULL,
  'private',
  'post_v2'
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = u.id
);
