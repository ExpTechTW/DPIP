package com.exptech.dpip.widget

import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.os.Build
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import com.exptech.dpip.R
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.util.Locale

/** Small/Tall regressions reproduced with the launcher's actual RemoteViews. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [26, 35], qualifiers = "420dpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WidgetSmallTallRegressionTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val instanceId = 42
    private val taipei = ZoneOffset.ofHours(8)

    private fun atTaipei(hour: Int, minute: Int): Long =
        LocalDateTime.of(2026, 10, 12, hour, minute).toInstant(taipei).toEpochMilli()

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        val store = WidgetStore.open(context)
        store.writeCatalog(
            listOf(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!),
            1L,
        )
        store.writeInstance(instanceId, WidgetAddress.Saved("407"), "407", 1L)
        store.commitCurrentWeather(
            store.beginCurrentWeatherWrite(WidgetAddress.Saved("407"))!!,
            CurrentWeatherSnapshot(
                schemaVersion = 7,
                sourceIdentifier = "region:407",
                regionCode = "407",
                regionName = "西屯區",
                observationTime = atTaipei(14, 5) / 1_000,
                stationName = "西屯",
                weather = "多雲有雨",
                weatherCode = 206,
                condition = WeatherCondition.Rain,
                isNight = false,
                nextDayNightTransitionTime = atTaipei(18, 0) / 1_000,
                calibratedTimeOffsetMilliseconds = 0,
                temperature = 27.5,
                humidity = 78,
                rain = 0.4,
                windDirection = "北北西",
                windSpeed = 1.3,
                apparentTemperature = 30.2,
            ),
            writtenAt = 1L,
        )
        store.commitForecast(
            token = store.beginForecastWrite(WidgetAddress.Saved("407"))!!,
            forecast = ForecastSnapshot(
                schemaVersion = 1,
                sourceIdentifier = "region:407",
                regionCode = "407",
                updateTime = atTaipei(14, 10),
                receivedAt = atTaipei(14, 10),
                points = listOf(
                    ForecastPoint("15:00", 27.0, "多雲", 200, 20),
                    ForecastPoint("16:00", 26.0, "多雲", 200, 30),
                    ForecastPoint("17:00", 25.0, "多雲有雨", 206, 60),
                    ForecastPoint("18:00", 24.0, "多雲有雨", 206, 70),
                    ForecastPoint("19:00", 24.0, "多雲", 200, 40),
                ),
            ),
            receivedCalibratedMilliseconds = atTaipei(14, 10),
            expiresAtMilliseconds = atTaipei(15, 0),
            writtenAt = 1L,
        )
        WidgetClock.installForTest(atTaipei(14, 20), android.os.SystemClock.elapsedRealtime())
    }

    @After
    fun tearDown() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        WidgetUpdater.resetOptionsProvider()
        WidgetClock.invalidate()
    }

    private fun configured(locale: String = "zh-TW", scale: Float = 1f): Context =
        context.createConfigurationContext(Configuration(context.resources.configuration).apply {
            setLocale(Locale.forLanguageTag(locale))
            fontScale = scale
        })

    private fun presentation(c: Context, width: Int, height: Int, state: String = "fresh"): WidgetPresentation {
        val base = WidgetUpdater.presentation(c, instanceId, width, height)
        return when (state) {
            "fresh" -> base
            "stale" -> base.copy(isStale = true, badgeText = c.getString(R.string.widget_stale))
            "queued" -> base.copy(refreshFeedback = WidgetRefreshFeedback.Queued)
            "running" -> base.copy(refreshFeedback = WidgetRefreshFeedback.Running)
            "failed" -> base.copy(refreshFeedback = WidgetRefreshFeedback.Failed)
            "temporary-location" -> WidgetPresenter.present(
                sizeClass = base.sizeClass,
                strings = WidgetUpdater.strings(c),
                address = WidgetAddress.CurrentLocation,
                locationName = base.locationName,
                stored = WidgetStore.open(c).readCurrentWeather(WidgetAddress.Saved("407")),
                forecast = null,
                locationDegradation = WidgetLocationDegradation.Unavailable,
                isCatalogMember = true,
                calibratedNowMilliseconds = atTaipei(14, 20),
                latitude = 24.181,
                longitude = 120.645,
                availableWidthDp = width,
                availableHeightDp = height,
                fontScale = c.resources.configuration.fontScale,
            )
            else -> error("Unknown fixture state: $state")
        }
    }

    private fun measure(c: Context, p: WidgetPresentation, view: View) {
        val density = c.resources.displayMetrics.density
        val width = (p.availableWidthDp * density).toInt()
        val height = (p.availableHeightDp * density).toInt()
        view.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, width, height)
    }

    private fun apply(c: Context, p: WidgetPresentation): View =
        WidgetRenderer.render(c, p, instanceId).apply(c, FrameLayout(c)).also { measure(c, p, it) }

    private fun assertIcon(c: Context, view: View, dp: Int) {
        val icon = view.findViewById<ImageView>(R.id.widget_icon)
        val pixels = (dp * c.resources.displayMetrics.density + 0.5f).toInt()
        assertEquals("icon width for ${dp}dp", pixels, icon.width)
        assertEquals("icon height for ${dp}dp", pixels, icon.height)
    }

    private fun writePreview(name: String, view: View) {
        val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
        try {
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.parseColor("#DDE3EA"))
            view.draw(canvas)
            assertTrue("preview must contain rendered content", (0 until bitmap.height step 4).any { y ->
                (0 until bitmap.width step 4).any { x -> bitmap.getPixel(x, y) != bitmap.getPixel(0, 0) }
            })
            val directory = File("build/widget-small-tall-regressions").apply { mkdirs() }
            File(directory, "$name-api${Build.VERSION.SDK_INT}.png").outputStream().use {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        } finally {
            bitmap.recycle()
        }
    }

    @Test
    fun smallAndTallKeepApprovedIconSizes() {
        val c = configured()
        for ((height, layout, iconDp) in listOf(
            Triple(172, R.layout.widget_small, 36),
            Triple(240, R.layout.widget_small_tall, 52),
        )) {
            val p = presentation(c, 120, height)
            assertEquals(layout, WidgetRenderer.layoutFor(p))
            val view = apply(c, p)
            assertIcon(c, view, iconDp)
            WidgetTextVisibility.assertTree("Small $height", view)
            writePreview("small-$height", view)
        }
    }

    @Test
    fun largeAndPreviewKeepOriginal28dpIcons() {
        val c = configured()
        for ((height, layout) in listOf(320 to R.layout.widget_large_tight, 344 to R.layout.widget_large)) {
            val p = presentation(c, 200, height)
            assertEquals(layout, WidgetRenderer.layoutFor(p))
            val view = apply(c, p)
            assertIcon(c, view, 28)
            WidgetTextVisibility.assertTree("Large $height fresh", view)
            writePreview("large-$height-fresh", view)
        }
        val preview = LayoutInflater.from(c).inflate(R.layout.widget_preview, FrameLayout(c), false)
        val icon = preview.findViewById<ImageView>(R.id.widget_icon)
        val pixels = (28 * c.resources.displayMetrics.density + 0.5f).toInt()
        assertEquals(pixels, icon.layoutParams.width)
        assertEquals(pixels, icon.layoutParams.height)
    }

    @Test
    fun largeTightStaleConditionRemainsWhole() {
        val c = configured()
        val p = presentation(c, 200, 320, "stale")
        assertEquals(R.layout.widget_large_tight, WidgetRenderer.layoutFor(p))
        val view = apply(c, p)
        val condition = view.findViewById<TextView>(R.id.widget_weather)
        assertEquals("多雲有雨", condition.text.toString())
        // F4's separate forecast height defect is outside this horizontal regression.
        WidgetTextVisibility.assertVisible("Large Tight stale condition", condition)
        assertEquals(32f, condition.textSize, 0f)
        writePreview("large-tight-stale", view)
    }

    @Test
    fun thaiStatusGlyphsFitAtSupportedFontScales() {
        for (scale in listOf(1f, 1.3f, 2f)) {
            val c = configured("th", scale)
            // Preserve the original QA reproductions and stay in the actual
            // Standard/Tall size classes after effective-size division.
            val boxes = if (scale == 1f) listOf(119 to 173, 121 to 241)
                else listOf((120 * scale).toInt() to (173 * scale).toInt(),
                    (120 * scale).toInt() to (240 * scale).toInt())
            for ((index, box) in boxes.withIndex()) {
                for (state in listOf("fresh", "stale", "temporary-location", "queued", "running", "failed")) {
                    val p = presentation(c, box.first, box.second, state)
                    val label = "Thai $scale ${box.first}x${box.second} $state"
                    assertEquals(label, if (index == 0) R.layout.widget_small else R.layout.widget_small_tall,
                        WidgetRenderer.layoutFor(p))
                    val view = apply(c, p)
                    // Keep native raster/ancestor assertions on all displayed
                    // glyphs, including long messages with existing end ellipsis.
                    WidgetTextVisibility.assertTree(label, view)
                    for (id in listOf(R.id.widget_temperature, R.id.widget_observation_time,
                        R.id.widget_humidity_value, R.id.widget_rain_value)) {
                        WidgetTextVisibility.assertVisible(label, view.findViewById(id))
                    }
                    val badge = view.findViewById<TextView>(R.id.widget_stale)
                    assertEquals(if (p.badgeText == null) View.GONE else View.VISIBLE, badge.visibility)
                    if (badge.visibility == View.VISIBLE) {
                        assertEquals(p.badgeText, badge.text.toString())
                        WidgetTextVisibility.assertVisible(label, badge,
                            allowEllipsis = state == "temporary-location")
                    }
                    assertRefresh(view, state)
                    writePreview("thai-$scale-$index-$state", view)
                }
                // Also raster-check the entire location message without
                // ellipsis in a wider box of the SAME selected Small layout.
                val wide = presentation(c, (199 * scale).toInt(), box.second, "temporary-location")
                val wideView = apply(c, wide)
                assertEquals(WidgetRenderer.layoutFor(presentation(c, box.first, box.second)),
                    WidgetRenderer.layoutFor(wide))
                WidgetTextVisibility.assertTree("Thai full location $scale $index", wideView)
                WidgetTextVisibility.assertVisible("Thai full location $scale $index",
                    wideView.findViewById(R.id.widget_stale))
            }
        }
    }

    private fun assertRefresh(view: View, state: String) {
        val busy = state == "queued" || state == "running"
        val visible = state != "fresh"
        val actionable = visible && !busy
        val refresh = view.findViewById<View>(R.id.widget_refresh)
        assertEquals("$state refresh visibility", if (visible) View.VISIBLE else View.GONE, refresh.visibility)
        assertEquals("$state enabled", actionable, refresh.isEnabled)
        assertEquals("$state click listener", actionable, refresh.hasOnClickListeners())
        assertEquals("$state progress", if (busy) View.VISIBLE else View.GONE,
            view.findViewById<View>(R.id.widget_refresh_progress).visibility)
        assertEquals("$state icon", if (busy) View.GONE else View.VISIBLE,
            view.findViewById<View>(R.id.widget_refresh_icon).visibility)
    }

    @Test
    fun tallSelectionAndRemoteViewsApplyRespectBoundaries() {
        for ((scale, heights) in listOf(1f to listOf(239, 240, 241),
            1.3f to listOf(311, 312, 313), 2f to listOf(479, 480, 481))) {
            val c = configured(scale = scale)
            for ((index, height) in heights.withIndex()) {
                val p = presentation(c, (199 * scale).toInt(), height)
                val expected = if (index == 0) R.layout.widget_small else R.layout.widget_small_tall
                val remote = WidgetRenderer.render(c, p, instanceId)
                assertEquals(expected, remote.layoutId)
                val view = remote.apply(c, FrameLayout(c))
                measure(c, p, view)
                assertIcon(c, view, if (index == 0) 36 else 52)
                assertEquals("14:05", view.findViewById<TextView>(R.id.widget_observation_time).text.toString())
                assertEquals("2026/10/12 14:05",
                    view.findViewById<View>(R.id.widget_observation_time).contentDescription.toString())
                WidgetTextVisibility.assertTree("boundary $scale $height", view)
            }
            assertEquals(R.layout.widget_small_compact,
                WidgetRenderer.layoutFor(presentation(c, (110 * scale).toInt(), heights[1])))
            val medium = presentation(c, (200 * scale).toInt(), heights[1])
            assertEquals(R.layout.widget_medium, WidgetRenderer.layoutFor(medium))
            val view = apply(c, medium)
            WidgetTextVisibility.assertTree("Medium $scale", view)
            writePreview("medium-$scale", view)
        }
    }

    @Test
    fun refreshTransitionsClearOldActionsWhenReapplied() {
        val c = configured("th")
        for (height in listOf(173, 241)) {
            val initial = presentation(c, 121, height)
            val view = apply(c, initial)
            for (state in listOf("stale", "queued", "running", "failed", "fresh", "temporary-location", "fresh")) {
                val p = presentation(c, 121, height, state)
                WidgetRenderer.render(c, p, instanceId).reapply(c, view)
                measure(c, p, view)
                assertRefresh(view, state)
                WidgetTextVisibility.assertTree("reapply $height $state", view)
            }
            assertFalse(view.findViewById<View>(R.id.widget_refresh).performClick())
        }
    }
}
