package com.exptech.dpip.widget

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * The one way anything asks the Widget for new data, and the work behind it.
 *
 * ## One refresh chain
 *
 * Every trigger — the periodic tick, a new or restored instance, a resize that
 * needs a forecast, the app publishing a snapshot, a reboot, the user's tap —
 * calls [request], which appends one network refresh to a single unique
 * WorkManager chain ([refreshWorkName], `APPEND_OR_REPLACE`). WorkManager runs a
 * chain one link at a time, so two refreshes never race each other: no
 * per-source names, no locks, no cancelling a run another trigger depends on.
 * Appending rather than replacing is also what keeps a manual refresh's
 * feedback: an app push queued behind it can no longer cancel it mid-flight.
 * A burst of requests is cheap, because a link skips a source that a previous
 * link refreshed moments ago (see [WeatherWidgetRefreshWorker]).
 *
 * ## What is promised
 *
 * The periodic tick asks for about every 20 minutes. WorkManager's floor is 15
 * minutes, and Doze, app-standby buckets and OEM battery managers all defer it,
 * so this is a **request**, never a guarantee; the screen shows the Taipei
 * observation time and an outdated notice when appropriate.
 * `android:updatePeriodMillis` is 0, so there is one scheduler, not two.
 *
 * ## Constraints
 *
 * A refresh link waits for a network: it exists to bring data in. The periodic
 * tick and the local redraw are *not* network-constrained, and both redraw from
 * the cache first, so an offline device still turns an old observation stale
 * rather than keeping a screen that never admits it is old.
 */
object WidgetRefresh {
    const val refreshWorkName = "widget-refresh"
    const val periodicWorkName = "widget-refresh-periodic"
    const val localRerenderWorkName = "widget-rerender"

    /**
     * Every piece of work this Widget enqueues carries this tag, so "the last
     * Widget was removed" cancels exactly what the Widget queued and never the
     * background-location watchdog's own work.
     */
    const val workTag = "widget-work"

    /** The requested cadence. A request, not a promise — see the class comment. */
    const val periodicIntervalMinutes = 20L

    private const val backoffSeconds = 30L

    /** Why a refresh was asked for. Logged, and carried for diagnostics only. */
    enum class Reason(val wire: String) {
        Periodic("periodic"),
        Update("update"),
        Configured("configured"),
        Resized("resized"),
        Restored("restored"),
        Boot("boot"),
        Boundary("boundary"),
        AppPublish("app-publish"),
        Tap("tap"),
    }

    /**
     * Appends one network refresh to the chain.
     *
     * [source] limits it to one address; null refreshes every address an
     * instance shows. A [manual] request is the user's tap: it records
     * "queued" feedback against this exact request, which the run then turns
     * into "updating" and its result.
     */
    fun request(
        context: Context,
        reason: Reason,
        source: WidgetAddress? = null,
        manual: Boolean = false,
    ) {
        val request = OneTimeWorkRequestBuilder<WeatherWidgetRefreshWorker>()
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, backoffSeconds, TimeUnit.SECONDS)
            .setInputData(
                Data.Builder()
                    .putString(WeatherWidgetRefreshWorker.KEY_MODE, WeatherWidgetRefreshWorker.MODE_REFRESH)
                    .putString(WeatherWidgetRefreshWorker.KEY_SOURCE, source?.sourceIdentifier)
                    .putBoolean(WeatherWidgetRefreshWorker.KEY_MANUAL, manual)
                    .putString(WeatherWidgetRefreshWorker.KEY_REASON, reason.wire)
                    .build(),
            )
            .addTag(workTag)
            .build()

