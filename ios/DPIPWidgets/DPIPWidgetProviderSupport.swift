import Foundation
import WidgetKit

enum ForecastWidgetFamilyPolicy {
    static func supportsForecast(_ family: WidgetFamily) -> Bool {
        switch family {
        case .systemMedium, .systemLarge:
            return true
        default:
            return false
        }
    }

    /// - Parameter calibratedDate: a calibrated instant, never a WidgetKit
    ///   entry date. Point labels are Taipei wall-clock readings of calibrated
    ///   time, so a device-clock date shifts the selection by the offset.
    static func visiblePoints(
        in forecast: ForecastWidgetSnapshot,
        at calibratedDate: Date,
        family: WidgetFamily
    ) -> [ForecastWidgetPoint] {
        guard supportsForecast(family) else { return [] }
        return ForecastWidgetSelection.upcomingPoints(
            forecast.points, at: calibratedDate, limit: 5
        )
    }
}

#if DEBUG

enum WidgetWeatherRefreshDiagnostics {
    /// The widget process exits before the in-app log is opened. This buffer
    /// is what that launch imports.
    static func log(_ message: String) {
        // This file is also compiled into the test host. Skip the app-group
        // write there; a real widget refresh does not carry that environment.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return
        }
        FileNativeLog.appGroup()?.record(
            level: .debug,
            tag: "WidgetWeatherRefresh",
            message: message
        )
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

    static func cacheChanged(
        from previous: CurrentWeatherWidgetSnapshot?,
        to current: CurrentWeatherWidgetSnapshot?
    ) -> Bool {
        guard let previous, let current else {
            return (previous == nil) != (current == nil)
        }

        return previous.sourceIdentifier != current.sourceIdentifier
            || previous.regionCode != current.regionCode
            || previous.observationTime != current.observationTime
    }
}
#endif

struct DPIPWidgetTimelinePlan: Sendable {
    let snapshot: CurrentWeatherWidgetSnapshot?
    let forecast: ForecastWidgetSnapshot?
    let states: [CurrentWeatherWidgetTimelineState]
    let reloadDate: Date

    func forecast(at date: Date) -> ForecastWidgetSnapshot? {
        guard let forecast, let snapshot,
              ForecastWidgetExpiry.isUsable(
                  forecast,
                  at: date,
                  calibratedTimeOffsetMilliseconds:
                      snapshot.calibratedTimeOffsetMilliseconds
              ) else {
            return nil
        }
        return forecast
    }
}

struct DPIPWidgetTimelinePlanner: Sendable {
    typealias LoadSnapshot = @Sendable (
        WidgetLocationTarget
    ) -> CurrentWeatherWidgetSnapshot?
    typealias RefreshSaved = @Sendable (
        WidgetLocationTarget
    ) async -> CurrentWeatherWidgetRefreshResult
    typealias RefreshCurrent = @Sendable () async
        -> CurrentWeatherWidgetRefreshResult
    typealias LoadForecast = @Sendable (
        WidgetLocationTarget, String, Date
    ) -> ForecastWidgetSnapshot?
    typealias RefreshForecast = @Sendable (
        WidgetLocationTarget, String
    ) async -> Void
    typealias Now = @Sendable () -> Date

    private let staleAfter: TimeInterval
    private let refreshInterval: TimeInterval
    private let loadSnapshot: LoadSnapshot
    private let refreshSaved: RefreshSaved
    private let refreshCurrent: RefreshCurrent
    private let loadForecast: LoadForecast
    private let refreshForecast: RefreshForecast
    private let now: Now

    init(
        staleAfter: TimeInterval,
        refreshInterval: TimeInterval,
        loadSnapshot: @escaping LoadSnapshot,
        refreshSaved: @escaping RefreshSaved,
        refreshCurrent: @escaping RefreshCurrent,
        loadForecast: @escaping LoadForecast = { _, _, _ in nil },
        refreshForecast: @escaping RefreshForecast = { _, _ in },
        now: @escaping Now
    ) {
        self.staleAfter = staleAfter
        self.refreshInterval = refreshInterval
        self.loadSnapshot = loadSnapshot
        self.refreshSaved = refreshSaved
        self.refreshCurrent = refreshCurrent
        self.loadForecast = loadForecast
        self.refreshForecast = refreshForecast
        self.now = now
    }

