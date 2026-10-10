import Foundation
import XCTest

/// Scripted `/ntp` responses keyed by host, so every rejection path is
/// reachable without a socket.
private struct StubHTTPTimeHostQuery: WidgetHTTPTimeHostQuerying {
    let responses: [String: Result<WidgetHTTPTimeExchange, Error>]

    func query(
        url: URL,
        timeout: TimeInterval
    ) async throws -> WidgetHTTPTimeExchange {
        guard let host = url.host,
              let response = responses[host]
        else {
            throw WidgetHTTPTimeError.invalidResponse
        }
        return try response.get()
    }
}

final class WidgetHTTPTimeSourceTests: XCTestCase {
    private let deviceMilliseconds: Int64 = 1_767_268_800_000

    private var deviceDate: Date {
        Date(timeIntervalSince1970: TimeInterval(deviceMilliseconds) / 1_000)
    }

    /// A healthy exchange: 200ms round trip, body agreeing with its own `Date`
    /// to within the header's one-second resolution.
    private func healthy(
        offsetMilliseconds: Int64 = 0,
        roundTripMilliseconds: Int64 = 200
    ) -> WidgetHTTPTimeExchange {
        let midpoint = deviceMilliseconds + roundTripMilliseconds / 2
        let server = midpoint + offsetMilliseconds
        return exchange(
            serverMilliseconds: server,
            // Floored to the second, as a real `Date` header is.
            dateHeaderMilliseconds: (server / 1_000) * 1_000,
            roundTripMilliseconds: roundTripMilliseconds
        )
    }

    private func exchange(
        serverMilliseconds: Int64,
        dateHeaderMilliseconds: Int64?,
        roundTripMilliseconds: Int64
    ) -> WidgetHTTPTimeExchange {
        WidgetHTTPTimeExchange(
            serverUnixMilliseconds: serverMilliseconds,
            dateHeader: dateHeaderMilliseconds.map {
                Date(timeIntervalSince1970: TimeInterval($0) / 1_000)
            },
            sentAt: deviceDate,
            receivedAt: deviceDate.addingTimeInterval(
                TimeInterval(roundTripMilliseconds) / 1_000
            )
        )
    }

    private func source(
        hosts: [String],
        responses: [String: Result<WidgetHTTPTimeExchange, Error>]
    ) -> WidgetHTTPTimeSource {
        WidgetHTTPTimeSource(
            hosts: hosts,
            deviceClock: TestWallClock(milliseconds: deviceMilliseconds),
            hostQuery: StubHTTPTimeHostQuery(responses: responses)
        )
    }

    func testAppliesMeasuredOffsetToDeviceClock() async throws {
        let time = try await source(
            hosts: ["a"],
            responses: ["a": .success(healthy(offsetMilliseconds: 4_000))]
        ).serverTimeUnixMilliseconds()

        XCTAssertEqual(time, deviceMilliseconds + 4_000)
    }

    func testCorrectsForNetworkDelayUsingTheExchangeMidpoint() async throws {
        // Stamped 500ms after the request left and 500ms before it landed, so
        // the device clock is exactly right: the offset must come out as zero
        // rather than as the full round trip.
        let time = try await source(
            hosts: ["a"],
            responses: [
                "a": .success(
                    exchange(
                        serverMilliseconds: deviceMilliseconds + 500,
                        dateHeaderMilliseconds: deviceMilliseconds + 500,
                        roundTripMilliseconds: 1_000
                    )
                )
            ]
        ).serverTimeUnixMilliseconds()

        XCTAssertEqual(time, deviceMilliseconds)
    }

    func testRejectsBodyDisagreeingWithItsOwnDateHeader() async {
        // The real failure behind this name: two of the four lb-* backends
        // were 15.7s behind, consistently and in agreement with each other, so
        // only the Cloudflare-stamped Date header could tell which answer to
        // believe.
        let good = healthy()
        let skewed = WidgetHTTPTimeExchange(
            serverUnixMilliseconds: good.serverUnixMilliseconds - 15_765,
            dateHeader: good.dateHeader,
            sentAt: good.sentAt,
            receivedAt: good.receivedAt
        )
        let subject = source(
            hosts: ["skewed"],
            responses: ["skewed": .success(skewed)]
        )

        await XCTAssertThrowsErrorAsync(
            try await subject.serverTimeUnixMilliseconds(),
            "a wrong backend clock must not win, even though it answered"
        )
    }

