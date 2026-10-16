package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.WorkManagerTestInitHelper
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * The provider's lifecycle: restore, delete, and the "update now" tap.
 *
 * The restore path is the one with a failure that leaves no trace — a row copied
 * to the new id without deleting the old one keeps its source "in use" forever,
 * so the Widget keeps fetching for a home-screen instance that no longer exists.
 */
@RunWith(RobolectricTestRunner::class)
class WeatherWidgetProviderTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private lateinit var store: WidgetStore
    private val provider = WeatherWidgetProvider()

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        store = WidgetStore.open(context)
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
        store.writeCatalog(
            listOf(
                WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!,
                WidgetCatalogLocation.create("100", "中正區", "臺北市", 25.032, 121.518)!!,
            ),
            1L,
        )
    }

    @After
    fun tearDown() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
    }

    private fun manager(): AppWidgetManager = AppWidgetManager.getInstance(context)

    private fun states(name: String): List<WorkInfo.State> =
        WorkManager.getInstance(context).getWorkInfosForUniqueWork(name).get().map { it.state }

    @Test
    fun `the refresh tap records feedback for its exact queued work and source`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)
        provider.onReceive(context, Intent(WidgetRenderer.ACTION_REFRESH).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, 11)
        })
        assertEquals(WidgetRefreshFeedback.Queued, store.readRefreshFeedback(address, System.currentTimeMillis())?.state)
        assertNull(store.readRefreshFeedback(WidgetAddress.Saved("100"), System.currentTimeMillis()))
        val work = WorkManager.getInstance(context)
            .getWorkInfosForUniqueWork(WidgetRefreshScheduler.sourceWorkName(address)).get().single()
        assertTrue(store.writeRefreshFeedback(address, work.id.toString(), WidgetRefreshFeedback.Running, System.currentTimeMillis()))
    }

    @Test
    fun `a restore moves each choice and leaves no ghost`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)

        provider.onRestored(context, intArrayOf(11, 12), intArrayOf(21, 22))

        assertNull("the old row must be gone", store.readInstance(11))
        assertNull(store.readInstance(12))
        assertEquals(WidgetAddress.Saved("407"), store.readInstance(21)!!.address)
        assertEquals(WidgetAddress.Saved("100"), store.readInstance(22)!!.address)
        assertEquals(2, store.usedAddresses().size)
    }

    @Test
    fun `a restore that hands back fewer ids drops the rest`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)

        // The launcher restored only the first widget.
        provider.onRestored(context, intArrayOf(11, 12), intArrayOf(21))

        assertEquals(WidgetAddress.Saved("407"), store.readInstance(21)!!.address)
        assertNull(store.readInstance(12))
        // The dropped widget's source is no longer in use.
        assertEquals(listOf(WidgetAddress.Saved("407")), store.usedAddresses())
    }

    @Test
    fun `a restore drops rows the launcher does not report at all`() {
        // An id that is neither live nor handed back: a ghost from a force-stop.
        store.writeInstance(99, WidgetAddress.Saved("100"), "100", 1L)

        provider.onRestored(context, intArrayOf(), intArrayOf())

        assertNull(store.readInstance(99))
    }

    @Test
    fun `deleting the last instance cancels every kind of work`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        WidgetRefreshScheduler.schedulePeriodic(context)
        WidgetRefreshScheduler.scheduleOneTime(context, WidgetAddress.Saved("407"))
        WidgetRefreshScheduler.scheduleLocalRerender(context, 60_000)

        provider.onDeleted(context, intArrayOf(11))

        assertNull(store.readInstance(11))
        assertTrue(
            "the periodic work should be cancelled: ${states(WidgetRefreshScheduler.periodicWorkName)}",
            states(WidgetRefreshScheduler.periodicWorkName).none { it == WorkInfo.State.ENQUEUED },
        )
        assertTrue(
            "the local redraw should be cancelled: " +
                "${states(WidgetRefreshScheduler.localRerenderWorkName)}",
            states(WidgetRefreshScheduler.localRerenderWorkName)
                .none { it == WorkInfo.State.ENQUEUED },
        )
        assertTrue(
            "the one-time work should be cancelled: " +
                "${states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))}",
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
                .none { it == WorkInfo.State.ENQUEUED },
        )
    }

    @Test
    fun `deleting one of two instances leaves the other's work running`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)
        WidgetRefreshScheduler.schedulePeriodic(context)

        provider.onDeleted(context, intArrayOf(11))

        assertNotNull(store.readInstance(12))
        assertTrue(states(WidgetRefreshScheduler.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
    }

    @Test
    fun `deleting the last instance of one source cancels only that source`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)
        WidgetRefreshScheduler.scheduleOneTime(context, WidgetAddress.Saved("407"))
        WidgetRefreshScheduler.scheduleOneTime(context, WidgetAddress.Saved("100"))

        provider.onDeleted(context, intArrayOf(11))

        assertTrue(
            "the removed source's request must be cancelled: " +
                "${states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))}",
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
                .none { it == WorkInfo.State.ENQUEUED },
        )
        assertTrue(
            "the surviving source must keep its request",
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("100")))
                .contains(WorkInfo.State.ENQUEUED),
        )
    }

    @Test
    fun `an update with no instances schedules nothing`() {
        provider.onUpdate(context, manager(), intArrayOf())

        assertEquals(0, states(WidgetRefreshScheduler.periodicWorkName).size)
    }

    @Test
    fun `an update with an instance renders it and asks for its source`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        provider.onUpdate(context, manager(), intArrayOf(11))

        assertTrue(states(WidgetRefreshScheduler.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
        assertTrue(
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
                .contains(WorkInfo.State.ENQUEUED),
        )
    }

    @Test
    fun `the update-now tap enqueues only its own instance's source`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        provider.onReceive(
            context,
            Intent(context, WeatherWidgetProvider::class.java).apply {
                action = WidgetRenderer.ACTION_REFRESH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, 11)
            },
        )

        assertTrue(
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
                .contains(WorkInfo.State.ENQUEUED),
        )
        assertEquals(0, states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("100"))).size)
    }

    @Test
    fun `the update-now tap for an unknown instance does nothing`() {
        provider.onReceive(
            context,
            Intent(context, WeatherWidgetProvider::class.java).apply {
                action = WidgetRenderer.ACTION_REFRESH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, 99)
            },
        )

        assertEquals(0, states(WidgetRefreshScheduler.allSourcesWorkName).size)
    }

    @Test
    fun `enabling schedules the periodic refresh and disabling cancels it`() {
        provider.onEnabled(context)
        assertTrue(states(WidgetRefreshScheduler.periodicWorkName).contains(WorkInfo.State.ENQUEUED))

        provider.onDisabled(context)
        assertTrue(
            states(WidgetRefreshScheduler.periodicWorkName).none { it == WorkInfo.State.ENQUEUED },
        )
    }
}
