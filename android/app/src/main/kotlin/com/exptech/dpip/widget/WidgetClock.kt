package com.exptech.dpip.widget

import android.os.SystemClock
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
    private data class Anchor(
        val serverMilliseconds: Long,
        val monotonicMilliseconds: Long,
    )

    // Publish both readings together: separate volatile fields can mix two syncs.
    @Volatile
    private var anchor: Anchor? = null

    val hasAnchor: Boolean
        get() = anchor != null

    /** Milliseconds since the anchor was taken, or null when there is none. */
    fun anchorAgeMilliseconds(): Long? {
        val current = anchor ?: return null
        return monotonicMilliseconds() - current.monotonicMilliseconds
    }

    fun install(serverUnixMilliseconds: Long) {
        anchor = Anchor(serverUnixMilliseconds, monotonicMilliseconds())
    }

    /**
     * Anchors at an explicit monotonic reading.
     *
     * Only a test needs this: it lets a test pin "the anchor was taken 30
     * seconds ago" without making the fake monotonic source stateful.
     */
    internal fun installAt(serverUnixMilliseconds: Long, monotonicMilliseconds: Long) {
        anchor = Anchor(serverUnixMilliseconds, monotonicMilliseconds)
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

    fun calibratedNowMilliseconds(): Long? = clock.calibratedNowMilliseconds()

    fun offsetMilliseconds(): Long? = clock.offsetMilliseconds()

    fun deviceMillisecondsFor(calibratedMilliseconds: Long): Long? =
        clock.deviceMillisecondsFor(calibratedMilliseconds)

    fun snapshotTime(): WidgetSnapshotTime? = clock.snapshotTime()

    fun invalidate() = clock.invalidate()

    /**
     * Anchors the clock without a network exchange.
     *
     * For tests that need "a synchronized process" — the property being tested
     * is what the code does *with* an anchor, not how the anchor was obtained.
     */
    internal fun installForTest(serverUnixMilliseconds: Long, monotonicMilliseconds: Long) {
        clock.installAt(serverUnixMilliseconds, monotonicMilliseconds)
    }

    /**
     * Synchronizes the clock, blocking up to roughly ten seconds.
     *
     * Never throws: a failure is "no usable calibration", which the caller
     * answers by keeping the snapshot it already has.
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

        for (host in sntpHosts) {
            sntpTime(host)?.let { clock.install(it); return true }
        }
        for (host in httpHosts) {
            httpTime(host)?.let { clock.install(it); return true }
        }

        // A failure here does not necessarily mean "no usable clock": an anchor
        // from an earlier success is still monotonic and still valid, so the
        // refresh may go on with it. What must not happen is inventing one —
        // `calibratedNowMilliseconds()` returns null until an anchor exists at
        // all, and every freshness decision refuses to guess. Mirrors iOS, where
        // `hasSynchronized` outlives a failed `synchronize()`.
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
