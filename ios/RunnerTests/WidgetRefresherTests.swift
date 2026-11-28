import Foundation
import WidgetKit
import XCTest

final class WidgetRefresherTests: XCTestCase {
    private var container: URL!
    private var store: WidgetTargetStore!

    override func setUpWithError() throws {
        container = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: container, withIntermediateDirectories: true
        )
        store = WidgetTargetStore(containerURL: container)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: container)
    }

    // MARK: Saved locations

    func testSavedTargetWritesItsOwnTownship() async throws {
        let calls = RefreshCalls()
        let refresher = makeRefresher(calls: calls)

        let outcome = await refresher.refresh(
            target: .saved(regionCode: "242"), family: .systemSmall
        )

        XCTAssertEqual(outcome, .refreshed)
        let snapshot = try XCTUnwrap(store.loadCurrent(for: .saved(regionCode: "242")))
        XCTAssertEqual(snapshot.sourceIdentifier, "region:242")
        XCTAssertEqual(snapshot.regionCode, "242")
        XCTAssertEqual(snapshot.regionName, "新莊區")
        XCTAssertEqual(snapshot.schemaVersion, 7)
        XCTAssertEqual(snapshot.calibratedTimeOffsetMilliseconds, 321)
        XCTAssertEqual(calls.weatherCoordinates, [[25.0358303, 121.4500307]])
        XCTAssertNil(store.loadCurrent(for: .saved(regionCode: "433")))
    }

    func testTargetsOutsideTheCatalogStartNoWork() async {
        for target: WidgetLocationTarget in [
            .saved(regionCode: "999"), .invalid(identifier: "region:abc"),
        ] {
            let calls = RefreshCalls()
            let outcome = await makeRefresher(calls: calls).refresh(
                target: target, family: .systemLarge
            )

            XCTAssertEqual(outcome, .unavailable, "\(target)")
            XCTAssertTrue(calls.weatherCoordinates.isEmpty, "\(target)")
            XCTAssertTrue(calls.forecastRegions.isEmpty, "\(target)")
        }
    }

    // MARK: Removed places

    func testOnlyAReadableCatalogCanSayAPlaceWasRemoved() throws {
        let catalog = try XCTUnwrap(WidgetLocationCatalog(
            schemaVersion: 1,
            locations: [CurrentWeatherWidgetTestFixtures.catalogLocation(regionCode: "242")]
                .compactMap { $0 }
        ))
        let resolver = SavedWidgetLocationResolver(catalog: catalog)

        XCTAssertTrue(resolver.isRemoved(target: .saved(regionCode: "433")))
        XCTAssertFalse(resolver.isRemoved(target: .saved(regionCode: "242")))
        XCTAssertFalse(resolver.isRemoved(target: .currentLocation))
        XCTAssertFalse(
            SavedWidgetLocationResolver(catalog: nil)
                .isRemoved(target: .saved(regionCode: "433"))
        )
    }

    func testASavedPlaceRemovedInTheAppLeavesNothingBehind() async throws {
        let removed = WidgetLocationTarget.saved(regionCode: "999")
        let kept = WidgetLocationTarget.saved(regionCode: "242")
        try seed(removed, regionCode: "999")
        try seed(kept, regionCode: "242")
        let forecast = try XCTUnwrap(ForecastWidgetSnapshot(
            sourceIdentifier: "region:999", regionCode: "999",
            updateTime: 1_710_907_200_000, receivedAt: 1_710_907_200_000,
            points: [ForecastWidgetPoint(
                time: "13:00", temperature: 22, weather: "晴", weatherCode: 100, pop: 10
            )!]
        ))
        XCTAssertTrue(try store.writeForecast(forecast, for: removed))
        store.recordRefreshOutcome(.failed, for: removed)
        try store.writeRain(
            RainTrendWidgetSnapshot(
                sourceIdentifier: "region:999", regionCode: "999",
                trend: RainHourTrend(startSecond: 1_710_907_200, mm: Array(repeating: 6, count: 60))!
            ),
            for: removed
        )
        XCTAssertNotNil(store.loadRain(for: removed, regionCode: "999"))
        let forecastFile = try XCTUnwrap(store.forecastURL(for: removed))

        let calls = RefreshCalls()
        let outcome = await makeRefresher(calls: calls).refresh(
            target: removed, family: .systemMedium
        )

        XCTAssertEqual(outcome, .unavailable)
        XCTAssertNil(store.loadCurrent(for: removed))
        XCTAssertFalse(FileManager.default.fileExists(atPath: forecastFile.path))
        XCTAssertEqual(store.refreshFailures(for: removed), 0)
        XCTAssertNil(store.loadRain(for: removed, regionCode: "999"))
        XCTAssertTrue(calls.weatherCoordinates.isEmpty)
        XCTAssertTrue(calls.forecastRegions.isEmpty)
        // Every other target keeps its own.
        XCTAssertNotNil(store.loadCurrent(for: kept))
    }

    func testThePreviousVersionsSingleFileGoesOnlyWithItsOwnPlace() async throws {
        let removed = WidgetLocationTarget.saved(regionCode: "999")
        let legacy = store.legacyCurrentWeatherURL
        try FileManager.default.createDirectory(
            at: legacy.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        func writeLegacy(_ regionCode: String) throws {
            try JSONEncoder().encode(CurrentWeatherWidgetTestFixtures.snapshot(
                sourceIdentifier: "region:\(regionCode)", regionCode: regionCode
            )).write(to: legacy)
        }

        try writeLegacy("433")
        _ = await makeRefresher(calls: RefreshCalls()).refresh(target: removed, family: .systemSmall)
        XCTAssertNotNil(store.loadCurrent(for: .saved(regionCode: "433")))

        try writeLegacy("999")
        XCTAssertNotNil(store.loadCurrent(for: removed))
        _ = await makeRefresher(calls: RefreshCalls()).refresh(target: removed, family: .systemSmall)
        XCTAssertNil(store.loadCurrent(for: removed))
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacy.path))
    }

    func testWithoutACatalogNothingIsDeleted() async throws {
        let target = WidgetLocationTarget.saved(regionCode: "242")
        try seed(target, regionCode: "242")
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.resolveSaved = { _ in nil }
        dependencies.isRemoved = {
            SavedWidgetLocationResolver(catalog: nil).isRemoved(target: $0)
        }

        let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: target, family: .systemSmall)

        XCTAssertEqual(outcome, .unavailable)
        XCTAssertNotNil(store.loadCurrent(for: target))
    }

    func testWeatherFailureKeepsTheCacheAndRetries() async throws {
        let target = WidgetLocationTarget.saved(regionCode: "242")
        let cached = try seed(target, regionCode: "242")
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.fetchWeather = { _, _ in throw WidgetRefreshTestError.scripted }

        let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: target, family: .systemSmall)

        XCTAssertEqual(outcome, .failed)
        XCTAssertEqual(try cachedData(target), cached)
    }

    func testNoObservationKeepsTheCacheWithoutRetrying() async throws {
        let target = WidgetLocationTarget.saved(regionCode: "242")
        let cached = try seed(target, regionCode: "242")
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.fetchWeather = { _, _ in nil }

        let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: target, family: .systemSmall)

        XCTAssertEqual(outcome, .unavailable)
        XCTAssertEqual(try cachedData(target), cached)
    }

    func testStorageFailureIsRetried() async {
        let refresher = WidgetRefresher(
            store: FailingCommitStore(base: store),
            dependencies: makeDependencies(calls: RefreshCalls())
        )

        let outcome = await refresher.refresh(
            target: .saved(regionCode: "242"), family: .systemSmall
        )

        XCTAssertEqual(outcome, .failed)
    }

    func testOlderObservationThanTheCacheCountsAsCurrent() async throws {
        let target = WidgetLocationTarget.saved(regionCode: "242")
        let base = CurrentWeatherWidgetTestFixtures.snapshot(
            sourceIdentifier: "region:242", regionCode: "242"
        )
        // Newer than the fixture observation the refresh will fetch.
        let newer = CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: base.sourceIdentifier,
            regionCode: base.regionCode,
            regionName: base.regionName,
            observationTime: 1_800_000_000,
            stationName: base.stationName,
            weather: base.weather,
            weatherCode: base.weatherCode,
            condition: base.condition,
            isNight: base.isNight,
            nextDayNightTransitionTime: base.nextDayNightTransitionTime,
            calibratedTimeOffsetMilliseconds: base.calibratedTimeOffsetMilliseconds,
            temperature: base.temperature,
            humidity: base.humidity,
            rain: base.rain
        )
        let cached = try CurrentWeatherWidgetTestFixtures.seed(
            newer, at: .saved(regionCode: "242"), containerURL: container
        )

        let outcome = await makeRefresher(calls: RefreshCalls())
            .refresh(target: target, family: .systemSmall)

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertEqual(try cachedData(target), cached)
    }

    // MARK: Clock

    func testClockFailureStillCommitsTheObservation() async throws {
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.sampleClock = {
            CurrentWeatherSnapshotTime(
                calibratedNowUnixMilliseconds: 1_710_907_200_000,
                calibratedTimeOffsetMilliseconds: 0
            )
        }

        let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: .saved(regionCode: "242"), family: .systemSmall)

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertEqual(
            store.loadCurrent(for: .saved(regionCode: "242"))?
                .calibratedTimeOffsetMilliseconds,
            0
        )
    }

    func testASlowClockDoesNotCostTheObservation() async throws {
        let gate = AsyncOperationGate()
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.synchronizeClock = { await gate.wait() }
        let refresher = WidgetRefresher(
            store: store, dependencies: dependencies, budget: 1.5
        )

        let started = Date()
        let outcome = await refresher.refresh(
            target: .saved(regionCode: "242"), family: .systemSmall
        )

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertNotNil(store.loadCurrent(for: .saved(regionCode: "242")))
        XCTAssertLessThan(Date().timeIntervalSince(started), 1.5)
        await gate.open()
    }

    func testClockStartsBeforeTheLocationIsKnown() async {
        let calls = RefreshCalls()
        let location = AsyncOperationGate()
        var dependencies = makeDependencies(calls: calls)
        dependencies.acquireCurrentLocation = { @MainActor in
            await location.wait()
            return .acquired(WidgetCurrentLocation(latitude: 24.17, longitude: 120.64)!)
        }
        let refresher = WidgetRefresher(store: store, dependencies: dependencies)

        let task = Task {
            await refresher.refresh(target: .currentLocation, family: .systemSmall)
        }
        await waitUntil { calls.clockSynchronizations > 0 }
        XCTAssertEqual(calls.clockSynchronizations, 1)
        XCTAssertTrue(calls.weatherCoordinates.isEmpty)

        await location.open()
        let outcome = await task.value
        XCTAssertEqual(outcome, .refreshed)
    }

    // MARK: Current Location

    func testCurrentLocationFetchesTheTownshipCentroid() async throws {
        let calls = RefreshCalls()
        var dependencies = makeDependencies(calls: calls)
        dependencies.acquireCurrentLocation = { @MainActor in
            .acquired(WidgetCurrentLocation(latitude: 24.17, longitude: 120.64)!)
        }

        let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: .currentLocation, family: .systemSmall)

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertEqual(calls.weatherCoordinates, [[24.18134, 120.64662]])
        XCTAssertEqual(store.loadCurrent(for: .currentLocation)?.regionCode, "407")
    }

    func testCurrentLocationFailuresMapToTheirRetryPolicy() async throws {
        let cases: [(WidgetCurrentLocationResult, WidgetRefreshOutcome)] = [
            (.unavailable, .unavailable),
            (.timedOut, .failed),
            (.failed, .failed),
        ]
        for (result, expected) in cases {
            let calls = RefreshCalls()
            var dependencies = makeDependencies(calls: calls)
            dependencies.acquireCurrentLocation = { @MainActor in result }

            let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
                .refresh(target: .currentLocation, family: .systemSmall)

            XCTAssertEqual(outcome, expected, "\(result)")
            XCTAssertTrue(calls.weatherCoordinates.isEmpty, "\(result)")
        }
    }

    func testAFixOutsideEveryTownshipStartsNoNetworkWork() async {
        let calls = RefreshCalls()
        var dependencies = makeDependencies(calls: calls)
        dependencies.resolveTownship = { _ in nil }

        let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: .currentLocation, family: .systemLarge)

        XCTAssertEqual(outcome, .unavailable)
        XCTAssertTrue(calls.weatherCoordinates.isEmpty)
        XCTAssertTrue(calls.forecastRegions.isEmpty)
    }

    func testTownshipChangeReplacesTheCurrentLocationSnapshot() async throws {
        _ = try seed(.currentLocation, regionCode: "433")

        let outcome = await makeRefresher(calls: RefreshCalls())
            .refresh(target: .currentLocation, family: .systemSmall)

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertEqual(store.loadCurrent(for: .currentLocation)?.regionCode, "407")
    }

    // MARK: Forecast

    func testSmallNeverRequestsAForecast() async {
        let calls = RefreshCalls()

        _ = await makeRefresher(calls: calls).refresh(
            target: .saved(regionCode: "242"), family: .systemSmall
        )

        XCTAssertTrue(calls.forecastRegions.isEmpty)
    }

    func testMediumAndLargeFetchTheForecastAlongsideTheWeather() async throws {
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            try? FileManager.default.removeItem(at: container)
            let calls = RefreshCalls()
            let weather = AsyncOperationGate()
            var dependencies = makeDependencies(calls: calls)
            let base = dependencies.fetchWeather
            dependencies.fetchWeather = { latitude, longitude in
                await weather.wait()
                return try await base(latitude, longitude)
            }
            let refresher = WidgetRefresher(store: store, dependencies: dependencies)

            let task = Task {
                await refresher.refresh(target: .saved(regionCode: "242"), family: family)
            }
            // The forecast request goes out while the observation is pending.
            await waitUntil { !calls.forecastRegions.isEmpty }
            XCTAssertEqual(calls.forecastRegions, ["242"], "\(family)")
            await weather.open()
            _ = await task.value

            let forecast = store.loadForecast(
                for: .saved(regionCode: "242"), regionCode: "242",
                at: Date(timeIntervalSince1970: 1_710_907_200),
                calibratedTimeOffsetMilliseconds: 321
            )
            XCTAssertEqual(forecast?.points.count, 3, "\(family)")
        }
    }

    func testForecastFailureKeepsTheCachedForecastAndTheWeather() async throws {
        let target = WidgetLocationTarget.saved(regionCode: "242")
        try store.writeForecast(forecastSnapshot(region: "242"), for: target)
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.fetchForecast = { _ in throw WidgetRefreshTestError.scripted }

        let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: target, family: .systemMedium)

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertEqual(
            store.loadForecast(
                for: target, regionCode: "242",
                at: Date(timeIntervalSince1970: 1_710_907_200)
            )?.updateTime,
            forecastSnapshot(region: "242").updateTime
        )
    }

    func testForecastIsDroppedWhenTheSnapshotMovedToAnotherTownship() async throws {
        // The observation fails, so the cache still shows township 433 while
        // the fresh fix resolved to 407: a 407 forecast must not be attached.
        _ = try seed(.currentLocation, regionCode: "433")
        let calls = RefreshCalls()
        var dependencies = makeDependencies(calls: calls)
        dependencies.fetchWeather = { _, _ in throw WidgetRefreshTestError.scripted }

        _ = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: .currentLocation, family: .systemMedium)

        XCTAssertEqual(calls.forecastRegions, ["407"])
        XCTAssertNil(store.forecastURL(for: .currentLocation).flatMap {
            try? Data(contentsOf: $0)
        })
    }

    func testUnresolvedCurrentLocationStillRefreshesTheCachedTownshipsForecast() async throws {
        _ = try seed(.currentLocation, regionCode: "407")
        let calls = RefreshCalls()
        var dependencies = makeDependencies(calls: calls)
        dependencies.acquireCurrentLocation = { @MainActor in .timedOut }

        let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: .currentLocation, family: .systemLarge)

        XCTAssertEqual(outcome, .failed)
        XCTAssertTrue(calls.weatherCoordinates.isEmpty)
        XCTAssertEqual(calls.forecastRegions, ["407"])
    }

    // MARK: Rain

    func testMediumAndLargeCacheTheRainTrendForTheirTownship() async throws {
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            try? FileManager.default.removeItem(at: container)
            let calls = RefreshCalls()

            _ = await makeRefresher(calls: calls).refresh(
                target: .saved(regionCode: "242"), family: family
            )

            XCTAssertEqual(calls.rainRegions, ["242"], "\(family)")
            let rain = try XCTUnwrap(
                store.loadRain(for: .saved(regionCode: "242"), regionCode: "242")
            )
            XCTAssertEqual(rain.trend.startSecond, 1_710_907_200)
            XCTAssertEqual(rain.trend.summary.grade, .light)
            XCTAssertNil(store.loadRain(for: .saved(regionCode: "242"), regionCode: "433"))
        }
    }

    func testSmallNeverRequestsTheRainTrend() async {
        let calls = RefreshCalls()

        _ = await makeRefresher(calls: calls).refresh(
            target: .saved(regionCode: "242"), family: .systemSmall
        )

        XCTAssertTrue(calls.rainRegions.isEmpty)
        XCTAssertNil(store.rainURL(for: .saved(regionCode: "242")).flatMap {
            try? Data(contentsOf: $0)
        })
    }

    func testRainFailureKeepsTheCachedTrendAndTheWeather() async throws {
        let target = WidgetLocationTarget.saved(regionCode: "242")
        let cached = RainTrendWidgetSnapshot(
            sourceIdentifier: "region:242", regionCode: "242",
            trend: RainHourTrend(
                startSecond: 1_710_906_000, mm: Array(repeating: 1, count: 60)
            )!
        )
        try store.writeRain(cached, for: target)
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.fetchRain = { _, _ in throw WidgetRefreshTestError.scripted }

        let outcome = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: target, family: .systemLarge)

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertEqual(store.loadRain(for: target, regionCode: "242"), cached)
    }

    func testRainForAnotherTownshipThanTheSnapshotIsDropped() async throws {
        _ = try seed(.currentLocation, regionCode: "433")
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.fetchWeather = { _, _ in throw WidgetRefreshTestError.scripted }

        _ = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: .currentLocation, family: .systemMedium)

        XCTAssertNil(store.rainURL(for: .currentLocation).flatMap {
            try? Data(contentsOf: $0)
        })
    }

    func testADryHourReplacesAnEarlierRainyOne() async throws {
        let target = WidgetLocationTarget.saved(regionCode: "242")
        try store.writeRain(
            RainHourTrend(startSecond: 1_710_906_000, mm: Array(repeating: 9, count: 60))
                .map {
                    RainTrendWidgetSnapshot(
                        sourceIdentifier: "region:242", regionCode: "242", trend: $0
                    )
                }!,
            for: target
        )
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.fetchRain = { _, now in
            try RainHourTrend.decode(
                Data(#"{"rainfallWarnings-rkai":[]}"#.utf8), now: now
            )
        }

        _ = await WidgetRefresher(store: store, dependencies: dependencies)
            .refresh(target: target, family: .systemMedium)

        XCTAssertEqual(store.loadRain(for: target, regionCode: "242")?.trend.isDry, true)
    }

    // MARK: Budget

    func testBudgetEndsAHungRefreshAsARetry() async {
        let hang = AsyncOperationGate()
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.fetchWeather = { _, _ in
            await hang.wait()
            return nil
        }
        let refresher = WidgetRefresher(
            store: store, dependencies: dependencies, budget: 0.3
        )

        let started = Date()
        let outcome = await refresher.refresh(
            target: .saved(regionCode: "242"), family: .systemSmall
        )

        XCTAssertEqual(outcome, .failed)
        XCTAssertLessThan(Date().timeIntervalSince(started), 2)
        await hang.open()
    }

    func testBudgetKeepsAnObservationCommittedBeforeIt() async {
        let hang = AsyncOperationGate()
        var dependencies = makeDependencies(calls: RefreshCalls())
        dependencies.fetchForecast = { _ in
            await hang.wait()
            throw WidgetRefreshTestError.scripted
        }
        let refresher = WidgetRefresher(
            store: store, dependencies: dependencies, budget: 0.5
        )

        let outcome = await refresher.refresh(
            target: .saved(regionCode: "242"), family: .systemMedium
        )

        XCTAssertEqual(outcome, .refreshed)
        XCTAssertNotNil(store.loadCurrent(for: .saved(regionCode: "242")))
        await hang.open()
    }

    // MARK: Retry backoff

    func testFailuresInARowAreCountedPerTargetAndClearedByARefresh() {
        let current = WidgetLocationTarget.currentLocation
        let saved = WidgetLocationTarget.saved(regionCode: "242")

        XCTAssertEqual(store.refreshFailures(for: current), 0)
        XCTAssertEqual(store.recordRefreshOutcome(.failed, for: current), 1)
        XCTAssertEqual(store.recordRefreshOutcome(.failed, for: current), 2)
        // Unavailable reloads on the regular cycle; it neither adds nor clears.
        XCTAssertEqual(store.recordRefreshOutcome(.unavailable, for: current), 2)
        XCTAssertEqual(store.recordRefreshOutcome(.failed, for: current), 3)
        XCTAssertEqual(store.refreshFailures(for: saved), 0)
        // Another widget process reads the same count.
        XCTAssertEqual(
            WidgetTargetStore(containerURL: container).refreshFailures(for: current), 3
        )

        XCTAssertEqual(store.recordRefreshOutcome(.refreshed, for: current), 0)
        XCTAssertEqual(store.refreshFailures(for: current), 0)
        XCTAssertEqual(store.recordRefreshOutcome(.failed, for: current), 1)
        // No storage for an invalid target: every failure is the first.
        XCTAssertEqual(store.recordRefreshOutcome(.failed, for: .invalid(identifier: "region:bad")), 1)
    }

    func testRetriesBackOffAcrossReloadsAndStartOverAfterARefresh() async {
        let outcomes = OutcomeScript([
            .failed, .failed, .failed, .failed, .refreshed, .failed,
        ])
        let store = store!
        let now = Date(timeIntervalSince1970: 10_000)
        let planner = DPIPWidgetTimelinePlanner(
            builder: WidgetTimelineBuilder(
                refreshInterval: 30 * 60, retryInterval: 10 * 60
            ),
            loadSnapshot: { _ in nil },
            refresh: { _, _ in outcomes.next() },
            recordOutcome: { target, outcome in
                store.recordRefreshOutcome(outcome, for: target)
            },
            now: { now }
        )

        var minutes: [Double] = []
        for _ in 0..<6 {
            let plan = await planner.plan(for: .currentLocation)
            minutes.append(plan.reloadDate.timeIntervalSince(now) / 60)
        }

        XCTAssertEqual(minutes, [10, 20, 30, 30, 30, 10])
    }

    // MARK: Helpers

    /// Polls for work that runs on other tasks, for up to two seconds.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func makeRefresher(calls: RefreshCalls) -> WidgetRefresher {
        WidgetRefresher(store: store, dependencies: makeDependencies(calls: calls))
    }

    private func makeDependencies(calls: RefreshCalls) -> WidgetRefresher.Dependencies {
        let catalog = WidgetLocationCatalog(
            schemaVersion: 1,
            locations: ["242", "433"].compactMap {
                CurrentWeatherWidgetTestFixtures.catalogLocation(regionCode: $0)
            }
        )!
        return WidgetRefresher.Dependencies(
            resolveSaved: { target in
                SavedWidgetLocationResolver(catalog: catalog).resolve(target: target)
            },
            isRemoved: { target in
                SavedWidgetLocationResolver(catalog: catalog).isRemoved(target: target)
            },
            acquireCurrentLocation: { @MainActor in
                .acquired(WidgetCurrentLocation(latitude: 24.17, longitude: 120.64)!)
            },
            resolveTownship: { _ in
                CurrentWeatherWidgetTestFixtures.resolvedLocation()
            },
            fetchWeather: { latitude, longitude in
                calls.recordWeather(latitude, longitude)
                return try CurrentWeatherWidgetTestFixtures.observation()
            },
            fetchForecast: { regionCode in
                calls.recordForecast(regionCode)
                return try forecastDTO()
            },
            fetchRain: { regionCode, _ in
                calls.recordRain(regionCode)
                return RainHourTrend(
                    startSecond: 1_710_907_200,
                    mm: Array(repeating: 0, count: 50) + Array(repeating: 6, count: 10)
                )!
            },
            synchronizeClock: { calls.recordClock() },
            sampleClock: { CurrentWeatherWidgetTestFixtures.snapshotTime() },
            now: { Date(timeIntervalSince1970: 1_710_907_200) }
        )
    }

    @discardableResult
    private func seed(
        _ target: WidgetLocationTarget, regionCode: String
    ) throws -> Data {
        try CurrentWeatherWidgetTestFixtures.seed(
            CurrentWeatherWidgetTestFixtures.snapshot(
                sourceIdentifier: target.sourceIdentifier!,
                regionCode: regionCode
            ),
            at: CurrentWeatherSnapshotAddress(sourceIdentifier: target.sourceIdentifier!)!,
            containerURL: container
        )
    }

    private func cachedData(_ target: WidgetLocationTarget) throws -> Data {
        try Data(contentsOf: XCTUnwrap(store.currentWeatherURL(for: target)))
    }

    private func forecastSnapshot(region: String) -> ForecastWidgetSnapshot {
        ForecastWidgetSnapshot(
            sourceIdentifier: "region:\(region)", regionCode: region,
            updateTime: 1_710_906_000_000, receivedAt: 1_710_906_060_000,
            points: ["12:00", "13:00"].map {
                ForecastWidgetPoint(
                    time: $0, temperature: 22, weather: "晴",
                    weatherCode: 100, pop: 10
                )!
            }
        )!
    }
}

