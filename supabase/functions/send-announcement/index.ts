import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { sendOneSignalNotification } from "../_shared/onesignal.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const authHeader = req.headers.get("Authorization");

    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Client with caller's JWT to verify auth and admin status
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });

    // Verify caller identity
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify admin role via RPC
    const { data: isAdmin, error: adminCheckError } = await supabaseClient.rpc("is_current_user_admin");
    if (adminCheckError || !isAdmin) {
      return new Response(
        JSON.stringify({ error: "Forbidden: Caller is not an authorized administrator" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const {
      title,
      body: content,
      type = "general",
      target_route_id = null,
      priority = "normal",
      expires_at = null,
    } = body;

    if (!title || !content) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: title, body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (type === "disruption" && !target_route_id) {
      return new Response(
        JSON.stringify({ error: "Route-targeted disruption requires target_route_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Default expiry 7 days if omitted
    const effectiveExpiresAt = expires_at
      ? new Date(expires_at).toISOString()
      : new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString();

    // Use service role to insert announcement and dispatch
    const adminSupabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    });

    // 1. Insert announcement into public.notification_announcements matching migration schema
    const { data: announcement, error: insertError } = await adminSupabase
      .from("notification_announcements")
      .insert({
        title,
        body: content,
        type,
        route_id: target_route_id,
        created_by: user.id,
        expires_at: effectiveExpiresAt,
        status: "published",
        metadata: { priority },
      })
      .select()
      .single();

    if (insertError) {
      console.error("[send-announcement] Insert error:", insertError);
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Determine target audience and recipients
    let pushResult;
    const targetUserIds: string[] = [];
    const targetGuestIds: string[] = [];
    const externalIds: string[] = [];
    const subIds: string[] = [];

    if (type === "general") {
      // Broadcast to all active users/subscribers
      const { data: allSubs } = await adminSupabase
        .from("notification_subscriptions")
        .select("user_id, guest_device_id, onesignal_subscription_id")
        .eq("is_enabled", true);

      for (const sub of allSubs ?? []) {
        if (sub.user_id) {
          targetUserIds.push(sub.user_id);
          externalIds.push(sub.user_id);
        } else if (sub.guest_device_id) {
          targetGuestIds.push(sub.guest_device_id);
          if (sub.onesignal_subscription_id) subIds.push(sub.onesignal_subscription_id);
        } else if (sub.onesignal_subscription_id) {
          subIds.push(sub.onesignal_subscription_id);
        }
      }

      pushResult = await sendOneSignalNotification({
        headings: { en: title },
        contents: { en: content },
        included_segments: ["Subscribed Users"],
        data: {
          announcement_id: announcement.id,
          type: "announcement",
          priority,
        },
      });
    } else {
      // Disruption targeting a specific route
      const { data: routeSubs } = await adminSupabase
        .from("notification_subscriptions")
        .select("user_id, guest_device_id, onesignal_subscription_id")
        .contains("subscribed_route_ids", [target_route_id])
        .eq("is_enabled", true);

      for (const sub of routeSubs ?? []) {
        if (sub.user_id) {
          targetUserIds.push(sub.user_id);
          externalIds.push(sub.user_id);
        } else if (sub.guest_device_id) {
          targetGuestIds.push(sub.guest_device_id);
          if (sub.onesignal_subscription_id) subIds.push(sub.onesignal_subscription_id);
        } else if (sub.onesignal_subscription_id) {
          subIds.push(sub.onesignal_subscription_id);
        }
      }

      if (externalIds.length > 0 || subIds.length > 0) {
        pushResult = await sendOneSignalNotification({
          headings: { en: `Route Alert: ${title}` },
          contents: { en: content },
          include_aliases: externalIds.length > 0 ? { external_id: externalIds } : undefined,
          include_subscription_ids: subIds.length > 0 ? subIds : undefined,
          data: {
            announcement_id: announcement.id,
            type: "disruption",
            route_id: target_route_id,
          },
        });
      } else {
        pushResult = { success: true, recipients: 0 };
      }
    }

    // 3. Persist in-app inbox notifications so messages appear in the 7-day inbox even if push fails/is denied
    const inboxEntries = [];
    for (const uid of targetUserIds) {
      inboxEntries.push({
        user_id: uid,
        announcement_id: announcement.id,
        notification_type: type === "disruption" ? "disruption" : "announcement",
        title,
        body: content,
        data: {
          priority,
          route_id: target_route_id,
        },
        expires_at: effectiveExpiresAt,
      });
    }
    for (const gid of targetGuestIds) {
      inboxEntries.push({
        guest_device_id: gid,
        announcement_id: announcement.id,
        notification_type: type === "disruption" ? "disruption" : "announcement",
        title,
        body: content,
        data: {
          priority,
          route_id: target_route_id,
        },
        expires_at: effectiveExpiresAt,
      });
    }

    if (inboxEntries.length > 0) {
      await adminSupabase.from("inbox_notifications").insert(inboxEntries);
    }

    // 4. Update announcement delivery metadata
    await adminSupabase
      .from("notification_announcements")
      .update({
        metadata: {
          priority,
          onesignal_id: pushResult.id,
          recipients: pushResult.recipients,
          errors: pushResult.errors,
          inbox_saved_count: inboxEntries.length,
        },
      })
      .eq("id", announcement.id);

    return new Response(
      JSON.stringify({
        success: true,
        announcement,
        push: pushResult,
        inbox_count: inboxEntries.length,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[send-announcement] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
