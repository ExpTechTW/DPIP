package com.exptech.dpip.widget

import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Parcel
import android.util.SizeF
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import com.exptech.dpip.R
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File

/**
 * The next-hour rain chart from cache to launcher: what the presenter decides,
 * what the renderer puts in the `RemoteViews`, what the layouts can hold, and
 * the five-minute redraw that keeps it starting at "now".
 *
 * Every failure state must leave the chart area `GONE` — a Widget that draws a
 * chart it cannot vouch for is worse than one that draws the hourly row.
 */
@RunWith(RobolectricTestRunner::class)
// The density the layout tests measure at (`WidgetLayoutFitTest`): at the
// default mdpi Robolectric's fallback font metrics make every line far taller
// than a device draws it.
@Config(sdk = [26, 35], qualifiers = "420dpi")
class WidgetRainChartTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val manager: AppWidgetManager get() = AppWidgetManager.getInstance(context)
    private val address = WidgetAddress.Saved("407")
    private val start = 1_791_454_200L
    private val now = (start + 7 * 60) * 1_000 + 30_000
    private lateinit var store: WidgetStore

    private val strings = WidgetStrings(
        stale = "OUTDATED", noData = "NO DATA", openApp = "OPEN", needsApp = "NEEDS APP",
        reconfigure = "RECONFIGURE", humidity = "H", rain = "R", wind = "W", station = "S",
        sunrise = "UP", sunset = "DOWN", apparent = "FEELS", currentLocation = "HERE",
        locationDisabled = "OFF", locationUnavailable = "UNAVAILABLE", locationOutside = "OUTSIDE",
    )

    @Before
    fun setUp() {
        WidgetStore.resetForTest()
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        store = WidgetStore.open(context)
        WidgetUpdater.resetOptionsProvider()
        WidgetClock.installForTest(now, android.os.SystemClock.elapsedRealtime())
        assertTrue(store.writeCatalog(listOf(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!), 1L))
    }

    @After
    fun tearDown() {
        WidgetUpdater.resetOptionsProvider()
        WidgetClock.invalidate()
        WidgetStore.resetForTest()
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
    }

    private fun trend(vararg leading: Double, startSecond: Long = start) =
        RainHourTrend(startSecond, leading.toList() + List(60 - leading.size) { 0.0 })

    private fun snapshot(regionCode: String = "407", source: String = address.sourceIdentifier) = CurrentWeatherSnapshot(
        schemaVersion = 7, sourceIdentifier = source, regionCode = regionCode, regionName = "西屯區",
        observationTime = now / 1_000 - 600, stationName = "西屯", weather = "陰有雨", weatherCode = 206,
        condition = WeatherCondition.Rain, isNight = false, nextDayNightTransitionTime = now / 1_000 + 7_200,
        calibratedTimeOffsetMilliseconds = 0, temperature = 21.0, humidity = 90, rain = 3.5,
        windDirection = null, windSpeed = null, apparentTemperature = null,
    )

    private fun present(
        rain: StoredRainTrend?,
        sizeClass: WidgetSizeClass = WidgetSizeClass.Medium,
        calibratedNow: Long? = now,
        degradation: WidgetLocationDegradation? = null,
        target: WidgetAddress = address,
    ) = WidgetPresenter.present(
        sizeClass = sizeClass,
        strings = strings,
        address = target,
        locationName = "西屯區",
        stored = StoredCurrentWeather(snapshot(source = target.sourceIdentifier), 1, 1),
        forecast = null,
        locationDegradation = degradation,
        isCatalogMember = true,
        calibratedNowMilliseconds = calibratedNow,
        latitude = 24.181,
        longitude = 120.645,
        availableWidthDp = 300,
        availableHeightDp = 200,
        rain = rain,
    )

    // ── What the presenter decides ──────────────────────────────────────────

    @Test
    fun `the chart starts at now and greys the minutes past the data`() {
        val chart = present(StoredRainTrend("407", trend(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 40.0)))
            .rainChart!!
        // 7.5 minutes after the start: whole minutes, like Dart's inMinutes.
        assertEquals(60, chart.levels.size)
        assertEquals(WidgetPresenter.rainLevel(8.0), chart.levels[0])
        assertEquals("a bar above the ceiling is drawn full", 10_000, chart.levels[1])
        assertEquals(0, chart.levels[2])
        assertEquals(List(7) { null }, chart.levels.takeLast(7))
        assertEquals(53, chart.levels.count { it != null })
        assertEquals(listOf("Now", "10 min", "20 min", "30 min", "40 min", "50 min"), chart.ticks)
        assertEquals("Heavy rain likely to stop in 9 minutes", chart.summary)
    }

    @Test
    fun `data that starts ahead of now is grey until it begins`() {
        val chart = present(StoredRainTrend("407", trend(6.0, startSecond = now / 1_000 + 150))).rainChart!!
        assertEquals(listOf(null, null), chart.levels.take(2))
        assertEquals(WidgetPresenter.rainLevel(6.0), chart.levels[2])
    }

    @Test
    fun `the summary follows the app's grading`() {
        assertEquals("Light showers possible", present(StoredRainTrend("407", trend(4.9))).rainChart!!.summary)
        assertEquals(
            "Light rain continuing for the next hour",
            present(StoredRainTrend("407", RainHourTrend(start, List(60) { 6.0 }))).rainChart!!.summary,
        )
        assertEquals(
            "Heavy rain continuing for the next hour",
            present(StoredRainTrend("407", RainHourTrend(start, List(60) { 16.0 }))).rainChart!!.summary,
        )
    }

    @Test
    fun `nothing is drawn that the Widget cannot vouch for`() {
        val wet = StoredRainTrend("407", trend(8.0))
        assertNotNull(present(wet).rainChart)
        assertNull("no trend", present(null).rainChart)
        assertNull("a dry hour hands the slot back to the hourly row", present(StoredRainTrend("407", trend())).rainChart)
        assertNull("another township", present(StoredRainTrend("100", trend(8.0))).rainChart)
        assertNull("no trusted clock", present(wet, calibratedNow = null).rainChart)
        assertNull("the hour has passed", present(wet, calibratedNow = (start + 3_600) * 1_000).rainChart)
        assertNull("the square layout has no room", present(wet, sizeClass = WidgetSizeClass.Small).rainChart)
        for (degradation in WidgetLocationDegradation.entries) {
            assertNull(
                "an untrusted position ($degradation), outside Taiwan included",
                present(wet, degradation = degradation, target = WidgetAddress.CurrentLocation).rainChart,
            )
        }
    }

    // ── What reaches the launcher ───────────────────────────────────────────

    private fun bind(id: Int, width: Int, height: Int) {
        shadowOf(manager).addBoundWidget(id, AppWidgetProviderInfo().apply {
            provider = ComponentName(context, WeatherWidgetProvider::class.java)
        })
        WidgetUpdater.optionsProvider = { _, _ ->
            Bundle().apply {
                putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, width)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, width)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, height)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, height)
                if (android.os.Build.VERSION.SDK_INT >= 31) {
                    putParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES,
                        arrayListOf(SizeF(width.toFloat(), height.toFloat())))
                }
            }
        }
        assertTrue(store.writeInstance(id, address, "407", 1L))
        assertEquals(WidgetWriteResult.Written, store.commitCurrentWeather(snapshot(), writtenAt = 1L))
    }

    private fun applied(id: Int, width: Int, height: Int): View {
        val view = WidgetUpdater.render(context, manager, id).apply(context, FrameLayout(context))
        val density = context.resources.displayMetrics.density
        val w = (width * density).toInt()
        val h = (height * density).toInt()
        view.measure(View.MeasureSpec.makeMeasureSpec(w, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(h, View.MeasureSpec.EXACTLY))
        view.layout(0, 0, w, h)
        return view
    }

    private fun bars(view: View): List<ImageView> {
        val group = view.findViewById<android.widget.LinearLayout>(R.id.widget_rain_bars)
        return (0 until group.childCount).map { group.getChildAt(it) as ImageView }
    }

    @Test
    fun `a wet hour replaces the hourly row with sixty levelled bars`() {
        bind(11, 300, 200)
        assertTrue(store.commitRainTrend("407", trend(8.0, 40.0), writtenAt = 1L))

        val view = applied(11, 300, 200)

        assertEquals(View.VISIBLE, view.findViewById<View>(R.id.widget_rain_chart).visibility)
        assertEquals(View.GONE, view.findViewById<View>(R.id.widget_forecast_container).visibility)
        val bars = bars(view)
        assertEquals(60, bars.size)
        // Seven whole minutes have passed: the data's first seven are behind us.
        assertEquals(0, bars[0].drawable.level)
        assertEquals(53, bars.count { it.drawable is android.graphics.drawable.ClipDrawable })
        assertEquals(7, bars.count { it.drawable !is android.graphics.drawable.ClipDrawable })
        assertEquals(
            context.getString(R.string.widget_rain_now),
            view.findViewById<TextView>(R.id.widget_rain_tick_0).text.toString(),
        )
        WidgetTextVisibility.assertTree("rain medium", view)
    }

    @Test
    fun `a dry or missing trend keeps the hourly row and hides the chart`() {
        bind(11, 300, 200)
        assertEquals(View.GONE, applied(11, 300, 200).findViewById<View>(R.id.widget_rain_chart).visibility)

        assertTrue(store.commitRainTrend("407", trend(), writtenAt = 1L))
        val view = applied(11, 300, 200)
        assertEquals(View.GONE, view.findViewById<View>(R.id.widget_rain_chart).visibility)
        assertEquals(View.VISIBLE, view.findViewById<View>(R.id.widget_forecast_container).visibility)
    }

    @Test
    fun `the chart fits every wide layout in every widget language`() {
        assertTrue(store.commitRainTrend("407", trend(*DoubleArray(30) { 6.0 }), writtenAt = 1L))
        for ((width, height) in listOf(200 to 170, 320 to 172, 260 to 240, 320 to 300, 340 to 320, 360 to 360)) {
            bind(11, width, height)
            for (locale in listOf("zh-TW", "en", "ja", "ko", "th", "vi", "in", "fil", "zh-CN", "zh-HK", "yue")) {
                val localized = context.createConfigurationContext(
                    android.content.res.Configuration(context.resources.configuration).apply {
                        setLocale(java.util.Locale.forLanguageTag(locale))
                    },
                )
                val view = WidgetUpdater.render(localized, manager, 11).apply(localized, FrameLayout(localized))
                val density = localized.resources.displayMetrics.density
                view.measure(
                    View.MeasureSpec.makeMeasureSpec((width * density).toInt(), View.MeasureSpec.EXACTLY),
                    View.MeasureSpec.makeMeasureSpec((height * density).toInt(), View.MeasureSpec.EXACTLY),
                )
                view.layout(0, 0, (width * density).toInt(), (height * density).toInt())
                assertEquals("$locale ${width}x$height", View.VISIBLE, view.findViewById<View>(R.id.widget_rain_chart).visibility)
                assertTrue("$locale ${width}x$height bars have no height",
                    view.findViewById<View>(R.id.widget_rain_bars).height > 0)
                WidgetTextVisibility.assertTree("$locale ${width}x$height", view)
            }
        }
    }

    @Test
    @Config(sdk = [35])
    fun `sixteen launcher boxes with a chart stay a small parcel`() {
        bind(11, 300, 200)
        assertTrue(store.commitRainTrend("407", trend(*DoubleArray(60) { 12.0 }), writtenAt = 1L))
        val sizes = ArrayList((0 until 16).map { SizeF(260f + it * 8, 180f + it * 12) })
        WidgetUpdater.optionsProvider = { _, _ ->
            Bundle().apply { putParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES, sizes) }
        }
        val parcel = Parcel.obtain()
        try {
            WidgetUpdater.render(context, manager, 11).writeToParcel(parcel, 0)
            // The binder transaction limit is 1 MB and a launcher holds several
            // Widgets' views at once; the bars are actions, not pixels (about
            // 135 KB for the worst case of sixteen boxes, about 8 KB per box).
            assertTrue("parcel was ${parcel.dataSize()} bytes", parcel.dataSize() < 200_000)
        } finally {
            parcel.recycle()
        }
    }

    // ── The five-minute redraw ──────────────────────────────────────────────

    private fun scheduledTicks() = shadowOf(context.getSystemService(AlarmManager::class.java)).scheduledAlarms
        .filter { shadowOf(it.operation).savedIntent.action == WidgetRainTicker.ACTION_TICK }

    @Test
    fun `a rendered chart arms a non-wakeup redraw and a chartless full render cancels it`() {
        bind(11, 300, 200)
        assertTrue(store.commitRainTrend("407", trend(8.0), writtenAt = 1L))

        WidgetUpdater.updateAll(context)

        val tick = scheduledTicks().single()
        assertEquals(AlarmManager.ELAPSED_REALTIME, tick.type)
        val delay = tick.triggerAtMs - android.os.SystemClock.elapsedRealtime()
        assertEquals(WidgetRainTicker.intervalMilliseconds, delay)

        assertTrue(store.commitRainTrend("407", trend(), writtenAt = 2L))
        WidgetUpdater.updateAll(context)
        assertTrue(scheduledTicks().isEmpty())
    }

    @Test
    fun `the tick redraws from the cache and asks for no fetch`() {
        bind(11, 300, 200)
        assertTrue(store.commitRainTrend("407", trend(8.0), writtenAt = 1L))
        androidx.work.testing.WorkManagerTestInitHelper.initializeTestWorkManager(
            context,
            WidgetSchedulingOnlyWorkerFactory.configuration(),
        )

        WeatherWidgetProvider().onReceive(
            context,
            Intent(context, WeatherWidgetProvider::class.java).setAction(WidgetRainTicker.ACTION_TICK),
        )

        assertEquals(View.VISIBLE, shadowOf(manager).getViewFor(11).findViewById<View>(R.id.widget_rain_chart).visibility)
        assertTrue(
            androidx.work.WorkManager.getInstance(context)
                .getWorkInfosForUniqueWork(WidgetRefresh.refreshWorkName).get().isEmpty(),
        )
        assertEquals(1, scheduledTicks().size)
    }

    // ── Every language has the words ────────────────────────────────────────

    @Test
    fun `every widget language carries the rain strings`() {
        val names = listOf(
            "widget_rain_title", "widget_rain_scattered", "widget_rain_light_sustained",
            "widget_rain_light_stopping", "widget_rain_heavy_sustained", "widget_rain_heavy_stopping",
            "widget_rain_now", "widget_rain_minute",
        )
        val res = listOf("src/main/res", "app/src/main/res").map(::File).first { it.isDirectory }
        val files = res.listFiles()!!.filter { it.name.startsWith("values") }
            .map { File(it, "widget_strings.xml") }.filter { it.isFile }
        assertEquals("all eleven widget languages", 11, files.size)
        for (file in files) {
            val text = file.readText()
            for (name in names) {
                assertTrue("${file.parentFile!!.name} lacks $name", text.contains("name=\"$name\""))
            }
            for (name in listOf("widget_rain_light_stopping", "widget_rain_heavy_stopping", "widget_rain_minute")) {
                val value = Regex("name=\"$name\"[^>]*>([^<]*)<").find(text)!!.groupValues[1]
                assertTrue("${file.parentFile!!.name} $name must carry its number", value.contains("%1\$d"))
            }
        }
    }
}
