import Foundation

/// One `/ntp` exchange, measured against the device clock.
///
/// `sentAt` and `receivedAt` bracket the request so the offset can be corrected
/// for network delay; `dateHeader` is the HTTP `Date` of the same response —
/// see `WidgetHTTPTimeSource` for what it can and cannot prove.
struct WidgetHTTPTimeExchange: Sendable {
    let serverUnixMilliseconds: Int64
    let dateHeader: Date?
    let sentAt: Date
    let receivedAt: Date
}

protocol WidgetHTTPTimeHostQuerying: Sendable {
    func query(
        url: URL,
        timeout: TimeInterval
    ) async throws -> WidgetHTTPTimeExchange
}

enum WidgetHTTPTimeError: Error, Equatable {
    case allHostsRejected
    case invalidResponse
    case httpStatus(Int)
    case responseTooLarge
}

/// `WidgetServerTimeSource` over `https://api.lb.exptech.dev/ntp`, for networks
/// that block SNTP's UDP/123 — corporate Wi-Fi, hotel and campus networks, some
/// carriers.
///
/// Strictly a fallback behind `WidgetSNTPClient`: one HTTPS round trip resolves
/// "now" to roughly ±RTT/2 (±150 ms measured), where the SNTP exchange resolves
/// it to about a millisecond. It exists so a blocked UDP port degrades the
/// widget's clock instead of leaving it uncalibrated — and every forecast expiry
/// the widget computes is measured in calibrated time.
///
/// ## Why the `Date` header is checked
///
/// The body is the *origin's* clock, and not every origin's clock is right: of
/// the four `lb-*` nodes behind this name, two were 15.7 seconds behind at the
/// time of writing — consistently, and in agreement with each other, so a
/// quorum across them would not have caught it either.
///
/// What does catch it is the `Date` header of the very same response. This host
/// sits behind Cloudflare, so `Date` is stamped at the edge, independently of
/// whichever backend answered — which makes every response self-checking: a body
/// more than `maximumDateSkew` from its own `Date` is a bad backend (or a frozen
/// cache), and is discarded without needing to know which node it came from.
///
/// Every guard fails closed: installing a wrong offset is worse than not
/// calibrating, so a rejected response throws and `WidgetServerClock` keeps its
/// last anchor.
struct WidgetHTTPTimeSource: WidgetServerTimeSource {
    /// The DNS-balanced LB name — the one place the repository uses a bare
    /// host.
    ///
    /// Region-pinned API traffic deliberately never does, because region
    /// selection and failover belong to the app. A clock reading has no region
    /// to select, and the bare name is what Cloudflare terminates with a valid
    /// certificate — `time.exptech.com.tw`, SNTP's own primary, serves `/ntp`
    /// too but presents an expired certificate for the wrong name, and its
    /// `Date` comes from the same machine as its body, so it can neither be
    /// reached over HTTPS nor check itself.
    static let defaultHosts = ["api.lb.exptech.dev"]

    /// How far the body may sit from its own `Date` header.
    ///
    /// `Date` has one-second resolution and is stamped at the edge after the
    /// origin wrote the body, so a healthy response lands within about a second
    /// of its header (−66 to +910 ms over thirty samples). Two seconds absorbs
    /// that with room to spare, and still rejects the 15.7-second backends by a
    /// factor of seven.
    static let maximumDateSkew: TimeInterval = 2

    /// Round trips slower than this are discarded rather than halved.
    ///
    /// The offset estimate assumes the body was stamped at the midpoint of the
    /// exchange, so its error grows with the round trip.
    static let maximumRoundTrip: TimeInterval = 1.5

    private let hosts: [String]
    private let hostTimeout: TimeInterval
    private let deviceClock: any WidgetWallTimeSource
    private let hostQuery: any WidgetHTTPTimeHostQuerying

    init(
        hosts: [String] = defaultHosts,
        hostTimeout: TimeInterval = 2,
        deviceClock: any WidgetWallTimeSource =
            WidgetSystemWallTimeSource(),
        hostQuery: any WidgetHTTPTimeHostQuerying =
            WidgetURLSessionHTTPTimeHostQuery()
    ) {
        self.hosts = hosts
        self.hostTimeout = hostTimeout
        self.deviceClock = deviceClock
        self.hostQuery = hostQuery
    }

