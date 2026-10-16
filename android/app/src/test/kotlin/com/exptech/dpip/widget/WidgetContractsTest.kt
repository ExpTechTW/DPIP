package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetContractsTest {
    @Test
    fun `classifies every documented weather-code family`() {
        // Plain sky, from the hundreds family only when there is no phenomenon.
        assertEquals(WeatherCondition.Clear, weatherConditionForCode(100))
        assertEquals(WeatherCondition.Cloudy, weatherConditionForCode(200))
        assertEquals(WeatherCondition.Overcast, weatherConditionForCode(300))
        // A phenomenon suffix wins over its family: 106 is rain, not clear.
        assertEquals(WeatherCondition.Rain, weatherConditionForCode(106))
        assertEquals(WeatherCondition.Rain, weatherConditionForCode(206))
        assertEquals(WeatherCondition.Fog, weatherConditionForCode(101))
        assertEquals(WeatherCondition.Fog, weatherConditionForCode(105))
        assertEquals(WeatherCondition.Thunderstorm, weatherConditionForCode(114))
        assertEquals(WeatherCondition.Thunderstorm, weatherConditionForCode(117))
        assertEquals(WeatherCondition.Snow, weatherConditionForCode(108))
        assertEquals(WeatherCondition.Rain, weatherConditionForCode(113))
        assertEquals(WeatherCondition.Snow, weatherConditionForCode(110))
        // Unknown families, codes below the range and non-positive codes.
        assertEquals(WeatherCondition.Unknown, weatherConditionForCode(400))
        assertEquals(WeatherCondition.Unknown, weatherConditionForCode(0))
        assertEquals(WeatherCondition.Unknown, weatherConditionForCode(-99))
    }

    @Test
    fun `parses the two legal source identifiers and nothing else`() {
        assertEquals(WidgetAddress.CurrentLocation, WidgetAddress.fromSourceIdentifier("current-location"))
        assertEquals(WidgetAddress.Saved("407"), WidgetAddress.fromSourceIdentifier("region:407"))
        assertNull(WidgetAddress.fromSourceIdentifier(null))
        assertNull(WidgetAddress.fromSourceIdentifier("current"))
        assertNull(WidgetAddress.fromSourceIdentifier("region:"))
        assertNull(WidgetAddress.fromSourceIdentifier("region:40"))
        assertNull(WidgetAddress.fromSourceIdentifier("region:4077"))
        assertNull(WidgetAddress.fromSourceIdentifier("region:4O7"))
        assertNull(WidgetAddress.fromSourceIdentifier("region:407/../../etc"))
    }

    @Test
    fun `round-trips a source identifier`() {
        for (address in listOf(WidgetAddress.CurrentLocation, WidgetAddress.Saved("100"))) {
            assertEquals(address, WidgetAddress.fromSourceIdentifier(address.sourceIdentifier))
        }
    }

    @Test
    fun `rejects an out-of-range or non-finite coordinate`() {
        assertNull(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 91.0, 120.0))
        assertNull(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.0, 181.0))
        assertNull(WidgetCatalogLocation.create("407", "西屯區", "臺中市", Double.NaN, 120.0))
        assertNull(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.0, Double.POSITIVE_INFINITY))
        assertTrue(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645) != null)
    }

    @Test
    fun `an empty display name is not a location`() {
        assertNull(WidgetCatalogLocation.create("407", "", "臺中市", 24.181, 120.645))
    }

    @Test
    fun `a saved resolved location must name its own town`() {
        assertNull(
            ResolvedWeatherLocation.create(
                address = WidgetAddress.Saved("407"),
                regionCode = "100",
                regionName = "中正區",
                latitude = 25.0,
                longitude = 121.5,
            ),
        )
        assertTrue(
            ResolvedWeatherLocation.create(
                address = WidgetAddress.Saved("407"),
                regionCode = "407",
                regionName = "西屯區",
                latitude = 24.181,
                longitude = 120.645,
            ) != null,
        )
    }

    @Test
    fun `a forecast clock label is only a label when it is HH mm`() {
        assertEquals(840, ForecastPoint("14:00", 27.0, "多雲", 200, null).minutesSinceMidnight)
        assertEquals(0, ForecastPoint("00:00", 27.0, "多雲", 200, null).minutesSinceMidnight)
        assertEquals(1439, ForecastPoint("23:59", 27.0, "多雲", 200, null).minutesSinceMidnight)
        assertNull(ForecastPoint("9:00", 27.0, "多雲", 200, null).minutesSinceMidnight)
        assertNull(ForecastPoint("24:00", 27.0, "多雲", 200, null).minutesSinceMidnight)
        assertNull(ForecastPoint("14:60", 27.0, "多雲", 200, null).minutesSinceMidnight)
        assertNull(ForecastPoint("14-00", 27.0, "多雲", 200, null).minutesSinceMidnight)
        assertNull(ForecastPoint("", 27.0, "多雲", 200, null).minutesSinceMidnight)
    }

    @Test
    fun `a snapshot exposes the address its source names`() {
        val snapshot = CurrentWeatherSnapshot(
            schemaVersion = 7,
            sourceIdentifier = "region:407",
            regionCode = "407",
            regionName = "西屯區",
            observationTime = 1,
            stationName = "西屯",
            weather = "晴",
            weatherCode = 100,
            condition = WeatherCondition.Clear,
            isNight = false,
            nextDayNightTransitionTime = 2,
            calibratedTimeOffsetMilliseconds = 0,
            temperature = null,
            humidity = null,
            rain = null,
            windDirection = null,
            windSpeed = null,
            apparentTemperature = null,
        )
        assertEquals(WidgetAddress.Saved("407"), snapshot.address)
    }

    @Test
    fun `no source identifier is unknown rather than empty`() {
        assertFalse(WidgetAddress.fromSourceIdentifier("") is WidgetAddress.Saved)
    }
}
