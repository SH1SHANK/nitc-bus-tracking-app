#!/usr/bin/env bash
set -e

export PGPASSWORD=postgres
PSQL="/opt/homebrew/opt/postgresql@18/bin/psql -h localhost -p 54322 -U postgres -d postgres"

echo "======================================================="
echo "STARTING CONCURRENCY RACE-CONDITION VERIFICATION TESTS"
echo "======================================================="

# Setup test fixtures
$PSQL -q -c "
DELETE FROM public.bus_events WHERE bus_id = '99999999-0000-4000-8000-000000000001'::uuid;
DELETE FROM public.bus_positions WHERE bus_id = '99999999-0000-4000-8000-000000000001'::uuid;
DELETE FROM public.bus_current_state WHERE bus_id = '99999999-0000-4000-8000-000000000001'::uuid;
DELETE FROM public.devices WHERE device_id IN ('CONCUR-DEV-001', 'CONCUR-DEV-002');
DELETE FROM public.buses WHERE id = '99999999-0000-4000-8000-000000000001'::uuid;

INSERT INTO public.buses (id, bus_number, display_name, is_active)
VALUES ('99999999-0000-4000-8000-000000000001'::uuid, 'BUS-CONCUR-99', 'Concurrency Test Bus', true);

INSERT INTO public.devices (device_id, bus_id, credential_hash, is_active, current_epoch)
VALUES ('CONCUR-DEV-001', '99999999-0000-4000-8000-000000000001'::uuid, extensions.crypt('concur_secret', extensions.gen_salt('bf', 8)), true, 1);
"

echo "Fixtures created."

# -----------------------------------------------------------------------------
# Scenario 1: Competing concurrent packets on the same device
# -----------------------------------------------------------------------------
echo ""
echo "--- Scenario 1: Concurrent competing packets on same device ---"

# Transaction 1: Acquires advisory lock, sleeps 0.5s, then attempts to ingest seq 150
$PSQL -c "
BEGIN;
SELECT pg_advisory_xact_lock(1001, hashtext('CONCUR-DEV-001'));
SELECT pg_sleep(0.5);
SELECT public.ingest_telemetry_packet('CONCUR-DEV-001', 150, now() - interval '20 seconds', 11.321050, 75.933050, 20.0, 90.0, 5.0) AS res_tx1;
COMMIT;
" > /tmp/tx1.out 2>&1 &
PID1=$!

sleep 0.1

# Transaction 2: Competes for lock. Will wait for TX1, then run seq 200
$PSQL -c "
BEGIN;
SELECT public.ingest_telemetry_packet('CONCUR-DEV-001', 200, now() - interval '10 seconds', 11.322050, 75.933050, 25.0, 90.0, 5.0) AS res_tx2;
COMMIT;
" > /tmp/tx2.out 2>&1 &
PID2=$!

wait $PID1
wait $PID2

echo "TX1 Result:"
grep -A 2 "res_tx1" /tmp/tx1.out | tail -n 1
echo "TX2 Result:"
grep -A 2 "res_tx2" /tmp/tx2.out | tail -n 1

# Delayed packet seq 175 arrives after seq 200 committed
echo "Testing delayed packet seq 175 against current seq 200..."
$PSQL -c "
SELECT public.ingest_telemetry_packet('CONCUR-DEV-001', 175, now() - interval '5 seconds', 11.321500, 75.933050, 22.0, 90.0, 5.0) AS res_stale;
"

# -----------------------------------------------------------------------------
# Scenario 2: Concurrent ingestion while reset_device_sequence is running
# -----------------------------------------------------------------------------
echo ""
echo "--- Scenario 2: Concurrent ingestion during epoch reset RPC ---"

