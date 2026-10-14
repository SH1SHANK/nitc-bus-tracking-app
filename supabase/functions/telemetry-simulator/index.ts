import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Route R1 57 Coordinates (Mega Hostel Boys <-> East Campus Loop)
// [longitude, latitude] in GeoJSON format
const ROUTE_R1_COORDS: [number, number][] = [
  [75.937622401, 11.317139262],
  [75.937532083, 11.317165826],
  [75.937768504, 11.317949468],
  [75.937952383, 11.318586754],
  [75.936663378, 11.318821721],
  [75.936310197, 11.318524561],
  [75.936197, 11.318517631],
  [75.936102285, 11.318591555],
  [75.936111525, 11.318649309],
  [75.935779808, 11.318773073],
  [75.935682782, 11.318786934],
  [75.935581136, 11.318706079],
  [75.935423053, 11.31875516],
  [75.934940234, 11.318775951],
  [75.934533649, 11.318907629],
  [75.934533649, 11.319785483],
  [75.934529029, 11.320162036],
  [75.934505927, 11.320399981],
  [75.934522098, 11.320919762],
  [75.934508238, 11.321136916],
  [75.934949474, 11.321573532],
  [75.935434649, 11.322106724],
  [75.935560552, 11.322366614],
  [75.935980998, 11.322812472],
  [75.936269765, 11.322843659],
  [75.93660127, 11.32302385],
  [75.936962808, 11.323242158],
  [75.9371661, 11.323344959],
  [75.937283917, 11.323175164],
  [75.9371661, 11.323344959],
  [75.936962808, 11.323242158],
  [75.93660127, 11.32302385],
  [75.936269765, 11.322843659],
  [75.935980998, 11.322812472],
  [75.935560552, 11.322366614],
  [75.935434649, 11.322106724],
  [75.934949474, 11.321573532],
  [75.934508238, 11.321136916],
  [75.934522098, 11.320919762],
  [75.934505927, 11.320399981],
  [75.934529029, 11.320162036],
  [75.934533649, 11.319785483],
  [75.934533649, 11.318907629],
  [75.934940234, 11.318775951],
  [75.935423053, 11.31875516],
  [75.935581136, 11.318706079],
  [75.935682782, 11.318786934],
  [75.935779808, 11.318773073],
  [75.936111525, 11.318649309],
  [75.936102285, 11.318591555],
  [75.936197, 11.318517631],
  [75.936310197, 11.318524561],
  [75.936663378, 11.318821721],
  [75.937952383, 11.318586754],
  [75.937768504, 11.317949468],
  [75.937532083, 11.317165826],
  [75.937622401, 11.317139262],
];

// Route R1 Stops for proximity / dwell slowdown
const ROUTE_R1_STOPS = [
  { name: "Mega Hostel Boys", lat: 11.317167, lon: 75.937750 },
  { name: "ATM Circle", lat: 11.321187, lon: 75.934706 },
  { name: "Department Building", lat: 11.321778, lon: 75.935111 },
  { name: "Architecture", lat: 11.323028, lon: 75.936722 },
  { name: "East Campus", lat: 11.323361, lon: 75.937194 },
];

const DEG_TO_RAD = Math.PI / 180;
const EARTH_RADIUS_M = 6371000;

function distanceMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const dLat = (lat2 - lat1) * DEG_TO_RAD;
  const dLon = (lon2 - lon1) * DEG_TO_RAD;
  const meanLat = ((lat1 + lat2) / 2) * DEG_TO_RAD;
  const x = dLon * Math.cos(meanLat);
  const y = dLat;
  return Math.sqrt(x * x + y * y) * EARTH_RADIUS_M;
}

function bearingDegrees(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const phi1 = lat1 * DEG_TO_RAD;
  const phi2 = lat2 * DEG_TO_RAD;
  const deltaLambda = (lon2 - lon1) * DEG_TO_RAD;
  const y = Math.sin(deltaLambda) * Math.cos(phi2);
  const x = Math.cos(phi1) * Math.sin(phi2) - Math.sin(phi1) * Math.cos(phi2) * Math.cos(deltaLambda);
  const theta = Math.atan2(y, x);
  return (theta * (180 / Math.PI) + 360) % 360;
}

