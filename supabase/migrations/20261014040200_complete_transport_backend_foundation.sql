-- ============================================================================
-- Tracklet Migration: Complete Supabase Backend Foundation
-- File: 20261014040200_complete_transport_backend_foundation.sql
-- Description:
--   1. Reconcile canonical route codes (R1, R2) for active routes.
--   2. Fix public.set_updated_at() security definer advisor finding.
--   3. Harden table privileges with principle of least privilege.
--   4. Refine Row Level Security (RLS) policies for anon & authenticated roles.
--   5. Add foreign-key, performance, and integrity constraints.
--   6. Add epoch/session columns to devices, bus_positions, and bus_current_state.
--   7. Upgrade get_active_bus_positions() with explicit freshness semantics (is_stale).
--   8. Implement atomic, secure telemetry ingestion RPC: ingest_telemetry_packet().
--   9. Implement administrative device management helper: register_tracking_device().
--  10. Implement administrative device deactivation helper: set_device_active().
--  11. Implement audited sequence & epoch reset protocol: reset_device_sequence().
--  12. Ensure public.bus_current_state is in supabase_realtime publication.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Canonical Route Alignment
-- ----------------------------------------------------------------------------
UPDATE public.routes
SET
  route_code = CASE
    WHEN id = '10000000-0000-4000-8000-000000000001' THEN 'R1'
    WHEN id = '20000000-0000-4000-8000-000000000002' THEN 'R2'
    ELSE route_code
  END,
  updated_at = now()
WHERE id IN (
  '10000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000002'
);

-- ----------------------------------------------------------------------------
-- 2. Security Advisor Remediation: Switch set_updated_at() to SECURITY INVOKER
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. Least-Privilege Grants for Exposed Client Roles (anon, authenticated)
-- ----------------------------------------------------------------------------
-- Revoke all blanket write privileges from anon and authenticated
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON
  public.routes,
  public.stops,
  public.route_stops,
  public.route_geometries,
  public.buses,
  public.bus_timings,
  public.bus_current_state,
  public.bus_positions,
  public.bus_events,
  public.trips,
  public.devices
FROM anon, authenticated;

-- Grant strictly SELECT on public transport data tables
GRANT SELECT ON
  public.routes,
  public.stops,
  public.route_stops,
  public.route_geometries,
  public.buses,
  public.bus_timings,
  public.bus_current_state,
  public.trips
TO anon, authenticated;

-- Devices table contains credentials: completely revoke from anon & authenticated
REVOKE ALL ON public.devices FROM anon, authenticated;

-- Ensure service_role has full management access on all tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;

-- ----------------------------------------------------------------------------
-- 4. Row Level Security (RLS) Hardening
-- ----------------------------------------------------------------------------
-- Ensure RLS is active on all transport tables
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_geometries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_timings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_current_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- Preserve separate RLS policies for bus_current_state
DROP POLICY IF EXISTS "read_bus_current_state" ON public.bus_current_state;
DROP POLICY IF EXISTS "read_bus_current_state_anon" ON public.bus_current_state;
CREATE POLICY "read_bus_current_state" ON public.bus_current_state
  FOR SELECT
  TO authenticated
  USING (true);
CREATE POLICY "read_bus_current_state_anon" ON public.bus_current_state
  FOR SELECT
  TO anon
  USING (true);

-- Ensure read_trips allows anon as well as authenticated (for schedule/trip viewing)
DROP POLICY IF EXISTS "read_trips" ON public.trips;
DROP POLICY IF EXISTS "read_trips_public" ON public.trips;
CREATE POLICY "read_trips_public" ON public.trips
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Ensure bus_positions is only readable by authenticated users or service_role
DROP POLICY IF EXISTS "Allow authenticated read on bus_positions" ON public.bus_positions;
DROP POLICY IF EXISTS "read_bus_positions" ON public.bus_positions;
CREATE POLICY "Allow authenticated read on bus_positions" ON public.bus_positions
  FOR SELECT
  TO authenticated
  USING (true);

