package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.util.SizeF
import android.widget.RemoteViews
import com.exptech.dpip.R

/**
 * Turns cached state into launcher layouts for each actual content box.
 * Rendering and the resize check use the same size authority [WidgetSizes].
 */
object WidgetUpdater {

    /**
     * Re-renders every instance the launcher has.
     *
     * The one render that knows every instance, so it is the one that decides
     * whether the rain chart's five-minute redraw keeps running
     * ([WidgetRainTicker]); a partial render can only start it.
     */
    fun updateAll(context: Context) {
        val manager = managerOrNull(context) ?: return
        var chart = false
        for (id in liveAppWidgetIds(context, manager)) chart = updateInstance(context, manager, id) or chart
        if (chart) WidgetRainTicker.arm(context) else WidgetRainTicker.cancel(context)
    }

    fun updateInstance(context: Context, appWidgetId: Int) {
        if (updateInstance(context, managerOrNull(context) ?: return, appWidgetId)) WidgetRainTicker.arm(context)
    }

    /** Re-renders every instance of one address from the cache. */
    fun updateAddress(context: Context, address: WidgetAddress) {
        val manager = managerOrNull(context) ?: return
        var chart = false
        for (instance in WidgetStore.open(context).readInstances()) {
            if (instance.address.sourceIdentifier == address.sourceIdentifier) {
                chart = updateInstance(context, manager, instance.appWidgetId) or chart
            }
        }
        if (chart) WidgetRainTicker.arm(context)
    }

    /**
     * `AppWidgetManager` when the device has one.
     *
     * `getInstance` is documented to return null without `FEATURE_APP_WIDGETS` —
     * Android TV, Automotive, some work profiles. Nothing to draw on such a
     * device is the correct outcome, so this answers null and the callers return.
     */
    private fun managerOrNull(context: Context): AppWidgetManager? =
        AppWidgetManager.getInstance(context)

    /** Submits one instance's views; true when any of its boxes drew a rain chart. */
    private fun updateInstance(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
    ): Boolean {
        return try {
            val (views, chart) = build(context, manager, appWidgetId)
            manager.updateAppWidget(appWidgetId, views)
            chart
        } catch (error: Exception) {
            // A launcher that has already removed the instance throws here; that
            // is not a failure worth propagating into a worker result.
            WidgetLog.warning(context, "update failed id=$appWidgetId error=${error.logName()}")
            false
        }
    }

    /**
     * The `RemoteViews` for an instance, from the cache only — no network.
     *
     * The store is read once per instance; each launcher box then only lays the
     * same data out at its own size, all against one calibrated instant.
     */
    fun render(context: Context, manager: AppWidgetManager, appWidgetId: Int): RemoteViews =
        build(context, manager, appWidgetId).first

    private fun build(context: Context, manager: AppWidgetManager, appWidgetId: Int): Pair<RemoteViews, Boolean> {
        val options = optionsOf(manager, appWidgetId)
        val data = InstanceData.load(context, appWidgetId)
        var chart = false
        fun child(size: SizeF): RemoteViews {
            val presentation = data.present(size.width.toInt(), size.height.toInt())
            if (presentation.rainChart != null) chart = true
            return WidgetRenderer.render(context, presentation, appWidgetId)
        }
        val boxes = WidgetSizes.boxes(options)
        val views = when {
            android.os.Build.VERSION.SDK_INT >= 31 -> RemoteViews(boxes.associateWith(::child))
            boxes.size == 1 -> child(boxes.first())
            // Each rotation by name. Recovering the two from `boxes` by width
            // cannot tell them apart when a launcher reports one width for both
            // — see WidgetSizes.RotationBoxes.
            else -> WidgetSizes.rotationBoxes(options).let { RemoteViews(child(it.landscape), child(it.portrait)) }
        }
        return views to chart
    }

    fun presentation(
        context: Context,
        appWidgetId: Int,
        widthDp: Int,
        heightDp: Int,
    ): WidgetPresentation = InstanceData.load(context, appWidgetId).present(widthDp, heightDp)