// Compute cumulative segment distances along route
interface SegmentInfo {
  startIdx: number;
  lat1: number;
  lon1: number;
  lat2: number;
  lon2: number;
  lengthMeters: number;
  cumulativeStartMeters: number;
  bearing: number;
}

const SEGMENTS: SegmentInfo[] = [];
let TOTAL_ROUTE_METERS = 0;

for (let i = 0; i < ROUTE_R1_COORDS.length - 1; i++) {
  const [lon1, lat1] = ROUTE_R1_COORDS[i];
  const [lon2, lat2] = ROUTE_R1_COORDS[i + 1];
  const len = distanceMeters(lat1, lon1, lat2, lon2);
  const brg = bearingDegrees(lat1, lon1, lat2, lon2);
  SEGMENTS.push({
    startIdx: i,
    lat1,
    lon1,
    lat2,
    lon2,
    lengthMeters: len,
    cumulativeStartMeters: TOTAL_ROUTE_METERS,
    bearing: brg,
  });
  TOTAL_ROUTE_METERS += len;
}

// Project coordinate onto route geometry to find distance along route
function findProgressMeters(lat: number, lon: number): number {
  let minDistance = Infinity;
  let bestProgressMeters = 0;

  for (const seg of SEGMENTS) {
    if (seg.lengthMeters <= 0.001) continue;

    // Project (lat, lon) onto segment in local Cartesian meters
    const meanLat = ((seg.lat1 + seg.lat2) / 2) * DEG_TO_RAD;
    const cosLat = Math.cos(meanLat);

    const vx = (seg.lon2 - seg.lon1) * DEG_TO_RAD * cosLat * EARTH_RADIUS_M;
    const vy = (seg.lat2 - seg.lat1) * DEG_TO_RAD * EARTH_RADIUS_M;
    const ux = (lon - seg.lon1) * DEG_TO_RAD * cosLat * EARTH_RADIUS_M;
    const uy = (lat - seg.lat1) * DEG_TO_RAD * EARTH_RADIUS_M;

    const vLenSq = vx * vx + vy * vy;
    const t = Math.max(0, Math.min(1, (ux * vx + uy * vy) / vLenSq));

    const projX = seg.lon1 * DEG_TO_RAD * cosLat * EARTH_RADIUS_M + t * vx;
    const projY = seg.lat1 * DEG_TO_RAD * EARTH_RADIUS_M + t * vy;

    const pointX = lon * DEG_TO_RAD * cosLat * EARTH_RADIUS_M;
    const pointY = lat * DEG_TO_RAD * EARTH_RADIUS_M;

    const dist = Math.sqrt((pointX - projX) ** 2 + (pointY - projY) ** 2);

    if (dist < minDistance) {
      minDistance = dist;
      bestProgressMeters = seg.cumulativeStartMeters + t * seg.lengthMeters;
    }
  }

  return bestProgressMeters;
}

