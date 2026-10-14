# Backend Telemetry API Implementation Plan

**Target Repositories**: 
- `backend_bus_tracker` (Fastify REST API Gateway)
- `NITC_BUS_TRACKING_APP` (Supabase Transport Foundation & Flutter Client)

**Authoritative Database Schema**: Supabase Migration `20261014040200_complete_transport_backend_foundation.sql` (Project Ref: `fnngudikrvelpuhngtlw`)  
**Audit Reference**: Comprehensive Backend Telemetry API Audit Report (October 14, 2026)  
**Status**: Ready for Phased Execution  

---

## 1. Executive Summary & Objective

This implementation plan provides an exhaustive, step-by-step engineering roadmap to bring the Fastify telemetry ingestion backend (`backend_bus_tracker`) into complete structural, cryptographic, and operational alignment with the deployed Supabase transport backend (`fnngudikrvelpuhngtlw`).

### Current Problem Statement
The backend API and the deployed database contract currently diverge in multiple critical areas:
1. **Critical RPC Signature Incompatibility (`DB-001`)**: The Fastify repository calls `ingest_telemetry(...)` with 12 legacy parameters including `p_bus_id` and `p_recorded_at`. In production, this fails immediately because the deployed RPC is `ingest_telemetry_packet(...)` which derives `bus_id` dynamically from `devices.bus_id`, accepts `p_epoch`, uses `p_timestamp`, and relies on a `(device_id, epoch, seq)` unique index rather than the dropped `(bus_id, recorded_at)` constraint.
2. **Error Flattening & False Rejections (`DB-002`)**: Fastify inspects `result.reason`, which does not exist in `ingest_telemetry_packet` (it returns `{ success, code, error, bus_id, status }`), causing all non-success outcomes to be returned as `401 Unauthorized` (`device_inactive`).
3. **Cryptographic Incompatibility (`SEC-001`)**: Fastify hashes secrets using Node.js `scrypt`, while PostgreSQL functions (`register_tracking_device` and `reset_device_sequence`) use `pgcrypto` Bcrypt (`$2a$08$...`). Devices provisioned via the API cannot authenticate via database RPCs, and devices provisioned in SQL fail API authentication.
4. **Sequence Lockout on Reboot (`DATA-001`)**: The API has no sequence epoch support and provides no endpoint for `reset_device_sequence`. When an ESP32 hardware tracker reboots and its monotonic sequence counter resets to 1, all packets are permanently rejected as stale.
5. **Pre-Ingestion Anomaly Dropping (`DATA-005` / `CONC-001`)**: Fastify executes an unlocked query (`getLastState`) and discards duplicate or out-of-order packets in Node memory before invoking Supabase. This creates dirty-read race conditions, bypasses PostgreSQL transaction-scoped advisory locks (`1001` device, `1002` bus), and prevents `devices.last_seen` liveness updates.
6. **Validation Mismatches (`DATA-002`, `DATA-003`, `DATA-004`)**: Fastify permits coordinates across Kerala (`[8.0, 12.9]`), but the database strictly enforces the NITC corridor (`[11.200000, 11.450000]`). Fastify allows 6-hour-old packets, but the database rejects anything older than 15 minutes (`900s`). Fastify's JSON schema rejects optional `epoch` and forbids `null` values for `speed`, `heading`, and `accuracy`.

### Target Architecture
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             ESP32 / Mock Tracker                            │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ HTTPS POST /api/v1/telemetry
                                       │ Bearer Device JWT
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Fastify Gateway (backend_bus_tracker)                    │
│  - Strict JSON Schema Validation (NITC Corridor bounds, ±900s clock drift)   │
│  - Trust Proxy Validation (Loopback / Private CIDR / Render RFC1918)        │
│  - Active Device Verification (devices.is_active check)                      │
│  - Pass-through to Database RPC (NO in-memory duplicate packet dropping)     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Supabase Service Role RPC
                                       │ ingest_telemetry_packet(...)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                  PostgreSQL Database Engine (Supabase / PostGIS)            │
│  - Advisory Locks: pg_advisory_xact_lock(1001, dev_crc), (1002, bus_crc)    │
│  - Monotonic Epoch & Sequence Deduplication (device_id, epoch, seq)          │
│  - Dynamic Bus Resolution (from active device assignment)                   │
│  - Atomic Multi-Table Mutation:                                             │
│      ├── bus_positions (history ledger)                                      │
│      ├── bus_current_state (realtime snapshot)                              │
│      └── devices (last_seen_at liveness)                                    │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Supabase Realtime (WAL change)
                                       │ bus_current_state UPDATE
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Flutter Client (NITC_BUS_TRACKING_APP)                   │
│  - Active Map Marker Updates & ETA Animations                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Source-of-Truth Contract Specification

