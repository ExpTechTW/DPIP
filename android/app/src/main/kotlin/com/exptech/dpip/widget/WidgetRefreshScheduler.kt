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
 * The Widget's update cadence, expressed as WorkManager work.
 *
 * ## What is promised, and what is not
 *
 * The target is a refresh about every 20 minutes. WorkManager's own floor for
 * periodic work is 15 minutes, and beyond that Doze, app-standby buckets and
 * OEM battery managers all defer it — so this is a **request**, never a
 * guarantee, and nothing in the UI may say "every 20 minutes" or imply the data
 * is live. The screen shows the Taipei observation time and an outdated notice
 * when appropriate; its accessible description retains the full date and time.
 *
 * `android:updatePeriodMillis` is 0 in `weather_widget_info.xml`, so there is
 * one scheduler and not two disagreeing ones.
 *
 * ## Constraints
 *
 * The **periodic** work and the local re-render are deliberately *not*
 * network-constrained. A constraint would block the whole worker offline,
 * including the part that only re-draws from the cache, and an offline device
 * would then keep showing an old screen that never admits it is old. Instead the
 * worker always runs, always re-renders, and treats the fetch as best-effort —
 * so an offline period degrades to "the same observation, now marked stale",
 * which is the honest screen. The 6 s HTTP timeout bounds the cost of the
 * attempt.
 *
 * A **one-time** refresh *is* network-constrained: it exists to bring data in,
 * and running it offline only to fail would burn a worker slot for nothing.
 */
object WidgetRefreshScheduler {
    const val periodicWorkName = "widget-refresh-periodic"
    const val allSourcesWorkName = "widget-refresh-once-all"
    const val localRerenderWorkName = "widget-rerender"

    /** The requested cadence. A request, not a promise — see the class comment. */
    const val periodicIntervalMinutes = 20L

    private const val backoffSeconds = 30L

    /**
     * Every piece of work this Widget enqueues carries this tag.
     *
     * Cancelling by tag is what lets "the last Widget was removed" undo the
     * per-source one-time work without touching the background-location
     * watchdog's own periodic work, which `cancelAllWork` would take with it.
     */
    const val workTag = "widget-work"

    private const val oneTimePrefix = "widget-refresh-once-"

    fun sourceWorkName(address: WidgetAddress): String =
        oneTimePrefix + address.sourceIdentifier

    fun schedulePeriodic(context: Context) {
        val request = PeriodicWorkRequestBuilder<WeatherWidgetRefreshWorker>(
            periodicIntervalMinutes,
            TimeUnit.MINUTES,
        )
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, backoffSeconds, TimeUnit.SECONDS)
            .addTag(workTag)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            periodicWorkName,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }

    /**
     * A one-shot refresh, for one source or for everything.
     *
     * De-duplicated **per source**, not globally. A single global unique name
     * meant that a Widget added while another source's refresh was running was
     * KEEP-dropped, and the new instance kept the launcher's `initialLayout`
     * until the next periodic run — the "add B while A is running" gap.
     *
     * `REPLACE`, not `KEEP`: a same-source request can carry *newer* demand than
     * the run it would be de-duplicated against. The case that matters is a
     * compact widget resized to medium while its refresh is already running —
     * with KEEP the resize's request was dropped, the running refresh had already
     * sampled "no forecast needed", and the medium widget stayed forecastless for
     * up to a period. Replacing restarts the run, which samples the demand again.
     * A burst of taps therefore collapses into one run rather than a queue of
     * them.
     */
    fun scheduleOneTime(context: Context, address: WidgetAddress?, manual: Boolean = false) {
        enqueueOneTime(context, address, manual, ExistingWorkPolicy.REPLACE)
    }

    /**
     * Recovery adds no new demand: keep an unfinished source request, including
     * a manual refresh's feedback identity, rather than cancelling it each time
     * the process receives a boot/package/restore reconciliation broadcast.
     */
    fun scheduleRecovery(context: Context, address: WidgetAddress) {
        enqueueOneTime(context, address, false, ExistingWorkPolicy.KEEP)
    }

    private fun enqueueOneTime(
        context: Context,
        address: WidgetAddress?,
        manual: Boolean,
        policy: ExistingWorkPolicy,
    ) {
        val request = OneTimeWorkRequestBuilder<WeatherWidgetRefreshWorker>()
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build(),
            )
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, backoffSeconds, TimeUnit.SECONDS)
            .setInputData(
                Data.Builder()
                    .putString(WeatherWidgetRefreshWorker.KEY_SOURCE, address?.sourceIdentifier)
                    .putBoolean(WeatherWidgetRefreshWorker.KEY_MANUAL, manual)
                    .build(),
            )
            .addTag(workTag)
            .build()

        if (manual && address != null) {
            WidgetStore.open(context).beginRefreshFeedback(address, request.id.toString(), System.currentTimeMillis())
        }

        WorkManager.getInstance(context).enqueueUniqueWork(
            address?.let(::sourceWorkName) ?: allSourcesWorkName,
            policy,
            request,
        )
        if (manual) WeatherWidgetRefreshWorker.scheduleNextLocalRerender(context)
    }

    /**
     * Cancels the queued refresh for one source.
     *
     * Called when the last instance showing that source is removed: without it a
     * request already in the queue would still run, and fetch for a home screen
     * that no longer shows it.
     */
    fun cancelSource(context: Context, address: WidgetAddress) {
        WorkManager.getInstance(context).cancelUniqueWork(sourceWorkName(address))
    }

    /**
     * A cache-only redraw at a future boundary, so the screen can turn stale or
     * flip day/night without a network round trip.
     *
     * Non-exact by construction: WorkManager may deliver it late, and it is only
     * an optimisation on top of the periodic redraw. Nothing depends on it
     * having run.
     *
     * The delay is passed through uncapped. The earlier version clamped it to 60
     * seconds, which turned every boundary — however far away — into a redraw
     * every minute, and each redraw read the store and re-inflated three
     * `RemoteViews`.
     */
    fun scheduleLocalRerender(context: Context, delayMilliseconds: Long) {
        val request = OneTimeWorkRequestBuilder<WeatherWidgetRefreshWorker>()
            .setInitialDelay(delayMilliseconds.coerceAtLeast(0), TimeUnit.MILLISECONDS)
            .setInputData(
                Data.Builder()
                    .putBoolean(WeatherWidgetRefreshWorker.KEY_LOCAL_ONLY, true)
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
     * Everything this Widget has queued, and nothing else.
     *
     * Called when the last instance is removed. The per-source one-time work is
     * cancelled by tag because its names are addresses, and enumerating them
     * afterwards is impossible — the instance rows that named them are gone.
     */
    fun cancelAll(context: Context) {
        val workManager = WorkManager.getInstance(context)
        workManager.cancelUniqueWork(periodicWorkName)
        workManager.cancelUniqueWork(allSourcesWorkName)
        workManager.cancelUniqueWork(localRerenderWorkName)
        workManager.cancelAllWorkByTag(workTag)
    }

    fun cancelPeriodic(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(periodicWorkName)
    }
}
