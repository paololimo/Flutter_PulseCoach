-- Story 21.5 D2 (server-authoritative hardening): every shared_sessions row
-- MUST have a session_participants row for its host, otherwise
-- score_shared_session / sweep_unscored_shared_sessions (which key off
-- session_participants) never score the host — the host earns ZERO points for a
-- completed shared session.
--
-- The client (createSharedSession) already upserts the host participant. This
-- trigger is defense-in-depth: it guarantees the invariant at the database even
-- if a future client refactor drops the upsert. Idempotent with the client
-- upsert via ON CONFLICT DO NOTHING (session_participants has UNIQUE(session_id,
-- user_id)). Migration back-fills any pre-existing host-less sessions on apply.

CREATE OR REPLACE FUNCTION public.handle_new_shared_session()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.session_participants (session_id, user_id)
  VALUES (NEW.id, NEW.host_user_id)
  ON CONFLICT (session_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Idempotent: drop before recreating
DROP TRIGGER IF EXISTS on_shared_session_created ON public.shared_sessions;

CREATE TRIGGER on_shared_session_created
  AFTER INSERT ON public.shared_sessions
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_shared_session();

-- Back-fill: register the host of any existing session that has no host row
INSERT INTO public.session_participants (session_id, user_id)
SELECT s.id, s.host_user_id
FROM public.shared_sessions s
WHERE NOT EXISTS (
  SELECT 1 FROM public.session_participants p
  WHERE p.session_id = s.id AND p.user_id = s.host_user_id
);
