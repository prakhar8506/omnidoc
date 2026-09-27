/**
 * Edge Function: interpret-lab
 *
 * Vision OCR + plain-language clinical education for average patients.
 * Extracts ONLY values visible in the document; never invents biomarkers.
 *
 * Returns severity, causes, lifestyle measures, specialist, consult urgency,
 * and commonly discussed medicines (educational — not a prescription).
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

interface LabTest {
  name: string;
  code: string | null;
  value: number | null;
  value_text: string | null;
  unit: string | null;
  ref_low: number | null;
  ref_high: number | null;
  ref_text: string | null;
  flag: string | null;
  severity: string | null;
  plain_meaning: string;
  what_it_means: string;
  possible_causes: string[];
  lifestyle_measures: string[];
  precautions: string[];
  consult_urgency: string;
  specialist: string;
  commonly_discussed_medicines: Array<{
    name: string;
    why_discussed: string;
    note: string;
  }>;
}

interface StructuredLab {
  tests: LabTest[];
  collection_date: string | null;
  lab_name: string | null;
  confidence: number;
  ai_summary: string;
  detailed_explanation: string;
  overall_urgency: string;
  urgency_banner: string;
  recommended_specialist: string;
  care_plan: string[];
  red_flags: string[];
  medicine_education: string[];
  doctor_questions: string[];
  ocr_text: string | null;
  message?: string;
}

const EXTRACTION_PROMPT = `You are Cura's lab-report educator for everyday people with no medical training.
Read the attached lab report / prescription image or PDF carefully.

CRITICAL RULES:
1. Extract ONLY values clearly visible in the document. NEVER invent biomarkers or numbers.
2. If handwriting is unreadable, omit that line or mark value null.
3. Explain like talking to a smart 16-year-old: short sentences, no jargon without definition.
4. For each abnormal finding, explain what the test measures (e.g. hemoglobin/Hb = oxygen-carrying protein in red blood cells).
5. Severity must be one of: normal | mild | moderate | severe | critical | unknown
6. flag must be one of: low | high | normal | abnormal | null
7. commonly_discussed_medicines = medicines clinicians COMMONLY discuss for related conditions in standard guidelines (e.g. ferrous sulfate for iron-deficiency anemia). This is EDUCATION only — NOT a prescription. Each medicine must include note: "Discuss with your doctor before taking — not a prescription from Cura."
8. If everything is normal, say so clearly and still explain what was checked.
9. Always include that this is not a diagnosis and a licensed clinician must confirm.
10. Respond with JSON only (no markdown).

Return STRICT JSON:
{
  "ocr_text": "full readable text transcribed from the document",
  "lab_name": string|null,
  "collection_date": string|null,
  "confidence": number between 0 and 1,
  "overall_urgency": "routine"|"soon"|"urgent"|"emergency",
  "urgency_banner": "one short line: how fast to see a doctor",
  "recommended_specialist": "e.g. General Physician / Hematologist / Endocrinologist",
  "ai_summary": "3-5 sentences overview a non-medical person understands",
  "detailed_explanation": "longer plain-language walkthrough of the whole report",
  "care_plan": ["practical lifestyle / diet / sleep / hydration steps"],
  "red_flags": ["symptoms that mean go to ER / seek care today"],
  "medicine_education": ["short bullets about commonly discussed meds for these findings — always say discuss with doctor"],
  "doctor_questions": ["up to 6 specific questions for the clinician"],
  "tests": [
    {
      "name": "Hemoglobin",
      "code": "Hb",
      "value": 16.0,
      "value_text": "16.0",
      "unit": "g/dL",
      "ref_low": 13.0,
      "ref_high": 17.0,
      "ref_text": "13.0-17.0 g/dL",
      "flag": "normal",
      "severity": "normal",
      "plain_meaning": "How much oxygen-carrying protein is in your blood",
      "what_it_means": "Your number vs the lab's normal range, in plain words",
      "possible_causes": ["only if abnormal — otherwise empty array"],
      "lifestyle_measures": ["diet, rest, hydration, exercise tips related to this marker"],
      "precautions": ["what to avoid / watch for"],
      "consult_urgency": "routine|soon|urgent|emergency",
      "specialist": "who usually manages this",
      "commonly_discussed_medicines": [
        {
          "name": "example only if relevant",
          "why_discussed": "why doctors may mention it",
          "note": "Discuss with your doctor before taking — not a prescription from Cura."
        }
      ]
    }
  ]
}`;

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
    } = await userClient.auth.getUser();

    if (!user) {
      return jsonResponse({ error: "Unauthorized — sign in to analyze lab reports" }, 401);
    }

    const body = (await req.json()) as InterpretLabBody;
    if (!body?.document_id || !body?.storage_path) {
      return jsonResponse(
        { error: "document_id and storage_path are required" },
        400,
      );
    }

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
          "Document uploaded, but the file could not be loaded for OCR. Try re-uploading a clear photo or PDF.",
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
          result = ensureDisclaimer(result);
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
      overall_urgency: result.overall_urgency,
      urgency_banner: result.urgency_banner,
      recommended_specialist: result.recommended_specialist,
      care_plan: result.care_plan,
      red_flags: result.red_flags,
      medicine_education: result.medicine_education,
      detailed_explanation: result.detailed_explanation,
    };

    if (user && serviceRoleKey && supabaseUrl) {
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
      }

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

    return jsonResponse(toClientPayload(body, result, status));
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("interpret-lab error:", message);
    return jsonResponse({ error: message }, 500);
  }
});

function toClientPayload(
  body: InterpretLabBody,
  result: StructuredLab,
  status: string,
) {
  return {
    document_id: body.document_id,
    storage_path: body.storage_path,
    file_name: body.file_name ?? null,
    status,
    plainLanguageSummary: result.ai_summary,
    detailedExplanation: result.detailed_explanation || result.ai_summary,
    keyFindings: result.tests.map((t) => {
      const val = t.value_text ??
        (t.value == null ? "—" : `${t.value}${t.unit ? ` ${t.unit}` : ""}`);
      const flag = t.flag ? ` (${t.flag})` : "";
      const sev = t.severity && t.severity !== "normal" ? ` [${t.severity}]` : "";
      return `${t.name}: ${val}${flag}${sev}`;
    }),
    doctorQuestions: result.doctor_questions,
    overallUrgency: result.overall_urgency,
    urgencyBanner: result.urgency_banner,
    recommendedSpecialist: result.recommended_specialist,
    carePlan: result.care_plan,
    redFlags: result.red_flags,
    medicineEducation: result.medicine_education,
    tests: result.tests,
    ...result,
  };
}

function ensureDisclaimer(result: StructuredLab): StructuredLab {
  const disc =
    " This is educational guidance only — not a diagnosis or prescription. Confirm with a licensed clinician before any medicines or treatment.";
  if (!result.ai_summary.toLowerCase().includes("not a diagnosis")) {
    result.ai_summary = `${result.ai_summary.trim()}${disc}`;
  }
  if (!result.detailed_explanation.toLowerCase().includes("not a diagnosis")) {
    result.detailed_explanation = `${result.detailed_explanation.trim()}${disc}`;
  }
  return result;
}

function emptyPending(aiSummary: string, message: string): StructuredLab {
  return {
    tests: [],
    collection_date: null,
    lab_name: null,
    confidence: 0,
    ai_summary: aiSummary,
    detailed_explanation: aiSummary,
    overall_urgency: "routine",
    urgency_banner: "Analysis pending — review the original report with your clinician.",
    recommended_specialist: "General Physician",
    care_plan: [],
    red_flags: [
      "Chest pain, severe breathlessness, fainting, or sudden weakness → seek emergency care.",
    ],
    medicine_education: [],
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
  const preferred = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.6-flash";
  // Google currently routes flash traffic to 3.6; keep aliases for transitions.
  const models = [
    ...new Set([
      preferred,
      "gemini-3.6-flash",
      "gemini-flash-latest",
      "gemini-2.5-flash",
      "gemini-2.0-flash",
    ]),
  ].filter(Boolean);

  const errors: string[] = [];
  for (const model of models) {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
      `?key=${encodeURIComponent(apiKey)}`;

    let succeeded = false;
    for (let attempt = 0; attempt < 3 && !succeeded; attempt++) {
      if (attempt > 0) {
        await new Promise((r) => setTimeout(r, 1200 * attempt));
      }
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
                    mimeType: mime.startsWith("image/") || mime === "application/pdf"
                      ? mime
                      : "image/jpeg",
                    data: bytesToBase64(bytes),
                  },
                },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.15,
            responseMimeType: "application/json",
          },
        }),
      });

      if (!res.ok) {
        const errText = await res.text();
        const msg = `Gemini ${model} error ${res.status}: ${errText}`;
        console.error(msg);
        // Retry transient overload
        if (res.status === 503 || res.status === 429) {
          if (attempt === 2) errors.push(msg);
          continue;
        }
        errors.push(msg);
        break;
      }

      const data = await res.json();
      const text = data?.candidates?.[0]?.content?.parts
        ?.map((p: { text?: string }) => p.text ?? "")
        .join("")
        .trim();
      if (!text) {
        errors.push(`Gemini ${model} returned empty OCR payload`);
        break;
      }
      try {
        return normalizeExtraction(JSON.parse(stripCodeFence(text)));
      } catch (parseErr) {
        errors.push(
          `Gemini ${model} JSON parse failed: ${
            parseErr instanceof Error ? parseErr.message : "parse error"
          }`,
        );
        break;
      }
    }
  }
  throw new Error(errors.join(" | ") || "Gemini failed");
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
      temperature: 0.15,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: EXTRACTION_PROMPT },
        {
          role: "user",
          content: [
            {
              type: "text",
              text:
                "Extract every lab value from this document and explain each result for a non-medical patient.",
            },
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

function asStringList(v: unknown, max = 8): string[] {
  if (!Array.isArray(v)) return [];
  return v.map((x) => String(x).trim()).filter(Boolean).slice(0, max);
}

function normalizeExtraction(raw: Record<string, unknown>): StructuredLab {
  const testsRaw = Array.isArray(raw.tests) ? raw.tests : [];
  const tests = testsRaw
    .map((t) => {
      const row = t as Record<string, unknown>;
      const name = String(row.name ?? "").trim();
      if (!name) return null;

      const medsRaw = Array.isArray(row.commonly_discussed_medicines)
        ? row.commonly_discussed_medicines
        : [];
      const meds = medsRaw
        .map((m) => {
          const med = m as Record<string, unknown>;
          const medName = String(med.name ?? "").trim();
          if (!medName) return null;
          return {
            name: medName,
            why_discussed: String(med.why_discussed ?? "").trim() ||
              "Sometimes discussed by clinicians for related findings.",
            note: String(med.note ?? "").trim() ||
              "Discuss with your doctor before taking — not a prescription from Cura.",
          };
        })
        .filter(Boolean) as LabTest["commonly_discussed_medicines"];

      const value = toNum(row.value);
      const valueText = row.value_text != null
        ? String(row.value_text)
        : (value == null ? null : String(value));

      return {
        name,
        code: row.code == null || String(row.code).trim() === ""
          ? abbreviate(name)
          : String(row.code).trim(),
        value,
        value_text: valueText,
        unit: row.unit == null ? null : String(row.unit),
        ref_low: toNum(row.ref_low),
        ref_high: toNum(row.ref_high),
        ref_text: row.ref_text == null ? null : String(row.ref_text),
        flag: row.flag == null ? null : String(row.flag).toLowerCase(),
        severity: row.severity == null ? null : String(row.severity).toLowerCase(),
        plain_meaning: String(row.plain_meaning ?? "").trim() ||
          `${name} is a lab measurement from your report.`,
        what_it_means: String(row.what_it_means ?? "").trim() ||
          "See your clinician for personalized interpretation.",
        possible_causes: asStringList(row.possible_causes),
        lifestyle_measures: asStringList(row.lifestyle_measures),
        precautions: asStringList(row.precautions),
        consult_urgency: String(row.consult_urgency ?? "routine").toLowerCase(),
        specialist: String(row.specialist ?? "General Physician").trim() ||
          "General Physician",
        commonly_discussed_medicines: meds,
      } satisfies LabTest;
    })
    .filter(Boolean) as LabTest[];

  const questions = asStringList(raw.doctor_questions, 6);

  return {
    tests,
    collection_date: raw.collection_date == null ? null : String(raw.collection_date),
    lab_name: raw.lab_name == null ? null : String(raw.lab_name),
    confidence: clamp01(toNum(raw.confidence) ?? 0),
    ai_summary: String(raw.ai_summary ?? "Document processed. Review with your clinician."),
    detailed_explanation: String(
      raw.detailed_explanation ?? raw.ai_summary ??
        "Document processed. Review with your clinician.",
    ),
    overall_urgency: String(raw.overall_urgency ?? "routine").toLowerCase(),
    urgency_banner: String(raw.urgency_banner ?? "").trim() ||
      "Review these results with your clinician.",
    recommended_specialist: String(raw.recommended_specialist ?? "General Physician")
      .trim() || "General Physician",
    care_plan: asStringList(raw.care_plan, 10),
    red_flags: asStringList(raw.red_flags, 8),
    medicine_education: asStringList(raw.medicine_education, 10),
    doctor_questions: questions.length
      ? questions
      : ["Can you help me interpret these results?"],
    ocr_text: raw.ocr_text == null ? null : String(raw.ocr_text),
  };
}

function abbreviate(name: string): string {
  const parts = name.split(/\s+/).filter(Boolean);
  if (parts.length === 1) return parts[0].slice(0, 6).toUpperCase();
  return parts.map((p) => p[0]).join("").slice(0, 6).toUpperCase();
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
