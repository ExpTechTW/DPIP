package com.exptech.dpip.widget

import android.content.Context
import android.content.SharedPreferences
import android.os.SystemClock
import android.provider.Settings
import androidx.core.content.edit
import java.io.BufferedReader
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/** A calibrated instant together with the device→server correction it implies. */
data class WidgetSnapshotTime(
    val calibratedNowUnixMilliseconds: Long,
    val calibratedTimeOffsetMilliseconds: Long,
)

/** A server instant and the monotonic (`elapsedRealtime`) reading it was taken at. */
data class ClockAnchor(
    val serverMilliseconds: Long,
    val monotonicMilliseconds: Long,
)

/**
 * A server anchor and the two clocks it is measured against.
 *
 * Pure, so the one property that matters is testable without a socket: once
 * [install] has taken a **server instant** and a **monotonic reading**, every
 * later question is answered from monotonic time plus that instant. Changing the
 * device's date or timezone therefore cannot move it — only a new
 * synchronization can — which is what stops a clock change from making an old
 * observation look fresh or reviving an expired forecast.
 *
 * The wall clock is still consulted, but only for [offsetMilliseconds], which
 * converts a calibrated instant back into *the device clock as it is now*. That
 * is a derived value, re-measured on every call, so a jumped clock corrects
 * itself instead of being baked in.
 */
class CalibratedClock(
    private val wallMilliseconds: () -> Long,
    private val monotonicMilliseconds: () -> Long,
) {
    // Publish both readings together: separate volatile fields can mix two syncs.
    @Volatile
    private var anchor: ClockAnchor? = null

    val hasAnchor: Boolean
        get() = anchor != null

    /** Milliseconds since the anchor was taken, or null when there is none. */
    fun anchorAgeMilliseconds(): Long? {
        val current = anchor ?: return null
        return monotonicMilliseconds() - current.monotonicMilliseconds
    }

    /** The anchor as it stands, so it can be kept across process death. */
    fun anchor(): ClockAnchor? = anchor

    fun install(serverUnixMilliseconds: Long): ClockAnchor =
        ClockAnchor(serverUnixMilliseconds, monotonicMilliseconds()).also { anchor = it }

    /**
     * Anchors at an explicit monotonic reading.
     *
     * Only a test needs this: it lets a test pin "the anchor was taken 30
     * seconds ago" without making the fake monotonic source stateful.
     */
    internal fun installAt(serverUnixMilliseconds: Long, monotonicMilliseconds: Long) {
        anchor = ClockAnchor(serverUnixMilliseconds, monotonicMilliseconds)
    }

    fun invalidate() {
        anchor = null
    }

    /**
     * The trusted calibrated instant, or null before any synchronization.
     *
     * A null is the point: device time is not a server time, and a caller that
     * gets null must not decide that an observation is fresh.
     */
    fun calibratedNowMilliseconds(): Long? {
        val current = anchor ?: return null
        return current.serverMilliseconds + (monotonicMilliseconds() - current.monotonicMilliseconds)
    }

    /** Calibrated minus device wall clock, or null when unanchored. */
    fun offsetMilliseconds(): Long? =
        calibratedNowMilliseconds()?.let { it - wallMilliseconds() }

    /**
     * The instant to publish, read in one evaluation.
     *
     * The instant and the offset have to describe the same moment: taken in two
     * calls they could straddle a wall-clock change and disagree by exactly the
     * jump this class exists to absorb.
     */
    fun snapshotTime(): WidgetSnapshotTime? {
        val current = anchor ?: return null
        val wall = wallMilliseconds()
        val calibrated = current.serverMilliseconds + (monotonicMilliseconds() - current.monotonicMilliseconds)
        return WidgetSnapshotTime(calibrated, calibrated - wall)
    }

    /** A calibrated deadline as a reading of the device clock right now. */
    fun deviceMillisecondsFor(calibratedMilliseconds: Long): Long? =
        offsetMilliseconds()?.let { calibratedMilliseconds - it }
}

