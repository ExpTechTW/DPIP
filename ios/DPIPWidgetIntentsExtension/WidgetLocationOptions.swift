import Foundation

struct WidgetLocationOption: Equatable {
    let identifier: String
    let displayString: String
}

func makeCurrentWidgetLocationOption(
    displayString: String
) -> WidgetLocationOption {
    WidgetLocationOption(
        identifier: "current-location",
        displayString: displayString
    )
}

func makeWidgetLocationOptions(
    from catalog: WidgetLocationCatalog?,
    currentLocationDisplayString: String
) -> [WidgetLocationOption] {
    var options = [
        makeCurrentWidgetLocationOption(
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
