-- ============================================================================
-- Tracklet Migration: Update public.routes Schema with Typed PostGIS Path
-- ============================================================================

-- 1. Add missing route metadata columns
ALTER TABLE public.routes
  ADD COLUMN IF NOT EXISTS route_code text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS path_source text NOT NULL DEFAULT 'manual',
  ADD COLUMN IF NOT EXISTS path_verified boolean NOT NULL DEFAULT false;

-- 2. Assign stable codes and descriptions to the four canonical routes
UPDATE public.routes
SET
  route_code = CASE
    WHEN id = '10000000-0000-4000-8000-000000000001' THEN 'R1'
    WHEN id = '20000000-0000-4000-8000-000000000002' THEN 'R2'
    WHEN id = '30000000-0000-4000-8000-000000000003' THEN 'R3'
    WHEN id = '40000000-0000-4000-8000-000000000004' THEN 'R4'
    ELSE route_code
  END,
  description = CASE
    WHEN id = '10000000-0000-4000-8000-000000000001' THEN 'East Campus to Mega Boys Hostel via Main Gate'
    WHEN id = '20000000-0000-4000-8000-000000000002' THEN 'East Campus to Ladies Hostel via South Campus loop'
    WHEN id = '30000000-0000-4000-8000-000000000003' THEN 'Architecture Department to Ladies Hostel express loop'
    WHEN id = '40000000-0000-4000-8000-000000000004' THEN 'Architecture Department to Mega Boys Hostel express loop'
    ELSE description
  END
WHERE id IN (
  '10000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000002',
  '30000000-0000-4000-8000-000000000003',
  '40000000-0000-4000-8000-000000000004'
);

-- 3. Convert route path column to typed PostGIS LineString (EPSG:4326)
ALTER TABLE public.routes
  ALTER COLUMN path TYPE geometry(LineString, 4326)
  USING path::geometry(LineString, 4326);

-- 4. Add uniqueness for assigned route codes
CREATE UNIQUE INDEX IF NOT EXISTS routes_route_code_uidx
  ON public.routes (route_code)
  WHERE route_code IS NOT NULL;

-- 5. Add a spatial GiST index for route geometry
CREATE INDEX IF NOT EXISTS routes_path_gix
  ON public.routes USING gist (path);

-- 6. Update get_route_geometry RPC to use routes table directly
CREATE OR REPLACE FUNCTION public.get_route_geometry(
  p_route_id uuid
)
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
SECURITY INVOKER
SET search_path = public, extensions, pg_temp
AS $$
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
$$;

REVOKE ALL ON FUNCTION public.get_route_geometry(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_route_geometry(uuid) TO anon, authenticated, service_role;