/// Publication 1_710_907_200_000 ms: fresh at the tests' fixed `now`.
private func forecastDTO() throws -> ForecastRemoteDTO {
    let points = ["13:00", "14:00", "15:00"].map {
        ["time": $0, "temperature": 22, "weather": "晴",
         "weatherCode": 100, "pop": 20] as [String: Any]
    }
    return try JSONDecoder().decode(
        ForecastRemoteDTO.self,
        from: JSONSerialization.data(withJSONObject: [
            "updateTime": 1_710_907_200_000 as Int64, "forecast": points,
        ])
    )
}

/// Hands out scripted refresh outcomes in order.
private final class OutcomeScript: @unchecked Sendable {
    private let lock = NSLock()
    private var remaining: [WidgetRefreshOutcome]

    init(_ outcomes: [WidgetRefreshOutcome]) {
        remaining = outcomes
    }

    func next() -> WidgetRefreshOutcome {
        lock.withLock { remaining.removeFirst() }
    }
}

private final class RefreshCalls: @unchecked Sendable {
    private let lock = NSLock()
    private var weather: [[Double]] = []
    private var forecasts: [String] = []
    private var rains: [String] = []
    private var clocks = 0

    var weatherCoordinates: [[Double]] { lock.withLock { weather } }
    var forecastRegions: [String] { lock.withLock { forecasts } }
    var rainRegions: [String] { lock.withLock { rains } }
    var clockSynchronizations: Int { lock.withLock { clocks } }

