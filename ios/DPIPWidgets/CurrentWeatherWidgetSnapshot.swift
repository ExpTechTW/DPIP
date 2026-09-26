import Foundation
import SwiftUI

enum CurrentWeatherWidgetCondition: String, Decodable, Sendable {
    case clear
    case cloudy
    case overcast
    case rain
    case thunderstorm
    case snow
    case fog
    case unknown
}

enum WidgetWeatherCondition: CaseIterable, Equatable, Sendable {
    case clear
    case cloudy
    case overcast
    case fog
    case rain
    case sleet
    case snow
    case hail
    case thunder
    case thunderstorm
    case unknown

    init(weatherCode: Int, weather: String) {
        switch weatherCode % 100 {
        case 1, 2, 5:
            self = .fog
            return
        case 3, 4, 19:
            self = .thunder
            return
        case 6, 11:
            self = .rain
            return
        case 7, 12:
            self = .sleet
            return
        case 8, 9, 10, 15:
            self = .snow
            return
        case 13, 16, 18:
            self = .hail
            return
        case 14, 17:
            self = .thunderstorm
            return
        default:
            break
        }

        switch weatherCode / 100 {
        case 1:
            self = .clear
        case 2:
            self = .cloudy
        case 3:
            self = .overcast
        default:
            self = Self.fallbackCondition(weather: weather)
        }
    }

    private static func fallbackCondition(weather: String) -> Self {
        if weather.contains("雷"), weather.contains("雨") {
            return .thunderstorm
        }
        if weather.contains("雹") {
            return .hail
        }
        if weather.contains("雨"), weather.contains("雪") {
            return .sleet
        }
        if weather.contains("雪") {
            return .snow
        }
        if weather.contains("雷") {
            return .thunder
        }
        if weather.contains("雨") {
            return .rain
        }
        if weather.contains("霧")
            || weather.contains("靄")
            || weather.contains("霾") {
            return .fog
        }
        if weather.contains("晴") {
            return .clear
        }
        if weather.contains("多雲") {
            return .cloudy
        }
        if weather.contains("陰") {
            return .overcast
        }
        return .unknown
    }

    var localizedDisplayName: LocalizedStringKey {
        LocalizedStringKey(displayNameLocalizationKey)
    }

    var displayNameLocalizationKey: String {
        switch self {
        case .clear:
            return "weather.clear"
        case .cloudy:
            return "weather.cloudy"
        case .overcast:
            return "weather.overcast"
        case .rain:
            return "weather.rain"
        case .sleet:
            return "weather.sleet"
        case .hail:
            return "weather.hail"
        case .thunder:
            return "weather.thunder"
        case .thunderstorm:
            return "weather.thunderstorm"
        case .snow:
            return "weather.snow"
        case .fog:
            return "weather.fog"
        case .unknown:
            return "weather.unknown"
        }
    }

    func systemImageName(isNight: Bool) -> String {
        switch self {
        case .clear:
            return isNight
                ? "moon.stars.fill"
                : "sun.max.fill"

        case .cloudy:
            return isNight
                ? "cloud.moon.fill"
                : "cloud.sun.fill"

        case .overcast:
            return "cloud.fill"

        case .rain:
            return "cloud.rain.fill"

        case .sleet:
            return "cloud.sleet.fill"

        case .hail:
            return "cloud.hail.fill"

        case .thunder:
            return "bolt.fill"

        case .thunderstorm:
            return "cloud.bolt.rain.fill"

        case .snow:
            return "cloud.snow.fill"

        case .fog:
            return "cloud.fog.fill"

        case .unknown:
            return "cloud.fill"
        }
    }
}

enum WidgetWindDirection: CaseIterable, Equatable, Sendable {
    case north
    case northNortheast
    case northeast
    case eastNortheast
    case east
    case eastSoutheast
    case southeast
    case southSoutheast
    case south
    case southSouthwest
    case southwest
    case westSouthwest
    case west
    case westNorthwest
    case northwest
    case northNorthwest

