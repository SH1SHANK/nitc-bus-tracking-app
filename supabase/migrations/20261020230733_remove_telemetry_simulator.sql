-- Stop all historical names used for the simulator schedule before removing
-- its database entry points. Keep existing telemetry rows and the
-- is_simulation classification used by rider-facing filters.
DO $$
DECLARE
  v_job_id bigint;
BEGIN
  FOR v_job_id IN
    SELECT jobid FROM cron.job
    WHERE jobname IN ('bus-telemetry-simulator', 'bus-telemetry-simulator-15s')
  LOOP
    PERFORM cron.unschedule(v_job_id);
  END LOOP;
END;
$$;

DROP FUNCTION IF EXISTS public.trigger_telemetry_simulation_15s();
DROP FUNCTION IF EXISTS public.consume_telemetry_simulator_nonce(uuid, timestamptz);
DROP TABLE IF EXISTS public.telemetry_simulator_nonces;
