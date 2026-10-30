# Testing, Debugging, & Troubleshooting Runbook

## 1. Automated Test Suites & Coverage

Both repositories maintain automated test suites protecting protocol invariants, boundary constraints, and business logic.

### 1.1 Fastify Backend Tests (Vitest)
Located in `backend_bus_tracker/test/`:
- **`test/core.test.ts`:** Stateless coordinate boundary checks, speed caps, heading wrap normalization, time skew detection.
- **`test/routes/auth.route.test.ts`:** Device secret authentication, Bcrypt comparison, JWT issuance, rate limiting.
- **`test/routes/reset_session.test.ts`:** Cold boot handshake, epoch negotiation, idempotent retry handling with duplicate `session_id`.
- **`test/routes/telemetry.route.test.ts`:** Telemetry ingestion, sequence monotonicity, payload validation, batch handling.
- **`test/routes/security.test.ts`:** Helmet headers, CORS origins, payload body caps (1 MB), token spoofing rejection.
- **`test/integration/supabase.integration.test.ts`:** Real Fastify-to-Supabase integration test against isolated database.

*Execution:*
```bash
cd /Users/shashankmergu/Desktop/backend_bus_tracker
npm test
```

### 1.2 Flutter Mobile Tests
Located in `NITC_BUS_TRACKING_APP/test/`:
- **`test/data/transit/bus_eta_test.dart`:** 21 passing test cases covering route projection, out-of-route detection, dwell identification, speed smoothing, and ETA calculations across edge cases.
- **`test/features/home/home_transit_logic_test.dart`:** Nearest stop discovery, walking time estimation, upcoming departure filtering.
- **`test/features/map/bus_stop_progress_test.dart`:** Direction-aware loop route matching, skipped stop resolution, out-and-back route disambiguation.

*Execution:*
```bash
cd /Users/shashankmergu/Desktop/NITC_BUS_TRACKING_APP
flutter test
```

---

## 2. Common Failure Modes & Runbooks

### 2.1 Failure Mode: Hardware Rejection (HTTP 409 Sequence Conflict)
- **Symptom:** Fastify returns `{ "ok": false, "code": "STALE_SEQUENCE" }` or `{ "code": "SEQUENCE_REUSE_CONFLICT" }`.
- **Root Cause:** Tracker rebooted or reset its local sequence counter to `1` without performing a session reset (`/auth/reset-session`), causing it to emit `seq = 1` against an existing epoch that is already at `seq = 500`.
- **Resolution:** Firmware must always execute `POST /api/v1/auth/reset-session` on startup before sending telemetry. If an HTTP 409 `STALE_SEQUENCE` is received, firmware must trigger an immediate reset-session handshake.

### 2.2 Failure Mode: Stale Bus on Mobile Map (Amber Badge)
- **Symptom:** Bus marker renders with an amber outline and "Stale" label; ETA shows "Unavailable".
- **Diagnosis:**
  1. Check `devices.last_seen_at` in Supabase:
     ```sql
     SELECT device_id, last_seen_at, current_epoch FROM devices WHERE device_id = 'NITC-BUS-001';
     ```
  2. If `last_seen_at` is older than 60 seconds, check the physical bus tracker's cellular connectivity and GPS antenna connection.
  3. Check Fastify logs on Render for `HTTP 422` (out-of-bounds rejection) or `HTTP 401` (expired token).

### 2.3 Failure Mode: Realtime Change Events Not Received
- **Symptom:** Mobile app does not update bus position immediately; only refreshes every 15 seconds.
- **Root Cause:** Expected behavior under current permissions. Migration `20261014050000` revoked `SELECT` on `bus_current_state` from `anon` to enforce security projection, causing Supabase Realtime CDC to drop client WebSocket delivery.
- **Resolution:** The mobile app's 15-second timer is the verified fallback mechanism. If sub-second push updates are required, implement a Realtime Broadcast trigger.
