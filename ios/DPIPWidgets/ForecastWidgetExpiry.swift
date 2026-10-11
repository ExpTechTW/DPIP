import Foundation

enum ForecastWidgetExpiry {
    /// Device-clock cache/display deadline. Neither input is a point valid time.
    /// Publication uses server time while receipt uses device time; compare
    /// them in calibrated time before scheduling the deadline on WidgetKit.
    static func date(
        for snapshot: ForecastWidgetSnapshot,
        calibratedTimeOffsetMilliseconds: Int = 0
    ) -> Date {
        let offset = TimeInterval(calibratedTimeOffsetMilliseconds) / 1_000
        let publishedCalibrated = Date(
            timeIntervalSince1970: TimeInterval(snapshot.updateTime) / 1_000
        )
        let receivedDevice = Date(
            timeIntervalSince1970: TimeInterval(snapshot.receivedAt) / 1_000
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        let nextTaipeiHour = calendar.dateInterval(
            of: .hour,
            for: receivedDevice.addingTimeInterval(offset)
        )!.end
        return min(
            publishedCalibrated.addingTimeInterval(30 * 60),
            nextTaipeiHour
        ).addingTimeInterval(-offset)
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
        deviceDate < self.date(
            for: snapshot,
            calibratedTimeOffsetMilliseconds: calibratedTimeOffsetMilliseconds
        )
    }
}
