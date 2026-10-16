import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct EEWLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EEWActivityAttributes.self) { context in
            EEWLockScreenView(context: context)
                .padding(14)
                .foregroundStyle(.secondary)
                .activitySystemActionForegroundColor(.secondary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EEWEventHeading(provider: context.attributes.provider)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 6) {
                        EEWReportNumber(number: context.state.reportNo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        EEWTestBadge()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .center, spacing: 8) {
                        EEWPrimarySummary(state: context.state, island: true)
                        EEWExpandedEventDetails(state: context.state)
                    }
                    .padding(.top, 4)
                    .foregroundStyle(.white)
                }
            } compactLeading: {
                EEWCompactIntensity(state: context.state)
            } compactTrailing: {
                EEWCompactArrival(state: context.state)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            } minimal: {
                EEWMinimalView(state: context.state)
            }
            // Keep event details clear of the curved system mask.
            .contentMargins(.horizontal, 28, for: .expanded)
            .keylineTint(.red)
        }
    }
}

@available(iOS 16.1, *)
private struct EEWLockScreenView: View {
    let context: ActivityViewContext<EEWActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                EEWEventHeading(provider: context.attributes.provider)
                    .layoutPriority(1)
                Spacer(minLength: 4)
                EEWReportNumber(number: context.state.reportNo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                EEWTestBadge()
            }
            EEWEventDetails(state: context.state)
            EEWPrimarySummary(state: context.state)
        }
    }
}

@available(iOS 16.1, *)
private struct EEWEventHeading: View {
    let provider: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg")
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            // A single text flow shares compression instead of truncating title/source separately.
            Text(
                "\(Text("eew.title").fontWeight(.semibold))\(Text(verbatim: " · " + provider).foregroundColor(.secondary))"
            )
            .layoutPriority(1)
        }
        .font(.caption)
        .foregroundStyle(.primary)
        .lineLimit(1)
        // The Island leading region must retain both title and source at large text sizes.
        .minimumScaleFactor(0.6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: NSLocalizedString("eew.title", comment: "EEW title") + " " + provider))
    }
}

@available(iOS 16.1, *)
private struct EEWPrimarySummary: View {
    let state: EEWActivityAttributes.ContentState
    var island = false

    var body: some View {
        // Each optional field falls back independently; missing personalization
        // does not identify why the local estimate or ETA is unavailable.
        let intensity = EEWPresentation.intensity(for: state)

        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .center, spacing: 4) {
                Text(LocalizedStringKey(EEWPresentation.intensityLabel(for: state)))
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                EEWIntensityValue(intensity: intensity)
                    .font(.system(size: 42, weight: .bold))
                    .frame(minHeight: 52)
                    .foregroundStyle(EEWIntensityColor.color(for: intensity))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(LocalizedStringKey(EEWPresentation.intensityLabel(for: state))))
            .accessibilityValue(EEWIntensityValue.text(intensity, spoken: true))

            VStack(alignment: .center, spacing: 4) {
                Text("eew.arrival.estimated")
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    // The live countdown supplies this label to VoiceOver.
                    .accessibilityHidden(!state.waveArrived && state.estimatedSArrivalAt != nil)
                EEWArrivalView(state: state, island: island)
                    .frame(minHeight: 52)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityElement(children: .combine)
        }
    }
}

@available(iOS 16.1, *)
private struct EEWEventDetails: View {
    let state: EEWActivityAttributes.ContentState

    var body: some View {
        // A single text flow gives long epicenters up to two lines without
        // displacing magnitude/depth into a separate compressed column.
        Text(verbatim: EEWEventDetailText(state: state).full)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(Text(verbatim: EEWEventDetailText(state: state).spoken))
    }
}

@available(iOS 16.1, *)
private struct EEWExpandedEventDetails: View {
    let state: EEWActivityAttributes.ContentState

