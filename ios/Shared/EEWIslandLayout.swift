import SwiftUI
import WidgetKit

/// Width is proposed by the host, not inferred from the device or activity count.
@available(iOS 16.1, *)
struct EEWIslandWidthReader<Content: View>: View {
    @ViewBuilder let content: (Bool) -> Content

    var body: some View {
        // CI's iOS 26 SDK has no Dynamic Island width environment key.
        // Let ViewThatFits measure the host's proposal on every supported SDK.
        content(false)
    }
}

@available(iOS 16.1, *)
struct EEWIslandFittingView<Regular: View, Compact: View, Smallest: View, Fallback: View>: View {
    let limitedInWidth: Bool
    @ViewBuilder let regular: () -> Regular
    @ViewBuilder let compact: () -> Compact
    @ViewBuilder let smallest: () -> Smallest
    @ViewBuilder let fallback: () -> Fallback

    var body: some View {
        ViewThatFits {
            if !limitedInWidth {
                regular().fixedSize()
            }
            // A truncated Text must never count as a successful fit. Measure the
            // complete candidate, including localized weak/strong intensity labels.
            compact().fixedSize()
            if Smallest.self != EmptyView.self {
                smallest().fixedSize()
            }
            // The terminal candidate must degrade without a partial label.
            fallback()
        }
        .lineLimit(1)
    }
}

// Preserve the existing three-candidate call sites. Badge presentations can
// insert one smaller, complete candidate without changing the fitting policy.
@available(iOS 16.1, *)
extension EEWIslandFittingView where Smallest == EmptyView {
    init(
        limitedInWidth: Bool,
        @ViewBuilder regular: @escaping () -> Regular,
        @ViewBuilder compact: @escaping () -> Compact,
        @ViewBuilder fallback: @escaping () -> Fallback
    ) {
        self.limitedInWidth = limitedInWidth
        self.regular = regular
        self.compact = compact
        self.smallest = { EmptyView() }
        self.fallback = fallback
    }
}

/// The compact intensity block. Intrinsic text size determines its width,
/// including localized weak/strong labels; the fitting container selects the
/// dense metrics before it removes the block, and neither variant truncates or
/// scales a classification. A township in the nsspe list gets the same white
/// ring as on the Lock Screen.
@available(iOS 16.1, *)
struct EEWIslandIntensityBadge<Label: View>: View {
    let intensity: Int?
    var live = false
    var dense = false
    @ViewBuilder let label: () -> Label

    var body: some View {
        label()
            .font(EEWActivityStyle.rounded(dense ? 11 : 14))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, dense ? 2 : 4)
            .frame(minWidth: dense ? 16 : 22, minHeight: dense ? 16 : 22)
            .foregroundStyle(EEWIntensityColor.foreground(for: intensity).color)
            .background(
                EEWIntensityColor.color(for: intensity),
                in: RoundedRectangle(cornerRadius: dense ? 5 : 7, style: .continuous)
            )
            .modifier(EEWLiveRing(live: live, radius: dense ? 5 : 7, gap: 1.5, width: 1.5))
    }
}

/// Compact leading: the block and the source text, then the block alone, then
/// the dense block, then the bare label or a symbol — a partial label never
/// wins.
@available(iOS 16.1, *)
struct EEWIslandIntensityPresentation<Label: View, Source: View>: View {
    let intensity: Int?
    var live = false
    let limitedInWidth: Bool
    @ViewBuilder let label: () -> Label
    @ViewBuilder let source: () -> Source

    private var badge: some View {
        EEWIslandIntensityBadge(intensity: intensity, live: live, label: label)
    }

    var body: some View {
        EEWIslandFittingView(limitedInWidth: limitedInWidth) {
            HStack(spacing: 5) {
                badge
                source()
            }
        } compact: {
            badge
        } smallest: {
            EEWIslandIntensityBadge(intensity: intensity, live: live, dense: true, label: label)
        } fallback: {
            ViewThatFits {
                // Never let clipped text win, even after removing the badge.
                label().font(.caption2.bold()).monospacedDigit().fixedSize()
                Image(systemName: "waveform.path.ecg")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 16, maxHeight: 16)
                    .foregroundStyle(.red)
            }
        }
    }
}

/// A timer Text is greedy and has no useful intrinsic width in a widget host.
/// Measure a hidden monospaced envelope, then fix that width for the real
/// system timer. The envelope is layout only and never visible or accessible.
@available(iOS 16.1, *)
struct EEWIslandTimerEnvelope<Timer: View>: View {
    let sample: String
    @ViewBuilder let timer: () -> Timer

    var body: some View {
        Text(verbatim: sample)
            .monospacedDigit()
            .hidden()
            .accessibilityHidden(true)
            .overlay(alignment: .center) {
                // Widget time Text is horizontally flexible. An overlay does
                // not contribute to ViewThatFits' measurement, and maxWidth:
                // .infinity is not a fixed width when fixedSize probes ideal
                // sizes. Archive an explicit frame matching the measured sample.
                GeometryReader { geometry in
                    timer()
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                        .multilineTextAlignment(.center)
                }
            }
            // Include breathing room in the fitting decision itself; adding it
            // only to the overlay would let a cramped numeric candidate win.
            .padding(.horizontal, 2)
    }
}
