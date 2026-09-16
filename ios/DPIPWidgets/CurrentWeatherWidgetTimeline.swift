import Foundation

struct CurrentWeatherWidgetTimelineState: Equatable {
    let date: Date
    let isStale: Bool
    let isNight: Bool
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

        let observationDate = Date(
            timeIntervalSince1970: TimeInterval(snapshot.observationTime)
        )
        let staleAt = observationDate.addingTimeInterval(staleAfter)

        return CurrentWeatherWidgetTimelineState(
            date: date,
            isStale: date >= staleAt,
            isNight: isNight(for: snapshot, at: date)
        )
    }

    static func states(
        snapshot: CurrentWeatherWidgetSnapshot?,
        now: Date,
        staleAfter: TimeInterval
    ) -> [CurrentWeatherWidgetTimelineState] {
        guard let snapshot else {
            return [
                state(
                    snapshot: nil,
                    at: now,
                    staleAfter: staleAfter
                )
            ]
        }

        let observationDate = Date(
            timeIntervalSince1970: TimeInterval(snapshot.observationTime)
        )
        let staleAt = observationDate.addingTimeInterval(staleAfter)
        let transitionAt = Date(
            timeIntervalSince1970:
                TimeInterval(snapshot.nextDayNightTransitionTime)
        )

        var dates = [now]

        if staleAt > now {
            dates.append(staleAt)
        }

        if snapshot.nextDayNightTransitionTime > 0,
           transitionAt > now {
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
        at date: Date
    ) -> Bool {
        guard snapshot.nextDayNightTransitionTime > 0 else {
            return snapshot.isNight
        }

        let transitionAt = Date(
            timeIntervalSince1970:
                TimeInterval(snapshot.nextDayNightTransitionTime)
        )

        return date >= transitionAt
            ? !snapshot.isNight
            : snapshot.isNight
    }
}
