import SwiftUI
import WidgetKit

/// Width is proposed by the host, not inferred from the device or activity count.
@available(iOS 16.1, *)
struct EEWIslandWidthReader<Content: View>: View {
    @ViewBuilder let content: (Bool) -> Content

    var body: some View {
        if #available(iOS 27.0, *) {
            EEWLimitedIslandWidthReader(content: content)
        } else {
            content(false)
        }
    }
}

// Keep the property wrapper itself out of the earlier-OS view's stored properties.
@available(iOS 27.0, *)
private struct EEWLimitedIslandWidthReader<Content: View>: View {
    @Environment(\.isDynamicIslandLimitedInWidth) private var limitedInWidth
    @ViewBuilder let content: (Bool) -> Content

    var body: some View { content(limitedInWidth) }
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

/// Intrinsic text size determines the badge dimensions, including localized
/// weak/strong labels. The fitting container selects dense metrics before it
/// removes the badge; neither variant truncates or scales a classification.
@available(iOS 16.1, *)
struct EEWIslandIntensityBadge<Label: View>: View {
    let intensity: Int
    var dense = false
    @ViewBuilder let label: () -> Label

    var body: some View {
        label()
            .font(dense ? .caption2.bold() : .caption.bold())
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, dense ? 2 : 4)
            .padding(.vertical, dense ? 1 : 2)
            .foregroundStyle(EEWIntensityColor.foreground(for: intensity))
            .background(EEWIntensityColor.color(for: intensity), in: RoundedRectangle(cornerRadius: 4))
    }
}

@available(iOS 16.1, *)
struct EEWIslandIntensityPresentation<Label: View, TestBadge: View>: View {
    let intensity: Int
    let limitedInWidth: Bool
    @ViewBuilder let label: () -> Label
    @ViewBuilder let testBadge: () -> TestBadge

    private var badge: some View {
        EEWIslandIntensityBadge(intensity: intensity, label: label)
    }

    var body: some View {
        EEWIslandFittingView(limitedInWidth: limitedInWidth) {
            HStack(spacing: 4) {
                waveform
                badge
                testBadge()
            }
        } compact: {
            if limitedInWidth {
                badge
            } else {
                // Drop the visual TEST decoration before losing the waveform.
                // The caller retains TEST's spoken hint at every width.
                HStack(spacing: 4) {
                    waveform
                    badge
                }
            }
        } smallest: {
            EEWIslandIntensityBadge(intensity: intensity, dense: true, label: label)
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

    private var waveform: some View {
        Image(systemName: "waveform.path.ecg")
            .foregroundStyle(.red)
            .accessibilityHidden(true)
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
