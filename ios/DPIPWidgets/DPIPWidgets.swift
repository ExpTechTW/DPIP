import WidgetKit
import SwiftUI

struct DPIPWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DPIPWidgetEntry {
        DPIPWidgetEntry(date: .now, snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (DPIPWidgetEntry) -> Void) {
        let snapshot = WidgetSnapshotStore()
            .loadCurrentWeatherSnapshot()

        let entry = DPIPWidgetEntry(date: .now, snapshot: snapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DPIPWidgetEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore()
            .loadCurrentWeatherSnapshot()

        let entry = DPIPWidgetEntry(date: .now, snapshot: snapshot)

        let timeline = Timeline(
            entries: [entry],
            policy: .never
        )

        completion(timeline)
    }
}

struct DPIPWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CurrentWeatherWidgetSnapshot?
}

struct DPIPWidgetsEntryView : View {
    let entry: DPIPWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            VStack(alignment: .leading) {
                Text(snapshot.regionName)

                if let temperature = snapshot.temperature {
                    Text("\(temperature, specifier: "%.1f")°")
                } else {
                    Text("--°")
                }
            }
        } else {
            Text("尚無天氣資料")
        }
    }
}

struct DPIPWidgets: Widget {
    let kind: String = "DPIPWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DPIPWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                DPIPWidgetsEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DPIPWidgetsEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
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
            weather: "多雲",
            weatherCode: 200,
            temperature: 28.4,
            humidity: 76,
            rain: 0
        )
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
