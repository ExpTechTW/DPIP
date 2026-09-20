import Foundation

enum CurrentWeatherWidgetSnapshotWriterError: Error {
    case invalidSourceIdentifier
}

struct CurrentWeatherWidgetSnapshotWriter {
    let containerURL: URL

    func write(
        _ snapshot: CurrentWeatherWidgetSnapshot
    ) throws {
        let data = try JSONEncoder().encode(snapshot)

        guard
            let sourceIdentifier = snapshot.sourceIdentifier,
            let address = CurrentWeatherSnapshotAddress(
                sourceIdentifier: sourceIdentifier
            )
        else {
            throw CurrentWeatherWidgetSnapshotWriterError
                .invalidSourceIdentifier
        }

        try CurrentWeatherSnapshotStorage(
            containerURL: containerURL
        ).replace(
            data,
            for: address
        )
    }
}
