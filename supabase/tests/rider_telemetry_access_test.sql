DO $$
BEGIN
  IF has_table_privilege('anon', 'public.devices', 'SELECT') OR
     has_table_privilege('authenticated', 'public.devices', 'SELECT') THEN
    RAISE EXCEPTION 'Rider role can read device credentials';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname IN ('devices', 'bus_current_state', 'bus_positions', 'bus_events')
      AND NOT c.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'RLS is disabled on a restricted transit table';
  END IF;
  IF has_table_privilege('anon', 'public.buses', 'SELECT') OR
     has_table_privilege('authenticated', 'public.buses', 'SELECT') OR
     has_table_privilege('anon', 'public.trips', 'SELECT') OR
     has_table_privilege('authenticated', 'public.trips', 'SELECT') THEN
    RAISE EXCEPTION 'Rider role can read operational bus/trip rows directly';
  END IF;
  IF has_table_privilege('anon', 'public.bus_current_state', 'SELECT') OR
     has_table_privilege('authenticated', 'public.bus_current_state', 'SELECT') OR
     has_table_privilege('anon', 'public.bus_events', 'SELECT') OR
     has_table_privilege('authenticated', 'public.bus_events', 'SELECT') OR
     has_table_privilege('anon', 'public.bus_positions', 'SELECT') OR
     has_table_privilege('authenticated', 'public.bus_positions', 'SELECT') THEN
    RAISE EXCEPTION 'Rider role can read raw operational telemetry';
  END IF;
  IF NOT has_function_privilege('anon', 'public.get_active_bus_positions()', 'EXECUTE') OR
     NOT has_function_privilege('authenticated', 'public.get_active_bus_positions()', 'EXECUTE') OR
     NOT has_function_privilege('anon', 'public.get_active_bus_positions_v2()', 'EXECUTE') OR
     NOT has_function_privilege('authenticated', 'public.get_active_bus_positions_v2()', 'EXECUTE') OR
     NOT has_function_privilege('anon', 'public.get_active_trip_stop_events(uuid)', 'EXECUTE') OR
     NOT has_function_privilege('authenticated', 'public.get_active_trip_stop_events(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Rider transit RPC access is missing';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM pg_proc p,
         LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) acl
    WHERE p.oid IN (
      'public.get_active_bus_positions()'::regprocedure,
      'public.get_active_bus_positions_v2()'::regprocedure,
      'public.get_active_trip_stop_events(uuid)'::regprocedure
    )
      AND acl.grantee = 0
      AND acl.privilege_type = 'EXECUTE'
  ) THEN
    RAISE EXCEPTION 'Stop-event RPC is executable by PUBLIC';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    WHERE p.oid IN (
      'public.get_active_bus_positions()'::regprocedure,
      'public.get_active_bus_positions_v2()'::regprocedure,
      'public.get_active_trip_stop_events(uuid)'::regprocedure
    )
      AND NOT p.prosecdef
  ) THEN
    RAISE EXCEPTION 'Rider RPC is not SECURITY DEFINER';
  END IF;
END;
$$;
