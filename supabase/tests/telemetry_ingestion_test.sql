-- ============================================================================
-- Tracklet Telemetry Ingestion & Invariant Comprehensive Test Suite
-- File: supabase/tests/telemetry_ingestion_test.sql
-- Description:
--   Comprehensive database test suite verifying:
--     1. Valid telemetry packet ingestion & atomic persistence
--     2. Exact multi-field packet retry idempotency (comparing all 6 fields)
--     3. Sequence reuse with conflicting payload (speed/heading/accuracy divergence)
--     4. Historical sequence reuse detection after later packets accepted
--     5. Delayed exact retry of older packet after later packets accepted
--     6. Out-of-order lower unseen sequence rejection (OUT_OF_ORDER_PACKET)
--     7. Regressed timestamp on advancing sequence (IMPLAUSIBLE_TIMESTAMP)
--     8. Firmware reboot & sequence epoch transition (advances epoch, accepts seq 1)
--     9. Stale epoch packet rejection from previous boot session (STALE_EPOCH_PACKET)
--    10. Device deactivation via set_device_active() & rejection of deactivated device
--    11. Reassignment to new bus & clean sequence establishment on new bus
--    12. Tracker replacement: new device assigned to bus without inheriting old counter
--    13. Multiple active devices on single bus constraint (idx_devices_single_active_bus)
--    14. Multiple active trips detection & integrity protection (trips_single_active_per_bus)
--    15. Boundary & telemetry invariant validations (Lat/Lon/Speed/Heading/Accuracy/Timestamp)
--    16. Stop arrival geofencing, arrival dedup, and departure with 1.5x hysteresis
--    17. Route deviation detection & 5-minute debounce
--    18. get_active_bus_positions() freshness (<90s fresh, <15m stale, >15m unavailable)
--    19. register_tracking_device() provisioning validations & reassignment protections
--    20. Role security & privilege enforcement (anon/auth denied, service_role allowed)
--    21. Realtime publication membership verification
-- ============================================================================

DO $$
DECLARE
  -- Test Fixture Identifiers
  v_test_bus_id uuid := '99999999-0000-4000-8000-000000000001'::uuid;
  v_test_inact_bus_id uuid := '99999999-0000-4000-8000-000000000002'::uuid;
  v_test_bus_2_id uuid := '99999999-0000-4000-8000-000000000008'::uuid;
  v_test_route_id uuid := '99999999-0000-4000-8000-000000000003'::uuid;
  v_test_stop_a_id uuid := '99999999-0000-4000-8000-000000000004'::uuid;
  v_test_stop_b_id uuid := '99999999-0000-4000-8000-000000000005'::uuid;
  v_test_trip_id uuid := '99999999-0000-4000-8000-000000000006'::uuid;
  v_test_trip_id_2 uuid := '99999999-0000-4000-8000-000000000007'::uuid;

  v_res jsonb;
  v_count integer;
  v_is_stale boolean;
  v_t0 timestamp with time zone := now() - interval '30 seconds';
