package `in`.ac.nitc.tracklet.widget

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

data class ActiveBusModel(
    val busId: String,
    val busNumber: String,
    val displayName: String,
    val routeId: String?,
    val routeName: String?,
    val latitude: Double,
    val longitude: Double,
    val isStale: Boolean,
    val lastSeenEpochMs: Long
)

data class NearestBusResult(
    val monitoredStop: StopModel,
    val bus: ActiveBusModel?,
    val distanceMeters: Double?,
    val isStale: Boolean,
    val telemetryEpochMs: Long?,
    val errorMessage: String?
)

class WidgetDataRepository(private val context: Context) {

    private val supabaseUrl = "https://fnngudikrvelpuhngtlw.supabase.co"
    private val supabaseAnonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZubmd1ZGlrcnZlbHB1aG5ndGx3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE0Mjc0MDAsImV4cCI6MjEwNzAwMzQwMH0.K7L2ESSZjV3R7OCwcOy_WA8XNCivIrUqZGRMitRrMEc"

    /**
     * Resolves the target monitored stop:
     * 1. Manual pinned stop if selected by user
     * 2. Nearest stop to user's last known coordinates if available
     * 3. Fallback to default campus stop (Main Gate)
     */
    fun resolveMonitoredStop(): StopModel {
        val allStops = WidgetPreferences.getStops(context)

        // 1. Manual override check
        val pinned = WidgetPreferences.getPinnedStop(context)
        if (pinned != null) {
            val matching = allStops.find { it.id == pinned.first }
            if (matching != null) return matching
            return StopModel(pinned.first, pinned.second, 11.320083, 75.932722)
        }

        // 2. Automatic selection: check user location
        val userLocation = WidgetPreferences.getUserLocation(context)
        if (userLocation != null) {
            var nearestStop: StopModel? = null
            var minDistance = Double.MAX_VALUE
            for (stop in allStops) {
                val d = GeoUtils.distanceMeters(
                    userLocation.first,
                    userLocation.second,
                    stop.latitude,
                    stop.longitude
                )
                if (d < minDistance) {
                    minDistance = d
                    nearestStop = stop
                }
            }
            if (nearestStop != null) {
                WidgetPreferences.setLastKnownNearestStop(
                    context,
                    nearestStop.id,
                    nearestStop.name,
                    nearestStop.latitude,
                    nearestStop.longitude
                )
                return nearestStop
            }
        }

        // 3. Last known nearest stop if stored
        val lastKnown = WidgetPreferences.getLastKnownNearestStop(context)
        if (lastKnown != null) return lastKnown

        // 4. Fallback to Main Gate
        return allStops.firstOrNull { it.id == "444f8f96-e747-4382-a80f-a283539f0fec" }
            ?: allStops.first()
    }

    fun distanceToStop(stopName: String): Double? {
        val userLocation = WidgetPreferences.getUserLocation(context) ?: return null
        val stop = WidgetPreferences.getStops(context).firstOrNull {
            it.name.equals(stopName, ignoreCase = true)
        } ?: return null
        return GeoUtils.distanceMeters(
            userLocation.first,
            userLocation.second,
            stop.latitude,
            stop.longitude
        )
    }

