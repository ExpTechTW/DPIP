import Foundation

enum WidgetLocationTarget: Equatable, Sendable {
    case currentLocation
    case saved(regionCode: String)
    case invalid(identifier: String)

    init(identifier: String?) {
        guard let identifier else {
            self = .currentLocation
            return
        }

        guard let address = CurrentWeatherSnapshotAddress(
            sourceIdentifier: identifier
        ) else {
            self = .invalid(identifier: identifier)
            return
        }

        switch address {
        case .currentLocation:
            self = .currentLocation

        case .saved(let regionCode):
            self = .saved(regionCode: regionCode)
        }
    }
}

extension WidgetLocationTarget {
    // This literal is independent of configuration and always a valid URL.
    private static let homeURL = URL(string: "dpip:///home")!

    /// The configured target survives missing/expired weather. Never derive a
    /// navigation destination from a cached observation's region.
    var widgetURL: URL {
        var components = URLComponents()
        components.scheme = "dpip"
        components.host = ""
        components.path = "/home"
        if let identifier = sourceIdentifier,
           WidgetLocationTarget(identifier: identifier) == self {
            var allowed = CharacterSet.urlQueryAllowed
            allowed.remove(charactersIn: ":&=+?#%")
            if let encoded = identifier.addingPercentEncoding(
                withAllowedCharacters: allowed
            ) {
                components.percentEncodedQuery = "widgetLocation=" + encoded
            }
        }
        return Self.widgetURL(from: components)
    }

    static func widgetURL(from components: URLComponents) -> URL {
        components.url ?? homeURL
    }

    var sourceIdentifier: String? {
        switch self {
        case .currentLocation:
            return CurrentWeatherSnapshotAddress
                .currentLocation
                .sourceIdentifier

        case .saved(let regionCode):
            return CurrentWeatherSnapshotAddress
                .saved(regionCode: regionCode)
                .sourceIdentifier

        case .invalid:
            return nil
        }
    }

    func matches(
        snapshot: CurrentWeatherWidgetSnapshot
    ) -> Bool {
        guard
            let sourceIdentifier = snapshot.sourceIdentifier,
            let address = CurrentWeatherSnapshotAddress(
                sourceIdentifier: sourceIdentifier
            )
        else {
            return false
        }

        switch (self, address) {
        case (.currentLocation, .currentLocation):
            return true

        case let (
            .saved(regionCode),
            .saved(snapshotRegionCode)
        ):
            return snapshotRegionCode == regionCode
                && snapshot.regionCode == regionCode

        default:
            return false
        }
    }
}
