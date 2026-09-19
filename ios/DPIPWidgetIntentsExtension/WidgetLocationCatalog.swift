import Foundation

struct WidgetLocationCatalog: Decodable {
    let schemaVersion: Int
    let locations: [WidgetLocationCatalogLocation]
}

struct WidgetLocationCatalogLocation: Decodable {
    let regionCode: String
    let displayName: String
    let administrativeAreaName: String
    let latitude: Double
    let longitude: Double
}

struct WidgetLocationCatalogStore {
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

        return Self.decode(data)
    }

    static func decode(_ data: Data) -> WidgetLocationCatalog? {
        guard let catalog = try? JSONDecoder().decode(
            WidgetLocationCatalog.self,
            from: data
        ) else {
            return nil
        }

        guard catalog.schemaVersion == 1 else {
            return nil
        }

        return catalog
    }
}
