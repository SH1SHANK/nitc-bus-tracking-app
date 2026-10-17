import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

// ============================================================================
// GEOGRAPHIC & ROUTE DEFINITIONS
// ============================================================================

// Route R1: Mega Hostel Boys <-> East Campus Loop (57 waypoints)
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

// Route R2: East Campus - SOMS Loop (55 waypoints)
const ROUTE_R2_COORDS: [number, number][] = [
  [75.932509521, 11.31486636],
  [75.933270755, 11.315101074],
  [75.933879743, 11.315767154],
  [75.933578421, 11.316011383],
  [75.933473751, 11.31616363],
  [75.933505469, 11.316325393],
  [75.933920976, 11.316569622],
  [75.933505469, 11.317286451],
  [75.933522505, 11.317865765],
  [75.933414664, 11.318633343],
  [75.932209376, 11.318474752],
  [75.931188053, 11.318068761],
  [75.93083281, 11.318633343],
  [75.932095191, 11.319305767],
  [75.932095191, 11.319603917],
  [75.932019067, 11.319781538],
  [75.932653429, 11.319952816],
  [75.933674752, 11.321113699],
  [75.9340744, 11.321494316],
  [75.93451211, 11.32113273],
  [75.93545731, 11.322109647],
  [75.935568224, 11.322362847],
  [75.935971044, 11.322803728],
  [75.936278709, 11.322844962],
  [75.936532454, 11.322987693],
  [75.936973336, 11.323254125],
  [75.937179503, 11.323346108],
  [75.937300032, 11.323184346],
  [75.937179503, 11.323346108],
  [75.936973336, 11.323254125],
  [75.936532454, 11.322987693],
  [75.936278709, 11.322844962],
  [75.935971044, 11.322803728],
  [75.935568224, 11.322362847],
  [75.93545731, 11.322109647],
  [75.93451211, 11.32113273],
  [75.9340744, 11.321494316],
  [75.933674752, 11.321113699],
  [75.932653429, 11.319952816],
  [75.932019067, 11.319781538],
  [75.932095191, 11.319603917],
  [75.932095191, 11.319305767],
  [75.93083281, 11.318633343],
  [75.931188053, 11.318068761],
  [75.932209376, 11.318474752],
  [75.933414664, 11.318633343],
  [75.933522505, 11.317865765],
  [75.933505469, 11.317286451],
  [75.933920976, 11.316569622],
  [75.933505469, 11.316325393],
  [75.933473751, 11.31616363],
  [75.933578421, 11.316011383],
  [75.933879743, 11.315767154],
  [75.933270755, 11.315101074],
  [75.932509521, 11.31486636],
];

export interface StopPoint {
  name: string;
  lat: number;
  lon: number;
}

const ROUTE_R1_STOPS: StopPoint[] = [
  { name: "Mega Hostel Boys", lat: 11.317167, lon: 75.937750 },
  { name: "ATM Circle", lat: 11.321187, lon: 75.934706 },
  { name: "Department Building", lat: 11.321778, lon: 75.935111 },
  { name: "Architecture", lat: 11.323028, lon: 75.936722 },
  { name: "East Campus", lat: 11.323361, lon: 75.937194 },
];

const ROUTE_R2_STOPS: StopPoint[] = [
  { name: "SOMS", lat: 11.314866, lon: 75.932510 },
  { name: "Ladies Hostel", lat: 11.318306, lon: 75.931000 },
  { name: "Main Gate", lat: 11.320083, lon: 75.932722 },
  { name: "Center Circle", lat: 11.321333, lon: 75.934083 },
  { name: "ATM Circle", lat: 11.321187, lon: 75.934706 },
  { name: "Department Building", lat: 11.321778, lon: 75.935111 },
  { name: "Architecture", lat: 11.323028, lon: 75.936722 },
  { name: "East Campus", lat: 11.323361, lon: 75.937194 },
];

const DEG_TO_RAD = Math.PI / 180;
const EARTH_RADIUS_M = 6371000;

export function distanceMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const dLat = (lat2 - lat1) * DEG_TO_RAD;
  const dLon = (lon2 - lon1) * DEG_TO_RAD;
  const meanLat = ((lat1 + lat2) / 2) * DEG_TO_RAD;
  const x = dLon * Math.cos(meanLat);
  const y = dLat;
  return Math.sqrt(x * x + y * y) * EARTH_RADIUS_M;
}

export function bearingDegrees(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const phi1 = lat1 * DEG_TO_RAD;
  const phi2 = lat2 * DEG_TO_RAD;
  const deltaLambda = (lon2 - lon1) * DEG_TO_RAD;
  const y = Math.sin(deltaLambda) * Math.cos(phi2);
  const x = Math.cos(phi1) * Math.sin(phi2) - Math.sin(phi1) * Math.cos(phi2) * Math.cos(deltaLambda);
  const theta = Math.atan2(y, x);
  return (theta * (180 / Math.PI) + 360) % 360;
}

export interface SegmentInfo {
  startIdx: number;
  lat1: number;
  lon1: number;
  lat2: number;
  lon2: number;
  lengthMeters: number;
  cumulativeStartMeters: number;
  bearing: number;
}

