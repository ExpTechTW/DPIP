package com.exptech.dpip.widget

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.test.core.app.ApplicationProvider
import androidx.work.ListenableWorker
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.workDataOf
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.concurrent.TimeUnit

/**
 * The worker itself, in its three modes: which addresses a refresh link
 * touches, what the periodic tick asks for, and how far ahead a redraw is
 * asked for.
 *
 * The redraw delay is asserted through the log line rather than by inspecting
 * WorkManager, which does not expose an enqueued work's initial delay — and the
 * delay is the thing that was wrong (clamped to sixty seconds, so every boundary
 * became a redraw a minute later).
 */
@RunWith(RobolectricTestRunner::class)
class WeatherWidgetRefreshWorkerTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private lateinit var store: WidgetStore
    private lateinit var log: RecordingLog
    private lateinit var workManager: WorkManager

    private lateinit var refresherCalls: MutableList<String>

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        // The worker reaches the store through the process singleton, so a stale
        // one would keep a connection to the previous test's deleted file.
        WidgetStore.resetForTest()
        store = WidgetStore.open(context)
        log = RecordingLog()
        WidgetLog.overrideSink = { log }
        androidx.work.testing.WorkManagerTestInitHelper.initializeTestWorkManager(
            context,
            WidgetSchedulingOnlyWorkerFactory.configuration(),
        )
        workManager = WorkManager.getInstance(context)
        refresherCalls = ArrayList()
        WeatherWidgetRefreshWorker.refresher = { _, address ->
            refresherCalls.add(address.sourceIdentifier)
            WidgetRefreshResult.Refreshed
        }
    }

    @After
    fun tearDown() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        WidgetUpdater.resetOptionsProvider()
        WidgetClock.invalidate()
        WidgetLog.resetForTest()
        WeatherWidgetRefreshWorker.resetRefresher()
    }

    private fun worker(
        mode: String = WeatherWidgetRefreshWorker.MODE_REFRESH,
        source: String? = null,
        manual: Boolean = false,
        attempt: Int = 0,
    ) = TestListenableWorkerBuilder<WeatherWidgetRefreshWorker>(context)
        .setRunAttemptCount(attempt)
        .setInputData(
            workDataOf(
                WeatherWidgetRefreshWorker.KEY_MODE to mode,
                WeatherWidgetRefreshWorker.KEY_SOURCE to source,
                WeatherWidgetRefreshWorker.KEY_MANUAL to manual,
            ),
        )
        .build()

    private fun periodic(attempt: Int = 0) = worker(WeatherWidgetRefreshWorker.MODE_PERIODIC, attempt = attempt)
    private fun redraw() = worker(WeatherWidgetRefreshWorker.MODE_REDRAW)

    private fun bindLive(vararg ids: Int) {
        for (id in ids) {
            org.robolectric.Shadows.shadowOf(android.appwidget.AppWidgetManager.getInstance(context)).addBoundWidget(
                id,
                android.appwidget.AppWidgetProviderInfo().apply {
                    provider = android.content.ComponentName(context, WeatherWidgetProvider::class.java)
                },
            )
        }
    }

    private fun infos(name: String): List<WorkInfo> = workManager.getWorkInfosForUniqueWork(name).get()

    private fun unavailableInstances(body: () -> Unit) {
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path, null, SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL("ALTER TABLE widget_instances RENAME TO unavailable_instances")
            try {
                body()
            } finally {
                database.execSQL("ALTER TABLE unavailable_instances RENAME TO widget_instances")
            }
        }
    }

    // ── The periodic tick ───────────────────────────────────────────────────

    @Test
    fun `periodic recovery after a failed reconcile removes orphans and stops empty polling`() {
        store.writeInstance(99, WidgetAddress.Saved("407"), "407", 1L)
        val other = androidx.work.OneTimeWorkRequestBuilder<WeatherWidgetRefreshWorker>()
            .setInitialDelay(1, TimeUnit.DAYS).build()
        workManager.enqueueUniqueWork("other-feature", androidx.work.ExistingWorkPolicy.KEEP, other)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update)
        WidgetRefresh.scheduleLocalRerender(context, 60_000)
        unavailableInstances {
            WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Restored)
            assertEquals(WorkInfo.State.ENQUEUED, infos(WidgetRefresh.periodicWorkName).single().state)
        }

        // Only the production background tick runs after the fault clears: no
        // second receiver event or manual reconcile is available to heal it.
        assertEquals(ListenableWorker.Result.success(), periodic().startWork().get(10, TimeUnit.SECONDS))

        assertTrue("recovery must remove the orphan", store.readInstances().isEmpty())
        for (name in listOf(
            WidgetRefresh.periodicWorkName,
            WidgetRefresh.refreshWorkName,
            WidgetRefresh.localRerenderWorkName,
        )) {
            val work = infos(name)
            assertTrue("$name must not poll an empty launcher", work.isNotEmpty() && work.all { it.state == WorkInfo.State.CANCELLED })
        }
        assertEquals(WorkInfo.State.ENQUEUED, infos("other-feature").single().state)
    }

    @Test
    fun `the periodic tick drops ghosts, appends one refresh and fetches nothing itself`() {
        for ((id, address) in listOf(11 to WidgetAddress.Saved("407"), 13 to WidgetAddress.CurrentLocation)) {
            store.writeInstance(id, address, null, 1L)
        }
        bindLive(11, 13)
        store.writeInstance(99, WidgetAddress.Saved("100"), "100", 1L)
        WidgetRefresh.schedulePeriodic(context)
        val periodicId = infos(WidgetRefresh.periodicWorkName).single().id

        assertEquals(ListenableWorker.Result.success(), periodic().startWork().get(10, TimeUnit.SECONDS))

        assertTrue("the tick must leave fetching to the chain", refresherCalls.isEmpty())
        assertEquals(setOf(11, 13), store.readInstances().map { it.appWidgetId }.toSet())
        assertEquals(listOf(WorkInfo.State.ENQUEUED), infos(WidgetRefresh.refreshWorkName).map { it.state })
        // The tick must not re-enqueue the work it is running as.
        assertEquals(periodicId, infos(WidgetRefresh.periodicWorkName).single().id)
    }

    @Test
    fun `authority failure retries are bounded but the next period still reconciles after recovery`() {
        store.writeInstance(99, WidgetAddress.Saved("407"), "407", 1L)
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path, null, SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL(
                "CREATE TRIGGER refuse_delete BEFORE DELETE ON widget_instances " +
                    "BEGIN SELECT RAISE(ABORT, 'temporary delete failure'); END",
            )
            try {
                WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Restored)
                val periodicId = infos(WidgetRefresh.periodicWorkName).single().id
                for (attempt in listOf(0, 1, 2, 3, 4)) {
                    assertEquals(
                        "authority attempt=$attempt",
                        if (attempt < 3) ListenableWorker.Result.retry() else ListenableWorker.Result.success(),
                        periodic(attempt).startWork().get(10, TimeUnit.SECONDS),
                    )
                    val periodicWork = infos(WidgetRefresh.periodicWorkName).single()
                    assertEquals(periodicId, periodicWork.id)
                    assertEquals(WorkInfo.State.ENQUEUED, periodicWork.state)
                }
                assertTrue("untrusted rows must not be fetched", infos(WidgetRefresh.refreshWorkName).isEmpty())
                assertEquals(listOf(99), store.readInstances().map { it.appWidgetId })
            } finally {
                database.execSQL("DROP TRIGGER refuse_delete")
            }
        }
        // Retry exhaustion is not a permanent escape from authority checks:
        // the next periodic invocation heals without another receiver callback.
        assertEquals(ListenableWorker.Result.success(), periodic().startWork().get(10, TimeUnit.SECONDS))
        assertTrue(store.readInstances().isEmpty())
        assertEquals(WorkInfo.State.CANCELLED, infos(WidgetRefresh.periodicWorkName).single().state)
        assertTrue(refresherCalls.isEmpty())
    }

    // ── A refresh link ──────────────────────────────────────────────────────

    @Test
    fun `a manual update reports running then its actual result without altering freshness`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        for ((result, expected) in listOf(
            WidgetRefreshResult.Refreshed to WidgetRefreshFeedback.Updated,
            WidgetRefreshResult.Superseded to WidgetRefreshFeedback.Updated,
            WidgetRefreshResult.Failed to WidgetRefreshFeedback.Failed,
            WidgetRefreshResult.Unavailable to WidgetRefreshFeedback.Failed,
            WidgetRefreshResult.NoObservation to WidgetRefreshFeedback.Failed,
        )) {
            val run = worker(source = address.sourceIdentifier, manual = true)
            store.beginRefreshFeedback(address, run.id.toString(), System.currentTimeMillis())
            WeatherWidgetRefreshWorker.refresher = { _, _ ->
                assertEquals(WidgetRefreshFeedback.Running, store.readRefreshFeedback(address, System.currentTimeMillis())?.state)
                assertEquals(
                    WidgetRefreshFeedback.Running,
                    WidgetUpdater.presentation(context, 11, 218, 202).refreshFeedback,
                )
                result
            }
            run.doWork()
            assertEquals("result=$result", expected, store.readRefreshFeedback(address, System.currentTimeMillis())?.state)
            assertNull("feedback never manufactures an observation", store.readCurrentWeather(address))
        }
    }

    @Test
    fun `an app push queued behind a manual refresh cannot swallow its feedback`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Tap, address, manual = true)
        val tap = infos(WidgetRefresh.refreshWorkName).single()
        // The app publishes while the tap is still queued: the old per-source
        // REPLACE cancelled the tap here and left "queued" on screen.
        WidgetRefresh.request(context, WidgetRefresh.Reason.AppPublish, address)
        assertEquals(WorkInfo.State.ENQUEUED, infos(WidgetRefresh.refreshWorkName).single { it.id == tap.id }.state)

        val manualRun = TestListenableWorkerBuilder<WeatherWidgetRefreshWorker>(context)
            .setId(tap.id)
            .setInputData(workDataOf(
                WeatherWidgetRefreshWorker.KEY_SOURCE to address.sourceIdentifier,
                WeatherWidgetRefreshWorker.KEY_MANUAL to true,
            ))
            .build()
        manualRun.doWork()
        worker(source = address.sourceIdentifier).doWork()

        assertEquals(WidgetRefreshFeedback.Updated, store.readRefreshFeedback(address, System.currentTimeMillis())?.state)
        assertEquals("the push behind the tap found it already done", listOf("region:407"), refresherCalls)
    }

    @Test
    fun `an older run cannot overwrite the newest queued feedback`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        val run = worker(source = address.sourceIdentifier, manual = true)
        store.beginRefreshFeedback(address, run.id.toString(), System.currentTimeMillis())
        WeatherWidgetRefreshWorker.refresher = { _, _ ->
            store.beginRefreshFeedback(address, "newer", System.currentTimeMillis())
            WidgetRefreshResult.Failed
        }
        run.doWork()
        assertEquals(WidgetRefreshFeedback.Queued, store.readRefreshFeedback(address, System.currentTimeMillis())?.state)
    }

    @Test
    fun `failed refresh retries only below the worker attempt limit`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        WeatherWidgetRefreshWorker.refresher = { _, _ -> WidgetRefreshResult.Failed }
        for (attempt in listOf(0, 1, 2, 3, 4)) {
            val run = worker(source = "region:407", attempt = attempt)
            assertEquals(attempt, run.runAttemptCount)
            assertEquals(
                "attempt=$attempt",
                if (attempt < 3) ListenableWorker.Result.retry() else ListenableWorker.Result.success(),
                run.doWork(),
            )
        }
    }

    @Test
    fun `non-failure refresh outcomes do not request worker retries`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        for (outcome in WidgetRefreshResult.entries.filter { it != WidgetRefreshResult.Failed }) {
            WeatherWidgetRefreshWorker.refresher = { _, _ -> outcome }
            assertEquals(
                "outcome=$outcome",
                ListenableWorker.Result.success(),
                worker(source = "region:407", manual = true).doWork(),
            )
        }
    }

    @Test
    fun `a throwing refresher follows the same bounded worker retry policy`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        WeatherWidgetRefreshWorker.refresher = { _, _ -> throw IllegalStateException("fetch failed") }
        assertEquals(ListenableWorker.Result.retry(), worker(source = "region:407", attempt = 2).doWork())
        assertEquals(ListenableWorker.Result.success(), worker(source = "region:407", attempt = 3).doWork())
    }

    @Test
    fun `a request for a source whose last instance is gone fetches nothing`() {
        // Queued before the instance was removed: the fetch must not happen, and
        // the location fix, clock exchange and HTTP behind it must not either.
        val result = worker(source = "region:407").startWork().get()

        assertTrue(result is ListenableWorker.Result.Success)
        assertTrue("the fetch ran for a source with no instance: $refresherCalls", refresherCalls.isEmpty())
        assertTrue(log.contains("reason=no-instance"))
    }

    @Test
    fun `a request with no source refreshes every shown source once`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(13, WidgetAddress.CurrentLocation, null, 1L)

        worker().startWork().get()

        assertEquals(listOf("region:407", "current-location"), refresherCalls)
    }

    @Test
    fun `a link right after a successful one skips the source unless the user asked`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        worker(source = "region:407").doWork()
        worker().doWork()
        assertEquals("a burst fetches once", listOf("region:407"), refresherCalls)

        worker(source = "region:407", manual = true).doWork()
        assertEquals("a tap always fetches", listOf("region:407", "region:407"), refresherCalls)
    }

    @Test
    fun `a source that is not a valid identifier is ignored, not fatal`() {
        val result = worker(source = "not-a-source").startWork().get()
        assertTrue(result is ListenableWorker.Result.Success)
        assertTrue(refresherCalls.isEmpty())
    }

    // ── Redraws ─────────────────────────────────────────────────────────────

    private fun seedSnapshot(observationSeconds: Long, transitionSeconds: Long) {
        store.writeCatalog(listOf(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!), 1L)
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.commitCurrentWeather(
            CurrentWeatherSnapshot(
                schemaVersion = 7,
                sourceIdentifier = "region:407",
                regionCode = "407",
                regionName = "西屯區",
                observationTime = observationSeconds,
                stationName = "西屯",
                weather = "晴",
                weatherCode = 100,
                condition = WeatherCondition.Clear,
                isNight = false,
                nextDayNightTransitionTime = transitionSeconds,
                calibratedTimeOffsetMilliseconds = 0,
                temperature = 27.0,
                humidity = 60,
                rain = 0.0,
                windDirection = null,
                windSpeed = null,
                apparentTemperature = null,
            ),
            writtenAt = 1L,
        )
    }

    @Test
    fun `a cache-only run touches no network and still re-renders`() {
        seedSnapshot(observationSeconds = 1_791_454_316, transitionSeconds = 1_791_460_000)
        val result = redraw().startWork().get()
        assertTrue(result is ListenableWorker.Result.Success)
        assertTrue("cache-only work must not invoke the refresher", refresherCalls.isEmpty())
        assertTrue(infos(WidgetRefresh.refreshWorkName).isEmpty())
    }

    @Test
    fun `a cache-only run with nothing stored still succeeds`() {
        assertTrue(redraw().startWork().get() is ListenableWorker.Result.Success)
    }

    @Test
    fun `feedback schedules expiry even when the server clock is unavailable`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        WidgetClock.invalidate()
        store.beginRefreshFeedback(WidgetAddress.Saved("407"), "request", System.currentTimeMillis())
        WidgetRefresh.scheduleNextLocalRerender(context)
        assertTrue(log.lines.any { it.contains("local redraw scheduled in") })
    }

    @Test
    fun `the next redraw is scheduled for the real boundary, not a minute later`() {
        val calibratedNow = System.currentTimeMillis()
        WidgetClock.installForTest(calibratedNow, android.os.SystemClock.elapsedRealtime())

        // The observation ages out in 15 minutes, which is nearer than its
        // transition an hour away.
        val observationSeconds = (calibratedNow - WidgetDeadlines.staleAfterMilliseconds) / 1_000 + 15 * 60
        seedSnapshot(observationSeconds = observationSeconds, transitionSeconds = observationSeconds + 3_600)

        redraw().startWork().get()

        val line = log.lines.firstOrNull { it.contains("local redraw") }
        checkNotNull(line) { "expected a scheduling line in ${log.lines}" }
        val seconds = line.substringAfter("in ").substringBefore("s").toLong()
        // 15 minutes, near enough for a millisecond clock: the clamp this
        // replaced would have reported 60.
        assertTrue("expected ~900s, was $seconds ($line)", seconds in 890..910)
    }

    @Test
    fun `a process that lost its anchor restores it and still schedules the boundary`() {
        // The defect: the anchor lived only in memory, and a redraw runs in
        // whatever process the system starts for it. With no anchor it called a
        // fresh observation outdated, hid the forecast, and scheduled nothing —
        // so the Widget stayed "outdated" until the user tapped it.
        android.provider.Settings.Global.putInt(context.contentResolver, android.provider.Settings.Global.BOOT_COUNT, 4)
        WidgetClock.attach(context)
        val calibratedNow = System.currentTimeMillis()
        WidgetClock.installForTest(calibratedNow, android.os.SystemClock.elapsedRealtime(), persist = true)
        val observationSeconds = (calibratedNow - WidgetDeadlines.staleAfterMilliseconds) / 1_000 + 15 * 60
        seedSnapshot(observationSeconds = observationSeconds, transitionSeconds = observationSeconds + 7_200)
        WidgetClock.forgetForTest()

        redraw().startWork().get()

        assertTrue("the fresh observation is drawn as fresh", !WidgetUpdater.presentation(context, 11, 218, 202).isStale)
        val line = checkNotNull(log.lines.firstOrNull { it.contains("local redraw") }) { "nothing scheduled: ${log.lines}" }
        val seconds = line.substringAfter("in ").substringBefore("s").toLong()
        assertTrue("expected ~900s, was $seconds ($line)", seconds in 890..910)
        assertTrue("the next boundary is a staleness one: $line", line.endsWith("refetch=true"))
    }

    @Test
    fun `with no anchor anywhere no weather boundary is scheduled`() {
        seedSnapshot(observationSeconds = 1_791_454_316, transitionSeconds = 1_791_460_000)
        WidgetClock.invalidate()

        val result = redraw().startWork().get()

        assertTrue(result is ListenableWorker.Result.Success)
        assertEquals(null, log.lines.firstOrNull { it.contains("local redraw") })
    }

    @Test
    fun `a day-night boundary only redraws`() {
        val calibratedNow = System.currentTimeMillis()
        WidgetClock.installForTest(calibratedNow, android.os.SystemClock.elapsedRealtime())
        // Fresh for another hour, but the sun sets in ten minutes.
        seedSnapshot(observationSeconds = calibratedNow / 1_000, transitionSeconds = calibratedNow / 1_000 + 600)

        WidgetRefresh.scheduleNextLocalRerender(context)

        val line = checkNotNull(log.lines.firstOrNull { it.contains("local redraw") })
        assertTrue(line, line.endsWith("refetch=false"))
    }

    @Test
    fun `a boundary that needs data asks the chain for it and one that does not, does not`() {
        seedSnapshot(observationSeconds = 1_791_454_316, transitionSeconds = 1_791_460_000)

        worker(WeatherWidgetRefreshWorker.MODE_REDRAW).startWork().get()
        assertTrue("a day/night redraw fetches nothing", infos(WidgetRefresh.refreshWorkName).isEmpty())

        TestListenableWorkerBuilder<WeatherWidgetRefreshWorker>(context)
            .setInputData(workDataOf(
                WeatherWidgetRefreshWorker.KEY_MODE to WeatherWidgetRefreshWorker.MODE_REDRAW,
                WeatherWidgetRefreshWorker.KEY_REFETCH to true,
            ))
            .build()
            .startWork()
            .get()

        assertEquals(listOf(WorkInfo.State.ENQUEUED), infos(WidgetRefresh.refreshWorkName).map { it.state })
        assertTrue("the redraw itself fetches nothing", refresherCalls.isEmpty())
    }
}
