-- ============================================================================
-- Tracklet Migration: Create Hostels Table, RPC & Foreign Key Integration
-- ============================================================================

-- 1. Create public.hostels Table
CREATE TABLE IF NOT EXISTS public.hostels (
  hostel_id text NOT NULL,
  hostel_name text NOT NULL,
  short_code text NULL,
  gender text NULL CHECK (gender IN ('boys', 'girls', 'co-ed', 'all')),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT hostels_pkey PRIMARY KEY (hostel_id),
  CONSTRAINT hostels_name_unique UNIQUE (hostel_name)
);

-- Seed Canonical NITC Hostels idempotently
INSERT INTO public.hostels (hostel_id, hostel_name, short_code, gender)
VALUES
  ('A', 'A Hostel', 'A', 'boys'),
  ('B', 'B Hostel', 'B', 'boys'),
  ('C', 'C Hostel', 'C', 'boys'),
  ('D', 'D Hostel', 'D', 'boys'),
  ('E', 'E Hostel', 'E', 'boys'),
  ('F', 'F Hostel', 'F', 'boys'),
  ('G', 'G Hostel', 'G', 'boys'),
  ('MBH_1', 'Mega Hostel (MBH - Phase 1)', 'MBH-1', 'boys'),
  ('MBH_2', 'Mega Hostel (MBH - Phase 2)', 'MBH-2', 'boys'),
  ('PG_1', 'PG 1 Hostel', 'PG-1', 'boys'),
  ('PG_2', 'PG 2 Hostel', 'PG-2', 'boys'),
  ('MBA', 'MBA Hostel', 'MBA', 'boys'),
  ('LH_MAIN', 'Ladies Hostel (LH - Main Block)', 'LH-Main', 'girls'),
  ('LH_MEGA', 'Ladies Hostel (LH - Mega Block)', 'LH-Mega', 'girls'),
  ('IH', 'International Hostel', 'IH', 'co-ed'),
  ('DAY_SCHOLAR', 'Day Scholar', 'DS', 'all')
ON CONFLICT (hostel_id) DO UPDATE SET
  hostel_name = EXCLUDED.hostel_name,
  short_code = EXCLUDED.short_code,
  gender = EXCLUDED.gender;

-- 2. Add hostel_id to public.users if not already present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'hostel_id'
  ) THEN
    ALTER TABLE public.users ADD COLUMN hostel_id text REFERENCES public.hostels(hostel_id) ON UPDATE CASCADE ON DELETE SET NULL;
    CREATE INDEX IF NOT EXISTS idx_users_hostel_id ON public.users(hostel_id);
  END IF;
END $$;

-- 3. Enable RLS on public.hostels
ALTER TABLE public.hostels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access for hostels" ON public.hostels;
CREATE POLICY "Allow public read access for hostels"
  ON public.hostels FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Allow service role full access on hostels" ON public.hostels;
CREATE POLICY "Allow service role full access on hostels"
  ON public.hostels FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- 4. Create public.get_hostels() RPC
CREATE OR REPLACE FUNCTION public.get_hostels()
RETURNS TABLE(
  hostel_id text,
  hostel_name text,
  short_code text,
  gender text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
  SELECT h.hostel_id, h.hostel_name, h.short_code, h.gender
  FROM public.hostels h
  ORDER BY h.hostel_name ASC;
$$;

REVOKE ALL ON FUNCTION public.get_hostels() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_hostels() TO anon, authenticated, service_role;
