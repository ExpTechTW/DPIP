import Foundation
import WidgetKit

/// What one refresh achieved, as far as the next reload is concerned.
enum WidgetRefreshOutcome: Equatable, Sendable {
    /// The target's current weather is as new as the server's: written now,
    /// or the cache already held that observation or a newer one.
    case refreshed
    /// Retrying soon would fail the same way: no location permission, a
    /// target missing from the catalog, a place outside every township, or a
    /// station with no observation.
    case unavailable
    /// A retry may succeed: the network, a timeout, or storage failed.
    case failed
}

/// Storage the refresher writes through; `WidgetTargetStore` in production.
protocol WidgetRefreshStoring: Sendable {
    func loadCurrent(for target: WidgetLocationTarget)
        -> CurrentWeatherWidgetSnapshot?
    /// Deletes everything kept for a target the app no longer has.
    func removeAll(for target: WidgetLocationTarget) throws
    func beginCurrentWrite(for address: CurrentWeatherSnapshotAddress) throws
        -> CurrentWeatherSnapshotWriteToken
    func commitCurrent(
        _ snapshot: CurrentWeatherWidgetSnapshot,
        using token: CurrentWeatherSnapshotWriteToken
    ) throws -> CurrentWeatherSnapshotWriteResult
    func writeForecast(
        _ snapshot: ForecastWidgetSnapshot,
        for target: WidgetLocationTarget
    ) throws -> Bool
    func writeRain(
        _ snapshot: RainTrendWidgetSnapshot,
        for target: WidgetLocationTarget
    ) throws
}

extension WidgetTargetStore: WidgetRefreshStoring {}

/// The one refresh path behind every timeline: resolve the target's place,
/// fetch its parts — current weather, and for Medium and Large the hourly
/// forecast and the next-hour rain — in parallel, and commit each part as
/// soon as it arrives.
///
/// Everything runs under one budget. WidgetKit gives `getTimeline` a limited
/// time and does not say how long, and a serial chain of location, clock,
/// observation and forecast could outlast it, delivering no timeline at all.
/// At the deadline whatever is committed stays committed; the rest is
/// abandoned for the next reload.
struct WidgetRefresher: Sendable {
    static let defaultBudget: TimeInterval = 12

    struct Dependencies: Sendable {
        var resolveSaved: @Sendable (WidgetLocationTarget)
            -> WidgetResolvedWeatherLocation?
        /// A saved place the app's catalog no longer lists; see
        /// `SavedWidgetLocationResolver.isRemoved`.
        var isRemoved: @Sendable (WidgetLocationTarget) -> Bool = { _ in false }
        var acquireCurrentLocation: @MainActor @Sendable () async
            -> WidgetCurrentLocationResult
        var resolveTownship: @Sendable (WidgetCurrentLocation)
            -> WidgetResolvedWeatherLocation?
        var fetchWeather: @Sendable (Double, Double) async throws
            -> CurrentWeatherRemoteDTO?
        var fetchForecast: @Sendable (String) async throws -> ForecastRemoteDTO
        /// The next hour's rain for a township; the date is a dry hour's origin.
        var fetchRain: @Sendable (String, Date) async throws -> RainHourTrend
        /// Starts or joins a server-time synchronization.
        var synchronizeClock: @Sendable () async -> Void
        /// The best time sample available now: calibrated when any anchor is
        /// usable, otherwise the device clock with a zero offset.
        var sampleClock: @Sendable () async -> CurrentWeatherSnapshotTime
        var now: @Sendable () -> Date
    }

    let store: any WidgetRefreshStoring
    let dependencies: Dependencies
    var budget: TimeInterval = defaultBudget

    func refresh(
        target: WidgetLocationTarget,
        family: WidgetFamily
    ) async -> WidgetRefreshOutcome {
        guard let source = target.sourceIdentifier,
              let address = CurrentWeatherSnapshotAddress(sourceIdentifier: source)
        else {
            return .unavailable
        }
        let token: CurrentWeatherSnapshotWriteToken
        do {
            token = try store.beginCurrentWrite(for: address)
        } catch {
            return .failed
        }

        let progress = WidgetRefreshProgress()
        let deadline = WidgetDeadline.uptime() + budget
        let finished = await WidgetDeadline.run(within: budget) {
            await perform(
                target: target, family: family, token: token,
                deadline: deadline, progress: progress
            )
        }
        #if DEBUG
        if finished == nil {
            WidgetWeatherRefreshDiagnostics.log("refresh budget exhausted")
        }
        #endif
        return finished ?? progress.outcome ?? .failed
    }

