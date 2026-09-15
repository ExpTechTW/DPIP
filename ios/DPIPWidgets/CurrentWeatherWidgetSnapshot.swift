import Foundation

struct CurrentWeatherWidgetSnapshot: Decodable {
    let schemaVersion: Int

    let regionCode: String
    let regionName: String

    let observationTime: Int

    let stationName: String

    let weather: String
    let weatherCode: Int

    let temperature: Double?
    let humidity: Int?
    let rain: Double?
}
