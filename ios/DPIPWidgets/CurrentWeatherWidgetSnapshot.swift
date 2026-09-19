import Foundation
import SwiftUI

enum CurrentWeatherWidgetCondition: String, Decodable {
    case clear
    case cloudy
    case overcast
    case rain
    case thunderstorm
    case snow
    case fog
    case unknown

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

struct CurrentWeatherWidgetSnapshot: Decodable {
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
        rain: Double?
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
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        schemaVersion = try container.decode(
            Int.self,
            forKey: .schemaVersion
        )

        guard (1...5).contains(schemaVersion) else {
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
    }
}