    func recordRain(_ regionCode: String) {
        lock.withLock { rains.append(regionCode) }
    }

    func recordWeather(_ latitude: Double, _ longitude: Double) {
        lock.withLock { weather.append([latitude, longitude]) }
    }

    func recordForecast(_ regionCode: String) {
        lock.withLock { forecasts.append(regionCode) }
    }

    func recordClock() {
        lock.withLock { clocks += 1 }
    }
}

private struct FailingCommitStore: WidgetRefreshStoring {
    let base: WidgetTargetStore

    func loadCurrent(for target: WidgetLocationTarget) -> CurrentWeatherWidgetSnapshot? {
        base.loadCurrent(for: target)
    }

    func removeAll(for target: WidgetLocationTarget) throws {
        try base.removeAll(for: target)
    }

    func beginCurrentWrite(
        for address: CurrentWeatherSnapshotAddress
    ) throws -> CurrentWeatherSnapshotWriteToken {
        try base.beginCurrentWrite(for: address)
    }

    func commitCurrent(
        _ snapshot: CurrentWeatherWidgetSnapshot,
        using token: CurrentWeatherSnapshotWriteToken
    ) throws -> CurrentWeatherSnapshotWriteResult {
        throw WidgetRefreshTestError.scripted
    }

    func writeForecast(
        _ snapshot: ForecastWidgetSnapshot, for target: WidgetLocationTarget
    ) throws -> Bool {
        try base.writeForecast(snapshot, for: target)
    }

    func writeRain(
        _ snapshot: RainTrendWidgetSnapshot, for target: WidgetLocationTarget
    ) throws {
        try base.writeRain(snapshot, for: target)
    }
}
