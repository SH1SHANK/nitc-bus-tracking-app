package `in`.ac.nitc.tracklet.widget

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Persisted state and configuration store for the Nearest Bus native App Widget.
 */
object WidgetPreferences {
    private const val PREFS_NAME = "nitc_bus_widget_prefs"

    // Stop keys
    private const val KEY_PINNED_STOP_ID = "pinned_stop_id"
    private const val KEY_PINNED_STOP_NAME = "pinned_stop_name"
    private const val KEY_LAST_KNOWN_STOP_ID = "last_known_stop_id"
    private const val KEY_LAST_KNOWN_STOP_NAME = "last_known_stop_name"
    private const val KEY_LAST_KNOWN_STOP_LAT = "last_known_stop_lat"
    private const val KEY_LAST_KNOWN_STOP_LNG = "last_known_stop_lng"

    // User location cache
    private const val KEY_LAST_USER_LAT = "last_user_lat"
    private const val KEY_LAST_USER_LNG = "last_user_lng"

    // Widget content cache
    private const val KEY_DISPLAY_STOP_NAME = "display_stop_name"
    private const val KEY_DISPLAY_BUS_NAME = "display_bus_name"
    private const val KEY_DISPLAY_DISTANCE_METERS = "display_distance_meters"
    private const val KEY_DISPLAY_STOP_DISTANCE_METERS = "display_stop_distance_meters"
    private const val KEY_DISPLAY_TELEMETRY_EPOCH_MS = "display_telemetry_epoch_ms"
    private const val KEY_DISPLAY_IS_STALE = "display_is_stale"
    private const val KEY_DISPLAY_ERROR_MSG = "display_error_msg"
    private const val KEY_LAST_REFRESH_TIMESTAMP = "last_refresh_timestamp"

    // Reference data cache
    private const val KEY_CACHED_STOPS = "cached_stops_json"
    private const val KEY_CACHED_ROUTE_STOPS = "cached_route_stops_json"

    private fun prefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    // Pinned stop (Manual override)
    fun getPinnedStop(context: Context): Pair<String, String>? {
        val id = prefs(context).getString(KEY_PINNED_STOP_ID, null) ?: return null
        val name = prefs(context).getString(KEY_PINNED_STOP_NAME, "Selected Stop") ?: "Selected Stop"
        return Pair(id, name)
    }

    fun setPinnedStop(context: Context, stopId: String?, stopName: String?) {
        prefs(context).edit().apply {
            if (stopId != null) {
                putString(KEY_PINNED_STOP_ID, stopId)
                putString(KEY_PINNED_STOP_NAME, stopName ?: "Selected Stop")
            } else {
                remove(KEY_PINNED_STOP_ID)
                remove(KEY_PINNED_STOP_NAME)
            }
            apply()
        }
    }

    // Last known nearest stop (Automatic selection)
    fun setLastKnownNearestStop(context: Context, id: String, name: String, lat: Double, lng: Double) {
        prefs(context).edit()
            .putString(KEY_LAST_KNOWN_STOP_ID, id)
            .putString(KEY_LAST_KNOWN_STOP_NAME, name)
            .putFloat(KEY_LAST_KNOWN_STOP_LAT, lat.toFloat())
            .putFloat(KEY_LAST_KNOWN_STOP_LNG, lng.toFloat())
            .apply()
    }

    fun getLastKnownNearestStop(context: Context): StopModel? {
        val p = prefs(context)
        val id = p.getString(KEY_LAST_KNOWN_STOP_ID, null) ?: return null
        val name = p.getString(KEY_LAST_KNOWN_STOP_NAME, "Campus Stop") ?: "Campus Stop"
        val lat = p.getFloat(KEY_LAST_KNOWN_STOP_LAT, 0f).toDouble()
        val lng = p.getFloat(KEY_LAST_KNOWN_STOP_LNG, 0f).toDouble()
        return StopModel(id, name, lat, lng)
    }

    // User location
    fun setUserLocation(context: Context, lat: Double, lng: Double) {
        prefs(context).edit()
            .putFloat(KEY_LAST_USER_LAT, lat.toFloat())
            .putFloat(KEY_LAST_USER_LNG, lng.toFloat())
            .apply()
    }

