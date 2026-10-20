package `in`.ac.nitc.tracklet.widget

import kotlin.math.*

object GeoUtils {
    private const val EARTH_RADIUS_METERS = 6371000.0

    /**
     * Standard Haversine distance in meters between two WGS-84 coordinate points.
     */
    fun distanceMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = sin(dLat / 2).pow(2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2).pow(2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return EARTH_RADIUS_METERS * c
    }

    /**
     * Concise display distance for the widget (e.g. "45 m away" or "1.2 km away").
     */
    fun formatDistance(distanceMeters: Double): String {
        return if (distanceMeters < 1000.0) {
            "${distanceMeters.roundToInt()} m away"
        } else {
            val km = distanceMeters / 1000.0
            String.format("%.1f km away", km)
        }
    }

    fun formatWalkingSummary(distanceMeters: Double): String {
        val walkMinutes = ceil(distanceMeters / 80.0).toInt().coerceAtLeast(1)
        return "${formatDistance(distanceMeters)} · ~${walkMinutes} min walk"
    }

    /**
     * Relative freshness label based on telemetry recorded timestamp epoch millis.
     */
    fun formatFreshness(telemetryEpochMs: Long, isStale: Boolean): String {
        if (telemetryEpochMs <= 0L) return "Location unavailable"
        if (isStale) return "Location outdated"

        val diffMs = System.currentTimeMillis() - telemetryEpochMs
        if (diffMs < 0) return "Updated just now"
        val seconds = diffMs / 1000
        val minutes = seconds / 60

        return when {
            seconds < 30 -> "Updated just now"
            minutes == 1L -> "Updated 1m ago"
            minutes in 2..59 -> "Updated ${minutes}m ago"
            else -> "Location outdated"
        }
    }
}
