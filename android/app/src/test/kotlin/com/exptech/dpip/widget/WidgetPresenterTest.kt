package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.util.Locale

class WidgetPresenterTest {
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

    private fun atTaipei(hour: Int, minute: Int, second: Int = 0): Long =
        LocalDateTime.of(2026, 10, 12, hour, minute, second).toInstant(taipei).toEpochMilli()

    private fun snapshot(
        observationTime: Long = atTaipei(14, 0) / 1_000,
        offsetMilliseconds: Long = 0,
        isNight: Boolean = false,
        nextTransition: Long = Long.MAX_VALUE,
        regionCode: String = "407",
        source: String = "region:407",
        temperature: Double? = 27.5,
        humidity: Int? = 78,
        rain: Double? = 0.4,
        windSpeed: Double? = 1.3,
        windDirection: String? = "北北西",
        stationName: String = "西屯",
    ) = CurrentWeatherSnapshot(
        schemaVersion = 7,
        sourceIdentifier = source,
        regionCode = regionCode,
        regionName = "西屯區",
        observationTime = observationTime,
        stationName = stationName,
        weather = "多雲有雨",
        weatherCode = 206,
        condition = WeatherCondition.Rain,
        isNight = isNight,
        nextDayNightTransitionTime = nextTransition,
        calibratedTimeOffsetMilliseconds = offsetMilliseconds,
        temperature = temperature,
        humidity = humidity,
        rain = rain,
        windDirection = windDirection,
        windSpeed = windSpeed,
        apparentTemperature = 30.2,
    )

    private fun stored(snapshot: CurrentWeatherSnapshot) = StoredCurrentWeather(snapshot, 1, 1)

    private fun present(
        sizeClass: WidgetSizeClass = WidgetSizeClass.Large,
        address: WidgetAddress? = WidgetAddress.Saved("407"),
        stored: StoredCurrentWeather? = null,
        forecast: StoredForecast? = null,
        locationDegradation: WidgetLocationDegradation? = null,
        isCatalogMember: Boolean = true,
        calibratedNowMilliseconds: Long? = atTaipei(14, 20),
        locationName: String? = "西屯區",
        latitude: Double? = 24.181,
        longitude: Double? = 120.645,
    ) = WidgetPresenter.present(
        sizeClass = sizeClass,
        strings = strings,
        address = address,
        locationName = locationName,
        stored = stored,
        forecast = forecast,
        locationDegradation = locationDegradation,
        isCatalogMember = isCatalogMember,
        calibratedNowMilliseconds = calibratedNowMilliseconds,
        latitude = latitude,
        longitude = longitude,
    )

    @Test
    fun `size class comes from the measured size, not the cell count`() {
        // Height decides: the two-row layout needs room for the four-line hourly
        // columns, and the large one adds the detail grid below them.
        assertEquals(WidgetSizeClass.Small, WidgetPresenter.sizeClass(110, 110))
        assertEquals(WidgetSizeClass.Small, WidgetPresenter.sizeClass(199, 300))
        assertEquals(WidgetSizeClass.Small, WidgetPresenter.sizeClass(250, 103))
        assertEquals(WidgetSizeClass.Small, WidgetPresenter.sizeClass(250, 169))
        assertEquals(WidgetSizeClass.Medium, WidgetPresenter.sizeClass(250, 170))
        assertEquals(WidgetSizeClass.Medium, WidgetPresenter.sizeClass(340, 307))
        assertEquals(WidgetSizeClass.Medium, WidgetPresenter.sizeClass(339, 319))
        assertEquals(WidgetSizeClass.Large, WidgetPresenter.sizeClass(340, 308))
        // A Pixel 10a reports 373x312 for 4x3; it reads like its 4x4 cell.
        assertEquals(WidgetSizeClass.Large, WidgetPresenter.sizeClass(373, 312))
    }