-- Devices: only accessible by service_role
DROP POLICY IF EXISTS "Allow service role full access on devices" ON public.devices;
CREATE POLICY "Allow service role full access on devices" ON public.devices
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- 5. Foreign Key, Operational & Integrity Constraints
-- ----------------------------------------------------------------------------
-- Add sequence epoch columns to support persistent hardware session tracking across reboots
ALTER TABLE public.devices
  ADD COLUMN IF NOT EXISTS current_epoch bigint NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS last_session_id text;

ALTER TABLE public.bus_positions
  ADD COLUMN IF NOT EXISTS device_id text,
  ADD COLUMN IF NOT EXISTS epoch bigint NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS status text;

ALTER TABLE public.bus_current_state
  ADD COLUMN IF NOT EXISTS device_id text,
  ADD COLUMN IF NOT EXISTS epoch bigint NOT NULL DEFAULT 1;

-- Backfill any historical bus_positions rows with null device_id before enforcing constraints
-- To guarantee zero unique collisions across legacy rows:
--   1. device_id is assigned deterministic 'LEGACY-' || bus_id::text
--   2. epoch is set to 0 (reserving epoch >= 1 for active hardware trackers)
--   3. seq is set to the row's unique identity primary key 'id'
UPDATE public.bus_positions
SET device_id = 'LEGACY-' || bus_id::text,
    epoch = 0,
    seq = id
WHERE device_id IS NULL;

ALTER TABLE public.bus_positions
  ALTER COLUMN device_id SET NOT NULL;

-- Drop legacy (bus_id, recorded_at) constraint in favor of canonical (device_id, epoch, seq) packet identity
ALTER TABLE public.bus_positions
  DROP CONSTRAINT IF EXISTS bus_positions_bus_id_recorded_at_key;

ALTER TABLE public.bus_positions
  DROP CONSTRAINT IF EXISTS uq_bus_positions_device_epoch_seq;

ALTER TABLE public.bus_positions
  ADD CONSTRAINT uq_bus_positions_device_epoch_seq UNIQUE (device_id, epoch, seq);

CREATE INDEX IF NOT EXISTS idx_bus_current_state_trip_id
  ON public.bus_current_state (trip_id)
  WHERE trip_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_bus_positions_bus_seq
  ON public.bus_positions (bus_id, seq DESC);

CREATE INDEX IF NOT EXISTS idx_bus_positions_device_epoch_seq
  ON public.bus_positions (device_id, epoch, seq DESC);

CREATE INDEX IF NOT EXISTS idx_trips_route_status
  ON public.trips (route_id, status);

CREATE INDEX IF NOT EXISTS idx_buses_active
  ON public.buses (is_active)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_routes_active
  ON public.routes (is_active)
  WHERE is_active = true;

-- Ensure at most one active device per bus to prevent multi-device hardware races
CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_single_active_bus
  ON public.devices (bus_id)
  WHERE is_active = true;

-- Ensure at most one active trip per bus at database constraint level
CREATE UNIQUE INDEX IF NOT EXISTS trips_single_active_per_bus
  ON public.trips (bus_id)
  WHERE status = 'active';

