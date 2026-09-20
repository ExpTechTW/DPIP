import Foundation
import XCTest

final class WidgetSNTPClientTests: XCTestCase {
    func testPrimarySuccessDoesNotQueryBackup() async throws {
        let query = ScriptedSNTPHostQuery(
            results: [.success(makeExchange(offsetMilliseconds: 250))]
        )
        let client = WidgetSNTPClient(hostQuery: query)

        let result = try await client.serverTimeUnixMilliseconds()

        XCTAssertEqual(result, 10_250)
        let calls = await query.calls
        XCTAssertEqual(calls.map(\.host), [WidgetSNTPClient.primaryHost])
        XCTAssertEqual(calls.map(\.timeout), [3])
    }

    func testPrimaryFailureFallsBackToBackup() async throws {
        let query = ScriptedSNTPHostQuery(
            results: [
                .failure(WidgetSNTPError.connectionFailed),
                .success(makeExchange(offsetMilliseconds: -400)),
            ]
        )
        let client = WidgetSNTPClient(hostQuery: query)

        let result = try await client.serverTimeUnixMilliseconds()

        XCTAssertEqual(result, 9_600)
        let calls = await query.calls
        XCTAssertEqual(
            calls.map(\.host),
            [WidgetSNTPClient.primaryHost, WidgetSNTPClient.backupHost]
        )
        XCTAssertEqual(calls.map(\.timeout), [3, 3])
    }

    func testPrimaryTimeoutFallsBackWithoutRealDelay() async throws {
        let query = ScriptedSNTPHostQuery(
            results: [
                .failure(WidgetSNTPError.timedOut),
                .success(makeExchange(offsetMilliseconds: 0)),
            ]
        )
        let client = WidgetSNTPClient(hostQuery: query)

        let result = try await client.serverTimeUnixMilliseconds()

        XCTAssertEqual(result, 10_000)
        let calls = await query.calls
        XCTAssertEqual(calls.map(\.timeout), [3, 3])
    }

