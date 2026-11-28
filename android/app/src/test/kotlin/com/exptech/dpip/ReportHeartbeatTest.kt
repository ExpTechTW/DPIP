package com.exptech.dpip

import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import androidx.work.ListenableWorker
import androidx.work.NetworkType
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.testing.WorkManagerTestInitHelper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import kotlin.random.Random
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

/**
 * The report heartbeat: one report from a device that has had no successful
 * report for [ReportHeartbeat.QUIET_MS] plus its jitter, in every mode, from
 * what is stored — never a fix — and never through the real network here.
 */
@RunWith(RobolectricTestRunner::class)
class ReportHeartbeatTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()

    /** Every URL a test sent, answered by [answer]. */
    private val sent = mutableListOf<String>()
    private var answer: (String) -> Int = { 204 }
    private lateinit var realTransport: BgLocationStore.Transport

    private val jitter = 5L * 60 * 60 * 1000
    private val threshold = ReportHeartbeat.QUIET_MS + jitter
    private val t0 = 1_700_000_000_000L

    @Before
    fun setUp() {
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
        realTransport = BgLocationStore.transport
        BgLocationStore.transport = BgLocationStore.Transport { url ->
            sent += url
            answer(url)
        }
    }

    @After
    fun tearDown() {
        BgLocationStore.transport = realTransport
        WorkManager.getInstance(context).cancelAllWork()
    }

    private fun record(at: Long = t0, lat: Double = 25.0478, lng: Double = 121.5319) =
        BgLocationStore.Reported(at, lat, lng)

    /** A device that reported once at [t0] and knows what to send as. */
    private fun reportedDevice(jitterMs: Long = jitter) {
        BgLocationStore.saveIdentity(context, "tok", "1.2.3", 0)
        BgLocationStore.recordReported(context, t0, 25.0478, 121.5319)
        BgLocationStore.prefs(context).edit().putLong("heartbeat_jitter_ms", jitterMs).apply()
    }

    // ---- the due rule ----

    @Test
    fun `no record at all has nothing to send`() {
        val decision = ReportHeartbeat.decide(t0, null, jitter, manual = null)
        assertTrue(decision is ReportHeartbeat.Decision.Skip)

        // In manual mode too: a pinned point is not a record.
        val manual = ReportHeartbeat.Point(23.97, 121.6)
        assertTrue(
            ReportHeartbeat.decide(t0, null, jitter, manual) is ReportHeartbeat.Decision.Skip,
        )
    }

    @Test
    fun `due only once the last success is older than three days plus the jitter`() {
        val last = record()
        fun at(age: Long) = ReportHeartbeat.decide(t0 + age, last, jitter, manual = null)

        assertTrue(at(threshold - 1) is ReportHeartbeat.Decision.Skip)
        assertTrue(at(threshold) is ReportHeartbeat.Decision.Skip)
        assertTrue(at(threshold + 1) is ReportHeartbeat.Decision.Send)
        // The jitter is part of the threshold, not a decoration on it.
        assertTrue(
            ReportHeartbeat.decide(t0 + threshold + 1, last, jitter + 2, null)
                is ReportHeartbeat.Decision.Skip,
        )
    }

    @Test
    fun `a last success stamped in the future is due rather than held off`() {
        val decision = ReportHeartbeat.decide(t0, record(at = t0 + 60_000L), jitter, null)
        assertTrue(decision is ReportHeartbeat.Decision.Send)
    }

    @Test
    fun `the jitter is drawn once, inside a day, and never redrawn`() {
        val first = ReportHeartbeat.jitterMs(context, Random(1))
        assertTrue(first in 0 until ReportHeartbeat.JITTER_RANGE_MS)
        repeat(3) { seed ->
            assertEquals(first, ReportHeartbeat.jitterMs(context, Random(seed + 100)))
        }
    }

    // ---- the point ----

    @Test
    fun `sends the pinned township point while one is pinned, else the last reported`() {
        val last = record()
        val manual = ReportHeartbeat.Point(23.97, 121.6)
        val now = t0 + threshold + 1

        val pinned = ReportHeartbeat.decide(now, last, jitter, manual)
        assertEquals(manual, (pinned as ReportHeartbeat.Decision.Send).point)

        val auto = ReportHeartbeat.decide(now, last, jitter, null)
        assertEquals(
            ReportHeartbeat.Point(last.lat, last.lng),
            (auto as ReportHeartbeat.Decision.Send).point,
        )
    }

    @Test
    fun `a run resends exactly the stored point, and the cleared pin falls back`() {
        reportedDevice()
        ReportHeartbeat.setManualPoint(context, 23.97, 121.6)
        ReportHeartbeat.run(context, t0 + threshold + 1)
        assertEquals(
            listOf("https://api.core-tnn1.exptech.dev/api/v2/location/0/tok/1.2.3/23.97,121.6"),
            sent,
        )

        // Back to automatic, and quiet again: what the last success sent is
        // what goes out.
        ReportHeartbeat.clearManualPoint(context)
        BgLocationStore.recordReported(context, t0, 25.0478, 121.5319)
        sent.clear()
        ReportHeartbeat.run(context, t0 + threshold + 2 * 60_000L)
        assertEquals(
            listOf("https://api.core-tnn1.exptech.dev/api/v2/location/0/tok/1.2.3/25.0478,121.5319"),
            sent,
        )
    }

    // ---- what a run does with the answer ----

    @Test
    fun `a 2xx updates the record with the time and the point it sent`() {
        reportedDevice()
        ReportHeartbeat.setManualPoint(context, 23.97, 121.6)
        val now = t0 + threshold + 1

        val outcome = ReportHeartbeat.run(context, now)

        assertTrue(outcome, outcome.contains("sent (204)"))
        assertEquals(BgLocationStore.Reported(now, 23.97, 121.6), BgLocationStore.reported(context))
        // Fresh again: the next daily run sends nothing.
        sent.clear()
        ReportHeartbeat.run(context, now + 24L * 60 * 60 * 1000)
        assertTrue(sent.isEmpty())
    }

    @Test
    fun `a 429 leaves the record alone, so the next run retries`() {
        reportedDevice()
        answer = { 429 }
        val now = t0 + threshold + 1

        val outcome = ReportHeartbeat.run(context, now)

        assertTrue(outcome, outcome.contains("failed (429)"))
        assertEquals(record(), BgLocationStore.reported(context))

        answer = { 204 }
        ReportHeartbeat.run(context, now + 24L * 60 * 60 * 1000)
        assertEquals(2, sent.size)
    }

    @Test
    fun `a request that never got an answer leaves the record alone`() {
        reportedDevice()
        answer = { throw IOException("offline") }

        val outcome = ReportHeartbeat.run(context, t0 + threshold + 1)

        assertTrue(outcome, outcome.contains("failed (no answer)"))
        assertEquals(record(), BgLocationStore.reported(context))
        val crumbs = BgLocationStore.drainBreadcrumbs(context).joinToString("\n")
        assertTrue(crumbs, crumbs.contains("heartbeat failed: IOException"))
        assertTrue(crumbs, crumbs.contains("heartbeat: due"))
    }

    @Test
    fun `every run leaves a trace, sent or not`() {
        ReportHeartbeat.run(context, t0)
        reportedDevice()
        ReportHeartbeat.run(context, t0 + 1)

        val crumbs = BgLocationStore.drainBreadcrumbs(context)
        assertEquals(2, crumbs.size)
        assertTrue(crumbs[0], crumbs[0].endsWith("heartbeat: no successful report yet"))
        assertTrue(crumbs[1], crumbs[1].contains("heartbeat: not due"))
        assertTrue(sent.isEmpty())
        val diagnostics = ReportHeartbeat.diagnostics(context)
        assertEquals(t0 + 1, diagnostics["heartbeatLastRunAt"])
        assertEquals(t0 + threshold, diagnostics["heartbeatDueAt"])
    }

    @Test
    fun `no push token means no request and no change`() {
        BgLocationStore.recordReported(context, t0, 25.0478, 121.5319)

        val outcome = ReportHeartbeat.run(context, t0 + 5L * 24 * 60 * 60 * 1000)

        assertTrue(outcome, outcome.contains("no push token"))
        assertTrue(sent.isEmpty())
        assertEquals(t0, BgLocationStore.reported(context)?.at)
    }

    @Test
    fun `a report inside the last minute holds the heartbeat off`() {
        reportedDevice()
        val now = t0 + threshold + 1
        BgLocationStore.prefs(context).edit()
            .putLong(BgLocationStore.KEY_LAST_SENT_AT, now - 30_000L)
            .apply()

        val outcome = ReportHeartbeat.run(context, now)

        assertTrue(outcome, outcome.contains("inside the last minute"))
        assertTrue(sent.isEmpty())
    }

    // ---- every path's 2xx counts ----

    @Test
    fun `the background path's 2xx updates the record, its failures do not`() {
        BgLocationStore.saveConfig(context, "tok", "1.2.3", 0)
        answer = { 500 }
        BgLocationStore.report(context, 24.1, 120.7)
        assertNull(BgLocationStore.reported(context))

        BgLocationStore.prefs(context).edit().remove(BgLocationStore.KEY_LAST_SENT_AT).apply()
        answer = { 204 }
        val before = System.currentTimeMillis()
        BgLocationStore.report(context, 24.1, 120.7)
        val reported = BgLocationStore.reported(context)
        assertNotNull(reported)
        assertEquals(24.1, reported!!.lat, 0.0)
        assertEquals(120.7, reported.lng, 0.0)
        assertTrue(reported.at >= before)
    }

    @Test
    fun `Dart's foreground 2xx reaches the record through the channel`() {
        val result = CapturingResult()
        val before = System.currentTimeMillis()
        channel().onMethodCall(
            MethodCall("recordReport", mapOf("lat" to 22.99, "lng" to 120.2)),
            result,
        )
        assertTrue(result.succeeded)
        val reported = BgLocationStore.reported(context)!!
        assertEquals(22.99, reported.lat, 0.0)
        assertEquals(120.2, reported.lng, 0.0)
        assertTrue(reported.at >= before)
    }

    // ---- the channel contract, and `stop` ----

    @Test
    fun `the identity Dart hands over enables nothing, and a new token still re-reports on start`() {
        BgLocationStore.saveConfig(context, "old", "1.2.3", 0)
        val result = CapturingResult()
        channel().onMethodCall(
            MethodCall(
                "setReportIdentity",
                mapOf("platform" to 0, "token" to "new", "version" to "1.2.3"),
            ),
            result,
        )
        assertTrue(result.succeeded)
        assertEquals("new", BgLocationStore.prefs(context).getString(BgLocationStore.KEY_TOKEN, null))
        // `start(new)` must still see a changed config, or the background
        // path would never report the new token by itself.
        assertFalse(BgLocationStore.configMatches(context, "new", "1.2.3", 0))
        assertTrue(BgLocationStore.configMatches(context, "old", "1.2.3", 0))

        BgLocationStore.disable(context)
        channel().onMethodCall(
            MethodCall(
                "setReportIdentity",
                mapOf("platform" to 0, "token" to "newer", "version" to "1.2.3"),
            ),
            CapturingResult(),
        )
        assertFalse(BgLocationStore.enabled(context))
    }

    @Test
    fun `a device that predates the started-with marker matches on its stored identity`() {
        BgLocationStore.prefs(context).edit()
            .putBoolean(BgLocationStore.KEY_ENABLED, true)
            .putString(BgLocationStore.KEY_TOKEN, "tok")
            .putString(BgLocationStore.KEY_VERSION, "1.2.3")
            .putInt(BgLocationStore.KEY_PLATFORM, 0)
            .apply()
        assertTrue(BgLocationStore.configMatches(context, "tok", "1.2.3", 0))
        assertFalse(BgLocationStore.configMatches(context, "tok", "1.2.4", 0))
    }

    @Test
    fun `bad arguments are refused`() {
        val result = CapturingResult()
        channel().onMethodCall(MethodCall("setManualPoint", mapOf("lat" to 1.0)), result)
        assertEquals("bad_args", result.errorCode)
        assertNull(ReportHeartbeat.manualPoint(context))
    }

    @Test
    fun `a reboot or an app update arms the job, with background reporting off too`() {
        // Manual mode, or a device that never enabled background reporting.
        assertFalse(BgLocationStore.enabled(context))
        assertTrue(heartbeatWork().isEmpty())

        LocationBootReceiver().onReceive(
            context,
            Intent(Intent.ACTION_MY_PACKAGE_REPLACED),
        )
        val armed = heartbeatWork().single()
        assertEquals(WorkInfo.State.ENQUEUED, armed.state)

        // A reboot keeps the same job rather than queueing a second one.
        LocationBootReceiver().onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))
        assertEquals(armed.id, heartbeatWork().single().id)
    }

    @Test
    fun `an unrelated broadcast arms nothing`() {
        LocationBootReceiver().onReceive(context, Intent("com.example.SOMETHING"))
        assertTrue(heartbeatWork().isEmpty())
    }

    @Test
    fun `the job is unique, waits for a network, and survives stop with everything it needs`() {
        ReportHeartbeat.ensure(context)
        val first = heartbeatWork().single()
        ReportHeartbeat.ensure(context)
        ReportHeartbeat.ensure(context)
        val kept = heartbeatWork().single()
        assertEquals(first.id, kept.id)
        assertEquals(WorkInfo.State.ENQUEUED, kept.state)
        assertEquals(NetworkType.CONNECTED, kept.constraints.requiredNetworkType)
        assertNotNull(kept.periodicityInfo)

        // Manual mode: Dart stops background reporting, after handing over
        // the identity and the pinned point.
        reportedDevice()
        val pin = CapturingResult()
        channel().onMethodCall(
            MethodCall("setManualPoint", mapOf("lat" to 23.97, "lng" to 121.6)),
            pin,
        )
        assertTrue(pin.succeeded)
        val stop = CapturingResult()
        channel().onMethodCall(MethodCall("stop", null), stop)
        assertTrue(stop.succeeded)

        assertEquals(first.id, heartbeatWork().single { !it.state.isFinished }.id)
        val outcome = ReportHeartbeat.run(context, t0 + threshold + 1)
        assertTrue(outcome, outcome.contains("sent (204)"))
        assertEquals(
            listOf("https://api.core-tnn1.exptech.dev/api/v2/location/0/tok/1.2.3/23.97,121.6"),
            sent,
        )
    }

    @Test
    fun `the worker always succeeds, because the next run is the retry`() {
        reportedDevice()
        answer = { 429 }
        BgLocationStore.recordReported(context, 1L, 25.0478, 121.5319)
        val worker = TestListenableWorkerBuilder<ReportHeartbeatWorker>(context).build()

        assertEquals(ListenableWorker.Result.success(), worker.doWork())
        assertEquals(1, sent.size)
        assertEquals(1L, BgLocationStore.reported(context)?.at)
    }

    private fun heartbeatWork(): List<WorkInfo> =
        WorkManager.getInstance(context)
            .getWorkInfosForUniqueWork(ReportHeartbeat.UNIQUE_WORK)
            .get()

    private fun channel() = BackgroundLocationChannel(context)

    private class CapturingResult : MethodChannel.Result {
        var succeeded = false
        var errorCode: String? = null

        override fun success(result: Any?) {
            succeeded = true
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            this.errorCode = errorCode
        }

        override fun notImplemented() {
            errorCode = "notImplemented"
        }
    }
}
