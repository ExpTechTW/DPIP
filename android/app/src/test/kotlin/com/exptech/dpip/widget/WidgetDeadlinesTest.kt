package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDateTime
import java.time.ZoneOffset

/**
 * The instants the refresh worker schedules a cache-only redraw at.
 *
 * Pinned as a pure function because the value is a *delay* passed to
 * WorkManager: getting it wrong is not visibly broken, it is a redraw that
 * arrives too early (and then again, and again) or too late (so the screen stays
 * stale). The version this replaced clamped every delay to sixty seconds, which
 * made "the next boundary" mean "a minute from now" whatever it actually was.
 */
class WidgetDeadlinesTest {
    private val taipei = ZoneOffset.ofHours(8)

    private fun atTaipei(hour: Int, minute: Int): Long =
        LocalDateTime.of(2026, 10, 12, hour, minute).toInstant(taipei).toEpochMilli()

    private fun snapshot(
        observationSeconds: Long,
        nextTransitionSeconds: Long = 0,
        offsetMilliseconds: Long = 0,
    ) = CurrentWeatherSnapshot(
        schemaVersion = 7,
        sourceIdentifier = "region:407",
        regionCode = "407",
        regionName = "西屯區",
        observationTime = observationSeconds,
        stationName = "西屯",
        weather = "晴",
        weatherCode = 100,
        condition = WeatherCondition.Clear,
        isNight = false,
        nextDayNightTransitionTime = nextTransitionSeconds,
        calibratedTimeOffsetMilliseconds = offsetMilliseconds,
        temperature = 27.0,
        humidity = 60,
        rain = 0.0,
        windDirection = null,
        windSpeed = null,
        apparentTemperature = null,
    )

    @Test
    fun `staleness is thirty minutes after the observation, in calibrated time`() {
        val observation = atTaipei(14, 0) / 1_000
        assertEquals(
            observation * 1_000 + 30 * 60 * 1_000,
            WidgetDeadlines.staleness(snapshot(observation)),
        )
    }

    @Test
    fun `a snapshot without a transition has no day or night boundary`() {
        assertNull(WidgetDeadlines.dayNight(snapshot(1_000, nextTransitionSeconds = 0)))
        assertEquals(2_000_000L, WidgetDeadlines.dayNight(snapshot(1_000, nextTransitionSeconds = 2_000)))
    }

    @Test
    fun `the earlier of publication plus thirty minutes and the next Taipei hour wins`() {
        // Published and received at 14:10, so the next Taipei hour is 15:00
        // (50 min), which is later than publication + 30 min.
        assertEquals(
            atTaipei(14, 40),
            WidgetDeadlines.forecastExpiry(
                updateTimeMilliseconds = atTaipei(14, 10),
                receivedCalibratedMilliseconds = atTaipei(14, 10),
            ),
        )
        // Published and received at 14:45: the next hour is 15 minutes away and
        // is earlier than publication + 30 minutes.
        assertEquals(
            atTaipei(15, 0),
            WidgetDeadlines.forecastExpiry(
                updateTimeMilliseconds = atTaipei(14, 45),
                receivedCalibratedMilliseconds = atTaipei(14, 45),
            ),
        )
    }

    @Test
    fun `the receipt is taken in calibrated time`() {
        // A receipt read at 14:45 calibrated, published at 14:45.
        assertEquals(
            atTaipei(15, 0),
            WidgetDeadlines.forecastExpiry(
                updateTimeMilliseconds = atTaipei(14, 45),
                receivedCalibratedMilliseconds = atTaipei(14, 45),
            ),
        )
        // The same instant before it was brought into calibrated time would give
        // an hour earlier — which is the bug that a *later* offset could not
        // repair, and why the receipt is fixed at commit.
        assertEquals(
            atTaipei(14, 0),
            WidgetDeadlines.forecastExpiry(
                updateTimeMilliseconds = atTaipei(14, 45),
                receivedCalibratedMilliseconds = atTaipei(13, 45),
            ),
        )
    }

    private fun storedForecast(expiresAt: Long) = StoredForecast(
        forecast = ForecastSnapshot(
            schemaVersion = 1,
            sourceIdentifier = "region:407",
            regionCode = "407",
            updateTime = 0,
            receivedAt = 0,
            points = listOf(ForecastPoint("15:00", 27.0, "晴", 100, null)),
        ),
        receivedCalibratedMilliseconds = 0,
        expiresAtMilliseconds = expiresAt,
    )

    @Test
    fun `the next change is the earliest boundary still in the future`() {
        val observation = atTaipei(14, 0) / 1_000
        // The transition is twenty minutes away; staleness is thirty.
        val entry = snapshot(observation, nextTransitionSeconds = observation + 20 * 60)

        assertEquals(
            (observation + 20 * 60) * 1_000,
            WidgetDeadlines.nextChange(entry, null, atTaipei(14, 0)),
        )
        // Past the transition, staleness is the next thing to happen.
        assertEquals(
            observation * 1_000 + 30 * 60 * 1_000,
            WidgetDeadlines.nextChange(entry, null, atTaipei(14, 21)),
        )
        // Past both, nothing will change on its own.
        assertNull(WidgetDeadlines.nextChange(entry, null, atTaipei(14, 31)))
    }

    @Test
    fun `a forecast expiry earlier than the observation boundary is scheduled`() {
        val observation = atTaipei(14, 0) / 1_000
        val forecast = storedForecast(atTaipei(15, 0))
        // Staleness is 14:30 and the forecast expires at 15:00, so staleness wins.
        assertEquals(
            observation * 1_000 + 30 * 60 * 1_000,
            WidgetDeadlines.nextChange(snapshot(observation), forecast, atTaipei(14, 0)),
        )
        // Once the observation is stale, the forecast expiry is the next change.
        assertEquals(
            atTaipei(15, 0),
            WidgetDeadlines.nextChange(snapshot(observation), forecast, atTaipei(14, 31)),
        )
    }
}