export interface RouteModel {
  code: string;
  id: string;
  name: string;
  coords: [number, number][];
  stops: StopPoint[];
  segments: SegmentInfo[];
  totalMeters: number;
}

function buildRouteModel(code: string, id: string, name: string, coords: [number, number][], stops: StopPoint[]): RouteModel {
  const segments: SegmentInfo[] = [];
  let totalMeters = 0;

  for (let i = 0; i < coords.length - 1; i++) {
    const [lon1, lat1] = coords[i];
    const [lon2, lat2] = coords[i + 1];
    const len = distanceMeters(lat1, lon1, lat2, lon2);
    const brg = bearingDegrees(lat1, lon1, lat2, lon2);
    segments.push({
      startIdx: i,
      lat1,
      lon1,
      lat2,
      lon2,
      lengthMeters: len,
      cumulativeStartMeters: totalMeters,
      bearing: brg,
    });
    totalMeters += len;
  }

  return { code, id, name, coords, stops, segments, totalMeters };
}

const ROUTE_CACHE: Record<string, RouteModel> = {
  R1: buildRouteModel("R1", "10000000-0000-4000-8000-000000000001", "East Campus - MBH", ROUTE_R1_COORDS, ROUTE_R1_STOPS),
  R2: buildRouteModel("R2", "20000000-0000-4000-8000-000000000002", "East Campus - SOMS", ROUTE_R2_COORDS, ROUTE_R2_STOPS),
};

/**
 * Direction- and Monotonicity-Aware Route Projection
 * Solves the out-and-back loop ambiguity where opposite-direction segments share identical road geometry.
 */
export function findProgressMeters(
  route: RouteModel,
  lat: number,
  lon: number,
  heading?: number | null,
  previousProgress?: number | null,
): number {
  let minScore = Infinity;
  let bestProgressMeters = 0;

  for (const seg of route.segments) {
    if (seg.lengthMeters <= 0.001) continue;

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

    let penalty = 0;

    // 1. Heading Alignment: Heavily penalize segments pointing in the opposite direction
    if (heading != null && !isNaN(heading)) {
      let diff = Math.abs(seg.bearing - heading) % 360;
      if (diff > 180) diff = 360 - diff;
      if (diff > 75) {
        penalty += 1500; // Strong penalty against opposing direction
      } else {
        penalty += diff * 0.2;
      }
    }

    // 2. Monotonic Forward Preference: Heavily penalize snapping backwards across loop legs
    if (previousProgress != null && !isNaN(previousProgress)) {
      const segProgress = seg.cumulativeStartMeters + t * seg.lengthMeters;
      const backwardJump = (previousProgress - segProgress + route.totalMeters) % route.totalMeters;
      if (backwardJump > 80 && backwardJump < route.totalMeters - 150) {
        penalty += 2000;
      }
    }

    const score = dist + penalty;
    if (score < minScore) {
      minScore = score;
      bestProgressMeters = seg.cumulativeStartMeters + t * seg.lengthMeters;
    }
  }

  return bestProgressMeters;
}

