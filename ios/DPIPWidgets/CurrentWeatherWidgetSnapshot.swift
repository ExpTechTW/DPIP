import Foundation

enum CurrentWeatherWidgetCondition: String, Decodable {
    case clear
    case cloudy
    case overcast
    case rain
    case thunderstorm
    case snow
    case fog
    case unknown

    var systemImageName: String {
        switch self {
        case .clear:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.sun.fill"
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

    let regionCode: String
    let regionName: String

    let observationTime: Int

    let stationName: String

    let weather: String
    let weatherCode: Int
    let condition: CurrentWeatherWidgetCondition

    let temperature: Double?
    let humidity: Int?
    let rain: Double?

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case regionCode
        case regionName
        case observationTime
        case stationName
        case weather
        case weatherCode
        case condition
        case temperature
        case humidity
        case rain
    }

    init(
        schemaVersion: Int,
        regionCode: String,
        regionName: String,
        observationTime: Int,
        stationName: String,
        weather: String,
        weatherCode: Int,
        condition: CurrentWeatherWidgetCondition,
        temperature: Double?,
        humidity: Int?,
        rain: Double?
    ) {
        self.schemaVersion = schemaVersion
        self.regionCode = regionCode
        self.regionName = regionName
        self.observationTime = observationTime
        self.stationName = stationName
        self.weather = weather
        self.weatherCode = weatherCode
        self.condition = condition
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
