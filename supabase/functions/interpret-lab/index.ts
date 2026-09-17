/**
 * Edge Function: interpret-lab
 *
 * Accepts a JWT-authenticated request with:
 *   { document_id: string, storage_path: string, file_name?: string }
 *
 * Pipeline (stub):
 * 1. Verify JWT via Supabase Auth
 * 2. If OPENAI_API_KEY or GEMINI_API_KEY present → attempt structure/summary
 *    (never invent biomarker values without OCR text)
 * 3. Otherwise return placeholder with confidence 0 and empty tests[]
 * 4. Persist to lab_documents via service role when SUPABASE_SERVICE_ROLE_KEY set
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

    const body = (await req.json()) as InterpretLabBody;
    if (!body?.document_id || !body?.storage_path) {
      return jsonResponse(
        { error: "document_id and storage_path are required" },
        400,
      );
    }

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    const hasProvider = Boolean(openaiKey || geminiKey);

    // Stub: no OCR provider wired. Never invent biomarker values.
    let result: StructuredLab;

    if (!hasProvider) {
      result = {
        tests: [],
        collection_date: null,
        lab_name: null,
        confidence: 0,
        ai_summary:
          "OCR / AI provider not configured. Upload received; interpretation pending.",
        doctor_questions: [
          "Ask your clinician to review this lab report once OCR is enabled.",
        ],
        ocr_text: null,
        message:
          "OCR provider not configured. Set OPENAI_API_KEY or GEMINI_API_KEY (and wire OCR) to enable interpretation. Returning empty tests[] — no biomarker values invented.",
      };
    } else {
      // Provider keys present but OCR pipeline not implemented in this stub.
      // Still return empty tests[] — never invent values without OCR text.
      result = {
        tests: [],
        collection_date: null,
        lab_name: null,
        confidence: 0,
        ai_summary:
          "AI provider configured, but OCR extraction is not yet enabled for this document. No biomarker values were inferred.",
        doctor_questions: [
          "Please have a clinician review the original report.",
        ],
        ocr_text: null,
        message:
          "Provider key present, but OCR step is stubbed. Empty tests[] returned.",
      };

      // Optional: call LLM only for a non-diagnostic disclaimer summary once OCR exists.
      // Intentionally skipped here to avoid hallucinating biomarkers.
      void openaiKey;
      void geminiKey;
    }

    const status = hasProvider ? "needs_ocr" : "pending_ocr_config";
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
            warning: `Persist failed: ${updateError.message}`,
          },
          200,
        );
      }
    }

    return jsonResponse({
      document_id: body.document_id,
      storage_path: body.storage_path,
      file_name: body.file_name ?? null,
      status,
      ...result,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.error("interpret-lab error:", message);
    return jsonResponse({ error: message }, 500);
  }
});

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
