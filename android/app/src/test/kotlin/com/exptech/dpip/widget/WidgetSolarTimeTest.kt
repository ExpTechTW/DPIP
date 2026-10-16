package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneOffset

class WidgetSolarTimeTest {
    private val taipei = ZoneOffset.ofHours(8)

    // Taipei City, one of the coordinates the catalog actually publishes.
    private val latitude = 25.032188
    private val longitude = 121.5183226

    private fun at(hour: Int, minute: Int, month: Int, day: Int): Long =
        LocalDateTime.of(2026, month, day, hour, minute).toInstant(taipei).toEpochMilli()

    /** The transition API answers in **seconds**, the unit the contract stores. */
    private fun local(seconds: Long): LocalDateTime =
        LocalDateTime.ofInstant(Instant.ofEpochSecond(seconds), taipei)

    /** Seconds past local midnight, against a published almanac time. */
    private fun assertNear(actual: Int, expectedHour: Int, expectedMinute: Int, minutes: Int) {
        val expected = expectedHour * 3_600 + expectedMinute * 60
        val actualClock = "%02d:%02d".format(actual / 3_600, (actual % 3_600) / 60)
        assertTrue(
            "expected about %02d:%02d but was %s".format(expectedHour, expectedMinute, actualClock),
            Math.abs(actual - expected) <= minutes * 60,
        )
    }

    @Test
    fun `summer sunrise and sunset are plausible for Taipei`() {
        val times = WidgetSolarTime.sunSeconds(at(12, 0, 6, 21), latitude, longitude)
        assertNear(times.sunrise, 5, 1, 6)
        assertNear(times.sunset, 18, 48, 6)
        assertTrue(times.sunrise < times.sunset)
    }

    @Test
    fun `winter sunrise and sunset are plausible for Taipei`() {
        val times = WidgetSolarTime.sunSeconds(at(12, 0, 12, 21), latitude, longitude)
        assertNear(times.sunrise, 6, 34, 6)
        assertNear(times.sunset, 17, 9, 6)
    }

    @Test
    fun `the sun is up at midday and down at three and twenty-three`() {
        assertFalse(WidgetSolarTime.isNightAt(at(12, 0, 6, 21), latitude, longitude))
        assertTrue(WidgetSolarTime.isNightAt(at(3, 0, 6, 21), latitude, longitude))
        assertTrue(WidgetSolarTime.isNightAt(at(23, 0, 6, 21), latitude, longitude))
    }

    @Test
    fun `the transition is today's sunrise before dawn and today's sunset after it`() {
        val beforeDawn = local(WidgetSolarTime.nextDayNightTransitionSecondsAt(at(3, 0, 6, 21), latitude, longitude))
        val afterDawn = local(WidgetSolarTime.nextDayNightTransitionSecondsAt(at(12, 0, 6, 21), latitude, longitude))

        assertEquals(21, beforeDawn.dayOfMonth)
        assertEquals(5, beforeDawn.hour)
        assertEquals(21, afterDawn.dayOfMonth)
        assertEquals(18, afterDawn.hour)
    }

    @Test
    fun `the transition is whole seconds, not milliseconds`() {
        // The unit is the contract: `nextDayNightTransitionTime` is stored in
        // seconds on both platforms. A millisecond value here would be read back
        // as a date a thousand times too far away.
        val transition = WidgetSolarTime.nextDayNightTransitionSecondsAt(at(3, 0, 6, 21), latitude, longitude)
        assertTrue(
            "expected Unix seconds, got $transition",
            transition in 1_700_000_000L..2_200_000_000L,
        )
    }

    @Test
    fun `after sunset the next transition is tomorrow's sunrise`() {
        val transition = local(WidgetSolarTime.nextDayNightTransitionSecondsAt(at(23, 0, 6, 21), latitude, longitude))
        assertEquals(22, transition.dayOfMonth)
        assertEquals(5, transition.hour)
    }

    @Test
    fun `polar day has no night and no crossing`() {
        val times = WidgetSolarTime.sunSeconds(at(12, 0, 6, 21), 89.0, 0.0)
        assertEquals(0, times.sunrise)
        assertEquals(24 * 3_600, times.sunset)
        assertFalse(WidgetSolarTime.isNightAt(at(2, 0, 6, 21), 89.0, 0.0))
    }

    @Test
    fun `polar night is night all day`() {
        val times = WidgetSolarTime.sunSeconds(at(12, 0, 12, 21), 89.0, 0.0)
        assertEquals(times.sunrise, times.sunset)
        assertTrue(WidgetSolarTime.isNightAt(at(12, 0, 12, 21), 89.0, 0.0))
    }
}
