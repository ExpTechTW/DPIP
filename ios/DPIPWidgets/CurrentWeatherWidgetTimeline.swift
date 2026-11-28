import Foundation

struct CurrentWeatherWidgetTimelineState: Equatable, Sendable {
    /// Device-clock date supplied to WidgetKit for entry scheduling.
    let date: Date
    let isStale: Bool
    let isNight: Bool
}

/// Converts between calibrated/server instants and WidgetKit's device clock.
///
/// The serialized offset is calibrated time minus device time. Widget state
/// comparisons add it to device dates; WidgetKit scheduling subtracts it from
/// calibrated deadlines. An older snapshot decodes with a zero correction.
struct CurrentWeatherWidgetTimeCalibration {
    private let calibratedMinusDevice: TimeInterval

    init(snapshot: CurrentWeatherWidgetSnapshot) {
        calibratedMinusDevice =
            TimeInterval(snapshot.calibratedTimeOffsetMilliseconds) / 1_000
    }

    func calibratedDate(fromDeviceDate date: Date) -> Date {
        date.addingTimeInterval(calibratedMinusDevice)
    }

    func deviceDate(forCalibratedDate date: Date) -> Date {
        date.addingTimeInterval(-calibratedMinusDevice)
    }
}

enum CurrentWeatherWidgetTimeline {
    /// Observations are published ten to twenty minutes after the reading, so
    /// a thirty-minute limit made a fresh fetch stale within one reload.
    static let defaultStaleAfter: TimeInterval = 60 * 60

    /// Device-clock instant at which `snapshot` becomes stale.
    static func staleDate(
        for snapshot: CurrentWeatherWidgetSnapshot,
        staleAfter: TimeInterval
    ) -> Date {
        CurrentWeatherWidgetTimeCalibration(snapshot: snapshot).deviceDate(
            forCalibratedDate: Date(
                timeIntervalSince1970: TimeInterval(snapshot.observationTime)
            ).addingTimeInterval(staleAfter)
        )
    }

    /// Device-clock instants of each whole Taipei hour in `(after, before)`.
    ///
    /// The hourly row picks its first hour from the entry date once the
    /// observation is stale, so without an entry on each hour a delayed
    /// reload keeps showing an hour that has already passed.
    static func hourBoundaries(
        for snapshot: CurrentWeatherWidgetSnapshot,
        after deviceDate: Date,
        before deviceLimit: Date
    ) -> [Date] {
        let calibration = CurrentWeatherWidgetTimeCalibration(
            snapshot: snapshot
        )
        // Taipei is a whole-hour offset from UTC, so UTC hours are its hours.
        let calibrated = calibration.calibratedDate(fromDeviceDate: deviceDate)
            .timeIntervalSince1970
        var hour = (calibrated / 3_600).rounded(.down) * 3_600 + 3_600
        var boundaries: [Date] = []
        while true {
            let device = calibration.deviceDate(
                forCalibratedDate: Date(timeIntervalSince1970: hour)
            )
            guard device < deviceLimit else { break }
            if device > deviceDate { boundaries.append(device) }
            hour += 3_600
        }
        return boundaries
    }

    static func state(
        snapshot: CurrentWeatherWidgetSnapshot?,
        at date: Date,
        staleAfter: TimeInterval
    ) -> CurrentWeatherWidgetTimelineState {
        guard let snapshot else {
            return CurrentWeatherWidgetTimelineState(
                date: date,
                isStale: false,
                isNight: false
            )
        }

        let calibration = CurrentWeatherWidgetTimeCalibration(
            snapshot: snapshot
        )
        let calibratedDate = calibration.calibratedDate(
            fromDeviceDate: date
        )
        let observationDate = Date(
            timeIntervalSince1970: TimeInterval(snapshot.observationTime)
        )
        let staleAt = observationDate.addingTimeInterval(staleAfter)

        return CurrentWeatherWidgetTimelineState(
            date: date,
            isStale: calibratedDate >= staleAt,
            isNight: isNight(for: snapshot, at: calibratedDate)
        )
    }

    static func states(
        snapshot: CurrentWeatherWidgetSnapshot?,
        deviceNow: Date,
        staleAfter: TimeInterval
    ) -> [CurrentWeatherWidgetTimelineState] {
        guard let snapshot else {
            return [
                state(
                    snapshot: nil,
                    at: deviceNow,
                    staleAfter: staleAfter
                )
            ]
        }

        let calibration = CurrentWeatherWidgetTimeCalibration(
            snapshot: snapshot
        )
        let staleAt = staleDate(for: snapshot, staleAfter: staleAfter)
        let transitionAt = calibration.deviceDate(
            forCalibratedDate: Date(
                timeIntervalSince1970:
                    TimeInterval(snapshot.nextDayNightTransitionTime)
            )
        )

        var dates = [deviceNow]

        if staleAt > deviceNow {
            dates.append(staleAt)
        }

        if snapshot.nextDayNightTransitionTime > 0,
           transitionAt > deviceNow {
            // A snapshot deliberately carries only its next solar transition.
            // A later day/night cycle requires a fresh publish from the app.
            dates.append(transitionAt)
        }

        return Array(Set(dates))
            .sorted()
            .map {
                state(
                    snapshot: snapshot,
                    at: $0,
                    staleAfter: staleAfter
                )
            }
    }

    private static func isNight(
        for snapshot: CurrentWeatherWidgetSnapshot,
        at calibratedDate: Date
    ) -> Bool {
        guard snapshot.nextDayNightTransitionTime > 0 else {
            return snapshot.isNight
        }

        let transitionAt = Date(
            timeIntervalSince1970:
                TimeInterval(snapshot.nextDayNightTransitionTime)
        )

        return calibratedDate >= transitionAt
            ? !snapshot.isNight
            : snapshot.isNight
    }
}
