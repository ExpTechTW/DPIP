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
                "wind": {
                  "direction": "南南西",
                  "speed": 1.5,
                  "beaufort": 1
                },
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
        XCTAssertEqual(weather.windDirection, "南南西")
        XCTAssertEqual(weather.windSpeed, 1.5)
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
                rain: "-99",
                wind: #"{ "direction": "北", "speed": -99 }"#
            )
        )

        XCTAssertNil(weather.temperature)
        XCTAssertNil(weather.humidity)
        XCTAssertNil(weather.rain)
        XCTAssertEqual(weather.windDirection, "北")
        XCTAssertNil(weather.windSpeed)
    }

    func testMissingOptionalKeysDecodeAsNil() throws {
        let weather = try decode(
            """
            {
              "station": { "name": "仁德" },
              "time": 1789567200,
              "data": {
                "weather": "晴",
                "weatherCode": 100,
                "wind": {}
              }
            }
            """
        )

        XCTAssertNil(weather.temperature)
        XCTAssertNil(weather.humidity)
        XCTAssertNil(weather.rain)
        XCTAssertNil(weather.windDirection)
        XCTAssertNil(weather.windSpeed)
    }

    func testExplicitNullOptionalValuesDecodeAsNil() throws {
        let weather = try decode(
            validJSON(
                temperature: "null",
                humidity: "null",
                rain: "null",
                wind: #"{ "direction": null, "speed": null }"#
            )
        )

        XCTAssertNil(weather.temperature)
        XCTAssertNil(weather.humidity)
        XCTAssertNil(weather.rain)
        XCTAssertNil(weather.windDirection)
        XCTAssertNil(weather.windSpeed)
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
        rain: String = "0.0",
        wind: String = #"{ "direction": "東", "speed": 2.5 }"#
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
            "rain": \(rain),
            "wind": \(wind)
          }
        }
        """
    }
}

final class CurrentApparentTemperatureTests: XCTestCase {
    func testMatchesFixedCWAFormulaParityVectors() {
        // Project goldens from the published formula, shared with Dart tests.
        let vectors: [(Double, Int, Double, Double)] = [
            (30, 80, 2, 33.9659458296072),
            (12, 65, 1.2, 10.820012239693988),
            (25, 60, 0, 27.089955502470914),
            (25, 60, 8, 21.889955502470915),
            (32, 10, 2, 30.227599518688184),
            (32, 95, 2, 38.28219542753772),
            (-5, 70, 3, -9.26026582286526),
            (20, 0, 1, 17.450000000000003),
            (20, 100, 1, 22.114536136797756),
        ]

        for (temperature, humidity, windSpeed, expected) in vectors {
            let actual = currentApparentTemperature(
                temperature: temperature,
                humidity: humidity,
                windSpeed: windSpeed
            )
            XCTAssertEqual(actual ?? .nan, expected, accuracy: 1e-9)
        }
    }

    func testRejectsMissingAndInvalidInputs() {
        XCTAssertNil(currentApparentTemperature(temperature: nil, humidity: 60, windSpeed: 1))
        XCTAssertNil(currentApparentTemperature(temperature: 25, humidity: nil, windSpeed: 1))
        XCTAssertNil(currentApparentTemperature(temperature: 25, humidity: 60, windSpeed: nil))
        for humidity in [-1, 101] {
            XCTAssertNil(currentApparentTemperature(temperature: 25, humidity: humidity, windSpeed: 1))
        }
        XCTAssertNil(currentApparentTemperature(temperature: 25, humidity: 60, windSpeed: -0.1))
        for nonFinite in [Double.nan, .infinity, -.infinity] {
            XCTAssertNil(currentApparentTemperature(temperature: nonFinite, humidity: 60, windSpeed: 1))
            XCTAssertNil(currentApparentTemperature(temperature: 25, humidity: 60, windSpeed: nonFinite))
        }
        XCTAssertNil(currentApparentTemperature(temperature: -237.700000001, humidity: 100, windSpeed: 1))
    }
}

final class CurrentWeatherWidgetSnapshotTests: XCTestCase {
    func testDecodesSchemaVersionSevenSnapshot() throws {
        let encoded = try JSONEncoder().encode(makeSnapshot())
        let snapshot = try JSONDecoder().decode(CurrentWeatherWidgetSnapshot.self, from: encoded)
        XCTAssertEqual(snapshot.schemaVersion, 7)
        XCTAssertEqual(snapshot.apparentTemperature, 31.39512521394631)
    }
    func testDecodesSchemaVersionSixSnapshot() throws {
        let snapshot = try decode(
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
              "temperature": 28.5,
              "humidity": 70,
              "rain": 0.0,
              "windDirection": "南南西",
              "windSpeed": 1.5
            }
            """
        )

        XCTAssertEqual(snapshot.schemaVersion, 6)
        XCTAssertEqual(snapshot.windDirection, "南南西")
        XCTAssertEqual(snapshot.windSpeed, 1.5)
        XCTAssertNil(snapshot.apparentTemperature)
    }

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
        XCTAssertNil(snapshot.windDirection)
        XCTAssertNil(snapshot.windSpeed)
        XCTAssertNil(snapshot.apparentTemperature)
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
                  "schemaVersion": 8,
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
        XCTAssertNil(snapshot.apparentTemperature)
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
        XCTAssertNil(snapshot.apparentTemperature)
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
        XCTAssertNil(snapshot.apparentTemperature)
    }

    func testDecodesSchemaVersionOneWithNilApparentTemperature() throws {
        let snapshot = try decode(
            """
            {
              "schemaVersion": 1,
              "regionCode": "660",
              "regionName": "西屯區",
              "observationTime": 1789567200,
              "stationName": "西屯",
              "weather": "晴",
              "weatherCode": 100
            }
            """
        )
        XCTAssertNil(snapshot.apparentTemperature)
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

    private func makeSnapshot(
        schemaVersion: Int = 7,
        sourceIdentifier: String? = "region:100",
        regionCode: String = "100",
        condition: CurrentWeatherWidgetCondition = .clear,
        temperature: Double? = 28.5,
        humidity: Int? = 70,
        rain: Double? = 0,
        windDirection: String? = "南南西",
        windSpeed: Double? = 1.5,
        apparentTemperature: Double? = 31.39512521394631
    ) -> CurrentWeatherWidgetSnapshot {
        CurrentWeatherWidgetSnapshot(
            schemaVersion: schemaVersion,
            sourceIdentifier: sourceIdentifier,
            regionCode: regionCode,
            regionName: "中正區",
            observationTime: 1_710_900_000,
            stationName: "臺北",
            weather: "晴",
            weatherCode: 100,
            condition: condition,
            isNight: false,
            nextDayNightTransitionTime: 1_710_929_103,
            calibratedTimeOffsetMilliseconds: -5_000,
            temperature: temperature,
            humidity: humidity,
            rain: rain,
            windDirection: windDirection,
            windSpeed: windSpeed,
            apparentTemperature: apparentTemperature
        )
    }

    func testEncodesSchemaVersionSevenWithAllFields() throws {
        let snapshot = CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: "region:100",
            regionCode: "100",
            regionName: "中正區",
            observationTime: 1_710_900_000,
            stationName: "臺北",
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: false,
            nextDayNightTransitionTime: 1_710_929_103,
            calibratedTimeOffsetMilliseconds: -5_000,
            temperature: 28.5,
            humidity: 70,
            rain: 0,
            windDirection: "南南西",
            windSpeed: 1.5,
            apparentTemperature: 31.39512521394631
        )

        let data = try JSONEncoder().encode(snapshot)

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: data
            ) as? [String: Any]
        )

        XCTAssertEqual(json.count, 18)

        XCTAssertEqual(json["schemaVersion"] as? Int, 7)
        XCTAssertEqual(
            json["sourceIdentifier"] as? String,
            "region:100"
        )
        XCTAssertEqual(
            json["regionCode"] as? String,
            "100"
        )
        XCTAssertEqual(
            json["regionName"] as? String,
            "中正區"
        )
        XCTAssertEqual(
            json["observationTime"] as? Int,
            1_710_900_000
        )
        XCTAssertEqual(
            json["stationName"] as? String,
            "臺北"
        )
        XCTAssertEqual(
            json["weather"] as? String,
            "晴"
        )
        XCTAssertEqual(
            json["weatherCode"] as? Int,
            100
        )
        XCTAssertEqual(
            json["condition"] as? String,
            "clear"
        )
        XCTAssertEqual(
            json["isNight"] as? Bool,
            false
        )
        XCTAssertEqual(
            json["nextDayNightTransitionTime"] as? Int,
            1_710_929_103
        )
        XCTAssertEqual(
            json["calibratedTimeOffsetMilliseconds"] as? Int,
            -5_000
        )
        XCTAssertEqual(
            json["temperature"] as? Double,
            28.5
        )
        XCTAssertEqual(
            json["humidity"] as? Int,
            70
        )
        XCTAssertEqual(
            json["rain"] as? Double,
            0
        )
        XCTAssertEqual(
            json["windDirection"] as? String,
            "南南西"
        )
        XCTAssertEqual(
            json["windSpeed"] as? Double,
            1.5
        )
        XCTAssertEqual(
            try XCTUnwrap(json["apparentTemperature"] as? Double),
            31.39512521394631,
            accuracy: 1e-9
        )
    }

    func testEncodingPreservesExplicitNullWeatherValues()
        throws
    {
        let snapshot = CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: "region:100",
            regionCode: "100",
            regionName: "中正區",
            observationTime: 1_710_900_000,
            stationName: "臺北",
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: false,
            nextDayNightTransitionTime: 1_710_929_103,
            calibratedTimeOffsetMilliseconds: 0,
            temperature: nil,
            humidity: nil,
            rain: nil,
            windDirection: nil,
            windSpeed: nil
        )

        let data = try JSONEncoder().encode(snapshot)

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: data
            ) as? [String: Any]
        )

        XCTAssertEqual(json.count, 18)

        XCTAssertTrue(json["temperature"] is NSNull)
        XCTAssertTrue(json["humidity"] is NSNull)
        XCTAssertTrue(json["rain"] is NSNull)
        XCTAssertTrue(json["windDirection"] is NSNull)
        XCTAssertTrue(json["windSpeed"] is NSNull)
        XCTAssertTrue(json["apparentTemperature"] is NSNull)
        let decoded = try JSONDecoder().decode(
            CurrentWeatherWidgetSnapshot.self,
            from: data
        )
        XCTAssertNil(decoded.apparentTemperature)
    }

    func testSchemaVersionFiveCannotBeEncoded() {
        let snapshot = makeSnapshot(schemaVersion: 5)

        XCTAssertThrowsError(
            try JSONEncoder().encode(snapshot)
        )
    }

    func testSchemaVersionSevenWithoutSourceIdentifierCannotBeEncoded() {
        let snapshot = makeSnapshot(sourceIdentifier: nil)

        XCTAssertThrowsError(
            try JSONEncoder().encode(snapshot)
        )
    }

    func testSchemaVersionSevenRejectsMalformedSourceIdentifiers() {
        let malformedSourceIdentifiers = [
            "",
            "region:",
            "region:10",
            "region:1000",
            "region:ABC",
            "region:１００",
            "something-else",
        ]

        for sourceIdentifier in malformedSourceIdentifiers {
            let snapshot = makeSnapshot(
                sourceIdentifier: sourceIdentifier
            )

            XCTAssertThrowsError(
                try JSONEncoder().encode(snapshot),
                sourceIdentifier
            )
        }
    }

    func testSavedSourceIdentifierMustMatchPayloadRegionCode() {
        let snapshot = makeSnapshot(
            sourceIdentifier: "region:100",
            regionCode: "407"
        )

        XCTAssertThrowsError(
            try JSONEncoder().encode(snapshot)
        )
    }

    func testCurrentLocationWithResolvedRegionCodeCanBeEncoded() {
        let snapshot = makeSnapshot(
            sourceIdentifier: "current-location",
            regionCode: "407"
        )

        XCTAssertNoThrow(
            try JSONEncoder().encode(snapshot)
        )
    }

    func testEncodedSchemaVersionSevenContainsExactlyContractKeys() throws {
        let data = try JSONEncoder().encode(makeSnapshot())
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
                "windDirection",
                "windSpeed",
                "apparentTemperature",
            ])
        )
    }

    func testConditionEncodesUsingRawSchemaValue() throws {
        let data = try JSONEncoder().encode(
            makeSnapshot(condition: .thunderstorm)
        )
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data)
                as? [String: Any]
        )

        XCTAssertEqual(
            json["condition"] as? String,
            "thunderstorm"
        )
    }

    func testSchemaVersionSevenRoundTripPreservesAllFields() throws {
        let original = CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: "region:407",
            regionCode: "407",
            regionName: "西屯區",
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
            rain: 12.5,
            windDirection: "北北東",
            windSpeed: 4.25,
            apparentTemperature: 30.123456789
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            CurrentWeatherWidgetSnapshot.self,
            from: encoded
        )

        XCTAssertEqual(decoded.schemaVersion, original.schemaVersion)
        XCTAssertEqual(decoded.sourceIdentifier, original.sourceIdentifier)
        XCTAssertEqual(decoded.regionCode, original.regionCode)
        XCTAssertEqual(decoded.regionName, original.regionName)
        XCTAssertEqual(decoded.observationTime, original.observationTime)
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
        XCTAssertEqual(decoded.windDirection, original.windDirection)
        XCTAssertEqual(decoded.windSpeed, original.windSpeed)
        XCTAssertEqual(decoded.apparentTemperature, original.apparentTemperature)
    }
}

