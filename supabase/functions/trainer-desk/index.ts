/**
 * Introductions between a Cura user and a collaborated trainer.
 * Body.action: list | request | desk | decide
 * Service role only. The client never receives a trainer desk code back.
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const tracks = new Set(["gym", "diet", "assist"]);

const roster = [
  {
    id: "gym-blr",
    display_name: "Gym coach, Bengaluru",
    city: "Bengaluru",
    tracks: ["gym"],
    monthly_rate_inr: 8000,
    bio: "Strength sessions and a weekly plan you can do in a gym. Not medical care.",
    desk_code: "cura-gym-blr-4k7m",
  },
  {
    id: "diet-bom",
    display_name: "Meal coach, Mumbai",
    city: "Mumbai",
    tracks: ["diet"],
    monthly_rate_inr: 6000,
    bio: "A practical meal plan from what you already eat. Not a diagnosis and not a prescription.",
    desk_code: "cura-diet-bom-9p2q",
  },
  {
    id: "habit-del",
    display_name: "Habit assistant, Delhi",
    city: "Delhi",
    tracks: ["assist"],
    monthly_rate_inr: 5000,
    bio: "Check-ins for training days, meals, and sleep. Day-to-day help, not clinical treatment.",
    desk_code: "cura-habit-del-3n8w",
  },
  {
    id: "both-hyd",
    display_name: "Strength and meals, Hyderabad",
    city: "Hyderabad",
    tracks: ["gym", "diet"],
    monthly_rate_inr: 10000,
    bio: "Gym sessions plus a meal plan. The coach does not replace your doctor.",
    desk_code: "cura-both-hyd-6t1r",
  },
];

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function cleanTracks(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item)).filter((item) => tracks.has(item));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "POST required" }, 405);

  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !serviceKey) return json({ error: "Trainer desk is not available." }, 503);

  const supabase = createClient(url, serviceKey);
  const body = await req.json().catch(() => ({}));
  const action = String(body.action ?? "");

  if (roster.length > 0) {
    await supabase.from("trainer_profiles").upsert(roster, { onConflict: "id" });
  }

  if (action === "list") {
    const { data, error } = await supabase
      .from("trainer_profiles")
      .select("id, display_name, city, tracks, monthly_rate_inr, bio")
      .eq("active", true)
      .order("monthly_rate_inr");
    if (error) return json({ error: "Could not load trainers." }, 500);
    return json({
      trainers: data ?? [],
      commission_percent: 20,
    });
  }

  if (action === "request") {
    const userId = String(body.user_id ?? "").trim();
    const trainerId = String(body.trainer_id ?? "").trim();
    const chosen = cleanTracks(body.tracks);
    const note = String(body.note ?? "").trim().slice(0, 500);
    if (!userId || !trainerId || chosen.length === 0) {
      return json({ error: "Choose at least one kind of help." }, 400);
    }
    const { data: trainer } = await supabase
      .from("trainer_profiles")
      .select("id")
      .eq("id", trainerId)
      .eq("active", true)
      .maybeSingle();
    if (!trainer) return json({ error: "That trainer is not available." }, 404);

    const row = {
      user_id: userId,
      user_name: String(body.user_name ?? "Cura member").trim().slice(0, 80) || "Cura member",
      user_email: String(body.user_email ?? "").trim().slice(0, 120),
      trainer_id: trainerId,
      tracks: chosen,
      city: String(body.city ?? "").trim().slice(0, 80),
      note,
      status: "requested",
    };
    const { error } = await supabase
      .from("trainer_requests")
      .upsert(row, { onConflict: "user_id,trainer_id" });
    if (error) return json({ error: "Could not send the request." }, 500);
    return json({ status: "requested" });
  }

  if (action === "desk" || action === "decide") {
    const code = String(body.desk_code ?? "").trim();
    const { data: trainer } = await supabase
      .from("trainer_profiles")
      .select("id, display_name")
      .eq("desk_code", code)
      .eq("active", true)
      .maybeSingle();
    if (!trainer) return json({ error: "That trainer code is not recognised." }, 403);

    if (action === "decide") {
      const status = String(body.status ?? "");
      if (status !== "accepted" && status !== "declined") {
        return json({ error: "Choose accept or decline." }, 400);
      }
      const { error } = await supabase
        .from("trainer_requests")
        .update({ status })
        .eq("id", String(body.request_id ?? ""))
        .eq("trainer_id", trainer.id);
      if (error) return json({ error: "Could not update the request." }, 500);
    }

    const { data, error } = await supabase
      .from("trainer_requests")
      .select("id, user_name, user_email, city, tracks, note, status, created_at")
      .eq("trainer_id", trainer.id)
      .order("created_at", { ascending: false });
    if (error) return json({ error: "Could not load requests." }, 500);
    return json({ trainer_name: trainer.display_name, requests: data ?? [] });
  }

  return json({ error: "Unknown action" }, 400);
});
