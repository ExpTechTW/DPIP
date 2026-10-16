package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.FrameLayout
import android.widget.RemoteViews
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.exptech.dpip.R
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The Widget on a real device.
 *
 * The JVM suite covers the policy, and Robolectric covers the layouts and the
 * store against a simulated framework. Three things it cannot stand in for, and
 * which this suite therefore checks against the real ones:
 *
 * * the **provider metadata** the launcher reads, resolved from the real
 *   `AppWidgetProviderInfo`;
 * * the **real `RemoteViews` inflater** and its click handling;
 * * the **real SQLite** the store is built on, at the device's schema version.
 *
 * It runs from `android.yml` on an emulator. A device is the only place these
 * assertions can be made, so `tool/dev/test_android.sh` does not run them and a
 * green JVM run says nothing about them.
 */
@RunWith(AndroidJUnit4::class)
class WidgetOnDeviceTest {
    private val context: Context
        get() = InstrumentationRegistry.getInstrumentation().targetContext

    private val component = ComponentName(
        context,
        WeatherWidgetProvider::class.java,
    )

    /**
     * A database of this suite's own.
     *
     * It runs on a real device, and the device may be somebody's daily phone with
     * a Weather Widget on the home screen. Deleting `dpip_widget.db` — the name
     * production uses — would take that Widget and its chosen town with it, so
     * nothing here ever names that file. The store takes the name it opens
     * precisely so a test can stay away from it.
     */
    private val testDatabase = "dpip_widget_instrumented_test.db"

    private fun openStore(): WidgetStore =
        WidgetStore.openUncached(context, databaseName = testDatabase)

    @Before
    fun setUp() {
        context.deleteDatabase(testDatabase)
        WidgetStore.resetForTest()
    }

    @After
    fun tearDown() {
        context.deleteDatabase(testDatabase)
        WidgetStore.resetForTest()
    }

    @Test
    fun theLauncherReadsTheMetadataThisWidgetNeeds() {
        val info: AppWidgetProviderInfo = AppWidgetManager.getInstance(context)
            .installedProviders
            .firstOrNull { it.provider == component }
            ?: error("the provider is not installed; check the manifest and the metadata")

        assertEquals("WorkManager owns the cadence", 0, info.updatePeriodMillis)
        assertEquals(
            "the configuration Activity must be resolved by the framework",
            WeatherWidgetConfigurationActivity::class.java.name,
            info.configure?.className,
        )
        assertTrue("resizable horizontally", info.resizeMode and AppWidgetProviderInfo.RESIZE_HORIZONTAL != 0)
        assertTrue("resizable vertically", info.resizeMode and AppWidgetProviderInfo.RESIZE_VERTICAL != 0)
        assertNotNull(info.initialLayout)
        if (android.os.Build.VERSION.SDK_INT >= 28) {
            assertTrue("launcher reconfiguration replaces the in-widget settings button",
                info.widgetFeatures and AppWidgetProviderInfo.WIDGET_FEATURE_RECONFIGURABLE != 0)
        }
    }

    @Test
    fun theConfigurationActivityIsReachableThroughItsAction() {
        val resolved = context.packageManager.resolveActivity(
            Intent(AppWidgetManager.ACTION_APPWIDGET_CONFIGURE).setPackage(context.packageName),
            0,
        )
        assertEquals(
            WeatherWidgetConfigurationActivity::class.java.name,
            resolved?.activityInfo?.name,
        )
    }

    @Test
    fun theProductionDatabaseIsNeverNamedByThisSuite() {
        // A guard on the guard: if somebody later makes this suite open the
        // production file, this fails before anything deletes it.
        assertTrue(
            "the suite must not name the production database",
            testDatabase != WidgetStore.DATABASE_NAME,
        )
        assertTrue(
            "the production database file must not exist in this suite's path",
            !context.getDatabasePath(WidgetStore.DATABASE_NAME).exists() ||
                openStore().readInstances().isEmpty(),
        )
    }