final class CurrentWeatherWidgetConditionTests: XCTestCase {
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
            "rain": 0,
            "wind": {
              "direction": "西北",
              "speed": 3.25
            }
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
        XCTAssertEqual(weather.windDirection, "西北")
        XCTAssertEqual(weather.windSpeed, 3.25)
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

private struct SolarGolden {
    let id: String
    let latitude: Double
    let longitude: Double
    let nowUnixSeconds: Int64
    let expectedIsNight: Bool
    let expectedNextTransitionUnixSeconds: Int64
}

private let solarGoldens: [SolarGolden] = [
    // 臺北市中正區, region 100
    .init(id: "100-2024-02-29-noon", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_709_179_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_709_200_528),
    .init(id: "100-2024-03-20-noon", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_710_907_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_710_929_103),
    .init(id: "100-2024-06-21-noon", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_718_942_400, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_718_966_796),
    .init(id: "100-2024-09-22-noon", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_726_977_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_726_998_631),
    .init(id: "100-2024-12-21-noon", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_734_753_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_734_772_166),
    .init(id: "100-2024-12-31-noon", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_735_617_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_735_636_511),

    // 臺中市中區, region 400
    .init(id: "400-2024-02-29-noon", latitude: 24.1439458, longitude: 120.6794414, nowUnixSeconds: 1_709_179_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_709_200_763),
    .init(id: "400-2024-03-20-noon", latitude: 24.1439458, longitude: 120.6794414, nowUnixSeconds: 1_710_907_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_710_929_303),
    .init(id: "400-2024-06-21-noon", latitude: 24.1439458, longitude: 120.6794414, nowUnixSeconds: 1_718_942_400, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_718_966_881),
    .init(id: "400-2024-09-22-noon", latitude: 24.1439458, longitude: 120.6794414, nowUnixSeconds: 1_726_977_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_726_998_830),
    .init(id: "400-2024-12-21-noon", latitude: 24.1439458, longitude: 120.6794414, nowUnixSeconds: 1_734_753_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_734_772_480),
    .init(id: "400-2024-12-31-noon", latitude: 24.1439458, longitude: 120.6794414, nowUnixSeconds: 1_735_617_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_735_636_822),

    // 高雄市新興區, region 800
    .init(id: "800-2024-02-29-noon", latitude: 22.6310347, longitude: 120.3101095, nowUnixSeconds: 1_709_179_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_709_200_908),
    .init(id: "800-2024-03-20-noon", latitude: 22.6310347, longitude: 120.3101095, nowUnixSeconds: 1_710_907_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_710_929_389),
    .init(id: "800-2024-06-21-noon", latitude: 22.6310347, longitude: 120.3101095, nowUnixSeconds: 1_718_942_400, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_718_966_776),
    .init(id: "800-2024-09-22-noon", latitude: 22.6310347, longitude: 120.3101095, nowUnixSeconds: 1_726_977_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_726_998_915),
    .init(id: "800-2024-12-21-noon", latitude: 22.6310347, longitude: 120.3101095, nowUnixSeconds: 1_734_753_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_734_772_755),
    .init(id: "800-2024-12-31-noon", latitude: 22.6310347, longitude: 120.3101095, nowUnixSeconds: 1_735_617_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_735_637_094),

    // 花蓮縣花蓮市, region 970
    .init(id: "970-2024-02-29-noon", latitude: 23.9820651, longitude: 121.6067705, nowUnixSeconds: 1_709_179_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_709_200_546),
    .init(id: "970-2024-03-20-noon", latitude: 23.9820651, longitude: 121.6067705, nowUnixSeconds: 1_710_907_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_710_929_080),
    .init(id: "970-2024-06-21-noon", latitude: 23.9820651, longitude: 121.6067705, nowUnixSeconds: 1_718_942_400, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_718_966_637),
    .init(id: "970-2024-09-22-noon", latitude: 23.9820651, longitude: 121.6067705, nowUnixSeconds: 1_726_977_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_726_998_607),
    .init(id: "970-2024-12-21-noon", latitude: 23.9820651, longitude: 121.6067705, nowUnixSeconds: 1_734_753_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_734_772_277),
    .init(id: "970-2024-12-31-noon", latitude: 23.9820651, longitude: 121.6067705, nowUnixSeconds: 1_735_617_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_735_636_619),

    // 臺東縣蘭嶼鄉, region 952
    .init(id: "952-2024-02-29-noon", latitude: 22.0244984, longitude: 121.5560627, nowUnixSeconds: 1_709_179_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_709_200_631),
    .init(id: "952-2024-03-20-noon", latitude: 22.0244984, longitude: 121.5560627, nowUnixSeconds: 1_710_907_200, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_710_929_089),
    .init(id: "952-2024-06-21-noon", latitude: 22.0244984, longitude: 121.5560627, nowUnixSeconds: 1_718_942_400, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_718_966_401),
    .init(id: "952-2024-09-22-noon", latitude: 22.0244984, longitude: 121.5560627, nowUnixSeconds: 1_726_977_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_726_998_615),
    .init(id: "952-2024-12-21-noon", latitude: 22.0244984, longitude: 121.5560627, nowUnixSeconds: 1_734_753_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_734_772_530),
    .init(id: "952-2024-12-31-noon", latitude: 22.0244984, longitude: 121.5560627, nowUnixSeconds: 1_735_617_600, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_735_636_867),

    // Taipei exact boundaries, 2024-03-20
    .init(id: "100-before-sunrise", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_710_885_457, expectedIsNight: true, expectedNextTransitionUnixSeconds: 1_710_885_458),
    .init(id: "100-at-sunrise", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_710_885_458, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_710_929_103),
    .init(id: "100-after-sunrise", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_710_885_459, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_710_929_103),
    .init(id: "100-before-sunset", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_710_929_102, expectedIsNight: false, expectedNextTransitionUnixSeconds: 1_710_929_103),
    .init(id: "100-at-sunset", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_710_929_103, expectedIsNight: true, expectedNextTransitionUnixSeconds: 1_710_971_796),
    .init(id: "100-after-sunset", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_710_929_104, expectedIsNight: true, expectedNextTransitionUnixSeconds: 1_710_971_796),

    // 2024-12-31 after sunset -> 2025-01-01 sunrise
    .init(id: "100-year-rollover-after-sunset", latitude: 25.032188, longitude: 121.5183226, nowUnixSeconds: 1_735_636_512, expectedIsNight: true, expectedNextTransitionUnixSeconds: 1_735_684_745),
]

final class WidgetSolarTimeTests: XCTestCase {
    func testSolarGoldensMatchDartAuthority() {
        for golden in solarGoldens {
            let (nowUnixMilliseconds, overflow) =
                golden.nowUnixSeconds.multipliedReportingOverflow(
                    by: 1_000
                )

            XCTAssertFalse(
                overflow,
                "Unix millisecond conversion overflowed for \(golden.id)"
            )

            guard !overflow else {
                continue
            }

            XCTAssertEqual(
                WidgetSolarTime.isNight(
                    unixMilliseconds: nowUnixMilliseconds,
                    latitude: golden.latitude,
                    longitude: golden.longitude
                ),
                golden.expectedIsNight,
                "Unexpected day/night state for \(golden.id)"
            )

            XCTAssertEqual(
                WidgetSolarTime.nextDayNightTransition(
                    unixMilliseconds: nowUnixMilliseconds,
                    latitude: golden.latitude,
                    longitude: golden.longitude
                ),
                golden.expectedNextTransitionUnixSeconds,
                "Unexpected next transition for \(golden.id)"
            )
        }
    }

