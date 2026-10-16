-- 20261015070000_telemetry_simulator_15s_cron.sql
-- Configure Telemetry Simulator Edge Function to execute every 15 seconds via pg_cron & pg_net

-- 1. Create or replace the 15-second simulation driver function
CREATE OR REPLACE FUNCTION public.trigger_telemetry_simulation_15s()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, net, pg_temp
AS $$
BEGIN
  -- Execute 4 simulation cycles spaced 15 seconds apart within each minute
  FOR i IN 1..4 LOOP
    PERFORM net.http_post(
      url := 'https://fnngudikrvelpuhngtlw.supabase.co/functions/v1/telemetry-simulator',
      body := '{"points": 1, "autoTrip": true, "mode": "fleet"}'::jsonb,
      headers := '{"Content-Type": "application/json"}'::jsonb,
      timeout_milliseconds := 15000
    );
    IF i < 4 THEN
      PERFORM pg_sleep(15);
    END IF;
  END LOOP;
END;
$$;

-- 2. Restrict execution permissions strictly to privileged roles
REVOKE ALL ON FUNCTION public.trigger_telemetry_simulation_15s() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_telemetry_simulation_15s() TO postgres, service_role;

-- 3. Unschedule legacy minute-based job if present
DO $$
BEGIN
  PERFORM cron.unschedule('bus-telemetry-simulator');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- 4. Register the new 15-second cron schedule
DO $$
BEGIN
  PERFORM cron.unschedule('bus-telemetry-simulator-15s');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

SELECT cron.schedule(
  'bus-telemetry-simulator-15s',
  '* * * * *',
  'SELECT public.trigger_telemetry_simulation_15s();'
);
