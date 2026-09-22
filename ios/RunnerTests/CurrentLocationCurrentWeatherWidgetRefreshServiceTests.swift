import Foundation
import XCTest

@MainActor
final class CurrentLocationCurrentWeatherWidgetRefreshServiceTests:
    XCTestCase
{
    private var containerURL: URL!
    private let preciseLocation = WidgetCurrentLocation(
        latitude: 24.181234,
        longitude: 120.612345
    )!

    override func setUpWithError() throws {
        containerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: containerURL)
        containerURL = nil
    }

    func testSuccessfulRefreshRunsPipelineAndWritesResolvedSnapshot()
        async throws
    {
        let recorder = CurrentLocationRefreshEventRecorder()
        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation()),
            onFetch: { recorder.record(.fetchWeather) }
        )
        let writer = CurrentWeatherSnapshotWriterSpy(
            onWrite: { recorder.record(.writeSnapshot) }
        )
        let service = makeService(
            recorder: recorder,
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh()

        XCTAssertEqual(result, .refreshed)
        let snapshot = try XCTUnwrap(writer.snapshots.first)
        XCTAssertEqual(snapshot.schemaVersion, 5)
        XCTAssertEqual(snapshot.sourceIdentifier, "current-location")
        XCTAssertEqual(snapshot.regionCode, "407")
        XCTAssertEqual(snapshot.regionName, "西屯區")
        XCTAssertEqual(snapshot.stationName, "西屯測站")
        XCTAssertEqual(snapshot.calibratedTimeOffsetMilliseconds, 321)

        let events = recorder.events
        XCTAssertLessThan(
            try XCTUnwrap(events.firstIndex(of: .beginWrite)),
            try XCTUnwrap(events.firstIndex(of: .acquireLocation))
        )
        XCTAssertLessThan(
            try XCTUnwrap(events.firstIndex(of: .acquireLocation)),
            try XCTUnwrap(events.firstIndex(of: .resolveTownship))
        )
        XCTAssertLessThan(
            try XCTUnwrap(events.firstIndex(of: .resolveTownship)),
            try XCTUnwrap(events.firstIndex(of: .fetchWeather))
        )
        XCTAssertLessThan(
            try XCTUnwrap(events.firstIndex(of: .resolveTownship)),
            try XCTUnwrap(events.firstIndex(of: .synchronizeClock))
        )
        XCTAssertGreaterThan(
            try XCTUnwrap(events.firstIndex(of: .writeSnapshot)),
            try XCTUnwrap(events.firstIndex(of: .fetchWeather))
        )
        XCTAssertGreaterThan(
            try XCTUnwrap(events.firstIndex(of: .writeSnapshot)),
            try XCTUnwrap(events.firstIndex(of: .synchronizeClock))
        )
    }

    func testWeatherUsesTownshipCentroidInsteadOfPreciseLocation()
        async throws
    {
        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation())
        )
        let service = makeService(
            weather: weather,
            writeSnapshot: CurrentWeatherSnapshotWriterSpy().write
        )

        let result = await service.refresh()
        XCTAssertEqual(result, .refreshed)

        let coordinates = await weather.coordinates
        XCTAssertEqual(coordinates.count, 1)
        XCTAssertEqual(coordinates.first?.latitude, 24.1813400)
        XCTAssertEqual(coordinates.first?.longitude, 120.6466200)
        XCTAssertNotEqual(
            coordinates.first?.latitude,
            preciseLocation.latitude
        )
        XCTAssertNotEqual(
            coordinates.first?.longitude,
            preciseLocation.longitude
        )
    }

    func testLocationAcquisitionFailuresDoNotStartPipeline() async throws {
        let cases: [(
            WidgetCurrentLocationResult,
            CurrentWeatherWidgetRefreshResult
        )] = [
            (.unavailable, .unavailable),
            (.timedOut, .unavailable),
            (.failed, .failed),
        ]

        for (locationResult, expectedResult) in cases {
            let weather = ScriptedCurrentWeather(
                result: .success(try makeObservation())
            )
            let clock = ScriptedSnapshotClock(sample: makeSnapshotTime())
            let writer = CurrentWeatherSnapshotWriterSpy()
            let service = makeService(
                locationResult: locationResult,
                weather: weather,
                synchronizeClock: {
                    await clock.synchronizeAndSample()
                },
                writeSnapshot: writer.write
            )

            let result = await service.refresh()
            let weatherCallCount = await weather.callCount
            let clockCallCount = await clock.callCount
            XCTAssertEqual(result, expectedResult)
            XCTAssertEqual(weatherCallCount, 0)
            XCTAssertEqual(clockCallCount, 0)
            XCTAssertEqual(writer.writeCount, 0)
        }
    }

    func testTownshipResolutionFailureDoesNotStartNetworkOrWrite()
        async throws
    {
        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation())
        )
        let clock = ScriptedSnapshotClock(sample: makeSnapshotTime())
        let writer = CurrentWeatherSnapshotWriterSpy()
        let service = makeService(
            shouldResolveTownship: false,
            weather: weather,
            synchronizeClock: {
                await clock.synchronizeAndSample()
            },
            writeSnapshot: writer.write
        )

        let result = await service.refresh()
        let weatherCallCount = await weather.callCount
        let clockCallCount = await clock.callCount
        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(weatherCallCount, 0)
        XCTAssertEqual(clockCallCount, 0)
        XCTAssertEqual(writer.writeCount, 0)
    }

    func testResolvedSavedAddressIsRejectedWithoutFallback() async throws {
        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentWeatherSnapshotWriterSpy()
        let savedLocation = try XCTUnwrap(
            WidgetResolvedWeatherLocation(
                address: .saved(regionCode: "407"),
                regionCode: "407",
                regionName: "西屯區",
                latitude: 24.1813400,
                longitude: 120.6466200
            )
        )
        let service = makeService(
            resolvedLocation: savedLocation,
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh()
        let weatherCallCount = await weather.callCount
        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(weatherCallCount, 0)
        XCTAssertEqual(writer.writeCount, 0)
    }

    func testNoObservationLeavesExistingCurrentLocationCacheUntouched()
        async throws
    {
        let oldData = try seedExistingSnapshot()
        let weather = ScriptedCurrentWeather(result: .success(nil))
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = makeService(
            weather: weather,
            writeSnapshot: { snapshot in
                try CurrentWeatherWidgetTestFixtures.write(
                    snapshot,
                    to: .currentLocation,
                    using: writer
                )
            }
        )

        let result = await service.refresh()
        XCTAssertEqual(result, .noObservation)
        XCTAssertEqual(try cachedData(), oldData)
    }

    func testWeatherFailureLeavesExistingCurrentLocationCacheUntouched()
        async throws
    {
        let oldData = try seedExistingSnapshot()
        let weather = ScriptedCurrentWeather(
            result: .failure(.scripted)
        )
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = makeService(
            weather: weather,
            writeSnapshot: { snapshot in
                try CurrentWeatherWidgetTestFixtures.write(
                    snapshot,
                    to: .currentLocation,
                    using: writer
                )
            }
        )

        let result = await service.refresh()
        XCTAssertEqual(result, .failed)
        XCTAssertEqual(try cachedData(), oldData)
    }

    func testTownshipChangeReplacesOnlyCanonicalCurrentLocationFile()
        async throws
    {
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let firstService = makeService(
            resolvedLocation: resolvedLocation(
                regionCode: "407",
                regionName: "西屯區",
                latitude: 24.1813400,
                longitude: 120.6466200
            ),
            weather: ScriptedCurrentWeather(
                result: .success(try makeObservation())
            ),
            writeSnapshot: { snapshot in
                try CurrentWeatherWidgetTestFixtures.write(
                    snapshot,
                    to: .currentLocation,
                    using: writer
                )
            }
        )
        let secondService = makeService(
            resolvedLocation: resolvedLocation(
                regionCode: "110",
                regionName: "信義區",
                latitude: 25.0333200,
                longitude: 121.5701000
            ),
            weather: ScriptedCurrentWeather(
                result: .success(try makeObservation())
            ),
            writeSnapshot: { snapshot in
                try CurrentWeatherWidgetTestFixtures.write(
                    snapshot,
                    to: .currentLocation,
                    using: writer
                )
            }
        )

        let firstResult = await firstService.refresh()
        let secondResult = await secondService.refresh()
        XCTAssertEqual(firstResult, .refreshed)
        XCTAssertEqual(secondResult, .refreshed)

        let snapshot = try JSONDecoder().decode(
            CurrentWeatherWidgetSnapshot.self,
            from: cachedData()
        )
        XCTAssertEqual(snapshot.sourceIdentifier, "current-location")
        XCTAssertEqual(snapshot.regionCode, "110")
        XCTAssertEqual(snapshot.regionName, "信義區")
        let directory = CurrentWeatherSnapshotStorage(
            containerURL: containerURL
        ).snapshotURL(for: .currentLocation)
            .deletingLastPathComponent()
        XCTAssertEqual(
            try FileManager.default.contentsOfDirectory(atPath: directory.path),
            ["current-location.json"]
        )
    }

    private func makeService(
        locationResult: WidgetCurrentLocationResult? = nil,
        resolvedLocation: WidgetResolvedWeatherLocation? = nil,
        shouldResolveTownship: Bool = true,
        recorder: CurrentLocationRefreshEventRecorder? = nil,
        weather: ScriptedCurrentWeather,
        synchronizeClock: @escaping
            CurrentWeatherWidgetRefreshPipeline.SynchronizeClock = {
                    CurrentWeatherSnapshotTime(
                        calibratedNowUnixMilliseconds: 1_710_907_200_000,
                        calibratedTimeOffsetMilliseconds: 321
                    )
                },
        writeSnapshot: @escaping @Sendable (
            CurrentWeatherWidgetSnapshot
        ) throws -> Void
    ) -> CurrentLocationCurrentWeatherWidgetRefreshService {
        let preciseLocation = preciseLocation
        let defaultResolvedLocation = self.resolvedLocation()
        return CurrentLocationCurrentWeatherWidgetRefreshService(
            acquireLocation: { @MainActor in
                recorder?.record(.acquireLocation)
                return locationResult ?? .acquired(preciseLocation)
            },
            resolveTownship: { location in
                recorder?.record(.resolveTownship)
                guard shouldResolveTownship,
                      location == preciseLocation
                else {
                    return nil
                }
                if let resolvedLocation {
                    return resolvedLocation
                }
                return defaultResolvedLocation
            },
            beginWrite: { address in
                recorder?.record(.beginWrite)
                return CurrentWeatherSnapshotWriteToken(
                    address: address,
                    generation: 1
                )
            },
            pipeline: CurrentWeatherWidgetRefreshPipeline(
                fetchWeather: { latitude, longitude in
                    try await weather.fetch(
                        latitude: latitude,
                        longitude: longitude
                    )
                },
                synchronizeClock: {
                    recorder?.record(.synchronizeClock)
                    return await synchronizeClock()
                },
                commitSnapshot: { snapshot, _ in
                    try writeSnapshot(snapshot)
                    return .written
                }
            )
        )
    }

    private func resolvedLocation(
        regionCode: String = "407",
        regionName: String = "西屯區",
        latitude: Double = 24.1813400,
        longitude: Double = 120.6466200
    ) -> WidgetResolvedWeatherLocation {
        CurrentWeatherWidgetTestFixtures.resolvedLocation(
            regionCode: regionCode,
            regionName: regionName,
            latitude: latitude,
            longitude: longitude
        )
    }

    private func makeObservation() throws -> CurrentWeatherRemoteDTO {
        try CurrentWeatherWidgetTestFixtures.observation()
    }

    private func makeSnapshotTime() -> CurrentWeatherSnapshotTime {
        CurrentWeatherWidgetTestFixtures.snapshotTime()
    }

    @discardableResult
    private func seedExistingSnapshot() throws -> Data {
        try CurrentWeatherWidgetTestFixtures.seed(
            CurrentWeatherWidgetTestFixtures.snapshot(
                sourceIdentifier: "current-location",
                regionCode: "407"
            ),
            at: .currentLocation,
            containerURL: containerURL
        )
    }

    private func cachedData() throws -> Data {
        try CurrentWeatherWidgetTestFixtures.cachedData(
            at: .currentLocation,
            containerURL: containerURL
        )
    }
}

private enum CurrentLocationRefreshEvent: Equatable {
    case beginWrite
    case acquireLocation
    case resolveTownship
    case fetchWeather
    case synchronizeClock
    case writeSnapshot
}

private final class CurrentLocationRefreshEventRecorder:
    @unchecked Sendable
{
    private let lock = NSLock()
    private var storedEvents: [CurrentLocationRefreshEvent] = []

    var events: [CurrentLocationRefreshEvent] {
        lock.lock()
        defer { lock.unlock() }
        return storedEvents
    }

    func record(_ event: CurrentLocationRefreshEvent) {
        lock.lock()
        storedEvents.append(event)
        lock.unlock()
    }
}
