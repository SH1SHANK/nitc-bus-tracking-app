DO $$
DECLARE
  v_positions_definition text;
  v_events_definition text;
  v_nearby_definition text;
  v_nonce uuid := gen_random_uuid();
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.telemetry_simulator_nonces'::regclass) THEN
    RAISE EXCEPTION 'simulator nonce table must have RLS enabled';
  END IF;
  IF has_table_privilege('anon', 'public.telemetry_simulator_nonces', 'SELECT') OR
     has_table_privilege('authenticated', 'public.telemetry_simulator_nonces', 'SELECT') THEN
    RAISE EXCEPTION 'rider role can read simulator nonces';
  END IF;
  IF has_function_privilege('anon', 'public.consume_telemetry_simulator_nonce(uuid,timestamptz)', 'EXECUTE') OR
     has_function_privilege('authenticated', 'public.consume_telemetry_simulator_nonce(uuid,timestamptz)', 'EXECUTE') THEN
    RAISE EXCEPTION 'untrusted role can consume simulator nonces';
  END IF;
  IF NOT has_function_privilege('service_role', 'public.consume_telemetry_simulator_nonce(uuid,timestamptz)', 'EXECUTE') THEN
    RAISE EXCEPTION 'service role cannot consume simulator nonces';
  END IF;
  SELECT pg_get_functiondef('public.get_active_bus_positions_v2()'::regprocedure) INTO v_positions_definition;
  SELECT pg_get_functiondef('public.get_active_trip_stop_events(uuid)'::regprocedure) INTO v_events_definition;
  SELECT pg_get_functiondef('public.get_nearby_buses(double precision,double precision,double precision,integer)'::regprocedure) INTO v_nearby_definition;
  IF position('NOT b.is_simulation' IN v_positions_definition) = 0 OR
     position('NOT b.is_simulation' IN v_events_definition) = 0 OR
     position('NOT b.is_simulation' IN v_nearby_definition) = 0 THEN
    RAISE EXCEPTION 'rider projections expose simulator data';
  END IF;
  IF NOT public.consume_telemetry_simulator_nonce(v_nonce, now() + interval '5 minutes') OR
     public.consume_telemetry_simulator_nonce(v_nonce, now() + interval '5 minutes') THEN
    RAISE EXCEPTION 'simulator nonce replay was accepted';
  END IF;
  DELETE FROM public.telemetry_simulator_nonces WHERE nonce = v_nonce;
END;
$$;
