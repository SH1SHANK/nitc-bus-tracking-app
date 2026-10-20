import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { verifySchedulerOrServiceRole } from "../_shared/auth.ts";
import { sendOneSignalNotification } from "../_shared/onesignal.ts";

interface BoardingReminder {
  id: string;
  user_id: string | null;
  guest_device_id: string | null;
  stop_id: string;
  stop_name?: string;
  intended_leave_time: string; // HH:MM:SS
  timezone: string;
  recurrence_days: number[]; // e.g. [1, 2, 3, 4, 5] (1=Monday ... 7=Sunday)
  is_enabled: boolean;
  last_processed_date: string | null;
  last_processed_status: string;
  suppression_reason: string | null;
}

interface BusAvailabilityRow {
  bus_id: string;
  bus_number: string;
  route_id: string;
  route_name: string;
  trip_id: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  is_stale: boolean;
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

    // 2. Fetch all enabled reminders
    const { data: reminders, error: fetchError } = await adminSupabase
      .from("boarding_reminders")
      .select("*, stops(name)")
      .eq("is_enabled", true);

    if (fetchError) {
      console.error("[process-bus-reminders] Error fetching reminders:", fetchError);
      return new Response(JSON.stringify({ error: fetchError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const reminderList = (reminders || []) as (BoardingReminder & { stops?: { name: string } })[];
    const processed = [];
    const nowUtc = new Date();

    for (const rem of reminderList) {
      const tz = rem.timezone || "Asia/Kolkata";

      // 3. Evaluate current date and time in reminder's target timezone
      const formatter = new Intl.DateTimeFormat("en-US", {
        timeZone: tz,
        weekday: "short",
        hour: "numeric",
        minute: "numeric",
        second: "numeric",
        hour12: false,
      });
      const parts = formatter.formatToParts(nowUtc);
      const weekdayStr = parts.find((p) => p.type === "weekday")?.value ?? "Mon";
      const hourVal = parseInt(parts.find((p) => p.type === "hour")?.value ?? "0", 10);
      const minuteVal = parseInt(parts.find((p) => p.type === "minute")?.value ?? "0", 10);

      // ISO weekday: Monday = 1 ... Sunday = 7
      const weekdayMap: Record<string, number> = {
        Mon: 1,
        Tue: 2,
        Wed: 3,
        Thu: 4,
        Fri: 5,
        Sat: 6,
        Sun: 7,
      };
      const currentIsoWeekday = weekdayMap[weekdayStr] ?? 1;

      // Check recurrence days (default [1,2,3,4,5])
      const recurrenceDays = rem.recurrence_days ?? [1, 2, 3, 4, 5];
      if (!recurrenceDays.includes(currentIsoWeekday)) {
        continue;
      }

      // Format today's date in target timezone (YYYY-MM-DD)
      const dateParts = new Intl.DateTimeFormat("en-CA", { timeZone: tz }).formatToParts(nowUtc);
      const todayDateStr = `${dateParts.find((p) => p.type === "year")?.value}-${dateParts.find(
        (p) => p.type === "month"
      )?.value}-${dateParts.find((p) => p.type === "day")?.value}`;

      // Check if already processed/sent today
      if (rem.last_processed_date === todayDateStr && rem.last_processed_status === "sent") {
        continue;
      }

      // Parse intended leave time (HH:MM:SS)
      const timeTokens = rem.intended_leave_time.split(":");
      const leaveHour = parseInt(timeTokens[0], 10);
      const leaveMinute = parseInt(timeTokens[1], 10);
      const leaveMinutesOfDay = leaveHour * 60 + leaveMinute;

      // Notice time is 30 minutes before intended leave time
      // Total minutes calculation with circular day wrapping (1440 minutes)
      let noticeMinutesOfDay = leaveMinutesOfDay - 30;
      if (noticeMinutesOfDay < 0) {
        noticeMinutesOfDay += 1440;
      }

      const currentMinutesOfDay = hourVal * 60 + minuteVal;

      // Bounded 10-minute check window ending 2 minutes after scheduled notice time
      // Window: [notice - 10, notice + 2]
      let diff = currentMinutesOfDay - noticeMinutesOfDay;
      if (diff < -720) diff += 1440;
      if (diff > 720) diff -= 1440;

      const isInEvaluationWindow = diff >= -10 && diff <= 2;
      if (!isInEvaluationWindow) {
        continue;
      }

      // 4. Telemetry Check via RPC: check_bus_availability_for_stop
      const { data: availabilityRows, error: availError } = await adminSupabase.rpc(
        "check_bus_availability_for_stop",
        {
          p_stop_id: rem.stop_id,
          p_max_stale_seconds: 90,
        }
      );

      if (availError) {
        console.error(`[process-bus-reminders] RPC error for stop ${rem.stop_id}:`, availError);
        continue;
      }

      const activeBuses = (availabilityRows || []) as BusAvailabilityRow[];
      // Bus is available if at least one candidate bus is active, serving this stop, and not stale
      const freshBus = activeBuses.find((b) => !b.is_stale);
      const isAvailable = !!freshBus;
      const stopName = rem.stops?.name || "your stop";

      // 5. Decision Policy:
      // If no active bus is found, record suppression reason
      if (!isAvailable) {
        await adminSupabase
          .from("boarding_reminders")
          .update({
            last_processed_date: todayDateStr,
            last_processed_status: "suppressed",
            suppression_reason: "no_active_buses_for_stop",
            updated_at: new Date().toISOString(),
          })
          .eq("id", rem.id);

        processed.push({ id: rem.id, status: "suppressed_no_bus" });
        continue;
      }

      // 6. Bus is confirmed active; build reminder message
      const formattedLeaveTime = `${String(leaveHour).padStart(2, "0")}:${String(
        leaveMinute
      ).padStart(2, "0")}`;
      const title = `Boarding Reminder for ${stopName}`;
      const body = `Your intended leave time is ${formattedLeaveTime}. Bus ${freshBus.bus_number} (${freshBus.route_name}) is currently active and serving ${stopName}.`;

      let pushSucceeded = false;
      let pushResult = null;

      if (rem.user_id) {
        try {
          pushResult = await sendOneSignalNotification({
            headings: { en: title },
            contents: { en: body },
            include_aliases: { external_id: [rem.user_id] },
            data: {
              type: "reminder",
              reminder_id: rem.id,
              stop_id: rem.stop_id,
              leave_time: rem.intended_leave_time,
            },
          });
          pushSucceeded = pushResult.success;
        } catch (pushErr) {
          console.error(`[process-bus-reminders] Push failed for user ${rem.user_id}:`, pushErr);
        }

        // Add to user in-app inbox
        await adminSupabase.from("inbox_notifications").insert({
          user_id: rem.user_id,
          title,
          body,
          notification_type: "reminder",
          data: {
            reminder_id: rem.id,
            stop_id: rem.stop_id,
            leave_time: rem.intended_leave_time,
            bus_details: {
              bus_id: freshBus.bus_id,
              bus_number: freshBus.bus_number,
              route_name: freshBus.route_name,
            },
          },
        });
      } else if (rem.guest_device_id) {
        const { data: guestSub } = await adminSupabase
          .from("notification_subscriptions")
          .select("onesignal_subscription_id")
          .eq("guest_device_id", rem.guest_device_id)
          .eq("is_enabled", true)
          .single();

        if (guestSub?.onesignal_subscription_id) {
          try {
            pushResult = await sendOneSignalNotification({
              headings: { en: title },
              contents: { en: body },
              include_subscription_ids: [guestSub.onesignal_subscription_id],
              data: {
                type: "reminder",
                reminder_id: rem.id,
                stop_id: rem.stop_id,
              },
            });
            pushSucceeded = pushResult.success;
          } catch (pushErr) {
            console.error(`[process-bus-reminders] Push failed for guest ${rem.guest_device_id}:`, pushErr);
          }
        } else {
          pushSucceeded = true;
        }

        // Add to guest in-app inbox
        await adminSupabase.from("inbox_notifications").insert({
          guest_device_id: rem.guest_device_id,
          title,
          body,
          notification_type: "reminder",
          data: {
            reminder_id: rem.id,
            stop_id: rem.stop_id,
            leave_time: rem.intended_leave_time,
          },
        });
      }

      // 7. Update reminder state: mark 'sent' only if push dispatch succeeded
      if (pushSucceeded) {
        await adminSupabase
          .from("boarding_reminders")
          .update({
            last_processed_date: todayDateStr,
            last_processed_status: "sent",
            suppression_reason: null,
            updated_at: new Date().toISOString(),
          })
          .eq("id", rem.id);

        processed.push({ id: rem.id, status: "sent", push: pushResult });
      } else {
        // Transient push error: mark failed without setting last_processed_date=today so retry window can attempt again
        await adminSupabase
          .from("boarding_reminders")
          .update({
            last_processed_status: "failed",
            suppression_reason: "push_dispatch_failed",
            updated_at: new Date().toISOString(),
          })
          .eq("id", rem.id);

        processed.push({ id: rem.id, status: "failed_push_retryable" });
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        checked_count: reminderList.length,
        processed,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[process-bus-reminders] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
