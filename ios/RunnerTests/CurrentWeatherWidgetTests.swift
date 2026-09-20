import Foundation
import XCTest

final class CurrentWeatherRemoteDTOTests: XCTestCase {
    func testDecodesValidClearResponse() throws {
        let weather = try decode(
            """
            {
              "id": "C0X16",
              "station": {
                "name": "仁德",
                "lat": 22.9683,
                "lon": 120.2577,
                "altitude": 26,
                "distance": 0.81
              },
              "time": 1789567200,
              "data": {
                "weather": "晴",
                "weatherCode": 100,
                "temperature": 28.5,
                "humidity": 70,
                "rain": 0.0,
                "wind": { "speed": 1.5, "beaufort": 1 },
                "gust": { "speed": 3.0, "beaufort": 2 }
              }
            }
            """
        )

        XCTAssertEqual(weather.stationName, "仁德")
        XCTAssertEqual(weather.time, 1_789_567_200)
        XCTAssertEqual(weather.weather, "晴")
        XCTAssertEqual(weather.weatherCode, 100)
        XCTAssertEqual(weather.condition, .clear)
        XCTAssertEqual(weather.temperature, 28.5)
        XCTAssertEqual(weather.humidity, 70)
        XCTAssertEqual(weather.rain, 0)
    }

    func testDecodesValidRainResponse() throws {
        let weather = try decode(
            validJSON(
                weather: "有雨",
                weatherCode: 106
            )
        )

        XCTAssertEqual(weather.weather, "有雨")
        XCTAssertEqual(weather.weatherCode, 106)
        XCTAssertEqual(weather.condition, .rain)
    }

    func testMissingSentinelsDecodeAsNil() throws {
        let weather = try decode(
            validJSON(
                temperature: "-99",
                humidity: "-99",
                rain: "-99"
            )
        )

        XCTAssertNil(weather.temperature)
        XCTAssertNil(weather.humidity)
        XCTAssertNil(weather.rain)
    }

    func testMissingOptionalKeysDecodeAsNil() throws {
        let weather = try decode(
            """
            {
              "station": { "name": "仁德" },
              "time": 1789567200,
              "data": {
                "weather": "晴",
                "weatherCode": 100
              }
            }
            """
        )

        XCTAssertNil(weather.temperature)
        XCTAssertNil(weather.humidity)
        XCTAssertNil(weather.rain)
    }

    func testExplicitNullOptionalValuesDecodeAsNil() throws {
        let weather = try decode(
            validJSON(
                temperature: "null",
                humidity: "null",
                rain: "null"
            )
        )

        XCTAssertNil(weather.temperature)
        XCTAssertNil(weather.humidity)
        XCTAssertNil(weather.rain)
    }

    func testIntegerJSONValuesDecodeAsDouble() throws {
        let weather = try decode(
            validJSON(
                temperature: "28",
                rain: "1"
            )
        )

        XCTAssertEqual(weather.temperature, 28.0)
        XCTAssertEqual(weather.rain, 1.0)
    }

    func testIntegralFloatingPointJSONValueDecodesAsInt() throws {
        let weather = try decode(
            validJSON(humidity: "70.0")
        )

        XCTAssertEqual(weather.humidity, 70)
    }

    func testRejectsFractionalJSONValueForInt() {
        XCTAssertThrowsError(
            try decode(validJSON(humidity: "70.5"))
        )
    }

    func testRejectsBooleanForNumericField() {
        XCTAssertThrowsError(
            try decode(validJSON(temperature: "true"))
        )
    }

    func testRejectsOversizedInt() {
        XCTAssertThrowsError(
            try decode(
                validJSON(time: "9223372036854775808")
            )
        )
    }

    func testNegativeTimestampPreservesCurrentDecodingBehavior() throws {
        let weather = try decode(validJSON(time: "-1"))

        XCTAssertEqual(weather.time, -1)
    }

    func testRejectsMissingStationName() {
        XCTAssertThrowsError(
            try decode(
                validJSON(station: "{}")
            )
        )
    }

