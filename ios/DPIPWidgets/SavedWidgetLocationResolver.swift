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
}
