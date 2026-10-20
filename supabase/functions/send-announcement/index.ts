import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { sendOneSignalNotificationToTargets } from "../_shared/onesignal.ts";
import {
  fetchAllPages,
  type NotificationSubscription,
  partitionSubscriptionRecipients,
} from "../_shared/notification_recipients.ts";

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
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Client with caller's JWT to verify auth and admin status
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });

    // Verify caller identity
    const { data: { user }, error: userError } = await supabaseClient.auth
      .getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify admin role via RPC
    const { data: isAdmin, error: adminCheckError } = await supabaseClient.rpc(
      "is_current_user_admin",
    );
    if (adminCheckError || !isAdmin) {
      return new Response(
        JSON.stringify({
          error: "Forbidden: Caller is not an authorized administrator",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
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
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (type === "disruption" && !target_route_id) {
      return new Response(
        JSON.stringify({
          error: "Route-targeted disruption requires target_route_id",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
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

    const audienceSnapshotAt = new Date().toISOString();
    const subscriptions = await fetchAllPages<NotificationSubscription>(
      async (afterId, limit) => {
        let query = adminSupabase
          .from("notification_subscriptions")
          .select("id, user_id, guest_device_id, onesignal_subscription_id")
          .eq("is_enabled", true)
          .lte("created_at", audienceSnapshotAt);
        if (type === "disruption") {
          query = query.contains("subscribed_route_ids", [target_route_id]);
        }
        if (afterId !== null) query = query.gt("id", afterId);
        const { data, error } = await query.order("id").limit(limit);
        return { data, error };
      },
    );
    const { userIds, guestIds, externalIds, subscriptionIds } =
      partitionSubscriptionRecipients(subscriptions);

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

    // 2. Dispatch to the exact Supabase audience, in separate OneSignal target groups
    let pushResult;
    pushResult = await sendOneSignalNotificationToTargets({
      headings: type === "disruption"
        ? { en: `Update for your route: ${title}` }
        : { en: title },
      contents: { en: content },
      data: type === "disruption"
        ? {
          announcement_id: announcement.id,
          type: "disruption",
          route_id: target_route_id,
        }
        : { announcement_id: announcement.id, type: "announcement", priority },
    }, {
      externalIds,
      subscriptionIds,
      idempotencyKey: announcement.id,
    });

    // 3. Persist in-app inbox notifications so messages appear in the 7-day inbox even if push fails/is denied
    const inboxEntries = [];
    for (const uid of userIds) {
      inboxEntries.push({
        user_id: uid,
        announcement_id: announcement.id,
        notification_type: type === "disruption"
          ? "disruption"
          : "announcement",
        title,
        body: content,
        data: {
          priority,
          route_id: target_route_id,
        },
        expires_at: effectiveExpiresAt,
      });
    }
    for (const gid of guestIds) {
      inboxEntries.push({
        guest_device_id: gid,
        announcement_id: announcement.id,
        notification_type: type === "disruption"
          ? "disruption"
          : "announcement",
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
          push_accepted: pushResult.success,
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
        push_accepted: pushResult.success,
        announcement,
        push: pushResult,
        inbox_count: inboxEntries.length,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error("[send-announcement] Unexpected error:", err);
    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : String(err),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
