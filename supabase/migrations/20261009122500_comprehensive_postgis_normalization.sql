-- ============================================================================
-- Tracklet Migration: Comprehensive PostGIS Integration & Spatial Normalization
-- ============================================================================

-- 1. Ensure PostGIS extension is active
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Create public.route_geometries Table for Road-Following Paths
CREATE TABLE IF NOT EXISTS public.route_geometries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL,
  variant text NOT NULL DEFAULT 'main',
  path geometry(LineString, 4326) NOT NULL,
  source text NOT NULL DEFAULT 'osm',
  is_verified boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT route_geometries_pkey PRIMARY KEY (id),
  CONSTRAINT route_geometries_route_id_fkey FOREIGN KEY (route_id)
    REFERENCES public.routes(id) ON DELETE CASCADE,
  CONSTRAINT route_geometries_route_variant_unique UNIQUE (route_id, variant)
);

-- Spatial GiST Index on Route Paths
CREATE INDEX IF NOT EXISTS idx_route_geometries_path
  ON public.route_geometries USING gist (path);

-- Attach updated_at Trigger
DROP TRIGGER IF EXISTS trg_route_geometries_set_updated_at ON public.route_geometries;
CREATE TRIGGER trg_route_geometries_set_updated_at
  BEFORE UPDATE ON public.route_geometries
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Enable RLS on route_geometries
ALTER TABLE public.route_geometries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read-only access for route_geometries" ON public.route_geometries;
CREATE POLICY "Allow public read-only access for route_geometries"
  ON public.route_geometries FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Allow service role full access for route_geometries" ON public.route_geometries;
CREATE POLICY "Allow service role full access for route_geometries"
  ON public.route_geometries FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- 3. Populate Canonical Route Geometries for R1, R2, R3, R4
INSERT INTO public.route_geometries (route_id, variant, path, source, is_verified)
SELECT
  r.id AS route_id,
  'main' AS variant,
  ST_MakeLine(s.location::geometry ORDER BY rs.sequence) AS path,
  'canonical_stop_sequence' AS source,
  true AS is_verified
FROM public.routes r
JOIN public.route_stops rs ON rs.route_id = r.id
JOIN public.stops s ON s.id = rs.stop_id
WHERE r.id IN (
  '10000000-0000-4000-8000-000000000001'::uuid,
  '20000000-0000-4000-8000-000000000002'::uuid,
  '30000000-0000-4000-8000-000000000003'::uuid,
  '40000000-0000-4000-8000-000000000004'::uuid
)
GROUP BY r.id
ON CONFLICT (route_id, variant) DO UPDATE SET
  path = EXCLUDED.path,
  source = EXCLUDED.source,
  is_verified = EXCLUDED.is_verified,
  updated_at = now();

-- 4. Enhance bus_events with Optional Event Location
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bus_events' AND column_name = 'latitude'
  ) THEN
    ALTER TABLE public.bus_events ADD COLUMN latitude numeric NULL;
    ALTER TABLE public.bus_events ADD COLUMN longitude numeric NULL;
    ALTER TABLE public.bus_events ADD COLUMN location geography(Point, 4326) GENERATED ALWAYS AS (
      CASE
        WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN
          (st_setsrid(st_makepoint((longitude)::double precision, (latitude)::double precision), 4326))::geography
        ELSE NULL
      END
    ) STORED;

    CREATE INDEX IF NOT EXISTS idx_bus_events_location
      ON public.bus_events USING gist (location)
      WHERE location IS NOT NULL;
  END IF;
END $$;

-- 5. Standardize Campus Buildings Spatial Index & Canonical Longitude
-- Verify GiST index exists on location
CREATE INDEX IF NOT EXISTS idx_campus_buildings_location
  ON public.campus_buildings USING gist (location);

-- 6. Spatial RPC Functions

