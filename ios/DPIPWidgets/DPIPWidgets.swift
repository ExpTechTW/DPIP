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

private func forecastIsNight(
    pointTime: String,
    entryDate: Date,
    isCurrentlyNight: Bool,
    nextTransitionTime: Int
) -> Bool {
    let parts = pointTime.split(separator: ":")
    guard parts.count == 2,
          let hour = Int(parts[0]),
          let minute = Int(parts[1]),
          (0...23).contains(hour),
          (0...59).contains(minute)
    else {
        return isCurrentlyNight
    }

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!

    let currentComponents = calendar.dateComponents(
        [.hour, .minute],
        from: entryDate
    )

    guard let currentHour = currentComponents.hour,
          let currentMinute = currentComponents.minute
    else {
        return isCurrentlyNight
    }

    let currentMinutes = currentHour * 60 + currentMinute
    let forecastMinutes = hour * 60 + minute

    var minutesAhead = forecastMinutes - currentMinutes

    if minutesAhead < 0 {
        minutesAhead += 24 * 60
    }

    guard minutesAhead <= 12 * 60 else {
        return isCurrentlyNight
    }

    let transitionDate = Date(
        timeIntervalSince1970: TimeInterval(nextTransitionTime)
    )

    let minutesUntilTransition =
        transitionDate.timeIntervalSince(entryDate) / 60

    guard minutesUntilTransition >= 0 else {
        return isCurrentlyNight
    }

    if Double(minutesAhead) < minutesUntilTransition {
        return isCurrentlyNight
    }

    return !isCurrentlyNight
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

private struct MediumCurrentWeatherView: View {
    let entry: DPIPWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let observationDate = Date(
                timeIntervalSince1970: TimeInterval(snapshot.observationTime)
            )

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
                                Text("widget.feels_like")
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

                        Text(snapshot.presentationCondition.localizedDisplayName)
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(.secondary)
                }

                if let forecast = entry.forecast,
                   !forecast.points.isEmpty {
                    HourlyForecastSection(
                        forecast: forecast,
                        compact: true,
                        entryDate: entry.date,
                        isCurrentlyNight: entry.isNight,
                        nextTransitionTime: snapshot.nextDayNightTransitionTime
                    )
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

private struct LargeCurrentWeatherView: View {
    let entry: DPIPWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let observationDate = Date(
                timeIntervalSince1970: TimeInterval(snapshot.observationTime)
            )

            let transitionDate = Date(
                timeIntervalSince1970:
                    TimeInterval(snapshot.nextDayNightTransitionTime)
            )

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
                                Text("widget.feels_like")
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

                        Text(snapshot.presentationCondition.localizedDisplayName)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if let forecast = entry.forecast,
                   !forecast.points.isEmpty {
                    HourlyForecastSection(
                        forecast: forecast,
                        compact: false,
                        entryDate: entry.date,
                        isCurrentlyNight: entry.isNight,
                        nextTransitionTime: snapshot.nextDayNightTransitionTime
                    )

                    let forecastUpdateDate = Date(
                        timeIntervalSince1970:
                            TimeInterval(forecast.updateTime) / 1000
                    )
                }

                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 16) {
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

                        VStack(alignment: .leading, spacing: 2) {
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
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.isNight ? "widget.sunrise" : "widget.sunset")
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
                            Text("widget.wind")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            if let windSpeed = snapshot.windSpeed {
                                HStack(spacing: 4) {
                                    if let direction = snapshot.presentationWindDirection {
                                        Text(direction.localizedDisplayName)
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
                            Text("widget.station")
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

                Text("widget.no_weather_data")
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

private struct HourlyForecastPointView: View {
    let point: ForecastWidgetPoint
    let compact: Bool

    let entryDate: Date
    let isCurrentlyNight: Bool
    let nextTransitionTime: Int

    var body: some View {
        let isNight = forecastIsNight(
            pointTime: point.time,
            entryDate: entryDate,
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

private struct HourlyForecastSection: View {
    let forecast: ForecastWidgetSnapshot
    let compact: Bool

    let entryDate: Date
    let isCurrentlyNight: Bool
    let nextTransitionTime: Int

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: compact ? 4 : 12
        ) {
            HStack(
                alignment: .top,
                spacing: compact ? 4 : 8
            ) {
                ForEach(
                    Array(forecast.points.enumerated()),
                    id: \.offset
                ) { _, point in
                    HourlyForecastPointView(
                        point: point,
                        compact: compact,
                        entryDate: entryDate,
                        isCurrentlyNight: isCurrentlyNight,
                        nextTransitionTime: nextTransitionTime
                    )
                        .frame(
                            maxWidth: .infinity,
                            alignment: .center
                        )
                }
            }
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
            .systemMedium,
            .systemLarge
        ])
        .configurationDisplayName("widget.current_weather")
        .description("widget.current_weather_description")
    }
}

struct DPIPWidgets_Previews: PreviewProvider {
    private static let previewNow = Date()

    private static let previewTransitionTime = Int(
        previewNow
            .addingTimeInterval(6 * 60 * 60)
            .timeIntervalSince1970
    )

    private static let previewForecast = ForecastWidgetSnapshot(
        sourceIdentifier: "current-location",
        regionCode: "407",

        updateTime: 1_790_316_445_925,
        receivedAt: 1_790_316_600_000,

        points: [
            ForecastWidgetPoint(
                time: "01:00",
                temperature: 26.0,
                weather: "晴",
                weatherCode: 100,
                pop: 0
            )!,
            ForecastWidgetPoint(
                time: "02:00",
                temperature: 26.0,
                weather: "多雲",
                weatherCode: 200,
                pop: 10
            )!,
            ForecastWidgetPoint(
                time: "03:00",
                temperature: 25.0,
                weather: "多雲有雨",
                weatherCode: 206,
                pop: 60
            )!,
            ForecastWidgetPoint(
                time: "04:00",
                temperature: 25.0,
                weather: "多雲有雷雨",
                weatherCode: 214,
                pop: 80
            )!,
            ForecastWidgetPoint(
                time: "05:00",
                temperature: 24.0,
                weather: "多雲有霧",
                weatherCode: 205,
                pop: 20
            )!,
        ]    )

    private static let previewEntry = DPIPWidgetEntry(
        date: previewNow,
        snapshot: CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: "current-location",
            regionCode: "407",
            regionName: "西屯區",
            observationTime: Int(previewNow.timeIntervalSince1970),
            stationName: "西屯",
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: true,
            nextDayNightTransitionTime: previewTransitionTime,
            calibratedTimeOffsetMilliseconds: 0,
            temperature: 28.0,
            humidity: 76,
            rain: 0.0,
            windDirection: "北北西",
            windSpeed: 1.3,
            apparentTemperature: 30.2
        ),
        isStale: false,
        isNight: true,
        forecast: previewForecast
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
            apparentTemperature: nil,
        ),
        isStale: false,
        isNight: false,
        forecast: previewForecast
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
