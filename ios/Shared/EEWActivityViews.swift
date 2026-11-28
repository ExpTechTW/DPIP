import SwiftUI
import WidgetKit

/// One report, resolved for display: what every EEW Live Activity view reads.
/// Shared with the app so the native tests can lay the views out.
@available(iOS 16.1, *)
struct EEWActivityReport {
    let provider: EEWPresentation.Provider
    let state: EEWActivityAttributes.ContentState
    let isStale: Bool
    let strings: EEWStrings

    init(
        provider: String, state: EEWActivityAttributes.ContentState, isStale: Bool,
        strings: EEWStrings = .main
    ) {
        self.provider = EEWPresentation.Provider(provider)
        self.state = state
        self.isStale = isStale
        self.strings = strings
    }

    var kind: EEWPresentation.Kind { EEWPresentation.kind(for: state) }
    var style: EEWPresentation.Style { EEWPresentation.style(for: state, provider: provider) }
    var precision: EEWPresentation.Precision? { EEWPresentation.precision(for: state, provider: provider) }
    var localIntensity: Int? { EEWPresentation.localIntensity(for: state) }
    var localIsLive: Bool { EEWPresentation.localIsLive(for: state) }
    var maxIntensity: Int? { EEWPresentation.maxIntensity(for: state) }
    var arrival: EEWPresentation.Arrival { EEWPresentation.arrival(for: state, isStale: isStale) }
    var note: EEWPresentation.Note? { EEWPresentation.note(for: state, provider: provider) }
    var showsDisclaimer: Bool { EEWPresentation.showsDisclaimer(provider) }

    var kindText: String { strings.kind(kind) }
    var reportNumber: String { strings.reportNumber(state) }
    var sourceText: String { strings.source(provider) }
    var originTime: String { EEWStrings.originTime(state.originAt) }
    var epicenter: String { strings.epicenter(state) }
    var magnitude: String { strings.magnitude(state) }
    var depth: String { strings.depth(state) }
    var localLabel: String { strings.localLabel(live: localIsLive) }
    var arrivalLabel: String { strings.arrivalLabel(arrival) }
    var maxEstimate: String { strings.maxEstimate(maxIntensity) }
    var noteText: String? { note.map(strings.note) }
}

/// Type and the few greys every presentation shares, from the design canvas.
@available(iOS 16.1, *)
enum EEWActivityStyle {
    static let secondary = EEWRGB(integerLiteral: 0xAEAEB2).color
    static let tertiary = EEWRGB(integerLiteral: 0xC7C7CC).color
    static let quiet = EEWRGB(integerLiteral: 0x8E8E93).color
    static let noteText = EEWRGB(integerLiteral: 0xE5E5EA).color

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Pieces

/// The intensity block: a fixed square in the intensity colour, the level
/// large and 級/弱/強 small. A township in the nsspe list gets a white ring,
/// separated from the block by a gap of whatever lies behind it. It never
/// flashes — a Live Activity cannot animate continuously, and a ring is
/// readable at a glance.
@available(iOS 16.1, *)
struct EEWIntensityBlock: View {
    struct Metrics {
        let side: CGFloat
        let radius: CGFloat
        let digit: CGFloat
        let unit: CGFloat
        let ringGap: CGFloat
        let ringWidth: CGFloat

        static let lockScreen = Metrics(side: 56, radius: 14, digit: 32, unit: 13, ringGap: 2, ringWidth: 2.5)
        static let expanded = Metrics(side: 48, radius: 13, digit: 28, unit: 12, ringGap: 2, ringWidth: 2)
        static let watch = Metrics(side: 40, radius: 11, digit: 24, unit: 10, ringGap: 2, ringWidth: 2)
    }

    let ordinal: Int?
    let live: Bool
    let metrics: Metrics
    let strings: EEWStrings

