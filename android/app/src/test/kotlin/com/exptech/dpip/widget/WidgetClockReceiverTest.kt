package com.exptech.dpip.widget

import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.WorkManagerTestInitHelper
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * What a device clock or timezone change does.
 *
 * The calibrated anchor is monotonic, so the change cannot move it — that is
 * `CalibratedClockTest`'s job. What this covers is the part that *is* affected:
 * the device-side offset a scheduled redraw is expressed in, and what is on
 * screen, both of which have to be redone when the clock the user just changed
 * is the one the schedule was measured against.
 */
@RunWith(RobolectricTestRunner::class)
class WidgetClockReceiverTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val receiver = WidgetClockReceiver()
    private lateinit var store: WidgetStore

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        store = WidgetStore.open(context)
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
        store.writeCatalog(
            listOf(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!),
            1L,
        )
    }

    @After
    fun tearDown() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        WidgetLog.resetForTest()
    }

    private fun states(name: String): List<WorkInfo.State> =
        WorkManager.getInstance(context).getWorkInfosForUniqueWork(name).get().map { it.state }

    @Test
    fun `a time change re-arms the local redraw`() {
        val log = RecordingLog()
        WidgetLog.overrideSink = { log }
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        receiver.onReceive(context, Intent(Intent.ACTION_TIME_CHANGED))

        // A zero delay means the test scheduler runs it immediately, so the
        // assertion is that it was armed at all, not that it is still queued.
        assertTrue(
            "the redraw should be re-armed: ${states(WidgetRefreshScheduler.localRerenderWorkName)}",
            states(WidgetRefreshScheduler.localRerenderWorkName).isNotEmpty(),
        )
        assertTrue(log.contains("clock changed action=android.intent.action.TIME_SET"))
    }

    @Test
    fun `a timezone change re-arms the local redraw`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        receiver.onReceive(context, Intent(Intent.ACTION_TIMEZONE_CHANGED))

        assertTrue(states(WidgetRefreshScheduler.localRerenderWorkName).isNotEmpty())
    }

    @Test
    fun `with no instances nothing is scheduled`() {
        receiver.onReceive(context, Intent(Intent.ACTION_TIME_CHANGED))

        assertTrue(states(WidgetRefreshScheduler.localRerenderWorkName).isEmpty())
    }

    @Test
    fun `an unrelated broadcast is ignored`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        receiver.onReceive(context, Intent(Intent.ACTION_SCREEN_ON))

        assertTrue(states(WidgetRefreshScheduler.localRerenderWorkName).isEmpty())
    }
}
