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

  const userId = user.id;

  // Remove backup from Storage (ignore not-found errors)
  await supabaseAdmin.storage.from("backups").remove([`${userId}/backup_v1.enc`]);

  // Future (Epic 18+): DELETE FROM profiles, friendships, activity_feed,
  // leaderboard_entries WHERE user_id = userId once those tables exist.
  // FK ON DELETE CASCADE on the auth.users reference will handle them
  // automatically once the tables are created with the correct FK setup.

  // Delete the auth user — this is the cascade root.
  const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId);
  if (deleteError) {
    return new Response(JSON.stringify({ error: deleteError.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
