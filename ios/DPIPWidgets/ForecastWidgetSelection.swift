import Foundation

/// Selects display hours from date-free API clock labels at each timeline entry.
enum ForecastWidgetSelection {
    private static let minutesPerDay = 24 * 60
    private static let maximumFutureMinutes = 12 * 60
    private static let taipei = TimeZone(identifier: "Asia/Taipei")!

    /// - Parameter calibratedDate: a calibrated instant. A label is a Taipei
    ///   wall-clock reading of calibrated time, so a device-clock date would
    ///   shift the selection by the calibration offset.
    static func minutesAhead(
        for clockLabel: String,
        at calibratedDate: Date
    ) -> Int? {
        guard let forecastMinutes = ForecastWidgetPoint.minutesSinceMidnight(
            clockLabel
        ) else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = taipei
        let current = calendar.dateComponents(
            [.hour, .minute], from: calibratedDate
        )
        guard let hour = current.hour, let minute = current.minute else {
            return nil
        }

        // A clock label has no date. A past label may mean tomorrow only
        // within this short horizon; otherwise it is too ambiguous to show.
        // The current minute remains eligible for an hourly forecast.
        let currentMinutes = hour * 60 + minute
        let distance = (forecastMinutes - currentMinutes + minutesPerDay)
            % minutesPerDay
        return distance <= maximumFutureMinutes ? distance : nil
    }

    static func upcomingPoints(
        _ points: [ForecastWidgetPoint],
        at calibratedDate: Date,
        limit: Int
    ) -> [ForecastWidgetPoint] {
        guard limit > 0 else { return [] }
        return Array(points.enumerated().compactMap { index, point
            -> (index: Int, distance: Int, point: ForecastWidgetPoint)? in
            guard let distance = minutesAhead(
                for: point.time, at: calibratedDate
            ) else {
                return nil
            }
            return (index, distance, point)
        }.sorted { lhs, rhs in
            if lhs.distance != rhs.distance {
                return lhs.distance < rhs.distance
            }
            return lhs.index < rhs.index
        }.prefix(limit).map { $0.point })
    }
}