    init?(rawDirection: String) {
        switch rawDirection.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "北", "N":
            self = .north
        case "北北東", "NNE":
            self = .northNortheast
        case "東北", "NE":
            self = .northeast
        case "東北東", "ENE":
            self = .eastNortheast
        case "東", "E":
            self = .east
        case "東南東", "ESE":
            self = .eastSoutheast
        case "東南", "SE":
            self = .southeast
        case "南南東", "SSE":
            self = .southSoutheast
        case "南", "S":
            self = .south
        case "南南西", "SSW":
            self = .southSouthwest
        case "西南", "SW":
            self = .southwest
        case "西南西", "WSW":
            self = .westSouthwest
        case "西", "W":
            self = .west
        case "西北西", "WNW":
            self = .westNorthwest
        case "西北", "NW":
            self = .northwest
        case "北北西", "NNW":
            self = .northNorthwest
        default:
            return nil
        }
    }

    var localizedDisplayName: LocalizedStringKey {
        LocalizedStringKey(displayNameLocalizationKey)
    }

    var displayNameLocalizationKey: String {
        switch self {
        case .north:
            return "wind.direction.n"
        case .northNortheast:
            return "wind.direction.nne"
        case .northeast:
            return "wind.direction.ne"
        case .eastNortheast:
            return "wind.direction.ene"
        case .east:
            return "wind.direction.e"
        case .eastSoutheast:
            return "wind.direction.ese"
        case .southeast:
            return "wind.direction.se"
        case .southSoutheast:
            return "wind.direction.sse"
        case .south:
            return "wind.direction.s"
        case .southSouthwest:
            return "wind.direction.ssw"
        case .southwest:
            return "wind.direction.sw"
        case .westSouthwest:
            return "wind.direction.wsw"
        case .west:
            return "wind.direction.w"
        case .westNorthwest:
            return "wind.direction.wnw"
        case .northwest:
            return "wind.direction.nw"
        case .northNorthwest:
            return "wind.direction.nnw"
        }
    }
}

struct CurrentWeatherWidgetSnapshot: Codable, Sendable {
    let schemaVersion: Int
    let sourceIdentifier: String?

    let regionCode: String
    let regionName: String

    let observationTime: Int

    let stationName: String

    let weather: String
    let weatherCode: Int
    let condition: CurrentWeatherWidgetCondition
    let isNight: Bool

    /// The one next solar transition carried by this snapshot.
    let nextDayNightTransitionTime: Int

    /// Calibrated/server time minus device time, in milliseconds.
    let calibratedTimeOffsetMilliseconds: Int

    let temperature: Double?
    let humidity: Int?
    let rain: Double?
    let windDirection: String?
    let windSpeed: Double?
    let apparentTemperature: Double?

    var presentationCondition: WidgetWeatherCondition {
        WidgetWeatherCondition(weatherCode: weatherCode, weather: weather)
    }

    var presentationWindDirection: WidgetWindDirection? {
        guard let windDirection else {
            return nil
        }

        return WidgetWindDirection(
            rawDirection: windDirection
        )
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case sourceIdentifier
        case regionCode
        case regionName
        case observationTime
        case stationName
        case weather
        case weatherCode
        case condition
        case isNight
        case nextDayNightTransitionTime
        case calibratedTimeOffsetMilliseconds
        case temperature
        case humidity
        case rain
        case windDirection
        case windSpeed
        case apparentTemperature
    }

