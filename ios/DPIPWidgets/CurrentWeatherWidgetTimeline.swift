import Foundation

struct CurrentWeatherWidgetTimelineState: Equatable {
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
        let observationDate = Date(
            timeIntervalSince1970: TimeInterval(snapshot.observationTime)
        )
        let staleAt = calibration.deviceDate(
            forCalibratedDate: observationDate.addingTimeInterval(staleAfter)
        )
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
