package com.exptech.dpip.widget

/**
 * The two time protocols behind the calibrated clock, as pure functions.
 *
 * Split out of `WidgetClock` so the arithmetic — which is the part that can be
 * silently wrong — is exercised without a socket, a network, or a two-second
 * test. `WidgetClock` keeps only the transport. This mirrors the iOS split
 * between `WidgetNTPPacket` (pure) and `WidgetNetworkSNTPHostQuery` (I/O), and
 * the rules are the same ones.
 */
object NtpPacket {
    const val length = 48
    private const val unixEpochDeltaSeconds = 2_208_988_800.0
    private const val eraSeconds = 4_294_967_296.0

    /** A mode-3 client request carrying the client's transmit instant at t1. */
    fun request(clientTransmitMilliseconds: Long): ByteArray {
        val packet = ByteArray(length)
        // Leap indicator 0, NTP version 3, client mode 3.
        packet[0] = 0x1B
        writeTimestamp(packet, 40, clientTransmitMilliseconds)
        return packet
    }

    /**
     * The corrected server instant, or null when the response is not usable.
     *
     * Every guard is a reason to keep the previous anchor rather than install a
     * wrong one. Two of them are about the exchange itself rather than the
     * packet's contents:
     *
     * * **The originate timestamp must be ours.** A reply whose originate field
     *   is not the transmit timestamp this client sent is not a reply to this
     *   request — an off-path forgery, or a stray packet — and its offsets mean
     *   nothing.
     * * **The wall clock must not have moved during the exchange.** `t1` and `t4`
     *   are wall-clock readings and the offset is computed from them, so a clock
     *   adjustment between them (a user changing the date, an NTP daemon
     *   stepping the system clock) corrupts the arithmetic: a one-hour step
     *   mid-exchange halves into a thirty-minute error. The monotonic readings
     *   are the same exchange measured on a clock that cannot move, so a
     *   disagreement between the two is proof the reading is unusable rather than
     *   evidence about the server.
     */
    fun correctedUnixMilliseconds(
        packet: ByteArray,
        packetLength: Int,
        clientTransmitMilliseconds: Long,
        clientReceiveMilliseconds: Long,
        monotonicTransmitMilliseconds: Long,
        monotonicReceiveMilliseconds: Long,
        /** The request this reply answers, for the byte-exact originate check. */
        request: ByteArray? = null,
    ): Long? {
        if (packetLength < length) return null

        val firstByte = packet[0].toInt() and 0xFF
        val leapIndicator = firstByte shr 6
        val version = (firstByte shr 3) and 0x07
        val mode = firstByte and 0x07
        val stratum = packet[1].toInt() and 0xFF
        if (leapIndicator == 3) return null
        if (version != 3 && version != 4) return null
        if (mode != 4) return null
        if (stratum !in 1..15) return null
        if (isZeroTimestamp(packet, 24) || isZeroTimestamp(packet, 32) || isZeroTimestamp(packet, 40)) {
            return null
        }

        if (request != null && !originateMatches(request, packet)) return null

        val reference = clientReceiveMilliseconds / 1_000.0

        val wallElapsed = clientReceiveMilliseconds - clientTransmitMilliseconds
        val monotonicElapsed = monotonicReceiveMilliseconds - monotonicTransmitMilliseconds
        if (wallElapsed < 0 || monotonicElapsed < 0) return null
        if (Math.abs(wallElapsed - monotonicElapsed) > maximumWallDiscontinuityMilliseconds) {
            return null
        }

        val serverReceive = unixTime(packet, 32, reference) ?: return null
        val serverTransmit = unixTime(packet, 40, reference) ?: return null
        if (serverTransmit < serverReceive) return null

        val clientTransmit = clientTransmitMilliseconds / 1_000.0
        val clientReceive = clientReceiveMilliseconds / 1_000.0
        val offset = ((serverReceive - clientTransmit) + (serverTransmit - clientReceive)) / 2
        val corrected = clientReceive + offset
        if (!corrected.isFinite() || corrected < 0) return null
        if (corrected > Long.MAX_VALUE / 1_000.0) return null
        return Math.round(corrected * 1_000)
    }

    /**
     * Whether the reply echoes **our** request, byte for byte.
     *
     * The originate field (offset 24) must hold the transmit timestamp the client
     * sent (offset 40 of the request). A range check — "within a second" — is the
     * shape this had first, and it accepts a reply to a *different* request whose
     * timestamp happens to be close, which is exactly what a stray or forged
     * packet looks like. Comparing the eight bytes cannot be satisfied by
     * coincidence: the fraction alone is 1/2³² s.
     */
    fun originateMatches(request: ByteArray, response: ByteArray): Boolean {
        if (request.size < length || response.size < length) return false
        for (index in 0 until 8) {
            if (request[40 + index] != response[24 + index]) return false
        }
        return true
    }

