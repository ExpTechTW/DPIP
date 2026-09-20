import Foundation

enum CurrentWeatherClientError: Error, Equatable {
    case invalidCoordinate
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case responseTooLarge
}

struct CurrentWeatherClient: Sendable {
    private static let scheme = "https"
    private static let host = "api.core-tnn1.exptech.dev"
    private static let realtimePath = "/api/v5/meteor/weather/realtime"

    private static let requestTimeout: TimeInterval = 6
    private static let maximumResponseSize = 128 * 1024

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func makeURL(latitude: Double, longitude: Double) throws -> URL {
        guard latitude.isFinite,
              longitude.isFinite,
              (-90.0...90.0).contains(latitude),
              (-180.0...180.0).contains(longitude)
        else {
            throw CurrentWeatherClientError.invalidCoordinate
        }

        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.path = "\(Self.realtimePath)/\(latitude),\(longitude)"

        guard let url = components.url else {
            throw CurrentWeatherClientError.invalidURL
        }

        return url
    }

    func fetch(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeatherRemoteDTO? {
        let url = try makeURL(
            latitude: latitude,
            longitude: longitude
        )

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Self.requestTimeout

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CurrentWeatherClientError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CurrentWeatherClientError.httpStatus(
                httpResponse.statusCode
            )
        }

        guard data.count <= Self.maximumResponseSize else {
            throw CurrentWeatherClientError.responseTooLarge
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data)

        if let object = jsonObject as? [String: Any],
           object.isEmpty {
            return nil
        }

        return try JSONDecoder().decode(
            CurrentWeatherRemoteDTO.self,
            from: data
        )
    }
}