    func testPositiveModuloKeepsPositiveValue() {
        XCTAssertEqual(
            WidgetSolarTime.positiveModulo(
                10,
                modulus: 360
            ),
            10
        )
    }

    func testPositiveModuloWrapsOverflow() {
        XCTAssertEqual(
            WidgetSolarTime.positiveModulo(
                370,
                modulus: 360
            ),
            10
        )
    }

    func testPositiveModuloWrapsNegativeValue() {
        XCTAssertEqual(
            WidgetSolarTime.positiveModulo(
                -10,
                modulus: 360
            ),
            350
        )
    }

    func testPositiveModuloWrapsMultipleNegativeCycles() {
        XCTAssertEqual(
            WidgetSolarTime.positiveModulo(
                -730,
                modulus: 360
            ),
            350
        )
    }

    func testPositiveModuloNormalizesNegativeZero() {
        let result = WidgetSolarTime.positiveModulo(
            -0.0,
            modulus: 360
        )

        XCTAssertEqual(result, 0)
        XCTAssertEqual(result.sign, .plus)
    }

    func testJulianDaysIsZeroAtJ2000Noon() {
        XCTAssertEqual(
            WidgetSolarTime.julianDays(
                unixMilliseconds: 946_728_000_000
            ),
            0
        )
    }

