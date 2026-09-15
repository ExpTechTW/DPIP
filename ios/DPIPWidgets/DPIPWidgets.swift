import WidgetKit
import SwiftUI

struct DPIPWidgetProvider: TimelineProvider {
    private let staleAfter: TimeInterval = 30 * 60

    func placeholder(in context: Context) -> DPIPWidgetEntry {
        DPIPWidgetEntry(date: .now, snapshot: nil, isStale: false)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (DPIPWidgetEntry) -> Void
    ) {
        let snapshot = WidgetSnapshotStore()
            .loadCurrentWeatherSnapshot()

        let now = Date.now

        let isStale: Bool

        if let snapshot {
            let observationDate = Date(
                timeIntervalSince1970: TimeInterval(snapshot.observationTime)
            )

            isStale =
                now >= observationDate.addingTimeInterval(staleAfter)
        } else {
            isStale = false
        }

        let entry = DPIPWidgetEntry(
            date: now,
            snapshot: snapshot,
            isStale: isStale
        )

        completion(entry)
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<DPIPWidgetEntry>) -> Void
    ) {
        let snapshot = WidgetSnapshotStore()
            .loadCurrentWeatherSnapshot()

        let now = Date.now

        guard let snapshot else {
            let entry = DPIPWidgetEntry(
                date: now,
                snapshot: nil,
                isStale: false
            )

            completion(
                Timeline(entries: [entry], policy: .never)
            )
            return
        }

        let observationDate = Date(
            timeIntervalSince1970: TimeInterval(snapshot.observationTime)
        )

        let staleAt = observationDate.addingTimeInterval(staleAfter)

        if now >= staleAt {
            let staleEntry = DPIPWidgetEntry(
                date: now,
                snapshot: snapshot,
                isStale: true
            )

            completion(
                Timeline(
                    entries: [staleEntry],
                    policy: .never
                )
            )
        } else {
            let freshEntry = DPIPWidgetEntry(
                date: now,
                snapshot: snapshot,
                isStale: false
            )

            let staleEntry = DPIPWidgetEntry(
                date: staleAt,
                snapshot: snapshot,
                isStale: true
            )
            completion(
                Timeline(
                    entries: [freshEntry, staleEntry],
                    policy: .never
                )
            )
        }
    }
}

struct DPIPWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CurrentWeatherWidgetSnapshot?
    let isStale: Bool
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
                        Image(systemName: snapshot.condition.systemImageName)

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
                        Text("較舊")
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

                Text("尚無天氣資料")
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
        .configurationDisplayName("目前天氣")
        .description("顯示 DPIP 所選地區的目前天氣。")
    }
}

struct DPIPWidgets_Previews: PreviewProvider {
    private static let previewEntry = DPIPWidgetEntry(
        date: .now,
        snapshot: CurrentWeatherWidgetSnapshot(
            schemaVersion: 1,
            regionCode: "660",
            regionName: "西屯區",
            observationTime: 0,
            stationName: "西屯",
            weather: "短暫雷雨",
            weatherCode: 200,
            condition: .thunderstorm,
            temperature: 28.4,
            humidity: 76,
            rain: 0
        ),isStale: true
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