// Interpolate position given distance along route
function interpolatePosition(progressMeters: number): {
  lat: number;
  lon: number;
  heading: number;
} {
  const normProgress = ((progressMeters % TOTAL_ROUTE_METERS) + TOTAL_ROUTE_METERS) % TOTAL_ROUTE_METERS;

  for (let i = 0; i < SEGMENTS.length; i++) {
    const seg = SEGMENTS[i];
    const segEnd = seg.cumulativeStartMeters + seg.lengthMeters;

    if (normProgress <= segEnd || i === SEGMENTS.length - 1) {
      const segOffset = Math.max(0, normProgress - seg.cumulativeStartMeters);
      const ratio = seg.lengthMeters > 0 ? Math.min(1, segOffset / seg.lengthMeters) : 0;

      const lat = seg.lat1 + ratio * (seg.lat2 - seg.lat1);
      const lon = seg.lon1 + ratio * (seg.lon2 - seg.lon1);
      return {
        lat: Math.round(lat * 1e6) / 1e6,
        lon: Math.round(lon * 1e6) / 1e6,
        heading: Math.round(seg.bearing * 10) / 10,
      };
    }
  }

  return {
    lat: Math.round(SEGMENTS[0].lat1 * 1e6) / 1e6,
    lon: Math.round(SEGMENTS[0].lon1 * 1e6) / 1e6,
    heading: Math.round(SEGMENTS[0].bearing * 10) / 10,
  };
}

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  const startTime = Date.now();

  try {
    const url = new URL(req.url);
    let body: Record<string, unknown> = {};

    if (req.method === "POST") {
      try {
        body = await req.json();
      } catch {
        body = {};
      }
    }

    // Configurable parameters via query param or JSON body
    const mode = (body.mode as string) || url.searchParams.get("mode") || "simulate";
    const fault = (body.fault as string) || url.searchParams.get("fault") || null;
    const deviceId = (body.deviceId as string) || url.searchParams.get("deviceId") || "NITC-SIM-001";
    const secret = (body.secret as string) || url.searchParams.get("secret") || "SimDeviceSecret123456!";
    const busNumber = (body.busNumber as string) || url.searchParams.get("busNumber") || "Bus 1";
    const apiUrl =
      (body.apiUrl as string) ||
      url.searchParams.get("apiUrl") ||
      Deno.env.get("RENDER_API_URL") ||
      "https://bus-telemetry-api.onrender.com";

    const pointCount = Math.min(10, Math.max(1, Number(body.points || url.searchParams.get("points") || 5)));
    const intervalSec = Math.min(5, Math.max(1, Number(body.interval || url.searchParams.get("interval") || 2.5)));
    const nominalSpeedKmh = Math.min(40, Math.max(5, Number(body.speed || url.searchParams.get("speed") || 20)));

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // ========================================================================
    // MODE 1: INTEGRATION TEST SUITE ("test")
    // ========================================================================
    if (mode === "test") {
      return await runIntegrationTestSuite(supabase, apiUrl, deviceId, secret, busNumber, startTime);
    }

    // ========================================================================
    // MODE 2: CONTINUOUS ROUTE SIMULATION ("simulate" - zero new tables)
    // ========================================================================
    // A hardware tracker's state is strictly derived from standard database state
    // (bus_current_state and devices) and sent over Fastify /api/v1/telemetry.

    // 1. Fetch current canonical state for device
    const { data: curState } = await supabase
      .from("bus_current_state")
      .select("seq, epoch, latitude, longitude, speed, heading, status, recorded_at")
      .eq("device_id", deviceId)
      .maybeSingle();

    const { data: devRecord } = await supabase
      .from("devices")
      .select("id, current_epoch, is_active")
      .eq("device_id", deviceId)
      .maybeSingle();

    let epoch = curState?.epoch ?? devRecord?.current_epoch ?? 1;
    let nextSeq = (curState?.seq ?? 0) + 1;
    let isColdBoot = !curState || (curState.seq === 0) || fault === "reboot";

    // 2. Perform Session Reset on cold boot or reboot fault
    if (isColdBoot) {
      const sessionId = `sim-boot-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;
      const resetRes = await fetch(`${apiUrl}/api/v1/auth/reset-session`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          device_id: deviceId,
          secret,
          session_id: sessionId,
          reason: fault === "reboot" ? "simulator_fault_reboot" : "simulator_cold_boot",
        }),
      });

      if (!resetRes.ok) {
        const errJson = await resetRes.json().catch(() => ({}));
        throw new Error(`Session reset failed with HTTP ${resetRes.status}: ${JSON.stringify(errJson)}`);
      }

      const resetJson = await resetRes.json();
      epoch = resetJson.epoch;
      nextSeq = 1;
    }

    // 3. Obtain Device JWT from Fastify API Gateway
    const authRes = await fetch(`${apiUrl}/api/v1/auth/device`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ device_id: deviceId, secret }),
    });

    if (!authRes.ok) {
      const authErr = await authRes.json().catch(() => ({}));
      throw new Error(`Device authentication failed with HTTP ${authRes.status}: ${JSON.stringify(authErr)}`);
    }

    const { token } = await authRes.json();
    if (!token) {
      throw new Error("No JWT token returned from device auth endpoint");
    }

    // 4. Determine starting route progress
    let currentProgressMeters: number;
    if (!curState?.latitude || !curState?.longitude) {
      // Start at waypoint 0 (Mega Hostel Boys)
      currentProgressMeters = 0;
    } else {
      // Resume by projecting last known location onto Route R1
      currentProgressMeters = findProgressMeters(Number(curState.latitude), Number(curState.longitude));
    }

    // 5. Emit consecutive realistic telemetry fixes
    const stepDistanceMeters = (nominalSpeedKmh / 3.6) * intervalSec;
    const transmittedPackets: Array<Record<string, unknown>> = [];
    const eventsObserved: Array<Record<string, unknown>> = [];

    for (let i = 0; i < pointCount; i++) {
      if (i > 0) {
        // Space requests realistically so timestamps & implied speed are strictly valid
        await new Promise((resolve) => setTimeout(resolve, intervalSec * 1000));
      }

      currentProgressMeters = (currentProgressMeters + stepDistanceMeters) % TOTAL_ROUTE_METERS;
      const pos = interpolatePosition(currentProgressMeters);

      // Check proximity to stops for realistic deceleration / dwell
      let minStopDist = Infinity;
      for (const stop of ROUTE_R1_STOPS) {
        const dist = distanceMeters(pos.lat, pos.lon, stop.lat, stop.lon);
        if (dist < minStopDist) minStopDist = dist;
      }

      let speedKmh = nominalSpeedKmh;
      if (minStopDist < 25) {
        // Dwell / slow speed near stop
        speedKmh = Math.max(3.5, nominalSpeedKmh * 0.3);
      } else if (minStopDist < 60) {
        speedKmh = Math.max(8.0, nominalSpeedKmh * 0.6);
      }

      let fixLat = pos.lat;
      let fixLon = pos.lon;
      let fixSeq = nextSeq + i;
      let fixSpeed = Math.round(speedKmh * 10) / 10;
      let fixHeading = pos.heading;

      // Handle Fault Injection
      if (fault === "gps_drift" && i === Math.floor(pointCount / 2)) {
        // Drift latitude by ~160m off route to trigger route_deviation event
        fixLat = Math.round((pos.lat + 0.0015) * 1e6) / 1e6;
      }

      const packet = {
        device_id: deviceId,
        seq: fixSeq,
        epoch,
        timestamp: new Date().toISOString(),
        latitude: fixLat,
        longitude: fixLon,
        speed: fixSpeed,
        heading: fixHeading,
        accuracy: 4.0,
      };

      // Transmit to Fastify API Gateway
      const telRes = await fetch(`${apiUrl}/api/v1/telemetry`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(packet),
      });

      const telJson = await telRes.json().catch(() => ({}));

      if (telJson.events && Array.isArray(telJson.events) && telJson.events.length > 0) {
        eventsObserved.push(...telJson.events);
      }

      transmittedPackets.push({
        seq: fixSeq,
        epoch,
        latitude: fixLat,
        longitude: fixLon,
        speed: fixSpeed,
        heading: fixHeading,
        status: fixSpeed >= 3.0 ? "moving" : "stationary",
        httpStatus: telRes.status,
        apiResponse: telJson,
      });

      // Special Fault: Duplicate packet retry
      if (fault === "duplicate" && i === 1) {
        const dupRes = await fetch(`${apiUrl}/api/v1/telemetry`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(packet),
        });
        const dupJson = await dupRes.json().catch(() => ({}));
        transmittedPackets.push({
          fault: "duplicate_retry",
          seq: fixSeq,
          httpStatus: dupRes.status,
          apiResponse: dupJson,
        });
      }

      // Special Fault: Conflicting sequence reuse
      if (fault === "conflict" && i === 1) {
        const confPacket = {
          ...packet,
          speed: 45.0,
          heading: (fixHeading + 90) % 360,
        };
        const confRes = await fetch(`${apiUrl}/api/v1/telemetry`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(confPacket),
        });
        const confJson = await confRes.json().catch(() => ({}));
        transmittedPackets.push({
          fault: "conflict_attempt",
          seq: fixSeq,
          httpStatus: confRes.status,
          apiResponse: confJson,
        });
      }
    }

    const durationMs = Date.now() - startTime;

    return new Response(
      JSON.stringify(
        {
          ok: true,
          mode: "simulate",
          deviceId,
          busNumber,
          epoch,
          resumedFrom: {
            isColdBoot,
            previousSeq: curState?.seq ?? 0,
            startProgressMeters: Math.round(currentProgressMeters),
            totalRouteMeters: Math.round(TOTAL_ROUTE_METERS),
          },
          packetsEmitted: transmittedPackets.length,
          faultInjected: fault,
          eventsObserved,
          packets: transmittedPackets,
          durationMs,
        },
        null,
        2,
      ),
      {
        status: 200,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify(
        {
          ok: false,
          mode: "simulate",
          error: errorMsg,
          durationMs: Date.now() - startTime,
        },
        null,
        2,
      ),
      {
        status: 500,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }
});

// ============================================================================
// INTEGRATION TEST SUITE HELPER
// ============================================================================
interface StepResult {
  step: string;
  name: string;
  success: boolean;
  status: number;
  durationMs: number;
  details: Record<string, unknown>;
  error?: string;
}

async function runIntegrationTestSuite(
  supabase: ReturnType<typeof createClient>,
  apiUrl: string,
  deviceId: string,
  secret: string,
  busNumber: string,
  startTime: number,
): Promise<Response> {
  const results: StepResult[] = [];

  try {
    // 0. Ensure device is registered in Supabase
    const t0 = Date.now();
    const { data: regData, error: regError } = await supabase.rpc("register_tracking_device", {
      p_device_id: deviceId,
      p_bus_number: busNumber,
      p_secret: secret,
      p_allow_reassign: true,
    });

    results.push({
      step: "0_provision",
      name: "Device Provisioning / Verification",
      success: !regError && regData?.ok === true,
      status: regError ? 500 : 200,
      durationMs: Date.now() - t0,
      details: { rpcResult: regData, error: regError?.message },
    });

    // 1. Reset Session (Cold boot)
    const sessionId = `sim-boot-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
    const t1 = Date.now();
    const resetRes = await fetch(`${apiUrl}/api/v1/auth/reset-session`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        device_id: deviceId,
        secret,
        session_id: sessionId,
        reason: "simulator_reboot",
      }),
    });
    const resetJson = await resetRes.json();
    const epoch = resetJson.epoch;

    results.push({
      step: "1_reset_session",
      name: "Cold Boot Session Reset",
      success: resetRes.status === 200 && resetJson.ok === true && typeof epoch === "number" && epoch >= 1,
      status: resetRes.status,
      durationMs: Date.now() - t1,
      details: { response: resetJson, sessionId, epoch },
    });

    // 2. Idempotent Retry of Reset Session
    const t2 = Date.now();
    const retryRes = await fetch(`${apiUrl}/api/v1/auth/reset-session`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        device_id: deviceId,
        secret,
        session_id: sessionId,
        reason: "simulator_reboot",
      }),
    });
    const retryJson = await retryRes.json();

    results.push({
      step: "2_idempotent_reset_retry",
      name: "Idempotent Session Reset Retry",
      success: retryRes.status === 200 && retryJson.epoch === epoch && retryJson.idempotent_retry === true,
      status: retryRes.status,
      durationMs: Date.now() - t2,
      details: { response: retryJson },
    });

    // 3. Authenticate and obtain JWT
    const t3 = Date.now();
    const authRes = await fetch(`${apiUrl}/api/v1/auth/device`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ device_id: deviceId, secret }),
    });
    const authJson = await authRes.json();
    const token = authJson.token;

    results.push({
      step: "3_device_auth",
      name: "Device JWT Token Issuance",
      success: authRes.status === 200 && !!token && authJson.token_type === "Bearer",
      status: authRes.status,
      durationMs: Date.now() - t3,
      details: { tokenType: authJson.token_type, expiresIn: authJson.expires_in },
    });

    if (!token) {
      throw new Error("Cannot proceed without device JWT token");
    }

    // 4. Ingest Telemetry Fix Seq 1 (Route R1 Waypoint 0: 11.317139, 75.937622)
    const t4 = Date.now();
    const packet1 = {
      device_id: deviceId,
      seq: 1,
      epoch,
      timestamp: new Date().toISOString(),
      latitude: 11.317139,
      longitude: 75.937622,
      speed: 15.5,
      heading: 45.0,
      accuracy: 4.2,
    };
    const tel1Res = await fetch(`${apiUrl}/api/v1/telemetry`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(packet1),
    });
    const tel1Json = await tel1Res.json();

    results.push({
      step: "4_telemetry_seq_1",
      name: "Monotonic Telemetry Fix (Seq 1)",
      success: tel1Res.status === 200 && tel1Json.stored === true && tel1Json.state_updated === true,
      status: tel1Res.status,
      durationMs: Date.now() - t4,
      details: { packet: packet1, response: tel1Json },
    });

    // 5. Exact Duplicate Retry (Seq 1)
    const t5 = Date.now();
    const dupRes = await fetch(`${apiUrl}/api/v1/telemetry`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(packet1),
    });
    const dupJson = await dupRes.json();

    results.push({
      step: "5_duplicate_retry",
      name: "Exact Duplicate Retry Idempotency",
      success: dupRes.status === 200 && dupJson.stored === false && dupJson.state_updated === false && dupJson.reason === "duplicate",
      status: dupRes.status,
      durationMs: Date.now() - t5,
      details: { response: dupJson },
    });

    // 6. Monotonic Advancing Fix Seq 2
    const t6 = Date.now();
    await new Promise((r) => setTimeout(r, 2000));
    const packet2 = {
      device_id: deviceId,
      seq: 2,
      epoch,
      timestamp: new Date().toISOString(),
      latitude: 11.317166,
      longitude: 75.937532,
      speed: 18.0,
      heading: 50.0,
      accuracy: 4.0,
    };
    const tel2Res = await fetch(`${apiUrl}/api/v1/telemetry`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(packet2),
    });
    const tel2Json = await tel2Res.json();

    results.push({
      step: "6_telemetry_seq_2",
      name: "Monotonic Advancing Fix (Seq 2)",
      success: tel2Res.status === 200 && tel2Json.stored === true && tel2Json.state_updated === true,
      status: tel2Res.status,
      durationMs: Date.now() - t6,
      details: { packet: packet2, response: tel2Json },
    });

    // 7. Conflicting Sequence Reuse Rejection
    const t7 = Date.now();
    const packet2Conflict = {
      ...packet2,
      speed: 35.0,
      heading: 120.0,
    };
    const confRes = await fetch(`${apiUrl}/api/v1/telemetry`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(packet2Conflict),
    });
    const confJson = await confRes.json();

    results.push({
      step: "7_sequence_reuse_conflict",
      name: "Conflicting Sequence Reuse Detection",
      success: confRes.status === 409 && (confJson.code === "SEQUENCE_REUSE_CONFLICT" || confJson.error === "Conflict"),
      status: confRes.status,
      durationMs: Date.now() - t7,
      details: { response: confJson },
    });

    // 8. Database Canonical State Verification
    const t8 = Date.now();
    const { data: dbState, error: stateErr } = await supabase
      .from("bus_current_state")
      .select("device_id, seq, epoch, speed, heading, updated_at")
      .eq("device_id", deviceId)
      .maybeSingle();

    const { count: posCount, error: countErr } = await supabase
      .from("bus_positions")
      .select("*", { count: "exact", head: true })
      .eq("device_id", deviceId);

    const dbSuccess = !stateErr && !countErr && dbState?.seq === 2 && dbState?.epoch === epoch && (posCount ?? 0) >= 2;

    results.push({
      step: "8_database_verification",
      name: "Supabase Database Canonical State Verification",
      success: dbSuccess,
      status: dbSuccess ? 200 : 500,
      durationMs: Date.now() - t8,
      details: {
        busCurrentState: dbState,
        busPositionsCount: posCount,
        stateError: stateErr?.message,
        countError: countErr?.message,
      },
    });

    const allPassed = results.every((r) => r.success);
    const summary = {
      ok: allPassed,
      mode: "test",
      status: allPassed ? "ALL_TESTS_PASSED" : "TESTS_FAILED",
      totalDurationMs: Date.now() - startTime,
      apiUrl,
      deviceId,
      epoch,
      results,
    };

    return new Response(JSON.stringify(summary, null, 2), {
      status: allPassed ? 200 : 500,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify(
        {
          ok: false,
          mode: "test",
          status: "FATAL_ERROR",
          error: errorMsg,
          totalDurationMs: Date.now() - startTime,
          results,
        },
        null,
        2,
      ),
      {
        status: 500,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }
}
