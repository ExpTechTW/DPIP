package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import androidx.work.ListenableWorker
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.testing.WorkManagerTestInitHelper
import androidx.work.workDataOf
import com.exptech.dpip.R
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.util.concurrent.TimeUnit

/** Observe the manager's submitted face, not WidgetUpdater.render's return value. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [26, 35])
class WidgetSubmissionWiringTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val manager: AppWidgetManager get() = AppWidgetManager.getInstance(context)
    private val a = WidgetAddress.Saved("407")
    private val b = WidgetAddress.Saved("100")
    private lateinit var store: WidgetStore

    @Before fun setUp() {
        WidgetStore.resetForTest()
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        store = WidgetStore.open(context)
        WidgetUpdater.resetOptionsProvider()
        WidgetClock.invalidate()
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
        assertTrue(store.writeCatalog(listOf(
            WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!,
            WidgetCatalogLocation.create("100", "中正區", "臺北市", 25.032, 121.518)!!,
        ), 1L))
        bind(11, a)
        bind(12, b)
        cache(a, "西屯區", 27.0)
        cache(b, "中正區", 19.0)
    }

    @After fun tearDown() {
        WorkManager.getInstance(context).cancelAllWork().result.get(5, TimeUnit.SECONDS)
        WeatherWidgetRefreshWorker.resetRefresher()
        WidgetUpdater.resetOptionsProvider()
        WidgetClock.invalidate()
        WidgetStore.resetForTest()
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
    }

    private fun bind(id: Int, address: WidgetAddress.Saved) {
        shadowOf(manager).addBoundWidget(id, AppWidgetProviderInfo().apply {
            provider = ComponentName(context, WeatherWidgetProvider::class.java)
        })
        manager.updateAppWidgetOptions(id, options(180, 160))
        assertTrue(store.writeInstance(id, address, address.regionCode, 1L))
    }

    private fun options(width: Int, height: Int) = Bundle().apply {
        putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, width)
        putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, width)
        putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, height)
        putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, height)
        if (Build.VERSION.SDK_INT >= 31) {
            putParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES,
                arrayListOf(SizeF(width.toFloat(), height.toFloat())))
        }
    }

    private fun cache(address: WidgetAddress.Saved, name: String, temperature: Double) {
        val previous = store.readCurrentWeather(address)?.snapshot?.observationTime ?: 1_791_454_316L
        assertEquals(WidgetWriteResult.Written, store.commitCurrentWeather(
            checkNotNull(store.beginCurrentWeatherWrite(address)),
            CurrentWeatherSnapshot(
                schemaVersion = 7, sourceIdentifier = address.sourceIdentifier,
                regionCode = address.regionCode, regionName = name,
                observationTime = previous + 60, stationName = name,
                weather = "晴", weatherCode = 100, condition = WeatherCondition.Clear,
                isNight = false, nextDayNightTransitionTime = previous + 3_600,
                calibratedTimeOffsetMilliseconds = 0, temperature = temperature,
                humidity = 60, rain = 0.0, windDirection = null,
                windSpeed = null, apparentTemperature = null,
            ), writtenAt = 1L,
        ))
    }

    private fun submitted(id: Int): View = checkNotNull(shadowOf(manager).getViewFor(id)) {
        "production must submit RemoteViews for widget $id"
    }

    private fun text(id: Int, viewId: Int): String =
        submitted(id).findViewById<TextView>(viewId).text.toString()

    private fun requests(address: WidgetAddress): List<WorkInfo> = WorkManager.getInstance(context)
        .getWorkInfosForUniqueWork(WidgetRefreshScheduler.sourceWorkName(address))
        .get(5, TimeUnit.SECONDS)

    private fun resize(id: Int, width: Int, height: Int) {
        val options = options(width, height)
        // Bound widgets have no provider object in this shadow: emulate the host's
        // options write, then call the production callback explicitly.
        manager.updateAppWidgetOptions(id, options)
        WeatherWidgetProvider().onAppWidgetOptionsChanged(context, manager, id, options)
    }

    @Test fun `updateInstance submits the exact instance weather to the manager`() {
        WidgetUpdater.updateInstance(context, 11)
        WidgetUpdater.updateInstance(context, 12)
        assertEquals("西屯區", text(11, R.id.widget_location))
        assertEquals("27°", text(11, R.id.widget_temperature))
        assertEquals("中正區", text(12, R.id.widget_location))
        assertEquals("19°", text(12, R.id.widget_temperature))
    }

    @Test fun `source scoped cache only worker changes A submitted face but leaves B untouched`() {
        WidgetUpdater.updateInstance(context, 11)
        WidgetUpdater.updateInstance(context, 12)
        cache(a, "西屯新觀測", 30.0)
        cache(b, "中正未提交", 15.0)
        WeatherWidgetRefreshWorker.refresher = { _, _, _, _, _ ->
            error("cache-only work must not acquire weather")
        }
        val worker = TestListenableWorkerBuilder<WeatherWidgetRefreshWorker>(context)
            .setInputData(workDataOf(
                WeatherWidgetRefreshWorker.KEY_LOCAL_ONLY to true,
                WeatherWidgetRefreshWorker.KEY_SOURCE to a.sourceIdentifier,
            )).build()
        assertTrue(worker.doWork() is ListenableWorker.Result.Success)
        assertEquals("西屯新觀測", text(11, R.id.widget_location))
        assertEquals("30°", text(11, R.id.widget_temperature))
        assertEquals("中正區", text(12, R.id.widget_location))
        assertEquals("19°", text(12, R.id.widget_temperature))
        // Prove B really has new cached data, rather than vacuously asserting
        // that a source with nothing to change remained unchanged.
        WidgetUpdater.updateInstance(context, 12)
        assertEquals("中正未提交", text(12, R.id.widget_location))
        assertEquals("15°", text(12, R.id.widget_temperature))
    }

    @Test fun `resize callback submits medium and large faces and requests only their source`() {
        WidgetUpdater.updateInstance(context, 11)
        assertNull(submitted(11).findViewById<View>(R.id.widget_forecast_container))
        resize(11, 300, 200)
        assertNotNull(submitted(11).findViewById<View>(R.id.widget_forecast_container))
        assertNull(submitted(11).findViewById<View>(R.id.widget_grid_station_value))
        assertTrue(store.hasForecastDemand(a))
        assertTrue(requests(a).any { it.state == WorkInfo.State.ENQUEUED })
        assertTrue(requests(b).isEmpty())
        resize(11, 300, 400)
        assertNotNull(submitted(11).findViewById<View>(R.id.widget_grid_station_value))
        assertEquals("西屯區", text(11, R.id.widget_location))
        resize(11, 180, 160)
        assertNull(submitted(11).findViewById<View>(R.id.widget_forecast_container))
        assertTrue("downsize must not erase unserved demand", store.hasForecastDemand(a))
    }

    @Test fun `downsizing one instance still requests forecast for another wide instance of its source`() {
        bind(13, a)
        manager.updateAppWidgetOptions(13, options(300, 240))
        assertFalse(store.hasForecastDemand(a))
        resize(11, 180, 160)
        assertNull(submitted(11).findViewById<View>(R.id.widget_forecast_container))
        assertTrue(store.hasForecastDemand(a))
        assertTrue(requests(a).any { it.state == WorkInfo.State.ENQUEUED })
        assertTrue(requests(b).isEmpty())
    }

    @Test fun `compact only resize redraws without creating forecast demand or refresh work`() {
        resize(11, 180, 160)
        assertEquals("西屯區", text(11, R.id.widget_location))
        assertFalse(store.hasForecastDemand(a))
        assertTrue(requests(a).isEmpty())
        assertTrue(requests(b).isEmpty())
    }
}