    func testJulianDaysIsNegativeHalfAtJ2000Midnight() {
        XCTAssertEqual(
            WidgetSolarTime.julianDays(
                unixMilliseconds: 946_684_800_000
            ),
            -0.5
        )
    }

    func testJulianDaysAdvancesOnePerDay() {
        XCTAssertEqual(
            WidgetSolarTime.julianDays(
                unixMilliseconds: 946_814_400_000
            ),
            1
        )
    }

    func testJulianDaysMatchesUnixEpochOffset() {
        XCTAssertEqual(
            WidgetSolarTime.julianDays(
                unixMilliseconds: 0
            ),
            -10_957.5
        )
    }

    func testSolarTermsAtJ2000() {
        let terms = WidgetSolarTime.solarTerms(
            unixMilliseconds: 946_728_000_000
        )

        XCTAssertEqual(
            terms.meanLongitudeDegrees,
            280.460,
            accuracy: 0.000_001
        )

        XCTAssertEqual(
            terms.rightAscensionRadians,
            -1.3738212627,
            accuracy: 0.000_000_001
        )

        XCTAssertEqual(
            terms.declinationRadians,
            -0.4020091673,
            accuracy: 0.000_000_001
        )
    }

    func testIsNightIgnoresSubsecondWithinBoundarySecond() {
        let latitude = 25.032188
        let longitude = 121.5183226

        XCTAssertFalse(
            WidgetSolarTime.isNight(
                unixMilliseconds: 1_710_885_458_999,
                latitude: latitude,
                longitude: longitude
            )
        )

        XCTAssertTrue(
            WidgetSolarTime.isNight(
                unixMilliseconds: 1_710_929_103_999,
                latitude: latitude,
                longitude: longitude
            )
        )
    }

}

final class WidgetResolvedWeatherLocationTests: XCTestCase {
    func testAcceptsValidSavedLocation() {
        let location = WidgetResolvedWeatherLocation(
            address: .saved(regionCode: "407"),
            regionCode: "407",
            regionName: "西屯區",
            latitude: 24.1658213,
            longitude: 120.6336717
        )

        XCTAssertEqual(
            location?.address,
            .saved(regionCode: "407")
        )
        XCTAssertEqual(location?.regionCode, "407")
        XCTAssertEqual(location?.regionName, "西屯區")
        XCTAssertEqual(location?.latitude, 24.1658213)
        XCTAssertEqual(location?.longitude, 120.6336717)
    }

