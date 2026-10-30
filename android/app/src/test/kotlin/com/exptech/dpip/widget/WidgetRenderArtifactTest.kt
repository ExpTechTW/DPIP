package com.exptech.dpip.widget

import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.FrameLayout
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
import java.io.FileOutputStream
import java.time.LocalDateTime
import java.time.ZoneOffset

/**
 * Renders the real `RemoteViews` for each family, at the real sizes, into PNGs.
 *
 * The layout-fit suite proves nothing is clipped; it says nothing about what the
 * widget *looks like*. These artifacts are the visual half: the production
 * renderer, applied and drawn through Robolectric's native graphics, at the
 * sizes a launcher reports, in both the light and the dark palette. They are
 * written under `build/widget-previews/` for a human to look at, and each test
 * also asserts the bitmap is not blank, so a broken render fails rather than
 * producing a silently empty file. The glyph sheet draws the icon set the
 * renderer chooses from on that same rasterizer: a blank or malformed vector
 * path is only ever visible that way.
 *
 * The fixture is fixed — the same 西屯區 snapshot and forecast `WidgetUpdater`
 * would draw — so the images are comparable between runs. It is not an iOS
 * screenshot: with no captured iOS frame available these are the Android side of
 * a source-level restatement, not a pixel diff.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], qualifiers = "420dpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WidgetRenderArtifactTest {
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

    private fun px(dp: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        dp.toFloat(),
        context.resources.displayMetrics,
    ).toInt()

    /** Applies the production RemoteViews at the reported size and draws it. */
    private fun render(widthDp: Int, heightDp: Int, presentationOverride: WidgetPresentation? = null): Bitmap {
        WidgetUpdater.optionsProvider = { _, id ->
            Bundle().apply {
                if (id == instanceId) {
                    putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, widthDp)
                    putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, heightDp)
                }
            }
        }
        val presentation = presentationOverride ?: WidgetUpdater.presentation(context, instanceId, widthDp, heightDp)
        val view = WidgetRenderer.render(context, presentation, instanceId)
            .apply(context, FrameLayout(context))
        val widthPx = px(widthDp)
        val heightPx = px(heightDp)
        view.measure(
            android.view.View.MeasureSpec.makeMeasureSpec(widthPx, android.view.View.MeasureSpec.EXACTLY),
            android.view.View.MeasureSpec.makeMeasureSpec(heightPx, android.view.View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, widthPx, heightPx)
        WidgetTextVisibility.assertTree("${widthDp}x$heightDp", view)
        assertImportantTextNotCropped(view, "${widthDp}x$heightDp", presentation)
        val refresh = view.findViewById<View>(R.id.widget_refresh)
        assertEquals("$widthDp x $heightDp: refresh visibility",
            if (presentation.showRefresh) View.VISIBLE else View.GONE, refresh.visibility)
        if (!presentation.showRefresh) {
            assertTrue("hidden refresh must not retain a tap target", !refresh.isEnabled && !refresh.hasOnClickListeners())
        }
        view.findViewById<TextView>(R.id.widget_observation_time)?.let {
            assertEquals("14:05", it.text.toString())
            assertEquals("2026/10/12 14:05", it.contentDescription.toString())
        }

        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        // A flat backdrop, so the translucent container is visible rather than
        // composited onto whatever the PNG viewer chooses.
        canvas.drawColor(if (isNight()) Color.parseColor("#11151C") else Color.parseColor("#DDE3EA"))
        view.draw(canvas)
        return bitmap
    }

    private fun isNight(): Boolean =
        (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES

    private fun write(name: String, bitmap: Bitmap) {
        val directory = File("build/widget-previews").apply { mkdirs() }
        val file = File(directory, "$name.png")
        FileOutputStream(file).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        assertTrue("the artifact must not be blank: ${file.absolutePath}", notBlank(bitmap))
        println("widget-preview: ${file.absolutePath}")
    }

    /**
     * That the lines the widget must never crop are drawn whole: the town, the
     * observation clock, the square metric values and the forecast probability.
     * A crop here is exactly what the previous revision shipped — the rainfall
     * value lost its last `m` — and it has to fail the test that produces the
     * picture, not just be visible in it.
     */
    private fun assertImportantTextNotCropped(view: android.view.View, label: String, presentation: WidgetPresentation) {
        if (presentation.sizeClass == WidgetSizeClass.Medium && presentation.hasObservation) {
            WidgetTextVisibility.assertVisible("$label: primary temperature", view.findViewById(R.id.widget_temperature))
            if (presentation.apparentText != null) {
                WidgetTextVisibility.assertVisible("$label: apparent temperature", view.findViewById(R.id.widget_apparent))
            }
        }
        for (id in listOf(
            R.id.widget_location,
            R.id.widget_observation_time,
            R.id.widget_humidity_value,
            R.id.widget_rain_value,
            R.id.widget_forecast_pop,
        )) {
            val line = view.findViewById<TextView>(id) ?: continue
            WidgetTextVisibility.assertVisible("$label: $id", line)
            assertEquals(
                "$label: ${view.resources.getResourceEntryName(id)} must not be cropped " +
                    "(text '${line.text}')",
                0,
                line.layout?.getEllipsisCount(0) ?: 0,
            )
            assertTrue(
                "$label: ${view.resources.getResourceEntryName(id)}'s line is wider than its view",
                (line.layout?.getLineWidth(0) ?: 0f) <= line.width + 1f,
            )
        }
        // The fixture's own values, so the picture cannot quietly show a truncation
        // that produced no ellipsis.
        view.findViewById<TextView>(R.id.widget_humidity_value)?.let {
            assertEquals("$label: humidity value", presentation.humidityText, it.text.toString())
        }
        view.findViewById<TextView>(R.id.widget_rain_value)?.let {
            assertEquals("$label: rainfall value", presentation.rainText, it.text.toString())
        }
    }

    private fun notBlank(bitmap: Bitmap): Boolean {
        val first = bitmap.getPixel(0, 0)
        for (y in 0 until bitmap.height step 4) {
            for (x in 0 until bitmap.width step 4) {
                if (bitmap.getPixel(x, y) != first) return true
            }
        }
        return false
    }

    private fun renderFamily(prefix: String) {
        write("$prefix-small", render(120, 172))
        write("$prefix-small-compact", render(110, 110))
        write("$prefix-small-threshold", render(118, 152))
        write("$prefix-small-normal-threshold", render(118, WidgetPresenter.compactHeightDp))
        write("$prefix-medium", render(320, 172))
        write("$prefix-200x170-fresh", render(200, 170))
        write("$prefix-large", render(320, 344))
        write("$prefix-large-narrow", render(200, 320))
        write("$prefix-large-narrow-tall", render(250, 344))
        // Taller than either layout's content: a Pixel Pro's grid reports these.
        write("$prefix-medium-tall", render(330, 270))
        write("$prefix-medium-tall-threshold", render(250, WidgetPresenter.mediumTallMinimumHeightDp))
        write("$prefix-large-pixel10a-4x3", render(374, 310))
        write("$prefix-large-threshold", render(340, WidgetPresenter.largeMinimumHeightDp))
        write("$prefix-medium-tall-pixel7pro", render(218, 307))
        write("$prefix-medium-tall-full-threshold", render(218, WidgetPresenter.mediumTallFullDetailHeightDp))
        write("$prefix-large-tall", render(330, 420))

        // Capture the same layouts with a collapsed action, active feedback,
        // retry and success. No old image is evidence for these new states.
        for ((width, height) in listOf(110 to 110, 120 to 172, 200 to 170, 200 to 320, 250 to 344)) {
            val fresh = WidgetUpdater.presentation(context, instanceId, width, height)
            for (feedback in listOf(WidgetRefreshFeedback.Queued, WidgetRefreshFeedback.Running,
                WidgetRefreshFeedback.Failed, WidgetRefreshFeedback.Updated)) {
                write("$prefix-${width}x$height-${feedback.wire}",
                    render(width, height, fresh.copy(refreshFeedback = feedback)))
            }
            if (fresh.sizeClass != WidgetSizeClass.Small) {
                write("$prefix-${width}x$height-no-forecast", render(width, height, fresh.copy(forecast = emptyList())))
                write("$prefix-${width}x$height-stale", render(width, height, fresh.copy(
                    isStale = true, badgeText = context.getString(R.string.widget_stale))))
            }
        }

        WidgetClock.invalidate()
        write("$prefix-small-stale", render(120, 172))
        write("$prefix-small-normal-threshold-stale", render(118, WidgetPresenter.compactHeightDp))
        WidgetClock.installForTest(atTaipei(14, 20), android.os.SystemClock.elapsedRealtime())
        val store = WidgetStore.open(context)
        val address = WidgetAddress.Saved("407")
        val stored = store.readCurrentWeather(address)!!
        val needsApp = WidgetPresenter.present(
            sizeClass = WidgetSizeClass.Small,
            strings = WidgetUpdater.strings(context),
            address = WidgetAddress.CurrentLocation,
            locationName = "西屯區",
            stored = stored,
            forecast = null,
            locationDegradation = WidgetLocationDegradation.Permission,
            isCatalogMember = true,
            calibratedNowMilliseconds = atTaipei(14, 20),
            latitude = 24.181,
            longitude = 120.645,
            availableWidthDp = 120,
            availableHeightDp = 172,
        )
        write("$prefix-small-needs-app", render(120, 172, needsApp))
        for ((name, humidity, rain) in listOf(
            Triple("extreme", 100, 100.0),
            Triple("missing", null, null),
        )) {
            store.commitCurrentWeather(
                store.beginCurrentWeatherWrite(address)!!,
                stored.snapshot.copy(humidity = humidity, rain = rain),
                writtenAt = 1L,
            )
            write("$prefix-small-$name", render(120, 172))
        }
    }

    @Test
    @Config(sdk = [31, 35])
    fun `exact launcher boxes drive child layouts and shared forecast demand`() {
        val boxes = arrayListOf(android.util.SizeF(130f, 220f), android.util.SizeF(269f, 117f),
            android.util.SizeF(320f, 172f), android.util.SizeF(320f, 344f))
        WidgetUpdater.optionsProvider = { _, _ -> Bundle().apply {
            putParcelableArrayList(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_SIZES, boxes)
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
        } }
        assertTrue("medium child must have its source forecast fetched",
            WidgetUpdater.needsForecast(context, WidgetAddress.Saved("407")))
        val remote = WidgetUpdater.render(context, android.appwidget.AppWidgetManager.getInstance(context), instanceId)
        for (box in boxes) {
            // Invoke the framework's host selection, not our own map lookup.
            val child = org.robolectric.util.ReflectionHelpers.callInstanceMethod<android.widget.RemoteViews>(
                remote, "getRemoteViewsToApply",
                org.robolectric.util.ReflectionHelpers.ClassParameter.from(Context::class.java, context),
                org.robolectric.util.ReflectionHelpers.ClassParameter.from(android.util.SizeF::class.java, box),
            )
            val view = child.apply(context, FrameLayout(context))
            val w = px(box.width.toInt())
            val h = px(box.height.toInt())
            view.measure(android.view.View.MeasureSpec.makeMeasureSpec(w, android.view.View.MeasureSpec.EXACTLY),
                android.view.View.MeasureSpec.makeMeasureSpec(h, android.view.View.MeasureSpec.EXACTLY))
            view.layout(0, 0, w, h)
            WidgetTextVisibility.assertTree("exact $box", view)
            if (box.width == 130f || box.height == 117f) {
                WidgetTextVisibility.assertVisible("exact humidity", view.findViewById(R.id.widget_humidity_value))
                WidgetTextVisibility.assertVisible("exact rain", view.findViewById(R.id.widget_rain_value))
            } else {
                assertEquals(5, view.findViewById<android.widget.LinearLayout>(R.id.widget_forecast_container).childCount)
            }
            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            view.draw(Canvas(bitmap))
            write("exact-${box.width.toInt()}x${box.height.toInt()}", bitmap)
        }
        // Resizing down removes demand through the same authority, without stale size caching.
        boxes.clear()
        boxes.add(android.util.SizeF(130f, 455f))
        assertTrue(!WidgetUpdater.needsForecast(context, WidgetAddress.Saved("407")))
        write("narrow-tall-balanced", render(130, 455))
        val view = WidgetRenderer.render(context, WidgetUpdater.presentation(context, instanceId, 130, 455), instanceId)
            .apply(context, FrameLayout(context))
        view.measure(android.view.View.MeasureSpec.makeMeasureSpec(px(130), android.view.View.MeasureSpec.EXACTLY),
            android.view.View.MeasureSpec.makeMeasureSpec(px(455), android.view.View.MeasureSpec.EXACTLY))
        view.layout(0, 0, px(130), px(455))
        val temperature = view.findViewById<TextView>(R.id.widget_temperature)
        val clock = view.findViewById<TextView>(R.id.widget_observation_time)
        assertTrue("narrow tall must not separate reading from observation by hundreds of dp",
            temperature.top - clock.bottom < px(40))
    }

    @Test
    @Config(sdk = [26])
    fun `portrait launcher bounds must retain both small weather metrics`() {
        // Representative rotation bounds, NOT a captured Pixel option bundle.
        // min height belongs to landscape; min width belongs to portrait.
        WidgetUpdater.optionsProvider = { _, _ -> Bundle().apply {
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 130)
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 269)
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 117)
            putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 220)
        } }
        val remote = WidgetUpdater.render(context, android.appwidget.AppWidgetManager.getInstance(context), instanceId)
        val view = remote.apply(context, FrameLayout(context))
        view.measure(android.view.View.MeasureSpec.makeMeasureSpec(px(130), android.view.View.MeasureSpec.EXACTLY),
            android.view.View.MeasureSpec.makeMeasureSpec(px(220), android.view.View.MeasureSpec.EXACTLY))
        view.layout(0, 0, px(130), px(220))
        for (id in listOf(R.id.widget_humidity_value, R.id.widget_rain_value)) {
            val metric = view.findViewById<TextView>(id)
            org.junit.Assert.assertNotNull("portrait 2x2 must not silently lose humidity/rainfall", metric)
            WidgetTextVisibility.assertVisible("portrait metric", metric!!)
        }
        val landscape = context.createConfigurationContext(Configuration(context.resources.configuration).apply {
            orientation = Configuration.ORIENTATION_LANDSCAPE
        })
        // The very same RemoteViews can rotate without a provider/worker wake-up.
        val rotated = remote.apply(landscape, FrameLayout(landscape))
        rotated.measure(android.view.View.MeasureSpec.makeMeasureSpec(px(269), android.view.View.MeasureSpec.EXACTLY),
            android.view.View.MeasureSpec.makeMeasureSpec(px(117), android.view.View.MeasureSpec.EXACTLY))
        rotated.layout(0, 0, px(269), px(117))
        WidgetTextVisibility.assertTree("legacy rotation", rotated)
        for (id in listOf(R.id.widget_humidity_value, R.id.widget_rain_value)) {
            WidgetTextVisibility.assertVisible("legacy rotation metric", rotated.findViewById(id))
        }
    }

    @Test
    fun `writes the light previews`() {
        renderFamily("light")
    }

    @Test
    fun `cloud weather glyphs retain transparent margins at widget sizes`() {
        val glyphs = listOf(
            R.drawable.ic_widget_weather_cloudy_day,
            R.drawable.ic_widget_weather_cloudy_night,
            R.drawable.ic_widget_weather_overcast,
            R.drawable.ic_widget_weather_rain,
            R.drawable.ic_widget_weather_thunderstorm,
            R.drawable.ic_widget_weather_snow,
        )
        for (glyph in glyphs) {
            for (size in listOf(16, 24, 40)) {
                val bitmap = Bitmap.createBitmap(px(size), px(size), Bitmap.Config.ARGB_8888)
                val drawable = context.getDrawable(glyph)!!.mutate()
                drawable.setBounds(0, 0, bitmap.width, bitmap.height)
                drawable.draw(Canvas(bitmap))
                val label = "${context.resources.getResourceEntryName(glyph)} at ${size}dp"
                assertTrue("$label must not be blank", notBlank(bitmap))
                // A clipped vector still draws a nonblank image. Check the actual
                // raster edges too: cloud translations once put the left lobe
                // outside the viewport, flattening it at every widget size.
                for (i in 0 until bitmap.width) {
                    for ((x, y) in listOf(
                        0 to i, bitmap.width - 1 to i,
                        i to 0, i to bitmap.height - 1,
                    )) {
                        assertEquals("$label touches edge ($x, $y)", 0, Color.alpha(bitmap.getPixel(x, y)))
                    }
                }
            }
        }
    }

    /**
     * One sheet with every glyph the renderer can choose, so the vector set can
     * be eyeballed in one picture instead of trusting the filenames. Rows carry
     * the same `widget_secondary` tint the widget applies; a day/night pair is
     * two rows because which one is drawn is the mapping
     * `WidgetRendererTest` pins by resource id.
     */
    @Test
    fun `writes the glyph sheet`() {
        val rows = listOf(
            "Clear (day)" to R.drawable.ic_widget_weather_clear_day,
            "Clear (night)" to R.drawable.ic_widget_weather_clear_night,
            "Cloudy (day)" to R.drawable.ic_widget_weather_cloudy_day,
            "Cloudy (night)" to R.drawable.ic_widget_weather_cloudy_night,
            "Overcast" to R.drawable.ic_widget_weather_overcast,
            "Rain" to R.drawable.ic_widget_weather_rain,
            "Thunderstorm" to R.drawable.ic_widget_weather_thunderstorm,
            "Snow" to R.drawable.ic_widget_weather_snow,
            "Fog" to R.drawable.ic_widget_weather_fog,
            "Unknown" to R.drawable.ic_widget_weather_unknown,
        )
        val tint = context.getColor(R.color.widget_secondary)
        val column = android.widget.LinearLayout(context).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(px(24), px(24), px(24), px(24))
        }
        for ((label, glyph) in rows) {
            val row = android.widget.LinearLayout(context).apply {
                orientation = android.widget.LinearLayout.HORIZONTAL
                gravity = android.view.Gravity.CENTER_VERTICAL
            }
            row.addView(android.widget.ImageView(context).apply {
                setImageResource(glyph)
                setColorFilter(tint)
                layoutParams = android.widget.LinearLayout.LayoutParams(px(40), px(40))
            })
            row.addView(TextView(context).apply {
                text = label
                setTextColor(Color.BLACK)
                textSize = 16f
                layoutParams =
                    android.widget.LinearLayout.LayoutParams(
                        android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                        android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                    ).apply { marginStart = px(16) }
            })
            column.addView(row)
        }
        column.measure(
            android.view.View.MeasureSpec.makeMeasureSpec(px(280), android.view.View.MeasureSpec.EXACTLY),
            android.view.View.MeasureSpec.makeMeasureSpec(0, android.view.View.MeasureSpec.UNSPECIFIED),
        )
        column.layout(0, 0, column.measuredWidth, column.measuredHeight)
        val bitmap = Bitmap.createBitmap(
            column.measuredWidth,
            column.measuredHeight,
            Bitmap.Config.ARGB_8888,
        )
        column.draw(Canvas(bitmap))
        write("glyphs", bitmap)
    }

    @Test
    @Config(qualifiers = "night-420dpi")
    fun `writes the dark previews`() {
        renderFamily("dark")
    }
}