    func testRejectsMissingTime() {
        XCTAssertThrowsError(
            try decode(
                """
                {
                  "station": { "name": "仁德" },
                  "data": {
                    "weather": "晴",
                    "weatherCode": 100
                  }
                }
                """
            )
        )
    }

    func testRejectsMissingWeather() {
        XCTAssertThrowsError(
            try decode(
                validJSON(weather: nil)
            )
        )
    }

    func testRejectsMissingWeatherCode() {
        XCTAssertThrowsError(
            try decode(
                validJSON(weatherCode: nil)
            )
        )
    }

    func testRejectsMalformedDataStructure() {
        XCTAssertThrowsError(
            try decode(
                """
                {
                  "station": { "name": "仁德" },
                  "time": 1789567200,
                  "data": []
                }
                """
            )
        )
    }

    func testRejectsMalformedRequiredFieldType() {
        XCTAssertThrowsError(
            try decode(
                """
                {
                  "station": { "name": "仁德" },
                  "time": "1789567200",
                  "data": {
                    "weather": "晴",
                    "weatherCode": 100
                  }
                }
                """
            )
        )
    }

    func testMatchesDartWeatherCodeSemantics() {
        let cases: [(Int, CurrentWeatherWidgetCondition)] = [
            (100, .clear),
            (200, .cloudy),
            (300, .overcast),
            (101, .fog),
            (102, .fog),
            (105, .fog),
            (103, .thunderstorm),
            (104, .thunderstorm),
            (114, .thunderstorm),
            (115, .thunderstorm),
            (116, .thunderstorm),
            (117, .thunderstorm),
            (118, .thunderstorm),
            (119, .thunderstorm),
            (106, .rain),
            (107, .rain),
            (111, .rain),
            (113, .rain),
            (108, .snow),
            (109, .snow),
            (110, .snow),
            (112, .snow),
        ]

        for (code, condition) in cases {
            XCTAssertEqual(
                currentWeatherWidgetCondition(for: code),
                condition,
                "weather code \(code)"
            )
        }
    }

    func testPhenomenonTakesPrecedenceOverSkyState() {
        let cases: [(Int, CurrentWeatherWidgetCondition)] = [
            (106, .rain),
            (214, .thunderstorm),
            (305, .fog),
        ]

        for (code, condition) in cases {
            XCTAssertEqual(
                currentWeatherWidgetCondition(for: code),
                condition,
                "weather code \(code)"
            )
        }
    }

    func testUnknownWeatherCodesReturnUnknown() {
        for code in [0, -1, 420] {
            XCTAssertEqual(
                currentWeatherWidgetCondition(for: code),
                .unknown,
                "weather code \(code)"
            )
        }
    }

    private func decode(_ json: String) throws -> CurrentWeatherRemoteDTO {
        try JSONDecoder().decode(
            CurrentWeatherRemoteDTO.self,
            from: Data(json.utf8)
        )
    }

    private func validJSON(
        station: String = #"{ "name": "仁德" }"#,
        time: String = "1789567200",
        weather: String? = "晴",
        weatherCode: Int? = 100,
        temperature: String = "28.5",
        humidity: String = "70",
        rain: String = "0.0"
    ) -> String {
        let weatherField = weather.map { #""weather": "\#($0)","# } ?? ""
        let weatherCodeField = weatherCode.map {
            #""weatherCode": \#($0),"#
        } ?? ""

        return """
        {
          "station": \(station),
          "time": \(time),
          "data": {
            \(weatherField)
            \(weatherCodeField)
            "temperature": \(temperature),
            "humidity": \(humidity),
            "rain": \(rain)
          }
        }
        """
    }
}

final class CurrentWeatherWidgetSnapshotTests: XCTestCase {
    func testDecodesSchemaVersionFiveSnapshot() throws {
        let snapshot = try decode(
            """
            {
              "schemaVersion": 5,
              "sourceIdentifier": "region:220",
              "regionCode": "220",
              "regionName": "板橋區",
              "observationTime": 1789567200,
              "stationName": "板橋",
              "weather": "晴",
              "weatherCode": 100,
              "condition": "clear",
              "isNight": false,
              "nextDayNightTransitionTime": 1789562700,
              "calibratedTimeOffsetMilliseconds": 0,
              "temperature": 28.5,
              "humidity": 70,
              "rain": 0.0
            }
            """
        )

        XCTAssertEqual(snapshot.schemaVersion, 5)
        XCTAssertEqual(snapshot.sourceIdentifier, "region:220")
        XCTAssertEqual(snapshot.regionCode, "220")
    }

