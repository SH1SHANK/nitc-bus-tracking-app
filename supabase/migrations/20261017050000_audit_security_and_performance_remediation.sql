-- ============================================================================
-- Migration: 20261017050000_audit_security_and_performance_remediation.sql
-- Audit Remediation: Security Hardening, Index Cleanup, RLS Optimization, and Egress/Bloat Prevention
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SEC-01: Revoke anon execution from sensitive SECURITY DEFINER RPCs
-- ----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.register_tracking_device(text, text, text, boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.reset_device_sequence(text, text, text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_device_active(text, boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.ingest_telemetry_packet(text, bigint, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, text, double precision, double precision, bigint) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.notify_active_bus_positions_broadcast() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.trigger_telemetry_simulation_15s() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.delete_user_account() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.change_my_username(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_my_profile(text, text, text, text, jsonb, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.complete_onboarding(text, text, text, text, jsonb, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.ensure_my_profile() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_my_profile() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_admin(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_current_user_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.log_admin_action(text, text, text, jsonb, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_get_overview() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_get_devices() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_register_device(text, text, text, boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_toggle_device_status(text, boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_rotate_device_secret(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_get_debug_trackers() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.admin_get_system_health() FROM PUBLIC, anon;

-- ----------------------------------------------------------------------------
-- 2. SEC-03: Fix mutable search_path on public.is_nitc_email
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_nitc_email(p_email text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SET search_path = pg_temp
AS $$
DECLARE
  v_clean text := trim(lower(coalesce(p_email, '')));
  v_parts text[];
BEGIN
  IF v_clean = '' THEN
    RETURN false;
  END IF;

  -- Must contain exactly one '@' delimiter (no multiple '@' allowed)
  v_parts := string_to_array(v_clean, '@');
  IF array_length(v_parts, 1) <> 2 THEN
    RETURN false;
  END IF;

  -- Local-part must not be empty
  IF v_parts[1] = '' THEN
    RETURN false;
  END IF;

  -- Domain part must match 'nitc.ac.in' or any department subdomain '*.nitc.ac.in'
  IF v_parts[2] = 'nitc.ac.in' OR v_parts[2] LIKE '%.nitc.ac.in' THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. PERF-01: Drop duplicate index on public.bus_positions
-- uq_bus_positions_device_epoch_seq already covers (device_id, epoch, seq)
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS public.idx_bus_positions_device_epoch_seq;

-- ----------------------------------------------------------------------------
-- 4. PERF-02: Add missing foreign key index on public.bus_events(stop_id)
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_bus_events_stop_id
  ON public.bus_events (stop_id)
  WHERE stop_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 5. PERF-03: Optimize public.users RLS policies with (select auth.uid())
-- Prevents re-evaluation of auth.uid() per-row by forcing an initPlan
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Allow users to read their own profile" ON public.users;
CREATE POLICY "Allow users to read their own profile"
  ON public.users FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id AND public.is_authorized_nitc_user());

DROP POLICY IF EXISTS "Allow users to update their own profile" ON public.users;
CREATE POLICY "Allow users to update their own profile"
  ON public.users FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id AND public.is_authorized_nitc_user())
  WITH CHECK ((select auth.uid()) = user_id AND public.is_authorized_nitc_user());

-- ----------------------------------------------------------------------------
-- 6. EGR-03: Add daily cleanup job for net._http_response table
-- pg_net records every HTTP response into net._http_response (4x/min = 5.7k/day)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cleanup_http_responses()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = net, pg_temp
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'net' AND table_name = '_http_response' AND column_name = 'created'
  ) THEN
    EXECUTE 'DELETE FROM net._http_response WHERE created < now() - interval ''24 hours''';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'net' AND table_name = '_http_response' AND column_name = 'created_at'
  ) THEN
    EXECUTE 'DELETE FROM net._http_response WHERE created_at < now() - interval ''24 hours''';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_http_responses() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_http_responses() TO postgres, service_role;

DO $$
BEGIN
  PERFORM cron.unschedule('cleanup-net-http-responses');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

SELECT cron.schedule(
  'cleanup-net-http-responses',
  '0 3 * * *',
  'SELECT public.cleanup_http_responses();'
);
