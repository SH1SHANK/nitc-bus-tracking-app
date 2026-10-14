-- Expose only rider-required live telemetry fields and active-trip stop events.
-- Keep devices and historical telemetry private; do not change ingestion.

-- The client uses the two narrow RPCs below instead of table reads. Remove
-- inherited broad rider access to raw/current operational rows.
REVOKE SELECT ON public.buses, public.trips, public.bus_current_state,
  public.bus_positions, public.bus_events FROM anon, authenticated;
DROP POLICY IF EXISTS "read_buses" ON public.buses;
DROP POLICY IF EXISTS "read_buses_anon" ON public.buses;
DROP POLICY IF EXISTS "read_trips" ON public.trips;
DROP POLICY IF EXISTS "read_trips_public" ON public.trips;
DROP POLICY IF EXISTS "read_bus_current_state" ON public.bus_current_state;
DROP POLICY IF EXISTS "read_bus_current_state_anon" ON public.bus_current_state;
DROP POLICY IF EXISTS "read_bus_events" ON public.bus_events;
DROP POLICY IF EXISTS "Allow authenticated read on bus_positions" ON public.bus_positions;
DROP POLICY IF EXISTS "read_bus_positions" ON public.bus_positions;

CREATE OR REPLACE FUNCTION public.get_active_bus_positions_v2()
RETURNS TABLE (
  bus_id uuid,
  bus_number text,
  display_name text,
  trip_id uuid,
  active_trip_id uuid,
  route_id uuid,
  route_name text,
  latitude double precision,
  longitude double precision,
  speed double precision,
  heading double precision,
  status text,
  last_seen timestamptz,
  recorded_at timestamptz,
  is_stale boolean,
  epoch bigint,
  seq bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
  SELECT b.id, b.bus_number::text, b.display_name::text,
         c.trip_id, c.trip_id,
         COALESCE(t.route_id, prior.route_id),
         COALESCE(r.name::text, prior.route_name),
         c.latitude::double precision, c.longitude::double precision,
         c.speed::double precision, c.heading::double precision,
         c.status::text, c.last_seen, c.recorded_at,
         c.last_seen < now() - interval '90 seconds', c.epoch, c.seq
  FROM public.bus_current_state c
  JOIN public.buses b ON b.id = c.bus_id
  LEFT JOIN public.trips t ON t.id = c.trip_id
  LEFT JOIN public.routes r ON r.id = t.route_id
  LEFT JOIN LATERAL (
    SELECT tr.route_id, rr.name AS route_name
    FROM public.trips tr
    JOIN public.routes rr ON rr.id = tr.route_id
    WHERE tr.bus_id = b.id
    ORDER BY tr.started_at DESC NULLS LAST, tr.created_at DESC
    LIMIT 1
  ) prior ON true
  WHERE b.is_active AND c.last_seen > now() - interval '15 minutes'
  ORDER BY b.bus_number;
$$;
REVOKE ALL ON FUNCTION public.get_active_bus_positions() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_active_bus_positions_v2() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_active_bus_positions_v2() TO anon, authenticated, service_role;

-- Preserve the original RPC result shape for installed older clients.
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
  last_seen timestamptz,
  recorded_at timestamptz,
  is_stale boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
  SELECT p.bus_id, p.bus_number, p.display_name, p.trip_id, p.route_id,
         p.route_name, p.latitude, p.longitude, p.speed, p.heading,
         p.status, p.last_seen, p.recorded_at, p.is_stale
  FROM public.get_active_bus_positions_v2() p;
$$;
REVOKE ALL ON FUNCTION public.get_active_bus_positions() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_active_bus_positions() TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.get_active_trip_stop_events(p_trip_id uuid)
RETURNS TABLE (stop_id uuid, event_type text, occurred_at timestamptz)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
  SELECT e.stop_id, e.event_type::text, e.occurred_at
  FROM public.bus_events e
  JOIN public.trips t ON t.id = e.trip_id
  JOIN public.bus_current_state c ON c.trip_id = t.id AND c.bus_id = t.bus_id
  JOIN public.buses b ON b.id = t.bus_id AND b.is_active
  WHERE t.id = p_trip_id
    AND t.status = 'active'
    AND c.last_seen > now() - interval '15 minutes'
    AND e.stop_id IS NOT NULL
    AND e.event_type IN ('arrived', 'departed')
  ORDER BY e.occurred_at, e.id;
$$;
REVOKE ALL ON FUNCTION public.get_active_trip_stop_events(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_active_trip_stop_events(uuid) TO anon, authenticated, service_role;