    var body: some View {
        let details = EEWEventDetailText(state: state)

        ViewThatFits(in: .horizontal) {
            // Measure the richer candidates at their full single-line width,
            // so truncation cannot make them win before detail is reduced.
            Text(verbatim: details.full)
                .fixedSize(horizontal: true, vertical: false)
            Text(verbatim: details.epicenterMagnitude)
                .fixedSize(horizontal: true, vertical: false)
            Text(verbatim: state.epicenter)
                .truncationMode(.tail)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        // Visual reduction must not remove event information from VoiceOver.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: details.spoken))
    }
}

@available(iOS 16.1, *)
private struct EEWEventDetailText {
    let state: EEWActivityAttributes.ContentState

    var spoken: String {
        String(
            format: NSLocalizedString("eew.details.spoken.format", comment: "Spoken earthquake details"),
            state.epicenter, state.magnitude, state.depthKm)
    }

    var epicenterMagnitude: String {
        state.epicenter + " · " + String(format: "M%.1f", state.magnitude)
    }

    var full: String {
        epicenterMagnitude + " · "
            + String(
                format: "%@ %.0f km",
                NSLocalizedString("eew.depth", comment: "Earthquake depth"), state.depthKm)
    }
}

@available(iOS 16.1, *)
private struct EEWTestBadge: View {
    var body: some View {
        // All Phase 1 activities are mock data, including non-DEBUG builds.
        // Keep the marker until a production contract explicitly identifies tests.
        Text("eew.test.short")
            .font(.caption2.bold())
            .foregroundStyle(.gray)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(.gray.opacity(0.15), in: Capsule())
            .lineLimit(1)
            .fixedSize()
            .accessibilityLabel(Text("eew.test.spoken"))
    }
}

@available(iOS 16.1, *)
private struct EEWReportNumber: View {
    let number: Int

    var body: some View {
        Text(String(format: NSLocalizedString("eew.report.format", comment: "EEW report number"), number))
            .monospacedDigit()
            .lineLimit(1)
            // Preserve the complete report ordinal in the Island at large text sizes.
            .minimumScaleFactor(0.7)
    }
}

@available(iOS 16.1, *)
private struct EEWIntensityValue: View {
    let intensity: Int
    var compact = false

    var body: some View { Self.text(intensity, compact: compact) }

    static func badgeText(_ intensity: Int) -> Text {
        let content = EEWPresentation.intensityText(intensity, compact: true)
        // Omit only the unit. Localized weak/strong labels remain indivisible.
        if let level = content.level { return Text(level, format: .number) }
        return text(intensity, compact: true)
    }

    static func text(_ intensity: Int, compact: Bool = false, spoken: Bool = false) -> Text {
        let content = EEWPresentation.intensityText(intensity, compact: compact, spoken: spoken)
        if let level = content.level {
            return Text(String(format: NSLocalizedString(content.key, comment: "Intensity level"), level))
        }
        return Text(LocalizedStringKey(content.key))
    }
}

@available(iOS 16.1, *)
private struct EEWArrivalView: View {
    let state: EEWActivityAttributes.ContentState
    var island = false

