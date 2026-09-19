import Foundation

struct WidgetLocationOption: Equatable {
    let identifier: String
    let displayString: String
}

func makeWidgetLocationOptions(
    from catalog: WidgetLocationCatalog?,
    currentLocationDisplayString: String
) -> [WidgetLocationOption] {
    var options = [
        WidgetLocationOption(
            identifier: "current-location",
            displayString: currentLocationDisplayString
        )
    ]

    guard let catalog else {
        return options
    }

    options.append(
        contentsOf: catalog.locations.map { location in
            WidgetLocationOption(
                identifier: "region:\(location.regionCode)",
                displayString:
                    "\(location.displayName) — "
                    + location.administrativeAreaName
            )
        }
    )

    return options
}
