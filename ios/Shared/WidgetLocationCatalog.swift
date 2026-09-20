import Foundation

struct WidgetLocationCatalog: Equatable, Sendable {
    static let supportedSchemaVersion = 1

    let schemaVersion: Int
    let locations: [WidgetLocationCatalogLocation]

    init?(
        schemaVersion: Int,
        locations: [WidgetLocationCatalogLocation]
    ) {
        guard schemaVersion == Self.supportedSchemaVersion else {
            return nil
        }

        let regionCodes = Set(locations.map(\.regionCode))

        guard regionCodes.count == locations.count else {
            return nil
        }

        self.schemaVersion = schemaVersion
        self.locations = locations
    }

    static func decode(_ data: Data) -> Self? {
        try? JSONDecoder().decode(Self.self, from: data)
    }
}

extension WidgetLocationCatalog: Decodable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case locations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decode(
            Int.self,
            forKey: .schemaVersion
        )
        let locations = try container.decode(
            [WidgetLocationCatalogLocation].self,
            forKey: .locations
        )

        guard let catalog = Self(
            schemaVersion: schemaVersion,
            locations: locations
        ) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription:
                        "Unsupported schema version or duplicate region code."
                )
            )
        }

        self = catalog
    }
}

struct WidgetLocationCatalogLocation: Equatable, Sendable {
    let regionCode: String
    let displayName: String
    let administrativeAreaName: String
    let latitude: Double
    let longitude: Double

    init?(
        regionCode: String,
        displayName: String,
        administrativeAreaName: String,
        latitude: Double,
        longitude: Double
    ) {
        guard
            Self.isValidRegionCode(regionCode),
            latitude.isFinite,
            longitude.isFinite,
            (-90 ... 90).contains(latitude),
            (-180 ... 180).contains(longitude)
        else {
            return nil
        }

        self.regionCode = regionCode
        self.displayName = displayName
        self.administrativeAreaName = administrativeAreaName
        self.latitude = latitude
        self.longitude = longitude
    }

    private static func isValidRegionCode(
        _ regionCode: String
    ) -> Bool {
        let bytes = regionCode.utf8

        return bytes.count == 3
            && bytes.allSatisfy { byte in
                byte >= 48 && byte <= 57
            }
    }
}

extension WidgetLocationCatalogLocation: Decodable {
    private enum CodingKeys: String, CodingKey {
        case regionCode
        case displayName
        case administrativeAreaName
        case latitude
        case longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let regionCode = try container.decode(
            String.self,
            forKey: .regionCode
        )
        let displayName = try container.decode(
            String.self,
            forKey: .displayName
        )
        let administrativeAreaName = try container.decode(
            String.self,
            forKey: .administrativeAreaName
        )
        let latitude = try container.decode(
            Double.self,
            forKey: .latitude
        )
        let longitude = try container.decode(
            Double.self,
            forKey: .longitude
        )

        guard let location = Self(
            regionCode: regionCode,
            displayName: displayName,
            administrativeAreaName: administrativeAreaName,
            latitude: latitude,
            longitude: longitude
        ) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription:
                        "Invalid region code or coordinate."
                )
            )
        }

        self = location
    }
}

struct WidgetLocationCatalogStore: Sendable {
    private let appGroupIdentifier =
        "group.com.exptech.dpip.dpip.widgets"

    func load() -> WidgetLocationCatalog? {
        guard let containerURL =
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            )
        else {
            return nil
        }

        let url = containerURL
            .appendingPathComponent("WidgetSnapshots")
            .appendingPathComponent("location-catalog.json")

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return WidgetLocationCatalog.decode(data)
    }
}