-- 6.1 get_nearby_stops
CREATE OR REPLACE FUNCTION public.get_nearby_stops(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_meters double precision DEFAULT 500,
  p_limit integer DEFAULT 10
)
RETURNS TABLE(
  stop_id uuid,
  code text,
  name text,
  latitude double precision,
  longitude double precision,
  distance_meters double precision,
  nearest_node_id bigint,
  is_active boolean
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions, pg_temp
AS $$
  WITH origin AS (
    SELECT ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography AS pt
  )
  SELECT
    s.id AS stop_id,
    s.code::text,
    s.name::text,
    s.latitude::double precision,
    s.longitude::double precision,
    ST_Distance(s.location, origin.pt) AS distance_meters,
    s.nearest_node_id,
    s.is_active
  FROM public.stops s, origin
  WHERE s.is_active
    AND ST_DWithin(s.location, origin.pt, p_radius_meters)
  ORDER BY distance_meters ASC
  LIMIT LEAST(GREATEST(p_limit, 1), 50);
$$;

-- 6.2 get_nearby_buses
CREATE OR REPLACE FUNCTION public.get_nearby_buses(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_meters double precision DEFAULT 2000,
  p_limit integer DEFAULT 10
)
RETURNS TABLE(
  bus_id uuid,
  bus_number text,
  display_name text,
  latitude double precision,
  longitude double precision,
  speed double precision,
  heading double precision,
  status text,
  distance_meters double precision,
  last_seen timestamp with time zone
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions, pg_temp
AS $$
  WITH origin AS (
    SELECT ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography AS pt
  )
  SELECT
    b.id AS bus_id,
    b.bus_number::text,
    b.display_name::text,
    c.latitude::double precision,
    c.longitude::double precision,
    c.speed::double precision,
    c.heading::double precision,
    c.status::text,
    ST_Distance(c.location, origin.pt) AS distance_meters,
    c.last_seen
  FROM public.bus_current_state c
  JOIN public.buses b ON b.id = c.bus_id, origin
  WHERE b.is_active
    AND c.last_seen > now() - interval '5 minutes'
    AND ST_DWithin(c.location, origin.pt, p_radius_meters)
  ORDER BY distance_meters ASC
  LIMIT LEAST(GREATEST(p_limit, 1), 50);
$$;

-- 6.3 get_active_bus_positions
CREATE OR REPLACE FUNCTION public.get_active_bus_positions()
RETURNS TABLE(
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
  recorded_at timestamp with time zone
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
    t.route_id,
    r.name::text AS route_name,
    c.latitude::double precision,
    c.longitude::double precision,
    c.speed::double precision,
    c.heading::double precision,
    c.status::text,
    c.last_seen,
    c.recorded_at
  FROM public.bus_current_state c
  JOIN public.buses b ON b.id = c.bus_id
  LEFT JOIN public.trips t ON t.id = c.trip_id
  LEFT JOIN public.routes r ON r.id = t.route_id
  WHERE b.is_active
    AND c.last_seen > now() - interval '10 minutes'
  ORDER BY b.bus_number ASC;
$$;

-- 6.4 get_route_geometry
CREATE OR REPLACE FUNCTION public.get_route_geometry(
  p_route_id uuid,
  p_variant text DEFAULT 'main'
)
RETURNS TABLE(
  route_id uuid,
  variant text,
  is_verified boolean,
  source text,
  geojson jsonb,
  stop_count integer
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_geom geometry(LineString, 4326);
  v_verified boolean := false;
  v_src text := 'osm';
  v_stops_count integer := 0;
BEGIN
  -- 1. Try fetching stored route geometry
  SELECT rg.path, rg.is_verified, rg.source
  INTO v_geom, v_verified, v_src
  FROM public.route_geometries rg
  WHERE rg.route_id = p_route_id AND rg.variant = p_variant;

  -- 2. Fallback: synthesize from route_stops if not explicitly in table
  IF v_geom IS NULL THEN
    SELECT
      ST_MakeLine(s.location::geometry ORDER BY rs.sequence),
      false,
      'computed_stop_sequence'
    INTO v_geom, v_verified, v_src
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    WHERE rs.route_id = p_route_id;
  END IF;

  -- 3. Stop count
  SELECT COUNT(*) INTO v_stops_count
  FROM public.route_stops rs
  WHERE rs.route_id = p_route_id;

  RETURN QUERY
  SELECT
    p_route_id AS route_id,
    p_variant AS variant,
    v_verified AS is_verified,
    v_src AS source,
    ST_AsGeoJSON(v_geom)::jsonb AS geojson,
    v_stops_count AS stop_count;
END;
$$;

-- 6.5 get_campus_buildings_nearby
CREATE OR REPLACE FUNCTION public.get_campus_buildings_nearby(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_meters double precision DEFAULT 500,
  p_limit integer DEFAULT 20
)
RETURNS TABLE(
  id text,
  name text,
  category text,
  latitude double precision,
  longitude double precision,
  distance_meters double precision,
  nearest_node_id bigint,
  amenity text,
  building_type text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions, pg_temp
AS $$
  WITH origin AS (
    SELECT ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography AS pt
  )
  SELECT
    b.id,
    b.name,
    b.category,
    b.lat AS latitude,
    b.lng AS longitude,
    ST_Distance(b.location, origin.pt) AS distance_meters,
    b.nearest_node_id,
    b.amenity,
    b.building_type
  FROM public.campus_buildings b, origin
  WHERE ST_DWithin(b.location, origin.pt, p_radius_meters)
  ORDER BY distance_meters ASC
  LIMIT LEAST(GREATEST(p_limit, 1), 100);
$$;

-- 7. Grant Permissions for Spatial RPC Functions
REVOKE ALL ON FUNCTION public.get_nearby_stops(double precision, double precision, double precision, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_nearby_stops(double precision, double precision, double precision, integer) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_nearby_buses(double precision, double precision, double precision, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_nearby_buses(double precision, double precision, double precision, integer) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_active_bus_positions() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_active_bus_positions() TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_route_geometry(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_route_geometry(uuid, text) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_campus_buildings_nearby(double precision, double precision, double precision, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_campus_buildings_nearby(double precision, double precision, double precision, integer) TO anon, authenticated, service_role;
