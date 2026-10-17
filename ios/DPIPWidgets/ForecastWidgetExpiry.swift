import Foundation

enum ForecastWidgetExpiry {
    enum Freshness: Equatable, Sendable {
        case fresh, stale, expired
    }

    static let freshDuration: TimeInterval = 30 * 60
    static let hardExpiryDuration: TimeInterval = 120 * 60
    /// Small server/clock disagreement is tolerated; a publication further
    /// ahead is ineligible, rather than granting an unbounded cache lifetime.
    static let maximumFutureSkew: TimeInterval = 2 * 60

    /// Device-clock boundaries derived only from the API publication instant.
    /// Receipt and hourly point selection never determine publication age.
    static func staleDate(
        for snapshot: ForecastWidgetSnapshot,
        calibratedTimeOffsetMilliseconds: Int = 0
    ) -> Date {
        publicationDeviceDate(snapshot, calibratedTimeOffsetMilliseconds)
            .addingTimeInterval(freshDuration)
    }

    static func date(
        for snapshot: ForecastWidgetSnapshot,
        calibratedTimeOffsetMilliseconds: Int = 0
    ) -> Date {
        publicationDeviceDate(snapshot, calibratedTimeOffsetMilliseconds)
            .addingTimeInterval(hardExpiryDuration)
    }

    static func freshness(
        of snapshot: ForecastWidgetSnapshot,
        at deviceDate: Date,
        calibratedTimeOffsetMilliseconds: Int = 0
    ) -> Freshness {
        let publication = publicationDeviceDate(
            snapshot, calibratedTimeOffsetMilliseconds
        )
        let age = deviceDate.timeIntervalSince(publication)
        guard snapshot.updateTime > 0, age.isFinite,
              age >= -maximumFutureSkew,
              age < hardExpiryDuration else { return .expired }
        return age < freshDuration ? .fresh : .stale
    }

    private static func publicationDeviceDate(
        _ snapshot: ForecastWidgetSnapshot, _ offsetMilliseconds: Int
    ) -> Date {
        Date(timeIntervalSince1970: TimeInterval(snapshot.updateTime) / 1_000)
            .addingTimeInterval(-TimeInterval(offsetMilliseconds) / 1_000)
    }

    /// All dates are in the device clock domain. Bound the lead to two
    /// minutes and requests to at least five minutes apart in Release.
    /// A shorter configured interval (DEBUG) keeps its existing cadence.
    /// If expiry is too close, prefer the request floor over a retry loop;
    /// the independently supplied expiry entry removes the predictions.
    static func requestedReloadDate(
        now: Date,
        normalReloadDate: Date,
        expiry: Date
    ) -> Date {
        guard expiry > now else { return normalReloadDate }
        let interval = max(0, normalReloadDate.timeIntervalSince(now))
        let earliest = now.addingTimeInterval(min(5 * 60, interval))
        let beforeExpiry = expiry.addingTimeInterval(-min(2 * 60, interval))
        return min(normalReloadDate, max(earliest, beforeExpiry))
    }

    static func isUsable(
        _ snapshot: ForecastWidgetSnapshot,
        at deviceDate: Date,
        calibratedTimeOffsetMilliseconds: Int = 0
    ) -> Bool {
        freshness(
            of: snapshot, at: deviceDate,
            calibratedTimeOffsetMilliseconds: calibratedTimeOffsetMilliseconds
        ) != .expired
    }
}
