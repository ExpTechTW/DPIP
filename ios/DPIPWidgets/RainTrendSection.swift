import SwiftUI
import WidgetKit

/// The next-hour rain chart that takes the hourly row's place on Medium and
/// Large while rain is coming — the widget's version of the Home sheet's
/// `HomeRainTrendSection`, drawn with `Canvas` because the extension still
/// deploys to iOS 15, where Swift Charts does not exist.
///
/// Time runs from the entry's own instant, as the app's chart runs from "now":
/// the bars shift left by the minutes elapsed since the forecast's origin,
/// and minutes the forecast does not cover are a grey band, never bars. The
/// summary reads the same minutes the bars show, never the ones behind.
struct RainTrendSection: View {
    let trend: RainHourTrend
    /// The entry's calibrated instant. The forecast origin is a server stamp.
    let calibratedDate: Date
    let family: WidgetFamily
    var localizationBundle: Bundle = .main
    /// The tight accessibility layout the hourly row also has: the type
    /// stops at the default size, the gaps close, the chart is shorter, and
    /// the title line and the drop give way to the summary.
    var compactAccessibility = false

    /// What one family, or the compact accessibility layout, draws.
    struct Layout: Equatable, Sendable {
        /// The chart, its tick labels included.
        let chartHeight: CGFloat
        let spacing: CGFloat
        /// Large's title line above the summary; otherwise the summary shares
        /// one line with the update time.
        let showsTitleLine: Bool
        let showsDrop: Bool
        /// The largest text size the header follows.
        let maximumTypeSize: DynamicTypeSize
    }

    static func layout(
        for family: WidgetFamily, compactAccessibility: Bool
    ) -> Layout {
        if compactAccessibility {
            return Layout(
                chartHeight: 32, spacing: 0, showsTitleLine: false,
                showsDrop: false, maximumTypeSize: .large
            )
        }
        if family == .systemMedium {
            return Layout(
                chartHeight: 40, spacing: 2, showsTitleLine: false,
                showsDrop: true, maximumTypeSize: .xLarge
            )
        }
        return Layout(
            chartHeight: 64, spacing: 4, showsTitleLine: true,
            showsDrop: true, maximumTypeSize: .xxLarge
        )
    }

    private var layout: Layout {
        Self.layout(for: family, compactAccessibility: compactAccessibility)
    }

    private var elapsedMinutes: Int {
        trend.elapsedMinutes(at: calibratedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacing) {
            header
            RainTrendChart(
                trend: trend,
                elapsedMinutes: elapsedMinutes,
                localizationBundle: localizationBundle
            )
            .frame(height: layout.chartHeight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var header: some View {
        if !layout.showsTitleLine {
            oneLineHeader
                .dynamicTypeSize(...layout.maximumTypeSize)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: "drop")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("widget.rain_trend_title", bundle: localizationBundle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 4)
                    updatedText
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize()
                }
                summaryText
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .dynamicTypeSize(...layout.maximumTypeSize)
        }
    }

    /// The summary beside the fixed-width update time. The summary is drawn
    /// whole, never cut: each step down — the drop, then a smaller font,
    /// then the default text size — is taken only when the line would not
    /// fit, and only the last resort may shrink it.
    @ViewBuilder
    private var oneLineHeader: some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                oneLine(summaryFont: .caption, showsDrop: layout.showsDrop, whole: true)
                oneLine(summaryFont: .caption2, showsDrop: false, whole: true)
                oneLine(summaryFont: .caption2, showsDrop: false, whole: true)
                    .dynamicTypeSize(...DynamicTypeSize.large)
                oneLine(summaryFont: .caption2, showsDrop: false, whole: false)
                    .dynamicTypeSize(...DynamicTypeSize.large)
            }
        } else {
            oneLine(summaryFont: .caption, showsDrop: layout.showsDrop, whole: false)
        }
    }

    private func oneLine(
        summaryFont: Font, showsDrop: Bool, whole: Bool
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if showsDrop {
                Image(systemName: "drop")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            summaryText
                .font(summaryFont)
                .lineLimit(1)
                .minimumScaleFactor(whole ? 1 : 0.8)
                .fixedSize(horizontal: whole, vertical: false)
            Spacer(minLength: 4)
            updatedText
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
        }
    }

    private var summaryText: Text {
        Text(verbatim: Self.summary(
            of: trend, at: calibratedDate, bundle: localizationBundle
        ))
    }

    /// "Updated HH:mm" from the forecast's own origin, in Taipei time — the
    /// data's moment, as the app labels it, not when the widget fetched it.
    private var updatedText: Text {
        Text(verbatim: Self.updated(trend.startDate, bundle: localizationBundle))
    }

    private var accessibilityText: Text {
        Text(verbatim: [
            localizationBundle.localizedString(
                forKey: "widget.rain_trend_title", value: nil, table: nil
            ),
            Self.summary(of: trend, at: calibratedDate, bundle: localizationBundle),
            Self.updated(trend.startDate, bundle: localizationBundle),
        ].joined(separator: ", "))
    }

    /// The summary line at a calibrated instant, read from the minutes still
    /// ahead of it: the stop counts from the entry, not the forecast's origin.
    static func summary(
        of trend: RainHourTrend, at calibratedDate: Date, bundle: Bundle
    ) -> String {
        summary(trend.summary(at: calibratedDate), bundle: bundle)
    }

    /// The one-line reading the app shows under its title. A dry hour never
    /// reaches the chart; it is read as scattered only to stay total.
    static func summary(
        _ summary: RainHourTrend.Summary, bundle: Bundle
    ) -> String {
        let key: String
        switch (summary.grade, summary.stopInMinutes) {
        case (.none, _), (.scattered, _):
            key = "widget.rain_trend_scattered"
        case (.light, nil):
            key = "widget.rain_trend_light_sustained"
        case (.light, .some):
            key = "widget.rain_trend_light_stopping %lld"
        case (.heavy, nil):
            key = "widget.rain_trend_heavy_sustained"
        case (.heavy, .some):
            key = "widget.rain_trend_heavy_stopping %lld"
        }
        let format = bundle.localizedString(forKey: key, value: nil, table: nil)
        guard let minutes = summary.stopInMinutes else { return format }
        return String(format: format, Int64(minutes))
    }

    static func updated(_ date: Date, bundle: Bundle) -> String {
        String(
            format: bundle.localizedString(
                forKey: "widget.rain_trend_updated %@", value: nil, table: nil
            ),
            clockLabel(date)
        )
    }

    /// The axis label for `minute` minutes from now.
    static func tickLabel(_ minute: Int, bundle: Bundle) -> String {
        guard minute > 0 else {
            return bundle.localizedString(
                forKey: "widget.rain_trend_now", value: nil, table: nil
            )
        }
        return String(
            format: bundle.localizedString(
                forKey: "widget.rain_trend_minute %lld", value: nil, table: nil
            ),
            Int64(minute)
        )
    }

    static func clockLabel(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }
}

