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
 * the clock's UDP exchange) belongs to the refresh chain, which the callbacks
 * merely ask for through [WidgetRefresh.request]. A receiver that blocks is an
 * ANR, and an ANR here is the launcher's, not this app's, to report.
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
        if (WidgetStore.open(context).readInstances().isEmpty()) return
        WidgetRefresh.schedulePeriodic(context)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update)
    }

    /**
     * A resize re-selects the layout. The render is synchronous and cache-only;
     * a refresh is asked for only when the new size draws a forecast the cache
     * cannot give it, which is what makes a drag to a wider cell free.
     */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        WidgetUpdater.updateInstance(context, appWidgetId)
        if (!WidgetUpdater.needsForecast(context, appWidgetId)) return
        val address = WidgetStore.open(context).readInstance(appWidgetId)?.address ?: return
        WidgetRefresh.request(context, WidgetRefresh.Reason.Resized, address)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val store = WidgetStore.open(context)
        for (appWidgetId in appWidgetIds) {
            store.deleteInstance(appWidgetId)
        }
        when (val result = store.readInstancesResult()) {
            // A failed read is not proof that the launcher removed every
            // instance. Retain recovery without retrying in a receiver.
            WidgetInstanceReadResult.Failed -> WidgetRefresh.schedulePeriodic(context)
            // The last instance is gone: cancel the periodic tick, the queued
            // refreshes and the pending redraw together. A link still queued
            // for a removed source skips it, because no instance shows it.
            is WidgetInstanceReadResult.Read -> if (result.instances.isEmpty()) WidgetRefresh.cancelAll(context)
        }
    }

    override fun onEnabled(context: Context) {
        WidgetRefresh.schedulePeriodic(context)
    }

    override fun onDisabled(context: Context) {
        // Cancelling here as well as in onDeleted is what keeps a device with
        // no Weather Widget from polling the weather forever.
        WidgetRefresh.cancelAll(context)
    }

    /**
     * Re-attaches restored instances to their saved choice.
     *
     * A launcher restore hands back fresh ids with no configuration: the
     * settings Activity is not run, and without this the Widget would come back
     * blank. The choice is *moved* by position — the pairing the framework
     * itself defines — and the old row is deleted, because a row left behind
     * keeps its source alive.
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
                WidgetLog.info(context, "restored instance ${newWidgetIds[index]} from ${oldWidgetIds[index]}")
            }
        }
        // Drops any row the launcher did not hand back, then redraws. The ids
        // just restored are kept regardless: a launcher does not always report
        // them through `getAppWidgetIds` by the time this runs.
        WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Restored, keepIds = newWidgetIds.toSet())
    }

    /**
     * The "update now" tap: an explicit broadcast to this receiver, carrying
     * only the instance id. The button is disabled while its request is queued
     * or running, which is the throttle.
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
        WidgetRefresh.request(context, WidgetRefresh.Reason.Tap, address, manual = true)
        WidgetUpdater.updateAddress(context, address)
    }
}
