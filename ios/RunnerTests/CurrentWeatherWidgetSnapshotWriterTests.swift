import XCTest
@testable import Runner

final class CurrentWeatherSnapshotStorageTests: XCTestCase {
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

    func testCurrentLocationResolvesCanonicalURL() {
        let url = storage.snapshotURL(for: .currentLocation)

        XCTAssertEqual(
            url,
            containerURL
                .appendingPathComponent(
                    "WidgetSnapshots",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "current-weather",
                    isDirectory: true
                )
                .appendingPathComponent("current-location.json")
        )
    }

    func testSavedRegionResolvesCanonicalURL() {
        let url = storage.snapshotURL(
            for: .saved(regionCode: "407")
        )

        XCTAssertEqual(
            url,
            containerURL
                .appendingPathComponent(
                    "WidgetSnapshots",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "current-weather",
                    isDirectory: true
                )
                .appendingPathComponent("region-407.json")
        )
    }

    func testReplaceCreatesMissingIntermediateDirectories()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let token = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: token
            ),
            .written
        )

        var isDirectory: ObjCBool = false
        let directoryExists = FileManager.default.fileExists(
            atPath: storage.snapshotURL(for: address)
                .deletingLastPathComponent().path,
            isDirectory: &isDirectory
        )

        XCTAssertTrue(directoryExists)
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testNewerObservationTimeWins() throws {
        let address = CurrentWeatherSnapshotAddress.saved(
            regionCode: "407"
        )
        let first = try storage.beginWrite(for: address)
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "region:407",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: first
            ),
            .written
        )
        let second = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "region:407",
                    regionCode: "407",
                    observationTime: 200
                ),
                using: second
            ),
            .written
        )
        XCTAssertEqual(try cachedSnapshot(for: address).observationTime, 200)
    }

    func testOlderObservationArrivingLaterIsRejected() throws {
        let address = CurrentWeatherSnapshotAddress.saved(
            regionCode: "407"
        )
        let olderRefresh = try storage.beginWrite(for: address)
        let newerRefresh = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "region:407",
                    regionCode: "407",
                    observationTime: 200
                ),
                using: newerRefresh
            ),
            .written
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "region:407",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: olderRefresh
            ),
            .rejected
        )
        XCTAssertEqual(try cachedSnapshot(for: address).observationTime, 200)
    }

    func testSavedRegionOlderGenerationWithNewerObservationWins()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.saved(
            regionCode: "407"
        )
        let olderRefresh = try storage.beginWrite(for: address)
        let newerRefresh = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "region:407",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: newerRefresh
            ),
            .written
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "region:407",
                    regionCode: "407",
                    observationTime: 200
                ),
                using: olderRefresh
            ),
            .written
        )
        XCTAssertEqual(try cachedSnapshot(for: address).observationTime, 200)
    }

    func testSameObservationNewerCurrentLocationTownshipWins()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let region407 = try storage.beginWrite(for: address)
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: region407
            ),
            .written
        )
        let region110 = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 100
                ),
                using: region110
            ),
            .written
        )
        XCTAssertEqual(try cachedSnapshot(for: address).regionCode, "110")
    }

    func testSameObservationOlderCurrentLocationCannotRevertTownship()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let older407 = try storage.beginWrite(for: address)
        let newer110 = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 100
                ),
                using: newer110
            ),
            .written
        )
        let bytesAfterNewerWrite = try Data(
            contentsOf: storage.snapshotURL(for: address)
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: older407
            ),
            .rejected
        )

        XCTAssertEqual(
            try Data(contentsOf: storage.snapshotURL(for: address)),
            bytesAfterNewerWrite
        )
        XCTAssertEqual(try cachedSnapshot(for: address).regionCode, "110")
    }

    func testOlderCurrentLocationWithNewerObservationCannotRevertTownship()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let older407 = try storage.beginWrite(for: address)
        let newer110 = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 100
                ),
                using: newer110
            ),
            .written
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 200
                ),
                using: older407
            ),
            .rejected
        )

        let cached = try cachedSnapshot(for: address)
        XCTAssertEqual(cached.regionCode, "110")
        XCTAssertEqual(cached.observationTime, 100)
    }

    func testSameCurrentLocationRegionUsesObservationBeforeGeneration()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let older = try storage.beginWrite(for: address)
        let newer = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: newer
            ),
            .written
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 200
                ),
                using: older
            ),
            .written
        )
        XCTAssertEqual(try cachedSnapshot(for: address).observationTime, 200)
    }

    func testSameRegionWeatherWriteRetainsNewerLocationFence() throws {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let olderWeather = try storage.beginWrite(for: address)
        let intermediateTownship = try storage.beginWrite(for: address)
        let newestSameTownship = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: newestSameTownship
            ),
            .written
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 200
                ),
                using: olderWeather
            ),
            .written
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 300
                ),
                using: intermediateTownship
            ),
            .rejected
        )

        let cached = try cachedSnapshot(for: address)
        XCTAssertEqual(cached.regionCode, "407")
        XCTAssertEqual(cached.observationTime, 200)
    }

    func testRejectedWeatherStillAdvancesCurrentLocationFence()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let initial = try storage.beginWrite(for: address)
        let intermediateTownship = try storage.beginWrite(for: address)
        let newestSameTownship = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 200
                ),
                using: initial
            ),
            .written
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: newestSameTownship
            ),
            .rejected
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 300
                ),
                using: intermediateTownship
            ),
            .rejected
        )

        let cached = try cachedSnapshot(for: address)
        XCTAssertEqual(cached.regionCode, "407")
        XCTAssertEqual(cached.observationTime, 200)
    }

    func testSavedRegionUsesGenerationForSameObservation() throws {
        let address = CurrentWeatherSnapshotAddress.saved(
            regionCode: "407"
        )
        let older = try storage.beginWrite(for: address)
        let newer = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "region:407",
                    regionCode: "407",
                    regionName: "newer",
                    observationTime: 100
                ),
                using: newer
            ),
            .written
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "region:407",
                    regionCode: "407",
                    regionName: "older",
                    observationTime: 100
                ),
                using: older
            ),
            .rejected
        )
        XCTAssertEqual(try cachedSnapshot(for: address).regionName, "newer")
    }

    func testDifferentTargetsHaveIndependentGenerationsAndCaches()
        throws
    {
        let current = CurrentWeatherSnapshotAddress.currentLocation
        let saved = CurrentWeatherSnapshotAddress.saved(regionCode: "407")
        let currentToken = try storage.beginWrite(for: current)
        let savedToken = try storage.beginWrite(for: saved)

        XCTAssertEqual(currentToken.generation, 1)
        XCTAssertEqual(savedToken.generation, 1)
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 100
                ),
                using: currentToken
            ),
            .written
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "region:407",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: savedToken
            ),
            .written
        )
        XCTAssertEqual(try cachedSnapshot(for: current).regionCode, "110")
        XCTAssertEqual(try cachedSnapshot(for: saved).regionCode, "407")
    }

    func testPreFixSchemaFiveCacheAcceptsFirstEqualObservationWrite()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        try seedUncoordinatedSnapshot(
            snapshotData(
                sourceIdentifier: "current-location",
                regionCode: "407",
                observationTime: 100
            ),
            for: address
        )
        let firstCoordinatedRefresh = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 100
                ),
                using: firstCoordinatedRefresh
            ),
            .written
        )
        XCTAssertEqual(try cachedSnapshot(for: address).regionCode, "110")
    }

    func testLegacyInjectedGenerationMigratesToSidecarOnly() throws {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        var legacySnapshot = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                )
            ) as? [String: Any]
        )
        legacySnapshot["_dpipStorageWriteGeneration"] = 3
        try seedUncoordinatedSnapshot(
            JSONSerialization.data(withJSONObject: legacySnapshot),
            for: address
        )
        let stateURL = orderingStateURL(for: address)
        try FileManager.default.createDirectory(
            at: stateURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(
            "{\"schemaVersion\":1,\"lastIssuedGeneration\":5}".utf8
        ).write(to: stateURL, options: .atomic)

        let migrated = try storage.beginWrite(for: address)
        XCTAssertEqual(migrated.generation, 6)
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 100
                ),
                using: migrated
            ),
            .written
        )

        let canonical = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: Data(contentsOf: storage.snapshotURL(for: address))
            ) as? [String: Any]
        )
        XCTAssertNil(canonical["_dpipStorageWriteGeneration"])
        let sidecar = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: Data(contentsOf: stateURL)
            ) as? [String: Any]
        )
        XCTAssertEqual(sidecar["schemaVersion"] as? Int, 2)
        let committed = try XCTUnwrap(
            sidecar["committedSnapshot"] as? [String: Any]
        )
        XCTAssertEqual(committed["snapshotGeneration"] as? Int, 6)
    }

    func testLegacyCacheAcceptsFirstValidCoordinatedWrite() throws {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        var legacy = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                )
            ) as? [String: Any]
        )
        legacy["schemaVersion"] = 4
        legacy.removeValue(forKey: "sourceIdentifier")
        try seedUncoordinatedSnapshot(
            JSONSerialization.data(withJSONObject: legacy),
            for: address
        )
        let firstCoordinatedRefresh = try storage.beginWrite(for: address)

        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 100
                ),
                using: firstCoordinatedRefresh
            ),
            .written
        )
        XCTAssertEqual(try cachedSnapshot(for: address).regionCode, "110")
    }

    func testDeterministicInterleavingRejectsLateOlderRefresh()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let older = try storage.beginWrite(for: address)
        let newer = try storage.beginWrite(for: address)
        let firstAccessBlocked = expectation(
            description: "older write is blocked before compare"
        )
        let olderFinished = expectation(description: "older write finished")
        let newerFinished = expectation(description: "newer write finished")
        let coordinator = BlockingFirstSnapshotCoordinator(
            firstAccessBlocked: firstAccessBlocked
        )
        let interleavedStorage = CurrentWeatherSnapshotStorage(
            containerURL: containerURL,
            coordinator: coordinator
        )
        let olderResult = SnapshotWriteResultBox()
        let newerResult = SnapshotWriteResultBox()

        DispatchQueue.global().async {
            olderResult.set(
                Result {
                    try interleavedStorage.replace(
                        self.snapshotData(
                            sourceIdentifier: "current-location",
                            regionCode: "407",
                            observationTime: 100
                        ),
                        using: older
                    )
                }
            )
            olderFinished.fulfill()
        }
        wait(for: [firstAccessBlocked], timeout: 2)
        DispatchQueue.global().async {
            newerResult.set(
                Result {
                    try interleavedStorage.replace(
                        self.snapshotData(
                            sourceIdentifier: "current-location",
                            regionCode: "110",
                            observationTime: 100
                        ),
                        using: newer
                    )
                }
            )
            newerFinished.fulfill()
        }
        wait(for: [newerFinished], timeout: 2)
        coordinator.releaseFirstAccess()
        wait(for: [olderFinished], timeout: 2)

        XCTAssertEqual(try newerResult.get().get(), .written)
        XCTAssertEqual(try olderResult.get().get(), .rejected)
        XCTAssertEqual(try cachedSnapshot(for: address).regionCode, "110")
    }

    func testCoordinationFailurePreservesExistingCache() throws {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let token = try storage.beginWrite(for: address)
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: token
            ),
            .written
        )
        let original = try Data(contentsOf: storage.snapshotURL(for: address))
        let nextToken = try storage.beginWrite(for: address)
        let failingStorage = CurrentWeatherSnapshotStorage(
            containerURL: containerURL,
            coordinator: FailingSnapshotCoordinator()
        )

        XCTAssertThrowsError(
            try failingStorage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 100
                ),
                using: nextToken
            )
        )
        XCTAssertEqual(
            try Data(contentsOf: storage.snapshotURL(for: address)),
            original
        )
    }

    func testCrashBeforeSnapshotReplacementFencesAllocatedTokens()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let initial = try storage.beginWrite(for: address)
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: initial
            ),
            .written
        )
        let olderInFlight = try storage.beginWrite(for: address)
        let interrupted = try storage.beginWrite(for: address)
        let failingStorage = CurrentWeatherSnapshotStorage(
            containerURL: containerURL,
            persister: FailingNthSnapshotPersister(failAt: 2)
        )

        XCTAssertThrowsError(
            try failingStorage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 50
                ),
                using: interrupted
            )
        )
        XCTAssertEqual(try cachedSnapshot(for: address).regionCode, "407")

        let recovered = try storage.beginWrite(for: address)
        XCTAssertEqual(recovered.generation, 4)
        XCTAssertThrowsError(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 300
                ),
                using: olderInFlight
            )
        )
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 50
                ),
                using: recovered
            ),
            .written
        )
        XCTAssertEqual(try cachedSnapshot(for: address).regionCode, "110")
    }

    func testCrashAfterSnapshotReplacementRecoversCommittedOrdering()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let initial = try storage.beginWrite(for: address)
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: initial
            ),
            .written
        )
        let olderInFlight = try storage.beginWrite(for: address)
        let interrupted = try storage.beginWrite(for: address)
        let failingStorage = CurrentWeatherSnapshotStorage(
            containerURL: containerURL,
            persister: FailingNthSnapshotPersister(failAt: 3)
        )

        XCTAssertThrowsError(
            try failingStorage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "110",
                    observationTime: 50
                ),
                using: interrupted
            )
        )
        XCTAssertEqual(try cachedSnapshot(for: address).regionCode, "110")

        let recovered = try storage.beginWrite(for: address)
        XCTAssertEqual(recovered.generation, 4)
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 300
                ),
                using: olderInFlight
            ),
            .rejected
        )
        XCTAssertEqual(try cachedSnapshot(for: address).regionCode, "110")
    }

    func testSidecarSnapshotMismatchFailsClosed() throws {
        let address = CurrentWeatherSnapshotAddress.currentLocation
        let initial = try storage.beginWrite(for: address)
        XCTAssertEqual(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 100
                ),
                using: initial
            ),
            .written
        )
        let inFlight = try storage.beginWrite(for: address)
        let mismatched = snapshotData(
            sourceIdentifier: "current-location",
            regionCode: "110",
            observationTime: 200
        )
        try seedUncoordinatedSnapshot(mismatched, for: address)

        XCTAssertThrowsError(
            try storage.replace(
                snapshotData(
                    sourceIdentifier: "current-location",
                    regionCode: "407",
                    observationTime: 300
                ),
                using: inFlight
            )
        )
        XCTAssertEqual(
            try Data(contentsOf: storage.snapshotURL(for: address)),
            mismatched
        )
        XCTAssertThrowsError(try storage.beginWrite(for: address))
    }

    private var storage: CurrentWeatherSnapshotStorage {
        CurrentWeatherSnapshotStorage(containerURL: containerURL)
    }

    private func snapshotData(
        sourceIdentifier: String,
        regionCode: String,
        regionName: String = "西屯區",
        observationTime: Int
    ) -> Data {
        try! JSONEncoder().encode(
            CurrentWeatherWidgetSnapshot(
                schemaVersion: 5,
                sourceIdentifier: sourceIdentifier,
                regionCode: regionCode,
                regionName: regionName,
                observationTime: observationTime,
                stationName: "測站",
                weather: "晴",
                weatherCode: 100,
                condition: .clear,
                isNight: false,
                nextDayNightTransitionTime: 200,
                calibratedTimeOffsetMilliseconds: 0,
                temperature: 25,
                humidity: 60,
                rain: 0
            )
        )
    }

    private func cachedSnapshot(
        for address: CurrentWeatherSnapshotAddress
    ) throws -> CurrentWeatherWidgetSnapshot {
        try JSONDecoder().decode(
            CurrentWeatherWidgetSnapshot.self,
            from: Data(contentsOf: storage.snapshotURL(for: address))
        )
    }

    private func seedUncoordinatedSnapshot(
        _ data: Data,
        for address: CurrentWeatherSnapshotAddress
    ) throws {
        let url = storage.snapshotURL(for: address)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    private func orderingStateURL(
        for address: CurrentWeatherSnapshotAddress
    ) -> URL {
        containerURL
            .appendingPathComponent("WidgetSnapshots", isDirectory: true)
            .appendingPathComponent(
                "current-weather-ordering",
                isDirectory: true
            )
            .appendingPathComponent(address.filename + ".json")
    }
}