/// Sixty one-minute bars under a fixed 35 mm ceiling, with 10/20/30 mm guides
/// and ticks every ten minutes — the app's `_Chart`, minus what a widget
/// cannot animate.
struct RainTrendChart: View {
    static let maximumMm = 35.0
    static let ticks = [0, 10, 20, 30, 40, 50]
    private static let labelBand: CGFloat = 12

    let trend: RainHourTrend
    let elapsedMinutes: Int
    var localizationBundle: Bundle = .main

    /// Bar heights in mm for each of the sixty slots, or nil where the
    /// forecast has no data for that minute.
    static func slots(
        for trend: RainHourTrend,
        elapsedMinutes: Int
    ) -> [Double?] {
        (0..<RainHourTrend.sampleCount).map { index in
            let source = index + elapsedMinutes
            guard trend.mm.indices.contains(source) else { return nil }
            return min(trend.mm[source], maximumMm)
        }
    }

    var body: some View {
        let slots = Self.slots(for: trend, elapsedMinutes: elapsedMinutes)
        ZStack {
            Canvas { context, size in
                drawFrame(slots: slots, in: &context, size: size)
            }
            Canvas { context, size in
                drawBars(slots: slots, in: &context, size: size)
            }
            .foregroundStyle(.tint)
            .rainTrendAccentable()
        }
    }

    private func plotHeight(_ size: CGSize) -> CGFloat {
        max(0, size.height - Self.labelBand)
    }

    private func slotWidth(_ size: CGSize) -> CGFloat {
        size.width / CGFloat(RainHourTrend.sampleCount)
    }

    private func drawBars(
        slots: [Double?], in context: inout GraphicsContext, size: CGSize
    ) {
        let plot = plotHeight(size)
        let slot = slotWidth(size)
        let barWidth = max(1, slot * 0.6)
        var bars = Path()
        for (index, value) in slots.enumerated() {
            guard let value, value > 0 else { continue }
            let height = max(1, plot * CGFloat(value / Self.maximumMm))
            bars.addRoundedRect(
                in: CGRect(
                    x: CGFloat(index) * slot + (slot - barWidth) / 2,
                    y: plot - height,
                    width: barWidth,
                    height: height
                ),
                cornerSize: CGSize(width: 0.5, height: 0.5)
            )
        }
        context.fill(bars, with: .foreground)
    }

    private func drawFrame(
        slots: [Double?], in context: inout GraphicsContext, size: CGSize
    ) {
        let plot = plotHeight(size)
        let slot = slotWidth(size)

        // Minutes the forecast does not cover: one grey band per run.
        var missing = Path()
        var runStart: Int?
        for index in 0...slots.count {
            let isMissing = index < slots.count && slots[index] == nil
            if isMissing, runStart == nil { runStart = index }
            if !isMissing, let start = runStart {
                missing.addRect(CGRect(
                    x: CGFloat(start) * slot, y: 0,
                    width: CGFloat(index - start) * slot, height: plot
                ))
                runStart = nil
            }
        }
        context.fill(missing, with: .style(.secondary.opacity(0.12)))

        var guides = Path()
        for mm in [10.0, 20.0, 30.0] {
            let y = plot - plot * CGFloat(mm / Self.maximumMm)
            guides.move(to: CGPoint(x: 0, y: y))
            guides.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(
            guides, with: .style(.secondary.opacity(0.35)),
            style: StrokeStyle(lineWidth: 0.5, dash: [3, 3])
        )

        var axis = Path()
        axis.move(to: CGPoint(x: 0, y: plot))
        axis.addLine(to: CGPoint(x: size.width, y: plot))
        for minute in Self.ticks {
            let x = CGFloat(minute) * slot + slot / 2
            axis.move(to: CGPoint(x: x, y: plot))
            axis.addLine(to: CGPoint(x: x, y: plot + 3))
        }
        context.stroke(
            axis, with: .style(.secondary.opacity(0.4)), lineWidth: 0.5
        )

        for minute in Self.ticks {
            let label = Text(verbatim: RainTrendSection.tickLabel(
                minute, bundle: localizationBundle
            ))
            context.draw(
                label.font(.system(size: 9)).foregroundColor(.secondary),
                at: CGPoint(x: CGFloat(minute) * slot + slot / 2, y: size.height),
                anchor: minute == 0 ? .bottomLeading : .bottom
            )
        }
    }
}

private extension View {
    @ViewBuilder
    func rainTrendAccentable() -> some View {
        if #available(iOS 16.0, *) {
            widgetAccentable()
        } else {
            self
        }
    }
}