/**
 * The Widget's calibrated clock: SNTP first, a verified HTTPS reading second.
 *
 * This mirrors `WidgetServerClock` / `WidgetSNTPClient` / `WidgetHTTPTimeSource`
 * in the iOS Widget Extension, and for the same reasons. The anchor lives in
 * [CalibratedClock]; the policy — the NTP packet arithmetic and the acceptance
 * rule for an HTTPS reading — lives in [NtpPacket] and [HttpTimeValidation] as
 * pure functions. This object owns only the sockets and the ordering of the two
 * sources.
 *
 * The order is precision, not preference. RFC 5905 resolves "now" to about a
 * millisecond; one HTTPS round trip only to ±RTT/2. The HTTP stage exists for
 * corporate, hotel and campus networks that block UDP/123, where the
 * alternative is no calibration at all — but it is reached only when every SNTP
 * host has failed.
 */
object WidgetClock {
    private const val ntpPort = 123
    private const val sntpHostTimeoutMilliseconds = 3_000
    private const val httpHostTimeoutMilliseconds = 2_000

    /** An anchor younger than this is reused rather than re-fetched. */
    private const val resynchronizeAfterMilliseconds = 60_000L

    private val sntpHosts = listOf("time.exptech.com.tw", "time.apple.com")
    private val httpHosts = listOf("api.lb.exptech.dev")

    private val clock = CalibratedClock(
        wallMilliseconds = { System.currentTimeMillis() },
        monotonicMilliseconds = { SystemClock.elapsedRealtime() },
    )

    val hasSynchronized: Boolean get() = clock.hasAnchor

    /** Where the anchor outlives this process; null until [attach]. */
    @Volatile
    private var anchors: ClockAnchorStore? = null

    /**
     * Connects the clock to its persisted anchor, and restores it when this
     * process has none of its own.
     *
     * Called at every entry point that reads calibrated time (a render, the
     * redraw scheduler, a refresh), because any of them can be the first thing
     * a freshly started process does. Cheap: the preferences file is cached by
     * the platform after its first read.
     */
    fun attach(context: Context) {
        val store = ClockAnchorStore.of(context)
        anchors = store
        if (clock.hasAnchor) return
        store.read(SystemClock.elapsedRealtime())?.let {
            clock.installAt(it.serverMilliseconds, it.monotonicMilliseconds)
        }
    }

    fun calibratedNowMilliseconds(): Long? = clock.calibratedNowMilliseconds()

    fun offsetMilliseconds(): Long? = clock.offsetMilliseconds()

    fun deviceMillisecondsFor(calibratedMilliseconds: Long): Long? =
        clock.deviceMillisecondsFor(calibratedMilliseconds)

    fun snapshotTime(): WidgetSnapshotTime? = clock.snapshotTime()

    /** Drops the anchor, here and on disk. */
    fun invalidate() {
        clock.invalidate()
        anchors?.clear()
    }

    /**
     * Anchors the clock without a network exchange.
     *
     * For tests that need "a synchronized process" — the property being tested
     * is what the code does *with* an anchor, not how the anchor was obtained.
     * [persist] also writes it where the next process would find it.
     */
    internal fun installForTest(serverUnixMilliseconds: Long, monotonicMilliseconds: Long, persist: Boolean = false) {
        clock.installAt(serverUnixMilliseconds, monotonicMilliseconds)
        if (persist) anchors?.write(ClockAnchor(serverUnixMilliseconds, monotonicMilliseconds))
    }

    /** What process death does: the in-memory anchor is gone, the persisted one is not. */
    internal fun forgetForTest() {
        clock.invalidate()
        anchors = null
    }