    func testRejectsSavedAddressRegionMismatch() {
        XCTAssertNil(
            WidgetResolvedWeatherLocation(
                address: .saved(regionCode: "407"),
                regionCode: "100",
                regionName: "中正區",
                latitude: 25.032188,
                longitude: 121.5183226
            )
        )
    }

    func testAcceptsCurrentLocationWithResolvedRegion() {
        let location = WidgetResolvedWeatherLocation(
            address: .currentLocation,
            regionCode: "407",
            regionName: "西屯區",
            latitude: 24.1658213,
            longitude: 120.6336717
        )

        XCTAssertEqual(
            location?.address,
            .currentLocation
        )

        XCTAssertEqual(
            location?.regionCode,
            "407"
        )
    }

    func testRejectsInvalidRegionCode() {
        XCTAssertNil(
            WidgetResolvedWeatherLocation(
                address: .currentLocation,
                regionCode: "40A",
                regionName: "西屯區",
                latitude: 24.1658213,
                longitude: 120.6336717
            )
        )
    }

    func testRejectsInvalidCoordinates() {
        XCTAssertNil(
            WidgetResolvedWeatherLocation(
                address: .currentLocation,
                regionCode: "407",
                regionName: "西屯區",
                latitude: 91,
                longitude: 120.6336717
            )
        )

        XCTAssertNil(
            WidgetResolvedWeatherLocation(
                address: .currentLocation,
                regionCode: "407",
                regionName: "西屯區",
                latitude: 24.1658213,
                longitude: .infinity
            )
        )
    }
}

final class CurrentWeatherWidgetSnapshotFactoryTests: XCTestCase {
    func testCreatesSchemaSevenSnapshotFromResolvedInputs() throws {
        let observation = try makeObservation()

        let location = try XCTUnwrap(
            WidgetResolvedWeatherLocation(
                address: .saved(regionCode: "100"),
                regionCode: "100",
                regionName: "中正區",
                latitude: 25.032188,
                longitude: 121.5183226
            )
        )

        let time = CurrentWeatherSnapshotTime(
            calibratedNowUnixMilliseconds:
                1_710_907_200_000,
            calibratedTimeOffsetMilliseconds:
                -5_000
        )

        let snapshot =
            CurrentWeatherWidgetSnapshotFactory.make(
                observation: observation,
                location: location,
                time: time
            )

        XCTAssertEqual(snapshot.schemaVersion, 7)
        XCTAssertEqual(
            snapshot.sourceIdentifier,
            "region:100"
        )

        XCTAssertEqual(snapshot.regionCode, "100")
        XCTAssertEqual(snapshot.regionName, "中正區")

        XCTAssertEqual(
            snapshot.observationTime,
            1_710_900_000
        )

        XCTAssertEqual(snapshot.stationName, "臺北")
        XCTAssertEqual(snapshot.weather, "晴")
        XCTAssertEqual(snapshot.weatherCode, 100)
        XCTAssertEqual(snapshot.condition, .clear)

        XCTAssertFalse(snapshot.isNight)
        XCTAssertEqual(
            snapshot.nextDayNightTransitionTime,
            1_710_929_103
        )

        XCTAssertEqual(
            snapshot.calibratedTimeOffsetMilliseconds,
            -5_000
        )

        XCTAssertEqual(snapshot.temperature, 28.5)
        XCTAssertEqual(snapshot.humidity, 70)
        XCTAssertEqual(snapshot.rain, 0)
        XCTAssertEqual(snapshot.windDirection, "南南西")
        XCTAssertEqual(snapshot.windSpeed, 1.5)
        XCTAssertEqual(
            try XCTUnwrap(snapshot.apparentTemperature),
            31.39512521394631,
            accuracy: 1e-9
        )
    }