        if (manual && source != null) {
            WidgetStore.open(context).beginRefreshFeedback(source, request.id.toString(), System.currentTimeMillis())
        }
        WidgetLog.info(
            context,
            "refresh requested reason=${reason.wire} source=${source?.sourceIdentifier ?: "all"}",
        )
        WorkManager.getInstance(context).enqueueUniqueWork(
            refreshWorkName,
            ExistingWorkPolicy.APPEND_OR_REPLACE,
            request,
        )
        if (manual) scheduleNextLocalRerender(context)
    }

    fun schedulePeriodic(context: Context) {
        val request = PeriodicWorkRequestBuilder<WeatherWidgetRefreshWorker>(
            periodicIntervalMinutes,
            TimeUnit.MINUTES,
        )
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, backoffSeconds, TimeUnit.SECONDS)
            .setInputData(
                Data.Builder()
                    .putString(WeatherWidgetRefreshWorker.KEY_MODE, WeatherWidgetRefreshWorker.MODE_PERIODIC)
                    .build(),
            )
            .addTag(workTag)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            periodicWorkName,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }

    /**
     * A redraw at a future boundary, from the cache first, so the screen turns
     * stale or flips day/night even offline.
     *
     * When [refetch] is set the boundary is one that needs new data — the
     * observation ageing out, the forecast expiring — and the redraw also
     * appends a refresh to the chain. Redrawing alone there is what left a
     * Widget saying "outdated" until the user tapped it.
     *
     * Non-exact by construction: WorkManager may deliver it late, and the
     * periodic tick redraws too. The delay is passed through uncapped — a clamp
     * turned every boundary into a redraw every minute.
     */
    fun scheduleLocalRerender(context: Context, delayMilliseconds: Long, refetch: Boolean = false) {
        val request = OneTimeWorkRequestBuilder<WeatherWidgetRefreshWorker>()
            .setInitialDelay(delayMilliseconds.coerceAtLeast(0), TimeUnit.MILLISECONDS)
            .setInputData(
                Data.Builder()
                    .putString(WeatherWidgetRefreshWorker.KEY_MODE, WeatherWidgetRefreshWorker.MODE_REDRAW)
                    .putBoolean(WeatherWidgetRefreshWorker.KEY_REFETCH, refetch)
                    .build(),
            )
            .addTag(workTag)
            .build()

        WorkManager.getInstance(context).enqueueUniqueWork(
            localRerenderWorkName,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }

    /**
     * Asks for a redraw at the next instant the screen could change.
     *
     * The boundaries are the staleness deadline, the next day/night transition
     * and the forecast's expiry — all calibrated, from `WidgetDeadlines` — plus
     * the expiry of manual-refresh feedback, which is UI-only device time. A
     * calibrated boundary is placed on the device clock with the *live* anchor,
     * so a device time change cannot misplace it; the anchor survives process
     * death (`WidgetClock.attach`), so a redraw scheduled by one process is
     * placed correctly by the next. With no anchor at all only the feedback
     * expiry can be scheduled.
     */
    fun scheduleNextLocalRerender(context: Context) {
        WidgetClock.attach(context)
        val calibratedNow = WidgetClock.calibratedNowMilliseconds()
        val now = System.currentTimeMillis()
        val store = WidgetStore.open(context)
        var earliest: Long? = null
        var refetchAt: Long? = null
        for (address in store.usedAddresses()) {
            store.readRefreshFeedback(address, now)?.let {
                earliest = minOf(earliest ?: Long.MAX_VALUE, it.expiresAtMilliseconds)
            }
            if (calibratedNow == null) continue
            val snapshot = store.readCurrentWeather(address)?.snapshot ?: continue
            val forecast = store.readForecast(address)
            WidgetDeadlines.nextChange(snapshot, forecast, calibratedNow)
                ?.let(WidgetClock::deviceMillisecondsFor)
                ?.let { earliest = minOf(earliest ?: Long.MAX_VALUE, it) }
            WidgetDeadlines.nextRefetch(snapshot, forecast, calibratedNow)
                ?.let(WidgetClock::deviceMillisecondsFor)
                ?.let { refetchAt = minOf(refetchAt ?: Long.MAX_VALUE, it) }
        }
        val at = earliest ?: return
        val refetch = refetchAt?.let { it <= at } == true
        val delayMilliseconds = at - now
        WidgetLog.debug(context, "local redraw scheduled in ${delayMilliseconds / 1_000}s refetch=$refetch")
        scheduleLocalRerender(context, delayMilliseconds, refetch)
    }

    /**
     * Brings the stored instances and the scheduled work back in line with the
     * launcher, then redraws.
     *
     * 1. **Drop rows the launcher no longer has** — a restore, force-stop or
     *    launcher crash leaves rows that would keep a source polling for a home
     *    screen that does not exist. `AppWidgetManager` is the authority, except
     *    for [keepIds]: a restore creates rows for ids the manager may not
     *    report yet.
     * 2. **Keep or cancel the periodic tick** from the surviving rows. A failed
     *    read is not authority to cancel anything: the periodic tick is kept as
     *    the bounded recovery path.
     * 3. **Request one refresh** for the survivors, when [reason] is given.
     * 4. **Redraw** whatever remains.
     *
     * [ensurePeriodic] is false only for the periodic tick itself, which must
     * not re-enqueue the work it is running as.
     */
    fun reconcile(
        context: Context,
        reason: Reason?,
        keepIds: Set<Int> = emptySet(),
        ensurePeriodic: Boolean = true,
    ): WidgetInstanceReadResult {
        val live = WidgetUpdater.liveAppWidgetIds(context).toSet() + keepIds
        val result = WidgetStore.open(context).reconcileInstances(live)
        if (result !is WidgetInstanceReadResult.Read) {
            WidgetLog.warning(context, "reconcile failed; retaining periodic recovery")
            schedulePeriodic(context)
            return result
        }
        if (result.dropped.isNotEmpty()) {
            WidgetLog.info(context, "reconcile dropped ${result.dropped.size} stale instances")
        }
        if (result.instances.isEmpty()) {
            cancelAll(context)
        } else {
            if (ensurePeriodic) schedulePeriodic(context)
            if (reason != null) request(context, reason)
        }
        WidgetUpdater.updateAll(context)
        return result
    }

    /**
     * Everything this Widget has queued, and nothing else. Called when the last
     * instance is removed.
     */
    fun cancelAll(context: Context) {
        val workManager = WorkManager.getInstance(context)
        workManager.cancelUniqueWork(periodicWorkName)
        workManager.cancelUniqueWork(refreshWorkName)
        workManager.cancelUniqueWork(localRerenderWorkName)
        workManager.cancelAllWorkByTag(workTag)
    }
}
