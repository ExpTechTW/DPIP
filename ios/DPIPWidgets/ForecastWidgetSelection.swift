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

        // Keep this distance helper usable for the current hour's day/night
        // presentation. upcomingPoints separately requires the next whole hour.
        if forecastMinutes == hour * 60 { return 0 }

        // A clock label has no date. A past label may mean tomorrow only
        // within this short horizon; otherwise it is too ambiguous to show.
        // Keep future distances relative to the instant (not the hour start)
        // to preserve the 12-hour horizon and day/night transition timing.
        let currentMinutes = hour * 60 + minute
        let distance = (forecastMinutes - currentMinutes + minutesPerDay)
            % minutesPerDay
        return distance <= maximumFutureMinutes ? distance : nil
    }

    /// Start strictly after the reference's Taipei hour; retain API labels and
    /// original order for equal distances, with a 12-hour reference horizon.
    static func upcomingPoints(
        _ points: [ForecastWidgetPoint],
        at calibratedDate: Date,
        observationTime: Int? = nil,
        limit: Int
    ) -> [ForecastWidgetPoint] {
        guard limit > 0 else { return [] }
        let reference = selectionReference(
            observationTime: observationTime, at: calibratedDate
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = taipei
        let minutesUntilNextHour = 60 - calendar.component(.minute, from: reference)
        return Array(points.enumerated().compactMap { index, point
            -> (index: Int, distance: Int, point: ForecastWidgetPoint)? in
            guard let distance = minutesAhead(
                for: point.time, at: reference
            ), distance >= minutesUntilNextHour else {
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

    /// Observation epochs are already calibrated Unix seconds; never add the
    /// device offset to them. Reuse Current Weather's stale boundary. Missing,
    /// invalid, future or stale observations use the next calibrated-clock hour
    /// instead, so a failed weather refresh cannot keep clearly past hours.
    /// Publication/receipt timestamps only govern expiry, never selection.
    private static func selectionReference(
        observationTime: Int?, at calibratedDate: Date
    ) -> Date {
        guard let observationTime, observationTime > 0 else {
            return calibratedDate
        }
        let age = calibratedDate.timeIntervalSince1970 - TimeInterval(observationTime)
        guard age >= 0, age < CurrentWeatherWidgetTimeline.defaultStaleAfter else {
            return calibratedDate
        }
        return Date(timeIntervalSince1970: TimeInterval(observationTime))
    }
}