export function interpolatePosition(route: RouteModel, progressMeters: number): { lat: number; lon: number; heading: number } {
  const normProgress = ((progressMeters % route.totalMeters) + route.totalMeters) % route.totalMeters;

  for (let i = 0; i < route.segments.length; i++) {
    const seg = route.segments[i];
    const segEnd = seg.cumulativeStartMeters + seg.lengthMeters;

    if (normProgress <= segEnd || i === route.segments.length - 1) {
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
    lat: Math.round(route.segments[0].lat1 * 1e6) / 1e6,
    lon: Math.round(route.segments[0].lon1 * 1e6) / 1e6,
    heading: Math.round(route.segments[0].bearing * 10) / 10,
  };
}

export function calculateKinematics(
  route: RouteModel,
  lat: number,
  lon: number,
  nominalSpeedKmh: number,
): { speedKmh: number; status: string; accuracyM: number; nearestStop: { name: string; distM: number } } {
  let minStopDist = Infinity;
  let nearestStopName = "";

  for (const stop of route.stops) {
    const dist = distanceMeters(lat, lon, stop.lat, stop.lon);
    if (dist < minStopDist) {
      minStopDist = dist;
      nearestStopName = stop.name;
    }
  }

  let speedKmh = nominalSpeedKmh;
  if (minStopDist < 18) {
    // Stop dwell / passenger exchange
    speedKmh = 0.0;
  } else if (minStopDist < 35) {
    // Deceleration when approaching stop
    speedKmh = Math.max(3.0, nominalSpeedKmh * 0.25);
  } else if (minStopDist < 65) {
    // Acceleration when departing stop
    speedKmh = Math.max(8.0, nominalSpeedKmh * 0.55);
  }

  // Realistic GPS accuracy HDOP variance: 3.2m - 5.8m
  const accuracyM = Math.round((3.2 + Math.random() * 2.6) * 10) / 10;
  const status = speedKmh >= 3.0 ? "moving" : "stationary";

  return {
    speedKmh: Math.round(speedKmh * 10) / 10,
    status,
    accuracyM,
    nearestStop: { name: nearestStopName, distM: Math.round(minStopDist) },
  };
}

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

// ============================================================================
// SIMULATOR CORE LOGIC
// ============================================================================

export interface SimulationParams {
  mode: "simulate" | "batch" | "fleet" | "test" | "loop";
  route: "R1" | "R2" | string;
  fault: string | null;
  deviceId: string;
  secret: string;
  busNumber: string;
  apiUrl: string;
  pointCount: number;
  intervalSec: number;
  nominalSpeedKmh: number;
  autoTrip: boolean;
  fullLoop?: boolean;
}

export async function authenticateOrResetTracker(
  apiUrl: string,
  deviceId: string,
  secret: string,
  forceReboot = false,
  curSeq = 0,
  curEpoch = 1,
): Promise<{ token: string; epoch: number; nextSeq: number }> {
  let nextSeq = curSeq > 0 ? curSeq + 1 : 1;
  let epoch = curEpoch;

  if (curSeq === 0 || forceReboot) {
    const sessionId = `sim-boot-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;
    const resetRes = await fetch(`${apiUrl}/api/v1/auth/reset-session`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        device_id: deviceId,
        secret,
        session_id: sessionId,
        reason: forceReboot ? "simulator_fault_reboot" : "simulator_cold_boot",
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

  return { token, epoch, nextSeq };
}

// In-memory cache structures to eliminate redundant PostgREST calls across simulator runs
const PROVISIONED_DEVICES = new Set<string>();
const BUS_ID_CACHE = new Map<string, string>();
const ACTIVE_TRIP_CACHE = new Map<string, { tripId: string; busId: string; routeId: string; cachedAt: number }>();

// Ensure active trip exists for bus & route so stop arrival/departure events trigger
async function ensureActiveTrip(
  supabase: SupabaseClient<any, any, any>,
  busNumber: string,
  routeId: string,
): Promise<{ tripId: string | null; busId: string | null }> {
  try {
    const cachedTrip = ACTIVE_TRIP_CACHE.get(busNumber);
    // Reuse active trip if cached within the last 15 minutes for the same route
    if (cachedTrip && cachedTrip.routeId === routeId && Date.now() - cachedTrip.cachedAt < 15 * 60 * 1000) {
      return { tripId: cachedTrip.tripId, busId: cachedTrip.busId };
    }

    let busId = BUS_ID_CACHE.get(busNumber);
    if (!busId) {
      const { data: bus } = await supabase.from("buses").select("id").eq("bus_number", busNumber).maybeSingle();
      if (!bus?.id) return { tripId: null, busId: null };
      busId = bus.id;
      BUS_ID_CACHE.set(busNumber, busId);
    }

    const { data: existingTrip } = await supabase
      .from("trips")
      .select("id, route_id")
      .eq("bus_id", busId)
      .eq("status", "active")
      .maybeSingle();

    if (existingTrip?.id) {
      ACTIVE_TRIP_CACHE.set(busNumber, {
        tripId: existingTrip.id,
        busId,
        routeId: existingTrip.route_id ?? routeId,
        cachedAt: Date.now(),
      });
      return { tripId: existingTrip.id, busId };
    }

    const { data: newTrip, error } = await supabase
      .from("trips")
      .insert({
        bus_id: busId,
        route_id: routeId,
        status: "active",
        started_at: new Date().toISOString(),
      })
      .select("id")
      .single();

    if (error) {
      console.warn("Could not auto-create trip:", error.message);
      return { tripId: null, busId };
    }

    if (newTrip?.id) {
      ACTIVE_TRIP_CACHE.set(busNumber, {
        tripId: newTrip.id,
        busId,
        routeId,
        cachedAt: Date.now(),
      });
    }

    return { tripId: newTrip?.id ?? null, busId };
  } catch (e) {
    console.warn("ensureActiveTrip exception:", e);
    return { tripId: null, busId: null };
  }
}

// ----------------------------------------------------------------------------
// HANDLER: Simulate ENTIRE Bus Loop (Full Circuit from Start to Finish)
// ----------------------------------------------------------------------------
async function handleLoopMode(
  supabase: SupabaseClient<any, any, any>,
  params: SimulationParams,
  startTime: number,
): Promise<Response> {
  const route = ROUTE_CACHE[params.route.toUpperCase()] || ROUTE_CACHE.R1;

  // 1. Ensure active trip exists so stop events trigger
  await ensureActiveTrip(supabase, params.busNumber, route.id);

  // 2. Fetch current state and authenticate device
  const { data: curState } = await supabase
    .from("bus_current_state")
    .select("seq, epoch, latitude, longitude, heading, bus_id")
    .eq("device_id", params.deviceId)
    .maybeSingle();

  const { data: devRecord } = await supabase
    .from("devices")
    .select("current_epoch")
    .eq("device_id", params.deviceId)
    .maybeSingle();

  const activeEpoch = curState?.epoch ?? devRecord?.current_epoch ?? 1;

  const { token, epoch, nextSeq } = await authenticateOrResetTracker(
    params.apiUrl,
    params.deviceId,
    params.secret,
    false,
    curState?.seq ?? 0,
    activeEpoch,
  );

  // 3. Generate fixes covering the 100% full route loop
  // Typically 55-60 fixes spaced by ~45m covering totalRouteMeters
  const loopStepMeters = 45;
  const totalSteps = Math.ceil(route.totalMeters / loopStepMeters);
  const packets: Array<Record<string, unknown>> = [];
  const now = Date.now();
  const timeStepSec = 3.5; // Realistic spacing for ~45m distance

  let progress = 0;
  for (let i = 0; i < totalSteps; i++) {
    const pos = interpolatePosition(route, progress);
    const kinematics = calculateKinematics(route, pos.lat, pos.lon, params.nominalSpeedKmh);

    // Stagger timestamps backwards from now so sequence is strictly monotonic
    const offsetSec = (totalSteps - 1 - i) * timeStepSec;
    const pktTimestamp = new Date(now - offsetSec * 1000).toISOString();

    packets.push({
      device_id: params.deviceId,
      seq: nextSeq + i,
      epoch,
      timestamp: pktTimestamp,
      latitude: pos.lat,
      longitude: pos.lon,
      speed: kinematics.speedKmh,
      heading: pos.heading,
      accuracy: kinematics.accuracyM,
    });

    progress = (progress + loopStepMeters) % route.totalMeters;
  }

  // Ensure final point closes the loop exactly at origin
  const endPos = interpolatePosition(route, 0);
  packets.push({
    device_id: params.deviceId,
    seq: nextSeq + totalSteps,
    epoch,
    timestamp: new Date(now).toISOString(),
    latitude: endPos.lat,
    longitude: endPos.lon,
    speed: 0.0,
    heading: endPos.heading,
    accuracy: 3.6,
  });

  // Transmit packets in batches of 25 (Fastify batch max or friendly chunking)
  const batchSize = 25;
  const batchResults: Array<Record<string, unknown>> = [];
  let totalAccepted = 0;
  let totalDuplicates = 0;
  let totalRejected = 0;

  for (let b = 0; b < packets.length; b += batchSize) {
    const chunk = packets.slice(b, b + batchSize);
    const batchRes = await fetch(`${params.apiUrl}/api/v1/telemetry/batch`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        device_id: params.deviceId,
        packets: chunk,
      }),
    });

    const batchJson = await batchRes.json().catch(() => ({}));
    if (typeof batchJson.accepted === "number") totalAccepted += batchJson.accepted;
    if (typeof batchJson.duplicates === "number") totalDuplicates += batchJson.duplicates;
    if (typeof batchJson.rejected === "number") totalRejected += batchJson.rejected;

    batchResults.push({
      batchIndex: Math.floor(b / batchSize) + 1,
      count: chunk.length,
      httpStatus: batchRes.status,
      response: batchJson,
    });
  }

  // 4. Query events generated during this full loop
  const busId = (curState as any)?.bus_id;
  let loopEvents: any[] = [];
  if (busId) {
    const { data: events } = await supabase
      .from("bus_events")
      .select("event_type, stop_id, occurred_at, metadata")
      .eq("bus_id", busId)
      .order("occurred_at", { ascending: false })
      .limit(20);
    loopEvents = events ?? [];
  }

  const durationMs = Date.now() - startTime;
  return new Response(
    JSON.stringify(
      {
        ok: totalRejected === 0,
        mode: "loop",
        route: route.code,
        routeName: route.name,
        totalRouteMeters: Math.round(route.totalMeters),
        loopCompleted: true,
        fixesGenerated: packets.length,
        totalAccepted,
        totalDuplicates,
        totalRejected,
        startProgressMeters: 0,
        endProgressMeters: Math.round(route.totalMeters),
        batches: batchResults,
        recentEvents: loopEvents,
        durationMs,
      },
      null,
      2,
    ),
    { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
  );
}

// ----------------------------------------------------------------------------
// HANDLER: Continuous Single Bus Telemetry Simulation
// ----------------------------------------------------------------------------
async function handleSimulateMode(
  supabase: SupabaseClient<any, any, any>,
  params: SimulationParams,
  startTime: number,
): Promise<Response> {
  const route = ROUTE_CACHE[params.route.toUpperCase()] || ROUTE_CACHE.R1;

  if (params.autoTrip) {
    await ensureActiveTrip(supabase, params.busNumber, route.id);
  }

  // 1. Fetch current canonical state
  const { data: curState } = await supabase
    .from("bus_current_state")
    .select("seq, epoch, latitude, longitude, speed, heading, status, recorded_at")
    .eq("device_id", params.deviceId)
    .maybeSingle();

  const { data: devRecord } = await supabase
    .from("devices")
    .select("current_epoch")
    .eq("device_id", params.deviceId)
    .maybeSingle();

  const activeEpoch = curState?.epoch ?? devRecord?.current_epoch ?? 1;

  const isRebootFault = params.fault === "reboot";
  const { token, epoch, nextSeq } = await authenticateOrResetTracker(
    params.apiUrl,
    params.deviceId,
    params.secret,
    isRebootFault,
    curState?.seq ?? 0,
    activeEpoch,
  );

  // 2. Determine starting route progress using heading & monotonicity awareness
  let currentProgressMeters: number;
  if (!curState?.latitude || !curState?.longitude) {
    currentProgressMeters = 0;
  } else {
    currentProgressMeters = findProgressMeters(
      route,
      Number(curState.latitude),
      Number(curState.longitude),
      curState.heading != null ? Number(curState.heading) : null,
    );
  }

  const stepDistanceMeters = (params.nominalSpeedKmh / 3.6) * params.intervalSec;
  const transmittedPackets: Array<Record<string, unknown>> = [];
  const eventsObserved: Array<Record<string, unknown>> = [];

  for (let i = 0; i < params.pointCount; i++) {
    if (i > 0 && params.intervalSec > 0) {
      await new Promise((resolve) => setTimeout(resolve, params.intervalSec * 1000));
    }

    currentProgressMeters = (currentProgressMeters + stepDistanceMeters) % route.totalMeters;
    const pos = interpolatePosition(route, currentProgressMeters);
    const kinematics = calculateKinematics(route, pos.lat, pos.lon, params.nominalSpeedKmh);

    let fixLat = pos.lat;
    let fixLon = pos.lon;
    let fixSeq = nextSeq + i;
    let fixEpoch = epoch;
    let fixSpeed = kinematics.speedKmh;
    let fixHeading = pos.heading;
    let fixAccuracy = kinematics.accuracyM;
    let fixTimestamp = new Date().toISOString();

    // ------------------------------------------------------------------------
    // Comprehensive Fault Injection Matrix
    // ------------------------------------------------------------------------
    if (params.fault === "gps_drift" && i === Math.floor(params.pointCount / 2)) {
      // Drift ~170m off route to trigger route_deviation event
      fixLat = Math.round((pos.lat + 0.0016) * 1e6) / 1e6;
    } else if (params.fault === "stale_sequence" && i === 1) {
      fixSeq = Math.max(0, nextSeq - 1);
    } else if (params.fault === "stale_epoch" && i === 1) {
      fixEpoch = Math.max(0, epoch - 1);
    } else if (params.fault === "future_epoch" && i === 1) {
      fixEpoch = epoch + 2;
    } else if (params.fault === "excessive_speed" && i === 1) {
      fixSpeed = 135.5;
    } else if (params.fault === "out_of_bounds" && i === 1) {
      fixLat = 12.854123;
      fixLon = 77.456123;
    } else if (params.fault === "stale_timestamp" && i === 1) {
      fixTimestamp = new Date(Date.now() - 20 * 60 * 1000).toISOString();
    } else if (params.fault === "dwell") {
      fixSpeed = 0.0;
      fixLat = Math.round((pos.lat + (Math.random() - 0.5) * 0.00001) * 1e6) / 1e6;
      fixLon = Math.round((pos.lon + (Math.random() - 0.5) * 0.00001) * 1e6) / 1e6;
    }

    const packet = {
      device_id: params.deviceId,
      seq: fixSeq,
      epoch: fixEpoch,
      timestamp: fixTimestamp,
      latitude: fixLat,
      longitude: fixLon,
      speed: fixSpeed,
      heading: fixHeading,
      accuracy: fixAccuracy,
    };

    const telRes = await fetch(`${params.apiUrl}/api/v1/telemetry`, {
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
      epoch: fixEpoch,
      latitude: fixLat,
      longitude: fixLon,
      speed: fixSpeed,
      heading: fixHeading,
      accuracy: fixAccuracy,
      status: kinematics.status,
      nearestStop: kinematics.nearestStop,
      httpStatus: telRes.status,
      apiResponse: telJson,
    });

    // Special Fault: Duplicate packet retry
    if (params.fault === "duplicate" && i === 1) {
      const dupRes = await fetch(`${params.apiUrl}/api/v1/telemetry`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
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
    if (params.fault === "conflict" && i === 1) {
      const confPacket = {
        ...packet,
        speed: 48.0,
        heading: (fixHeading + 90) % 360,
      };
      const confRes = await fetch(`${params.apiUrl}/api/v1/telemetry`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
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
        route: route.code,
        routeName: route.name,
        deviceId: params.deviceId,
        busNumber: params.busNumber,
        epoch,
        resumedFrom: {
          previousSeq: curState?.seq ?? 0,
          startProgressMeters: Math.round(currentProgressMeters),
          totalRouteMeters: Math.round(route.totalMeters),
        },
        packetsEmitted: transmittedPackets.length,
        faultInjected: params.fault,
        eventsObserved,
        packets: transmittedPackets,
        durationMs,
      },
      null,
      2,
    ),
    { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
  );
}

// ----------------------------------------------------------------------------
// HANDLER: Batch Offline Flush Simulation (POST /api/v1/telemetry/batch)
// ----------------------------------------------------------------------------
async function handleBatchMode(
  supabase: SupabaseClient<any, any, any>,
  params: SimulationParams,
  startTime: number,
): Promise<Response> {
  const route = ROUTE_CACHE[params.route.toUpperCase()] || ROUTE_CACHE.R1;

  if (params.autoTrip) {
    await ensureActiveTrip(supabase, params.busNumber, route.id);
  }

  const { data: curState } = await supabase
    .from("bus_current_state")
    .select("seq, epoch, latitude, longitude, heading")
    .eq("device_id", params.deviceId)
    .maybeSingle();

  const { data: devRecord } = await supabase
    .from("devices")
    .select("current_epoch")
    .eq("device_id", params.deviceId)
    .maybeSingle();

  const activeEpoch = curState?.epoch ?? devRecord?.current_epoch ?? 1;

  const { token, epoch, nextSeq } = await authenticateOrResetTracker(
    params.apiUrl,
    params.deviceId,
    params.secret,
    false,
    curState?.seq ?? 0,
    activeEpoch,
  );

  let currentProgressMeters = (!curState?.latitude || !curState?.longitude)
    ? 0
    : findProgressMeters(
        route,
        Number(curState.latitude),
        Number(curState.longitude),
        curState.heading != null ? Number(curState.heading) : null,
      );

  const stepDistanceMeters = (params.nominalSpeedKmh / 3.6) * params.intervalSec;
  const packets: Array<Record<string, unknown>> = [];
  const nowMs = Date.now();

  for (let i = 0; i < params.pointCount; i++) {
    currentProgressMeters = (currentProgressMeters + stepDistanceMeters) % route.totalMeters;
    const pos = interpolatePosition(route, currentProgressMeters);
    const kinematics = calculateKinematics(route, pos.lat, pos.lon, params.nominalSpeedKmh);

    // Stagger timestamps backwards from now so offline packet sequence is strictly monotonic
    const offsetSec = (params.pointCount - 1 - i) * params.intervalSec;
    const pktTimestamp = new Date(nowMs - offsetSec * 1000).toISOString();

    packets.push({
      device_id: params.deviceId,
      seq: nextSeq + i,
      epoch,
      timestamp: pktTimestamp,
      latitude: pos.lat,
      longitude: pos.lon,
      speed: kinematics.speedKmh,
      heading: pos.heading,
      accuracy: kinematics.accuracyM,
    });
  }

  // Transmit batch payload to /api/v1/telemetry/batch
  const batchRes = await fetch(`${params.apiUrl}/api/v1/telemetry/batch`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      device_id: params.deviceId,
      packets,
    }),
  });

  const batchJson = await batchRes.json().catch(() => ({}));
  const durationMs = Date.now() - startTime;

  return new Response(
    JSON.stringify(
      {
        ok: batchRes.status === 200 && batchJson.ok === true,
        mode: "batch",
        route: route.code,
        deviceId: params.deviceId,
        busNumber: params.busNumber,
        epoch,
        batchSize: packets.length,
        httpStatus: batchRes.status,
        apiResponse: batchJson,
        durationMs,
      },
      null,
      2,
    ),
    { status: batchRes.status, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
  );
}

// ----------------------------------------------------------------------------
// HANDLER: Multi-Bus Fleet Simulation (Concurrent fleet telemetry)
// ----------------------------------------------------------------------------
interface FleetBusSpec {
  busNumber: string;
  deviceId: string;
  secret: string;
  route: "R1" | "R2";
  speedKmh: number;
}

const DEFAULT_FLEET: FleetBusSpec[] = [
  { busNumber: "Bus 1", deviceId: "NITC-SIM-001", secret: "SimDeviceSecret123456!", route: "R1", speedKmh: 20 },
  { busNumber: "Bus 2", deviceId: "NITC-SIM-002", secret: "SimDeviceSecret223456!", route: "R2", speedKmh: 18 },
];

async function handleFleetMode(
  supabase: SupabaseClient<any, any, any>,
  params: SimulationParams,
  startTime: number,
): Promise<Response> {
  const fleetResults: Array<Record<string, unknown>> = [];

  // Register / Provision fleet devices if not already provisioned in current runtime isolate
  for (const bus of DEFAULT_FLEET) {
    if (!PROVISIONED_DEVICES.has(bus.deviceId)) {
      await (supabase.rpc as any)("register_tracking_device", {
        p_device_id: bus.deviceId,
        p_bus_number: bus.busNumber,
        p_secret: bus.secret,
        p_allow_reassign: true,
      });
      PROVISIONED_DEVICES.add(bus.deviceId);
    }
  }

  // Run simulation in parallel for each bus in fleet
  const tasks = DEFAULT_FLEET.map(async (busSpec) => {
    const busParams: SimulationParams = {
      ...params,
      busNumber: busSpec.busNumber,
      deviceId: busSpec.deviceId,
      secret: busSpec.secret,
      route: busSpec.route,
      nominalSpeedKmh: busSpec.speedKmh,
      pointCount: Math.min(params.pointCount, 5),
    };

    const simRes = await handleSimulateMode(supabase, busParams, Date.now());
    const simJson = await simRes.json();
    return {
      bus: busSpec.busNumber,
      device: busSpec.deviceId,
      route: busSpec.route,
      success: simRes.status === 200,
      details: simJson,
    };
  });

  const settled = await Promise.all(tasks);
  fleetResults.push(...settled);

  const durationMs = Date.now() - startTime;
  return new Response(
    JSON.stringify(
      {
        ok: fleetResults.every((r) => r.success),
        mode: "fleet",
        fleetSize: DEFAULT_FLEET.length,
        durationMs,
        fleet: fleetResults,
      },
      null,
      2,
    ),
    { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
  );
}

// ----------------------------------------------------------------------------
// HANDLER: Comprehensive Integration Test Suite ("test")
// ----------------------------------------------------------------------------
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
  supabase: SupabaseClient<any, any, any>,
  apiUrl: string,
  deviceId: string,
  secret: string,
  busNumber: string,
  startTime: number,
): Promise<Response> {
  const results: StepResult[] = [];

  try {
    // Step 0: Ensure device is registered in Supabase
    const t0 = Date.now();
    const { data: regData, error: regError } = await (supabase.rpc as any)("register_tracking_device", {
      p_device_id: deviceId,
      p_bus_number: busNumber,
      p_secret: secret,
      p_allow_reassign: true,
    });

    results.push({
      step: "0_provision",
      name: "Device Provisioning / Verification",
      success: !regError && (regData as any)?.ok === true,
      status: regError ? 500 : 200,
      durationMs: Date.now() - t0,
      details: { rpcResult: regData, error: regError?.message },
    });

    // Step 1: Reset Session (Cold boot)
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

    // Step 2: Idempotent Retry of Reset Session
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

    // Step 3: Authenticate and obtain JWT
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

    if (!token) throw new Error("Cannot proceed without device JWT token");

    // Fetch current position to smoothly advance along Route R1 without speed jumps
    const { data: curStateBefore } = await supabase
      .from("bus_current_state")
      .select("latitude, longitude, heading")
      .eq("device_id", deviceId)
      .maybeSingle();

    const testRoute = ROUTE_CACHE.R1;
    let testProgress = (!curStateBefore?.latitude || !curStateBefore?.longitude)
      ? 0
      : findProgressMeters(
          testRoute,
          Number(curStateBefore.latitude),
          Number(curStateBefore.longitude),
          curStateBefore.heading != null ? Number(curStateBefore.heading) : null,
        );

    // Step 4: Ingest Telemetry Fix Seq 1 (Smooth Route Progression)
    testProgress = (testProgress + 12) % testRoute.totalMeters;
    const pos1 = interpolatePosition(testRoute, testProgress);
    const t4 = Date.now();
    const packet1 = {
      device_id: deviceId,
      seq: 1,
      epoch,
      timestamp: new Date().toISOString(),
      latitude: pos1.lat,
      longitude: pos1.lon,
      speed: 18.0,
      heading: pos1.heading,
      accuracy: 4.0,
    };
    const tel1Res = await fetch(`${apiUrl}/api/v1/telemetry`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
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

    // Step 5: Exact Duplicate Retry (Seq 1)
    const t5 = Date.now();
    const dupRes = await fetch(`${apiUrl}/api/v1/telemetry`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify(packet1),
    });
    const dupJson = await dupRes.json();

    results.push({
      step: "5_duplicate_retry",
      name: "Exact Duplicate Retry Idempotency",
      success: dupRes.status === 200 && dupJson.stored === false && dupJson.reason === "duplicate",
      status: dupRes.status,
      durationMs: Date.now() - t5,
      details: { response: dupJson },
    });

    // Step 6: Monotonic Advancing Fix Seq 2
    const t6 = Date.now();
    await new Promise((r) => setTimeout(r, 2000));
    testProgress = (testProgress + 12) % testRoute.totalMeters;
    const pos2 = interpolatePosition(testRoute, testProgress);
    const packet2 = {
      device_id: deviceId,
      seq: 2,
      epoch,
      timestamp: new Date().toISOString(),
      latitude: pos2.lat,
      longitude: pos2.lon,
      speed: 20.0,
      heading: pos2.heading,
      accuracy: 4.0,
    };
    const tel2Res = await fetch(`${apiUrl}/api/v1/telemetry`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
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

    // Step 7: Conflicting Sequence Reuse Rejection
    const t7 = Date.now();
    const packet2Conflict = {
      ...packet2,
      speed: 35.0,
      heading: (pos2.heading + 90) % 360,
    };
    const confRes = await fetch(`${apiUrl}/api/v1/telemetry`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify(packet2Conflict),
    });
    const confJson = await confRes.json();

    results.push({
      step: "7_sequence_reuse_conflict",
      name: "Conflicting Sequence Reuse Detection (409)",
      success: confRes.status === 409 && (confJson.code === "SEQUENCE_REUSE_CONFLICT" || confJson.error === "Conflict"),
      status: confRes.status,
      durationMs: Date.now() - t7,
      details: { response: confJson },
    });

    // Step 8: Offline Batch Flush Telemetry Test (POST /api/v1/telemetry/batch)
    const t8 = Date.now();
    testProgress = (testProgress + 12) % testRoute.totalMeters;
    const pos3 = interpolatePosition(testRoute, testProgress);
    testProgress = (testProgress + 12) % testRoute.totalMeters;
    const pos4 = interpolatePosition(testRoute, testProgress);

    const batchNow = Date.now();
    const batchPackets = [
      {
        device_id: deviceId,
        seq: 3,
        epoch,
        timestamp: new Date(batchNow + 1000).toISOString(),
        latitude: pos3.lat,
        longitude: pos3.lon,
        speed: 21.0,
        heading: pos3.heading,
        accuracy: 4.1,
      },
      {
        device_id: deviceId,
        seq: 4,
        epoch,
        timestamp: new Date(batchNow + 2000).toISOString(),
        latitude: pos4.lat,
        longitude: pos4.lon,
        speed: 22.5,
        heading: pos4.heading,
        accuracy: 3.9,
      },
    ];

    const batchRes = await fetch(`${apiUrl}/api/v1/telemetry/batch`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify({ device_id: deviceId, packets: batchPackets }),
    });
    const batchJson = await batchRes.json();

    results.push({
      step: "8_batch_ingestion",
      name: "Offline Batch Buffer Flush (/telemetry/batch)",
      success: batchRes.status === 200 && batchJson.ok === true && batchJson.accepted === 2,
      status: batchRes.status,
      durationMs: Date.now() - t8,
      details: { response: batchJson },
    });

    // Step 9: Excessive Speed Invariant Test (> 120 km/h rejection)
    const t9 = Date.now();
    const badSpeedPacket = {
      device_id: deviceId,
      seq: 5,
      epoch,
      timestamp: new Date().toISOString(),
      latitude: 11.318821,
      longitude: 75.936663,
      speed: 135.0,
      heading: 60.0,
      accuracy: 4.0,
    };
    const speedRes = await fetch(`${apiUrl}/api/v1/telemetry`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify(badSpeedPacket),
    });
    const speedJson = await speedRes.json();

    results.push({
      step: "9_speed_invariant",
      name: "Excessive Speed Invariant (>120 km/h) Rejection",
      success:
        (speedRes.status === 422 || speedRes.status === 400) &&
        (speedJson.code === "speed_out_of_range" ||
          speedJson.code === "INVALID_SPEED" ||
          speedJson.message?.toLowerCase().includes("speed")),
      status: speedRes.status,
      durationMs: Date.now() - t9,
      details: { response: speedJson },
    });

    // Step 10: Database Canonical State Verification
    const t10 = Date.now();
    const { data: dbState, error: stateErr } = await supabase
      .from("bus_current_state")
      .select("device_id, seq, epoch, speed, heading, updated_at")
      .eq("device_id", deviceId)
      .maybeSingle();

    const { count: posCount, error: countErr } = await supabase
      .from("bus_positions")
      .select("*", { count: "exact", head: true })
      .eq("device_id", deviceId);

    const dbSuccess = !stateErr && !countErr && (dbState as any)?.seq === 4 && (dbState as any)?.epoch === epoch && (posCount ?? 0) >= 4;

    results.push({
      step: "10_database_verification",
      name: "Supabase Database Canonical State Verification",
      success: dbSuccess,
      status: dbSuccess ? 200 : 500,
      durationMs: Date.now() - t10,
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
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }
}

// ============================================================================
// MAIN ENTRY POINT (HTTP Edge Function & CLI Runnable)
// ============================================================================

export async function processSimulatorRequest(req: Request): Promise<Response> {
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

    const mode = ((body.mode as string) || url.searchParams.get("mode") || "simulate") as SimulationParams["mode"];
    const route = (body.route as string) || url.searchParams.get("route") || "R1";
    const fault = (body.fault as string) || url.searchParams.get("fault") || null;
    const deviceId = (body.deviceId as string) || url.searchParams.get("deviceId") || "NITC-SIM-001";
    const secret = (body.secret as string) || url.searchParams.get("secret") || "SimDeviceSecret123456!";
    const busNumber = (body.busNumber as string) || url.searchParams.get("busNumber") || "Bus 1";
    const apiUrl =
      (body.apiUrl as string) ||
      url.searchParams.get("apiUrl") ||
      Deno.env.get("RENDER_API_URL") ||
      "https://bus-telemetry-api.onrender.com";

    const pointCount = Math.min(60, Math.max(1, Number(body.points || url.searchParams.get("points") || 6)));
    const intervalSec = Math.min(10, Math.max(0, Number(body.interval || url.searchParams.get("interval") || 2.0)));
    const nominalSpeedKmh = Math.min(50, Math.max(5, Number(body.speed || url.searchParams.get("speed") || 22)));
    const autoTrip = body.autoTrip === true || url.searchParams.get("autoTrip") === "true";
    const fullLoop = body.fullLoop === true || url.searchParams.get("fullLoop") === "true";

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const params: SimulationParams = {
      mode,
      route,
      fault,
      deviceId,
      secret,
      busNumber,
      apiUrl,
      pointCount,
      intervalSec,
      nominalSpeedKmh,
      autoTrip,
      fullLoop,
    };

    if (mode === "loop" || fullLoop) {
      return await handleLoopMode(supabase, params, startTime);
    }

    switch (mode) {
      case "test":
        return await runIntegrationTestSuite(supabase, apiUrl, deviceId, secret, busNumber, startTime);
      case "batch":
        return await handleBatchMode(supabase, params, startTime);
      case "fleet":
        return await handleFleetMode(supabase, params, startTime);
      case "simulate":
      default:
        return await handleSimulateMode(supabase, params, startTime);
    }
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ ok: false, error: errorMsg, durationMs: Date.now() - startTime }, null, 2),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }
}

// Start Deno HTTP server if served as an Edge Function
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  return await processSimulatorRequest(req);
});
