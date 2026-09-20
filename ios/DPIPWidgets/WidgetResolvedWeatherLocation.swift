enum WidgetResolvedWeatherLocationValidation {
    static func isValidRegionCode(
        _ regionCode: String
    ) -> Bool {
        let bytes = regionCode.utf8

        return bytes.count == 3
            && bytes.allSatisfy { byte in
                byte >= 48 && byte <= 57
            }
    }
}

struct WidgetResolvedWeatherLocation: Equatable, Sendable {
    let address: CurrentWeatherSnapshotAddress
    let regionCode: String
    let regionName: String
    let latitude: Double
    let longitude: Double

    init?(
        address: CurrentWeatherSnapshotAddress,
        regionCode: String,
        regionName: String,
        latitude: Double,
        longitude: Double
    ) {
        guard
            WidgetResolvedWeatherLocationValidation
                .isValidRegionCode(regionCode),
            latitude.isFinite,
            longitude.isFinite,
            (-90 ... 90).contains(latitude),
            (-180 ... 180).contains(longitude)
        else {
            return nil
        }

        if case let .saved(addressRegionCode) = address {
            guard addressRegionCode == regionCode else {
                return nil
            }
        }

        self.address = address
        self.regionCode = regionCode
        self.regionName = regionName
        self.latitude = latitude
        self.longitude = longitude
    }
}