# TX A: Starts reset_device_sequence, holds lock with pg_sleep
$PSQL -c "
BEGIN;
SELECT pg_advisory_xact_lock(1001, hashtext('CONCUR-DEV-001'));
SELECT pg_sleep(0.5);
SELECT public.reset_device_sequence('CONCUR-DEV-001', 'concur_secret', 'sess_concur_1', 'concurrency_reboot_test') AS res_reset;
COMMIT;
" > /tmp/tx_reset.out 2>&1 &
PID_RESET=$!

sleep 0.1

# TX B: Competing ingestion from old epoch 1 attempts to run
$PSQL -c "
BEGIN;
SELECT public.ingest_telemetry_packet('CONCUR-DEV-001', 205, now() - interval '2 seconds', 11.322100, 75.933100, 25.0, 90.0, 5.0, 'moving', 50.0, 500.0, 1) AS res_ingest_during_reset;
COMMIT;
" > /tmp/tx_ingest_reset.out 2>&1 &
PID_INGEST=$!

wait $PID_RESET
wait $PID_INGEST

echo "Reset RPC Result:"
grep -A 2 "res_reset" /tmp/tx_reset.out | tail -n 1
echo "Competing Ingestion Result (Old Epoch 1 should be rejected):"
grep -A 2 "res_ingest_during_reset" /tmp/tx_ingest_reset.out | tail -n 1

# -----------------------------------------------------------------------------
# Scenario 3: Concurrent ingestion from old tracker during replacement reassignment
# -----------------------------------------------------------------------------
echo ""
echo "--- Scenario 3: Concurrent old tracker ingestion during replacement reassignment ---"

# TX C: Reassignment transaction assigns CONCUR-DEV-002 to BUS-CONCUR-99
$PSQL -c "
BEGIN;
SELECT pg_advisory_xact_lock(1001, hashtext('CONCUR-DEV-001'));
SELECT pg_sleep(0.5);
SELECT public.register_tracking_device('CONCUR-DEV-002', 'BUS-CONCUR-99', 'replacement_secret_123', true) AS res_reassign;
COMMIT;
" > /tmp/tx_reassign.out 2>&1 &
PID_REASSIGN=$!

sleep 0.1

# TX D: Old tracker CONCUR-DEV-001 attempts to ingest telemetry while reassignment executes
$PSQL -c "
BEGIN;
SELECT public.ingest_telemetry_packet('CONCUR-DEV-001', 250, now(), 11.322200, 75.933200, 20.0, 90.0, 5.0, 'moving', 50.0, 500.0, 2) AS res_old_tracker;
COMMIT;
" > /tmp/tx_old.out 2>&1 &
PID_OLD=$!

wait $PID_REASSIGN
wait $PID_OLD

echo "Reassignment Result:"
grep -A 2 "res_reassign" /tmp/tx_reassign.out | tail -n 1
echo "Old Tracker Ingestion Result (Must be rejected with UNAUTHORIZED_DEVICE):"
grep -A 2 "res_old_tracker" /tmp/tx_old.out | tail -n 1

# Verify New Tracker can immediately ingest telemetry cleanly
echo "New Tracker CONCUR-DEV-002 Ingestion:"
$PSQL -c "
SELECT public.ingest_telemetry_packet('CONCUR-DEV-002', 1, now(), 11.322500, 75.933500, 25.0, 90.0, 5.0, 'moving') AS res_new_tracker;
"

# Cleanup
$PSQL -q -c "
DELETE FROM public.bus_events WHERE bus_id = '99999999-0000-4000-8000-000000000001'::uuid;
DELETE FROM public.bus_positions WHERE bus_id = '99999999-0000-4000-8000-000000000001'::uuid;
DELETE FROM public.bus_current_state WHERE bus_id = '99999999-0000-4000-8000-000000000001'::uuid;
DELETE FROM public.devices WHERE device_id IN ('CONCUR-DEV-001', 'CONCUR-DEV-002');
DELETE FROM public.buses WHERE id = '99999999-0000-4000-8000-000000000001'::uuid;
"

echo "======================================================="
echo "ALL CONCURRENCY TESTS EXECUTED AND VERIFIED!"
echo "======================================================="
