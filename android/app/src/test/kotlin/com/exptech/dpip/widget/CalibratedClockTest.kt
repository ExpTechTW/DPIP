package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong

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
    fun `reads during reinstall use a complete anchor without blocking`() {
        val monotonic = AtomicLong(0)
        val pauseNextReading = AtomicBoolean(false)
        val readingStarted = CountDownLatch(1)
        val resumeReading = CountDownLatch(1)
        val concurrentClock = CalibratedClock(
            wallMilliseconds = { 1_000_000L },
            monotonicMilliseconds = {
                if (pauseNextReading.compareAndSet(true, false)) {
                    readingStarted.countDown()
                    check(resumeReading.await(5, TimeUnit.SECONDS)) { "Monotonic read was not resumed" }
                }
                monotonic.get()
            },
        )
        concurrentClock.install(1_000_000L)
        monotonic.set(3_600_000L)
        val executor = Executors.newSingleThreadExecutor()
        pauseNextReading.set(true)
        val install = executor.submit { concurrentClock.install(4_600_000L) }
        try {
            assertTrue("Reinstall did not reach the monotonic read", readingStarted.await(5, TimeUnit.SECONDS))
            assertTrue(concurrentClock.hasAnchor)
            assertEquals(4_600_000L, concurrentClock.calibratedNowMilliseconds())
            assertEquals(3_600_000L, concurrentClock.anchorAgeMilliseconds())
            assertEquals(3_600_000L, concurrentClock.offsetMilliseconds())
            assertEquals(WidgetSnapshotTime(4_600_000L, 3_600_000L), concurrentClock.snapshotTime())
            assertEquals(1_030_000L, concurrentClock.deviceMillisecondsFor(4_630_000L))
        } finally {
            resumeReading.countDown()
            try {
                install.get(5, TimeUnit.SECONDS)
            } finally {
                executor.shutdownNow()
                assertTrue("Reinstall thread did not stop", executor.awaitTermination(5, TimeUnit.SECONDS))
            }
        }
        assertEquals(4_600_000L, concurrentClock.calibratedNowMilliseconds())
        assertEquals(0L, concurrentClock.anchorAgeMilliseconds())
    }

    @Test
    fun `invalidate during install leaves no anchor until a complete install is published`() {
        val pauseNextReading = AtomicBoolean(false)
        val readingStarted = CountDownLatch(1)
        val resumeReading = CountDownLatch(1)
        val concurrentClock = CalibratedClock(
            wallMilliseconds = { 1_000_000L },
            monotonicMilliseconds = {
                if (pauseNextReading.compareAndSet(true, false)) {
                    readingStarted.countDown()
                    check(resumeReading.await(5, TimeUnit.SECONDS)) { "Monotonic read was not resumed" }
                }
                3_600_000L
            },
        )
        concurrentClock.installAt(1_000_000L, 0L)
        val executor = Executors.newSingleThreadExecutor()
        pauseNextReading.set(true)
        val install = executor.submit { concurrentClock.install(4_600_000L) }
        try {
            assertTrue("Install did not reach the monotonic read", readingStarted.await(5, TimeUnit.SECONDS))
            concurrentClock.invalidate()
            assertFalse(concurrentClock.hasAnchor)
            assertNull(concurrentClock.anchorAgeMilliseconds())
            assertNull(concurrentClock.calibratedNowMilliseconds())
            assertNull(concurrentClock.offsetMilliseconds())
            assertNull(concurrentClock.snapshotTime())
            assertNull(concurrentClock.deviceMillisecondsFor(4_630_000L))
        } finally {
            resumeReading.countDown()
            try {
                install.get(5, TimeUnit.SECONDS)
            } finally {
                executor.shutdownNow()
                assertTrue("Install thread did not stop", executor.awaitTermination(5, TimeUnit.SECONDS))
            }
        }
        // The overlapping install may complete after invalidate, but it must
        // publish both readings, never just the monotonic half of an anchor.
        assertTrue(concurrentClock.hasAnchor)
        assertEquals(0L, concurrentClock.anchorAgeMilliseconds())
        assertEquals(WidgetSnapshotTime(4_600_000L, 3_600_000L), concurrentClock.snapshotTime())
        concurrentClock.invalidate()
        assertFalse(concurrentClock.hasAnchor)
        assertNull(concurrentClock.snapshotTime())
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
