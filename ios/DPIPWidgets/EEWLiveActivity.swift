import ActivityKit
import SwiftUI
import WidgetKit

/// The EEW Live Activity. The views and every rule they follow live in
/// ios/Shared (EEWActivityViews, EEWPresentation) so the app's tests can lay
/// them out; this file only places them.
@available(iOS 16.1, *)
struct EEWLiveActivity: Widget {
    var body: some WidgetConfiguration {
        // iOS 18 also shows a Live Activity in the Apple Watch Smart Stack.
        // Without `.small` the watch gets the compact Island pieces; with it,
        // EEWWatchView. SE-0360 lets the two branches differ in type.
        if #available(iOS 18.0, *) {
            return configuration.supplementalActivityFamilies([.small])
        }
        return configuration
    }

    private var configuration: some WidgetConfiguration {
        ActivityConfiguration(for: EEWActivityAttributes.self) { context in
            EEWActivityContent(report: EEWActivityReport(context))
        } dynamicIsland: { context in
            let report = EEWActivityReport(context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EEWIntensityBlock(
                        ordinal: report.localIntensity, live: report.localIsLive, metrics: .expanded,
                        strings: report.strings)
                        // Room for the nsspe ring, which is drawn outside.
                        .padding(4)
                        .accessibilityLabel(Text(verbatim: report.localLabel))
                        .accessibilityValue(Text(verbatim: report.strings.spokenIntensity(report.localIntensity)))
                }
                DynamicIslandExpandedRegion(.center) {
                    EEWIslandExpandedCenter(report: report)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EEWIslandExpandedArrival(report: report)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EEWIslandExpandedBottom(report: report)
                        .padding(.top, 4)
                }
            } compactLeading: {
                EEWIslandCompactLeading(report: report)
            } compactTrailing: {
                EEWIslandCompactTrailing(report: report)
            } minimal: {
                EEWIslandMinimal(report: report)
            }
            // Keep event details clear of the curved system mask.
            .contentMargins(.horizontal, 22, for: .expanded)
            .keylineTint(report.style.background.color)
        }
    }
}

/// The activity's own view: the Lock Screen card, or on iOS 18 and later the
/// watch layout when the system asks for the `.small` family.
@available(iOS 16.1, *)
private struct EEWActivityContent: View {
    let report: EEWActivityReport

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                EEWActivityFamilyContent(report: report)
            } else {
                EEWLockScreenView(report: report)
            }
        }
        .activityBackgroundTint(report.style.tint.color)
        .activitySystemActionForegroundColor(.white)
    }
}

@available(iOS 18.0, *)
private struct EEWActivityFamilyContent: View {
    @Environment(\.activityFamily) private var family
    let report: EEWActivityReport

    var body: some View {
        switch family {
        case .small: EEWWatchView(report: report)
        default: EEWLockScreenView(report: report)
        }
    }
}

@available(iOS 16.1, *)
extension EEWActivityReport {
    init(_ context: ActivityViewContext<EEWActivityAttributes>) {
        // The server marks arrival with the push's stale-date; iOS 16.1 has no
        // isStale and only ever shows an explicit arrival.
        var isStale = false
        if #available(iOS 16.2, *) { isStale = context.isStale }
        self.init(provider: context.attributes.provider, state: context.state, isStale: isStale)
    }
}

