import Foundation

enum CurrentWeatherWidgetSnapshotWriterError: Error {
    case invalidSourceIdentifier
}

struct CurrentWeatherWidgetSnapshotWriter: Sendable {
    let containerURL: URL

    func beginWrite(
        for address: CurrentWeatherSnapshotAddress
    ) throws -> CurrentWeatherSnapshotWriteToken {
        try CurrentWeatherSnapshotStorage(
            containerURL: containerURL
        ).beginWrite(for: address)
    }

    func write(
        _ snapshot: CurrentWeatherWidgetSnapshot,
        using token: CurrentWeatherSnapshotWriteToken
    ) throws -> CurrentWeatherSnapshotWriteResult {
        let data = try JSONEncoder().encode(snapshot)

        let address = try address(for: snapshot)
        guard address == token.address else {
            throw CurrentWeatherSnapshotStorageError.invalidWriteToken
        }

        return try CurrentWeatherSnapshotStorage(
            containerURL: containerURL
        ).replace(
            data,
            using: token
        )
    }

    private func address(
        for snapshot: CurrentWeatherWidgetSnapshot
    ) throws -> CurrentWeatherSnapshotAddress {
        guard
            let sourceIdentifier = snapshot.sourceIdentifier,
            let address = CurrentWeatherSnapshotAddress(
                sourceIdentifier: sourceIdentifier
            )
        else {
            throw CurrentWeatherWidgetSnapshotWriterError
                .invalidSourceIdentifier
        }
        return address
    }
}
