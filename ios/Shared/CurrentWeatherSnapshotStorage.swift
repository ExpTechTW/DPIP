import Foundation

struct CurrentWeatherSnapshotStorage {
    let containerURL: URL

    func snapshotURL(
        for address: CurrentWeatherSnapshotAddress
    ) -> URL {
        containerURL
            .appendingPathComponent(
                "WidgetSnapshots",
                isDirectory: true
            )
            .appendingPathComponent(
                "current-weather",
                isDirectory: true
            )
            .appendingPathComponent(address.filename)
    }

    func replace(
        _ data: Data,
        for address: CurrentWeatherSnapshotAddress
    ) throws {
        let destination = snapshotURL(for: address)

        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try data.write(
            to: destination,
            options: .atomic
        )
    }
}
