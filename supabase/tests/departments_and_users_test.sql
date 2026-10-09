-- ============================================================================
-- Tracklet Test Suite: Departments, Users, Auth Trigger & Profile RPCs
-- ============================================================================

DO $$
DECLARE
    v_test_user_id uuid := 'a0000000-0000-0000-0000-000000000001'::uuid;
    v_test_user_id_2 uuid := 'a0000000-0000-0000-0000-000000000002'::uuid;
    v_count integer;
    v_profile record;
    v_updated_at_before timestamptz;
    v_updated_at_after timestamptz;
    v_error_caught boolean;
BEGIN
    RAISE NOTICE 'Starting Tracklet Profile & Departments Verification Tests...';

    -- 1. All 21 Department Records Exist
    SELECT COUNT(*) INTO v_count FROM public.departments;
    IF v_count <> 21 THEN
        RAISE EXCEPTION 'Assertion Failed: Expected 21 departments, found %', v_count;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.departments WHERE department_id = 'CS' AND department_name = 'Computer Science & Engineering') THEN
        RAISE EXCEPTION 'Assertion Failed: Department CS missing or incorrect name';
    END IF;
    RAISE NOTICE '✓ 1. All 21 departments verified.';

    -- 1b. All 16 Canonical Hostels Exist
    SELECT COUNT(*) INTO v_count FROM public.hostels;
    IF v_count <> 16 THEN
        RAISE EXCEPTION 'Assertion Failed: Expected 16 hostels, found %', v_count;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.hostels WHERE hostel_id = 'MBH_1' AND hostel_name = 'Mega Hostel (MBH - Phase 1)') THEN
        RAISE EXCEPTION 'Assertion Failed: Hostel MBH_1 missing or incorrect name';
    END IF;
    RAISE NOTICE '✓ 1b. All 16 hostels verified.';

    -- 2. Auth Trigger Profile Creation Verification
    -- Clean up test records if present
    DELETE FROM public.users WHERE user_id IN (v_test_user_id, v_test_user_id_2);
    DELETE FROM auth.users WHERE id IN (v_test_user_id, v_test_user_id_2);

    -- Simulate Auth User Creation
    INSERT INTO auth.users (id, email, raw_user_meta_data, created_at, updated_at)
    VALUES (
      v_test_user_id,
      'test_student_1@nitc.ac.in',
      '{"full_name": "Test Student One"}'::jsonb,
      now(),
      now()
    );

    SELECT COUNT(*) INTO v_count FROM public.users WHERE user_id = v_test_user_id;
    IF v_count <> 1 THEN
        RAISE EXCEPTION 'Assertion Failed: Profile row was not created automatically by trigger on auth.users';
    END IF;

    SELECT full_name, onboarding_completed INTO v_profile FROM public.users WHERE user_id = v_test_user_id;
    IF v_profile.full_name <> 'Test Student One' OR v_profile.onboarding_completed <> false THEN
        RAISE EXCEPTION 'Assertion Failed: Initial profile state mismatch: full_name=%, onboarding_completed=%',
          v_profile.full_name, v_profile.onboarding_completed;
    END IF;
    RAISE NOTICE '✓ 2. Auth trigger automatically provisions exactly one profile row.';

    -- 3. ensure_my_profile() Idempotency
    -- Set auth.uid() context for test user 1
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_test_user_id::text, 'role', 'authenticated')::text, true);

    SELECT * INTO v_profile FROM public.ensure_my_profile();
    IF v_profile.user_id <> v_test_user_id THEN
        RAISE EXCEPTION 'Assertion Failed: ensure_my_profile returned incorrect user_id: %', v_profile.user_id;
    END IF;

    SELECT COUNT(*) INTO v_count FROM public.users WHERE user_id = v_test_user_id;
    IF v_count <> 1 THEN
        RAISE EXCEPTION 'Assertion Failed: Repeated ensure_my_profile created duplicate rows';
    END IF;
    RAISE NOTICE '✓ 3. ensure_my_profile is idempotent and duplicate-safe.';

    -- 4. Unauthenticated Caller Handling
    PERFORM set_config('request.jwt.claims', '', true);
    v_error_caught := false;
    BEGIN
        PERFORM public.get_my_profile();
    EXCEPTION WHEN OTHERS THEN
        v_error_caught := true;
    END;
    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'Assertion Failed: Unauthenticated call to get_my_profile did not raise an exception';
    END IF;
    RAISE NOTICE '✓ 4. Unauthenticated RPC calls are strictly rejected.';

    -- 5. Complete Onboarding Validation (Negative tests: invalid department, missing fields, malformed json)
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_test_user_id::text, 'role', 'authenticated')::text, true);

    -- Test Invalid Department
    v_error_caught := false;
    BEGIN
        PERFORM public.complete_onboarding('Shashank', 'INVALID_DEPT', '2024-2028', 'Mega Hostel', '{}'::jsonb);
    EXCEPTION WHEN OTHERS THEN
        v_error_caught := true;
    END;
    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'Assertion Failed: complete_onboarding accepted invalid department ID';
    END IF;

    -- Test Missing Required Field (Empty batch)
    v_error_caught := false;
    BEGIN
        PERFORM public.complete_onboarding('Shashank', 'CS', '', 'Mega Hostel', '{}'::jsonb);
    EXCEPTION WHEN OTHERS THEN
        v_error_caught := true;
    END;
    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'Assertion Failed: complete_onboarding accepted empty batch';
    END IF;

    -- Test Invalid Notification Prefs (array instead of object)
    v_error_caught := false;
    BEGIN
        PERFORM public.complete_onboarding('Shashank', 'CS', 'B24', 'Mega Hostel', '["invalid"]'::jsonb);
    EXCEPTION WHEN OTHERS THEN
        v_error_caught := true;
    END;
    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'Assertion Failed: complete_onboarding accepted array for notification_prefs';
    END IF;
    RAISE NOTICE '✓ 5. Input validation (departments, required fields, JSON structure) verified.';

    -- 6. Successful Onboarding
    SELECT updated_at INTO v_updated_at_before FROM public.users WHERE user_id = v_test_user_id;

    SELECT * INTO v_profile FROM public.complete_onboarding(
        'Shashank Mergu',
        'CS',
        '2024-2028',
        'Mega Hostel Boys',
        '{"bus_alerts": true, "push_enabled": true}'::jsonb
    );

    IF v_profile.onboarding_completed <> true OR v_profile.department_name <> 'Computer Science & Engineering' THEN
        RAISE EXCEPTION 'Assertion Failed: complete_onboarding returned incorrect state: completed=%, dept=%',
            v_profile.onboarding_completed, v_profile.department_name;
    END IF;
    RAISE NOTICE '✓ 6. complete_onboarding successfully marks onboarding complete with department name join.';

    -- 7. Profile Updates and updated_at trigger
    SELECT * INTO v_profile FROM public.update_my_profile(
        p_hostel => 'A-Hostel',
        p_notification_prefs => '{"bus_alerts": false, "push_enabled": true}'::jsonb
    );

    IF v_profile.hostel <> 'A-Hostel' THEN
        RAISE EXCEPTION 'Assertion Failed: update_my_profile failed to update hostel';
    END IF;

    SELECT updated_at INTO v_updated_at_after FROM public.users WHERE user_id = v_test_user_id;
    IF v_updated_at_after <= v_updated_at_before THEN
        RAISE EXCEPTION 'Assertion Failed: updated_at was not updated by trigger';
    END IF;
    RAISE NOTICE '✓ 7. update_my_profile and updated_at trigger verified.';

    -- 8. Verify Transit Data Integrity (buses, routes, stops, timings)
    SELECT COUNT(*) INTO v_count FROM public.stops WHERE code IN ('department_building', 'kattangal_bus_stop', 'main_gate');
    IF v_count < 3 THEN
        RAISE EXCEPTION 'Assertion Failed: Pre-existing stops data was affected';
    END IF;

    SELECT COUNT(*) INTO v_count FROM public.bus_timings;
    IF v_count < 100 THEN
        RAISE EXCEPTION 'Assertion Failed: Pre-existing bus timings were affected';
    END IF;
    RAISE NOTICE '✓ 8. Transit database objects and seed data remain intact.';

    -- Clean up test records
    PERFORM set_config('request.jwt.claims', '', true);
    DELETE FROM public.users WHERE user_id = v_test_user_id;
    DELETE FROM auth.users WHERE id = v_test_user_id;

    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'ALL USER PROFILE & DEPARTMENT TESTS PASSED SUCCESSFULLY';
    RAISE NOTICE '=======================================================';
END $$;