    func testAcceptsDateHeaderFlooredASecondBelowTheBody() async throws {
        // A healthy response measures within about a second of its own
        // header, largely because `Date` truncates to the second.
        let time = try await source(
            hosts: ["a"],
            responses: [
                "a": .success(
                    exchange(
                        serverMilliseconds: deviceMilliseconds + 100 + 875,
                        dateHeaderMilliseconds: deviceMilliseconds + 100,
                        roundTripMilliseconds: 200
                    )
                )
            ]
        ).serverTimeUnixMilliseconds()

        XCTAssertEqual(time, deviceMilliseconds + 875)
    }

    func testRejectsResponseWithoutDateHeader() async {
        let probe = healthy()
        let subject = source(
            hosts: ["a"],
            responses: [
                "a": .success(
                    exchange(
                        serverMilliseconds: probe.serverUnixMilliseconds,
                        dateHeaderMilliseconds: nil,
                        roundTripMilliseconds: 200
                    )
                )
            ]
        )

        await XCTAssertThrowsErrorAsync(
            try await subject.serverTimeUnixMilliseconds(),
            "unverifiable is not usable"
        )
    }

    func testRejectsRoundTripTooSlowToHalve() async {
        let subject = source(
            hosts: ["a"],
            responses: ["a": .success(healthy(roundTripMilliseconds: 4_600))]
        )

        await XCTAssertThrowsErrorAsync(
            try await subject.serverTimeUnixMilliseconds()
        )
    }

    func testRejectsNonPositiveBody() async {
        let subject = source(
            hosts: ["a"],
            responses: [
                "a": .success(
                    exchange(
                        serverMilliseconds: 0,
                        dateHeaderMilliseconds: deviceMilliseconds,
                        roundTripMilliseconds: 200
                    )
                )
            ]
        )

        await XCTAssertThrowsErrorAsync(
            try await subject.serverTimeUnixMilliseconds()
        )
    }

    func testFailsWhenTheHostCannotBeReached() async {
        // What a blocked UDP port plus an unreachable HTTPS endpoint looks
        // like: no calibration, rather than a guessed one.
        let subject = source(
            hosts: ["a"],
            responses: ["a": .failure(WidgetHTTPTimeError.invalidResponse)]
        )

        await XCTAssertThrowsErrorAsync(
            try await subject.serverTimeUnixMilliseconds()
        )
    }

    func testFallsThroughAFailingHostWhenMoreThanOneIsGiven() async throws {
        let time = try await source(
            hosts: ["down", "good"],
            responses: [
                "down": .failure(WidgetHTTPTimeError.invalidResponse),
                "good": .success(healthy(offsetMilliseconds: -2_000)),
            ]
        ).serverTimeUnixMilliseconds()

        XCTAssertEqual(time, deviceMilliseconds - 2_000)
    }

    func testFailsRatherThanHangingWithNoHosts() async {
        let subject = source(hosts: [], responses: [:])

        await XCTAssertThrowsErrorAsync(
            try await subject.serverTimeUnixMilliseconds()
        )
    }

    func testAsksTheDNSBalancedLBNameOverHTTPS() {
        // The one bare host the repository uses: a clock reading has no region
        // to pin, and this is the name Cloudflare terminates with a valid cert.
        XCTAssertEqual(
            WidgetHTTPTimeSource.defaultHosts,
            ["api.lb.exptech.dev"]
        )
        XCTAssertEqual(
            WidgetHTTPTimeSource.url(
                host: "api.lb.exptech.dev"
            )?.absoluteString,
            "https://api.lb.exptech.dev/ntp"
        )
    }

    func testNeverBuildsACleartextURL() {
        // A cleartext time source is one any network in the path can rewrite —
        // including the captive portals that block UDP/123 in the first place.
        XCTAssertEqual(
            WidgetHTTPTimeSource.url(host: "example.test")?.scheme,
            "https"
        )
    }

