-- ============================================================================
-- Migration: 20261017060000_retention_cleanup_and_index_optimization.sql
-- Production Maintenance Strategy: Data Retention Policies, Bounded Batch Cleanups,
-- Staggered pg_cron Automation, Index Optimization, and Observability Logging
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. OBSERVABILITY: maintenance_logs Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.maintenance_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_name text NOT NULL,
  records_deleted integer NOT NULL DEFAULT 0,
  duration_ms integer NOT NULL DEFAULT 0,
  cutoff timestamptz,
  status text NOT NULL DEFAULT 'completed', -- 'completed', 'partial', 'failed', 'skipped'
  error_message text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  executed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_maintenance_logs_executed_at
  ON public.maintenance_logs (executed_at DESC);

CREATE INDEX IF NOT EXISTS idx_maintenance_logs_task_name
  ON public.maintenance_logs (task_name, executed_at DESC);

ALTER TABLE public.maintenance_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow service role full access on maintenance_logs" ON public.maintenance_logs;
CREATE POLICY "Allow service role full access on maintenance_logs"
  ON public.maintenance_logs
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow verified admins to view maintenance_logs" ON public.maintenance_logs;
CREATE POLICY "Allow verified admins to view maintenance_logs"
  ON public.maintenance_logs
  FOR SELECT
  TO authenticated
  USING (public.is_current_user_admin());

-- ----------------------------------------------------------------------------
-- 2. INDEX OPTIMIZATION & DEDUPLICATION
-- ----------------------------------------------------------------------------
-- Drop redundant index (already covered by unique constraint uq_bus_positions_device_epoch_seq)
DROP INDEX IF EXISTS public.idx_bus_positions_device_epoch_seq;

-- B-tree index on recorded_at to accelerate retention sweeps and SELECT max(recorded_at)
CREATE INDEX IF NOT EXISTS idx_bus_positions_recorded_at
  ON public.bus_positions (recorded_at);

-- Composite index to accelerate bus-specific historical lookups & debug console queries
CREATE INDEX IF NOT EXISTS idx_bus_positions_bus_id_recorded_at
  ON public.bus_positions (bus_id, recorded_at DESC);

-- B-tree index on occurred_at to accelerate bus_events retention sweeps
CREATE INDEX IF NOT EXISTS idx_bus_events_occurred_at
  ON public.bus_events (occurred_at);

-- Foreign key partial index on bus_events(stop_id)
CREATE INDEX IF NOT EXISTS idx_bus_events_stop_id
  ON public.bus_events (stop_id)
  WHERE stop_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 3. BOUNDED BATCH CLEANUP FUNCTIONS
-- Note on PostgreSQL Transaction Semantics:
-- In PL/pgSQL functions, all loop iterations execute within the calling query's
-- single transaction. The loop with LIMIT p_batch_size bounds working memory
-- and statement duration. p_max_batches strictly bounds total transaction time.
-- ----------------------------------------------------------------------------

-- Function 3.1: Clean up historical telemetry positions (Category 1: 30-Day Retention)
CREATE OR REPLACE FUNCTION public.cleanup_bus_positions(
  p_batch_size int DEFAULT 5000,
  p_cutoff_interval interval DEFAULT '30 days',
  p_max_batches int DEFAULT 10
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_cutoff timestamptz := now() - p_cutoff_interval;
  v_start_ts timestamptz := clock_timestamp();
  v_total_deleted integer := 0;
  v_batch_deleted integer := 0;
  v_batch_count integer := 0;
  v_duration_ms integer;
  v_status text := 'completed';
  v_error text := NULL;
BEGIN
  IF p_batch_size <= 0 OR p_batch_size > 50000 THEN
    p_batch_size := 5000;
  END IF;
  IF p_max_batches <= 0 OR p_max_batches > 100 THEN
    p_max_batches := 10;
  END IF;

  LOOP
    EXIT WHEN v_batch_count >= p_max_batches;

    WITH batch AS (
      SELECT id FROM public.bus_positions
      WHERE recorded_at < v_cutoff
      ORDER BY recorded_at ASC
      LIMIT p_batch_size
    )
    DELETE FROM public.bus_positions
    WHERE id IN (SELECT id FROM batch);

    GET DIAGNOSTICS v_batch_deleted = ROW_COUNT;
    v_total_deleted := v_total_deleted + v_batch_deleted;
    v_batch_count := v_batch_count + 1;

    EXIT WHEN v_batch_deleted < p_batch_size;
  END LOOP;

  IF v_batch_deleted = p_batch_size AND v_batch_count >= p_max_batches THEN
    v_status := 'partial';
  END IF;

  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;

  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_bus_positions', v_total_deleted, v_duration_ms, v_cutoff, v_status, NULL,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count, 'interval', p_cutoff_interval::text)
  );

  RETURN jsonb_build_object(
    'task', 'cleanup_bus_positions',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'cutoff', v_cutoff,
    'status', v_status
  );