    /**
     * Fetches active buses and computes the closest qualifying bus serving the monitored stop.
     */
    fun fetchNearestBusForStop(stop: StopModel): NearestBusResult {
        return try {
            val routeStops = WidgetPreferences.getRouteStops(context)
            val buses = fetchActiveBusesFromNetwork()

            if (buses.isEmpty()) {
                return NearestBusResult(
                    monitoredStop = stop,
                    bus = null,
                    distanceMeters = null,
                    isStale = false,
                    telemetryEpochMs = null,
                    errorMessage = "No active buses"
                )
            }

            // Filter for qualifying buses:
            // Must have valid route serving the monitored stop
            val qualifyingBuses = buses.filter { bus ->
                if (bus.routeId == null) return@filter false
                val servedStops = routeStops[bus.routeId] ?: emptySet()
                servedStops.contains(stop.id)
            }

            if (qualifyingBuses.isEmpty()) {
                return NearestBusResult(
                    monitoredStop = stop,
                    bus = null,
                    distanceMeters = null,
                    isStale = false,
                    telemetryEpochMs = null,
                    errorMessage = "No buses serving this stop"
                )
            }

            // Find the closest qualifying bus to the monitored stop
            var closestBus: ActiveBusModel? = null
            var minDistance = Double.MAX_VALUE

            for (bus in qualifyingBuses) {
                // Reject invalid coordinates
                if (bus.latitude == 0.0 && bus.longitude == 0.0) continue

                val distance = GeoUtils.distanceMeters(
                    bus.latitude,
                    bus.longitude,
                    stop.latitude,
                    stop.longitude
                )

                if (distance < minDistance) {
                    minDistance = distance
                    closestBus = bus
                }
            }

            if (closestBus == null) {
                return NearestBusResult(
                    monitoredStop = stop,
                    bus = null,
                    distanceMeters = null,
                    isStale = false,
                    telemetryEpochMs = null,
                    errorMessage = "Location unavailable"
                )
            }

            NearestBusResult(
                monitoredStop = stop,
                bus = closestBus,
                distanceMeters = minDistance,
                isStale = closestBus.isStale,
                telemetryEpochMs = closestBus.lastSeenEpochMs,
                errorMessage = null
            )
        } catch (e: Exception) {
            NearestBusResult(
                monitoredStop = stop,
                bus = null,
                distanceMeters = null,
                isStale = false,
                telemetryEpochMs = null,
                errorMessage = "Network unavailable"
            )
        }
    }

    /**
     * Executes the existing public RPC get_active_bus_positions_v2 using HTTP POST.
     */
    private fun fetchActiveBusesFromNetwork(): List<ActiveBusModel> {
        val url = URL("$supabaseUrl/rest/v1/rpc/get_active_bus_positions_v2")
        val conn = url.openConnection() as HttpURLConnection
        conn.requestMethod = "POST"
        conn.connectTimeout = 8000
        conn.readTimeout = 8000
        conn.setRequestProperty("User-Agent", "NITC-BusTracker-Widget/1.0")
        conn.setRequestProperty("apikey", supabaseAnonKey)
        conn.setRequestProperty("Authorization", "Bearer $supabaseAnonKey")
        conn.setRequestProperty("Content-Type", "application/json")
        conn.setRequestProperty("Accept", "application/json")
        conn.doOutput = true

        OutputStreamWriter(conn.outputStream).use { writer ->
            writer.write("{}")
            writer.flush()
        }

        if (conn.responseCode !in 200..299) {
            return emptyList()
        }

        val responseStr = BufferedReader(InputStreamReader(conn.inputStream)).use { it.readText() }
        val arr = JSONArray(responseStr)
        val list = mutableListOf<ActiveBusModel>()

        val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val isoFormatFallback = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }

        for (i in 0 until arr.length()) {
            val obj = arr.getJSONObject(i)
            val busId = obj.optString("bus_id", "")
            val busNum = obj.optString("bus_number", "")
            val displayName = obj.optString("display_name", busNum)
            val routeId = obj.optString("route_id", null.toString()).let { if (it == "null" || it.isBlank()) null else it }
            val routeName = obj.optString("route_name", null.toString()).let { if (it == "null" || it.isBlank()) null else it }
            val lat = obj.optDouble("latitude", 0.0)
            val lng = obj.optDouble("longitude", 0.0)
            val isStale = obj.optBoolean("is_stale", false)
            val lastSeenStr = obj.optString("last_seen", "")

            var epochMs = 0L
            if (lastSeenStr.isNotBlank()) {
                try {
                    epochMs = isoFormat.parse(lastSeenStr)?.time
                        ?: isoFormatFallback.parse(lastSeenStr)?.time
                        ?: 0L
                } catch (_: Exception) {
                    epochMs = System.currentTimeMillis()
                }
            }

            list.add(
                ActiveBusModel(
                    busId = busId,
                    busNumber = busNum,
                    displayName = displayName.ifBlank { busNum },
                    routeId = routeId,
                    routeName = routeName,
                    latitude = lat,
                    longitude = lng,
                    isStale = isStale,
                    lastSeenEpochMs = epochMs
                )
            )
        }

        return list
    }
}
