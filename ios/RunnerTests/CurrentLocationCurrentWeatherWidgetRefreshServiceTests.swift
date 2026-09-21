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
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation()),
            recorder: recorder
        )
        let writer = CurrentLocationSnapshotWriterSpy(recorder: recorder)
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
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation())
        )
        let service = makeService(
            weather: weather,
            writeSnapshot: CurrentLocationSnapshotWriterSpy().write
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

    func testLocationUnavailableDoesNotStartNetworkOrWrite() async throws {
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation())
        )
        let clock = CurrentLocationScriptedClock(sample: makeSnapshotTime())
        let writer = CurrentLocationSnapshotWriterSpy()
        let service = makeService(
            locationResult: .unavailable,
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

    func testLocationTimeoutIsUnavailableWithoutWrite() async throws {
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentLocationSnapshotWriterSpy()
        let service = makeService(
            locationResult: .timedOut,
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh()
        let weatherCallCount = await weather.callCount
        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(weatherCallCount, 0)
        XCTAssertEqual(writer.writeCount, 0)
    }

    func testLocationAcquisitionFailureFailsWithoutWrite() async throws {
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentLocationSnapshotWriterSpy()
        let service = makeService(
            locationResult: .failed,
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh()
        let weatherCallCount = await weather.callCount
        XCTAssertEqual(result, .failed)
        XCTAssertEqual(weatherCallCount, 0)
        XCTAssertEqual(writer.writeCount, 0)
    }

    func testTownshipResolutionFailureDoesNotStartNetworkOrWrite()
        async throws
    {
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation())
        )
        let clock = CurrentLocationScriptedClock(sample: makeSnapshotTime())
        let writer = CurrentLocationSnapshotWriterSpy()
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
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentLocationSnapshotWriterSpy()
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
        let weather = CurrentLocationScriptedWeather(result: .success(nil))
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = makeService(
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh()
        XCTAssertEqual(result, .noObservation)
        XCTAssertEqual(try cachedData(), oldData)
    }

    func testWeatherFailureLeavesExistingCurrentLocationCacheUntouched()
        async throws
    {
        let oldData = try seedExistingSnapshot()
        let weather = CurrentLocationScriptedWeather(
            result: .failure(.scripted)
        )
        let writer = CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
        let service = makeService(
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh()
        XCTAssertEqual(result, .failed)
        XCTAssertEqual(try cachedData(), oldData)
    }

    func testFirstClockSyncFailureWithoutAnchorDoesNotWrite() async throws {
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentLocationSnapshotWriterSpy()
        let clock = makeClock(serverResults: [.failure(.scripted)])
        let service = makeService(
            weather: weather,
            clock: clock,
            writeSnapshot: writer.write
        )

        let result = await service.refresh()
        let hasSynchronized = await clock.hasSynchronized
        XCTAssertEqual(result, .failed)
        XCTAssertFalse(hasSynchronized)
        XCTAssertEqual(writer.writeCount, 0)
    }

    func testLaterClockSyncFailureUsesRetainedAnchor() async throws {
        let monotonicClock = CurrentLocationTestMonotonicClock(
            milliseconds: 100
        )
        let clock = makeClock(
            monotonicClock: monotonicClock,
            serverResults: [
                .success(10_000),
                .failure(.scripted),
            ]
        )
        let firstSyncSucceeded = await clock.synchronize()
        XCTAssertTrue(firstSyncSucceeded)
        monotonicClock.set(milliseconds: 600)
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentLocationSnapshotWriterSpy()
        let service = makeService(
            weather: weather,
            clock: clock,
            writeSnapshot: writer.write
        )

        let result = await service.refresh()
        XCTAssertEqual(result, .refreshed)
        XCTAssertEqual(writer.writeCount, 1)
        XCTAssertEqual(
            writer.snapshots.first?.calibratedTimeOffsetMilliseconds,
            5_500
        )
    }

    func testWriterFailureLeavesExistingCurrentLocationCacheUntouched()
        async throws
    {
        let oldData = try seedExistingSnapshot()
        let weather = CurrentLocationScriptedWeather(
            result: .success(try makeObservation())
        )
        let writer = CurrentLocationSnapshotWriterSpy(error: .scripted)
        let service = makeService(
            weather: weather,
            writeSnapshot: writer.write
        )

        let result = await service.refresh()
        XCTAssertEqual(result, .failed)
        XCTAssertEqual(writer.writeCount, 1)
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
            weather: CurrentLocationScriptedWeather(
                result: .success(try makeObservation())
            ),
            writeSnapshot: writer.write
        )
        let secondService = makeService(
            resolvedLocation: resolvedLocation(
                regionCode: "110",
                regionName: "信義區",
                latitude: 25.0333200,
                longitude: 121.5701000
            ),
            weather: CurrentLocationScriptedWeather(
                result: .success(try makeObservation())
            ),
            writeSnapshot: writer.write
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

    func testWeatherAndClockRunConcurrentlyAfterTownshipResolution()
        async throws
    {
        let weatherGate = CurrentLocationRefreshOperationGate()
        let clockGate = CurrentLocationRefreshOperationGate()
        let observation = try makeObservation()
        let resolvedLocation = resolvedLocation()
        let snapshotTime = makeSnapshotTime()
        let writer = CurrentLocationSnapshotWriterSpy()
        let service = CurrentLocationCurrentWeatherWidgetRefreshService(
            acquireLocation: { @MainActor [preciseLocation] in
                .acquired(preciseLocation)
            },
            resolveTownship: { _ in
                resolvedLocation
            },
            fetchWeather: { _, _ in
                await weatherGate.wait()
                return observation
            },
            synchronizeClock: {
                await clockGate.wait()
                return snapshotTime
            },
            writeSnapshot: writer.write
        )

        let refresh = Task { await service.refresh() }
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
        locationResult: WidgetCurrentLocationResult? = nil,
        resolvedLocation: WidgetResolvedWeatherLocation? = nil,
        shouldResolveTownship: Bool = true,
        recorder: CurrentLocationRefreshEventRecorder? = nil,
        weather: CurrentLocationScriptedWeather,
        synchronizeClock: @escaping
            CurrentLocationCurrentWeatherWidgetRefreshService
                .SynchronizeClock = {
                    CurrentWeatherSnapshotTime(
                        calibratedNowUnixMilliseconds: 1_710_907_200_000,
                        calibratedTimeOffsetMilliseconds: 321
                    )
                },
        writeSnapshot: @escaping
            CurrentLocationCurrentWeatherWidgetRefreshService.WriteSnapshot
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
            writeSnapshot: writeSnapshot
        )
    }

    private func makeService(
        weather: CurrentLocationScriptedWeather,
        clock: WidgetServerClock,
        writeSnapshot: @escaping
            CurrentLocationCurrentWeatherWidgetRefreshService.WriteSnapshot
    ) -> CurrentLocationCurrentWeatherWidgetRefreshService {
        let preciseLocation = preciseLocation
        let resolvedLocation = resolvedLocation()
        return CurrentLocationCurrentWeatherWidgetRefreshService(
            acquireLocation: { @MainActor in
                .acquired(preciseLocation)
            },
            resolveTownship: { location in
                guard location == preciseLocation else {
                    return nil
                }
                return resolvedLocation
            },
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

    private func resolvedLocation(
        regionCode: String = "407",
        regionName: String = "西屯區",
        latitude: Double = 24.1813400,
        longitude: Double = 120.6466200
    ) -> WidgetResolvedWeatherLocation {
        WidgetResolvedWeatherLocation(
            address: .currentLocation,
            regionCode: regionCode,
            regionName: regionName,
            latitude: latitude,
            longitude: longitude
        )!
    }

    private func makeObservation() throws -> CurrentWeatherRemoteDTO {
        try JSONDecoder().decode(
            CurrentWeatherRemoteDTO.self,
            from: Data(
                """
                {
                  "station": {"name": "西屯測站"},
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
        )
    }

    private func makeSnapshotTime() -> CurrentWeatherSnapshotTime {
        CurrentWeatherSnapshotTime(
            calibratedNowUnixMilliseconds: 1_710_907_200_000,
            calibratedTimeOffsetMilliseconds: 321
        )
    }

    private func makeClock(
        monotonicClock: CurrentLocationTestMonotonicClock =
            CurrentLocationTestMonotonicClock(milliseconds: 100),
        serverResults: [Result<Int64, CurrentLocationRefreshTestError>]
    ) -> WidgetServerClock {
        WidgetServerClock(
            deviceClock: CurrentLocationTestWallClock(milliseconds: 5_000),
            monotonicClock: monotonicClock,
            serverTimeSource: CurrentLocationScriptedServerTimeSource(
                results: serverResults
            ),
            timeoutRunner: CurrentLocationPassthroughTimeoutRunner()
        )
    }

    @discardableResult
    private func seedExistingSnapshot() throws -> Data {
        try CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        ).write(
            CurrentWeatherWidgetSnapshot(
                schemaVersion: 5,
                sourceIdentifier: "current-location",
                regionCode: "407",
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
        return try cachedData()
    }

    private func cachedData() throws -> Data {
        try Data(
            contentsOf: CurrentWeatherSnapshotStorage(
                containerURL: containerURL
            ).snapshotURL(for: .currentLocation)
        )
    }
}

private enum CurrentLocationRefreshTestError: Error, Sendable {
    case scripted
}

private enum CurrentLocationRefreshEvent: Equatable {
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

private actor CurrentLocationScriptedWeather {
    struct Coordinates: Sendable {
        let latitude: Double
        let longitude: Double
    }

    private(set) var callCount = 0
    private(set) var coordinates: [Coordinates] = []
    private let result: Result<
        CurrentWeatherRemoteDTO?,
        CurrentLocationRefreshTestError
    >
    private let recorder: CurrentLocationRefreshEventRecorder?

    init(
        result: Result<
            CurrentWeatherRemoteDTO?,
            CurrentLocationRefreshTestError
        >,
        recorder: CurrentLocationRefreshEventRecorder? = nil
    ) {
        self.result = result
        self.recorder = recorder
    }

    func fetch(
        latitude: Double,
        longitude: Double
    ) throws -> CurrentWeatherRemoteDTO? {
        recorder?.record(.fetchWeather)
        callCount += 1
        coordinates.append(
            Coordinates(latitude: latitude, longitude: longitude)
        )
        return try result.get()
    }
}

private actor CurrentLocationScriptedClock {
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

private final class CurrentLocationSnapshotWriterSpy: @unchecked Sendable {
    private let lock = NSLock()
    private let error: CurrentLocationRefreshTestError?
    private let recorder: CurrentLocationRefreshEventRecorder?
    private var storedSnapshots: [CurrentWeatherWidgetSnapshot] = []
    private var storedWriteCount = 0

    init(
        error: CurrentLocationRefreshTestError? = nil,
        recorder: CurrentLocationRefreshEventRecorder? = nil
    ) {
        self.error = error
        self.recorder = recorder
    }

    var snapshots: [CurrentWeatherWidgetSnapshot] {
        lock.lock()
        defer { lock.unlock() }
        return storedSnapshots
    }

    var writeCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedWriteCount
    }

    func write(_ snapshot: CurrentWeatherWidgetSnapshot) throws {
        recorder?.record(.writeSnapshot)
        lock.lock()
        storedWriteCount += 1
        let error = error
        if error == nil {
            storedSnapshots.append(snapshot)
        }
        lock.unlock()

        if let error {
            throw error
        }
    }
}

private actor CurrentLocationRefreshOperationGate {
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

private final class CurrentLocationTestWallClock: WidgetWallTimeSource,
    @unchecked Sendable
{
    private let milliseconds: Int64

    init(milliseconds: Int64) {
        self.milliseconds = milliseconds
    }

    func now() -> Date {
        Date(
            timeIntervalSince1970: TimeInterval(milliseconds) / 1_000
        )
    }
}

private final class CurrentLocationTestMonotonicClock:
    WidgetMonotonicTimeSource,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var milliseconds: Int64

    init(milliseconds: Int64) {
        self.milliseconds = milliseconds
    }

    func elapsedMilliseconds() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return milliseconds
    }

    func set(milliseconds: Int64) {
        lock.lock()
        self.milliseconds = milliseconds
        lock.unlock()
    }
}

private actor CurrentLocationScriptedServerTimeSource:
    WidgetServerTimeSource
{
    private var results: [
        Result<Int64, CurrentLocationRefreshTestError>
    ]

    init(results: [Result<Int64, CurrentLocationRefreshTestError>]) {
        self.results = results
    }

    func serverTimeUnixMilliseconds() throws -> Int64 {
        guard !results.isEmpty else {
            throw CurrentLocationRefreshTestError.scripted
        }
        return try results.removeFirst().get()
    }
}

private struct CurrentLocationPassthroughTimeoutRunner:
    WidgetServerClockTimeoutRunning
{
    func serverTimeUnixMilliseconds(
        from source: any WidgetServerTimeSource,
        timeout: TimeInterval
    ) async throws -> Int64 {
        try await source.serverTimeUnixMilliseconds()
    }
}