EXCEPTION WHEN OTHERS THEN
  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;
  v_error := SQLERRM;
  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_bus_positions', v_total_deleted, v_duration_ms, v_cutoff, 'failed', v_error,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count)
  );
  RETURN jsonb_build_object(
    'task', 'cleanup_bus_positions',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'status', 'failed',
    'error', v_error
  );
END;
$$;

-- Function 3.2: Clean up spatial and transit events (Category 2: 60-Day Retention)
CREATE OR REPLACE FUNCTION public.cleanup_bus_events(
  p_batch_size int DEFAULT 5000,
  p_cutoff_interval interval DEFAULT '60 days',
  p_max_batches int DEFAULT 10
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_cutoff timestamptz := now() - p_cutoff_interval;
  v_start_ts timestamptz := clock_timestamp();
  v_total_deleted integer := 0;
  v_batch_deleted integer := 0;
  v_batch_count integer := 0;
  v_duration_ms integer;
  v_status text := 'completed';
  v_error text := NULL;
BEGIN
  IF p_batch_size <= 0 OR p_batch_size > 50000 THEN
    p_batch_size := 5000;
  END IF;
  IF p_max_batches <= 0 OR p_max_batches > 100 THEN
    p_max_batches := 10;
  END IF;

  LOOP
    EXIT WHEN v_batch_count >= p_max_batches;

    WITH batch AS (
      SELECT id FROM public.bus_events
      WHERE occurred_at < v_cutoff
      ORDER BY occurred_at ASC
      LIMIT p_batch_size
    )
    DELETE FROM public.bus_events
    WHERE id IN (SELECT id FROM batch);

    GET DIAGNOSTICS v_batch_deleted = ROW_COUNT;
    v_total_deleted := v_total_deleted + v_batch_deleted;
    v_batch_count := v_batch_count + 1;

    EXIT WHEN v_batch_deleted < p_batch_size;
  END LOOP;

  IF v_batch_deleted = p_batch_size AND v_batch_count >= p_max_batches THEN
    v_status := 'partial';
  END IF;

  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;

  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_bus_events', v_total_deleted, v_duration_ms, v_cutoff, v_status, NULL,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count, 'interval', p_cutoff_interval::text)
  );

  RETURN jsonb_build_object(
    'task', 'cleanup_bus_events',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'cutoff', v_cutoff,
    'status', v_status
  );
EXCEPTION WHEN OTHERS THEN
  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;
  v_error := SQLERRM;
  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_bus_events', v_total_deleted, v_duration_ms, v_cutoff, 'failed', v_error,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count)
  );
  RETURN jsonb_build_object(
    'task', 'cleanup_bus_events',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'status', 'failed',
    'error', v_error
  );
END;
$$;

