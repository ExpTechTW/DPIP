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
    /// - Parameter observationTime: Current Weather's Unix seconds, already in
    ///   the calibrated domain. Forecast publication is never a selector.
    static func visiblePoints(
        in forecast: ForecastWidgetSnapshot,
        at calibratedDate: Date,
        observationTime: Int?,
        family: WidgetFamily
    ) -> [ForecastWidgetPoint] {
        guard supportsForecast(family) else { return [] }
        return ForecastWidgetSelection.upcomingPoints(
            forecast.points, at: calibratedDate,
            observationTime: observationTime, limit: 5
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
}
#endif

/// In-memory presentation only; never passed to a cache writer or planner.
struct DPIPWidgetSnapshotContent: Sendable {
    let snapshot: CurrentWeatherWidgetSnapshot?
    let forecast: ForecastWidgetSnapshot?
    var rain: RainTrendWidgetSnapshot? = nil
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
    typealias LoadRain = DPIPWidgetTimelinePlanner.LoadRain

    let loadSnapshot: LoadSnapshot
    let timelinePlanner: DPIPWidgetTimelinePlanner
    let loadForecast: LoadForecast
    let loadRain: LoadRain

    init(loadSnapshot: @escaping LoadSnapshot,
         timelinePlanner: DPIPWidgetTimelinePlanner,
         loadForecast: @escaping LoadForecast = { _, _, _ in nil },
         loadRain: @escaping LoadRain = { _, _ in nil }) {
        self.loadSnapshot = loadSnapshot
        self.timelinePlanner = timelinePlanner
        self.loadForecast = loadForecast
        self.loadRain = loadRain
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
        var rain: RainTrendWidgetSnapshot?
        if ForecastWidgetFamilyPolicy.supportsForecast(family),
           let current, target.matches(snapshot: current) {
            rain = loadRain(target, current.regionCode)
        }
        let cached = DPIPWidgetSnapshotContent(
            snapshot: current, forecast: forecast, rain: rain
        )
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
               observationTime: current.observationTime,
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
    private static let staleAfter = CurrentWeatherWidgetTimeline.defaultStaleAfter

    // A failed refresh retries after `retryInterval`, and each further
    // failure in a row waits that much longer, up to `refreshInterval`.
    #if DEBUG
    static let refreshInterval: TimeInterval = 60
    static let retryInterval: TimeInterval = 60
    #else
    static let refreshInterval: TimeInterval = 30 * 60
    static let retryInterval: TimeInterval = 10 * 60
    #endif

    // One dependency graph per extension process, so every getTimeline the
    // process handles shares one server clock and its anchor.
    static let shared: DPIPWidgetProviderDependencies = {
        let store = WidgetTargetStore.appGroup()
        let loadSnapshot: DPIPWidgetTimelinePlanner.LoadSnapshot = { target in
            store?.loadCurrent(for: target)
        }
        let loadRain: DPIPWidgetTimelinePlanner.LoadRain = { target, regionCode in
            store?.loadRain(for: target, regionCode: regionCode)
        }
        let loadForecast: DPIPWidgetTimelinePlanner.LoadForecast = {
            target, regionCode, date in
            guard let store,
                  let current = store.loadCurrent(for: target),
                  current.regionCode == regionCode
            else {
                return nil
            }
            return store.loadForecast(
                for: target,
                regionCode: regionCode,
                at: date,
                calibratedTimeOffsetMilliseconds:
                    current.calibratedTimeOffsetMilliseconds
            )
        }
        let refresher = store.map {
            WidgetRefresher(
                store: $0,
                dependencies: .live(containerURL: $0.containerURL)
            )
        }

        return DPIPWidgetProviderDependencies(
            loadSnapshot: loadSnapshot,
            timelinePlanner: DPIPWidgetTimelinePlanner(
                builder: WidgetTimelineBuilder(
                    staleAfter: staleAfter,
                    refreshInterval: refreshInterval,
                    retryInterval: retryInterval
                ),
                loadSnapshot: loadSnapshot,
                loadForecast: loadForecast,
                loadRain: loadRain,
                refresh: { target, family in
                    guard let refresher else {
                        #if DEBUG
                        WidgetWeatherRefreshDiagnostics.log(
                            "refresh unavailable appGroupContainer=false"
                        )
                        #endif
                        return .unavailable
                    }
                    return await refresher.refresh(target: target, family: family)
                },
                recordOutcome: { target, outcome in
                    store?.recordRefreshOutcome(outcome, for: target)
                        ?? WidgetRefreshFailures.count(after: outcome, following: 0)
                },
                now: { Date.now }
            ),
            loadForecast: loadForecast,
            loadRain: loadRain
        )
    }()
}

extension WidgetRefresher.Dependencies {
    static func live(containerURL: URL) -> Self {
        let weatherClient = CurrentWeatherClient()
        let forecastClient = ForecastClient()
        let rainClient = RainTrendClient()
        let clock = WidgetServerClock(
            anchorStore: WidgetFileClockAnchorStore(containerURL: containerURL)
        )
        return Self(
            resolveSaved: { target in
                SavedWidgetLocationResolver(
                    catalog: WidgetLocationCatalogStore(
                        containerURL: containerURL
                    ).load()
                ).resolve(target: target)
            },
            isRemoved: { target in
                SavedWidgetLocationResolver(
                    catalog: WidgetLocationCatalogStore(
                        containerURL: containerURL
                    ).load()
                ).isRemoved(target: target)
            },
            acquireCurrentLocation: { @MainActor in
                await WidgetCurrentLocationClient().acquireLocation()
            },
            resolveTownship: { location in
                WidgetTownshipResolverRuntime.shared?.resolve(location)
            },
            fetchWeather: { latitude, longitude in
                try await weatherClient.fetch(
                    latitude: latitude, longitude: longitude
                )
            },
            fetchForecast: { regionCode in
                try await forecastClient.fetch(regionCode: regionCode)
            },
            fetchRain: { regionCode, now in
                try await rainClient.fetch(regionCode: regionCode, now: now)
            },
            synchronizeClock: { _ = await clock.synchronize() },
            sampleClock: { await clock.currentWeatherSnapshotTime() },
            now: { Date.now }
        )
    }
}
