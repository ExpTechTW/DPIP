package com.exptech.dpip.widget

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.NetworkType
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

/**
 * What the Widget enqueues, and what it stops enqueuing.
 *
 * The refresh chain is the contract here: every trigger appends to one unique
 * chain, so nothing a later trigger does can cancel a refresh an earlier one
 * asked for — the gap through which an app push used to swallow a manual
 * refresh's feedback — and a cancellation takes everything the Widget queued
 * and nothing another feature did.
 */
@RunWith(RobolectricTestRunner::class)
class WidgetRefreshTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val saved407 = WidgetAddress.Saved("407")
    private val saved100 = WidgetAddress.Saved("100")

    private lateinit var workManager: WorkManager

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        WorkManagerTestInitHelper.initializeTestWorkManager(
            context,
            WidgetSchedulingOnlyWorkerFactory.configuration(),
        )
        workManager = WorkManager.getInstance(context)
    }

    @After
    fun tearDown() {
        workManager.cancelAllWork()
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
    }

    private fun infos(uniqueName: String): List<WorkInfo> =
        workManager.getWorkInfosForUniqueWork(uniqueName).get()

    private fun pending(uniqueName: String): List<WorkInfo> =
        infos(uniqueName).filter { it.state == WorkInfo.State.ENQUEUED || it.state == WorkInfo.State.BLOCKED }

    @Test
    fun `every request appends to the one chain instead of replacing what is queued`() {
        WidgetRefresh.request(context, WidgetRefresh.Reason.Tap, saved407, manual = true)
        val manual = infos(WidgetRefresh.refreshWorkName).single()
        WidgetRefresh.request(context, WidgetRefresh.Reason.AppPublish, saved407)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update, saved100)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Periodic)

        val chain = infos(WidgetRefresh.refreshWorkName)
        assertEquals(4, chain.size)
        assertTrue("an app push must not cancel the tap", chain.none { it.state == WorkInfo.State.CANCELLED })
        assertEquals(WorkInfo.State.ENQUEUED, chain.single { it.id == manual.id }.state)
        assertEquals(3, chain.count { it.state == WorkInfo.State.BLOCKED })
        assertTrue(chain.all { it.tags.contains(WidgetRefresh.workTag) })
    }

    @Test
    fun `a manual request records queued feedback for its exact work and source`() {
        WidgetRefresh.request(context, WidgetRefresh.Reason.Tap, saved407, manual = true)
        val work = infos(WidgetRefresh.refreshWorkName).single()
        val store = WidgetStore.open(context)
        assertEquals(WidgetRefreshFeedback.Queued, store.readRefreshFeedback(saved407, System.currentTimeMillis())?.state)
        assertNull(store.readRefreshFeedback(saved100, System.currentTimeMillis()))
        assertTrue(store.writeRefreshFeedback(saved407, work.id.toString(), WidgetRefreshFeedback.Running, System.currentTimeMillis()))
    }

    @Test
    fun `refreshes wait for the network and redraws do not`() {
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update, saved407)
        assertEquals(
            NetworkType.CONNECTED,
            infos(WidgetRefresh.refreshWorkName).single().constraints.requiredNetworkType,
        )

        // A local redraw must not be blocked offline: the point of it is to turn
        // a cached screen stale while there is no network at all.
        WidgetRefresh.scheduleLocalRerender(context, 60_000)
        val redraw = infos(WidgetRefresh.localRerenderWorkName).single()
        assertEquals(NetworkType.NOT_REQUIRED, redraw.constraints.requiredNetworkType)
        assertTrue(redraw.tags.contains(WidgetRefresh.workTag))
    }

    @Test
    fun `the periodic tick is not constrained to the network either`() {
        WidgetRefresh.schedulePeriodic(context)
        val work = infos(WidgetRefresh.periodicWorkName).single()
        assertEquals(NetworkType.NOT_REQUIRED, work.constraints.requiredNetworkType)
        assertEquals(WorkInfo.State.ENQUEUED, work.state)
    }

    @Test
    fun `scheduling the periodic tick twice updates rather than restarts it`() {
        WidgetRefresh.schedulePeriodic(context)
        val first = infos(WidgetRefresh.periodicWorkName).single().id
        WidgetRefresh.schedulePeriodic(context)
        assertEquals(first, infos(WidgetRefresh.periodicWorkName).single().id)
    }

    @Test
    fun `a local redraw replaces its own predecessor`() {
        WidgetRefresh.scheduleLocalRerender(context, 60_000)
        WidgetRefresh.scheduleLocalRerender(context, 120_000)
        assertEquals(1, pending(WidgetRefresh.localRerenderWorkName).size)
    }

    @Test
    fun `cancelling everything stops the periodic, refresh and redraw work`() {
        WidgetRefresh.schedulePeriodic(context)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update, saved407)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update)
        WidgetRefresh.scheduleLocalRerender(context, 60_000)

        WidgetRefresh.cancelAll(context)

        for (name in listOf(
            WidgetRefresh.periodicWorkName,
            WidgetRefresh.localRerenderWorkName,
            WidgetRefresh.refreshWorkName,
        )) {
            assertTrue("$name should be cancelled, was ${infos(name)}", pending(name).isEmpty())
        }

        // A request after the cancellation starts a fresh chain instead of
        // being appended to a cancelled one.
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update)
        assertEquals(1, pending(WidgetRefresh.refreshWorkName).size)
    }

    @Test
    fun `cancelling widget work leaves another feature's work alone`() {
        // The background-location watchdog owns its own periodic work, and the
        // Widget must only cancel what it queued itself. `cancelAllWork()` would
        // take this with it; so would a tag shared with it.
        val watchdog = androidx.work.PeriodicWorkRequestBuilder<WeatherWidgetRefreshWorker>(
            30,
            java.util.concurrent.TimeUnit.MINUTES,
        ).addTag("background-location-watchdog").build()
        workManager.enqueueUniquePeriodicWork(
            "background-location-watchdog",
            androidx.work.ExistingPeriodicWorkPolicy.KEEP,
            watchdog,
        )

        WidgetRefresh.schedulePeriodic(context)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update, saved407)
        WidgetRefresh.cancelAll(context)

        val watchdogStates = infos("background-location-watchdog").map { it.state }
        // Non-empty first: `all { … }` over an empty list passes for the wrong
        // reason, which is how a vacuous test looks green.
        assertTrue("the watchdog work must exist to be checked", watchdogStates.isNotEmpty())
        assertTrue(
            "another feature's work was cancelled: $watchdogStates",
            watchdogStates.all { it != WorkInfo.State.CANCELLED },
        )
    }
}

/**
 * Scheduling assertions must not race an automatically started worker against
 * their fixtures (or perform real HTTP). Worker tests execute production
 * workers explicitly through TestListenableWorkerBuilder instead.
 */
internal object WidgetSchedulingOnlyWorkerFactory : androidx.work.WorkerFactory() {
    fun configuration(): androidx.work.Configuration = androidx.work.Configuration.Builder()
        .setExecutor(androidx.work.testing.SynchronousExecutor())
        .setWorkerFactory(this)
        .build()

    override fun createWorker(
        appContext: Context,
        workerClassName: String,
        workerParameters: androidx.work.WorkerParameters,
    ): androidx.work.ListenableWorker? {
        if (workerClassName != WeatherWidgetRefreshWorker::class.java.name) return null
        return object : androidx.work.Worker(appContext, workerParameters) {
            override fun doWork(): Result = Result.success()
        }
    }
}
