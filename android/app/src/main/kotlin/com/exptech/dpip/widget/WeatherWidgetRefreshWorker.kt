package com.exptech.dpip.widget

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * The Widget's background work, in three modes (see [WidgetRefresh]):
 *
 * * [MODE_REFRESH] — one link of the refresh chain: fetch, commit, redraw.
 * * [MODE_PERIODIC] — the periodic tick: reconcile against the launcher, redraw
 *   from the cache, and append a refresh link. It fetches nothing itself, so it
 *   can never run beside a link of the chain.
 * * [MODE_REDRAW] — a redraw at a boundary, from the cache; a boundary that
 *   needs new data also appends a refresh link.
 *
 * Every mode redraws, even when every fetch failed: the launcher is holding a
 * `RemoteViews` captured at some past instant, and this process is the only
 * thing that can replace it with one that admits how old it is.
 *
 * It runs on WorkManager's own background thread, so the fetch and the
 * database work are blocking, and neither touches the main thread.
 */
class WeatherWidgetRefreshWorker(
    context: Context,
    parameters: WorkerParameters,
) : Worker(context, parameters) {
    override fun doWork(): Result = when (inputData.getString(KEY_MODE)) {
        MODE_PERIODIC -> periodic()
        MODE_REDRAW -> redraw()
        else -> refresh()
    }

    private fun periodic(): Result {
        // The tick is also the recovery owner after a receiver's authority read
        // failed: it re-checks the launcher, so orphan rows are dropped instead
        // of polled forever once storage recovers.
        return when (WidgetRefresh.reconcile(applicationContext, WidgetRefresh.Reason.Periodic, ensurePeriodic = false)) {
            WidgetInstanceReadResult.Failed -> retryOrGiveUp()
            is WidgetInstanceReadResult.Read -> Result.success()
        }
    }

    private fun redraw(): Result {
        WidgetUpdater.updateAll(applicationContext)
        if (inputData.getBoolean(KEY_REFETCH, false)) {
            WidgetRefresh.request(applicationContext, WidgetRefresh.Reason.Boundary)
        }
        WidgetRefresh.scheduleNextLocalRerender(applicationContext)
        return Result.success()
    }

    private fun refresh(): Result {
        val store = WidgetStore.open(applicationContext)
        val source = inputData.getString(KEY_SOURCE)
        val manual = inputData.getBoolean(KEY_MANUAL, false)
        val addresses = if (source == null) {
            store.usedAddresses()
        } else {
            val requested = WidgetAddress.fromSourceIdentifier(source)
            if (requested == null) {
                WidgetLog.warning(applicationContext, "refresh for an unknown source ignored")
                return Result.success()
            }
            listOf(requested)
        }

        var transientFailure = false
        for (address in addresses) {
            if (isStopped) break
            // A request queued before the last instance was removed must not
            // spend a location fix, a clock exchange and an HTTP fetch on a
            // screen that no longer exists.
            if (!store.hasInstanceFor(address)) {
                WidgetLog.info(applicationContext, "refresh skipped source=${address.sourceIdentifier} reason=no-instance")
                continue
            }
            // Triggers arrive in bursts (an app launch publishes, redraws and
            // asks; a boot reconciles), and every one of them appends a link.
            // The first link fetches; the rest find it done.
            if (!manual && refreshedRecently(store, address)) {
                WidgetLog.debug(applicationContext, "refresh skipped source=${address.sourceIdentifier} reason=recent")
                continue
            }
            if (manual && store.writeRefreshFeedback(address, id.toString(), WidgetRefreshFeedback.Running, now())) {
                WidgetUpdater.updateAddress(applicationContext, address)
            }

            val result = try {
                refresher(applicationContext, address)
            } catch (error: Exception) {
                WidgetLog.error(
                    applicationContext,
                    "refresh threw source=${address.sourceIdentifier} error=${error.logName()}",
                )
                WidgetRefreshResult.Failed
            }
            // Superseded means the app published something newer meanwhile:
            // the screen is as current as this run could have made it.
            val current = result == WidgetRefreshResult.Refreshed || result == WidgetRefreshResult.Superseded
            if (current) store.markRefreshed(address, now())
            if (result == WidgetRefreshResult.Failed) transientFailure = true
            if (manual) {
                store.writeRefreshFeedback(
                    address, id.toString(),
                    if (current) WidgetRefreshFeedback.Updated else WidgetRefreshFeedback.Failed,
                    now(),
                )
            }
            WidgetUpdater.updateAddress(applicationContext, address)
        }

        WidgetRefresh.scheduleNextLocalRerender(applicationContext)
        return if (transientFailure) retryOrGiveUp() else Result.success()
    }

    /**
     * A bounded retry: three attempts with WorkManager's exponential backoff,
     * so an outage is retried a few times and then left to the next period
     * rather than looping.
     */
    private fun retryOrGiveUp(): Result =
        if (runAttemptCount < maximumAttempts) Result.retry() else Result.success()

    private fun refreshedRecently(store: WidgetStore, address: WidgetAddress): Boolean {
        val at = store.readRefreshedAt(address) ?: return false
        val now = now()
        return at <= now && now - at < recentRefreshMilliseconds
    }

    private fun now() = System.currentTimeMillis()

    companion object {
        const val KEY_MODE = "mode"
        const val KEY_SOURCE = "source"
        const val KEY_MANUAL = "manual"
        const val KEY_REASON = "reason"
        const val KEY_REFETCH = "refetch"

        const val MODE_REFRESH = "refresh"
        const val MODE_PERIODIC = "periodic"
        const val MODE_REDRAW = "redraw"

        private const val maximumAttempts = 3

        /** A link this soon after a successful one for the same source skips it. */
        const val recentRefreshMilliseconds = 60_000L

        /**
         * How one address is refreshed.
         *
         * A seam, so a test can assert *whether* a fetch was attempted without a
         * network or a location fix. Production never replaces it.
         */
        internal var refresher: (Context, WidgetAddress) -> WidgetRefreshResult = ::refreshFromNetwork

        internal fun resetRefresher() {
            refresher = ::refreshFromNetwork
        }

        private fun refreshFromNetwork(context: Context, address: WidgetAddress): WidgetRefreshResult =
            WidgetRefreshService.create(context).refresh(address)
    }
}