    func testCreatesSnapshotWithNilWindValues() throws {
        let observation = try makeObservation(wind: "{}")
        let location = try XCTUnwrap(
            WidgetResolvedWeatherLocation(
                address: .saved(regionCode: "100"),
                regionCode: "100",
                regionName: "中正區",
                latitude: 25.0324,
                longitude: 121.5199
            )
        )

        let snapshot = CurrentWeatherWidgetSnapshotFactory.make(
            observation: observation,
            location: location,
            time: .init(
                calibratedNowUnixMilliseconds: 1_789_567_500_000,
                calibratedTimeOffsetMilliseconds: 0
            )
        )

        XCTAssertNil(snapshot.windDirection)
        XCTAssertNil(snapshot.windSpeed)
        XCTAssertNil(snapshot.apparentTemperature)
    }

    func testMissingApparentInputDoesNotFailSnapshotGeneration() throws {
        let cases: [(String, String, String)] = [
            ("null", "70", #"{ "speed": 1.5 }"#),
            ("28.5", "null", #"{ "speed": 1.5 }"#),
            ("28.5", "70", "{}"),
        ]
        let location = CurrentWeatherWidgetTestFixtures.resolvedLocation()

        for (temperature, humidity, wind) in cases {
            let observation = try makeObservation(
                temperature: temperature,
                humidity: humidity,
                wind: wind
            )
            let snapshot = CurrentWeatherWidgetSnapshotFactory.make(
                observation: observation,
                location: location,
                time: CurrentWeatherWidgetTestFixtures.snapshotTime()
            )
            XCTAssertEqual(snapshot.schemaVersion, 7)
            XCTAssertNil(snapshot.apparentTemperature)
        }
    }

    private func makeObservation(
        temperature: String = "28.5",
        humidity: String = "70",
        wind: String =
            #"{ "direction": "南南西", "speed": 1.5 }"#
    ) throws
        -> CurrentWeatherRemoteDTO
    {
        let json = """
        {
          "station": {
            "name": "臺北"
          },
          "time": 1710900000,
          "data": {
            "weather": "晴",
            "weatherCode": 100,
            "temperature": \(temperature),
            "humidity": \(humidity),
            "rain": 0,
            "wind": \(wind)
          }
        }
        """

        return try JSONDecoder().decode(
            CurrentWeatherRemoteDTO.self,
            from: Data(json.utf8)
        )
    }
}
