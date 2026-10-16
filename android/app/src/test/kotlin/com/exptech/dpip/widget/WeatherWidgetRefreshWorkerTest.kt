package com.exptech.dpip.widget

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.WorkInfo
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.workDataOf
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * The worker itself: which addresses it touches, and how far ahead it asks for
 * the next redraw.
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

    private lateinit var refresherCalls: MutableList<Triple<String, Boolean, Long?>>

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        // The worker reaches the store through the process singleton, so a stale
        // one would keep a connection to the previous test's deleted file.
        WidgetStore.resetForTest()
        store = WidgetStore.openUncached(context)
        log = RecordingLog()
        WidgetLog.overrideSink = { log }
        androidx.work.testing.WorkManagerTestInitHelper.initializeTestWorkManager(context)
        refresherCalls = ArrayList()
        WeatherWidgetRefreshWorker.refresher = { _, address, includeForecast, demandVersion, _ ->
            refresherCalls.add(Triple(address.sourceIdentifier, includeForecast, demandVersion))
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

    /**
     * Gives an instance a place on the home screen at a measured size.
     *
     * The size comes through `WidgetUpdater.optionsProvider`: the real
     * `AppWidgetManager.getAppWidgetOptions` is answered by the system service
     * and is empty under a JVM runner, so a test that set the options through it
     * would silently be testing the default size.
     */
    private fun bindInstance(
        appWidgetId: Int,
        address: WidgetAddress,
        regionCode: String?,
        widthDp: Int,
        heightDp: Int,
    ) {
        store.writeInstance(appWidgetId, address, regionCode, 1L)
        WidgetUpdater.optionsProvider = { _, id ->
            android.os.Bundle().apply {
                if (id == appWidgetId) {
                    putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, widthDp)
                    putInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, heightDp)
                }
            }
        }
    }

    private fun worker(localOnly: Boolean, source: String? = null, manual: Boolean = false) =
        TestListenableWorkerBuilder<WeatherWidgetRefreshWorker>(context)
            .setInputData(
                workDataOf(
                    WeatherWidgetRefreshWorker.KEY_LOCAL_ONLY to localOnly,
                    WeatherWidgetRefreshWorker.KEY_SOURCE to source,
                    WeatherWidgetRefreshWorker.KEY_MANUAL to manual,
                ),
            )
            .build()

    @Test
    fun `a manual update reports running then its actual result without altering freshness`() {
        val address = WidgetAddress.Saved("407")
        for (result in listOf(WidgetRefreshResult.Refreshed, WidgetRefreshResult.Failed, WidgetRefreshResult.Unavailable, WidgetRefreshResult.NoObservation)) {
            bindInstance(11, address, "407", 218, 202)
            val worker = worker(localOnly = false, source = address.sourceIdentifier, manual = true)
            store.beginRefreshFeedback(address, worker.id.toString(), System.currentTimeMillis())
            WeatherWidgetRefreshWorker.refresher = { _, _, _, _, _ ->
                assertEquals(WidgetRefreshFeedback.Running, store.readRefreshFeedback(address, System.currentTimeMillis())?.state)
                assertEquals(
                    WidgetRefreshFeedback.Running,
                    WidgetUpdater.presentation(context, 11, 218, 202).refreshFeedback,
                )
                result
            }
            worker.doWork()
            assertEquals(
                if (result == WidgetRefreshResult.Refreshed) WidgetRefreshFeedback.Updated else WidgetRefreshFeedback.Failed,
                store.readRefreshFeedback(address, System.currentTimeMillis())?.state,
            )
            assertNull("feedback never manufactures an observation", store.readCurrentWeather(address))
        }
    }

    @Test
    fun `a replaced manual update cannot overwrite the newest queued feedback`() {
        val address = WidgetAddress.Saved("407")
        bindInstance(11, address, "407", 218, 202)
        val worker = worker(localOnly = false, source = address.sourceIdentifier, manual = true)
        store.beginRefreshFeedback(address, worker.id.toString(), System.currentTimeMillis())
        WeatherWidgetRefreshWorker.refresher = { _, _, _, _, _ ->
            store.beginRefreshFeedback(address, "replacement", System.currentTimeMillis())
            WidgetRefreshResult.Failed
        }
        worker.doWork()
        assertEquals(WidgetRefreshFeedback.Queued, store.readRefreshFeedback(address, System.currentTimeMillis())?.state)
    }

    @Test
    fun `feedback schedules expiry even when the server clock is unavailable`() {
        val address = WidgetAddress.Saved("407")
        bindInstance(11, address, "407", 218, 202)
        WidgetClock.invalidate()
        store.beginRefreshFeedback(address, "request", System.currentTimeMillis())
        WeatherWidgetRefreshWorker.scheduleNextLocalRerender(context)
        assertTrue(log.lines.any { it.contains("local redraw scheduled in") })
    }

    private fun seedSnapshot(
        source: String = "region:407",
        regionCode: String = "407",
        observationSeconds: Long,
        transitionSeconds: Long,
    ) {
        store.writeCatalog(
            listOf(WidgetCatalogLocation.create(regionCode, "第${regionCode}區", "縣", 24.181, 120.645)!!),
            1L,
        )
        val address = WidgetAddress.fromSourceIdentifier(source)!!
        store.writeInstance(11, address, regionCode, 1L)
        store.commitCurrentWeather(
            store.beginCurrentWeatherWrite(address)!!,
            CurrentWeatherSnapshot(
                schemaVersion = 7,
                sourceIdentifier = source,
                regionCode = regionCode,
                regionName = "第${regionCode}區",
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
        val result = worker(localOnly = true).startWork().get()
        assertTrue(result is androidx.work.ListenableWorker.Result.Success)
        // No fetch was attempted, so nothing was logged about one.
        assertTrue(log.lines.none { it.contains("weather failed") })
    }

    @Test
    fun `a cache-only run with nothing stored still succeeds`() {
        val result = worker(localOnly = true).startWork().get()
        assertTrue(result is androidx.work.ListenableWorker.Result.Success)
    }

    @Test
    fun `a source-scoped run leaves other sources alone`() {
        // Both sources have instances, but only one is asked for.
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)

        val result = worker(localOnly = true, source = "region:100").startWork().get()

        assertTrue(result is androidx.work.ListenableWorker.Result.Success)
        // A cache-only run writes nothing, so this is really about not throwing
        // and not touching the other address's state.
        assertNull(store.readLocationState(WidgetAddress.Saved("407")))
    }

    @Test
    fun `a request for a source whose last instance is gone fetches nothing`() {
        // Queued before the instance was removed: the fetch must not happen, and
        // the location fix, clock exchange and HTTP behind it must not either.
        val result = worker(localOnly = false, source = "region:407").startWork().get()

        assertTrue(result is androidx.work.ListenableWorker.Result.Success)
        assertTrue(
            "the fetch ran for a source with no instance: $refresherCalls",
            refresherCalls.isEmpty(),
        )
        assertTrue(log.contains("reason=no-instance"))
    }

    @Test
    fun `a request for a source a widget shows does fetch`() {
        bindInstance(11, WidgetAddress.Saved("407"), "407", widthDp = 250, heightDp = 172)

        worker(localOnly = false, source = "region:407").startWork().get()

        assertEquals(listOf(Triple("region:407", true, 1L)), refresherCalls)
    }

    @Test
    fun `the fetch happens even when a compact widget is placed in a short box`() {
        // 250 dp wide but under the forecast budget: the compact layout, and no
        // forecast is asked for.
        bindInstance(11, WidgetAddress.Saved("407"), "407", widthDp = 250, heightDp = 96)

        worker(localOnly = false, source = "region:407").startWork().get()

        assertEquals(listOf(Triple("region:407", false, null)), refresherCalls)
    }

    @Test
    fun `a resize that outlives the queued request still brings the forecast`() {
        // The request is made while the widget is compact…
        bindInstance(11, WidgetAddress.Saved("407"), "407", widthDp = 250, heightDp = 96)
        assertFalse(WidgetUpdater.refreshForecastDemand(context, WidgetAddress.Saved("407")))

        // …then the user drags it taller, which records the demand durably…
        bindInstance(11, WidgetAddress.Saved("407"), "407", widthDp = 250, heightDp = 172)
        assertTrue(WidgetUpdater.refreshForecastDemand(context, WidgetAddress.Saved("407")))

        // …and then back to compact before the work runs, so the live sample
        // alone would say "no forecast". The demand flag is what keeps it.
        bindInstance(11, WidgetAddress.Saved("407"), "407", widthDp = 250, heightDp = 96)

        worker(localOnly = false, source = "region:407").startWork().get()

        assertEquals(
            "the demand must outlive the box it was raised in",
            listOf(Triple("region:407", true, 1L)),
            refresherCalls,
        )
    }

    private fun seedForecast(
        source: String = "region:407",
        regionCode: String = "407",
        updateTime: Long,
        expiresAt: Long,
    ) {
        val address = WidgetAddress.fromSourceIdentifier(source)!!
        store.commitForecast(
            token = store.beginForecastWrite(address)!!,
            forecast = ForecastSnapshot(
                schemaVersion = 1,
                sourceIdentifier = source,
                regionCode = regionCode,
                updateTime = updateTime,
                receivedAt = updateTime,
                points = listOf(ForecastPoint("15:00", 27.0, "多雲", 200, 20)),
            ),
            receivedCalibratedMilliseconds = updateTime,
            expiresAtMilliseconds = expiresAt,
            writtenAt = 1L,
        )
    }

    /** A trusted clock, so a stored deadline can be compared at all. */
    private fun installClock(calibratedNowMilliseconds: Long) {
        WidgetClock.installForTest(
            calibratedNowMilliseconds,
            android.os.SystemClock.elapsedRealtime(),
        )
    }

    @Test
    fun `an expired forecast is fetched again`() {
        val now = 1_791_454_400_000L
        installClock(now)
        bindInstance(11, WidgetAddress.Saved("407"), "407", widthDp = 250, heightDp = 172)
        seedSnapshot(observationSeconds = now / 1_000, transitionSeconds = 0)
        // On screen, and past its deadline.
        seedForecast(updateTime = now - 3_600_000, expiresAt = now - 1)

        worker(localOnly = false, source = "region:407").startWork().get()

        assertEquals(
            "an expired forecast must be fetched again, not kept for ever",
            listOf(Triple("region:407", true, 1L)),
            refresherCalls,
        )
    }

    @Test
    fun `a forecast belonging to a township the widget has left is fetched again`() {
        val now = 1_791_454_400_000L
        installClock(now)
        bindInstance(11, WidgetAddress.CurrentLocation, null, widthDp = 250, heightDp = 172)
        store.commitCurrentWeather(
            store.beginCurrentWeatherWrite(WidgetAddress.CurrentLocation)!!,
            CurrentWeatherSnapshot(
                schemaVersion = 7,
                sourceIdentifier = "current-location",
                regionCode = "100",
                regionName = "中正區",
                observationTime = now / 1_000,
                stationName = "臺北",
                weather = "晴",
                weatherCode = 100,
                condition = WeatherCondition.Clear,
                isNight = false,
                nextDayNightTransitionTime = 0,
                calibratedTimeOffsetMilliseconds = 0,
                temperature = 28.0,
                humidity = 60,
                rain = 0.0,
                windDirection = null,
                windSpeed = null,
                apparentTemperature = null,
            ),
            writtenAt = 1L,
        )
        // The forecast is still the one for the township the device left.
        seedForecast(
            source = "current-location",
            regionCode = "407",
            updateTime = now - 60_000,
            expiresAt = now + 3_600_000,
        )

        worker(localOnly = false, source = "current-location").startWork().get()

        assertEquals(
            listOf(Triple("current-location", true, 1L)),
            refresherCalls,
        )
    }

    @Test
    fun `a wide widget reserves a forecast ticket even when the cached one is usable`() {
        val now = 1_791_454_400_000L
        installClock(now)
        bindInstance(11, WidgetAddress.Saved("407"), "407", widthDp = 250, heightDp = 172)
        seedSnapshot(observationSeconds = now / 1_000, transitionSeconds = 0)
        seedForecast(updateTime = now - 60_000, expiresAt = now + 1_800_000)

        worker(localOnly = false, source = "region:407").startWork().get()

        // The reservation is optimistic, and deliberately so: whether this cached
        // forecast is the one *this run's* township needs can only be answered
        // after the position resolves, where the cache can only name the previous
        // township. The worker must not decide it here by looking at the cache —
        // `WidgetRefreshServiceTest` pins the skip that happens after the resolve.
        assertEquals(
            "a wide instance must reserve a ticket even for a usable forecast",
            listOf(Triple("region:407", true, 0L)),
            refresherCalls,
        )
    }

    @Test
    fun `two runs for one source never fetch at the same time and neither is dropped`() {
        bindInstance(11, WidgetAddress.Saved("407"), "407", widthDp = 250, heightDp = 172)
        val inside = AtomicInteger(0)
        val maximumInside = AtomicInteger(0)
        val fetches = AtomicInteger(0)
        WeatherWidgetRefreshWorker.refresher = { _, _, _, _, _ ->
            val concurrent = inside.incrementAndGet()
            maximumInside.updateAndGet { current -> maxOf(current, concurrent) }
            fetches.incrementAndGet()
            Thread.sleep(50)
            inside.decrementAndGet()
            WidgetRefreshResult.Refreshed
        }

        val first = Thread { worker(localOnly = false, source = "region:407").startWork().get() }
        val second = Thread { worker(localOnly = false, source = "region:407").startWork().get() }
        first.start()
        second.start()
        first.join(10_000)
        second.join(10_000)

        // A replacement is served rather than swallowed — the second request
        // waits for the monitor instead of being skipped — but never beside the
        // first.
        assertEquals("both requests must be served", 2, fetches.get())
        assertEquals("two runs for one source must not fetch at once", 1, maximumInside.get())
    }

    /**
     * The real service over the real store, with a fetch the test can hold.
     *
     * A commit, a demand clear or a forecast fetch is therefore observable in the
     * store and in [forecastRegions], which is what these concurrency tests need
     * — a stub refresher could only report that a fetch was *asked for*.
     */
    private fun realRefresher(
        insideFetch: CountDownLatch?,
        release: CountDownLatch,
        forecastRegions: MutableList<String>,
        onEnter: () -> Unit = {},
    ): (Context, WidgetAddress, Boolean, Long?, () -> Boolean) -> WidgetRefreshResult =
        { ctx, addr, includeForecast, demandVersion, isCancelled ->
            onEnter()
            WidgetRefreshService(
                context = ctx,
                store = store,
                resolveAddress = {
                    LocationResolution.Resolved(
                        ResolvedWeatherLocation.create(it, "407", "西屯區", 24.181, 120.645)!!,
                    )
                },
                synchronizeClock = { true },
                snapshotTime = { WidgetSnapshotTime(1_791_454_400_000L, 0) },
                fetchWeather = { _, _ ->
                    insideFetch?.countDown()
                    release.await(10, TimeUnit.SECONDS)
                    RemoteCurrentWeather(
                        stationName = "西屯",
                        time = 1_791_454_316,
                        weather = "多雲有雨",
                        weatherCode = 206,
                        temperature = 27.5,
                        humidity = 78,
                        rain = 0.4,
                        windDirection = "北北西",
                        windSpeed = 1.3,
                    )
                },
                fetchForecast = { region ->
                    forecastRegions.add(region)
                    RemoteForecast(
                        updateTime = 1_791_454_316_000L,
                        points = listOf(ForecastPoint("15:00", 27.0, "多雲", 200, 20)),
                    )
                },
                nowMilliseconds = { 1L },
                calibratedNowMilliseconds = { 1_791_454_400_000L },
            ).refresh(addr, includeForecast, demandVersion, isCancelled)
        }

    @Test
    fun `a run stopped mid-fetch leaves the resize to the run that replaced it`() {
        val address = WidgetAddress.Saved("407")
        store.writeCatalog(
            listOf(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!),
            1L,
        )
        // Compact when the first run samples the demand: it wants no forecast.
        bindInstance(11, address, "407", widthDp = 250, heightDp = 96)

        val insideFetch = CountDownLatch(1)
        val release = CountDownLatch(1)
        val forecastRegions = Collections.synchronizedList(ArrayList<String>())
        WeatherWidgetRefreshWorker.refresher = realRefresher(insideFetch, release, forecastRegions)

        val stopped = worker(localOnly = false, source = "region:407")
        val stoppedThread = Thread { stopped.startWork().get() }
        stoppedThread.start()
        assertTrue(
            "the first run must reach its fetch: ${log.lines}",
            insideFetch.await(10, TimeUnit.SECONDS),
        )

        // The user drags the widget taller while that run is parked: the demand is
        // raised, and `REPLACE` stops the run and queues its replacement.
        bindInstance(11, address, "407", widthDp = 250, heightDp = 172)
        assertTrue(WidgetUpdater.refreshForecastDemand(context, address))
        stopped.stop(WorkInfo.STOP_REASON_CANCELLED_BY_APP)
        release.countDown()
        stoppedThread.join(10_000)

        // The stopped run left nothing behind — no snapshot, the demand it never
        // answered still raised, and no redraw re-armed under its own identity.
        assertNull("a stopped run must not commit", store.readCurrentWeather(address))
        assertTrue("a stopped run must not clear the demand", store.hasForecastDemand(address))
        assertNull(
            "a stopped run must not re-arm the redraw: ${log.lines}",
            log.lines.firstOrNull { it.contains("local redraw") },
        )

        // The replacement is the run that answers the resize.
        worker(localOnly = false, source = "region:407").startWork().get()

        assertEquals(
            "the resized widget's forecast must be fetched by the replacement",
            listOf("407"),
            forecastRegions,
        )
        assertEquals("407", store.readForecast(address)!!.forecast.regionCode)
    }

    @Test
    fun `a replacement waits for the source instead of being dropped`() {
        // The same race, but observed from the other side: the replacement is
        // started *while the first run is still parked*, which is what a real
        // `WorkManager` `REPLACE` does — it does not wait for the old run to end
        // before the new one runs. The proof that it is not dropped is that it
        // fetches once the stopped run lets go.
        val address = WidgetAddress.Saved("407")
        store.writeCatalog(
            listOf(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!),
            1L,
        )
        bindInstance(11, address, "407", widthDp = 250, heightDp = 96)

        val insideFetch = CountDownLatch(1)
        val release = CountDownLatch(1)
        val refresherEntries = AtomicInteger(0)
        val forecastRegions = Collections.synchronizedList(ArrayList<String>())
        WeatherWidgetRefreshWorker.refresher = realRefresher(insideFetch, release, forecastRegions) {
            refresherEntries.incrementAndGet()
        }

        val stopped = worker(localOnly = false, source = "region:407")
        val stoppedThread = Thread { stopped.startWork().get() }
        stoppedThread.start()
        assertTrue(
            "the first run must reach its fetch: ${log.lines}",
            insideFetch.await(10, TimeUnit.SECONDS),
        )

        // The resize and its replacement arrive while the first run is parked.
        bindInstance(11, address, "407", widthDp = 250, heightDp = 172)
        assertTrue(WidgetUpdater.refreshForecastDemand(context, address))
        WidgetRefreshScheduler.scheduleOneTime(context, address)
        stopped.stop(WorkInfo.STOP_REASON_CANCELLED_BY_APP)

        val replacement = worker(localOnly = false, source = "region:407")
        val replacementThread = Thread { replacement.startWork().get() }
        replacementThread.start()

        // It is waiting on the source, not fetching beside the stopped run: it has
        // had 300 ms to reach its refresher and has not, because the monitor is
        // still held.
        replacementThread.join(300)
        assertEquals(
            "the replacement must wait for the source, not fetch beside it",
            1,
            refresherEntries.get(),
        )

        release.countDown()
        stoppedThread.join(10_000)
        replacementThread.join(10_000)

        // Only now can the replacement have run — and it answered the resize.
        assertEquals(2, refresherEntries.get())
        assertEquals("the resize's forecast must be fetched", listOf("407"), forecastRegions)
        assertFalse(
            "the replacement's commit must clear the demand it answered",
            store.hasForecastDemand(address),
        )
    }

    @Test
    fun `a source that is not a valid identifier is ignored, not fatal`() {
        val result = worker(localOnly = true, source = "not-a-source").startWork().get()
        assertTrue(result is androidx.work.ListenableWorker.Result.Success)
    }

    @Test
    fun `the next redraw is scheduled for the real boundary, not a minute later`() {
        val now = System.currentTimeMillis()
        val calibratedNow = now
        WidgetClock.invalidate()
        // Anchor the clock so the worker can place a calibrated boundary on the
        // device clock.
        WidgetClock.installForTest(calibratedNow, android.os.SystemClock.elapsedRealtime())

        // The observation ages out in 15 minutes, which is nearer than its
        // transition an hour away.
        val observationSeconds = (calibratedNow / 1_000) - (30 * 60) + (15 * 60)
        seedSnapshot(
            observationSeconds = observationSeconds,
            transitionSeconds = observationSeconds + 3_600,
        )

        worker(localOnly = true).startWork().get()

        val line = log.lines.firstOrNull { it.contains("local redraw") }
        checkNotNull(line) { "expected a scheduling line in ${log.lines}" }
        val seconds = line.substringAfter("in ").substringBefore("s").toLong()
        // 15 minutes, near enough for a millisecond clock: the clamp this
        // replaced would have reported 60.
        assertTrue("expected ~900s, was $seconds ($line)", seconds in 890..910)
        WidgetClock.invalidate()
    }

    @Test
    fun `no trusted clock means no redraw is scheduled`() {
        seedSnapshot(observationSeconds = 1_791_454_316, transitionSeconds = 1_791_460_000)
        WidgetClock.invalidate()

        val result = worker(localOnly = true).startWork().get()

        assertTrue(result is androidx.work.ListenableWorker.Result.Success)
        assertEquals(null, log.lines.firstOrNull { it.contains("local redraw") })
    }
}