-- ----------------------------------------------------------------------------
-- 6. Upgraded get_active_bus_positions() with Explicit Freshness
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_active_bus_positions();
CREATE OR REPLACE FUNCTION public.get_active_bus_positions()
RETURNS TABLE (
  bus_id uuid,
  bus_number text,
  display_name text,
  trip_id uuid,
  route_id uuid,
  route_name text,
  latitude double precision,
  longitude double precision,
  speed double precision,
  heading double precision,
  status text,
  last_seen timestamp with time zone,
  recorded_at timestamp with time zone,
  is_stale boolean
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions, pg_temp
AS $$
  SELECT 
    b.id AS bus_id,
    b.bus_number::text,
    b.display_name::text,
    c.trip_id,
    COALESCE(t.route_id, (
      SELECT tr.route_id 
      FROM public.trips tr 
      WHERE tr.bus_id = b.id 
      ORDER BY tr.started_at DESC NULLS LAST, tr.created_at DESC 
      LIMIT 1
    )) AS route_id,
    COALESCE(r.name::text, (
      SELECT r2.name::text 
      FROM public.trips tr2 
      JOIN public.routes r2 ON r2.id = tr2.route_id
      WHERE tr2.bus_id = b.id 
      ORDER BY tr2.started_at DESC NULLS LAST, tr2.created_at DESC 
      LIMIT 1
    )) AS route_name,
    c.latitude::double precision,
    c.longitude::double precision,
    c.speed::double precision,
    c.heading::double precision,
    c.status::text,
    c.last_seen,
    c.recorded_at,
    (c.last_seen < now() - interval '90 seconds') AS is_stale
  FROM public.bus_current_state c
  JOIN public.buses b ON b.id = c.bus_id
  LEFT JOIN public.trips t ON t.id = c.trip_id
  LEFT JOIN public.routes r ON r.id = t.route_id
  WHERE b.is_active
    AND c.last_seen > now() - interval '15 minutes'
  ORDER BY b.bus_number ASC;
$$;

GRANT EXECUTE ON FUNCTION public.get_active_bus_positions() TO anon, authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 7. Production-Ready Atomic Telemetry Ingestion RPC
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.ingest_telemetry_packet(text, bigint, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, text, double precision, double precision);
CREATE OR REPLACE FUNCTION public.ingest_telemetry_packet(
  p_device_id text,
  p_seq bigint,
  p_timestamp timestamp with time zone,
  p_latitude numeric,
  p_longitude numeric,
  p_speed numeric DEFAULT NULL,
  p_heading numeric DEFAULT NULL,
  p_accuracy numeric DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_stop_radius_m double precision DEFAULT 50.0,
  p_deviation_m double precision DEFAULT 500.0,
  p_epoch bigint DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_device_pk uuid;
  v_bus_id uuid;
  v_bus_is_active boolean;
  v_dev_epoch bigint;
  v_epoch bigint;
  v_current_seq bigint;
  v_current_recorded_at timestamp with time zone;
  v_cur_dev text;
  v_cur_epoch bigint;
  v_hist_recorded_at timestamp with time zone;
  v_hist_lat numeric;
  v_hist_lon numeric;
  v_hist_speed numeric;
  v_hist_heading numeric;
  v_hist_accuracy numeric;
  v_hist_status text;
  v_canon_lat numeric;
  v_canon_lon numeric;
  v_canon_speed numeric;
  v_canon_heading numeric;
  v_canon_accuracy numeric;
  v_is_exact_retry boolean := false;
  v_active_trip_count integer;
  v_trip_id uuid;
  v_route_id uuid;
  v_point extensions.geography;
  v_rows_pos integer := 0;
  v_rows_state integer := 0;
  v_status text;
  v_heading numeric;
  v_stop_radius_m double precision;
  v_deviation_m double precision;
  v_events jsonb := '[]'::jsonb;
  v_batch jsonb;
  v_path extensions.geography;
  v_dist double precision;
BEGIN
  -- 0. Concurrency Protection & Scoped Namespace Advisory Locks
  IF p_device_id IS NULL OR length(trim(p_device_id)) = 0 THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'UNAUTHORIZED_DEVICE',
      'error', 'Device identifier is required'
    );
  END IF;

  -- Lock 1: Device critical section (Namespace classid 1001)
  PERFORM pg_advisory_xact_lock(1001, hashtext(p_device_id));

  -- 1. Device Authorization & Bus Resolution
  SELECT d.id, d.bus_id, b.is_active, d.current_epoch
  INTO v_device_pk, v_bus_id, v_bus_is_active, v_dev_epoch
  FROM public.devices d
  LEFT JOIN public.buses b ON b.id = d.bus_id
  WHERE d.device_id = p_device_id AND d.is_active = true;

  IF v_device_pk IS NULL THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'UNAUTHORIZED_DEVICE',
      'error', 'Device is not registered or is inactive'
    );
  END IF;

  IF v_bus_id IS NULL THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'UNAUTHORIZED_DEVICE',
      'error', 'Device is not assigned to a bus'
    );
  END IF;

  IF NOT COALESCE(v_bus_is_active, false) THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'INACTIVE_BUS',
      'error', 'Assigned bus is currently marked inactive'
    );
  END IF;

  -- Epoch Authorization Validation: Telemetry packets CANNOT unilaterally advance epoch
  IF p_epoch IS NOT NULL THEN
    IF p_epoch < v_dev_epoch THEN
      RETURN jsonb_build_object(
        'ok', false,
        'code', 'STALE_EPOCH_PACKET',
        'error', 'Packet belongs to a previous session epoch and cannot overwrite newer state',
        'current_epoch', v_dev_epoch,
        'submitted_epoch', p_epoch
      );
    ELSIF p_epoch > v_dev_epoch THEN
      RETURN jsonb_build_object(
        'ok', false,
        'code', 'UNAUTHORIZED_EPOCH',
        'error', 'Packet epoch exceeds authorized device epoch. Device must invoke reset_device_sequence() to negotiate a new session epoch.',
        'authorized_epoch', v_dev_epoch,
        'submitted_epoch', p_epoch
      );
    END IF;
    v_epoch := p_epoch;
  ELSE
    -- Legacy/backward-compatible devices without explicit epoch default to authorized device epoch
    v_epoch := v_dev_epoch;
  END IF;

  -- Lock 2: Bus critical section (Namespace classid 1002, strictly ordered after Device lock)
  PERFORM pg_advisory_xact_lock(1002, hashtext(v_bus_id::text));

  -- 2. Sequence Validation
  IF p_seq IS NULL OR p_seq < 0 THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'INVALID_SEQUENCE',
      'error', 'Packet sequence must be a non-negative integer'
    );
  END IF;

  -- 3. Telemetry Invariant Validation
  -- Latitude & Longitude (Regional transit plausibility corridor: Kozhikode / NITC transit area)
  IF p_latitude IS NULL OR p_latitude < 11.200000 OR p_latitude > 11.450000 OR
     p_longitude IS NULL OR p_longitude < 75.800000 OR p_longitude > 76.100000 THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'COORDINATES_OUT_OF_BOUNDS',
      'error', 'Latitude or longitude outside valid regional transit bounds'
    );
  END IF;

  -- Speed (0 to 120 km/h)
  IF p_speed IS NOT NULL AND (p_speed < 0 OR p_speed > 120) THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'INVALID_SPEED',
      'error', 'Speed must be between 0 and 120 km/h'
    );
  END IF;

  -- Heading (0 to 360 degrees)
  IF p_heading IS NOT NULL THEN
    IF p_heading < 0 OR p_heading > 360 THEN
      RETURN jsonb_build_object(
        'ok', false,
        'code', 'INVALID_HEADING',
        'error', 'Heading must be between 0 and 360 degrees'
      );
    END IF;
    -- Normalize 360 to 0
    v_heading := CASE WHEN p_heading = 360.0 THEN 0.0 ELSE p_heading END;
  ELSE
    v_heading := NULL;
  END IF;

  -- Accuracy (0 to 500 meters)
  IF p_accuracy IS NOT NULL AND (p_accuracy < 0 OR p_accuracy > 500) THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'INVALID_ACCURACY',
      'error', 'Accuracy must be between 0 and 500 meters'
    );
  END IF;

  -- Timestamp plausibility (not older than 15 minutes, not > 1 minute in future)
  IF p_timestamp IS NULL OR p_timestamp < (now() - interval '15 minutes') OR p_timestamp > (now() + interval '1 minute') THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'IMPLAUSIBLE_TIMESTAMP',
      'error', 'Packet timestamp is either too old (>15m) or future-dated (>1m)'
    );
  END IF;

  -- Clamp stop radius and deviation thresholds server-side
  v_stop_radius_m := GREATEST(20.0, LEAST(COALESCE(p_stop_radius_m, 50.0), 100.0));
  v_deviation_m := GREATEST(100.0, LEAST(COALESCE(p_deviation_m, 500.0), 1000.0));

  -- Determine bus movement status if not explicitly provided
  v_status := COALESCE(
    NULLIF(lower(trim(p_status)), ''),
    CASE WHEN COALESCE(p_speed, 0) >= 3.0 THEN 'moving' ELSE 'stationary' END
  );
  IF v_status NOT IN ('moving', 'stationary', 'delayed', 'maintenance') THEN
    v_status := CASE WHEN COALESCE(p_speed, 0) >= 3.0 THEN 'moving' ELSE 'stationary' END;
  END IF;

  -- Compute canonicalized values for consistent storage and comparison
  v_canon_lat := round(p_latitude::numeric, 6);
  v_canon_lon := round(p_longitude::numeric, 6);
  v_canon_speed := CASE WHEN p_speed IS NOT NULL THEN round(p_speed::numeric, 2) ELSE NULL END;
  v_canon_heading := CASE WHEN v_heading IS NOT NULL THEN round(v_heading::numeric, 2) ELSE NULL END;
  v_canon_accuracy := CASE WHEN p_accuracy IS NOT NULL THEN round(p_accuracy::numeric, 2) ELSE NULL END;

  -- 4. Row-Level Lock on bus_current_state & Epoch/Sequence Monotonicity Check
  SELECT seq, recorded_at, trip_id, device_id, epoch
  INTO v_current_seq, v_current_recorded_at, v_trip_id, v_cur_dev, v_cur_epoch
  FROM public.bus_current_state
  WHERE bus_id = v_bus_id
  FOR UPDATE;

  -- Verify session epoch & sequence against current state
  IF v_cur_dev IS NOT NULL AND v_cur_dev = p_device_id THEN
    -- Check for stale epoch (packet from an older boot session)
    IF v_cur_epoch IS NOT NULL AND v_epoch < v_cur_epoch THEN
      RETURN jsonb_build_object(
        'ok', false,
        'code', 'STALE_EPOCH_PACKET',
        'error', 'Packet belongs to a previous session epoch and cannot overwrite newer state',
        'current_epoch', v_cur_epoch,
        'submitted_epoch', v_epoch
      );
    END IF;

    -- Within the same epoch: check sequence
    IF v_cur_epoch IS NOT NULL AND v_epoch = v_cur_epoch AND v_current_seq IS NOT NULL AND p_seq <= v_current_seq THEN
      -- Historical deduplication check on exact (device_id, epoch, seq)
      SELECT recorded_at, latitude, longitude, speed, heading, accuracy, status
      INTO v_hist_recorded_at, v_hist_lat, v_hist_lon, v_hist_speed, v_hist_heading, v_hist_accuracy, v_hist_status
      FROM public.bus_positions
      WHERE device_id = p_device_id AND epoch = v_epoch AND seq = p_seq
      ORDER BY recorded_at DESC
      LIMIT 1;

      IF v_hist_recorded_at IS NOT NULL THEN
        -- Comprehensive deterministic canonical equality across ALL 7 identity fields
        -- Handles nullability and floating-point/numeric rounding safely using IS NOT DISTINCT FROM
        v_is_exact_retry := (
          (p_timestamp IS NOT DISTINCT FROM v_hist_recorded_at)
          AND (v_canon_lat IS NOT DISTINCT FROM round(v_hist_lat::numeric, 6))
          AND (v_canon_lon IS NOT DISTINCT FROM round(v_hist_lon::numeric, 6))
          AND (v_canon_speed IS NOT DISTINCT FROM CASE WHEN v_hist_speed IS NOT NULL THEN round(v_hist_speed::numeric, 2) ELSE NULL END)
          AND (v_canon_heading IS NOT DISTINCT FROM CASE WHEN v_hist_heading IS NOT NULL THEN round(v_hist_heading::numeric, 2) ELSE NULL END)
          AND (v_canon_accuracy IS NOT DISTINCT FROM CASE WHEN v_hist_accuracy IS NOT NULL THEN round(v_hist_accuracy::numeric, 2) ELSE NULL END)
          AND (v_status IS NOT DISTINCT FROM v_hist_status)
        );

        IF v_is_exact_retry THEN
          UPDATE public.devices SET last_seen = now(), updated_at = now() WHERE id = v_device_pk;
          RETURN jsonb_build_object(
            'ok', true,
            'code', 'DUPLICATE_PACKET',
            'stored', false,
            'bus_id', v_bus_id,
            'trip_id', v_trip_id,
            'events', '[]'::jsonb
          );
        ELSE
          RETURN jsonb_build_object(
            'ok', false,
            'code', 'SEQUENCE_REUSE_CONFLICT',
            'error', 'Sequence number was previously used with conflicting telemetry data',
            'device_id', p_device_id,
            'epoch', v_epoch,
            'seq', p_seq,
            'historical_timestamp', v_hist_recorded_at
          );
        END IF;
      ELSE
        RETURN jsonb_build_object(
          'ok', false,
          'code', 'OUT_OF_ORDER_PACKET',
          'error', 'Packet sequence is older than currently accepted state',
          'current_seq', v_current_seq,
          'submitted_seq', p_seq
        );
      END IF;
    END IF;

    -- Timestamp progression check within the same epoch (only applicable once packets have been recorded in this epoch)
    IF v_cur_epoch IS NOT NULL AND v_epoch = v_cur_epoch AND COALESCE(v_current_seq, 0) > 0 AND v_current_recorded_at IS NOT NULL AND p_timestamp < v_current_recorded_at THEN
      RETURN jsonb_build_object(
        'ok', false,
        'code', 'IMPLAUSIBLE_TIMESTAMP',
        'error', 'Packet timestamp cannot regress earlier than current state',
        'current_recorded_at', v_current_recorded_at,
        'submitted_timestamp', p_timestamp
      );
    END IF;
  END IF;

  -- 5. Active Trip Integrity & Resolution
  SELECT count(*)
  INTO v_active_trip_count
  FROM public.trips
  WHERE bus_id = v_bus_id AND status = 'active';

  IF v_active_trip_count > 1 THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'AMBIGUOUS_ACTIVE_TRIP',
      'error', 'Multiple active trips found for bus ' || v_bus_id::text || '. Database integrity must be reconciled.',
      'active_trip_count', v_active_trip_count
    );
  ELSIF v_active_trip_count = 1 THEN
    SELECT id, route_id INTO v_trip_id, v_route_id
    FROM public.trips
    WHERE bus_id = v_bus_id AND status = 'active'
    LIMIT 1;
  ELSE
    v_trip_id := NULL;
    v_route_id := NULL;
  END IF;

  v_point := extensions.st_setsrid(extensions.st_makepoint(p_longitude::float8, p_latitude::float8), 4326)::extensions.geography;

  -- 6. Insert History (bus_positions) - Deduplicated on canonical packet identity (device_id, epoch, seq)
  INSERT INTO public.bus_positions (
    bus_id, trip_id, device_id, epoch, latitude, longitude, speed, heading, accuracy, status, seq, recorded_at, received_at
  )
  VALUES (
    v_bus_id, v_trip_id, p_device_id, v_epoch, v_canon_lat, v_canon_lon, v_canon_speed, v_canon_heading, v_canon_accuracy, v_status, p_seq, p_timestamp, now()
  )
  ON CONFLICT (device_id, epoch, seq) DO NOTHING;

  GET DIAGNOSTICS v_rows_pos = ROW_COUNT;

  -- 7. Upsert Current State (bus_current_state) atomically
  INSERT INTO public.bus_current_state (
    bus_id, trip_id, device_id, epoch, latitude, longitude, speed, heading, accuracy, seq, status, recorded_at, last_seen, updated_at
  )
  VALUES (
    v_bus_id, v_trip_id, p_device_id, v_epoch, v_canon_lat, v_canon_lon, v_canon_speed, v_canon_heading, v_canon_accuracy, p_seq, v_status, p_timestamp, now(), now()
  )
  ON CONFLICT (bus_id) DO UPDATE SET
    trip_id = EXCLUDED.trip_id,
    device_id = EXCLUDED.device_id,
    epoch = EXCLUDED.epoch,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    speed = EXCLUDED.speed,
    heading = EXCLUDED.heading,
    accuracy = EXCLUDED.accuracy,
    seq = EXCLUDED.seq,
    status = EXCLUDED.status,
    recorded_at = EXCLUDED.recorded_at,
    last_seen = now(),
    updated_at = now()
  WHERE bus_current_state.device_id <> EXCLUDED.device_id
     OR bus_current_state.epoch < EXCLUDED.epoch
     OR (bus_current_state.epoch = EXCLUDED.epoch AND bus_current_state.seq < EXCLUDED.seq);

  GET DIAGNOSTICS v_rows_state = ROW_COUNT;

  -- Update device metadata
  UPDATE public.devices
  SET last_seen = now(), updated_at = now()
  WHERE id = v_device_pk;

  -- 8. PostGIS Processing: Stop geofencing and route deviation when active trip exists
  IF (v_rows_state > 0) AND v_trip_id IS NOT NULL AND v_route_id IS NOT NULL THEN
    -- Detect Stop Departures (1.5x radius hysteresis)
    WITH last_ev AS (
      SELECT DISTINCT ON (stop_id) stop_id, event_type
      FROM public.bus_events
      WHERE bus_id = v_bus_id AND trip_id = v_trip_id AND stop_id IS NOT NULL
        AND event_type IN ('arrived', 'departed')
      ORDER BY stop_id, occurred_at DESC
    ), ins_dep AS (
      INSERT INTO public.bus_events (bus_id, trip_id, stop_id, event_type, occurred_at, metadata)
      SELECT v_bus_id, v_trip_id, l.stop_id, 'departed', p_timestamp, jsonb_build_object('stop_code', s.code)
      FROM last_ev l
      JOIN public.stops s ON s.id = l.stop_id
      WHERE l.event_type = 'arrived'
        AND NOT extensions.st_dwithin(s.location, v_point, v_stop_radius_m * 1.5)
      RETURNING stop_id
    )
    SELECT COALESCE(jsonb_agg(jsonb_build_object('type', 'departed', 'stop_id', stop_id)), '[]'::jsonb)
    INTO v_batch FROM ins_dep;
    v_events := v_events || v_batch;

    -- Detect Stop Arrivals
    WITH near AS (
      SELECT s.id AS stop_id, s.code
      FROM public.route_stops rs
      JOIN public.stops s ON s.id = rs.stop_id
      WHERE rs.route_id = v_route_id AND s.is_active
        AND extensions.st_dwithin(s.location, v_point, v_stop_radius_m)
    ), last_ev AS (
      SELECT DISTINCT ON (stop_id) stop_id, event_type
      FROM public.bus_events
      WHERE bus_id = v_bus_id AND trip_id = v_trip_id AND stop_id IS NOT NULL
        AND event_type IN ('arrived', 'departed')
      ORDER BY stop_id, occurred_at DESC
    ), ins_arr AS (
      INSERT INTO public.bus_events (bus_id, trip_id, stop_id, event_type, occurred_at, metadata)
      SELECT v_bus_id, v_trip_id, n.stop_id, 'arrived', p_timestamp, jsonb_build_object('stop_code', n.code)
      FROM near n
      LEFT JOIN last_ev l ON l.stop_id = n.stop_id
      WHERE l.event_type IS DISTINCT FROM 'arrived'
      RETURNING stop_id
    )
    SELECT COALESCE(jsonb_agg(jsonb_build_object('type', 'arrived', 'stop_id', stop_id)), '[]'::jsonb)
    INTO v_batch FROM ins_arr;
    v_events := v_events || v_batch;

    -- Route Deviation Detection (debounced to once / 5 min / trip)
    SELECT COALESCE(
      r.path::extensions.geography,
      (SELECT extensions.st_makeline(s.location::extensions.geometry ORDER BY rs.sequence)::extensions.geography
       FROM public.route_stops rs
       JOIN public.stops s ON s.id = rs.stop_id
       WHERE rs.route_id = r.id
       HAVING count(*) >= 2)
    )
    INTO v_path
    FROM public.routes r
    WHERE r.id = v_route_id;

    IF v_path IS NOT NULL THEN
      v_dist := extensions.st_distance(v_path, v_point);
      IF v_dist > v_deviation_m AND NOT EXISTS (
        SELECT 1 FROM public.bus_events
        WHERE trip_id = v_trip_id AND event_type = 'route_deviation'
          AND occurred_at > p_timestamp - interval '5 minutes'
      ) THEN
        INSERT INTO public.bus_events (bus_id, trip_id, event_type, occurred_at, metadata)
        VALUES (v_bus_id, v_trip_id, 'route_deviation', p_timestamp, jsonb_build_object('distance_m', round(v_dist::numeric)));
        v_events := v_events || jsonb_build_array(
          jsonb_build_object('type', 'route_deviation', 'distance_m', round(v_dist::numeric))
        );
      END IF;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'code', 'SUCCESS',
    'bus_id', v_bus_id,
    'trip_id', v_trip_id,
    'device_id', p_device_id,
    'epoch', v_epoch,
    'seq', p_seq,
    'pos_inserted', (v_rows_pos > 0),
    'state_updated', (v_rows_state > 0),
    'events', v_events
  );
