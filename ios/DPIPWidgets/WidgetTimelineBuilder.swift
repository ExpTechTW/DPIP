import Foundation
import WidgetKit

struct DPIPWidgetTimelinePlan: Sendable {
    let snapshot: CurrentWeatherWidgetSnapshot?
    let forecast: ForecastWidgetSnapshot?
    let states: [CurrentWeatherWidgetTimelineState]
    let reloadDate: Date

    func forecast(at date: Date) -> ForecastWidgetSnapshot? {
        guard let forecast, let snapshot,
              ForecastWidgetExpiry.isUsable(
                  forecast,
                  at: date,
                  calibratedTimeOffsetMilliseconds:
                      snapshot.calibratedTimeOffsetMilliseconds
              ) else {
            return nil
        }
        return forecast
    }
}

/// Turns what is cached for a target into entries and a reload date.
///
/// Entries are free; reloads are rationed by WidgetKit and may run late. So
/// every change the cache already implies gets its own entry — the stale
/// boundary, the day/night transition, the forecast's soft and hard expiry,
/// each whole hour of the hourly row — and the reload is only for new data.
struct WidgetTimelineBuilder: Sendable {
    let staleAfter: TimeInterval
    /// After a refresh that delivered, or could not have delivered, anything.
    let refreshInterval: TimeInterval
    /// After a refresh that failed: the first retry, and what each further
    /// failure in a row adds, up to `refreshInterval`.
    let retryInterval: TimeInterval

    init(
        staleAfter: TimeInterval = CurrentWeatherWidgetTimeline.defaultStaleAfter,
        refreshInterval: TimeInterval,
        retryInterval: TimeInterval? = nil
    ) {
        self.staleAfter = staleAfter
        self.refreshInterval = refreshInterval
        self.retryInterval = retryInterval ?? refreshInterval
    }

    /// The wait after `count` failed refreshes in a row: `retryInterval` for
    /// the first, one more for each after it, never longer than a successful
    /// refresh waits — ten, twenty, then thirty minutes. A target that keeps
    /// failing, such as Current Location with no fix in reach, would
    /// otherwise ask for a reload every ten minutes: about 144 a day, against
    /// the 40 to 70 WidgetKit typically grants a widget.
    func retryDelay(afterConsecutiveFailures count: Int) -> TimeInterval {
        min(
            retryInterval * Double(max(1, count)),
            max(retryInterval, refreshInterval)
        )
    }

    /// - Parameter consecutiveFailures: failed refreshes in a row for this
    ///   target, `outcome` included; read only when `outcome` is `.failed`.
    func plan(
        snapshot: CurrentWeatherWidgetSnapshot?,
        forecast: ForecastWidgetSnapshot?,
        outcome: WidgetRefreshOutcome?,
        consecutiveFailures: Int = 1,
        deviceNow: Date
    ) -> DPIPWidgetTimelinePlan {
        var states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot,
            deviceNow: deviceNow,
            staleAfter: staleAfter
        )
        // Only a failed attempt retries sooner. A target that cannot resolve
        // (no permission, not in the catalog) would fail the same way again.
        var reloadDate = deviceNow.addingTimeInterval(
            outcome == .failed
                ? retryDelay(afterConsecutiveFailures: consecutiveFailures)
                : refreshInterval
        )
        guard let snapshot else {
            return DPIPWidgetTimelinePlan(
                snapshot: nil, forecast: nil,
                states: states, reloadDate: reloadDate
            )
        }

        // The stale boundary must bring a real fetch, not merely another
        // entry drawing the same observation as stale.
        let staleAt = CurrentWeatherWidgetTimeline.staleDate(
            for: snapshot, staleAfter: staleAfter
        )
        if staleAt > deviceNow {
            reloadDate = min(reloadDate, staleAt)
        }

