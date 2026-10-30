-- Restore the previously removed simulator behind its signed, replay-protected
-- service-to-service path. The cron remains disabled until the Vault flag is set.
CREATE TABLE IF NOT EXISTS public.telemetry_simulator_nonces (
  nonce uuid PRIMARY KEY,
  expires_at timestamptz NOT NULL
);
ALTER TABLE public.telemetry_simulator_nonces ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.telemetry_simulator_nonces FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, DELETE ON public.telemetry_simulator_nonces TO service_role;

CREATE OR REPLACE FUNCTION public.consume_telemetry_simulator_nonce(
  p_nonce uuid,
  p_expires_at timestamptz
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
  IF p_expires_at <= now() OR p_expires_at > now() + interval '10 minutes' THEN
    RETURN false;
  END IF;
  DELETE FROM public.telemetry_simulator_nonces WHERE expires_at <= now();
  INSERT INTO public.telemetry_simulator_nonces(nonce, expires_at)
  VALUES (p_nonce, p_expires_at)
  ON CONFLICT DO NOTHING;
  RETURN FOUND;
END;
$$;
REVOKE ALL ON FUNCTION public.consume_telemetry_simulator_nonce(uuid, timestamptz) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.consume_telemetry_simulator_nonce(uuid, timestamptz) TO service_role;

-- This projection is only called by explicitly opted-in non-production builds.
-- It returns rows marked as simulations and never changes the rider RPC.
CREATE OR REPLACE FUNCTION public.get_simulated_bus_positions_for_testing()
RETURNS TABLE (
  bus_id uuid, bus_number text, display_name text, trip_id uuid, active_trip_id uuid,
  route_id uuid, route_name text, latitude double precision, longitude double precision,
  speed double precision, heading double precision, status text, last_seen timestamptz,
  recorded_at timestamptz, is_stale boolean, epoch bigint, seq bigint
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
  SELECT b.id, b.bus_number::text, b.display_name::text, c.trip_id, c.trip_id,
         COALESCE(t.route_id, prior.route_id), COALESCE(r.name::text, prior.route_name),
         c.latitude::double precision, c.longitude::double precision,
         c.speed::double precision, c.heading::double precision, c.status::text,
         c.last_seen, c.recorded_at, c.last_seen < now() - interval '90 seconds', c.epoch, c.seq
  FROM public.bus_current_state c
  JOIN public.buses b ON b.id = c.bus_id
  LEFT JOIN public.trips t ON t.id = c.trip_id
  LEFT JOIN public.routes r ON r.id = t.route_id
  LEFT JOIN LATERAL (
    SELECT tr.route_id, rr.name AS route_name
    FROM public.trips tr JOIN public.routes rr ON rr.id = tr.route_id
    WHERE tr.bus_id = b.id
    ORDER BY tr.started_at DESC NULLS LAST, tr.created_at DESC LIMIT 1
  ) prior ON true
  WHERE b.is_active AND b.is_simulation AND c.last_seen > now() - interval '15 minutes'
  ORDER BY b.bus_number;
$$;
REVOKE ALL ON FUNCTION public.get_simulated_bus_positions_for_testing() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_simulated_bus_positions_for_testing() TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.trigger_telemetry_simulation_15s()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, net, vault, extensions, pg_temp
AS $$
DECLARE
  v_secret text;
  v_gateway_jwt text;
  v_timestamp text;
  v_nonce uuid;
  v_body jsonb := '{"mode":"fleet"}'::jsonb;
  v_signature text;
  v_enabled text;
BEGIN
  SELECT decrypted_secret INTO v_enabled
  FROM vault.decrypted_secrets WHERE name = 'telemetry_simulator_enabled';
  IF coalesce(v_enabled, 'false') <> 'true' THEN
    RETURN;
  END IF;
  SELECT decrypted_secret INTO v_secret
  FROM vault.decrypted_secrets WHERE name = 'telemetry_simulator_hmac_secret';
  SELECT decrypted_secret INTO v_gateway_jwt
  FROM vault.decrypted_secrets WHERE name = 'telemetry_simulator_gateway_jwt';
  IF octet_length(convert_to(coalesce(v_secret, ''), 'UTF8')) < 32 OR coalesce(v_gateway_jwt, '') = '' THEN
    RAISE WARNING 'telemetry simulator scheduler secrets are not configured';
    RETURN;
  END IF;

  FOR i IN 1..4 LOOP
    v_timestamp := extract(epoch FROM clock_timestamp())::bigint::text;
    v_nonce := gen_random_uuid();
    v_signature := encode(extensions.hmac(
      convert_to(v_timestamp || '.' || v_nonce::text || '.' || v_body::text, 'UTF8'),
      convert_to(v_secret, 'UTF8'), 'sha256'), 'hex');
    PERFORM net.http_post(
      url := 'https://fnngudikrvelpuhngtlw.supabase.co/functions/v1/telemetry-simulator',
      body := v_body,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', v_gateway_jwt,
        'Authorization', 'Bearer ' || v_gateway_jwt,
        'x-simulator-timestamp', v_timestamp,
        'x-simulator-nonce', v_nonce::text,
        'x-simulator-signature', v_signature
      ),
      timeout_milliseconds := 15000
    );
    IF i < 4 THEN PERFORM pg_sleep(15); END IF;
  END LOOP;
END;
$$;
REVOKE ALL ON FUNCTION public.trigger_telemetry_simulation_15s() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_telemetry_simulation_15s() TO postgres, service_role;

DO $$
DECLARE
  v_job_id bigint;
BEGIN
  FOR v_job_id IN
    SELECT jobid FROM cron.job WHERE jobname = 'bus-telemetry-simulator-15s'
  LOOP
    PERFORM cron.unschedule(v_job_id);
  END LOOP;
END;
$$;

SELECT cron.schedule(
  'bus-telemetry-simulator-15s',
  '* * * * *',
  'SELECT public.trigger_telemetry_simulation_15s();'
);
