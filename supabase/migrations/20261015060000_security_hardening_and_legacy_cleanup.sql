-- Migration: Security Hardening, Invariant Alignment, Legacy Cleanup and Realtime Broadcast
-- Timestamp: 20261015060000
-- 
-- 1. P0: Device Secret Invariant Alignment (>= 16 chars) in register_tracking_device and reset_device_sequence
-- 2. P2: Fix get_route_geometry fallback path_source and is_verified flags
-- 3. P2: Drop duplicate partial unique index trips_single_active_per_bus (preserving trips_one_active_per_bus)
-- 4. P2: Drop deprecated and insecure legacy RPCs
-- 5. P1: Realtime Broadcast trigger for bus_current_state (wake-up without exposing SELECT)

-- ----------------------------------------------------------------------------
-- 1. P0: register_tracking_device (Enforce 16-128 char secret length invariant)
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.register_tracking_device(text, text, text);
CREATE OR REPLACE FUNCTION public.register_tracking_device(
  p_device_id text,
  p_bus_number text,
  p_secret text,
  p_allow_reassign boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_bus_id uuid;
  v_existing_bus_id uuid;
  v_existing_bus_number text;
  v_other_active_dev text;
  v_device_pk uuid;
  v_epoch bigint;
  v_dev_h1 integer;
  v_dev_h2 integer;
  v_bus_h1 integer;
  v_bus_h2 integer;
BEGIN
  -- 1. Input Validation
  IF p_device_id IS NULL OR length(trim(p_device_id)) < 3 THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'INVALID_DEVICE_ID',
      'error', 'Device ID must be at least 3 characters'
    );
  END IF;

  IF p_secret IS NULL OR char_length(p_secret) < 16 OR char_length(p_secret) > 128 THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'WEAK_SECRET',
      'error', 'Device secret must be between 16 and 128 characters'
    );
  END IF;

  -- 2. Bus Lookup
  SELECT id INTO v_bus_id FROM public.buses WHERE bus_number = p_bus_number;
  IF v_bus_id IS NULL THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'BUS_NOT_FOUND',
      'error', 'Bus not found: ' || p_bus_number
    );
  END IF;

  -- 3. Check existing device assignment & target bus state
  SELECT d.id, d.bus_id, b.bus_number, d.current_epoch
  INTO v_device_pk, v_existing_bus_id, v_existing_bus_number, v_epoch
  FROM public.devices d
  LEFT JOIN public.buses b ON b.id = d.bus_id
  WHERE d.device_id = p_device_id;

  SELECT d.device_id INTO v_other_active_dev
  FROM public.devices d
  WHERE d.bus_id = v_bus_id AND d.is_active = true AND d.device_id <> p_device_id;

  -- 4. Acquire Global Advisory Locks in Strict Hierarchy
  -- Lock Tier 1: All involved devices ordered by hashtext() (Namespace classid 1001)
  v_dev_h1 := hashtext(p_device_id);
  IF v_other_active_dev IS NOT NULL AND v_other_active_dev <> p_device_id THEN
    v_dev_h2 := hashtext(v_other_active_dev);
    IF v_dev_h1 < v_dev_h2 THEN
      PERFORM pg_advisory_xact_lock(1001, v_dev_h1);
      PERFORM pg_advisory_xact_lock(1001, v_dev_h2);
    ELSIF v_dev_h2 < v_dev_h1 THEN
      PERFORM pg_advisory_xact_lock(1001, v_dev_h2);
      PERFORM pg_advisory_xact_lock(1001, v_dev_h1);
    ELSE
      PERFORM pg_advisory_xact_lock(1001, v_dev_h1);
    END IF;
  ELSE
    PERFORM pg_advisory_xact_lock(1001, v_dev_h1);
  END IF;

  -- Lock Tier 2: All involved buses ordered by hashtext() (Namespace classid 1002)
  v_bus_h1 := hashtext(v_bus_id::text);
  IF v_existing_bus_id IS NOT NULL AND v_existing_bus_id <> v_bus_id THEN
    v_bus_h2 := hashtext(v_existing_bus_id::text);
    IF v_bus_h1 < v_bus_h2 THEN
      PERFORM pg_advisory_xact_lock(1002, v_bus_h1);
      PERFORM pg_advisory_xact_lock(1002, v_bus_h2);
    ELSIF v_bus_h2 < v_bus_h1 THEN
      PERFORM pg_advisory_xact_lock(1002, v_bus_h2);
      PERFORM pg_advisory_xact_lock(1002, v_bus_h1);
    ELSE
      PERFORM pg_advisory_xact_lock(1002, v_bus_h1);
    END IF;
  ELSE
    PERFORM pg_advisory_xact_lock(1002, v_bus_h1);
  END IF;

  -- 5. Validate Reassignment Permissions
  IF v_device_pk IS NOT NULL AND v_existing_bus_id <> v_bus_id THEN
    IF NOT p_allow_reassign THEN
      RETURN jsonb_build_object(
        'ok', false,
        'code', 'REASSIGNMENT_CONFLICT',
        'error', 'Device ' || p_device_id || ' is already assigned to bus ' || v_existing_bus_number || '. Set p_allow_reassign=true to override.',
        'current_bus_number', v_existing_bus_number
      );
    ELSE
      -- Advance epoch upon reassignment to isolate prior sessions
      v_epoch := COALESCE(v_epoch, 1) + 1;
      -- Reset previous bus current state so it no longer references this device
      UPDATE public.bus_current_state
      SET device_id = NULL, last_seen = to_timestamp(0), updated_at = now()
      WHERE bus_id = v_existing_bus_id;
    END IF;
  ELSE
    v_epoch := COALESCE(v_epoch, 1);
  END IF;

  IF v_other_active_dev IS NOT NULL THEN
    IF NOT p_allow_reassign THEN
      RETURN jsonb_build_object(
        'ok', false,
        'code', 'BUS_ALREADY_ASSIGNED',
        'error', 'Bus ' || p_bus_number || ' already has active device ' || v_other_active_dev || '. Set p_allow_reassign=true to replace it.',
        'existing_device_id', v_other_active_dev
      );
    ELSE
      -- Deactivate previous device atomically to prevent further telemetry ingestion
      UPDATE public.devices
      SET is_active = false, updated_at = now()
      WHERE bus_id = v_bus_id AND device_id <> p_device_id;

      -- Reset target bus current state: clear sequence and set last_seen = 0 so former coordinates do NOT appear fresh
      UPDATE public.bus_current_state
      SET device_id = p_device_id, epoch = v_epoch, seq = 0, last_seen = to_timestamp(0), updated_at = now()
      WHERE bus_id = v_bus_id;
    END IF;
  END IF;

  -- 6. Upsert device record with hashed secret (Bcrypt 8 salt rounds)
  INSERT INTO public.devices (
    device_id, bus_id, credential_hash, is_active, current_epoch, updated_at
  )
  VALUES (
    p_device_id, v_bus_id, extensions.crypt(p_secret, extensions.gen_salt('bf', 8)), true, v_epoch, now()
  )
  ON CONFLICT (device_id) DO UPDATE SET
    bus_id = EXCLUDED.bus_id,
    credential_hash = EXCLUDED.credential_hash,
    is_active = true,
    current_epoch = EXCLUDED.current_epoch,
    updated_at = now()
  RETURNING id INTO v_device_pk;

  RETURN jsonb_build_object(
    'ok', true,
    'code', 'SUCCESS',
    'device_pk', v_device_pk,
    'device_id', p_device_id,
    'bus_id', v_bus_id,
    'bus_number', p_bus_number,
    'epoch', v_epoch
  );
