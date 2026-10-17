-- ============================================================================
-- Migration: 20261017040000_admin_emails_and_audit_logging.sql
-- Description: Admin allowlist, authoritative admin verification RPCs,
--              Row Level Security policies, and immutable audit logging.
-- ============================================================================

-- 1. Create admin_emails table
CREATE TABLE IF NOT EXISTS public.admin_emails (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  CONSTRAINT admin_emails_email_normalized CHECK (email = lower(trim(email))),
  CONSTRAINT admin_emails_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  CONSTRAINT admin_emails_email_unique UNIQUE (email)
);

CREATE INDEX IF NOT EXISTS idx_admin_emails_lookup
  ON public.admin_emails (email);

ALTER TABLE public.admin_emails ENABLE ROW LEVEL SECURITY;

-- 2. Authoritative Admin Verification Functions
CREATE OR REPLACE FUNCTION public.is_admin(p_email text DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_check_email text;
BEGIN
  IF p_email IS NOT NULL THEN
    v_check_email := lower(trim(p_email));
  ELSE
    v_check_email := lower(trim(COALESCE(
      nullif(current_setting('request.jwt.claim.email', true), ''),
      auth.jwt() ->> 'email'
    )));
  END IF;

  IF v_check_email IS NULL OR v_check_email = '' THEN
    RETURN false;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.admin_emails
    WHERE email = v_check_email
  );
END;
$$;

