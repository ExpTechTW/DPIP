import WidgetKit
import SwiftUI

struct DPIPWidgetProvider: TimelineProvider {
    private let staleAfter: TimeInterval = 30 * 60
    private let snapshotStore = WidgetSnapshotStore()

    func placeholder(in context: Context) -> DPIPWidgetEntry {
        DPIPWidgetEntry(
            date: .now,
            snapshot: nil,
            isStale: false,
            isNight: false,
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (DPIPWidgetEntry) -> Void
    ) {
        let snapshot = snapshotStore.loadCurrentWeatherSnapshot()
        let deviceNow = Date.now
        let state = CurrentWeatherWidgetTimeline.state(
            snapshot: snapshot,
            at: deviceNow,
            staleAfter: staleAfter
        )

        let entry = DPIPWidgetEntry(
            date: state.date,
            snapshot: snapshot,
            isStale: state.isStale,
            isNight: state.isNight
        )

        completion(entry)
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<DPIPWidgetEntry>) -> Void
    ) {
        let deviceNow = Date()
        let snapshot = snapshotStore.loadCurrentWeatherSnapshot()
        let entries = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot,
            deviceNow: deviceNow,
            staleAfter: staleAfter
        )
            .map { state in
                DPIPWidgetEntry(
                    date: state.date,
                    snapshot: snapshot,
                    isStale: state.isStale,
                    isNight: state.isNight
                )
            }

        completion(
            Timeline(
                entries: entries,
                // The app owns refreshes. This timeline projects only the
                // stale deadline and one solar transition in the snapshot.
                policy: .never
            )
        )
    }
}

struct DPIPWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CurrentWeatherWidgetSnapshot?
    let isStale: Bool
    let isNight: Bool
}

struct DPIPWidgetsEntryView : View {
    let entry: DPIPWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let observationDate = Date(
                timeIntervalSince1970: TimeInterval(snapshot.observationTime)
            )

            VStack(alignment: .leading) {
                HStack {
                    Text(snapshot.regionName)
                        .font(.headline)
                        .layoutPriority(1)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: snapshot.condition.systemImageName(
                            isNight: entry.isNight
                        ))

                        Text(snapshot.weather)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .font(.caption)
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

                HStack(spacing: 4) {
                    if entry.isStale {
                        Text("widget.stale")
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "clock")

                    Text(observationDate, style: .time)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
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

struct DPIPWidgets: Widget {
    let kind: String = "DPIPWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DPIPWidgetProvider()) { entry in
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
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("widget.current_weather")
        .description("widget.current_weather_description")
    }
}

struct DPIPWidgets_Previews: PreviewProvider {
    private static let previewEntry = DPIPWidgetEntry(
        date: .now,
        snapshot: CurrentWeatherWidgetSnapshot(
            schemaVersion: 4,
            regionCode: "660",
            regionName: "西屯區",
            observationTime: 0,
            stationName: "西屯",
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: true,
            nextDayNightTransitionTime: 1_789_562_700,
            calibratedTimeOffsetMilliseconds: 0,
            temperature: 28.4,
            humidity: 76,
            rain: 0
        ),isStale: true, isNight: true
    )

    static var previews: some View {
        Group {
            if #available(iOSApplicationExtension 17.0, *) {
                DPIPWidgetsEntryView(entry: previewEntry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DPIPWidgetsEntryView(entry: previewEntry)
                    .padding()
                    .background()
            }
        }
        .previewContext(
            WidgetPreviewContext(family: .systemSmall)
        )
    }
}
