import Foundation

/// The subset of `/api/v5/meteor/weather/realtime/:coords` used by the
/// current-weather widget.
struct CurrentWeatherRemoteDTO: Decodable, Sendable {
    let stationName: String
    let time: Int
    let weather: String
    let weatherCode: Int
    let temperature: Double?
    let humidity: Int?
    let rain: Double?

    var condition: CurrentWeatherWidgetCondition {
        currentWeatherWidgetCondition(for: weatherCode)
    }

    private enum CodingKeys: String, CodingKey {
        case station
        case time
        case data
    }

    private struct Station: Decodable, Sendable {
        let name: String
    }

    private struct WeatherData: Decodable, Sendable {
        let weather: String
        let weatherCode: Int
        let temperature: Double?
        let humidity: Int?
        let rain: Double?

        private enum CodingKeys: String, CodingKey {
            case weather
            case weatherCode
            case temperature
            case humidity
            case rain
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            weather = try container.decode(String.self, forKey: .weather)
            weatherCode = try container.decode(Int.self, forKey: .weatherCode)
            temperature = try Self.decodeNullableDouble(
                from: container,
                forKey: .temperature
            )
            humidity = try Self.decodeNullableInt(
                from: container,
                forKey: .humidity
            )
            rain = try Self.decodeNullableDouble(
                from: container,
                forKey: .rain
            )
        }

        private static func decodeNullableDouble(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) throws -> Double? {
            guard let value = try container.decodeIfPresent(
                Double.self,
                forKey: key
            ) else {
                return nil
            }

            return value == -99 ? nil : value
        }

        private static func decodeNullableInt(
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) throws -> Int? {
            guard let value = try container.decodeIfPresent(
                Int.self,
                forKey: key
            ) else {
                return nil
            }

            return value == -99 ? nil : value
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let station = try container.decode(Station.self, forKey: .station)
        let data = try container.decode(WeatherData.self, forKey: .data)

        stationName = station.name
        time = try container.decode(Int.self, forKey: .time)
        weather = data.weather
        weatherCode = data.weatherCode
        temperature = data.temperature
        humidity = data.humidity
        rain = data.rain
    }
}

/// Mirrors Dart's authoritative `weatherConditionForCode()` classification.
func currentWeatherWidgetCondition(
    for weatherCode: Int
) -> CurrentWeatherWidgetCondition {
    guard weatherCode > 0 else {
        return .unknown
    }

    switch weatherCode % 100 {
    case 1, 2, 5:
        return .fog
    case 3, 4, 14, 15, 16, 17, 18, 19:
        return .thunderstorm
    case 6, 7, 11, 13:
        return .rain
    case 8, 9, 10, 12:
        return .snow
    default:
        break
    }

    switch weatherCode / 100 {
    case 1:
        return .clear
    case 2:
        return .cloudy
    case 3:
        return .overcast
    default:
        return .unknown
    }
}
