package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetTimeProtocolsTest {
    private fun serverPacket(
        serverReceiveMilliseconds: Long,
        serverTransmitMilliseconds: Long,
        originateMilliseconds: Long = 100_000L,
        mutate: (ByteArray) -> Unit = {},
    ): ByteArray {
        val packet = ByteArray(NtpPacket.length)
        // Leap indicator 0, NTP version 4, server mode 4.
        packet[0] = ((4 shl 3) or 4).toByte()
        packet[1] = 2
        // The originate field must echo the client's transmit timestamp.
        NtpPacket.writeTimestamp(packet, 24, originateMilliseconds)
        NtpPacket.writeTimestamp(packet, 32, serverReceiveMilliseconds)
        NtpPacket.writeTimestamp(packet, 40, serverTransmitMilliseconds)
        mutate(packet)
        return packet
    }

    /** An exchange whose wall and monotonic elapsed times agree. */
    private fun corrected(
        packet: ByteArray,
        clientTransmit: Long = 100_000L,
        clientReceive: Long = 102_000L,
        monotonicTransmit: Long = 500_000L,
        monotonicReceive: Long = 502_000L,
    ): Long? = NtpPacket.correctedUnixMilliseconds(
        packet = packet,
        packetLength = packet.size,
        clientTransmitMilliseconds = clientTransmit,
        clientReceiveMilliseconds = clientReceive,
        monotonicTransmitMilliseconds = monotonicTransmit,
        monotonicReceiveMilliseconds = monotonicReceive,
        request = NtpPacket.request(clientTransmit),
    )

    @Test
    fun `the request is a mode-three client packet carrying t1`() {
        val transmit = 1_791_454_316_000L
        val request = NtpPacket.request(transmit)
        assertEquals(48, request.size)
        assertEquals(0x1B, request[0].toInt() and 0xFF)
        // The wire timestamp counts seconds from 1900, not from 1970.
        val t1 = NtpPacket.readTimestamp(request, 40)!!
        assertEquals(transmit / 1_000.0 + 2_208_988_800.0, t1, 0.001)
    }

    @Test
    fun `the corrected instant removes the network delay`() {
        // Client sends at t1, server is exactly 5000 ms ahead, one second of
        // travel each way, ten milliseconds of server processing.
        val clientTransmit = 100_000L
        val clientReceive = 102_000L
        val serverReceive = clientTransmit + 5_000 + 1_000
        val serverTransmit = serverReceive + 10

        val corrected = corrected(
            packet = serverPacket(serverReceive, serverTransmit),
            clientTransmit = clientTransmit,
            clientReceive = clientReceive,
        )
        // ((6000) + (4010)) / 2 = 5005 ms of correction on top of t4.
        assertEquals(107_005L, corrected)
    }

    @Test
    fun `refuses a response that is not a synchronised server reply`() {
        val valid = serverPacket(101_000, 101_100)

        val cases = mapOf(
            "leap indicator 3" to serverPacket(101_000, 101_100) { it[0] = 0xC0.toByte() },
            "client mode" to serverPacket(101_000, 101_100) { it[0] = ((4 shl 3) or 3).toByte() },
            "version 2" to serverPacket(101_000, 101_100) { it[0] = ((2 shl 3) or 4).toByte() },
            "stratum 0" to serverPacket(101_000, 101_100) { it[1] = 0 },
            "stratum 16" to serverPacket(101_000, 101_100) { it[1] = 16 },
            "zero transmit stamp" to serverPacket(101_000, 101_100) { packet ->
                for (index in 40 until 48) packet[index] = 0
            },
            "zero receive stamp" to serverPacket(101_000, 101_100) { packet ->
                for (index in 32 until 40) packet[index] = 0
            },
            "transmit before receive" to serverPacket(101_100, 101_000),
        )

        for ((name, packet) in cases) {
            assertNull(name, corrected(packet))
        }
        assertNotNull(corrected(valid))
    }

    @Test
    fun `refuses a reply whose originate stamp is not ours`() {
        // The echo of our transmit timestamp is what ties the reply to our
        // request; without it this could be any packet that reached the socket.
        assertNull(
            corrected(serverPacket(101_000, 101_100, originateMilliseconds = 999_000)),
        )
        assertNotNull(
            corrected(serverPacket(101_000, 101_100, originateMilliseconds = 100_000)),
        )
    }

    @Test
    fun `refuses an originate stamp that is only nearly ours`() {
        // A range check would accept this: it is one millisecond from the
        // transmit stamp we sent. A reply to somebody else's request, or one
        // replayed at the right port, is exactly this shape — so the comparison
        // is the eight bytes the client wrote, not a tolerance.
        assertNull(
            corrected(
                serverPacket(101_000, 101_100, originateMilliseconds = 100_001L),
            ),
        )
        // Even a sub-millisecond difference is visible in the fraction.
        val request = NtpPacket.request(100_000)
        val response = serverPacket(101_000, 101_100, originateMilliseconds = 100_000)
        assertTrue(NtpPacket.originateMatches(request, response))
        response[31] = (response[31].toInt() xor 0x01).toByte()
        assertFalse(NtpPacket.originateMatches(request, response))
    }

    @Test
    fun `a request that does not echo back is refused whatever else it says`() {
        // Two different requests, each well formed, one answered by the other's
        // reply: the timestamps are identical everywhere except the originate
        // field, and that is the only thing that distinguishes them.
        val request = NtpPacket.request(100_000)
        val other = NtpPacket.request(100_000L + 1L)
        val response = NtpPacket.request(100_000)
        val serverReply = serverPacket(101_000, 101_100, originateMilliseconds = 100_001L)
        assertFalse(NtpPacket.originateMatches(request, serverReply))
        assertTrue(NtpPacket.originateMatches(other, serverReply))
        assertFalse(NtpPacket.originateMatches(request, response))
    }

    @Test
    fun `refuses an exchange the wall clock moved during`() {
        val packet = serverPacket(101_000, 101_100)

        // Two seconds of monotonic time, an hour of wall time: the device clock
        // was stepped mid-exchange, and the offset would be wrong by half of it.
        assertNull(
            corrected(
                packet,
                clientTransmit = 100_000L,
                clientReceive = 100_000L + 3_600_000L,
                monotonicTransmit = 500_000L,
                monotonicReceive = 502_000L,
            ),
        )

        // A millisecond of disagreement between the two reads is normal.
        assertNotNull(corrected(packet, clientReceive = 102_001L, monotonicReceive = 502_000L))
    }

    @Test
    fun `refuses a packet with no originate stamp`() {
        val packet = serverPacket(101_000, 101_100)
        for (index in 24 until 32) packet[index] = 0
        assertNull(corrected(packet))
    }

    @Test
    fun `refuses a truncated packet`() {
        val truncated = serverPacket(101_000, 101_100).copyOf(32)
        assertNull(
            NtpPacket.correctedUnixMilliseconds(
                packet = truncated,
                packetLength = 32,
                clientTransmitMilliseconds = 100_000,
                clientReceiveMilliseconds = 102_000,
                monotonicTransmitMilliseconds = 500_000,
                monotonicReceiveMilliseconds = 502_000,
            ),
        )
    }

    @Test
    fun `unfolds a timestamp past the 2036 era rollover`() {
        // A wire timestamp in the era starting 2036, read near 2037.
        val reference = 2_100_000_000.0
        val packet = ByteArray(NtpPacket.length)
        NtpPacket.writeTimestamp(packet, 0, (reference * 1_000).toLong())
        val unfolded = NtpPacket.unixTime(packet, 0, reference)!!
        assertEquals(reference, unfolded, 1.0)
    }

    // ── HTTPS fallback acceptance ───────────────────────────────────────────

    @Test
    fun `a healthy HTTPS reading yields its midpoint offset`() {
        val offset = HttpTimeValidation.offsetMilliseconds(
            serverUnixMilliseconds = 1_000_000,
            dateHeaderUnixMilliseconds = 1_000_200,
            sentAtMilliseconds = 999_000,
            receivedAtMilliseconds = 1_000_000,
        )
        assertEquals(500L, offset)
    }

    @Test
    fun `a backend clock far from its own Date header is refused`() {
        // The measured defect: a node 15.7 seconds behind its own edge stamp.
        assertNull(
            HttpTimeValidation.offsetMilliseconds(
                serverUnixMilliseconds = 1_000_000,
                dateHeaderUnixMilliseconds = 984_300,
                sentAtMilliseconds = 999_000,
                receivedAtMilliseconds = 1_000_000,
            ),
        )
        // Two seconds of skew is still inside the allowance.
        assertTrue(
            HttpTimeValidation.offsetMilliseconds(
                serverUnixMilliseconds = 1_000_000,
                dateHeaderUnixMilliseconds = 998_000,
                sentAtMilliseconds = 999_000,
                receivedAtMilliseconds = 1_000_000,
            ) != null,
        )
    }

    @Test
    fun `a reading without a Date header is unusable rather than unverified`() {
        assertNull(
            HttpTimeValidation.offsetMilliseconds(
                serverUnixMilliseconds = 1_000_000,
                dateHeaderUnixMilliseconds = null,
                sentAtMilliseconds = 999_000,
                receivedAtMilliseconds = 1_000_000,
            ),
        )
    }

    @Test
    fun `a slow or impossible round trip is refused rather than halved`() {
        assertNull(
            HttpTimeValidation.offsetMilliseconds(
                serverUnixMilliseconds = 1_000_000,
                dateHeaderUnixMilliseconds = 1_000_200,
                sentAtMilliseconds = 998_000,
                receivedAtMilliseconds = 1_000_000,
            ),
        )
        assertNull(
            HttpTimeValidation.offsetMilliseconds(
                serverUnixMilliseconds = 1_000_000,
                dateHeaderUnixMilliseconds = 1_000_200,
                sentAtMilliseconds = 1_000_000,
                receivedAtMilliseconds = 999_000,
            ),
        )
    }

    @Test
    fun `a non-positive body is refused`() {
        assertNull(
            HttpTimeValidation.offsetMilliseconds(
                serverUnixMilliseconds = 0,
                dateHeaderUnixMilliseconds = 0,
                sentAtMilliseconds = 999_000,
                receivedAtMilliseconds = 1_000_000,
            ),
        )
    }
}
