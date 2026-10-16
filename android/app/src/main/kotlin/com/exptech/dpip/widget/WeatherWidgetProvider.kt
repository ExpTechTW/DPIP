package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle

/**
 * The home-screen Widget's lifecycle entry point.
 *
 * Every callback here does bounded work only — a cache read, a `RemoteViews`
 * build, and an enqueue. `onUpdate` and `onOptionsChanged` run on the main
 * thread inside a broadcast window, so anything that can block (HTTP, location,
 * the clock's UDP exchange) belongs to [WeatherWidgetRefreshWorker], which the
 * callbacks merely ask for. That split is not tidiness: a receiver that blocks
 * is an ANR, and an ANR here is the launcher's, not this app's, to report.
 */
class WeatherWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        // A restored or app-updated instance may exist with no worker history.
        // Rendering first means the Widget shows whatever is already cached
        // rather than a blank while the fetch runs.
        for (appWidgetId in appWidgetIds) {
            WidgetUpdater.updateInstance(context, appWidgetId)
        }

        val store = WidgetStore.open(context)
        if (store.readInstances().isEmpty()) return
        WidgetRefreshScheduler.schedulePeriodic(context)

        // Per source, so an instance added while another source's refresh is
        // running still gets its own fetch instead of being dropped.
        for (address in store.usedAddresses()) {
            WidgetUpdater.refreshForecastDemand(context, address)
            WidgetRefreshScheduler.scheduleOneTime(context, address)
        }
    }

    /**
     * A resize re-selects the layout, and may newly require a forecast.
     *
     * The render is synchronous and cache-only; the fetch is enqueued only when
     * the new size class draws a forecast the cache does not already hold, which
     * is what makes a drag to a wider cell free.
     */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        WidgetUpdater.updateInstance(context, appWidgetId)

        val store = WidgetStore.open(context)
        val instance = store.readInstance(appWidgetId) ?: return
        // The demand is recorded before the request is made: a resize can raise
        // it while a refresh for the same source is already running, and the
        // durable flag is what makes the next run fetch it anyway.
        if (!WidgetUpdater.refreshForecastDemand(context, instance.address)) return
        WidgetRefreshScheduler.scheduleOneTime(context, instance.address)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val store = WidgetStore.open(context)
        // The addresses are read before the rows go: afterwards there is nothing
        // left to say which sources these instances were showing.
        val removed = appWidgetIds
            .toList()
            .mapNotNull { store.readInstance(it)?.address }
            .distinct()

        for (appWidgetId in appWidgetIds) {
            store.deleteInstance(appWidgetId)
        }

        val remaining = when (val result = store.readInstancesResult()) {
            is WidgetInstanceReadResult.Read -> result.instances
            WidgetInstanceReadResult.Failed -> {
                // A failed delete/read is not proof that the launcher removed
                // every instance. Retain recovery without retrying in a receiver.
                WidgetRefreshScheduler.schedulePeriodic(context)
                return
            }
        }
        if (remaining.isEmpty()) {
            // The last instance is gone: cancel the periodic work, the one-time
            // requests and the pending local redraw together. Leaving the
            // redraw behind would keep a worker waking up to redraw nothing.
            WidgetRefreshScheduler.cancelAll(context)
            return
        }

        // Other instances remain, but a source with none left must not keep a
        // queued refresh: it would run and fetch for a screen that is gone.
        for (address in removed) {
            if (remaining.none { it.address == address }) {
                WidgetRefreshScheduler.cancelSource(context, address)
            }
        }
    }

    override fun onEnabled(context: Context) {
        WidgetRefreshScheduler.schedulePeriodic(context)
    }

    override fun onDisabled(context: Context) {
        // Cancelling here rather than in onDeleted is what keeps a device with
        // no Weather Widget from polling the weather every 20 minutes forever.
        WidgetRefreshScheduler.cancelAll(context)
    }

    /**
     * Re-attaches restored instances to their saved choice.
     *
     * A launcher restore hands back fresh ids with no configuration: the
     * settings Activity is not run, and without this the Widget would come back
     * blank. The choice is *moved* by position — the pairing the framework
     * itself defines — and the old row is deleted, because a row left behind
     * keeps its source alive and is never fenced.
     */
    override fun onRestored(
        context: Context,
        oldWidgetIds: IntArray,
        newWidgetIds: IntArray,
    ) {
        val store = WidgetStore.open(context)
        for (index in oldWidgetIds.indices) {
            if (index >= newWidgetIds.size) break
            if (store.remapInstance(oldWidgetIds[index], newWidgetIds[index])) {
                WidgetLog.info(
                    context,
                    "restored instance ${newWidgetIds[index]} from ${oldWidgetIds[index]}",
                )
            }
        }
        // Drops any row the launcher did not hand back, then redraws. The ids
        // just restored are kept regardless: a launcher does not always report
        // them through `getAppWidgetIds` by the time this runs, and treating
        // that as "gone" would delete exactly what was restored.
        WidgetUpdater.reconcile(context, keepIds = newWidgetIds.toSet())
    }

    /**
     * The "update now" tap.
     *
     * An explicit broadcast to this receiver, so no other app can drive it, and
     * it carries only the instance id. The refresh it asks for is de-duplicated
     * per source, which is the throttle: repeated taps while one is in flight
     * coalesce instead of queueing.
     */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != WidgetRenderer.ACTION_REFRESH) return

        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return

        val address = WidgetStore.open(context).readInstance(appWidgetId)?.address ?: return
        WidgetRefreshScheduler.scheduleOneTime(context, address, manual = true)
        WidgetUpdater.updateAddress(context, address)
    }
}