    func plan(
        for target: WidgetLocationTarget,
        family: WidgetFamily = .systemSmall
    ) async -> DPIPWidgetTimelinePlan {
        #if DEBUG
        let snapshotBeforeRefresh: CurrentWeatherWidgetSnapshot?
        switch target {
        case .saved, .currentLocation:
            snapshotBeforeRefresh = loadSnapshot(target)
            WidgetWeatherRefreshDiagnostics.log(
                "cacheBefore "
                    + WidgetWeatherRefreshDiagnostics.snapshotSummary(
                        snapshotBeforeRefresh
                    )
            )
        case .invalid:
            snapshotBeforeRefresh = nil
        }
        #endif

        switch target {
        case .saved:
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
        case .currentLocation:
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log(
                "refresh began target=current-location"
            )
            let refreshResult = await refreshCurrent()
            WidgetWeatherRefreshDiagnostics.log(
                "refresh result=\(refreshResult.diagnosticName)"
            )
            #else
            _ = await refreshCurrent()
            #endif
        case .invalid:
            break
        }

        // Always reload after the refresh attempt. Failed refreshes leave the
        // same-location cache untouched, so this also provides SWR behavior.
        var snapshot = loadSnapshot(target)
        if ForecastWidgetFamilyPolicy.supportsForecast(family),
           let current = snapshot,
           target.matches(snapshot: current) {
            await refreshForecast(target, current.regionCode)
            // Re-read after the forecast await to reject a late township A
            // response if Current Location has since moved to township B.
            snapshot = loadSnapshot(target)
        }
        let deviceNow = now()
        var states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot,
            deviceNow: deviceNow,
            staleAfter: staleAfter
        )
        var reloadDate = deviceNow.addingTimeInterval(refreshInterval)
        let forecast: ForecastWidgetSnapshot?
        if ForecastWidgetFamilyPolicy.supportsForecast(family),
           let snapshot,
           target.matches(snapshot: snapshot) {
            forecast = loadForecast(
                target, snapshot.regionCode, deviceNow
            )
        } else {
            forecast = nil
        }
        if let forecast, let snapshot {
            let expiry = ForecastWidgetExpiry.date(
                for: forecast,
                calibratedTimeOffsetMilliseconds:
                    snapshot.calibratedTimeOffsetMilliseconds
            )
            reloadDate = ForecastWidgetExpiry.requestedReloadDate(
                now: deviceNow,
                normalReloadDate: reloadDate,
                expiry: expiry
            )
            // Reload eligibility is not an execution guarantee. Supply the
            // expiry state even when it falls after the requested reload.
            if expiry > deviceNow,
               !states.contains(where: { $0.date == expiry }) {
                states.append(CurrentWeatherWidgetTimeline.state(
                    snapshot: snapshot,
                    at: expiry,
                    staleAfter: staleAfter
                ))
                states.sort { $0.date < $1.date }
            }
        }

        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "cacheAfter "
                + WidgetWeatherRefreshDiagnostics.snapshotSummary(snapshot)
        )
        switch target {
        case .saved, .currentLocation:
            let cacheChanged = WidgetWeatherRefreshDiagnostics.cacheChanged(
                from: snapshotBeforeRefresh,
                to: snapshot
            )
            WidgetWeatherRefreshDiagnostics.log(
                "cacheChanged=\(cacheChanged)"
            )
        case .invalid:
            break
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
            forecast: forecast,
            states: states,
            reloadDate: reloadDate
        )
    }
}

/// In-memory presentation only; never passed to a cache writer or planner.
struct DPIPWidgetSnapshotContent: Sendable {
    let snapshot: CurrentWeatherWidgetSnapshot?
    let forecast: ForecastWidgetSnapshot?
}