END;
$$;

REVOKE ALL ON FUNCTION public.register_tracking_device(text, text, text, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.register_tracking_device(text, text, text, boolean) TO service_role;

-- ----------------------------------------------------------------------------
-- 2. P0: reset_device_sequence (Enforce 16-128 char secret length invariant)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reset_device_sequence(
  p_device_id text,
  p_secret text,
  p_session_id text DEFAULT NULL,
  p_reason text DEFAULT 'firmware_reboot'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_bus_id uuid;
  v_device_pk uuid;
  v_cred_hash text;
  v_cur_epoch bigint;
  v_last_session text;
  v_new_epoch bigint;
BEGIN
  IF p_device_id IS NULL OR length(trim(p_device_id)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'code', 'UNAUTHORIZED_DEVICE', 'error', 'Device identifier is required');
  END IF;

  IF p_secret IS NULL OR length(trim(p_secret)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'code', 'MISSING_CREDENTIALS', 'error', 'Device secret is required');
  END IF;

  -- 1. Tier 1: Acquire Device Advisory Lock (Namespace classid 1001) FIRST to serialize with ingestion
  PERFORM pg_advisory_xact_lock(1001, hashtext(p_device_id));

  SELECT id, bus_id, credential_hash, current_epoch, last_session_id
  INTO v_device_pk, v_bus_id, v_cred_hash, v_cur_epoch, v_last_session
  FROM public.devices
  WHERE device_id = p_device_id AND is_active = true;

  IF v_device_pk IS NULL THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'UNAUTHORIZED_DEVICE',
      'error', 'Device not found or inactive'
    );
  END IF;

  -- 2. Tier 2: Acquire Bus Advisory Lock (Namespace classid 1002) in strictly ordered hierarchy
  IF v_bus_id IS NOT NULL THEN
    PERFORM pg_advisory_xact_lock(1002, hashtext(v_bus_id::text));
  END IF;

  -- Idempotent Session Negotiation: If device retries with the same session_id (e.g. cellular network dropped response),
  -- do NOT advance epoch again; return the currently established epoch!
  IF p_session_id IS NOT NULL AND v_last_session IS NOT NULL AND v_last_session = p_session_id THEN
    RETURN jsonb_build_object(
      'ok', true,
      'code', 'SUCCESS',
      'device_id', p_device_id,
      'bus_id', v_bus_id,
      'epoch', v_cur_epoch,
      'idempotent_retry', true
    );
  END IF;

  -- Enforce secret length invariant (16 - 128 chars) after idempotency check and before Bcrypt verification
  IF p_secret IS NULL OR char_length(p_secret) < 16 OR char_length(p_secret) > 128 THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'INVALID_CREDENTIALS',
      'error', 'Invalid device credentials'
    );
  END IF;

  -- Verify credential secret strictly - reject if device credentials unconfigured or secret mismatches
  IF v_cred_hash IS NULL OR length(trim(v_cred_hash)) = 0 THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'UNCONFIGURED_CREDENTIALS',
      'error', 'Device has no configured credentials in the database'
    );
  END IF;

  IF v_cred_hash IS DISTINCT FROM extensions.crypt(p_secret, v_cred_hash) THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'INVALID_CREDENTIALS',
      'error', 'Invalid device credentials'
    );
  END IF;

  -- Advance device epoch for fresh session
  v_new_epoch := v_cur_epoch + 1;
  UPDATE public.devices
  SET current_epoch = v_new_epoch,
      last_session_id = p_session_id,
      updated_at = now()
  WHERE id = v_device_pk;

  -- Reset sequence and set new epoch on bus_current_state
  IF v_bus_id IS NOT NULL THEN
    UPDATE public.bus_current_state
    SET device_id = p_device_id, epoch = v_new_epoch, seq = 0, last_seen = to_timestamp(0), updated_at = now()
    WHERE bus_id = v_bus_id;

    -- Log audit event in bus_events
    INSERT INTO public.bus_events (bus_id, event_type, occurred_at, metadata)
    VALUES (
      v_bus_id,
      'device_sequence_reset',
      now(),
      jsonb_build_object('device_id', p_device_id, 'new_epoch', v_new_epoch, 'session_id', p_session_id, 'reason', p_reason)
    );
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'code', 'SUCCESS',
    'device_id', p_device_id,
    'bus_id', v_bus_id,
    'new_epoch', v_new_epoch,
    'idempotent_retry', false
  );