        if let forecast {
            let offset = snapshot.calibratedTimeOffsetMilliseconds
            let expiry = ForecastWidgetExpiry.date(
                for: forecast, calibratedTimeOffsetMilliseconds: offset
            )
            reloadDate = ForecastWidgetExpiry.requestedReloadDate(
                now: deviceNow,
                normalReloadDate: reloadDate,
                expiry: expiry
            )
            // Reload eligibility is not an execution guarantee. Schedule both
            // publication transitions even beyond the requested reload.
            let boundaries = [
                ForecastWidgetExpiry.staleDate(
                    for: forecast, calibratedTimeOffsetMilliseconds: offset
                ),
                expiry,
            ] + CurrentWeatherWidgetTimeline.hourBoundaries(
                for: snapshot, after: deviceNow, before: expiry
            )
            for boundary in boundaries
            where boundary > deviceNow
                && !states.contains(where: { $0.date == boundary }) {
                states.append(CurrentWeatherWidgetTimeline.state(
                    snapshot: snapshot, at: boundary, staleAfter: staleAfter
                ))
            }
            states.sort { $0.date < $1.date }
        }

        return DPIPWidgetTimelinePlan(
            snapshot: snapshot,
            forecast: forecast,
            states: states,
            reloadDate: reloadDate
        )
    }
}

/// One `getTimeline`: refresh the target, then plan from what is cached.
///
/// Planning always reads the cache after the refresh, never the refresh's own
/// result, so a failed refresh still shows the target's last good data.
struct DPIPWidgetTimelinePlanner: Sendable {
    typealias LoadSnapshot = @Sendable (WidgetLocationTarget)
        -> CurrentWeatherWidgetSnapshot?
    typealias LoadForecast = @Sendable (WidgetLocationTarget, String, Date)
        -> ForecastWidgetSnapshot?
    typealias Refresh = @Sendable (WidgetLocationTarget, WidgetFamily) async
        -> WidgetRefreshOutcome
    /// Remembers a refresh's outcome against its target and returns the
    /// target's failed refreshes in a row, this one included.
    typealias RecordOutcome = @Sendable (WidgetLocationTarget, WidgetRefreshOutcome)
        -> Int
    typealias Now = @Sendable () -> Date

    let builder: WidgetTimelineBuilder
    let loadSnapshot: LoadSnapshot
    var loadForecast: LoadForecast = { _, _, _ in nil }
    let refresh: Refresh
    /// Remembers nothing by default: every failure is the first.
    var recordOutcome: RecordOutcome = { _, outcome in
        WidgetRefreshFailures.count(after: outcome, following: 0)
    }
    let now: Now

    func plan(
        for target: WidgetLocationTarget,
        family: WidgetFamily = .systemSmall
    ) async -> DPIPWidgetTimelinePlan {
        let outcome: WidgetRefreshOutcome?
        if target.sourceIdentifier == nil {
            outcome = nil
        } else {
            outcome = await refresh(target, family)
        }
        let failures = outcome.map { recordOutcome(target, $0) } ?? 0

        let deviceNow = now()
        let snapshot = loadSnapshot(target)
        let forecast: ForecastWidgetSnapshot?
        if ForecastWidgetFamilyPolicy.supportsForecast(family),
           let snapshot, target.matches(snapshot: snapshot) {
            forecast = loadForecast(target, snapshot.regionCode, deviceNow)
        } else {
            forecast = nil
        }
        let plan = builder.plan(
            snapshot: snapshot, forecast: forecast,
            outcome: outcome, consecutiveFailures: failures,
            deviceNow: deviceNow
        )
        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "timeline outcome=\(outcome.map { "\($0)" } ?? "none") "
                + "failures=\(failures) "
                + WidgetWeatherRefreshDiagnostics.snapshotSummary(snapshot)
                + " entries=\(plan.states.count) "
                + "reloadDateUnix=\(Int(plan.reloadDate.timeIntervalSince1970))"
        )
        #endif
        return plan
    }
}

/// Failed refreshes in a row for one target: what the retry backs off by.
enum WidgetRefreshFailures {
    /// The count stops here; the retry reached its cap long before.
    static let maximum = 100

    /// A stored count, held to `0...maximum` whatever was written.
    static func clamped(_ count: Int) -> Int {
        min(max(0, count), maximum)
    }

    /// The count after `outcome`: a failure adds one, a refresh clears it,
    /// and an unavailable target, which reloads on the regular cycle
    /// anyway, leaves it as it was.
    static func count(
        after outcome: WidgetRefreshOutcome,
        following previous: Int
    ) -> Int {
        let previous = clamped(previous)
        switch outcome {
        case .failed:
            return min(previous + 1, maximum)
        case .refreshed:
            return 0
        case .unavailable:
            return previous
        }
    }
}
