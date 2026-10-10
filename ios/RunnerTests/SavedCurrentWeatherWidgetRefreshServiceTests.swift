import Foundation
import XCTest

final class SavedCurrentWeatherWidgetRefreshServiceTests: XCTestCase {
    private var containerURL: URL!

    override func setUpWithError() throws {
        containerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: containerURL)
        containerURL = nil
    }

    func testSavedTargetWritesCorrectRegionCache() async throws {
        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = try makeService(
            codes: ["242", "433"],
            weather: weather,
            writeSnapshot: { snapshot in
                try CurrentWeatherWidgetTestFixtures.write(
                    snapshot,
                    to: .saved(regionCode: "242"),
                    using: writer
                )
            }
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .refreshed)
        let storage = CurrentWeatherSnapshotStorage(
            containerURL: containerURL
        )
        let savedURL = storage.snapshotURL(
            for: .saved(regionCode: "242")
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: storage.snapshotURL(
                    for: .saved(regionCode: "433")
                ).path
            )
        )
    }

    func testUnresolvableTargetsDoNotStartRefreshWork() async throws {
        let targets: [WidgetLocationTarget] = [
            .currentLocation,
            .invalid(identifier: "region:２４２"),
            .saved(regionCode: "433"),
        ]

        for target in targets {
            let weather = ScriptedCurrentWeather(
                result: .success(try makeObservation())
            )
            let clock = ScriptedSnapshotClock(sample: makeSnapshotTime())
            let writer = CurrentWeatherSnapshotWriterSpy()
            let service = try makeService(
                codes: ["242"],
                weather: weather,
                synchronizeClock: {
                    await clock.synchronizeAndSample()
                },
                writeSnapshot: writer.write
            )

            let result = await service.refresh(target: target)
            let weatherCallCount = await weather.callCount
            let clockCallCount = await clock.callCount

            XCTAssertEqual(result, .unavailable, "\(target)")
            XCTAssertEqual(weatherCallCount, 0, "\(target)")
            XCTAssertEqual(clockCallCount, 0, "\(target)")
            XCTAssertEqual(writer.writeCount, 0, "\(target)")
        }
    }

    func testSuccessfulRefreshWritesSchemaSevenResolvedSnapshot() async throws {
        let observation = try makeObservation()
        let weather = ScriptedCurrentWeather(
            result: .success(observation)
        )
        let clock = makeClock(
            serverResults: [.success(10_000)]
        )
        let writer = CurrentWeatherSnapshotWriterSpy()
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            clock: clock,
            writeSnapshot: writer.write
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .refreshed)
        let snapshot = try XCTUnwrap(writer.snapshots.first)
        XCTAssertEqual(snapshot.schemaVersion, 7)
        XCTAssertEqual(snapshot.sourceIdentifier, "region:242")
        XCTAssertEqual(snapshot.regionCode, "242")
        XCTAssertEqual(snapshot.regionName, "新莊區")
        XCTAssertEqual(snapshot.observationTime, observation.time)
        XCTAssertEqual(snapshot.stationName, observation.stationName)
        XCTAssertEqual(snapshot.weather, observation.weather)
        XCTAssertEqual(snapshot.weatherCode, observation.weatherCode)
        XCTAssertEqual(snapshot.temperature, observation.temperature)
        XCTAssertEqual(snapshot.humidity, observation.humidity)
        XCTAssertEqual(snapshot.rain, observation.rain)
        XCTAssertEqual(snapshot.windDirection, observation.windDirection)
        XCTAssertEqual(snapshot.windSpeed, observation.windSpeed)
        XCTAssertEqual(
            try XCTUnwrap(snapshot.apparentTemperature),
            31.39512521394631,
            accuracy: 1e-9
        )
        XCTAssertEqual(snapshot.calibratedTimeOffsetMilliseconds, 5_000)
        let coordinates = await weather.coordinates
        XCTAssertEqual(coordinates.count, 1)
        XCTAssertEqual(coordinates.first?.latitude, 25.0358303)
        XCTAssertEqual(coordinates.first?.longitude, 121.4500307)
    }

    func testMissingWindStillRefreshesWithNilApparentTemperature() async throws {
        let weather = ScriptedCurrentWeather(
            result: .success(try CurrentWeatherWidgetTestFixtures.observation(
                windSpeed: "null"
            ))
        )
        let writer = CurrentWeatherSnapshotWriterSpy()
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh(target: .saved(regionCode: "242"))
        XCTAssertEqual(result, .refreshed)
        let snapshot = try XCTUnwrap(writer.snapshots.first)
        XCTAssertNil(snapshot.apparentTemperature)
    }

    func testFirstClockSyncFailureDoesNotWrite() async throws {
        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentWeatherSnapshotWriterSpy()
        let clock = makeClock(
            serverResults: [.failure(WidgetRefreshTestError.scripted)]
        )
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            clock: clock,
            writeSnapshot: writer.write
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .failed)
        let hasSynchronized = await clock.hasSynchronized
        let weatherCallCount = await weather.callCount
        XCTAssertFalse(hasSynchronized)
        XCTAssertEqual(weatherCallCount, 1)
        XCTAssertEqual(writer.writeCount, 0)
    }

    func testLaterClockSyncFailureUsesRetainedAnchor() async throws {
        let wallClock = TestWallClock(milliseconds: 5_000)
        let monotonicClock = TestMonotonicClock(milliseconds: 100)
        let clock = makeClock(
            wallClock: wallClock,
            monotonicClock: monotonicClock,
            serverResults: [
                .success(10_000),
                .failure(WidgetRefreshTestError.scripted),
            ]
        )
        let firstSyncSucceeded = await clock.synchronize()
        XCTAssertTrue(firstSyncSucceeded)
        monotonicClock.set(milliseconds: 600)

        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentWeatherSnapshotWriterSpy()
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            clock: clock,
            writeSnapshot: writer.write
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .refreshed)
        let hasSynchronized = await clock.hasSynchronized
        XCTAssertTrue(hasSynchronized)
        XCTAssertEqual(writer.writeCount, 1)
        XCTAssertEqual(
            writer.snapshots.first?.calibratedTimeOffsetMilliseconds,
            5_500
        )
    }

    func testWeatherFailureKeepsExistingCache() async throws {
        let oldData = try seedExistingSnapshot(regionCode: "242")
        let weather = ScriptedCurrentWeather(
            result: .failure(.scripted)
        )
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            writeSnapshot: { snapshot in
                try CurrentWeatherWidgetTestFixtures.write(
                    snapshot,
                    to: .saved(regionCode: "242"),
                    using: writer
                )
            }
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .failed)
        XCTAssertEqual(try cachedData(regionCode: "242"), oldData)
    }

    func testNoObservationKeepsExistingCache() async throws {
        let oldData = try seedExistingSnapshot(regionCode: "242")
        let weather = ScriptedCurrentWeather(result: .success(nil))
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            writeSnapshot: { snapshot in
                try CurrentWeatherWidgetTestFixtures.write(
                    snapshot,
                    to: .saved(regionCode: "242"),
                    using: writer
                )
            }
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .noObservation)
        XCTAssertEqual(try cachedData(regionCode: "242"), oldData)
    }

    func testWriterFailureKeepsExistingCache() async throws {
        let oldData = try seedExistingSnapshot(regionCode: "242")
        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentWeatherSnapshotWriterSpy(error: .scripted)
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .failed)
        XCTAssertEqual(writer.writeCount, 1)
        XCTAssertEqual(try cachedData(regionCode: "242"), oldData)
    }

    func testRegionARefreshNeverOverwritesRegionBCache() async throws {
        let regionBData = try seedExistingSnapshot(regionCode: "433")
        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = try makeService(
            codes: ["242", "433"],
            weather: weather,
            writeSnapshot: { snapshot in
                try CurrentWeatherWidgetTestFixtures.write(
                    snapshot,
                    to: .saved(regionCode: "242"),
                    using: writer
                )
            }
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .refreshed)
        XCTAssertEqual(try cachedData(regionCode: "433"), regionBData)
        XCTAssertNotNil(try? cachedData(regionCode: "242"))
    }

    func testWeatherAndClockStartBeforeEitherCompletes() async throws {
        let weatherGate = AsyncOperationGate()
        let clockGate = AsyncOperationGate()
        let observation = try makeObservation()
        let writer = CurrentWeatherSnapshotWriterSpy()
        let resolver = try makeResolver(codes: ["242"])
        let service = SavedCurrentWeatherWidgetRefreshService(
            resolveLocation: resolver.resolve,
            beginWrite: { address in
                CurrentWeatherSnapshotWriteToken(
                    address: address,
                    generation: 1
                )
            },
            pipeline: CurrentWeatherWidgetRefreshPipeline(
                fetchWeather: { _, _ in
                    await weatherGate.wait()
                    return observation
                },
                synchronizeClock: {
                    await clockGate.wait()
                    return self.makeSnapshotTime()
                },
                commitSnapshot: { snapshot, _ in
                    try writer.write(snapshot)
                    return .written
                }
            )
        )

        let refresh = Task {
            await service.refresh(
                target: .saved(regionCode: "242")
            )
        }
        for _ in 0..<200 {
            if await weatherGate.hasStarted,
               await clockGate.hasStarted {
                break
            }
            await Task.yield()
        }

        let weatherStarted = await weatherGate.hasStarted
        let clockStarted = await clockGate.hasStarted
        XCTAssertTrue(weatherStarted)
        XCTAssertTrue(clockStarted)
        await weatherGate.open()
        await clockGate.open()
        let result = await refresh.value
        XCTAssertEqual(result, .refreshed)
    }

    func testRejectedWriteReturnsSuperseded() async throws {
        let resolver = try makeResolver(codes: ["242"])
        let weather = ScriptedCurrentWeather(
            result: .success(try makeObservation())
        )
        let expectedToken = CurrentWeatherSnapshotWriteToken(
            address: .saved(regionCode: "242"),
            generation: 7
        )
        let service = SavedCurrentWeatherWidgetRefreshService(
            resolveLocation: resolver.resolve,
            beginWrite: { address in
                XCTAssertEqual(address, expectedToken.address)
                return expectedToken
            },
            pipeline: CurrentWeatherWidgetRefreshPipeline(
                fetchWeather: { latitude, longitude in
                    try await weather.fetch(
                        latitude: latitude,
                        longitude: longitude
                    )
                },
                synchronizeClock: makeSnapshotTime,
                commitSnapshot: { _, token in
                    XCTAssertEqual(token, expectedToken)
                    return .rejected
                }
            )
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .superseded)
    }

    private func makeService(
        codes: [String],
        weather: ScriptedCurrentWeather,
        synchronizeClock: @escaping
            CurrentWeatherWidgetRefreshPipeline.SynchronizeClock = {
                CurrentWeatherSnapshotTime(
                    calibratedNowUnixMilliseconds: 1_710_907_200_000,
                    calibratedTimeOffsetMilliseconds: 0
                )
            },
        writeSnapshot: @escaping @Sendable (
            CurrentWeatherWidgetSnapshot
        ) throws -> Void
    ) throws -> SavedCurrentWeatherWidgetRefreshService {
        let resolver = try makeResolver(codes: codes)
        return SavedCurrentWeatherWidgetRefreshService(
            resolveLocation: resolver.resolve,
            beginWrite: { address in
                CurrentWeatherSnapshotWriteToken(
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
                synchronizeClock: synchronizeClock,
                commitSnapshot: { snapshot, _ in
                    try writeSnapshot(snapshot)
                    return .written
                }
            )
        )
    }

    private func makeService(
        codes: [String],
        weather: ScriptedCurrentWeather,
        clock: WidgetServerClock,
        writeSnapshot: @escaping @Sendable (
            CurrentWeatherWidgetSnapshot
        ) throws -> Void
    ) throws -> SavedCurrentWeatherWidgetRefreshService {
        let resolver = try makeResolver(codes: codes)
        return SavedCurrentWeatherWidgetRefreshService(
            resolveLocation: resolver.resolve,
            beginWrite: { address in
                CurrentWeatherSnapshotWriteToken(
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
                    await CurrentWeatherWidgetRefreshPipeline
                        .synchronizedSnapshotTime(clock: clock)
                },
                commitSnapshot: { snapshot, _ in
                    try writeSnapshot(snapshot)
                    return .written
                }
            )
        )
    }

    private func makeResolver(
        codes: [String]
    ) throws -> SavedWidgetLocationResolver {
        let locations = try codes.map { code in
            try XCTUnwrap(makeCatalogLocation(regionCode: code))
        }
        let catalog = try XCTUnwrap(
            WidgetLocationCatalog(
                schemaVersion: 1,
                locations: locations
            )
        )
        return SavedWidgetLocationResolver(catalog: catalog)
    }

    private func makeCatalogLocation(
        regionCode: String
    ) -> WidgetLocationCatalogLocation? {
        CurrentWeatherWidgetTestFixtures.catalogLocation(
            regionCode: regionCode
        )
    }

    private func makeObservation() throws -> CurrentWeatherRemoteDTO {
        try CurrentWeatherWidgetTestFixtures.observation(
            stationName: "板橋"
        )
    }

    private func makeSnapshotTime() -> CurrentWeatherSnapshotTime {
        CurrentWeatherWidgetTestFixtures.snapshotTime(
            offsetMilliseconds: 0
        )
    }

    private func makeClock(
        wallClock: TestWallClock = TestWallClock(milliseconds: 5_000),
        monotonicClock: TestMonotonicClock =
            TestMonotonicClock(milliseconds: 100),
        serverResults: [Result<Int64, Error>]
    ) -> WidgetServerClock {
        WidgetServerClock(
            deviceClock: wallClock,
            monotonicClock: monotonicClock,
            serverTimeSource: ScriptedServerTimeSource(
                results: serverResults
            ),
            timeoutRunner: PassthroughServerClockTimeoutRunner()
        )
    }

    @discardableResult
    private func seedExistingSnapshot(
        regionCode: String
    ) throws -> Data {
        let address = CurrentWeatherSnapshotAddress.saved(
            regionCode: regionCode
        )
        return try CurrentWeatherWidgetTestFixtures.seed(
            CurrentWeatherWidgetTestFixtures.snapshot(
                sourceIdentifier: "region:\(regionCode)",
                regionCode: regionCode
            ),
            at: address,
            containerURL: containerURL
        )
    }

    private func cachedData(regionCode: String) throws -> Data {
        try CurrentWeatherWidgetTestFixtures.cachedData(
            at: .saved(regionCode: regionCode),
            containerURL: containerURL
        )
    }
}
