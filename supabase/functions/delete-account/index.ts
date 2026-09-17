/**
 * Edge Function: delete-account
 *
 * Authenticated stub that deletes user-owned application rows, then
 * optionally removes the Auth user via the service role.
 *
 * Documented deletion steps (order matters for FKs):
 *  1. Verify JWT and resolve auth.uid()
 *  2. Delete child / dependent rows first:
 *       biomarker_results → lab_documents
 *       pregnancy_logs, pregnancy_profiles
 *       nutrition_logs, cycle_logs, chronic_readings, workouts
 *       appointments, medications, family_members
 *       ai_messages, habit_logs, journal_entries, check_ins, scores, health_events
 *  3. Delete singleton / PK-by-user_id rows:
 *       medical_id, consent_settings, wearable_connections
 *  4. Delete Storage objects under lab-uploads/{user_id}/ and avatars/{user_id}/
 *     (when service role + buckets exist)
 *  5. Delete profiles row (id = user_id)
 *  6. Delete auth.users via admin.auth.admin.deleteUser(user_id)
 *     (requires SUPABASE_SERVICE_ROLE_KEY)
 *
 * This stub performs steps 2–3 and 5–6 when the service role is configured.
 * Storage cleanup (step 4) is attempted best-effort.
 */

import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/** Tables keyed by user_id (delete all matching rows). Order: children first. */
const USER_ID_TABLES: string[] = [
  "biomarker_results",
  "lab_documents",
  "pregnancy_logs",
  "pregnancy_profiles",
  "nutrition_logs",
  "cycle_logs",
  "chronic_readings",
  "workouts",
  "appointments",
  "medications",
  "family_members",
  "ai_messages",
  "habit_logs",
  "journal_entries",
  "check_ins",
  "scores",
  "health_events",
  "medical_id",
  "consent_settings",
  "wearable_connections",
];

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST" && req.method !== "DELETE") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return jsonResponse({ error: "Missing or invalid Authorization header" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? Deno.env.get("SB_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SB_ANON_KEY") ?? "";
    const serviceRoleKey = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SB_SERVICE_ROLE_KEY"));

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const userId = user.id;
    const steps: string[] = [];
    const errors: string[] = [];

    if (!serviceRoleKey) {
      return jsonResponse(
        {
          ok: false,
          user_id: userId,
          message:
            "SUPABASE_SERVICE_ROLE_KEY not set. Documented steps only — no deletions performed.",
          documented_steps: [
            "1. Verify JWT → auth.uid()",
            "2. Delete user-owned rows (biomarker_results, lab_documents, pregnancy_*, nutrition_logs, cycle_logs, chronic_readings, workouts, appointments, medications, family_members, ai_messages, habit_logs, journal_entries, check_ins, scores, health_events)",
            "3. Delete medical_id, consent_settings, wearable_connections",
            "4. Remove Storage objects under lab-uploads/{uid}/ and avatars/{uid}/",
            "5. Delete profiles where id = uid",
            "6. admin.auth.admin.deleteUser(uid)",
          ],
        },
        503,
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);

    // Step 2–3: delete application rows owned by the user
    for (const table of USER_ID_TABLES) {
      const { error } = await admin.from(table).delete().eq("user_id", userId);
      if (error) {
        // Table may not exist yet in older environments — record and continue
        errors.push(`${table}: ${error.message}`);
      } else {
        steps.push(`deleted ${table} where user_id = uid`);
      }
    }

    // Step 4: best-effort storage cleanup
    await deleteUserStoragePrefix(admin, "lab-uploads", userId, steps, errors);
    await deleteUserStoragePrefix(admin, "avatars", userId, steps, errors);

    // Step 5: profiles (PK column is id, not user_id)
    {
      const { error } = await admin.from("profiles").delete().eq("id", userId);
      if (error) {
        errors.push(`profiles: ${error.message}`);
      } else {
        steps.push("deleted profiles where id = uid");
      }
    }

    // Step 6: remove Auth user
    {
      const { error } = await admin.auth.admin.deleteUser(userId);
      if (error) {
        errors.push(`auth.deleteUser: ${error.message}`);
      } else {
        steps.push("deleted auth.users row");
      }
    }

    return jsonResponse({
      ok: errors.length === 0,
      user_id: userId,
      steps,
      errors: errors.length ? errors : undefined,
      message:
        errors.length === 0
          ? "Account and owned data deleted."
          : "Account deletion completed with some errors; see errors[].",
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("delete-account error:", message);
    return jsonResponse({ error: message }, 500);
  }
});

async function deleteUserStoragePrefix(
  admin: SupabaseClient,
  bucket: string,
  userId: string,
  steps: string[],
  errors: string[],
): Promise<void> {
  try {
    const { data: listed, error: listError } = await admin.storage
      .from(bucket)
      .list(userId, { limit: 1000 });

    if (listError) {
      errors.push(`storage.list ${bucket}/${userId}: ${listError.message}`);
      return;
    }

    const paths = (listed ?? []).map((f) => `${userId}/${f.name}`);
    if (paths.length === 0) {
      steps.push(`storage ${bucket}/${userId}: empty`);
      return;
    }

    const { error: removeError } = await admin.storage.from(bucket).remove(paths);
    if (removeError) {
      errors.push(`storage.remove ${bucket}: ${removeError.message}`);
    } else {
      steps.push(`removed ${paths.length} object(s) from ${bucket}/${userId}`);
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    errors.push(`storage ${bucket}: ${msg}`);
  }
}

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
