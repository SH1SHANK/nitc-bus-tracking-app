package `in`.ac.nitc.tracklet.widget

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class NearestBusWidgetWorker(
    private val context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        WidgetRefreshState.begin()
        NearestBusWidgetProvider.updateAllWidgets(context)
        try {
            val repository = WidgetDataRepository(context)
            val stop = repository.resolveMonitoredStop()
            val result = repository.fetchNearestBusForStop(stop)
            val stopDistanceMeters = repository.distanceToStop(stop.name)

            val newBusName = result.bus?.displayName ?: result.bus?.busNumber
            val newDistance = result.distanceMeters

            WidgetPreferences.saveWidgetData(
                context = context,
                stopName = stop.name,
                busName = newBusName,
                distanceMeters = newDistance,
                stopDistanceMeters = stopDistanceMeters,
                telemetryEpochMs = result.telemetryEpochMs,
                isStale = result.isStale,
                errorMessage = result.errorMessage
            )

            Result.success()
        } catch (_: Exception) {
            Result.retry()
        } finally {
            WidgetRefreshState.end()
            NearestBusWidgetProvider.updateAllWidgets(context)
        }
    }
}