    /// The `/ntp` URL for `host`. HTTPS only — a cleartext time source is one
    /// any network in the path can rewrite, and the networks that block UDP/123
    /// are exactly the ones in a position to do it.
    static func url(host: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/ntp"
        return components.url
    }

    func serverTimeUnixMilliseconds() async throws -> Int64 {
        for host in hosts {
            try Task.checkCancellation()

            guard let url = Self.url(host: host) else { continue }

            let exchange: WidgetHTTPTimeExchange
            do {
                exchange = try await hostQuery.query(
                    url: url,
                    timeout: hostTimeout
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                continue
            }

            guard let offset = Self.offset(from: exchange) else { continue }
            let corrected = deviceClock.now().addingTimeInterval(offset)
            return Int64((corrected.timeIntervalSince1970 * 1_000).rounded())
        }

        throw WidgetHTTPTimeError.allHostsRejected
    }

    /// The device→server correction this exchange reports, or `nil` when it is
    /// not trustworthy enough to use.
    static func offset(
        from exchange: WidgetHTTPTimeExchange
    ) -> TimeInterval? {
        guard exchange.serverUnixMilliseconds > 0 else { return nil }

        let roundTrip = exchange.receivedAt.timeIntervalSince(exchange.sentAt)
        guard roundTrip >= 0, roundTrip <= maximumRoundTrip else {
            return nil
        }

        // Nothing but the Date header can tell a wrong backend clock from a
        // right one, so a response without it is unusable rather than merely
        // unverified.
        guard let dateHeader = exchange.dateHeader else { return nil }

        let server = Date(
            timeIntervalSince1970:
                Double(exchange.serverUnixMilliseconds) / 1_000
        )
        guard abs(server.timeIntervalSince(dateHeader)) <= maximumDateSkew
        else {
            return nil
        }

        // The body was stamped somewhere inside the exchange; the midpoint is
        // the best estimate a single round trip can give.
        let midpoint = exchange.sentAt.addingTimeInterval(roundTrip / 2)
        return server.timeIntervalSince(midpoint)
    }
}

/// One `/ntp` round trip over `URLSession`, with the caches bypassed — a cached
/// clock reading is worse than no reading.
struct WidgetURLSessionHTTPTimeHostQuery: WidgetHTTPTimeHostQuerying {
    /// The body is about twenty bytes; anything larger is not this endpoint.
    private static let maximumResponseSize = 1024

    private let session: URLSession
    private let wallClock: any WidgetWallTimeSource

    init(
        session: URLSession = .shared,
        wallClock: any WidgetWallTimeSource = WidgetSystemWallTimeSource()
    ) {
        self.session = session
        self.wallClock = wallClock
    }

    func query(
        url: URL,
        timeout: TimeInterval
    ) async throws -> WidgetHTTPTimeExchange {
        try Task.checkCancellation()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let sentAt = wallClock.now()
        let (data, response) = try await session.data(for: request)
        let receivedAt = wallClock.now()

        guard let response = response as? HTTPURLResponse else {
            throw WidgetHTTPTimeError.invalidResponse
        }
        guard response.statusCode == 200 else {
            throw WidgetHTTPTimeError.httpStatus(response.statusCode)
        }
        guard data.count <= Self.maximumResponseSize else {
            throw WidgetHTTPTimeError.responseTooLarge
        }

        // Unix milliseconds with a fractional part ("1791454316238.287"); the
        // fraction sits far below this path's accuracy.
        guard let body = String(data: data, encoding: .utf8),
              let milliseconds = Double(
                  body.trimmingCharacters(in: .whitespacesAndNewlines)
              )
        else {
            throw WidgetHTTPTimeError.invalidResponse
        }

        return WidgetHTTPTimeExchange(
            serverUnixMilliseconds: Int64(milliseconds.rounded()),
            dateHeader: WidgetHTTPDateHeader.date(
                response.value(forHTTPHeaderField: "Date")
            ),
            sentAt: sentAt,
            receivedAt: receivedAt
        )
    }
}

/// RFC 9110 `Date` parsing, fixed to `en_US_POSIX` and GMT.
///
/// `DateFormatter` otherwise reads the device's locale and calendar, so the same
/// header would parse on one device and return nil on another — and a nil here
/// means the response gets rejected, which would make calibration fail only for
/// users with, say, a Buddhist calendar.
enum WidgetHTTPDateHeader {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }()

    static func date(_ header: String?) -> Date? {
        guard let header else { return nil }
        return formatter.date(
            from: header.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