### 2.1 Database Ingestion RPC: `ingest_telemetry_packet`
- **Schema & Owner**: `public.ingest_telemetry_packet(...)`, `SECURITY DEFINER`, search_path `public, extensions, auth`.
- **Parameter Signature**:
  ```sql
  FUNCTION public.ingest_telemetry_packet(
    p_device_id uuid,
    p_seq bigint,
    p_timestamp timestamptz,
    p_latitude double precision,
    p_longitude double precision,
    p_speed double precision DEFAULT NULL::double precision,
    p_heading double precision DEFAULT NULL::double precision,
    p_accuracy double precision DEFAULT NULL::double precision,
    p_status text DEFAULT 'in_service'::text,
    p_stop_radius_m double precision DEFAULT 40.0::double precision,
    p_deviation_m double precision DEFAULT 100.0::double precision,
    p_epoch integer DEFAULT 0
  ) RETURNS jsonb
  ```
- **Return JSON Structure**:
  - **Success**:
    ```json
    { "success": true, "code": "INGESTED", "bus_id": "uuid", "status": "in_service" }
    ```
  - **Handled Non-Error (Idempotent Duplicate)**:
    ```json
    { "success": true, "code": "DUPLICATE_PACKET", "bus_id": "uuid", "status": "in_service" }
    ```
  - **Rejections (`success: false`)**:
    - `"DEVICE_NOT_FOUND"`: Device does not exist in `devices` table.
    - `"DEVICE_INACTIVE"`: `devices.is_active` is `false`.
    - `"DEVICE_NOT_ASSIGNED"`: `devices.bus_id` is `NULL`.
    - `"BUS_NOT_FOUND"`: Referenced bus row missing.
    - `"BUS_INACTIVE"`: `buses.is_active` is `false`.
    - `"UNAUTHORIZED_EPOCH"`: `p_epoch > devices.current_epoch`.
    - `"STALE_EPOCH"`: `p_epoch < devices.current_epoch`.
    - `"STALE_SEQUENCE"`: `p_seq < bus_current_state.seq` in current epoch.
    - `"SEQUENCE_REUSE_CONFLICT"`: `(device_id, epoch, seq)` exists in `bus_positions` with divergent coordinate/timestamp payload.
    - `"PACKET_TOO_OLD"`: `p_timestamp < now() - interval '15 minutes'`.
    - `"PACKET_FROM_FUTURE"`: `p_timestamp > now() + interval '5 minutes'`.
    - `"INVALID_COORDINATES"`: Latitude outside `[11.200000, 11.450000]` or longitude outside `[75.750000, 76.050000]`.
    - `"INVALID_HEADING"`: Heading not `NULL` and not in `[0, 360]`.
    - `"INVALID_ACCURACY"`: Accuracy not `NULL` and outside `[0, 500]`.
    - `"INVALID_SPEED"`: Speed not `NULL` and outside `[0, 120]` (in km/h).

### 2.2 Database Reset Session RPC: `reset_device_sequence`
- **Schema & Owner**: `public.reset_device_sequence(...)`, `SECURITY DEFINER`, search_path `public, extensions, auth`.
- **Parameter Signature**:
  ```sql
  FUNCTION public.reset_device_sequence(
    p_device_id uuid,
    p_secret text,
    p_session_id text DEFAULT NULL::text,
    p_reason text DEFAULT 'clean_reset'::text
  ) RETURNS jsonb
  ```
- **Verification Rule**: Verifies `v_device.secret_hash = crypt(p_secret, v_device.secret_hash)`.
- **Action**: Increments `devices.current_epoch = devices.current_epoch + 1`, logs reset to `telemetry_reset_logs`, updates `devices.last_session_id`.
- **Return JSON Structure**:
  - Success: `{"success": true, "code": "RESET_CONFIRMED", "epoch": 1, "device_id": "...", "bus_id": "..."}`
  - Failure: `{"success": false, "code": "UNAUTHORIZED", "error": "Invalid device credentials"}`