    func testSchemaVersionFiveRequiresSourceIdentifier() {
        XCTAssertThrowsError(
            try decode(
                """
                {
                  "schemaVersion": 5,
                  "regionCode": "220",
                  "regionName": "板橋區",
                  "observationTime": 1789567200,
                  "stationName": "板橋",
                  "weather": "晴",
                  "weatherCode": 100,
                  "condition": "clear",
                  "isNight": false,
                  "nextDayNightTransitionTime": 1789562700,
                  "calibratedTimeOffsetMilliseconds": 0,
                  "temperature": null,
                  "humidity": null,
                  "rain": null
                }
                """
            )
        )
    }

    func testRejectsUnsupportedSchemaVersion() {
        XCTAssertThrowsError(
            try decode(
                """
                {
                  "schemaVersion": 6,
                  "sourceIdentifier": "region:220",
                  "regionCode": "220",
                  "regionName": "板橋區",
                  "observationTime": 1789567200,
                  "stationName": "板橋",
                  "weather": "晴",
                  "weatherCode": 100,
                  "condition": "clear",
                  "isNight": false,
                  "nextDayNightTransitionTime": 1789562700,
                  "calibratedTimeOffsetMilliseconds": 0,
                  "temperature": null,
                  "humidity": null,
                  "rain": null
                }
                """
            )
        )
    }

    func testDecodesSchemaVersionFourSnapshot() throws {
        let snapshot = try decode(
            """
            {
              "schemaVersion": 4,
              "regionCode": "660",
              "regionName": "西屯區",
              "observationTime": 1789567200,
              "stationName": "西屯",
              "weather": "晴",
              "weatherCode": 100,
              "condition": "clear",
              "isNight": true,
              "nextDayNightTransitionTime": 1789562700,
              "calibratedTimeOffsetMilliseconds": -300000,
              "temperature": 28.5,
              "humidity": null,
              "rain": 0.0
            }
            """
        )

        XCTAssertEqual(snapshot.schemaVersion, 4)
        XCTAssertNil(snapshot.sourceIdentifier)
        XCTAssertEqual(snapshot.regionCode, "660")
        XCTAssertEqual(snapshot.regionName, "西屯區")
        XCTAssertEqual(snapshot.observationTime, 1_789_567_200)
        XCTAssertEqual(snapshot.stationName, "西屯")
        XCTAssertEqual(snapshot.weather, "晴")
        XCTAssertEqual(snapshot.weatherCode, 100)
        XCTAssertEqual(snapshot.condition, .clear)
        XCTAssertTrue(snapshot.isNight)
        XCTAssertEqual(snapshot.nextDayNightTransitionTime, 1_789_562_700)
        XCTAssertEqual(snapshot.calibratedTimeOffsetMilliseconds, -300_000)
        XCTAssertEqual(snapshot.temperature, 28.5)
        XCTAssertNil(snapshot.humidity)
        XCTAssertEqual(snapshot.rain, 0)
    }

    func testDecodesSchemaVersionThreeSnapshotWithZeroCalibration() throws {
        let snapshot = try decode(
            """
            {
              "schemaVersion": 3,
              "regionCode": "660",
              "regionName": "西屯區",
              "observationTime": 1789567200,
              "stationName": "西屯",
              "weather": "晴",
              "weatherCode": 100,
              "condition": "clear",
              "isNight": true,
              "nextDayNightTransitionTime": 1789562700,
              "temperature": null,
              "humidity": null,
              "rain": null
            }
            """
        )

        XCTAssertTrue(snapshot.isNight)
        XCTAssertEqual(snapshot.nextDayNightTransitionTime, 1_789_562_700)
        XCTAssertEqual(snapshot.calibratedTimeOffsetMilliseconds, 0)
        XCTAssertNil(snapshot.temperature)
        XCTAssertNil(snapshot.humidity)
        XCTAssertNil(snapshot.rain)
    }