END;
$$;

REVOKE ALL ON FUNCTION public.reset_device_sequence(text, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_device_sequence(text, text, text, text) TO service_role;

-- ----------------------------------------------------------------------------
-- 3. P2: Fix get_route_geometry Fallback Flags
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_route_geometry(p_route_id uuid)
RETURNS TABLE(
  route_id uuid,
  route_code text,
  name text,
  description text,
  is_verified boolean,
  path_source text,
  geojson jsonb,
  stop_count integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $function$
DECLARE
  v_geom geometry(LineString, 4326);
  v_code text;
  v_name text;
  v_desc text;
  v_verified boolean := false;
  v_src text := 'manual';
  v_stops_count integer := 0;
BEGIN
  SELECT r.path, r.route_code, r.name, r.description, r.path_verified, r.path_source
  INTO v_geom, v_code, v_name, v_desc, v_verified, v_src
  FROM public.routes r
  WHERE r.id = p_route_id;

  -- Synthesize from stops if path geometry is not yet populated
  IF v_geom IS NULL THEN
    SELECT ST_MakeLine(s.location::geometry ORDER BY rs.sequence)
    INTO v_geom
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    WHERE rs.route_id = p_route_id;

    v_src := 'synthesized_stops';
    v_verified := false;
  END IF;

  SELECT COUNT(*) INTO v_stops_count
  FROM public.route_stops rs
  WHERE rs.route_id = p_route_id;

  RETURN QUERY
  SELECT 
    p_route_id AS route_id,
    v_code AS route_code,
    v_name AS name,
    v_desc AS description,
    v_verified AS is_verified,
    v_src AS path_source,
    ST_AsGeoJSON(v_geom)::jsonb AS geojson,
    v_stops_count AS stop_count;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_route_geometry(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_route_geometry(uuid) TO anon, authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 4. P2: Drop Duplicate Partial Unique Index on trips
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS public.trips_single_active_per_bus;

-- ----------------------------------------------------------------------------
-- 5. P2: Drop Deprecated & Insecure Legacy RPCs
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.ingest_telemetry(text, uuid, bigint, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, text, double precision, double precision);
DROP FUNCTION IF EXISTS public.nearby_buses(double precision, double precision, double precision);
DROP FUNCTION IF EXISTS public.nearest_stops(double precision, double precision, integer);
DROP FUNCTION IF EXISTS public.get_route_geometry_legacy(uuid, text);

-- ----------------------------------------------------------------------------
-- 6. P1: Realtime Broadcast Wake-Up Mechanism for bus_current_state
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_active_bus_positions_broadcast()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
BEGIN
  PERFORM realtime.send(
    jsonb_build_object(
      'bus_id', NEW.bus_id,
      'updated_at', NEW.updated_at
    ),
    'bus_state_updated',
    'active-bus-positions',
    false
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'notify_active_bus_positions_broadcast failed: %', SQLERRM;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.notify_active_bus_positions_broadcast() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.notify_active_bus_positions_broadcast() TO service_role;

DROP TRIGGER IF EXISTS trg_notify_active_bus_positions ON public.bus_current_state;
CREATE TRIGGER trg_notify_active_bus_positions
  AFTER INSERT OR UPDATE ON public.bus_current_state
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_active_bus_positions_broadcast();
