import Foundation

/// Forecast failures are independent of current-weather refresh and cache.
struct ForecastWidgetRefreshService: Sendable {
    typealias Fetch = @Sendable (String) async throws -> ForecastRemoteDTO
    typealias LoadCurrent = @Sendable (WidgetLocationTarget)
        -> CurrentWeatherWidgetSnapshot?
    typealias SavedIsResolved = @Sendable (WidgetLocationTarget) -> Bool
    typealias Write = @Sendable (ForecastWidgetSnapshot,
                                  WidgetLocationTarget) throws -> Bool
    typealias Now = @Sendable () -> Date

    private let fetch: Fetch
    private let loadCurrent: LoadCurrent
    private let savedIsResolved: SavedIsResolved
    private let write: Write
    private let now: Now

    init(fetch: @escaping Fetch, loadCurrent: @escaping LoadCurrent,
         savedIsResolved: @escaping SavedIsResolved,
         write: @escaping Write, now: @escaping Now) {
        self.fetch = fetch
        self.loadCurrent = loadCurrent
        self.savedIsResolved = savedIsResolved
        self.write = write
        self.now = now
    }

    func refresh(target: WidgetLocationTarget,
                 regionCode: String) async {
        guard matchesCurrent(target: target, regionCode: regionCode),
              isResolved(target) else { return }

        let response: ForecastRemoteDTO
        do {
            response = try await fetch(regionCode)
        } catch {
            return
        }

        // Recheck after await: a Current Location request for A may complete
        // after the current-weather snapshot has moved to township B.
        guard matchesCurrent(target: target, regionCode: regionCode),
              isResolved(target), !response.points.isEmpty else { return }
        let receivedAt = Int64(now().timeIntervalSince1970 * 1_000)
        guard let snapshot = ForecastWidgetSnapshot(
            sourceIdentifier: target.sourceIdentifier ?? "",
            regionCode: regionCode,
            updateTime: response.updateTime,
            receivedAt: receivedAt,
            points: response.points
        ), ForecastWidgetExpiry.isUsable(snapshot, at: now()) else { return }
        _ = try? write(snapshot, target)
    }

    private func matchesCurrent(target: WidgetLocationTarget,
                                regionCode: String) -> Bool {
        guard let current = loadCurrent(target),
              target.matches(snapshot: current),
              current.sourceIdentifier == target.sourceIdentifier,
              current.regionCode == regionCode else { return false }
        return true
    }

    private func isResolved(_ target: WidgetLocationTarget) -> Bool {
        switch target {
        case .saved:
            return savedIsResolved(target)
        case .currentLocation:
            return true
        case .invalid:
            return false
        }
    }
}
