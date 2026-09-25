import Foundation

enum ForecastClientError: Error, Equatable {
    case invalidRegionCode
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case responseTooLarge
}

struct ForecastClient: Sendable {
    private static let requestTimeout: TimeInterval = 6
    private static let maximumResponseSize = 128 * 1024
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func makeURL(regionCode: String) throws -> URL {
        guard WidgetResolvedWeatherLocationValidation
            .isValidRegionCode(regionCode) else {
            throw ForecastClientError.invalidRegionCode
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.core-tnn1.exptech.dev"
        components.path = "/api/v5/meteor/weather/forecast/\(regionCode)"
        guard let url = components.url else {
            throw ForecastClientError.invalidURL
        }
        return url
    }

    func fetch(regionCode: String) async throws -> ForecastRemoteDTO {
        var request = URLRequest(url: try makeURL(regionCode: regionCode))
        request.httpMethod = "GET"
        request.timeoutInterval = Self.requestTimeout
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw ForecastClientError.invalidResponse
        }
        guard response.statusCode == 200 else {
            throw ForecastClientError.httpStatus(response.statusCode)
        }
        guard data.count <= Self.maximumResponseSize else {
            throw ForecastClientError.responseTooLarge
        }
        return try JSONDecoder().decode(ForecastRemoteDTO.self, from: data)
    }
}