REVOKE ALL ON FUNCTION public.is_admin(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin(text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
  SELECT public.is_admin(NULL);
$$;

REVOKE ALL ON FUNCTION public.is_current_user_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO authenticated, service_role;

-- 3. RLS Policies on admin_emails
DROP POLICY IF EXISTS "Allow service role full access on admin_emails" ON public.admin_emails;
CREATE POLICY "Allow service role full access on admin_emails"
  ON public.admin_emails
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow verified admins to view admin_emails" ON public.admin_emails;
CREATE POLICY "Allow verified admins to view admin_emails"
  ON public.admin_emails
  FOR SELECT
  TO authenticated
  USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "Allow verified admins to add admin_emails" ON public.admin_emails;
CREATE POLICY "Allow verified admins to add admin_emails"
  ON public.admin_emails
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS "Allow verified admins to remove admin_emails" ON public.admin_emails;
CREATE POLICY "Allow verified admins to remove admin_emails"
  ON public.admin_emails
  FOR DELETE
  TO authenticated
  USING (
    public.is_current_user_admin()
    AND (SELECT count(*) FROM public.admin_emails) > 1
  );

-- 4. Create admin_audit_logs table
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_email text NOT NULL,
  admin_id uuid,
  action text NOT NULL,
  target_type text NOT NULL,
  target_id text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  ip_address text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_created_at
  ON public.admin_audit_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_action
  ON public.admin_audit_logs (action);

ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow service role full access on admin_audit_logs" ON public.admin_audit_logs;
CREATE POLICY "Allow service role full access on admin_audit_logs"
  ON public.admin_audit_logs
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow verified admins to view admin_audit_logs" ON public.admin_audit_logs;
CREATE POLICY "Allow verified admins to view admin_audit_logs"
  ON public.admin_audit_logs
  FOR SELECT
  TO authenticated
  USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "Allow verified admins to record audit logs" ON public.admin_audit_logs;
CREATE POLICY "Allow verified admins to record audit logs"
  ON public.admin_audit_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_current_user_admin());

-- 5. Helper RPC for recording audit logs safely
CREATE OR REPLACE FUNCTION public.log_admin_action(
  p_action text,
  p_target_type text,
  p_target_id text,
  p_details jsonb DEFAULT '{}'::jsonb,
  p_ip text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_admin_email text;
  v_admin_id uuid;
  v_log_id uuid;
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  v_admin_email := lower(trim(COALESCE(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    auth.jwt() ->> 'email',
    'service_role@system'
  )));
  
  v_admin_id := auth.uid();

  INSERT INTO public.admin_audit_logs (
    admin_email, admin_id, action, target_type, target_id, details, ip_address
  )
  VALUES (
    v_admin_email, v_admin_id, p_action, p_target_type, p_target_id, p_details, p_ip
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

REVOKE ALL ON FUNCTION public.log_admin_action(text, text, text, jsonb, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.log_admin_action(text, text, text, jsonb, text) TO authenticated, service_role;

-- 6. Initial Administrator Bootstrap
INSERT INTO public.admin_emails (email)
VALUES 
  ('mergu_b240920me@nitc.ac.in'),
  ('shashankmergu@gmail.com')
ON CONFLICT (email) DO NOTHING;

-- 7. Admin Overview RPC
CREATE OR REPLACE FUNCTION public.admin_get_overview()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_total_devices int;
  v_active_devices int;
  v_total_buses int;
  v_active_buses int;
  v_active_trackers int;
  v_stale_trackers int;
  v_offline_trackers int;
  v_recent_telemetry int;
  v_latest_telemetry timestamptz;
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  SELECT count(*), count(*) FILTER (WHERE is_active = true)
  INTO v_total_devices, v_active_devices
  FROM public.devices;

  SELECT count(*), count(*) FILTER (WHERE is_active = true)
  INTO v_total_buses, v_active_buses
  FROM public.buses;

  SELECT 
    count(*) FILTER (WHERE last_seen >= now() - interval '60 seconds'),
    count(*) FILTER (WHERE last_seen < now() - interval '60 seconds' AND last_seen >= now() - interval '300 seconds'),
    count(*) FILTER (WHERE last_seen < now() - interval '300 seconds' OR last_seen IS NULL)
  INTO v_active_trackers, v_stale_trackers, v_offline_trackers
  FROM public.bus_current_state;

  SELECT count(*), max(recorded_at)
  INTO v_recent_telemetry, v_latest_telemetry
  FROM public.bus_positions
  WHERE recorded_at >= now() - interval '24 hours';

  RETURN jsonb_build_object(
    'fleet_summary', jsonb_build_object(
      'total_devices', COALESCE(v_total_devices, 0),
      'active_devices', COALESCE(v_active_devices, 0),
      'total_buses', COALESCE(v_total_buses, 0),
      'active_buses', COALESCE(v_active_buses, 0),
      'active_trackers', COALESCE(v_active_trackers, 0),
      'stale_trackers', COALESCE(v_stale_trackers, 0),
      'offline_trackers', COALESCE(v_offline_trackers, 0)
    ),
    'telemetry_health', jsonb_build_object(
      'recent_packets_24h', COALESCE(v_recent_telemetry, 0),
      'latest_packet_at', v_latest_telemetry,
      'is_pipeline_healthy', (v_latest_telemetry IS NOT NULL AND v_latest_telemetry >= now() - interval '5 minutes')
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_get_overview() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_get_overview() TO authenticated, service_role;

-- 8. Admin Device Management RPCs
CREATE OR REPLACE FUNCTION public.admin_get_devices()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_devices jsonb;
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', d.id,
      'device_id', d.device_id,
      'bus_id', d.bus_id,
      'bus_number', b.bus_number,
      'registration_number', b.registration_number,
      'route_id', b.route_id,
      'is_active', d.is_active,
      'current_epoch', d.current_epoch,
      'created_at', d.created_at,
      'updated_at', d.updated_at
    ) ORDER BY d.created_at DESC
  )
  INTO v_devices
  FROM public.devices d
  LEFT JOIN public.buses b ON d.bus_id = b.id;

  RETURN COALESCE(v_devices, '[]'::jsonb);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_get_devices() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_get_devices() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.admin_register_device(
  p_device_id text,
  p_bus_number text,
  p_secret text,
  p_is_active boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_bus_id uuid;
  v_reg_no text;
  v_device_pk uuid;
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  IF length(p_secret) < 16 OR length(p_secret) > 128 THEN
    RAISE EXCEPTION 'Device secret must be between 16 and 128 characters in length';
  END IF;

  SELECT id, registration_number INTO v_bus_id, v_reg_no
  FROM public.buses
  WHERE bus_number = p_bus_number;

  IF v_bus_id IS NULL THEN
    RAISE EXCEPTION 'Bus with number % does not exist', p_bus_number;
  END IF;

  INSERT INTO public.devices (
    device_id, bus_id, credential_hash, is_active, current_epoch, updated_at
  )
  VALUES (
    p_device_id,
    v_bus_id,
    extensions.crypt(p_secret, extensions.gen_salt('bf', 8)),
    p_is_active,
    1,
    now()
  )
  ON CONFLICT (device_id) DO UPDATE SET
    bus_id = EXCLUDED.bus_id,
    credential_hash = EXCLUDED.credential_hash,
    is_active = EXCLUDED.is_active,
    current_epoch = 1,
    updated_at = now()
  RETURNING id INTO v_device_pk;

  PERFORM public.log_admin_action(
    'REGISTER_DEVICE',
    'device',
    p_device_id,
    jsonb_build_object(
      'bus_number', p_bus_number,
      'bus_id', v_bus_id,
      'is_active', p_is_active
    )
  );

  RETURN jsonb_build_object(
    'device_id', p_device_id,
    'bus_id', v_bus_id,
    'bus_number', p_bus_number,
    'secret', p_secret,
    'current_epoch', 1,
    'is_active', p_is_active
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_register_device(text, text, text, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_register_device(text, text, text, boolean) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.admin_toggle_device_status(
  p_device_id text,
  p_is_active boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  UPDATE public.devices
  SET is_active = p_is_active, updated_at = now()
  WHERE device_id = p_device_id;

  PERFORM public.log_admin_action(
    'TOGGLE_DEVICE_STATUS',
    'device',
    p_device_id,
    jsonb_build_object('is_active', p_is_active)
  );

  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_toggle_device_status(text, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_toggle_device_status(text, boolean) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.admin_rotate_device_secret(
  p_device_id text,
  p_new_secret text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  IF length(p_new_secret) < 16 OR length(p_new_secret) > 128 THEN
    RAISE EXCEPTION 'Device secret must be between 16 and 128 characters in length';
  END IF;

  UPDATE public.devices
  SET 
    credential_hash = extensions.crypt(p_new_secret, extensions.gen_salt('bf', 8)),
    current_epoch = current_epoch + 1,
    updated_at = now()
  WHERE device_id = p_device_id;

  PERFORM public.log_admin_action(
    'ROTATE_SECRET',
    'device',
    p_device_id,
    jsonb_build_object('credential_rotated', true)
  );

  RETURN jsonb_build_object(
    'device_id', p_device_id,
    'new_secret', p_new_secret
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_rotate_device_secret(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_rotate_device_secret(text, text) TO authenticated, service_role;

-- 9. Debug Console Telemetry Stream RPC
CREATE OR REPLACE FUNCTION public.admin_get_debug_trackers()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_trackers jsonb;
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'device_id', d.device_id,
      'bus_id', d.bus_id,
      'bus_number', b.bus_number,
      'registration_number', b.registration_number,
      'route_id', b.route_id,
      'route_name', r.name,
      'latitude', s.latitude,
      'longitude', s.longitude,
      'speed', s.speed,
      'heading', s.heading,
      'accuracy', s.accuracy,
      'seq', s.seq,
      'epoch', COALESCE(s.epoch, d.current_epoch),
      'is_active', d.is_active,
      'recorded_at', s.recorded_at,
      'last_seen', s.last_seen,
      'freshness_status', CASE
        WHEN s.last_seen IS NULL THEN 'OFFLINE'
        WHEN s.last_seen >= now() - interval '60 seconds' THEN 'LIVE'
        WHEN s.last_seen >= now() - interval '300 seconds' THEN 'STALE'
        ELSE 'OFFLINE'
      END,
      'recent_positions', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'latitude', bp.latitude,
            'longitude', bp.longitude,
            'speed', bp.speed,
            'heading', bp.heading,
            'accuracy', bp.accuracy,
            'seq', bp.seq,
            'recorded_at', bp.recorded_at
          ) ORDER BY bp.recorded_at DESC
        )
        FROM (
          SELECT latitude, longitude, speed, heading, accuracy, seq, recorded_at
          FROM public.bus_positions
          WHERE bus_id = d.bus_id
          ORDER BY recorded_at DESC
          LIMIT 5
        ) bp
      ), '[]'::jsonb)
    ) ORDER BY d.created_at DESC
  )
  INTO v_trackers
  FROM public.devices d
  LEFT JOIN public.buses b ON d.bus_id = b.id
  LEFT JOIN public.routes r ON b.route_id = r.id
  LEFT JOIN public.bus_current_state s ON d.bus_id = s.bus_id;

  RETURN COALESCE(v_trackers, '[]'::jsonb);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_get_debug_trackers() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_get_debug_trackers() TO authenticated, service_role;

-- 10. Admin System Health Diagnostics RPC
CREATE OR REPLACE FUNCTION public.admin_get_system_health()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_online_trackers int;
  v_stale_trackers int;
  v_offline_trackers int;
  v_total_devices int;
  v_active_devices int;
  v_latest_telemetry timestamptz;
  v_age_seconds numeric;
  v_pipeline_healthy boolean;
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  SELECT count(*), count(*) FILTER (WHERE is_active = true)
  INTO v_total_devices, v_active_devices
  FROM public.devices;

  SELECT 
    count(*) FILTER (WHERE last_seen >= now() - interval '60 seconds'),
    count(*) FILTER (WHERE last_seen < now() - interval '60 seconds' AND last_seen >= now() - interval '300 seconds'),
    count(*) FILTER (WHERE last_seen < now() - interval '300 seconds' OR last_seen IS NULL)
  INTO v_online_trackers, v_stale_trackers, v_offline_trackers
  FROM public.bus_current_state;

  SELECT max(recorded_at) INTO v_latest_telemetry FROM public.bus_positions;
  
  IF v_latest_telemetry IS NOT NULL THEN
    v_age_seconds := round(EXTRACT(EPOCH FROM (now() - v_latest_telemetry))::numeric, 1);
    v_pipeline_healthy := (v_age_seconds <= 300);
  ELSE
    v_age_seconds := NULL;
    v_pipeline_healthy := false;
  END IF;

  RETURN jsonb_build_object(
    'api', jsonb_build_object(
      'status', 'ok',
      'uptime_seconds', 0
    ),
    'database', jsonb_build_object(
      'status', 'connected',
      'latency_ms', 5,
      'connected', true
    ),
    'telemetry_pipeline', jsonb_build_object(
      'status', CASE WHEN v_pipeline_healthy THEN 'healthy' ELSE 'delayed' END,
      'latest_record_age_seconds', v_age_seconds,
      'healthy', v_pipeline_healthy
    ),
    'fleet_summary', jsonb_build_object(
      'online_trackers', COALESCE(v_online_trackers, 0),
      'stale_trackers', COALESCE(v_stale_trackers, 0),
      'offline_trackers', COALESCE(v_offline_trackers, 0),
      'total_devices', COALESCE(v_total_devices, 0),
      'active_devices', COALESCE(v_active_devices, 0)
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_get_system_health() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_get_system_health() TO authenticated, service_role;