### 2.3 Unit Conventions
| Metric | API Ingestion Schema | Supabase RPC | Flutter Model / Realtime | Notes |
|---|---|---|---|---|
| Speed | `km/h` (float) | `km/h` (float) | `km/h` (float) | Fastify and DB both expect km/h. Max: 120.0 km/h. |
| Heading | degrees `[0, 360]` | degrees `[0, 360]` | degrees `[0, 360]` | 360 normalized to 0. |
| Accuracy | meters `[0, 500]` | meters `[0, 500]` | meters | Nullable float. |
| Coordinates | `[lat, lng]` WGS84 | `[lat, lng]` WGS84 | `[lat, lng]` WGS84 | NITC Corridor: Lat `11.20-11.45`, Lng `75.75-76.05`. |
| Epoch | integer `>= 0` | integer `>= 0` | integer | Defaults to 0 if omitted by legacy trackers. |

---

## 3. Findings & Resolution Matrix

| Finding ID | Severity | File(s) Affected | Proposed Engineering Resolution |
|---|---|---|---|
| **DB-001** | CRITICAL | `src/repositories/telemetry.repo.ts` | Replace `ingest_telemetry` RPC call with `ingest_telemetry_packet`. Align all 12 parameters (`p_device_id`, `p_seq`, `p_timestamp`, `p_latitude`, `p_longitude`, `p_speed`, `p_heading`, `p_accuracy`, `p_status`, `p_stop_radius_m`, `p_deviation_m`, `p_epoch`). Remove `p_bus_id`. |
| **DB-002** | HIGH | `src/routes/telemetry.ts` | Refactor RPC outcome mapping. Check `result.code`. Map rejections to specific 4xx/5xx status codes instead of generic 401 `device_inactive`. Treat `DUPLICATE_PACKET` as HTTP 200 `{ stored: true, duplicate: true }`. |
| **SEC-001** | CRITICAL | `src/lib/password.ts`, `scripts/provision-device.ts` | Replace custom Node.js `scrypt` hashing with `bcryptjs` (8 rounds). Match `pgcrypto` `crypt(secret, gen_salt('bf', 8))` exactly. |
| **SEC-002** | MEDIUM | `src/schemas/auth.ts`, `scripts/provision-device.ts` | Ensure secret length validation allows standard 8-char to 64-char device secrets, matching PostgreSQL constraint `length(p_secret) >= 8`. |
| **SEC-003** | HIGH | `src/plugins/auth.ts` | Update `authenticateDevice` hook to query `devices.is_active` and `devices.bus_id` dynamically from cache/DB instead of trusting static JWT claims for 12 hours. |
| **SEC-004** | MEDIUM | `src/app.ts`, `src/config.ts` | Configure `trustProxy` with strict CIDR masks (e.g. `127.0.0.1/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16`) instead of boolean `true`. |
| **DATA-001** | CRITICAL | `src/routes/auth.ts`, `src/schemas/auth.ts` | Implement `POST /api/v1/auth/reset-session` endpoint in Fastify calling `reset_device_sequence`. Allow hardware trackers to advance epoch upon reboot. |
| **DATA-002** | HIGH | `src/schemas/telemetry.ts`, `src/services/validation.ts` | Align geospatial boundaries to NITC Corridor: Latitude `[11.200000, 11.450000]`, Longitude `[75.750000, 76.050000]`. |
| **DATA-003** | HIGH | `src/services/validation.ts` | Align max timestamp drift to 15 minutes past (`900s`) and 5 minutes future (`300s`) matching PostgreSQL RPC assertions. |
| **DATA-004** | MEDIUM | `src/schemas/telemetry.ts` | Add optional `epoch` integer field to schema. Allow `speed`, `heading`, and `accuracy` to be `null` in JSON schema. |
| **DATA-005** | HIGH | `src/services/anomaly.ts`, `src/routes/telemetry.ts` | Remove in-memory `getLastState` check that drops packets prior to RPC. Let `ingest_telemetry_packet` handle deduplication under advisory locks. |
| **CONC-001**| HIGH | `src/services/processing.ts`, `src/routes/telemetry.ts` | Eliminate pre-ingestion race condition. Rely exclusively on PostgreSQL advisory locks (`1001` device, `1002` bus) inside transaction. |
| **API-001** | MEDIUM | `src/routes/trips.ts` | In `endTrip`, clear `bus_current_state.trip_id` when closing a trip to prevent orphaned active trip IDs on idle buses. |
| **API-002** | MEDIUM | `src/routes/buses.ts` | Call canonical `get_nearby_buses` and `get_nearby_stops` RPCs with distance and limit parameters. |
| **DEP-001** | LOW | `src/routes/health.ts` | Add `/readyz` probe executing `SELECT 1` on Supabase to distinguish process liveness from database readiness. |