    var body: some View {
        let label = strings.intensity(ordinal)
        let parts = Self.split(label)
        // 級/弱/強 are drawn small; English's −/+ would sink to a dot at that
        // size, so a symbol suffix keeps the number's size.
        let symbolSuffix = !parts.suffix.isEmpty && parts.suffix.allSatisfy(\.isMathSymbol)
        HStack(alignment: .lastTextBaseline, spacing: 1) {
            if !parts.prefix.isEmpty { Text(verbatim: parts.prefix).font(.system(size: metrics.unit, weight: .bold)) }
            Text(verbatim: symbolSuffix ? parts.number + parts.suffix : parts.number)
                .font(EEWActivityStyle.rounded(metrics.digit))
            if !parts.suffix.isEmpty && !symbolSuffix {
                Text(verbatim: parts.suffix).font(.system(size: metrics.unit, weight: .bold))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundStyle(EEWIntensityColor.foreground(for: ordinal).color)
        .frame(width: metrics.side, height: metrics.side)
        .background(
            EEWIntensityColor.color(for: ordinal),
            in: RoundedRectangle(cornerRadius: metrics.radius, style: .continuous)
        )
        .modifier(EEWLiveRing(live: live, radius: metrics.radius, gap: metrics.ringGap, width: metrics.ringWidth))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: strings.spokenIntensity(ordinal)))
    }

    /// "5弱" → ("", "5", "弱"); "Level 5" would be ("Level ", "5", ""). The
    /// number is drawn large whatever the language puts around it.
    static func split(_ label: String) -> (prefix: String, number: String, suffix: String) {
        guard let start = label.firstIndex(where: \.isNumber) else { return ("", label, "") }
        let end = label[start...].firstIndex(where: { !$0.isNumber }) ?? label.endIndex
        return (String(label[..<start]), String(label[start..<end]), String(label[end...]))
    }
}

/// The nsspe ring, drawn outside the block so it never moves the layout.
@available(iOS 16.1, *)
struct EEWLiveRing: ViewModifier {
    let live: Bool
    let radius: CGFloat
    let gap: CGFloat
    let width: CGFloat

    func body(content: Content) -> some View {
        content.overlay {
            if live {
                let outset = gap + width / 2
                RoundedRectangle(cornerRadius: radius + outset, style: .continuous)
                    .stroke(Color.white, lineWidth: width)
                    .padding(-outset)
                    .accessibilityHidden(true)
            }
        }
    }
}

@available(iOS 16.1, *)
struct EEWKindBadge: View {
    let report: EEWActivityReport
    var size: CGFloat = 11

    var body: some View {
        let style = report.style
        Text(verbatim: report.kindText)
            .font(.system(size: size, weight: .heavy))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 6)
            .frame(height: size + 5)
            .foregroundStyle(style.foreground.color)
            .background(style.background.color, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}

/// ■ 最大預估 5弱 — a small square, not a second intensity block, so it is
/// never mistaken for the user's own intensity.
@available(iOS 16.1, *)
struct EEWMaxEstimate: View {
    let report: EEWActivityReport
    var square: CGFloat = 8

    var body: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(EEWIntensityColor.color(for: report.maxIntensity))
                .frame(width: square, height: square)
                .accessibilityHidden(true)
            Text(verbatim: report.maxEstimate)
                .lineLimit(1)
        }
        .font(.system(size: 11))
        .foregroundStyle(EEWActivityStyle.tertiary)
    }
}

/// A system countdown to the ETA. It keeps running in the system renderer
/// while the extension is suspended and clamps at zero; reaching zero is not
/// arrival (see `EEWPresentation.arrival`).
@available(iOS 16.1, *)
struct EEWCountdown: View {
    let arrival: Date

    var body: some View {
        // There is no verified seconds-only replacement in the installed SDK:
        // Timer(maxFieldCount: 1) switches to minutes above 60 seconds;
        // DateOffset(fields: [.second], sign: .never) counts up after the ETA;
        // dateRange(endingAt:) + ComponentsFormatStyle stalls in Live Activities.
        // Do not replace it with a static string or a custom DiscreteFormatStyle.
        let now = Date.now
        let timer = Text(timerInterval: now...max(arrival, now), countsDown: true, showsHours: false)
        timer
            .monospacedDigit()
            .accessibilityLabel(Text(eew: "eew.label.arrival"))
            .accessibilityValue(timer)
    }
}

/// What sits under 震波預計抵達: the countdown, 抵達, 未提供 or 取消.
@available(iOS 16.1, *)
struct EEWArrivalSlot: View {
    struct Metrics {
        let countdown: CGFloat
        let arrived: CGFloat
        let text: CGFloat

        static let lockScreen = Metrics(countdown: 34, arrived: 24, text: 20)
        static let expanded = Metrics(countdown: 30, arrived: 20, text: 15)
        static let watch = Metrics(countdown: 28, arrived: 20, text: 18)
    }

    let report: EEWActivityReport
    let metrics: Metrics
    var alignment: TextAlignment = .trailing

