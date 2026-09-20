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
        let weather = ScriptedRefreshWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = try makeService(
            codes: ["242", "433"],
            weather: weather,
            writeSnapshot: writer.write
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

    func testCurrentLocationTargetIsUnavailableWithoutStartingWork() async throws {
        let weather = ScriptedRefreshWeather(
            result: .success(try makeObservation())
        )
        let clock = ScriptedRefreshClock(
            sample: makeSnapshotTime()
        )
        let writer = RefreshSnapshotWriterSpy()
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            synchronizeClock: {
                await clock.synchronizeAndSample()
            },
            writeSnapshot: writer.write
        )

        let result = await service.refresh(target: .currentLocation)

        XCTAssertEqual(result, .unavailable)
        let weatherCallCount = await weather.callCount
        let clockCallCount = await clock.callCount
        XCTAssertEqual(weatherCallCount, 0)
        XCTAssertEqual(clockCallCount, 0)
        XCTAssertEqual(writer.writeCount, 0)
    }

    func testInvalidTargetIsUnavailableWithoutStartingWork() async throws {
        let weather = ScriptedRefreshWeather(
            result: .success(try makeObservation())
        )
        let clock = ScriptedRefreshClock(
            sample: makeSnapshotTime()
        )
        let writer = RefreshSnapshotWriterSpy()
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            synchronizeClock: {
                await clock.synchronizeAndSample()
            },
            writeSnapshot: writer.write
        )

        let result = await service.refresh(
            target: .invalid(identifier: "region:２４２")
        )

        XCTAssertEqual(result, .unavailable)
        let weatherCallCount = await weather.callCount
        let clockCallCount = await clock.callCount
        XCTAssertEqual(weatherCallCount, 0)
        XCTAssertEqual(clockCallCount, 0)
        XCTAssertEqual(writer.writeCount, 0)
    }

    func testMissingSavedRegionIsUnavailableWithoutStartingWork() async throws {
        let weather = ScriptedRefreshWeather(
            result: .success(try makeObservation())
        )
        let clock = ScriptedRefreshClock(
            sample: makeSnapshotTime()
        )
        let writer = RefreshSnapshotWriterSpy()
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            synchronizeClock: {
                await clock.synchronizeAndSample()
            },
            writeSnapshot: writer.write
        )

        let result = await service.refresh(
            target: .saved(regionCode: "433")
        )

        XCTAssertEqual(result, .unavailable)
        let weatherCallCount = await weather.callCount
        let clockCallCount = await clock.callCount
        XCTAssertEqual(weatherCallCount, 0)
        XCTAssertEqual(clockCallCount, 0)
        XCTAssertEqual(writer.writeCount, 0)
    }

    func testSuccessfulRefreshWritesSchemaFiveResolvedSnapshot() async throws {
        let observation = try makeObservation()
        let weather = ScriptedRefreshWeather(
            result: .success(observation)
        )
        let clock = makeClock(
            serverResults: [.success(10_000)]
        )
        let writer = RefreshSnapshotWriterSpy()
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
        XCTAssertEqual(snapshot.schemaVersion, 5)
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
        XCTAssertEqual(snapshot.calibratedTimeOffsetMilliseconds, 5_000)
        let coordinates = await weather.coordinates
        XCTAssertEqual(coordinates.count, 1)
        XCTAssertEqual(coordinates.first?.latitude, 25.0358303)
        XCTAssertEqual(coordinates.first?.longitude, 121.4500307)
    }

    func testFirstClockSyncFailureDoesNotWrite() async throws {
        let weather = ScriptedRefreshWeather(
            result: .success(try makeObservation())
        )
        let writer = RefreshSnapshotWriterSpy()
        let clock = makeClock(
            serverResults: [.failure(.scripted)]
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
        let wallClock = RefreshTestWallClock(milliseconds: 5_000)
        let monotonicClock = RefreshTestMonotonicClock(milliseconds: 100)
        let clock = makeClock(
            wallClock: wallClock,
            monotonicClock: monotonicClock,
            serverResults: [
                .success(10_000),
                .failure(.scripted),
            ]
        )
        let firstSyncSucceeded = await clock.synchronize()
        XCTAssertTrue(firstSyncSucceeded)
        monotonicClock.set(milliseconds: 600)

        let weather = ScriptedRefreshWeather(
            result: .success(try makeObservation())
        )
        let writer = RefreshSnapshotWriterSpy()
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
        let weather = ScriptedRefreshWeather(
            result: .failure(.scripted)
        )
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .failed)
        XCTAssertEqual(try cachedData(regionCode: "242"), oldData)
    }

    func testNoObservationKeepsExistingCache() async throws {
        let oldData = try seedExistingSnapshot(regionCode: "242")
        let weather = ScriptedRefreshWeather(result: .success(nil))
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = try makeService(
            codes: ["242"],
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .noObservation)
        XCTAssertEqual(try cachedData(regionCode: "242"), oldData)
    }

    func testWriterFailureKeepsExistingCache() async throws {
        let oldData = try seedExistingSnapshot(regionCode: "242")
        let weather = ScriptedRefreshWeather(
            result: .success(try makeObservation())
        )
        let writer = RefreshSnapshotWriterSpy(error: .scripted)
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
        let weather = ScriptedRefreshWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = try makeService(
            codes: ["242", "433"],
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh(
            target: .saved(regionCode: "242")
        )

        XCTAssertEqual(result, .refreshed)
        XCTAssertEqual(try cachedData(regionCode: "433"), regionBData)
        XCTAssertNotNil(try? cachedData(regionCode: "242"))
    }

    func testWeatherAndClockStartBeforeEitherCompletes() async throws {
        let weatherGate = RefreshOperationGate()
        let clockGate = RefreshOperationGate()
        let observation = try makeObservation()
        let writer = RefreshSnapshotWriterSpy()
        let resolver = try makeResolver(codes: ["242"])
        let service = SavedCurrentWeatherWidgetRefreshService(
            resolveLocation: resolver.resolve,
            fetchWeather: { _, _ in
                await weatherGate.wait()
                return observation
            },
            synchronizeClock: {
                await clockGate.wait()
                return self.makeSnapshotTime()
            },
            writeSnapshot: writer.write
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

    private func makeService(
        codes: [String],
        weather: ScriptedRefreshWeather,
        synchronizeClock: @escaping
            SavedCurrentWeatherWidgetRefreshService.SynchronizeClock = {
                CurrentWeatherSnapshotTime(
                    calibratedNowUnixMilliseconds: 1_710_907_200_000,
                    calibratedTimeOffsetMilliseconds: 0
                )
            },
        writeSnapshot: @escaping
            SavedCurrentWeatherWidgetRefreshService.WriteSnapshot
    ) throws -> SavedCurrentWeatherWidgetRefreshService {
        let resolver = try makeResolver(codes: codes)
        return SavedCurrentWeatherWidgetRefreshService(
            resolveLocation: resolver.resolve,
            fetchWeather: { latitude, longitude in
                try await weather.fetch(
                    latitude: latitude,
                    longitude: longitude
                )
            },
            synchronizeClock: synchronizeClock,
            writeSnapshot: writeSnapshot
        )
    }

    private func makeService(
        codes: [String],
        weather: ScriptedRefreshWeather,
        clock: WidgetServerClock,
        writeSnapshot: @escaping
            SavedCurrentWeatherWidgetRefreshService.WriteSnapshot
    ) throws -> SavedCurrentWeatherWidgetRefreshService {
        let resolver = try makeResolver(codes: codes)
        return SavedCurrentWeatherWidgetRefreshService(
            resolveLocation: resolver.resolve,
            fetchWeather: { latitude, longitude in
                try await weather.fetch(
                    latitude: latitude,
                    longitude: longitude
                )
            },
            clock: clock,
            writeSnapshot: writeSnapshot
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
        switch regionCode {
        case "242":
            return WidgetLocationCatalogLocation(
                regionCode: "242",
                displayName: "新莊區",
                administrativeAreaName: "新北市",
                latitude: 25.0358303,
                longitude: 121.4500307
            )
        case "433":
            return WidgetLocationCatalogLocation(
                regionCode: "433",
                displayName: "沙鹿區",
                administrativeAreaName: "臺中市",
                latitude: 24.2338622,
                longitude: 120.565703
            )
        default:
            return nil
        }
    }

    private func makeObservation() throws -> CurrentWeatherRemoteDTO {
        let data = Data(
            """
            {
              "station": {"name": "板橋"},
              "time": 1710900000,
              "data": {
                "weather": "晴",
                "weatherCode": 100,
                "temperature": 28.5,
                "humidity": 70,
                "rain": 0
              }
            }
            """.utf8
        )
        return try JSONDecoder().decode(
            CurrentWeatherRemoteDTO.self,
            from: data
        )
    }

    private func makeSnapshotTime() -> CurrentWeatherSnapshotTime {
        CurrentWeatherSnapshotTime(
            calibratedNowUnixMilliseconds: 1_710_907_200_000,
            calibratedTimeOffsetMilliseconds: 0
        )
    }

    private func makeClock(
        wallClock: RefreshTestWallClock =
            RefreshTestWallClock(milliseconds: 5_000),
        monotonicClock: RefreshTestMonotonicClock =
            RefreshTestMonotonicClock(milliseconds: 100),
        serverResults: [Result<Int64, RefreshTestError>]
    ) -> WidgetServerClock {
        WidgetServerClock(
            deviceClock: wallClock,
            monotonicClock: monotonicClock,
            serverTimeSource: RefreshScriptedServerTimeSource(
                results: serverResults
            ),
            timeoutRunner: RefreshPassthroughTimeoutRunner()
        )
    }

    @discardableResult
    private func seedExistingSnapshot(
        regionCode: String
    ) throws -> Data {
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        try writer.write(
            CurrentWeatherWidgetSnapshot(
                schemaVersion: 5,
                sourceIdentifier: "region:\(regionCode)",
                regionCode: regionCode,
                regionName: "舊快取",
                observationTime: 1_700_000_000,
                stationName: "舊測站",
                weather: "陰",
                weatherCode: 300,
                condition: .overcast,
                isNight: false,
                nextDayNightTransitionTime: 1_700_010_000,
                calibratedTimeOffsetMilliseconds: 123,
                temperature: 20,
                humidity: 60,
                rain: 1
            )
        )
        return try cachedData(regionCode: regionCode)
    }

    private func cachedData(regionCode: String) throws -> Data {
        let url = CurrentWeatherSnapshotStorage(
            containerURL: containerURL
        ).snapshotURL(for: .saved(regionCode: regionCode))
        return try Data(contentsOf: url)
    }
}

private enum RefreshTestError: Error, Sendable {
    case scripted
}

private actor ScriptedRefreshWeather {
    struct Coordinates: Sendable {
        let latitude: Double
        let longitude: Double
    }

    private(set) var callCount = 0
    private(set) var coordinates: [Coordinates] = []
    private let result: Result<CurrentWeatherRemoteDTO?, RefreshTestError>

    init(result: Result<CurrentWeatherRemoteDTO?, RefreshTestError>) {
        self.result = result
    }

    func fetch(
        latitude: Double,
        longitude: Double
    ) throws -> CurrentWeatherRemoteDTO? {
        callCount += 1
        coordinates.append(
            Coordinates(latitude: latitude, longitude: longitude)
        )
        return try result.get()
    }
}

private actor ScriptedRefreshClock {
    private(set) var callCount = 0
    private let sample: CurrentWeatherSnapshotTime?

    init(sample: CurrentWeatherSnapshotTime?) {
        self.sample = sample
    }

    func synchronizeAndSample() -> CurrentWeatherSnapshotTime? {
        callCount += 1
        return sample
    }
}

private final class RefreshSnapshotWriterSpy: @unchecked Sendable {
    private let lock = NSLock()
    private let error: RefreshTestError?
    private var _snapshots: [CurrentWeatherWidgetSnapshot] = []
    private var _writeCount = 0

    init(error: RefreshTestError? = nil) {
        self.error = error
    }

    var snapshots: [CurrentWeatherWidgetSnapshot] {
        lock.lock()
        defer { lock.unlock() }
        return _snapshots
    }

    var writeCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _writeCount
    }

    func write(_ snapshot: CurrentWeatherWidgetSnapshot) throws {
        lock.lock()
        _writeCount += 1
        let error = error
        if error == nil {
            _snapshots.append(snapshot)
        }
        lock.unlock()

        if let error {
            throw error
        }
    }
}

private actor RefreshOperationGate {
    private(set) var hasStarted = false
    private var isOpen = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        hasStarted = true
        guard !isOpen else {
            return
        }
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

private final class RefreshTestWallClock: WidgetWallTimeSource,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var milliseconds: Int64

    init(milliseconds: Int64) {
        self.milliseconds = milliseconds
    }

    func now() -> Date {
        lock.lock()
        let milliseconds = milliseconds
        lock.unlock()
        return Date(
            timeIntervalSince1970: TimeInterval(milliseconds) / 1_000
        )
    }
}

private final class RefreshTestMonotonicClock: WidgetMonotonicTimeSource,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var milliseconds: Int64

    init(milliseconds: Int64) {
        self.milliseconds = milliseconds
    }

    func elapsedMilliseconds() -> Int64 {
        lock.lock()
        let milliseconds = milliseconds
        lock.unlock()
        return milliseconds
    }

    func set(milliseconds: Int64) {
        lock.lock()
        self.milliseconds = milliseconds
        lock.unlock()
    }
}

private actor RefreshScriptedServerTimeSource: WidgetServerTimeSource {
    private var results: [Result<Int64, RefreshTestError>]

    init(results: [Result<Int64, RefreshTestError>]) {
        self.results = results
    }

    func serverTimeUnixMilliseconds() throws -> Int64 {
        guard !results.isEmpty else {
            throw RefreshTestError.scripted
        }
        return try results.removeFirst().get()
    }
}

private struct RefreshPassthroughTimeoutRunner:
    WidgetServerClockTimeoutRunning
{
    func serverTimeUnixMilliseconds(
        from source: any WidgetServerTimeSource,
        timeout: TimeInterval
    ) async throws -> Int64 {
        try await source.serverTimeUnixMilliseconds()
    }
}
