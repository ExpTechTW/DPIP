import ActivityKit
import SwiftUI
import WidgetKit

/// The EEW Live Activity. The views and every rule they follow live in
/// ios/Shared (EEWActivityViews, EEWPresentation) so the app's tests can lay
/// them out; this file only places them.
@available(iOS 16.1, *)
struct EEWLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EEWActivityAttributes.self) { context in
            EEWActivityContent(report: EEWActivityReport(context))
        } dynamicIsland: { context in
            // A format version this build does not understand shows nothing.
            let report = EEWActivityReport(context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if let report {
                        EEWIntensityBlock(
                            ordinal: report.localIntensity, live: report.localIsLive, metrics: .expanded,
                            strings: report.strings)
                            // Room for the nsspe ring, which is drawn outside.
                            .padding(4)
                            .accessibilityLabel(Text(verbatim: report.localLabel))
                            .accessibilityValue(Text(verbatim: report.strings.spokenIntensity(report.localIntensity)))
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    if let report { EEWIslandExpandedCenter(report: report) }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let report { EEWIslandExpandedArrival(report: report) }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let report {
                        EEWIslandExpandedBottom(report: report)
                            .padding(.top, 4)
                    }
                }
            } compactLeading: {
                if let report { EEWIslandCompactLeading(report: report) }
            } compactTrailing: {
                if let report { EEWIslandCompactTrailing(report: report) }
            } minimal: {
                if let report { EEWIslandMinimal(report: report) }
            }
            // Keep event details clear of the curved system mask.
            .contentMargins(.horizontal, 22, for: .expanded)
            .keylineTint(report?.style.background.color)
        }
    }
}

/// The activity's own view: the Lock Screen card.
@available(iOS 16.1, *)
private struct EEWActivityContent: View {
    let report: EEWActivityReport?

    var body: some View {
        Group {
            if let report {
                EEWLockScreenView(report: report)
            }
        }
        .activityBackgroundTint(report?.style.tint.color)
        .activitySystemActionForegroundColor(.white)
    }
}

@available(iOS 16.1, *)
extension EEWActivityReport {
    /// Parses the push's `d` and estimates with what the app left in the App
    /// Group: the observer and the S-wave table. Without them the local
    /// intensity is 「—」 and the arrival 「未提供」.
    init?(_ context: ActivityViewContext<EEWActivityAttributes>) {
        var isStale = false
        if #available(iOS 16.2, *) { isStale = context.isStale }
        let store = EEWLiveActivityStore()
        self.init(
            provider: context.attributes.provider, d: context.state.d,
            observer: store?.observer()?.point, table: store?.table(), isStale: isStale)
    }
}