    var body: some View {
        switch report.arrival {
        case .countdown(let arrival):
            EEWCountdown(arrival: arrival)
                .font(EEWActivityStyle.rounded(metrics.countdown))
                .multilineTextAlignment(alignment)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        case .arrived:
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: metrics.arrived * 0.75, weight: .heavy))
                    .accessibilityHidden(true)
                Text(verbatim: report.strings.slot(.arrived) ?? "")
                    .font(.system(size: metrics.arrived, weight: .heavy))
            }
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        case .unavailable, .cancelled:
            Text(verbatim: report.strings.slot(report.arrival) ?? "")
                .font(.system(size: metrics.text, weight: .bold))
                .foregroundStyle(EEWActivityStyle.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - Lock Screen

/// The Lock Screen (and StandBy) card. Everything has a fixed place:
///
///     [kind] #3 01:48:25                    ● 精度可用 | 氣象署
///     所在地預估 │ 震源               │ 震波預計抵達
///     [ 5弱 ]   │ 花蓮縣近海          │        0:21
///               │ M5.8 20 km         │
///               │ ■ 最大預估 5弱      │
///     note (TREM)
///     TREM · 最終結果應以氣象署發布之內容為準
///
/// It stays under the system's 160 pt height limit, so the sizes are fixed
/// rather than Dynamic Type: a card that grew would be cut off instead.
@available(iOS 16.1, *)
struct EEWLockScreenView: View {
    let report: EEWActivityReport

    static let tableSpacing: CGFloat = 12
    static let localColumn: CGFloat = 72
    static let arrivalColumn: CGFloat = 92

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleRow
            table
            if report.showsDisclaimer {
                VStack(alignment: .leading, spacing: 2) {
                    // The line is kept even without a note, so the disclaimer
                    // never moves.
                    Text(verbatim: report.noteText ?? " ")
                        .font(.system(size: 12))
                        .foregroundStyle(EEWActivityStyle.noteText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(height: 16)
                        .accessibilityHidden(report.noteText == nil)
                    Text(verbatim: "TREM · " + report.strings.disclaimer)
                        .font(.system(size: 11))
                        .foregroundStyle(EEWActivityStyle.quiet)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(height: 14)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(.white)
    }

    private var titleRow: some View {
        HStack(spacing: 6) {
            EEWKindBadge(report: report)
            Text(verbatim: report.reportNumber)
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
            Text(verbatim: report.originTime)
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(EEWActivityStyle.secondary)
            Spacer(minLength: 4)
            EEWHeaderTrailing(report: report)
        }
        .lineLimit(1)
        .frame(height: 16)
    }

    private var table: some View {
        HStack(alignment: .top, spacing: Self.tableSpacing) {
            VStack(spacing: 6) {
                label(report.localLabel, live: report.localIsLive)
                    .frame(maxWidth: .infinity, alignment: .center)
                EEWIntensityBlock(
                    ordinal: report.localIntensity, live: report.localIsLive, metrics: .lockScreen,
                    strings: report.strings)
            }
            .frame(width: Self.localColumn)
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 6) {
                label(report.strings.sourceLabel, live: false)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: report.epicenter)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(verbatim: report.magnitude)
                            .font(EEWActivityStyle.rounded(19))
                        Text(verbatim: report.depth)
                            .font(.system(size: 12))
                            .foregroundStyle(EEWActivityStyle.secondary)
                    }
                    .monospacedDigit()
                    .lineLimit(1)
                    Spacer(minLength: 0)
                    EEWMaxEstimate(report: report)
                }
                .frame(height: EEWIntensityBlock.Metrics.lockScreen.side)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            VStack(alignment: .trailing, spacing: 6) {
                label(report.arrivalLabel, live: false)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                EEWArrivalSlot(report: report, metrics: .lockScreen)
                    .frame(
                        width: Self.arrivalColumn, height: EEWIntensityBlock.Metrics.lockScreen.side,
                        alignment: .trailing)
            }
            .frame(width: Self.arrivalColumn)
            .accessibilityElement(children: .combine)
        }
    }

    private func label(_ text: String, live: Bool) -> some View {
        Text(verbatim: text)
            .font(.system(size: 11, weight: live ? .bold : .regular))
            .foregroundStyle(live ? Color.white : EEWActivityStyle.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(height: 13)
    }
}

/// Right of the title: 氣象署 for CWA, the precision dot and text for TREM.
@available(iOS 16.1, *)
struct EEWHeaderTrailing: View {
    let report: EEWActivityReport

    var body: some View {
        HStack(spacing: 5) {
            if let precision = report.precision {
                Circle()
                    .fill(EEWPresentation.precisionDot(precision).color)
                    .frame(width: 7, height: 7)
                    .accessibilityHidden(true)
                Text(verbatim: report.strings.precision(precision))
            } else if report.provider == .cwa {
                Text(verbatim: report.sourceText)
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(EEWActivityStyle.secondary)
        .lineLimit(1)
    }
}

// MARK: - Dynamic Island

/// Expanded, centre: the epicentre over `M6.6 · 10 km · #3`.
@available(iOS 16.1, *)
struct EEWIslandExpandedCenter: View {
    let report: EEWActivityReport

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: report.epicenter)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .truncationMode(.tail)
            Text("\(Text(verbatim: report.magnitude).fontWeight(.bold).foregroundColor(.white))\(Text(verbatim: " · \(report.depth) · \(report.reportNumber)"))")
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(EEWActivityStyle.secondary)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Expanded, bottom: kind · source · time | ■ 最大預估, and the TREM
/// disclaimer.
@available(iOS 16.1, *)
struct EEWIslandExpandedBottom: View {
    let report: EEWActivityReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                EEWKindBadge(report: report, size: 10)
                Text(verbatim: "\(report.sourceText) · \(report.originTime)")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(EEWActivityStyle.quiet)
                    .lineLimit(1)
                Spacer(minLength: 4)
                EEWMaxEstimate(report: report, square: 7)
            }
            if report.showsDisclaimer {
                Text(verbatim: report.strings.disclaimer)
                    .font(.system(size: 10))
                    .foregroundStyle(EEWActivityStyle.quiet)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

/// Expanded, trailing: the countdown at 30 pt, or 抵達 / 未提供 / 取消.
@available(iOS 16.1, *)
struct EEWIslandExpandedArrival: View {
    let report: EEWActivityReport

    var body: some View {
        Group {
            if case .countdown = report.arrival {
                // A timer Text is greedy in a widget host; the envelope gives
                // it the width of its widest value instead of the region's.
                EEWIslandTimerEnvelope(sample: EEWPresentation.islandTimerSample(for: report.state, now: .now)) {
                    EEWArrivalSlot(report: report, metrics: .expanded, alignment: .center)
                }
                .font(EEWActivityStyle.rounded(EEWArrivalSlot.Metrics.expanded.countdown))
            } else {
                EEWArrivalSlot(report: report, metrics: .expanded)
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

/// Compact, leading: the intensity block and the source. The fitting view
/// drops the source, then shrinks the block, before anything is clipped.
@available(iOS 16.1, *)
struct EEWIslandCompactLeading: View {
    let report: EEWActivityReport

    var body: some View {
        EEWIslandWidthReader { limited in
            EEWIslandIntensityPresentation(
                intensity: report.localIntensity, live: report.localIsLive, limitedInWidth: limited
            ) {
                Text(verbatim: report.strings.compactIntensity(report.localIntensity))
            } source: {
                Text(verbatim: report.sourceText)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(EEWActivityStyle.tertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: report.localLabel))
        .accessibilityValue(Text(verbatim: report.strings.spokenIntensity(report.localIntensity)))
        .accessibilityHint(Text(verbatim: report.sourceText))
    }
}

/// Compact, trailing: the countdown, 抵達, 未提供 or 取消, then the same a
/// size smaller; a symbol only when even that does not fit.
@available(iOS 16.1, *)
struct EEWIslandCompactTrailing: View {
    let report: EEWActivityReport

    var body: some View {
        EEWIslandWidthReader { limited in
            EEWIslandFittingView(limitedInWidth: limited) {
                slot(scale: 1)
            } compact: {
                slot(scale: 0.8)
            } fallback: {
                EEWIslandArrivalSymbol(report: report)
            }
        }
    }

    // Sizes go in here rather than on the candidate: an inner font wins over
    // an outer one, so `.font` on a finished slot would not shrink it.
    @ViewBuilder private func slot(scale: CGFloat) -> some View {
        switch report.arrival {
        case .countdown(let arrival):
            EEWIslandTimerEnvelope(sample: EEWPresentation.islandTimerSample(for: report.state, now: .now)) {
                EEWCountdown(arrival: arrival)
                    .foregroundStyle(.white)
            }
            .font(EEWActivityStyle.rounded(14 * scale))
        case .arrived:
            HStack(spacing: 3) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11 * scale, weight: .heavy))
                    .accessibilityHidden(true)
                Text(verbatim: report.strings.slot(.arrived) ?? "")
            }
            .font(.system(size: 13 * scale, weight: .heavy))
            .foregroundStyle(.white)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(verbatim: report.arrivalLabel))
        case .unavailable, .cancelled:
            Text(verbatim: report.strings.slot(report.arrival) ?? "")
                .font(.system(size: 13 * scale, weight: .bold))
                .foregroundStyle(EEWActivityStyle.tertiary)
                .accessibilityLabel(Text(verbatim: report.arrivalLabel))
                .accessibilityValue(Text(verbatim: report.strings.slot(report.arrival) ?? ""))
        }
    }
}

@available(iOS 16.1, *)
struct EEWIslandArrivalSymbol: View {
    let report: EEWActivityReport

    var body: some View {
        Image(systemName: EEWPresentation.islandArrivalSymbol(for: report.arrival))
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 14, maxHeight: 14)
            .foregroundStyle(.white)
            // The visible slot may only fit a symbol; VoiceOver still gets
            // the live countdown or the state, never a guessed arrival.
            .accessibilityRepresentation {
                switch report.arrival {
                case .countdown(let arrival):
                    EEWCountdown(arrival: arrival)
                case .arrived, .unavailable, .cancelled:
                    Text(verbatim: report.strings.slot(report.arrival) ?? "")
                        .accessibilityLabel(Text(verbatim: report.arrivalLabel))
                }
            }
    }
}

/// Minimal: the intensity block and the countdown, then the countdown alone,
/// then a symbol.
@available(iOS 16.1, *)
struct EEWIslandMinimal: View {
    let report: EEWActivityReport

    var body: some View {
        EEWIslandWidthReader { limited in
            EEWIslandFittingView(limitedInWidth: limited) {
                HStack(spacing: 4) {
                    EEWIslandIntensityBadge(intensity: report.localIntensity, live: report.localIsLive, dense: true) {
                        Text(verbatim: report.strings.compactIntensity(report.localIntensity))
                    }
                    arrival
                }
            } compact: {
                arrival
            } fallback: {
                EEWIslandArrivalSymbol(report: report)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var arrival: some View {
        switch report.arrival {
        case .countdown(let arrival):
            EEWIslandTimerEnvelope(sample: EEWPresentation.islandTimerSample(for: report.state, now: .now)) {
                EEWCountdown(arrival: arrival)
                    .foregroundStyle(.white)
            }
            .font(EEWActivityStyle.rounded(11))
        case .arrived, .unavailable, .cancelled:
            EEWIslandArrivalSymbol(report: report)
        }
    }
}

// MARK: - Apple Watch

/// The Smart Stack layout (`.small`). Same order as the phone, same colours,
/// ring and "—" rules; depth, the maximum estimate and the notes do not fit
/// and stay on the phone.
///
///     [kind] #2                  氣象署
///     花蓮縣近海                   M6.6
///     所在地預估        震波預計抵達
///     [ 4級 ]          0:28
@available(iOS 16.1, *)
struct EEWWatchView: View {
    let report: EEWActivityReport

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                EEWKindBadge(report: report, size: 10)
                Text(verbatim: report.reportNumber)
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                Spacer(minLength: 4)
                Text(verbatim: report.sourceText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(EEWActivityStyle.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: report.epicenter)
                    .font(.system(size: 12, weight: .semibold))
                    .truncationMode(.tail)
                Spacer(minLength: 0)
                Text(verbatim: report.magnitude)
                    .font(EEWActivityStyle.rounded(13))
                    .monospacedDigit()
                    .layoutPriority(1)
            }
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: report.localLabel)
                        .font(.system(size: 10, weight: report.localIsLive ? .bold : .regular))
                        .foregroundStyle(report.localIsLive ? Color.white : EEWActivityStyle.secondary)
                    EEWIntensityBlock(
                        ordinal: report.localIntensity, live: report.localIsLive, metrics: .watch,
                        strings: report.strings)
                        .padding(.leading, 4)
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: report.arrivalLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(EEWActivityStyle.secondary)
                    EEWArrivalSlot(report: report, metrics: .watch, alignment: .leading)
                        .frame(height: 40, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
        .lineLimit(1)
        .padding(10)
        .foregroundStyle(.white)
    }
}
