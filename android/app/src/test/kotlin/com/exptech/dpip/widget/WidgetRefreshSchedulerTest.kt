package com.exptech.dpip.widget

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.NetworkType
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.WorkManagerTestInitHelper
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * What the Widget enqueues, and what it stops enqueuing.
 *
 * Two failures are pinned here. The first is a **global** one-time work name:
 * with `KEEP`, adding a second Widget while the first source's refresh was
 * running dropped the new instance's request entirely, and the launcher kept
 * drawing its `initialLayout` until the next periodic run. The second is a
 * *cancellation* that was too narrow: removing the last Widget left the pending
 * local redraw behind, waking a worker to redraw nothing.
 */
@RunWith(RobolectricTestRunner::class)
class WidgetRefreshSchedulerTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val saved407 = WidgetAddress.Saved("407")
    private val saved100 = WidgetAddress.Saved("100")

    private lateinit var workManager: WorkManager

    @Before
    fun setUp() {
        WorkManagerTestInitHelper.initializeTestWorkManager(
            context,
            WidgetSchedulingOnlyWorkerFactory.configuration(),
        )
        workManager = WorkManager.getInstance(context)
    }

    @After
    fun tearDown() {
        workManager.cancelAllWork()
    }

    private fun infos(uniqueName: String): List<WorkInfo> =
        workManager.getWorkInfosForUniqueWork(uniqueName).get()

    private fun states(uniqueName: String): List<WorkInfo.State> =
        infos(uniqueName).map { it.state }

    @Test
    fun `recovery keeps pending manual work and feedback but a new demand still replaces it`() {
        WidgetRefreshScheduler.scheduleOneTime(context, saved407, manual = true)
        val manualId = infos(WidgetRefreshScheduler.sourceWorkName(saved407)).single().id
        repeat(3) { WidgetRefreshScheduler.scheduleRecovery(context, saved407) }
        assertEquals(manualId, infos(WidgetRefreshScheduler.sourceWorkName(saved407)).single().id)
        assertTrue(WidgetStore.open(context).writeRefreshFeedback(
            saved407, manualId.toString(), WidgetRefreshFeedback.Running, System.currentTimeMillis(),
        ))
        WidgetRefreshScheduler.scheduleOneTime(context, saved407)
        assertTrue(manualId != infos(WidgetRefreshScheduler.sourceWorkName(saved407)).single().id)
    }

    @Test
    fun `a one-time refresh is de-duplicated per source, not globally`() {
        WidgetRefreshScheduler.scheduleOneTime(context, saved407)
        WidgetRefreshScheduler.scheduleOneTime(context, saved407)
        assertEquals(1, infos(WidgetRefreshScheduler.sourceWorkName(saved407)).size)

        // A different source gets its own unique work, so a request that arrives
        // while another source is running is not dropped.
        WidgetRefreshScheduler.scheduleOneTime(context, saved100)
        assertEquals(1, infos(WidgetRefreshScheduler.sourceWorkName(saved100)).size)
        assertEquals(
            1,
            infos(WidgetRefreshScheduler.sourceWorkName(saved407)).size,
        )
        assertTrue(
            states(WidgetRefreshScheduler.sourceWorkName(saved100)).contains(WorkInfo.State.ENQUEUED),
        )
    }

    @Test
    fun `a refresh with no source is its own unique work`() {
        WidgetRefreshScheduler.scheduleOneTime(context, null)
        val work = infos(WidgetRefreshScheduler.allSourcesWorkName)
        assertEquals(1, work.size)
        assertTrue(work.first().tags.contains(WidgetRefreshScheduler.workTag))
    }

    @Test
    fun `one-time refreshes wait for the network and redraws do not`() {
        WidgetRefreshScheduler.scheduleOneTime(context, saved407)
        assertEquals(
            NetworkType.CONNECTED,
            infos(WidgetRefreshScheduler.sourceWorkName(saved407)).first().constraints.requiredNetworkType,
        )

        // A local redraw must not be blocked offline: the point of it is to turn
        // a cached screen stale while there is no network at all.
        WidgetRefreshScheduler.scheduleLocalRerender(context, 60_000)
        val redraw = infos(WidgetRefreshScheduler.localRerenderWorkName).first()
        assertEquals(NetworkType.NOT_REQUIRED, redraw.constraints.requiredNetworkType)
        assertTrue(redraw.tags.contains(WidgetRefreshScheduler.workTag))
    }

    @Test
    fun `the periodic refresh is not constrained to the network either`() {
        WidgetRefreshScheduler.schedulePeriodic(context)
        val work = infos(WidgetRefreshScheduler.periodicWorkName).first()
        assertEquals(NetworkType.NOT_REQUIRED, work.constraints.requiredNetworkType)
        assertTrue(work.state == WorkInfo.State.ENQUEUED)
    }

    @Test
    fun `scheduling the periodic work twice updates rather than duplicates it`() {
        WidgetRefreshScheduler.schedulePeriodic(context)
        WidgetRefreshScheduler.schedulePeriodic(context)
        assertEquals(1, infos(WidgetRefreshScheduler.periodicWorkName).size)
    }

    @Test
    fun `a local redraw replaces its own predecessor`() {
        WidgetRefreshScheduler.scheduleLocalRerender(context, 60_000)
        WidgetRefreshScheduler.scheduleLocalRerender(context, 120_000)
        assertEquals(1, infos(WidgetRefreshScheduler.localRerenderWorkName).size)
    }

    @Test
    fun `cancelling everything stops the periodic, one-time and redraw work`() {
        WidgetRefreshScheduler.schedulePeriodic(context)
        WidgetRefreshScheduler.scheduleOneTime(context, saved407)
        WidgetRefreshScheduler.scheduleOneTime(context, saved100)
        WidgetRefreshScheduler.scheduleOneTime(context, null)
        WidgetRefreshScheduler.scheduleLocalRerender(context, 60_000)

        WidgetRefreshScheduler.cancelAll(context)

        for (name in listOf(
            WidgetRefreshScheduler.periodicWorkName,
            WidgetRefreshScheduler.localRerenderWorkName,
            WidgetRefreshScheduler.allSourcesWorkName,
            WidgetRefreshScheduler.sourceWorkName(saved407),
            WidgetRefreshScheduler.sourceWorkName(saved100),
        )) {
            val workStates = states(name)
            assertTrue(
                "$name should be cancelled, was $workStates",
                workStates.isEmpty() || workStates.all { it == WorkInfo.State.CANCELLED },
            )
        }
    }

    @Test
    fun `cancelling widget work leaves another feature's work alone`() {
        // The background-location watchdog owns its own periodic work — the same
        // names and tags `BackgroundLocationWatchdog` uses — and the Widget must
        // only cancel what it queued itself. A `cancelAllWork()` would take this
        // with it; so would a tag shared with it.
        val watchdog = androidx.work.PeriodicWorkRequestBuilder<WeatherWidgetRefreshWorker>(
            30,
            java.util.concurrent.TimeUnit.MINUTES,
        ).addTag("background-location-watchdog").build()
        workManager.enqueueUniquePeriodicWork(
            "background-location-watchdog",
            androidx.work.ExistingPeriodicWorkPolicy.KEEP,
            watchdog,
        )

        WidgetRefreshScheduler.schedulePeriodic(context)
        WidgetRefreshScheduler.scheduleOneTime(context, saved407)
        WidgetRefreshScheduler.cancelAll(context)

        val watchdogStates = states("background-location-watchdog")
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
 * Scheduling assertions must not race an automatically started periodic worker
 * against their fixtures (or perform real HTTP). Worker tests execute production
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