    func testDecodesSchemaVersionTwoSnapshotWithLegacyDefaults() throws {
        let snapshot = try decode(
            """
            {
              "schemaVersion": 2,
              "regionCode": "660",
              "regionName": "西屯區",
              "observationTime": 1789567200,
              "stationName": "西屯",
              "weather": "晴",
              "weatherCode": 100,
              "condition": "clear",
              "temperature": null,
              "humidity": null,
              "rain": null
            }
            """
        )

        XCTAssertFalse(snapshot.isNight)
        XCTAssertEqual(snapshot.nextDayNightTransitionTime, 0)
        XCTAssertEqual(snapshot.calibratedTimeOffsetMilliseconds, 0)
    }

    func testSchemaVersionFourRequiresCalibration() {
        XCTAssertThrowsError(
            try decode(
                """
                {
                  "schemaVersion": 4,
                  "regionCode": "660",
                  "regionName": "西屯區",
                  "observationTime": 1789567200,
                  "stationName": "西屯",
                  "weather": "晴",
                  "weatherCode": 100,
                  "condition": "clear",
                  "isNight": false,
                  "nextDayNightTransitionTime": 1789562700,
                  "temperature": null,
                  "humidity": null,
                  "rain": null
                }
                """
            )
        )
    }

    func testUnknownConditionDecodesAsUnknown() throws {
        let snapshot = try decode(
            """
            {
              "schemaVersion": 3,
              "regionCode": "660",
              "regionName": "西屯區",
              "observationTime": 1789567200,
              "stationName": "西屯",
              "weather": "未知",
              "weatherCode": 999,
              "condition": "future-condition",
              "isNight": false,
              "nextDayNightTransitionTime": 0,
              "temperature": null,
              "humidity": null,
              "rain": null
            }
            """
        )

        XCTAssertEqual(snapshot.condition, .unknown)
    }

    private func decode(_ json: String) throws -> CurrentWeatherWidgetSnapshot {
        try JSONDecoder().decode(
            CurrentWeatherWidgetSnapshot.self,
            from: Data(json.utf8)
        )
    }
}

final class CurrentWeatherWidgetConditionTests: XCTestCase {
    func testEveryConditionHasItsOwnLocalizationKey() {
        let expected: [(CurrentWeatherWidgetCondition, String)] = [
            (.clear, "weather.clear"),
            (.cloudy, "weather.cloudy"),
            (.overcast, "weather.overcast"),
            (.rain, "weather.rain"),
            (.thunderstorm, "weather.thunderstorm"),
            (.snow, "weather.snow"),
            (.fog, "weather.fog"),
            (.unknown, "weather.unknown"),
        ]

        for (condition, key) in expected {
            XCTAssertEqual(condition.displayNameLocalizationKey, key)
        }
    }

    func testClearAndCloudyUseDayNightSymbols() {
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.clear.systemImageName(isNight: false),
            "sun.max.fill"
        )
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.clear.systemImageName(isNight: true),
            "moon.stars.fill"
        )
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.cloudy.systemImageName(isNight: false),
            "cloud.sun.fill"
        )
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.cloudy.systemImageName(isNight: true),
            "cloud.moon.fill"
        )
    }

    func testRainSymbolDoesNotDependOnDayNight() {
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.rain.systemImageName(isNight: false),
            "cloud.rain.fill"
        )
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.rain.systemImageName(isNight: true),
            "cloud.rain.fill"
        )
    }
}

final class CurrentWeatherWidgetTimelineTests: XCTestCase {
    private let staleAfter: TimeInterval = 30 * 60

