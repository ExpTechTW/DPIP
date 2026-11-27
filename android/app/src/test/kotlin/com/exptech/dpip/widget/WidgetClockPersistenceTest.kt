package com.exptech.dpip.widget

import android.content.Context
import android.provider.Settings
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * The calibrated anchor across process death.
 *
 * The defect this pins: the anchor lived only in memory, so every process the
 * system started for the Widget — a delayed redraw, a clock-change broadcast,
 * the app's own catalog publish — drew a fresh observation as outdated and hid
 * the forecast until a network refresh happened to synchronize, and the user
 * had to tap the Widget to get its data back.
 */
@RunWith(RobolectricTestRunner::class)
class WidgetClockPersistenceTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()

    @Before
    fun setUp() {
        Settings.Global.putInt(context.contentResolver, Settings.Global.BOOT_COUNT, 7)
        WidgetClock.attach(context)
        WidgetClock.invalidate()
    }

    @After
    fun tearDown() {
        WidgetClock.invalidate()
    }

    private fun store(boot: Int?) = ClockAnchorStore(
        context.getSharedPreferences("anchor-test", Context.MODE_PRIVATE),
        bootCount = { boot },
    )

    @Test
    fun `a new process restores the anchor the last one synchronized`() {
        val now = 1_791_454_400_000L
        WidgetClock.installForTest(now, android.os.SystemClock.elapsedRealtime(), persist = true)

        WidgetClock.forgetForTest()
        assertNull("process death drops the in-memory anchor", WidgetClock.calibratedNowMilliseconds())

        WidgetClock.attach(context)
        assertEquals(now, WidgetClock.calibratedNowMilliseconds())
    }

    @Test
    fun `an anchor from another boot is not restored`() {
        WidgetClock.installForTest(1_791_454_400_000L, android.os.SystemClock.elapsedRealtime(), persist = true)
        WidgetClock.forgetForTest()
        Settings.Global.putInt(context.contentResolver, Settings.Global.BOOT_COUNT, 8)

        WidgetClock.attach(context)

        assertNull(WidgetClock.calibratedNowMilliseconds())
    }

    @Test
    fun `an anchor older than a day or from an earlier elapsed clock is not restored`() {
        val day = ClockAnchorStore.maximumAgeMilliseconds
        val store = store(boot = 3)
        store.write(ClockAnchor(serverMilliseconds = 1_791_454_400_000L, monotonicMilliseconds = 10_000L))

        assertNotNull(store.read(monotonicNowMilliseconds = 10_000L + day))
        assertNull("older than a day", store.read(monotonicNowMilliseconds = 10_001L + day))
        assertNull("the elapsed clock restarted", store.read(monotonicNowMilliseconds = 9_999L))
    }

    @Test
    fun `a device that cannot name its boot keeps nothing`() {
        val unknown = store(boot = null)
        unknown.write(ClockAnchor(1_791_454_400_000L, 10_000L))
        assertNull(unknown.read(10_000L))
        assertNull("nothing was written under a known boot either", store(boot = 3).read(10_000L))
    }

    @Test
    fun `invalidating drops the persisted anchor too`() {
        WidgetClock.installForTest(1_791_454_400_000L, android.os.SystemClock.elapsedRealtime(), persist = true)
        WidgetClock.invalidate()
        WidgetClock.forgetForTest()

        WidgetClock.attach(context)

        assertFalse(WidgetClock.hasSynchronized)
    }

    @Test
    fun `an in-memory anchor is never replaced by an older persisted one`() {
        val persisted = 1_791_454_400_000L
        WidgetClock.installForTest(persisted, android.os.SystemClock.elapsedRealtime(), persist = true)
        WidgetClock.installForTest(persisted + 5_000, android.os.SystemClock.elapsedRealtime())

        WidgetClock.attach(context)

        assertTrue(WidgetClock.calibratedNowMilliseconds()!! >= persisted + 5_000)
    }
}
