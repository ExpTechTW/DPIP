import WidgetKit
import SwiftUI

struct DPIPWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DPIPWidgetEntry {
        DPIPWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (DPIPWidgetEntry) -> ()) {
        let entry = DPIPWidgetEntry(date: .now)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DPIPWidgetEntry>) -> ()) {
        let entry = DPIPWidgetEntry(date: .now)
        let timeline = Timeline(
            entries: [entry],
            policy: .never
        )
        
        completion(timeline)
    }
}

struct DPIPWidgetEntry: TimelineEntry {
    let date: Date
}

struct DPIPWidgetsEntryView : View {
    let entry: DPIPWidgetEntry

    var body: some View {
        VStack {
            Text("DPIP")
            Text("Widget Connected")
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
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct DPIPWidgets_Previews: PreviewProvider {
    static var previews: some View {
        DPIPWidgetsEntryView(
            entry: DPIPWidgetEntry(date: .now)
        )
        .previewContext(
            WidgetPreviewContext(family: .systemSmall)
        )
    }
}