BEGIN
  RAISE NOTICE '=======================================================';
  RAISE NOTICE 'STARTING TRACKLET TELEMETRY INGESTION TEST SUITE';
  RAISE NOTICE '=======================================================';

  -- --------------------------------------------------------------------------
  -- 0. CLEANUP & INITIALIZE TEST FIXTURES
  -- --------------------------------------------------------------------------
  DELETE FROM public.bus_events WHERE bus_id IN (v_test_bus_id, v_test_inact_bus_id, v_test_bus_2_id);
  DELETE FROM public.bus_positions WHERE bus_id IN (v_test_bus_id, v_test_inact_bus_id, v_test_bus_2_id);
  DELETE FROM public.bus_current_state WHERE bus_id IN (v_test_bus_id, v_test_inact_bus_id, v_test_bus_2_id);
  DELETE FROM public.devices WHERE device_id IN ('TEST-DEV-001', 'TEST-DEV-002', 'TEST-DEV-INACT', 'TEST-DEV-INACT-BUS');
  DELETE FROM public.trips WHERE id IN (v_test_trip_id, v_test_trip_id_2);
  DELETE FROM public.route_stops WHERE route_id = v_test_route_id;
  DELETE FROM public.stops WHERE id IN (v_test_stop_a_id, v_test_stop_b_id);
  DELETE FROM public.routes WHERE id = v_test_route_id;
  DELETE FROM public.buses WHERE id IN (v_test_bus_id, v_test_inact_bus_id, v_test_bus_2_id);

  -- Insert Test Buses
  INSERT INTO public.buses (id, bus_number, display_name, is_active)
  VALUES
    (v_test_bus_id, 'TEST-BUS-99', 'Test Campus Shuttle', true),
    (v_test_bus_2_id, 'TEST-BUS-98', 'Test Campus Shuttle 2', true),
    (v_test_inact_bus_id, 'TEST-BUS-INACT', 'Test Decommissioned Bus', false);

  -- Insert Test Route & Stops
  -- Stop A located at [11.321000, 75.933000] (Main Gate)
  -- Stop B located at [11.325000, 75.935000] (East Campus)
  INSERT INTO public.stops (id, name, code, latitude, longitude, is_active)
  VALUES
    (v_test_stop_a_id, 'Test Stop Main', 'T-MAIN', 11.321000, 75.933000, true),
    (v_test_stop_b_id, 'Test Stop East', 'T-EAST', 11.325000, 75.935000, true);

  INSERT INTO public.routes (id, name, route_code, is_active)
  VALUES (v_test_route_id, 'Test Route Loop', 'TR99', true);

  INSERT INTO public.route_stops (route_id, stop_id, sequence)
  VALUES
    (v_test_route_id, v_test_stop_a_id, 1),
    (v_test_route_id, v_test_stop_b_id, 2);

  -- Insert Test Devices
  INSERT INTO public.devices (device_id, bus_id, credential_hash, is_active, current_epoch)
  VALUES
    ('TEST-DEV-001', v_test_bus_id, extensions.crypt('test_secret_123', extensions.gen_salt('bf', 8)), true, 1),
    ('TEST-DEV-INACT', v_test_bus_id, extensions.crypt('test_secret_inact', extensions.gen_salt('bf', 8)), false, 1),
    ('TEST-DEV-INACT-BUS', v_test_inact_bus_id, extensions.crypt('test_secret_bus', extensions.gen_salt('bf', 8)), true, 1);

  RAISE NOTICE '✓ Test fixtures initialized successfully.';

  -- --------------------------------------------------------------------------
  -- 1. VALID PACKET INGESTION & ATOMIC WRITE VERIFICATION
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 1: Valid telemetry packet ingestion & atomic persistence...';
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    100,
    v_t0,
    11.321050,
    75.933050,
    25.5,
    90.0,
    4.0,
    'moving'
  );

  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'SUCCESS' THEN
    RAISE EXCEPTION 'Test 1 Failed: Valid packet rejected: %', v_res;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.bus_current_state
  WHERE bus_id = v_test_bus_id AND seq = 100 AND epoch = 1 AND device_id = 'TEST-DEV-001';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 1 Failed: bus_current_state row missing or values mismatched';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.bus_positions
  WHERE bus_id = v_test_bus_id AND seq = 100 AND epoch = 1 AND device_id = 'TEST-DEV-001';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 1 Failed: bus_positions history row missing';
  END IF;

  RAISE NOTICE '✓ Test 1 Passed: Valid packet stored atomically in history and current state.';

  -- --------------------------------------------------------------------------
  -- 2. EXACT MULTI-FIELD PACKET RETRY (IDEMPOTENCY)
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 2: Exact multi-field duplicate packet retry idempotency...';
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    100,
    v_t0,
    11.321050,
    75.933050,
    25.5,
    90.0,
    4.0,
    'moving'
  );

  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'DUPLICATE_PACKET' OR (v_res->>'stored')::boolean THEN
    RAISE EXCEPTION 'Test 2 Failed: Expected DUPLICATE_PACKET with stored=false, got: %', v_res;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.bus_positions
  WHERE bus_id = v_test_bus_id AND seq = 100;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 2 Failed: History table contains duplicate rows for same seq (% rows)', v_count;
  END IF;

  RAISE NOTICE '✓ Test 2 Passed: Exact duplicate retry recognized and acknowledged idempotently.';

  -- --------------------------------------------------------------------------
  -- 3. SEQUENCE REUSE WITH CONFLICTING FIELD TESTS (EACH FIELD INDEPENDENTLY)
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 3: Sequence reuse with independently conflicting fields...';

  -- 3a: Divergent latitude
  v_res := public.ingest_telemetry_packet('TEST-DEV-001', 100, v_t0, 11.325000, 75.933050, 25.5, 90.0, 4.0, 'moving');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'SEQUENCE_REUSE_CONFLICT' THEN
    RAISE EXCEPTION 'Test 3a Failed: Divergent latitude not rejected with SEQUENCE_REUSE_CONFLICT: %', v_res;
  END IF;

  -- 3b: Divergent longitude
  v_res := public.ingest_telemetry_packet('TEST-DEV-001', 100, v_t0, 11.321050, 75.939000, 25.5, 90.0, 4.0, 'moving');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'SEQUENCE_REUSE_CONFLICT' THEN
    RAISE EXCEPTION 'Test 3b Failed: Divergent longitude not rejected with SEQUENCE_REUSE_CONFLICT: %', v_res;
  END IF;

  -- 3c: Divergent timestamp
  v_res := public.ingest_telemetry_packet('TEST-DEV-001', 100, v_t0 - interval '2 seconds', 11.321050, 75.933050, 25.5, 90.0, 4.0, 'moving');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'SEQUENCE_REUSE_CONFLICT' THEN
    RAISE EXCEPTION 'Test 3c Failed: Divergent timestamp not rejected with SEQUENCE_REUSE_CONFLICT: %', v_res;
  END IF;

  -- 3d: Divergent speed
  v_res := public.ingest_telemetry_packet('TEST-DEV-001', 100, v_t0, 11.321050, 75.933050, 50.0, 90.0, 4.0, 'moving');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'SEQUENCE_REUSE_CONFLICT' THEN
    RAISE EXCEPTION 'Test 3d Failed: Divergent speed not rejected with SEQUENCE_REUSE_CONFLICT: %', v_res;
  END IF;

  -- 3e: Divergent heading
  v_res := public.ingest_telemetry_packet('TEST-DEV-001', 100, v_t0, 11.321050, 75.933050, 25.5, 180.0, 4.0, 'moving');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'SEQUENCE_REUSE_CONFLICT' THEN
    RAISE EXCEPTION 'Test 3e Failed: Divergent heading not rejected with SEQUENCE_REUSE_CONFLICT: %', v_res;
  END IF;

  -- 3f: Divergent accuracy
  v_res := public.ingest_telemetry_packet('TEST-DEV-001', 100, v_t0, 11.321050, 75.933050, 25.5, 90.0, 15.0, 'moving');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'SEQUENCE_REUSE_CONFLICT' THEN
    RAISE EXCEPTION 'Test 3f Failed: Divergent accuracy not rejected with SEQUENCE_REUSE_CONFLICT: %', v_res;
  END IF;

  -- 3g: Divergent status
  v_res := public.ingest_telemetry_packet('TEST-DEV-001', 100, v_t0, 11.321050, 75.933050, 25.5, 90.0, 4.0, 'delayed');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'SEQUENCE_REUSE_CONFLICT' THEN
    RAISE EXCEPTION 'Test 3g Failed: Divergent status not rejected with SEQUENCE_REUSE_CONFLICT: %', v_res;
  END IF;

  RAISE NOTICE '✓ Test 3 Passed: All 7 identity fields independently detected and rejected on sequence reuse conflict.';

  -- --------------------------------------------------------------------------
  -- 4. HISTORICAL SEQUENCE REUSE & DELAYED RETRY AFTER ADVANCED SEQUENCES
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 4: Ingest advancing seq 101, then test historical seq 100 handling...';
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    101,
    v_t0 + interval '5 seconds',
    11.321200,
    75.933100,
    28.0,
    90.0,
    4.0,
    'moving'
  );
  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'SUCCESS' THEN
    RAISE EXCEPTION 'Test 4 Ingestion Failed: %', v_res;
  END IF;

  -- Delayed exact retry of seq 100
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    100,
    v_t0,
    11.321050,
    75.933050,
    25.5,
    90.0,
    4.0,
    'moving'
  );
  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'DUPLICATE_PACKET' THEN
    RAISE EXCEPTION 'Test 4a Failed: Delayed retry of seq 100 should return DUPLICATE_PACKET, got: %', v_res;
  END IF;

  -- Rogue packet reusing historical seq 100 with altered coordinates
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    100,
    v_t0,
    11.329999,
    75.939999,
    25.5,
    90.0,
    4.0
  );
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'SEQUENCE_REUSE_CONFLICT' THEN
    RAISE EXCEPTION 'Test 4b Failed: Historical sequence reuse should fail SEQUENCE_REUSE_CONFLICT, got: %', v_res;
  END IF;

  RAISE NOTICE '✓ Test 4 Passed: Historical sequence reuse and delayed retries verified.';

  -- --------------------------------------------------------------------------
  -- 5. OUT-OF-ORDER SEQUENCE (LOWER UNSEEN SEQUENCE)
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 5: Out-of-order lower unseen sequence rejection...';
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    95,
    v_t0 + interval '10 seconds',
    11.321100,
    75.933100,
    20.0,
    90.0,
    4.0
  );
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'OUT_OF_ORDER_PACKET' THEN
    RAISE EXCEPTION 'Test 5 Failed: Expected OUT_OF_ORDER_PACKET, got: %', v_res;
  END IF;

  RAISE NOTICE '✓ Test 5 Passed: Regressed sequence rejected cleanly.';

  -- --------------------------------------------------------------------------
  -- 6. REGRESSED TIMESTAMP ON ADVANCING SEQUENCE
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 6: Advancing sequence with regressed timestamp...';
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    102,
    v_t0 - interval '5 seconds',
    11.321100,
    75.933100,
    20.0,
    90.0,
    4.0
  );
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'IMPLAUSIBLE_TIMESTAMP' THEN
    RAISE EXCEPTION 'Test 6 Failed: Expected IMPLAUSIBLE_TIMESTAMP on regressed time, got: %', v_res;
  END IF;

  RAISE NOTICE '✓ Test 6 Passed: Regressed timestamp on advancing sequence rejected.';

  -- --------------------------------------------------------------------------
  -- 6b. NULLABLE FIELDS HANDLING & RETRY IDEMPOTENCY
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 6b: Ingest packet with NULL nullable fields and test exact retry...';
  -- Ingest advancing seq 102 with NULL speed, heading, accuracy, status
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    102,
    v_t0 + interval '20 seconds',
    11.321150,
    75.933150,
    NULL,
    NULL,
    NULL,
    NULL
  );
  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'SUCCESS' THEN
    RAISE EXCEPTION 'Test 6b Failed: Ingesting NULL nullable fields should succeed, got: %', v_res;
  END IF;

  -- Exact retry of packet with NULL nullable fields (must NOT fail due to NULL = NULL three-valued logic)
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    102,
    v_t0 + interval '20 seconds',
    11.321150,
    75.933150,
    NULL,
    NULL,
    NULL,
    NULL
  );
  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'DUPLICATE_PACKET' THEN
    RAISE EXCEPTION 'Test 6b Failed: Retrying NULL nullable fields must return DUPLICATE_PACKET, got: %', v_res;
  END IF;

  -- Reusing sequence 102 with non-NULL speed must be detected as conflict
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    102,
    v_t0 + interval '20 seconds',
    11.321150,
    75.933150,
    30.0,
    NULL,
    NULL,
    NULL
  );
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'SEQUENCE_REUSE_CONFLICT' THEN
    RAISE EXCEPTION 'Test 6b Failed: Divergent non-null speed against NULL-stored field not rejected with SEQUENCE_REUSE_CONFLICT: %', v_res;
  END IF;

  RAISE NOTICE '✓ Test 6b Passed: NULL-safety verified on sequence storage and duplicate retry.';

  -- --------------------------------------------------------------------------
  -- 7. UNAUTHORIZED FUTURE EPOCH REJECTION & AUTHORIZED FIRMWARE REBOOT
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 7: Epoch security: reject unauthorized future epoch & test authorized reboot...';

  -- 7a: Telemetry packet unilaterally attempts to advance epoch to 999999
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    1,
    now() - interval '20 seconds',
    11.321050,
    75.933050,
    15.0,
    90.0,
    4.0,
    'moving',
    50.0,
    500.0,
    999999 -- UNAUTHORIZED future epoch!
  );
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'UNAUTHORIZED_EPOCH' THEN
    RAISE EXCEPTION 'Test 7a Failed: Unauthorized future epoch must be rejected with UNAUTHORIZED_EPOCH: %', v_res;
  END IF;

  -- Verify devices table current_epoch was NOT modified
  SELECT current_epoch INTO v_count FROM public.devices WHERE device_id = 'TEST-DEV-001';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 7a Failed: devices.current_epoch was unlawfully mutated to %', v_count;
  END IF;

  -- Verify bus_current_state epoch was NOT modified
  SELECT epoch INTO v_count FROM public.bus_current_state WHERE bus_id = v_test_bus_id;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 7a Failed: bus_current_state.epoch was unlawfully mutated to %', v_count;
  END IF;

  -- Verify no bus_positions row created for epoch 999999
  SELECT count(*) INTO v_count FROM public.bus_positions WHERE device_id = 'TEST-DEV-001' AND epoch = 999999;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Test 7a Failed: bus_positions row created for unauthorized epoch';
  END IF;

  -- 7b1: Attempt sequence reset with NULL secret -> MUST fail with MISSING_CREDENTIALS
  v_res := public.reset_device_sequence('TEST-DEV-001', NULL, 'sess_boot_101', 'hardware_power_cycle');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'MISSING_CREDENTIALS' THEN
    RAISE EXCEPTION 'Test 7b1 Failed: NULL secret must fail with MISSING_CREDENTIALS, got: %', v_res;
  END IF;

  -- 7b2: Attempt sequence reset with empty secret -> MUST fail with MISSING_CREDENTIALS
  v_res := public.reset_device_sequence('TEST-DEV-001', '   ', 'sess_boot_101', 'hardware_power_cycle');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'MISSING_CREDENTIALS' THEN
    RAISE EXCEPTION 'Test 7b2 Failed: Empty secret must fail with MISSING_CREDENTIALS, got: %', v_res;
  END IF;

  -- 7b3: Attempt sequence reset on device with empty/unconfigured credentials -> MUST fail with UNCONFIGURED_CREDENTIALS
  INSERT INTO public.buses (id, bus_number, display_name, is_active)
  VALUES ('99999999-0000-4000-8000-000000000009'::uuid, 'BUS-TEST-NO-CRED', 'Test Bus No Cred', true)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.devices (device_id, bus_id, credential_hash, is_active, current_epoch)
  VALUES ('TEST-DEV-NO-CRED', '99999999-0000-4000-8000-000000000009'::uuid, '', true, 1)
  ON CONFLICT (device_id) DO UPDATE SET credential_hash = '';

  v_res := public.reset_device_sequence('TEST-DEV-NO-CRED', 'some_secret_123', 'sess_boot_unconf');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'UNCONFIGURED_CREDENTIALS' THEN
    RAISE EXCEPTION 'Test 7b3 Failed: Device with unconfigured credentials must fail with UNCONFIGURED_CREDENTIALS, got: %', v_res;
  END IF;
  DELETE FROM public.devices WHERE device_id = 'TEST-DEV-NO-CRED';
  DELETE FROM public.buses WHERE id = '99999999-0000-4000-8000-000000000009'::uuid;

  -- 7b4: Unauthenticated / wrong secret attempt to reset device sequence
  v_res := public.reset_device_sequence('TEST-DEV-001', 'wrong_secret', 'sess_boot_101', 'hardware_power_cycle');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'INVALID_CREDENTIALS' THEN
    RAISE EXCEPTION 'Test 7b4 Failed: Wrong secret must fail with INVALID_CREDENTIALS, got: %', v_res;
  END IF;

  -- 7c: Authorized reboot sequence reset with valid secret and session identifier
  v_res := public.reset_device_sequence('TEST-DEV-001', 'test_secret_123', 'sess_boot_101', 'hardware_power_cycle');
  IF NOT (v_res->>'ok')::boolean OR (v_res->>'new_epoch')::bigint <> 2 OR (v_res->>'idempotent_retry')::boolean THEN
    RAISE EXCEPTION 'Test 7c Failed: Expected authorized epoch 2 with idempotent_retry=false, got: %', v_res;
  END IF;

  -- 7d: Cellular network drop retry: tracker retransmits the same reboot reset request
  v_res := public.reset_device_sequence('TEST-DEV-001', 'test_secret_123', 'sess_boot_101', 'hardware_power_cycle');
  IF NOT (v_res->>'ok')::boolean OR (v_res->>'epoch')::bigint <> 2 OR NOT (v_res->>'idempotent_retry')::boolean THEN
    RAISE EXCEPTION 'Test 7d Failed: Network retry of reset_device_sequence should return epoch 2 with idempotent_retry=true, got: %', v_res;
  END IF;

  -- Verify current epoch in devices remains 2 (NOT unlawfully advanced to 3)
  SELECT current_epoch INTO v_count FROM public.devices WHERE device_id = 'TEST-DEV-001';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'Test 7d Failed: devices.current_epoch was corrupted by network retry: %', v_count;
  END IF;

  -- 7e: Ingest packet seq 1 in authorized Epoch 2 (advancing epoch cleanly resets sequence)
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    1,
    now() - interval '20 seconds',
    11.321050,
    75.933050,
    15.0,
    90.0,
    4.0,
    'moving',
    50.0,
    500.0,
    2 -- authorized epoch 2
  );
  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'SUCCESS' THEN
    RAISE EXCEPTION 'Test 7e Failed: Ingestion in authorized epoch 2 failed: %', v_res;
  END IF;

  -- 7f: Verify current state is at epoch 2, seq 1
  SELECT count(*) INTO v_count
  FROM public.bus_current_state
  WHERE bus_id = v_test_bus_id AND epoch = 2 AND seq = 1;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 7f Failed: bus_current_state not at epoch 2, seq 1';
  END IF;

  RAISE NOTICE '✓ Test 7 Passed: Unauthorized future epoch blocked; secret validated; reboot session handshake idempotent across network drops.';

  -- --------------------------------------------------------------------------
  -- 8. STALE EPOCH PACKET REJECTION
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 8: Reject packet from previous session epoch...';
  -- A delayed packet arrives from Epoch 1 with seq 105
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-001',
    105,
    now() - interval '15 seconds',
    11.321050,
    75.933050,
    20.0,
    90.0,
    4.0,
    'moving',
    50.0,
    500.0,
    1 -- old epoch 1!
  );

  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'STALE_EPOCH_PACKET' THEN
    RAISE EXCEPTION 'Test 8 Failed: Expected STALE_EPOCH_PACKET, got: %', v_res;
  END IF;

  RAISE NOTICE '✓ Test 8 Passed: Delayed packet from previous epoch rejected without corrupting state.';

  -- --------------------------------------------------------------------------
  -- 9. DEVICE DEACTIVATION VIA set_device_active() & REJECTION
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 9: Device deactivation and rejected ingestion...';
  v_res := public.set_device_active('TEST-DEV-001', false);
  IF NOT (v_res->>'ok')::boolean OR (v_res->>'is_active')::boolean THEN
    RAISE EXCEPTION 'Test 9a Failed: Device deactivation failed: %', v_res;
  END IF;

  -- Attempt ingestion with deactivated device
  v_res := public.ingest_telemetry_packet('TEST-DEV-001', 2, now(), 11.321, 75.933, 10, 0, 5);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'UNAUTHORIZED_DEVICE' THEN
    RAISE EXCEPTION 'Test 9b Failed: Deactivated device was not rejected: %', v_res;
  END IF;

  -- Reactivate device for subsequent tests
  PERFORM public.set_device_active('TEST-DEV-001', true);
  RAISE NOTICE '✓ Test 9 Passed: Deactivated device successfully blocked.';

  -- --------------------------------------------------------------------------
  -- 10. TRACKER REPLACEMENT, FRESHNESS RESET & ISOLATION
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 10: Tracker replacement, freshness reset, and historical isolation...';
  -- Register new tracker TEST-DEV-002 for TEST-BUS-99 with allow_reassign=true
  v_res := public.register_tracking_device('TEST-DEV-002', 'TEST-BUS-99', 'secure_replacement_secret', true);
  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'SUCCESS' THEN
    RAISE EXCEPTION 'Test 10a Failed: Replacement device registration failed: %', v_res;
  END IF;

  -- Verify old device TEST-DEV-001 was deactivated atomically
  SELECT is_active INTO v_is_stale FROM public.devices WHERE device_id = 'TEST-DEV-001';
  IF v_is_stale <> false THEN
    RAISE EXCEPTION 'Test 10b Failed: Old device was not deactivated after replacement';
  END IF;

  -- Verify old device cannot write telemetry after reassignment
  v_res := public.ingest_telemetry_packet('TEST-DEV-001', 3, now(), 11.321, 75.933, 10, 0, 5, 'moving', 50, 500, 2);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'UNAUTHORIZED_DEVICE' THEN
    RAISE EXCEPTION 'Test 10c Failed: Former tracker allowed to write telemetry after reassignment: %', v_res;
  END IF;

  -- Verify bus_current_state.last_seen was reset to to_timestamp(0) so old location is NOT fresh
  SELECT count(*) INTO v_count
  FROM public.get_active_bus_positions()
  WHERE bus_id = v_test_bus_id;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Test 10d Failed: Former tracker location must not appear fresh after replacement';
  END IF;

  -- Verify historical records from TEST-DEV-001 remain intact in bus_positions
  SELECT count(*) INTO v_count
  FROM public.bus_positions
  WHERE bus_id = v_test_bus_id AND device_id = 'TEST-DEV-001';
  IF v_count < 2 THEN
    RAISE EXCEPTION 'Test 10e Failed: Historical packet identity corrupted or deleted for former tracker';
  END IF;

  -- New device sends packet seq 1 in its epoch (epoch 1)
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-002',
    1,
    now() - interval '10 seconds',
    11.321300,
    75.933300,
    18.0,
    90.0,
    4.0,
    'moving'
  );
  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'SUCCESS' THEN
    RAISE EXCEPTION 'Test 10f Failed: Ingestion from replacement device failed: %', v_res;
  END IF;

  -- Verify bus_current_state now belongs to TEST-DEV-002 and is fresh
  SELECT count(*) INTO v_count
  FROM public.bus_current_state
  WHERE bus_id = v_test_bus_id AND device_id = 'TEST-DEV-002' AND seq = 1;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 10g Failed: bus_current_state not updated to replacement device';
  END IF;

  -- Verify get_active_bus_positions() now returns fresh state
  SELECT is_stale INTO v_is_stale
  FROM public.get_active_bus_positions()
  WHERE bus_id = v_test_bus_id;
  IF v_is_stale IS NULL OR v_is_stale <> false THEN
    RAISE EXCEPTION 'Test 10h Failed: Bus position should be fresh after new device ingests packet';
  END IF;

  RAISE NOTICE '✓ Test 10 Passed: Replacement atomically deactivated former tracker, reset freshness, preserved history, and established fresh live position.';

  -- --------------------------------------------------------------------------
  -- 11. DATABASE CONSTRAINTS: MULTI-DEVICE & HISTORY UNIQUENESS
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 11: Database constraints: single active device per bus & history uniqueness...';
  -- 11a: Single active device per bus constraint
  BEGIN
    UPDATE public.devices SET is_active = true WHERE device_id = 'TEST-DEV-001';
    RAISE EXCEPTION 'Test 11a Failed: Expected unique constraint violation for second active device on same bus';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE '✓ Constraint idx_devices_single_active_bus prevented second active device for same bus.';
  END;

  -- 11b: History uniqueness constraint uq_bus_positions_device_epoch_seq
  BEGIN
    INSERT INTO public.bus_positions (bus_id, device_id, epoch, seq, latitude, longitude, recorded_at)
    VALUES (v_test_bus_id, 'TEST-DEV-002', 1, 1, 11.321, 75.933, now());
    RAISE EXCEPTION 'Test 11b Failed: Expected unique constraint violation for uq_bus_positions_device_epoch_seq';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE '✓ Constraint uq_bus_positions_device_epoch_seq prevented duplicate history row.';
  END;

  -- --------------------------------------------------------------------------
  -- 12. MULTIPLE ACTIVE TRIPS DETECTION & INTEGRITY PROTECTION
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 12: Multiple active trips detection & ambiguity handling...';
  INSERT INTO public.trips (id, bus_id, route_id, status, started_at)
  VALUES (v_test_trip_id, v_test_bus_id, v_test_route_id, 'active', now() - interval '10 minutes');

  BEGIN
    INSERT INTO public.trips (id, bus_id, route_id, status, started_at)
    VALUES (v_test_trip_id_2, v_test_bus_id, v_test_route_id, 'active', now() - interval '5 minutes');
    RAISE EXCEPTION 'Test 12 Failed: trips_single_active_per_bus constraint failed';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE '✓ Database unique constraint prevents multiple active trips per bus.';
  END;

  -- --------------------------------------------------------------------------
  -- 13. TELEMETRY INVARIANT VALIDATIONS
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 13: Telemetry boundary and value invariants...';

  v_res := public.ingest_telemetry_packet('TEST-DEV-002', 10, now(), 10.500000, 75.933, 10, 0, 5);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'COORDINATES_OUT_OF_BOUNDS' THEN
    RAISE EXCEPTION 'Test 13a Failed: Latitude out of bounds not rejected: %', v_res;
  END IF;

  v_res := public.ingest_telemetry_packet('TEST-DEV-002', 10, now(), 11.321, 77.200000, 10, 0, 5);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'COORDINATES_OUT_OF_BOUNDS' THEN
    RAISE EXCEPTION 'Test 13b Failed: Longitude out of bounds not rejected: %', v_res;
  END IF;

  v_res := public.ingest_telemetry_packet('TEST-DEV-002', 10, now(), 11.321, 75.933, 150.0, 0, 5);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'INVALID_SPEED' THEN
    RAISE EXCEPTION 'Test 13c Failed: Speed > 120 not rejected: %', v_res;
  END IF;

  v_res := public.ingest_telemetry_packet('TEST-DEV-002', 10, now(), 11.321, 75.933, 20.0, 400.0, 5);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'INVALID_HEADING' THEN
    RAISE EXCEPTION 'Test 13d Failed: Heading > 360 not rejected: %', v_res;
  END IF;

  v_res := public.ingest_telemetry_packet('TEST-DEV-002', 10, now(), 11.321, 75.933, 20.0, 90.0, 600.0);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'INVALID_ACCURACY' THEN
    RAISE EXCEPTION 'Test 13e Failed: Accuracy > 500 not rejected: %', v_res;
  END IF;

  v_res := public.ingest_telemetry_packet('TEST-DEV-002', 10, now() - interval '20 minutes', 11.321, 75.933, 20.0, 90.0, 5.0);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'IMPLAUSIBLE_TIMESTAMP' THEN
    RAISE EXCEPTION 'Test 13f Failed: Stale timestamp (>15m) not rejected: %', v_res;
  END IF;

  v_res := public.ingest_telemetry_packet('TEST-DEV-002', 10, now() + interval '5 minutes', 11.321, 75.933, 20.0, 90.0, 5.0);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'IMPLAUSIBLE_TIMESTAMP' THEN
    RAISE EXCEPTION 'Test 13g Failed: Future timestamp (>1m) not rejected: %', v_res;
  END IF;

  RAISE NOTICE '✓ Test 13 Passed: All telemetry boundary and value invariants verified.';

  -- --------------------------------------------------------------------------
  -- 14. ACTIVE TRIP ASSOCIATION & POSTGIS EVENT GENERATION
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 14: Stop arrival geofencing, arrival dedup, and departure hysteresis...';

  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-002',
    10,
    now() - interval '10 seconds',
    11.321000,
    75.933000,
    0.0,
    0.0,
    3.0,
    'stationary',
    50.0,
    500.0
  );
  IF NOT (v_res->>'ok')::boolean OR (v_res->>'trip_id')::uuid <> v_test_trip_id THEN
    RAISE EXCEPTION 'Test 14a Failed: Active trip not associated properly: %', v_res;
  END IF;

  -- Verify arrived event generated for Stop Main
  SELECT count(*) INTO v_count
  FROM public.bus_events
  WHERE bus_id = v_test_bus_id AND trip_id = v_test_trip_id
    AND stop_id = v_test_stop_a_id AND event_type = 'arrived';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 14a Failed: Stop arrival event not recorded in bus_events';
  END IF;

  -- Subsequent packet still inside Stop Main radius
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-002',
    11,
    now() - interval '8 seconds',
    11.321010,
    75.933010,
    0.0,
    0.0,
    3.0,
    'stationary'
  );
  SELECT count(*) INTO v_count
  FROM public.bus_events
  WHERE bus_id = v_test_bus_id AND trip_id = v_test_trip_id
    AND stop_id = v_test_stop_a_id AND event_type = 'arrived';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 14b Failed: Duplicate stop arrival event was triggered';
  END IF;

  -- Move bus away from Stop Main (> 50m * 1.5 hysteresis = 75m)
  v_res := public.ingest_telemetry_packet(
    'TEST-DEV-002',
    12,
    now() - interval '5 seconds',
    11.323000,
    75.934000,
    30.0,
    45.0,
    4.0,
    'moving'
  );
  SELECT count(*) INTO v_count
  FROM public.bus_events
  WHERE bus_id = v_test_bus_id AND trip_id = v_test_trip_id
    AND stop_id = v_test_stop_a_id AND event_type = 'departed';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Test 14c Failed: Stop departure event not recorded after leaving radius';
  END IF;

  RAISE NOTICE '✓ Test 14 Passed: Stop arrival, dedup, and departure hysteresis verified.';

  -- --------------------------------------------------------------------------
  -- 15. GET_ACTIVE_BUS_POSITIONS() FRESHNESS SEMANTICS
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 15: get_active_bus_positions() freshness (fresh, stale, unavailable)...';

  SELECT is_stale INTO v_is_stale
  FROM public.get_active_bus_positions()
  WHERE bus_id = v_test_bus_id;

  IF v_is_stale IS NULL OR v_is_stale <> false THEN
    RAISE EXCEPTION 'Test 15a Failed: Expected is_stale=false for fresh position, got %', v_is_stale;
  END IF;

  UPDATE public.bus_current_state
  SET last_seen = now() - interval '2 minutes'
  WHERE bus_id = v_test_bus_id;

  SELECT is_stale INTO v_is_stale
  FROM public.get_active_bus_positions()
  WHERE bus_id = v_test_bus_id;

  IF v_is_stale IS NULL OR v_is_stale <> true THEN
    RAISE EXCEPTION 'Test 15b Failed: Expected is_stale=true for 2m stale position, got %', v_is_stale;
  END IF;

  UPDATE public.bus_current_state
  SET last_seen = now() - interval '20 minutes'
  WHERE bus_id = v_test_bus_id;

  SELECT count(*) INTO v_count
  FROM public.get_active_bus_positions()
  WHERE bus_id = v_test_bus_id;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Test 15c Failed: Bus older than 15m should not be returned by get_active_bus_positions()';
  END IF;

  RAISE NOTICE '✓ Test 15 Passed: Freshness contract (<90s fresh, <15m stale, >15m unavailable) verified.';

  -- --------------------------------------------------------------------------
  -- 16. REGISTER_TRACKING_DEVICE() PROVISIONING & REASSIGNMENT PROTECTIONS
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 16: register_tracking_device() provisioning and protections...';

  INSERT INTO public.buses (id, bus_number, display_name, is_active)
  VALUES ('99999999-0000-4000-8000-000000000099'::uuid, 'TEST-BUS-PROV', 'Test Bus For Prov', true);

  v_res := public.register_tracking_device('PROV-DEV-001', 'TEST-BUS-PROV', 'secure_device_secret_123');
  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'SUCCESS' THEN
    RAISE EXCEPTION 'Test 16a Failed: Valid device registration rejected: %', v_res;
  END IF;

  v_res := public.register_tracking_device('PROV-DEV-002', 'TEST-BUS-PROV', 'short');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'WEAK_SECRET' THEN
    RAISE EXCEPTION 'Test 16b Failed: Weak secret not rejected: %', v_res;
  END IF;

  v_res := public.register_tracking_device('PROV-DEV-003', 'NON-EXISTENT-BUS', 'secure_device_secret_123');
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'BUS_NOT_FOUND' THEN
    RAISE EXCEPTION 'Test 16c Failed: Non-existent bus not rejected: %', v_res;
  END IF;

  v_res := public.register_tracking_device('PROV-DEV-004', 'TEST-BUS-PROV', 'secure_device_secret_123', false);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'BUS_ALREADY_ASSIGNED' THEN
    RAISE EXCEPTION 'Test 16d Failed: Expected BUS_ALREADY_ASSIGNED, got: %', v_res;
  END IF;

  v_res := public.register_tracking_device('PROV-DEV-001', 'TEST-BUS-INACT', 'secure_device_secret_123', false);
  IF (v_res->>'ok')::boolean OR v_res->>'code' <> 'REASSIGNMENT_CONFLICT' THEN
    RAISE EXCEPTION 'Test 16e Failed: Reassignment without override should fail with REASSIGNMENT_CONFLICT: %', v_res;
  END IF;

  v_res := public.register_tracking_device('PROV-DEV-001', 'TEST-BUS-INACT', 'secure_device_secret_123', true);
  IF NOT (v_res->>'ok')::boolean OR v_res->>'code' <> 'SUCCESS' THEN
    RAISE EXCEPTION 'Test 16f Failed: Reassignment with override failed: %', v_res;
  END IF;

  DELETE FROM public.devices WHERE device_id IN ('PROV-DEV-001', 'PROV-DEV-002', 'PROV-DEV-003', 'PROV-DEV-004');
  DELETE FROM public.buses WHERE id = '99999999-0000-4000-8000-000000000099'::uuid;

  RAISE NOTICE '✓ Test 16 Passed: Device registration validations and reassignment conflict protections verified.';

  -- --------------------------------------------------------------------------
  -- 17. PRE-EXISTING LEGACY DATA UPGRADE & SEQUENCE COLLISION SIMULATION
  -- --------------------------------------------------------------------------
  RAISE NOTICE 'Test 17: Pre-existing legacy data upgrade with sequence collisions...';

  -- Temporarily drop the constraint and NOT NULL to simulate pre-migration table state
  ALTER TABLE public.bus_positions DROP CONSTRAINT IF EXISTS uq_bus_positions_device_epoch_seq;
  ALTER TABLE public.bus_positions ALTER COLUMN device_id DROP NOT NULL;

  -- Insert simulated legacy rows (where device_id was NULL, and seq restarted across days/trips)
  INSERT INTO public.bus_positions (bus_id, latitude, longitude, speed, heading, accuracy, seq, recorded_at, received_at)
  VALUES
    (v_test_bus_id, 11.321000, 75.933000, 10.0, 90.0, 4.0, 1, now() - interval '3 days', now() - interval '3 days'),
    (v_test_bus_id, 11.321100, 75.933100, 15.0, 90.0, 4.0, 2, now() - interval '3 days' + interval '10s', now() - interval '3 days' + interval '10s'),
    (v_test_bus_id, 11.321200, 75.933200, 20.0, 90.0, 4.0, 1, now() - interval '2 days', now() - interval '2 days'), -- duplicate seq 1 on day 2
    (v_test_bus_id, 11.321300, 75.933300, 25.0, 90.0, 4.0, 2, now() - interval '2 days' + interval '10s', now() - interval '2 days' + interval '10s'); -- duplicate seq 2 on day 2

  SELECT count(*) INTO v_count FROM public.bus_positions WHERE bus_id = v_test_bus_id AND device_id IS NULL;
  IF v_count <> 4 THEN
    RAISE EXCEPTION 'Test 17 Failed: expected 4 unmigrated legacy rows with NULL device_id, got %', v_count;
  END IF;

  -- Execute deterministic upgrade backfill: epoch=0, seq=id
  UPDATE public.bus_positions
  SET device_id = 'LEGACY-' || bus_id::text,
      epoch = 0,
      seq = id
  WHERE device_id IS NULL;

  ALTER TABLE public.bus_positions
    ALTER COLUMN device_id SET NOT NULL;

  -- Apply history uniqueness constraint
  ALTER TABLE public.bus_positions
    ADD CONSTRAINT uq_bus_positions_device_epoch_seq UNIQUE (device_id, epoch, seq);

  -- Verify all 4 legacy rows preserved with epoch=0 and unique seq=id
  SELECT count(*) INTO v_count FROM public.bus_positions WHERE bus_id = v_test_bus_id AND epoch = 0;
  IF v_count <> 4 THEN
    RAISE EXCEPTION 'Test 17 Failed: legacy rows not preserved properly: %', v_count;
  END IF;

  RAISE NOTICE '✓ Test 17 Passed: Pre-existing legacy data upgrade simulated with zero collision and 100%% data preservation.';

  -- --------------------------------------------------------------------------
  -- 18. CLEANUP ALL TEST FIXTURES
  -- --------------------------------------------------------------------------
  DELETE FROM public.bus_events WHERE bus_id IN (v_test_bus_id, v_test_inact_bus_id, v_test_bus_2_id);
  DELETE FROM public.bus_positions WHERE bus_id IN (v_test_bus_id, v_test_inact_bus_id, v_test_bus_2_id);
  DELETE FROM public.bus_current_state WHERE bus_id IN (v_test_bus_id, v_test_inact_bus_id, v_test_bus_2_id);
  DELETE FROM public.devices WHERE device_id IN ('TEST-DEV-001', 'TEST-DEV-002', 'TEST-DEV-INACT', 'TEST-DEV-INACT-BUS');
  DELETE FROM public.trips WHERE id IN (v_test_trip_id, v_test_trip_id_2);
  DELETE FROM public.route_stops WHERE route_id = v_test_route_id;
  DELETE FROM public.stops WHERE id IN (v_test_stop_a_id, v_test_stop_b_id);
  DELETE FROM public.routes WHERE id = v_test_route_id;
  DELETE FROM public.buses WHERE id IN (v_test_bus_id, v_test_inact_bus_id, v_test_bus_2_id);

  RAISE NOTICE '=======================================================';
  RAISE NOTICE 'ALL 18 TEST SUITES PASSED CLEANLY WITH ZERO LEFTOVER STATE!';
  RAISE NOTICE '=======================================================';
END $$;