#if DEBUG
    // Canvas-only fixtures: no Activity.request, Flutter bridge, or manager state.
    @available(iOS 16.2, *)
    enum EEWActivityPreviewData {
        static let cwa = EEWActivityAttributes(provider: "cwa", eventId: "preview-cwa")
        static let trem = EEWActivityAttributes(provider: "trem", eventId: "preview-trem")

        /// CWA 地震速報 (alert 0), local 4級, max 5弱.
        static var cwaStandard: EEWActivityAttributes.ContentState {
            state(report: 2, epicenter: "花蓮縣近海", magnitude: 6.6, depth: 10, max: 5, local: 4, eta: 28, alert: 0)
        }

        /// CWA 緊急地震速報 (alert 1), local 6弱, max 6強.
        static var cwaEmergency: EEWActivityAttributes.ContentState {
            state(report: 3, epicenter: "花蓮縣壽豐鄉近海", magnitude: 7.1, depth: 15, max: 8, local: 7, eta: 12, alert: 1)
        }

        /// CWA, wave explicitly arrived: 抵達.
        static var cwaArrived: EEWActivityAttributes.ContentState {
            state(
                report: 4, epicenter: "花蓮縣近海", magnitude: 6.6, depth: 10, max: 5, local: 4, eta: -3, alert: 0,
                arrived: true)
        }

        /// TREM 精度可用 (rk 4…).
        static var tremUsable: EEWActivityAttributes.ContentState {
            state(report: 3, epicenter: "花蓮縣近海", magnitude: 5.8, depth: 20, max: 5, local: 4, eta: 21, alert: 0, rk: "4441")
        }

        /// TREM 精度低 (rk 1…), intensity not determined yet.
        static var tremLow: EEWActivityAttributes.ContentState {
            state(report: 1, epicenter: "宜蘭縣外海", magnitude: 4.6, depth: 10, max: 0, local: 0, eta: 34, alert: 0, rk: "1111")
        }

        /// TREM 無震源參數推定 (M1.0, 10 km placeholders), local from nsspe.
        static var tremNoSource: EEWActivityAttributes.ContentState {
            state(
                report: 1, epicenter: "花蓮縣近海", magnitude: 1.0, depth: 10, max: 0, local: nil, eta: 15, alert: 0,
                rk: "2111", noSource: true, localNsspe: 3, nsspeMax: 3)
        }

        /// TREM 緊急地震速報 whose local value nsspe raised: ring, 所在地・即時.
        static var tremLocalFromNsspe: EEWActivityAttributes.ContentState {
            state(
                report: 3, epicenter: "臺東縣近海", magnitude: 6.2, depth: 20, max: 4, local: 4, eta: 8, alert: 1,
                rk: "4442", localNsspe: 5, nsspeMax: 5)
        }

        /// TREM 緊急地震速報 最終報, arrived.
        static var tremFinal: EEWActivityAttributes.ContentState {
            state(
                report: 6, epicenter: "花蓮縣壽豐鄉近海", magnitude: 7.1, depth: 15, max: 8, local: 7, eta: -5, alert: 1,
                rk: "4444", isFinal: true, arrived: true)
        }

        /// TREM 取消報.
        static var tremCancelled: EEWActivityAttributes.ContentState {
            state(
                report: 2, epicenter: "花蓮縣近海", magnitude: 5.8, depth: 20, max: 4, local: 3, eta: 20, alert: 1,
                rk: "/////", cancelled: true)
        }

        /// Stretches every slot: three-digit report, long epicentre, 10:00+.
        static var layoutStress: EEWActivityAttributes.ContentState {
            state(
                report: 123, epicenter: "花蓮縣壽豐鄉東南方外海（臺灣東部海域）", magnitude: 6.1, depth: 120, max: 9,
                local: 9, eta: 653, alert: 1, rk: "4444", isFinal: true, localNsspe: 9, nsspeMax: 9)
        }

        private static func state(
            report: Int, epicenter: String, magnitude: Double, depth: Double, max: Int, local: Int?,
            eta: TimeInterval?, alert: Int, rk: String? = nil, noSource: Bool? = nil, isFinal: Bool? = nil,
            cancelled: Bool? = nil, arrived: Bool = false, localNsspe: Int? = nil, nsspeMax: Int? = nil
        ) -> EEWActivityAttributes.ContentState {
            // Refresh the absolute ETA whenever Canvas recreates the fixture.
            // Resume/reload a long-running preview to restart its countdown.
            let now = Date.now
            return EEWActivityAttributes.ContentState(
                reportNo: report, originAt: now.addingTimeInterval(-10), magnitude: magnitude, depthKm: depth,
                epicenter: epicenter, reportMaxIntensity: max, estimatedLocalIntensity: local,
                estimatedSArrivalAt: eta.map { now.addingTimeInterval($0) }, waveArrived: arrived,
                alert: alert, isFinal: isFinal, cancelled: cancelled, rk: rk, noSource: noSource,
                localNsspeIntensity: localNsspe, nsspeMaxIntensity: nsspeMax)
        }
    }

    @available(iOS 17.0, *)
    #Preview("Lock Screen — CWA", as: .content, using: EEWActivityPreviewData.cwa) {
        EEWLiveActivity()
    } contentStates: {
        EEWActivityPreviewData.cwaStandard
        EEWActivityPreviewData.cwaEmergency
        EEWActivityPreviewData.cwaArrived
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
        EEWActivityPreviewData.cwaArrived
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
        EEWActivityPreviewData.cwaStandard
        EEWActivityPreviewData.cwaArrived
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
        EEWActivityPreviewData.cwaStandard
        EEWActivityPreviewData.cwaArrived
        EEWActivityPreviewData.tremNoSource
        EEWActivityPreviewData.tremLocalFromNsspe
        EEWActivityPreviewData.tremCancelled
    }

    @available(iOS 17.0, *)
    #Preview("Apple Watch — Smart Stack") {
        @ViewBuilder func watch(_ provider: String, _ state: EEWActivityAttributes.ContentState) -> some View {
            let report = EEWActivityReport(provider: provider, state: state, isStale: false)
            EEWWatchView(report: report)
                .frame(width: 178)
                .background(report.style.tint.color, in: RoundedRectangle(cornerRadius: 20))
        }
        return VStack(spacing: 12) {
            watch("cwa", EEWActivityPreviewData.cwaStandard)
            watch("trem", EEWActivityPreviewData.tremLocalFromNsspe)
            watch("trem", EEWActivityPreviewData.tremNoSource)
            watch("trem", EEWActivityPreviewData.tremCancelled)
            watch("cwa", EEWActivityPreviewData.cwaArrived)
        }
        .padding()
        .background(.black)
    }

    /// 抵達 the way production reaches it: the server's stale-date passed while
    /// the ETA had not been explicitly marked arrived.
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
