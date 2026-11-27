import Foundation

struct SavedWidgetLocationResolver: Sendable {
    let catalog: WidgetLocationCatalog?

    func resolve(
        target: WidgetLocationTarget
    ) -> WidgetResolvedWeatherLocation? {
        guard
            case let .saved(regionCode) = target,
            let catalog,
            let location = catalog.locations.first(where: {
                $0.regionCode == regionCode
            })
        else {
            return nil
        }

        return WidgetResolvedWeatherLocation(
            address: .saved(regionCode: regionCode),
            regionCode: location.regionCode,
            regionName: location.displayName,
            latitude: location.latitude,
            longitude: location.longitude
        )
    }

    /// The app's catalog is readable and no longer lists this saved place:
    /// the user removed it in the app. False without a catalog, which cannot
    /// tell a removed place from one never published.
    func isRemoved(target: WidgetLocationTarget) -> Bool {
        guard case .saved = target, catalog != nil else { return false }
        return resolve(target: target) == nil
    }
}
