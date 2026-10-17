import AppIntents
import Foundation

/// An action on the existing SiriKit-configured widget, not a new configuration.
/// WidgetKit reloads the timeline after the button's intent returns. Fetching,
/// cache isolation and publication expiry remain the timeline planner's job.
@available(iOS 17.0, *)
struct RefreshForecastIntent: AppIntent {
    static let title: LocalizedStringResource = "widget.refresh_forecast"
    static let openAppWhenRun = false
    static let isDiscoverable = false

    @Parameter(title: "widget.refresh_location")
    var locationIdentifier: String

    init() {
        locationIdentifier = ""
    }

    init(locationIdentifier: String) {
        self.locationIdentifier = locationIdentifier
    }

    func perform() async throws -> some IntentResult {
        try requestRefresh(catalog: WidgetLocationCatalogStore().load())
    }

    // Same execution path with an explicit catalog for deterministic tests.
    // No injected transport is needed: the action has no network dependency.
    func requestRefresh(catalog: WidgetLocationCatalog?) throws -> some IntentResult {
        _ = try Self.validatedTarget(
            identifier: locationIdentifier,
            catalog: catalog
        )
        // Returning acknowledges the request, never successful weather delivery.
        // No cache writes, API fetches or explicit kind-wide reloads here.
        return .result()
    }

    static func validatedTarget(
        identifier: String,
        catalog: WidgetLocationCatalog?
    ) throws -> WidgetLocationTarget {
        let target = WidgetLocationTarget(identifier: identifier)
        switch target {
        case .currentLocation:
            return target
        case .saved:
            guard SavedWidgetLocationResolver(catalog: catalog)
                .resolve(target: target) != nil else {
                throw ValidationError.locationUnavailable
            }
            return target
        case .invalid:
            throw ValidationError.invalidIdentifier
        }
    }

    enum ValidationError: Error, Equatable {
        case invalidIdentifier
        case locationUnavailable
    }
}
