import Foundation

struct ResolvedSavedLocation: Equatable, Sendable {
    let sourceIdentifier: String
    let regionCode: String
    let regionName: String
    let latitude: Double
    let longitude: Double
}

struct SavedWidgetLocationResolver: Sendable {
    let catalog: WidgetLocationCatalog?

    func resolve(
        target: WidgetLocationTarget
    ) -> ResolvedSavedLocation? {
        guard
            case let .saved(regionCode) = target,
            let catalog,
            let location = catalog.locations.first(where: {
                $0.regionCode == regionCode
            }),
            let sourceIdentifier = target.sourceIdentifier
        else {
            return nil
        }

        return ResolvedSavedLocation(
            sourceIdentifier: sourceIdentifier,
            regionCode: location.regionCode,
            regionName: location.displayName,
            latitude: location.latitude,
            longitude: location.longitude
        )
    }
}