    var body: some View {
        switch EEWPresentation.arrival(for: state) {
        case .arrived:
            Text("eew.arrived.short")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        case .countdown(let arrival):
            EEWCountdown(arrival: arrival, island: island)
                .font(.system(size: 42, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        case .unavailable:
            Text("eew.unavailable")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

@available(iOS 16.1, *)
private struct EEWCountdown: View {
    let arrival: Date
    var island = false

    var body: some View {
        // Compatibility fallback: this Apple timer keeps updating in the system
        // renderer while the app/extension is suspended, and clamps at zero.
        // There is no verified seconds-only replacement in the installed SDK:
        // Timer(maxFieldCount: 1) switches to minutes above 60 seconds;
        // DateOffset(fields: [.second], sign: .never) counts up after the ETA;
        // dateRange(endingAt:) + ComponentsFormatStyle stalls in Live Activities.
        // Do not replace it with a static string or a custom DiscreteFormatStyle.
        // Reaching zero never infers waveArrived or ends the existing activity.
        let now = Date.now
        let timer = Text(timerInterval: now...max(arrival, now), countsDown: true, showsHours: false)
        timer
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .foregroundStyle(island ? Color.white : Color.primary)
            .accessibilityLabel(Text("eew.arrival.estimated"))
            .accessibilityValue(timer)
    }
}

@available(iOS 16.1, *)
private struct EEWCompactIntensity: View {
    let state: EEWActivityAttributes.ContentState

    var body: some View {
        EEWIslandWidthReader { limited in
            EEWIslandIntensityPresentation(
                intensity: EEWPresentation.intensity(for: state), limitedInWidth: limited
            ) {
                EEWIntensityValue.badgeText(EEWPresentation.intensity(for: state))
            } testBadge: {
                EEWTestBadge()
            }
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedStringKey(EEWPresentation.intensityLabel(for: state))))
        .accessibilityValue(EEWIntensityValue.text(EEWPresentation.intensity(for: state), spoken: true))
        .accessibilityHint(Text("eew.test.spoken"))
    }
}

@available(iOS 16.1, *)
private struct EEWCompactArrival: View {
    let state: EEWActivityAttributes.ContentState

    var body: some View {
        EEWIslandWidthReader { limited in
            EEWIslandFittingView(limitedInWidth: limited) {
                arrival
            } compact: {
                arrival.font(.caption2.bold())
            } fallback: {
                EEWIslandArrivalSymbol(state: state)
            }
        }
    }

    @ViewBuilder private var arrival: some View {
        switch EEWPresentation.arrival(for: state) {
        case .arrived:
            Text("eew.arrived.short")
                .accessibilityLabel(Text("eew.arrival.estimated"))
                .accessibilityValue(Text("eew.arrived.short"))
        case .countdown(let arrival):
            EEWIslandTimerEnvelope(sample: EEWPresentation.islandTimerSample(for: state, now: .now)) {
                EEWCountdown(arrival: arrival, island: true)
            }
        case .unavailable:
            EEWIslandArrivalSymbol(state: state)
        }
    }
}

@available(iOS 16.1, *)
private struct EEWIslandArrivalSymbol: View {
    let state: EEWActivityAttributes.ContentState

    var body: some View {
        Image(systemName: EEWPresentation.islandArrivalSymbol(for: state))
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 14, maxHeight: 14)
            .foregroundStyle(EEWPresentation.arrival(for: state) == .unavailable ? .secondary : .primary)
            // Preserve live countdown semantics for VoiceOver even if the visible
            // slot can only fit a clock. Never announce this as an arrived state.
            .accessibilityRepresentation {
                switch EEWPresentation.arrival(for: state) {
                case .countdown(let arrival):
                    EEWCountdown(arrival: arrival, island: true)
                case .arrived:
                    Text("eew.arrived.short")
                        .accessibilityLabel(Text("eew.arrival.estimated"))
                        .accessibilityValue(Text("eew.arrived.short"))
                case .unavailable:
                    Text("eew.unavailable")
                        .accessibilityLabel(Text("eew.arrival.estimated"))
                        .accessibilityValue(Text("eew.unavailable"))
                }
            }
    }
}

@available(iOS 16.1, *)
private struct EEWMinimalView: View {
    let state: EEWActivityAttributes.ContentState

    var body: some View {
        EEWIslandWidthReader { limited in
            EEWIslandFittingView(limitedInWidth: limited) {
                HStack(spacing: 4) {
                    EEWIslandIntensityBadge(intensity: EEWPresentation.intensity(for: state), dense: true) {
                        EEWIntensityValue.badgeText(EEWPresentation.intensity(for: state))
                    }
                    arrival
                }
            } compact: {
                // A limited-width hint does not justify discarding a timer that
                // actually fits. Minimal already uses the smallest approved font.
                arrival
            } fallback: {
                EEWIslandArrivalSymbol(state: state)
            }
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .accessibilityRepresentation {
            HStack {
                EEWIntensityValue.text(EEWPresentation.intensity(for: state), spoken: true)
                    .accessibilityLabel(Text(LocalizedStringKey(EEWPresentation.intensityLabel(for: state))))
                    .accessibilityValue(EEWIntensityValue.text(EEWPresentation.intensity(for: state), spoken: true))
                arrival
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("eew.test.spoken"))
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("eew.test.spoken"))
    }

    @ViewBuilder private var arrival: some View {
        switch EEWPresentation.arrival(for: state) {
        case .countdown(let arrival):
            EEWIslandTimerEnvelope(sample: EEWPresentation.islandTimerSample(for: state, now: .now)) {
                EEWCountdown(arrival: arrival, island: true)
            }
            .font(.caption2.bold())
        case .arrived:
            EEWIslandArrivalSymbol(state: state)
        case .unavailable:
            Image(systemName: "waveform.path.ecg")
                .foregroundStyle(.red)
                .accessibilityLabel(Text("eew.arrival.estimated"))
                .accessibilityValue(Text("eew.unavailable"))
        }
    }
}

#if DEBUG
    // Canvas-only fixtures: no Activity.request, Flutter bridge, or manager state.
    @available(iOS 17.0, *)
    private enum EEWActivityPreviewData {
        static let personalizedAttributes = EEWActivityAttributes(
            provider: "CWA", eventId: "preview-personalized"
        )
        static let genericAttributes = EEWActivityAttributes(
            provider: "CWA", eventId: "preview-generic"
        )

        static var personalized: EEWActivityAttributes.ContentState { state() }
        static var generic: EEWActivityAttributes.ContentState {
            state(localIntensity: nil, arrivalDelay: nil)
        }
        static var intensityOnly: EEWActivityAttributes.ContentState {
            state(arrivalDelay: nil)
        }
        static var arrivalOnly: EEWActivityAttributes.ContentState {
            state(localIntensity: nil)
        }
        static var waveArrived: EEWActivityAttributes.ContentState { state(waveArrived: true) }
        static var seconds125: EEWActivityAttributes.ContentState { state(arrivalDelay: 125) }
        static var seconds65: EEWActivityAttributes.ContentState { state(arrivalDelay: 65) }
        static var seconds35: EEWActivityAttributes.ContentState { state(arrivalDelay: 35) }
        static var seconds9: EEWActivityAttributes.ContentState { state(arrivalDelay: 9) }
        static var zeroETA: EEWActivityAttributes.ContentState { state(arrivalDelay: 0) }
        static var expiredETA: EEWActivityAttributes.ContentState { state(arrivalDelay: -5) }
        static var intensity6Weak: EEWActivityAttributes.ContentState { state(localIntensity: 7) }
        static var intensity6Strong: EEWActivityAttributes.ContentState { state(localIntensity: 8) }
        static var intensity7: EEWActivityAttributes.ContentState { state(localIntensity: 9) }
        static var layoutStress: EEWActivityAttributes.ContentState {
            state(
                reportNo: 123, epicenter: "花蓮縣壽豐鄉東南方外海（臺灣東部海域）",
                localIntensity: 6, arrivalDelay: 653)
        }

        private static func state(
            waveArrived: Bool = false,
            reportNo: Int = 4, epicenter: String = "臺東縣近海",
            localIntensity: Int? = 4, arrivalDelay: TimeInterval? = 60
        ) -> EEWActivityAttributes.ContentState {
            // Refresh the absolute ETA whenever Canvas recreates the fixture.
            // Resume/reload a long-running preview to restart its countdown.
            let now = Date.now
            return EEWActivityAttributes.ContentState(
                reportNo: reportNo,
                originAt: now.addingTimeInterval(-10),
                magnitude: 6.1,
                depthKm: 20,
                epicenter: epicenter,
                reportMaxIntensity: 5,
                estimatedLocalIntensity: localIntensity,
                estimatedSArrivalAt: arrivalDelay.map {
                    now.addingTimeInterval(waveArrived ? -1 : $0)
                },
                waveArrived: waveArrived
            )
        }
    }

    @available(iOS 17.0, *)
    #Preview(
        "Lock Screen — Personalized", as: .content,
        using: EEWActivityPreviewData.personalizedAttributes) {
            EEWLiveActivity()
        } contentStates: {
            EEWActivityPreviewData.personalized
            EEWActivityPreviewData.seconds125
            EEWActivityPreviewData.seconds65
            EEWActivityPreviewData.seconds35
            EEWActivityPreviewData.seconds9
            EEWActivityPreviewData.zeroETA
            EEWActivityPreviewData.expiredETA
            EEWActivityPreviewData.intensity6Weak
            EEWActivityPreviewData.intensity6Strong
            EEWActivityPreviewData.intensity7
        }

    @available(iOS 17.0, *)
    #Preview(
        "Lock Screen — Generic", as: .content,
        using: EEWActivityPreviewData.genericAttributes) {
            EEWLiveActivity()
        } contentStates: {
            EEWActivityPreviewData.generic
        }

    @available(iOS 17.0, *)
    #Preview(
        "Lock Screen — Partial Personalization", as: .content,
        using: EEWActivityPreviewData.personalizedAttributes) {
            EEWLiveActivity()
        } contentStates: {
            EEWActivityPreviewData.intensityOnly
            EEWActivityPreviewData.arrivalOnly
        }

