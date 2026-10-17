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
private struct SmallCurrentWeatherView: View {
    let entry: DPIPWidgetEntry

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

                        Text(snapshot.presentationCondition.localizedDisplayName)
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

                Text("widget.no_weather_data")
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize, let snapshot = entry.snapshot {
            AccessibleCurrentWeatherContent(
                entry: entry, snapshot: snapshot, family: .systemMedium,
                localizationBundle: localizationBundle
            )
        } else if let snapshot = entry.snapshot {
            let observationDate = Date(
                timeIntervalSince1970: TimeInterval(snapshot.observationTime)
            )

            let calibratedDate = CurrentWeatherWidgetTimeCalibration(
                snapshot: snapshot
            ).calibratedDate(fromDeviceDate: entry.date)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
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

                    Spacer()

                    Text(observationDate, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

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

                HourlyForecastSection(
                    entry: entry,
                    family: .systemMedium,
                    calibratedDate: calibratedDate,
                    isCurrentlyNight: entry.isNight,
                    nextTransitionTime: snapshot.nextDayNightTransitionTime,
                    localizationBundle: localizationBundle
                )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
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

struct LargeCurrentWeatherView: View {
    let entry: DPIPWidgetEntry
    var localizationBundle: Bundle = .main

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize, let snapshot = entry.snapshot {
            AccessibleCurrentWeatherContent(
                entry: entry, snapshot: snapshot, family: .systemLarge,
                localizationBundle: localizationBundle
            )
        } else if let snapshot = entry.snapshot {
            let observationDate = Date(
                timeIntervalSince1970: TimeInterval(snapshot.observationTime)
            )

            let transitionDate = Date(
                timeIntervalSince1970:
                    TimeInterval(snapshot.nextDayNightTransitionTime)
            )

            let calibratedDate = CurrentWeatherWidgetTimeCalibration(
                snapshot: snapshot
            ).calibratedDate(fromDeviceDate: entry.date)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
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

                    Spacer()

                    Text(observationDate, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

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

                Spacer()

                HourlyForecastSection(
                    entry: entry,
                    family: .systemLarge,
                    calibratedDate: calibratedDate,
                    isCurrentlyNight: entry.isNight,
                    nextTransitionTime: snapshot.nextDayNightTransitionTime,
                    localizationBundle: localizationBundle
                )

                Spacer()

                VStack(alignment: .leading, spacing: 14) {
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
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
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
                maxHeight: .infinity,
            )
        }
    }
}

/// Accessibility sizes need fewer columns and less vertical stacking inside
/// WidgetKit's fixed bounds. Keep the main temperature and nearest forecast
/// readable; cap only supporting metadata, whose rows retain their full values.
private struct AccessibleCurrentWeatherContent: View {
    let entry: DPIPWidgetEntry
    let snapshot: CurrentWeatherWidgetSnapshot
    let family: WidgetFamily
    let localizationBundle: Bundle

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(snapshot.regionName)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1)
                if snapshot.sourceIdentifier == "current-location" {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text(Date(timeIntervalSince1970: TimeInterval(snapshot.observationTime)), style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)

            HStack(spacing: 8) {
                Group {
                    if let temperature = snapshot.temperature {
                        Text("\(temperature, specifier: "%.0f")°")
                    } else {
                        Text("—°").foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: family == .systemMedium ? 38 : 42,
                              weight: .semibold, design: .rounded))
                .fixedSize()

                if let apparentTemperature = snapshot.apparentTemperature {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("widget.feels_like", bundle: localizationBundle)
                        Text("\(apparentTemperature, specifier: "%.0f")°")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Image(systemName: snapshot.presentationCondition.systemImageName(isNight: entry.isNight))
                    Text(snapshot.presentationCondition.localizedDisplayName, bundle: localizationBundle)
                        .lineLimit(2)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
            .fixedSize(horizontal: false, vertical: true)

            HourlyForecastSection(
                entry: entry, family: family,
                calibratedDate: CurrentWeatherWidgetTimeCalibration(snapshot: snapshot)
                    .calibratedDate(fromDeviceDate: entry.date),
                isCurrentlyNight: entry.isNight,
                nextTransitionTime: snapshot.nextDayNightTransitionTime,
                localizationBundle: localizationBundle
            )

            if family == .systemLarge {
                Spacer(minLength: 0)
                details
                    .font(.caption2)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            detail("widget.humidity") {
                Text(snapshot.humidity.map { "\($0)%" } ?? "--%")
            }
            detail("widget.rainfall") {
                if let rain = snapshot.rain {
                    Text("\(rain, specifier: "%.1f") mm")
                } else {
                    Text("-- mm")
                }
            }
            detail(entry.isNight ? "widget.sunrise" : "widget.sunset") {
                Text(Date(timeIntervalSince1970: TimeInterval(snapshot.nextDayNightTransitionTime)), style: .time)
            }
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
            detail("widget.station") {
                Text(snapshot.stationName.isEmpty ? "--" : snapshot.stationName)
                    .lineLimit(2)
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
            value().font(.caption2.weight(.medium))
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

private struct HourlyForecastPointView: View {
    let point: ForecastWidgetPoint
    let compact: Bool

    let calibratedDate: Date
    let isCurrentlyNight: Bool
    let nextTransitionTime: Int

    var body: some View {
        let isNight = forecastIsNight(
            pointTime: point.time,
            calibratedDate: calibratedDate,
            isCurrentlyNight: isCurrentlyNight,
            nextTransitionTime: nextTransitionTime
        )

        VStack(spacing: compact ? 2 : 5) {
            Text(point.time)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Image(
                systemName: point.presentationCondition.systemImageName(
                    isNight: isNight
                )
            )
            .font(compact ? .title3 : .title2)

            Text("\(point.temperature, specifier: "%.0f")°")
                .font(compact ? .caption : .subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            if let pop = point.pop {
                Text("\(pop)%")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct AccessibleForecastPointView: View {
    let point: ForecastWidgetPoint
    let isNight: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(point.time)
                .foregroundStyle(.secondary)
                .fixedSize()
            Image(systemName: point.presentationCondition.systemImageName(isNight: isNight))
                .font(.system(size: 22))
                .fixedSize()
            Text("\(point.temperature, specifier: "%.0f")°")
                .fontWeight(.semibold)
                .fixedSize()
            Spacer(minLength: 0)
            Text(point.pop.map { "\($0)%" } ?? "—")
                .font(.caption)
                .foregroundStyle(.secondary)
                // Keep the time and temperature at the requested size. The
                // secondary probability must leave room for full HH:mm labels,
                // negative temperatures and 100% even on narrow widget cards.
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .fixedSize()
        }
        .font(.caption2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let points = entry.upcomingForecastPoints(for: family)
        if !points.isEmpty, entry.forecastFreshness == .stale {
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 4) {
                    forecastContent(points: points)
                    Text("widget.forecast_outdated", bundle: localizationBundle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
                // This secondary status shares a fixed forecast area. Bound
                // only its growth; never shrink the current-weather content.
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func forecastContent(points: [ForecastWidgetPoint]) -> some View {
        let compact = family == .systemMedium
        if !points.isEmpty, dynamicTypeSize.isAccessibilitySize {
            // Fixed WidgetKit cards cannot scroll. Prioritize the nearest hour(s)
            // at larger text sizes, with time, condition, temperature and rain
            // probability on a single row instead of four stacked lines.
            VStack(spacing: 4) {
                ForEach(Array(points.prefix(compact ? 1 : 2)), id: \.time) { point in
                    AccessibleForecastPointView(
                        point: point,
                        isNight: forecastIsNight(
                            pointTime: point.time, calibratedDate: calibratedDate,
                            isCurrentlyNight: isCurrentlyNight,
                            nextTransitionTime: nextTransitionTime
                        )
                    )
                }
            }
        } else if !points.isEmpty {
            VStack(
                alignment: .leading,
                spacing: compact ? 4 : 12
            ) {
                HStack(
                    alignment: .top,
                    spacing: compact ? 4 : 8
                ) {
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        HourlyForecastPointView(
                            point: point,
                            compact: compact,
                            calibratedDate: calibratedDate,
                            isCurrentlyNight: isCurrentlyNight,
                            nextTransitionTime: nextTransitionTime
                        )
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
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
        }
    }
}
