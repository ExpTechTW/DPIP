package com.exptech.dpip.widget

import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import com.exptech.dpip.R
import org.junit.After
import org.junit.Assert.assertEquals
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

/** F4: complete hourly columns through production selection and native RemoteViews. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [26, 35], qualifiers = "420dpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WidgetLargeTightForecastRegressionTest {
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

    /** Adds the study's calibrated TextView offset to the unchanged strict helper. */
    private fun assertNativeInk(label: String, text: TextView, root: View) {
        val layout = text.layout!!
        val offset = org.robolectric.util.ReflectionHelpers.callInstanceMethod<Int>(text, "getVerticalOffset",
            org.robolectric.util.ReflectionHelpers.ClassParameter.from(Boolean::class.javaPrimitiveType, false))
        val bounds = android.graphics.Rect(0, 0, text.width, text.height)
        (root as android.view.ViewGroup).offsetDescendantRectToMyCoords(text, bounds)
        val clip = android.graphics.RectF(bounds)
        var node: View = text
        while (node !== root) {
            val parent = node.parent as android.view.ViewGroup
            val b = android.graphics.Rect(0, 0, parent.width, parent.height)
            if (parent !== root) root.offsetDescendantRectToMyCoords(parent, b)
            if (parent.clipChildren) {
                if (parent.clipToPadding) {
                    b.left += parent.paddingLeft; b.top += parent.paddingTop
                    b.right -= parent.paddingRight; b.bottom -= parent.paddingBottom
                }
                assertTrue("$label ancestor clip", clip.intersect(android.graphics.RectF(b)))
            }
            node = parent
        }
        val guard = text.textSize.toInt().coerceAtLeast(1)
        val width = (0 until layout.lineCount).maxOf { kotlin.math.ceil(layout.getLineRight(it).toDouble()).toInt() }.coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width + guard * 2, layout.height + guard * 2, Bitmap.Config.ARGB_8888)
        try {
            val canvas = Canvas(bitmap)
            canvas.translate(guard.toFloat(), guard.toFloat()); layout.draw(canvas)
            val pixels = IntArray(bitmap.width * bitmap.height)
            bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
            var ink = 0
            for (i in pixels.indices) if (pixels[i] ushr 24 != 0) {
                ink++
                val x = bounds.left + text.compoundPaddingLeft - text.scrollX + i % bitmap.width - guard + 0.5f
                val y = bounds.top + text.extendedPaddingTop + offset - text.scrollY + i / bitmap.width - guard + 0.5f
                assertTrue("$label native glyph ($x,$y) outside $clip", clip.contains(x, y))
            }
            assertTrue("$label must draw ink", ink > 0)
        } finally { bitmap.recycle() }
    }

    private val output get() = File("build/widget-large-tight-forecast").apply { mkdirs() }

    private fun name(p: WidgetPresentation) = context.resources.getResourceEntryName(WidgetRenderer.layoutFor(p))

    private fun record(label: String, p: WidgetPresentation, view: View) {
        fun node(v: View): org.json.JSONObject = org.json.JSONObject().apply {
            put("id", if (v.id == View.NO_ID) "none" else context.resources.getResourceEntryName(v.id))
            put("bounds", org.json.JSONArray(listOf(v.left, v.top, v.right, v.bottom)))
            put("padding", org.json.JSONArray(listOf(v.paddingLeft, v.paddingTop, v.paddingRight, v.paddingBottom)))
            put("visibility", v.visibility)
            (v.layoutParams as? android.view.ViewGroup.MarginLayoutParams)?.let {
                put("margins", org.json.JSONArray(listOf(it.leftMargin, it.topMargin, it.rightMargin, it.bottomMargin)))
            }
            if (v is TextView) {
                put("text", v.text); put("textSize", v.textSize)
                put("required", v.layout?.height); put("available", v.height-v.compoundPaddingTop-v.compoundPaddingBottom)
                put("layoutText", v.layout?.text); put("ellipsis", v.layout?.let { l -> (0 until l.lineCount).sumOf { l.getEllipsisCount(it) } })
            }
            if (v is android.view.ViewGroup) {
                put("clipChildren", v.clipChildren); put("clipToPadding", v.clipToPadding)
                put("children", org.json.JSONArray((0 until v.childCount).map { node(v.getChildAt(it)) }))
            }
        }
        File(output, "measurements-api${Build.VERSION.SDK_INT}.jsonl").appendText(
            org.json.JSONObject().put("case", label).put("layout", name(p)).put("tree", node(view)).toString()+"\n")
    }

    private fun draw(view: View, label: String? = null) {
        val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
        try {
            view.draw(Canvas(bitmap))
            if (label != null) File(output, "$label-api${Build.VERSION.SDK_INT}.png").outputStream().use {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        } finally { bitmap.recycle() }
    }

    private fun check(label: String, p: WidgetPresentation, view: View) {
        val forecast = view.findViewById<android.view.ViewGroup>(R.id.widget_forecast_container)
        assertEquals("$label five columns", 5, forecast.childCount)
        assertEquals(5, p.forecast.size)
        for (i in 0 until 5) {
            val column = forecast.getChildAt(i)
            for ((id, expected) in listOf(R.id.widget_forecast_time to p.forecast[i].time,
                R.id.widget_forecast_temperature to p.forecast[i].temperatureText,
                R.id.widget_forecast_pop to p.forecast[i].popText)) {
                val text = column.findViewById<TextView>(id)
                assertEquals("$label column $i text", expected, text.text.toString())
                if (id == R.id.widget_forecast_pop && expected == "—") {
                    assertEquals(text.context.getString(R.string.widget_forecast_pop_unavailable), text.contentDescription)
                }
                assertTrue("$label column $i usable height", text.height-text.compoundPaddingTop-text.compoundPaddingBottom > 0)
                assertEquals("$label column $i layout text", expected, text.layout.text.toString())
                WidgetTextVisibility.assertVisible("$label column $i $expected", text)
                assertNativeInk("$label column $i $expected", text, view)
            }
            val icon = column.findViewById<ImageView>(R.id.widget_forecast_icon)
            assertTrue("$label column $i icon", icon.visibility == View.VISIBLE && icon.width > 0 && icon.height > 0 && icon.drawable != null)
        }
        WidgetTextVisibility.assertTree(label, view)
        for (id in listOf(R.id.widget_temperature, R.id.widget_weather, R.id.widget_apparent,
            R.id.widget_grid_humidity_value, R.id.widget_grid_rain_value, R.id.widget_grid_wind_value,
            R.id.widget_grid_station_value, R.id.widget_stale)) {
            val text = view.findViewById<TextView>(id)
            if (text != null && text.visibility == View.VISIBLE && text.text.isNotEmpty()) assertNativeInk("$label ${text.text}", text, view)
        }
        val stale = view.findViewById<TextView>(R.id.widget_stale)
        assertEquals(p.badgeText != null, stale.visibility == View.VISIBLE)
        if (p.badgeText != null) assertEquals(p.badgeText, stale.text.toString())
        val refresh = view.findViewById<View>(R.id.widget_refresh)
        val busy = p.refreshFeedback == WidgetRefreshFeedback.Queued || p.refreshFeedback == WidgetRefreshFeedback.Running
        assertEquals(if (p.showRefresh) View.VISIBLE else View.GONE, refresh.visibility)
        assertEquals(p.showRefresh && p.canRefresh && !busy, refresh.isEnabled)
        assertEquals(refresh.isEnabled, refresh.hasOnClickListeners())
        assertEquals(if (busy) View.GONE else View.VISIBLE, view.findViewById<View>(R.id.widget_refresh_icon).visibility)
        assertEquals(if (busy) View.VISIBLE else View.GONE, view.findViewById<View>(R.id.widget_refresh_progress).visibility)
        assertTrue(view.hasOnClickListeners())
    }

    private fun exercise(c: Context, p: WidgetPresentation, label: String, preview: Boolean = false) {
        val view = WidgetRenderer.render(c, p, instanceId).apply(c, FrameLayout(c))
        record("$label applied", p, view)
        measure(c, p, view)
        record("$label first-measure", p, view)
        val failures = mutableListOf<String>()
        try { check("$label first-measure", p, view) } catch (e: AssertionError) { failures += e.message.orEmpty() }
        // Save the first native draw even when the visibility regression fails.
        draw(view, if (preview) label else null)
        record("$label first-draw", p, view)
        try { check("$label first-draw", p, view) } catch (e: AssertionError) { failures += e.message.orEmpty() }
        view.requestLayout(); measure(c, p, view)
        record("$label subsequent-measure", p, view)
        try { check("$label subsequent-measure", p, view) } catch (e: AssertionError) { failures += e.message.orEmpty() }
        assertTrue(failures.joinToString("\n"), failures.isEmpty())
    }

    @Test fun minimumStaleForecastKeepsEveryProbability() {
        val c = configured()
        val p = presentation(c, 200, 320, "stale")
        assertEquals(R.layout.widget_large_tight, WidgetRenderer.layoutFor(p))
        exercise(c, p, "minimum-stale", preview = true)
    }
    @Test fun largeTightBoundariesLocalesScalesAndRefreshStates() {
        val failures = mutableListOf<String>()
        var cases = 0
        val locales = listOf("zh-TW", "en", "ja", "ko", "th", "fil")
        for (locale in locales) for (scale in listOf(1f, 1.3f, 2f)) {
            val c = configured(locale, scale)
            // 336dp Roomy stale has a separately reproduced pre-existing API35 defect;
            // its strict before/after diagnostic is preserved outside the F4 suite.
            // Keep this regression matrix on Tight, Medium, and a 344dp Roomy control.
            for (effectiveHeight in listOf(319, 320, 335, 344)) for (effectiveWidth in listOf(200, 300)) {
                val w = kotlin.math.ceil(effectiveWidth * scale.toDouble()).toInt()
                val h = kotlin.math.ceil(effectiveHeight * scale.toDouble()).toInt()
                for (state in listOf("fresh", "stale", "queued", "running", "failed", "stale-running")) {
                    val p = if (state == "stale-running") presentation(c, w, h, "stale").copy(refreshFeedback = WidgetRefreshFeedback.Running)
                        else presentation(c, w, h, state)
                    val expected = when {
                        p.effectiveHeightDp < 320 && p.effectiveWidthDp < 340 -> R.layout.widget_medium_tall
                        p.effectiveHeightDp < 336 -> R.layout.widget_large_tight
                        else -> R.layout.widget_large
                    }
                    assertEquals("production boundary $w $h $scale", expected, WidgetRenderer.layoutFor(p))
                    val label = "$locale-$w-$h-f$scale-$state"
                    try { exercise(c, p, label, preview = scale == 1f && locale == "zh-TW" && state in listOf("fresh", "stale")) }
                    catch (e: AssertionError) { failures += "$label layout=${name(p)} API=${Build.VERSION.SDK_INT}: ${e.message}" }
                    cases++
                }
            }
        }
        // Physical dimensions at enlarged fonts are intentionally classified by production.
        for (scale in listOf(1.3f, 2f)) for (h in listOf(319, 320, 335, 336)) {
            val c = configured(scale = scale)
            val p = presentation(c, 200, h, "stale")
            assertTrue("unscaled physical box must not be forced Large", p.sizeClass != WidgetSizeClass.Large)
            record("physical-200-$h-f$scale", p, apply(c, p))
        }
        File(output, "matrix-failures-api${Build.VERSION.SDK_INT}.txt").writeText(failures.joinToString("\n"))
        File(output, "matrix-count-api${Build.VERSION.SDK_INT}.txt").writeText("$cases cases, ${failures.size} failures")
        assertTrue("$cases cases; ${failures.size} failures:\n${failures.take(20).joinToString("\n")}", failures.isEmpty())
    }

    @Test fun darkLongDescriptionsAndMissingForecastValues() {
        val store = WidgetStore.open(context)
        // Missing POP is decoded/presented by production as a dash; no invented value.
        store.commitForecast(store.beginForecastWrite(WidgetAddress.Saved("407"))!!,
            ForecastSnapshot(1, "region:407", "407", atTaipei(14, 10), atTaipei(14, 10),
                (15..19).map { ForecastPoint("$it:00", 27.0, "局部短暫陣雨", 206, null) }),
            receivedCalibratedMilliseconds = atTaipei(14, 10), expiresAtMilliseconds = atTaipei(15, 0), writtenAt = 2L)
        for (locale in listOf("zh-TW", "en", "ja", "ko", "th", "fil")) {
            for (dark in listOf(false, true)) {
                val base = configured(locale)
                val c = base.createConfigurationContext(Configuration(base.resources.configuration).apply {
                    uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
                        if (dark) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO
                })
                val p = presentation(c, 300, 320, "stale").copy(weatherText = "局部短暫陣雨")
                assertTrue(p.forecast.all { it.popText == "—" })
                exercise(c, p, "long-missing-$locale-dark$dark", preview = true)
                val minimum = presentation(c, 200, 320, "stale")
                exercise(c, minimum, "minimum-missing-$locale-dark$dark", preview = true)
            }
        }
    }

    @Test fun reapplyPreservesRefreshIdentityAndFiveColumns() {
        val sent = mutableListOf<android.app.PendingIntent>()
        val c = object : android.content.ContextWrapper(configured()) {
            override fun startIntentSender(intent: android.content.IntentSender, fillInIntent: android.content.Intent?,
                flagsMask: Int, flagsValues: Int, extraFlags: Int, options: android.os.Bundle?) {
                sent += (intent as org.robolectric.fakes.RoboIntentSender).pendingIntent
            }
        }
        fun pending(view: View, id: Int): android.app.PendingIntent {
            val count = sent.size
            assertTrue(view.findViewById<View>(id).performClick())
            assertEquals(count + 1, sent.size)
            return sent.last()
        }
        val p = presentation(c, 200, 320, "stale")
        val view = apply(c, p)
        val refreshIntent = pending(view, R.id.widget_refresh)
        val openIntent = pending(view, android.R.id.background)
        val instanceOther = WidgetRenderer.render(c, p, instanceId + 1).apply(c, FrameLayout(c))
        org.junit.Assert.assertNotEquals(refreshIntent, pending(instanceOther, R.id.widget_refresh))
        val shadow = org.robolectric.Shadows.shadowOf(refreshIntent)
        assertTrue(shadow.isBroadcast)
        assertEquals(WidgetRenderer.ACTION_REFRESH, shadow.savedIntent.action)
        assertEquals(instanceId, shadow.savedIntent.getIntExtra(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, -1))
        assertEquals(android.app.PendingIntent.FLAG_IMMUTABLE, shadow.flags and android.app.PendingIntent.FLAG_IMMUTABLE)
        assertEquals(WidgetRenderer.ACTION_OPEN_HOME, org.robolectric.Shadows.shadowOf(openIntent).savedIntent.action)
        for (state in listOf("queued", "running", "failed", "fresh", "stale")) {
            val next = presentation(c, 200, 320, state)
            WidgetRenderer.render(c, next, instanceId).reapply(c, view)
            view.requestLayout(); measure(c, next, view); draw(view)
            check("reapply $state", next, view)
            assertEquals(openIntent, pending(view, android.R.id.background))
            if (view.findViewById<View>(R.id.widget_refresh).visibility == View.VISIBLE && next.canRefresh &&
                next.refreshFeedback != WidgetRefreshFeedback.Queued && next.refreshFeedback != WidgetRefreshFeedback.Running) {
                assertEquals(refreshIntent, pending(view, R.id.widget_refresh))
            }
            assertTrue(view.contentDescription.toString().contains(requireNotNull(next.temperatureText)))
            assertEquals(c.getString(when(next.refreshFeedback) {
                WidgetRefreshFeedback.Queued -> R.string.widget_refresh_queued
                WidgetRefreshFeedback.Running -> R.string.widget_refresh_running
                WidgetRefreshFeedback.Failed -> R.string.widget_refresh_failed
                else -> R.string.widget_refresh
            }), view.findViewById<View>(R.id.widget_refresh).contentDescription)
        }
    }
    @Test fun expiredForecastRetainsMissingDataPolicy() {
        WidgetClock.installForTest(atTaipei(15, 1), android.os.SystemClock.elapsedRealtime())
        val c = configured()
        val p = presentation(c, 200, 320, "stale")
        assertEquals(R.layout.widget_large_tight, WidgetRenderer.layoutFor(p))
        assertTrue(p.forecast.isEmpty())
        val view = apply(c, p)
        assertEquals(0, view.findViewById<android.view.ViewGroup>(R.id.widget_forecast_container).childCount)
        assertEquals(p.temperatureText, view.findViewById<TextView>(R.id.widget_temperature).text.toString())
        WidgetTextVisibility.assertTree("expired forecast", view)
        draw(view, "expired-forecast")
    }
    @Test fun roomy336BoundaryUsesProductionSelection() {
        for (locale in listOf("zh-TW", "en", "ja", "ko", "th", "fil")) for (scale in listOf(1f, 1.3f, 2f)) {
            val c = configured(locale, scale)
            val w = kotlin.math.ceil(200 * scale.toDouble()).toInt()
            val h = kotlin.math.ceil(336 * scale.toDouble()).toInt()
            val p = presentation(c, w, h, "stale")
            assertEquals(R.layout.widget_large, WidgetRenderer.layoutFor(p))
            // Selection assertion only. Native visibility of this unchanged layout's
            // minimum is a separate strict diagnostic, not an F4 Tight assertion.
            record("roomy-boundary-$locale-$w-$h-f$scale", p, apply(c, p))
        }
    }

    @Test fun darkMinimumRetainsFiveNonzeroProbabilities() {
        val base = configured()
        val c = base.createConfigurationContext(Configuration(base.resources.configuration).apply {
            uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or Configuration.UI_MODE_NIGHT_YES
        })
        for (state in listOf("fresh", "stale", "running", "failed")) {
            val p = presentation(c, 200, 320, state)
            assertEquals(R.layout.widget_large_tight, WidgetRenderer.layoutFor(p))
            exercise(c, p, "minimum-dark-$state", preview = true)
        }
    }
}
