import WidgetKit
import SwiftUI
import Intents
import AppIntents

struct DPIPWidgetProvider: IntentTimelineProvider {
    typealias Intent = WeatherWidgetConfigurationIntent
    private let staleAfter = CurrentWeatherWidgetTimeline.defaultStaleAfter
    private let dependencies: DPIPWidgetProviderDependencies

    init(
        dependencies: DPIPWidgetProviderDependencies =
            DPIPWidgetProviderRuntime.shared
    ) {
        self.dependencies = dependencies
    }

    func placeholder(in context: Context) -> DPIPWidgetEntry {
        let date = Date.now
        let sample = DPIPWidgetGalleryPreview.sample(at: date)
        let content = DPIPWidgetSnapshotContent(
            snapshot: sample.snapshot,
            forecast: ForecastWidgetFamilyPolicy.supportsForecast(context.family)
                ? sample.forecast : nil
        )
        return DPIPWidgetEntry(
            date: date,
            snapshot: content.snapshot,
            isStale: false,
            isNight: content.snapshot?.isNight ?? false,
            forecast: content.forecast
        )
    }

    func getSnapshot(
        for configuration: WeatherWidgetConfigurationIntent,
        in context: Context,
        completion: @escaping (DPIPWidgetEntry) -> Void
    ) {
        let deviceNow = Date.now
        let target = WidgetLocationTarget(
            identifier: configuration.location?.identifier
        )

        let content = dependencies.snapshotContent(
            for: target,
            at: deviceNow,
            family: context.family,
            isPreview: context.isPreview
        )
        let snapshot = content.snapshot

        let state = CurrentWeatherWidgetTimeline.state(
            snapshot: snapshot,
            at: deviceNow,
            staleAfter: staleAfter
        )

        let entry = DPIPWidgetEntry(
            date: state.date,
            snapshot: snapshot,
            isStale: state.isStale,
            isNight: state.isNight,
            forecast: content.forecast,
            locationTarget: target
        )

        completion(entry)
    }

    func getTimeline(
        for configuration: WeatherWidgetConfigurationIntent,
        in context: Context,
        completion: @escaping (Timeline<DPIPWidgetEntry>) -> Void
    ) {
        let target = WidgetLocationTarget(
            identifier: configuration.location?.identifier
        )

        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "getTimeline target="
                + WidgetWeatherRefreshDiagnostics.targetIdentifier(target)
        )
        switch target {
        case .saved(let regionCode):
            WidgetWeatherRefreshDiagnostics.log(
                "target=saved region=\(regionCode)"
            )
        case .currentLocation:
            WidgetWeatherRefreshDiagnostics.log(
                "target=current-location nativeRefresh=enabled "
                    + "cacheReload=enabled"
            )
        case .invalid:
            WidgetWeatherRefreshDiagnostics.log("target=invalid")
        }
        #endif

        Task {
            let plan = await dependencies.timelinePlanner.plan(
                for: target,
                family: context.family
            )
            let entries = plan.states.map { state in
                DPIPWidgetEntry(
                    date: state.date,
                    snapshot: plan.snapshot,
                    isStale: state.isStale,
                    isNight: state.isNight,
                    forecast: plan.forecast(at: state.date),
                    locationTarget: target
                )
            }

            completion(
                Timeline(
                    entries: entries,
                    policy: .after(plan.reloadDate)
                )
            )
        }
    }
}

/// - Parameter calibratedDate: a calibrated instant, never a WidgetKit entry
///   date. `nextTransitionTime` is published in the calibrated domain, so
///   subtracting a device-clock date here would yield the calibration offset
///   rather than the time remaining.
private func forecastIsNight(
    pointTime: String,
    calibratedDate: Date,
    isCurrentlyNight: Bool,
    nextTransitionTime: Int
) -> Bool {
    guard let minutesAhead = ForecastWidgetSelection.minutesAhead(
        for: pointTime, at: calibratedDate
    ) else {
        return isCurrentlyNight
    }

    let transitionDate = Date(
        timeIntervalSince1970: TimeInterval(nextTransitionTime)
    )

    let minutesUntilTransition =
        transitionDate.timeIntervalSince(calibratedDate) / 60

    guard minutesUntilTransition >= 0 else {
        return isCurrentlyNight
    }

    if Double(minutesAhead) < minutesUntilTransition {
        return isCurrentlyNight
    }

    return !isCurrentlyNight
}

