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
import java.util.concurrent.FutureTask
import java.util.concurrent.TimeUnit
import org.robolectric.RobolectricTestRunner

/**
 * The store's real SQL, on Robolectric's SQLite.
 *
 * The ordering *rule* is pinned by `SnapshotOrderingTest` as a pure function;
 * what this covers is everything the rule cannot see — that the acquisition
 * counter survives a transaction and a new connection, that a removed town
 * refuses a late write, that a restore leaves no ghost, that an upgrade keeps
 * the user's choices and their last observation, and that a broken database
 * reports a *failure* rather than a quiet rejection.
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

    @Test
    fun `authority reads distinguish an empty instance table from an unavailable one`() {
        assertEquals(WidgetInstanceReadResult.Read(emptyList()), store.readInstancesResult())
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path, null, SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL("ALTER TABLE widget_instances RENAME TO unavailable_instances")
            try {
                assertEquals(WidgetInstanceReadResult.Failed, store.readInstancesResult())
                assertEquals(WidgetInstanceReadResult.Failed, store.reconcileInstances(emptySet()))
            } finally {
                database.execSQL("ALTER TABLE unavailable_instances RENAME TO widget_instances")
            }
        }
        assertEquals(WidgetInstanceReadResult.Read(emptyList()), store.readInstancesResult())
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
    fun `the v5 upgrade keeps v4 observations, positions and choices`() {
        // The v4 schema, as the previous build left it: the snapshot table's
        // shape is unchanged, the rest of the cache is not.
        val path = context.getDatabasePath(WidgetStore.DATABASE_NAME)
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        path.parentFile?.mkdirs()
        SQLiteDatabase.openOrCreateDatabase(path, null).use { legacy ->
            legacy.execSQL("CREATE TABLE widget_instances (app_widget_id INTEGER PRIMARY KEY, source_identifier TEXT NOT NULL, region_code TEXT, updated_at INTEGER NOT NULL)")
            legacy.execSQL("CREATE TABLE widget_catalog (region_code TEXT PRIMARY KEY, display_name TEXT NOT NULL, administrative_area TEXT NOT NULL, latitude REAL NOT NULL, longitude REAL NOT NULL)")
            legacy.execSQL("CREATE TABLE widget_meta (id INTEGER PRIMARY KEY, schema_version INTEGER NOT NULL, written_at INTEGER NOT NULL)")
            legacy.execSQL(
                "CREATE TABLE widget_snapshots (source_identifier TEXT PRIMARY KEY, schema_version INTEGER NOT NULL," +
                    " region_code TEXT NOT NULL, region_name TEXT NOT NULL, observation_time INTEGER NOT NULL," +
                    " station_name TEXT NOT NULL, weather TEXT NOT NULL, weather_code INTEGER NOT NULL," +
                    " condition TEXT NOT NULL, is_night INTEGER NOT NULL, next_transition INTEGER NOT NULL," +
                    " calibrated_offset INTEGER NOT NULL, temperature REAL, humidity INTEGER, rain REAL," +
                    " wind_direction TEXT, wind_speed REAL, apparent_temperature REAL," +
                    " write_generation INTEGER NOT NULL, location_generation INTEGER NOT NULL, written_at INTEGER NOT NULL)",
            )
            legacy.execSQL(
                "CREATE TABLE widget_source_state (source_identifier TEXT PRIMARY KEY, degradation TEXT," +
                    " generation INTEGER NOT NULL, forecast_demand INTEGER NOT NULL," +
                    " forecast_demand_version INTEGER NOT NULL, updated_at INTEGER NOT NULL)",
            )
            legacy.execSQL("CREATE TABLE widget_ordering (kind TEXT NOT NULL, source_identifier TEXT NOT NULL, last_issued INTEGER NOT NULL, rejected_through INTEGER NOT NULL, snapshot_generation INTEGER, location_generation INTEGER, value_time INTEGER, region_code TEXT, PRIMARY KEY (kind, source_identifier))")
            legacy.execSQL("CREATE TABLE widget_refresh_feedback (source_identifier TEXT PRIMARY KEY, request_id TEXT NOT NULL, state TEXT NOT NULL, updated_at INTEGER NOT NULL, expires_at INTEGER NOT NULL)")
            legacy.execSQL("INSERT INTO widget_instances VALUES (11, 'current-location', NULL, 5)")
            legacy.execSQL("INSERT INTO widget_catalog VALUES ('407', '西屯區', '臺中市', 24.181, 120.645)")
            legacy.execSQL("INSERT INTO widget_meta VALUES (1, 1, 5)")
            legacy.execSQL(
                "INSERT INTO widget_snapshots VALUES ('current-location', 7, '407', '西屯區', 1791454316, '西屯'," +
                    " '晴', 100, 'clear', 0, 0, 0, 27.5, 60, 0.0, NULL, NULL, NULL, 57, 57, 1)",
            )
            legacy.execSQL("INSERT INTO widget_source_state VALUES ('current-location', 'unusable_fix', 57, 1, 3, 1)")
            legacy.version = 4
        }

        val upgraded = WidgetStore.openUncached(context)

        assertEquals(WidgetAddress.CurrentLocation, upgraded.readInstance(11)?.address)
        assertEquals(1, upgraded.readCatalog()!!.locations.size)
        assertEquals("an update must not blank the Widget", 1_791_454_316L,
            upgraded.readCurrentWeather(WidgetAddress.CurrentLocation)?.snapshot?.observationTime)
        assertEquals(WidgetLocationDegradation.UnusableFix, upgraded.readLocationState(WidgetAddress.CurrentLocation))
        // The rebuilt counter restarts at one, and the kept row was reset with
        // it: a township change after the update is not refused by generation
        // 57 from the counter that no longer exists.
        assertEquals(1L, upgraded.beginAcquisition(WidgetAddress.CurrentLocation))
        assertEquals(
            WidgetWriteResult.Written,
            upgraded.commitCurrentWeather(
                snapshot(source = "current-location", regionCode = "100", observationSeconds = 1_791_454_000),
                writtenAt = 2L,
            ),
        )
        assertTrue(upgraded.beginRefreshFeedback(WidgetAddress.CurrentLocation, "after-upgrade", 1_000L))
    }

    private fun commit(observation: Long = 1_791_454_316, target: WidgetStore = store) =
        target.commitCurrentWeather(snapshot(observation), writtenAt = 1L)

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
        regionCode: String = "407",
        updateTime: Long = 1_000,
        receivedCalibrated: Long = 5_000,
        expiresAt: Long = 9_000,
    ) = store.commitForecast(
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

        assertEquals(WidgetWriteResult.Written, commit(observation = 1_791_454_400))
        assertEquals(WidgetWriteResult.Superseded, commit(observation = 1_791_454_300))

        assertEquals(
            1_791_454_400L,
            store.readCurrentWeather(saved)!!.snapshot.observationTime,
        )
    }

    @Test
    fun `the snapshot round-trips every field`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        commit()

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

    @Test
    fun `a town leaving the catalog refuses a late write`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        val acquisition = store.beginAcquisition(saved)!!

        assertTrue(store.writeCatalog(catalog("100"), 2L))

        assertEquals(
            WidgetWriteResult.Superseded,
            store.commitCurrentWeather(snapshot(), writtenAt = 1L, acquisition = acquisition),
        )
        assertNull(store.readCurrentWeather(saved))
    }

    @Test
    fun `acquisitions count up per source and survive a new connection`() {
        assertEquals(1L, store.beginAcquisition(saved))
        assertEquals(2L, store.beginAcquisition(saved))
        assertEquals(1L, store.beginAcquisition(WidgetAddress.CurrentLocation))
        assertEquals(3L, WidgetStore.openUncached(context).beginAcquisition(saved))
    }

    @Test
    fun `a refresh time round-trips per source`() {
        assertNull(store.readRefreshedAt(saved))
        assertTrue(store.markRefreshed(saved, 1_000L))
        assertEquals(1_000L, store.readRefreshedAt(saved))
        assertNull(store.readRefreshedAt(WidgetAddress.CurrentLocation))
        // A position write shares the row without touching the refresh time.
        assertTrue(store.writeLocationState(saved, WidgetLocationDegradation.Unavailable, 2_000L))
        assertEquals(1_000L, store.readRefreshedAt(saved))
    }

    // ── Instances ───────────────────────────────────────────────────────────

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

        assertEquals(1, (store.reconcileInstances(setOf(12)) as WidgetInstanceReadResult.Read).dropped.size)

        assertNull(store.readInstance(11))
        assertNotNull(store.readInstance(12))
        assertEquals(listOf(WidgetAddress.Saved("100")), store.usedAddresses())
    }

    @Test
    fun `every degradation round-trips`() {
        for (degradation in WidgetLocationDegradation.entries) {
            assertTrue(store.writeLocationState(WidgetAddress.CurrentLocation, degradation, 1L))
            assertEquals(degradation, store.readLocationState(WidgetAddress.CurrentLocation))
        }
    }

    @Test
    fun `a commit that lands may clear the degradation`() {
        val address = WidgetAddress.CurrentLocation
        assertTrue(store.writeLocationState(address, WidgetLocationDegradation.Permission, 1L))

        assertEquals(
            WidgetWriteResult.Written,
            store.commitCurrentWeather(
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
        assertTrue(store.writeLocationState(address, WidgetLocationDegradation.Permission, 1L))

        store.commitCurrentWeather(
            snapshot(source = "current-location", observationSeconds = 2_000),
            writtenAt = 1L,
        )

        // A second, older acquisition is superseded; its commit must not touch
        // the degradation, because the observation it belongs to never landed.
        assertEquals(
            WidgetWriteResult.Superseded,
            store.commitCurrentWeather(
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
        commit()

        assertEquals(
            WidgetWriteResult.Superseded,
            commitForecast(regionCode = "100"),
        )
        assertNull(store.readForecast(saved))
    }

    @Test
    fun `a forecast round-trips its points in order`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        commit()

        assertEquals(
            WidgetWriteResult.Written,
            store.commitForecast(
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
    fun `a broken database is a failure, not a quiet rejection`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))

        // Break the cache table underneath the store, the way a corrupt or
        // half-migrated file would.
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path,
            null,
            SQLiteDatabase.OPEN_READWRITE,
        ).use { it.execSQL("DROP TABLE widget_snapshots") }

        assertEquals(WidgetWriteResult.Failed, commit())
    }

    @Test
    fun `a broken database is logged with its operation and error class, and no coordinates`() {
        val recorded = ArrayList<String>()
        WidgetLog.overrideSink = { _ -> RecordingLog(recorded) }

        assertTrue(store.writeCatalog(catalog("407"), 1L))
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path,
            null,
            SQLiteDatabase.OPEN_READWRITE,
        ).use { it.execSQL("DROP TABLE widget_snapshots") }

        assertEquals(WidgetWriteResult.Failed, commit())

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
        assertEquals(
            WidgetWriteResult.Written,
            upgraded.commitForecast(
                forecast = forecast().copy(sourceIdentifier = "current-location"),
                receivedCalibratedMilliseconds = 1L,
                expiresAtMilliseconds = 2L,
                writtenAt = 1L,
            ),
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
            commit(target = upgraded),
        )
    }

    // ── Catalog lookups ─────────────────────────────────────────────────────

    @Test
    fun `a catalog lookup distinguishes a deleted town from an unreadable table`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        assertEquals(
            WidgetCatalogLookup.Found(catalog("407").single()),
            store.lookupCatalogLocation("407"),
        )
        // A town the user never saved, on a catalog that read fine.
        assertEquals(WidgetCatalogLookup.Absent, store.lookupCatalogLocation("100"))

        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path,
            null,
            SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL("ALTER TABLE widget_catalog RENAME TO unavailable_catalog")
            try {
                // The read did not happen. Answering `Absent` here is what made a
                // transient SQLite error render a still-saved town as Reconfigure.
                assertEquals(WidgetCatalogLookup.Failed, store.lookupCatalogLocation("407"))
                assertNull(store.findCatalogLocation("407"))
            } finally {
                database.execSQL("ALTER TABLE unavailable_catalog RENAME TO widget_catalog")
            }
        }

        assertEquals(
            WidgetCatalogLookup.Found(catalog("407").single()),
            store.lookupCatalogLocation("407"),
        )
    }


    // ── Next-hour rain ──────────────────────────────────────────────────────

    @Test
    fun `a rain trend round-trips per township and is replaced whole`() {
        val wet = RainHourTrend(1_791_454_200, List(60) { it * 0.5 })
        assertTrue(store.commitRainTrend("407", wet, writtenAt = 1L))
        assertEquals(StoredRainTrend("407", wet), store.readRainTrend("407"))
        assertNull(store.readRainTrend("100"))

        val dry = RainHourTrend(1_791_454_800, List(60) { 0.0 })
        assertTrue(store.commitRainTrend("407", dry, writtenAt = 2L))
        assertEquals(dry, store.readRainTrend("407")!!.trend)
    }

    @Test
    fun `the v6 upgrade only adds the rain cache`() {
        assertTrue(store.writeCatalog(catalog("407"), 1L))
        store.writeInstance(11, saved, "407", 1L)
        assertEquals(WidgetWriteResult.Written, commit())
        assertEquals(WidgetWriteResult.Written, commitForecast())
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path, null, SQLiteDatabase.OPEN_READWRITE,
        ).use {
            it.execSQL("DROP TABLE widget_rain_trends")
            it.version = 5
        }

        val upgraded = WidgetStore.openUncached(context)

        assertEquals(snapshot().observationTime, upgraded.readCurrentWeather(saved)?.snapshot?.observationTime)
        assertEquals(9_000L, upgraded.readForecast(saved)?.expiresAtMilliseconds)
        assertEquals(saved, upgraded.readInstance(11)?.address)
        assertTrue(upgraded.commitRainTrend("407", RainHourTrend(60, List(60) { 1.0 }), writtenAt = 1L))
    }
}
