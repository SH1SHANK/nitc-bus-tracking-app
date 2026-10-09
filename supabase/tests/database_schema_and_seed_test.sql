-- ============================================================================
-- Tracklet Supabase Test Suite
-- Database Schema, Constraint, RLS, and Seed Integrity Verification
-- ============================================================================

DO $$
DECLARE
    v_count integer;
    v_rec record;
BEGIN
    RAISE NOTICE 'Starting Tracklet database verification tests...';

    -- 1. Table Existence Checks
    RAISE NOTICE 'Test 1: Checking required tables...';
    FOR v_rec IN
        SELECT unnest(ARRAY[
            'stops', 'routes', 'route_stops', 'buses',
            'devices', 'trips', 'bus_positions', 'bus_current_state',
            'bus_events', 'bus_timings'
        ]) AS tbl
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = v_rec.tbl
        ) THEN
            RAISE EXCEPTION 'Assertion Failed: Table public.% does not exist', v_rec.tbl;
        END IF;
    END LOOP;
    RAISE NOTICE '✓ All 10 public tables present.';

    -- 2. PostGIS Extension & Generated Geography Column Verification
    RAISE NOTICE 'Test 2: Checking PostGIS and spatial generated columns...';
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
        RAISE EXCEPTION 'Assertion Failed: PostGIS extension is not installed';
    END IF;

    -- Verify generated columns produce valid PostGIS points
    SELECT COUNT(*) INTO v_count FROM public.stops WHERE location IS NULL;
    IF v_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: Found % stops with NULL generated location', v_count;
    END IF;
    RAISE NOTICE '✓ PostGIS extension active and generated geography columns working.';

    -- 3. Canonical Seed Data Checks
    RAISE NOTICE 'Test 3: Checking canonical seed data...';

    -- 3a. 9 Canonical Stops
    SELECT COUNT(*) INTO v_count FROM public.stops
    WHERE code IN (
        'department_building', 'kattangal_bus_stop', 'main_gate',
        'architecture', 'ladies_hostel', 'mega_hostel_boys',
        'east_campus', 'south_campus', 'center_circle'
    );
    IF v_count <> 9 THEN
        RAISE EXCEPTION 'Assertion Failed: Expected 9 canonical stops, found %', v_count;
    END IF;

    -- 3b. 4 Canonical Routes
    SELECT COUNT(*) INTO v_count FROM public.routes
    WHERE id IN (
        '10000000-0000-4000-8000-000000000001'::uuid,
        '20000000-0000-4000-8000-000000000002'::uuid,
        '30000000-0000-4000-8000-000000000003'::uuid,
        '40000000-0000-4000-8000-000000000004'::uuid
    );
    IF v_count <> 4 THEN
        RAISE EXCEPTION 'Assertion Failed: Expected 4 canonical routes, found %', v_count;
    END IF;

    -- 3c. 6 Canonical Buses
    SELECT COUNT(*) INTO v_count FROM public.buses
    WHERE bus_number IN ('Bus 1', 'Bus 2', 'Bus 3', 'Bus 4', 'A/C 1', 'A/C 2');
    IF v_count <> 6 THEN
        RAISE EXCEPTION 'Assertion Failed: Expected 6 canonical buses, found %', v_count;
    END IF;

    -- 3d. Route Stops Sequence & Counts (R1=8, R2=10, R3=6, R4=6 -> Total 30)
    SELECT COUNT(*) INTO v_count FROM public.route_stops
    WHERE route_id IN (
        '10000000-0000-4000-8000-000000000001'::uuid,
        '20000000-0000-4000-8000-000000000002'::uuid,
        '30000000-0000-4000-8000-000000000003'::uuid,
        '40000000-0000-4000-8000-000000000004'::uuid
    );
    IF v_count <> 30 THEN
        RAISE EXCEPTION 'Assertion Failed: Expected 30 canonical route_stops, found %', v_count;
    END IF;

    -- 3e. 100 Scheduled Bus Timings
    SELECT COUNT(*) INTO v_count FROM public.bus_timings;
    IF v_count <> 100 THEN
        RAISE EXCEPTION 'Assertion Failed: Expected 100 bus timings, found %', v_count;
    END IF;
    RAISE NOTICE '✓ All canonical seed counts verified (9 stops, 4 routes, 6 buses, 30 route_stops, 100 timings).';

    -- 4. RLS Enabled Checks
    RAISE NOTICE 'Test 4: Checking Row Level Security...';
    FOR v_rec IN
        SELECT c.relname
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relkind = 'r'
          AND c.relname IN ('stops', 'routes', 'route_stops', 'buses', 'bus_timings', 'bus_current_state')
          AND NOT c.relrowsecurity
    LOOP
        RAISE EXCEPTION 'Assertion Failed: RLS is disabled on table public.%', v_rec.relname;
    END LOOP;
    RAISE NOTICE '✓ RLS is enabled on all core public tables.';

    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'ALL DATABASE VERIFICATION TESTS PASSED SUCCESSFULLY!';
    RAISE NOTICE '=======================================================';
END $$;