    private func perform(
        target: WidgetLocationTarget,
        family: WidgetFamily,
        token: CurrentWeatherSnapshotWriteToken,
        deadline: TimeInterval,
        progress: WidgetRefreshProgress
    ) async -> WidgetRefreshOutcome {
        // Server time does not depend on the place, so it starts first and
        // overlaps the location fix.
        let clock = Task { await dependencies.synchronizeClock() }

        let resolution = await resolve(target)
        let location: WidgetResolvedWeatherLocation?
        let locationOutcome: WidgetRefreshOutcome?
        switch resolution {
        case .resolved(let resolved):
            location = resolved
            locationOutcome = nil
        case .unresolved(let outcome):
            location = nil
            locationOutcome = outcome
            progress.record(outcome)
        }
        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "location " + (location.map {
                "resolved regionCode=\($0.regionCode)"
            } ?? "unresolved")
        )
        #endif

        // Without a fresh fix, Current Location's forecast still follows the
        // township its cache shows. A saved place missing from the catalog
        // has been removed in the app, and fetches nothing.
        let regionCode = location?.regionCode
            ?? (target == .currentLocation
                ? store.loadCurrent(for: target)?.regionCode : nil)
        let wantsForecast = ForecastWidgetFamilyPolicy.supportsForecast(family)

        async let observation = fetchObservation(location)
        async let forecast = fetchForecast(wantsForecast ? regionCode : nil)
        // The rain chart shares the hourly row's place, so it follows the
        // same families.
        async let rain = fetchRain(wantsForecast ? regionCode : nil)

        var outcome = locationOutcome ?? .failed
        if let location {
            switch await observation {
            case .success(let dto?):
                let time = await clockSample(after: clock, deadline: deadline)
                outcome = commitCurrent(
                    CurrentWeatherWidgetSnapshotFactory.make(
                        observation: dto, location: location, time: time
                    ),
                    token: token
                )
            case .success(nil):
                outcome = .unavailable
            case .failure:
                outcome = .failed
            }
            progress.record(outcome)
        }

        if let response = await forecast, let regionCode {
            commitForecast(response, target: target, regionCode: regionCode)
        }
        if let trend = await rain, let regionCode {
            commitRain(trend, target: target, regionCode: regionCode)
        }
        return outcome
    }

    // MARK: Location

    private enum Resolution {
        case resolved(WidgetResolvedWeatherLocation)
        case unresolved(WidgetRefreshOutcome)
    }

    private func resolve(_ target: WidgetLocationTarget) async -> Resolution {
        switch target {
        case .saved:
            if let location = dependencies.resolveSaved(target) {
                return .resolved(location)
            }
            // Removed in the app: its last reading must not stay on screen
            // indefinitely, and nothing will ever refresh it. The widget shows
            // no data until it is pointed at a place the app still has.
            if dependencies.isRemoved(target) {
                try? store.removeAll(for: target)
                #if DEBUG
                WidgetWeatherRefreshDiagnostics.log("saved target removed")
                #endif
            }
            return .unresolved(.unavailable)
        case .currentLocation:
            switch await dependencies.acquireCurrentLocation() {
            case .acquired(let fix):
                guard let location = dependencies.resolveTownship(fix),
                      location.address == .currentLocation
                else {
                    return .unresolved(.unavailable)
                }
                return .resolved(location)
            case .unavailable:
                return .unresolved(.unavailable)
            case .timedOut, .failed:
                return .unresolved(.failed)
            }
        case .invalid:
            return .unresolved(.unavailable)
        }
    }

    // MARK: Current weather

    private func fetchObservation(
        _ location: WidgetResolvedWeatherLocation?
    ) async -> Result<CurrentWeatherRemoteDTO?, Error> {
        guard let location else { return .success(nil) }
        do {
            // The township centroid, never the precise fix: the township is
            // what the widget names, and the fix stays on the device.
            return .success(try await dependencies.fetchWeather(
                location.latitude, location.longitude
            ))
        } catch {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log("weather failed")
            #endif
            return .failure(error)
        }
    }

    /// Waits for the synchronization only while the budget allows, then
    /// samples whatever calibration exists. A clock that cannot be reached
    /// never costs the observation that already arrived.
    private func clockSample(
        after synchronization: Task<Void, Never>,
        deadline: TimeInterval
    ) async -> CurrentWeatherSnapshotTime {
        let remaining = deadline - WidgetDeadline.uptime() - 0.5
        if remaining > 0 {
            _ = await WidgetDeadline.run(within: remaining) {
                await synchronization.value
            }
        }
        return await dependencies.sampleClock()
    }

    private func commitCurrent(
        _ snapshot: CurrentWeatherWidgetSnapshot,
        token: CurrentWeatherSnapshotWriteToken
    ) -> WidgetRefreshOutcome {
        do {
            let result = try store.commitCurrent(snapshot, using: token)
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log(
                "snapshot \(result == .written ? "written" : "superseded") "
                    + "regionCode=\(snapshot.regionCode) "
                    + "observationTime=\(snapshot.observationTime)"
            )
            #endif
            // A rejected write means the cache already holds this
            // observation or a newer one: nothing is left to fetch.
            return .refreshed
        } catch {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log("snapshot write failed")
            #endif
            return .failed
        }
    }

    // MARK: Forecast

    private func fetchForecast(_ regionCode: String?) async -> ForecastRemoteDTO? {
        guard let regionCode else { return nil }
        return try? await dependencies.fetchForecast(regionCode)
    }

    /// Commits only against the township the target's current weather now
    /// shows: a Current Location response for township A that lands after
    /// the snapshot moved to B is dropped.
    private func commitForecast(
        _ response: ForecastRemoteDTO,
        target: WidgetLocationTarget,
        regionCode: String
    ) {
        let now = dependencies.now()
        guard !response.points.isEmpty,
              let current = store.loadCurrent(for: target),
              current.regionCode == regionCode,
              let snapshot = ForecastWidgetSnapshot(
                  sourceIdentifier: target.sourceIdentifier ?? "",
                  regionCode: regionCode,
                  updateTime: response.updateTime,
                  receivedAt: Int64(now.timeIntervalSince1970 * 1_000),
                  points: response.points
              ),
              ForecastWidgetExpiry.isUsable(
                  snapshot, at: now,
                  calibratedTimeOffsetMilliseconds:
                      current.calibratedTimeOffsetMilliseconds
              )
        else {
            return
        }
        _ = try? store.writeForecast(snapshot, for: target)
    }
}

