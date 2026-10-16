package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetSnapshotDecoderTest {
    private fun fixture(name: String): String =
        checkNotNull(javaClass.getResourceAsStream("/$name")) { "missing fixture $name" }
            .use { it.readBytes().toString(Charsets.UTF_8) }

    @Test
    fun `decodes the real Dart current-weather payload`() {
        val snapshot = WidgetSnapshotDecoder.decodeCurrentWeather(fixture("current_weather_v7.json"))
        checkNotNull(snapshot)
        assertEquals(7, snapshot.schemaVersion)
        assertEquals("region:407", snapshot.sourceIdentifier)
        assertEquals(WidgetAddress.Saved("407"), snapshot.address)
        assertEquals("407", snapshot.regionCode)
        assertEquals("西屯區", snapshot.regionName)
        assertEquals(1791454316L, snapshot.observationTime)
        assertEquals("西屯", snapshot.stationName)
        assertEquals(206, snapshot.weatherCode)
        assertEquals(WeatherCondition.Rain, snapshot.condition)
        assertEquals(false, snapshot.isNight)
        assertEquals(1791470400L, snapshot.nextDayNightTransitionTime)
        assertEquals(-1200L, snapshot.calibratedTimeOffsetMilliseconds)
        assertEquals(27.5, snapshot.temperature!!, 1e-9)
        assertEquals(78, snapshot.humidity!!.toLong())
        assertEquals(0.0, snapshot.rain!!, 1e-9)
        assertEquals("北北西", snapshot.windDirection)
        assertEquals(1.3, snapshot.windSpeed!!, 1e-9)
        assertEquals(30.2, snapshot.apparentTemperature!!, 1e-9)
    }

    @Test
    fun `missing optional values decode as null, not as zero`() {
        val snapshot = WidgetSnapshotDecoder.decodeCurrentWeather(fixture("current_weather_v7_minimal.json"))
        checkNotNull(snapshot)
        assertNull(snapshot.temperature)
        assertNull(snapshot.humidity)
        assertNull(snapshot.rain)
        assertNull(snapshot.windDirection)
        assertNull(snapshot.windSpeed)
        assertNull(snapshot.apparentTemperature)
        assertEquals(WeatherCondition.Clear, snapshot.condition)
        assertEquals(true, snapshot.isNight)
    }

    @Test
    fun `rejects a schema this build does not know`() {
        for (version in listOf(6, 8, 0, -1)) {
            val payload = fixture("current_weather_v7.json").replace("\"schemaVersion\":7", "\"schemaVersion\":$version")
            assertNull("schemaVersion $version", WidgetSnapshotDecoder.decodeCurrentWeather(payload))
        }
    }

    @Test
    fun `rejects a source that does not agree with its region`() {
        val payload = fixture("current_weather_v7.json")
            .replace("\"sourceIdentifier\":\"region:407\"", "\"sourceIdentifier\":\"region:100\"")
        assertNull(WidgetSnapshotDecoder.decodeCurrentWeather(payload))
    }

    @Test
    fun `rejects an illegal source identifier`() {
        for (source in listOf("", "current", "region:40", "region:4077", "chosen")) {
            val payload = fixture("current_weather_v7.json")
                .replace("\"sourceIdentifier\":\"region:407\"", "\"sourceIdentifier\":\"$source\"")
            assertNull("source '$source'", WidgetSnapshotDecoder.decodeCurrentWeather(payload))
        }
    }

    @Test
    fun `rejects an observation time that is not a positive instant`() {
        val payload = fixture("current_weather_v7.json")
            .replace("\"observationTime\":1791454316", "\"observationTime\":0")
        assertNull(WidgetSnapshotDecoder.decodeCurrentWeather(payload))
    }

    @Test
    fun `rejects a payload without the fields the layout needs`() {
        for (field in listOf("regionName", "stationName", "weather", "weatherCode", "isNight", "nextDayNightTransitionTime")) {
            val payload = fixture("current_weather_v7.json")
                .replace("\"$field\":", "\"$field-removed\":")
            assertNull("missing $field", WidgetSnapshotDecoder.decodeCurrentWeather(payload))
        }
    }

    @Test
    fun `an unknown condition wire degrades to unknown rather than rejecting the payload`() {
        val payload = fixture("current_weather_v7.json").replace("\"condition\":\"rain\"", "\"condition\":\"hailstorm\"")
        assertEquals(WeatherCondition.Unknown, WidgetSnapshotDecoder.decodeCurrentWeather(payload)!!.condition)
    }

    @Test
    fun `an added field does not break the decoder`() {
        val payload = fixture("current_weather_v7.json")
            .replaceFirst("{", "{\"somethingNew\":{\"nested\":[1,2,3]},")
        assertTrue(WidgetSnapshotDecoder.decodeCurrentWeather(payload) != null)
    }

    @Test
    fun `rejects a non-finite number rather than drawing it`() {
        val payload = fixture("current_weather_v7.json").replace("\"temperature\":27.5", "\"temperature\":NaN")
        assertNull(WidgetSnapshotDecoder.decodeCurrentWeather(payload))
    }

    @Test
    fun `rejects a payload past the size ceiling before parsing it`() {
        val padding = "x".repeat(WidgetSnapshotDecoder.maximumPayloadBytes)
        val payload = fixture("current_weather_v7.json").replaceFirst("{", "{\"padding\":\"$padding\",")
        assertNull(WidgetSnapshotDecoder.decodeCurrentWeather(payload))
    }

    @Test
    fun `decodes the location catalog and refuses a duplicate code`() {
        val catalog = WidgetSnapshotDecoder.decodeLocationCatalog(fixture("location_catalog_v1.json"))
        checkNotNull(catalog)
        assertEquals(2, catalog.size)
        assertEquals("西屯區", catalog[0].displayName)
        assertEquals(24.181, catalog[0].latitude, 1e-9)

        val duplicated = fixture("location_catalog_v1.json")
            .replace("\"regionCode\":\"100\"", "\"regionCode\":\"407\"")
        assertNull(WidgetSnapshotDecoder.decodeLocationCatalog(duplicated))
    }

    @Test
    fun `an empty catalog is a valid catalog`() {
        assertEquals(
            0,
            WidgetSnapshotDecoder.decodeLocationCatalog("""{"schemaVersion":1,"locations":[]}""")!!.size,
        )
    }

    @Test
    fun `decodes a forecast snapshot and rejects a mismatched saved address`() {
        val forecast = WidgetSnapshotDecoder.decodeForecast(fixture("forecast_v1.json"))
        checkNotNull(forecast)
        assertEquals("current-location", forecast.sourceIdentifier)
        assertEquals(2, forecast.points.size)
        assertEquals(60, forecast.points[0].pop!!.toLong())

        // A saved town's forecast must name that town. A Current Location
        // forecast legitimately names whichever town the fix resolved, so only
        // the saved case can be checked here; the read-time region check covers
        // the other.
        val saved = fixture("forecast_v1.json").replace("current-location", "region:407")
        assertTrue(WidgetSnapshotDecoder.decodeForecast(saved) != null)
        val mismatched = saved.replace("\"regionCode\":\"407\"", "\"regionCode\":\"100\"")
        assertNull(WidgetSnapshotDecoder.decodeForecast(mismatched))
    }

    @Test
    fun `drops the forecast points that are not usable`() {
        val root = WidgetJsonParser.parse(fixture("forecast_remote_v5.json"))!!.objOrNull()!!
        val points = root["forecast"]!!.arrOrNull()!!.values
            .mapNotNull { WidgetSnapshotDecoder.decodeForecastPoint(it) }

        // "bad" has no usable clock label and is dropped; pop -99 and 150 are
        // both out of range and become null rather than a percentage.
        assertEquals(3, points.size)
        assertEquals(60, points[0].pop!!.toLong())
        assertNull(points[1].pop)
        assertNull(points[2].pop)
    }
}
