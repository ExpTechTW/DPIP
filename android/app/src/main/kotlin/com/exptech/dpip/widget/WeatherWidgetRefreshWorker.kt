package com.exptech.dpip.widget

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.ConcurrentHashMap

/**
 * Refreshes the addresses it was asked for, then redraws.
 *
 * The redraw always happens, even when every fetch failed: the launcher is
 * holding a `RemoteViews` captured at some past instant, and this process is the
 * only thing that can replace it with one that admits how old it is. An early
 * return on the first failure would leave that stale screen looking current.
 *
 * It runs on WorkManager's own background thread, so the fetch and the database
 * work are blocking, and neither touches the main thread.
 */
class WeatherWidgetRefreshWorker(
    context: Context,
    parameters: WorkerParameters,
) : Worker(context, parameters) {
    override fun doWork(): Result {
        if (isStopped) return Result.success()
        val localOnly = inputData.getBoolean(KEY_LOCAL_ONLY, false)
        val source = inputData.getString(KEY_SOURCE)
        val manual = inputData.getBoolean(KEY_MANUAL, false)
        var transientFailure = false

        if (!localOnly) {
            val store = WidgetStore.open(applicationContext)
            // A source-scoped request is honoured **only while an instance still
            // shows it**. A request queued before the last instance was removed
            // would otherwise run and spend a location fix, a clock exchange and
            // an HTTP fetch on a screen that no longer exists.
            val requested = source?.let { WidgetAddress.fromSourceIdentifier(it) }
            val addresses = when {
                source == null -> {
                    // Periodic/global work is also the recovery owner after a
                    // receiver's authority read failed. Retaining a periodic job
                    // without rechecking the launcher would poll orphan rows
                    // forever once storage recovers. This run fetches surviving
                    // sources itself, so do not enqueue duplicate one-time work.
                    when (val reconciled = WidgetUpdater.reconcile(applicationContext, requestRecovery = false)) {
                        WidgetInstanceReadResult.Failed -> {
                            transientFailure = true
                            emptyList()
                        }
                        is WidgetInstanceReadResult.Read -> {
                            // reconcile cancelled all widget work. Do not re-arm
                            // a local redraw after discovering an empty launcher.
                            if (reconciled.instances.isEmpty()) return Result.success()
                            reconciled.instances.map { it.address }.distinct()
                        }
                    }
                }
                requested == null -> {
                    WidgetLog.warning(applicationContext, "refresh for an unknown source ignored")
                    emptyList()
                }
                !store.hasInstanceFor(requested) -> {
                    WidgetLog.info(
                        applicationContext,
                        "refresh skipped source=${requested.sourceIdentifier} reason=no-instance",
                    )
                    emptyList()
                }
                else -> listOf(requested)
            }

            for (address in addresses) {
                // One run per source at a time, and a second request is *served*
                // rather than dropped. `REPLACE` cancels the queued work, not the
                // thread an already running `Worker` is parked on, so a
                // replacement can arrive while the run it replaced is still
                // fetching. Skipping it — "already running, it covers the same
                // address" — swallowed exactly the request a resize had raised a
                // new forecast demand behind: the running run had sampled the
                // demand before the resize and would never answer it. Waiting for
                // the monitor instead means the newest request runs once the
                // stopped one lets go, sampling the demand as it is now.
                val monitor = sourceLocks.computeIfAbsent(address.sourceIdentifier) { Any() }
                synchronized(monitor) {
                    // A cancelled run stops before doing more work: its result
                    // would be fenced anyway, but a location fix and an HTTP
                    // fetch are not free.
                    if (isStopped) {
                        WidgetLog.info(applicationContext, "refresh stopped before fetch")
                        continue
                    }
                    if (manual && store.writeRefreshFeedback(
                            address, id.toString(), WidgetRefreshFeedback.Running, System.currentTimeMillis(),
                        )) {
                        WidgetUpdater.updateAddress(applicationContext, address)
                    }

                    // The durable demand is re-derived first, so a resize that
                    // happened while this work waited is recorded; the
                    // reservation is then decided optimistically for any wide
                    // instance. Whether the cached forecast is usable for the
                    // township this run resolves to is decided *after* the
                    // resolve, inside the service — the cache can only name the
                    // previous township.
                    WidgetUpdater.refreshForecastDemand(applicationContext, address)
                    val includeForecast = WidgetUpdater.wantsForecast(applicationContext, address)
                    val demandVersion = if (includeForecast) {
                        store.readForecastDemandVersion(address)
                    } else {
                        null
                    }
                    val result = try {
                        refresher(applicationContext, address, includeForecast, demandVersion) {
                            isStopped
                        }
                    } catch (error: Exception) {
                        WidgetLog.error(
                            applicationContext,
                            "refresh threw source=${address.sourceIdentifier} " +
                                "error=${error.logName()}",
                        )
                        WidgetRefreshResult.Failed
                    }
                    if (result == WidgetRefreshResult.Failed) transientFailure = true
                    if (manual && !isStopped && result != WidgetRefreshResult.Cancelled) {
                        store.writeRefreshFeedback(
                            address, id.toString(),
                            if (result == WidgetRefreshResult.Refreshed) WidgetRefreshFeedback.Updated
                            else WidgetRefreshFeedback.Failed,
                            System.currentTimeMillis(),
                        )
                    }
                }
            }
        }

        if (source != null) {
            WidgetAddress.fromSourceIdentifier(source)
                ?.let { WidgetUpdater.updateAddress(applicationContext, it) }
                ?: WidgetUpdater.updateAll(applicationContext)
        } else {
            WidgetUpdater.updateAll(applicationContext)
        }
        // A cancelled run must not re-arm the schedule: the run that replaced it
        // does that, with its own, newer state.
        if (!isStopped) scheduleNextLocalRerender(applicationContext)

        // A bounded retry: three attempts with WorkManager's exponential backoff,
        // so a network outage is retried a few times and then left to the next
        // period rather than looping.
        return if (transientFailure && !localOnly && runAttemptCount < maximumAttempts) {
            Result.retry()
        } else {
            Result.success()
        }
    }

    /**
     * Asks for a cache-only redraw at the next instant the screen could change.
     *
     * The boundaries are the staleness deadline, the next day/night transition
     * and the forecast's expiry — all computed in calibrated time by
     * `WidgetDeadlines`, and converted to a delay from the device clock with the
     * *live* clock anchor. Using the snapshot's stored offset here was wrong:
     * that offset describes the device clock when the snapshot was written, so a
     * device time change would schedule the redraw at the wrong moment.
     *
     * With no anchor there is no trustworthy way to place a calibrated instant
     * on the device clock, so only UI-feedback expiry can be scheduled — weather
     * still relies on the periodic redraw and reports untrusted freshness.
     */
    companion object {
        const val KEY_LOCAL_ONLY = "local_only"
        const val KEY_SOURCE = "source"
        const val KEY_MANUAL = "manual"

        /** Feedback is UI-only and can expire even without a trusted server clock.
         * Weather boundaries remain calibrated, and the earliest of both wins.
         */
        internal fun scheduleNextLocalRerender(context: Context) {
            val calibratedNow = WidgetClock.calibratedNowMilliseconds()
            val now = System.currentTimeMillis()
            val store = WidgetStore.open(context)
            var earliestDeviceBoundary: Long? = null
            for (address in store.usedAddresses()) {
                val feedback = store.readRefreshFeedback(address, now)
                if (feedback != null) {
                    earliestDeviceBoundary = minOf(earliestDeviceBoundary ?: Long.MAX_VALUE, feedback.expiresAtMilliseconds)
                }
                if (calibratedNow == null) continue
                val snapshot = store.readCurrentWeather(address)?.snapshot ?: continue
                val change = WidgetDeadlines.nextChange(snapshot, store.readForecast(address), calibratedNow) ?: continue
                val deviceBoundary = WidgetClock.deviceMillisecondsFor(change) ?: continue
                earliestDeviceBoundary = minOf(earliestDeviceBoundary ?: Long.MAX_VALUE, deviceBoundary)
            }
            val delayMilliseconds = (earliestDeviceBoundary ?: return) - now
            WidgetLog.debug(context, "local redraw scheduled in ${delayMilliseconds / 1_000}s")
            WidgetRefreshScheduler.scheduleLocalRerender(context, delayMilliseconds)
        }

        private const val maximumAttempts = 3

        /**
         * How one address is refreshed.
         *
         * A seam, so a test can assert *whether* a fetch was attempted — the
         * behaviour these tests are about — without a network or a location fix.
         * It defaults to the production path, and the production code never
         * replaces it.
         */
        internal var refresher:
            (Context, WidgetAddress, Boolean, Long?, () -> Boolean) -> WidgetRefreshResult = {
                context,
                address,
                includeForecast,
                demandVersion,
                isCancelled,
            ->
            WidgetRefreshService.create(context)
                .refresh(address, includeForecast, demandVersion, isCancelled)
        }

        internal fun resetRefresher() {
            refresher = { context, address, includeForecast, demandVersion, isCancelled ->
                WidgetRefreshService.create(context)
                    .refresh(address, includeForecast, demandVersion, isCancelled)
            }
        }

        /**
         * One in-process guard per source.
         *
         * Not a substitute for WorkManager's own uniqueness — that decides what
         * runs; this decides what runs *at the same time*, which `REPLACE` cannot:
         * cancelling a `WorkInfo` does not interrupt a blocking `Worker`. A
         * request that finds the monitor held waits for it instead of being
         * dropped, so the newest demand is always answered by the newest run.
         */
        private val sourceLocks = ConcurrentHashMap<String, Any>()
    }
}