    init(
        schemaVersion: Int,
        sourceIdentifier: String? = nil,
        regionCode: String,
        regionName: String,
        observationTime: Int,
        stationName: String,
        weather: String,
        weatherCode: Int,
        condition: CurrentWeatherWidgetCondition,
        isNight: Bool,
        nextDayNightTransitionTime: Int,
        calibratedTimeOffsetMilliseconds: Int,
        temperature: Double?,
        humidity: Int?,
        rain: Double?,
        windDirection: String? = nil,
        windSpeed: Double? = nil,
        apparentTemperature: Double? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.sourceIdentifier = sourceIdentifier
        self.regionCode = regionCode
        self.regionName = regionName
        self.observationTime = observationTime
        self.stationName = stationName
        self.weather = weather
        self.weatherCode = weatherCode
        self.condition = condition
        self.isNight = isNight
        self.nextDayNightTransitionTime = nextDayNightTransitionTime
        self.calibratedTimeOffsetMilliseconds =
            calibratedTimeOffsetMilliseconds
        self.temperature = temperature
        self.humidity = humidity
        self.rain = rain
        self.windDirection = windDirection
        self.windSpeed = windSpeed
        self.apparentTemperature = apparentTemperature
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        schemaVersion = try container.decode(
            Int.self,
            forKey: .schemaVersion
        )

        guard (1...7).contains(schemaVersion) else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription:
                    "Unsupported current-weather snapshot schema version."
            )
        }

        if schemaVersion >= 5 {
            sourceIdentifier = try container.decode(
                String.self,
                forKey: .sourceIdentifier
            )
        } else {
            sourceIdentifier = nil
        }

        regionCode = try container.decode(
            String.self,
            forKey: .regionCode
        )

        regionName = try container.decode(
            String.self,
            forKey: .regionName
        )

        observationTime = try container.decode(
            Int.self,
            forKey: .observationTime
        )

        stationName = try container.decode(
            String.self,
            forKey: .stationName
        )

        weather = try container.decode(
            String.self,
            forKey: .weather
        )

        weatherCode = try container.decode(
            Int.self,
            forKey: .weatherCode
        )

        let conditionRawValue = try container.decodeIfPresent(
            String.self,
            forKey: .condition
        )

        condition = conditionRawValue
            .flatMap(CurrentWeatherWidgetCondition.init(rawValue:))
            ?? .unknown

        isNight = try container.decodeIfPresent(
            Bool.self,
            forKey: .isNight
        ) ?? false

        nextDayNightTransitionTime = try container.decodeIfPresent(
            Int.self,
            forKey: .nextDayNightTransitionTime
        ) ?? 0

        if schemaVersion >= 4 {
            calibratedTimeOffsetMilliseconds = try container.decode(
                Int.self,
                forKey: .calibratedTimeOffsetMilliseconds
            )
        } else {
            calibratedTimeOffsetMilliseconds = try container.decodeIfPresent(
                Int.self,
                forKey: .calibratedTimeOffsetMilliseconds
            ) ?? 0
        }

        temperature = try container.decodeIfPresent(
            Double.self,
            forKey: .temperature
        )

        humidity = try container.decodeIfPresent(
            Int.self,
            forKey: .humidity
        )

        rain = try container.decodeIfPresent(
            Double.self,
            forKey: .rain
        )

        if schemaVersion >= 6 {
            windDirection = try container.decodeIfPresent(
                String.self,
                forKey: .windDirection
            )
            windSpeed = try container.decodeIfPresent(
                Double.self,
                forKey: .windSpeed
            )
        } else {
            windDirection = nil
            windSpeed = nil
        }

        if schemaVersion >= 7 {
            apparentTemperature = try container.decodeIfPresent(
                Double.self,
                forKey: .apparentTemperature
            )
        } else {
            apparentTemperature = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        guard schemaVersion == 7 else {
            throw EncodingError.invalidValue(
                schemaVersion,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription:
                        "Only current-weather snapshot schema version 7 can be encoded."
                )
            )
        }

        guard let sourceIdentifier else {
            throw EncodingError.invalidValue(
                sourceIdentifier as Any,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription:
                        "Schema version 7 requires a source identifier."
                )
            )
        }

        guard let address = CurrentWeatherSnapshotAddress(
            sourceIdentifier: sourceIdentifier
        ) else {
            throw EncodingError.invalidValue(
                sourceIdentifier,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription:
                        "Invalid current-weather snapshot source identifier."
                )
            )
        }

        guard CurrentWeatherSnapshotAddress(
            sourceIdentifier: "region:\(regionCode)"
        ) != nil else {
            throw EncodingError.invalidValue(
                regionCode,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription:
                        "Current-weather snapshot region code must be exactly three ASCII digits."
                )
            )
        }

        if case let .saved(addressRegionCode) = address {
            guard addressRegionCode == regionCode else {
                throw EncodingError.invalidValue(
                    regionCode,
                    .init(
                        codingPath: encoder.codingPath,
                        debugDescription:
                            "Saved snapshot source identifier and payload region code must match."
                    )
                )
            }
        }

        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            schemaVersion,
            forKey: .schemaVersion
        )
        try container.encode(
            sourceIdentifier,
            forKey: .sourceIdentifier
        )
        try container.encode(
            regionCode,
            forKey: .regionCode
        )
        try container.encode(
            regionName,
            forKey: .regionName
        )
        try container.encode(
            observationTime,
            forKey: .observationTime
        )
        try container.encode(
            stationName,
            forKey: .stationName
        )
        try container.encode(
            weather,
            forKey: .weather
        )
        try container.encode(
            weatherCode,
            forKey: .weatherCode
        )
        try container.encode(
            condition.rawValue,
            forKey: .condition
        )
        try container.encode(
            isNight,
            forKey: .isNight
        )
        try container.encode(
            nextDayNightTransitionTime,
            forKey: .nextDayNightTransitionTime
        )
        try container.encode(
            calibratedTimeOffsetMilliseconds,
            forKey: .calibratedTimeOffsetMilliseconds
        )

        if let temperature {
            try container.encode(
                temperature,
                forKey: .temperature
            )
        } else {
            try container.encodeNil(
                forKey: .temperature
            )
        }

        if let humidity {
            try container.encode(
                humidity,
                forKey: .humidity
            )
        } else {
            try container.encodeNil(
                forKey: .humidity
            )
        }

        if let rain {
            try container.encode(
                rain,
                forKey: .rain
            )
        } else {
            try container.encodeNil(
                forKey: .rain
            )
        }

        if let windDirection {
            try container.encode(
                windDirection,
                forKey: .windDirection
            )
        } else {
            try container.encodeNil(
                forKey: .windDirection
            )
        }

        if let windSpeed {
            try container.encode(
                windSpeed,
                forKey: .windSpeed
            )
        } else {
            try container.encodeNil(
                forKey: .windSpeed
            )
        }

        if let apparentTemperature {
            try container.encode(
                apparentTemperature,
                forKey: .apparentTemperature
            )
        } else {
            try container.encodeNil(
                forKey: .apparentTemperature
            )
        }
    }
}
