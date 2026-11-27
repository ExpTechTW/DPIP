import Foundation

/// Every file the widget keeps for one configured target, in the App Group.
///
/// One type owns them so no reader can pair one target's current weather with
/// another target's forecast:
///
/// - current weather, one file per target, ordered by
///   `CurrentWeatherSnapshotStorage` — the app writes the same files — plus
///   the pre-per-target `current-weather.json` as a read-only fallback for a
///   device upgraded from a version that only wrote that;
/// - the hourly forecast, one file per target under
///   `ForecastSnapshotLocation`;
/// - the next-hour rain trend, one file per target under `rain-trend`;
/// - how many refreshes in a row have failed, one file per target under
///   `refresh-failures`, so the retry backs off across widget processes.
struct WidgetTargetStore: Sendable {
    static let appGroupIdentifier = "group.com.exptech.dpip.dpip.widgets"
    private static let maximumPayloadSize = 128 * 1024

    let containerURL: URL

    /// The App Group store, or nil when the container is unavailable.
    static func appGroup() -> WidgetTargetStore? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ).map(WidgetTargetStore.init(containerURL:))
    }

    // MARK: Current weather

    private var currentWeather: CurrentWeatherSnapshotStorage {
        CurrentWeatherSnapshotStorage(containerURL: containerURL)
    }

    /// The single file older app versions wrote for every target.
    var legacyCurrentWeatherURL: URL {
        containerURL
            .appendingPathComponent("WidgetSnapshots", isDirectory: true)
            .appendingPathComponent("current-weather.json")
    }

    func currentWeatherURL(for target: WidgetLocationTarget) -> URL? {
        guard let source = target.sourceIdentifier,
              let address = CurrentWeatherSnapshotAddress(
                  sourceIdentifier: source
              )
        else {
            return nil
        }
        return currentWeather.snapshotURL(for: address)
    }

    func loadCurrent(
        for target: WidgetLocationTarget
    ) -> CurrentWeatherWidgetSnapshot? {
        for url in [currentWeatherURL(for: target), legacyCurrentWeatherURL] {
            guard let url,
                  let data = try? Data(contentsOf: url),
                  let snapshot = try? JSONDecoder().decode(
                      CurrentWeatherWidgetSnapshot.self, from: data
                  ),
                  target.matches(snapshot: snapshot)
            else {
                continue
            }
            return snapshot
        }
        return nil
    }

    /// Reserves this refresh's place in the target's write order. Taken when
    /// the refresh begins, so a slower, earlier refresh cannot overwrite a
    /// later one's township.
    func beginCurrentWrite(
        for address: CurrentWeatherSnapshotAddress
    ) throws -> CurrentWeatherSnapshotWriteToken {
        try currentWeather.beginWrite(for: address)
    }

    func commitCurrent(
        _ snapshot: CurrentWeatherWidgetSnapshot,
        using token: CurrentWeatherSnapshotWriteToken
    ) throws -> CurrentWeatherSnapshotWriteResult {
        guard let source = snapshot.sourceIdentifier,
              CurrentWeatherSnapshotAddress(sourceIdentifier: source)
                  == token.address
        else {
            throw CurrentWeatherSnapshotStorageError.invalidWriteToken
        }
        return try currentWeather.replace(
            try JSONEncoder().encode(snapshot), using: token
        )
    }

    // MARK: Hourly forecast

    func forecastURL(for target: WidgetLocationTarget) -> URL? {
        guard let source = target.sourceIdentifier,
              let address = CurrentWeatherSnapshotAddress(
                  sourceIdentifier: source
              )
        else {
            return nil
        }
        return ForecastSnapshotLocation
            .directoryURL(in: containerURL)
            .appendingPathComponent(address.filename)
    }

    /// The target's forecast for `regionCode`, while it is still usable at
    /// the device date `date`.
    func loadForecast(
        for target: WidgetLocationTarget,
        regionCode: String,
        at date: Date,
        calibratedTimeOffsetMilliseconds: Int = 0
    ) -> ForecastWidgetSnapshot? {
        guard let url = forecastURL(for: target),
              let snapshot = Self.decodeForecast(at: url),
              snapshot.sourceIdentifier == target.sourceIdentifier,
              snapshot.regionCode == regionCode,
              ForecastWidgetExpiry.isUsable(
                  snapshot,
                  at: date,
                  calibratedTimeOffsetMilliseconds:
                      calibratedTimeOffsetMilliseconds
              )
        else {
            return nil
        }
        return snapshot
    }

    /// Writes `snapshot` unless the cache already holds the same or a newer
    /// publication for the same region. Receiving a publication again must
    /// not move its receipt, which would stretch its lifetime.
    @discardableResult
    func writeForecast(
        _ snapshot: ForecastWidgetSnapshot,
        for target: WidgetLocationTarget
    ) throws -> Bool {
        guard snapshot.sourceIdentifier == target.sourceIdentifier,
              let url = forecastURL(for: target)
        else {
            return false
        }
        let data = try JSONEncoder().encode(snapshot)
        guard data.count <= Self.maximumPayloadSize else { return false }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return try Self.coordinatedReplace(at: url) { coordinatedURL in
            if let existing = Self.decodeForecast(at: coordinatedURL),
               existing.sourceIdentifier == snapshot.sourceIdentifier,
               existing.regionCode == snapshot.regionCode,
               existing.updateTime >= snapshot.updateTime {
                return false
            }
            try data.write(to: coordinatedURL, options: .atomic)
            return true
        }
    }

    // MARK: Rain trend

    func rainURL(for target: WidgetLocationTarget) -> URL? {
        guard let source = target.sourceIdentifier,
              let address = CurrentWeatherSnapshotAddress(
                  sourceIdentifier: source
              )
        else {
            return nil
        }
        return containerURL
            .appendingPathComponent("WidgetSnapshots", isDirectory: true)
            .appendingPathComponent("rain-trend", isDirectory: true)
            .appendingPathComponent(address.filename)
    }

    /// The target's rain trend for `regionCode`, whatever its age; the
    /// timeline decides how long its hour stays on screen.
    func loadRain(
        for target: WidgetLocationTarget,
        regionCode: String
    ) -> RainTrendWidgetSnapshot? {
        guard let url = rainURL(for: target),
              let data = try? Data(contentsOf: url),
              data.count <= Self.maximumPayloadSize,
              let snapshot = try? JSONDecoder().decode(
                  RainTrendWidgetSnapshot.self, from: data
              ),
              snapshot.schemaVersion == RainTrendWidgetSnapshot.schemaVersion,
              snapshot.sourceIdentifier == target.sourceIdentifier,
              snapshot.regionCode == regionCode
        else {
            return nil
        }
        return snapshot
    }

    func writeRain(
        _ snapshot: RainTrendWidgetSnapshot,
        for target: WidgetLocationTarget
    ) throws {
        guard snapshot.sourceIdentifier == target.sourceIdentifier,
              let url = rainURL(for: target)
        else {
            return
        }
        let data = try JSONEncoder().encode(snapshot)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        _ = try Self.coordinatedReplace(at: url) { coordinatedURL in
            try data.write(to: coordinatedURL, options: .atomic)
            return true
        }
    }

    private static func decodeForecast(at url: URL) -> ForecastWidgetSnapshot? {
        guard let size = (try? FileManager.default.attributesOfItem(
                  atPath: url.path
              ))?[.size] as? NSNumber,
              size.intValue <= maximumPayloadSize,
              let data = try? Data(contentsOf: url),
              data.count <= maximumPayloadSize
        else {
            return nil
        }
        return try? JSONDecoder().decode(ForecastWidgetSnapshot.self, from: data)
    }

    /// Runs `body` under a replacing write claim on `url`, so a concurrent
    /// writer in the app or another widget process is serialised with it.
    static func coordinatedReplace(
        at url: URL,
        _ body: (URL) throws -> Bool
    ) throws -> Bool {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var result: Result<Bool, Error>?
        coordinator.coordinate(
            writingItemAt: url,
            options: .forReplacing,
            error: &coordinationError
        ) { coordinatedURL in
            result = Result { try body(coordinatedURL) }
        }
        if let result { return try result.get() }
        if let coordinationError { throw coordinationError }
        return false
    }

    // MARK: Refresh failures

    private struct RefreshFailureRecord: Codable {
        let consecutiveFailures: Int
    }

    func refreshFailuresURL(for target: WidgetLocationTarget) -> URL? {
        guard let source = target.sourceIdentifier,
              let address = CurrentWeatherSnapshotAddress(
                  sourceIdentifier: source
              )
        else {
            return nil
        }
        return containerURL
            .appendingPathComponent("WidgetSnapshots", isDirectory: true)
            .appendingPathComponent("refresh-failures", isDirectory: true)
            .appendingPathComponent(address.filename)
    }

    /// Failed refreshes in a row for `target`, zero when none is recorded.
    func refreshFailures(for target: WidgetLocationTarget) -> Int {
        refreshFailuresURL(for: target).map(Self.decodeRefreshFailures) ?? 0
    }

    /// Counts `outcome` against `target` and returns its failed refreshes in
    /// a row, this one included; see `WidgetRefreshFailures`. Every widget
    /// showing one target shares the count, so any of them failing backs
    /// them all off. When the count cannot be stored, this failure counts as
    /// the first: storage trouble never stretches the retry.
    @discardableResult
    func recordRefreshOutcome(
        _ outcome: WidgetRefreshOutcome,
        for target: WidgetLocationTarget
    ) -> Int {
        let unstored = WidgetRefreshFailures.count(after: outcome, following: 0)
        guard let url = refreshFailuresURL(for: target) else { return unstored }
        // Nothing to write: an unavailable target leaves the count, and a
        // refresh with none recorded has nothing to clear.
        let stored = Self.decodeRefreshFailures(at: url)
        if WidgetRefreshFailures.count(after: outcome, following: stored)
            == stored {
            return stored
        }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            var counted = unstored
            _ = try Self.coordinatedReplace(at: url) { coordinatedURL in
                counted = WidgetRefreshFailures.count(
                    after: outcome,
                    following: Self.decodeRefreshFailures(at: coordinatedURL)
                )
                try JSONEncoder().encode(
                    RefreshFailureRecord(consecutiveFailures: counted)
                ).write(to: coordinatedURL, options: .atomic)
                return true
            }
            return counted
        } catch {
            return unstored
        }
    }

    private static func decodeRefreshFailures(at url: URL) -> Int {
        guard let data = try? Data(contentsOf: url),
              data.count <= maximumPayloadSize,
              let record = try? JSONDecoder().decode(
                  RefreshFailureRecord.self, from: data
              )
        else {
            return 0
        }
        return WidgetRefreshFailures.clamped(record.consecutiveFailures)
    }

    // MARK: Removed targets

    /// Deletes every file kept for `target`: its current weather, the
    /// pre-per-target file when that holds this target, its forecast, its
    /// rain trend and its failure count.
    func removeAll(for target: WidgetLocationTarget) throws {
        guard let source = target.sourceIdentifier,
              let address = CurrentWeatherSnapshotAddress(sourceIdentifier: source)
        else {
            return
        }
        try currentWeather.remove(for: address)
        if let data = try? Data(contentsOf: legacyCurrentWeatherURL),
           let legacy = try? JSONDecoder().decode(
               CurrentWeatherWidgetSnapshot.self, from: data
           ),
           target.matches(snapshot: legacy) {
            try Self.coordinatedRemove(at: legacyCurrentWeatherURL)
        }
        for url in [
            forecastURL(for: target), rainURL(for: target),
            refreshFailuresURL(for: target),
        ] {
            if let url { try Self.coordinatedRemove(at: url) }
        }
    }

    /// Deletes `url` under a delete claim; a file already gone is no error.
    private static func coordinatedRemove(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var result: Result<Void, Error>?
        coordinator.coordinate(
            writingItemAt: url, options: .forDeleting, error: &coordinationError
        ) { coordinatedURL in
            result = Result {
                do {
                    try FileManager.default.removeItem(at: coordinatedURL)
                } catch let error as CocoaError where error.code == .fileNoSuchFile {
                    // Removed by another process meanwhile.
                }
            }
        }
        if let result { return try result.get() }
        if let coordinationError { throw coordinationError }
    }
}
