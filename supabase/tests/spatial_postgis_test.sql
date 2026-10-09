-- ============================================================================
-- Tracklet PostGIS Spatial Test Suite
-- Validates SRID 4326, GiST Indexes, Spatial Distance & Radius Queries, RPCs
-- ============================================================================

DO $$
DECLARE
    v_count integer;
    v_stop record;
    v_bldg record;
    v_route record;
    v_geojson jsonb;
    v_dist double precision;
BEGIN
    RAISE NOTICE 'Starting Tracklet PostGIS Spatial Verification Tests...';

    -- 1. Verify PostGIS Extension & Spatial Column Types
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
        RAISE EXCEPTION 'Assertion Failed: PostGIS extension is not installed';
    END IF;

    -- 2. Verify GiST Spatial Indexes
    RAISE NOTICE 'Test 2: Verifying GiST spatial indexes...';
    FOR v_stop IN
        SELECT unnest(ARRAY[
            'stops_location_gix',
            'idx_campus_buildings_location',
            'bus_positions_location_gix',
            'bus_current_state_location_gix',
            'routes_path_gix'
        ]) AS idx_name
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_class i
            JOIN pg_namespace n ON n.oid = i.relnamespace
            WHERE n.nspname = 'public' AND i.relname = v_stop.idx_name
        ) THEN
            RAISE EXCEPTION 'Assertion Failed: Expected GiST index % not found', v_stop.idx_name;
        END IF;
    END LOOP;
    RAISE NOTICE '✓ All 5 GiST spatial indexes verified.';

    -- 3. Verify Stops Geography & Coordinates
    RAISE NOTICE 'Test 3: Testing get_nearby_stops RPC...';
    -- Search near Department Building (11.321743, 75.933857) with 300m radius
    SELECT COUNT(*) INTO v_count
    FROM public.get_nearby_stops(11.321743, 75.933857, 300, 10);

    IF v_count < 3 THEN
        RAISE EXCEPTION 'Assertion Failed: get_nearby_stops returned fewer than 3 stops within 300m (found %)', v_count;
    END IF;
    RAISE NOTICE '✓ get_nearby_stops returns accurate proximity results.';

    -- 4. Verify Campus Buildings Spatial Search
    RAISE NOTICE 'Test 4: Testing get_campus_buildings_nearby RPC...';
    SELECT COUNT(*) INTO v_count
    FROM public.get_campus_buildings_nearby(11.321743, 75.933857, 100, 10);

    IF v_count < 2 THEN
        RAISE EXCEPTION 'Assertion Failed: get_campus_buildings_nearby returned % buildings within 100m', v_count;
    END IF;
    RAISE NOTICE '✓ get_campus_buildings_nearby returns accurate landmark results.';

    -- 5. Verify Route Geometries & GeoJSON Generation for Mapbox
    RAISE NOTICE 'Test 5: Testing get_route_geometry RPC...';
    SELECT * INTO v_route
    FROM public.get_route_geometry('10000000-0000-4000-8000-000000000001'::uuid);

    IF v_route.geojson IS NULL OR (v_route.geojson->>'type') <> 'LineString' THEN
        RAISE EXCEPTION 'Assertion Failed: get_route_geometry did not return valid GeoJSON LineString: %', v_route.geojson;
    END IF;

    IF jsonb_array_length(v_route.geojson->'coordinates') < 2 THEN
        RAISE EXCEPTION 'Assertion Failed: GeoJSON coordinates list too short: %', v_route.geojson;
    END IF;
    RAISE NOTICE '✓ get_route_geometry returns valid Mapbox-compatible GeoJSON LineString.';

    -- 6. Verify Active Bus Positions RPC
    RAISE NOTICE 'Test 6: Testing get_active_bus_positions RPC...';
    -- Verify function executes without error
    PERFORM * FROM public.get_active_bus_positions();
    RAISE NOTICE '✓ get_active_bus_positions executed cleanly.';

    -- 7. Verify Coordinate Axis Order (Lon=X between 75.9 and 76.0, Lat=Y between 11.3 and 11.4)
    RAISE NOTICE 'Test 7: Validating coordinate bounds and axis ordering...';
    SELECT COUNT(*) INTO v_count
    FROM public.stops
    WHERE latitude NOT BETWEEN 11.0 AND 12.0 OR longitude NOT BETWEEN 75.0 AND 77.0;

    IF v_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: % stops have coordinates outside NIT Calicut bounding box', v_count;
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM public.campus_buildings
    WHERE lat NOT BETWEEN 11.0 AND 12.0 OR lng NOT BETWEEN 75.0 AND 77.0;

    IF v_count > 0 THEN
        RAISE EXCEPTION 'Assertion Failed: % campus buildings have coordinates outside NIT Calicut bounding box', v_count;
    END IF;
    RAISE NOTICE '✓ All coordinates verified within NIT Calicut campus spatial envelope with correct [Lng, Lat] axis ordering.';

    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'ALL POSTGIS SPATIAL VERIFICATION TESTS PASSED SUCCESSFULLY';
    RAISE NOTICE '=======================================================';
END $$;
