/**
 * Family circle invites.
 * Body.action: create | preview | accept | list | remove
 * Uses the service role so Google-signed-in users (no Supabase auth id) can connect.
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const relations = new Set(["Parent", "Spouse", "Child", "Sibling", "Caregiver", "Family"]);

function inverse(relation: string): string {
  switch (relation) {
    case "Parent":
      return "Child";
    case "Child":
      return "Parent";
    case "Spouse":
      return "Spouse";
    case "Sibling":
      return "Sibling";
    default:
      return "Family";
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function code(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const body = await req.json();
    const action = String(body?.action ?? "");
    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    if (action === "create") {
      const userId = String(body?.user_id ?? "").trim();
      const name = String(body?.name ?? "").trim();
      const email = String(body?.email ?? "").trim().toLowerCase();
      const relation = String(body?.relation ?? "Family").trim();
      if (userId.length < 3 || name.length < 1 || !relations.has(relation)) {
        return json({ error: "A name and relationship are required." }, 400);
      }
      const inviteCode = code();
      const { error } = await admin.from("family_invites").insert({
        code: inviteCode,
        inviter_id: userId,
        inviter_name: name.slice(0, 80),
        inviter_email: email || null,
        relation,
        status: "pending",
      });
      if (error) return json({ error: "The invite could not be created." }, 500);
      return json({ code: inviteCode });
    }

    if (action === "preview") {
      const inviteCode = String(body?.code ?? "").trim().toLowerCase();
      const { data } = await admin
        .from("family_invites")
        .select("inviter_name, relation, status")
        .eq("code", inviteCode)
        .maybeSingle();
      if (!data) return json({ error: "This invite link is not valid." }, 404);
      return json({
        inviter_name: data.inviter_name,
        relation: data.relation,
        status: data.status,
      });
    }

    if (action === "accept") {
      const inviteCode = String(body?.code ?? "").trim().toLowerCase();
      const userId = String(body?.user_id ?? "").trim();
      const name = String(body?.name ?? "").trim();
      const email = String(body?.email ?? "").trim().toLowerCase();
      if (userId.length < 3 || name.length < 1) {
        return json({ error: "Sign in before accepting an invite." }, 400);
      }
      const { data: invite } = await admin
        .from("family_invites")
        .select("code, inviter_id, inviter_name, inviter_email, relation, status")
        .eq("code", inviteCode)
        .maybeSingle();
      if (!invite) return json({ error: "This invite link is not valid." }, 404);
      if (invite.inviter_id === userId) {
        return json({ error: "You cannot accept your own invite." }, 400);
      }
      if (invite.status === "accepted" && invite.accepter_id && invite.accepter_id !== userId) {
        return json({ error: "This invite was already used." }, 409);
      }

      const theirRelation = String(invite.relation);
      const myRelation = inverse(theirRelation);
      const rows = [
        {
          user_id: invite.inviter_id,
          member_id: userId,
          member_name: name.slice(0, 80),
          member_email: email || null,
          relation: theirRelation,
          invite_code: inviteCode,
        },
        {
          user_id: userId,
          member_id: invite.inviter_id,
          member_name: invite.inviter_name,
          member_email: invite.inviter_email,
          relation: myRelation,
          invite_code: inviteCode,
        },
      ];
      const { error: linkError } = await admin
        .from("family_links")
        .upsert(rows, { onConflict: "user_id,member_id" });
      if (linkError) return json({ error: "The connection could not be saved." }, 500);

      await admin
        .from("family_invites")
        .update({
          status: "accepted",
          accepter_id: userId,
          accepter_name: name.slice(0, 80),
          accepter_email: email || null,
          accepted_at: new Date().toISOString(),
        })
        .eq("code", inviteCode);

      return json({
        connected: true,
        member_name: invite.inviter_name,
        relation: myRelation,
      });
    }

    if (action === "list") {
      const userId = String(body?.user_id ?? "").trim();
      if (userId.length < 3) return json({ error: "Sign in to see your family." }, 400);
      const { data: links } = await admin
        .from("family_links")
        .select("member_id, member_name, member_email, relation")
        .eq("user_id", userId);
      const { data: pending } = await admin
        .from("family_invites")
        .select("code, relation, created_at")
        .eq("inviter_id", userId)
        .eq("status", "pending");
      return json({ members: links ?? [], pending: pending ?? [] });
    }

    if (action === "remove") {
      const userId = String(body?.user_id ?? "").trim();
      const memberId = String(body?.member_id ?? "").trim();
      if (userId.length < 3 || memberId.length < 3) {
        return json({ error: "That family member could not be removed." }, 400);
      }
      await admin.from("family_links").delete().eq("user_id", userId).eq("member_id", memberId);
      await admin.from("family_links").delete().eq("user_id", memberId).eq("member_id", userId);
      return json({ removed: true });
    }

    return json({ error: "Unknown action." }, 400);
  } catch {
    return json({ error: "Family invites are unavailable right now." }, 500);
  }
});