-- Function 3.3: Administrative audit logs cleanup (Category 3: Defaults to 365 days, manual/opt-in)
-- Security/compliance rationale: Audit trails are low volume and must not be purged without institutional review.
CREATE OR REPLACE FUNCTION public.cleanup_admin_audit_logs(
  p_batch_size int DEFAULT 2000,
  p_cutoff_interval interval DEFAULT '365 days',
  p_max_batches int DEFAULT 10
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_cutoff timestamptz := now() - p_cutoff_interval;
  v_start_ts timestamptz := clock_timestamp();
  v_total_deleted integer := 0;
  v_batch_deleted integer := 0;
  v_batch_count integer := 0;
  v_duration_ms integer;
  v_status text := 'completed';
  v_error text := NULL;
BEGIN
  IF to_regclass('public.admin_audit_logs') IS NULL THEN
    RETURN jsonb_build_object(
      'task', 'cleanup_admin_audit_logs',
      'records_deleted', 0,
      'duration_ms', 0,
      'status', 'skipped_table_absent'
    );
  END IF;

  IF p_batch_size <= 0 OR p_batch_size > 20000 THEN
    p_batch_size := 2000;
  END IF;
  IF p_max_batches <= 0 OR p_max_batches > 100 THEN
    p_max_batches := 10;
  END IF;

  LOOP
    EXIT WHEN v_batch_count >= p_max_batches;

    WITH batch AS (
      SELECT id FROM public.admin_audit_logs
      WHERE created_at < v_cutoff
      ORDER BY created_at ASC
      LIMIT p_batch_size
    )
    DELETE FROM public.admin_audit_logs
    WHERE id IN (SELECT id FROM batch);

    GET DIAGNOSTICS v_batch_deleted = ROW_COUNT;
    v_total_deleted := v_total_deleted + v_batch_deleted;
    v_batch_count := v_batch_count + 1;

    EXIT WHEN v_batch_deleted < p_batch_size;
  END LOOP;

  IF v_batch_deleted = p_batch_size AND v_batch_count >= p_max_batches THEN
    v_status := 'partial';
  END IF;

  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;

  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_admin_audit_logs', v_total_deleted, v_duration_ms, v_cutoff, v_status, NULL,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count, 'interval', p_cutoff_interval::text)
  );

  RETURN jsonb_build_object(
    'task', 'cleanup_admin_audit_logs',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'cutoff', v_cutoff,
    'status', v_status
  );
EXCEPTION WHEN OTHERS THEN
  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;
  v_error := SQLERRM;
  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_admin_audit_logs', v_total_deleted, v_duration_ms, v_cutoff, 'failed', v_error,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count)
  );
  RETURN jsonb_build_object(
    'task', 'cleanup_admin_audit_logs',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'status', 'failed',
    'error', v_error
  );
END;
$$;

-- Explicitly drop 0-argument cleanup_http_responses if present from previous migrations
-- to prevent ambiguous function overload errors on 0-argument calls.
DROP FUNCTION IF EXISTS public.cleanup_http_responses();

-- Function 3.4: Clean up ephemeral pg_net HTTP responses (Category 4: 24-Hour Retention)
CREATE OR REPLACE FUNCTION public.cleanup_http_responses(
  p_batch_size int DEFAULT 5000,
  p_cutoff_interval interval DEFAULT '24 hours',
  p_max_batches int DEFAULT 10
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = net, public, extensions, pg_temp
AS $$
DECLARE
  v_cutoff timestamptz := now() - p_cutoff_interval;
  v_start_ts timestamptz := clock_timestamp();
  v_total_deleted integer := 0;
  v_batch_deleted integer := 0;
  v_batch_count integer := 0;
  v_duration_ms integer;
  v_status text := 'completed';
  v_error text := NULL;
  v_has_table boolean := false;
BEGIN
  IF to_regclass('net._http_response') IS NOT NULL THEN
    v_has_table := true;
  END IF;

  IF NOT v_has_table THEN
    RETURN jsonb_build_object(
      'task', 'cleanup_http_responses',
      'records_deleted', 0,
      'duration_ms', 0,
      'status', 'skipped_table_absent'
    );
  END IF;

  IF p_batch_size <= 0 OR p_batch_size > 50000 THEN
    p_batch_size := 5000;
  END IF;
  IF p_max_batches <= 0 OR p_max_batches > 100 THEN
    p_max_batches := 10;
  END IF;

  LOOP
    EXIT WHEN v_batch_count >= p_max_batches;

    WITH batch AS (
      SELECT id FROM net._http_response
      WHERE created < v_cutoff
      ORDER BY created ASC
      LIMIT p_batch_size
    )
    DELETE FROM net._http_response
    WHERE id IN (SELECT id FROM batch);

    GET DIAGNOSTICS v_batch_deleted = ROW_COUNT;
    v_total_deleted := v_total_deleted + v_batch_deleted;
    v_batch_count := v_batch_count + 1;

    EXIT WHEN v_batch_deleted < p_batch_size;
  END LOOP;

  IF v_batch_deleted = p_batch_size AND v_batch_count >= p_max_batches THEN
    v_status := 'partial';
  END IF;

  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;

  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_http_responses', v_total_deleted, v_duration_ms, v_cutoff, v_status, NULL,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count, 'interval', p_cutoff_interval::text)
  );

  RETURN jsonb_build_object(
    'task', 'cleanup_http_responses',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'cutoff', v_cutoff,
    'status', v_status
  );