    @Test
    fun `the square layout falls back to its compact form only below its own budget`() {
        // A Pixel 2x2 cell reports about 120x172 dp and gets the full square
        // layout; only the metadata's 110x110 minimum, a wide-but-short box, or
        // a large system font drops to the compact one.
        assertFalse(WidgetPresenter.compactLayout(120, 172))
        assertFalse(WidgetPresenter.compactLayout(118, 168))
        assertTrue(WidgetPresenter.compactLayout(118, 152))
        assertTrue(WidgetPresenter.compactLayout(158, 158))
        assertTrue(WidgetPresenter.compactLayout(110, 110))
        assertTrue(WidgetPresenter.compactLayout(250, 110))
        assertTrue(WidgetPresenter.compactLayout(199, 110))
        assertTrue(WidgetPresenter.compactLayout(120, 172, fontScale = 1.3f))
    }

    @Test
    fun `staleness is measured from the injected calibrated instant`() {
        val observation = atTaipei(14, 0) / 1_000
        val deadline = observation * 1_000 + 30 * 60 * 1_000

        assertTrue(
            present(
                stored = stored(snapshot(observation)),
                calibratedNowMilliseconds = deadline,
            ).isStale,
        )
        assertFalse(
            present(
                stored = stored(snapshot(observation)),
                calibratedNowMilliseconds = deadline - 1,
            ).isStale,
        )
    }

    @Test
    fun `an untrusted clock marks the data outdated rather than guessing`() {
        val presentation = present(
            stored = stored(snapshot(atTaipei(14, 0) / 1_000)),
            calibratedNowMilliseconds = null,
        )
        assertTrue(presentation.isStale)
        assertEquals("OUTDATED", presentation.badgeText)
        assertTrue(presentation.showRefresh)
    }

    @Test
    fun `the stored calibration offset never shifts the observation text`() {
        // The observation is already a server instant. Applying the
        // device→calibrated offset to it would move a correct reading by exactly
        // the amount the device clock is wrong, in whichever direction.
        val observation = atTaipei(14, 0) / 1_000
        val text = present(stored = stored(snapshot(observation))).observationTimeMillis
        val shiftedForward = present(
            address = WidgetAddress.CurrentLocation,
            stored = stored(snapshot(observation, offsetMilliseconds = 3_600_000, source = "current-location")),
        ).observationTimeMillis
        val shiftedBackward = present(
            address = WidgetAddress.CurrentLocation,
            stored = stored(snapshot(observation, offsetMilliseconds = -3_600_000, source = "current-location")),
        ).observationTimeMillis

        assertEquals(observation * 1_000, text)
        assertEquals(text, shiftedForward)
        assertEquals(text, shiftedBackward)
    }

    @Test
    fun `every family uses a fixed 24-hour Taipei observation clock`() {
        for (size in WidgetSizeClass.entries) {
            val presentation = present(sizeClass = size, stored = stored(snapshot()))
            assertEquals("14:00", WidgetPresenter.observationText(presentation.observationTimeMillis!!))
        }
        assertEquals("14:05", WidgetPresenter.observationText(atTaipei(14, 5)))
        assertEquals("00:00", WidgetPresenter.observationText(atTaipei(0, 0)))
        assertEquals("00:05", WidgetPresenter.observationText(atTaipei(0, 5)))
    }

    @Test
    fun `the full observation date and clock remain available for accessibility`() {
        assertEquals("2026/10/12 14:05", WidgetPresenter.observationDescription(atTaipei(14, 5)))
    }

    @Test
    fun `the observation text is correct across a year boundary`() {
        val newYearEve = LocalDateTime.of(2026, 12, 31, 23, 59)
            .toInstant(taipei).toEpochMilli()
        val newYearDay = LocalDateTime.of(2027, 1, 1, 0, 5)
            .toInstant(taipei).toEpochMilli()

        assertEquals("23:59", WidgetPresenter.observationText(newYearEve))
        assertEquals("00:05", WidgetPresenter.observationText(newYearDay))
        assertEquals("2026/12/31 23:59", WidgetPresenter.observationDescription(newYearEve))
        assertEquals("2027/01/01 00:05", WidgetPresenter.observationDescription(newYearDay))
    }

