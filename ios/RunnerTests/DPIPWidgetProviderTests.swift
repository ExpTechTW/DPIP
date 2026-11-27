import Foundation
import WidgetKit
import XCTest

final class DPIPWidgetProviderTests: XCTestCase {
    private let staleAfter: TimeInterval = 60 * 60
    private let now = Date(timeIntervalSince1970: 10_000)

    func testSavedTargetInvokesRefresh() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            snapshots: [(target, snapshot(for: target))]
        )

        _ = await planner(store: store).plan(for: target)

        XCTAssertEqual(store.savedRefreshTargets, [target])
        XCTAssertEqual(store.currentRefreshCount, 0)
    }

    func testSavedTargetReloadsCacheAfterSuccessfulRefresh() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let oldSnapshot = snapshot(
            for: target,
            stationName: "old-station"
        )
        let refreshedSnapshot = snapshot(
            for: target,
            stationName: "refreshed-station"
        )
        let store = ProviderTimelineTestStore(
            refreshResult: .refreshed,
            snapshots: [(target, oldSnapshot)],
            refreshedSnapshot: refreshedSnapshot
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(
            store.events,
            [.load(target), .refreshSaved(target), .load(target)]
        )
        XCTAssertEqual(plan.snapshot?.stationName, "refreshed-station")
    }

    func testSavedRefreshFailureKeepsCachedSnapshot() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            snapshots: [
                (target, snapshot(
                    for: target,
                    stationName: "cached-station"
                )),
            ]
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(plan.snapshot?.stationName, "cached-station")
        XCTAssertEqual(store.cachedSnapshot(for: target)?.regionCode, "407")
    }

    func testSavedNoObservationKeepsCachedSnapshot() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let store = ProviderTimelineTestStore(
            refreshResult: .noObservation,
            snapshots: [
                (target, snapshot(
                    for: target,
                    stationName: "cached-station"
                )),
            ]
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(plan.snapshot?.stationName, "cached-station")
        XCTAssertEqual(store.cachedSnapshot(for: target)?.regionCode, "407")
    }

    func testSavedUnavailableKeepsSameLocationCache() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let otherTarget = WidgetLocationTarget.saved(regionCode: "242")
        let store = ProviderTimelineTestStore(
            refreshResult: .unavailable,
            snapshots: [
                (target, snapshot(
                    for: target,
                    stationName: "region-407"
                )),
                (otherTarget, snapshot(
                    for: otherTarget,
                    stationName: "region-242"
                )),
            ]
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(plan.snapshot?.stationName, "region-407")
        XCTAssertEqual(store.loadTargets, [target, target])
    }

    func testCurrentLocationInvokesOnlyCurrentRefresh() async {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .refreshed,
            currentRefreshResult: .refreshed,
            snapshots: [(target, snapshot(for: target))]
        )

        _ = await planner(store: store).plan(for: target)

        XCTAssertTrue(store.savedRefreshTargets.isEmpty)
        XCTAssertEqual(store.currentRefreshCount, 1)
    }

    func testCurrentLocationSuccessReloadsCurrentLocationCache() async {
        let target = WidgetLocationTarget.currentLocation
        let refreshedSnapshot = snapshot(
            for: target,
            stationName: "refreshed-current-location"
        )
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            currentRefreshResult: .refreshed,
            snapshots: [(target, snapshot(for: target))],
            refreshedSnapshot: refreshedSnapshot
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(
            store.events,
            [.load(target), .refreshCurrent, .load(target)]
        )
        XCTAssertEqual(
            plan.snapshot?.stationName,
            "refreshed-current-location"
        )
    }

    func testCurrentLocationFailureReloadsStaleCache() async {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            currentRefreshResult: .failed,
            snapshots: [
                (target, snapshot(
                    for: target,
                    stationName: "current-location-cache"
                )),
            ]
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(
            plan.snapshot?.stationName,
            "current-location-cache"
        )
        XCTAssertEqual(
            store.events,
            [.load(target), .refreshCurrent, .load(target)]
        )
    }

    func testCurrentLocationFailureWithoutCacheKeepsNoDataBehavior() async {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            currentRefreshResult: .failed,
            snapshots: []
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertNil(plan.snapshot)
        XCTAssertEqual(plan.states.count, 1)
        XCTAssertEqual(
            store.events,
            [.load(target), .refreshCurrent, .load(target)]
        )
    }

    func testInvalidTargetDoesNotInvokeRefreshOrUseOtherCache() async {
        let target = WidgetLocationTarget.invalid(
            identifier: "region:invalid"
        )
        let savedTarget = WidgetLocationTarget.saved(regionCode: "407")
        let store = ProviderTimelineTestStore(
            refreshResult: .refreshed,
            snapshots: [(savedTarget, snapshot(for: savedTarget))]
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertTrue(store.savedRefreshTargets.isEmpty)
        XCTAssertEqual(store.currentRefreshCount, 0)
        XCTAssertNil(plan.snapshot)
        XCTAssertEqual(store.loadTargets, [target])
    }

    #if DEBUG
    func testDebugTimelineRequestsRefreshAfterSixtySeconds() async {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            snapshots: []
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(DPIPWidgetProviderRuntime.refreshInterval, 60)
        XCTAssertEqual(DPIPWidgetProviderRuntime.retryInterval, 60)
        XCTAssertGreaterThan(plan.reloadDate, now)
        XCTAssertEqual(
            plan.reloadDate,
            now.addingTimeInterval(60)
        )
    }
    #else
    func testReleaseTimelineRetriesFailuresAfterTenMinutes() async {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            currentRefreshResult: .failed,
            snapshots: []
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(DPIPWidgetProviderRuntime.refreshInterval, 30 * 60)
        XCTAssertEqual(DPIPWidgetProviderRuntime.retryInterval, 10 * 60)
        XCTAssertEqual(
            plan.reloadDate,
            now.addingTimeInterval(10 * 60)
        )
    }
    #endif

    func testSuccessfulRefreshReloadsAfterTheRefreshInterval() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let store = ProviderTimelineTestStore(
            refreshResult: .refreshed,
            snapshots: [(target, snapshot(for: target, observationTime: 10_000))]
        )

        let plan = await planner(
            store: store, refreshInterval: 30 * 60, retryInterval: 10 * 60
        ).plan(for: target)

        XCTAssertEqual(plan.reloadDate, now.addingTimeInterval(30 * 60))
    }

    func testFailedRefreshRetriesSooner() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            snapshots: [(target, snapshot(for: target, observationTime: 10_000))]
        )

        let plan = await planner(
            store: store, refreshInterval: 30 * 60, retryInterval: 10 * 60
        ).plan(for: target)

        XCTAssertEqual(plan.reloadDate, now.addingTimeInterval(10 * 60))
    }

    func testUnresolvableTargetDoesNotRetrySooner() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let store = ProviderTimelineTestStore(
            refreshResult: .unavailable,
            snapshots: []
        )

        let plan = await planner(
            store: store, refreshInterval: 30 * 60, retryInterval: 10 * 60
        ).plan(for: target)

        XCTAssertEqual(plan.reloadDate, now.addingTimeInterval(30 * 60))
    }

    func testStaleBoundaryBeforeTheNextReloadBringsTheReloadForward() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        // Observed 45 minutes ago: stale in 15 minutes, before the 30-minute
        // reload, so that boundary must be a reload rather than an entry only.
        let store = ProviderTimelineTestStore(
            refreshResult: .refreshed,
            snapshots: [(target, snapshot(
                for: target, observationTime: 10_000 - 45 * 60
            ))]
        )

        let plan = await planner(
            store: store, refreshInterval: 30 * 60, retryInterval: 10 * 60
        ).plan(for: target)

        XCTAssertEqual(plan.reloadDate, now.addingTimeInterval(15 * 60))
        XCTAssertEqual(
            plan.states.map(\.date),
            [now, now.addingTimeInterval(15 * 60)]
        )
        XCTAssertEqual(plan.states.map(\.isStale), [false, true])
    }

    func testAlreadyStaleObservationKeepsTheNormalInterval() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let store = ProviderTimelineTestStore(
            refreshResult: .refreshed,
            snapshots: [(target, snapshot(
                for: target, observationTime: 10_000 - 2 * 60 * 60
            ))]
        )

        let plan = await planner(
            store: store, refreshInterval: 30 * 60, retryInterval: 10 * 60
        ).plan(for: target)

        XCTAssertEqual(plan.reloadDate, now.addingTimeInterval(30 * 60))
        XCTAssertEqual(plan.states.map(\.isStale), [true])
    }

    func testHourBoundariesAreWholeCalibratedHoursOnTheDeviceClock() {
        // The fixture's calibrated clock is 123 ms ahead of the device.
        let snapshot = CurrentWeatherWidgetTestFixtures.snapshot(
            sourceIdentifier: "region:242", regionCode: "242"
        )
        let deviceNow = Date(timeIntervalSince1970: 9_000)

        let hours = CurrentWeatherWidgetTimeline.hourBoundaries(
            for: snapshot,
            after: deviceNow,
            before: deviceNow.addingTimeInterval(3 * 3_600)
        )

        XCTAssertEqual(hours, [3, 4, 5].map {
            Date(timeIntervalSince1970: Double($0) * 3_600 - 0.123)
        })
    }

    func testSnapshotPathIsCacheOnlyAndDoesNotInvokeRefresh() {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .refreshed,
            currentRefreshResult: .refreshed,
            snapshots: [(target, snapshot(for: target))]
        )
        let dependencies = DPIPWidgetProviderDependencies(
            loadSnapshot: store.load,
            timelinePlanner: planner(store: store)
        )

        let loaded = dependencies.snapshot(for: target)

        XCTAssertEqual(loaded?.sourceIdentifier, "current-location")
        XCTAssertEqual(store.loadTargets, [target])
        XCTAssertTrue(store.savedRefreshTargets.isEmpty)
        XCTAssertEqual(store.currentRefreshCount, 0)
    }

    private func planner(
        store: ProviderTimelineTestStore,
        refreshInterval: TimeInterval = DPIPWidgetProviderRuntime.refreshInterval,
        retryInterval: TimeInterval = DPIPWidgetProviderRuntime.retryInterval
    ) -> DPIPWidgetTimelinePlanner {
        let fixedNow = now
        return DPIPWidgetTimelinePlanner(
            staleAfter: staleAfter,
            refreshInterval: refreshInterval,
            retryInterval: retryInterval,
            loadSnapshot: store.load,
            refreshSaved: store.refreshSaved,
            refreshCurrent: store.refreshCurrent,
            now: { fixedNow }
        )
    }

    private func snapshot(
        for target: WidgetLocationTarget,
        stationName: String = "station",
        observationTime: Int = 10_000
    ) -> CurrentWeatherWidgetSnapshot {
        let regionCode: String
        switch target {
        case .saved(let savedRegionCode):
            regionCode = savedRegionCode
        case .currentLocation, .invalid:
            regionCode = "407"
        }

        return CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: target.sourceIdentifier,
            regionCode: regionCode,
            regionName: "測試地區",
            observationTime: observationTime,
            stationName: stationName,
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: false,
            nextDayNightTransitionTime: 0,
            calibratedTimeOffsetMilliseconds: 0,
            temperature: 28,
            humidity: 70,
            rain: 0
        )
    }
}

