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

        try storage.replace(Data("snapshot".utf8), for: address)

        var isDirectory: ObjCBool = false
        let directoryExists = FileManager.default.fileExists(
            atPath: storage.snapshotURL(for: address)
                .deletingLastPathComponent().path,
            isDirectory: &isDirectory
        )

        XCTAssertTrue(directoryExists)
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testReplaceWritesExpectedBytes() throws {
        let data = Data([0x00, 0x7F, 0x80, 0xFF])
        let address = CurrentWeatherSnapshotAddress.saved(
            regionCode: "407"
        )

        try storage.replace(data, for: address)

        XCTAssertEqual(
            try Data(contentsOf: storage.snapshotURL(for: address)),
            data
        )
    }

    private var storage: CurrentWeatherSnapshotStorage {
        CurrentWeatherSnapshotStorage(containerURL: containerURL)
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
