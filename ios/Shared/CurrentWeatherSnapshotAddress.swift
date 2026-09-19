enum CurrentWeatherSnapshotAddress: Equatable {
    case currentLocation
    case saved(regionCode: String)

    init?(sourceIdentifier: String) {
        if sourceIdentifier == "current-location" {
            self = .currentLocation
            return
        }

        let prefix = "region:"

        guard sourceIdentifier.hasPrefix(prefix) else {
            return nil
        }

        let regionCode = String(
            sourceIdentifier.dropFirst(prefix.count)
        )

        guard Self.isValidRegionCode(regionCode) else {
            return nil
        }

        self = .saved(regionCode: regionCode)
    }

    var sourceIdentifier: String {
        switch self {
        case .currentLocation:
            return "current-location"

        case .saved(let regionCode):
            return "region:\(regionCode)"
        }
    }

    var filename: String {
        switch self {
        case .currentLocation:
            return "current-location.json"

        case .saved(let regionCode):
            return "region-\(regionCode).json"
        }
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
