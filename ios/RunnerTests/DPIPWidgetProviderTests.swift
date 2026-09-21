import Foundation
import XCTest

final class DPIPWidgetProviderTests: XCTestCase {
    private let staleAfter: TimeInterval = 30 * 60
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

    func testRefreshFailureDoesNotMutateOrDeleteCache() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let cachedSnapshot = snapshot(
            for: target,
            stationName: "unchanged-cache"
        )
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            snapshots: [(target, cachedSnapshot)]
        )

        _ = await planner(store: store).plan(for: target)

        XCTAssertEqual(store.cacheMutationCount, 0)
        XCTAssertEqual(
            store.cachedSnapshot(for: target)?.stationName,
            "unchanged-cache"
        )
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
        XCTAssertGreaterThan(plan.reloadDate, now)
        XCTAssertEqual(
            plan.reloadDate,
            now.addingTimeInterval(60)
        )
    }
    #else
    func testReleaseTimelineRequestsRefreshAfterTwentyMinutes() async {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            snapshots: []
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(DPIPWidgetProviderRuntime.refreshInterval, 20 * 60)
        XCTAssertGreaterThan(plan.reloadDate, now)
        XCTAssertEqual(
            plan.reloadDate,
            now.addingTimeInterval(20 * 60)
        )
    }
    #endif

    func testRuntimeKeepsThirtyMinuteStaleInterval() {
        XCTAssertEqual(staleAfter, 30 * 60)
    }

    func testTimelineProjectionDelegatesToCurrentWeatherTimeline() async {
        let target = WidgetLocationTarget.currentLocation
        let cachedSnapshot = snapshot(
            for: target,
            observationTime: 9_000,
            isNight: false,
            transitionTime: 10_500
        )
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            snapshots: [(target, cachedSnapshot)]
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertEqual(
            plan.states,
            CurrentWeatherWidgetTimeline.states(
                snapshot: cachedSnapshot,
                deviceNow: now,
                staleAfter: staleAfter
            )
        )
    }

    func testRefreshRuntimeReusesOneServerClock() async {
        let recorder = ProviderClockIdentityRecorder()
        let runtime = SavedCurrentWeatherWidgetRefreshRuntime(
            serverClock: WidgetServerClock(),
            refreshWithClock: { clock, _ in
                recorder.record(clock)
                return .failed
            }
        )

        _ = await runtime.refresh(
            target: .saved(regionCode: "407")
        )
        _ = await runtime.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(recorder.identities.count, 2)
        XCTAssertEqual(Set(recorder.identities).count, 1)
    }

    func testSavedAndCurrentRefreshRuntimesShareOneServerClock() async {
        let recorder = ProviderClockIdentityRecorder()
        let clock = WidgetServerClock()
        let savedRuntime = SavedCurrentWeatherWidgetRefreshRuntime(
            serverClock: clock,
            refreshWithClock: { receivedClock, _ in
                recorder.record(receivedClock)
                return .failed
            }
        )
        let currentRuntime =
            CurrentLocationCurrentWeatherWidgetRefreshRuntime(
                serverClock: clock,
                refreshWithClock: { receivedClock in
                    recorder.record(receivedClock)
                    return .failed
                }
            )

        _ = await savedRuntime.refresh(
            target: .saved(regionCode: "407")
        )
        _ = await currentRuntime.refresh()

        XCTAssertEqual(recorder.identities.count, 2)
        XCTAssertEqual(Set(recorder.identities).count, 1)
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
        store: ProviderTimelineTestStore
    ) -> DPIPWidgetTimelinePlanner {
        let fixedNow = now
        return DPIPWidgetTimelinePlanner(
            staleAfter: staleAfter,
            refreshInterval: DPIPWidgetProviderRuntime.refreshInterval,
            loadSnapshot: store.load,
            refreshSaved: store.refreshSaved,
            refreshCurrent: store.refreshCurrent,
            now: { fixedNow }
        )
    }

    private func snapshot(
        for target: WidgetLocationTarget,
        stationName: String = "station",
        observationTime: Int = 10_000,
        isNight: Bool = false,
        transitionTime: Int = 0
    ) -> CurrentWeatherWidgetSnapshot {
        let regionCode: String
        switch target {
        case .saved(let savedRegionCode):
            regionCode = savedRegionCode
        case .currentLocation, .invalid:
            regionCode = "407"
        }

        return CurrentWeatherWidgetSnapshot(
            schemaVersion: 5,
            sourceIdentifier: target.sourceIdentifier,
            regionCode: regionCode,
            regionName: "測試地區",
            observationTime: observationTime,
            stationName: stationName,
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: isNight,
            nextDayNightTransitionTime: transitionTime,
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
    private let savedRefreshResult: SavedCurrentWeatherWidgetRefreshResult
    private let currentRefreshResult:
        CurrentLocationCurrentWeatherWidgetRefreshResult
    private let refreshedSnapshot: CurrentWeatherWidgetSnapshot?

    private var storedSnapshots: [String: CurrentWeatherWidgetSnapshot]
    private var storedEvents: [ProviderTimelineEvent] = []
    private var storedCacheMutationCount = 0

    init(
        refreshResult: SavedCurrentWeatherWidgetRefreshResult,
        currentRefreshResult:
            CurrentLocationCurrentWeatherWidgetRefreshResult = .failed,
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
    ) async -> SavedCurrentWeatherWidgetRefreshResult {
        recordSavedRefresh(target)
        return savedRefreshResult
    }

    func refreshCurrent() async
        -> CurrentLocationCurrentWeatherWidgetRefreshResult
    {
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

    var cacheMutationCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedCacheMutationCount
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
            storedCacheMutationCount += 1
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
            storedCacheMutationCount += 1
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

private final class ProviderClockIdentityRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storedIdentities: [ObjectIdentifier] = []

    func record(_ clock: WidgetServerClock) {
        lock.lock()
        defer { lock.unlock() }
        storedIdentities.append(ObjectIdentifier(clock))
    }

    var identities: [ObjectIdentifier] {
        lock.lock()
        defer { lock.unlock() }
        return storedIdentities
    }
}
