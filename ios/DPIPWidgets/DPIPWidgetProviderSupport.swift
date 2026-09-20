import Foundation

struct DPIPWidgetTimelinePlan: Sendable {
    let snapshot: CurrentWeatherWidgetSnapshot?
    let states: [CurrentWeatherWidgetTimelineState]
    let reloadDate: Date
}

struct DPIPWidgetTimelinePlanner: Sendable {
    typealias LoadSnapshot = @Sendable (
        WidgetLocationTarget
    ) -> CurrentWeatherWidgetSnapshot?
    typealias RefreshSaved = @Sendable (
        WidgetLocationTarget
    ) async -> SavedCurrentWeatherWidgetRefreshResult
    typealias Now = @Sendable () -> Date

    private let staleAfter: TimeInterval
    private let refreshInterval: TimeInterval
    private let loadSnapshot: LoadSnapshot
    private let refreshSaved: RefreshSaved
    private let now: Now

    init(
        staleAfter: TimeInterval,
        refreshInterval: TimeInterval,
        loadSnapshot: @escaping LoadSnapshot,
        refreshSaved: @escaping RefreshSaved,
        now: @escaping Now
    ) {
        self.staleAfter = staleAfter
        self.refreshInterval = refreshInterval
        self.loadSnapshot = loadSnapshot
        self.refreshSaved = refreshSaved
        self.now = now
    }

    func plan(
        for target: WidgetLocationTarget
    ) async -> DPIPWidgetTimelinePlan {
        if case .saved = target {
            _ = await refreshSaved(target)
        }

        // Always reload after the refresh attempt. Failed refreshes leave the
        // same-location cache untouched, so this also provides SWR behavior.
        let snapshot = loadSnapshot(target)
        let deviceNow = now()
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot,
            deviceNow: deviceNow,
            staleAfter: staleAfter
        )

        return DPIPWidgetTimelinePlan(
            snapshot: snapshot,
            states: states,
            reloadDate: deviceNow.addingTimeInterval(refreshInterval)
        )
    }
}

struct SavedCurrentWeatherWidgetRefreshRuntime: Sendable {
    typealias RefreshWithClock = @Sendable (
        WidgetServerClock,
        WidgetLocationTarget
    ) async -> SavedCurrentWeatherWidgetRefreshResult

    private let serverClock: WidgetServerClock
    private let refreshWithClock: RefreshWithClock

    init(
        serverClock: WidgetServerClock,
        refreshWithClock: @escaping RefreshWithClock
    ) {
        self.serverClock = serverClock
        self.refreshWithClock = refreshWithClock
    }

    func refresh(
        target: WidgetLocationTarget
    ) async -> SavedCurrentWeatherWidgetRefreshResult {
        await refreshWithClock(serverClock, target)
    }
}

struct DPIPWidgetProviderDependencies: Sendable {
    typealias LoadSnapshot = DPIPWidgetTimelinePlanner.LoadSnapshot

    let loadSnapshot: LoadSnapshot
    let timelinePlanner: DPIPWidgetTimelinePlanner
}

enum DPIPWidgetProviderRuntime {
    private static let appGroupIdentifier =
        "group.com.exptech.dpip.dpip.widgets"
    private static let staleAfter: TimeInterval = 30 * 60

    // This process-scoped dependency graph retains one clock for every
    // getTimeline call handled by the current extension process.
    static let shared: DPIPWidgetProviderDependencies = {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
        let snapshotStore = WidgetSnapshotStore(
            containerURL: containerURL
        )
        let loadSnapshot: DPIPWidgetTimelinePlanner.LoadSnapshot = {
            target in
            snapshotStore.loadCurrentWeatherSnapshot(for: target)
        }

        let weatherClient = CurrentWeatherClient()
        let refreshRuntime = SavedCurrentWeatherWidgetRefreshRuntime(
            serverClock: WidgetServerClock(),
            refreshWithClock: { clock, target in
                guard let containerURL else {
                    return .unavailable
                }

                let catalog = WidgetLocationCatalogStore(
                    containerURL: containerURL
                ).load()
                let service = SavedCurrentWeatherWidgetRefreshService(
                    resolver: SavedWidgetLocationResolver(
                        catalog: catalog
                    ),
                    weatherClient: weatherClient,
                    clock: clock,
                    writer: CurrentWeatherWidgetSnapshotWriter(
                        containerURL: containerURL
                    )
                )

                return await service.refresh(target: target)
            }
        )

        return DPIPWidgetProviderDependencies(
            loadSnapshot: loadSnapshot,
            timelinePlanner: DPIPWidgetTimelinePlanner(
                staleAfter: staleAfter,
                refreshInterval: staleAfter,
                loadSnapshot: loadSnapshot,
                refreshSaved: refreshRuntime.refresh,
                now: { Date.now }
            )
        )
    }()
}
