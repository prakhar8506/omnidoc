/**
 * One free Premium trial per device hash.
 * Body: { device_hash: string }
 * Returns: { allowed: boolean }
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const hash = String(body?.device_hash ?? "").trim();
    if (!/^[a-f0-9]{64}$/.test(hash)) {
      return new Response(JSON.stringify({ allowed: false }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: existing } = await admin
      .from("device_trials")
      .select("device_hash")
      .eq("device_hash", hash)
      .maybeSingle();

    if (existing) {
      return new Response(JSON.stringify({ allowed: false }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error } = await admin.from("device_trials").insert({ device_hash: hash });
    if (error) {
      return new Response(JSON.stringify({ allowed: false }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ allowed: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch {
    return new Response(JSON.stringify({ allowed: false }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
