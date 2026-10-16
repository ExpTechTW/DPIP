package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.widget.RemoteViews
import com.exptech.dpip.R

/**
 * Turns cached state into launcher layouts for each actual content box.
 * Rendering and forecast demand use the same size authority [WidgetSizes].
 */
object WidgetUpdater {

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (id in liveAppWidgetIds(context, manager)) updateInstance(context, manager, id)
    }

    fun updateInstance(context: Context, appWidgetId: Int) {
        updateInstance(context, AppWidgetManager.getInstance(context), appWidgetId)
    }

    private fun updateInstance(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        try {
            manager.updateAppWidget(appWidgetId, render(context, manager, appWidgetId))
        } catch (error: Exception) {
            // A launcher that has already removed the instance throws here; that
            // is not a failure worth propagating into a worker result.
            WidgetLog.warning(
                context,
                "update failed id=$appWidgetId error=${error.logName()}",
            )
        }
    }

    /** The `RemoteViews` for an instance, from the cache only — no network. */
    fun render(context: Context, manager: AppWidgetManager, appWidgetId: Int): RemoteViews {
        val options = optionsOf(manager, appWidgetId)
        val boxes = WidgetSizes.boxes(options)
        fun child(size: android.util.SizeF) = WidgetRenderer.render(
            context, presentation(context, appWidgetId, size.width.toInt(), size.height.toInt()), appWidgetId,
        )
        if (android.os.Build.VERSION.SDK_INT >= 31) {
            return RemoteViews(boxes.associateWith(::child))
        }
        if (boxes.size == 1) return child(boxes.first())
        return RemoteViews(child(WidgetSizes.landscape(boxes)), child(WidgetSizes.portrait(boxes)))
    }

    fun sizeClass(context: Context, appWidgetId: Int): WidgetSizeClass {
        val options = optionsOf(AppWidgetManager.getInstance(context), appWidgetId)
        return WidgetSizes.largestClass(context, options)
    }

    fun presentation(
        context: Context,
        appWidgetId: Int,
        widthDp: Int,
        heightDp: Int,
    ): WidgetPresentation {
        val store = WidgetStore.open(context)
        val fontScale = context.resources.configuration.fontScale
        val sizeClass = WidgetPresenter.sizeClass(widthDp, heightDp, fontScale)
        val instance = store.readInstance(appWidgetId)

        if (instance == null) {
            return WidgetPresenter.present(
                sizeClass = sizeClass,
                strings = strings(context),
                address = null,
                locationName = null,
                stored = null,
                forecast = null,
                locationDegradation = null,
                isCatalogMember = false,
                calibratedNowMilliseconds = WidgetClock.calibratedNowMilliseconds(),
                latitude = null,
                longitude = null,
                availableWidthDp = widthDp,
                availableHeightDp = heightDp,
                fontScale = fontScale,
            )
        }

        val address = instance.address
        val catalogLocation = (address as? WidgetAddress.Saved)
            ?.let { store.findCatalogLocation(it.regionCode) }

        val stored = store.readCurrentWeather(address)
        val regionCode = stored?.snapshot?.regionCode ?: catalogLocation?.regionCode

        // The centroid comes from the catalog for a saved town and from the
        // township directory for a Current Location (the snapshot names the
        // township but does not carry its coordinates).
        val catalogCentroid = catalogLocation?.takeIf { it.regionCode == regionCode }
        val township = if (catalogCentroid == null) {
            regionCode?.let { townshipResolver(context)?.township(it) }
        } else {
            null
        }
        val latitude = catalogCentroid?.latitude ?: township?.latitude
        val longitude = catalogCentroid?.longitude ?: township?.longitude

        val locationName = stored?.snapshot?.regionName
            ?: catalogLocation?.displayName

        val presentation = WidgetPresenter.present(
            sizeClass = sizeClass,
            strings = strings(context),
            address = address,
            locationName = locationName,
            stored = stored,
            forecast = if (sizeClass == WidgetSizeClass.Small) null else store.readForecast(address),
            // A degradation is only meaningful for a position the app resolves
            // itself; a saved town has no fix to distrust.
            locationDegradation = if (address is WidgetAddress.CurrentLocation) {
                store.readLocationState(address)
            } else {
                null
            },
            isCatalogMember = address !is WidgetAddress.Saved || catalogLocation != null,
            // The one trusted instant the presentation is allowed to reason
            // from, from the monotonic anchor rather than the wall clock.
            calibratedNowMilliseconds = WidgetClock.calibratedNowMilliseconds(),
            latitude = latitude,
            longitude = longitude,
            availableWidthDp = widthDp,
            availableHeightDp = heightDp,
            fontScale = fontScale,
        )
        val feedback = store.readRefreshFeedback(address, System.currentTimeMillis())
        return presentation.copy(refreshFeedback = feedback?.state)
    }

    fun strings(context: Context) = WidgetStrings(
        stale = context.getString(R.string.widget_stale),
        noData = context.getString(R.string.widget_no_data),
        openApp = context.getString(R.string.widget_open_app),
        needsApp = context.getString(R.string.widget_needs_app),
        reconfigure = context.getString(R.string.widget_reconfigure),
        humidity = context.getString(R.string.widget_humidity),
        rain = context.getString(R.string.widget_rain),
        wind = context.getString(R.string.widget_wind),
        station = context.getString(R.string.widget_station),
        sunrise = context.getString(R.string.widget_sunrise),
        sunset = context.getString(R.string.widget_sunset),
        apparent = context.getString(R.string.widget_apparent),
        currentLocation = context.getString(R.string.widget_current_location),
        locationDisabled = context.getString(R.string.widget_location_disabled),
        locationUnavailable = context.getString(R.string.widget_location_unavailable),
        locationOutside = context.getString(R.string.widget_location_outside),
    )

    /** Every address some instance is showing, in first-seen order. */
    fun addresses(context: Context): List<WidgetAddress> =
        WidgetStore.open(context).usedAddresses()

    /**
     * Whether any instance for [address] is large enough to draw a forecast.
     *
     * Asked per address rather than per instance because the fetch is shared:
     * a source with one compact and one wide instance is fetched once, and it
     * needs the forecast because the wide one will draw it. A compact-only
     * address never fetches one.
     */
    fun needsForecast(context: Context, address: WidgetAddress): Boolean {
        val store = WidgetStore.open(context)
        return store.readInstances()
            .filter { it.address.sourceIdentifier == address.sourceIdentifier }
            .any { sizeClass(context, it.appWidgetId) != WidgetSizeClass.Small }
    }

    /**
     * Records whether [address] wants a forecast it does not have, and answers
     * whether it does.
     *
     * Called wherever an instance's size can change — a new instance, a resize, a
     * reconfigure — **and on every refresh**, so the answer is re-derived each
     * time rather than remembered once. "Has no forecast" is not the question: a
     * stored forecast can be expired, can belong to the township the device has
     * since left, or can carry no deadline this process is able to verify. Each
     * of those means a fetch is wanted, and asking only about absence is what
     * left a medium widget showing a forecast from the previous hour forever.
     */
    fun refreshForecastDemand(context: Context, address: WidgetAddress): Boolean {
        val store = WidgetStore.open(context)
        val wanted = needsForecast(context, address) && !hasUsableForecast(context, store, address)
        if (wanted) {
            store.setForecastDemand(address, demand = true, updatedAt = System.currentTimeMillis())
        }
        return wanted || store.hasForecastDemand(address)
    }

    /**
     * Whether a refresh for [address] should reserve a forecast ticket at all.
     *
     * Deliberately **not** "is the cached forecast unusable": a wide instance
     * always reserves, because whether the cached forecast is the one *this
     * round's* township needs can only be answered after the position resolves.
     * The cache can only name the township of the previous observation, so a
     * device walking from A to B holds a fresh A forecast that any check against
     * A would call usable — and B would then wait a whole period. The reservation
     * is made here; whether it is spent is decided after the resolve, in
     * `WidgetRefreshService`.
     *
     * The durable demand still counts: a resize can raise it while a compact run
     * is already in flight, and that run has no ticket to spend.
     */
    fun wantsForecast(context: Context, address: WidgetAddress): Boolean {
        val store = WidgetStore.open(context)
        return needsForecast(context, address) || store.hasForecastDemand(address)
    }

    /**
     * Whether the cached forecast is one this Widget may keep showing.
     *
     * Three ways to fail, all of which mean "fetch again":
     *
     * * it belongs to a different township than the address resolves to now — a
     *   Current Location that moved, or a saved town whose code was reused;
     * * its recorded deadline has passed (or has not been reached yet, which is a
     *   clock this process cannot vouch for);
     * * there is no trusted clock at all, so freshness cannot be established.
     */
    fun hasUsableForecast(
        context: Context,
        store: WidgetStore,
        address: WidgetAddress,
    ): Boolean {
        val forecast = store.readForecast(address) ?: return false
        val currentRegion = currentRegionCode(store, address) ?: return false
        if (forecast.regionCode != currentRegion) return false
        val calibratedNow = WidgetClock.calibratedNowMilliseconds() ?: return false
        return calibratedNow < forecast.expiresAtMilliseconds
    }

    /** The township the address would query now, or null when it cannot be said. */
    fun currentRegionCode(store: WidgetStore, address: WidgetAddress): String? = when (address) {
        is WidgetAddress.Saved -> address.regionCode
        WidgetAddress.CurrentLocation -> store.readCurrentWeather(address)?.snapshot?.regionCode
    }

    /** Re-renders every instance of one address from the cache. */
    fun updateAddress(context: Context, address: WidgetAddress) {
        val manager = AppWidgetManager.getInstance(context)
        for (instance in WidgetStore.open(context).readInstances()) {
            if (instance.address.sourceIdentifier == address.sourceIdentifier) {
                updateInstance(context, manager, instance.appWidgetId)
            }
        }
    }

    /** The ids the launcher actually still has for this Widget. */
    fun liveAppWidgetIds(
        context: Context,
        manager: AppWidgetManager = AppWidgetManager.getInstance(context),
    ): IntArray = manager.getAppWidgetIds(
        ComponentName(context, WeatherWidgetProvider::class.java),
    )

    /**
     * Brings the stored instances and the scheduled work back in line.
     *
     * Four things, in order:
     *
     * 1. **Drop rows the launcher no longer has.** A restore, a force-stop or a
     *    launcher crash leaves rows for instances that are gone; they keep a
     *    source "in use" forever, so the Widget keeps polling for a home screen
     *    that does not exist. Reconciling against `AppWidgetManager` is the only
     *    authority on which instances are live — with one exception, [keepIds],
     *    because a restore creates rows for ids the manager may not report yet,
     *    and dropping those would delete exactly what was just restored.
     * 2. **Schedule or cancel the periodic work** from the surviving rows.
     * 3. **Request recovery once per surviving source**, keeping unfinished work,
     *    unless the calling background worker is already about to refresh them.
     * 4. **Redraw** whatever remains.
     *
     * Doing it from the instance table rather than an in-memory counter is what
     * makes it correct after a process death, when there is no counter.
     */
    fun reconcile(
        context: Context,
        keepIds: Set<Int> = emptySet(),
        requestRecovery: Boolean = true,
    ): WidgetInstanceReadResult {
        val store = WidgetStore.open(context)
        val live = liveAppWidgetIds(context).toSet() + keepIds
        val result = store.reconcileInstances(live)
        if (result is WidgetInstanceReadResult.Failed) {
            // Unavailability says nothing about ownership. Keep (or establish)
            // the bounded periodic recovery path, never spin in the receiver.
            WidgetLog.warning(context, "reconcile failed; retaining periodic recovery")
            WidgetRefreshScheduler.schedulePeriodic(context)
            return result
        }
        result as WidgetInstanceReadResult.Read
        if (result.dropped.isNotEmpty()) {
            WidgetLog.info(context, "reconcile dropped ${result.dropped.size} stale instances")
        }

        if (result.instances.isEmpty()) {
            WidgetRefreshScheduler.cancelAll(context)
        } else {
            WidgetRefreshScheduler.schedulePeriodic(context)
            val addresses = result.instances.map { it.address }.distinct()
            for (address in result.dropped.distinct()) {
                if (address !in addresses) WidgetRefreshScheduler.cancelSource(context, address)
            }
            if (requestRecovery) {
                for (address in addresses) {
                    WidgetRefreshScheduler.scheduleRecovery(context, address)
                }
            }
        }
        updateAll(context)
        return result
    }

    /**
     * How an instance's measured size is read.
     *
     * A seam for tests only: `AppWidgetManager.getAppWidgetOptions` is answered
     * by the system service, so under a JVM runner it always comes back empty and
     * every instance would look like the default size. Production never replaces
     * this.
     */
    internal var optionsProvider: (AppWidgetManager, Int) -> Bundle = { manager, id ->
        try {
            manager.getAppWidgetOptions(id)
        } catch (_: Exception) {
            Bundle()
        }
    }

    internal fun resetOptionsProvider() {
        optionsProvider = { manager, id ->
            try {
                manager.getAppWidgetOptions(id)
            } catch (_: Exception) {
                Bundle()
            }
        }
    }

    private fun optionsOf(manager: AppWidgetManager, appWidgetId: Int): Bundle =
        optionsProvider(manager, appWidgetId)

    private fun townshipResolver(context: Context): WidgetTownshipResolver? {
        if (resolverLoaded) return resolver
        synchronized(this) {
            if (!resolverLoaded) {
                resolver = WidgetTownshipResolver.load(context.applicationContext)
                resolverLoaded = true
            }
        }
        return resolver
    }

    // The boundary table is ~700 KB decoded into shapes; decoding it per render
    // would be the most expensive thing this process does. One per process, and
    // `resolverLoaded` distinguishes "not attempted yet" from "attempted and
    // absent", because an asset that failed to load will not appear later.
    @Volatile
    private var resolverLoaded = false

    @Volatile
    private var resolver: WidgetTownshipResolver? = null
}
