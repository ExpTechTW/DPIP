package com.exptech.dpip.widget

import android.content.Context
import android.database.sqlite.SQLiteDatabase
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
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.robolectric.RobolectricTestRunner

/**
 * The store's real SQL, on Robolectric's SQLite.
 *
 * The ordering *rule* is pinned by `SnapshotOrderingTest` as a pure function;
 * what this covers is everything the rule cannot see — that the token survives
 * a transaction, that a clear fences an in-flight write, that a removed town
 * fences its own, that a reconfigure does not fence a source another instance
 * still uses, that a restore leaves no ghost, that an upgrade keeps the user's
 * choices, and that a broken database reports a *failure* rather than a quiet
 * rejection.
 */
@RunWith(RobolectricTestRunner::class)
@org.robolectric.annotation.Config(sdk = [26, 35])
class WidgetStoreTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val saved = WidgetAddress.Saved("407")
    private lateinit var store: WidgetStore

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        store = WidgetStore.openUncached(context)
    }

    @After
    fun tearDown() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetLog.resetForTest()
    }

    private fun snapshot(
        observationSeconds: Long = 1_791_454_316,
        regionCode: String = "407",
        source: String = "region:407",
    ) = CurrentWeatherSnapshot(
        schemaVersion = 7,
        sourceIdentifier = source,
        regionCode = regionCode,
        regionName = "西屯區",
        observationTime = observationSeconds,
        stationName = "西屯",
        weather = "多雲有雨",
        weatherCode = 206,
        condition = WeatherCondition.Rain,
        isNight = false,
        nextDayNightTransitionTime = observationSeconds + 3_600,
        calibratedTimeOffsetMilliseconds = -1_200,
        temperature = 27.5,
        humidity = 78,
        rain = 0.4,
        windDirection = "北北西",
        windSpeed = 1.3,
        apparentTemperature = 30.2,
    )

    @Test
    fun `manual feedback survives a new connection and is isolated by source`() {
        assertTrue(store.beginRefreshFeedback(saved, "request-a", 1_000L))
        val reopened = WidgetStore.openUncached(context)
        assertEquals(WidgetRefreshFeedback.Queued, reopened.readRefreshFeedback(saved, 1_001L)?.state)
        assertNull(reopened.readRefreshFeedback(WidgetAddress.Saved("100"), 1_001L))
        assertTrue(reopened.writeRefreshFeedback(saved, "request-a", WidgetRefreshFeedback.Running, 2_000L))
        assertEquals(WidgetRefreshFeedback.Running, store.readRefreshFeedback(saved, 2_001L)?.state)
    }

    @Test
    fun `an older worker cannot overwrite feedback for a newer tap`() {
        store.beginRefreshFeedback(saved, "old", 1_000L)
        store.beginRefreshFeedback(saved, "new", 2_000L)
        assertTrue(!store.writeRefreshFeedback(saved, "old", WidgetRefreshFeedback.Failed, 3_000L))
        assertEquals(WidgetRefreshFeedback.Queued, store.readRefreshFeedback(saved, 3_000L)?.state)
        assertTrue(store.writeRefreshFeedback(saved, "new", WidgetRefreshFeedback.Updated, 4_000L))
        assertEquals(WidgetRefreshFeedback.Updated, store.readRefreshFeedback(saved, 4_001L)?.state)
    }

    @Test
    fun `feedback expires and a clock moved before its start does not show it`() {
        store.beginRefreshFeedback(saved, "request", 1_000L)
        assertNull(store.readRefreshFeedback(saved, 999L))
        assertNull(store.readRefreshFeedback(saved, 121_000L))
        store.writeRefreshFeedback(saved, "request", WidgetRefreshFeedback.Updated, 2_000L)
        assertNull(store.readRefreshFeedback(saved, 32_000L))
    }

    @Test
    fun `the additive v4 upgrade preserves v3 observations forecasts and choices`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        store.writeInstance(11, saved, "407", 1L)
        assertEquals(WidgetWriteResult.Written, commit(store.beginCurrentWeatherWrite(saved)!!))
        assertEquals(WidgetWriteResult.Written, commitForecast(store.beginForecastWrite(saved)!!))
        val path = context.getDatabasePath(WidgetStore.DATABASE_NAME)
        SQLiteDatabase.openDatabase(path.path, null, SQLiteDatabase.OPEN_READWRITE).use {
            it.execSQL("DROP TABLE widget_refresh_feedback")
            it.version = 3
        }
        val upgraded = WidgetStore.openUncached(context)
        assertEquals(snapshot().observationTime, upgraded.readCurrentWeather(saved)?.snapshot?.observationTime)
        assertEquals(9_000L, upgraded.readForecast(saved)?.expiresAtMilliseconds)
        assertEquals(saved, upgraded.readInstance(11)?.address)
        assertTrue(upgraded.beginRefreshFeedback(saved, "after-upgrade", 1_000L))
    }

    private fun commit(token: WidgetWriteToken, observation: Long = 1_791_454_316) =
        store.commitCurrentWeather(token, snapshot(observation), writtenAt = 1L)

    private fun forecast(regionCode: String = "407", updateTime: Long = 1_000) = ForecastSnapshot(
        schemaVersion = 1,
        sourceIdentifier = "region:407",
        regionCode = regionCode,
        updateTime = updateTime,
        receivedAt = 2_000,
        points = listOf(ForecastPoint("15:00", 27.0, "多雲", 200, 20)),
    )

    /** Commits a forecast the way the refresh does: metadata fixed at commit. */
    private fun commitForecast(
        token: WidgetWriteToken,
        regionCode: String = "407",
        updateTime: Long = 1_000,
        receivedCalibrated: Long = 5_000,
        expiresAt: Long = 9_000,
    ) = store.commitForecast(
        token = token,
        forecast = forecast(regionCode, updateTime),
        receivedCalibratedMilliseconds = receivedCalibrated,
        expiresAtMilliseconds = expiresAt,
        writtenAt = 1L,
    )

    private fun catalog(vararg codes: String) = codes.map {
        WidgetCatalogLocation.create(it, "第${it}區", "縣", 24.0, 120.0)!!
    }

    // ── Ordering ────────────────────────────────────────────────────────────

    @Test
    fun `a later request carrying an older observation is superseded`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))

        val first = store.beginCurrentWeatherWrite(saved)!!
        assertEquals(WidgetWriteResult.Written, commit(first, observation = 1_791_454_400))

        val second = store.beginCurrentWeatherWrite(saved)!!
        assertEquals(
            WidgetWriteResult.Superseded,
            commit(second, observation = 1_791_454_300),
        )

        assertEquals(
            1_791_454_400L,
            store.readCurrentWeather(saved)!!.snapshot.observationTime,
        )
    }

    @Test
    fun `the snapshot round-trips every field`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        commit(store.beginCurrentWeatherWrite(saved)!!)

        val stored = store.readCurrentWeather(saved)!!
        val value = stored.snapshot
        assertEquals(7, value.schemaVersion)
        assertEquals("西屯", value.stationName)
        assertEquals(206, value.weatherCode)
        assertEquals(WeatherCondition.Rain, value.condition)
        assertEquals(-1_200L, value.calibratedTimeOffsetMilliseconds)
        assertEquals(27.5, value.temperature!!, 1e-9)
        assertEquals(78, value.humidity!!.toLong())
        assertEquals(0.4, value.rain!!, 1e-9)
        assertEquals("北北西", value.windDirection)
        assertEquals(1.3, value.windSpeed!!, 1e-9)
        assertEquals(30.2, value.apparentTemperature!!, 1e-9)
    }

    // ── Clear ───────────────────────────────────────────────────────────────

    @Test
    fun `a clear fences a refresh already in flight`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        val token = store.beginCurrentWeatherWrite(saved)!!

        assertTrue(store.clearCurrentWeather())

        // The refresh finishes after the clear and must not resurrect anything.
        assertEquals(WidgetWriteResult.Superseded, commit(token))
        assertNull(store.readCurrentWeather(saved))
    }

    @Test
    fun `a clear keeps the instance choices and the catalog`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        assertTrue(store.writeInstance(11, saved, "407", 1L))

        assertTrue(store.clearCurrentWeather())

        assertNotNull(store.readInstance(11))
        assertEquals(1, store.readCatalog()!!.locations.size)
    }

    @Test
    fun `a town leaving the catalog fences its in-flight write`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        val token = store.beginCurrentWeatherWrite(saved)!!

        assertTrue(store.writeCatalog(catalog("100"), 2L))

        assertEquals(WidgetWriteResult.Superseded, commit(token))
    }

    // ── Instances ───────────────────────────────────────────────────────────

    @Test
    fun `reconfiguring one of two instances on a source does not fence it`() {
        assertTrue(store.writeCatalog(catalog("407", "100"), 1L))
        assertTrue(store.writeInstance(11, saved, "407", 1L))
        assertTrue(store.writeInstance(12, saved, "407", 1L))

        // A refresh for the shared source is already in flight.
        val token = store.beginCurrentWeatherWrite(saved)!!

        // Instance 11 moves to another town while 12 stays, so the source is
        // still in use and the in-flight write must still be accepted.
        assertTrue(store.writeInstance(11, WidgetAddress.Saved("100"), "100", 2L))

        assertEquals(WidgetWriteResult.Written, commit(token))
    }

    @Test
    fun `reconfiguring the last instance on a source fences it`() {
        assertTrue(store.writeCatalog(catalog("407", "100"), 1L))
        assertTrue(store.writeInstance(11, saved, "407", 1L))

        // The refresh for the town being left is in flight when the user moves
        // the only instance away from it: its result must not land.
        val token = store.beginCurrentWeatherWrite(saved)!!
        assertTrue(store.writeInstance(11, WidgetAddress.Saved("100"), "100", 2L))

        assertEquals(WidgetWriteResult.Superseded, commit(token))
    }

    @Test
    fun `deleting one of two instances on a source does not fence it`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        assertTrue(store.writeInstance(11, saved, "407", 1L))
        assertTrue(store.writeInstance(12, saved, "407", 1L))

        val token = store.beginCurrentWeatherWrite(saved)!!
        assertTrue(store.deleteInstance(11))

        assertEquals(WidgetWriteResult.Written, commit(token))
    }

    @Test
    fun `a restore moves the choice and leaves no ghost`() {
        assertTrue(store.writeInstance(11, saved, "407", 1L))

        assertTrue(store.remapInstance(11, 22))

        assertNull(store.readInstance(11))
        assertEquals(saved, store.readInstance(22)!!.address)
        assertEquals(listOf(saved), store.usedAddresses())
    }

    @Test
    fun `reconcile drops rows the launcher no longer has`() {
        assertTrue(store.writeCatalog(catalog("407", "100"), 1L))
        assertTrue(store.writeInstance(11, saved, "407", 1L))
        assertTrue(store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L))

        assertEquals(1, store.reconcileInstances(setOf(12)))

        assertNull(store.readInstance(11))
        assertNotNull(store.readInstance(12))
        assertEquals(listOf(WidgetAddress.Saved("100")), store.usedAddresses())
    }

    @Test
    fun `reconcile fences a source whose last instance was dropped`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        assertTrue(store.writeInstance(11, saved, "407", 1L))
        val token = store.beginCurrentWeatherWrite(saved)!!

        assertEquals(1, store.reconcileInstances(emptySet()))

        assertEquals(WidgetWriteResult.Superseded, commit(token))
    }

    // ── Location state ──────────────────────────────────────────────────────

    @Test
    fun `every degradation round-trips`() {
        for (degradation in WidgetLocationDegradation.entries) {
            assertTrue(store.writeLocationState(WidgetAddress.CurrentLocation, degradation, 1L, 1L))
            assertEquals(degradation, store.readLocationState(WidgetAddress.CurrentLocation))
        }
    }

    @Test
    fun `an older acquisition cannot put a degradation back after a newer success`() {
        val address = WidgetAddress.CurrentLocation
        // The newer refresh succeeded and cleared the state at generation 7.
        assertTrue(store.writeLocationState(address, null, 7L, 7L))

        // The older refresh, which timed out, finishes afterwards.
        assertTrue(store.writeLocationState(address, WidgetLocationDegradation.UnusableFix, 5L, 8L))

        assertNull("the older timeout must not win", store.readLocationState(address))
    }

    @Test
    fun `an older success cannot clear a newer revocation`() {
        val address = WidgetAddress.CurrentLocation
        // The user revoked the permission; a refresh at generation 8 recorded it.
        assertTrue(
            store.writeLocationState(address, WidgetLocationDegradation.Permission, 8L, 8L),
        )

        // A refresh that had already obtained a fix, issued at generation 6,
        // commits its success now.
        assertTrue(store.writeLocationState(address, null, 6L, 9L))

        assertEquals(
            "the newer revocation must survive the older success",
            WidgetLocationDegradation.Permission,
            store.readLocationState(address),
        )
    }

    @Test
    fun `the two directions hold when the writes actually overlap`() {
        val address = WidgetAddress.CurrentLocation
        val newer = CountDownLatch(1)
        val older = CountDownLatch(1)

        // The older refresh is parked just before it writes its timeout, while a
        // newer one succeeds. The store serialises its methods, so whichever
        // order they arrive in, the newer generation must win.
        val olderThread = Thread {
            older.countDown()
            try {
                newer.await(5, TimeUnit.SECONDS)
            } catch (_: InterruptedException) {
                return@Thread
            }
            store.writeLocationState(address, WidgetLocationDegradation.UnusableFix, 5L, 5L)
        }
        olderThread.start()
        assertTrue(older.await(5, TimeUnit.SECONDS))

        assertTrue(store.writeLocationState(address, null, 7L, 7L))
        newer.countDown()
        olderThread.join(5_000)

        assertNull(
            "a timeout that finished after a newer success must not surface",
            store.readLocationState(address),
        )

        // And the mirror, with the roles swapped: a newer revocation must
        // survive an older success that lands afterwards.
        val successThread = Thread {
            try {
                newer.await(5, TimeUnit.SECONDS)
            } catch (_: InterruptedException) {
                return@Thread
            }
            store.writeLocationState(address, null, 6L, 9L)
        }
        assertTrue(store.writeLocationState(address, WidgetLocationDegradation.Permission, 8L, 8L))
        successThread.start()
        successThread.join(5_000)

        assertEquals(
            "an older success must not clear a newer revocation",
            WidgetLocationDegradation.Permission,
            store.readLocationState(address),
        )
    }

    @Test
    fun `a same-generation write is last-writer-wins`() {
        val address = WidgetAddress.CurrentLocation
        assertTrue(store.writeLocationState(address, WidgetLocationDegradation.Permission, 4L, 4L))
        assertTrue(store.writeLocationState(address, null, 4L, 5L))
        assertNull(store.readLocationState(address))
    }

    @Test
    fun `the generation is remembered even when the state is fine`() {
        val address = WidgetAddress.CurrentLocation
        assertTrue(store.writeLocationState(address, null, 9L, 9L))
        assertEquals(9L, store.readLocationStateGeneration(address))
    }

    @Test
    fun `the forecast demand survives until it is answered`() {
        val address = WidgetAddress.CurrentLocation
        assertFalse(store.hasForecastDemand(address))

        assertTrue(store.setForecastDemand(address, demand = true, updatedAt = 1L))
        assertTrue(store.hasForecastDemand(address))

        // A position write must not clear the demand: they share a row but are
        // different facts.
        assertTrue(
            store.writeLocationState(address, WidgetLocationDegradation.Permission, 3L, 2L),
        )
        assertTrue(store.hasForecastDemand(address))

        assertTrue(store.setForecastDemand(address, demand = false, updatedAt = 3L))
        assertFalse(store.hasForecastDemand(address))
    }

    @Test
    fun `a demand clear is ignored when a newer demand was raised meanwhile`() {
        val address = WidgetAddress.CurrentLocation
        assertTrue(store.setForecastDemand(address, demand = true, updatedAt = 1L))
        assertEquals(1L, store.readForecastDemandVersion(address))

        // The fetch reads the version it is answering, then a resize raises a new
        // demand while it is in flight.
        assertTrue(store.setForecastDemand(address, demand = true, updatedAt = 2L))
        assertEquals(2L, store.readForecastDemandVersion(address))

        // The fetch's commit names version 1, which no longer matches. The data
        // still lands — it is a real forecast — but the demand is left raised, so
        // the next run fetches for the demand it never answered.
        assertEquals(
            WidgetWriteResult.Written,
            store.commitForecast(
                token = store.beginForecastWrite(address)!!,
                forecast = forecast(),
                receivedCalibratedMilliseconds = 1L,
                expiresAtMilliseconds = 2L,
                writtenAt = 1L,
                answeredDemandVersion = 1L,
            ),
        )
        assertTrue(
            "the newer demand must survive the older fetch",
            store.hasForecastDemand(address),
        )

        // Answering the current version clears it, in the same transaction.
        assertEquals(
            WidgetWriteResult.Written,
            store.commitForecast(
                token = store.beginForecastWrite(address)!!,
                forecast = forecast(updateTime = 2_000),
                receivedCalibratedMilliseconds = 1L,
                expiresAtMilliseconds = 2L,
                writtenAt = 1L,
                answeredDemandVersion = 2L,
            ),
        )
        assertFalse(store.hasForecastDemand(address))
    }

    @Test
    fun `one refresh reserves both tickets in one transaction`() {
        val address = WidgetAddress.CurrentLocation

        val tokens = store.beginRefreshWrites(address, includeForecast = true)!!
        assertEquals(1L, tokens.currentWeather.generation)
        assertEquals(1L, tokens.forecast!!.generation)

        // A second refresh gets the next pair, still one apart per kind.
        val second = store.beginRefreshWrites(address, includeForecast = true)!!
        assertEquals(2L, second.currentWeather.generation)
        assertEquals(2L, second.forecast!!.generation)

        // Without a forecast there is no forecast ticket at all — and no
        // forecast counter moved.
        val third = store.beginRefreshWrites(address, includeForecast = false)!!
        assertNull(third.forecast)
        assertEquals(3L, third.currentWeather.generation)
        // Two forecast tickets have been issued so far, so the next is the
        // third — the counter only ever moves forward.
        assertEquals(
            3L,
            store.beginRefreshWrites(address, includeForecast = true)!!.forecast!!.generation,
        )
    }

    @Test
    fun `a clear after the pair is reserved fences the forecast too`() {
        val address = WidgetAddress.CurrentLocation
        val tokens = store.beginRefreshWrites(address, includeForecast = true)!!

        assertTrue(store.clearForecast())

        assertEquals(
            WidgetWriteResult.Superseded,
            store.commitForecast(
                token = tokens.forecast!!,
                forecast = forecast(),
                receivedCalibratedMilliseconds = 1L,
                expiresAtMilliseconds = 2L,
                writtenAt = 1L,
            ),
        )
        assertNull(store.readForecast(address))
    }

    @Test
    fun `a commit that lands may clear the degradation`() {
        val address = WidgetAddress.CurrentLocation
        assertTrue(store.writeLocationState(address, WidgetLocationDegradation.Permission, 1L, 1L))

        val token = store.beginCurrentWeatherWrite(address)!!
        assertEquals(
            WidgetWriteResult.Written,
            store.commitCurrentWeather(
                token = token,
                snapshot = snapshot(source = "current-location"),
                writtenAt = 1L,
                locationStateAfterCommit = LocationStateWrite.Set(null),
            ),
        )
        assertNull(store.readLocationState(address))
    }

    @Test
    fun `a superseded commit cannot clear the degradation`() {
        val address = WidgetAddress.CurrentLocation
        assertTrue(store.writeLocationState(address, WidgetLocationDegradation.Permission, 1L, 1L))

        val first = store.beginCurrentWeatherWrite(address)!!
        store.commitCurrentWeather(
            first,
            snapshot(source = "current-location", observationSeconds = 2_000),
            writtenAt = 1L,
        )

        // A second, older acquisition is superseded; its commit must not touch
        // the degradation, because the observation it belongs to never landed.
        val second = store.beginCurrentWeatherWrite(address)!!
        assertEquals(
            WidgetWriteResult.Superseded,
            store.commitCurrentWeather(
                token = second,
                snapshot = snapshot(source = "current-location", observationSeconds = 1_000),
                writtenAt = 1L,
                locationStateAfterCommit = LocationStateWrite.Set(null),
            ),
        )
        assertEquals(
            WidgetLocationDegradation.Permission,
            store.readLocationState(address),
        )
    }

    // ── Forecast ────────────────────────────────────────────────────────────

    @Test
    fun `a forecast is not filed against another township`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        commit(store.beginCurrentWeatherWrite(saved)!!)

        val token = store.beginForecastWrite(saved)!!
        assertEquals(
            WidgetWriteResult.Superseded,
            commitForecast(token, regionCode = "100"),
        )
        assertNull(store.readForecast(saved))
    }

    @Test
    fun `a forecast round-trips its points in order`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        commit(store.beginCurrentWeatherWrite(saved)!!)

        val token = store.beginForecastWrite(saved)!!
        assertEquals(
            WidgetWriteResult.Written,
            store.commitForecast(
                token = token,
                forecast = ForecastSnapshot(
                    schemaVersion = 1,
                    sourceIdentifier = "region:407",
                    regionCode = "407",
                    updateTime = 1_000,
                    receivedAt = 2_000,
                    points = listOf(
                        ForecastPoint("15:00", 27.0, "多雲", 200, 20),
                        ForecastPoint("16:00", 26.0, "多雲有雨", 206, null),
                    ),
                ),
                receivedCalibratedMilliseconds = 5_000,
                expiresAtMilliseconds = 9_000,
                writtenAt = 1L,
            ),
        )

        val stored = store.readForecast(saved)!!
        assertEquals(listOf("15:00", "16:00"), stored.points.map { it.time })
        assertEquals(20, stored.points[0].pop!!.toLong())
        assertNull(stored.points[1].pop)
        // The calibrated instants the commit recorded are what comes back.
        assertEquals(5_000L, stored.receivedCalibratedMilliseconds)
        assertEquals(9_000L, stored.expiresAtMilliseconds)
    }

    @Test
    fun `clearing the forecast removes the points with it`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        commit(store.beginCurrentWeatherWrite(saved)!!)
        commitForecast(store.beginForecastWrite(saved)!!)

        assertTrue(store.clearForecast())

        assertNull(store.readForecast(saved))
    }

    // ── Failures ────────────────────────────────────────────────────────────

    @Test
    fun `a broken database is a failure, not a quiet rejection`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        val token = store.beginCurrentWeatherWrite(saved)!!

        // Break the cache table underneath the store, the way a corrupt or
        // half-migrated file would.
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path,
            null,
            SQLiteDatabase.OPEN_READWRITE,
        ).use { it.execSQL("DROP TABLE widget_snapshots") }

        assertEquals(WidgetWriteResult.Failed, commit(token))
    }

    @Test
    fun `a broken database is logged with its operation and error class, and no coordinates`() {
        val recorded = ArrayList<String>()
        WidgetLog.overrideSink = { _ -> RecordingLog(recorded) }

        assertTrue(store.writeCatalog(catalog("407"), 1L))
        val token = store.beginCurrentWeatherWrite(saved)!!
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path,
            null,
            SQLiteDatabase.OPEN_READWRITE,
        ).use { it.execSQL("DROP TABLE widget_snapshots") }

        assertEquals(WidgetWriteResult.Failed, commit(token))

        assertTrue(
            "expected the operation in $recorded",
            recorded.any { it.contains("operation=currentWeather") },
        )
        assertTrue(
            "expected the exception class in $recorded",
            recorded.any { it.contains("error=SQLite") },
        )
        // A diagnostic must not become a location record.
        assertTrue(
            "coordinates leaked into $recorded",
            recorded.none { it.contains("120.6") || it.contains("24.18") },
        )
    }

    // ── Migration ───────────────────────────────────────────────────────────

    @Test
    fun `an upgrade from the previous schema keeps the choices and migrates the flag`() {
        // The schema the previous build shipped: no degradation/generation on the
        // source state, and no calibrated receipt or deadline on the forecast.
        val path = context.getDatabasePath(WidgetStore.DATABASE_NAME)
        path.parentFile?.mkdirs()
        val legacy = SQLiteDatabase.openOrCreateDatabase(path, null)
        legacy.execSQL(
            "CREATE TABLE widget_instances (app_widget_id INTEGER PRIMARY KEY," +
                "source_identifier TEXT NOT NULL, region_code TEXT, updated_at INTEGER NOT NULL)",
        )
        legacy.execSQL(
            "CREATE TABLE widget_catalog (region_code TEXT PRIMARY KEY, display_name TEXT NOT NULL," +
                "administrative_area TEXT NOT NULL, latitude REAL NOT NULL, longitude REAL NOT NULL)",
        )
        legacy.execSQL(
            "CREATE TABLE widget_meta (id INTEGER PRIMARY KEY, schema_version INTEGER NOT NULL," +
                "written_at INTEGER NOT NULL)",
        )
        legacy.execSQL(
            "CREATE TABLE widget_source_state (source_identifier TEXT PRIMARY KEY," +
                "needs_app INTEGER NOT NULL, updated_at INTEGER NOT NULL)",
        )
        legacy.execSQL(
            "CREATE TABLE widget_forecasts (source_identifier TEXT PRIMARY KEY," +
                "schema_version INTEGER NOT NULL, region_code TEXT NOT NULL," +
                "update_time INTEGER NOT NULL, received_at INTEGER NOT NULL," +
                "write_generation INTEGER NOT NULL, written_at INTEGER NOT NULL)",
        )
        legacy.execSQL(
            "CREATE TABLE widget_forecast_points (source_identifier TEXT NOT NULL," +
                "position INTEGER NOT NULL, time_label TEXT NOT NULL, temperature REAL NOT NULL," +
                "weather TEXT NOT NULL, weather_code INTEGER NOT NULL, pop INTEGER," +
                "PRIMARY KEY (source_identifier, position))",
        )
        legacy.execSQL(
            "CREATE TABLE widget_snapshots (source_identifier TEXT PRIMARY KEY," +
                "schema_version INTEGER NOT NULL, region_code TEXT NOT NULL," +
                "observation_time INTEGER NOT NULL, write_generation INTEGER NOT NULL," +
                "location_generation INTEGER NOT NULL, written_at INTEGER NOT NULL)",
        )
        legacy.execSQL("INSERT INTO widget_instances VALUES (11, 'current-location', NULL, 5)")
        legacy.execSQL("INSERT INTO widget_catalog VALUES ('407', '西屯區', '臺中市', 24.181, 120.645)")
        legacy.execSQL("INSERT INTO widget_meta VALUES (1, 1, 5)")
        legacy.execSQL("INSERT INTO widget_source_state VALUES ('current-location', 1, 5)")
        legacy.execSQL(
            "INSERT INTO widget_forecasts VALUES ('current-location', 1, '407', 1000, 2000, 1, 1)",
        )
        legacy.version = 2
        legacy.close()

        val upgraded = WidgetStore.openUncached(context)

        // What the user chose is not the schema's to discard.
        assertEquals(WidgetAddress.CurrentLocation, upgraded.readInstance(11)!!.address)
        assertEquals(1, upgraded.readCatalog()!!.locations.size)
        // The old boolean meant "the position needs the app"; it survives as the
        // reason that flag existed rather than being dropped.
        assertEquals(
            WidgetLocationDegradation.Permission,
            upgraded.readLocationState(WidgetAddress.CurrentLocation),
        )
        // The forecast cache had no deadline and is not readable by this build,
        // so it is gone — and the table accepts the new shape.
        assertNull(upgraded.readForecast(WidgetAddress.CurrentLocation))
        assertTrue(upgraded.setForecastDemand(WidgetAddress.CurrentLocation, true, 9L))
        assertEquals(
            WidgetWriteResult.Written,
            upgraded.commitForecast(
                token = upgraded.beginForecastWrite(WidgetAddress.CurrentLocation)!!,
                forecast = forecast(),
                receivedCalibratedMilliseconds = 1L,
                expiresAtMilliseconds = 2L,
                writtenAt = 1L,
            ),
        )
    }

    @Test
    fun `a source-scoped clear leaves the other towns alone`() {
        assertTrue(store.writeCatalog(catalog("407", "100"), 1L))
        val saved100 = WidgetAddress.Saved("100")
        commit(store.beginCurrentWeatherWrite(saved)!!)
        store.commitCurrentWeather(
            store.beginCurrentWeatherWrite(saved100)!!,
            snapshot(regionCode = "100", source = "region:100"),
            writtenAt = 1L,
        )

        // The app owns region:407 and changes town: only that source goes.
        assertTrue(store.clearCurrentWeatherSource(saved))

        assertNull(store.readCurrentWeather(saved))
        assertNotNull(
            "the other Widget's town must survive an app-side selection change",
            store.readCurrentWeather(saved100),
        )
    }

    @Test
    fun `an upgrade rebuilds the cache and keeps the user's choices`() {
        // A version-1 database, as an installed app would have left it: the
        // durable tables plus the old cache shape.
        val path = context.getDatabasePath(WidgetStore.DATABASE_NAME)
        path.parentFile?.mkdirs()
        val legacy = SQLiteDatabase.openOrCreateDatabase(path, null)
        legacy.execSQL(
            "CREATE TABLE widget_instances (app_widget_id INTEGER PRIMARY KEY," +
                "source_identifier TEXT NOT NULL, region_code TEXT, updated_at INTEGER NOT NULL)",
        )
        legacy.execSQL(
            "CREATE TABLE widget_catalog (region_code TEXT PRIMARY KEY, display_name TEXT NOT NULL," +
                "administrative_area TEXT NOT NULL, latitude REAL NOT NULL, longitude REAL NOT NULL)",
        )
        legacy.execSQL(
            "CREATE TABLE widget_meta (id INTEGER PRIMARY KEY, schema_version INTEGER NOT NULL," +
                "written_at INTEGER NOT NULL)",
        )
        legacy.execSQL(
            "CREATE TABLE widget_snapshots (source_identifier TEXT PRIMARY KEY, json TEXT NOT NULL," +
                "schema_version INTEGER NOT NULL, region_code TEXT NOT NULL," +
                "observation_time INTEGER NOT NULL, write_generation INTEGER NOT NULL," +
                "location_generation INTEGER NOT NULL, written_at INTEGER NOT NULL)",
        )
        legacy.execSQL(
            "CREATE TABLE widget_source_state (source_identifier TEXT PRIMARY KEY," +
                "needs_app INTEGER NOT NULL, updated_at INTEGER NOT NULL)",
        )
        legacy.execSQL("INSERT INTO widget_instances VALUES (11, 'region:407', '407', 5)")
        legacy.execSQL("INSERT INTO widget_catalog VALUES ('407', '西屯區', '臺中市', 24.181, 120.645)")
        legacy.execSQL("INSERT INTO widget_meta VALUES (1, 1, 5)")
        legacy.execSQL("INSERT INTO widget_snapshots VALUES ('region:407', '{}', 1, '407', 1, 1, 1, 1)")
        legacy.version = 1
        legacy.close()

        // Opening through the store runs onUpgrade to version 2.
        val upgraded = WidgetStore.openUncached(context)

        val instance = upgraded.readInstance(11)
        assertNotNull("the instance choice must survive an upgrade", instance)
        assertEquals(saved, instance!!.address)
        assertEquals(1, upgraded.readCatalog()!!.locations.size)
        // The v1 cache row is gone, and the table is the new shape.
        assertNull(upgraded.readCurrentWeather(saved))
        // And the rebuilt table accepts a write.
        assertEquals(
            WidgetWriteResult.Written,
            commit(upgraded.beginCurrentWeatherWrite(saved)!!),
        )
    }
}