---

## 4. Phased Implementation Plan

### Phase 0: Dependencies & Configuration Alignment
**Primary Directory**: `/Users/shashankmergu/Desktop/backend_bus_tracker`  
**Goal**: Install necessary cryptographic library and configure environment boundaries.

#### Step 0.1: Add `bcryptjs` and types
- **Action**: Add `bcryptjs` and `@types/bcryptjs` to `package.json`.
- **Command**:
  ```bash
  npm install bcryptjs
  npm install --save-dev @types/bcryptjs
  ```
- **Rationale**: `bcryptjs` is pure JavaScript with zero C++ compilation dependencies, ensuring flawless cross-platform deployment between macOS development and Render Alpine/Linux containers, while generating `$2a$` hashes 100% binary-compatible with PostgreSQL `pgcrypto`.

#### Step 0.2: Update Configuration Constants in `src/config.ts`
- **File**: `src/config.ts`
- **Changes**:
  1. Add NITC corridor geospatial bounding box constants:
     ```typescript
     export const NITC_BOUNDS = {
       MIN_LAT: 11.200000,
       MAX_LAT: 11.450000,
       MIN_LNG: 75.750000,
       MAX_LNG: 76.050000,
     } as const;
     ```
  2. Add maximum clock drift constants matching database intervals:
     ```typescript
     export const TELEMETRY_LIMITS = {
       MAX_PAST_DRIFT_SECONDS: 900, // 15 minutes (matches DB interval '15 minutes')
       MAX_FUTURE_DRIFT_SECONDS: 300, // 5 minutes (matches DB interval '5 minutes')
       MAX_SPEED_KMH: 120.0,
       MAX_ACCURACY_METERS: 500.0,
       DEFAULT_STOP_RADIUS_METERS: 40.0,
       DEFAULT_ROUTE_DEVIATION_METERS: 100.0,
     } as const;
     ```
  3. Update `trustProxy` setting in `src/config.ts` to allow specific private subnets (Render load balancer):
     ```typescript
     export const TRUSTED_PROXIES = process.env.TRUSTED_PROXIES 
       ? process.env.TRUSTED_PROXIES.split(',') 
       : ['127.0.0.1', '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'];
     ```

---

### Phase 1: Cryptographic Unification & Session Reset (P0)
**Goal**: Resolve `SEC-001`, `SEC-002`, and `DATA-001`. Enable devices to authenticate identically across Fastify and PostgreSQL, and provide the session reset endpoint.

#### Step 1.1: Refactor `src/lib/password.ts` to use Bcrypt
- **File**: `src/lib/password.ts`
- **Implementation**:
  ```typescript
  import bcrypt from 'bcryptjs';

  const BCRYPT_ROUNDS = 8; // Exactly matches pgcrypto gen_salt('bf', 8)

  /**
   * Hashes a secret using Bcrypt with 8 salt rounds, matching PostgreSQL pgcrypto.
   */
  export async function hashSecret(secret: string): Promise<string> {
    return bcrypt.hash(secret, BCRYPT_ROUNDS);
  }

  /**
   * Verifies a secret against a stored Bcrypt hash ($2a$ or $2b$).
   */
  export async function verifySecret(secret: string, hash: string): Promise<boolean> {
    if (!secret || !hash) return false;
    return bcrypt.compare(secret, hash);
  }
  ```

#### Step 1.2: Update `scripts/provision-device.ts`
- **File**: `scripts/provision-device.ts`
- **Changes**: Ensure provisioned device secret hashes use `hashSecret` from `src/lib/password.ts` with 8 rounds, and enforce secret length `>= 8` characters.

#### Step 1.3: Implement `POST /api/v1/auth/reset-session`
- **File**: `src/schemas/auth.ts`
  ```typescript
  export const ResetSessionBodySchema = {
    type: 'object',
    required: ['device_id', 'secret'],
    properties: {
      device_id: { type: 'string', format: 'uuid' },
      secret: { type: 'string', minLength: 8, maxLength: 64 },
      session_id: { type: 'string', maxLength: 128 },
      reason: { type: 'string', maxLength: 100 },
    },
    additionalProperties: false,
  } as const;
  ```
