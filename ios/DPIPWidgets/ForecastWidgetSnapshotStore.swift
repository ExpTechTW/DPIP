import Foundation

/// Independent per-target forecast cache in the App Group.
struct ForecastWidgetSnapshotStore: Sendable {
    private static let maximumPayloadSize = 128 * 1024
    let containerURL: URL

    func snapshotURL(for target: WidgetLocationTarget) -> URL? {
        guard let source = target.sourceIdentifier,
              let address = CurrentWeatherSnapshotAddress(
                  sourceIdentifier: source
              ) else { return nil }
        return containerURL
            .appendingPathComponent("WidgetSnapshots", isDirectory: true)
            .appendingPathComponent("hourly-forecast", isDirectory: true)
            .appendingPathComponent(address.filename)
    }

    func load(
        for target: WidgetLocationTarget,
        regionCode: String,
        at date: Date
    ) -> ForecastWidgetSnapshot? {
        guard let url = snapshotURL(for: target),
              let attributes = try? FileManager.default.attributesOfItem(
                  atPath: url.path
              ),
              let size = attributes[.size] as? NSNumber,
              size.intValue <= Self.maximumPayloadSize,
              let data = try? Data(contentsOf: url),
              data.count <= Self.maximumPayloadSize,
              let snapshot = try? JSONDecoder().decode(
                  ForecastWidgetSnapshot.self,
                  from: data
              ),
              snapshot.sourceIdentifier == target.sourceIdentifier,
              snapshot.regionCode == regionCode,
              ForecastWidgetExpiry.isUsable(snapshot, at: date)
        else { return nil }
        return snapshot
    }

    @discardableResult
    func write(_ snapshot: ForecastWidgetSnapshot,
               for target: WidgetLocationTarget) throws -> Bool {
        guard snapshot.sourceIdentifier == target.sourceIdentifier,
              let url = snapshotURL(for: target) else { return false }
        let data = try JSONEncoder().encode(snapshot)
        guard data.count <= Self.maximumPayloadSize else { return false }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var result: Result<Bool, Error>?
        coordinator.coordinate(
            writingItemAt: url,
            options: .forReplacing,
            error: &coordinationError
        ) { coordinatedURL in
            result = Result {
                // A late response for an older API publication cannot replace
                // a newer same-region forecast in this target's cache.
                let existingAttributes = try? FileManager.default.attributesOfItem(
                    atPath: coordinatedURL.path
                )
                let existingSize = (existingAttributes?[.size]
                    as? NSNumber)?.intValue
                if let existingSize,
                   existingSize <= Self.maximumPayloadSize,
                   let existingData = try? Data(contentsOf: coordinatedURL),
                   let existing = try? JSONDecoder().decode(
                       ForecastWidgetSnapshot.self,
                       from: existingData
                   ), existing.sourceIdentifier == snapshot.sourceIdentifier,
                   existing.regionCode == snapshot.regionCode,
                   existing.updateTime > snapshot.updateTime {
                    return false
                }
                try data.write(to: coordinatedURL, options: .atomic)
                return true
            }
        }
        if let result { return try result.get() }
        if let coordinationError { throw coordinationError }
        return false
    }
}
