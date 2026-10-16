package com.exptech.dpip.widget

import android.location.Location
import android.os.SystemClock
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * The quality gate a fix has to pass before it may be called a position.
 *
 * The accuracy is kept rather than consumed, because the township resolver needs
 * it: a 400-metre fix ten metres inside a boundary is not in that township with
 * any confidence. What this pins is that the *metadata* survives, that a fix
 * with no accuracy is refused instead of assumed exact, and that every rejection
 * names a reason.
 */
@RunWith(RobolectricTestRunner::class)
class WidgetLocationFixTest {
    private fun location(
        latitude: Double = 24.181,
        longitude: Double = 120.645,
        accuracy: Float? = 50f,
        ageMilliseconds: Long = 1_000,
    ) = Location("test").apply {
        this.latitude = latitude
        this.longitude = longitude
        if (accuracy == null) removeAccuracy() else this.accuracy = accuracy
        // Age is read from the monotonic clock, never the wall clock.
        elapsedRealtimeNanos =
            SystemClock.elapsedRealtimeNanos() - ageMilliseconds * 1_000_000L
    }

    @Test
    fun `a fresh fix keeps its coordinate, accuracy and age`() {
        val fix = WidgetLocationFix.toFix(location(accuracy = 120f, ageMilliseconds = 30_000))!!
        assertEquals(24.181, fix.latitude, 1e-9)
        assertEquals(120.0, fix.accuracyMeters, 1e-9)
        assertTrue(fix.ageMilliseconds in 29_000..31_000)
    }

    @Test
    fun `a fix with no accuracy is unusable rather than assumed exact`() {
        assertNull(WidgetLocationFix.toFix(location(accuracy = null)))
        assertNull(WidgetLocationFix.toFix(location(accuracy = -1f)))
    }

    @Test
    fun `a fix too coarse to name a township is unusable`() {
        assertNotNull(WidgetLocationFix.toFix(location(accuracy = 500f)))
        assertNull(WidgetLocationFix.toFix(location(accuracy = 500.5f)))
        assertNull(WidgetLocationFix.toFix(location(accuracy = 5_000f)))
    }

    @Test
    fun `an old fix is unusable however accurate it was`() {
        // Just inside the five-minute window, then just outside it.
        assertNotNull(WidgetLocationFix.toFix(location(ageMilliseconds = 4 * 60 * 1_000L)))
        assertNull(WidgetLocationFix.toFix(location(ageMilliseconds = 6 * 60 * 1_000L)))
    }

    @Test
    fun `impossible coordinates are unusable`() {
        assertNull(WidgetLocationFix.toFix(location(latitude = 91.0)))
        assertNull(WidgetLocationFix.toFix(location(longitude = 181.0)))
        assertNull(WidgetLocationFix.toFix(location(latitude = Double.NaN)))
    }

    @Test
    fun `every way of failing names a degradation`() {
        // A timeout and a null fix are as much "no position" as a denied
        // permission, and the version this replaced recorded only the
        // permission cases — the rest degraded silently.
        assertEquals(
            WidgetLocationDegradation.Permission,
            WidgetLocationFixResult.NotAuthorized.degradation,
        )
        assertEquals(
            WidgetLocationDegradation.Disabled,
            WidgetLocationFixResult.Disabled.degradation,
        )
        assertEquals(
            WidgetLocationDegradation.UnusableFix,
            WidgetLocationFixResult.Unusable.degradation,
        )
        assertEquals(
            WidgetLocationDegradation.Unavailable,
            WidgetLocationFixResult.Failed.degradation,
        )
        assertNull(
            WidgetLocationFixResult.Acquired(
                WidgetFix(24.0, 120.0, 50.0, 1_000),
            ).degradation,
        )
    }
}
