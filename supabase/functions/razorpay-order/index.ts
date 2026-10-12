/**
 * Creates a Razorpay order for Cura Premium: ₹599 / year.
 * Secrets: RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET
 * Returns: { order_id, key_id }
 */
const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const keyId = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
  if (!keyId || !keySecret) {
    return new Response(JSON.stringify({ error: "Razorpay is not configured" }), {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const auth = btoa(`${keyId}:${keySecret}`);
  const orderRes = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: 59900,
      currency: "INR",
      receipt: `cura_${Date.now()}`,
    }),
  });

  const order = await orderRes.json();
  if (!orderRes.ok || !order.id) {
    return new Response(JSON.stringify({ error: "Could not create the order" }), {
      status: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ order_id: order.id, key_id: keyId }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