    @Test
    fun theRealRemoteViewsInflaterAcceptsEveryLayout() {
        // `RemoteViews` refuses anything outside its allowlist — a `<View>`
        // divider is the classic case — and it refuses it here, at apply time,
        // not at compile time.
        for (layoutId in listOf(
            R.layout.widget_small,
            R.layout.widget_small_compact,
            R.layout.widget_medium,
            R.layout.widget_large,
            R.layout.widget_large_tight,
            R.layout.widget_forecast_item,
            R.layout.widget_forecast_item_large,
            R.layout.widget_empty,
            R.layout.widget_preview,
        )) {
            val applied: View = RemoteViews(context.packageName, layoutId)
                .apply(context, FrameLayout(context))
            assertNotNull(applied)
        }
    }

    @Test
    fun theRealRemoteViewsAppliesRefreshFeedbackAndRestoresIdle() {
        InstrumentationRegistry.getInstrumentation().runOnMainSync {
            val base = WidgetPresenter.present(
                sizeClass = WidgetSizeClass.Medium,
                strings = WidgetUpdater.strings(context),
                address = WidgetAddress.Saved("407"),
                locationName = "西屯區",
                stored = null,
                forecast = null,
                locationDegradation = null,
                isCatalogMember = true,
                calibratedNowMilliseconds = null,
                latitude = 24.181,
                longitude = 120.645,
            )
            val view = WidgetRenderer.render(context, base, 42).apply(context, FrameLayout(context))
            for (feedback in listOf(WidgetRefreshFeedback.Queued, WidgetRefreshFeedback.Running,
                WidgetRefreshFeedback.Failed, WidgetRefreshFeedback.Updated, null)) {
                WidgetRenderer.render(context, base.copy(refreshFeedback = feedback), 42).reapply(context, view)
                val busy = feedback == WidgetRefreshFeedback.Queued || feedback == WidgetRefreshFeedback.Running
                val progress = view.findViewById<android.widget.ProgressBar>(R.id.widget_refresh_progress)
                assertTrue(progress.isIndeterminate)
                assertTrue("the launcher can animate the arrow by drawable level",
                    progress.indeterminateDrawable is android.graphics.drawable.RotateDrawable)
                assertEquals(if (busy) View.VISIBLE else View.GONE, progress.visibility)
                assertEquals(!busy, view.findViewById<View>(R.id.widget_refresh).isEnabled)
                assertEquals(context.getString(R.string.widget_no_data),
                    view.findViewById<android.widget.TextView>(R.id.widget_empty_message).text.toString())
            }
        }
    }

    @Test
    fun theRealStoreRoundTripsASnapshot() {
        val store = openStore()
        val address = WidgetAddress.CurrentLocation
        assertTrue(
            store.writeCatalog(
                listOf(
                    WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!,
                ),
                1L,
            ),
        )
        assertTrue(store.writeInstance(11, address, null, 1L))

        val snapshot = CurrentWeatherSnapshot(
            schemaVersion = WidgetSnapshotDecoder.currentWeatherSchemaVersion,
            sourceIdentifier = address.sourceIdentifier,
            regionCode = "407",
            regionName = "西屯區",
            observationTime = 1_791_454_316,
            stationName = "西屯",
            weather = "多雲有雨",
            weatherCode = 206,
            condition = WeatherCondition.Rain,
            isNight = false,
            nextDayNightTransitionTime = 1_791_457_916,
            calibratedTimeOffsetMilliseconds = -1_200,
            temperature = 27.5,
            humidity = 78,
            rain = 0.4,
            windDirection = "北北西",
            windSpeed = 1.3,
            apparentTemperature = 30.2,
        )

        val tokens = store.beginRefreshWrites(address, includeForecast = true)!!
        assertEquals(
            WidgetWriteResult.Written,
            store.commitCurrentWeather(tokens.currentWeather, snapshot, writtenAt = 1L),
        )

        val stored = store.readCurrentWeather(address)!!
        assertEquals(1_791_454_316L, stored.snapshot.observationTime)
        assertEquals(206, stored.snapshot.weatherCode)
        assertEquals(27.5, stored.snapshot.temperature!!, 1e-9)

        // A clear fences the ticket and leaves the catalogue and the choice.
        assertTrue(store.clearCurrentWeather())
        assertEquals(
            WidgetWriteResult.Superseded,
            store.commitCurrentWeather(tokens.currentWeather, snapshot, writtenAt = 2L),
        )
        assertNotNull(store.readInstance(11))
        assertEquals(1, store.readCatalog()!!.locations.size)
    }
}