private enum ProviderTimelineEvent: Equatable {
    case refreshSaved(WidgetLocationTarget)
    case refreshCurrent
    case load(WidgetLocationTarget)
}

private final class ProviderTimelineTestStore: @unchecked Sendable {
    private let lock = NSLock()
    private let savedRefreshResult: CurrentWeatherWidgetRefreshResult
    private let currentRefreshResult: CurrentWeatherWidgetRefreshResult
    private let refreshedSnapshot: CurrentWeatherWidgetSnapshot?

    private var storedSnapshots: [String: CurrentWeatherWidgetSnapshot]
    private var storedEvents: [ProviderTimelineEvent] = []

    init(
        refreshResult: CurrentWeatherWidgetRefreshResult,
        currentRefreshResult: CurrentWeatherWidgetRefreshResult = .failed,
        snapshots: [(
            WidgetLocationTarget,
            CurrentWeatherWidgetSnapshot
        )],
        refreshedSnapshot: CurrentWeatherWidgetSnapshot? = nil
    ) {
        savedRefreshResult = refreshResult
        self.currentRefreshResult = currentRefreshResult
        self.refreshedSnapshot = refreshedSnapshot
        storedSnapshots = Dictionary(
            uniqueKeysWithValues: snapshots.map {
                (Self.key(for: $0.0), $0.1)
            }
        )
    }

