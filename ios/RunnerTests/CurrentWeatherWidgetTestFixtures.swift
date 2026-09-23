import Foundation

enum CurrentWeatherWidgetTestFixtures {
    static func observation(
        stationName: String = "西屯測站",
        time: Int = 1_710_900_000,
        windSpeed: String = "1.5"
    ) throws -> CurrentWeatherRemoteDTO {
        let data = Data(
            """
            {
              "station": {"name": "\(stationName)"},
              "time": \(time),
              "data": {
                "weather": "晴",
                "weatherCode": 100,
                "temperature": 28.5,
                "humidity": 70,
                "rain": 0,
                "wind": {
                  "direction": "南南西",
                  "speed": \(windSpeed)
                }
              }
            }
            """.utf8
        )
        return try JSONDecoder().decode(CurrentWeatherRemoteDTO.self, from: data)
    }

    static func snapshotTime(
        offsetMilliseconds: Int = 321
    ) -> CurrentWeatherSnapshotTime {
        CurrentWeatherSnapshotTime(
            calibratedNowUnixMilliseconds: 1_710_907_200_000,
            calibratedTimeOffsetMilliseconds: offsetMilliseconds
        )
    }

    static func resolvedLocation(
        address: CurrentWeatherSnapshotAddress = .currentLocation,
        regionCode: String = "407",
        regionName: String = "西屯區",
        latitude: Double = 24.1813400,
        longitude: Double = 120.6466200
    ) -> WidgetResolvedWeatherLocation {
        WidgetResolvedWeatherLocation(
            address: address,
            regionCode: regionCode,
            regionName: regionName,
            latitude: latitude,
            longitude: longitude
        )!
    }

    static func snapshot(
        sourceIdentifier: String,
        regionCode: String,
        regionName: String = "舊快取",
        schemaVersion: Int = 7
    ) -> CurrentWeatherWidgetSnapshot {
        CurrentWeatherWidgetSnapshot(
            schemaVersion: schemaVersion,
            sourceIdentifier: sourceIdentifier,
            regionCode: regionCode,
            regionName: regionName,
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
    }

    static func catalogLocation(
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

    static func seed(
        _ snapshot: CurrentWeatherWidgetSnapshot,
        at address: CurrentWeatherSnapshotAddress,
        containerURL: URL
    ) throws -> Data {
        let writer = CurrentWeatherWidgetSnapshotWriter(containerURL: containerURL)
        try write(snapshot, to: address, using: writer)
        return try cachedData(at: address, containerURL: containerURL)
    }

    static func write(
        _ snapshot: CurrentWeatherWidgetSnapshot,
        to address: CurrentWeatherSnapshotAddress,
        using writer: CurrentWeatherWidgetSnapshotWriter
    ) throws {
        let token = try writer.beginWrite(for: address)
        _ = try writer.write(snapshot, using: token)
    }

    static func cachedData(
        at address: CurrentWeatherSnapshotAddress,
        containerURL: URL
    ) throws -> Data {
        let url = CurrentWeatherSnapshotStorage(
            containerURL: containerURL
        ).snapshotURL(for: address)
        return try Data(contentsOf: url)
    }
}
