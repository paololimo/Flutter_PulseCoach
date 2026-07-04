import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// FR75 kill switch (epics.md AC4/counter-metrics): the ENTIRE bonus is this
// one constant. Set to 1.0 and redeploy to disable the bonus with zero other
// code changes, per the PM's weekly counter-metrics review process.
export const SHARED_SESSION_MULTIPLIER = 1.5;

export function intensityWeightFor(armKey: string): number {
  if (armKey.endsWith("_low")) return 1.0;
  if (armKey.endsWith("_medium")) return 1.5;
  return 2.0; // '_high' — mirrors ScoringConstants.intensityWeightFor (Dart)
}

export function computeAward(basePoints: number, multiplier: number): number {
  return Math.round(basePoints * multiplier);
}

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("Unauthorized", { status: 401 });
  const jwt = authHeader.replace("Bearer ", "");

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: userError } = await admin.auth.getUser(jwt);
  if (userError || !user) return new Response("Unauthorized", { status: 401 });

  const { sessionId } = await req.json();
  if (!sessionId) return new Response("Bad Request", { status: 400 });

  const { data: participants, error: participantsError } = await admin
    .from("session_participants")
    .select("user_id, rpe_value, arm_key, duration_minutes")
    .eq("session_id", sessionId);

  if (participantsError || !participants || participants.length === 0) {
    return new Response(JSON.stringify({ error: "lookup_failed" }), { status: 500 });
  }

  const isParticipant = participants.some((p) => p.user_id === user.id);
  if (!isParticipant) return new Response("Forbidden", { status: 403 });

  const allSubmitted = participants.every((p) => p.rpe_value !== null);
  if (!allSubmitted) {
    return new Response(JSON.stringify({ scored: false, reason: "pending" }), { status: 200 });
  }

  // Atomic claim: only the ONE invocation that observes "all submitted"
  // first actually scores; every other participant's own invocation
  // (racing this one) sees 0 rows updated and becomes a harmless no-op.
  const { data: claimed, error: claimError } = await admin
    .from("shared_sessions")
    .update({ scored: true })
    .eq("id", sessionId)
    .eq("scored", false)
    .select("id");

  if (claimError || !claimed || claimed.length === 0) {
    return new Response(JSON.stringify({ scored: false, reason: "already_scored" }), { status: 200 });
  }

  const awardedOn = new Date().toISOString().substring(0, 10);
  const results = [];
  for (const p of participants) {
    const basePoints = Math.round((p.duration_minutes ?? 0) * intensityWeightFor(p.arm_key ?? ""));
    const points = computeAward(basePoints, SHARED_SESSION_MULTIPLIER);
    const { data: awarded, error: awardError } = await admin.rpc("award_shared_session_points", {
      p_owner_id: p.user_id,
      p_idempotency_key: `shared:${sessionId}`,
      p_points: points,
      p_awarded_on: awardedOn,
    });
    results.push({ userId: p.user_id, awarded: awardError ? 0 : awarded });
  }

  return new Response(JSON.stringify({ scored: true, results }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
