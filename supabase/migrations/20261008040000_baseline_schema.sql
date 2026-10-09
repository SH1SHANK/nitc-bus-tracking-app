-- Tracklet Supabase Baseline Migration
-- Reflects existing schema on project fnngudikrvelpuhngtlw

-- Extensions
CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "extensions";

-- Timestamp update helper
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Table: public.stops
CREATE TABLE IF NOT EXISTS public.stops (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    code character varying NOT NULL,
    name character varying NOT NULL,
    latitude numeric NOT NULL,
    longitude numeric NOT NULL,
    location extensions.geography(Point, 4326) GENERATED ALWAYS AS (extensions.st_setsrid(extensions.st_makepoint((longitude)::double precision, (latitude)::double precision), 4326)::extensions.geography) STORED,
    nearest_node_id bigint,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT stops_pkey PRIMARY KEY (id),
    CONSTRAINT stops_code_key UNIQUE (code)
);

CREATE TRIGGER stops_updated_at
    BEFORE UPDATE ON public.stops
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Table: public.routes
CREATE TABLE IF NOT EXISTS public.routes (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name character varying NOT NULL,
    direction character varying NOT NULL DEFAULT 'forward'::character varying,
    path extensions.geography,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT routes_pkey PRIMARY KEY (id)
);

CREATE TRIGGER routes_updated_at
    BEFORE UPDATE ON public.routes
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Table: public.route_stops
CREATE TABLE IF NOT EXISTS public.route_stops (
    route_id uuid NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
    stop_id uuid NOT NULL REFERENCES public.stops(id) ON DELETE RESTRICT,
    sequence integer NOT NULL CHECK (sequence >= 0),
    distance_from_start numeric,
    estimated_duration_sec integer,
    CONSTRAINT route_stops_pkey PRIMARY KEY (route_id, sequence)
);

CREATE INDEX IF NOT EXISTS route_stops_stop_idx ON public.route_stops(stop_id);

-- Table: public.buses
CREATE TABLE IF NOT EXISTS public.buses (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    bus_number character varying NOT NULL,
    display_name character varying,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT buses_pkey PRIMARY KEY (id),
    CONSTRAINT buses_bus_number_key UNIQUE (bus_number)
);

CREATE TRIGGER buses_updated_at
    BEFORE UPDATE ON public.buses
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Table: public.devices
CREATE TABLE IF NOT EXISTS public.devices (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    device_id character varying NOT NULL,
    bus_id uuid NOT NULL REFERENCES public.buses(id),
    credential_hash text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    last_seen timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT devices_pkey PRIMARY KEY (id),
    CONSTRAINT devices_device_id_key UNIQUE (device_id)
);

CREATE TRIGGER devices_updated_at
    BEFORE UPDATE ON public.devices
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Table: public.trips
CREATE TABLE IF NOT EXISTS public.trips (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    bus_id uuid NOT NULL REFERENCES public.buses(id) ON DELETE CASCADE,
    route_id uuid NOT NULL REFERENCES public.routes(id) ON DELETE RESTRICT,
    status character varying NOT NULL DEFAULT 'scheduled'::character varying,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT trips_pkey PRIMARY KEY (id),
    CONSTRAINT trips_status_check CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled'))
);

CREATE UNIQUE INDEX IF NOT EXISTS trips_single_active_per_bus
    ON public.trips (bus_id)
    WHERE status = 'active';

-- Table: public.bus_positions
CREATE TABLE IF NOT EXISTS public.bus_positions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bus_id uuid NOT NULL REFERENCES public.buses(id),
    trip_id uuid REFERENCES public.trips(id),
    latitude numeric NOT NULL,
    longitude numeric NOT NULL,
    location extensions.geography(Point, 4326) GENERATED ALWAYS AS (extensions.st_setsrid(extensions.st_makepoint((longitude)::double precision, (latitude)::double precision), 4326)::extensions.geography) STORED,
    speed numeric,
    heading numeric,
    accuracy numeric,
    seq bigint NOT NULL,
    recorded_at timestamp with time zone NOT NULL,
    received_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT bus_positions_bus_id_recorded_at_key UNIQUE (bus_id, recorded_at)
);

