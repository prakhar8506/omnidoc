/**
 * Confirms a Razorpay payment signature before Premium is unlocked.
 * Body: { order_id, payment_id, signature }
 */
const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function hmacSha256(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signed = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
  return Array.from(new Uint8Array(signed)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
  if (!keySecret) {
    return new Response(JSON.stringify({ ok: false }), {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const body = await req.json();
  const orderId = String(body?.order_id ?? "");
  const paymentId = String(body?.payment_id ?? "");
  const signature = String(body?.signature ?? "");
  const expected = await hmacSha256(keySecret, `${orderId}|${paymentId}`);
  if (!orderId || !paymentId || expected !== signature) {
    return new Response(JSON.stringify({ ok: false }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const premiumUntil = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString();
  return new Response(JSON.stringify({ ok: true, premium_until: premiumUntil }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
