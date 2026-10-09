-- ============================================================================
-- Tracklet Migration: Create Campus Buildings Table & Indexes
-- ============================================================================

-- Ensure pg_trgm is enabled for text search indexing
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create campus_buildings table
CREATE TABLE IF NOT EXISTS public.campus_buildings (
  id text NOT NULL,
  name text NOT NULL,
  category text NULL,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  nearest_node_id bigint NOT NULL,
  snap_dist_m real NULL,
  description text NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  lon double precision NULL,
  amenity text NULL,
  building_type text NULL,
  location geography(point, 4326) GENERATED ALWAYS AS (
    (st_setsrid(st_makepoint((COALESCE(lon, lng))::double precision, (lat)::double precision), 4326))::geography
  ) STORED,
  CONSTRAINT campus_buildings_pkey PRIMARY KEY (id)
);

-- Indexes for performance and search
CREATE INDEX IF NOT EXISTS idx_campus_buildings_name_trgm
  ON public.campus_buildings USING gin (name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_campus_buildings_nearest_node
  ON public.campus_buildings USING btree (nearest_node_id);

CREATE INDEX IF NOT EXISTS idx_campus_buildings_category
  ON public.campus_buildings USING btree (category);

CREATE INDEX IF NOT EXISTS idx_campus_buildings_location
  ON public.campus_buildings USING gist (location);

-- Enable Row Level Security
ALTER TABLE public.campus_buildings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Allow public read-only access for campus_buildings" ON public.campus_buildings;
CREATE POLICY "Allow public read-only access for campus_buildings"
  ON public.campus_buildings FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Allow service role full access for campus_buildings" ON public.campus_buildings;
CREATE POLICY "Allow service role full access for campus_buildings"
  ON public.campus_buildings FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
