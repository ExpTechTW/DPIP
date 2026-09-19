import Intents

final class IntentHandler: INExtension,
    WeatherWidgetConfigurationIntentHandling
{
    override func handler(for intent: INIntent) -> Any {
        return self
    }

    func provideLocationOptionsCollection(
        for intent: WeatherWidgetConfigurationIntent,
        with completion: @escaping (
            INObjectCollection<WidgetLocation>?,
            Error?
        ) -> Void
    ) {
        let catalog = WidgetLocationCatalogStore().load()
        let currentLocationDisplayString = String(
            localized: "intent.current_location",
            bundle: .main,
            comment: "Current-location option in weather widget configuration."
        )

        let locations = makeWidgetLocationOptions(
            from: catalog,
            currentLocationDisplayString: currentLocationDisplayString
        ).map {
            WidgetLocation(
                identifier: $0.identifier,
                display: $0.displayString
            )
        }

        completion(
            INObjectCollection(items: locations),
            nil
        )
    }
}
