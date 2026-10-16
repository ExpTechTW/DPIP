package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.os.Bundle
import android.os.Looper
import android.os.SystemClock
import androidx.test.core.app.ApplicationProvider
import androidx.work.WorkManager
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.testing.WorkManagerTestInitHelper
import androidx.work.workDataOf
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * The Flutter boundary, driven the way the platform drives it.
 *
 * The mapping this pins is the one that used to be missing: a *storage* failure
 * came back to Dart as a rejected ordering — indistinguishable from losing a
 * race — so the app was told a write had succeeded when the database had not
 * written anything.
 */
@RunWith(RobolectricTestRunner::class)
class WidgetSnapshotChannelTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private lateinit var store: WidgetStore
    private lateinit var channel: WidgetSnapshotChannel

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        WidgetLog.resetForTest()
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
        store = WidgetStore.open(context)
        store.writeCatalog(
            listOf(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!),
            1L,
        )
        channel = WidgetSnapshotChannel(context)
    }

    @After
    fun tearDown() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        WidgetUpdater.resetOptionsProvider()
        WidgetClock.invalidate()
        WidgetLog.resetForTest()
    }

    /** A result that records what the platform channel was told. */
    private class RecordingResult : MethodChannel.Result {
        val done = CountDownLatch(1)
        var successValue: Any? = null
        var errorCode: String? = null
        var notImplemented = false

        override fun success(result: Any?) {
            successValue = result
            done.countDown()
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            this.errorCode = errorCode
            done.countDown()
        }

        override fun notImplemented() {
            notImplemented = true
            done.countDown()
        }

        /** The reply is posted to the main looper, which Robolectric holds. */
        fun await(timeoutMilliseconds: Long = 5_000): RecordingResult {
            val deadline = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(timeoutMilliseconds)
            while (done.count != 0L) {
                shadowOf(Looper.getMainLooper()).idle()
                if (done.count == 0L) break
                val remaining = deadline - System.nanoTime()
                assertTrue("platform channel did not reply within ${timeoutMilliseconds}ms", remaining > 0)
                done.await(minOf(remaining, TimeUnit.MILLISECONDS.toNanos(20)), TimeUnit.NANOSECONDS)
            }
            shadowOf(Looper.getMainLooper()).idle()
            return this
        }
    }

    @Test(timeout = 2_000)
    fun `an unanswered platform reply fails at a bounded total deadline`() {
        val failure = assertThrows(AssertionError::class.java) {
            RecordingResult().await(timeoutMilliseconds = 10)
        }
        assertTrue(failure.message!!.contains("platform channel did not reply"))
    }

    private fun write(
        kind: String?,
        json: String?,
        sourceIdentifier: String? = null,
    ) = RecordingResult().also { result ->
        channel.onMethodCall(
            MethodCall(
                "write",
                mapOf(
                    "kind" to kind,
                    "json" to json,
                    "sourceIdentifier" to sourceIdentifier,
                ),
            ),
            result,
        )
    }.await()

    private fun clear(kind: String?, sourceIdentifier: String? = null) =
        RecordingResult().also { result ->
            channel.onMethodCall(
                MethodCall(
                    "clear",
                    mapOf("kind" to kind, "sourceIdentifier" to sourceIdentifier),
                ),
                result,
            )
        }.await()

    private fun payload(observationTime: Long = 1_791_454_316) =
        """
        {"schemaVersion":7,"sourceIdentifier":"region:407","regionCode":"407",
         "regionName":"西屯區","observationTime":$observationTime,"stationName":"西屯",
         "weather":"多雲有雨","weatherCode":206,"condition":"rain","isNight":false,
         "nextDayNightTransitionTime":1791470400,"calibratedTimeOffsetMilliseconds":-1200,
         "temperature":27.5,"humidity":78,"rain":0.4,"windDirection":"北北西","windSpeed":1.3,
         "apparentTemperature":30.2}
        """.trimIndent()

    @Test
    fun `a valid payload is written and the instance redrawn`() {
        val result = write("currentWeather", payload(), "region:407")

        assertNull(result.errorCode)
        assertNotNull(store.readCurrentWeather(WidgetAddress.Saved("407")))
    }

    @Test
    fun `an unknown kind is refused by name`() {
        assertEquals("invalid_kind", write("somethingElse", "{}").errorCode)
        assertEquals("invalid_kind", clear("somethingElse").errorCode)
    }

    @Test
    fun `a payload this build cannot read is refused`() {
        // Wrong schema version.
        val wrongVersion = payload().replace("\"schemaVersion\":7", "\"schemaVersion\":8")
        assertEquals("invalid_payload", write("currentWeather", wrongVersion, "region:407").errorCode)

        // Not JSON at all.
        assertEquals("invalid_payload", write("currentWeather", "not json", "region:407").errorCode)

        // A source that does not match the payload it claims to describe.
        assertEquals(
            "invalid_payload",
            write("currentWeather", payload(), "region:100").errorCode,
        )
    }

    @Test
    fun `a source the payload disagrees with is refused`() {
        val mismatched = payload().replace("\"regionCode\":\"407\"", "\"regionCode\":\"100\"")
        assertEquals(
            "invalid_payload",
            write("currentWeather", mismatched, "region:407").errorCode,
        )
    }

    @Test
    fun `a storage failure reaches Dart as a failure, not as a lost race`() {
        // Break the cache table underneath the store, the way a corrupt or
        // half-migrated file would.
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path,
            null,
            SQLiteDatabase.OPEN_READWRITE,
        ).use { it.execSQL("DROP TABLE widget_snapshots") }

        val result = write("currentWeather", payload(), "region:407")

        assertEquals("write_failed", result.errorCode)
    }

    @Test
    fun `a superseded write is reported to Dart as success`() {
        write("currentWeather", payload(observationTime = 1_791_454_400), "region:407")

        // Older observation through the same boundary: the device's own fetched
        // snapshot already won the ordering race, which is normal and not
        // something the app can act on.
        val result = write("currentWeather", payload(observationTime = 1_791_454_300), "region:407")

        assertNull(result.errorCode)
        assertEquals(
            1_791_454_400L,
            store.readCurrentWeather(WidgetAddress.Saved("407"))!!.snapshot.observationTime,
        )
    }

    @Test
    fun `the catalog kind replaces the catalog`() {
        val json = """
            {"schemaVersion":1,"locations":[
              {"regionCode":"100","displayName":"中正區","administrativeAreaName":"臺北市",
               "latitude":25.032188,"longitude":121.5183226}]}
        """.trimIndent()

        assertNull(write("locationCatalog", json).errorCode)

        val catalog = store.readCatalog()!!
        assertEquals(listOf("100"), catalog.locations.map { it.regionCode })
    }

    @Test
    fun `clearing a kind empties it and reports success`() {
        write("currentWeather", payload(), "region:407")

        assertNull(clear("currentWeather").errorCode)
        assertNull(store.readCurrentWeather(WidgetAddress.Saved("407")))
    }

    @Test
    fun `a source-scoped clear of current weather leaves the other sources`() {
        write("currentWeather", payload(), "region:407")
        write("currentWeather", currentLocationPayload(1_791_454_316), "current-location")

        assertNull(clear("currentWeather", "region:407").errorCode)

        assertNull("the named source is gone", store.readCurrentWeather(WidgetAddress.Saved("407")))
        assertNotNull(
            "the other source must survive its neighbour's clear",
            store.readCurrentWeather(WidgetAddress.CurrentLocation),
        )
    }

    @Test
    fun `a source on a forecast clear is refused and clears nothing`() {
        write("currentWeather", payload(), "region:407")
        seedForecast(WidgetAddress.Saved("407"))
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        val result = clear("weatherForecast", "region:407")

        assertEquals("invalid_payload", result.errorCode)
        assertNotNull(
            "the forecast must survive a scoped clear it does not support",
            store.readForecast(WidgetAddress.Saved("407")),
        )
        assertNotNull(store.readCurrentWeather(WidgetAddress.Saved("407")))
        assertNotNull(store.readCatalog())
        assertNotNull(store.readInstance(11))
    }

    @Test
    fun `a source on a catalog clear is refused and keeps the catalog`() {
        write("currentWeather", payload(), "region:407")
        seedForecast(WidgetAddress.Saved("407"))
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        val result = clear("locationCatalog", "region:407")

        assertEquals("invalid_payload", result.errorCode)
        assertEquals(
            listOf("407"),
            store.readCatalog()!!.locations.map { it.regionCode },
        )
        assertNotNull(store.readCurrentWeather(WidgetAddress.Saved("407")))
        assertNotNull(store.readForecast(WidgetAddress.Saved("407")))
        assertNotNull(store.readInstance(11))
    }

    @Test
    fun `a malformed clear leaves every kind intact`() {
        write("currentWeather", payload(), "region:407")
        seedForecast(WidgetAddress.Saved("407"))
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        // An unknown kind never had a scope to begin with.
        assertEquals("invalid_kind", clear("somethingElse").errorCode)
        // A source that is not a valid address on the one kind that takes one.
        assertEquals("invalid_payload", clear("currentWeather", "region:../").errorCode)

        assertNotNull(store.readCurrentWeather(WidgetAddress.Saved("407")))
        assertNotNull(store.readForecast(WidgetAddress.Saved("407")))
        assertNotNull(store.readCatalog())
        assertNotNull(store.readInstance(11))
    }

    @Test
    fun `clearing the forecast without a source still clears it`() {
        seedForecast(WidgetAddress.Saved("407"))
        assertNotNull(store.readForecast(WidgetAddress.Saved("407")))

        assertNull(clear("weatherForecast").errorCode)

        assertNull(store.readForecast(WidgetAddress.Saved("407")))
    }

    @Test
    fun `clearing the catalog without a source still empties it`() {
        assertNotNull(store.readCatalog())

        assertNull(clear("locationCatalog").errorCode)

        assertTrue(store.readCatalog()!!.locations.isEmpty())
    }

    @Test
    fun `a write for a source no widget shows is cached but not fetched`() {
        // The app publishes for its own selected region; often no Widget on the
        // home screen shows it. The snapshot is still worth caching, but a fetch
        // would spend a location fix, a clock exchange and HTTP on nothing.
        val result = write("currentWeather", payload(), "region:407")

        assertNull(result.errorCode)
        assertNotNull(store.readCurrentWeather(WidgetAddress.Saved("407")))
        assertEquals(
            0,
            WorkManager.getInstance(context)
                .getWorkInfosForUniqueWork(
                    WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")),
                )
                .get()
                .size,
        )
    }

    @Test
    fun `a write for a source a widget shows does fetch`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        assertNull(write("currentWeather", payload(), "region:407").errorCode)

        val work = WorkManager.getInstance(context)
            .getWorkInfosForUniqueWork(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
            .get()
        assertEquals(1, work.size)
    }

    @Test
    fun `an unknown method is not implemented`() {
        val result = RecordingResult()
        channel.onMethodCall(MethodCall("somethingElse", null), result)
        assertTrue(result.await().notImplemented)
    }

    @Test
    fun `an app-published snapshot stays fresh when the headless fix is denied`() {
        // The full chain, end to end: the app publishes through the platform
        // channel; the headless refresh cannot get a background fix; the
        // production presentation must still show the observation as fresh with a
        // position notice — not as outdated for ever, which is what happened while
        // the clock was only calibrated after a successful fix.
        store.writeInstance(11, WidgetAddress.CurrentLocation, null, 1L)
        WidgetClock.invalidate()

        assertNull(
            write(
                "currentWeather",
                currentLocationPayload(atTaipei(14, 10) / 1_000),
                "current-location",
            ).errorCode,
        )

        WeatherWidgetRefreshWorker.refresher =
            { context, address, includeForecast, demandVersion, isCancelled ->
                WidgetRefreshService(
                    context = context,
                    store = store,
                    resolveAddress = {
                        LocationResolution.Degraded(WidgetLocationDegradation.Permission)
                    },
                    synchronizeClock = {
                        WidgetClock.installForTest(
                            atTaipei(14, 20),
                            SystemClock.elapsedRealtime(),
                        )
                        true
                    },
                    snapshotTime = { WidgetSnapshotTime(atTaipei(14, 20), 0) },
                    fetchWeather = { _, _ -> null },
                    fetchForecast = { throw WidgetHttpException("no network") },
                    nowMilliseconds = { 1L },
                ).refresh(address, includeForecast, demandVersion, isCancelled)
            }
        try {
            TestListenableWorkerBuilder<WeatherWidgetRefreshWorker>(context)
                .setInputData(
                    workDataOf(
                        WeatherWidgetRefreshWorker.KEY_LOCAL_ONLY to false,
                        WeatherWidgetRefreshWorker.KEY_SOURCE to "current-location",
                    ),
                )
                .build()
                .startWork()
                .get()
        } finally {
            WeatherWidgetRefreshWorker.resetRefresher()
        }

        WidgetUpdater.optionsProvider = { _, id ->
            Bundle().apply {
                if (id == 11) {
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
                }
            }
        }
        try {
            val presentation = WidgetUpdater.presentation(context, 11, 110, 110)
            assertFalse(
                "a fresh app observation must not be shown as outdated",
                presentation.isStale,
            )
            assertEquals(WidgetDisplayState.NeedsApp, presentation.state)
            assertEquals(WidgetUpdater.strings(context).needsApp, presentation.badgeText)
            assertNotNull("the observation time must still be drawn", presentation.observationTimeMillis)
        } finally {
            WidgetUpdater.resetOptionsProvider()
        }
    }

    private fun atTaipei(hour: Int, minute: Int): Long =
        LocalDateTime.of(2026, 10, 12, hour, minute)
            .toInstant(ZoneOffset.ofHours(8))
            .toEpochMilli()

    private fun currentLocationPayload(observationTime: Long) =
        """
        {"schemaVersion":7,"sourceIdentifier":"current-location","regionCode":"407",
         "regionName":"西屯區","observationTime":$observationTime,"stationName":"西屯",
         "weather":"多雲有雨","weatherCode":206,"condition":"rain","isNight":false,
         "nextDayNightTransitionTime":0,"calibratedTimeOffsetMilliseconds":0,
         "temperature":27.5,"humidity":78,"rain":0.4,"windDirection":"北北西","windSpeed":1.3,
         "apparentTemperature":30.2}
        """.trimIndent()

    /** Seeds a committed forecast directly, the way a refresh leaves one. */
    private fun seedForecast(address: WidgetAddress) {
        val regionCode = (address as WidgetAddress.Saved).regionCode
        val token = store.beginForecastWrite(address)!!
        store.commitForecast(
            token = token,
            forecast = ForecastSnapshot(
                schemaVersion = 1,
                sourceIdentifier = address.sourceIdentifier,
                regionCode = regionCode,
                updateTime = 1_000L,
                receivedAt = 2_000L,
                points = listOf(ForecastPoint("15:00", 27.0, "多雲", 200, 20)),
            ),
            receivedCalibratedMilliseconds = 5_000L,
            expiresAtMilliseconds = 9_000L,
            writtenAt = 1L,
        )
    }
}
