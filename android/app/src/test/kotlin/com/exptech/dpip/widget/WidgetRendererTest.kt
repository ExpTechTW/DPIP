package com.exptech.dpip.widget

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.RemoteViews
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import com.exptech.dpip.R
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.robolectric.util.ReflectionHelpers
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.time.LocalDateTime
import java.time.ZoneOffset

/**
 * The layouts and the renderer that drives them, applied for real.
 *
 * `RemoteViews` is not a general layout inflater: it only accepts a fixed list
 * of view classes, and each action it carries is resolved reflectively when the
 * **launcher** applies it. A layout with a `<View>` divider, or an action aimed
 * at an id the layout does not have, fails inside the launcher's process, where
 * the only trace is a widget that silently stops updating. Both mistakes exist
 * in this feature's history; both are caught here.
 *
 * The id sets are the other half of the iOS restatement: the square layout has
 * the humidity and rainfall row, the two-row layout has the apparent
 * temperature and the forecast, and the large one has the detail grid — and each
 * sets only what its own document contains.
 */
@RunWith(RobolectricTestRunner::class)
@org.robolectric.annotation.Config(sdk = [26, 35])
class WidgetRendererTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val taipei = ZoneOffset.ofHours(8)

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

    private fun atTaipei(hour: Int, minute: Int): Long =
        LocalDateTime.of(2026, 10, 12, hour, minute).toInstant(taipei).toEpochMilli()

    private fun snapshot() = CurrentWeatherSnapshot(
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
    )

    private fun presentation(
        sizeClass: WidgetSizeClass,
        widthDp: Int = WidgetPresenter.minimumWidthDp,
        heightDp: Int = WidgetPresenter.defaultAvailableHeightDp,
        stored: StoredCurrentWeather? = StoredCurrentWeather(snapshot(), 1, 1),
        address: WidgetAddress? = WidgetAddress.Saved("407"),
        locationName: String? = "西屯區",
        locationDegradation: WidgetLocationDegradation? = null,
    ) = WidgetPresenter.present(
        sizeClass = sizeClass,
        strings = strings,
        address = address,
        locationName = locationName,
        stored = stored,
        forecast = StoredForecast(
            forecast = ForecastSnapshot(
                schemaVersion = 1,
                sourceIdentifier = address?.sourceIdentifier ?: "region:407",
                regionCode = "407",
                updateTime = atTaipei(14, 10),
                receivedAt = atTaipei(14, 10),
                points = listOf(ForecastPoint("15:00", 27.0, "多雲", 200, 20)),
            ),
            receivedCalibratedMilliseconds = atTaipei(14, 10),
            expiresAtMilliseconds = atTaipei(15, 0),
        ),
        locationDegradation = locationDegradation,
        isCatalogMember = true,
        calibratedNowMilliseconds = atTaipei(14, 20),
        latitude = 24.181,
        longitude = 120.645,
        availableWidthDp = widthDp,
        availableHeightDp = heightDp,
    )

    private fun applied(sizeClass: WidgetSizeClass, appWidgetId: Int = 42): View =
        WidgetRenderer.render(context, presentation(sizeClass), appWidgetId)
            .apply(context, FrameLayout(context))

    /**
     * The description a launcher would announce for a rendered `RemoteViews`.
     *
     * Read off the applied view rather than off the `RemoteViews` actions: the
     * description is set by reflectively invoking `setContentDescription`, so
     * only applying it proves the method resolved and the value landed.
     */
    private fun appliedDescription(views: RemoteViews): String? =
        views.apply(context, FrameLayout(context))
            .findViewById<View>(android.R.id.background)
            .contentDescription
            ?.toString()

    /** Each hour is announced as one group, with weather semantics on its icon. */
    private fun forecastAnnouncements(presentation: WidgetPresentation): List<List<String>> {
        val view = WidgetRenderer.render(context, presentation, 42).apply(context, FrameLayout(context))
        val container = view.findViewById<android.widget.LinearLayout>(R.id.widget_forecast_container)
        return (0 until container.childCount).map { index ->
            val column = container.getChildAt(index)
            assertTrue("each hour must be focusable as a group on API 26 too", column.isFocusable)
            val icon = column.findViewById<ImageView>(R.id.widget_forecast_icon)
            assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_YES, icon.importantForAccessibility)
            listOf(
                column.findViewById<TextView>(R.id.widget_forecast_time).text.toString(),
                icon.contentDescription?.toString().orEmpty(),
                column.findViewById<TextView>(R.id.widget_forecast_temperature).text.toString(),
                column.findViewById<TextView>(R.id.widget_forecast_pop).contentDescription?.toString().orEmpty(),
            )
        }
    }

    /**
     * The view ids a `RemoteViews` carries a click action for.
     *
     * The click actions are *stored*, not applied, until a launcher-supplied
     * `OnClickHandler` is present — that handler is not part of the public API —
     * so asking the inflated view whether it has a listener would report none
     * even for a correct layout. Reading the actions back is the honest check:
     * it is exactly what the launcher would apply.
     */
    private fun clickTargets(views: RemoteViews): Set<Int> {
        // `RemoteViews` keeps them in `mActions`, and there is no public
        // accessor. Both the action class name and the field holding the target
        // view id changed across platform versions (API 26 uses a different pair
        // from API 35), so both are looked up rather than assumed — the test runs
        // on both.
        val actions = ReflectionHelpers.getField<ArrayList<*>>(views, "mActions")
        return actions.mapNotNull { action ->
            if (action == null) return@mapNotNull null
            val name = action.javaClass.simpleName
            if (!name.contains("OnClick")) return@mapNotNull null
            targetViewId(action) ?: return@mapNotNull null
        }.toSet()
    }

    /** The view id a `RemoteViews` action targets, walking the class hierarchy. */
    private fun targetViewId(action: Any): Int? {
        var type: Class<*>? = action.javaClass
        while (type != null) {
            val field = type.declaredFields.firstOrNull {
                it.name == "mViewId" || it.name == "viewId"
            }
            if (field != null) {
                field.isAccessible = true
                return field.get(action) as? Int
            }
            type = type.superclass
        }
        return null
    }

    @Test
    fun `every layout the provider renders applies as RemoteViews`() {
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
            assertNotNull(
                "layout $layoutId must apply",
                RemoteViews(context.packageName, layoutId).apply(context, FrameLayout(context)),
            )
        }
    }

    @Test
    fun `the configuration screen inflates with every view it drives`() {
        val themed = android.view.ContextThemeWrapper(context, R.style.WidgetConfigTheme)
        val view = LayoutInflater.from(themed)
            .inflate(R.layout.activity_widget_config, FrameLayout(themed), false)
        for (id in listOf(
            R.id.widget_config_title,
            R.id.widget_config_message,
            R.id.widget_config_list,
            R.id.widget_config_open_app,
            R.id.widget_config_cancel,
        )) {
            assertNotNull("$id must exist", view.findViewById<View>(id))
        }
    }

    @Test
    fun `the square layout draws the metric row and no forecast`() {
        // 120x172 dp is a Pixel 2x2 cell: the full square layout, not the
        // compact fallback.
        val presentation = presentation(WidgetSizeClass.Small, widthDp = 120, heightDp = 172)
        assertTrue(!presentation.compactLayout)
        val view = WidgetRenderer.render(context, presentation, 42)
            .apply(context, FrameLayout(context))

        assertEquals("西屯區", view.findViewById<TextView>(R.id.widget_location).text.toString())
        assertEquals("28°", view.findViewById<TextView>(R.id.widget_temperature).text.toString())
        assertEquals("多雲有雨", view.findViewById<TextView>(R.id.widget_weather).text.toString())
        assertEquals("78%", view.findViewById<TextView>(R.id.widget_humidity_value).text.toString())
        assertTrue(
            view.findViewById<TextView>(R.id.widget_rain_value).text.toString().contains("mm"),
        )
        // No container, no apparent temperature: the ids do not exist here.
        assertEquals(null, view.findViewById<View>(R.id.widget_forecast_container))
        assertEquals(null, view.findViewById<View>(R.id.widget_apparent))
    }

    @Test
    fun `the compact fallback keeps the essentials and drops what cannot fit`() {
        // 110x110 is the metadata's own minimum, so production selects the
        // compact form; it has no weather name and no metric row.
        val presentation = presentation(WidgetSizeClass.Small, widthDp = 110, heightDp = 110)
        assertTrue(presentation.compactLayout)
        val view = WidgetRenderer.render(context, presentation, 42)
            .apply(context, FrameLayout(context))

        assertEquals("西屯區", view.findViewById<TextView>(R.id.widget_location).text.toString())
        assertEquals("28°", view.findViewById<TextView>(R.id.widget_temperature).text.toString())
        assertEquals(null, view.findViewById<View>(R.id.widget_weather))
        assertEquals("78%", view.findViewById<TextView>(R.id.widget_humidity_value).text.toString())
        assertEquals("0.4 mm", view.findViewById<TextView>(R.id.widget_rain_value).text.toString())
        assertEquals(null, view.findViewById<View>(R.id.widget_apparent))
    }

    @Test
    fun `the medium layout draws the apparent temperature and one forecast column`() {
        val view = applied(WidgetSizeClass.Medium)
        assertEquals("FEELS 30°", view.findViewById<TextView>(R.id.widget_apparent).text.toString())
        val container = view.findViewById<android.widget.LinearLayout>(R.id.widget_forecast_container)
        assertEquals(1, container.childCount)
        assertEquals(
            "15:00",
            container.getChildAt(0).findViewById<TextView>(R.id.widget_forecast_time).text.toString(),
        )
        assertEquals(
            "20%",
            container.getChildAt(0).findViewById<TextView>(R.id.widget_forecast_pop).text.toString(),
        )
        assertEquals(null, view.findViewById<View>(R.id.widget_grid_humidity_value))
    }

    @Test
    fun `the large layout draws every field the renderer writes`() {
        val view = applied(WidgetSizeClass.Large)
        for (id in listOf(
            R.id.widget_location,
            R.id.widget_observation_time,
            R.id.widget_temperature,
            R.id.widget_weather,
            R.id.widget_apparent,
            R.id.widget_grid_humidity_value,
            R.id.widget_grid_rain_value,
            R.id.widget_grid_sun_label,
            R.id.widget_grid_sun_value,
            R.id.widget_grid_wind_value,
            R.id.widget_grid_station_value,
            R.id.widget_forecast_container,
            R.id.widget_stale,
        )) {
            assertNotNull("$id must exist in the large layout", view.findViewById<View>(id))
        }
        assertEquals("FEELS 30°", view.findViewById<TextView>(R.id.widget_apparent).text.toString())
        assertEquals("78%", view.findViewById<TextView>(R.id.widget_grid_humidity_value).text.toString())
        assertTrue(
            view.findViewById<TextView>(R.id.widget_grid_rain_value).text.toString().contains("mm"),
        )
        assertEquals("SUNSET", view.findViewById<TextView>(R.id.widget_grid_sun_label).text.toString())
        assertEquals("18:00", view.findViewById<TextView>(R.id.widget_grid_sun_value).text.toString())
        assertTrue(
            view.findViewById<TextView>(R.id.widget_grid_wind_value).text.toString()
                .contains("北北西"),
        )
        assertEquals("西屯", view.findViewById<TextView>(R.id.widget_grid_station_value).text.toString())
    }

    @Test
    fun `all five layouts show HH mm and retain the full accessible observation date`() {
        for ((width, height) in listOf(110 to 110, 120 to 172, 200 to 170, 200 to 320, 250 to 344)) {
            val presentation = presentation(WidgetPresenter.sizeClass(width, height), width, height)
            val view = WidgetRenderer.render(context, presentation, 42).apply(context, FrameLayout(context))
            val time = view.findViewById<TextView>(R.id.widget_observation_time)
            assertEquals("$width x $height", "14:05", time.text.toString())
            assertEquals("2026/10/12 14:05", time.contentDescription.toString())
            assertTrue(view.contentDescription.toString().contains("2026/10/12 14:05"))
        }
    }

    @Test
    fun `an empty cache draws the cloud and the message, not a blank`() {
        val presentation = presentation(
            WidgetSizeClass.Medium,
            stored = null,
            address = WidgetAddress.Saved("407"),
            locationName = null,
        )
        assertTrue(!presentation.hasObservation)
        val view = WidgetRenderer.render(context, presentation, 42)
            .apply(context, FrameLayout(context))
        assertEquals(
            "NO_DATA",
            view.findViewById<TextView>(R.id.widget_empty_message).text.toString(),
        )
        assertNotNull(view.findViewById<ImageView>(R.id.widget_empty_icon))
    }

    @Test
    @org.robolectric.annotation.Config(qualifiers = "zh-rTW")
    fun `a surface with nothing to name falls back to the localized widget name`() {
        // The fallback used to be the English literal "DPIP weather", which a
        // reader whose whole Widget speaks Traditional Chinese would hear in
        // English. It is now `widget_name`, resolved from the same resources
        // the rest of the Widget is.
        val nameless = presentation(
            WidgetSizeClass.Medium,
            stored = null,
            locationName = null,
        ).copy(badgeText = null, hintText = null)
        assertEquals(null, nameless.locationName)
        assertEquals(null, nameless.weatherText)
        assertEquals(null, nameless.temperatureText)
        assertEquals(null, nameless.badgeText)

        val described = appliedDescription(
            WidgetRenderer.render(context, nameless, 42),
        )
        assertEquals(context.getString(R.string.widget_name), described)
        assertEquals("目前天氣", described)
    }

    @Test
    @org.robolectric.annotation.Config(qualifiers = "zh-rTW")
    fun `an empty or reconfigured face describes itself in the system language`() {
        // The empty and reconfigure faces have no reading to name, so their
        // description is the message they already draw. It must come from the
        // localized strings, not from an English default.
        val localized = WidgetUpdater.strings(context)
        fun empty(stored: StoredCurrentWeather?, catalogMember: Boolean) =
            WidgetPresenter.present(
                sizeClass = WidgetSizeClass.Medium,
                strings = localized,
                address = WidgetAddress.Saved("407"),
                locationName = null,
                stored = stored,
                forecast = null,
                locationDegradation = null,
                isCatalogMember = catalogMember,
                calibratedNowMilliseconds = atTaipei(14, 20),
                latitude = 24.181,
                longitude = 120.645,
            )

        assertEquals(
            context.getString(R.string.widget_no_data),
            appliedDescription(
                WidgetRenderer.render(context, empty(stored = null, catalogMember = true), 1),
            ),
        )
        assertEquals(
            context.getString(R.string.widget_reconfigure),
            appliedDescription(
                WidgetRenderer.render(
                    context,
                    empty(stored = StoredCurrentWeather(snapshot(), 1, 1), catalogMember = false),
                    2,
                ),
            ),
        )
    }

    @Test
    fun `a description joins only the readings it has, with no leading separator`() {
        // Regression: the comma was written before every field, so a face whose
        // town was absent announced a leading separator. A blank field must drop
        // its separator too, not leave a gap.
        val observed = presentation(WidgetSizeClass.Small)
        val condition = context.getString(R.string.widget_weather_rain)
        val details = ", ${context.getString(R.string.widget_humidity)} 78%, " +
            "${context.getString(R.string.widget_rain)} 0.4 mm, " + context.getString(R.string.widget_compact_details)
        assertEquals(
            "$condition, 2026/10/12 14:05$details",
            appliedDescription(
                WidgetRenderer.render(
                    context,
                    observed.copy(locationName = null, temperatureText = null, badgeText = null),
                    42,
                ),
            ),
        )
        assertEquals(
            "$condition, 28°, 2026/10/12 14:05$details",
            appliedDescription(
                WidgetRenderer.render(
                    context,
                    observed.copy(locationName = null, badgeText = null),
                    43,
                ),
            ),
        )
        assertEquals(
            "$condition, 28°, 2026/10/12 14:05$details",
            appliedDescription(
                WidgetRenderer.render(
                    context,
                    observed.copy(locationName = "   ", badgeText = null),
                    44,
                ),
            ),
        )
    }

    @Test
    @org.robolectric.annotation.Config(qualifiers = "zh-rTW")
    fun `each forecast hour groups its localized weather and rain probability`() {
        for (size in listOf(WidgetSizeClass.Medium, WidgetSizeClass.Large)) {
            val forecast = listOf(
                ForecastPresentation("15:00", "27°", "20%", WeatherCondition.Cloudy, false),
                ForecastPresentation("16:00", "26°", "60%", WeatherCondition.Thunderstorm, false),
            )
            assertEquals(
                listOf(
                    listOf("15:00", "多雲", "27°", "降雨機率 20%"),
                    listOf("16:00", "雷雨", "26°", "降雨機率 60%"),
                ),
                forecastAnnouncements(presentation(size).copy(forecast = forecast)),
            )
        }
    }

    @Test
    @org.robolectric.annotation.Config(qualifiers = "en")
    fun `forecast descriptions localize every condition and name an unknown rain probability`() {
        val labels = mapOf(
            WeatherCondition.Clear to "Clear",
            WeatherCondition.Cloudy to "Cloudy",
            WeatherCondition.Overcast to "Overcast",
            WeatherCondition.Rain to "Rain",
            WeatherCondition.Thunderstorm to "Thunderstorm",
            WeatherCondition.Snow to "Snow",
            WeatherCondition.Fog to "Fog",
            WeatherCondition.Unknown to "Unknown",
        )
        for ((condition, label) in labels) {
            val point = ForecastPresentation("15:00", "27°", "—", condition, false)
            assertEquals(
                listOf(listOf("15:00", label, "27°", "Chance of rain unavailable")),
                forecastAnnouncements(presentation(WidgetSizeClass.Medium).copy(forecast = listOf(point))),
            )
        }
    }

    @Test
    @org.robolectric.annotation.Config(qualifiers = "en")
    fun `a known forecast rain probability is named rather than read as an unexplained percentage`() {
        assertEquals(
            listOf(listOf("15:00", "Cloudy", "27°", "Chance of rain 20%")),
            forecastAnnouncements(presentation(WidgetSizeClass.Medium)),
        )
    }

    @Test
    fun `a current-location widget shows the location mark, a saved town does not`() {
        val current = WidgetRenderer.render(
            context,
            presentation(
                WidgetSizeClass.Large,
                address = WidgetAddress.CurrentLocation,
                stored = StoredCurrentWeather(
                    snapshot().copy(sourceIdentifier = "current-location"),
                    1,
                    1,
                ),
            ),
            42,
        ).apply(context, FrameLayout(context))
        assertEquals(
            View.VISIBLE,
            current.findViewById<View>(R.id.widget_location_icon).visibility,
        )

        val saved = applied(WidgetSizeClass.Large)
        assertEquals(View.GONE, saved.findViewById<View>(R.id.widget_location_icon).visibility)
    }

    /**
     * The identity of the image, not just that one is present.
     *
     * A label can be right while the glyph beside it is wrong — a rainy hour
     * drawing the sun and announcing 多雲 would pass every description test
     * above. The square icon and an hourly icon are both pinned because the
     * renderer resolves both through the same table, and a night hour must not
     * fall back to the day glyph. `Unknown` and the null a degraded snapshot
     * can carry must land on the neutral marker rather than a guessed glyph.
     */
    @Test
    fun `every condition draws its own glyph, current and hourly`() {
        val night = true
        val day = false
        val glyphs = listOf(
            Triple(WeatherCondition.Clear, day, R.drawable.ic_widget_weather_clear_day),
            Triple(WeatherCondition.Clear, night, R.drawable.ic_widget_weather_clear_night),
            Triple(WeatherCondition.Cloudy, day, R.drawable.ic_widget_weather_cloudy_day),
            Triple(WeatherCondition.Cloudy, night, R.drawable.ic_widget_weather_cloudy_night),
            Triple(WeatherCondition.Overcast, day, R.drawable.ic_widget_weather_overcast),
            Triple(WeatherCondition.Overcast, night, R.drawable.ic_widget_weather_overcast),
            Triple(WeatherCondition.Rain, day, R.drawable.ic_widget_weather_rain),
            Triple(WeatherCondition.Rain, night, R.drawable.ic_widget_weather_rain),
            Triple(WeatherCondition.Thunderstorm, day, R.drawable.ic_widget_weather_thunderstorm),
            Triple(WeatherCondition.Thunderstorm, night, R.drawable.ic_widget_weather_thunderstorm),
            Triple(WeatherCondition.Snow, day, R.drawable.ic_widget_weather_snow),
            Triple(WeatherCondition.Snow, night, R.drawable.ic_widget_weather_snow),
            Triple(WeatherCondition.Fog, day, R.drawable.ic_widget_weather_fog),
            Triple(WeatherCondition.Fog, night, R.drawable.ic_widget_weather_fog),
            Triple(WeatherCondition.Unknown, day, R.drawable.ic_widget_weather_unknown),
            Triple(WeatherCondition.Unknown, night, R.drawable.ic_widget_weather_unknown),
        )
        for ((condition, isNight, expected) in glyphs) {
            val current = WidgetRenderer.render(
                context,
                presentation(WidgetSizeClass.Small).copy(condition = condition, isNight = isNight),
                42,
            ).apply(context, FrameLayout(context))
            assertEquals(
                "$condition (night=$isNight) draws the wrong square glyph",
                expected,
                shadowOf(current.findViewById<ImageView>(R.id.widget_icon).drawable).createdFromResId,
            )

            val hourly = WidgetRenderer.render(
                context,
                presentation(WidgetSizeClass.Medium).copy(
                    forecast = listOf(ForecastPresentation("15:00", "27°", "20%", condition, isNight)),
                ),
                42,
            ).apply(context, FrameLayout(context))
            val column = hourly
                .findViewById<android.widget.LinearLayout>(R.id.widget_forecast_container)
                .getChildAt(0)
            assertEquals(
                "$condition (night=$isNight) draws the wrong hourly glyph",
                expected,
                shadowOf(column.findViewById<ImageView>(R.id.widget_forecast_icon).drawable).createdFromResId,
            )
        }

        val missing = WidgetRenderer.render(
            context,
            presentation(WidgetSizeClass.Small).copy(condition = null),
            42,
        ).apply(context, FrameLayout(context))
        assertEquals(
            "a null condition must not crash the glyph lookup or guess a face",
            R.drawable.ic_widget_weather_unknown,
            shadowOf(missing.findViewById<ImageView>(R.id.widget_icon).drawable).createdFromResId,
        )
    }

    @Test
    fun `the stale notice is drawn only when there is something to say`() {
        val stale = WidgetRenderer.render(
            context,
            presentation(WidgetSizeClass.Medium).copy(isStale = true, badgeText = "OUTDATED"),
            appWidgetId = 7,
        ).apply(context, FrameLayout(context))
        assertEquals(View.VISIBLE, stale.findViewById<View>(R.id.widget_stale).visibility)
        assertEquals("OUTDATED", stale.findViewById<TextView>(R.id.widget_stale).text.toString())

        val fresh = applied(WidgetSizeClass.Medium)
        assertEquals(View.GONE, fresh.findViewById<View>(R.id.widget_stale).visibility)
    }

    @Test
    fun `a stale widget keeps the surface and refresh glyph tap targets`() {
        val large = WidgetRenderer.render(context, presentation(WidgetSizeClass.Large).copy(isStale = true), 42)
        assertEquals(
            setOf(android.R.id.background, R.id.widget_refresh),
            clickTargets(large),
        )
        val view = large.apply(context, FrameLayout(context))
        assertEquals(View.VISIBLE, view.findViewById<View>(R.id.widget_refresh).visibility)
    }

    @Test
    fun `a stale compact instance offers refresh instead of a settings button`() {
        val small = WidgetRenderer.render(
            context,
            presentation(WidgetSizeClass.Small, widthDp = 110, heightDp = 110).copy(isStale = true),
            42,
        )
        assertEquals(
            setOf(android.R.id.background, R.id.widget_refresh),
            clickTargets(small),
        )
        assertEquals(
            View.VISIBLE,
            small.apply(context, FrameLayout(context)).findViewById<View>(R.id.widget_refresh).visibility,
        )
    }

    @Test
    fun `fresh controls are gone and cannot be clicked while missing forecasts can be retried`() {
        for ((width, height) in listOf(110 to 110, 120 to 172, 200 to 170, 200 to 320, 250 to 344)) {
            val base = presentation(WidgetPresenter.sizeClass(width, height), width, height)
            val view = WidgetRenderer.render(context, base, 42).apply(context, FrameLayout(context))
            val refresh = view.findViewById<View>(R.id.widget_refresh)
            assertEquals(View.GONE, refresh.visibility)
            assertFalse(refresh.isEnabled)
            assertFalse(refresh.hasOnClickListeners())
            assertFalse(refresh.performClick())

            WidgetRenderer.render(context, base.copy(forecast = emptyList()), 42).reapply(context, view)
            val supportsForecast = base.sizeClass != WidgetSizeClass.Small
            assertEquals(if (supportsForecast) View.VISIBLE else View.GONE, refresh.visibility)
            assertEquals(supportsForecast, refresh.isEnabled)
            assertEquals(supportsForecast, refresh.hasOnClickListeners())
        }
    }

    @Test
    fun `refresh feedback swaps glyphs without adding a text notice and resets on reapply`() {
        for ((width, height) in listOf(110 to 110, 120 to 172, 200 to 170, 200 to 320, 250 to 344)) {
            val base = presentation(WidgetPresenter.sizeClass(width, height), width, height)
            val view = WidgetRenderer.render(context, base, 42).apply(context, FrameLayout(context))
            for (feedback in listOf(WidgetRefreshFeedback.Queued, WidgetRefreshFeedback.Running,
                WidgetRefreshFeedback.Failed, WidgetRefreshFeedback.Updated, null,
                WidgetRefreshFeedback.Running, WidgetRefreshFeedback.Failed, null)) {
                WidgetRenderer.render(context, base.copy(refreshFeedback = feedback), 42).reapply(context, view)
                val busy = feedback == WidgetRefreshFeedback.Queued || feedback == WidgetRefreshFeedback.Running
                val visible = busy || feedback == WidgetRefreshFeedback.Failed
                val actionable = visible && !busy
                val refresh = view.findViewById<View>(R.id.widget_refresh)
                assertEquals(if (visible) View.VISIBLE else View.GONE, refresh.visibility)
                assertEquals(View.GONE, view.findViewById<View>(R.id.widget_stale).visibility)
                assertEquals(if (busy) View.VISIBLE else View.GONE,
                    view.findViewById<View>(R.id.widget_refresh_progress).visibility)
                assertEquals(if (busy) View.GONE else View.VISIBLE,
                    view.findViewById<View>(R.id.widget_refresh_icon).visibility)
                assertEquals(actionable, refresh.isEnabled)
                assertEquals(actionable, refresh.hasOnClickListeners())
                if (!actionable) assertFalse(refresh.performClick())
                val expectedLabel = when (feedback) {
                    WidgetRefreshFeedback.Queued -> R.string.widget_refresh_queued
                    WidgetRefreshFeedback.Running -> R.string.widget_refresh_running
                    WidgetRefreshFeedback.Failed -> R.string.widget_refresh_failed
                    WidgetRefreshFeedback.Updated -> R.string.widget_refresh_updated
                    null -> R.string.widget_refresh
                }
                assertEquals(context.getString(expectedLabel),
                    view.findViewById<View>(R.id.widget_refresh).contentDescription)
                assertEquals(
                    if (feedback == WidgetRefreshFeedback.Failed) R.drawable.ic_widget_refresh_failed
                    else R.drawable.ic_widget_refresh,
                    org.robolectric.Shadows.shadowOf(view.findViewById<ImageView>(R.id.widget_refresh_icon).drawable).createdFromResId,
                )
                assertTrue(view.findViewById<android.widget.ProgressBar>(R.id.widget_refresh_progress).isIndeterminate)
            }
        }
    }

    @Test
    fun `refresh feedback never replaces the empty face message`() {
        val empty = presentation(WidgetSizeClass.Small, stored = null)
        for (feedback in WidgetRefreshFeedback.entries) {
            val view = WidgetRenderer.render(context, empty.copy(refreshFeedback = feedback), 42)
                .apply(context, FrameLayout(context))
            assertEquals("NO_DATA", view.findViewById<TextView>(R.id.widget_empty_message).text.toString())
            assertEquals(View.VISIBLE, view.findViewById<View>(R.id.widget_refresh).visibility)
        }
    }

    @Test
    fun `app attention and unconfigured empty states hide failed retry controls`() {
        for (stored in listOf(null, StoredCurrentWeather(snapshot(), 1, 1))) {
            val blocked = presentation(WidgetSizeClass.Small, stored = stored)
                .copy(state = WidgetDisplayState.NeedsApp, canRefresh = false,
                    refreshFeedback = WidgetRefreshFeedback.Failed)
            val view = WidgetRenderer.render(context, blocked, 42).apply(context, FrameLayout(context))
            val refresh = view.findViewById<View>(R.id.widget_refresh)
            assertEquals(View.GONE, refresh.visibility)
            assertFalse(refresh.hasOnClickListeners())
            WidgetRenderer.render(context, blocked.copy(refreshFeedback = WidgetRefreshFeedback.Running), 42)
                .reapply(context, view)
            assertEquals(View.VISIBLE, refresh.visibility)
            assertFalse(refresh.isEnabled)
            assertEquals(View.VISIBLE, view.findViewById<View>(R.id.widget_refresh_progress).visibility)
        }
        val unconfigured = presentation(WidgetSizeClass.Small, stored = null, address = null)
        val view = WidgetRenderer.render(context, unconfigured, 42).apply(context, FrameLayout(context))
        assertEquals(View.GONE, view.findViewById<View>(R.id.widget_refresh).visibility)
    }

    @Test
    fun `location retry survives reapply and clears clicks during progress permission loss and recovery`() {
        for ((width, height) in listOf(110 to 110, 120 to 172, 200 to 170, 200 to 320, 250 to 344)) {
            for (entry in listOf(null, StoredCurrentWeather(snapshot().copy(sourceIdentifier = "current-location"), 1, 1))) {
                fun present(degradation: WidgetLocationDegradation?) = presentation(
                    WidgetPresenter.sizeClass(width, height), width, height, stored = entry,
                    address = WidgetAddress.CurrentLocation, locationDegradation = degradation,
                )
                val initial = present(WidgetLocationDegradation.Unavailable)
                val view = WidgetRenderer.render(context, initial, 42).apply(context, FrameLayout(context))
                val refresh = view.findViewById<View>(R.id.widget_refresh)
                assertEquals(View.VISIBLE, refresh.visibility)
                assertTrue(refresh.isEnabled)
                assertTrue(refresh.hasOnClickListeners())

                val states = listOf(
                    initial.copy(refreshFeedback = WidgetRefreshFeedback.Queued),
                    initial.copy(refreshFeedback = WidgetRefreshFeedback.Running),
                    initial.copy(refreshFeedback = WidgetRefreshFeedback.Failed),
                    present(WidgetLocationDegradation.UnusableFix),
                    present(WidgetLocationDegradation.Permission).copy(refreshFeedback = WidgetRefreshFeedback.Failed),
                    initial,
                    present(null).copy(refreshFeedback = WidgetRefreshFeedback.Updated),
                    initial,
                )
                for (state in states) {
                    WidgetRenderer.render(context, state, 42).reapply(context, view)
                    val busy = state.refreshFeedback == WidgetRefreshFeedback.Queued ||
                        state.refreshFeedback == WidgetRefreshFeedback.Running
                    val blocked = state.state == WidgetDisplayState.NeedsApp
                    val recovered = state.state == WidgetDisplayState.Ready
                    val visible = !blocked && !recovered
                    val actionable = visible && !busy
                    assertEquals(if (visible) View.VISIBLE else View.GONE, refresh.visibility)
                    assertEquals(actionable, refresh.isEnabled)
                    assertEquals(actionable, refresh.hasOnClickListeners())
                    assertEquals(if (busy) View.VISIBLE else View.GONE,
                        view.findViewById<View>(R.id.widget_refresh_progress).visibility)
                    assertEquals(if (busy) View.GONE else View.VISIBLE,
                        view.findViewById<View>(R.id.widget_refresh_icon).visibility)
                    if (actionable) {
                        val app = shadowOf(ApplicationProvider.getApplicationContext<android.app.Application>())
                        val count = app.broadcastIntents.size
                        assertTrue(refresh.performClick())
                        assertEquals(count + 1, app.broadcastIntents.size)
                        val sent = app.broadcastIntents.last()
                        assertEquals(WidgetRenderer.ACTION_REFRESH, sent.action)
                        assertEquals(42, sent.getIntExtra(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, -1))
                    } else {
                        assertFalse(refresh.performClick())
                    }
                    if (state.refreshFeedback == WidgetRefreshFeedback.Failed) {
                        assertEquals(context.getString(R.string.widget_refresh_failed), refresh.contentDescription)
                    }
                }
            }
        }
    }

    @Test
    fun `each instance renders its own remote views`() {
        // The intents are per-instance, so two instances must not share one
        // RemoteViews object (FLAG_UPDATE_CURRENT would rewrite the shared one).
        val first = WidgetRenderer.render(context, presentation(WidgetSizeClass.Medium), 1)
        val second = WidgetRenderer.render(context, presentation(WidgetSizeClass.Medium), 2)
        assertTrue(first !== second)
        assertEquals(clickTargets(first), clickTargets(second))
    }

    @Test
    fun `an unknown condition still draws a glyph`() {
        val view = WidgetRenderer.render(
            context,
            presentation(WidgetSizeClass.Small).copy(condition = null),
            appWidgetId = 3,
        ).apply(context, FrameLayout(context))
        val icon = view.findViewById<ImageView>(R.id.widget_icon)
        assertNotNull(icon)
        assertNotNull("the neutral marker must be set", icon.drawable)
    }

    @Test
    @org.robolectric.annotation.Config(qualifiers = "420dpi")
    @org.robolectric.annotation.GraphicsMode(org.robolectric.annotation.GraphicsMode.Mode.NATIVE)
    fun `the gallery preview mirrors the square layout and carries only sample text`() {
        // `previewLayout` is drawn by the launcher before any instance exists, so
        // every value has to be in the document itself — and the document has to
        // match the real square layout, at the size the small picker shows.
        val view = LayoutInflater.from(context)
            .inflate(R.layout.widget_preview, FrameLayout(context), false)
        val density = context.resources.displayMetrics.density
        val width = (120 * density).toInt()
        val height = (172 * density).toInt()
        view.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, width, height)
        for (text in leaves(view).filterIsInstance<TextView>()) {
            val canEllipsise = text.text == context.getString(R.string.widget_preview_location) ||
                text.text == context.getString(R.string.widget_preview_weather)
            WidgetTextVisibility.assertVisible("gallery '${text.text}'", text, canEllipsise)
        }

        val sampleTime = context.getString(R.string.widget_preview_time)
        val time = leaves(view)
            .filterIsInstance<TextView>()
            .firstOrNull { it.text?.toString() == sampleTime }
        assertNotNull("the preview must show its sample observation time", time)
        assertEquals(
            "the preview's observation time must not be ellipsised",
            0,
            time!!.layout?.getEllipsisCount(0) ?: 0,
        )

        // No data-bound id: the preview must never be fed a cache entry.
        for (id in listOf(
            R.id.widget_location,
            R.id.widget_humidity_value,
            R.id.widget_rain_value,
            R.id.widget_forecast_container,
            R.id.widget_stale,
        )) {
            assertEquals(
                "the preview must not carry the data id ${context.resources.getResourceEntryName(id)}",
                null,
                view.findViewById<View>(id),
            )
        }

        val texts = leaves(view).filterIsInstance<TextView>().map { it.text?.toString().orEmpty() }
        assertTrue("preview shows no sample text: $texts", texts.any { it.isNotBlank() })
        assertNotNull(view.findViewById<ImageView>(R.id.widget_icon))
    }

    private fun leaves(view: View): List<View> = if (view is android.view.ViewGroup) {
        (0 until view.childCount).flatMap { leaves(view.getChildAt(it)) }
    } else {
        listOf(view)
    }
}
