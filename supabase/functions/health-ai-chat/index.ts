/**
 * Edge Function: health-ai-chat
 *
 * Accepts JWT + JSON { message: string, context?: unknown }
 * Returns { reply: string }
 *
 * System role: wellness coach — not a doctor; no diagnosis;
 * emergencies → redirect to local emergency services.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SYSTEM_PROMPT = `You are a wellness coach for a personal health companion app.
You are NOT a doctor and you do NOT diagnose conditions or prescribe treatments.
If the user describes a medical emergency (chest pain, difficulty breathing, severe bleeding,
stroke symptoms, suicidal ideation, etc.), tell them to call local emergency services
immediately and do not attempt to triage further.
Do not recommend medication dosing changes.
Lab and biometric information is informational only and must be reviewed by a clinician.
Be supportive, clear, and concise. Prefer asking clarifying questions when data is missing.`;

interface ChatBody {
  message: string;
  context?: unknown;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return jsonResponse({ error: "Missing or invalid Authorization header" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? Deno.env.get("SB_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SB_ANON_KEY") ?? "";

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

    const body = (await req.json()) as ChatBody;
    const message = (body?.message ?? "").trim();
    if (!message) {
      return jsonResponse({ error: "message is required" }, 400);
    }

    const contextText =
      body.context === undefined || body.context === null
        ? ""
        : typeof body.context === "string"
          ? body.context
          : JSON.stringify(body.context);

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    const geminiKey = Deno.env.get("GEMINI_API_KEY");

    let reply: string;

    if (openaiKey) {
      reply = await callOpenAI(openaiKey, message, contextText);
    } else if (geminiKey) {
      reply = await callGemini(geminiKey, message, contextText);
    } else {
      reply =
        "I'm your wellness coach (offline mode — no AI provider configured). " +
        "I can't diagnose or change medications. For emergencies, call local emergency services. " +
        "Set OPENAI_API_KEY or GEMINI_API_KEY on this Edge Function to enable live replies. " +
        (contextText
          ? "I received your context bundle and can discuss it once a provider is configured."
          : "Share how you're feeling, or upload a lab report for context later.");
    }

    return jsonResponse({ reply });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("health-ai-chat error:", message);
    return jsonResponse({ error: message }, 500);
  }
});

async function callOpenAI(
  apiKey: string,
  message: string,
  contextText: string,
): Promise<string> {
  const userContent = contextText
    ? `Authorized user context (consent-gated):\n${contextText}\n\nUser message:\n${message}`
    : message;

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini",
      temperature: 0.4,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: userContent },
      ],
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`OpenAI error ${res.status}: ${errText}`);
  }

  const data = await res.json();
  const reply = data?.choices?.[0]?.message?.content;
  if (!reply || typeof reply !== "string") {
    throw new Error("OpenAI returned an empty reply");
  }
  return reply.trim();
}

async function callGemini(
  apiKey: string,
  message: string,
  contextText: string,
): Promise<string> {
  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.6-flash";
  const userContent = contextText
    ? `Authorized user context (consent-gated):\n${contextText}\n\nUser message:\n${message}`
    : message;

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
    `?key=${encodeURIComponent(apiKey)}`;

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
      contents: [{ role: "user", parts: [{ text: userContent }] }],
      generationConfig: { temperature: 0.4 },
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Gemini error ${res.status}: ${errText}`);
  }

  const data = await res.json();
  const reply = data?.candidates?.[0]?.content?.parts
    ?.map((p: { text?: string }) => p.text ?? "")
    .join("")
    .trim();

  if (!reply) {
    throw new Error("Gemini returned an empty reply");
  }
  return reply;
}

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
