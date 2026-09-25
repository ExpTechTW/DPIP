import Foundation

enum ForecastWidgetExpiry {
    /// Cache/display deadline only. Neither input is a forecast-point time.
    static func date(for snapshot: ForecastWidgetSnapshot) -> Date {
        let published = Date(
            timeIntervalSince1970: TimeInterval(snapshot.updateTime) / 1_000
        )
        let received = Date(
            timeIntervalSince1970: TimeInterval(snapshot.receivedAt) / 1_000
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        let nextTaipeiHour = calendar.dateInterval(
            of: .hour,
            for: received
        )!.end
        return min(published.addingTimeInterval(30 * 60), nextTaipeiHour)
    }

    static func isUsable(_ snapshot: ForecastWidgetSnapshot, at date: Date) -> Bool {
        date < self.date(for: snapshot)
    }
}
