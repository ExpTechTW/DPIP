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

/** Production-selected Compact: first measure/draw, later traversal and reapply. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [26, 35], qualifiers = "420dpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WidgetCompactAccessibilityTest {
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
            "temporary-location", "needs-app" -> WidgetPresenter.present(
                sizeClass = base.sizeClass,
                strings = WidgetUpdater.strings(c),
                address = WidgetAddress.CurrentLocation,
                locationName = base.locationName,
                stored = WidgetStore.open(c).readCurrentWeather(WidgetAddress.Saved("407")),
                forecast = null,
                locationDegradation = if (state == "needs-app") WidgetLocationDegradation.Permission else WidgetLocationDegradation.Unavailable,
                isCatalogMember = true,
                calibratedNowMilliseconds = atTaipei(14, 20),
                latitude = 24.181,
                longitude = 120.645,
                availableWidthDp = width,
                availableHeightDp = height,
                fontScale = c.resources.configuration.fontScale,
            )
            "missing-values" -> base.copy(temperatureText = "--°", humidityText = "--%", rainText = "-- mm")
            "stale-running" -> base.copy(isStale = true, badgeText = c.getString(R.string.widget_stale), refreshFeedback = WidgetRefreshFeedback.Running)
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

    private val locales = listOf("zh-TW", "en", "ja", "ko", "th", "fil")
    private val scales = listOf(1f, 1.15f, 1.3f, 1.5f, 2f)
    private val boxes = listOf(110 to 110, 110 to 120, 118 to 152, 120 to 172, 158 to 158)
    private val states = listOf("fresh", "stale", "temporary-location", "queued", "running", "failed", "missing-values", "stale-running", "needs-app")
    private val output get() = File("build/widget-compact-accessibility").apply { mkdirs() }

    private fun draw(view: View, name: String? = null) {
        val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
        try {
            view.draw(Canvas(bitmap))
            if (name != null) File(output, "$name-api${Build.VERSION.SDK_INT}.png").outputStream().use {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        } finally { bitmap.recycle() }
    }

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

    private fun visible(view: View): Boolean {
        var node: View? = view
        while (node != null) {
            if (node.visibility != View.VISIBLE) return false
            node = node.parent as? View
        }
        return true
    }

    private fun check(label: String, c: Context, p: WidgetPresentation, view: View) {
        val temperature = view.findViewById<TextView>(R.id.widget_temperature)
        assertTrue("$label primary temperature height", temperature.height > 0)
        WidgetTextVisibility.assertVisible("$label temperature", temperature)
        assertNativeInk("$label temperature", temperature, view)
        WidgetTextVisibility.assertTree(label, view)
        for (id in listOf(R.id.widget_observation_time, R.id.widget_humidity_value, R.id.widget_rain_value, R.id.widget_stale)) {
            val text = view.findViewById<TextView>(id)
            if (visible(text) && text.text.isNotEmpty()) {
                WidgetTextVisibility.assertVisible("$label core ${text.text}", text,
                    allowEllipsis = id == R.id.widget_stale && !p.compactLayout)
                assertNativeInk("$label core ${text.text}", text, view)
            }
        }
        assertEquals("$label secondary rows change together", visible(view.findViewById(R.id.widget_observation_time)),
            visible(view.findViewById(R.id.widget_humidity_value)))
        val badge = view.findViewById<TextView>(R.id.widget_stale)
        assertEquals("$label status must survive fallback", p.badgeText != null, visible(badge))
        val refresh = view.findViewById<View>(R.id.widget_refresh)
        val busy = p.refreshFeedback == WidgetRefreshFeedback.Queued || p.refreshFeedback == WidgetRefreshFeedback.Running
        assertEquals(if (p.showRefresh) View.VISIBLE else View.GONE, refresh.visibility)
        assertEquals(p.showRefresh && p.canRefresh && !busy, refresh.isEnabled)
        assertEquals(refresh.isEnabled, refresh.hasOnClickListeners())
        val feedbackLabel = when (p.refreshFeedback) {
            WidgetRefreshFeedback.Queued -> R.string.widget_refresh_queued
            WidgetRefreshFeedback.Running -> R.string.widget_refresh_running
            WidgetRefreshFeedback.Failed -> R.string.widget_refresh_failed
            WidgetRefreshFeedback.Updated -> R.string.widget_refresh_updated
            null -> R.string.widget_refresh
        }
        assertEquals(c.getString(feedbackLabel), refresh.contentDescription)
        assertEquals(if (busy) View.GONE else View.VISIBLE, view.findViewById<View>(R.id.widget_refresh_icon).visibility)
        assertEquals(if (p.refreshFeedback == WidgetRefreshFeedback.Failed) R.drawable.ic_widget_refresh_failed else R.drawable.ic_widget_refresh,
            org.robolectric.Shadows.shadowOf(view.findViewById<ImageView>(R.id.widget_refresh_icon).drawable).createdFromResId)
        assertTrue(view.findViewById<android.widget.ProgressBar>(R.id.widget_refresh_progress).isIndeterminate)
        assertEquals(if (busy) View.VISIBLE else View.GONE, view.findViewById<View>(R.id.widget_refresh_progress).visibility)
        assertTrue(view.hasOnClickListeners())
        val description = view.contentDescription.toString()
        for (part in listOfNotNull(p.locationName, p.temperatureText, p.badgeText,
            p.observationTimeMillis?.let(WidgetPresenter::observationDescription))) assertTrue("$label missing semantic $part", description.contains(part))
        if (p.compactLayout) for (part in listOfNotNull(p.humidityText, p.rainText, p.hintText,
            if (p.isCurrentLocation) c.getString(R.string.widget_current_location) else null,
            c.getString(R.string.widget_humidity), c.getString(R.string.widget_rain), c.getString(R.string.widget_compact_details),
            c.getString(R.string.widget_weather_rain))) assertTrue("$label missing semantic $part", description.contains(part))
        // Disjoint visible leaf boxes catch accidental overlap independently of clipping.
        val leaves = mutableListOf<View>()
        fun collect(v: View) {
            if (!visible(v)) return
            if (v is android.view.ViewGroup) for (i in 0 until v.childCount) collect(v.getChildAt(i))
            else if (v.width > 0 && v.height > 0) leaves += v
        }
        collect(view)
        for (i in leaves.indices) for (j in i + 1 until leaves.size) {
            fun rect(v: View) = android.graphics.Rect(0, 0, v.width, v.height).also {
                (view as android.view.ViewGroup).offsetDescendantRectToMyCoords(v, it)
            }
            assertFalse("$label overlapping ${leaves[i].id} ${leaves[j].id}", android.graphics.Rect.intersects(rect(leaves[i]), rect(leaves[j])))
        }
    }

    @Test fun productionMatrixFirstMeasureDrawAndSubsequentMeasure() {
        val failures = mutableListOf<String>()
        val evidence = File(output, "matrix-api${Build.VERSION.SDK_INT}.txt")
        evidence.writeText("")
        var cases = 0
        for (locale in locales) for (scale in scales) for ((w, h) in boxes) for (state in states) {
            val c = configured(locale, scale)
            val p = presentation(c, w, h, state)
            val label = "$w x $h scale=$scale API=${Build.VERSION.SDK_INT} $locale $state"
            val view = apply(c, p)
            fun verify(stage: String) {
                try { check("$label $stage", c, p, view) }
                catch (e: AssertionError) { failures += "$label $stage: ${e.message}" }
            }
            verify("initial-measure")
            draw(view)
            verify("first-native-draw")
            view.requestLayout(); measure(c, p, view)
            verify("subsequent-measure")
            evidence.appendText("$label layout=${WidgetRenderer.layoutFor(p)} minimal=${!visible(view.findViewById(R.id.widget_observation_time))} tempPx=${view.findViewById<TextView>(R.id.widget_temperature).textSize}\n")
            cases++
        }
        File(output, "failures-api${Build.VERSION.SDK_INT}.txt").writeText(failures.joinToString("\n"))
        assertTrue("$cases cases; ${failures.size} stage failures:\n${failures.take(30).joinToString("\n")}", failures.isEmpty())
    }

    @Test fun longValuesCurrentLocationAndThaiGlyphs() {
        for (locale in locales) for (scale in scales) for ((w, h) in boxes) {
            val c = configured(locale, scale)
            for (number in listOf("-99°", "100°")) {
                val p = presentation(c, w, h, "stale").copy(locationName = "臺灣臺中市西屯區非常長的地點名稱", isCurrentLocation = true,
                    temperatureText = number, humidityText = "100%", rainText = "999.9 mm")
                val v = apply(c, p)
                check("long $locale $scale $w x $h $number", c, p, v)
                draw(v)
                viewReapply(c, p, v)
                check("long reapply $locale $scale $w x $h", c, p, v)
            }
        }
    }

    private fun viewReapply(c: Context, p: WidgetPresentation, view: View) {
        WidgetRenderer.render(c, p, instanceId).reapply(c, view)
        view.requestLayout(); measure(c, p, view)
    }

    @Test fun reapplyRefreshAndResizeRestoresSecondaryRows() {
        for (locale in locales) for (scale in scales.drop(1)) {
            val c = configured(locale, scale)
            var p = presentation(c, 110, 110, "stale")
            val v = apply(c, p)
            for ((w, h) in listOf(110 to 110, 158 to 158, 110 to 120, 120 to 172, 110 to 110)) {
                for (state in states) {
                    p = presentation(c, w, h, state)
                    viewReapply(c, p, v)
                    check("resize $locale $scale $w x $h $state", c, p, v)
                }
            }
        }
    }


    /** Real Presenter input; no test-side fallback thresholds or visibility decisions. */
    private fun p2Presentation(c: Context, w: Int, h: Int, humidity: Int?, rain: Double?, state: String = "stale"): WidgetPresentation {
        val stored = WidgetStore.open(c).readCurrentWeather(WidgetAddress.Saved("407"))!!
        return WidgetPresenter.present(
            sizeClass = WidgetPresenter.sizeClass(w, h, c.resources.configuration.fontScale),
            strings = WidgetUpdater.strings(c),
            address = if (state == "temporary-location") WidgetAddress.CurrentLocation else WidgetAddress.Saved("407"),
            locationName = "西屯", // A whole short place name, plus separate existing long-name coverage.
            stored = stored.copy(snapshot = stored.snapshot.copy(temperature = 28.0, humidity = humidity, rain = rain)),
            forecast = null,
            locationDegradation = if (state == "temporary-location") WidgetLocationDegradation.Unavailable else null,
            isCatalogMember = true,
            calibratedNowMilliseconds = atTaipei(if (state == "stale") 16 else 14, 20),
            latitude = 24.181, longitude = 120.645,
            availableWidthDp = w, availableHeightDp = h, fontScale = c.resources.configuration.fontScale,
        ).let { base -> base.copy(refreshFeedback = when (state) {
            "queued" -> WidgetRefreshFeedback.Queued
            "running" -> WidgetRefreshFeedback.Running
            "failed" -> WidgetRefreshFeedback.Failed
            else -> null
        }) }
    }

    private fun assertMode(label: String, view: View, extreme: Boolean) {
        for (id in listOf(R.id.widget_compact_header, R.id.widget_compact_metrics,
            R.id.widget_location, R.id.widget_observation_time, R.id.widget_humidity_value, R.id.widget_rain_value)) {
            assertEquals("$label expected extreme=$extreme id=$id", !extreme, visible(view.findViewById(id)))
        }
        assertTrue("$label temperature survives", visible(view.findViewById(R.id.widget_temperature)))
    }

    @Test fun p2CaseAKeepsFourRows() = verifyP2Case(P2Case("A", 110 to 158, 8, false))
    @Test fun p2CaseBPreservesExtremeFallback() = verifyP2Case(P2Case("B", 110 to 158, 78, true))
    @Test fun p2CaseCKeepsFourRows() = verifyP2Case(P2Case("C", 124 to 153, 78, false))

    private fun verifyP2Case(case: P2Case) {
        val evidence = File(output, "p2-case-${case.name}-api${Build.VERSION.SDK_INT}.txt")
        evidence.writeText("")
        for (locale in locales) {
            val (name, box, humidity, extreme) = case
            val c = configured(locale, 2f)
            val p = p2Presentation(c, box.first, box.second, humidity, 0.4)
            assertTrue(p.isStale)
            assertEquals("28°", p.temperatureText)
            assertEquals(R.layout.widget_small_compact_accessible, WidgetRenderer.layoutFor(p))
            val v = apply(c, p)
            val label = "$name ${box.first}x${box.second} scale=2.0 $locale API=${Build.VERSION.SDK_INT} stale humidity=$humidity rain=0.4"
            fun verify(stage: String) {
                assertMode("$label $stage", v, extreme)
                check("$label $stage", c, p, v)
                assertTrue("$label status survives", visible(v.findViewById(R.id.widget_stale)))
                if (!extreme) {
                    val location = v.findViewById<TextView>(R.id.widget_location)
                    WidgetTextVisibility.assertVisible("$label location", location)
                    assertNativeInk("$label location", location, v)
                }
                evidence.appendText("$label $stage expectedExtreme=$extreme actualExtreme=${!visible(v.findViewById(R.id.widget_compact_header))} " +
                    listOf(R.id.widget_temperature,R.id.widget_humidity_value,R.id.widget_rain_value,R.id.widget_stale).joinToString { id ->
                        val t=v.findViewById<TextView>(id)
                        "${t.text}:${t.width}x${t.height}/line=${t.layout?.height}/px=${t.textSize}"
                    } + "\n")
            }
            verify("first-measure")
            draw(v, "p2-$name-$locale")
            verify("first-native-draw")
            v.requestLayout(); measure(c, p, v)
            verify("subsequent-measure")
        }
    }

    private data class P2Case(val name: String, val box: Pair<Int, Int>, val humidity: Int, val extreme: Boolean)

    @Test fun p2AdjacentDimensionsContentAndStateBoundaries() {
        // A fixed product-space sample, independent of implementation thresholds.
        // All content/state/scale combinations; rotate locales across adjacent boxes.
        // The original full six-locale matrix and A/B/C tests remain exhaustive in locale.
        val adjacent = listOf(109 to 158, 110 to 157, 110 to 158, 110 to 159, 111 to 158,
            123 to 153, 124 to 152, 124 to 153, 124 to 154, 125 to 153)
        val evidence = File(output, "p2-boundaries-api${Build.VERSION.SDK_INT}.txt")
        evidence.writeText("")
        var cases = 0
        for ((boxIndex, box) in adjacent.withIndex()) for ((scaleIndex, scale) in scales.drop(1).withIndex())
            for ((humidityIndex, humidity) in listOf(8,78,100,null).withIndex())
                for ((rainIndex, rain) in listOf(0.4,999.9,null).withIndex())
                    for ((stateIndex, state) in listOf("fresh","stale","temporary-location","queued","running","failed").withIndex()) {
            val locale = locales[(boxIndex+scaleIndex+humidityIndex+rainIndex+stateIndex) % locales.size]
            val c = configured(locale, scale)
            val p = p2Presentation(c, box.first, box.second, humidity, rain, state)
            val label = "${box.first}x${box.second} scale=$scale $locale API=${Build.VERSION.SDK_INT} $state humidity=$humidity rain=$rain"
            val selected = WidgetRenderer.render(c,p,instanceId)
            val v = selected.apply(c,FrameLayout(c)); measure(c,p,v)
            val actualExtreme = !visible(v.findViewById(R.id.widget_compact_header))
            // Independent native feasibility oracle. Force a fresh full document only
            // in this counterfactual, and use the strict raster/ancestor helper rather
            // than copying the production selector's width/height calculations.
            val full = selected.apply {
                setViewVisibility(R.id.widget_compact_header,View.VISIBLE)
                setViewVisibility(R.id.widget_compact_metrics,View.VISIBLE)
            }.apply(c,FrameLayout(c))
            measure(c,p,full)
            val fitFailure = try {
                for (id in listOf(R.id.widget_temperature,R.id.widget_observation_time,R.id.widget_humidity_value,R.id.widget_rain_value,R.id.widget_stale)) {
                    val t=full.findViewById<TextView>(id)
                    if (visible(t) && t.text.isNotEmpty()) {
                        WidgetTextVisibility.assertVisible("$label full", t)
                        assertNativeInk("$label full",t,full)
                    }
                }
                null
            } catch (error: AssertionError) { error.message ?: "Native feasibility assertion failed" }
            val cannotFit = fitFailure != null
            evidence.appendText("$label expectedExtreme=$cannotFit actualExtreme=$actualExtreme reason=$fitFailure\n")
            assertEquals("$label fallback must match native feasibility",cannotFit,actualExtreme)
            assertMode(label,v,actualExtreme)
            check("$label first-measure",c,p,v)
            draw(v)
            check("$label first-draw",c,p,v)
            v.requestLayout(); measure(c,p,v)
            check("$label subsequent",c,p,v)
            cases++
        }
        assertEquals(2880,cases)
    }

    @Test fun p2NormalAdaptiveExtremeAdaptiveHostTransitions() {
        for (locale in locales) for (state in listOf("stale","queued","running","failed","fresh")) {
            var c=configured(locale,1f)
            var p=p2Presentation(c,110,158,78,0.4,state)
            var remote=WidgetRenderer.render(c,p,instanceId)
            var host=FrameLayout(c)
            var v=remote.apply(c,host)
            host.addView(v); measure(c,p,v)
            assertEquals(R.layout.widget_small_compact,remote.layoutId)
            check("normal $locale $state",c,p,v)
            val open=clickBindings(remote,v)[android.R.id.background]
            var refresh: android.app.PendingIntent? = null
            for ((index,fixture) in listOf(P2Case("adaptive",124 to 153,78,false),
                P2Case("extreme",110 to 158,78,true),P2Case("restored",110 to 158,8,false)).withIndex()) {
                c=configured(locale,2f)
                p=p2Presentation(c,fixture.box.first,fixture.box.second,fixture.humidity,0.4,state)
                val next=WidgetRenderer.render(c,p,instanceId)
                if (next.layoutId != remote.layoutId) {
                    // AppWidgetHost reconstructs when XML changes; cross-layout reapply is invalid.
                    host.removeView(v); host=FrameLayout(c)
                    v=next.apply(c,host); host.addView(v)
                } else next.reapply(c,v)
                measure(c,p,v)
                assertMode("transition $locale $state ${fixture.name}",v,fixture.extreme)
                check("transition $locale $state ${fixture.name}",c,p,v)
                draw(v)
                val bindings=clickBindings(next,v)
                assertEquals(open,bindings[android.R.id.background])
                if (index==0) refresh=bindings[R.id.widget_refresh]
                else assertEquals(refresh,bindings[R.id.widget_refresh])
                v.requestLayout(); measure(c,p,v)
                check("transition subsequent $locale $state ${fixture.name}",c,p,v)
                remote=next
            }
        }
    }

    @Test fun p2DetachedProbeAlsoRendersOnWorkerWithoutLooper() {
        val c=configured("th",2f)
        val p=p2Presentation(c,110,158,8,0.4)
        val executor=java.util.concurrent.Executors.newSingleThreadExecutor()
        try {
            val remote=executor.submit<android.widget.RemoteViews> {
                assertEquals(null,android.os.Looper.myLooper())
                WidgetRenderer.render(c,p,instanceId)
            }.get(30,java.util.concurrent.TimeUnit.SECONDS)
            val v=remote.apply(c,FrameLayout(c)); measure(c,p,v)
            assertMode("worker",v,false)
            check("worker",c,p,v)
        } finally { executor.shutdownNow() }
    }

    @Test fun previews() {
        for (night in listOf(false, true)) for ((scale, state) in listOf(1f to "fresh", 1f to "stale", 1.3f to "stale", 1.5f to "stale", 2f to "stale", 1.3f to "running", 2f to "failed")) {
            val c = configured("th", scale).let { base -> base.createConfigurationContext(Configuration(base.resources.configuration).apply {
                uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
                    if (night) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO
            }) }
            val p = presentation(c, 110, 110, state).copy(locationName = "臺中市西屯區非常長的名稱", temperatureText = "-12°", isCurrentLocation = true)
            val v = apply(c, p)
            check("preview $night $scale $state", c, p, v)
            draw(v, "compact-$night-$scale-$state")
        }
    }
    /** API-specific RemoteViews action containers, inspected only in the test. */
    private fun clickBindings(remote: android.widget.RemoteViews, view: View): Map<Int, android.app.PendingIntent?> {
        val actions = org.robolectric.util.ReflectionHelpers.getField<ArrayList<*>>(remote, "mActions")
        val result = mutableMapOf<Int, android.app.PendingIntent?>()
        for (action in actions.filterNotNull()) {
            val fields = generateSequence(action.javaClass as Class<*>?) { it.superclass }.flatMap { it.declaredFields.asSequence() }.toList()
            val target = fields.firstOrNull { it.name == "viewId" || it.name == "mViewId" } ?: continue
            target.isAccessible = true
            val id = target.getInt(action)
            assertTrue("RemoteViews target $id must exist", view.findViewById<View>(id) != null)
            if (!action.javaClass.simpleName.contains("OnClick")) continue
            fun pending(value: Any): android.app.PendingIntent? {
                for (field in value.javaClass.declaredFields) {
                    if (field.type == android.app.PendingIntent::class.java) {
                        field.isAccessible = true
                        return field.get(value) as? android.app.PendingIntent
                    }
                    if (field.type.simpleName == "RemoteResponse") {
                        field.isAccessible = true
                        field.get(value)?.let { return pending(it) }
                    }
                }
                return null
            }
            result[id] = pending(action)
        }
        return result
    }

    @Test fun remoteViewsIdsPendingIntentIdentityAndClearing() {
        for (scale in scales) {
            val c = configured("zh-TW", scale)
            val p = presentation(c, 110, 110, "stale")
            val remote = WidgetRenderer.render(c, p, 42)
            val view = remote.apply(c, FrameLayout(c))
            val binding = clickBindings(remote, view)
            val open = binding[android.R.id.background]!!
            val refresh = binding[R.id.widget_refresh]!!
            assertFalse(open == refresh)
            val otherRemote = WidgetRenderer.render(c, p, 43)
            val otherView = otherRemote.apply(c, FrameLayout(c))
            val other = clickBindings(otherRemote, otherView)
            assertFalse(open == other[android.R.id.background])
            assertFalse(refresh == other[R.id.widget_refresh])
            val openShadow = org.robolectric.Shadows.shadowOf(open)
            val refreshShadow = org.robolectric.Shadows.shadowOf(refresh)
            assertEquals(WidgetRenderer.ACTION_OPEN_HOME, openShadow.savedIntent.action)
            assertEquals(com.exptech.dpip.MainActivity::class.java.name, openShadow.savedIntent.component!!.className)
            assertEquals(42 * 4 + 1, openShadow.requestCode)
            assertEquals(42 * 4 + 3, refreshShadow.requestCode)
            assertEquals(WidgetRenderer.ACTION_REFRESH, refreshShadow.savedIntent.action)
            assertEquals(WeatherWidgetProvider::class.java.name, refreshShadow.savedIntent.component!!.className)
            assertEquals(42, refreshShadow.savedIntent.getIntExtra(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, -1))
            assertTrue(refreshShadow.flags and android.app.PendingIntent.FLAG_IMMUTABLE != 0)
            for (feedback in listOf(WidgetRefreshFeedback.Queued, WidgetRefreshFeedback.Running, WidgetRefreshFeedback.Failed, null)) {
                val next = WidgetRenderer.render(c, p.copy(refreshFeedback = feedback), 42)
                next.reapply(c, view)
                val nextBindings = clickBindings(next, view)
                val busy = feedback == WidgetRefreshFeedback.Queued || feedback == WidgetRefreshFeedback.Running
                assertEquals(if (busy) null else refresh, nextBindings[R.id.widget_refresh])
                assertEquals(open, nextBindings[android.R.id.background])
            }
        }
    }

    @Test fun temperatureGrowsWithAccessibilityTextAndRoomyAdaptivePreviews() {
        for (locale in locales) for (value in listOf("28°", "-99°", "100°")) {
            val baselineContext = configured(locale)
            val baseline = presentation(baselineContext, 110, 110, "stale").copy(temperatureText = value)
            val baselineView = apply(baselineContext, baseline)
            val baselinePixels = baselineView.findViewById<TextView>(R.id.widget_temperature).textSize
            for (scale in scales.drop(1)) {
                val c = configured(locale, scale)
                for ((w, h) in boxes) {
                    val p = presentation(c, w, h, "stale").copy(temperatureText = value)
                    val v = apply(c, p)
                    assertTrue("temperature must not shrink: $locale $value $scale $w x $h",
                        v.findViewById<TextView>(R.id.widget_temperature).textSize >= baselinePixels)
                    check("growth $locale $value $scale $w x $h", c, p, v)
                    if (locale == "th" && value == "28°" && w == 158 && (scale == 1.5f || scale == 2f)) {
                        assertTrue("roomy adaptive keeps secondary rows", visible(v.findViewById(R.id.widget_humidity_value)))
                        draw(v, "roomy-adaptive-$scale")
                    }
                }
            }
        }
    }

    @Test fun updaterUsesTheSameCompactDecisionForResponsiveAndLegacyRemoteViews() {
        val manager = android.appwidget.AppWidgetManager.getInstance(context)
        for (scale in scales) for ((w, h) in boxes) {
            val c = configured("th", scale)
            WidgetUpdater.optionsProvider = { _, _ -> android.os.Bundle().apply {
                putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, w)
                putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, h)
                if (Build.VERSION.SDK_INT >= 31) putParcelableArrayList(
                    android.appwidget.AppWidgetManager.OPTION_APPWIDGET_SIZES,
                    arrayListOf(android.util.SizeF(w.toFloat(), h.toFloat())),
                )
            } }
            val p = WidgetUpdater.presentation(c, instanceId, w, h)
            val remote = WidgetUpdater.render(c, manager, instanceId)
            val view = remote.apply(c, FrameLayout(c))
            measure(c, p, view)
            check("updater ${Build.VERSION.SDK_INT} $scale $w x $h", c, p, view)
        }
    }

}
