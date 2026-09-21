import Foundation
#if DEBUG
import OSLog

enum WidgetWeatherRefreshDiagnostics {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.exptech.dpip",
        category: "WidgetWeatherRefresh"
    )

    static func log(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    static func targetIdentifier(_ target: WidgetLocationTarget) -> String {
        switch target {
        case .currentLocation:
            return "current-location"
        case .saved(let regionCode):
            return "region:\(regionCode)"
        case .invalid:
            return "invalid"
        }
    }

    static func snapshotSummary(
        _ snapshot: CurrentWeatherWidgetSnapshot?
    ) -> String {
        guard let snapshot else {
            return "unavailable"
        }

        return "sourceIdentifier=\(snapshot.sourceIdentifier ?? "none") "
            + "regionCode=\(snapshot.regionCode) "
            + "observationTime=\(snapshot.observationTime)"
    }
}
#endif

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
        #if DEBUG
        let snapshotBeforeRefresh: CurrentWeatherWidgetSnapshot?
        if case .saved = target {
            snapshotBeforeRefresh = loadSnapshot(target)
            WidgetWeatherRefreshDiagnostics.log(
                "cacheBefore "
                    + WidgetWeatherRefreshDiagnostics.snapshotSummary(
                        snapshotBeforeRefresh
                    )
            )
        } else {
            snapshotBeforeRefresh = nil
        }
        #endif

        if case .saved = target {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log(
                "refresh began target="
                    + WidgetWeatherRefreshDiagnostics.targetIdentifier(target)
            )
            #endif

            #if DEBUG
            let refreshResult = await refreshSaved(target)
            WidgetWeatherRefreshDiagnostics.log(
                "refresh result=\(refreshResult.diagnosticName)"
            )
            #else
            _ = await refreshSaved(target)
            #endif
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
        let reloadDate = deviceNow.addingTimeInterval(refreshInterval)

        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "cacheAfter "
                + WidgetWeatherRefreshDiagnostics.snapshotSummary(snapshot)
        )
        if case .saved = target {
            let cacheChanged = snapshotBeforeRefresh?.observationTime
                != snapshot?.observationTime
            WidgetWeatherRefreshDiagnostics.log(
                "cacheChanged=\(cacheChanged)"
            )
        }
        let stale = states.first?.isStale ?? false
        WidgetWeatherRefreshDiagnostics.log(
            "timeline entries=\(states.count) stale=\(stale) "
                + "reloadIntervalSeconds=\(Int(refreshInterval)) "
                + "reloadDateUnix=\(Int(reloadDate.timeIntervalSince1970))"
        )
        #endif

        return DPIPWidgetTimelinePlan(
            snapshot: snapshot,
            states: states,
            reloadDate: reloadDate
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

    #if DEBUG
    static let refreshInterval: TimeInterval = 60
    #else
    static let refreshInterval: TimeInterval = 20 * 60
    #endif

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
                    #if DEBUG
                    WidgetWeatherRefreshDiagnostics.log(
                        "catalog unavailable appGroupContainer=false"
                    )
                    #endif
                    return .unavailable
                }

                #if DEBUG
                WidgetWeatherRefreshDiagnostics.log("catalog load started")
                #endif
                let catalog = WidgetLocationCatalogStore(
                    containerURL: containerURL
                ).load()
                #if DEBUG
                if let catalog {
                    WidgetWeatherRefreshDiagnostics.log(
                        "catalog load succeeded locations="
                            + "\(catalog.locations.count)"
                    )
                } else {
                    WidgetWeatherRefreshDiagnostics.log(
                        "catalog load failed"
                    )
                }
                #endif
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
                refreshInterval: refreshInterval,
                loadSnapshot: loadSnapshot,
                refreshSaved: refreshRuntime.refresh,
                now: { Date.now }
            )
        )
    }()
}

#if DEBUG
private extension SavedCurrentWeatherWidgetRefreshResult {
    var diagnosticName: String {
        switch self {
        case .refreshed:
            return "refreshed"
        case .noObservation:
            return "noObservation"
        case .unavailable:
            return "unavailable"
        case .failed:
            return "failed"
        }
    }
}
#endif