private enum SnapshotCoordinationTestError: Error {
    case failed
    case missingResult
}

private struct FailingSnapshotCoordinator:
    CurrentWeatherSnapshotCoordinating
{
    func coordinate<T>(
        writingItemAt url: URL,
        _ accessor: (URL) throws -> T
    ) throws -> T {
        throw SnapshotCoordinationTestError.failed
    }
}

private final class BlockingFirstSnapshotCoordinator:
    CurrentWeatherSnapshotCoordinating,
    @unchecked Sendable
{
    private let lock = NSLock()
    private let firstAccessBlocked: XCTestExpectation
    private let firstAccessGate = DispatchSemaphore(value: 0)
    private var accessCount = 0

    init(firstAccessBlocked: XCTestExpectation) {
        self.firstAccessBlocked = firstAccessBlocked
    }

    func coordinate<T>(
        writingItemAt url: URL,
        _ accessor: (URL) throws -> T
    ) throws -> T {
        lock.lock()
        accessCount += 1
        let shouldBlock = accessCount == 1
        lock.unlock()

        if shouldBlock {
            firstAccessBlocked.fulfill()
            firstAccessGate.wait()
        }
        return try accessor(url)
    }

    func releaseFirstAccess() {
        firstAccessGate.signal()
    }
}

private final class SnapshotWriteResultBox: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<CurrentWeatherSnapshotWriteResult, Error>?

    func set(
        _ result: Result<CurrentWeatherSnapshotWriteResult, Error>
    ) {
        lock.lock()
        self.result = result
        lock.unlock()
    }

    func get() throws -> Result<CurrentWeatherSnapshotWriteResult, Error> {
        lock.lock()
        defer { lock.unlock() }
        guard let result else {
            throw SnapshotCoordinationTestError.missingResult
        }
        return result
    }
}

