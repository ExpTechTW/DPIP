package com.exptech.dpip.widget

import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.WorkManagerTestInitHelper
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

/**
 * What a reboot, an app update or a device clock change does.
 *
 * The calibrated anchor is monotonic, so a clock change cannot move it — that is
 * `CalibratedClockTest`'s job. What this covers is the part that *is*
 * affected: what is on screen and the device-side offset a scheduled redraw is
 * expressed in, and, after a reboot, which instances still exist.
 */
@RunWith(RobolectricTestRunner::class)
class WidgetSystemReceiverTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val receiver = WidgetSystemReceiver()
    private lateinit var store: WidgetStore

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        store = WidgetStore.open(context)
        WorkManagerTestInitHelper.initializeTestWorkManager(
            context,
            WidgetSchedulingOnlyWorkerFactory.configuration(),
        )
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

    private fun bind(id: Int) {
        shadowOf(android.appwidget.AppWidgetManager.getInstance(context)).addBoundWidget(
            id,
            android.appwidget.AppWidgetProviderInfo().apply {
                provider = android.content.ComponentName(context, WeatherWidgetProvider::class.java)
            },
        )
    }

    @Test
    fun `a time change re-arms the local redraw`() {
        val log = RecordingLog()
        WidgetLog.overrideSink = { log }
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        receiver.onReceive(context, Intent(Intent.ACTION_TIME_CHANGED))

        // A zero delay means the test scheduler runs it immediately, so the
        // assertion is that it was armed at all, not that it is still queued.
        assertTrue(
            "the redraw should be re-armed: ${states(WidgetRefresh.localRerenderWorkName)}",
            states(WidgetRefresh.localRerenderWorkName).isNotEmpty(),
        )
        assertTrue(log.contains("clock changed action=android.intent.action.TIME_SET"))
        assertTrue("a clock change fetches nothing", states(WidgetRefresh.refreshWorkName).isEmpty())
    }

    @Test
    fun `a timezone change re-arms the local redraw`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        receiver.onReceive(context, Intent(Intent.ACTION_TIMEZONE_CHANGED))

        assertTrue(states(WidgetRefresh.localRerenderWorkName).isNotEmpty())
    }

    @Test
    fun `with no instances a clock change schedules nothing`() {
        receiver.onReceive(context, Intent(Intent.ACTION_TIME_CHANGED))

        assertTrue(states(WidgetRefresh.localRerenderWorkName).isEmpty())
    }

    @Test
    fun `a reboot drops ghosts and asks once for the instances that remain`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.CurrentLocation, null, 1L)
        store.writeInstance(99, WidgetAddress.Saved("100"), "100", 1L)
        bind(11)
        bind(12)

        receiver.onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))

        assertNull("an instance the launcher no longer has is dropped", store.readInstance(99))
        assertEquals(listOf(WorkInfo.State.ENQUEUED), states(WidgetRefresh.refreshWorkName))
        assertEquals(listOf(WorkInfo.State.ENQUEUED), states(WidgetRefresh.periodicWorkName))
    }

    @Test
    fun `an app update with nothing on the home screen cancels the widget's work`() {
        WidgetRefresh.schedulePeriodic(context)
        store.writeInstance(99, WidgetAddress.Saved("407"), "407", 1L)

        receiver.onReceive(context, Intent(Intent.ACTION_MY_PACKAGE_REPLACED))

        assertTrue(store.readInstances().isEmpty())
        assertTrue(states(WidgetRefresh.periodicWorkName).none { it == WorkInfo.State.ENQUEUED })
        assertTrue(states(WidgetRefresh.refreshWorkName).isEmpty())
    }

    @Test
    fun `an unrelated broadcast is ignored`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        receiver.onReceive(context, Intent(Intent.ACTION_SCREEN_ON))

        assertTrue(states(WidgetRefresh.localRerenderWorkName).isEmpty())
        assertTrue(states(WidgetRefresh.refreshWorkName).isEmpty())
    }
}
