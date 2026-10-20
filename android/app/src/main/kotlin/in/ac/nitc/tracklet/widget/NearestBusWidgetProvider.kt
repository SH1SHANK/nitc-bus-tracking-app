package `in`.ac.nitc.tracklet.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.Gravity
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.work.*
import `in`.ac.nitc.tracklet.MainActivity
import `in`.ac.nitc.tracklet.R
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

class NearestBusWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Enqueue an immediate background fetch
        enqueueOneTimeRefresh(context)

        // Render current/cached state immediately
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        schedulePeriodicRefresh(context)
        enqueueOneTimeRefresh(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelPeriodicRefresh(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH_WIDGET) {
            enqueueOneTimeRefresh(context)
        }
    }

    companion object {
        const val ACTION_REFRESH_WIDGET = "in.ac.nitc.tracklet.ACTION_REFRESH_WIDGET"
        private const val WORK_NAME_PERIODIC = "nearest_bus_widget_periodic_work"
        private const val WORK_NAME_ONE_TIME = "nearest_bus_widget_one_time_work"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val data = WidgetPreferences.getWidgetData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_nearest_bus)
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            val compact = minWidth < 160 || minHeight < 128

            views.setTextViewTextSize(
                R.id.widget_bus_name,
                TypedValue.COMPLEX_UNIT_SP,
                if (compact) 16f else 18f
            )
            views.setTextViewTextSize(
                R.id.widget_distance,
                TypedValue.COMPLEX_UNIT_SP,
                if (compact) 16f else 18f
            )
            views.setViewVisibility(R.id.widget_badge_live, View.GONE)
            views.setTextViewText(R.id.widget_stop_name, data.stopName)
            val stopDistance = data.stopDistanceMeters?.takeIf { it <= 3_000.0 }
            views.setViewVisibility(
                R.id.widget_stop_distance,
                if (stopDistance != null) View.VISIBLE else View.GONE
            )
            if (stopDistance != null) {
                views.setTextViewText(
                    R.id.widget_stop_distance,
                    GeoUtils.formatWalkingSummary(stopDistance)
                )
                if (compact) {
                    views.setTextViewTextSize(
                        R.id.widget_stop_distance,
                        TypedValue.COMPLEX_UNIT_SP,
                        10f
                    )
                }
            }

            val refreshing = WidgetRefreshState.isRefreshing
            views.setViewVisibility(
                R.id.widget_refresh_icon,
                if (refreshing) View.GONE else View.VISIBLE
            )
            views.setViewVisibility(
                R.id.widget_refresh_progress,
                if (refreshing) View.VISIBLE else View.GONE
            )
            views.setContentDescription(
                R.id.widget_btn_refresh,
                context.getString(
                    if (refreshing) R.string.widget_refreshing_tooltip
                    else R.string.widget_refresh_tooltip
                )
            )

            if (data.busName != null && data.distanceMeters != null) {
                views.setViewVisibility(R.id.widget_bus_container, View.VISIBLE)
                views.setViewVisibility(R.id.widget_loading_container, View.GONE)
                views.setViewVisibility(R.id.widget_empty_container, View.GONE)
                views.setViewVisibility(R.id.widget_error_container, View.GONE)

                val telemetryAge = System.currentTimeMillis() - data.telemetryEpochMs
                val isFresh = !data.isStale && data.telemetryEpochMs > 0L && telemetryAge in 0L..89_999L
                views.setViewVisibility(R.id.widget_badge_live, View.VISIBLE)
                views.setImageViewResource(
                    R.id.widget_badge_dot,
                    if (isFresh) R.drawable.widget_live_dot else R.drawable.widget_stale_dot
                )
                views.setTextViewText(
                    R.id.widget_badge_text,
                    GeoUtils.formatFreshness(data.telemetryEpochMs, data.isStale)
                )
                views.setTextColor(
                    R.id.widget_badge_text,
                    context.getColor(if (isFresh) R.color.widget_live_text else R.color.widget_stale_text)
                )

                views.setTextViewText(R.id.widget_bus_name, data.busName)
                views.setTextViewText(R.id.widget_distance, GeoUtils.formatDistance(data.distanceMeters))
            } else if (data.errorMessage == null && WidgetPreferences.getLastRefreshTimestamp(context) == 0L) {
                views.setViewVisibility(R.id.widget_bus_container, View.GONE)
                views.setViewVisibility(R.id.widget_loading_container, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty_container, View.GONE)
                views.setViewVisibility(R.id.widget_error_container, View.GONE)
            } else if (data.errorMessage in EMPTY_DATA_ERRORS || data.errorMessage == null) {
                views.setViewVisibility(R.id.widget_bus_container, View.GONE)
                views.setViewVisibility(R.id.widget_loading_container, View.GONE)
                views.setViewVisibility(R.id.widget_empty_container, View.VISIBLE)
                views.setViewVisibility(R.id.widget_error_container, View.GONE)
                views.setViewVisibility(
                    R.id.widget_empty_illustration,
                    if (minWidth < 120) View.GONE else View.VISIBLE
                )
                views.setInt(
                    R.id.widget_empty_text_container,
                    "setGravity",
                    if (minWidth < 120) Gravity.CENTER else Gravity.CENTER_VERTICAL or Gravity.START
                )
                views.setInt(
                    R.id.widget_empty_message,
                    "setGravity",
                    if (minWidth < 120) Gravity.CENTER else Gravity.START
                )
                views.setInt(
                    R.id.widget_empty_submessage,
                    "setGravity",
                    if (minWidth < 120) Gravity.CENTER else Gravity.START
                )
                val (title, subtitle) = when (data.errorMessage) {
                    "No buses serving this stop" ->
                        R.string.widget_no_eligible_buses to R.string.widget_other_stop_subtitle
                    "Location unavailable" ->
                        R.string.widget_location_unavailable to R.string.widget_location_unavailable_subtitle
                    else -> R.string.widget_no_active_buses to R.string.widget_empty_subtitle
                }
                views.setTextViewText(R.id.widget_empty_message, context.getString(title))
                views.setTextViewText(R.id.widget_empty_submessage, context.getString(subtitle))
            } else {
                views.setViewVisibility(R.id.widget_bus_container, View.GONE)
                views.setViewVisibility(R.id.widget_loading_container, View.GONE)
                views.setViewVisibility(R.id.widget_empty_container, View.GONE)
                views.setViewVisibility(R.id.widget_error_container, View.VISIBLE)

                views.setTextViewText(
                    R.id.widget_error_message,
                    context.getString(R.string.widget_error_state)
                )
                views.setTextViewText(
                    R.id.widget_error_submessage,
                    context.getString(R.string.widget_offline_state)
                )
            }

            // Interactive Refresh Button PendingIntent (triggers immediate background worker)
            val refreshIntent = Intent(context, NearestBusWidgetProvider::class.java).apply {
                action = ACTION_REFRESH_WIDGET
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_refresh, refreshPendingIntent)

            // Launch MainActivity when tapping the root widget card
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("source", "home_widget")
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, NearestBusWidgetProvider::class.java)
            )
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }

        private const val MIN_MANUAL_REFRESH_INTERVAL_MS = 10_000L // 10 seconds throttle
        private val EMPTY_DATA_ERRORS = setOf(
            "No active buses",
            "No buses serving this stop",
            "Location unavailable"
        )

        fun enqueueOneTimeRefresh(context: Context, force: Boolean = false) {
            if (!force) {
                val lastRefresh = WidgetPreferences.getLastRefreshTimestamp(context)
                if (System.currentTimeMillis() - lastRefresh < MIN_MANUAL_REFRESH_INTERVAL_MS) {
                    return // Throttled to preserve battery and avoid spamming network
                }
            }

            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = OneTimeWorkRequestBuilder<NearestBusWidgetWorker>()
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                WORK_NAME_ONE_TIME,
                ExistingWorkPolicy.KEEP,
                request
            )
        }

        fun schedulePeriodicRefresh(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            // 15-minute standard WorkManager periodic window
            val periodicRequest = PeriodicWorkRequestBuilder<NearestBusWidgetWorker>(
                15, TimeUnit.MINUTES,
                5, TimeUnit.MINUTES
            ).setConstraints(constraints).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME_PERIODIC,
                ExistingPeriodicWorkPolicy.KEEP,
                periodicRequest
            )
        }

        fun cancelPeriodicRefresh(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME_PERIODIC)
        }
    }
}

internal object WidgetRefreshState {
    private val activeWorkers = AtomicInteger(0)

    val isRefreshing: Boolean
        get() = activeWorkers.get() > 0

    fun begin() {
        activeWorkers.incrementAndGet()
    }

    fun end() {
        activeWorkers.updateAndGet { count -> (count - 1).coerceAtLeast(0) }
    }
}