    func testDayToNightBeforeStale() {
        let now = date(10_000)
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 11_200
            ),
            deviceNow: now,
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 10_000, isStale: false, isNight: false),
                state(at: 11_200, isStale: false, isNight: true),
                state(at: 11_800, isStale: true, isNight: true),
            ]
        )
    }

    func testDeviceClockAheadUsesNegativeOffsetForScheduling() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 11_200,
                offsetMilliseconds: -300_000
            ),
            deviceNow: date(10_300),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 10_300, isStale: false, isNight: false),
                state(at: 11_500, isStale: false, isNight: true),
                state(at: 12_100, isStale: true, isNight: true),
            ]
        )
    }

    func testDeviceClockBehindUsesPositiveOffsetForScheduling() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 11_200,
                offsetMilliseconds: 300_000
            ),
            deviceNow: date(9_700),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 9_700, isStale: false, isNight: false),
                state(at: 10_900, isStale: false, isNight: true),
                state(at: 11_500, isStale: true, isNight: true),
            ]
        )
    }

    func testStaleBoundaryUsesCalibratedTime() {
        let state = CurrentWeatherWidgetTimeline.state(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 0,
                offsetMilliseconds: -300_000
            ),
            at: date(12_100),
            staleAfter: staleAfter
        )

        XCTAssertTrue(state.isStale)
    }

    func testStaleBeforeDayToNightTransition() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 8_800,
                isNight: false,
                transitionTime: 11_200
            ),
            deviceNow: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 10_000, isStale: false, isNight: false),
                state(at: 10_600, isStale: true, isNight: false),
                state(at: 11_200, isStale: true, isNight: true),
            ]
        )
    }

    func testNightToDayTransition() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: true,
                transitionTime: 11_200
            ),
            deviceNow: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertTrue(states[0].isNight)
        XCTAssertFalse(states[1].isNight)
        XCTAssertFalse(states[2].isNight)
    }

    func testEqualStaleAndTransitionDatesAreDeduplicatedAndCombined() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 11_800
            ),
            deviceNow: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 10_000, isStale: false, isNight: false),
                state(at: 11_800, isStale: true, isNight: true),
            ]
        )
    }

    func testPastTransitionAffectsNowWithoutSchedulingPastDate() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 9_999
            ),
            deviceNow: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(states.map(\.date), [date(10_000), date(11_800)])
        XCTAssertTrue(states[0].isNight)
        XCTAssertFalse(states[0].isStale)
    }

    func testAlreadyStaleSnapshotIsStaleAtNow() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 8_000,
                isNight: false,
                transitionTime: 0
            ),
            deviceNow: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [state(at: 10_000, isStale: true, isNight: false)]
        )
    }

    func testZeroTransitionUsesSnapshotStateWithoutSolarEntry() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: true,
                transitionTime: 0
            ),
            deviceNow: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 10_000, isStale: false, isNight: true),
                state(at: 11_800, isStale: true, isNight: true),
            ]
        )
    }

    func testNoSnapshotProducesOneEmptyState() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: nil,
            deviceNow: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [state(at: 10_000, isStale: false, isNight: false)]
        )
    }

    func testSnapshotStateAfterTransitionUsesDateAwareNightValue() {
        let state = CurrentWeatherWidgetTimeline.state(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 11_200
            ),
            at: date(11_201),
            staleAfter: staleAfter
        )

        XCTAssertTrue(state.isNight)
        XCTAssertFalse(state.isStale)
    }

    private func snapshot(
        observationTime: Int,
        isNight: Bool,
        transitionTime: Int,
        offsetMilliseconds: Int = 0
    ) -> CurrentWeatherWidgetSnapshot {
        CurrentWeatherWidgetSnapshot(
            schemaVersion: 4,
            regionCode: "660",
            regionName: "西屯區",
            observationTime: observationTime,
            stationName: "西屯",
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: isNight,
            nextDayNightTransitionTime: transitionTime,
            calibratedTimeOffsetMilliseconds: offsetMilliseconds,
            temperature: 28,
            humidity: 76,
            rain: 0
        )
    }

    private func state(
        at timestamp: TimeInterval,
        isStale: Bool,
        isNight: Bool
    ) -> CurrentWeatherWidgetTimelineState {
        CurrentWeatherWidgetTimelineState(
            date: date(timestamp),
            isStale: isStale,
            isNight: isNight
        )
    }

    private func date(_ timestamp: TimeInterval) -> Date {
        Date(timeIntervalSince1970: timestamp)
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (URLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.badServerResponse)
            )
            return
        }

        do {
            let (response, data) = try handler(request)

            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )

            client?.urlProtocol(
                self,
                didLoad: data
            )

            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(
                self,
                didFailWithError: error
            )
        }
    }

    override func stopLoading() {}
}