- **File**: `src/routes/auth.ts`
  Add the reset-session endpoint:
  ```typescript
  fastify.post('/reset-session', {
    schema: {
      tags: ['auth'],
      summary: 'Reset device sequence counter on reboot',
      body: ResetSessionBodySchema,
    },
  }, async (request, reply) => {
    const { device_id, secret, session_id, reason } = request.body as any;

    const { data, error } = await supabase.rpc('reset_device_sequence', {
      p_device_id: device_id,
      p_secret: secret,
      p_session_id: session_id || null,
      p_reason: reason || 'hardware_reboot',
    });

    if (error) {
      request.log.error({ err: error, device_id }, 'reset_device_sequence RPC failed');
      return reply.code(500).send({
        statusCode: 500,
        error: 'Database Error',
        message: 'Failed to reset device sequence',
      });
    }

    if (!data || !data.success) {
      const code = data?.code || 'UNAUTHORIZED';
      request.log.warn({ device_id, code }, 'Device sequence reset rejected');
      return reply.code(401).send({
        statusCode: 401,
        error: 'Unauthorized',
        message: data?.error || 'Invalid device credentials',
        code,
      });
    }

    request.log.info({ device_id, epoch: data.epoch }, 'Device sequence reset successful');
    return reply.code(200).send({
      success: true,
      code: 'RESET_CONFIRMED',
      epoch: data.epoch,
      device_id: data.device_id,
      bus_id: data.bus_id,
    });
  });
  ```

---

### Phase 2: Schema, Validation & Anomaly Refinement (P0/P1)
**Goal**: Resolve `DATA-002`, `DATA-003`, `DATA-004`, `DATA-005`, and `CONC-001`.

#### Step 2.1: Update Ingestion Schema in `src/schemas/telemetry.ts`
- **File**: `src/schemas/telemetry.ts`
- **Adjustments**:
  - Add optional `epoch`: `{ type: 'integer', minimum: 0, default: 0 }`.
  - Adjust coordinates to NITC corridor:
    - `latitude`: `minimum: 11.200000`, `maximum: 11.450000`.
    - `longitude`: `minimum: 75.750000`, `maximum: 76.050000`.
  - Allow `speed`, `heading`, and `accuracy` to accept `null`:
    - `speed`: `{ type: ['number', 'null'], minimum: 0, maximum: 120 }`.
    - `heading`: `{ type: ['number', 'null'], minimum: 0, maximum: 360 }`.
    - `accuracy`: `{ type: ['number', 'null'], minimum: 0, maximum: 500 }`.
  - Status enum: `['in_service', 'out_of_service', 'maintenance', 'emergency']`.

#### Step 2.2: Refactor Validation in `src/services/validation.ts`
- **File**: `src/services/validation.ts`
- **Adjustments**:
  - Check clock drift against DB boundaries:
    ```typescript
    const now = Date.now();
    const packetTime = new Date(telemetry.timestamp).getTime();
    const pastDriftSec = (now - packetTime) / 1000;
    const futureDriftSec = (packetTime - now) / 1000;

    if (pastDriftSec > TELEMETRY_LIMITS.MAX_PAST_DRIFT_SECONDS) {
      return { valid: false, reason: 'PACKET_TOO_OLD', message: 'Packet timestamp is older than 15 minutes' };
    }
    if (futureDriftSec > TELEMETRY_LIMITS.MAX_FUTURE_DRIFT_SECONDS) {
      return { valid: false, reason: 'PACKET_FROM_FUTURE', message: 'Packet timestamp is more than 5 minutes in the future' };
    }
    ```
  - Normalize heading `360.0` to `0.0`.

#### Step 2.3: Remove In-Memory Anomaly Dropping (`src/services/anomaly.ts`)
- **File**: `src/services/anomaly.ts`
- **Rationale**: Anomaly detection in Fastify was doing an unisolated `getLastState(device.bus_id)` query and returning `isDuplicate: true` or `isStale: true`, causing Fastify to skip calling Supabase. This bypassed the database's advisory lock protection and prevented `devices.last_seen` from updating on duplicates.
- **Action**: Simplify Fastify's anomaly service to stateless rate checks (or GPS leap heuristic logging only) and never drop packets before calling the database. Let `ingest_telemetry_packet` be the single authoritative arbiter for sequence and deduplication under transaction-scoped advisory locks.

---

### Phase 3: Supabase Ingestion RPC Integration (P0)
**Goal**: Resolve `DB-001` and `DB-002`.

