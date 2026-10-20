import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { verifySchedulerOrServiceRole } from "../_shared/auth.ts";
import { sendOneSignalNotification } from "../_shared/onesignal.ts";

interface ApproachingBus {
  bus_id: string;
  bus_number: string;
  stop_id: string;
  stop_name: string;
  route_id: string;
  route_name: string;
  trip_id: string | null;
  distance_meters: number;
  speed: number;
  heading: number;
  last_seen: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // 1. Authorize: only trusted scheduler secret or service role is allowed
  const authErrorResponse = verifySchedulerOrServiceRole(req);
  if (authErrorResponse) {
    return authErrorResponse;
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const adminSupabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    });

    // 2. Query approaching buses within 300m of active stops on active routes
    // Telemetry freshness is strictly enforced by the RPC (<= 90 seconds old)
    const { data: approaches, error: approachError } = await adminSupabase.rpc(
      "get_buses_approaching_stops",
      {
        p_radius_meters: 300.0,
        p_max_stale_seconds: 90,
      }
    );

    if (approachError) {
      console.error("[process-bus-arrivals] RPC error:", approachError);
      return new Response(JSON.stringify({ error: approachError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const approachingList: ApproachingBus[] = approaches || [];
    let notificationsDispatched = 0;
    const results = [];

    // 3. For each approaching bus-stop pair, record arrival event and notify subscribers
    for (const item of approachingList) {
      // Build unique approach key per trip (or day if unassigned) to prevent duplicate alerts
      const datePrefix = new Date(item.last_seen || Date.now()).toISOString().slice(0, 10);
      const tripSegment = item.trip_id ?? `notrip-${datePrefix}`;
      const approachKey = `${item.bus_id}:${item.stop_id}:${tripSegment}`;

      // mark_bus_arrival_event handles deduplication: returns true only if newly registered
      const { data: isNewArrival, error: eventError } = await adminSupabase.rpc(
        "mark_bus_arrival_event",
        {
          p_bus_id: item.bus_id,
          p_stop_id: item.stop_id,
          p_trip_id: item.trip_id,
          p_approach_key: approachKey,
        }
      );

      if (eventError) {
        console.error("[process-bus-arrivals] Error recording arrival event:", eventError);
        continue;
      }

      if (!isNewArrival) {
        // Bus is already in approaching/notified status at this stop; deduplicated
        continue;
      }

      // 4. Find subscribers who are watching this stop or this route
      const { data: subscribers, error: subError } = await adminSupabase
        .from("notification_subscriptions")
        .select("user_id, guest_device_id, onesignal_subscription_id")
        .eq("is_enabled", true)
        .or(`subscribed_stop_ids.cs.{"${item.stop_id}"},subscribed_route_ids.cs.{"${item.route_id}"}`);

      if (subError) {
        console.error("[process-bus-arrivals] Error fetching subscribers:", subError);
        continue;
      }

      const externalIds: string[] = [];
      const subIds: string[] = [];
      const targetUserIds: string[] = [];
      const targetGuestIds: string[] = [];

      for (const sub of subscribers ?? []) {
        if (sub.user_id) {
          externalIds.push(sub.user_id);
          targetUserIds.push(sub.user_id);
        } else if (sub.guest_device_id) {
          targetGuestIds.push(sub.guest_device_id);
          if (sub.onesignal_subscription_id) {
            subIds.push(sub.onesignal_subscription_id);
          }
        } else if (sub.onesignal_subscription_id) {
          subIds.push(sub.onesignal_subscription_id);
        }
      }

      const title = `Bus Approaching ${item.stop_name}`;
      const message = `Bus ${item.bus_number} (${item.route_name}) is within ${Math.round(
        item.distance_meters
      )}m of ${item.stop_name}.`;

      // 5. Send push notification via OneSignal if recipients exist
      let pushSucceeded = false;
      let pushResult = null;

      if (externalIds.length > 0 || subIds.length > 0) {
        try {
          pushResult = await sendOneSignalNotification({
            headings: { en: title },
            contents: { en: message },
            include_aliases: externalIds.length > 0 ? { external_id: externalIds } : undefined,
            include_subscription_ids: subIds.length > 0 ? subIds : undefined,
            data: {
              type: "arrival",
              bus_id: item.bus_id,
              stop_id: item.stop_id,
              route_id: item.route_id,
            },
          });
          pushSucceeded = pushResult.success;
          if (pushSucceeded) notificationsDispatched++;
        } catch (pushErr) {
          console.error("[process-bus-arrivals] OneSignal push failed:", pushErr);
        }
      } else {
        // No external push targets registered, but still a valid arrival event
        pushSucceeded = true;
      }

      // 6. Only if push succeeded (or wasn't aborted by network/API failure), mark arrival notified and persist inbox
      if (pushSucceeded) {
        await adminSupabase.rpc("mark_bus_arrival_notified", {
          p_approach_key: approachKey,
        });

        // Insert into in-app inbox for registered users and guest devices
        const inboxEntries = [];
        for (const uid of targetUserIds) {
          inboxEntries.push({
            user_id: uid,
            title,
            body: message,
            notification_type: "arrival",
            data: {
              bus_id: item.bus_id,
              stop_id: item.stop_id,
              route_id: item.route_id,
              distance_meters: item.distance_meters,
            },
          });
        }
        for (const gid of targetGuestIds) {
          inboxEntries.push({
            guest_device_id: gid,
            title,
            body: message,
            notification_type: "arrival",
            data: {
              bus_id: item.bus_id,
              stop_id: item.stop_id,
              route_id: item.route_id,
              distance_meters: item.distance_meters,
            },
          });
        }

        if (inboxEntries.length > 0) {
          await adminSupabase.from("inbox_notifications").insert(inboxEntries);
        }

        results.push({
          bus: item.bus_number,
          stop: item.stop_name,
          recipients: externalIds.length + subIds.length,
          push: pushResult,
        });
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        approaching_count: approachingList.length,
        dispatched_count: notificationsDispatched,
        details: results,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[process-bus-arrivals] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
