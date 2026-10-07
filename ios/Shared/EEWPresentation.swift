import Foundation

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
