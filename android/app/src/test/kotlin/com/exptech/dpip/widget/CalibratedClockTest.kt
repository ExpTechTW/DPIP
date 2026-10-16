package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The property the whole freshness story rests on: a device clock change cannot
 * move calibrated time.
 *
 * The wall and monotonic sources are fake, so "the user changed the date" is one
 * line rather than a device setting.
 */
class CalibratedClockTest {
    private var wallMilliseconds = 1_000_000L
    private var monotonicMilliseconds = 50_000L

    private val clock = CalibratedClock(
        wallMilliseconds = { wallMilliseconds },
        monotonicMilliseconds = { monotonicMilliseconds },
    )

    @Test
    fun `an unanchored clock answers nothing rather than guessing`() {
        assertFalse(clock.hasAnchor)
        assertNull(clock.calibratedNowMilliseconds())
        assertNull(clock.offsetMilliseconds())
        assertNull(clock.snapshotTime())
        assertNull(clock.anchorAgeMilliseconds())
    }

    @Test
    fun `calibrated time advances with the monotonic clock only`() {
        // The server is five seconds ahead of the device right now.
        clock.install(serverUnixMilliseconds = wallMilliseconds + 5_000)
        val before = clock.calibratedNowMilliseconds()!!

        // The device clock jumps an hour forward, and a second of real time
        // passes.
        wallMilliseconds += 3_600_000
        monotonicMilliseconds += 1_000

        assertEquals(before + 1_000, clock.calibratedNowMilliseconds())
    }

    @Test
    fun `a device clock jump cannot make an old observation look fresh`() {
        // Anchored while the device clock is an hour *behind* the server.
        clock.install(serverUnixMilliseconds = wallMilliseconds + 3_600_000)
        val before = clock.calibratedNowMilliseconds()!!

        // The user corrects the device clock; calibrated time must not move
        // backwards, which is what would revive expired data.
        wallMilliseconds += 3_600_000

        assertEquals(before, clock.calibratedNowMilliseconds())
    }

    @Test
    fun `the offset is re-derived against the device clock on every read`() {
        clock.install(serverUnixMilliseconds = wallMilliseconds + 5_000)
        assertEquals(5_000L, clock.offsetMilliseconds())

        // The device clock falls an hour behind while the server keeps its pace:
        // the calibrated instant moves with monotonic time only, so the offset
        // grows by the hour. It is derived, never stored.
        wallMilliseconds -= 3_600_000
        monotonicMilliseconds += 60_000
        assertEquals(3_665_000L, clock.offsetMilliseconds())
    }

    @Test
    fun `snapshot time and its offset describe one evaluation`() {
        clock.install(serverUnixMilliseconds = wallMilliseconds + 5_000)
        monotonicMilliseconds += 250
        wallMilliseconds += 100

        val snapshot = clock.snapshotTime()!!
        assertEquals(1_005_250L, snapshot.calibratedNowUnixMilliseconds)
        assertEquals(
            snapshot.calibratedNowUnixMilliseconds - wallMilliseconds,
            snapshot.calibratedTimeOffsetMilliseconds,
        )
    }

    @Test
    fun `a calibrated deadline converts back to the device clock`() {
        clock.install(serverUnixMilliseconds = wallMilliseconds + 5_000)
        val deviceReading = clock.deviceMillisecondsFor(wallMilliseconds + 5_000 + 30_000)!!
        assertEquals(wallMilliseconds + 30_000, deviceReading)
    }

    @Test
    fun `anchoring twice replaces the anchor`() {
        clock.install(serverUnixMilliseconds = 1_000_000)
        monotonicMilliseconds += 10_000
        clock.install(serverUnixMilliseconds = 2_000_000)
        assertEquals(2_000_000L, clock.calibratedNowMilliseconds())
        assertEquals(0L, clock.anchorAgeMilliseconds())
    }

    @Test
    fun `invalidate drops the anchor`() {
        clock.install(serverUnixMilliseconds = 1_000_000)
        assertTrue(clock.hasAnchor)
        clock.invalidate()
        assertFalse(clock.hasAnchor)
        assertNull(clock.calibratedNowMilliseconds())
    }
}