    func testMatchesTheDartToleranceConstants() {
        // The two platforms must reject the same responses; a widget that
        // calibrates from a response the app refuses would disagree with the
        // app about what time it is.
        XCTAssertEqual(WidgetHTTPTimeSource.maximumDateSkew, 2)
        XCTAssertEqual(WidgetHTTPTimeSource.maximumRoundTrip, 1.5)
    }
}

final class WidgetHTTPDateHeaderTests: XCTestCase {
    func testParsesRFC9110ImfFixdate() {
        let parsed = WidgetHTTPDateHeader.date("Thu, 08 Oct 2026 09:07:58 GMT")

        XCTAssertEqual(parsed, Date(timeIntervalSince1970: 1_791_450_478))
    }

    func testIgnoresSurroundingWhitespace() {
        XCTAssertNotNil(
            WidgetHTTPDateHeader.date(" Thu, 08 Oct 2026 09:07:58 GMT ")
        )
    }

    func testReturnsNilForMissingOrMalformedHeader() {
        XCTAssertNil(WidgetHTTPDateHeader.date(nil))
        XCTAssertNil(WidgetHTTPDateHeader.date("not a date"))
        XCTAssertNil(WidgetHTTPDateHeader.date(""))
    }
}

final class WidgetFallbackServerTimeSourceTests: XCTestCase {
    func testStopsAtTheFirstSourceThatAnswers() async throws {
        let sntp = ScriptedServerTimeSource(results: [.success(1_000)])
        let http = ScriptedServerTimeSource(results: [.success(2_000)])

        let time = try await WidgetFallbackServerTimeSource([sntp, http])
            .serverTimeUnixMilliseconds()

        XCTAssertEqual(time, 1_000)
        let httpCalls = await http.callCount
        XCTAssertEqual(
            httpCalls,
            0,
            "HTTP is an order of magnitude less precise — never consulted "
                + "while SNTP is answering"
        )
    }

    func testFallsThroughToHTTPWhenSNTPFails() async throws {
        let sntp = ScriptedServerTimeSource(
            results: [.failure(WidgetSNTPError.allHostsFailed)]
        )
        let http = ScriptedServerTimeSource(results: [.success(2_000)])

        let time = try await WidgetFallbackServerTimeSource([sntp, http])
            .serverTimeUnixMilliseconds()

        XCTAssertEqual(time, 2_000)
        let sntpCalls = await sntp.callCount
        XCTAssertEqual(sntpCalls, 1)
    }

    func testFailsWhenEverySourceFails() async {
        let sntp = ScriptedServerTimeSource(
            results: [.failure(WidgetSNTPError.allHostsFailed)]
        )
        let http = ScriptedServerTimeSource(
            results: [.failure(WidgetHTTPTimeError.allHostsRejected)]
        )
        let subject = WidgetFallbackServerTimeSource([sntp, http])

        await XCTAssertThrowsErrorAsync(
            try await subject.serverTimeUnixMilliseconds()
        )
    }

    func testFailsOnAnEmptyChainRatherThanReportingATime() async {
        let subject = WidgetFallbackServerTimeSource([])

        await XCTAssertThrowsErrorAsync(
            try await subject.serverTimeUnixMilliseconds()
        )
    }

    func testCancellationStopsTheChainInsteadOfAdvancingIt() async {
        // A torn-down getTimeline must not be answered by the slower source.
        let sntp = ScriptedServerTimeSource(
            results: [.failure(CancellationError())]
        )
        let http = ScriptedServerTimeSource(results: [.success(2_000)])
        let subject = WidgetFallbackServerTimeSource([sntp, http])

        await XCTAssertThrowsErrorAsync(
            try await subject.serverTimeUnixMilliseconds()
        )
        let httpCalls = await http.callCount
        XCTAssertEqual(httpCalls, 0)
    }
}

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail(
            message.isEmpty ? "Expected an error to be thrown" : message,
            file: file,
            line: line
        )
    } catch {
        // Expected.
    }
}