EXCEPTION WHEN OTHERS THEN
  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;
  v_error := SQLERRM;
  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_http_responses', v_total_deleted, v_duration_ms, v_cutoff, 'failed', v_error,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count)
  );
  RETURN jsonb_build_object(
    'task', 'cleanup_http_responses',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'status', 'failed',
    'error', v_error
  );
END;
$$;

-- Function 3.5: Clean up pg_cron execution history (Category 5: 7-Day Retention)
CREATE OR REPLACE FUNCTION public.cleanup_cron_job_details(
  p_batch_size int DEFAULT 5000,
  p_cutoff_interval interval DEFAULT '7 days',
  p_max_batches int DEFAULT 10
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cron, public, extensions, pg_temp
AS $$
DECLARE
  v_cutoff timestamptz := now() - p_cutoff_interval;
  v_start_ts timestamptz := clock_timestamp();
  v_total_deleted integer := 0;
  v_batch_deleted integer := 0;
  v_batch_count integer := 0;
  v_duration_ms integer;
  v_status text := 'completed';
  v_error text := NULL;
  v_has_table boolean := false;
BEGIN
  IF to_regclass('cron.job_run_details') IS NOT NULL THEN
    v_has_table := true;
  END IF;

  IF NOT v_has_table THEN
    RETURN jsonb_build_object(
      'task', 'cleanup_cron_job_details',
      'records_deleted', 0,
      'duration_ms', 0,
      'status', 'skipped_table_absent'
    );
  END IF;

  IF p_batch_size <= 0 OR p_batch_size > 50000 THEN
    p_batch_size := 5000;
  END IF;
  IF p_max_batches <= 0 OR p_max_batches > 100 THEN
    p_max_batches := 10;
  END IF;

  LOOP
    EXIT WHEN v_batch_count >= p_max_batches;

    WITH batch AS (
      SELECT runid FROM cron.job_run_details
      WHERE start_time < v_cutoff
      ORDER BY start_time ASC
      LIMIT p_batch_size
    )
    DELETE FROM cron.job_run_details
    WHERE runid IN (SELECT runid FROM batch);

    GET DIAGNOSTICS v_batch_deleted = ROW_COUNT;
    v_total_deleted := v_total_deleted + v_batch_deleted;
    v_batch_count := v_batch_count + 1;

    EXIT WHEN v_batch_deleted < p_batch_size;
  END LOOP;

  IF v_batch_deleted = p_batch_size AND v_batch_count >= p_max_batches THEN
    v_status := 'partial';
  END IF;

  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;

  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_cron_job_details', v_total_deleted, v_duration_ms, v_cutoff, v_status, NULL,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count, 'interval', p_cutoff_interval::text)
  );

  RETURN jsonb_build_object(
    'task', 'cleanup_cron_job_details',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'cutoff', v_cutoff,
    'status', v_status
  );
