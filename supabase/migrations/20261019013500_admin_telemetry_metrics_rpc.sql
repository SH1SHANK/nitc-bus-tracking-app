CREATE OR REPLACE FUNCTION public.admin_get_telemetry_metrics()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_metrics jsonb;
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  SELECT jsonb_build_object(
    'hourly_packets', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'timestamp', t.time_bucket,
          'count', t.packet_count,
          'avg_speed', t.avg_speed
        ) ORDER BY t.time_bucket ASC
      )
      FROM (
        SELECT 
          date_trunc('hour', recorded_at) AS time_bucket,
          count(*) AS packet_count,
          round(avg(speed)::numeric, 1) AS avg_speed
        FROM public.bus_positions
        WHERE recorded_at >= now() - interval '24 hours'
        GROUP BY time_bucket
      ) t
    ), '[]'::jsonb),
    'speed_distribution', COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'bus_number', b.bus_number,
          'device_id', s.device_id,
          'speed', s.speed,
          'heading', s.heading,
          'last_seen', s.last_seen
        ) ORDER BY b.bus_number ASC
      )
      FROM public.bus_current_state s
      JOIN public.buses b ON b.id = s.bus_id
    ), '[]'::jsonb),
    'total_packets_all_time', (SELECT count(*) FROM public.bus_positions),
    'total_packets_24h', (SELECT count(*) FROM public.bus_positions WHERE recorded_at >= now() - interval '24 hours')
  ) INTO v_metrics;

  RETURN v_metrics;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_get_telemetry_metrics() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_get_telemetry_metrics() TO authenticated, service_role;