    /**
     * How far the wall-clock and monotonic elapsed times may disagree.
     *
     * The two measure the same interval; a millisecond of jitter between the two
     * reads is unavoidable, and a clock adjustment is orders of magnitude larger.
     */
    const val maximumWallDiscontinuityMilliseconds = 1_000L

    /** The NTP timestamp at [offset], as Unix seconds, in the era nearest [referenceUnixSeconds]. */
    fun unixTime(packet: ByteArray, offset: Int, referenceUnixSeconds: Double): Double? {
        val value = readTimestamp(packet, offset) ?: return null
        val eraZeroUnixTime = value - unixEpochDeltaSeconds
        // The wire format carries no era number. Selecting the era nearest the
        // reference is what unfolds timestamps past the February 2036 rollover.
        val era = Math.round((referenceUnixSeconds - eraZeroUnixTime) / eraSeconds)
        return eraZeroUnixTime + era * eraSeconds
    }

    fun readTimestamp(packet: ByteArray, offset: Int): Double? {
        if (offset < 0 || packet.size < offset + 8) return null
        val seconds = ((packet[offset].toLong() and 0xFF) shl 24) or
            ((packet[offset + 1].toLong() and 0xFF) shl 16) or
            ((packet[offset + 2].toLong() and 0xFF) shl 8) or
            (packet[offset + 3].toLong() and 0xFF)
        val fraction = ((packet[offset + 4].toLong() and 0xFF) shl 24) or
            ((packet[offset + 5].toLong() and 0xFF) shl 16) or
            ((packet[offset + 6].toLong() and 0xFF) shl 8) or
            (packet[offset + 7].toLong() and 0xFF)
        return seconds.toDouble() + fraction.toDouble() / eraSeconds
    }

    fun writeTimestamp(packet: ByteArray, offset: Int, unixMilliseconds: Long) {
        val ntpSeconds = (unixMilliseconds / 1_000.0) + unixEpochDeltaSeconds
        val whole = Math.floor(ntpSeconds)
        var era = whole % eraSeconds
        if (era < 0) era += eraSeconds
        val seconds = era.toLong()
        val fraction = Math.round((ntpSeconds - whole) * eraSeconds)
        writeUInt32(packet, offset, seconds)
        writeUInt32(packet, offset + 4, fraction)
    }

    private fun writeUInt32(packet: ByteArray, offset: Int, value: Long) {
        packet[offset] = ((value shr 24) and 0xFF).toByte()
        packet[offset + 1] = ((value shr 16) and 0xFF).toByte()
        packet[offset + 2] = ((value shr 8) and 0xFF).toByte()
        packet[offset + 3] = (value and 0xFF).toByte()
    }

    private fun isZeroTimestamp(packet: ByteArray, offset: Int): Boolean {
        for (index in offset until offset + 8) {
            if (packet[index].toInt() != 0) return false
        }
        return true
    }
}

/**
 * The verified HTTPS clock reading's acceptance rule.
 *
 * The body is the origin's clock, and not every origin's clock is right; the
 * `Date` header of the same response is stamped at the Cloudflare edge,
 * independently of whichever backend answered, which makes every response
 * self-checking. A body more than two seconds from its own header is discarded —
 * the measurement that made this necessary is in ARCHITECTURE.md's calibrated
 * time contract.
 *
 * A round trip slower than 1.5 s is also discarded rather than halved: the
 * estimate assumes the body was stamped at the midpoint, so its error grows with
 * the round trip.
 */
object HttpTimeValidation {
    const val maximumDateSkewMilliseconds = 2_000L
    const val maximumRoundTripMilliseconds = 1_500L

    /**
     * The device→server correction in milliseconds, or null when unusable.
     *
     * A response without a `Date` header is unusable rather than merely
     * unverified: nothing else can tell a wrong backend clock from a right one.
     */
    fun offsetMilliseconds(
        serverUnixMilliseconds: Long,
        dateHeaderUnixMilliseconds: Long?,
        sentAtMilliseconds: Long,
        receivedAtMilliseconds: Long,
    ): Long? {
        if (serverUnixMilliseconds <= 0) return null

        val roundTrip = receivedAtMilliseconds - sentAtMilliseconds
        if (roundTrip < 0 || roundTrip > maximumRoundTripMilliseconds) return null

        val dateHeader = dateHeaderUnixMilliseconds ?: return null
        if (Math.abs(serverUnixMilliseconds - dateHeader) > maximumDateSkewMilliseconds) return null

        val midpoint = sentAtMilliseconds + roundTrip / 2
        return serverUnixMilliseconds - midpoint
    }
}
