import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("Unauthorized", { status: 401 });

  const jwt = authHeader.replace("Bearer ", "");
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(jwt);
  if (userError || !user) return new Response("Unauthorized", { status: 401 });

  // Export all server-side personal data for this user.
  // v2.1 scope: auth user metadata only.
  // Future (Epic 18+): add queries for profiles, friendships,
  // activity_feed, leaderboard_entries once those tables exist.
  const exportData = {
    exportedAt: new Date().toISOString(),
    schemaVersion: 1,
    userId: user.id,
    email: user.email,
    emailConfirmedAt: user.email_confirmed_at,
    createdAt: user.created_at,
  };

  return new Response(JSON.stringify(exportData, null, 2), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