// All weather families show the source observation time beside current weather.
// Using the WidgetKit entry or render time would make stale data look fresh.
struct SmallCurrentWeatherView: View {
    let entry: DPIPWidgetEntry
    var localizationBundle: Bundle = .main

    var body: some View {
        if let snapshot = entry.snapshot {
            let observationDate = Date(
                timeIntervalSince1970: TimeInterval(snapshot.observationTime)
            )

            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(snapshot.regionName)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .layoutPriority(1)

                            if snapshot.sourceIdentifier == "current-location" {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .fixedSize()
                            }
                        }

                        Text(observationDate, style: .time)
                            .lineLimit(1)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 2) {
                        Image(systemName: snapshot.presentationCondition.systemImageName(
                            isNight: entry.isNight
                        ))
                        .font(.title)

                        Text(snapshot.presentationCondition.localizedDisplayName, bundle: localizationBundle)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if let temperature = snapshot.temperature {
                    Text("\(temperature, specifier: "%.0f")°")
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                } else {
                    Text("--°")
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                }

                HStack {
                    if let humidity = snapshot.humidity {
                        HStack(spacing: 4) {
                            Image(systemName: "humidity")
                            Text("\(humidity)%")
                        }
                        .font(.caption)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "humidity")
                            Text("--%")
                        }
                        .font(.caption)
                    }

                    Spacer()

                    if let rain = snapshot.rain {
                        HStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                            Text("\(rain, specifier: "%.1f") mm")
                        }
                        .font(.caption)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                            Text("-- mm")
                        }
                        .font(.caption)
                    }
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "cloud.fill")
                    .font(.title)

                Text("widget.no_weather_data", bundle: localizationBundle)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
    }
}

struct MediumCurrentWeatherView: View {
    let entry: DPIPWidgetEntry
    var localizationBundle: Bundle = .main

    var body: some View {
        CurrentWeatherWidgetContent(entry: entry, family: .systemMedium, localizationBundle: localizationBundle)
    }
}

struct LargeCurrentWeatherView: View {
    let entry: DPIPWidgetEntry
    var localizationBundle: Bundle = .main

    var body: some View {
        CurrentWeatherWidgetContent(entry: entry, family: .systemLarge, localizationBundle: localizationBundle)
    }
}

private struct CurrentWeatherWidgetContent: View {
    let entry: DPIPWidgetEntry
    let family: WidgetFamily
    let localizationBundle: Bundle

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                WeatherWidgetLayout(entry: entry, snapshot: snapshot, family: family,
                                    localizationBundle: localizationBundle)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "cloud.fill").font(.title)
                    Text("widget.no_weather_data", bundle: localizationBundle)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity,
               alignment: entry.snapshot == nil ? .center : .topLeading)
    }
}