    /**
     * Everything one instance's presentation reads, read once.
     *
     * The centroid comes from the catalog for a saved town and from the
     * township directory for a Current Location (the snapshot names the
     * township but does not carry its coordinates).
     */
    private class InstanceData(
        private val context: Context,
        private val address: WidgetAddress?,
        private val locationName: String?,
        private val stored: StoredCurrentWeather?,
        private val forecast: StoredForecast?,
        private val degradation: WidgetLocationDegradation?,
        private val isCatalogMember: Boolean,
        private val latitude: Double?,
        private val longitude: Double?,
        private val feedback: WidgetRefreshFeedback?,
        private val calibratedNowMilliseconds: Long?,
        private val rain: StoredRainTrend? = null,
    ) {
        private val strings = WidgetUpdater.strings(context)
        private val fontScale = context.resources.configuration.fontScale

        fun present(widthDp: Int, heightDp: Int): WidgetPresentation {
            val sizeClass = WidgetPresenter.sizeClass(widthDp, heightDp, fontScale)
            return WidgetPresenter.present(
                sizeClass = sizeClass,
                strings = strings,
                address = address,
                locationName = locationName,
                stored = stored,
                forecast = if (sizeClass == WidgetSizeClass.Small) null else forecast,
                locationDegradation = degradation,
                isCatalogMember = isCatalogMember,
                calibratedNowMilliseconds = calibratedNowMilliseconds,
                latitude = latitude,
                longitude = longitude,
                availableWidthDp = widthDp,
                availableHeightDp = heightDp,
                fontScale = fontScale,
                rain = rain,
            ).copy(refreshFeedback = feedback)
        }

        companion object {
            fun load(context: Context, appWidgetId: Int): InstanceData {
                val store = WidgetStore.open(context)
                // The one trusted instant every box of this render reasons from,
                // from the monotonic anchor rather than the wall clock — restored
                // from disk when this process has just started.
                WidgetClock.attach(context)
                val calibratedNow = WidgetClock.calibratedNowMilliseconds()
                val address = store.readInstance(appWidgetId)?.address
                    ?: return InstanceData(
                        context, null, null, null, null, null,
                        isCatalogMember = false, latitude = null, longitude = null,
                        feedback = null, calibratedNowMilliseconds = calibratedNow,
                    )

                val catalogLookup = (address as? WidgetAddress.Saved)
                    ?.let { store.lookupCatalogLocation(it.regionCode) }
                val catalogLocation = (catalogLookup as? WidgetCatalogLookup.Found)?.location
                val stored = store.readCurrentWeather(address)
                val regionCode = stored?.snapshot?.regionCode ?: catalogLocation?.regionCode
                val catalogCentroid = catalogLocation?.takeIf { it.regionCode == regionCode }
                val township = if (catalogCentroid == null) {
                    regionCode?.let { townshipResolver(context)?.township(it) }
                } else {
                    null
                }
                return InstanceData(
                    context = context,
                    address = address,
                    locationName = stored?.snapshot?.regionName ?: catalogLocation?.displayName,
                    stored = stored,
                    forecast = store.readForecast(address),
                    // A degradation is only meaningful for a position the app
                    // resolves itself; a saved town has no fix to distrust.
                    degradation = if (address is WidgetAddress.CurrentLocation) store.readLocationState(address) else null,
                    // Only a catalog that was *read* and does not contain this
                    // town means the user deleted it. A failed read keeps the
                    // Widget presentable, and keeps the refresh that recovers it.
                    isCatalogMember = catalogLookup !is WidgetCatalogLookup.Absent,
                    latitude = catalogCentroid?.latitude ?: township?.latitude,
                    longitude = catalogCentroid?.longitude ?: township?.longitude,
                    feedback = store.readRefreshFeedback(address, System.currentTimeMillis())?.state,
                    calibratedNowMilliseconds = calibratedNow,
                    rain = stored?.snapshot?.regionCode?.let(store::readRainTrend),
                )
            }
        }
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
        rainScattered = context.getString(R.string.widget_rain_scattered),
        rainLightSustained = context.getString(R.string.widget_rain_light_sustained),
        rainLightStopping = context.getString(R.string.widget_rain_light_stopping),
        rainHeavySustained = context.getString(R.string.widget_rain_heavy_sustained),
        rainHeavyStopping = context.getString(R.string.widget_rain_heavy_stopping),
        rainNow = context.getString(R.string.widget_rain_now),
        rainMinute = context.getString(R.string.widget_rain_minute),
    )

    /**
     * Whether [appWidgetId] now draws a forecast the cache cannot give it.
     *
     * Asked after a resize: a forecast is fetched with every refresh, but an
     * instance that grew into a forecast-drawing size between refreshes should
     * not wait a whole period for one.
     */
    fun needsForecast(context: Context, appWidgetId: Int): Boolean {
        val manager = managerOrNull(context) ?: return false
        if (WidgetSizes.largestClass(context, optionsOf(manager, appWidgetId)) == WidgetSizeClass.Small) return false
        WidgetClock.attach(context)
        val store = WidgetStore.open(context)
        val address = store.readInstance(appWidgetId)?.address ?: return false
        return !hasUsableForecast(store, address)
    }

    /**
     * Whether the cached forecast is one this Widget may keep showing: it
     * belongs to the township the address shows now, and a trusted clock says
     * its recorded deadline has not passed.
     */
    fun hasUsableForecast(store: WidgetStore, address: WidgetAddress): Boolean {
        val forecast = store.readForecast(address) ?: return false
        val currentRegion = when (address) {
            is WidgetAddress.Saved -> address.regionCode
            WidgetAddress.CurrentLocation -> store.readCurrentWeather(address)?.snapshot?.regionCode
        } ?: return false
        if (forecast.regionCode != currentRegion) return false
        val calibratedNow = WidgetClock.calibratedNowMilliseconds() ?: return false
        return calibratedNow < forecast.expiresAtMilliseconds
    }

    /**
     * The ids the launcher actually still has for this Widget. Empty on a device
     * with no `AppWidgetManager` at all — see [managerOrNull].
     */
    fun liveAppWidgetIds(
        context: Context,
        manager: AppWidgetManager? = managerOrNull(context),
    ): IntArray = manager?.getAppWidgetIds(
        ComponentName(context, WeatherWidgetProvider::class.java),
    ) ?: IntArray(0)

    /**
     * How an instance's measured size is read.
     *
     * A seam for tests only: `AppWidgetManager.getAppWidgetOptions` is answered
     * by the system service, so under a JVM runner it always comes back empty.
     */
    internal var optionsProvider: (AppWidgetManager, Int) -> Bundle = ::systemOptions

    internal fun resetOptionsProvider() {
        optionsProvider = ::systemOptions
    }

    private fun systemOptions(manager: AppWidgetManager, appWidgetId: Int): Bundle = try {
        manager.getAppWidgetOptions(appWidgetId)
    } catch (_: Exception) {
        Bundle()
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