-- Table: public.bus_current_state
CREATE TABLE IF NOT EXISTS public.bus_current_state (
    bus_id uuid NOT NULL PRIMARY KEY REFERENCES public.buses(id),
    trip_id uuid REFERENCES public.trips(id),
    latitude numeric NOT NULL,
    longitude numeric NOT NULL,
    location extensions.geography(Point, 4326) GENERATED ALWAYS AS (extensions.st_setsrid(extensions.st_makepoint((longitude)::double precision, (latitude)::double precision), 4326)::extensions.geography) STORED,
    speed numeric,
    heading numeric,
    accuracy numeric,
    seq bigint NOT NULL,
    status character varying NOT NULL DEFAULT 'stationary'::character varying,
    recorded_at timestamp with time zone NOT NULL,
    last_seen timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Table: public.bus_events
CREATE TABLE IF NOT EXISTS public.bus_events (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    bus_id uuid NOT NULL REFERENCES public.buses(id),
    trip_id uuid REFERENCES public.trips(id),
    stop_id uuid REFERENCES public.stops(id),
    event_type character varying NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Stored functions
CREATE OR REPLACE FUNCTION public.ingest_telemetry(
    p_device_id text,
    p_bus_id uuid,
    p_seq bigint,
    p_recorded_at timestamp with time zone,
    p_latitude numeric,
    p_longitude numeric,
    p_speed numeric,
    p_heading numeric,
    p_accuracy numeric,
    p_status text,
    p_stop_radius_m double precision DEFAULT 50,
    p_deviation_m double precision DEFAULT 500
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
    v_device_pk uuid;
    v_device_bus uuid;
    v_trip_id uuid;
    v_route_id uuid;
    v_point geography;
    v_rows int;
    v_state_updated boolean := false;
    v_events jsonb := '[]'::jsonb;
    v_batch jsonb;
    v_path geography;
    v_dist double precision;
BEGIN
    SELECT id, bus_id INTO v_device_pk, v_device_bus
    FROM devices WHERE device_id = p_device_id AND is_active;

    IF v_device_pk IS NULL THEN
        RETURN jsonb_build_object('ok', false, 'reason', 'device_inactive');
    END IF;

    IF v_device_bus <> p_bus_id THEN
        RETURN jsonb_build_object('ok', false, 'reason', 'device_mismatch');
    END IF;

    UPDATE devices SET last_seen = now() WHERE id = v_device_pk;

    SELECT id, route_id INTO v_trip_id, v_route_id
    FROM trips WHERE bus_id = p_bus_id AND status = 'active' LIMIT 1;

    v_point := st_setsrid(st_makepoint(p_longitude::float8, p_latitude::float8), 4326)::geography;

    -- history (dedupe on bus_id + recorded_at)
    INSERT INTO bus_positions (bus_id, trip_id, latitude, longitude, speed, heading, accuracy, seq, recorded_at)
    VALUES (p_bus_id, v_trip_id, p_latitude, p_longitude, p_speed, p_heading, p_accuracy, p_seq, p_recorded_at)
    ON CONFLICT (bus_id, recorded_at) DO NOTHING;

    GET DIAGNOSTICS v_rows = row_count;
    IF v_rows = 0 THEN
        RETURN jsonb_build_object('ok', true, 'stored', false, 'reason', 'duplicate');
    END IF;

    -- current state: only moves forward in time
    INSERT INTO bus_current_state AS c
        (bus_id, trip_id, latitude, longitude, speed, heading, accuracy, seq, status, recorded_at, last_seen, updated_at)
    VALUES
        (p_bus_id, v_trip_id, p_latitude, p_longitude, p_speed, p_heading, p_accuracy, p_seq, p_status, p_recorded_at, now(), now())
    ON CONFLICT (bus_id) DO UPDATE SET
        trip_id = excluded.trip_id, latitude = excluded.latitude, longitude = excluded.longitude,
        speed = excluded.speed, heading = excluded.heading, accuracy = excluded.accuracy,
        seq = excluded.seq, status = excluded.status, recorded_at = excluded.recorded_at,
        last_seen = now(), updated_at = now()
    WHERE c.recorded_at < excluded.recorded_at;

    GET DIAGNOSTICS v_rows = row_count;
    v_state_updated := v_rows > 0;

    IF v_state_updated AND v_trip_id IS NOT NULL THEN
        -- departures
        WITH last_ev AS (
            SELECT DISTINCT ON (stop_id) stop_id, event_type
            FROM bus_events
            WHERE bus_id = p_bus_id AND trip_id = v_trip_id AND stop_id IS NOT NULL
              AND event_type IN ('arrived','departed')
            ORDER BY stop_id, occurred_at DESC
        ), ins AS (
            INSERT INTO bus_events (bus_id, trip_id, stop_id, event_type, occurred_at, metadata)
            SELECT p_bus_id, v_trip_id, l.stop_id, 'departed', p_recorded_at, jsonb_build_object('stop_code', s.code)
            FROM last_ev l JOIN stops s ON s.id = l.stop_id
            WHERE l.event_type = 'arrived'
              AND NOT st_dwithin(s.location, v_point, p_stop_radius_m * 1.5)
            RETURNING stop_id
        )
        SELECT coalesce(jsonb_agg(jsonb_build_object('type','departed','stop_id',stop_id)), '[]'::jsonb)
        INTO v_batch FROM ins;
        v_events := v_events || v_batch;

        -- arrivals
        WITH near AS (
            SELECT s.id AS stop_id, s.code
            FROM route_stops rs JOIN stops s ON s.id = rs.stop_id
            WHERE rs.route_id = v_route_id AND s.is_active
              AND st_dwithin(s.location, v_point, p_stop_radius_m)
        ), last_ev AS (
            SELECT DISTINCT ON (stop_id) stop_id, event_type
            FROM bus_events
            WHERE bus_id = p_bus_id AND trip_id = v_trip_id AND stop_id IS NOT NULL
              AND event_type IN ('arrived','departed')
            ORDER BY stop_id, occurred_at DESC
        ), ins AS (
            INSERT INTO bus_events (bus_id, trip_id, stop_id, event_type, occurred_at, metadata)
            SELECT p_bus_id, v_trip_id, n.stop_id, 'arrived', p_recorded_at, jsonb_build_object('stop_code', n.code)
            FROM near n LEFT JOIN last_ev l ON l.stop_id = n.stop_id
            WHERE l.event_type IS DISTINCT FROM 'arrived'
            RETURNING stop_id
        )
        SELECT coalesce(jsonb_agg(jsonb_build_object('type','arrived','stop_id',stop_id)), '[]'::jsonb)
        INTO v_batch FROM ins;
        v_events := v_events || v_batch;

        -- route matching
        SELECT coalesce(
                 r.path,
                 (SELECT st_makeline(s.location::geometry ORDER BY rs.sequence)::geography
                  FROM route_stops rs JOIN stops s ON s.id = rs.stop_id
                  WHERE rs.route_id = r.id
                  HAVING count(*) >= 2)
               )
        INTO v_path FROM routes r WHERE r.id = v_route_id;

        IF v_path IS NOT NULL THEN
            v_dist := st_distance(v_path, v_point);
            IF v_dist > p_deviation_m AND NOT EXISTS (
                SELECT 1 FROM bus_events
                WHERE trip_id = v_trip_id AND event_type = 'route_deviation'
                  AND occurred_at > p_recorded_at - interval '5 minutes'
            ) THEN
                INSERT INTO bus_events (bus_id, trip_id, event_type, occurred_at, metadata)
                VALUES (p_bus_id, v_trip_id, 'route_deviation', p_recorded_at,
                        jsonb_build_object('distance_m', round(v_dist::numeric)));
                v_events := v_events || jsonb_build_array(
                    jsonb_build_object('type','route_deviation','distance_m', round(v_dist::numeric)));
            END IF;
        END IF;
    END IF;

    RETURN jsonb_build_object('ok', true, 'stored', true, 'state_updated', v_state_updated,
                              'bus_id', p_bus_id, 'trip_id', v_trip_id, 'events', v_events);
END;
$$;

CREATE OR REPLACE FUNCTION public.nearby_buses(
    p_lat double precision,
    p_lon double precision,
    p_radius_m double precision DEFAULT 2000
)
RETURNS TABLE(
    bus_id uuid,
    bus_number text,
    display_name text,
    latitude numeric,
    longitude numeric,
    speed numeric,
    heading numeric,
    status text,
    recorded_at timestamp with time zone,
    distance_m double precision
)
LANGUAGE sql
STABLE
SET search_path TO 'public', 'extensions'
AS $$
    WITH q AS (SELECT st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography AS pt)
    SELECT b.id, b.bus_number::text, b.display_name::text, c.latitude::numeric, c.longitude::numeric,
           c.speed::numeric, c.heading::numeric, c.status::text, c.recorded_at,
           st_distance(c.location, q.pt)
    FROM bus_current_state c
    JOIN buses b ON b.id = c.bus_id, q
    WHERE b.is_active
      AND c.last_seen > now() - interval '2 minutes'
      AND st_dwithin(c.location, q.pt, p_radius_m)
    ORDER BY 10;
$$;

CREATE OR REPLACE FUNCTION public.nearest_stops(
    p_lat double precision,
    p_lon double precision,
    p_limit integer DEFAULT 3
)
RETURNS TABLE(
    stop_id uuid,
    code text,
    name text,
    latitude numeric,
    longitude numeric,
    distance_m double precision
)
LANGUAGE sql
STABLE
SET search_path TO 'public', 'extensions'
AS $$
    WITH q AS (SELECT st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography AS pt)
    SELECT s.id, s.code::text, s.name::text, s.latitude::numeric, s.longitude::numeric,
           st_distance(s.location, q.pt)
    FROM stops s, q
    WHERE s.is_active
    ORDER BY s.location <-> q.pt
    LIMIT least(greatest(p_limit, 1), 20);
$$;

-- Row Level Security
ALTER TABLE public.stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_current_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_events ENABLE ROW LEVEL SECURITY;

-- Existing RLS Policies
CREATE POLICY "read_stops" ON public.stops FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_routes" ON public.routes FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_route_stops" ON public.route_stops FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_buses" ON public.buses FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_trips" ON public.trips FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_bus_current_state" ON public.bus_current_state FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_bus_events" ON public.bus_events FOR SELECT TO authenticated USING (true);

-- Realtime Publication
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'bus_current_state'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.bus_current_state;
    END IF;
END;
$$;