final class CurrentWeatherClientTests: XCTestCase {
    private var session: URLSession!
    private var client: CurrentWeatherClient!

    override func setUp() {
        super.setUp()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]

        session = URLSession(configuration: configuration)
        client = CurrentWeatherClient(session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        session.invalidateAndCancel()

        client = nil
        session = nil

        super.tearDown()
    }

    func testMakeURLBuildsRealtimeEndpoint() throws {
        let url = try client.makeURL(
            latitude: 24.1658,
            longitude: 120.6336
        )

        let components = try XCTUnwrap(
            URLComponents(url: url, resolvingAgainstBaseURL: false)
        )

        XCTAssertEqual(
            url.absoluteString,
            "https://api.core-tnn1.exptech.dev/api/v5/meteor/weather/realtime/24.1658,120.6336"
        )
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "api.core-tnn1.exptech.dev")
        XCTAssertEqual(
            components.path,
            "/api/v5/meteor/weather/realtime/24.1658,120.6336"
        )
        XCTAssertNil(components.query)
    }

    func testMakeURLPreservesNegativeCoordinatesAndOrdering() throws {
        let url = try client.makeURL(
            latitude: -24.1658,
            longitude: -120.6336
        )

        XCTAssertEqual(
            url.absoluteString,
            "https://api.core-tnn1.exptech.dev/api/v5/meteor/weather/realtime/-24.1658,-120.6336"
        )
    }

    func testMakeURLAcceptsCoordinateBoundaries() throws {
        XCTAssertEqual(
            try client.makeURL(
                latitude: 90,
                longitude: 180
            ).absoluteString,
            "https://api.core-tnn1.exptech.dev/api/v5/meteor/weather/realtime/90.0,180.0"
        )

        XCTAssertEqual(
            try client.makeURL(
                latitude: -90,
                longitude: -180
            ).absoluteString,
            "https://api.core-tnn1.exptech.dev/api/v5/meteor/weather/realtime/-90.0,-180.0"
        )
    }

    func testMakeURLRejectsInvalidLatitude() {
        XCTAssertThrowsError(
            try client.makeURL(latitude: 90.1, longitude: 120)
        ) { error in
            XCTAssertEqual(
                error as? CurrentWeatherClientError,
                .invalidCoordinate
            )
        }

        XCTAssertThrowsError(
            try client.makeURL(latitude: -90.1, longitude: 120)
        ) { error in
            XCTAssertEqual(
                error as? CurrentWeatherClientError,
                .invalidCoordinate
            )
        }
    }

    func testMakeURLRejectsInvalidLongitude() {
        XCTAssertThrowsError(
            try client.makeURL(latitude: 24, longitude: 180.1)
        ) { error in
            XCTAssertEqual(
                error as? CurrentWeatherClientError,
                .invalidCoordinate
            )
        }

        XCTAssertThrowsError(
            try client.makeURL(latitude: 24, longitude: -180.1)
        ) { error in
            XCTAssertEqual(
                error as? CurrentWeatherClientError,
                .invalidCoordinate
            )
        }
    }

    func testMakeURLRejectsNonFiniteCoordinates() {
        let invalidCoordinates: [(Double, Double)] = [
            (.nan, 120),
            (.infinity, 120),
            (-.infinity, 120),
            (24, .nan),
            (24, .infinity),
            (24, -.infinity),
        ]

        for (latitude, longitude) in invalidCoordinates {
            XCTAssertThrowsError(
                try client.makeURL(
                    latitude: latitude,
                    longitude: longitude
                )
            ) { error in
                XCTAssertEqual(
                    error as? CurrentWeatherClientError,
                    .invalidCoordinate
                )
            }
        }
    }

    func testFetchReturnsDecodedWeather() async throws {
        let json = """
        {
          "id": "C0F9T",
          "station": {
            "name": "西屯"
          },
          "time": 1789877400,
          "data": {
            "weather": "晴",
            "weatherCode": 100,
            "temperature": 30.6,
            "humidity": 66,
            "rain": 0
          }
        }
        """

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.timeoutInterval, 6)
            XCTAssertEqual(
                request.url?.absoluteString,
                "https://api.core-tnn1.exptech.dev/api/v5/meteor/weather/realtime/24.1658,120.6336"
            )

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )

            return (
                response,
                Data(json.utf8)
            )
        }

        let result = try await client.fetch(
            latitude: 24.1658,
            longitude: 120.6336
        )

        let weather = try XCTUnwrap(result)

        XCTAssertEqual(weather.stationName, "西屯")
        XCTAssertEqual(weather.time, 1789877400)
        XCTAssertEqual(weather.weather, "晴")
        XCTAssertEqual(weather.weatherCode, 100)
        XCTAssertEqual(weather.temperature, 30.6)
        XCTAssertEqual(weather.humidity, 66)
        XCTAssertEqual(weather.rain, 0)
    }

    func testFetchReturnsNilForStructurallyEmptyObjects() async throws {
        for body in ["{}", "  { \n } \n"] {
            setHTTPResponse(data: Data(body.utf8))

            let result = try await fetch()

            XCTAssertNil(result, body)
        }
    }

    func testFetchRejectsMalformedOrWrongShapeResponses() async {
        let cases = [
            ("malformed JSON", #"{"station":"#),
            ("top-level array", "[]"),
            ("missing realtime structure", #"{"message":"ok"}"#),
            (
                "invalid required field type",
                """
                {
                  "station": { "name": "西屯" },
                  "time": "1789877400",
                  "data": {
                    "weather": "晴",
                    "weatherCode": 100
                  }
                }
                """
            ),
        ]

        for (name, body) in cases {
            setHTTPResponse(data: Data(body.utf8))

            do {
                _ = try await fetch()
                XCTFail("Expected decoding failure for \(name)")
            } catch {
                XCTAssertFalse(
                    error is CurrentWeatherClientError,
                    "\(name): \(error)"
                )
            }
        }
    }

    func testFetchRejectsHTTPFailures() async {
        for statusCode in [404, 500] {
            setHTTPResponse(
                statusCode: statusCode,
                data: Data("{}".utf8)
            )

            await assertFetchThrows(
                .httpStatus(statusCode),
                context: "HTTP \(statusCode)"
            )
        }
    }

    func testFetchAcceptsOnlyHTTP200() async {
        setHTTPResponse(statusCode: 204, data: Data())

        await assertFetchThrows(.httpStatus(204))
    }

    func testFetchRejectsOversizedResponse() async {
        setHTTPResponse(
            data: Data(repeating: 0x20, count: 128 * 1024 + 1)
        )

        await assertFetchThrows(.responseTooLarge)
    }

    func testFetchPropagatesTransportFailure() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            _ = try await fetch()
            XCTFail("Expected transport failure")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .timedOut)
            XCTAssertFalse(error is CurrentWeatherClientError)
        }
    }

    func testFetchRejectsNonHTTPResponse() async {
        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = URLResponse(
                url: url,
                mimeType: "application/json",
                expectedContentLength: 2,
                textEncodingName: "utf-8"
            )

            return (response, Data("{}".utf8))
        }

        await assertFetchThrows(.invalidResponse)
    }

    private func fetch() async throws -> CurrentWeatherRemoteDTO? {
        try await client.fetch(
            latitude: 24.1658,
            longitude: 120.6336
        )
    }

    private func setHTTPResponse(
        statusCode: Int = 200,
        data: Data
    ) {
        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: nil
                )
            )

            return (response, data)
        }
    }

    private func assertFetchThrows(
        _ expectedError: CurrentWeatherClientError,
        context: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await fetch()
            XCTFail(
                "Expected \(expectedError) \(context)",
                file: file,
                line: line
            )
        } catch {
            XCTAssertEqual(
                error as? CurrentWeatherClientError,
                expectedError,
                context,
                file: file,
                line: line
            )
        }
    }
}