    func testBothHostsFail() async {
        let query = ScriptedSNTPHostQuery(
            results: [
                .failure(WidgetSNTPError.connectionFailed),
                .failure(WidgetSNTPError.timedOut),
            ]
        )
        let client = WidgetSNTPClient(hostQuery: query)

        do {
            _ = try await client.serverTimeUnixMilliseconds()
            XCTFail("Expected all hosts to fail")
        } catch let error as WidgetSNTPError {
            XCTAssertEqual(error, .allHostsFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let calls = await query.calls
        XCTAssertEqual(
            calls.map(\.host),
            [WidgetSNTPClient.primaryHost, WidgetSNTPClient.backupHost]
        )
    }

    func testMalformedAndUndersizedResponsesAreRejected() {
        let undersized = WidgetSNTPExchange(
            response: Data(repeating: 0, count: 47),
            clientTransmitTime: date(milliseconds: 9_000),
            clientReceiveTime: date(milliseconds: 10_000)
        )
        XCTAssertThrowsError(
            try WidgetNTPPacket.correctedUnixMilliseconds(
                exchange: undersized
            )
        ) { error in
            XCTAssertEqual(error as? WidgetSNTPError, .invalidResponse)
        }

        var malformedPacket = makeServerPacket(
            serverReceiveMilliseconds: 9_500,
            serverTransmitMilliseconds: 9_600
        )
        malformedPacket[0] = 0x23
        let malformed = WidgetSNTPExchange(
            response: malformedPacket,
            clientTransmitTime: date(milliseconds: 9_000),
            clientReceiveTime: date(milliseconds: 10_000)
        )
        XCTAssertThrowsError(
            try WidgetNTPPacket.correctedUnixMilliseconds(
                exchange: malformed
            )
        ) { error in
            XCTAssertEqual(error as? WidgetSNTPError, .invalidResponse)
        }
    }

    func testNTPTimeConvertsToUnixEpochWithFraction() throws {
        var packet = Data(repeating: 0, count: WidgetNTPPacket.length)
        WidgetNTPPacket.writeTimestamp(
            unixTime: 0.5,
            to: &packet,
            at: 32
        )

        let unixTime = try WidgetNTPPacket.unixTime(
            from: packet,
            at: 32,
            near: 0.5
        )

        XCTAssertEqual(unixTime, 0.5, accuracy: 0.000_001)
    }

    func testNTPTimeUnfoldsEraAfter2036Rollover() throws {
        let unixTimeIn2040: TimeInterval = 2_208_988_800
        var packet = Data(repeating: 0, count: WidgetNTPPacket.length)
        WidgetNTPPacket.writeTimestamp(
            unixTime: unixTimeIn2040,
            to: &packet,
            at: 32
        )

        let decoded = try WidgetNTPPacket.unixTime(
            from: packet,
            at: 32,
            near: unixTimeIn2040
        )

        XCTAssertEqual(decoded, unixTimeIn2040, accuracy: 0.000_001)
    }

    func testOffsetFormulaSupportsPositiveAndNegativeOffsets() {
        let positive = WidgetNTPPacket.offsetSeconds(
            clientTransmitTime: 100,
            serverReceiveTime: 106,
            serverTransmitTime: 107,
            clientReceiveTime: 103
        )
        let negative = WidgetNTPPacket.offsetSeconds(
            clientTransmitTime: 100,
            serverReceiveTime: 96,
            serverTransmitTime: 97,
            clientReceiveTime: 103
        )

        XCTAssertEqual(positive, 5)
        XCTAssertEqual(negative, -5)
    }

    func testRequestIsStandardFortyEightByteClientPacket() {
        let request = WidgetNTPPacket.request(
            transmitTime: date(milliseconds: 10_000)
        )

        XCTAssertEqual(request.count, 48)
        XCTAssertEqual(request[0], 0x1B)
    }

    private func makeExchange(
        offsetMilliseconds: Int64
    ) -> WidgetSNTPExchange {
        let clientTransmitMilliseconds: Int64 = 9_000
        let clientReceiveMilliseconds: Int64 = 10_000
        let serverReceiveMilliseconds =
            clientTransmitMilliseconds + offsetMilliseconds + 100
        let serverTransmitMilliseconds =
            clientReceiveMilliseconds + offsetMilliseconds - 100

        return WidgetSNTPExchange(
            response: makeServerPacket(
                serverReceiveMilliseconds: serverReceiveMilliseconds,
                serverTransmitMilliseconds: serverTransmitMilliseconds
            ),
            clientTransmitTime: date(
                milliseconds: clientTransmitMilliseconds
            ),
            clientReceiveTime: date(
                milliseconds: clientReceiveMilliseconds
            )
        )
    }

    private func makeServerPacket(
        serverReceiveMilliseconds: Int64,
        serverTransmitMilliseconds: Int64
    ) -> Data {
        var packet = Data(repeating: 0, count: WidgetNTPPacket.length)
        packet[0] = 0x24
        packet[1] = 1
        WidgetNTPPacket.writeTimestamp(
            unixTime: TimeInterval(serverReceiveMilliseconds) / 1_000,
            to: &packet,
            at: 32
        )
        WidgetNTPPacket.writeTimestamp(
            unixTime: TimeInterval(serverTransmitMilliseconds) / 1_000,
            to: &packet,
            at: 40
        )
        return packet
    }

    private func date(milliseconds: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1_000)
    }
}

private actor ScriptedSNTPHostQuery: WidgetSNTPHostQuerying {
    struct Call: Sendable {
        let host: String
        let timeout: TimeInterval
    }

    private(set) var calls: [Call] = []
    private var results: [Result<WidgetSNTPExchange, Error>]

    init(results: [Result<WidgetSNTPExchange, Error>]) {
        self.results = results
    }

    func query(
        host: String,
        timeout: TimeInterval
    ) async throws -> WidgetSNTPExchange {
        calls.append(Call(host: host, timeout: timeout))
        guard !results.isEmpty else {
            throw WidgetSNTPError.connectionFailed
        }
        return try results.removeFirst().get()
    }
}