#### Step 3.1: Refactor `src/repositories/telemetry.repo.ts`
- **File**: `src/repositories/telemetry.repo.ts`
- **Implementation**:
  ```typescript
  import { supabase } from '../lib/supabase';

  export interface IngestionParams {
    deviceId: string;
    seq: number;
    timestamp: string; // ISO-8601 string
    latitude: number;
    longitude: number;
    speed?: number | null;
    heading?: number | null;
    accuracy?: number | null;
    status?: string;
    stopRadiusM?: number;
    deviationM?: number;
    epoch?: number;
  }

  export interface IngestionResult {
    success: boolean;
    code: string;
    bus_id?: string;
    status?: string;
    error?: string;
  }

  export async function ingestTelemetryPacket(params: IngestionParams): Promise<IngestionResult> {
    const { data, error } = await supabase.rpc('ingest_telemetry_packet', {
      p_device_id: params.deviceId,
      p_seq: params.seq,
      p_timestamp: params.timestamp,
      p_latitude: params.latitude,
      p_longitude: params.longitude,
      p_speed: params.speed ?? null,
      p_heading: params.heading ?? null,
      p_accuracy: params.accuracy ?? null,
      p_status: params.status ?? 'in_service',
      p_stop_radius_m: params.stopRadiusM ?? 40.0,
      p_deviation_m: params.deviationM ?? 100.0,
      p_epoch: params.epoch ?? 0,
    });

    if (error) {
      throw error;
    }

    return data as IngestionResult;
  }
  ```

#### Step 3.2: Refactor Route Ingestion Handler in `src/routes/telemetry.ts`
- **File**: `src/routes/telemetry.ts`
- **Implementation**:
  ```typescript
  fastify.post('/', {
    schema: {
      tags: ['telemetry'],
      summary: 'Ingest bus GPS telemetry packet',
      body: TelemetryBodySchema,
    },
    preHandler: [fastify.authenticateDevice],
  }, async (request, reply) => {
    const device = request.device;
    const body = request.body as any;

    try {
      const result = await ingestTelemetryPacket({
        deviceId: device.device_id,
        seq: body.seq,
        timestamp: body.timestamp,
        latitude: body.latitude,
        longitude: body.longitude,
        speed: body.speed,
        heading: body.heading,
        accuracy: body.accuracy,
        status: body.status,
        epoch: body.epoch ?? 0,
      });

      // Handle handled non-fatal states (idempotent duplicate)
      if (result.success && result.code === 'DUPLICATE_PACKET') {
        return reply.code(200).send({
          stored: true,
          duplicate: true,
          code: 'DUPLICATE_PACKET',
          bus_id: result.bus_id,
          status: result.status,
        });
      }

      if (result.success) {
        return reply.code(200).send({
          stored: true,
          duplicate: false,
          code: 'INGESTED',
          bus_id: result.bus_id,
          status: result.status,
        });
      }

      // Handle database rejections
      request.log.warn({ code: result.code, error: result.error, device_id: device.device_id }, 'Telemetry ingestion rejected by DB');

      switch (result.code) {
        case 'DEVICE_NOT_FOUND':
        case 'DEVICE_INACTIVE':
        case 'BUS_NOT_FOUND':
        case 'BUS_INACTIVE':
          return reply.code(401).send({
            statusCode: 401,
            error: 'Unauthorized',
            code: result.code,
            message: result.error || 'Device or bus is inactive or not found',
          });

        case 'DEVICE_NOT_ASSIGNED':
          return reply.code(403).send({
            statusCode: 403,
            error: 'Forbidden',
            code: result.code,
            message: 'Device is not assigned to any bus',
          });

        case 'UNAUTHORIZED_EPOCH':
        case 'STALE_EPOCH':
        case 'STALE_SEQUENCE':
        case 'SEQUENCE_REUSE_CONFLICT':
          return reply.code(409).send({
            statusCode: 409,
            error: 'Conflict',
            code: result.code,
            message: result.error || 'Sequence or epoch conflict',
          });

        case 'PACKET_TOO_OLD':
        case 'PACKET_FROM_FUTURE':
        case 'INVALID_COORDINATES':
        case 'INVALID_HEADING':
        case 'INVALID_ACCURACY':
        case 'INVALID_SPEED':
          return reply.code(422).send({
            statusCode: 422,
            error: 'Unprocessable Entity',
            code: result.code,
            message: result.error || 'Telemetry payload failed validation',
          });

        default:
          return reply.code(400).send({
            statusCode: 400,
            error: 'Bad Request',
            code: result.code || 'UNKNOWN_ERROR',
            message: result.error || 'Ingestion failed',
          });
      }
    } catch (err: any) {
      request.log.error({ err, device_id: device.device_id }, 'Unexpected error during telemetry ingestion');
      return reply.code(500).send({
        statusCode: 500,
        error: 'Internal Server Error',
        message: 'Failed to process telemetry packet',
      });
    }
  });
  ```