END;
$$;

-- Ingestion is strictly executed by service_role (used by the Fastify backend)
REVOKE ALL ON FUNCTION public.ingest_telemetry_packet(text, bigint, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, text, double precision, double precision, bigint) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.ingest_telemetry_packet(text, bigint, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, text, double precision, double precision, bigint) TO service_role;

-- ----------------------------------------------------------------------------
-- 8. Administrative Device Provisioning Function
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

  IF p_secret IS NULL OR length(p_secret) < 8 THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'WEAK_SECRET',
      'error', 'Device secret must be at least 8 characters'
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

  -- 6. Upsert device record with hashed secret
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
-- 9. Administrative Device Activation/Deactivation Helper
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_device_active(
  p_device_id text,
  p_is_active boolean
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_device_pk uuid;
BEGIN
  IF p_device_id IS NULL OR length(trim(p_device_id)) = 0 THEN
    RETURN jsonb_build_object('ok', false, 'code', 'DEVICE_NOT_FOUND', 'error', 'Device identifier is required');
  END IF;

  -- Acquire advisory lock on device (Namespace classid 1001) to serialize with ingestion
  PERFORM pg_advisory_xact_lock(1001, hashtext(p_device_id));

  UPDATE public.devices
  SET is_active = p_is_active, updated_at = now()
  WHERE device_id = p_device_id
  RETURNING id INTO v_device_pk;

  IF v_device_pk IS NULL THEN
    RETURN jsonb_build_object(
      'ok', false,
      'code', 'DEVICE_NOT_FOUND',
      'error', 'Device not found: ' || p_device_id
    );
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'code', 'SUCCESS',
    'device_id', p_device_id,
    'is_active', p_is_active
  );
END;
$$;

REVOKE ALL ON FUNCTION public.set_device_active(text, boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_device_active(text, boolean) TO service_role;

-- ----------------------------------------------------------------------------
-- 10. Audited Firmware Reboot & Counter Reset Protocol
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
-- 11. Verify Realtime Publication Configuration
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'bus_current_state'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bus_current_state;
  END IF;
END $$;