enum DPIPWidgetGalleryPreview {
    /// Use a complete sample, rather than attaching invented forecast values
    /// to a real observation. Also used by Canvas and WidgetKit placeholders.
    static func sample(at date: Date) -> DPIPWidgetSnapshotContent {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        let hour = calendar.component(.hour, from: date)
        let isNight = hour < 6 || hour >= 18
        let transition = calendar.nextDate(
            after: date,
            matching: DateComponents(hour: isNight ? 6 : 18, minute: 0),
            matchingPolicy: .nextTime
        )!
        let nextHour = calendar.dateInterval(of: .hour, for: date)!.end
        let conditions: [(String, Int, Double, Int)] = [
            ("晴", 100, 28, 0),
            ("多雲", 200, 28, 10),
            ("多雲", 200, 27, 20),
            ("多雲有雨", 206, 27, 60),
            ("多雲有雨", 206, 26, 60),
        ]
        let points = conditions.enumerated().map { index, value in
            let pointDate = nextHour.addingTimeInterval(Double(index) * 3_600)
            let pointHour = calendar.component(.hour, from: pointDate)
            return ForecastWidgetPoint(
                time: String(format: "%02d:00", pointHour),
                temperature: value.2,
                weather: value.0,
                weatherCode: value.1,
                pop: value.3
            )!
        }
        let milliseconds = Int64(date.timeIntervalSince1970 * 1_000)
        return DPIPWidgetSnapshotContent(
            snapshot: CurrentWeatherWidgetSnapshot(
                schemaVersion: 7,
                sourceIdentifier: "region:407",
                regionCode: "407",
                regionName: String(localized: "widget.preview_location"),
                observationTime: Int(date.timeIntervalSince1970),
                stationName: "西屯",
                weather: "晴",
                weatherCode: 100,
                condition: .clear,
                isNight: isNight,
                nextDayNightTransitionTime: Int(transition.timeIntervalSince1970),
                calibratedTimeOffsetMilliseconds: 0,
                temperature: 28,
                humidity: 76,
                rain: 0,
                windDirection: "北北西",
                windSpeed: 1.3,
                apparentTemperature: 30
            ),
            forecast: ForecastWidgetSnapshot(
                sourceIdentifier: "region:407",
                regionCode: "407",
                updateTime: milliseconds,
                receivedAt: milliseconds,
                points: points
            )
        )
    }
}

struct DPIPWidgetProviderDependencies: Sendable {
    typealias LoadSnapshot = DPIPWidgetTimelinePlanner.LoadSnapshot
    typealias LoadForecast = DPIPWidgetTimelinePlanner.LoadForecast

    let loadSnapshot: LoadSnapshot
    let timelinePlanner: DPIPWidgetTimelinePlanner
    let loadForecast: LoadForecast

    init(loadSnapshot: @escaping LoadSnapshot,
         timelinePlanner: DPIPWidgetTimelinePlanner,
         loadForecast: @escaping LoadForecast = { _, _, _ in nil }) {
        self.loadSnapshot = loadSnapshot
        self.timelinePlanner = timelinePlanner
        self.loadForecast = loadForecast
    }

    func snapshot(
        for target: WidgetLocationTarget
    ) -> CurrentWeatherWidgetSnapshot? {
        loadSnapshot(target)
    }

    /// WidgetKit snapshots remain cache-only. The gallery fallback is selected
    /// here, outside getTimeline's planner and all persistence dependencies.
    func snapshotContent(
        for target: WidgetLocationTarget,
        at date: Date,
        family: WidgetFamily,
        isPreview: Bool
    ) -> DPIPWidgetSnapshotContent {
        let current = snapshot(for: target)
        let forecast = forecastSnapshot(
            for: target, currentSnapshot: current, at: date, family: family
        )
        let cached = DPIPWidgetSnapshotContent(snapshot: current, forecast: forecast)
        guard isPreview, target.sourceIdentifier != nil else { return cached }

        // Small has no forecast: only the current-weather half needs a sample,
        // and only when the cache holds nothing for this target.
        guard ForecastWidgetFamilyPolicy.supportsForecast(family) else {
            if let current, target.matches(snapshot: current) { return cached }
            return DPIPWidgetSnapshotContent(
                snapshot: DPIPWidgetGalleryPreview.sample(at: date).snapshot,
                forecast: nil
            )
        }

        if let current, target.matches(snapshot: current), let forecast,
           forecast.sourceIdentifier == target.sourceIdentifier,
           forecast.regionCode == current.regionCode,
           ForecastWidgetExpiry.isUsable(
               forecast, at: date,
               calibratedTimeOffsetMilliseconds:
                   current.calibratedTimeOffsetMilliseconds
           ), !ForecastWidgetFamilyPolicy.visiblePoints(
               in: forecast,
               at: CurrentWeatherWidgetTimeCalibration(snapshot: current)
                   .calibratedDate(fromDeviceDate: date),
               family: family
           ).isEmpty {
            return cached
        }
        return DPIPWidgetGalleryPreview.sample(at: date)
    }

