-- ============================================================================
-- Tracklet Migration: OneSignal & Supabase Notification System MVP
-- File: 20261020020000_notification_system_mvp.sql
-- Description:
--   1. Notification announcements table for general broadcasts and route disruptions.
--   2. User & guest device notification preferences / subscriptions table.
--   3. Boarding reminders table with 30-min lead time and weekday recurrence.
--   4. Seven-day in-app notification inbox table with read/unread tracking.
--   5. Bus arrival events table for 300m spatial approach detection and deduplication.
--   6. Row Level Security (RLS) policies enforcing user isolation and admin checks.
--   7. Spatial and relational helper RPCs for Edge Functions and scheduled workers.
--   8. Retention cleanup RPC for 7-day inbox expiration.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Notification Announcements Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notification_announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text NOT NULL,
  type text NOT NULL CHECK (type IN ('general', 'disruption')),
  route_id uuid REFERENCES public.routes(id) ON DELETE SET NULL,
  expires_at timestamptz NOT NULL,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'published' CHECK (status IN ('draft', 'published', 'expired', 'archived')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_announcements_active
  ON public.notification_announcements (status, expires_at DESC);

CREATE INDEX IF NOT EXISTS idx_announcements_route
  ON public.notification_announcements (route_id)
  WHERE route_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 2. Notification Subscriptions Table (Authenticated & Guest)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notification_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  guest_device_id text,
  onesignal_subscription_id text,
  subscribed_route_ids uuid[] NOT NULL DEFAULT '{}',
  subscribed_stop_ids uuid[] NOT NULL DEFAULT '{}',
  is_enabled boolean NOT NULL DEFAULT true,
  platform text NOT NULL DEFAULT 'android' CHECK (platform IN ('android', 'web', 'ios')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_subscription_identity CHECK (
    (user_id IS NOT NULL) OR (guest_device_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_user
  ON public.notification_subscriptions (user_id)
  WHERE user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_guest
  ON public.notification_subscriptions (guest_device_id)
  WHERE guest_device_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 3. Boarding Reminders Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.boarding_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  guest_device_id text,
  stop_id uuid NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  intended_leave_time time NOT NULL,
  recurrence_days smallint[] NOT NULL DEFAULT '{1,2,3,4,5}',
  timezone text NOT NULL DEFAULT 'Asia/Kolkata',
  is_enabled boolean NOT NULL DEFAULT true,
  last_processed_date date,
  last_processed_status text DEFAULT 'idle' CHECK (last_processed_status IN ('idle', 'sent', 'suppressed', 'failed')),
  suppression_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_reminder_identity CHECK (
    (user_id IS NOT NULL) OR (guest_device_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_reminders_active
  ON public.boarding_reminders (is_enabled, intended_leave_time)
  WHERE is_enabled = true;

CREATE INDEX IF NOT EXISTS idx_reminders_user
  ON public.boarding_reminders (user_id)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reminders_guest
  ON public.boarding_reminders (guest_device_id)
  WHERE guest_device_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 4. In-App Notification Inbox Table (7-Day Retention)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.inbox_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  guest_device_id text,
  announcement_id uuid REFERENCES public.notification_announcements(id) ON DELETE SET NULL,
  notification_type text NOT NULL CHECK (notification_type IN ('announcement', 'disruption', 'reminder', 'arrival')),
  title text NOT NULL,
  body text NOT NULL,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_read boolean NOT NULL DEFAULT false,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  CONSTRAINT chk_inbox_identity CHECK (
    (user_id IS NOT NULL) OR (guest_device_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_inbox_user_read
  ON public.inbox_notifications (user_id, is_read, created_at DESC)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_inbox_guest_read
  ON public.inbox_notifications (guest_device_id, is_read, created_at DESC)
  WHERE guest_device_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_inbox_expiry
  ON public.inbox_notifications (expires_at);

-- ----------------------------------------------------------------------------
-- 5. Bus Arrival Events Table (300m Approach Tracking & Deduplication)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bus_arrival_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bus_id uuid NOT NULL REFERENCES public.buses(id) ON DELETE CASCADE,
  stop_id uuid NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  trip_id uuid REFERENCES public.trips(id) ON DELETE SET NULL,
  approach_key text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'approaching' CHECK (status IN ('approaching', 'notified', 'departed')),
  entered_at timestamptz NOT NULL DEFAULT now(),
  notified_at timestamptz,
  exited_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_arrival_events_lookup
  ON public.bus_arrival_events (bus_id, stop_id, status);

-- ----------------------------------------------------------------------------
-- 6. Row Level Security (RLS) Policies
-- ----------------------------------------------------------------------------
ALTER TABLE public.notification_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.boarding_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inbox_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_arrival_events ENABLE ROW LEVEL SECURITY;

-- Announcements: readable by everyone, writable only by verified admins
DROP POLICY IF EXISTS "read_announcements_public" ON public.notification_announcements;
CREATE POLICY "read_announcements_public" ON public.notification_announcements
  FOR SELECT
  TO anon, authenticated
  USING (status = 'published' AND expires_at > now());

DROP POLICY IF EXISTS "admin_manage_announcements" ON public.notification_announcements;
CREATE POLICY "admin_manage_announcements" ON public.notification_announcements
  FOR ALL
  TO authenticated
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

-- Subscriptions: users manage their own, service_role has full access
DROP POLICY IF EXISTS "user_manage_own_subscription" ON public.notification_subscriptions;
CREATE POLICY "user_manage_own_subscription" ON public.notification_subscriptions
  FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Reminders: users manage their own
DROP POLICY IF EXISTS "user_manage_own_reminders" ON public.boarding_reminders;
CREATE POLICY "user_manage_own_reminders" ON public.boarding_reminders
  FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Inbox: users read and mark read their own
DROP POLICY IF EXISTS "user_manage_own_inbox" ON public.inbox_notifications;
CREATE POLICY "user_manage_own_inbox" ON public.inbox_notifications
  FOR ALL
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Bus arrival events: internal state, managed by service_role
DROP POLICY IF EXISTS "arrival_events_service_role" ON public.bus_arrival_events;
CREATE POLICY "arrival_events_service_role" ON public.bus_arrival_events
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Ensure service_role has full management privileges on all new tables
GRANT ALL ON
  public.notification_announcements,
  public.notification_subscriptions,
  public.boarding_reminders,
  public.inbox_notifications,
  public.bus_arrival_events
TO service_role;

GRANT SELECT ON
  public.notification_announcements,
  public.notification_subscriptions,
  public.boarding_reminders,
  public.inbox_notifications
TO authenticated;

GRANT SELECT ON
  public.notification_announcements
TO anon;

-- ----------------------------------------------------------------------------
-- 7. Helper RPCs for Edge Functions and Scheduled Workers
-- ----------------------------------------------------------------------------

-- Check bus availability for a specific stop on active routes (used by process-bus-reminders)
CREATE OR REPLACE FUNCTION public.check_bus_availability_for_stop(
  p_stop_id uuid,
  p_max_stale_seconds int DEFAULT 90
)
RETURNS TABLE (
  bus_id uuid,
  bus_number text,
  route_id uuid,
  route_name text,
  trip_id uuid,
  latitude double precision,
  longitude double precision,
  speed double precision,
  heading double precision,
  is_stale boolean,
  last_seen timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
  SELECT b.id AS bus_id,
         b.bus_number::text,
         r.id AS route_id,
         r.name::text AS route_name,
         c.trip_id,
         c.latitude::double precision,
         c.longitude::double precision,
         c.speed::double precision,
         c.heading::double precision,
         c.last_seen < now() - (p_max_stale_seconds || ' seconds')::interval AS is_stale,
         c.last_seen
  FROM public.bus_current_state c
  JOIN public.buses b ON b.id = c.bus_id
  JOIN public.trips t ON t.id = c.trip_id AND t.status = 'active'
  JOIN public.routes r ON r.id = t.route_id
  JOIN public.route_stops rs ON rs.route_id = r.id AND rs.stop_id = p_stop_id
  WHERE b.is_active AND NOT b.is_simulation
    AND c.last_seen > now() - interval '15 minutes'
  ORDER BY c.last_seen DESC;
$$;

-- Spatial query to detect buses within 300m of served stops along active routes
CREATE OR REPLACE FUNCTION public.get_buses_approaching_stops(
  p_radius_meters double precision DEFAULT 300.0,
  p_max_stale_seconds int DEFAULT 90
)
RETURNS TABLE (
  bus_id uuid,
  bus_number text,
  stop_id uuid,
  stop_name text,
  route_id uuid,
  route_name text,
  trip_id uuid,
  distance_meters double precision,
  speed double precision,
  heading double precision,
  last_seen timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
  SELECT b.id AS bus_id,
         b.bus_number::text,
         s.id AS stop_id,
         s.name::text AS stop_name,
         r.id AS route_id,
         r.name::text AS route_name,
         c.trip_id,
         ST_Distance(c.location, s.location)::double precision AS distance_meters,
         c.speed::double precision,
         c.heading::double precision,
         c.last_seen
  FROM public.bus_current_state c
  JOIN public.buses b ON b.id = c.bus_id
  JOIN public.trips t ON t.id = c.trip_id AND t.status = 'active'
  JOIN public.routes r ON r.id = t.route_id
  JOIN public.route_stops rs ON rs.route_id = r.id
  JOIN public.stops s ON s.id = rs.stop_id
  WHERE b.is_active AND NOT b.is_simulation
    AND c.last_seen > now() - (p_max_stale_seconds || ' seconds')::interval
    AND ST_DWithin(c.location, s.location, p_radius_meters)
  ORDER BY distance_meters ASC;
$$;

-- Atomically register approaching bus event without prematurely setting status to 'notified'
-- Returns true if this is a newly recorded arrival approach for this bus/stop/trip
CREATE OR REPLACE FUNCTION public.mark_bus_arrival_event(
  p_bus_id uuid,
  p_stop_id uuid,
  p_trip_id uuid,
  p_approach_key text
)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.bus_arrival_events (
    bus_id, stop_id, trip_id, approach_key, status, entered_at
  )
  VALUES (
    p_bus_id, p_stop_id, p_trip_id, p_approach_key, 'approaching', now()
  )
  ON CONFLICT (approach_key) DO NOTHING;

  RETURN FOUND;
END;
$$;

-- Mark arrival event as notified once OneSignal dispatch succeeds
CREATE OR REPLACE FUNCTION public.mark_bus_arrival_notified(
  p_approach_key text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.bus_arrival_events
  SET status = 'notified', notified_at = now()
  WHERE approach_key = p_approach_key AND status = 'approaching';
END;
$$;

-- Mark departed when bus moves away (> 350m) from stop
CREATE OR REPLACE FUNCTION public.mark_bus_departed_event(
  p_bus_id uuid,
  p_stop_id uuid,
  p_trip_id uuid
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.bus_arrival_events
  SET status = 'departed', exited_at = now()
  WHERE bus_id = p_bus_id AND stop_id = p_stop_id
    AND (trip_id = p_trip_id OR (trip_id IS NULL AND p_trip_id IS NULL))
    AND status IN ('approaching', 'notified');
END;
$$;

-- Guest inbox retrieval helper (restricted exclusively to service_role to avoid cross-device leakage)
CREATE OR REPLACE FUNCTION public.get_guest_inbox(p_guest_device_id text)
RETURNS SETOF public.inbox_notifications
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT * FROM public.inbox_notifications
  WHERE guest_device_id = p_guest_device_id
    AND expires_at > now()
  ORDER BY created_at DESC;
$$;

-- Cleanup task for 7-day inbox retention, expired announcements, and old arrival records
CREATE OR REPLACE FUNCTION public.cleanup_expired_notifications_and_events()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_inbox_deleted int := 0;
  v_events_deleted int := 0;
  v_announcements_expired int := 0;
BEGIN
  -- Delete inbox entries older than 7 days
  DELETE FROM public.inbox_notifications
  WHERE expires_at <= now() OR created_at < now() - interval '7 days';
  GET DIAGNOSTICS v_inbox_deleted = ROW_COUNT;

  -- Delete arrival events older than 3 days
  DELETE FROM public.bus_arrival_events
  WHERE entered_at < now() - interval '3 days';
  GET DIAGNOSTICS v_events_deleted = ROW_COUNT;

  -- Mark expired announcements
  UPDATE public.notification_announcements
  SET status = 'expired'
  WHERE status = 'published' AND expires_at <= now();
  GET DIAGNOSTICS v_announcements_expired = ROW_COUNT;

  RETURN jsonb_build_object(
    'inbox_deleted', v_inbox_deleted,
    'events_deleted', v_events_deleted,
    'announcements_expired', v_announcements_expired
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_bus_availability_for_stop(uuid, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_bus_availability_for_stop(uuid, int) TO service_role;

REVOKE ALL ON FUNCTION public.get_buses_approaching_stops(double precision, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_buses_approaching_stops(double precision, int) TO service_role;

REVOKE ALL ON FUNCTION public.mark_bus_arrival_event(uuid, uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_bus_arrival_event(uuid, uuid, uuid, text) TO service_role;

REVOKE ALL ON FUNCTION public.mark_bus_arrival_notified(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_bus_arrival_notified(text) TO service_role;

REVOKE ALL ON FUNCTION public.mark_bus_departed_event(uuid, uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_bus_departed_event(uuid, uuid, uuid) TO service_role;

REVOKE ALL ON FUNCTION public.get_guest_inbox(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_guest_inbox(text) TO service_role;

REVOKE ALL ON FUNCTION public.cleanup_expired_notifications_and_events() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_notifications_and_events() TO service_role, postgres;

-- ----------------------------------------------------------------------------
-- 8. Scheduled Workers Cron Setup
-- ----------------------------------------------------------------------------

-- Helper function to trigger notification workers with pg_net
CREATE OR REPLACE FUNCTION public.trigger_notification_worker(p_function_name text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, net, vault, extensions, pg_temp
AS $$
DECLARE
  v_secret text;
  v_gateway_jwt text;
  v_project_url text := 'https://fnngudikrvelpuhngtlw.supabase.co';
BEGIN
  SELECT decrypted_secret INTO v_secret
  FROM vault.decrypted_secrets WHERE name = 'scheduler_secret';
  SELECT decrypted_secret INTO v_gateway_jwt
  FROM vault.decrypted_secrets WHERE name = 'telemetry_simulator_gateway_jwt';

  IF coalesce(v_gateway_jwt, '') = '' THEN
    -- Fallback to service role if gateway JWT not separately stored
    SELECT decrypted_secret INTO v_gateway_jwt
    FROM vault.decrypted_secrets WHERE name = 'service_role_key';
  END IF;

  PERFORM net.http_post(
    url := v_project_url || '/functions/v1/' || p_function_name,
    body := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', coalesce(v_gateway_jwt, ''),
      'Authorization', 'Bearer ' || coalesce(v_gateway_jwt, ''),
      'x-scheduler-secret', coalesce(v_secret, '')
    ),
    timeout_milliseconds := 15000
  );
END;
$$;

REVOKE ALL ON FUNCTION public.trigger_notification_worker(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_notification_worker(text) TO postgres, service_role;

DO $$
BEGIN
  PERFORM cron.unschedule('cleanup-expired-notifications');
  PERFORM cron.unschedule('bus-arrivals-check-worker');
  PERFORM cron.unschedule('bus-reminders-check-worker');
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 1. Daily cleanup at 03:00 UTC
SELECT cron.schedule(
  'cleanup-expired-notifications',
  '0 3 * * *',
  'SELECT public.cleanup_expired_notifications_and_events();'
);

-- 2. Bus arrivals evaluation worker (every minute)
SELECT cron.schedule(
  'bus-arrivals-check-worker',
  '* * * * *',
  $$SELECT public.trigger_notification_worker('process-bus-arrivals');$$
);

-- 3. Bus boarding reminders evaluation worker (every minute)
SELECT cron.schedule(
  'bus-reminders-check-worker',
  '* * * * *',
  $$SELECT public.trigger_notification_worker('process-bus-reminders');$$
);

