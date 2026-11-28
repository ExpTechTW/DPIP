package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The port of `rain_hour_trend.dart`, case for case with
 * `test/features/weather/domain/rain_hour_trend_test.dart`: the Widget and the
 * home sheet must read the same hour the same way.
 */
class WidgetRainTrendTest {
    private val now = 1_786_362_645_000L

    private fun rain60(vararg leading: Number): String =
        (0 until 60).joinToString(",", "[", "]") { (leading.getOrNull(it) ?: 0).toString() }

    private fun decode(json: String) = RainHourTrend.decode(WidgetJsonParser.parse(json)!!, now)

    private fun trend(vararg values: Double) =
        RainHourTrend(0, values.toList() + List(60 - values.size) { 0.0 })

    @Test
    fun `decode reads the first non-empty rainforecast series`() {
        val trend = decode(
            """{"rainfallWarnings-rkai":[{"start":1786362600,"rain":${rain60(6, 5, 4)}}],
               "rainfallWarnings-other":[{"start":1,"rain":[]}]}""",
        )!!
        assertEquals(1_786_362_600L, trend.startSecond)
        assertEquals(60, trend.mm.size)
        assertEquals(listOf(6.0, 5.0, 4.0), trend.mm.subList(0, 3))
        assertTrue(trend.mm.subList(3, 60).all { it == 0.0 })
    }

    @Test
    fun `an empty response and an all-empty series are a dry hour at the current minute`() {
        for (json in listOf("{}", """{"rainfallWarnings-rkai":[]}""")) {
            val trend = decode(json)!!
            assertTrue(json, trend.isDry)
            assertEquals(60, trend.mm.size)
            assertTrue(trend.mm.all { it == 0.0 })
            assertEquals(0L, trend.startSecond % 60)
            assertEquals(now / 1_000 / 60 * 60, trend.startSecond)
        }
    }

    @Test
    fun `decode skips empty series before the real one`() {
        val trend = decode("""{"empty":[],"real":[{"start":10,"rain":${rain60(1)}}]}""")!!
        assertEquals(10L, trend.startSecond)
    }

    @Test
    fun `a malformed series is a failure, never a dry hour`() {
        for (json in listOf(
            """{"s":[{"start":"x","rain":${rain60(1)}}]}""",
            """{"s":[{"start":1,"rain":[1,2]}]}""",
            """{"s":[42]}""",
            """{"s":[{"start":1,"rain":"none"}]}""",
            """{"s":[{"start":1,"rain":${rain60(1).replaceFirst("1", "\"1\"")}}]}""",
            "[]",
        )) {
            assertNull(json, decode(json))
        }
    }

    @Test
    fun `an all-dry hour is none`() {
        val summary = trend().summary
        assertEquals(RainHourTrendGrade.None, summary.grade)
        assertFalse(summary.sustained)
        assertNull(summary.stopInMinutes)
    }

    @Test
    fun `the grade is read from the peak`() {
        assertEquals(RainHourTrendGrade.Scattered, trend(0.0, 4.9, 0.0, 0.0, 0.0, 2.5).summary.grade)
        assertEquals(RainHourTrendGrade.Light, trend(5.0).summary.grade)
        assertEquals(RainHourTrendGrade.Light, trend(14.9).summary.grade)
        assertEquals(RainHourTrendGrade.Heavy, trend(15.0).summary.grade)
    }

    @Test
    fun `scattered showers never report a stop`() {
        val summary = trend(*DoubleArray(59) { 1.0 }).summary
        assertEquals(RainHourTrendGrade.Scattered, summary.grade)
        assertFalse(summary.sustained)
        assertNull(summary.stopInMinutes)
    }

    @Test
    fun `rain that stops mid-hour reports the minute after the last wet one`() {
        val summary = trend(*DoubleArray(21) { 6.0 }).summary
        assertEquals(RainHourTrendGrade.Light, summary.grade)
        assertFalse(summary.sustained)
        assertEquals(21, summary.stopInMinutes)
    }

    @Test
    fun `rain still falling from minute 45 on is sustained`() {
        val sustained = RainHourTrend(0, List(60) { if (it == 45) 20.0 else 0.0 }).summary
        assertEquals(RainHourTrendGrade.Heavy, sustained.grade)
        assertTrue(sustained.sustained)
        assertNull(sustained.stopInMinutes)

        val stopping = RainHourTrend(0, List(60) { if (it == 44) 20.0 else 0.0 }).summary
        assertFalse(stopping.sustained)
        assertEquals(45, stopping.stopInMinutes)
    }
}