private final class FailingNthSnapshotPersister:
    CurrentWeatherSnapshotPersisting,
    @unchecked Sendable
{
    private let lock = NSLock()
    private let failAt: Int
    private var writeCount = 0

    init(failAt: Int) {
        self.failAt = failAt
    }

    func write(_ data: Data, to url: URL) throws {
        lock.lock()
        writeCount += 1
        let shouldFail = writeCount == failAt
        lock.unlock()

        if shouldFail {
            throw SnapshotCoordinationTestError.failed
        }
        try data.write(to: url, options: .atomic)
    }
}

final class CurrentWeatherWidgetSnapshotWriterTests: XCTestCase {
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

    func testValidSavedSnapshotWritesRegionCache() throws {
        let snapshot = makeSnapshot(
            sourceIdentifier: "region:407",
            regionCode: "407"
        )

        try writer.write(snapshot)

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: snapshotURL(
                    for: .saved(regionCode: "407")
                ).path
            )
        )
    }

    func testValidCurrentLocationSnapshotWritesCurrentCache()
        throws
    {
        let snapshot = makeSnapshot(
            sourceIdentifier: "current-location",
            regionCode: "407"
        )

        try writer.write(snapshot)

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: snapshotURL(for: .currentLocation).path
            )
        )
    }

    func testWrittenJSONRoundTripsSchemaVersionFiveFields()
        throws
    {
        let original = makeSnapshot(
            sourceIdentifier: "region:407",
            regionCode: "407"
        )

        try writer.write(original)

        let data = try Data(
            contentsOf: snapshotURL(
                for: .saved(regionCode: "407")
            )
        )
        let decoded = try JSONDecoder().decode(
            CurrentWeatherWidgetSnapshot.self,
            from: data
        )

        XCTAssertEqual(decoded.schemaVersion, original.schemaVersion)
        XCTAssertEqual(
            decoded.sourceIdentifier,
            original.sourceIdentifier
        )
        XCTAssertEqual(decoded.regionCode, original.regionCode)
        XCTAssertEqual(decoded.regionName, original.regionName)
        XCTAssertEqual(
            decoded.observationTime,
            original.observationTime
        )
        XCTAssertEqual(decoded.stationName, original.stationName)
        XCTAssertEqual(decoded.weather, original.weather)
        XCTAssertEqual(decoded.weatherCode, original.weatherCode)
        XCTAssertEqual(decoded.condition, original.condition)
        XCTAssertEqual(decoded.isNight, original.isNight)
        XCTAssertEqual(
            decoded.nextDayNightTransitionTime,
            original.nextDayNightTransitionTime
        )
        XCTAssertEqual(
            decoded.calibratedTimeOffsetMilliseconds,
            original.calibratedTimeOffsetMilliseconds
        )
        XCTAssertEqual(decoded.temperature, original.temperature)
        XCTAssertEqual(decoded.humidity, original.humidity)
        XCTAssertEqual(decoded.rain, original.rain)
    }

    func testWrittenJSONContainsExactlyCanonicalSchemaVersionFiveKeys()
        throws
    {
        try writer.write(
            makeSnapshot(
                sourceIdentifier: "region:407",
                regionCode: "407"
            )
        )

        let data = try Data(
            contentsOf: snapshotURL(
                for: .saved(regionCode: "407")
            )
        )
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data)
                as? [String: Any]
        )

        XCTAssertEqual(
            Set(json.keys),
            Set([
                "schemaVersion",
                "sourceIdentifier",
                "regionCode",
                "regionName",
                "observationTime",
                "stationName",
                "weather",
                "weatherCode",
                "condition",
                "isNight",
                "nextDayNightTransitionTime",
                "calibratedTimeOffsetMilliseconds",
                "temperature",
                "humidity",
                "rain",
            ])
        )
    }

    func testSavedLocationCachesAreIndependent() throws {
        let region407 = makeSnapshot(
            sourceIdentifier: "region:407",
            regionCode: "407",
            regionName: "西屯區"
        )
        let region100 = makeSnapshot(
            sourceIdentifier: "region:100",
            regionCode: "100",
            regionName: "中正區"
        )

        try writer.write(region407)
        let region407Bytes = try Data(
            contentsOf: snapshotURL(
                for: .saved(regionCode: "407")
            )
        )
        try writer.write(region100)

        XCTAssertEqual(
            try Data(
                contentsOf: snapshotURL(
                    for: .saved(regionCode: "407")
                )
            ),
            region407Bytes
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: snapshotURL(
                    for: .saved(regionCode: "100")
                ).path
            )
        )
    }

    func testCurrentLocationCacheIsIndependentFromSavedCache()
        throws
    {
        let saved = makeSnapshot(
            sourceIdentifier: "region:407",
            regionCode: "407"
        )
        let current = makeSnapshot(
            sourceIdentifier: "current-location",
            regionCode: "407"
        )

        try writer.write(saved)
        let savedBytes = try Data(
            contentsOf: snapshotURL(
                for: .saved(regionCode: "407")
            )
        )
        try writer.write(current)

        XCTAssertEqual(
            try Data(
                contentsOf: snapshotURL(
                    for: .saved(regionCode: "407")
                )
            ),
            savedBytes
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: snapshotURL(for: .currentLocation).path
            )
        )
    }

    func testEncodingFailurePreservesExistingCacheBytes()
        throws
    {
        let address = CurrentWeatherSnapshotAddress.saved(
            regionCode: "407"
        )
        let valid = makeSnapshot(
            sourceIdentifier: "region:407",
            regionCode: "407"
        )

        try writer.write(valid)
        let originalBytes = try Data(
            contentsOf: snapshotURL(for: address)
        )

        let legacy = makeSnapshot(
            schemaVersion: 4,
            sourceIdentifier: "region:407",
            regionCode: "407"
        )

        XCTAssertThrowsError(try writer.write(legacy))
        XCTAssertEqual(
            try Data(contentsOf: snapshotURL(for: address)),
            originalBytes
        )
    }

    private var writer: CurrentWeatherWidgetSnapshotWriter {
        CurrentWeatherWidgetSnapshotWriter(
            containerURL: containerURL
        )
    }

    private func snapshotURL(
        for address: CurrentWeatherSnapshotAddress
    ) -> URL {
        CurrentWeatherSnapshotStorage(
            containerURL: containerURL
        ).snapshotURL(for: address)
    }

    private func makeSnapshot(
        schemaVersion: Int = 5,
        sourceIdentifier: String,
        regionCode: String,
        regionName: String = "西屯區"
    ) -> CurrentWeatherWidgetSnapshot {
        CurrentWeatherWidgetSnapshot(
            schemaVersion: schemaVersion,
            sourceIdentifier: sourceIdentifier,
            regionCode: regionCode,
            regionName: regionName,
            observationTime: 1_789_567_200,
            stationName: "西屯",
            weather: "雷雨",
            weatherCode: 214,
            condition: .thunderstorm,
            isNight: true,
            nextDayNightTransitionTime: 1_789_562_700,
            calibratedTimeOffsetMilliseconds: -300_000,
            temperature: 27.5,
            humidity: 83,
            rain: 12.5
        )
    }
}
