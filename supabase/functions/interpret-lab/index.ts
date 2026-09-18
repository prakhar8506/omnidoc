/**
 * Edge Function: interpret-lab
 *
 * Accepts a JWT-authenticated request with:
 *   { document_id: string, storage_path: string, file_name?: string }
 * Optionally accepts inline base64 for small images:
 *   { document_id, storage_path, file_name, image_base64, mime_type }
 *
 * Pipeline:
 * 1. Verify JWT
 * 2. Load file from Storage (lab-uploads) or use inline base64
 * 3. Gemini / OpenAI vision extraction — only return biomarkers present in the document
 * 4. Persist structured result to lab_documents when service role is available
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface InterpretLabBody {
  document_id: string;
  storage_path: string;
  file_name?: string;
  image_base64?: string;
  mime_type?: string;
}

interface StructuredLab {
  tests: Array<{
    name: string;
    value: number | null;
    unit: string | null;
    ref_low: number | null;
    ref_high: number | null;
    flag: string | null;
  }>;
  collection_date: string | null;
  lab_name: string | null;
  confidence: number;
  ai_summary: string;
  doctor_questions: string[];
  ocr_text: string | null;
  message?: string;
}

const EXTRACTION_PROMPT = `You are a careful medical lab-report OCR assistant for Cura (a patient health companion).
Extract ONLY values clearly visible in the document. Never invent biomarkers.
Return STRICT JSON with this shape:
{
  "ocr_text": "full readable text transcribed from the document",
  "lab_name": string|null,
  "collection_date": string|null,
  "confidence": number between 0 and 1,
  "tests": [
    {
      "name": string,
      "value": number|null,
      "unit": string|null,
      "ref_low": number|null,
      "ref_high": number|null,
      "flag": "low"|"high"|"normal"|null
    }
  ],
  "ai_summary": "2-4 sentences plain language, non-diagnostic",
  "doctor_questions": ["up to 5 questions the patient could ask a clinician"]
}
Rules:
- If a value is unreadable, omit that test or set value null.
- confidence reflects OCR certainty, not clinical severity.
- ai_summary must say this is not a diagnosis and clinician review is required.
- Respond with JSON only.`;

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
    const serviceRoleKey =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SB_SERVICE_ROLE_KEY");

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

    const body = (await req.json()) as InterpretLabBody;
    if (!body?.document_id || !body?.storage_path) {
      return jsonResponse(
        { error: "document_id and storage_path are required" },
        400,
      );
    }

    // Path must stay under this user
    if (!body.storage_path.startsWith(`${user.id}/`)) {
      return jsonResponse({ error: "storage_path must be under your user folder" }, 403);
    }

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    const hasProvider = Boolean(openaiKey || geminiKey);

    let result: StructuredLab;
    let status = "pending_ocr_config";

    if (!hasProvider) {
      result = emptyPending(
        "OCR / AI provider not configured. Upload received; interpretation pending.",
        "OCR provider not configured. Set OPENAI_API_KEY or GEMINI_API_KEY to enable interpretation.",
      );
    } else {
      const fileBytes = await loadDocumentBytes({
        body,
        supabaseUrl,
        serviceRoleKey,
        userClient,
      });

      if (!fileBytes) {
        result = emptyPending(
          "Document uploaded, but the file could not be loaded for OCR. Try re-uploading an image or PDF.",
          "Could not load document bytes from storage or request body.",
        );
        status = "needs_ocr";
      } else {
        const mime = body.mime_type ?? guessMime(body.file_name ?? body.storage_path);
        try {
          if (geminiKey) {
            result = await extractWithGemini(geminiKey, fileBytes, mime);
          } else {
            result = await extractWithOpenAI(openaiKey!, fileBytes, mime);
          }
          status = result.tests.length > 0 ? "interpreted" : "needs_review";
          if (!result.ai_summary.toLowerCase().includes("not a diagnosis")) {
            result.ai_summary =
              `${result.ai_summary.trim()} This is not a diagnosis — please review with your clinician.`;
          }
        } catch (ocrErr) {
          const msg = ocrErr instanceof Error ? ocrErr.message : "OCR failed";
          console.error("OCR extraction failed:", msg);
          result = emptyPending(
            "Automated reading failed. Your file is saved; please review the original with your clinician.",
            msg,
          );
          status = "ocr_failed";
        }
      }
    }

    const structuredJson = {
      tests: result.tests,
      collection_date: result.collection_date,
      lab_name: result.lab_name,
      confidence: result.confidence,
    };

    if (serviceRoleKey && supabaseUrl) {
      const admin = createClient(supabaseUrl, serviceRoleKey);
      const { error: updateError } = await admin
        .from("lab_documents")
        .update({
          status,
          ocr_text: result.ocr_text,
          structured_json: structuredJson,
          ai_summary: result.ai_summary,
          doctor_questions: result.doctor_questions,
          confidence: result.confidence,
          clinician_verified: false,
          file_name: body.file_name ?? undefined,
        })
        .eq("id", body.document_id)
        .eq("user_id", user.id);

      if (updateError) {
        console.error("lab_documents update failed:", updateError.message);
        return jsonResponse(
          {
            ...result,
            document_id: body.document_id,
            storage_path: body.storage_path,
            status,
            warning: `Persist failed: ${updateError.message}`,
          },
          200,
        );
      }

      // Persist biomarker rows when present
      if (result.tests.length > 0) {
        await admin.from("biomarker_results").delete().eq("document_id", body.document_id);
        const rows = result.tests.map((t) => ({
          document_id: body.document_id,
          user_id: user.id,
          name: t.name,
          value: t.value,
          unit: t.unit,
          ref_low: t.ref_low,
          ref_high: t.ref_high,
          flag: t.flag,
        }));
        const { error: bioErr } = await admin.from("biomarker_results").insert(rows);
        if (bioErr) console.error("biomarker_results insert failed:", bioErr.message);
      }
    }

    return jsonResponse({
      document_id: body.document_id,
      storage_path: body.storage_path,
      file_name: body.file_name ?? null,
      status,
      plainLanguageSummary: result.ai_summary,
      detailedExplanation: result.ai_summary,
      keyFindings: result.tests.map((t) => {
        const val = t.value == null ? "—" : `${t.value}${t.unit ? ` ${t.unit}` : ""}`;
        const flag = t.flag ? ` (${t.flag})` : "";
        return `${t.name}: ${val}${flag}`;
      }),
      doctorQuestions: result.doctor_questions,
      ...result,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("interpret-lab error:", message);
    return jsonResponse({ error: message }, 500);
  }
});

function emptyPending(aiSummary: string, message: string): StructuredLab {
  return {
    tests: [],
    collection_date: null,
    lab_name: null,
    confidence: 0,
    ai_summary: aiSummary,
    doctor_questions: [
      "Can you help me interpret this document?",
      "Is any follow-up needed based on this file?",
    ],
    ocr_text: null,
    message,
  };
}

async function loadDocumentBytes(args: {
  body: InterpretLabBody;
  supabaseUrl: string;
  serviceRoleKey?: string;
  userClient: ReturnType<typeof createClient>;
}): Promise<Uint8Array | null> {
  const { body, serviceRoleKey, userClient, supabaseUrl } = args;
  if (body.image_base64 && body.image_base64.length > 0) {
    try {
      const bin = atob(body.image_base64);
      const bytes = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      return bytes;
    } catch {
      return null;
    }
  }

  const client = serviceRoleKey && supabaseUrl
    ? createClient(supabaseUrl, serviceRoleKey)
    : userClient;

  const { data, error } = await client.storage
    .from("lab-uploads")
    .download(body.storage_path);

  if (error || !data) {
    console.error("storage download failed:", error?.message);
    return null;
  }
  return new Uint8Array(await data.arrayBuffer());
}

function guessMime(name: string): string {
  const lower = name.toLowerCase();
  if (lower.endsWith(".pdf")) return "application/pdf";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".heic")) return "image/heic";
  return "image/jpeg";
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

async function extractWithGemini(
  apiKey: string,
  bytes: Uint8Array,
  mime: string,
): Promise<StructuredLab> {
  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.6-flash";
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
    `?key=${encodeURIComponent(apiKey)}`;

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          role: "user",
          parts: [
            { text: EXTRACTION_PROMPT },
            {
              inlineData: {
                mimeType: mime,
                data: bytesToBase64(bytes),
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: "application/json",
      },
    }),
  });

  if (!res.ok) {
    throw new Error(`Gemini error ${res.status}: ${await res.text()}`);
  }

  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts
    ?.map((p: { text?: string }) => p.text ?? "")
    .join("")
    .trim();
  if (!text) throw new Error("Gemini returned empty OCR payload");
  return normalizeExtraction(JSON.parse(stripCodeFence(text)));
}

async function extractWithOpenAI(
  apiKey: string,
  bytes: Uint8Array,
  mime: string,
): Promise<StructuredLab> {
  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";
  const dataUrl = `data:${mime};base64,${bytesToBase64(bytes)}`;
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0.1,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: EXTRACTION_PROMPT },
        {
          role: "user",
          content: [
            { type: "text", text: "Extract lab values from this document." },
            { type: "image_url", image_url: { url: dataUrl } },
          ],
        },
      ],
    }),
  });

  if (!res.ok) {
    throw new Error(`OpenAI error ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const text = data?.choices?.[0]?.message?.content;
  if (!text || typeof text !== "string") {
    throw new Error("OpenAI returned empty OCR payload");
  }
  return normalizeExtraction(JSON.parse(stripCodeFence(text)));
}

function stripCodeFence(text: string): string {
  const trimmed = text.trim();
  if (trimmed.startsWith("```")) {
    return trimmed.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
  }
  return trimmed;
}

function normalizeExtraction(raw: Record<string, unknown>): StructuredLab {
  const testsRaw = Array.isArray(raw.tests) ? raw.tests : [];
  const tests = testsRaw
    .map((t) => {
      const row = t as Record<string, unknown>;
      const name = String(row.name ?? "").trim();
      if (!name) return null;
      return {
        name,
        value: toNum(row.value),
        unit: row.unit == null ? null : String(row.unit),
        ref_low: toNum(row.ref_low),
        ref_high: toNum(row.ref_high),
        flag: row.flag == null ? null : String(row.flag).toLowerCase(),
      };
    })
    .filter(Boolean) as StructuredLab["tests"];

  const questions = Array.isArray(raw.doctor_questions)
    ? raw.doctor_questions.map((q) => String(q)).filter(Boolean).slice(0, 5)
    : [];

  return {
    tests,
    collection_date: raw.collection_date == null ? null : String(raw.collection_date),
    lab_name: raw.lab_name == null ? null : String(raw.lab_name),
    confidence: clamp01(toNum(raw.confidence) ?? 0),
    ai_summary: String(raw.ai_summary ?? "Document processed. Review with your clinician."),
    doctor_questions: questions.length
      ? questions
      : ["Can you help me interpret these results?"],
    ocr_text: raw.ocr_text == null ? null : String(raw.ocr_text),
  };
}

function toNum(v: unknown): number | null {
  if (v == null || v === "") return null;
  const n = typeof v === "number" ? v : Number(String(v).replace(/,/g, ""));
  return Number.isFinite(n) ? n : null;
}

function clamp01(n: number): number {
  if (n < 0) return 0;
  if (n > 1) return 1;
  return n;
}

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