---

### Phase 4: Authentication Hardening & Rate Limiting (P1)
**Goal**: Resolve `SEC-003` and `SEC-004`.

#### Step 4.1: Fastify Trust Proxy Configuration
- **File**: `src/app.ts`
- **Change**: Replace `trustProxy: true` with strict CIDR masks from `TRUSTED_PROXIES` in `src/config.ts`.
  ```typescript
  const app = Fastify({
    logger: true,
    trustProxy: TRUSTED_PROXIES,
  });
  ```

#### Step 4.2: Dynamic Device Liveness & Assignment Verification
- **File**: `src/plugins/auth.ts`
- **Change**: In `authenticateDevice`, after verifying the JWT payload, verify `devices.is_active` in Supabase (with a short 30-second LRU in-memory cache to prevent database query amplification) before passing request to the handler.
- If `is_active === false`, reject immediately with HTTP 401 `DEVICE_DEACTIVATED`.

---

### Phase 5: Transit Operations & Bus/Stop API Alignment (P2)
**Goal**: Resolve `API-001` and `API-002`.

#### Step 5.1: Trip Completion State Cleanup
- **File**: `src/routes/trips.ts`
- **Change**: In `endTrip`, when setting `trips.status = 'completed'`, also execute:
  ```typescript
  await supabase
    .from('bus_current_state')
    .update({ trip_id: null })
    .eq('bus_id', busId);
  ```

#### Step 5.2: Align Stop and Bus Query RPCs
- **File**: `src/routes/buses.ts`
- **Change**:
  - Replace legacy `nearby_buses` RPC call with canonical `get_nearby_buses(p_lat, p_lng, p_radius_m, p_limit)`.
  - Replace legacy `nearest_stops` RPC call with canonical `get_nearby_stops(p_lat, p_lng, p_radius_m, p_limit)`.

---

### Phase 6: Health Probes & Readiness (P2)
**Goal**: Resolve `DEP-001`.

#### Step 6.1: Add Database Readiness Probe
- **File**: `src/routes/health.ts`
- **Implementation**:
  - Retain `GET /healthz` as a fast process liveness probe (returns `{ status: 'ok' }`).
  - Add `GET /readyz`: Executes `supabase.from('devices').select('count', { count: 'exact', head: true })`.
  - If database query responds within 2 seconds, return HTTP 200 `{ ready: true, database: 'connected' }`.
  - If database query times out or fails, return HTTP 503 `{ ready: false, database: 'unreachable' }`.

---

### Phase 7: Test Suite Overhaul & Mocking (P1)
**Goal**: Update unit and integration tests to pass against the new contracts.

#### Step 7.1: Overhaul `test/telemetry.route.test.ts`
- Update tests to mock `ingest_telemetry_packet` with `{ success: true, code: 'INGESTED', bus_id: '...' }`.
- Add test assertions for:
  - Valid packet returns `200 { stored: true, duplicate: false }`.
  - Duplicate packet returns `200 { stored: true, duplicate: true, code: 'DUPLICATE_PACKET' }`.
  - Sequence reuse conflict returns `409 Conflict`.
  - Stale sequence returns `409 Conflict`.
  - Stale/Unauthorized epoch returns `409 Conflict`.
  - Packet older than 15 minutes returns `422 Unprocessable Entity`.
  - Coordinates outside NITC corridor return `422 Unprocessable Entity`.

#### Step 7.2: Create `test/reset_session.test.ts`
- Test `POST /api/v1/auth/reset-session`:
  - Valid credentials advance epoch and return `200 { success: true, epoch: 1 }`.
  - Invalid credentials return `401 Unauthorized`.
  - Missing secret or device_id returns `400 Bad Request`.

---

## 5. File-by-File Implementation Checklist

