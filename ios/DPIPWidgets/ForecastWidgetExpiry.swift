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
