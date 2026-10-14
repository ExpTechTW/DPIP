import Foundation
import SwiftUI

/// Pure presentation choices shared by the widget and its native regression tests.
@available(iOS 16.1, *)
enum EEWPresentation {
    enum Arrival: Equatable {
        case arrived
        case countdown(Date)
        case unavailable
    }

    struct IntensityText: Equatable {
        let key: String
        let level: Int?
    }

    static func intensity(for state: EEWActivityAttributes.ContentState) -> Int {
        // Missing local intensity and ETA fall back independently; neither
        // optional field is evidence that the other estimate exists.
        state.estimatedLocalIntensity ?? state.reportMaxIntensity
    }

    static func intensityLabel(for state: EEWActivityAttributes.ContentState) -> String {
        state.estimatedLocalIntensity == nil ? "eew.intensity.max" : "eew.intensity.local"
    }

    static func arrival(for state: EEWActivityAttributes.ContentState) -> Arrival {
        // Absolute ETA lets the system timer update while the extension sleeps.
        // Only an explicit domain update means arrived, even after ETA expires.
        if state.waveArrived { return .arrived }
        if let eta = state.estimatedSArrivalAt { return .countdown(eta) }
        return .unavailable
    }

    static func islandArrivalSymbol(for state: EEWActivityAttributes.ContentState) -> String {
        switch arrival(for: state) {
        case .arrived: return "checkmark"
        case .countdown: return "clock"
        case .unavailable: return "clock.badge.questionmark"
        }
    }

    static func islandTimerSample(for state: EEWActivityAttributes.ContentState, now: Date) -> String {
        guard let arrival = state.estimatedSArrivalAt else { return "8:88" }
        // Reserve the maximum remaining digit count at this render. A countdown
        // can only lose digits while the extension sleeps; an ETA update renders
        // a new envelope. Using originAt would unnecessarily reject a fitting
        // 9:59 timer for an older event. This is not displayed ETA data.
        let duration = max(0, arrival.timeIntervalSince(now))
        // The system countdown rounds a fractional remaining second up: 599.9s
        // still displays 10:00. Floor division would reserve only 8:88 and clip
        // the first second of the wider value in an archived widget layout.
        let minutes = Int(ceil(duration) / 60)
        return String(repeating: "8", count: max(1, String(minutes).count)) + ":88"
    }

    static func intensityText(_ intensity: Int, compact: Bool = false, spoken: Bool = false) -> IntensityText {
        // DPIP stores CWA's discrete ordinal, not the printed intensity number.
        let key: String
        switch intensity {
        case 5: key = "eew.intensity.5weak"
        case 6: key = "eew.intensity.5strong"
        case 7: key = "eew.intensity.6weak"
        case 8: key = "eew.intensity.6strong"
        default:
            return IntensityText(
                key: compact && !spoken ? "eew.intensity.compact.format" : "eew.intensity.format",
                level: intensity == 9 ? 7 : intensity)
        }
        return IntensityText(key: spoken ? key + ".spoken" : key, level: nil)
    }
}

@available(iOS 16.1, *)
enum EEWIntensityColor {
    static func foreground(for intensity: Int) -> Color {
        // Opaque sRGB backgrounds: choose the stronger black/white contrast.
        // No intensity colour is changed to make its text readable.
        let rgb = backgroundRGB(for: intensity)
        func linear(_ component: Int) -> Double {
            let value = Double(component) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linear(rgb.red) + 0.7152 * linear(rgb.green) + 0.0722 * linear(rgb.blue)
        let blackContrast = (luminance + 0.05) / 0.05
        let whiteContrast = 1.05 / (luminance + 0.05)
        return blackContrast >= whiteContrast ? .black : .white
    }

    static func color(for intensity: Int) -> Color {
        let rgb = backgroundRGB(for: intensity)
        return Color(
            .sRGB, red: Double(rgb.red) / 255, green: Double(rgb.green) / 255,
            blue: Double(rgb.blue) / 255, opacity: 1)
    }

    // The existing native palette matches lib/shared/seismic/intensity_colors.dart.
    // Move it here unchanged so widget presentation and native tests share it.
    private static func backgroundRGB(for intensity: Int) -> (red: Int, green: Int, blue: Int) {
        switch intensity {
        case 1: return (0, 50, 100)
        case 2: return (0, 100, 200)
        case 3: return (30, 150, 50)
        case 4: return (255, 200, 0)
        case 5: return (255, 150, 0)
        case 6: return (255, 100, 0)
        case 7: return (255, 0, 0)
        case 8: return (192, 0, 0)
        case 9: return (150, 0, 200)
        default: return (158, 158, 158)
        }
    }
}
