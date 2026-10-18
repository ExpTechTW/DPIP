package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.SystemClock
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
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * The refresh's ordering, on the real store.
 *
 * The rule "a late response must not overwrite a newer one" is only worth
 * anything if the *token* is taken before the work that can be overtaken, and
 * that is not visible in a pure function — it is visible here, by letting a
 * refresh's own fetch clear the cache underneath it.
 */
@RunWith(RobolectricTestRunner::class)
class WidgetRefreshServiceTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private lateinit var store: WidgetStore

    private val currentLocation = WidgetAddress.CurrentLocation
    private val taipei = ZoneOffset.ofHours(8)

    private fun atTaipei(hour: Int, minute: Int): Long =
        LocalDateTime.of(2026, 10, 12, hour, minute).toInstant(taipei).toEpochMilli()

    private fun resolved(regionCode: String, name: String = "第${regionCode}區") =
        ResolvedWeatherLocation.create(
            address = WidgetAddress.CurrentLocation,
            regionCode = regionCode,
            regionName = name,
            latitude = 24.181,
            longitude = 120.645,
        )!!

    private fun observation(time: Long = 1_791_454_316) = RemoteCurrentWeather(
        stationName = "西屯",
        time = time,
        weather = "多雲有雨",
        weatherCode = 206,
        temperature = 27.5,
        humidity = 78,
        rain = 0.4,
        windDirection = "北北西",
        windSpeed = 1.3,
    )

    private fun forecastUpdate(updateTime: Long = 1_791_454_316_000L) = RemoteForecast(
        updateTime = updateTime,
        points = listOf(ForecastPoint("15:00", 27.0, "多雲", 200, 20)),
    )

    private fun service(
        resolve: (WidgetAddress) -> LocationResolution = { LocationResolution.Resolved(resolved("407")) },
        synchronizeClock: () -> Boolean = { true },
        snapshotTime: () -> WidgetSnapshotTime? = { WidgetSnapshotTime(1_791_454_400_000L, 0) },
        fetchWeather: (Double, Double) -> RemoteCurrentWeather? = { _, _ -> observation() },
        fetchForecast: (String) -> RemoteForecast = { forecastUpdate() },
        now: () -> Long = { 1L },
        // The forecast's receipt is dated by this, read after its response; the
        // default follows the injected snapshot time so a test that sets one gets
        // a consistent clock.
        calibratedNow: () -> Long? = { snapshotTime()?.calibratedNowUnixMilliseconds },
    ) = WidgetRefreshService(
        context = context,
        store = store,
        resolveAddress = resolve,
        synchronizeClock = synchronizeClock,
        snapshotTime = snapshotTime,
        fetchWeather = fetchWeather,
        fetchForecast = fetchForecast,
        nowMilliseconds = now,
        calibratedNowMilliseconds = calibratedNow,
    )

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        store = WidgetStore.openUncached(context)
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
        WidgetUpdater.resetOptionsProvider()
        WidgetClock.invalidate()
        WidgetLog.resetForTest()
    }

    /**
     * A current-weather row for a township, as the store would hold it.
     *
     * Only the identity and the observation time matter to the ordering rules
     * these tests exercise.
     */
    private fun currentSnapshot(
        regionCode: String,
        observationSeconds: Long = 1_791_454_316,
    ) = CurrentWeatherSnapshot(
        schemaVersion = 7,
        sourceIdentifier = WidgetAddress.CurrentLocation.sourceIdentifier,
        regionCode = regionCode,
        regionName = "第${regionCode}區",
        observationTime = observationSeconds,
        stationName = "西屯",
        weather = "多雲有雨",
        weatherCode = 206,
        condition = WeatherCondition.Rain,
        isNight = false,
        nextDayNightTransitionTime = 0,
        calibratedTimeOffsetMilliseconds = 0,
        temperature = 27.5,
        humidity = 78,
        rain = 0.4,
        windDirection = "北北西",
        windSpeed = 1.3,
        apparentTemperature = 30.2,
    )

    private fun seedForecast(
        regionCode: String,
        updateTime: Long,
        expiresAt: Long,
    ) {
        store.commitForecast(
            token = store.beginForecastWrite(currentLocation)!!,
            forecast = ForecastSnapshot(
                schemaVersion = 1,
                sourceIdentifier = currentLocation.sourceIdentifier,
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

    @Test
    fun `the token is reserved before the fetch, so a clear during it wins`() {
        // The fetch clears the cache underneath the refresh before answering.
        // If the token were reserved after the fetch — as it was — the commit
        // would be accepted and the cleared data would reappear.
        val result = service(
            fetchWeather = { _, _ ->
                store.clearCurrentWeather()
                observation()
            },
        ).refresh(currentLocation, includeForecast = false)

        assertEquals(WidgetRefreshResult.Superseded, result)
        assertNull(store.readCurrentWeather(currentLocation))
    }

    @Test
    fun `the token is reserved before the clock, so a clear during it wins`() {
        val result = service(
            synchronizeClock = {
                store.clearCurrentWeather()
                true
            },
        ).refresh(currentLocation, includeForecast = false)

        assertEquals(WidgetRefreshResult.Superseded, result)
        assertNull(store.readCurrentWeather(currentLocation))
    }

    @Test
    fun `an older township cannot overwrite a newer one that landed while it waited`() {
        val inFlight = CountDownLatch(1)
        val released = CountDownLatch(1)

        // The first refresh reserves, resolves to township 407, and parks inside
        // its fetch.
        CheckedTestThreads().use { threads ->
            try {
                val slow = threads.start("older township refresh") {
                    service(
                        resolve = { LocationResolution.Resolved(resolved("407")) },
                        fetchWeather = { _, _ ->
                            inFlight.countDown()
                            assertTrue("older fetch was not released", released.await(10, TimeUnit.SECONDS))
                            observation(time = 1_791_454_400)
                        },
                    ).refresh(currentLocation, includeForecast = false).also {
                        assertEquals(WidgetRefreshResult.Superseded, it)
                    }
                }
                assertTrue(inFlight.await(10, TimeUnit.SECONDS))

                // The device moves to township 100 and a second refresh completes.
                val fast = service(
                    resolve = { LocationResolution.Resolved(resolved("100")) },
                    fetchWeather = { _, _ -> observation(time = 1_791_454_300) },
                ).refresh(currentLocation, includeForecast = false)
                assertEquals(WidgetRefreshResult.Refreshed, fast)

                released.countDown()
                threads.await(slow)

                // The older acquisition must not replace the newer township.
                val stored = store.readCurrentWeather(currentLocation)!!
                assertEquals("100", stored.snapshot.regionCode)
            } finally {
                released.countDown()
            }
        }
    }

    @Test
    fun `a clear during the current-weather fetch fences the forecast too`() {
        // Only the forecast cache is cleared: the current weather still lands,
        // and its refresh's forecast token was reserved with it, so the forecast
        // commit is refused as well.
        val result = service(
            fetchWeather = { _, _ ->
                store.clearForecast()
                observation()
            },
        ).refresh(currentLocation, includeForecast = true)

        assertEquals(WidgetRefreshResult.Refreshed, result)
        assertNull(store.readForecast(currentLocation))
    }

    @Test
    fun `a forecast lands with the same refresh identity`() {
        val result = service().refresh(currentLocation, includeForecast = true)
        assertEquals(WidgetRefreshResult.Refreshed, result)
        assertEquals("407", store.readForecast(currentLocation)!!.forecast.regionCode)
    }

    @Test
    fun `a failed clock leaves the previous snapshot alone`() {
        assertEquals(
            WidgetRefreshResult.Refreshed,
            service().refresh(currentLocation, includeForecast = false),
        )

        val result = service(synchronizeClock = { false })
            .refresh(currentLocation, includeForecast = false)

        assertEquals(WidgetRefreshResult.Unavailable, result)
        assertEquals(1_791_454_316L, store.readCurrentWeather(currentLocation)!!.snapshot.observationTime)
    }

    @Test
    fun `a failed fetch leaves the previous snapshot alone`() {
        service().refresh(currentLocation, includeForecast = false)

        val result = service(fetchWeather = { _, _ -> throw WidgetHttpException("boom") })
            .refresh(currentLocation, includeForecast = false)

        assertEquals(WidgetRefreshResult.Failed, result)
        assertEquals(1_791_454_316L, store.readCurrentWeather(currentLocation)!!.snapshot.observationTime)
    }

    @Test
    fun `no observation is its own outcome and writes nothing`() {
        val result = service(fetchWeather = { _, _ -> null })
            .refresh(currentLocation, includeForecast = false)
        assertEquals(WidgetRefreshResult.NoObservation, result)
        assertNull(store.readCurrentWeather(currentLocation))
    }

    @Test
    fun `a degraded position records the reason and keeps the snapshot`() {
        service().refresh(currentLocation, includeForecast = false)

        val result = service(
            resolve = { LocationResolution.Degraded(WidgetLocationDegradation.Disabled) },
        ).refresh(currentLocation, includeForecast = false)

        assertEquals(WidgetRefreshResult.Unavailable, result)
        assertEquals(
            WidgetLocationDegradation.Disabled,
            store.readLocationState(currentLocation),
        )
        // The last known observation is still on screen.
        assertEquals(1_791_454_316L, store.readCurrentWeather(currentLocation)!!.snapshot.observationTime)
    }

    @Test
    fun `a fix that cannot be trusted records its own reason`() {
        val result = service(
            resolve = { LocationResolution.Degraded(WidgetLocationDegradation.UnresolvedTownship) },
        ).refresh(currentLocation, includeForecast = false)

        assertEquals(WidgetRefreshResult.Unavailable, result)
        assertEquals(
            WidgetLocationDegradation.UnresolvedTownship,
            store.readLocationState(currentLocation),
        )
    }

    @Test
    fun `the degradation is only cleared by a commit that lands`() {
        store.writeLocationState(currentLocation, WidgetLocationDegradation.Permission, 1L, 1L)

        // The position resolves and the clock is fine, but the fetch returns
        // nothing, so no commit lands and the notice must stay.
        assertEquals(
            WidgetRefreshResult.NoObservation,
            service(fetchWeather = { _, _ -> null }).refresh(currentLocation, false),
        )
        assertEquals(
            WidgetLocationDegradation.Permission,
            store.readLocationState(currentLocation),
        )

        // Only a landed observation clears it.
        assertEquals(
            WidgetRefreshResult.Refreshed,
            service().refresh(currentLocation, false),
        )
        assertNull(store.readLocationState(currentLocation))
    }

    @Test
    fun `a later refresh recovers a temporary location failure without app intervention`() {
        for (degradation in listOf(WidgetLocationDegradation.Unavailable, WidgetLocationDegradation.UnusableFix,
            WidgetLocationDegradation.UnresolvedTownship)) {
            val cached = store.readCurrentWeather(currentLocation)
            assertEquals(
                WidgetRefreshResult.Unavailable,
                service(resolve = { LocationResolution.Degraded(degradation) })
                    .refresh(currentLocation, includeForecast = false),
            )
            assertEquals(degradation, store.readLocationState(currentLocation))
            assertEquals(cached, store.readCurrentWeather(currentLocation))

            assertEquals(
                WidgetRefreshResult.Refreshed,
                service().refresh(currentLocation, includeForecast = false),
            )
            assertNull(store.readLocationState(currentLocation))
            assertEquals("407", store.readCurrentWeather(currentLocation)!!.snapshot.regionCode)
        }
    }

    @Test
    fun `the snapshot records a transition in seconds, not milliseconds`() {
        service().refresh(currentLocation, includeForecast = false)

        val snapshot = store.readCurrentWeather(currentLocation)!!.snapshot
        // A Unix-seconds value for 2026 is around 1.79e9; milliseconds would be
        // three orders of magnitude larger.
        assertTrue(
            "transition is not Unix seconds: ${snapshot.nextDayNightTransitionTime}",
            snapshot.nextDayNightTransitionTime in 1_700_000_000L..2_200_000_000L,
        )
        assertTrue(
            "observation is not Unix seconds: ${snapshot.observationTime}",
            snapshot.observationTime in 1_700_000_000L..2_200_000_000L,
        )
        // And the day/night transition belongs to the same day as the
        // observation, which a 1000× error would not be.
        val delta = snapshot.nextDayNightTransitionTime - snapshot.observationTime
        assertTrue("transition should be within a day, was ${delta}s", delta in -86_400..86_400)
    }

    @Test
    fun `the forecast receipt is dated when its response arrives`() {
        // The response lands after the Taipei hour has turned. Dating the receipt
        // from the moment the weather fetch started would put it in the previous
        // hour, and the deadline — the earlier of publication + 30 min and the
        // next hourly boundary — would then be an hour too early.
        val publish = atTaipei(14, 50)
        var clock = atTaipei(14, 58)
        val service = service(
            fetchWeather = { _, _ -> observation() },
            fetchForecast = {
                // Reading the clock inside the fetch stands in for the wall time
                // the response takes.
                clock = atTaipei(15, 2)
                RemoteForecast(
                    updateTime = publish,
                    points = listOf(ForecastPoint("16:00", 27.0, "多雲", 200, 20)),
                )
            },
            calibratedNow = { clock },
        )

        assertEquals(WidgetRefreshResult.Refreshed, service.refresh(currentLocation, true))

        assertEquals(
            "the deadline must be taken from the receipt, not from before the request",
            atTaipei(15, 20),
            store.readForecast(currentLocation)!!.expiresAtMilliseconds,
        )
    }

    @Test
    fun `an expired forecast stays expired when the device clock is moved`() {
        // Accepted at 14:55 calibrated, published at 14:50: the next Taipei hour
        // (15:00) is nearer than publication + 30 minutes, so that is the
        // deadline the commit records.
        val accepted = atTaipei(14, 55)
        val publish = atTaipei(14, 50)
        service(
            snapshotTime = { WidgetSnapshotTime(accepted, 0) },
            fetchWeather = { _, _ -> observation() },
            fetchForecast = {
                RemoteForecast(
                    updateTime = publish,
                    points = listOf(ForecastPoint("15:00", 27.0, "多雲", 200, 20)),
                )
            },
        ).refresh(currentLocation, includeForecast = true)

        assertEquals(atTaipei(15, 0), store.readForecast(currentLocation)!!.expiresAtMilliseconds)

        // The user moves the device clock back forty minutes; the next weather
        // refresh records a new offset, and its forecast fetch fails, so the
        // stored forecast is still the one from before.
        val movedOffset = 40 * 60 * 1_000L
        val later = service(
            snapshotTime = { WidgetSnapshotTime(atTaipei(15, 5), movedOffset) },
            fetchWeather = { _, _ -> observation(time = 1_791_454_700) },
            fetchForecast = { throw WidgetHttpException("offline") },
        )
        assertEquals(
            WidgetRefreshResult.Refreshed,
            // The forecast is asked for again and its fetch fails, so the entry
            // from before is the one still on screen — which is the case a
            // recomputed deadline would have expired-and-revived.
            later.refresh(currentLocation, includeForecast = true),
        )

        assertEquals(
            "the recorded deadline must not move",
            atTaipei(15, 0),
            store.readForecast(currentLocation)!!.expiresAtMilliseconds,
        )
        assertEquals(
            movedOffset,
            store.readCurrentWeather(currentLocation)!!.snapshot.calibratedTimeOffsetMilliseconds,
        )

        // And the screen agrees: five minutes past the deadline it is gone.
        val presentation = WidgetPresenter.present(
            sizeClass = WidgetSizeClass.Medium,
            strings = WidgetUpdater.strings(context),
            address = currentLocation,
            locationName = "西屯區",
            stored = store.readCurrentWeather(currentLocation),
            forecast = store.readForecast(currentLocation),
            locationDegradation = null,
            isCatalogMember = true,
            calibratedNowMilliseconds = atTaipei(15, 5),
            latitude = 24.181,
            longitude = 120.645,
            availableHeightDp = 250,
        )
        assertTrue(
            "a forecast past its recorded deadline must not be drawn",
            presentation.forecast.isEmpty(),
        )
    }

    @Test
    fun `a resolved position is logged without its coordinates`() {
        val log = RecordingLog()
        WidgetLog.overrideSink = { log }

        service().refresh(currentLocation, includeForecast = false)

        assertTrue("expected a resolved line in ${log.lines}", log.contains("position resolved source=current-location region=407"))
        // The diagnostic carries the region, the accuracy and the age — never the
        // coordinate, which would turn a log into a location record.
        assertTrue(
            "coordinates leaked into ${log.lines}",
            log.lines.none { it.contains("24.1") || it.contains("120.6") },
        )
    }

    @Test
    fun `many refreshes of one source keep one ordering counter`() {
        val counter = AtomicInteger()
        repeat(3) {
            assertEquals(
                WidgetRefreshResult.Refreshed,
                service(now = { counter.incrementAndGet().toLong() })
                    .refresh(currentLocation, includeForecast = false),
            )
        }
        // The newest observation is the one on screen, and the counter only ever
        // moved forward.
        assertEquals(1_791_454_316L, store.readCurrentWeather(currentLocation)!!.snapshot.observationTime)
    }

    // ── A run that was stopped leaves nothing for the run that replaced it ──

    @Test
    fun `a run stopped before it starts touches nothing`() {
        var resolved = false
        val result = service(
            resolve = { resolved = true; LocationResolution.Resolved(resolved("407")) },
        ).refresh(currentLocation, includeForecast = true, isCancelled = { true })

        assertEquals(WidgetRefreshResult.Cancelled, result)
        assertFalse("a stopped run must not spend a location fix", resolved)
        assertNull(store.readCurrentWeather(currentLocation))
    }

    @Test
    fun `a run stopped while its weather fetch is in flight lands nothing`() {
        val stop = AtomicBoolean(false)
        var forecastFetches = 0
        store.setForecastDemand(currentLocation, demand = true, updatedAt = 1L)
        val demandVersion = store.readForecastDemandVersion(currentLocation)

        val result = service(
            fetchWeather = { _, _ ->
                // The replacement cancels this run while its fetch is parked.
                stop.set(true)
                observation()
            },
            fetchForecast = { forecastFetches++; forecastUpdate() },
        ).refresh(
            currentLocation,
            includeForecast = true,
            answeredDemandVersion = demandVersion,
            isCancelled = { stop.get() },
        )

        assertEquals(WidgetRefreshResult.Cancelled, result)
        assertNull(store.readCurrentWeather(currentLocation))
        assertNull(store.readForecast(currentLocation))
        assertEquals("a stopped run must not fetch the forecast", 0, forecastFetches)
        assertTrue(
            "a stopped run must not clear the demand its replacement will answer",
            store.hasForecastDemand(currentLocation),
        )
    }

    @Test
    fun `a run stopped while its forecast fetch is in flight keeps the demand raised`() {
        val stop = AtomicBoolean(false)
        store.setForecastDemand(currentLocation, demand = true, updatedAt = 1L)
        val demandVersion = store.readForecastDemandVersion(currentLocation)

        val result = service(
            fetchForecast = { stop.set(true); forecastUpdate() },
        ).refresh(
            currentLocation,
            includeForecast = true,
            answeredDemandVersion = demandVersion,
            isCancelled = { stop.get() },
        )

        // The observation landed before the stop, so that part stands.
        assertEquals(WidgetRefreshResult.Refreshed, result)
        assertNotNull(store.readCurrentWeather(currentLocation))
        assertNull("a stopped run must not commit its forecast", store.readForecast(currentLocation))
        assertTrue(
            "a stopped run must not answer the demand it never committed",
            store.hasForecastDemand(currentLocation),
        )
    }

    // ── The forecast is decided against the township this round resolved ──

    @Test
    fun `a fresh forecast for the township the device just left does not stop this round's fetch`() {
        // The cache names township A and its forecast is fresh, but this round's
        // position resolves to B. The reservation is made before the resolve, so
        // the fetch can only be decided here — against B.
        store.commitCurrentWeather(
            token = store.beginCurrentWeatherWrite(currentLocation)!!,
            snapshot = currentSnapshot("407"),
            writtenAt = 1L,
        )
        seedForecast(
            regionCode = "407",
            updateTime = 1_791_454_400_000L,
            expiresAt = 1_791_457_200_000L,
        )

        val fetched = ArrayList<String>()
        val result = service(
            resolve = { LocationResolution.Resolved(resolved("100")) },
            fetchForecast = { region -> fetched.add(region); forecastUpdate() },
        ).refresh(currentLocation, includeForecast = true)

        assertEquals(WidgetRefreshResult.Refreshed, result)
        assertEquals("the same round must fetch the township it resolved to", listOf("100"), fetched)
        assertEquals("100", store.readForecast(currentLocation)!!.forecast.regionCode)
    }

    @Test
    fun `a fresh forecast for the resolved township is not fetched again`() {
        store.commitCurrentWeather(
            token = store.beginCurrentWeatherWrite(currentLocation)!!,
            snapshot = currentSnapshot("407"),
            writtenAt = 1L,
        )
        seedForecast(
            regionCode = "407",
            updateTime = 1_791_454_400_000L,
            expiresAt = 1_791_457_200_000L,
        )

        var forecastFetches = 0
        val result = service(
            fetchForecast = { forecastFetches++; forecastUpdate() },
        ).refresh(currentLocation, includeForecast = true)

        assertEquals(WidgetRefreshResult.Refreshed, result)
        assertEquals("a forecast for the same township inside its deadline needs no fetch", 0, forecastFetches)
        assertEquals("407", store.readForecast(currentLocation)!!.forecast.regionCode)
    }

    // ── Calibration does not depend on getting a background fix ──

    @Test
    fun `a foreground-only position still calibrates the clock and the screen shows the fresh observation`() {
        WidgetClock.invalidate()
        val now = atTaipei(14, 20)
        // The app published a fresh observation while it was in the foreground;
        // the headless refresh cannot get a fix, but that must not stop the clock.
        store.writeInstance(7, WidgetAddress.CurrentLocation, null, 1L)
        store.commitCurrentWeather(
            token = store.beginCurrentWeatherWrite(WidgetAddress.CurrentLocation)!!,
            snapshot = currentSnapshot("407", observationSeconds = atTaipei(14, 18) / 1_000),
            writtenAt = 1L,
        )

        val result = service(
            resolve = { LocationResolution.Degraded(WidgetLocationDegradation.Permission) },
            synchronizeClock = {
                WidgetClock.installForTest(now, SystemClock.elapsedRealtime())
                true
            },
        ).refresh(WidgetAddress.CurrentLocation, includeForecast = false)

        assertEquals(WidgetRefreshResult.Unavailable, result)
        assertNotNull(
            "a degraded fix must still leave the clock anchored",
            WidgetClock.calibratedNowMilliseconds(),
        )
        assertEquals(
            WidgetLocationDegradation.Permission,
            store.readLocationState(WidgetAddress.CurrentLocation),
        )

        // The real production presentation, at the metadata's own minimum size.
        WidgetUpdater.optionsProvider = { _, id ->
            android.os.Bundle().apply {
                if (id == 7) {
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
                }
            }
        }
        val presentation = WidgetUpdater.presentation(context, 7, 110, 110)

        assertFalse(
            "an anchored clock must let a fresh observation be shown as fresh",
            presentation.isStale,
        )
        assertEquals(WidgetDisplayState.NeedsApp, presentation.state)
        assertNotNull("the observation time must still be drawn", presentation.observationTimeMillis)
        assertEquals(
            WidgetUpdater.strings(context).needsApp,
            presentation.badgeText,
        )
    }
}
