package com.exptech.dpip.widget

import android.app.Activity
import android.content.Context
import android.content.res.Configuration
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import com.exptech.dpip.R
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Robolectric
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * The layouts against the sizes a launcher actually reports.
 *
 * A `RemoteViews` that inflates is not a layout that *fits*: the medium layout
 * once carried a forecast container with `layout_weight="1"` inside a two-row
 * budget, which laid the container out at zero height and clipped the hours away
 * — invisible in any test that only asked whether the layout applied.
 *
 * The presentation comes from **`WidgetUpdater.presentation`**, the same call the
 * provider makes, with the size the launcher reported. Deriving the size class
 * here instead measured a *different* layout from the one production picks, so
 * the test could hide lines production still drew.
 *
 * `@GraphicsMode(NATIVE)` because the assertion is about text having a size at
 * all: the legacy JVM font metrics report one line height for every text size,
 * which no layout can satisfy.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [26, 35], qualifiers = "420dpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WidgetLayoutFitTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val instanceId = 42

    private val strings = WidgetStrings(
        stale = "OUTDATED",
        noData = "NO_DATA",
        openApp = "OPEN_APP",
        needsApp = "NEEDS_APP",
        reconfigure = "RECONFIGURE",
        humidity = "HUM",
        rain = "RAIN",
        wind = "WIND",
        station = "STATION",
        sunrise = "SUNRISE",
        sunset = "SUNSET",
        apparent = "FEELS",
        currentLocation = "CURRENT",
        locationDisabled = "LOCATION_OFF",
        locationUnavailable = "NO_FIX",
        locationOutside = "OUTSIDE",
    )

    private lateinit var store: WidgetStore
    private val taipei = java.time.ZoneOffset.ofHours(8)

    private fun atTaipei(hour: Int, minute: Int): Long =
        java.time.LocalDateTime.of(2026, 10, 12, hour, minute).toInstant(taipei).toEpochMilli()

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        store = WidgetStore.open(context)
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

    /** The size the launcher reports, as the provider reads it. */
    private fun reportSize(widthDp: Int, heightDp: Int) {
        WidgetUpdater.optionsProvider = { _, id ->
            Bundle().apply {
                if (id == instanceId) {
                    putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, widthDp)
                    putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, heightDp)
                }
            }
        }
    }

    private fun px(dp: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        dp.toFloat(),
        context.resources.displayMetrics,
    ).toInt()

    // A GONE group's children keep VISIBLE but are never laid out.
    private fun leaves(view: View): List<View> = if (view is ViewGroup) {
        if (view.visibility != View.VISIBLE) emptyList()
        else (0 until view.childCount).flatMap { leaves(view.getChildAt(it)) }
    } else {
        listOf(view)
    }

    /** The offset of [view]'s bottom/right inside [ancestor]. */
    private fun offsetWithin(view: View, ancestor: View): Pair<Int, Int> {
        var top = view.top
        var left = view.left
        var node: View? = view
        while (node != null && node !== ancestor) {
            node = node.parent as? View
            if (node != null && node !== ancestor) {
                top += node.top
                left += node.left
            }
        }
        return top to left
    }

    private fun nameOf(view: View): String = if (view.id == View.NO_ID) {
        view.javaClass.simpleName
    } else {
        context.resources.getResourceEntryName(view.id)
    }

    private fun assertRefreshFits(label: String, view: View, visible: Boolean) {
        val refresh = view.findViewById<View>(R.id.widget_refresh)
        assertEquals("$label: refresh visibility", if (visible) View.VISIBLE else View.GONE, refresh.visibility)
        if (visible) {
            assertTrue("$label: refresh must have a target box", refresh.width > 0 && refresh.height > 0)
        } else {
            assertTrue("$label: hidden refresh must be disabled", !refresh.isEnabled)
            assertTrue("$label: hidden refresh must not be clickable", !refresh.hasOnClickListeners())
        }
    }

    private fun withFontScale(scale: Float, block: () -> Unit) {
        val configuration = Configuration(context.resources.configuration)
        val original = configuration.fontScale
        configuration.fontScale = scale
        context.resources.updateConfiguration(configuration, context.resources.displayMetrics)
        try {
            block()
        } finally {
            configuration.fontScale = original
            context.resources.updateConfiguration(configuration, context.resources.displayMetrics)
        }
    }

    /**
     * Renders the production presentation for this box and lays it out in it.
     *
     * Everything below is asserted against the view the launcher would receive,
     * at the size the launcher said it had.
     */
    private fun assertFits(
        widthDp: Int,
        heightDp: Int,
        presentation: WidgetPresentation? = null,
    ) {
        reportSize(widthDp, heightDp)
        val fontScale = context.resources.configuration.fontScale
        val presentation = presentation
            ?: WidgetUpdater.presentation(context, instanceId, widthDp, heightDp)
        val label = "${presentation.sizeClass} at ${widthDp}x$heightDp dp " +
            "(fontScale $fontScale)"

        assertEquals(
            "$label: the production size class must match the reported size",
            WidgetPresenter.sizeClass(widthDp, heightDp, fontScale),
            presentation.sizeClass,
        )

        val view = WidgetRenderer.render(context, presentation, instanceId)
            .apply(context, FrameLayout(context))
        val widthPx = px(widthDp)
        val heightPx = px(heightDp)
        view.measure(
            View.MeasureSpec.makeMeasureSpec(widthPx, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(heightPx, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, widthPx, heightPx)

        assertEquals("$label: the root must fill the requested box", heightPx, view.measuredHeight)
        assertEquals("$label: the root must fill the requested box", widthPx, view.measuredWidth)

        // Nothing visible may be laid out past the box it lives in — vertically
        // or horizontally. A clipped line is what "the forecast is there but
        // invisible" looked like; a row wider than the widget is the same defect
        // sideways.
        for (leaf in leaves(view).filter { it.visibility == View.VISIBLE }) {
            if (leaf is TextView && leaf.text.isNotEmpty()) {
                WidgetTextVisibility.assertVisible("$label: ${nameOf(leaf)}", leaf, allowEllipsis = true)
            }
            val (top, left) = offsetWithin(leaf, view)
            assertTrue(
                "$label: ${nameOf(leaf)} overflows the root vertically " +
                    "(${top + leaf.height} > $heightPx)",
                top + leaf.height <= heightPx,
            )
            assertTrue(
                "$label: ${nameOf(leaf)} overflows the root horizontally " +
                    "(${left + leaf.width} > $widthPx)",
                left + leaf.width <= widthPx,
            )
            assertTrue(
                "$label: ${nameOf(leaf)} starts outside the root ($top, $left)",
                top >= 0 && left >= 0,
            )
        }

        // The essentials are never dropped, and they have to be readable: a text
        // view laid out at zero width says nothing.
        for (id in listOf(R.id.widget_location, R.id.widget_icon, R.id.widget_temperature)) {
            val required = view.findViewById<View>(id)
            assertNotNull("$label: $id must exist", required)
            if (id == R.id.widget_icon && presentation.adaptiveCompact) {
                assertEquals("adaptive decorative icon", View.GONE, required.visibility)
                assertTrue("adaptive condition remains accessible", view.contentDescription.isNotEmpty())
                continue
            }
            assertEquals("$label: ${nameOf(required)} must be visible", View.VISIBLE, required.visibility)
            assertTrue("$label: ${nameOf(required)} must have height", required.height > 0)
            assertTrue("$label: ${nameOf(required)} must have width", required.width > 0)
        }
        for (id in listOf(R.id.widget_location, R.id.widget_temperature)) {
            val text = view.findViewById<TextView>(id)
            assertTrue(
                "$label: ${nameOf(text)} has no readable width",
                text.width > px(8),
            )
        }
        assertTrue(
            "$label: the temperature must actually say something",
            view.findViewById<TextView>(R.id.widget_temperature).text.isNotEmpty(),
        )

        // The observation time is the other fact the screen always carries — a
        // saved town with no time reads as "live", which this Widget never claims.
        val observation = view.findViewById<TextView>(R.id.widget_observation_time)
        assertNotNull("$label: the observation time must exist", observation)
        assertEquals(
            "$label: the observation time must be visible",
            View.VISIBLE,
            observation.visibility,
        )
        assertTrue(
            "$label: the observation time has no readable width",
            observation.width > px(8),
        )
        assertEquals("$label: observation uses HH:mm", "14:05", observation.text.toString())

        assertRefreshFits(label, view, presentation.showRefresh)

        val container = view.findViewById<ViewGroup>(R.id.widget_forecast_container)
        if (presentation.sizeClass == WidgetSizeClass.Small) {
            assertEquals("$label: the square layout has no forecast", null, container)
            return
        }
        checkNotNull(container) { "$label: the forecast container must exist" }
        assertTrue("$label: the forecast container has no height", container.height > 0)
        assertTrue("$label: the forecast container has no width", container.width > 0)
        assertEquals("$label: five points must be drawn", 5, container.childCount)
        for (index in 0 until container.childCount) {
            val column = container.getChildAt(index)
            assertTrue("$label: column $index has no height", column.height > 0)
            assertTrue("$label: hourly columns must share the width evenly",
                kotlin.math.abs(column.width * container.childCount - container.width) <= container.childCount)
            // The four lines iOS draws — clock, glyph, temperature, probability.
            // "It fits" must never be bought by letting the probability collapse
            // to zero height, which a `wrap_content` column will do silently.
            for (id in listOf(
                R.id.widget_forecast_time,
                R.id.widget_forecast_icon,
                R.id.widget_forecast_temperature,
                R.id.widget_forecast_pop,
            )) {
                val line = column.findViewById<View>(id)
                assertNotNull("$label: column $index is missing $id", line)
                assertEquals("$label: column $index must show $id", View.VISIBLE, line.visibility)
                assertTrue(
                    "$label: column $index clipped $id to ${line.height}px",
                    line.height > px(8),
                )
                if (line is TextView) {
                    assertTextFits("$label: column $index ${nameOf(line)}", line)
                }
            }
            for (leaf in leaves(column).filter { it.visibility == View.VISIBLE }) {
                val (top, left) = offsetWithin(leaf, container)
                assertTrue(
                    "$label: a forecast line overflows its column " +
                        "(${top + leaf.height} > ${container.height})",
                    top + leaf.height <= container.height,
                )
                assertTrue(
                    "$label: a forecast line overflows its column sideways",
                    left + leaf.width <= container.width,
                )
            }
        }
    }

    @Test
    fun `medium apparent temperature retains its complete reading`() {
        assertMediumApparentTemperature()
    }

    @Test
    @Config(qualifiers = "zh-rTW-420dpi")
    fun `medium apparent temperature retains its complete reading in Traditional Chinese`() {
        assertMediumApparentTemperature()
    }

    @Test
    @Config(qualifiers = "ja-420dpi")
    fun `medium apparent temperature retains its complete reading in Japanese`() {
        assertMediumApparentTemperature()
    }

    @Test
    @Config(qualifiers = "ko-420dpi")
    fun `medium apparent temperature retains its complete reading in Korean`() {
        assertMediumApparentTemperature()
    }

    @Test
    @Config(qualifiers = "th-420dpi")
    fun `medium apparent temperature retains its complete reading in Thai`() {
        assertMediumApparentTemperature()
    }

    @Test
    @Config(qualifiers = "fil-420dpi")
    fun `medium apparent temperature retains its complete reading in Filipino`() {
        assertMediumApparentTemperature()
    }

    private fun assertMediumApparentTemperature() {
        val address = WidgetAddress.Saved("407")
        val snapshot = store.readCurrentWeather(address)!!.snapshot
        for (scale in listOf(1f, 1.3f)) {
            withFontScale(scale) {
                // At 1.3x the original 200x170 box intentionally selects Small.
                // Also exercise the smallest box that still selects Medium.
                val boxes = if (scale == 1f) listOf(200 to 170, 320 to 172)
                    else listOf(260 to 221, 320 to 230)
                for (apparent in listOf(30.2, -12.0, 100.0, -100.0, null)) {
                    store.commitCurrentWeather(store.beginCurrentWeatherWrite(address)!!,
                        snapshot.copy(apparentTemperature = apparent), writtenAt = 1L)
                    for ((width, height) in boxes) {
                        for (stale in listOf(false, true)) {
                            val base = WidgetUpdater.presentation(context, instanceId, width, height)
                            assertEquals(WidgetSizeClass.Medium, base.sizeClass)
                            val presentation = base.copy(isStale = stale,
                                badgeText = if (stale) context.getString(R.string.widget_stale) else null)
                            val label = "${context.resources.configuration.locales} ${width}x$height @$scale stale=$stale apparent=$apparent"
                            assertFits(width, height, presentation)
                            val view = renderAt(presentation, width, height)
                            val reading = view.findViewById<TextView>(R.id.widget_apparent)
                            if (apparent == null) {
                                assertEquals("$label: missing data", View.GONE, reading.visibility)
                            } else {
                                assertEquals("$label: localized reading", presentation.apparentText, reading.text.toString())
                                // Multi-line wrapping may leave a trailing space
                                // outside getLineWidth's advance. Check every
                                // drawn line and glyph against all ancestor clips,
                                // with ellipsis forbidden, using the strict raster
                                // helper rather than the single-line advance check.
                                WidgetTextVisibility.assertVisible("$label: apparent", reading)
                                assertEquals("$label: every character is laid out", reading.text.length,
                                    reading.layout.getLineEnd(reading.lineCount - 1))
                                assertEquals("$label: full reading is accessible", presentation.apparentText,
                                    reading.createAccessibilityNodeInfo().text.toString())
                            }
                            val temperature = view.findViewById<TextView>(R.id.widget_temperature)
                            assertTextFits("$label: primary", temperature)
                            if (apparent != null) assertTrue("$label: primary remains prominent", temperature.textSize > reading.textSize)
                            val icon = view.findViewById<View>(R.id.widget_icon)
                            assertEquals("$label: full condition glyph", px(32), icon.width)
                            assertEquals(icon.width, icon.height)
                            val weather = view.findViewById<TextView>(R.id.widget_weather)
                            WidgetTextVisibility.assertVisible("$label: condition", weather, allowEllipsis = true)
                            assertTrue("$label: condition has readable space", weather.width >= px(9))
                            val (_, iconLeft) = offsetWithin(icon, view)
                            val (_, temperatureLeft) = offsetWithin(temperature, view)
                            assertTrue("$label: primary stays before condition", temperatureLeft + temperature.width <= iconLeft)
                            if (apparent != null) {
                                val (_, apparentLeft) = offsetWithin(reading, view)
                                assertTrue("$label: readings never overlap", temperatureLeft + temperature.width <= apparentLeft)
                                assertTrue("$label: apparent stays before condition", apparentLeft + reading.width <= iconLeft)
                            }
                            if (width == 320 && scale == 1f) {
                                assertTextFits("$label: roomy condition", weather)
                                if (apparent != null) assertEquals("$label: roomy apparent stays on one line", 1, reading.lineCount)
                            }
                        }
                    }
                }
            }
        }
    }

    @Test
    fun `a two-row widget gets a forecast that actually fits`() {
        // The 172 dp a Pixel 4x2 cell reports, and the shortest this layout
        // claims to fit.
        assertFits(250, 172)
        assertFits(320, 172)
        assertFits(250, WidgetPresenter.mediumMinimumHeightDp)
    }

    @Test
    fun `a three-row widget gets a forecast that fits`() {
        assertFits(250, 240)
    }

    @Test
    fun `Pixel three-row cells spend their height on details instead of leaving dead space`() {
        // Pixel 7 Pro, 5-column launcher: the measured 3x3 and 5x3 content
        // boxes are 218x307 and 373x307 dp; a Pixel 10a's 4x3 is 374x310. An
        // expanding forecast container with top-aligned wrap_content columns
        // left about 130 dp unused. A 307 dp cell is now the tall two-row layout
        // with both detail rows; from 308 dp a wide one is the large layout.
        for (width in listOf(218, 373)) {
            assertFits(width, 307)
            val view = layoutAt(width, 307)
            for (id in listOf(R.id.widget_grid_humidity_value, R.id.widget_grid_station_value)) {
                WidgetTextVisibility.assertVisible("$width x 307 detail", view.findViewById(id))
            }
            val station = view.findViewById<TextView>(R.id.widget_grid_station_value)
            val (top, _) = offsetWithin(station, view)
            assertTrue(
                "$width x 307: the details must finish near the bottom, not halfway down",
                view.height - (top + station.height) <= px(24),
            )
        }
    }

    @Test
    fun `the tall two-row layout fits from its first breakpoint`() {
        for (width in listOf(200, 250, 373)) {
            assertFits(width, WidgetPresenter.mediumTallMinimumHeightDp)
            assertFits(width, WidgetPresenter.mediumTallFullDetailHeightDp)
            assertFits(width, WidgetPresenter.largeMinimumHeightDp - 1)
        }
        withFontScale(1.3f) {
            assertFits(260, 300)
            assertFits(373, 400)
        }
    }

    @Test
    fun `Pixel three-row cells retain their header with an outdated notice`() {
        for (width in listOf(218, 373)) {
            val fresh = WidgetUpdater.presentation(context, instanceId, width, 307)
            val view = renderAt(
                fresh.copy(isStale = true, badgeText = context.getString(R.string.widget_stale)),
                width,
                307,
            )
            for (id in listOf(R.id.widget_location, R.id.widget_observation_time, R.id.widget_stale)) {
                WidgetTextVisibility.assertVisible(
                    "$width x 307 stale header",
                    view.findViewById(id),
                    allowEllipsis = true,
                )
            }
            assertTextFits("stale town at $width", view.findViewById(R.id.widget_location))
            assertTextFits("stale date at $width", view.findViewById(R.id.widget_observation_time))
            val notice = view.findViewById<View>(R.id.widget_stale)
            val (noticeTop, _) = offsetWithin(notice, view)
            val time = view.findViewById<View>(R.id.widget_observation_time)
            val (timeTop, _) = offsetWithin(time, view)
            assertTrue("the notice belongs below the header", noticeTop >= timeTop + time.height)
        }
        withFontScale(1.3f) {
            assertFits(218, 307)
            assertFits(373, 307)
        }
    }

    @Test
    fun `a current location mark stays beside the town instead of drifting towards the clock`() {
        for ((width, height) in listOf(110 to 110, 120 to 172, 218 to 202, 373 to 307, 373 to 344)) {
            val fresh = WidgetUpdater.presentation(context, instanceId, width, height)
            val view = renderAt(fresh.copy(isCurrentLocation = true), width, height)
            val town = view.findViewById<TextView>(R.id.widget_location)
            val mark = view.findViewById<View>(R.id.widget_location_icon)
            val (_, townLeft) = offsetWithin(town, view)
            val (_, markLeft) = offsetWithin(mark, view)
            assertTrue("$width x $height: location must follow town text", markLeft - townLeft - town.width <= px(4) + 1)
            assertTrue("$width x $height: location must not overlap town", markLeft >= townLeft + town.width)
        }
    }

    @Test
    fun `manual feedback and outdated data do not clip the shortest medium cell`() {
        for (width in listOf(200, 218, 373)) {
            for (height in listOf(170, 202, 280)) {
                val fresh = WidgetUpdater.presentation(context, instanceId, width, height)
                assertFits(width, height, fresh.copy(
                    isCurrentLocation = true,
                    isStale = true,
                    badgeText = context.getString(R.string.widget_stale),
                    refreshFeedback = WidgetRefreshFeedback.Running,
                ))
            }
        }
    }

    @Test
    fun `large tight stale data keeps all hourly lines inside launcher bounds`() {
        for ((width, height) in listOf(340 to 308, 373 to 308, 373 to 312, 374 to 310, 200 to 320, 250 to 320,
            200 to 335, 200 to 336)) {
            val fresh = WidgetUpdater.presentation(context, instanceId, width, height)
            for (feedback in listOf(null, WidgetRefreshFeedback.Running, WidgetRefreshFeedback.Failed)) {
                val stale = fresh.copy(isStale = true, badgeText = context.getString(R.string.widget_stale),
                    refreshFeedback = feedback)
                assertFits(width, height, stale)
                val view = renderAt(stale, width, height)
                WidgetTextVisibility.assertTree("$width x $height stale $feedback", view)
                assertEquals(View.VISIBLE, view.findViewById<View>(R.id.widget_stale).visibility)
                val hours = view.findViewById<ViewGroup>(R.id.widget_forecast_container)
                assertEquals(5, hours.childCount)
                for ((index, point) in stale.forecast.withIndex()) {
                    val column = hours.getChildAt(index)
                    assertEquals(point.time, column.findViewById<TextView>(R.id.widget_forecast_time).text.toString())
                    assertEquals(point.temperatureText,
                        column.findViewById<TextView>(R.id.widget_forecast_temperature).text.toString())
                    val pop = column.findViewById<TextView>(R.id.widget_forecast_pop)
                    assertEquals(point.popText, pop.text.toString())
                    assertTrue("probability remains accessible", !pop.contentDescription.isNullOrBlank())
                    assertTrue("hour remains an accessibility group", column.isFocusable)
                    assertTrue("weather icon remains accessible",
                        !column.findViewById<View>(R.id.widget_forecast_icon).contentDescription.isNullOrBlank())
                }
            }
        }
    }

    @Test
    fun `hidden refresh gives its width back to each responsive layout`() {
        for ((width, height) in listOf(110 to 110, 120 to 172, 200 to 170, 200 to 320, 250 to 344)) {
            val base = WidgetUpdater.presentation(context, instanceId, width, height)
            val hidden = renderAt(base, width, height)
            val shown = renderAt(base.copy(refreshFeedback = WidgetRefreshFeedback.Failed), width, height)
            assertRefreshFits("$width x $height fresh", hidden, visible = false)
            assertRefreshFits("$width x $height failed", shown, visible = true)
            // Small's action shares the temperature row; every other variant
            // shares the town header. Both must reclaim the action and margins.
            fun expandedBudget(view: View): View {
                if (base.sizeClass == WidgetSizeClass.Small && !base.compactLayout) {
                    return view.findViewById(R.id.widget_temperature)
                }
                // The town itself keeps its intrinsic width so its location
                // mark stays adjacent. Its weighted outer group owns the slack.
                return view.findViewById<View>(R.id.widget_location).parent.parent as View
            }
            assertTrue("$width x $height: GONE must release horizontal space",
                expandedBudget(hidden).width > expandedBudget(shown).width)
            for (id in listOf(R.id.widget_location, R.id.widget_observation_time, R.id.widget_temperature)) {
                assertTextFits("$width x $height hidden", hidden.findViewById(id))
                assertTextFits("$width x $height failed", shown.findViewById(id))
            }
        }
    }

    @Test
    fun `feedback glyph changes never move content while the refresh action is visible`() {
        for ((width, height) in listOf(110 to 110, 120 to 172, 218 to 202, 373 to 320, 373 to 344)) {
            val base = WidgetUpdater.presentation(context, instanceId, width, height)
                .copy(isStale = true, badgeText = context.getString(R.string.widget_stale))
            fun bounds(feedback: WidgetRefreshFeedback?): List<List<Int>> {
                val view = renderAt(base.copy(refreshFeedback = feedback), width, height)
                return listOf(R.id.widget_location, R.id.widget_observation_time,
                    R.id.widget_temperature, R.id.widget_icon, R.id.widget_refresh,
                    R.id.widget_forecast_container).mapNotNull { id ->
                    view.findViewById<View>(id)?.let {
                        val (top, left) = offsetWithin(it, view)
                        listOf(id, top, left, it.width, it.height)
                    }
                }
            }
            val idle = bounds(null)
            for (feedback in WidgetRefreshFeedback.entries) {
                assertEquals("$width x $height $feedback must not shift content", idle, bounds(feedback))
            }
        }
    }

    @Test
    fun `roomy Android 12 cells have 48dp actions without enlarging the glyphs`() {
        fun withRefresh(width: Int) = renderAt(
            WidgetUpdater.presentation(context, instanceId, width, 280)
                .copy(refreshFeedback = WidgetRefreshFeedback.Failed), width, 280,
        )
        val view = withRefresh(373)
        val expectedDp = if (android.os.Build.VERSION.SDK_INT >= 31) 48 else 28
        for (id in listOf(R.id.widget_refresh)) {
            val action = view.findViewById<View>(id)
            assertTrue("roomy target", kotlin.math.abs(action.width - px(expectedDp)) <= 1)
            assertTrue("square target", kotlin.math.abs(action.height - px(expectedDp)) <= 1)
            assertTrue("the glyph stays 20dp", kotlin.math.abs(action.width - action.paddingLeft - action.paddingRight - px(20)) <= 1)
        }
        val narrow = withRefresh(218).findViewById<View>(R.id.widget_refresh)
        assertTrue("narrow headers preserve text width", kotlin.math.abs(narrow.width - px(28)) <= 1)
    }

    @Test
    @Config(sdk = [35], qualifiers = "420dpi")
    fun `resizing a reused roomy view restores narrow targets instead of hiding the town`() {
        val view = renderAt(WidgetUpdater.presentation(context, instanceId, 373, 280)
            .copy(refreshFeedback = WidgetRefreshFeedback.Failed), 373, 280)
        val narrow = WidgetUpdater.presentation(context, instanceId, 218, 280)
        WidgetRenderer.render(context, narrow.copy(isCurrentLocation = true,
            refreshFeedback = WidgetRefreshFeedback.Failed), instanceId).reapply(context, view)
        view.measure(
            View.MeasureSpec.makeMeasureSpec(px(218), View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(px(280), View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, px(218), px(280))
        for (id in listOf(R.id.widget_refresh)) {
            assertTrue("reapply restores 28dp", kotlin.math.abs(view.findViewById<View>(id).width - px(28)) <= 1)
        }
        assertTextFits("resized town", view.findViewById(R.id.widget_location))
    }

    @Test
    fun `the medium current-weather icon is more prominent than the hourly icons without clipping`() {
        for (width in listOf(218, 373)) {
            for (height in listOf(170, 202, 280)) {
                assertFits(width, height)
                val view = layoutAt(width, height)
                val icon = view.findViewById<View>(R.id.widget_icon)
                assertTrue("$width x $height: the current condition needs a 32dp glyph", icon.width >= px(32))
                assertEquals("the condition glyph stays square", icon.width, icon.height)
                val hours = view.findViewById<ViewGroup>(R.id.widget_forecast_container)
                val hourlyIcon = hours.getChildAt(0).findViewById<View>(R.id.widget_forecast_icon)
                assertTrue("the current condition must lead the hourly glyphs", icon.width > hourlyIcon.width)
            }
        }
    }

    @Test
    fun `a four-row widget gets every line without clipping`() {
        assertFits(250, 344)
        assertFits(320, 344)
        assertFits(250, WidgetPresenter.largeMinimumHeightDp)
    }

    @Test
    fun `the narrowest supported widget fits`() {
        // Below 200 dp the square layout is selected; a 110 dp tall box is
        // shorter than the square layout's own budget, so it is the compact
        // fallback.
        assertFits(199, 110)
        assertFits(200, 110)
        assertFits(250, 110)
    }

    @Test
    fun `a normal square widget fills its cell`() {
        // 120x172 is a Pixel 2x2 cell and the measured box the compact fallback
        // must not take over; 158x158 is the iOS square.
        assertFits(120, 172)
        assertFits(158, 158)
    }

    @Test
    fun `the smallest widget the metadata promises still reads`() {
        // The metadata declares 110×110 dp, so a launcher may hand exactly that
        // to the compact layout. This is the fresh case, the stale badge, and the
        // same box under a large system font.
        assertFits(110, 110)

        WidgetClock.invalidate()
        assertFits(110, 110)

        withFontScale(1.3f) { assertFits(110, 110) }
    }

    /**
     * The ellipsis a one-line `TextView` had to apply, or 0 when the whole text
     * fits.
     *
     * `width > 0` is not enough: a column can have a width and still show
     * nothing but "…", which is exactly what the 110 dp town did before this
     * test existed. The number of characters dropped is the honest measure.
     */
    private fun ellipsizedCharacters(view: TextView): Int = view.layout?.getEllipsisCount(0) ?: 0

    /**
     * That a line is drawn whole: no ellipsis, and the laid-out line is no wider
     * than the view that holds it.
     *
     * `text.isNotEmpty()` and `width > 0` both pass for a `TextView` that clipped
     * its own string — the square layout's rainfall value was laid out at 84 px
     * while "0.4 mm" needed 104, so the last `m` never existed on screen. The
     * ellipsis count and the measured line width are what catch that.
     */
    private fun assertTextFits(label: String, view: TextView) {
        WidgetTextVisibility.assertVisible(label, view)
        val layout = view.layout
        assertNotNull("$label has no layout", layout)
        assertEquals(
            "$label must not ellipsise '${view.text}'",
            0,
            layout!!.getEllipsisCount(0),
        )
        assertTrue(
            "$label's line (${layout.getLineWidth(0)}px) is wider than its view (${view.width}px)",
            layout.getLineWidth(0) <= view.width + 1f,
        )
        assertTrue("$label has no line height", layout.height > 0)
    }

    /**
     * Renders a production presentation at 110×110 dp and lays it out at exactly
     * that size, then asserts the three things the smallest box must not lose:
     * a town that is actually its name, a wall clock that kept its `HH:mm`, and
     * a refresh action that can be tapped when recovery is actionable.
     */
    private fun assertMinimalReadable(label: String, presentation: WidgetPresentation) {
        val view = WidgetRenderer.render(context, presentation, instanceId)
            .apply(context, FrameLayout(context))
        val px = px(110)
        view.measure(
            View.MeasureSpec.makeMeasureSpec(px, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(px, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, px, px)

        val town = view.findViewById<TextView>(R.id.widget_location)
        assertEquals("$label: the town must be its whole name", "西屯區", town.text.toString())
        assertEquals("$label: the town must not be ellipsised", 0, ellipsizedCharacters(town))

        val clock = view.findViewById<TextView>(R.id.widget_observation_time)
        assertTrue("$label: the clock must keep 14:05 but read '${clock.text}'", clock.text.contains("14:05"))
        assertEquals("$label: the clock must not be ellipsised", 0, ellipsizedCharacters(clock))

        assertRefreshFits(label, view, presentation.showRefresh)
    }

    @Test
    fun `the smallest widget keeps its town and clock at every font size`() {
        for (invalidate in listOf(false, true)) {
            for (scale in listOf(1.0f, 1.3f)) {
                withFontScale(scale) {
                    if (invalidate) {
                        WidgetClock.invalidate()
                    } else {
                        WidgetClock.installForTest(
                            atTaipei(14, 20),
                            android.os.SystemClock.elapsedRealtime(),
                        )
                    }
                    reportSize(110, 110)
                    val presentation = WidgetUpdater.presentation(context, instanceId, 110, 110)
                    assertEquals(WidgetSizeClass.Small, presentation.sizeClass)
                    assertMinimalReadable("110x110 @ $scale stale=$invalidate", presentation)
                }
            }
        }
    }

    @Test
    fun `the smallest widget keeps its town and clock under a long notice`() {
        // A retryable position failure and non-retryable app-attention states
        // must keep their town and clock in the same minimum box at large font.
        withFontScale(1.3f) {
            reportSize(110, 110)
            val notice = "POSITION IS OUTSIDE EVERY COVERED TOWNSHIP AND CANNOT BE RESOLVED"
            for (degradation in listOf(WidgetLocationDegradation.UnresolvedTownship,
                WidgetLocationDegradation.Permission, WidgetLocationDegradation.Disabled)) {
                val retryable = degradation == WidgetLocationDegradation.UnresolvedTownship
                val presentation = WidgetPresenter.present(
                    sizeClass = WidgetPresenter.sizeClass(110, 110, 1.3f),
                    strings = strings.copy(locationOutside = notice, needsApp = notice, locationDisabled = notice),
                    address = WidgetAddress.CurrentLocation,
                    locationName = "西屯區",
                    stored = store.readCurrentWeather(WidgetAddress.Saved("407")),
                    forecast = null,
                    locationDegradation = degradation,
                    isCatalogMember = true,
                    calibratedNowMilliseconds = atTaipei(14, 20),
                    latitude = 24.181,
                    longitude = 120.645,
                    availableWidthDp = 110,
                    availableHeightDp = 110,
                    fontScale = 1.3f,
                )
                assertEquals(if (retryable) WidgetDisplayState.LocationUnavailable else WidgetDisplayState.NeedsApp,
                    presentation.state)
                assertEquals(retryable, presentation.canRefresh)
                assertEquals(retryable, presentation.showRefresh)

                val view = renderAt(presentation, 110, 110)
                WidgetTextVisibility.assertTree("$degradation long notice", view)
                for (leaf in leaves(view).filter { it.visibility == View.VISIBLE }) {
                    val (top, left) = offsetWithin(leaf, view)
                    assertTrue("$degradation: valid bounds for ${nameOf(leaf)}",
                        top >= 0 && left >= 0 && top + leaf.height <= view.height && left + leaf.width <= view.width)
                }
                val town = view.findViewById<TextView>(R.id.widget_location)
                assertEquals("the town must survive the notice", "西屯區", town.text.toString())
                assertTextFits("$degradation town", town)

                val clock = view.findViewById<TextView>(R.id.widget_observation_time)
                assertEquals("14:05", clock.text.toString())
                assertEquals("2026/10/12 14:05", clock.contentDescription.toString())
                assertTextFits("$degradation clock", clock)

                val badge = view.findViewById<TextView>(R.id.widget_stale)
                assertEquals("the notice must actually be shown", View.VISIBLE, badge.visibility)
                assertEquals(context.getString(if (retryable) R.string.widget_compact_location else R.string.widget_compact_attention),
                    badge.text.toString())
                WidgetTextVisibility.assertVisible("$degradation concise badge", badge)
                assertTrue("the full notice must be accessible", view.contentDescription.contains(notice))
                assertRefreshFits("$degradation long notice", view, visible = retryable)
                val refresh = view.findViewById<View>(R.id.widget_refresh)
                assertEquals(retryable, refresh.isEnabled)
                assertEquals(retryable, refresh.hasOnClickListeners())
                if (retryable) {
                    assertEquals(context.getString(R.string.widget_refresh), refresh.contentDescription.toString())
                    // Android leaves node flags empty until a view is attached.
                    // A JVM activity supplies that host without a device.
                    val host = Robolectric.buildActivity(Activity::class.java).setup().visible()
                    try {
                        host.get().setContentView(view)
                        val node = refresh.createAccessibilityNodeInfo()
                        assertTrue("retry must be accessible as an enabled action", node.isEnabled && node.isClickable)
                        assertEquals(refresh.contentDescription, node.contentDescription)
                    } finally {
                        host.pause().stop().destroy()
                    }
                }
            }
        }
    }

    @Test
    fun `the layouts still fit with a large system font`() {
        withFontScale(1.3f) {
            assertFits(250, 172)
            assertFits(250, 240)
            assertFits(250, 344)
            assertFits(199, 110)
        }
    }

    @Test
    fun `a long position notice does not overflow the widget`() {
        // The layout's own text, not a hand-built one: the notice is the longest
        // the app can produce, and the badge is capped and ellipsised so it
        // cannot push the row wider than the widget it lives in. Rendered through
        // the presenter, because the badge text is what the presenter composes.
        val notice = "POSITION IS OUTSIDE EVERY COVERED TOWNSHIP AND CANNOT BE RESOLVED"
        val sizes = listOf(
            250 to 110,
            200 to 110,
            199 to 110,
            110 to 110,
            250 to 172,
            250 to 344,
        )
        for ((widthDp, heightDp) in sizes) {
            for (scale in listOf(1.0f, 1.3f)) {
                withFontScale(scale) {
                    assertFits(
                        widthDp = widthDp,
                        heightDp = heightDp,
                        presentation = WidgetPresenter.present(
                            sizeClass = WidgetPresenter.sizeClass(widthDp, heightDp, scale),
                            strings = strings.copy(locationOutside = notice),
                            address = WidgetAddress.CurrentLocation,
                            locationName = "西屯區",
                            stored = store.readCurrentWeather(WidgetAddress.Saved("407")),
                            forecast = store.readForecast(WidgetAddress.Saved("407")),
                            locationDegradation =
                                WidgetLocationDegradation.UnresolvedTownship,
                            isCatalogMember = true,
                            calibratedNowMilliseconds = atTaipei(14, 20),
                            latitude = 24.181,
                            longitude = 120.645,
                            availableWidthDp = widthDp,
                            availableHeightDp = heightDp,
                            fontScale = scale,
                        ),
                    )
                }
            }
        }
    }

    @Test
    fun `the size class follows the height a launcher can actually give`() {
        assertEquals(WidgetSizeClass.Small, WidgetPresenter.sizeClass(199, 344))
        assertEquals(WidgetSizeClass.Small, WidgetPresenter.sizeClass(250, 110))
        assertEquals(WidgetSizeClass.Small, WidgetPresenter.sizeClass(250, 169))
        assertEquals(WidgetSizeClass.Medium, WidgetPresenter.sizeClass(250, 170))
        assertEquals(WidgetSizeClass.Medium, WidgetPresenter.sizeClass(340, 307))
        assertEquals(WidgetSizeClass.Medium, WidgetPresenter.sizeClass(339, 319))
        assertEquals(WidgetSizeClass.Large, WidgetPresenter.sizeClass(340, 308))
        // A large system font needs proportionally more height, so the same box
        // gets a smaller layout rather than clipped text.
        assertEquals(WidgetSizeClass.Small, WidgetPresenter.sizeClass(250, 172, fontScale = 1.3f))
        assertEquals(WidgetSizeClass.Medium, WidgetPresenter.sizeClass(320, 230, fontScale = 1.3f))
    }

    @Test
    fun `the square layout's compact threshold is exactly its own budget`() {
        // The normal square budget is 118x168; one dp under either edge is the
        // compact fallback. Both sides are rendered, not just asserted, so the
        // boundary is a layout fact rather than a constant. The height budget is
        // measured with a visible notice, not just the fresh state's boxes.
        assertTrue(WidgetPresenter.compactLayout(117, 172))
        assertTrue(WidgetPresenter.compactLayout(118, 167))
        assertTrue(!WidgetPresenter.compactLayout(118, 168))
        assertFits(118, 168)
        assertFits(117, 172)
        assertFits(118, 167)
    }

    // ── The metric row and the header carry whole strings ───────────────────

    @Test
    fun `normal threshold footer has a complete visible text layout`() {
        assertMetricRowWhole("normal threshold", layoutAt(118, 168), "78%", "0.4 mm")
        WidgetClock.invalidate()
        assertMetricRowWhole("stale normal threshold", layoutAt(118, 168), "78%", "0.4 mm")
        assertTrue("old threshold must explicitly fall back", WidgetPresenter.compactLayout(118, 152))
        assertMetricRowWhole("compact footer", layoutAt(118, 152), "78%", "0.4 mm")
    }

    /** Commits the one snapshot the metric/header tests vary. */
    private fun commitSnapshot(
        regionName: String = "西屯區",
        stationName: String = "西屯",
        humidity: Int? = 78,
        rain: Double? = 0.4,
        temperature: Double? = 27.5,
        source: String = "region:407",
        address: WidgetAddress = WidgetAddress.Saved("407"),
    ) {
        store.commitCurrentWeather(
            store.beginCurrentWeatherWrite(address)!!,
            CurrentWeatherSnapshot(
                schemaVersion = 7,
                sourceIdentifier = source,
                regionCode = "407",
                regionName = regionName,
                observationTime = atTaipei(14, 5) / 1_000,
                stationName = stationName,
                weather = "多雲有雨",
                weatherCode = 206,
                condition = WeatherCondition.Rain,
                isNight = false,
                nextDayNightTransitionTime = atTaipei(18, 0) / 1_000,
                calibratedTimeOffsetMilliseconds = 0,
                temperature = temperature,
                humidity = humidity,
                rain = rain,
                windDirection = "北北西",
                windSpeed = 1.3,
                apparentTemperature = 30.2,
            ),
            writtenAt = 1L,
        )
    }

    /** The production presentation for a measured box, laid out at exactly it. */
    private fun layoutAt(widthDp: Int, heightDp: Int): View {
        reportSize(widthDp, heightDp)
        val presentation = WidgetUpdater.presentation(context, instanceId, widthDp, heightDp)
        return renderAt(presentation, widthDp, heightDp)
    }

    private fun renderAt(presentation: WidgetPresentation, widthDp: Int, heightDp: Int): View {
        val view = WidgetRenderer.render(context, presentation, instanceId)
            .apply(context, FrameLayout(context))
        view.measure(
            View.MeasureSpec.makeMeasureSpec(px(widthDp), View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(px(heightDp), View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, px(widthDp), px(heightDp))
        return view
    }

    private fun assertMetricRowWhole(label: String, view: View, humidity: String, rain: String) {
        val humidityValue = view.findViewById<TextView>(R.id.widget_humidity_value)
        val rainValue = view.findViewById<TextView>(R.id.widget_rain_value)
        assertEquals("$label: the humidity reading must be whole", humidity, humidityValue.text.toString())
        assertEquals("$label: the rainfall reading must be whole", rain, rainValue.text.toString())
        assertTextFits("$label: humidity", humidityValue)
        assertTextFits("$label: rainfall", rainValue)
    }

    @Test
    fun `the square metric row shows the whole reading at every value`() {
        // 78% / 0.4 mm fits; 100% / 100.0 mm must autosize rather than clip; a
        // missing reading keeps its placeholder. The last `m` of "0.4 mm" was
        // laid out off the view before the values carried an autosize range.
        val cases = listOf(
            Triple(78, 0.4, "78%" to "0.4 mm"),
            Triple(100, 100.0, "100%" to "100.0 mm"),
            Triple(null, null, "--%" to "-- mm"),
        )
        for ((humidity, rain, expected) in cases) {
            commitSnapshot(humidity = humidity, rain = rain)
            for ((widthDp, heightDp) in listOf(120 to 172, 118 to 168, 158 to 168)) {
                val label = "$humidity/$rain at ${widthDp}x$heightDp"
                val view = layoutAt(widthDp, heightDp)
                assertMetricRowWhole(label, view, expected.first, expected.second)
            }
        }
    }

    @Test
    fun `a stale square still shows its whole reading and its notice`() {
        WidgetClock.invalidate()
        val presentation = WidgetUpdater.presentation(context, instanceId, 120, 172)
        val view = renderAt(presentation, 120, 172)
        assertMetricRowWhole("stale 120x172", view, "78%", "0.4 mm")
        assertEquals(
            "the stale notice must be shown",
            View.VISIBLE,
            view.findViewById<View>(R.id.widget_stale).visibility,
        )
        val town = view.findViewById<TextView>(R.id.widget_location)
        assertEquals("西屯區", town.text.toString())
        assertTextFits("stale town", town)
    }

    @Test
    fun `a degraded square keeps the town and the reading`() {
        val presentation = WidgetPresenter.present(
            sizeClass = WidgetSizeClass.Small,
            strings = strings,
            address = WidgetAddress.CurrentLocation,
            locationName = "西屯區",
            stored = store.readCurrentWeather(WidgetAddress.Saved("407")),
            forecast = null,
            locationDegradation = WidgetLocationDegradation.Permission,
            isCatalogMember = true,
            calibratedNowMilliseconds = atTaipei(14, 20),
            latitude = 24.181,
            longitude = 120.645,
            availableWidthDp = 120,
            availableHeightDp = 172,
            fontScale = 1f,
        )
        assertEquals(WidgetDisplayState.NeedsApp, presentation.state)
        val view = renderAt(presentation, 120, 172)
        assertMetricRowWhole("needs-app 120x172", view, "78%", "0.4 mm")
        val town = view.findViewById<TextView>(R.id.widget_location)
        assertEquals("西屯區", town.text.toString())
        assertTextFits("needs-app town", town)
        assertEquals(
            "the position notice must be shown",
            View.VISIBLE,
            view.findViewById<View>(R.id.widget_stale).visibility,
        )
        val position = view.findViewById<View>(R.id.widget_location_icon)
        assertEquals("a Current Location shows the location mark", View.VISIBLE, position.visibility)
    }

    @Test
    fun `a long town autosizes instead of vanishing`() {
        commitSnapshot(regionName = "新北市板橋區", stationName = "板橋")
        val view = layoutAt(120, 172)
        val town = view.findViewById<TextView>(R.id.widget_location)
        assertEquals("新北市板橋區", town.text.toString())
        assertTrue("the long town must keep a readable width", town.width > px(30))
    }

    // ── The large header keeps the town and clock at a narrow cell ──────────

    private fun assertLargeHeaderReads(label: String, view: View, refreshVisible: Boolean = false) {
        val town = view.findViewById<TextView>(R.id.widget_location)
        val time = view.findViewById<TextView>(R.id.widget_observation_time)
        assertRefreshFits(label, view, refreshVisible)
        assertTextFits("$label: town", town)
        assertTextFits("$label: observation clock", time)
        assertEquals("$label: observation uses HH:mm", "14:05", time.text.toString())
        // The grid values autosize rather than ellipsise at the narrow cell.
        for (id in listOf(
            R.id.widget_grid_humidity_value,
            R.id.widget_grid_rain_value,
            R.id.widget_grid_sun_value,
            R.id.widget_grid_wind_value,
            R.id.widget_grid_station_value,
        )) {
            assertTextFits("$label: ${context.resources.getResourceEntryName(id)}", view.findViewById(id))
        }
    }

    @Test
    fun `the large header keeps the town and clock at the narrowest cell`() {
        // The presenter allows Large from 200x320; the header used to spend the
        // whole width on the long date and two 28 dp actions and leave the town
        // ~10 dp. Both the roomy (iOS-spaced) and the tight layout are measured.
        for ((widthDp, heightDp) in listOf(
            200 to 320,
            250 to 320,
            250 to 344,
            320 to 344,
        )) {
            assertFits(widthDp, heightDp)
            assertLargeHeaderReads("large $widthDp x $heightDp", layoutAt(widthDp, heightDp))
            WidgetTextVisibility.assertVisible(
                "large weather $widthDp x $heightDp",
                layoutAt(widthDp, heightDp).findViewById(R.id.widget_weather),
                allowEllipsis = true,
            )
        }
    }

    @Test
    fun `the large header survives stale, current and degraded states at 200dp`() {
        // A fresh saved town: no notice.
        val freshSaved = WidgetUpdater.presentation(context, instanceId, 200, 320)
        reportSize(200, 320)
        assertLargeHeaderReads("200x320 fresh", renderAt(freshSaved, 200, 320))
        assertEquals(
            View.GONE,
            renderAt(freshSaved, 200, 320).findViewById<View>(R.id.widget_stale).visibility,
        )

        // A Current Location: the town and the location mark, still no notice.
        store.writeInstance(instanceId, WidgetAddress.CurrentLocation, null, 1L)
        commitSnapshot(source = "current-location", address = WidgetAddress.CurrentLocation)
        val current = WidgetUpdater.presentation(context, instanceId, 200, 320)
        val currentView = renderAt(current, 200, 320)
        assertLargeHeaderReads("200x320 current without forecast", currentView, refreshVisible = true)
        assertEquals(
            View.VISIBLE,
            currentView.findViewById<View>(R.id.widget_location_icon).visibility,
        )
        assertEquals(
            View.GONE,
            currentView.findViewById<View>(R.id.widget_stale).visibility,
        )

        // A stale saved town: the notice must appear and the town must survive it.
        val stale = WidgetPresenter.present(
            sizeClass = WidgetSizeClass.Large,
            strings = strings,
            address = WidgetAddress.Saved("407"),
            locationName = "西屯區",
            stored = store.readCurrentWeather(WidgetAddress.Saved("407")),
            forecast = store.readForecast(WidgetAddress.Saved("407")),
            locationDegradation = null,
            isCatalogMember = true,
            calibratedNowMilliseconds = null,
            latitude = 24.181,
            longitude = 120.645,
            availableWidthDp = 200,
            availableHeightDp = 320,
        )
        val staleView = renderAt(stale, 200, 320)
        assertLargeHeaderReads("200x320 stale", staleView, refreshVisible = true)
        assertEquals(
            "the stale notice must be shown",
            View.VISIBLE,
            staleView.findViewById<View>(R.id.widget_stale).visibility,
        )

        // A degraded Current Location: the position notice must appear too.
        store.writeInstance(instanceId, WidgetAddress.CurrentLocation, null, 1L)
        val needsApp = WidgetPresenter.present(
            sizeClass = WidgetSizeClass.Large,
            strings = strings,
            address = WidgetAddress.CurrentLocation,
            locationName = "西屯區",
            stored = store.readCurrentWeather(WidgetAddress.CurrentLocation),
            forecast = null,
            locationDegradation = WidgetLocationDegradation.Permission,
            isCatalogMember = true,
            calibratedNowMilliseconds = atTaipei(14, 20),
            latitude = 24.181,
            longitude = 120.645,
            availableWidthDp = 200,
            availableHeightDp = 320,
        )
        val needsAppView = renderAt(needsApp, 200, 320)
        assertLargeHeaderReads("200x320 needs-app", needsAppView)
        assertEquals(
            "the position notice must be shown",
            View.VISIBLE,
            needsAppView.findViewById<View>(R.id.widget_stale).visibility,
        )
    }

    @Test
    fun `a long town in the large header still reads at 200dp`() {
        commitSnapshot(regionName = "新北市板橋區", stationName = "板橋")
        reportSize(200, 320)
        val view = renderAt(WidgetUpdater.presentation(context, instanceId, 200, 320), 200, 320)
        val town = view.findViewById<TextView>(R.id.widget_location)
        assertEquals("新北市板橋區", town.text.toString())
        // A six-character town cannot be whole at 200 dp; the contract is that it
        // stays readable and autosizes rather than being pushed to nothing, and
        // that the date and refresh action still fit beside it.
        assertTrue("the long town must keep a readable width", town.width > px(40))
        assertTextFits("200x320 long date", view.findViewById(R.id.widget_observation_time))
        assertEquals(
            View.GONE,
            view.findViewById<View>(R.id.widget_refresh).visibility,
        )
    }

    /** The strings the production presenter uses, for the locale tests. */
    private fun assertMediumFitsAtTheRealCell() {
        // 250x172 is the Pixel 4x2 cell.
        assertFits(250, 172)
        val view = layoutAt(250, 172)
        assertTextFits("medium town", view.findViewById(R.id.widget_location))
        assertTextFits("medium date", view.findViewById(R.id.widget_observation_time))
    }

    @Test
    fun `the medium cell keeps its town and date`() {
        assertMediumFitsAtTheRealCell()
    }

    // The metric values are locale-formatted (`%.1f`), and a locale with wider
    // glyphs must still fit the row whole. `zh-rTW`/`zh-rHK` share the town
    // strings; `th` is the widest of the shipped ones.

    private fun assertLocaleMatrix() {
        for (scale in listOf(1f, 1.3f)) {
            withFontScale(scale) {
                for ((humidity, rain, expected) in listOf(
                    Triple(78, 0.4, "78%" to "0.4 mm"),
                    Triple(100, 100.0, "100%" to "100.0 mm"),
                    Triple(null, null, "--%" to "-- mm"),
                )) {
                    commitSnapshot(humidity = humidity, rain = rain)
                    // At large font the actual Pixel box explicitly uses compact;
                    // a proportionally taller/wider normal box still keeps both
                    // readings. No normal presentation may silently lose its row.
                    val width = if (scale == 1f) 118 else 156
                    val height = if (scale == 1f) 168 else 224
                    for (state in listOf("fresh", "stale", "needs-app")) {
                        val presentation = WidgetPresenter.present(
                            sizeClass = WidgetSizeClass.Small,
                            strings = WidgetUpdater.strings(context),
                            address = if (state == "needs-app") WidgetAddress.CurrentLocation else WidgetAddress.Saved("407"),
                            locationName = "西屯區",
                            stored = store.readCurrentWeather(WidgetAddress.Saved("407")),
                            forecast = null,
                            locationDegradation = if (state == "needs-app") WidgetLocationDegradation.Permission else null,
                            isCatalogMember = true,
                            calibratedNowMilliseconds = if (state == "stale") null else atTaipei(14, 20),
                            latitude = 24.181,
                            longitude = 120.645,
                            availableWidthDp = width,
                            availableHeightDp = height,
                            fontScale = scale,
                        )
                        assertTrue("normal matrix must exercise normal", !presentation.compactLayout)
                        assertMetricRowWhole("$scale $state $expected", renderAt(presentation, width, height), expected.first, expected.second)
                        if (state != "fresh") {
                            assertEquals(View.VISIBLE, renderAt(presentation, width, height).findViewById<View>(R.id.widget_stale).visibility)
                        }
                    }
                }
                assertFits(120, 172)
                assertFits(320, 172)
                assertFits(200, 320)
                assertFits(250, 344)
                assertFits(320, 344)
                if (scale > 1f) {
                    assertFits(320, 230)
                    assertFits(320, 450)
                }
                commitSnapshot(regionName = "新北市板橋區", stationName = "臺灣臺北板橋自動氣象觀測站")
                assertFits(120, 172)
                assertFits(320, 172)
                assertFits(320, if (scale == 1f) 344 else 450)
            }
        }
    }

    @Test
    @Config(sdk = [26, 35], qualifiers = "zh-rTW-420dpi")
    fun `the square metric row is whole in zh-rTW`() {
        assertLocaleMatrix()
    }

    @Test
    @Config(sdk = [26, 35], qualifiers = "zh-rHK-420dpi")
    fun `the square metric row is whole in zh-rHK`() {
        assertLocaleMatrix()
    }

    @Test
    @Config(sdk = [26, 35], qualifiers = "th-420dpi")
    fun `the square metric row is whole in Thai`() {
        assertLocaleMatrix()
        commitSnapshot()
        val view = layoutAt(120, 172)
        assertTextFits("th humidity", view.findViewById(R.id.widget_humidity_value))
        assertTextFits("th rainfall", view.findViewById(R.id.widget_rain_value))
        assertTextFits("th town", view.findViewById(R.id.widget_location))
        assertTextFits("th clock", view.findViewById(R.id.widget_observation_time))
        assertTrue(
            "th rainfall must keep its unit",
            view.findViewById<TextView>(R.id.widget_rain_value).text.contains("mm"),
        )
    }
}
