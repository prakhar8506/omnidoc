/**
 * Edge Function: health-ai-chat
 *
 * Accepts JWT (user session) or project anon key (guest coaching) +
 * JSON { message: string, context?: unknown, mode?: string }
 * Returns { reply: string, triage?: object }
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

const SYSTEM_PROMPT = `You are Cura Health AI — a careful wellness coach inside a personal health companion app.

Rules:
- You are NOT a doctor. Do not diagnose disease or prescribe prescription medications.
- You MAY discuss general OTC self-care (e.g. rest, hydration, when people often use acetaminophen/ibuprofen) and clearly say it is general information, not a personal prescription.
- When the user asks "what medicine should I take", use their medication/prescription context if provided: list what they already have logged, note possible relevance, and warn them to confirm dose/interactions with a pharmacist or clinician. Never invent prescription drugs they do not have.
- If symptoms sound like an emergency (chest pain, severe breathing trouble, stroke signs, severe allergic reaction, suicidal ideation), tell them to call local emergency services immediately.
- Prefer clear, actionable, concise answers (short paragraphs + bullets). Reference vitals, labs, and mood from context when useful.
- Lab values are informational only — clinicians confirm clinical meaning.
- If context is missing, ask 1–2 clarifying questions.

When mode is "triage", structure the reply exactly as:
URGENCY: <LOW|MODERATE|URGENT|EMERGENCY>
WINDOW: <timeframe phrase>
ASSESSMENT: <2–4 sentences>
SELF_CARE:
- <title>: <one sentence>
- <title>: <one sentence>
RED_FLAGS:
- <flag>
- <flag>
SPECIALTY: <suggested clinician type>
OTC_NOTE: <optional note referencing logged meds or general OTC caution>`;

interface ChatBody {
  message: string;
  context?: unknown;
  mode?: string;
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
    const token = authHeader.slice("Bearer ".length).trim();

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    let user = null as { id: string } | null;
    try {
      const result = await userClient.auth.getUser(token);
      user = result.data.user;
    } catch (_) {
      user = null;
    }

    if (!user) {
      return jsonResponse(
        {
          error: "Unauthorized",
          hint: "Sign in with a real account to use Health AI.",
        },
        401,
      );
    }

    const body = (await req.json()) as ChatBody;
    const message = (body?.message ?? "").trim();
    if (!message) {
      return jsonResponse({ error: "message is required" }, 400);
    }

    const mode = (body.mode ?? "").toLowerCase();
    const contextText =
      body.context === undefined || body.context === null
        ? ""
        : typeof body.context === "string"
          ? body.context
          : JSON.stringify(body.context);

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    const geminiKey = Deno.env.get("GEMINI_API_KEY");

    const modePrefix =
      mode === "triage"
        ? "MODE=triage. Follow the triage response template exactly.\n\n"
        : "";

    let reply: string;

    if (openaiKey) {
      reply = await callOpenAI(openaiKey, `${modePrefix}${message}`, contextText);
    } else if (geminiKey) {
      reply = await callGemini(geminiKey, `${modePrefix}${message}`, contextText);
    } else {
      reply =
        "I'm your wellness coach (offline mode — no AI provider configured). " +
        "I can't diagnose or change medications. For emergencies, call local emergency services. " +
        "Set OPENAI_API_KEY or GEMINI_API_KEY on this Edge Function to enable live replies. " +
        (contextText
          ? "I received your context bundle and can discuss it once a provider is configured."
          : "Share how you're feeling, or upload a lab report for context later.");
    }

    const payload: Record<string, unknown> = {
      reply,
      guest: false,
      provider: openaiKey ? "openai" : geminiKey ? "gemini" : "offline",
    };

    if (mode === "triage") {
      try {
        payload.triage = parseTriageReply(reply);
      } catch (parseErr) {
        console.warn("triage parse failed:", parseErr);
        payload.triage = {
          urgency: "MODERATE",
          timeframeWindow: "24–48 hrs",
          clinicalRationale: reply,
          selfCare: [],
          redFlags: [
            "Difficulty breathing or sudden chest pressure.",
            "Loss of consciousness or severe disorientation.",
          ],
          recommendedSpecialty: "General Practice / Telehealth",
        };
      }
    }

    return jsonResponse(payload);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("health-ai-chat error:", message);
    return jsonResponse({ error: message }, 500);
  }
});

function parseTriageReply(reply: string): Record<string, unknown> {
  const urgencyMatch = reply.match(/URGENCY:\s*(LOW|MODERATE|URGENT|EMERGENCY)/i);
  const windowMatch = reply.match(/WINDOW:\s*(.+)/i);
  const assessmentMatch = reply.match(/ASSESSMENT:\s*([\s\S]*?)(?=\nSELF_CARE:|\nRED_FLAGS:|\nSPECIALTY:|\nOTC_NOTE:|$)/i);
  const specialtyMatch = reply.match(/SPECIALTY:\s*(.+)/i);
  const selfCareBlock = reply.match(/SELF_CARE:\s*([\s\S]*?)(?=\nRED_FLAGS:|\nSPECIALTY:|\nOTC_NOTE:|$)/i)?.[1] ?? "";
  const redFlagBlock = reply.match(/RED_FLAGS:\s*([\s\S]*?)(?=\nSPECIALTY:|\nOTC_NOTE:|$)/i)?.[1] ?? "";

  const selfCare = selfCareBlock
    .split("\n")
    .map((l) => l.replace(/^[-*•]\s*/, "").trim())
    .filter(Boolean)
    .map((line) => {
      const parts = line.split(":");
      if (parts.length >= 2) {
        return { title: parts[0].trim(), description: parts.slice(1).join(":").trim() };
      }
      return { title: "Self-care", description: line };
    });

  const redFlags = redFlagBlock
    .split("\n")
    .map((l) => l.replace(/^[-*•]\s*/, "").trim())
    .filter(Boolean);

  return {
    urgency: (urgencyMatch?.[1] ?? "MODERATE").toUpperCase(),
    timeframeWindow: windowMatch?.[1]?.trim() ?? "24–48 hrs",
    clinicalRationale: assessmentMatch?.[1]?.trim() ?? reply.trim(),
    selfCare,
    redFlags,
    recommendedSpecialty: specialtyMatch?.[1]?.trim() ?? "General Practice / Telehealth",
  };
}

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
  const preferred = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.6-flash";
  const models = [...new Set([preferred, "gemini-3.6-flash", "gemini-flash-latest", "gemini-2.5-flash", "gemini-2.0-flash"])];
  let lastError: Error | null = null;

  for (const model of models) {
    try {
      return await callGeminiWithModel(apiKey, model, message, contextText);
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
      console.warn(`Gemini model ${model} failed:`, lastError.message);
    }
  }

  throw lastError ?? new Error("Gemini request failed");
}

async function callGeminiWithModel(
  apiKey: string,
  model: string,
  message: string,
  contextText: string,
): Promise<string> {
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
