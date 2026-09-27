/**
 * Creates a confirmed account without Supabase Auth's confirmation mail,
 * then sends a short greeting from Cura.
 *
 * Requires the service role (injected on Supabase). Greeting delivery uses
 * RESEND_API_KEY when set. Account creation still succeeds if the mailer
 * is not configured — no confirmation link is ever sent.
 */

import { createClient, type User } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "Account service is not configured" }, 503);
  }

  // This endpoint creates accounts with the service role. Accept only the
  // project's publishable key (or a JWT signed with it). Anyone can extract
  // that key from the app, so we also rate-limit by client IP.
  const expectedKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const rawAuth = req.headers.get("authorization") ?? "";
  const rawApiKey = req.headers.get("apikey") ?? "";
  const token = rawAuth.replace(/^Bearer\s+/i, "").trim();
  const presented = token || rawApiKey.trim();
  if (!expectedKey || presented !== expectedKey) {
    return json({ error: "Unable to create account. Please try again." }, 401);
  }
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "unknown";
  if (isRateLimited(ip)) {
    return json({ error: "Too many sign-up attempts. Please wait a minute and try again." }, 429);
  }

  let body: {
    email?: string;
    password?: string;
    full_name?: string;
    blood_type?: string;
  };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const email = (body.email ?? "").trim().toLowerCase();
  const password = body.password ?? "";
  const fullName = (body.full_name ?? "").trim();
  const bloodType = (body.blood_type ?? "Unknown").trim() || "Unknown";

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 254) {
    return json({ error: "Enter a valid email address." }, 400);
  }
  if (password.length < 6 || password.length > 128) {
    return json({ error: "Password must be between 6 and 128 characters." }, 400);
  }
  if (fullName.length < 2 || fullName.length > 120) {
    return json({ error: "Enter your full name." }, 400);
  }
  if (bloodType.length > 12) {
    return json({ error: "Select a valid blood type." }, 400);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName, blood_type: bloodType },
  });

  if (!error && data.user) {
    const greeted = await sendGreeting(email, fullName);
    return json({ user_id: data.user.id, greeted });
  }

  const message = (error?.message ?? "").toLowerCase();
  const already = message.includes("already") || message.includes("registered") || message.includes("exists");
  if (!already) {
    return json({ error: "Unable to create account. Please try again." }, 400);
  }

  const existing = await findUserByEmail(admin, email);
  if (!existing) {
    return json({ error: "That email already has an account. Please sign in." }, 409);
  }

  if (existing.email_confirmed_at) {
    return json({ error: "That email already has an account. Please sign in." }, 409);
  }

  const { error: confirmError } = await admin.auth.admin.updateUserById(existing.id, {
    email_confirm: true,
    user_metadata: {
      ...(existing.user_metadata ?? {}),
      full_name: fullName,
      blood_type: bloodType,
    },
  });
  if (confirmError) {
    return json({ error: "Unable to create account. Please try again." }, 400);
  }

  const greeted = await sendGreeting(email, fullName);
  return json({ user_id: existing.id, greeted });
});

async function findUserByEmail(
  admin: ReturnType<typeof createClient>,
  email: string,
): Promise<User | null> {
  for (let page = 1; page <= 10; page++) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
    if (error || !data?.users?.length) return null;
    const found = data.users.find((user) => (user.email ?? "").toLowerCase() === email);
    if (found) return found;
    if (data.users.length < 200) return null;
  }
  return null;
}

async function sendGreeting(email: string, fullName: string): Promise<boolean> {
  const apiKey = Deno.env.get("RESEND_API_KEY") ?? "";
  if (!apiKey) return false;

  const from = Deno.env.get("CURA_FROM_EMAIL") ?? "Cura <hello@cura.health>";
  const name = fullName.split(" ")[0] || "there";
  const subject = "Thank you for signing in to Cura";
  const text = [
    `Hi ${name},`,
    "",
    "Thank you for signing in to Cura.",
    "",
    "Your health companion is ready. You can log how you feel, track meals and movement, and read lab reports in plain language.",
    "",
    "This note is only a greeting. There is nothing to confirm and no link to open.",
    "",
    "Take care,",
    "Cura",
  ].join("\n");

  const html = `<div style="font-family:Georgia,serif;color:#1c2430;line-height:1.5;max-width:520px">
<p>Hi ${escapeHtml(name)},</p>
<p>Thank you for signing in to Cura.</p>
<p>Your health companion is ready. You can log how you feel, track meals and movement, and read lab reports in plain language.</p>
<p>This note is only a greeting. There is nothing to confirm and no link to open.</p>
<p>Take care,<br>Cura</p>
</div>`;

  try {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ from, to: [email], subject, text, html }),
    });
    return response.ok;
  } catch {
    return false;
  }
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

const signupAttempts = new Map<string, number[]>();

function isRateLimited(ip: string): boolean {
  const now = Date.now();
  const windowMs = 60_000;
  const max = 8;
  const recent = (signupAttempts.get(ip) ?? []).filter((t) => now - t < windowMs);
  recent.push(now);
  signupAttempts.set(ip, recent);
  return recent.length > max;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
