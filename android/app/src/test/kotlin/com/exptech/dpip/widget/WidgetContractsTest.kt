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
    fun `widget codes distinguish mixed precipitation hail thunder and thunder snow`() {
        val cases = mapOf(
            3 to WidgetWeatherCondition.Thunder,
            4 to WidgetWeatherCondition.Thunder,
            7 to WidgetWeatherCondition.Sleet,
            12 to WidgetWeatherCondition.Sleet,
            13 to WidgetWeatherCondition.Hail,
            15 to WidgetWeatherCondition.Snow,
            16 to WidgetWeatherCondition.Hail,
            18 to WidgetWeatherCondition.Hail,
            19 to WidgetWeatherCondition.Thunder,
        )
        for (sky in listOf(100, 200, 300)) {
            for ((suffix, expected) in cases) {
                val code = sky + suffix
                val point = ForecastPoint("15:00", 20.0, "短暫雨", code, null)
                assertEquals("code=$code", expected, point.condition)
            }
        }
        assertEquals(WidgetWeatherCondition.Clear, WidgetWeatherCondition.from("晴", 100))
        assertEquals(WidgetWeatherCondition.Cloudy, WidgetWeatherCondition.from("多雲", 200))
        assertEquals(WidgetWeatherCondition.Overcast, WidgetWeatherCondition.from("陰", 300))
    }

    @Test
    fun `widget text distinguishes thunder hail rain snow and mixed precipitation`() {
        val cases = mapOf(
            "短暫雷陣雨或雪" to WidgetWeatherCondition.Thunderstorm,
            "雷雪" to WidgetWeatherCondition.Snow,
            "雷雹" to WidgetWeatherCondition.Hail,
            "雨雪" to WidgetWeatherCondition.Sleet,
            "雷聲" to WidgetWeatherCondition.Thunder,
            "有霾" to WidgetWeatherCondition.Fog,
            "有雨或雪" to WidgetWeatherCondition.Sleet,
            "雨夾雪" to WidgetWeatherCondition.Sleet,
            "積冰" to WidgetWeatherCondition.Unknown,
        )
        for ((weather, expected) in cases) {
            val point = ForecastPoint("15:00", 20.0, weather, 0, null)
            assertEquals(weather, expected, point.condition)
        }
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