| File | Status / Action | Details |
|---|---|---|
| `package.json` | Modify | Add `bcryptjs` and `@types/bcryptjs`. |
| `src/config.ts` | Modify | Define `NITC_BOUNDS`, `TELEMETRY_LIMITS`, `TRUSTED_PROXIES`. |
| `src/app.ts` | Modify | Use `TRUSTED_PROXIES` for `trustProxy`. |
| `src/lib/password.ts` | Modify | Rewrite using `bcryptjs` with 8 salt rounds. |
| `scripts/provision-device.ts` | Modify | Use Bcrypt 8 rounds, enforce secret length >= 8. |
| `src/schemas/auth.ts` | Modify | Add `ResetSessionBodySchema`. |
| `src/routes/auth.ts` | Modify | Add `POST /reset-session` route calling `reset_device_sequence`. |
| `src/plugins/auth.ts` | Modify | Add active device DB check on authenticated requests. |
| `src/schemas/telemetry.ts` | Modify | Add `epoch`, allow nullable metrics, enforce NITC bounds. |
| `src/services/validation.ts` | Modify | Check 15m past / 5m future drift, NITC bounds, heading normalize. |
| `src/services/anomaly.ts` | Modify | Remove pre-ingestion duplicate drop. |
| `src/repositories/telemetry.repo.ts` | Modify | Point to `ingest_telemetry_packet`, fix parameters and return types. |
| `src/routes/telemetry.ts` | Modify | Update handler to process `ingest_telemetry_packet` response codes. |
| `src/routes/trips.ts` | Modify | Clear `bus_current_state.trip_id` on trip completion. |
| `src/routes/buses.ts` | Modify | Call `get_nearby_buses` and `get_nearby_stops`. |
| `src/routes/health.ts` | Modify | Add `GET /readyz` DB check. |
| `test/telemetry.route.test.ts` | Modify | Update RPC mocks and response expectations. |
| `test/reset_session.test.ts` | Create | New test suite for reboot session reset. |

---

## 6. Verification and Acceptance Criteria

### 6.1 Cryptographic Interoperability
- [ ] A device hash generated in Node via `hashSecret("device_secret_123")` evaluates to `true` when tested against PostgreSQL `crypt('device_secret_123', hash)`.
- [ ] A hash generated in PostgreSQL via `crypt('device_secret_123', gen_salt('bf', 8))` evaluates to `true` when tested in Node via `verifySecret('device_secret_123', hash)`.

### 6.2 Telemetry Ingestion Contract
- [ ] `POST /api/v1/telemetry` with valid payload calls `ingest_telemetry_packet` with exact 12 parameters and returns `HTTP 200 { stored: true, duplicate: false }`.
- [ ] Sending the exact same packet again returns `HTTP 200 { stored: true, duplicate: true, code: 'DUPLICATE_PACKET' }`.
- [ ] Sending a packet with sequence lower than current state returns `HTTP 409 Conflict` with `code: 'STALE_SEQUENCE'`.
- [ ] Sending a packet with identical sequence but different coordinates returns `HTTP 409 Conflict` with `code: 'SEQUENCE_REUSE_CONFLICT'`.
- [ ] Sending a packet with timestamp 16 minutes old returns `HTTP 422 Unprocessable Entity` with `code: 'PACKET_TOO_OLD'`.
- [ ] Sending coordinates outside NITC corridor returns `HTTP 422 Unprocessable Entity` with `code: 'INVALID_COORDINATES'`.

### 6.3 Reboot & Session Reset
- [ ] `POST /api/v1/auth/reset-session` with valid device ID and secret returns `HTTP 200 { success: true, epoch: N + 1 }`.
- [ ] Ingesting telemetry with new epoch and sequence 1 succeeds immediately after reset.

---

## 7. Rollout & Rollback Plan

### 7.1 Staging Deployment
1. Deploy Fastify backend changes to Render staging environment.
2. Run mock ESP32 script sending 100 packets at 1 Hz across NITC campus corridor.
3. Verify `bus_positions` inserts, `bus_current_state` updates, and `devices.last_seen_at` updates.
4. Verify Flutter client receives Realtime WebSocket updates on map without visual jitter or disconnects.

### 7.2 Rollback Strategy
If unexpected errors occur on Render after deployment:
1. Revert Render deployment to the previous stable git commit.
2. Database requires zero rollback because migration `20261014040200` is already deployed and backwards-compatible with standard RPC parameters.

---

## 8. Summary of Decisions Requiring User Confirmation

1. **`bcryptjs` Adoption**: Pure JavaScript implementation of Bcrypt with 8 salt rounds was chosen over native `bcrypt` to prevent native C++ compilation failures on Render / Docker.
2. **Elimination of Fastify Pre-Ingestion Anomaly Drop**: Fastify will delegate sequence and duplicate handling exclusively to PostgreSQL's advisory-locked RPC.
3. **NITC Corridor Enforced at API Boundary**: API will reject out-of-corridor GPS packets early (HTTP 422) instead of waiting for database rejections.