    fun getUserLocation(context: Context): Pair<Double, Double>? {
        val p = prefs(context)
        if (!p.contains(KEY_LAST_USER_LAT)) return null
        return Pair(
            p.getFloat(KEY_LAST_USER_LAT, 0f).toDouble(),
            p.getFloat(KEY_LAST_USER_LNG, 0f).toDouble()
        )
    }

    // Cached stops reference data
    fun saveStops(context: Context, stops: List<StopModel>) {
        val arr = JSONArray()
        stops.forEach { s ->
            arr.put(JSONObject().apply {
                put("id", s.id)
                put("name", s.name)
                put("latitude", s.latitude)
                put("longitude", s.longitude)
            })
        }
        prefs(context).edit().putString(KEY_CACHED_STOPS, arr.toString()).apply()
    }

    fun getStops(context: Context): List<StopModel> {
        val raw = prefs(context).getString(KEY_CACHED_STOPS, null) ?: return defaultStops
        return try {
            val arr = JSONArray(raw)
            val list = mutableListOf<StopModel>()
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                list.add(
                    StopModel(
                        id = obj.getString("id"),
                        name = obj.getString("name"),
                        latitude = obj.getDouble("latitude"),
                        longitude = obj.getDouble("longitude")
                    )
                )
            }
            if (list.isEmpty()) defaultStops else list
        } catch (_: Exception) {
            defaultStops
        }
    }

    // Cached route_stops reference data: routeId -> list of stopIds
    fun saveRouteStops(context: Context, map: Map<String, Set<String>>) {
        val obj = JSONObject()
        map.forEach { (routeId, stopIds) ->
            obj.put(routeId, JSONArray(stopIds))
        }
        prefs(context).edit().putString(KEY_CACHED_ROUTE_STOPS, obj.toString()).apply()
    }

    fun getRouteStops(context: Context): Map<String, Set<String>> {
        val raw = prefs(context).getString(KEY_CACHED_ROUTE_STOPS, null) ?: return defaultRouteStops
        return try {
            val obj = JSONObject(raw)
            val map = mutableMapOf<String, Set<String>>()
            val keys = obj.keys()
            while (keys.hasNext()) {
                val rId = keys.next()
                val arr = obj.getJSONArray(rId)
                val set = mutableSetOf<String>()
                for (i in 0 until arr.length()) {
                    set.add(arr.getString(i))
                }
                map[rId] = set
            }
            if (map.isEmpty()) defaultRouteStops else map
        } catch (_: Exception) {
            defaultRouteStops
        }
    }

    // Display state
    fun saveWidgetData(
        context: Context,
        stopName: String,
        busName: String?,
        distanceMeters: Double?,
        stopDistanceMeters: Double? = null,
        telemetryEpochMs: Long?,
        isStale: Boolean,
        errorMessage: String?
    ) {
        prefs(context).edit()
            .putString(KEY_DISPLAY_STOP_NAME, stopName)
            .putString(KEY_DISPLAY_BUS_NAME, busName)
            .putFloat(KEY_DISPLAY_DISTANCE_METERS, distanceMeters?.toFloat() ?: -1f)
            .putFloat(KEY_DISPLAY_STOP_DISTANCE_METERS, stopDistanceMeters?.toFloat() ?: -1f)
            .putLong(KEY_DISPLAY_TELEMETRY_EPOCH_MS, telemetryEpochMs ?: 0L)
            .putBoolean(KEY_DISPLAY_IS_STALE, isStale)
            .putString(KEY_DISPLAY_ERROR_MSG, errorMessage)
            .putLong(KEY_LAST_REFRESH_TIMESTAMP, System.currentTimeMillis())
            .apply()
    }

    fun getLastRefreshTimestamp(context: Context): Long {
        return prefs(context).getLong(KEY_LAST_REFRESH_TIMESTAMP, 0L)
    }

    fun getWidgetData(context: Context): WidgetDisplayData {
        val p = prefs(context)
        val dist = p.getFloat(KEY_DISPLAY_DISTANCE_METERS, -1f)
        return WidgetDisplayData(
            stopName = p.getString(KEY_DISPLAY_STOP_NAME, "Main Gate") ?: "Main Gate",
            busName = p.getString(KEY_DISPLAY_BUS_NAME, null),
            distanceMeters = if (dist >= 0) dist.toDouble() else null,
            stopDistanceMeters = p.getFloat(KEY_DISPLAY_STOP_DISTANCE_METERS, -1f)
                .takeIf { it >= 0f }
                ?.toDouble(),
            telemetryEpochMs = p.getLong(KEY_DISPLAY_TELEMETRY_EPOCH_MS, 0L),
            isStale = p.getBoolean(KEY_DISPLAY_IS_STALE, false),
            errorMessage = p.getString(KEY_DISPLAY_ERROR_MSG, null)
        )
    }

    // Default Fallback Stops (NITC verified campus locations from Supabase)
    val defaultStops = listOf(
        StopModel("444f8f96-e747-4382-a80f-a283539f0fec", "Main Gate", 11.320083, 75.932722),
        StopModel("769d9f50-ae83-4379-ac7a-195b842d08fc", "Mega Hostel Boys", 11.317167, 75.937750),
        StopModel("750511fb-1840-4212-ba3b-f1c57e9e0ecd", "Ladies Hostel", 11.318306, 75.931000),
        StopModel("5b43a090-eddc-44c1-ba6a-f8dcfddd2958", "Architecture", 11.323028, 75.936722),
        StopModel("7e1def8f-38a1-409e-941c-5dc88df24876", "ATM Circle", 11.321187, 75.934706),
        StopModel("9a4f0f36-3d40-41fd-bb82-fd67bc95a148", "Center Circle", 11.321333, 75.934083),
        StopModel("1db6c799-56e2-49c2-8e7b-1799fad1b0a6", "Department Building", 11.321778, 75.935111),
        StopModel("7e7ecda0-36b5-41ae-be2b-54c150c4d272", "East Campus", 11.323361, 75.937194),
        StopModel("20eaac1b-7134-422c-9185-04edfdd797fa", "Kattangal Bus Stop", 11.318491, 75.939896),
        StopModel("8a3d16d0-9e3f-4025-a59b-e1993f579f13", "SOMS", 11.314866, 75.932510),
        StopModel("891e0885-7fb9-4ac7-ac3e-ec50c198d976", "South Campus", 11.314861, 75.932639),
        StopModel("63658f42-7697-439c-9e45-64de2ca055ea", "Bus Depot", 11.321140, 75.934943)
    )

    // Default Fallback Route to Stop Mappings
    val defaultRouteStops = mapOf(
        "10000000-0000-4000-8000-000000000001" to setOf(
            "769d9f50-ae83-4379-ac7a-195b842d08fc",
            "7e1def8f-38a1-409e-941c-5dc88df24876",
            "1db6c799-56e2-49c2-8e7b-1799fad1b0a6",
            "5b43a090-eddc-44c1-ba6a-f8dcfddd2958",
            "7e7ecda0-36b5-41ae-be2b-54c150c4d272"
        ),
        "20000000-0000-4000-8000-000000000002" to setOf(
            "8a3d16d0-9e3f-4025-a59b-e1993f579f13",
            "750511fb-1840-4212-ba3b-f1c57e9e0ecd",
            "444f8f96-e747-4382-a80f-a283539f0fec",
            "9a4f0f36-3d40-41fd-bb82-fd67bc95a148",
            "7e1def8f-38a1-409e-941c-5dc88df24876",
            "1db6c799-56e2-49c2-8e7b-1799fad1b0a6",
            "5b43a090-eddc-44c1-ba6a-f8dcfddd2958",
            "7e7ecda0-36b5-41ae-be2b-54c150c4d272"
        ),
        "30000000-0000-4000-8000-000000000003" to setOf(
            "5b43a090-eddc-44c1-ba6a-f8dcfddd2958",
            "9a4f0f36-3d40-41fd-bb82-fd67bc95a148",
            "444f8f96-e747-4382-a80f-a283539f0fec",
            "750511fb-1840-4212-ba3b-f1c57e9e0ecd"
        ),
        "40000000-0000-4000-8000-000000000004" to setOf(
            "5b43a090-eddc-44c1-ba6a-f8dcfddd2958",
            "9a4f0f36-3d40-41fd-bb82-fd67bc95a148",
            "444f8f96-e747-4382-a80f-a283539f0fec",
            "769d9f50-ae83-4379-ac7a-195b842d08fc"
        )
    )
}

data class StopModel(
    val id: String,
    val name: String,
    val latitude: Double,
    val longitude: Double
)

data class WidgetDisplayData(
    val stopName: String,
    val busName: String?,
    val distanceMeters: Double?,
    val stopDistanceMeters: Double?,
    val telemetryEpochMs: Long,
    val isStale: Boolean,
    val errorMessage: String?
)
