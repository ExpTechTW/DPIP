import Foundation

/// The narrow v5 township forecast response. Point labels are clock labels,
/// never dates; usable points retain their API order.
struct ForecastRemoteDTO: Decodable, Sendable {
    /// API publication time, Unix milliseconds.
    let updateTime: Int64
    let points: [ForecastWidgetPoint]

    private enum CodingKeys: String, CodingKey {
        case updateTime
        case forecast
    }

    private struct UsablePoint: Decodable {
        let point: ForecastWidgetPoint?

        init(from decoder: Decoder) throws {
            point = try? ForecastWidgetPoint(from: decoder)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        updateTime = try container.decode(Int64.self, forKey: .updateTime)
        guard updateTime > 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .updateTime,
                in: container,
                debugDescription: "Invalid forecast publication time."
            )
        }
        let forecast = try container.decode(
            [UsablePoint].self,
            forKey: .forecast
        )
        points = Array(forecast.compactMap(\.point).prefix(4))
    }
}
