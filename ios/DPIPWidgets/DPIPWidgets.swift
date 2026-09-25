import WidgetKit
import SwiftUI
import Intents

struct DPIPWidgetProvider: IntentTimelineProvider {
    typealias Intent = WeatherWidgetConfigurationIntent
    private let staleAfter: TimeInterval = 30 * 60
    private let dependencies: DPIPWidgetProviderDependencies

    init(
        dependencies: DPIPWidgetProviderDependencies =
            DPIPWidgetProviderRuntime.shared
    ) {
        self.dependencies = dependencies
    }

    private func snapshot(
        for configuration: WeatherWidgetConfigurationIntent
    ) -> CurrentWeatherWidgetSnapshot? {
        let target = WidgetLocationTarget(
            identifier: configuration.location?.identifier
        )

        return dependencies.snapshot(for: target)
    }

    func placeholder(in context: Context) -> DPIPWidgetEntry {
        DPIPWidgetEntry(
            date: .now,
            snapshot: nil,
            isStale: false,
            isNight: false,
        )
    }

    func getSnapshot(
        for configuration: WeatherWidgetConfigurationIntent,
        in context: Context,
        completion: @escaping (DPIPWidgetEntry) -> Void
    ) {
        let snapshot = snapshot(for: configuration)
        let deviceNow = Date.now
        let target = WidgetLocationTarget(
            identifier: configuration.location?.identifier
        )

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
            forecast: dependencies.forecastSnapshot(
                for: target,
                currentSnapshot: snapshot,
                at: deviceNow,
                family: context.family
            )
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
                    forecast: plan.forecast(at: state.date)
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

struct DPIPWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CurrentWeatherWidgetSnapshot?
    let isStale: Bool
    let isNight: Bool
    let forecast: ForecastWidgetSnapshot?

    init(date: Date, snapshot: CurrentWeatherWidgetSnapshot?,
         isStale: Bool, isNight: Bool,
         forecast: ForecastWidgetSnapshot? = nil) {
        self.date = date
        self.snapshot = snapshot
        self.isStale = isStale
        self.isNight = isNight
        self.forecast = forecast
    }
}

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
                        Image(systemName: snapshot.condition.systemImageName(
                            isNight: entry.isNight
                        ))
                        .font(.title)

                        Text(snapshot.weather)
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

private struct MediumCurrentWeatherView: View {
    let entry: DPIPWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let observationDate = Date(
                timeIntervalSince1970: TimeInterval(snapshot.observationTime)
            )

            VStack(alignment: .leading, spacing: 8) {
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

                Spacer()
                    .frame(height: 4)

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
                                Text("widget.feels_like")
                                Text("\(apparentTemperature, specifier: "%.0f")°")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: snapshot.condition.systemImageName(
                            isNight: entry.isNight
                        ))
                            .font(.title2)

                        Text(snapshot.condition.localizedDisplayName)
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(.secondary)
                }

                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("widget.humidity")
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

                    VStack(alignment: .center, spacing: 2) {
                        Text("widget.rainfall")
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
                    .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("widget.wind")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if let direction = snapshot.windDirection,
                           let speed = snapshot.windSpeed {
                            Text("\(direction) \(speed, specifier: "%.1f") m/s")
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        } else if let speed = snapshot.windSpeed {
                            Text("\(speed, specifier: "%.1f") m/s")
                                .font(.caption)
                                .fontWeight(.medium)
                        } else if let direction = snapshot.windDirection {
                            Text(direction)
                                .font(.caption)
                                .fontWeight(.medium)
                        } else {
                            Text("--")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
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

struct DPIPWidgetsEntryView : View {
    @Environment(\.widgetFamily) private var family

    let entry: DPIPWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCurrentWeatherView(entry: entry)

        case .systemMedium:
            MediumCurrentWeatherView(entry: entry)

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
                    .widgetURL(URL(string: "dpip:///home"))
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DPIPWidgetsEntryView(entry: entry)
                    .widgetURL(URL(string: "dpip:///home"))
                    .padding()
                    .background()
            }
        }
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
        .configurationDisplayName("widget.current_weather")
        .description("widget.current_weather_description")
    }
}

struct DPIPWidgets_Previews: PreviewProvider {
    private static let previewEntry = DPIPWidgetEntry(
        date: .now,
        snapshot: CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: "current-location",
            regionCode: "407",
            regionName: "西屯區",
            observationTime: Int(Date().timeIntervalSince1970),
            stationName: "西屯",
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: false,
            nextDayNightTransitionTime: 1_789_562_700,
            calibratedTimeOffsetMilliseconds: 0,
            temperature: 28.0,
            humidity: 76,
            rain: 0.0,
            windDirection: "北北西",
            windSpeed: 1.3,
            apparentTemperature: 30.2
        ),
        isStale: false,
        isNight: false
    )

    private static let missingOptionalDataEntry = DPIPWidgetEntry(
        date: .now,
        snapshot: CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: "current-location",
            regionCode: "407",
            regionName: "西屯區",
            observationTime: Int(Date().timeIntervalSince1970),
            stationName: "西屯",
            weather: "多雲",
            weatherCode: 200,
            condition: .cloudy,
            isNight: false,
            nextDayNightTransitionTime: 1_789_562_700,
            calibratedTimeOffsetMilliseconds: 0,
            temperature: 28.0,
            humidity: 76,
            rain: 0.0,
            windDirection: nil,
            windSpeed: nil,
            apparentTemperature: nil
        ),
        isStale: false,
        isNight: false
    )

    @ViewBuilder
    private static func previewView(
        entry: DPIPWidgetEntry
    ) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
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
