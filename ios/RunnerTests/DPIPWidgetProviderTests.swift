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

        XCTAssertEqual(store.refreshTargets, [target])
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
            [.refresh(target), .load(target)]
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
        XCTAssertEqual(store.loadTargets, [target])
    }

    func testCurrentLocationDoesNotInvokeSavedRefresh() async {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .refreshed,
            snapshots: [(target, snapshot(for: target))]
        )

        _ = await planner(store: store).plan(for: target)

        XCTAssertTrue(store.refreshTargets.isEmpty)
    }

    func testCurrentLocationDisplaysExistingCache() async {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
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

        XCTAssertTrue(store.refreshTargets.isEmpty)
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

    func testTimelineRequestsFutureRefreshEveryThirtyMinutes() async {
        let target = WidgetLocationTarget.currentLocation
        let store = ProviderTimelineTestStore(
            refreshResult: .failed,
            snapshots: []
        )

        let plan = await planner(store: store).plan(for: target)

        XCTAssertGreaterThan(plan.reloadDate, now)
        XCTAssertEqual(
            plan.reloadDate,
            now.addingTimeInterval(staleAfter)
        )
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

    private func planner(
        store: ProviderTimelineTestStore
    ) -> DPIPWidgetTimelinePlanner {
        let fixedNow = now
        return DPIPWidgetTimelinePlanner(
            staleAfter: staleAfter,
            refreshInterval: staleAfter,
            loadSnapshot: store.load,
            refreshSaved: store.refresh,
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
    case refresh(WidgetLocationTarget)
    case load(WidgetLocationTarget)
}

private final class ProviderTimelineTestStore: @unchecked Sendable {
    private let lock = NSLock()
    private let refreshResult: SavedCurrentWeatherWidgetRefreshResult
    private let refreshedSnapshot: CurrentWeatherWidgetSnapshot?

    private var storedSnapshots: [String: CurrentWeatherWidgetSnapshot]
    private var storedEvents: [ProviderTimelineEvent] = []
    private var storedCacheMutationCount = 0

    init(
        refreshResult: SavedCurrentWeatherWidgetRefreshResult,
        snapshots: [(
            WidgetLocationTarget,
            CurrentWeatherWidgetSnapshot
        )],
        refreshedSnapshot: CurrentWeatherWidgetSnapshot? = nil
    ) {
        self.refreshResult = refreshResult
        self.refreshedSnapshot = refreshedSnapshot
        storedSnapshots = Dictionary(
            uniqueKeysWithValues: snapshots.map {
                (Self.key(for: $0.0), $0.1)
            }
        )
    }

    func refresh(
        target: WidgetLocationTarget
    ) async -> SavedCurrentWeatherWidgetRefreshResult {
        recordRefresh(target)
        return refreshResult
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

    var refreshTargets: [WidgetLocationTarget] {
        events.compactMap { event in
            guard case let .refresh(target) = event else {
                return nil
            }
            return target
        }
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

    private func recordRefresh(
        _ target: WidgetLocationTarget
    ) {
        lock.lock()
        defer { lock.unlock() }
        storedEvents.append(.refresh(target))

        if refreshResult == .refreshed,
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