    @Test
    fun `the observation clock does not depend on the device locale or timezone`() {
        val original = Locale.getDefault()
        val originalZone = java.util.TimeZone.getDefault()
        try {
            Locale.setDefault(Locale.US)
            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("America/Los_Angeles"))
            val us = WidgetPresenter.observationText(atTaipei(14, 5))
            Locale.setDefault(Locale.JAPAN)
            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("UTC"))
            val japan = WidgetPresenter.observationText(atTaipei(14, 5))

            assertEquals("the format must be explicit, not locale-ordered", us, japan)
            assertEquals("14:05", us)
        } finally {
            Locale.setDefault(original)
            java.util.TimeZone.setDefault(originalZone)
        }
    }

    @Test
    fun `day and night flips without a fresh publish once the transition passes`() {
        val observation = atTaipei(14, 0) / 1_000
        val transition = WidgetSolarTime.nextDayNightTransitionSecondsAt(observation * 1_000, 24.181, 120.645)
        val entry = stored(snapshot(observation, isNight = false, nextTransition = transition))

        assertEquals(false, present(stored = entry, calibratedNowMilliseconds = transition * 1_000 - 1).isNight)
        assertEquals(true, present(stored = entry, calibratedNowMilliseconds = transition * 1_000).isNight)
    }

    @Test
    fun `a saved town removed from the catalog is a reconfigure, not a blank`() {
        val presentation = present(
            address = WidgetAddress.Saved("407"),
            stored = stored(snapshot()),
            isCatalogMember = false,
        )
        assertEquals(WidgetDisplayState.Reconfigure, presentation.state)
        assertEquals("RECONFIGURE", presentation.badgeText)
        assertEquals("OPEN_APP", presentation.hintText)
        assertNull(presentation.locationName)
    }

    @Test
    fun `no snapshot yet is a no-data state offering to open the app`() {
        val presentation = present(address = WidgetAddress.Saved("407"), stored = null)
        assertEquals(WidgetDisplayState.NoData, presentation.state)
        assertEquals("NO_DATA", presentation.badgeText)
        assertEquals("OPEN_APP", presentation.hintText)
    }

    @Test
    fun `each location degradation says something different`() {
        val cases = mapOf(
            WidgetLocationDegradation.Permission to "NEEDS_APP",
            WidgetLocationDegradation.UnusableFix to "NO_FIX",
            WidgetLocationDegradation.Disabled to "LOCATION_OFF",
            WidgetLocationDegradation.Unavailable to "NO_FIX",
            WidgetLocationDegradation.UnresolvedTownship to "OUTSIDE",
        )
        for ((degradation, expected) in cases) {
            val presentation = present(
                address = WidgetAddress.CurrentLocation,
                stored = stored(snapshot(source = "current-location")),
                locationDegradation = degradation,
            )
            assertEquals(degradation.name, expected, presentation.badgeText)
            val expectedState = when (degradation) {
                WidgetLocationDegradation.Permission, WidgetLocationDegradation.Disabled -> WidgetDisplayState.NeedsApp
                else -> WidgetDisplayState.LocationUnavailable
            }
            assertEquals(expectedState, presentation.state)
        }
    }

    @Test
    fun `a degradation is also reported before any snapshot exists`() {
        val presentation = present(
            address = WidgetAddress.CurrentLocation,
            stored = null,
            locationDegradation = WidgetLocationDegradation.Permission,
        )
        assertEquals(WidgetDisplayState.NeedsApp, presentation.state)
        assertEquals("NEEDS_APP", presentation.badgeText)
    }

    @Test
    fun `a stale observation outranks the position notice`() {
        val observation = atTaipei(14, 0) / 1_000
        val presentation = present(
            address = WidgetAddress.CurrentLocation,
            stored = stored(snapshot(observation, source = "current-location")),
            locationDegradation = WidgetLocationDegradation.Permission,
            calibratedNowMilliseconds = observation * 1_000 + 31 * 60 * 1_000,
        )
        assertEquals("OUTDATED", presentation.badgeText)
    }

    @Test
    fun `composes the small metric row with a localized decimal`() {
        val presentation = present(
            sizeClass = WidgetSizeClass.Small,
            stored = stored(snapshot()),
        )
        assertEquals("78%", presentation.humidityText)
        assertTrue(presentation.rainText!!.endsWith("mm"))
        assertTrue(presentation.rainText!!.startsWith("0.4"))
        assertEquals("FEELS 30°", presentation.apparentText)
        assertTrue(presentation.forecast.isEmpty())
        assertTrue(presentation.hasObservation)
    }

    @Test
    fun `a missing reading keeps its placeholder instead of vanishing`() {
        // iOS draws `--%`, `-- mm` and `--°` rather than dropping the line, and
        // the large grid keeps its labels either way.
        val presentation = present(
            sizeClass = WidgetSizeClass.Small,
            stored = stored(snapshot(humidity = null, rain = null, temperature = null)),
        )
        assertEquals("--%", presentation.humidityText)
        assertEquals("-- mm", presentation.rainText)
        assertEquals("--°", presentation.temperatureText)
    }

    @Test
    fun `the large layout falls back to an em-dash temperature`() {
        val presentation = present(
            sizeClass = WidgetSizeClass.Large,
            stored = stored(snapshot(temperature = null)),
        )
        assertEquals("—°", presentation.temperatureText)
    }

    @Test
    fun `wind and station fall back to a placeholder`() {
        val presentation = present(
            sizeClass = WidgetSizeClass.Large,
            stored = stored(snapshot(windSpeed = null, windDirection = null, stationName = "")),
        )
        assertEquals("--", presentation.windText)
        assertEquals("--", presentation.stationText)
    }

    // ── Forecast ────────────────────────────────────────────────────────────

    @Test
    fun `fresh observations hide refresh and Small does not require a forecast`() {
        for (size in WidgetSizeClass.entries) {
            val fresh = present(sizeClass = size, stored = stored(snapshot()), forecast = forecast())
            assertTrue(fresh.canRefresh)
            assertFalse(fresh.showRefresh)
            assertFalse(fresh.copy(refreshFeedback = WidgetRefreshFeedback.Updated).showRefresh)
        }
        val small = present(sizeClass = WidgetSizeClass.Small, stored = stored(snapshot()), forecast = null)
        assertTrue(small.forecast.isEmpty())
        assertFalse(small.showRefresh)
    }

    @Test
    fun `Medium and Large offer refresh when no usable hourly points remain`() {
        for (size in listOf(WidgetSizeClass.Medium, WidgetSizeClass.Large)) {
            val unusableForecasts = listOf(
                null,
                forecast(expiresAt = atTaipei(14, 20)),
                forecast(points = emptyList()),
                forecast(regionCode = "100"),
                forecast(source = "current-location"),
                forecast(points = listOf(ForecastPoint("14:00", 27.0, "多雲", 200, 20))),
            )
            for (forecast in unusableForecasts) {
                val presentation = present(sizeClass = size, stored = stored(snapshot()), forecast = forecast)
                assertFalse("observation is still fresh", presentation.isStale)
                assertTrue(presentation.forecast.isEmpty())
                assertTrue(presentation.showRefresh)
                assertTrue(presentation.copy(refreshFeedback = WidgetRefreshFeedback.Updated).showRefresh)
            }
        }
    }

    @Test
    fun `stale observations and manual failures offer refresh in every family`() {
        for (size in WidgetSizeClass.entries) {
            val fresh = present(sizeClass = size, stored = stored(snapshot()), forecast = forecast())
            assertTrue(fresh.copy(refreshFeedback = WidgetRefreshFeedback.Failed).showRefresh)
            val stale = present(sizeClass = size, stored = stored(snapshot()), forecast = forecast(),
                calibratedNowMilliseconds = atTaipei(14, 30))
            assertTrue(stale.isStale)
            assertTrue(stale.showRefresh)
        }
    }

    @Test
    fun `queued and running feedback stays visible until fresh success or idle`() {
        val fresh = present(stored = stored(snapshot()), forecast = forecast())
        assertFalse(fresh.showRefresh)
        for (feedback in listOf(WidgetRefreshFeedback.Queued, WidgetRefreshFeedback.Running)) {
            assertTrue(fresh.copy(refreshFeedback = feedback).showRefresh)
        }
        assertFalse(fresh.copy(refreshFeedback = WidgetRefreshFeedback.Updated).showRefresh)
        assertFalse(fresh.copy(refreshFeedback = null).showRefresh)
    }

    @Test
    fun `no observation offers refresh only for a configured actionable source`() {
        for (size in WidgetSizeClass.entries) {
            for (address in listOf(WidgetAddress.Saved("407"), WidgetAddress.CurrentLocation)) {
                assertTrue(present(sizeClass = size, address = address).showRefresh)
            }
            val unconfigured = present(sizeClass = size, address = null)
            val reconfigure = present(sizeClass = size, isCatalogMember = false)
            for (blocked in listOf(unconfigured, reconfigure)) {
                assertFalse(blocked.canRefresh)
                assertFalse(blocked.showRefresh)
                assertFalse(blocked.copy(refreshFeedback = WidgetRefreshFeedback.Failed).showRefresh)
            }
        }
    }

    @Test
    fun `location states requiring the app hide retries but retain active progress`() {
        for (degradation in listOf(WidgetLocationDegradation.Permission, WidgetLocationDegradation.Disabled)) {
            for (stored in listOf(null, stored(snapshot(source = "current-location")))) {
                val blocked = present(address = WidgetAddress.CurrentLocation, stored = stored,
                    locationDegradation = degradation, calibratedNowMilliseconds = null)
                assertEquals(WidgetDisplayState.NeedsApp, blocked.state)
                assertEquals(if (stored == null) "OPEN_APP" else null, blocked.hintText)
                assertFalse(blocked.canRefresh)
                assertFalse(blocked.showRefresh)
                assertFalse(blocked.copy(refreshFeedback = WidgetRefreshFeedback.Failed).showRefresh)
                for (feedback in listOf(WidgetRefreshFeedback.Queued, WidgetRefreshFeedback.Running)) {
                    assertTrue(blocked.copy(refreshFeedback = feedback).showRefresh)
                }
            }
        }
    }

    @Test
    fun `temporary location failures allow retry with or without a cached observation`() {
        for (degradation in listOf(WidgetLocationDegradation.Unavailable, WidgetLocationDegradation.UnusableFix,
            WidgetLocationDegradation.UnresolvedTownship)) {
            for (size in WidgetSizeClass.entries) {
                for (entry in listOf(null, stored(snapshot(source = "current-location")))) {
                    // A usable forecast and a fresh observation must not hide a location retry.
                    for (now in listOf(atTaipei(14, 20), atTaipei(14, 30), null)) {
                        val retry = present(sizeClass = size, address = WidgetAddress.CurrentLocation,
                            stored = entry, forecast = forecast(source = "current-location"),
                            locationDegradation = degradation, calibratedNowMilliseconds = now)
                        assertEquals(WidgetDisplayState.LocationUnavailable, retry.state)
                        assertEquals(entry != null, retry.hasObservation)
                        assertEquals(entry != null && (now == null || now >= atTaipei(14, 30)), retry.isStale)
                        assertEquals(
                            if (retry.isStale) "OUTDATED"
                            else if (degradation == WidgetLocationDegradation.UnresolvedTownship) "OUTSIDE"
                            else "NO_FIX",
                            retry.badgeText,
                        )
                        assertNull(retry.hintText)
                        assertTrue(retry.canRefresh)
                        assertTrue(retry.showRefresh)
                        assertTrue(retry.copy(refreshFeedback = WidgetRefreshFeedback.Failed).showRefresh)
                        for (feedback in listOf(WidgetRefreshFeedback.Queued, WidgetRefreshFeedback.Running)) {
                            assertTrue(retry.copy(refreshFeedback = feedback).showRefresh)
                        }
                    }
                }
            }
        }
    }

    @Test
    fun `a recovered location hides retry only when observation and required forecast are fresh`() {
        for (degradation in listOf(WidgetLocationDegradation.Unavailable, WidgetLocationDegradation.UnusableFix,
            WidgetLocationDegradation.UnresolvedTownship)) {
            for (size in WidgetSizeClass.entries) {
                val entry = stored(snapshot(source = "current-location"))
                val hourly = forecast(source = "current-location")
                val failed = present(sizeClass = size, address = WidgetAddress.CurrentLocation,
                    stored = entry, forecast = hourly, locationDegradation = degradation)
                    .copy(refreshFeedback = WidgetRefreshFeedback.Failed)
                assertTrue(failed.showRefresh)

                val recovered = present(sizeClass = size, address = WidgetAddress.CurrentLocation,
                    stored = entry, forecast = hourly, locationDegradation = null)
                    .copy(refreshFeedback = WidgetRefreshFeedback.Updated)
                assertEquals(WidgetDisplayState.Ready, recovered.state)
                assertNull(recovered.badgeText)
                assertNull(recovered.hintText)
                assertTrue(recovered.canRefresh)
                assertFalse(recovered.showRefresh)
                assertTrue(recovered.copy(isStale = true).showRefresh)
                assertEquals(size != WidgetSizeClass.Small, recovered.copy(forecast = emptyList()).showRefresh)
            }
        }
    }

    @Test
    fun `location degradation does not block saved sources or enable unconfigured sources`() {
        for (degradation in WidgetLocationDegradation.entries) {
            for (entry in listOf(null, stored(snapshot()))) {
                for (size in WidgetSizeClass.entries) {
                    val saved = present(sizeClass = size, stored = entry, forecast = forecast(),
                        locationDegradation = degradation)
                    assertTrue(saved.canRefresh)
                    assertEquals(entry == null, saved.showRefresh)
                    assertTrue(saved.copy(refreshFeedback = WidgetRefreshFeedback.Failed).showRefresh)

                    for (blocked in listOf(
                        present(sizeClass = size, address = null, stored = entry, locationDegradation = degradation),
                        present(sizeClass = size, stored = entry, locationDegradation = degradation, isCatalogMember = false),
                    )) {
                        assertFalse(blocked.canRefresh)
                        assertFalse(blocked.showRefresh)
                        assertFalse(blocked.copy(refreshFeedback = WidgetRefreshFeedback.Failed).showRefresh)
                    }
                }
            }
        }
    }

    /**
     * A stored forecast, whose deadline was fixed when it was accepted.
     *
     * The presenter no longer derives the deadline: it uses the one the commit
     * recorded, so these tests set it explicitly and `WidgetDeadlinesTest` owns
     * how it is derived.
     */
    private fun forecast(
        expiresAt: Long = atTaipei(15, 0),
        regionCode: String = "407",
        source: String = "region:407",
        points: List<ForecastPoint> = listOf(
            ForecastPoint("15:00", 27.0, "多雲", 200, 20),
            ForecastPoint("16:00", 26.0, "多雲有雨", 206, 60),
        ),
    ) = StoredForecast(
        forecast = ForecastSnapshot(
            schemaVersion = 1,
            sourceIdentifier = source,
            regionCode = regionCode,
            updateTime = atTaipei(14, 10),
            receivedAt = atTaipei(14, 10),
            points = points,
        ),
        receivedCalibratedMilliseconds = atTaipei(14, 10),
        expiresAtMilliseconds = expiresAt,
    )

    @Test
    fun `a forecast is hidden when it belongs to another township`() {
        val presentation = present(
            stored = stored(snapshot()),
            forecast = forecast(regionCode = "100"),
        )
        assertTrue(presentation.forecast.isEmpty())
    }

    @Test
    fun `a forecast is hidden when its address is not the snapshot's`() {
        val presentation = present(
            stored = stored(snapshot()),
            forecast = forecast(source = "current-location"),
        )
        assertTrue(presentation.forecast.isEmpty())
    }

    @Test
    fun `a forecast is hidden when the clock is untrusted`() {
        val presentation = present(
            stored = stored(snapshot()),
            forecast = forecast(),
            calibratedNowMilliseconds = null,
        )
        assertTrue(presentation.forecast.isEmpty())
    }

    @Test
    fun `a forecast is drawn until its recorded deadline and hidden from it`() {
        val deadline = atTaipei(15, 0)
        val entry = stored(snapshot())
        val forecast = forecast(expiresAt = deadline)

        assertFalse(
            present(
                stored = entry,
                forecast = forecast,
                calibratedNowMilliseconds = deadline - 1,
            ).forecast.isEmpty(),
        )
        assertTrue(
            present(
                stored = entry,
                forecast = forecast,
                calibratedNowMilliseconds = deadline,
            ).forecast.isEmpty(),
        )
    }

    @Test
    fun `the deadline is the stored one, not one derived from the snapshot offset`() {
        // The snapshot carries an hour of device→calibrated correction. Deriving
        // the deadline from it would move a 15:00 expiry an hour later; the stored
        // deadline is what the commit recorded and it does not move.
        val deadline = atTaipei(15, 0)
        val entry = stored(snapshot(offsetMilliseconds = 3_600_000))
        val forecast = forecast(expiresAt = deadline)

        assertTrue(
            present(
                stored = entry,
                forecast = forecast,
                calibratedNowMilliseconds = atTaipei(15, 5),
            ).forecast.isEmpty(),
        )
    }

    @Test
    fun `forecast selection is by clock distance and drops the ambiguous past`() {
        val now = atTaipei(14, 20)
        val points = listOf(
            ForecastPoint("17:00", 25.0, "多雲", 200, null),
            ForecastPoint("14:00", 27.0, "多雲", 200, null), // 1420 minutes ahead: too far
            ForecastPoint("15:00", 26.0, "多雲", 200, null),
            ForecastPoint("02:00", 22.0, "多雲", 200, null), // 700 minutes ahead: tomorrow
        )
        val selected = WidgetPresenter.upcoming(points, now, limit = 5)
        assertEquals(listOf("15:00", "17:00", "02:00"), selected.map { it.time })
    }

    @Test
    fun `forecast selection keeps the current minute and caps at five`() {
        val now = atTaipei(14, 20)
        val points = listOf(
            ForecastPoint("14:20", 27.0, "now", 200, null),
            ForecastPoint("15:00", 27.0, "next", 200, null),
            ForecastPoint("16:00", 27.0, "third", 200, null),
            ForecastPoint("17:00", 27.0, "fourth", 200, null),
            ForecastPoint("18:00", 27.0, "fifth", 200, null),
            ForecastPoint("19:00", 27.0, "sixth", 200, null),
            ForecastPoint("20:00", 27.0, "seventh", 200, null),
        )
        val selected = WidgetPresenter.upcoming(points, now, limit = 5)
        // The current minute is eligible, so 14:20 leads and the cap drops the
        // two furthest points.
        assertEquals(5, selected.size)
        assertEquals("now", selected.first().weather)
        assertEquals("fifth", selected.last().weather)
    }

    @Test
    fun `forecast ties keep the API order`() {
        val now = atTaipei(14, 20)
        val points = listOf(
            ForecastPoint("15:00", 1.0, "first", 200, null),
            ForecastPoint("15:00", 2.0, "second", 200, null),
        )
        val selected = WidgetPresenter.upcoming(points, now, limit = 5)
        assertEquals(listOf("first", "second"), selected.map { it.weather })
    }

    @Test
    fun `a medium or large instance draws the forecast inside its own expiry`() {
        val presentation = present(
            sizeClass = WidgetSizeClass.Medium,
            stored = stored(snapshot()),
            forecast = forecast(),
        )
        assertEquals(2, presentation.forecast.size)
        assertEquals("20%", presentation.forecast[0].popText)
    }

    @Test
    fun `a compact instance never draws a forecast`() {
        val presentation = present(
            sizeClass = WidgetSizeClass.Small,
            stored = stored(snapshot()),
            forecast = forecast(),
        )
        assertTrue(presentation.forecast.isEmpty())
    }

    @Test
    fun `the sun cell names the next crossing by phase`() {
        // iOS labels the next day/night transition sunrise or sunset by the
        // phase the snapshot's day/night says, and draws that instant.
        val transition = atTaipei(18, 0) / 1_000
        val day = present(
            stored = stored(snapshot(isNight = false, nextTransition = transition)),
        )
        assertEquals("SUNSET", day.sunLabel)
        assertEquals("18:00", day.sunValue)

        val night = present(
            stored = stored(snapshot(isNight = true, nextTransition = transition)),
        )
        assertEquals("SUNRISE", night.sunLabel)
        assertEquals("18:00", night.sunValue)
    }

    @Test
    fun `an unknown day-night transition draws a placeholder`() {
        val presentation = present(stored = stored(snapshot(nextTransition = 0)))
        assertEquals("SUNSET", presentation.sunLabel)
        assertEquals("--", presentation.sunValue)
    }

    @Test
    fun `a cached sunset becomes the next sunrise at and after the crossing`() {
        val sunset = WidgetSolarTime.nextDayNightTransitionSecondsAt(atTaipei(14, 20), 24.181, 120.645)
        val entry = stored(snapshot(isNight = false, nextTransition = sunset))
        for (now in listOf(sunset * 1_000, sunset * 1_000 + 60_000)) {
            val next = WidgetSolarTime.nextDayNightTransitionSecondsAt(now, 24.181, 120.645)
            val presentation = present(stored = entry, calibratedNowMilliseconds = now)

            assertTrue(presentation.isNight)
            assertEquals("SUNRISE", presentation.sunLabel)
            assertEquals(WidgetPresenter.observationText(next * 1_000).takeLast(5), presentation.sunValue)
            assertTrue(next > sunset)
        }
    }

    @Test
    fun `a cached sunrise becomes the next sunset at and after the crossing`() {
        val sunrise = WidgetSolarTime.nextDayNightTransitionSecondsAt(atTaipei(0, 0), 24.181, 120.645)
        val entry = stored(snapshot(isNight = true, nextTransition = sunrise))
        for (now in listOf(sunrise * 1_000, sunrise * 1_000 + 60_000)) {
            val next = WidgetSolarTime.nextDayNightTransitionSecondsAt(now, 24.181, 120.645)
            val presentation = present(stored = entry, calibratedNowMilliseconds = now)

            assertFalse(presentation.isNight)
            assertEquals("SUNSET", presentation.sunLabel)
            assertEquals(WidgetPresenter.observationText(next * 1_000).takeLast(5), presentation.sunValue)
            assertTrue(next > sunrise)
        }
    }

    @Test
    fun `a snapshot kept for several days still names the next crossing at the current location`() {
        val sunset = WidgetSolarTime.nextDayNightTransitionSecondsAt(atTaipei(14, 20), 24.181, 120.645)
        val now = atTaipei(14, 20) + 2 * 86_400_000L
        val next = WidgetSolarTime.nextDayNightTransitionSecondsAt(now, 24.181, 120.645)
        val presentation = present(
            stored = stored(snapshot(isNight = false, nextTransition = sunset)),
            calibratedNowMilliseconds = now,
        )

        assertFalse(presentation.isNight)
        assertEquals("SUNSET", presentation.sunLabel)
        assertEquals(WidgetPresenter.observationText(next * 1_000).takeLast(5), presentation.sunValue)
        assertTrue(presentation.isStale)
    }

    @Test
    fun `an elapsed crossing without coordinates is unknown rather than relabeled as the next one`() {
        val presentation = present(
            stored = stored(snapshot(isNight = false, nextTransition = atTaipei(18, 0) / 1_000)),
            calibratedNowMilliseconds = atTaipei(18, 1),
            latitude = null,
            longitude = null,
        )
        assertEquals("SUNRISE", presentation.sunLabel)
        assertEquals("--", presentation.sunValue)
    }
}
