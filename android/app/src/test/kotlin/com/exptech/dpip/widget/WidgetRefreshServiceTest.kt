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
import java.util.concurrent.atomic.AtomicInteger

/**
 * The refresh's ordering, on the real store.
 *
 * The rule "a late response must not overwrite a newer one" is only worth
 * anything if the *acquisition* is taken before the work that can be
 * overtaken, and that is not visible in a pure function — it is visible here,
 * by letting another writer land while a refresh's own fetch is parked.
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
                    ).refresh(currentLocation).also {
                        assertEquals(WidgetRefreshResult.Superseded, it)
                    }
                }
                assertTrue(inFlight.await(10, TimeUnit.SECONDS))

                // The device moves to township 100 and a second refresh completes.
                val fast = service(
                    resolve = { LocationResolution.Resolved(resolved("100")) },
                    fetchWeather = { _, _ -> observation(time = 1_791_454_300) },
                ).refresh(currentLocation)
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
    fun `a township the app publishes during the fix outranks the position taken before it`() {
        // The refresh took its acquisition, then the app published township
        // 100 while the fix was still being taken; the fix itself (407) is from
        // before the move and must not replace what the app just published.
        val result = service(
            resolve = {
                assertEquals(
                    WidgetWriteResult.Written,
                    store.commitCurrentWeather(currentSnapshot("100", observationSeconds = 1_791_454_000), writtenAt = 1L),
                )
                LocationResolution.Resolved(resolved("407"))
            },
        ).refresh(currentLocation)

        assertEquals(WidgetRefreshResult.Superseded, result)
        assertEquals("100", store.readCurrentWeather(currentLocation)!!.snapshot.regionCode)
        assertNull("a forecast for the township left behind is not fetched", store.readForecast(currentLocation))
    }

    @Test
    fun `a newer observation the app publishes during the fetch is kept`() {
        val result = service(
            fetchWeather = { _, _ ->
                store.commitCurrentWeather(currentSnapshot("407", observationSeconds = 1_791_454_900), writtenAt = 1L)
                observation(time = 1_791_454_316)
            },
        ).refresh(currentLocation)

        assertEquals(WidgetRefreshResult.Superseded, result)
        assertEquals(1_791_454_900L, store.readCurrentWeather(currentLocation)!!.snapshot.observationTime)
    }

    @Test
    fun `a forecast lands with the same refresh identity`() {
        val result = service().refresh(currentLocation)
        assertEquals(WidgetRefreshResult.Refreshed, result)
        assertEquals("407", store.readForecast(currentLocation)!!.forecast.regionCode)
    }

    @Test
    fun `a failed clock leaves the previous snapshot alone`() {
        assertEquals(
            WidgetRefreshResult.Refreshed,
            service().refresh(currentLocation),
        )

        val result = service(synchronizeClock = { false })
            .refresh(currentLocation)

        assertEquals(WidgetRefreshResult.Unavailable, result)
        assertEquals(1_791_454_316L, store.readCurrentWeather(currentLocation)!!.snapshot.observationTime)
    }

    @Test
    fun `a failed fetch leaves the previous snapshot alone`() {
        service().refresh(currentLocation)

        val result = service(fetchWeather = { _, _ -> throw WidgetHttpException("boom") })
            .refresh(currentLocation)

        assertEquals(WidgetRefreshResult.Failed, result)
        assertEquals(1_791_454_316L, store.readCurrentWeather(currentLocation)!!.snapshot.observationTime)
    }

    @Test
    fun `no observation is its own outcome and writes nothing`() {
        val result = service(fetchWeather = { _, _ -> null })
            .refresh(currentLocation)
        assertEquals(WidgetRefreshResult.NoObservation, result)
        assertNull(store.readCurrentWeather(currentLocation))
    }

    @Test
    fun `a degraded position records the reason and keeps the snapshot`() {
        service().refresh(currentLocation)

        val result = service(
            resolve = { LocationResolution.Degraded(WidgetLocationDegradation.Disabled) },
        ).refresh(currentLocation)

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
        ).refresh(currentLocation)

        assertEquals(WidgetRefreshResult.Unavailable, result)
        assertEquals(
            WidgetLocationDegradation.UnresolvedTownship,
            store.readLocationState(currentLocation),
        )
    }

    @Test
    fun `the degradation is only cleared by a commit that lands`() {
        store.writeLocationState(currentLocation, WidgetLocationDegradation.Permission, 1L)

        // The position resolves and the clock is fine, but the fetch returns
        // nothing, so no commit lands and the notice must stay.
        assertEquals(
            WidgetRefreshResult.NoObservation,
            service(fetchWeather = { _, _ -> null }).refresh(currentLocation),
        )
        assertEquals(
            WidgetLocationDegradation.Permission,
            store.readLocationState(currentLocation),
        )

        // Only a landed observation clears it.
        assertEquals(
            WidgetRefreshResult.Refreshed,
            service().refresh(currentLocation),
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
                    .refresh(currentLocation),
            )
            assertEquals(degradation, store.readLocationState(currentLocation))
            assertEquals(cached, store.readCurrentWeather(currentLocation))

            assertEquals(
                WidgetRefreshResult.Refreshed,
                service().refresh(currentLocation),
            )
            assertNull(store.readLocationState(currentLocation))
            assertEquals("407", store.readCurrentWeather(currentLocation)!!.snapshot.regionCode)
        }
    }

    @Test
    fun `the snapshot records a transition in seconds, not milliseconds`() {
        service().refresh(currentLocation)

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

        assertEquals(WidgetRefreshResult.Refreshed, service.refresh(currentLocation))

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
        ).refresh(currentLocation)

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
            later.refresh(currentLocation),
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

        service().refresh(currentLocation)

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
                    .refresh(currentLocation),
            )
        }
        // The newest observation is the one on screen, and the counter only ever
        // moved forward.
        assertEquals(1_791_454_316L, store.readCurrentWeather(currentLocation)!!.snapshot.observationTime)
    }

    @Test
    fun `a fresh forecast for the township the device just left does not stop this round's fetch`() {
        // The cache names township A and its forecast is fresh, but this round's
        // position resolves to B. The reservation is made before the resolve, so
        // the fetch can only be decided here — against B.
        store.commitCurrentWeather(
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
        ).refresh(currentLocation)

        assertEquals(WidgetRefreshResult.Refreshed, result)
        assertEquals("the same round must fetch the township it resolved to", listOf("100"), fetched)
        assertEquals("100", store.readForecast(currentLocation)!!.forecast.regionCode)
    }

    @Test
    fun `a fresh forecast for the resolved township is not fetched again`() {
        store.commitCurrentWeather(
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
        ).refresh(currentLocation)

        assertEquals(WidgetRefreshResult.Refreshed, result)
        assertEquals("a forecast for the same township inside its deadline needs no fetch", 0, forecastFetches)
        assertEquals("407", store.readForecast(currentLocation)!!.forecast.regionCode)
    }

    @Test
    fun `a foreground-only position still calibrates the clock and the screen shows the fresh observation`() {
        WidgetClock.invalidate()
        val now = atTaipei(14, 20)
        // The app published a fresh observation while it was in the foreground;
        // the headless refresh cannot get a fix, but that must not stop the clock.
        store.writeInstance(7, WidgetAddress.CurrentLocation, null, 1L)
        store.commitCurrentWeather(
            snapshot = currentSnapshot("407", observationSeconds = atTaipei(14, 18) / 1_000),
            writtenAt = 1L,
        )

        val result = service(
            resolve = { LocationResolution.Degraded(WidgetLocationDegradation.Permission) },
            synchronizeClock = {
                WidgetClock.installForTest(now, SystemClock.elapsedRealtime())
                true
            },
        ).refresh(WidgetAddress.CurrentLocation)

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