    @available(iOS 17.0, *)
    #Preview(
        "Lock Screen — Wave Arrived", as: .content,
        using: EEWActivityPreviewData.personalizedAttributes) {
            EEWLiveActivity()
        } contentStates: {
            EEWActivityPreviewData.waveArrived
        }

    @available(iOS 17.0, *)
    #Preview(
        "Lock Screen — Long Epicenter", as: .content,
        using: EEWActivityPreviewData.personalizedAttributes) {
            EEWLiveActivity()
        } contentStates: {
            EEWActivityPreviewData.layoutStress
        }

    @available(iOS 17.0, *)
    #Preview(
        "Dynamic Island — Expanded", as: .dynamicIsland(.expanded),
        using: EEWActivityPreviewData.personalizedAttributes) {
            EEWLiveActivity()
        } contentStates: {
            EEWActivityPreviewData.seconds125
            EEWActivityPreviewData.seconds65
            EEWActivityPreviewData.seconds35
            EEWActivityPreviewData.seconds9
            EEWActivityPreviewData.zeroETA
            EEWActivityPreviewData.expiredETA
            EEWActivityPreviewData.intensity6Weak
            EEWActivityPreviewData.intensity6Strong
            EEWActivityPreviewData.intensity7
            EEWActivityPreviewData.personalized
            EEWActivityPreviewData.generic
            EEWActivityPreviewData.intensityOnly
            EEWActivityPreviewData.arrivalOnly
            EEWActivityPreviewData.waveArrived
            EEWActivityPreviewData.layoutStress
        }

    @available(iOS 17.0, *)
    #Preview(
        "Dynamic Island — Compact", as: .dynamicIsland(.compact),
        using: EEWActivityPreviewData.personalizedAttributes) {
            EEWLiveActivity()
        } contentStates: {
            EEWActivityPreviewData.seconds125
            EEWActivityPreviewData.seconds65
            EEWActivityPreviewData.seconds35
            EEWActivityPreviewData.seconds9
            EEWActivityPreviewData.zeroETA
            EEWActivityPreviewData.expiredETA
            EEWActivityPreviewData.intensity6Weak
            EEWActivityPreviewData.intensity6Strong
            EEWActivityPreviewData.intensity7
            EEWActivityPreviewData.personalized
            EEWActivityPreviewData.generic
            EEWActivityPreviewData.intensityOnly
            EEWActivityPreviewData.arrivalOnly
            EEWActivityPreviewData.waveArrived
            EEWActivityPreviewData.layoutStress
        }

    @available(iOS 17.0, *)
    #Preview(
        "Dynamic Island — Minimal", as: .dynamicIsland(.minimal),
        using: EEWActivityPreviewData.personalizedAttributes) {
            EEWLiveActivity()
        } contentStates: {
            EEWActivityPreviewData.seconds125
            EEWActivityPreviewData.seconds65
            EEWActivityPreviewData.seconds35
            EEWActivityPreviewData.seconds9
            EEWActivityPreviewData.zeroETA
            EEWActivityPreviewData.expiredETA
            EEWActivityPreviewData.intensity6Weak
            EEWActivityPreviewData.intensity6Strong
            EEWActivityPreviewData.intensity7
            EEWActivityPreviewData.personalized
            EEWActivityPreviewData.generic
            EEWActivityPreviewData.intensityOnly
            EEWActivityPreviewData.arrivalOnly
            EEWActivityPreviewData.waveArrived
            EEWActivityPreviewData.layoutStress
        }
#endif