/// Measure complete layouts against the card's *content* area. A stack
/// measured after compression can fit geometrically while clipping glyphs.
private struct WeatherWidgetLayout: View {
    let entry: DPIPWidgetEntry
    let snapshot: CurrentWeatherWidgetSnapshot
    let family: WidgetFamily
    let localizationBundle: Bundle

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isMedium: Bool { family == .systemMedium }
    private var calibratedDate: Date {
        CurrentWeatherWidgetTimeCalibration(snapshot: snapshot).calibratedDate(fromDeviceDate: entry.date)
    }
    private var transitionDate: Date {
        Date(timeIntervalSince1970: TimeInterval(snapshot.nextDayNightTransitionTime))
    }
    private var showsWarning: Bool {
        entry.forecastFreshness == .stale && !entry.upcomingForecastPoints(for: family).isEmpty
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            if isMedium {
                ViewThatFits(in: .vertical) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        regular(tight: false)
                        regular(tight: true)
                    }
                    adaptive(detailLimit: 0, showsApparentTemperature: true)
                    // Keep the approved regular candidates intact. Only AX
                    // sizes can trade secondary content for vertical space.
                    if dynamicTypeSize.isAccessibilitySize {
                        adaptive(detailLimit: 0, showsApparentTemperature: false)
                        adaptive(detailLimit: 0, showsApparentTemperature: false, tight: true)
                    }
                }
            } else {
                ViewThatFits(in: .vertical) {
                    if dynamicTypeSize <= .xLarge {
                        regular(tight: false)
                        regular(tight: true)
                    }
                    adaptive(detailLimit: 5, showsApparentTemperature: true)
                    adaptive(detailLimit: 5, showsApparentTemperature: false)
                    adaptive(detailLimit: 4, showsApparentTemperature: false)
                    adaptive(detailLimit: 3, showsApparentTemperature: false)
                    adaptive(detailLimit: 2, showsApparentTemperature: false)
                    adaptive(detailLimit: 1, showsApparentTemperature: false)
                    adaptive(detailLimit: 0, showsApparentTemperature: false)
                }
            }
        } else if dynamicTypeSize <= .large {
            regular(tight: true)
        } else {
            // iOS 15 has no ViewThatFits or interactive widget button.
            adaptive(detailLimit: isMedium ? 0 : 3, showsApparentTemperature: false, tight: isMedium)
        }
    }

    private func regular(tight: Bool) -> some View {
        VStack(alignment: .leading, spacing: tight ? (isMedium ? 2 : 4) : (isMedium ? 6 : 12)) {
            header(adaptive: false)
            regularCurrentWeather

            if !isMedium { Spacer(minLength: tight ? 0 : nil) }
            forecast
            if !isMedium {
                Spacer(minLength: tight ? 0 : nil)
                detailGrid(tight: tight)
            }
        }
    }

    private func adaptive(detailLimit: Int, showsApparentTemperature: Bool, tight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: tight ? 2 : 4) {
            header(adaptive: dynamicTypeSize.isAccessibilitySize)
                .dynamicTypeSize(...(tight ? DynamicTypeSize.large : .accessibility1))
            adaptiveCurrentWeather(showsApparentTemperature: showsApparentTemperature, tight: tight)
                .dynamicTypeSize(...(tight ? DynamicTypeSize.large : .accessibility1))
            // Center the forecast between current weather and details
            // at larger Dynamic Type sizes.
            if !isMedium && dynamicTypeSize >= .xxLarge && detailLimit > 0 {
                Spacer(minLength: 0)
            }

            if tight && dynamicTypeSize.isAccessibilitySize {
                forecastContent(compactAccessibility: true)
            } else {
                forecast
            }

            if detailLimit > 0 {
                Spacer(minLength: 0)
                detailRows(limit: detailLimit)
                    .font(.caption2)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
    }

    private func header(adaptive: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: adaptive ? 4 : nil) {
            HStack(spacing: 4) {
                Text(snapshot.regionName)
                    .font(isMedium && !dynamicTypeSize.isAccessibilitySize
                          ? .subheadline.weight(.semibold)
                          : .headline
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1)
                if snapshot.sourceIdentifier == "current-location" {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
            Spacer(minLength: adaptive ? 0 : (isMedium ? 6 : nil))
            HStack(alignment: .firstTextBaseline, spacing: adaptive ? 4 : 6) {
                if showsWarning {
                    if !adaptive, #available(iOS 16.0, *) {
                        ViewThatFits(in: .horizontal) {
                            Text("widget.forecast_outdated", bundle: localizationBundle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: true, vertical: false)
                            warningIcon(adaptive: false)
                        }
                    } else {
                        warningIcon(adaptive: adaptive)
                    }
                }
                Text(Date(timeIntervalSince1970: TimeInterval(snapshot.observationTime)), style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            // The clock always takes its ideal width. In the adaptive header,
            // reserve the whole icon-and-clock group before offering space to
            // the location; keeping only the Text fixed can still overflow.
            .layoutPriority(adaptive ? 1 : 0)
        }
    }

    private func warningIcon(adaptive: Bool) -> some View {
        Image(systemName: "exclamationmark.triangle")
            .font(adaptive ? .caption2 : .system(size: 12))
            .foregroundStyle(.secondary)
            .fixedSize()
            .accessibilityLabel(Text("widget.forecast_outdated", bundle: localizationBundle))
    }

    private var forecast: some View {
        forecastContent(compactAccessibility: false)
    }

    private func forecastContent(compactAccessibility: Bool) -> some View {
        HourlyForecastSection(
            entry: entry, family: family, calibratedDate: calibratedDate,
            isCurrentlyNight: entry.isNight, nextTransitionTime: snapshot.nextDayNightTransitionTime,
            localizationBundle: localizationBundle, compactAccessibility: compactAccessibility
        )
    }

    @ViewBuilder
    private var regularCurrentWeather: some View {
        if isMedium {
        HStack(alignment: .center) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                if let temperature = snapshot.temperature {
                    Text("\(temperature, specifier: "%.0f")°")
                        .font(.system(
                            size: 38,
                            weight: .semibold,
                            design: .rounded
                        ))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("—°")
                        .font(.system(
                            size: 38,
                            weight: .semibold,
                            design: .rounded
                        ))
                        .foregroundStyle(.secondary)
                }

                if let apparentTemperature = snapshot.apparentTemperature {
                    HStack(spacing: 4) {
                        Text("widget.feels_like", bundle: localizationBundle)
                        Text("\(apparentTemperature, specifier: "%.0f")°")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: snapshot.presentationCondition.systemImageName(
                    isNight: entry.isNight
                ))
                    .font(.title2)

                Text(snapshot.presentationCondition.localizedDisplayName, bundle: localizationBundle)
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.secondary)
        }
        } else {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                if let temperature = snapshot.temperature {
                    Text("\(temperature, specifier: "%.0f")°")
                        .font(.system(
                            size: 42,
                            weight: .semibold,
                            design: .rounded
                        ))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("—°")
                        .font(.system(
                            size: 42,
                            weight: .semibold,
                            design: .rounded
                        ))
                        .foregroundStyle(.secondary)
                }

                if let apparentTemperature = snapshot.apparentTemperature {
                    HStack(spacing: 4) {
                        Text("widget.feels_like", bundle: localizationBundle)
                        Text("\(apparentTemperature, specifier: "%.0f")°")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: snapshot.presentationCondition.systemImageName(
                    isNight: entry.isNight
                ))
                    .font(.title)

                Text(snapshot.presentationCondition.localizedDisplayName, bundle: localizationBundle)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.secondary)
        }
        }
    }

    @ViewBuilder
    private func adaptiveCurrentWeather(showsApparentTemperature: Bool, tight: Bool) -> some View {
        if #available(iOS 16.0, *), showsApparentTemperature, snapshot.apparentTemperature != nil {
            ViewThatFits(in: .horizontal) {
                adaptiveCurrentWeatherRow(showsApparentTemperature: true, tight: tight)
                adaptiveCurrentWeatherRow(showsApparentTemperature: false, tight: tight)
            }
        } else {
            adaptiveCurrentWeatherRow(showsApparentTemperature: false, tight: tight)
        }
    }

    private func adaptiveCurrentWeatherRow(showsApparentTemperature: Bool, tight: Bool) -> some View {
        HStack(spacing: 8) {
            Group {
                if let temperature = snapshot.temperature {
                    Text("\(temperature, specifier: "%.0f")°")
                } else {
                    Text("—°").foregroundStyle(.secondary)
                }
            }
            .font(.system(size: isMedium ? 38 : 42, weight: .semibold, design: .rounded))
            .fixedSize()

            if showsApparentTemperature, let apparentTemperature = snapshot.apparentTemperature {
                VStack(alignment: .leading, spacing: 0) {
                    Text("widget.feels_like", bundle: localizationBundle)
                    Text("\(apparentTemperature, specifier: "%.0f")°")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize()
                .accessibilityElement(children: .combine)
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: snapshot.presentationCondition.systemImageName(isNight: entry.isNight))
                    .font(.system(size: isMedium ? 20 : 24))
                    .accessibilityHidden(true)
                Text(snapshot.presentationCondition.localizedDisplayName, bundle: localizationBundle)
                    .font(.caption)
                    .lineLimit(2)
            }
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize || showsApparentTemperature,
                       vertical: false)
            .layoutPriority(1)
        }
    }

    private func detailGrid(tight: Bool) -> some View {
        VStack(alignment: .leading, spacing: tight ? 6 : 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("widget.humidity", bundle: localizationBundle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let humidity = snapshot.humidity {
                        Text("\(humidity)%")
                            .font(.caption)
                            .fontWeight(.medium)
                    } else {
                        Text("--%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("widget.rainfall", bundle: localizationBundle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let rain = snapshot.rain {
                        Text("\(rain, specifier: "%.1f") mm")
                            .font(.caption)
                            .fontWeight(.medium)
                    } else {
                        Text("-- mm")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.isNight ? "widget.sunrise" : "widget.sunset", bundle: localizationBundle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(transitionDate, style: .time)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("widget.wind", bundle: localizationBundle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let windSpeed = snapshot.windSpeed {
                        HStack(spacing: 4) {
                            if let direction = snapshot.presentationWindDirection {
                                Text(direction.localizedDisplayName, bundle: localizationBundle)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            } else if let windDirection = snapshot.windDirection {
                                Text(windDirection)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }

                            Text("\(windSpeed, specifier: "%.1f") m/s")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    } else if let windDirection = snapshot.windDirection {
                        Text(windDirection)
                            .font(.caption)
                            .fontWeight(.medium)
                    } else {
                        Text("--")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("widget.station", bundle: localizationBundle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(snapshot.stationName.isEmpty ? "--" : snapshot.stationName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func detailRows(limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if limit >= 1 {
                detail("widget.humidity") {
                    Text(snapshot.humidity.map { "\($0)%" } ?? "--%")
                }
            }
            if limit >= 2 {
                detail("widget.rainfall") {
                    if let rain = snapshot.rain {
                        Text("\(rain, specifier: "%.1f") mm")
                    } else {
                        Text("-- mm")
                    }
                }
            }
            if limit >= 3 {
                detail(entry.isNight ? "widget.sunrise" : "widget.sunset") {
                    Text(Date(timeIntervalSince1970: TimeInterval(snapshot.nextDayNightTransitionTime)), style: .time)
                }
            }
            if limit >= 4 {
                detail("widget.wind") {
                    HStack(spacing: 4) {
                        if let direction = snapshot.presentationWindDirection {
                            Text(direction.localizedDisplayName, bundle: localizationBundle)
                        } else if let direction = snapshot.windDirection {
                            Text(direction)
                        }
                        if let speed = snapshot.windSpeed {
                            Text("\(speed, specifier: "%.1f") m/s")
                        } else if snapshot.windDirection == nil {
                            Text("--")
                        }
                    }
                }
            }
            if limit >= 5 {
                detail("widget.station") {
                    Text(snapshot.stationName.isEmpty ? "--" : snapshot.stationName)
                        .lineLimit(1)
                }
            }
        }
    }

    private func detail<Value: View>(
        _ key: LocalizedStringKey, @ViewBuilder value: () -> Value
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(key, bundle: localizationBundle)
                .foregroundStyle(.secondary)
                .fixedSize()
            Spacer(minLength: 0)
            value()
                .font(.caption2.weight(.medium))
                .lineLimit(1)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

struct HourlyForecastPointView: View {
    let point: ForecastWidgetPoint
    let compact: Bool
    let isNight: Bool
    var localizationBundle: Bundle = .main
    var compactAccessibility = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            column.accessibilityElement(children: .combine)
        } else {
            column
        }
    }

    private var column: some View {
        // The fixed card always presents the same five forecast slots.
        // Bound the supporting typography so each slot can keep all four
        // values in their original vertical order at every widget text size.
        VStack(spacing: compactAccessibility ? 0 : (compact ? 2 : 4)) {
            Text(point.time)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(.secondary)

            Image(systemName: point.presentationCondition.systemImageName(isNight: isNight))
                .font(compactAccessibility ? .body : (compact ? .title3 : .title2))
                .frame(height: compactAccessibility ? 18 : (compact ? 25 : 36))
                .accessibilityLabel(Text(point.presentationCondition.localizedDisplayName, bundle: localizationBundle))

            Text("\(point.temperature, specifier: "%.0f")°")
                .font(compact ? .caption : .subheadline)
                .fontWeight(.semibold)

            Text(point.pop.map { "\($0)%" } ?? "—")
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(point.pop == nil ? .tertiary : .secondary)
        }
        .lineLimit(1)
        .dynamicTypeSize(...DynamicTypeSize.large)
    }
}

struct HourlyForecastSection: View {
    let entry: DPIPWidgetEntry
    let family: WidgetFamily

    /// Calibrated, not the WidgetKit entry date: API clock labels are Taipei
    /// wall-clock readings of calibrated time.
    let calibratedDate: Date
    let isCurrentlyNight: Bool
    let nextTransitionTime: Int
    var localizationBundle: Bundle = .main
    var compactAccessibility = false

    var body: some View {
        let points = entry.upcomingForecastPoints(for: family)
        if !points.isEmpty, entry.forecastFreshness == .stale {
            HStack(spacing: 4) {
                forecastContent(points: points)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .forecastInvalidatableContent()
                refreshButton
            }
        } else if !points.isEmpty {
            forecastContent(points: points)
        } else if ForecastWidgetFamilyPolicy.supportsForecast(family) {
            unavailableContent
                .font(.caption)
                .foregroundStyle(.secondary)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func forecastContent(points: [ForecastWidgetPoint]) -> some View {
        let compact = family == .systemMedium
        return HStack(alignment: .top, spacing: compact ? 4 : 8) {
            // Stateless display slots can contain repeated API clock labels.
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                HourlyForecastPointView(
                    point: point, compact: compact,
                    isNight: forecastIsNight(
                        pointTime: point.time, calibratedDate: calibratedDate,
                        isCurrentlyNight: isCurrentlyNight, nextTransitionTime: nextTransitionTime
                    ),
                    localizationBundle: localizationBundle,
                    compactAccessibility: compactAccessibility
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var unavailableContent: some View {
        if #available(iOS 17.0, *),
           entry.forecastRefreshIdentifier(for: family) != nil {
            HStack(spacing: 4) {
                unavailableLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .forecastInvalidatableContent()
                refreshButton
            }
        } else {
            unavailableLabel
        }
    }

    @ViewBuilder
    private var refreshButton: some View {
        if #available(iOS 17.0, *),
           let identifier = entry.forecastRefreshIdentifier(for: family) {
            Button(intent: RefreshForecastIntent(locationIdentifier: identifier)) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("widget.refresh_forecast", bundle: localizationBundle))
            .accessibilityHint(Text("widget.refresh_forecast_hint", bundle: localizationBundle))
        }
    }

    @ViewBuilder
    private var unavailableLabel: some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                Text("widget.hourly_forecast_unavailable", bundle: localizationBundle)
                    .fixedSize()
                compactUnavailableLabel
            }
        } else {
            compactUnavailableLabel
        }
    }

    private var compactUnavailableLabel: some View {
        Text("widget.forecast_unavailable", bundle: localizationBundle)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

private extension View {
    @ViewBuilder
    func forecastInvalidatableContent() -> some View {
        if #available(iOS 17.0, *) {
            invalidatableContent()
        } else {
            self
        }
    }
}

struct DPIPWidgetsEntryView : View {
    @Environment(\.widgetFamily) private var family

    let entry: DPIPWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCurrentWeatherView(entry: entry)

        case .systemMedium:
            MediumCurrentWeatherView(entry: entry)

        case .systemLarge:
            LargeCurrentWeatherView(entry: entry)

        default:
            SmallCurrentWeatherView(entry: entry)
        }
    }
}

struct DPIPWidgets: Widget {
    let kind: String = "DPIPWidgets"

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: WeatherWidgetConfigurationIntent.self,
            provider: DPIPWidgetProvider()
        ) { entry in
            if #available(iOS 17.0, *) {
                DPIPWidgetsEntryView(entry: entry)
                    .widgetURL(entry.widgetURL)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DPIPWidgetsEntryView(entry: entry)
                    .widgetURL(entry.widgetURL)
                    .padding()
                    .background()
            }
        }
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
        .configurationDisplayName("widget.current_weather")
        .description("widget.current_weather_description")
    }
}

struct DPIPWidgets_Previews: PreviewProvider {
    private static let previewNow = Date()

    private static let previewContent = DPIPWidgetGalleryPreview.sample(at: previewNow)

    private static let previewEntry = DPIPWidgetEntry(
        date: previewNow,
        snapshot: previewContent.snapshot,
        isStale: false,
        isNight: previewContent.snapshot?.isNight ?? false,
        forecast: previewContent.forecast
    )

    private static let noForecastPreviewEntry = DPIPWidgetEntry(
        date: previewEntry.date,
        snapshot: previewEntry.snapshot,
        isStale: previewEntry.isStale,
        isNight: previewEntry.isNight,
        forecast: nil,
        locationTarget: previewEntry.locationTarget
    )

    private static let noWeatherDataEntry = DPIPWidgetEntry(
        date: previewNow,
        snapshot: nil,
        isStale: false,
        isNight: false,
        forecast: nil
    )

    private static let stalePreviewEntry: DPIPWidgetEntry? = {
        guard let snapshot = previewContent.snapshot,
              let forecast = previewContent.forecast else {
            return nil
        }

        // Convert the forecast publication time to device-clock time.
        let publicationDate = Date(
            timeIntervalSince1970:
                TimeInterval(forecast.updateTime) / 1_000
        ).addingTimeInterval(
            -TimeInterval(snapshot.calibratedTimeOffsetMilliseconds) / 1_000
        )

        // 45 minutes after publication: expected .stale.
        let staleDate = publicationDate.addingTimeInterval(45 * 60)

        return DPIPWidgetEntry(
            date: staleDate,
            snapshot: snapshot,
            isStale: false,
            isNight: snapshot.isNight,
            forecast: forecast
        )
    }()

    private static let expiredPreviewEntry: DPIPWidgetEntry? = {
        guard let base = stalePreviewEntry else {
            return nil
        }

        // The stale fixture is 45 minutes after publication.
        // Advance another 80 minutes to reach 125 minutes.
        let expiredDate = base.date.addingTimeInterval(80 * 60)

        return DPIPWidgetEntry(
            date: expiredDate,
            snapshot: base.snapshot,
            isStale: base.isStale,
            isNight: base.isNight,
            forecast: base.forecast,
            locationTarget: base.locationTarget
        )
    }()

    private static let longRegionStaleEntry: DPIPWidgetEntry? = {
        guard let base = stalePreviewEntry,
              let snapshot = base.snapshot else {
            return nil
        }

        let longRegionSnapshot = CurrentWeatherWidgetSnapshot(
            schemaVersion: snapshot.schemaVersion,
            sourceIdentifier: snapshot.sourceIdentifier,
            regionCode: snapshot.regionCode,
            regionName: "臺中市西屯區臺灣大道三段",
            observationTime: snapshot.observationTime,
            stationName: snapshot.stationName,
            weather: snapshot.weather,
            weatherCode: snapshot.weatherCode,
            condition: snapshot.condition,
            isNight: snapshot.isNight,
            nextDayNightTransitionTime: snapshot.nextDayNightTransitionTime,
            calibratedTimeOffsetMilliseconds:
                snapshot.calibratedTimeOffsetMilliseconds,
            temperature: snapshot.temperature,
            humidity: snapshot.humidity,
            rain: snapshot.rain,
            windDirection: snapshot.windDirection,
            windSpeed: snapshot.windSpeed,
            apparentTemperature: snapshot.apparentTemperature
        )

        return DPIPWidgetEntry(
            date: base.date,
            snapshot: longRegionSnapshot,
            isStale: base.isStale,
            isNight: base.isNight,
            forecast: base.forecast,
            locationTarget: base.locationTarget
        )
    }()

    private static let missingOptionalDataEntry = DPIPWidgetEntry(
        date: previewNow,
        snapshot: CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: "region:407",
            regionCode: "407",
            regionName: String(localized: "widget.preview_location"),
            observationTime: Int(previewNow.timeIntervalSince1970),
            stationName: "西屯",
            weather: "多雲",
            weatherCode: 200,
            condition: .cloudy,
            isNight: previewContent.snapshot!.isNight,
            nextDayNightTransitionTime: previewContent.snapshot!.nextDayNightTransitionTime,
            calibratedTimeOffsetMilliseconds: 0,
            temperature: 28.0,
            humidity: 76,
            rain: 0.0,
            windDirection: nil,
            windSpeed: nil,
            apparentTemperature: nil,
        ),
        isStale: false,
        isNight: previewContent.snapshot!.isNight,
        forecast: previewContent.forecast
    )

    @ViewBuilder
    private static func previewView(
        entry: DPIPWidgetEntry
    ) -> some View {
        if #available(iOS 17.0, *) {
            DPIPWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            DPIPWidgetsEntryView(entry: entry)
                .padding()
                .background()
        }
    }

    static var previews: some View {
        Group {
            previewView(entry: previewEntry)
                .previewDisplayName("Small")
                .previewContext(
                    WidgetPreviewContext(family: .systemSmall)
                )

            previewView(entry: previewEntry)
                .previewDisplayName("Medium")
                .previewContext(
                    WidgetPreviewContext(family: .systemMedium)
                )

            previewView(entry: previewEntry)
                .previewDisplayName("Large")
                .previewContext(
                    WidgetPreviewContext(family: .systemLarge)
                )

            previewView(entry: missingOptionalDataEntry)
                .previewDisplayName("Medium — Missing Optional Data")
                .previewContext(
                    WidgetPreviewContext(family: .systemMedium)
                )

            previewView(entry: previewEntry)
                .environment(\.locale, Locale(identifier: "en"))
                .previewDisplayName("Medium — English")
                .previewContext(
                    WidgetPreviewContext(family: .systemMedium)
                )

            previewView(entry: previewEntry)
                .environment(\.locale, Locale(identifier: "ja"))
                .previewDisplayName("Medium — Japanese")
                .previewContext(
                    WidgetPreviewContext(family: .systemMedium)
                )

            previewView(entry: previewEntry)
                .environment(\.locale, Locale(identifier: "ko"))
                .previewDisplayName("Medium — Korean")
                .previewContext(
                    WidgetPreviewContext(family: .systemMedium)
                )

            previewView(entry: previewEntry)
                .environment(\.locale, Locale(identifier: "zh-Hans"))
                .previewDisplayName("Medium — Simplified Chinese")
                .previewContext(
                    WidgetPreviewContext(family: .systemMedium)
                )

            previewView(entry: noForecastPreviewEntry)
                .environment(\.locale, Locale(identifier: "zh-TW"))
                .previewDisplayName("Medium — No Forecast")
                .previewContext(
                    WidgetPreviewContext(family: .systemMedium)
                )

            previewView(entry: noWeatherDataEntry)
                .environment(\.locale, Locale(identifier: "zh-TW"))
                .previewDisplayName("Medium — No Weather Data")
                .previewContext(
                    WidgetPreviewContext(family: .systemMedium)
                )

            if let stalePreviewEntry {
                previewView(entry: stalePreviewEntry)
                    .environment(\.locale, Locale(identifier: "zh-tw"))
                    .previewDisplayName("Medium — Stale (TW)")
                    .previewContext(
                        WidgetPreviewContext(family: .systemMedium)
                    )

                previewView(entry: stalePreviewEntry)
                    .environment(\.locale, Locale(identifier: "ja"))
                    .previewDisplayName("Medium — Stale (JA)")
                    .previewContext(
                        WidgetPreviewContext(family: .systemMedium)
                    )

                previewView(entry: stalePreviewEntry)
                    .environment(\.locale, Locale(identifier: "ja"))
                    .environment(\.dynamicTypeSize, .accessibility1)
                    .previewDisplayName("Medium — Stale (JA, Accessibility)")
                    .previewContext(
                        WidgetPreviewContext(family: .systemMedium)
                    )
            }

            if let expiredPreviewEntry {
                previewView(entry: expiredPreviewEntry)
                    .environment(\.locale, Locale(identifier: "zh-TW"))
                    .previewDisplayName("Medium — Expired Forecast")
                    .previewContext(
                        WidgetPreviewContext(family: .systemMedium)
                    )
            }

            if let longRegionStaleEntry {
                previewView(entry: longRegionStaleEntry)
                    .environment(\.locale, Locale(identifier: "ja"))
                    .previewDisplayName("Medium — Stale (Long Region)")
                    .previewContext(
                        WidgetPreviewContext(family: .systemMedium)
                    )
            }
        }
    }
}