    /**
     * Synchronizes the clock, blocking up to roughly ten seconds.
     *
     * Never throws: a failure is "no new calibration", and an anchor from an
     * earlier success — this process's own or one restored by [attach] — is
     * still monotonic and still valid, so the refresh goes on with it. What
     * must not happen is inventing one: `calibratedNowMilliseconds()` returns
     * null until an anchor exists at all. Mirrors iOS, where `hasSynchronized`
     * outlives a failed `synchronize()`.
     *
     * An anchor younger than [resynchronizeAfterMilliseconds] is reused. One
     * worker run refreshes several addresses, and without this each would spend
     * up to ten seconds on its own UDP exchange for a reading that cannot have
     * moved; Dart's realtime service resyncs on the same 60-second cadence.
     */
    @Synchronized
    fun synchronize(): Boolean {
        val age = clock.anchorAgeMilliseconds()
        if (age != null && age in 0 until resynchronizeAfterMilliseconds) return true

        val server = sntpHosts.firstNotNullOfOrNull(::sntpTime) ?: httpHosts.firstNotNullOfOrNull(::httpTime)
        if (server != null) {
            anchors?.write(clock.install(server))
            return true
        }
        return hasSynchronized
    }

    private fun sntpTime(host: String): Long? {
        return try {
            DatagramSocket().use { socket ->
                socket.soTimeout = sntpHostTimeoutMilliseconds
                val address = InetAddress.getByName(host)
                // Connected, not merely bound: the kernel then delivers datagrams
                // from this peer and port only, so an off-path reply to our
                // transient port cannot be read as an answer.
                socket.connect(address, ntpPort)
                val clientTransmitMilliseconds = System.currentTimeMillis()
                val monotonicTransmit = SystemClock.elapsedRealtime()
                val request = NtpPacket.request(clientTransmitMilliseconds)
                socket.send(DatagramPacket(request, request.size))

                val buffer = ByteArray(64)
                val response = DatagramPacket(buffer, buffer.size)
                socket.receive(response)
                val receivedAt = System.currentTimeMillis()
                val monotonicReceive = SystemClock.elapsedRealtime()
                // Belt and braces on top of the connection: the packet has to name
                // the peer we asked.
                if (response.address != address || response.port != ntpPort) return null

                // Both clocks around the same exchange: the wall readings give
                // the absolute instant, the monotonic ones prove the wall clock
                // did not move while they were being taken.
                NtpPacket.correctedUnixMilliseconds(
                    packet = response.data,
                    packetLength = response.length,
                    clientTransmitMilliseconds = clientTransmitMilliseconds,
                    clientReceiveMilliseconds = receivedAt,
                    monotonicTransmitMilliseconds = monotonicTransmit,
                    monotonicReceiveMilliseconds = monotonicReceive,
                    request = request,
                )
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun httpTime(host: String): Long? {
        var connection: HttpURLConnection? = null
        return try {
            connection = URL("https://$host/ntp").openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = httpHostTimeoutMilliseconds
            connection.readTimeout = httpHostTimeoutMilliseconds
            connection.useCaches = false
            connection.setRequestProperty("Cache-Control", "no-store")

            val sentAt = System.currentTimeMillis()
            val status = connection.responseCode
            val body = connection.inputStream.use { stream ->
                BufferedReader(stream.reader()).use { reader ->
                    val text = StringBuilder()
                    val buffer = CharArray(256)
                    while (true) {
                        val read = reader.read(buffer)
                        if (read < 0) break
                        text.append(buffer, 0, read)
                        // The body is about twenty bytes; anything larger is not
                        // this endpoint, and reading it all is the one way a
                        // hostile response could cost memory here.
                        if (text.length > 1_024) return@use null
                    }
                    text.toString()
                }
            } ?: return null
            val receivedAt = System.currentTimeMillis()

            if (status != HttpURLConnection.HTTP_OK) return null
            val bodyValue = body.trim().toDoubleOrNull() ?: return null
            if (!bodyValue.isFinite() || bodyValue <= 0) return null

            val serverMilliseconds = Math.round(bodyValue)
            val offset = HttpTimeValidation.offsetMilliseconds(
                serverUnixMilliseconds = serverMilliseconds,
                dateHeaderUnixMilliseconds = connection.getHeaderField("Date")?.let(::parseHttpDate),
                sentAtMilliseconds = sentAt,
                receivedAtMilliseconds = receivedAt,
            ) ?: return null

            System.currentTimeMillis() + offset
        } catch (_: Exception) {
            null
        } finally {
            connection?.disconnect()
        }
    }

    private val httpDateFormats = listOf(
        "EEE, dd MMM yyyy HH:mm:ss zzz",
        "EEE, dd-MMM-yy HH:mm:ss zzz",
        "EEE MMM d HH:mm:ss yyyy",
    )

    /**
     * RFC 9110 `Date`, fixed to `Locale.US` and GMT.
     *
     * A locale-sensitive formatter would parse the same header on one device and
     * return null on another, and a null here rejects the response — making
     * calibration fail only for users with, say, a Buddhist calendar.
     */
    private fun parseHttpDate(value: String): Long? {
        val trimmed = value.trim()
        for (pattern in httpDateFormats) {
            try {
                val format = SimpleDateFormat(pattern, Locale.US)
                format.timeZone = TimeZone.getTimeZone("GMT")
                format.isLenient = false
                val parsed = format.parse(trimmed) ?: continue
                return parsed.time
            } catch (_: Exception) {
                continue
            }
        }
        return null
    }
}

/**
 * The calibrated anchor, kept across process death.
 *
 * `SystemClock.elapsedRealtime()` keeps counting from boot whichever process
 * reads it, so a (server instant, elapsed reading) pair taken by one process
 * is exactly as true in the next one — until the device reboots and the
 * elapsed clock restarts. The boot is identified by `Settings.Global.BOOT_COUNT`;
 * an anchor from another boot, from a device that cannot name its boot, or
 * older than [maximumAgeMilliseconds] is not restored, and the process is then
 * as unanchored as it always was without one.
 *
 * Without this, every process the system started for the Widget — a delayed
 * redraw, a clock-change broadcast, a launcher update, the app's own catalog
 * publish — had no anchor until a network refresh synchronized, and drew every
 * observation as outdated and every forecast as gone in the meantime.
 *
 * Stored in the Widget's own private preferences file, not in a Dart setting:
 * it is native process state that Dart never reads.
 */
internal class ClockAnchorStore(
    private val preferences: SharedPreferences,
    private val bootCount: () -> Int?,
) {
    fun read(monotonicNowMilliseconds: Long): ClockAnchor? {
        val boot = bootCount() ?: return null
        if (preferences.getInt(KEY_BOOT, -1) != boot) return null
        val server = preferences.getLong(KEY_SERVER, -1L)
        val monotonic = preferences.getLong(KEY_MONOTONIC, -1L)
        if (server <= 0 || monotonic < 0) return null
        val age = monotonicNowMilliseconds - monotonic
        if (age < 0 || age > maximumAgeMilliseconds) return null
        return ClockAnchor(server, monotonic)
    }

    fun write(anchor: ClockAnchor) {
        val boot = bootCount() ?: return
        preferences.edit {
            putInt(KEY_BOOT, boot)
            putLong(KEY_SERVER, anchor.serverMilliseconds)
            putLong(KEY_MONOTONIC, anchor.monotonicMilliseconds)
        }
    }

    fun clear() {
        preferences.edit { clear() }
    }

    companion object {
        /** A day of monotonic drift is well under a second; older is not reused. */
        const val maximumAgeMilliseconds = 24L * 60 * 60 * 1_000

        private const val FILE = "dpip_widget_clock"
        private const val KEY_BOOT = "boot_count"
        private const val KEY_SERVER = "server_ms"
        private const val KEY_MONOTONIC = "elapsed_ms"

        fun of(context: Context): ClockAnchorStore {
            val application = context.applicationContext
            return ClockAnchorStore(
                preferences = application.getSharedPreferences(FILE, Context.MODE_PRIVATE),
                bootCount = {
                    Settings.Global.getInt(application.contentResolver, Settings.Global.BOOT_COUNT, -1)
                        .takeIf { it >= 0 }
                },
            )
        }
    }
}