EXCEPTION WHEN OTHERS THEN
  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;
  v_error := SQLERRM;
  INSERT INTO public.maintenance_logs (
    task_name, records_deleted, duration_ms, cutoff, status, error_message, metadata
  ) VALUES (
    'cleanup_cron_job_details', v_total_deleted, v_duration_ms, v_cutoff, 'failed', v_error,
    jsonb_build_object('batch_size', p_batch_size, 'batches_run', v_batch_count)
  );
  RETURN jsonb_build_object(
    'task', 'cleanup_cron_job_details',
    'records_deleted', v_total_deleted,
    'duration_ms', v_duration_ms,
    'status', 'failed',
    'error', v_error
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. MASTER ORCHESTRATOR: run_maintenance_retention_sweep()
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.run_maintenance_retention_sweep(
  p_include_audit_logs boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_start_ts timestamptz := clock_timestamp();
  v_pos_res jsonb;
  v_evt_res jsonb;
  v_aud_res jsonb := jsonb_build_object('task', 'cleanup_admin_audit_logs', 'status', 'skipped_by_policy');
  v_net_res jsonb;
  v_crn_res jsonb;
  v_total_deleted integer := 0;
  v_duration_ms integer;
  v_sweep_status text := 'completed';
BEGIN
  -- Concurrency Protection: Prevent overlapping maintenance executions
  IF NOT pg_try_advisory_xact_lock(9999, 1) THEN
    RETURN jsonb_build_object(
      'sweep_status', 'skipped_concurrent_run',
      'message', 'Another maintenance process is currently executing'
    );
  END IF;

  -- 1. Bus positions (Category 1: 30 days)
  v_pos_res := public.cleanup_bus_positions();
  v_total_deleted := v_total_deleted + COALESCE((v_pos_res->>'records_deleted')::integer, 0);

  -- 2. Bus events (Category 2: 60 days)
  v_evt_res := public.cleanup_bus_events();
  v_total_deleted := v_total_deleted + COALESCE((v_evt_res->>'records_deleted')::integer, 0);

  -- 3. Ephemeral net http responses (Category 4: 24 hours)
  v_net_res := public.cleanup_http_responses();
  v_total_deleted := v_total_deleted + COALESCE((v_net_res->>'records_deleted')::integer, 0);

  -- 4. Cron job details (Category 5: 7 days)
  v_crn_res := public.cleanup_cron_job_details();
  v_total_deleted := v_total_deleted + COALESCE((v_crn_res->>'records_deleted')::integer, 0);

  -- 5. Admin audit logs (Category 3: Only purged if explicitly opted in)
  IF p_include_audit_logs THEN
    v_aud_res := public.cleanup_admin_audit_logs();
    v_total_deleted := v_total_deleted + COALESCE((v_aud_res->>'records_deleted')::integer, 0);
  END IF;

  v_duration_ms := round(EXTRACT(EPOCH FROM (clock_timestamp() - v_start_ts)) * 1000)::integer;

  -- Accurate aggregate status calculation: partial failures are NOT reported as total success
  IF (v_pos_res->>'status' = 'failed') OR (v_evt_res->>'status' = 'failed') OR 
     (v_net_res->>'status' = 'failed') OR (v_crn_res->>'status' = 'failed') OR
     (v_aud_res->>'status' = 'failed') THEN
    v_sweep_status := 'failed';
  ELSIF (v_pos_res->>'status' = 'partial') OR (v_evt_res->>'status' = 'partial') OR 
        (v_net_res->>'status' = 'partial') OR (v_crn_res->>'status' = 'partial') OR
        (v_aud_res->>'status' = 'partial') THEN
    v_sweep_status := 'partial';
  ELSE
    v_sweep_status := 'completed';
  END IF;

  RETURN jsonb_build_object(
    'sweep_status', v_sweep_status,
    'total_records_deleted', v_total_deleted,
    'total_duration_ms', v_duration_ms,
    'details', jsonb_build_object(
      'bus_positions', v_pos_res,
      'bus_events', v_evt_res,
      'http_responses', v_net_res,
      'cron_job_details', v_crn_res,
      'admin_audit_logs', v_aud_res
    )
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. ADMIN DIAGNOSTIC RPC: admin_get_maintenance_status()
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_get_maintenance_status()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_recent_logs jsonb;
  v_table_stats jsonb;
  v_active_crons jsonb;
BEGIN
  IF NOT public.is_current_user_admin() AND current_user <> 'service_role' THEN
    RAISE EXCEPTION 'Access denied: caller is not an administrator';
  END IF;

  -- Fetch recent 20 maintenance executions
  SELECT COALESCE(jsonb_agg(to_jsonb(l)), '[]'::jsonb)
  INTO v_recent_logs
  FROM (
    SELECT id, task_name, records_deleted, duration_ms, cutoff, status, error_message, executed_at
    FROM public.maintenance_logs
    ORDER BY executed_at DESC
    LIMIT 20
  ) l;

  -- Operational table counts
  SELECT jsonb_build_object(
    'bus_positions_count', (SELECT count(*) FROM public.bus_positions),
    'bus_events_count', (SELECT count(*) FROM public.bus_events),
    'bus_current_state_count', (SELECT count(*) FROM public.bus_current_state)
  ) INTO v_table_stats;

  -- Scheduled maintenance cron jobs
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'jobname', jobname,
    'schedule', schedule,
    'active', active,
    'command', command
  )), '[]'::jsonb)
  INTO v_active_crons
  FROM cron.job
  WHERE jobname IN ('weekly-retention-sweep', 'daily-net-http-cleanup', 'cleanup-net-http-responses');

  RETURN jsonb_build_object(
    'tables', v_table_stats,
    'cron_schedules', v_active_crons,
    'recent_executions', v_recent_logs
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 6. SECURITY PRIVILEGE HARDENING
-- ----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.cleanup_bus_positions(int, interval, int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_bus_positions(int, interval, int) TO postgres, service_role;

REVOKE ALL ON FUNCTION public.cleanup_bus_events(int, interval, int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_bus_events(int, interval, int) TO postgres, service_role;

REVOKE ALL ON FUNCTION public.cleanup_admin_audit_logs(int, interval, int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_admin_audit_logs(int, interval, int) TO postgres, service_role;

REVOKE ALL ON FUNCTION public.cleanup_http_responses(int, interval, int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_http_responses(int, interval, int) TO postgres, service_role;

REVOKE ALL ON FUNCTION public.cleanup_cron_job_details(int, interval, int) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_cron_job_details(int, interval, int) TO postgres, service_role;

REVOKE ALL ON FUNCTION public.run_maintenance_retention_sweep(boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.run_maintenance_retention_sweep(boolean) TO postgres, service_role;

REVOKE ALL ON FUNCTION public.admin_get_maintenance_status() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_get_maintenance_status() TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 7. PG_CRON SCHEDULE CONFIGURATION (STAGGERED, NON-OVERLAPPING)
-- ----------------------------------------------------------------------------
-- Remove redundant/duplicate job from 20261017050000 if previously scheduled
DO $$
BEGIN
  PERFORM cron.unschedule('cleanup-net-http-responses');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- Schedule 7.1: Staggered daily cleanup of transient pg_net HTTP responses (Daily at 03:15 UTC)
DO $$
BEGIN
  PERFORM cron.unschedule('daily-net-http-cleanup');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

SELECT cron.schedule(
  'daily-net-http-cleanup',
  '15 3 * * *',
  'SELECT public.cleanup_http_responses();'
);

-- Schedule 7.2: Staggered weekly retention sweep (Every Sunday at 03:30 UTC)
DO $$
BEGIN
  PERFORM cron.unschedule('weekly-retention-sweep');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

SELECT cron.schedule(
  'weekly-retention-sweep',
  '30 3 * * 0',
  'SELECT public.run_maintenance_retention_sweep(false);'
);