#if DEBUG
    // Canvas-only fixtures: no Activity.request, Flutter bridge, or manager state.
    // The widget previews go through the App Group like a real render, so
    // without the app's table there they show 未提供; the plain view previews
    // below inject an estimate to show the countdown and 抵達.
    @available(iOS 16.2, *)
    enum EEWActivityPreviewData {
        static let cwa = EEWActivityAttributes(provider: "cwa", eventId: "preview-cwa")
        static let trem = EEWActivityAttributes(provider: "trem", eventId: "preview-trem")

        /// §6's vectors, ten seconds old.
        static func d(_ fields: String) -> EEWActivityAttributes.ContentState {
            let origin = Int(Date.now.timeIntervalSince1970) - 10
            return .init(d: fields.replacingOccurrences(of: "ORIGIN", with: String(origin)))
        }

        static var cwaStandard: EEWActivityAttributes.ContentState { d("1|2|0|ORIGIN|23.95|121.71|花蓮縣近海|6.6|10|5") }
        static var cwaEmergency: EEWActivityAttributes.ContentState {
            d("1|3|1|ORIGIN|23.85|121.62|花蓮縣壽豐鄉近海|7.1|15|8")
        }
        static var tremUsable: EEWActivityAttributes.ContentState { d("1|3|0|ORIGIN|23.95|121.71|花蓮縣近海|5.8|20|4|4||0") }
        static var tremLow: EEWActivityAttributes.ContentState { d("1|1|0|ORIGIN|23.95|121.71|花蓮縣近海|4.6|10|1|||0") }
        static var tremNoSource: EEWActivityAttributes.ContentState { d("1|1|8|ORIGIN|23.99|121.60|花蓮縣|1.0|10|2|3||3") }
        static var tremLocalFromNsspe: EEWActivityAttributes.ContentState {
            d("1|3|9|ORIGIN|22.78|121.38|臺東縣近海|6.2|20|4|5|2|5")
        }
        static var tremFinal: EEWActivityAttributes.ContentState {
            d("1|6|3|ORIGIN|23.85|121.62|花蓮縣壽豐鄉近海|7.1|15|4|8|2|0")
        }
        static var tremCancelled: EEWActivityAttributes.ContentState { d("1|2|4|ORIGIN|||||||||0") }
        static var layoutStress: EEWActivityAttributes.ContentState {
            d("1|123|11|ORIGIN|23.85|121.62|花蓮縣壽豐鄉東南方外海（臺灣東部海域）|6.1|120|4|9|2|9")
        }

        /// A rendered report with an injected estimate, for the plain previews.
        static func report(
            _ provider: String, _ state: EEWActivityAttributes.ContentState, travelSeconds: Int,
            localScale: Int = 4, isStale: Bool = false
        ) -> EEWActivityReport? {
            guard let payload = EEWPayload(state.d, provider: provider) else { return nil }
            let estimate = EEWPresentation.hasSource(payload)
                ? EEWLocalShaking.Estimate(scale: localScale, intensity: Double(localScale), sArrivalMs: travelSeconds * 1000)
                : nil
            return EEWActivityReport(payload: payload, estimate: estimate, isStale: isStale)
        }
    }

    @available(iOS 17.0, *)
    #Preview("Lock Screen — CWA", as: .content, using: EEWActivityPreviewData.cwa) {
        EEWLiveActivity()
    } contentStates: {
        EEWActivityPreviewData.cwaStandard
        EEWActivityPreviewData.cwaEmergency
    }

    @available(iOS 17.0, *)
    #Preview("Lock Screen — TREM", as: .content, using: EEWActivityPreviewData.trem) {
        EEWLiveActivity()
    } contentStates: {
        EEWActivityPreviewData.tremUsable
        EEWActivityPreviewData.tremLow
        EEWActivityPreviewData.tremNoSource
        EEWActivityPreviewData.tremLocalFromNsspe
        EEWActivityPreviewData.tremFinal
        EEWActivityPreviewData.tremCancelled
        EEWActivityPreviewData.layoutStress
    }

    @available(iOS 17.0, *)
    #Preview("Dynamic Island — Expanded, CWA", as: .dynamicIsland(.expanded), using: EEWActivityPreviewData.cwa) {
        EEWLiveActivity()
    } contentStates: {
        EEWActivityPreviewData.cwaStandard
        EEWActivityPreviewData.cwaEmergency
    }

    @available(iOS 17.0, *)
    #Preview("Dynamic Island — Expanded, TREM", as: .dynamicIsland(.expanded), using: EEWActivityPreviewData.trem) {
        EEWLiveActivity()
    } contentStates: {
        EEWActivityPreviewData.tremUsable
        EEWActivityPreviewData.tremLow
        EEWActivityPreviewData.tremNoSource
        EEWActivityPreviewData.tremLocalFromNsspe
        EEWActivityPreviewData.tremFinal
        EEWActivityPreviewData.tremCancelled
        EEWActivityPreviewData.layoutStress
    }

    @available(iOS 17.0, *)
    #Preview("Dynamic Island — Compact", as: .dynamicIsland(.compact), using: EEWActivityPreviewData.trem) {
        EEWLiveActivity()
    } contentStates: {
        EEWActivityPreviewData.tremUsable
        EEWActivityPreviewData.tremNoSource
        EEWActivityPreviewData.tremLocalFromNsspe
        EEWActivityPreviewData.tremCancelled
        EEWActivityPreviewData.layoutStress
    }

    @available(iOS 17.0, *)
    #Preview("Dynamic Island — Minimal", as: .dynamicIsland(.minimal), using: EEWActivityPreviewData.trem) {
        EEWLiveActivity()
    } contentStates: {
        EEWActivityPreviewData.tremUsable
        EEWActivityPreviewData.tremNoSource
        EEWActivityPreviewData.tremLocalFromNsspe
        EEWActivityPreviewData.tremCancelled
    }

    /// The countdown, 抵達 from the clock, and 抵達 from the server's
    /// stale-date, with an injected estimate.
    @available(iOS 17.0, *)
    #Preview("Lock Screen — countdown and 抵達") {
        VStack(spacing: 12) {
            ForEach(
                Array(
                    [
                        EEWActivityPreviewData.report("cwa", EEWActivityPreviewData.cwaStandard, travelSeconds: 40),
                        EEWActivityPreviewData.report("trem", EEWActivityPreviewData.tremUsable, travelSeconds: 3),
                        EEWActivityPreviewData.report(
                            "cwa", EEWActivityPreviewData.cwaEmergency, travelSeconds: 40, localScale: 7, isStale: true),
                    ].compactMap { $0 }.enumerated()), id: \.offset
            ) { _, report in
                EEWLockScreenView(report: report)
                    .frame(width: 360)
                    .background(report.style.tint.color, in: RoundedRectangle(cornerRadius: 22))
            }
        }
        .padding()
        .background(.black)
    }

    /// 抵達 the way production reaches it: the server's stale-date passed.
    @available(iOS 16.2, *)
    struct EEWLiveActivityStalePreviews: PreviewProvider {
        static var previews: some View {
            Group {
                EEWActivityPreviewData.cwa
                    .previewContext(EEWActivityPreviewData.cwaStandard, isStale: true, viewKind: .content)
                    .previewDisplayName("Lock Screen — stale, CWA")
                EEWActivityPreviewData.trem
                    .previewContext(EEWActivityPreviewData.tremUsable, isStale: true, viewKind: .dynamicIsland(.expanded))
                    .previewDisplayName("Dynamic Island — stale, TREM")
            }
        }
    }
#endif