extension WidgetRefresher {
    // MARK: Rain

    fileprivate func fetchRain(_ regionCode: String?) async -> RainHourTrend? {
        guard let regionCode else { return nil }
        do {
            return try await dependencies.fetchRain(regionCode, dependencies.now())
        } catch {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log("rain trend failed")
            #endif
            return nil
        }
    }

    /// Same township rule as the forecast. The newest fetch always replaces
    /// the cache: a dry answer must clear an earlier rainy one.
    fileprivate func commitRain(
        _ trend: RainHourTrend,
        target: WidgetLocationTarget,
        regionCode: String
    ) {
        guard let source = target.sourceIdentifier,
              store.loadCurrent(for: target)?.regionCode == regionCode
        else {
            return
        }
        try? store.writeRain(
            RainTrendWidgetSnapshot(
                sourceIdentifier: source, regionCode: regionCode, trend: trend
            ),
            for: target
        )
    }
}

/// The outcome committed so far, readable once the budget runs out.
final class WidgetRefreshProgress: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: WidgetRefreshOutcome?

    var outcome: WidgetRefreshOutcome? { lock.withLock { stored } }

    func record(_ outcome: WidgetRefreshOutcome) {
        lock.withLock { stored = outcome }
    }
}

/// Bounded waiting that returns on time even when the work cannot be
/// cancelled — a Core Location request or a UDP exchange keeps running to
/// its own timeout, but the caller no longer waits for it.
enum WidgetDeadline {
    static func uptime() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    static func run<T: Sendable>(
        within seconds: TimeInterval,
        _ operation: @escaping @Sendable () async -> T
    ) async -> T? {
        let gate = WidgetDeadlineGate<T>()
        return await withCheckedContinuation { continuation in
            gate.install(continuation)
            let work = Task { gate.finish(await operation()) }
            let timer = Task {
                try? await Task.sleep(
                    nanoseconds: UInt64(max(0, seconds) * 1_000_000_000)
                )
                if gate.finish(nil) { work.cancel() }
            }
            gate.install(timer: timer)
        }
    }
}

private final class WidgetDeadlineGate<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T?, Never>?
    private var timer: Task<Void, Never>?
    private var finished = false

    func install(_ continuation: CheckedContinuation<T?, Never>) {
        lock.withLock { self.continuation = continuation }
    }

    func install(timer: Task<Void, Never>) {
        let cancelNow = lock.withLock { () -> Bool in
            if finished { return true }
            self.timer = timer
            return false
        }
        if cancelNow { timer.cancel() }
    }

    /// Resumes the waiter once; returns whether this call was the one.
    @discardableResult
    func finish(_ value: T?) -> Bool {
        let (continuation, timer) = lock.withLock {
            () -> (CheckedContinuation<T?, Never>?, Task<Void, Never>?) in
            guard !finished else { return (nil, nil) }
            finished = true
            defer { self.continuation = nil; self.timer = nil }
            return (self.continuation, self.timer)
        }
        guard let continuation else { return false }
        timer?.cancel()
        continuation.resume(returning: value)
        return true
    }
}
