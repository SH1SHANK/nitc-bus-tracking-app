package `in`.ac.nitc.tracklet

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import `in`.ac.nitc.tracklet.widget.NearestBusWidgetProvider
import `in`.ac.nitc.tracklet.widget.StopModel
import `in`.ac.nitc.tracklet.widget.WidgetDataRepository
import `in`.ac.nitc.tracklet.widget.WidgetPreferences
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "in.ac.nitc.tracklet/widget"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgetData" -> {
                    try {
                        val stopName = call.argument<String>("stopName") ?: "Campus Stop"
                        val busName = call.argument<String>("busName")
                        val distanceMeters = call.argument<Double>("distanceMeters")
                        val telemetryEpochMs = call.argument<Long>("telemetryEpochMs") ?: System.currentTimeMillis()
                        val isStale = call.argument<Boolean>("isStale") ?: false
                        val errorMessage = call.argument<String>("errorMessage")
                        val stopDistanceMeters = WidgetDataRepository(applicationContext)
                            .distanceToStop(stopName)

                        WidgetPreferences.saveWidgetData(
                            context = applicationContext,
                            stopName = stopName,
                            busName = busName,
                            distanceMeters = distanceMeters,
                            stopDistanceMeters = stopDistanceMeters,
                            telemetryEpochMs = telemetryEpochMs,
                            isStale = isStale,
                            errorMessage = errorMessage
                        )

                        NearestBusWidgetProvider.updateAllWidgets(applicationContext)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UPDATE_ERROR", e.message, null)
                    }
                }
                "setPinnedStop" -> {
                    try {
                        val stopId = call.argument<String?>("stopId")
                        val stopName = call.argument<String?>("stopName")
                        WidgetPreferences.setPinnedStop(applicationContext, stopId, stopName)
                        NearestBusWidgetProvider.enqueueOneTimeRefresh(applicationContext)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("PIN_ERROR", e.message, null)
                    }
                }
                "setUserLocation" -> {
                    try {
                        val lat = call.argument<Double>("latitude")
                        val lng = call.argument<Double>("longitude")
                        if (lat != null && lng != null) {
                            WidgetPreferences.setUserLocation(applicationContext, lat, lng)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCATION_ERROR", e.message, null)
                    }
                }
                "syncReferenceData" -> {
                    try {
                        val stopsJson = call.argument<String>("stopsJson")
                        val routeStopsJson = call.argument<String>("routeStopsJson")

                        if (stopsJson != null) {
                            val arr = JSONArray(stopsJson)
                            val stopsList = mutableListOf<StopModel>()
                            for (i in 0 until arr.length()) {
                                val o = arr.getJSONObject(i)
                                stopsList.add(
                                    StopModel(
                                        id = o.getString("id"),
                                        name = o.getString("name"),
                                        latitude = o.getDouble("latitude"),
                                        longitude = o.getDouble("longitude")
                                    )
                                )
                            }
                            WidgetPreferences.saveStops(applicationContext, stopsList)
                        }

                        if (routeStopsJson != null) {
                            val obj = JSONObject(routeStopsJson)
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
                            WidgetPreferences.saveRouteStops(applicationContext, map)
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SYNC_ERROR", e.message, null)
                    }
                }
                "refreshWidget" -> {
                    NearestBusWidgetProvider.enqueueOneTimeRefresh(applicationContext)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
