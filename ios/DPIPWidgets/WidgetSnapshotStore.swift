import Foundation

enum WidgetSnapshotKind {
    case weatherForecast
    case currentWeather

    var filename: String {
        switch self {
        case .weatherForecast:
            return "weather-forecast.json"
        case .currentWeather:
            return "current-weather.json"
        }
    }
}

struct WidgetSnapshotStore: Sendable {
    private let appGroupContainerURL: URL?

    init(containerURL: URL?) {
        appGroupContainerURL = containerURL
    }

    func snapshotURL(for kind: WidgetSnapshotKind) -> URL? {
        guard let appGroupContainerURL else {
            return nil
        }

        let widgetSnapshotsURL =
            appGroupContainerURL.appendingPathComponent("WidgetSnapshots")

        return widgetSnapshotsURL.appendingPathComponent(
            kind.filename
        )
    }

    func loadData(for kind: WidgetSnapshotKind) -> Data? {
        guard let url = snapshotURL(for: kind) else {
            return nil
        }

        return try? Data(contentsOf: url)
    }

    func loadCurrentWeatherSnapshot() -> CurrentWeatherWidgetSnapshot? {
        guard let data = loadData(for: .currentWeather) else {
            return nil
        }

        return try? JSONDecoder().decode(
            CurrentWeatherWidgetSnapshot.self,
            from: data
        )
    }

    func currentWeatherSnapshotURL(
        for sourceIdentifier: String
    ) -> URL? {
        guard let address = CurrentWeatherSnapshotAddress(
            sourceIdentifier: sourceIdentifier
        ) else {
            return nil
        }

        guard let appGroupContainerURL else {
            return nil
        }

        return CurrentWeatherSnapshotStorage(
            containerURL: appGroupContainerURL
        ).snapshotURL(for: address)
    }

    func loadCurrentWeatherSnapshot(
        for target: WidgetLocationTarget
    ) -> CurrentWeatherWidgetSnapshot? {
        guard let sourceIdentifier = target.sourceIdentifier else {
            return nil
        }

        if let url = currentWeatherSnapshotURL(
            for: sourceIdentifier
        ),
           let data = try? Data(contentsOf: url),
           let snapshot = try? JSONDecoder().decode(
               CurrentWeatherWidgetSnapshot.self,
               from: data
           ),
           target.matches(snapshot: snapshot)
        {
            return snapshot
        }

        // Temporary migration fallback:
        // older app versions wrote one global current-weather.json.
        guard
            let legacySnapshot = loadCurrentWeatherSnapshot(),
            target.matches(snapshot: legacySnapshot)
        else {
            return nil
        }

        return legacySnapshot
    }
}
