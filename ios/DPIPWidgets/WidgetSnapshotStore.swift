import Foundation

enum WidgetSnapshotKind {
    case weatherForecast

    var filename: String {
        switch self {
        case .weatherForecast:
            return "weather-forecast.json"
        }
    }
}

struct WidgetSnapshotStore {
    private let appGroupIdentifier =
        "group.com.exptech.dpip.dpip.widgets"

    func snapshotURL(for kind: WidgetSnapshotKind) -> URL? {
        guard let appGroupContainerURL =
            FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            )
        else {
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
}
