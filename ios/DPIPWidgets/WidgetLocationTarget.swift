import Foundation

enum WidgetLocationTarget: Equatable {
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