    func refreshSaved(
        target: WidgetLocationTarget
    ) async -> CurrentWeatherWidgetRefreshResult {
        recordSavedRefresh(target)
        return savedRefreshResult
    }

    func refreshCurrent() async -> CurrentWeatherWidgetRefreshResult {
        recordCurrentRefresh()
        return currentRefreshResult
    }

    func load(
        target: WidgetLocationTarget
    ) -> CurrentWeatherWidgetSnapshot? {
        lock.lock()
        defer { lock.unlock() }
        storedEvents.append(.load(target))
        return storedSnapshots[Self.key(for: target)]
    }

    func cachedSnapshot(
        for target: WidgetLocationTarget
    ) -> CurrentWeatherWidgetSnapshot? {
        lock.lock()
        defer { lock.unlock() }
        return storedSnapshots[Self.key(for: target)]
    }

    var events: [ProviderTimelineEvent] {
        lock.lock()
        defer { lock.unlock() }
        return storedEvents
    }

    var savedRefreshTargets: [WidgetLocationTarget] {
        events.compactMap { event in
            guard case let .refreshSaved(target) = event else {
                return nil
            }
            return target
        }
    }

    var currentRefreshCount: Int {
        events.filter { $0 == .refreshCurrent }.count
    }

    var loadTargets: [WidgetLocationTarget] {
        events.compactMap { event in
            guard case let .load(target) = event else {
                return nil
            }
            return target
        }
    }

