import Intents

final class IntentHandler: INExtension,
    WeatherWidgetConfigurationIntentHandling
{
    override func handler(for intent: INIntent) -> Any {
        return self
    }

    func defaultLocation(
        for intent: WeatherWidgetConfigurationIntent
    ) -> WidgetLocation? {
        makeCurrentWidgetLocation()
    }

    func provideLocationOptionsCollection(
        for intent: WeatherWidgetConfigurationIntent,
        with completion: @escaping (
            INObjectCollection<WidgetLocation>?,
            Error?
        ) -> Void
    ) {
        let catalog = WidgetLocationCatalogStore().load()

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

    private func makeCurrentWidgetLocation() -> WidgetLocation {
        let option = makeCurrentWidgetLocationOption(
            displayString: currentLocationDisplayString
        )
        return WidgetLocation(
            identifier: option.identifier,
            display: option.displayString
        )
    }

    private var currentLocationDisplayString: String {
        String(
            localized: "intent.current_location",
            bundle: .main,
            comment: "Current-location option in weather widget configuration."
        )
    }
}