    func forecastSnapshot(
        for target: WidgetLocationTarget,
        currentSnapshot: CurrentWeatherWidgetSnapshot?,
        at date: Date,
        family: WidgetFamily
    ) -> ForecastWidgetSnapshot? {
        guard ForecastWidgetFamilyPolicy.supportsForecast(family),
              let currentSnapshot,
              target.matches(snapshot: currentSnapshot) else { return nil }
        return loadForecast(target, currentSnapshot.regionCode, date)
    }
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
        let forecastStore = containerURL.map {
            ForecastWidgetSnapshotStore(containerURL: $0)
        }
        let loadForecast: DPIPWidgetTimelinePlanner.LoadForecast = {
            target, regionCode, date in
            guard let current = loadSnapshot(target),
                  current.regionCode == regionCode else { return nil }
            return forecastStore?.load(
                for: target,
                regionCode: regionCode,
                at: date,
                calibratedTimeOffsetMilliseconds:
                    current.calibratedTimeOffsetMilliseconds
            )
        }
        let forecastClient = ForecastClient()
        let forecastRefresh = ForecastWidgetRefreshService(
            fetch: { regionCode in
                try await forecastClient.fetch(regionCode: regionCode)
            },
            loadCurrent: loadSnapshot,
            savedIsResolved: { target in
                guard let containerURL else { return false }
                let catalog = WidgetLocationCatalogStore(
                    containerURL: containerURL
                ).load()
                return SavedWidgetLocationResolver(
                    catalog: catalog
                ).resolve(target: target) != nil
            },
            write: { snapshot, target in
                guard let forecastStore else { return false }
                return try forecastStore.write(snapshot, for: target)
            },
            now: { Date.now }
        )

        let weatherClient = CurrentWeatherClient()
        let serverClock = WidgetServerClock()
        let writer = containerURL.map {
            CurrentWeatherWidgetSnapshotWriter(containerURL: $0)
        }
        let refreshSaved: DPIPWidgetTimelinePlanner.RefreshSaved = { target in
            guard let containerURL, let writer else {
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
                clock: serverClock,
                writer: writer
            )

            return await service.refresh(target: target)
        }
        let refreshCurrent: DPIPWidgetTimelinePlanner.RefreshCurrent = {
            guard let writer else {
                #if DEBUG
                WidgetWeatherRefreshDiagnostics.log(
                    "current location refresh unavailable "
                        + "appGroupContainer=false"
                )
                #endif
                return .unavailable
            }
            guard let resolver =
                WidgetTownshipResolverRuntime.shared
            else {
                #if DEBUG
                WidgetWeatherRefreshDiagnostics.log(
                    "township resolver unavailable"
                )
                #endif
                return .unavailable
            }

            let service =
                CurrentLocationCurrentWeatherWidgetRefreshService(
                    acquireLocation: { @MainActor in
                        await WidgetCurrentLocationClient()
                            .acquireLocation()
                    },
                    resolver: resolver,
                    weatherClient: weatherClient,
                    clock: serverClock,
                    writer: writer
                )
            return await service.refresh()
        }

        return DPIPWidgetProviderDependencies(
            loadSnapshot: loadSnapshot,
            timelinePlanner: DPIPWidgetTimelinePlanner(
                staleAfter: staleAfter,
                refreshInterval: refreshInterval,
                loadSnapshot: loadSnapshot,
                refreshSaved: refreshSaved,
                refreshCurrent: refreshCurrent,
                loadForecast: loadForecast,
                refreshForecast: { target, regionCode in
                    await forecastRefresh.refresh(
                        target: target, regionCode: regionCode
                    )
                },
                now: { Date.now }
            ),
            loadForecast: loadForecast
        )
    }()
}

#if DEBUG
private extension CurrentWeatherWidgetRefreshResult {
    var diagnosticName: String {
        switch self {
        case .refreshed:
            return "refreshed"
        case .superseded:
            return "superseded"
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