    private func recordSavedRefresh(
        _ target: WidgetLocationTarget
    ) {
        lock.lock()
        defer { lock.unlock() }
        storedEvents.append(.refreshSaved(target))

        if savedRefreshResult == .refreshed,
           let refreshedSnapshot {
            storedSnapshots[Self.key(for: target)] = refreshedSnapshot
        }
    }

    private func recordCurrentRefresh() {
        lock.lock()
        defer { lock.unlock() }
        let target = WidgetLocationTarget.currentLocation
        storedEvents.append(.refreshCurrent)

        if currentRefreshResult == .refreshed,
           let refreshedSnapshot {
            storedSnapshots[Self.key(for: target)] = refreshedSnapshot
        }
    }

    private static func key(
        for target: WidgetLocationTarget
    ) -> String {
        switch target {
        case .currentLocation:
            return "current-location"
        case .saved(let regionCode):
            return "region:\(regionCode)"
        case .invalid(let identifier):
            return "invalid:\(identifier)"
        }
    }
}

final class WidgetHeaderCueTests: XCTestCase {
    /// 15:21 in Taipei.
    private let now = Date(timeIntervalSince1970: 1_790_320_860)

    private func current(observedMinutesAgo minutes: Double = 10) -> CurrentWeatherWidgetSnapshot {
        CurrentWeatherWidgetSnapshot(
            schemaVersion: 7, sourceIdentifier: "region:407", regionCode: "407",
            regionName: "西屯區", observationTime: Int(now.timeIntervalSince1970 - minutes * 60),
            stationName: "西屯", weather: "晴", weatherCode: 100,
            condition: .clear, isNight: false, nextDayNightTransitionTime: 0,
            calibratedTimeOffsetMilliseconds: 0,
            temperature: 28, humidity: 70, rain: 0
        )
    }

    /// Hourly points from 16:00, published `minutes` ago.
    private func forecast(publishedMinutesAgo minutes: Double) -> ForecastWidgetSnapshot {
        ForecastWidgetSnapshot(
            sourceIdentifier: "region:407", regionCode: "407",
            updateTime: Int64((now.timeIntervalSince1970 - minutes * 60) * 1_000),
            receivedAt: Int64(now.timeIntervalSince1970 * 1_000),
            points: (16...20).map {
                ForecastWidgetPoint(
                    time: "\($0):00", temperature: 22, weather: "晴",
                    weatherCode: 100, pop: 10
                )!
            }
        )!
    }

    private func entry(
        isStale: Bool,
        forecast: ForecastWidgetSnapshot? = nil,
        snapshot: CurrentWeatherWidgetSnapshot? = nil,
        hasSnapshot: Bool = true
    ) -> DPIPWidgetEntry {
        DPIPWidgetEntry(
            date: now, snapshot: hasSnapshot ? (snapshot ?? current()) : nil,
            isStale: isStale, isNight: false, forecast: forecast,
            locationTarget: .saved(regionCode: "407")
        )
    }

    func testAStaleObservationIsMarkedInEveryFamily() {
        for family: WidgetFamily in [.systemSmall, .systemMedium, .systemLarge] {
            XCTAssertEqual(entry(isStale: true).headerCue(for: family), .staleObservation, "\(family)")
            XCTAssertNil(entry(isStale: false).headerCue(for: family), "\(family)")
        }
        XCTAssertNil(
            entry(isStale: true, hasSnapshot: false).headerCue(for: .systemMedium),
            "No reading, nothing to mark"
        )
    }

    func testAStaleObservationOutranksAnOutdatedForecast() {
        let outdated = forecast(publishedMinutesAgo: 45)

        XCTAssertEqual(
            entry(isStale: false, forecast: outdated).headerCue(for: .systemMedium),
            .outdatedForecast
        )
        XCTAssertEqual(
            entry(isStale: true, forecast: outdated).headerCue(for: .systemMedium),
            .staleObservation
        )
        XCTAssertNil(
            entry(isStale: false, forecast: forecast(publishedMinutesAgo: 15))
                .headerCue(for: .systemLarge)
        )
        // Small draws no forecast, so only the observation can be marked.
        XCTAssertNil(entry(isStale: false, forecast: outdated).headerCue(for: .systemSmall))
    }

    func testTheCueAppearsFromTheTimelinesStaleBoundary() {
        // Observed 45 minutes ago: stale fifteen minutes from now.
        let snapshot = current(observedMinutesAgo: 45)
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot, deviceNow: now, staleAfter: 60 * 60
        )

        XCTAssertEqual(states.map(\.date), [now, now.addingTimeInterval(15 * 60)])
        XCTAssertEqual(states.map {
            DPIPWidgetEntry(
                date: $0.date, snapshot: snapshot, isStale: $0.isStale,
                isNight: $0.isNight, locationTarget: .saved(regionCode: "407")
            ).headerCue(for: .systemMedium)
        }, [nil, .staleObservation])
    }
}
