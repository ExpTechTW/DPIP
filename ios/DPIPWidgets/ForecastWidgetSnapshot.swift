import Foundation

struct ForecastWidgetPoint: Codable, Equatable, Sendable {
    /// API-supplied HH:mm label only; no date or hour offset is inferred.
    let time: String
    /// Forecast air temperature in degrees Celsius.
    let temperature: Double
    let weather: String
    let weatherCode: Int
    /// Probability of precipitation in percent. Invalid/missing PoP is nil.
    let pop: Int?

    init?(time: String, temperature: Double, weather: String,
          weatherCode: Int, pop: Int?) {
        guard Self.isValidClockLabel(time), temperature.isFinite,
              !weather.isEmpty else {
            return nil
        }
        self.time = time
        self.temperature = temperature
        self.weather = weather
        self.weatherCode = weatherCode
        self.pop = pop.flatMap { (0...100).contains($0) ? $0 : nil }
    }

    private enum CodingKeys: String, CodingKey {
        case time, temperature, weather, weatherCode, pop
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let time = try container.decode(String.self, forKey: .time)
        let temperature = try container.decode(Double.self, forKey: .temperature)
        let weather = try container.decode(String.self, forKey: .weather)
        let weatherCode = try container.decode(Int.self, forKey: .weatherCode)
        let pop = try? container.decode(Int.self, forKey: .pop)
        guard let point = Self(
            time: time,
            temperature: temperature,
            weather: weather,
            weatherCode: weatherCode,
            pop: pop
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .time,
                in: container,
                debugDescription: "Unusable forecast point."
            )
        }
        self = point
    }

    private static func isValidClockLabel(_ value: String) -> Bool {
        let bytes = Array(value.utf8)
        guard bytes.count == 5, bytes[2] == 58,
              [0, 1, 3, 4].allSatisfy({ (48...57).contains(bytes[$0]) })
        else { return false }
        let hour = Int(bytes[0] - 48) * 10 + Int(bytes[1] - 48)
        let minute = Int(bytes[3] - 48) * 10 + Int(bytes[4] - 48)
        return hour < 24 && minute < 60
    }
}

struct ForecastWidgetSnapshot: Codable, Sendable {
    static let schemaVersion = 1

    let schemaVersion: Int
    let sourceIdentifier: String
    let regionCode: String
    /// API publication time, Unix milliseconds. Not a point valid time.
    let updateTime: Int64
    /// Local accepted-response time, Unix milliseconds. Not a point valid time.
    let receivedAt: Int64
    let points: [ForecastWidgetPoint]

    init?(sourceIdentifier: String, regionCode: String, updateTime: Int64,
          receivedAt: Int64, points: [ForecastWidgetPoint]) {
        guard let address = CurrentWeatherSnapshotAddress(
            sourceIdentifier: sourceIdentifier
        ), WidgetResolvedWeatherLocationValidation.isValidRegionCode(regionCode),
              updateTime > 0, receivedAt > 0,
              (1...4).contains(points.count) else { return nil }
        if case .saved(let code) = address, code != regionCode { return nil }
        self.schemaVersion = Self.schemaVersion
        self.sourceIdentifier = sourceIdentifier
        self.regionCode = regionCode
        self.updateTime = updateTime
        self.receivedAt = receivedAt
        self.points = points
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, sourceIdentifier, regionCode, updateTime
        case receivedAt, points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schema = try container.decode(Int.self, forKey: .schemaVersion)
        let source = try container.decode(String.self, forKey: .sourceIdentifier)
        let region = try container.decode(String.self, forKey: .regionCode)
        let updated = try container.decode(Int64.self, forKey: .updateTime)
        let received = try container.decode(Int64.self, forKey: .receivedAt)
        let points = try container.decode([ForecastWidgetPoint].self, forKey: .points)
        guard schema == Self.schemaVersion,
              let snapshot = Self(sourceIdentifier: source, regionCode: region,
                                  updateTime: updated, receivedAt: received,
                                  points: points) else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported or invalid forecast snapshot."
            )
        }
        self = snapshot
    }
}
