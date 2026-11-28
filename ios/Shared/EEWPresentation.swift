import Foundation
import SwiftUI

/// Every rule that decides what the EEW Live Activity shows, kept out of the
/// views so the widget, the app and the native tests share one copy.
///
/// The layout is fixed: every value has one place and keeps it, with "—" when
/// the value is missing, because people read this during an earthquake and
/// must not have to search for anything. So these rules choose values and
/// colours, never which slots exist.
@available(iOS 16.1, *)
enum EEWPresentation {
    enum Provider: Equatable {
        case cwa
        case trem

        /// Only `trem` is TREM; CWA is the official source and the default.
        init(_ raw: String) {
            self = raw.lowercased() == "trem" ? .trem : .cwa
        }
    }

    enum Kind: Equatable {
        /// alert 1: 緊急地震速報.
        case emergency
        /// alert 0: 地震速報.
        case standard
        /// 取消報.
        case cancelled
    }

    /// TREM's three precision kinds; CWA has none.
    enum Precision: Equatable {
        /// 假定震源: no source-parameter estimate (M1.0, 10 km placeholders).
        case assumed
        /// 精度低: the first digit of rk is 1–2.
        case low
        /// 精度可用: the first digit of rk is 3–4.
        case usable
    }

    enum Arrival: Equatable {
        case countdown(Date)
        case arrived
        case unavailable
        case cancelled
    }

    /// trem-monitor's eew-note, one per report, first match wins.
    enum Note: Equatable {
        case cancelled(comment: String?)
        /// 最終報 of an alert.
        case finalAlert
        /// The effective maximum is 6弱 or above.
        case strongShaking
        /// The event's first alert report, and the fallback for any alert.
        case alertIssued
        /// nsspe is above the model's estimate; carries the nsspe maximum.
        case acceleration(Int)
        /// nsspe exists but is not above the model, or rk 1–2 with an estimate.
        case direct
        /// rk 1–2 and no intensity estimate yet.
        case lowPrecision
    }

    struct Style: Equatable {
        let background: EEWRGB
        let foreground: EEWRGB
        /// `activityBackgroundTint`.
        let tint: EEWRGB
    }

    static func kind(for state: EEWActivityAttributes.ContentState) -> Kind {
        if state.cancelled == true { return .cancelled }
        return state.alert == 1 ? .emergency : .standard
    }

    /// nil for CWA, and for a cancelled report, whose rk is `/////`.
    static func precision(
        for state: EEWActivityAttributes.ContentState, provider: Provider
    ) -> Precision? {
        guard provider == .trem, state.cancelled != true else { return nil }
        if state.noSource == true { return .assumed }
        switch state.rk?.first {
        case "3", "4": return .usable
        default: return .low
        }
    }

    static func style(for state: EEWActivityAttributes.ContentState, provider: Provider) -> Style {
        switch kind(for: state) {
        case .cancelled:
            return Style(background: 0x48484A, foreground: 0xE5E5EA, tint: 0x1C1C1E)
        case .emergency:
            return Style(background: 0xFF0000, foreground: .white, tint: 0x3A0808)
        case .standard:
            switch precision(for: state, provider: provider) {
            case nil:
                return Style(background: 0xFFAA00, foreground: .black, tint: 0x211B04)
            case .usable:
                return Style(background: 0xFFC800, foreground: .black, tint: 0x211B04)
            case .low, .assumed:
                return Style(background: 0x003264, foreground: .white, tint: 0x07162A)
            }
        }
    }

    static func precisionDot(_ precision: Precision) -> EEWRGB {
        precision == .usable ? 0xFFC800 : 0x0064C8
    }

    /// The intensity for the user's township: max(model, nsspe), nil when
    /// neither exists or it is not determined. A cancelled report has none.
    static func localIntensity(for state: EEWActivityAttributes.ContentState) -> Int? {
        guard state.cancelled != true else { return nil }
        let levels = [state.estimatedLocalIntensity, state.localNsspeIntensity].compactMap { $0 }
        return EEWIntensity.determined(levels.max())
    }

    /// The township is in the nsspe list: the block gets its white ring and
    /// the label becomes 所在地・即時, with or without a magnitude.
    static func localIsLive(for state: EEWActivityAttributes.ContentState) -> Bool {
        state.cancelled != true && state.localNsspeIntensity != nil
    }

    /// 最大預估: max(eq.max, nsspe maximum), the same value as eew-note's
    /// effMax; nil while not determined.
    static func maxIntensity(for state: EEWActivityAttributes.ContentState) -> Int? {
        guard state.cancelled != true else { return nil }
        return EEWIntensity.determined(max(state.reportMaxIntensity, state.nsspeMaxIntensity ?? 0))
    }

    /// The report has real source parameters to show.
    static func hasSource(_ state: EEWActivityAttributes.ContentState) -> Bool {
        state.cancelled != true && state.noSource != true
    }

    /// What the countdown slot shows.
    ///
    /// The server marks arrival with the push's stale-date, which ActivityKit
    /// reports as `isStale`; reaching zero on the device's own clock is not
    /// arrival, so the timer then rests at 0:00. Stale without an ETA is not
    /// arrival either: a stale-date can also be a guard against a missed end,
    /// and without an ETA nothing was counting down to it. A report with no
    /// source parameters never shows a countdown — its ETA, if any, was
    /// computed from the placeholder source.
    static func arrival(for state: EEWActivityAttributes.ContentState, isStale: Bool = false) -> Arrival {
        if state.cancelled == true { return .cancelled }
        if state.noSource == true { return .unavailable }
        if state.waveArrived { return .arrived }
        guard let eta = state.estimatedSArrivalAt else { return .unavailable }
        return isStale ? .arrived : .countdown(eta)
    }

    /// trem-monitor's `noteFor` (src/lib/eew-note.ts), in its order. CWA
    /// reports carry no note.
    static func note(for state: EEWActivityAttributes.ContentState, provider: Provider) -> Note? {
        guard provider == .trem else { return nil }
        if state.cancelled == true { return .cancelled(comment: state.cancelComment) }
        let alarm = state.alert == 1
        if state.isFinal == true && alarm { return .finalAlert }
        let predicted = state.reportMaxIntensity
        let nsspeMax = state.nsspeMaxIntensity ?? 0
        if max(predicted, nsspeMax) >= 7 { return .strongShaking }
        if state.firstAlert == true { return .alertIssued }
        if nsspeMax > predicted { return .acceleration(nsspeMax) }
        if state.nsspeMaxIntensity != nil { return .direct }
        if state.rk?.first == "1" || state.rk?.first == "2" {
            return predicted > 0 ? .direct : .lowPrecision
        }
        return alarm ? .alertIssued : nil
    }

    /// Only the TREM cards carry 最終結果應以氣象署發布之內容為準.
    static func showsDisclaimer(_ provider: Provider) -> Bool {
        provider == .trem
    }

    static func islandArrivalSymbol(for arrival: Arrival) -> String {
        switch arrival {
        case .arrived: return "checkmark"
        case .countdown: return "clock"
        case .unavailable: return "clock.badge.questionmark"
        case .cancelled: return "xmark"
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
}

/// DPIP's 0–9 intensity ordinal (CWA's scale: 5 = 5弱 … 9 = 7).
enum EEWIntensity {
    enum Grade: Equatable {
        case level(Int)
        case weak(Int)
        case strong(Int)
    }

    /// 1–9, or nil for "not determined" (0, missing, or out of range).
    static func determined(_ ordinal: Int?) -> Int? {
        guard let ordinal, (1...9).contains(ordinal) else { return nil }
        return ordinal
    }

    static func grade(_ ordinal: Int?) -> Grade? {
        switch determined(ordinal) {
        case 5: return .weak(5)
        case 6: return .strong(5)
        case 7: return .weak(6)
        case 8: return .strong(6)
        case 9: return .level(7)
        case let level?: return .level(level)
        case nil: return nil
        }
    }
}

/// An opaque sRGB colour as 0xRRGGBB, so tests can pin the exact palette.
struct EEWRGB: Hashable, ExpressibleByIntegerLiteral {
    let hex: UInt32

    init(integerLiteral hex: UInt32) {
        self.hex = hex
    }

    static let white: EEWRGB = 0xFFFFFF
    static let black: EEWRGB = 0x000000

    var color: Color {
        Color(
            .sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}

/// trem-monitor's intensity palette, which the app's own matches
/// (lib/shared/seismic/intensity_colors.dart). Text is black on 4, 5弱 and 5強
/// and white on the rest — a fixed rule, not a contrast computation, so the
/// same level always looks the same everywhere.
enum EEWIntensityColor {
    static func background(for ordinal: Int?) -> EEWRGB {
        switch EEWIntensity.determined(ordinal) {
        case 1: return 0x003264
        case 2: return 0x0064C8
        case 3: return 0x1E9632
        case 4: return 0xFFC800
        case 5: return 0xFF9600
        case 6: return 0xFF6400
        case 7: return 0xFF0000
        case 8: return 0xC00000
        case 9: return 0x9600C8
        default: return 0x48484A
        }
    }

    static func foreground(for ordinal: Int?) -> EEWRGB {
        switch EEWIntensity.determined(ordinal) {
        case 4, 5, 6: return .black
        default: return .white
        }
    }

    static func color(for ordinal: Int?) -> Color { background(for: ordinal).color }
}

/// Live Activity text, looked up so that a missing translation shows English
/// rather than the key itself.
///
/// Foundation does not fall back per key: once it picks a language for the
/// bundle (ja, because the weather strings have ja), a key with no ja entry
/// comes back as the key. That is how every eew.* string rendered as
/// `eew.title`-style keys under Japanese. A language the catalog has no entry
/// for at all (th, vi, id, …) already falls back to English through the
/// development region; this covers the other case.
@available(iOS 16.1, *)
enum EEWText {
    static func string(_ key: String, bundle: Bundle = .main) -> String {
        let value = bundle.localizedString(forKey: key, value: nil, table: nil)
        guard value == key,
              let path = bundle.path(forResource: "en", ofType: "lproj"),
              let english = Bundle(path: path) else { return value }
        return english.localizedString(forKey: key, value: nil, table: nil)
    }
}

@available(iOS 16.1, *)
extension Text {
    /// A catalog string, never the raw key (see `EEWText`).
    init(eew key: String) {
        self.init(verbatim: EEWText.string(key))
    }
}

/// Every string the Live Activity shows, formatted. The lookup is injectable so
/// tests can render with the catalog's own zh-Hant text.
@available(iOS 16.1, *)
struct EEWStrings {
    let lookup: (String) -> String

    static let main = EEWStrings { EEWText.string($0) }

    static let placeholder = "—"

    private func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: lookup(key), arguments: arguments)
    }

    func kind(_ kind: EEWPresentation.Kind) -> String {
        switch kind {
        case .emergency: return lookup("eew.kind.emergency")
        case .standard: return lookup("eew.kind.standard")
        case .cancelled: return lookup("eew.kind.cancelled")
        }
    }

    /// #3, #6(最終), #2(取消).
    func reportNumber(_ state: EEWActivityAttributes.ContentState) -> String {
        if state.cancelled == true { return format("eew.report.cancelled.format", state.reportNo) }
        if state.isFinal == true { return format("eew.report.final.format", state.reportNo) }
        return "#\(state.reportNo)"
    }

    func source(_ provider: EEWPresentation.Provider) -> String {
        provider == .trem ? "TREM" : lookup("eew.source.cwa")
    }

    func precision(_ precision: EEWPresentation.Precision) -> String {
        switch precision {
        case .assumed: return lookup("eew.precision.assumed")
        case .low: return lookup("eew.precision.low")
        case .usable: return lookup("eew.precision.usable")
        }
    }

    /// Origin time as HH:mm:ss in Taiwan, as the app shows earthquake times.
    static func originTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    func localLabel(live: Bool) -> String {
        lookup(live ? "eew.label.local.live" : "eew.label.local")
    }

    var sourceLabel: String { lookup("eew.label.source") }

    func arrivalLabel(_ arrival: EEWPresentation.Arrival) -> String {
        lookup(arrival == .arrived ? "eew.label.arrived" : "eew.label.arrival")
    }

    /// 抵達, 未提供 or 取消; nil while counting down.
    func slot(_ arrival: EEWPresentation.Arrival) -> String? {
        switch arrival {
        case .countdown: return nil
        case .arrived: return lookup("eew.arrived")
        case .unavailable: return lookup("eew.unavailable")
        case .cancelled: return lookup("eew.cancelled")
        }
    }

    func epicenter(_ state: EEWActivityAttributes.ContentState) -> String {
        if state.cancelled == true { return Self.placeholder }
        if state.noSource == true { return lookup("eew.noSource") }
        return state.epicenter.isEmpty ? Self.placeholder : state.epicenter
    }

    func magnitude(_ state: EEWActivityAttributes.ContentState) -> String {
        EEWPresentation.hasSource(state) ? String(format: "M%.1f", state.magnitude) : "M" + Self.placeholder
    }

    func depth(_ state: EEWActivityAttributes.ContentState) -> String {
        EEWPresentation.hasSource(state)
            ? String(format: "%.0f km", state.depthKm) : Self.placeholder + " km"
    }

    /// 4級, 5弱, or "—".
    func intensity(_ ordinal: Int?) -> String {
        switch EEWIntensity.grade(ordinal) {
        case .level(let level): return format("eew.intensity.level.format", level)
        case .weak(let level): return format("eew.intensity.weak.format", level)
        case .strong(let level): return format("eew.intensity.strong.format", level)
        case nil: return Self.placeholder
        }
    }

    /// The Island's compact label: the plain levels lose their 級, 5弱 stays.
    func compactIntensity(_ ordinal: Int?) -> String {
        if case .level(let level) = EEWIntensity.grade(ordinal) { return String(level) }
        return intensity(ordinal)
    }

    func spokenIntensity(_ ordinal: Int?) -> String {
        switch EEWIntensity.grade(ordinal) {
        case .level(let level): return format("eew.intensity.spoken.level", level)
        case .weak(let level): return format("eew.intensity.spoken.weak", level)
        case .strong(let level): return format("eew.intensity.spoken.strong", level)
        case nil: return lookup("eew.intensity.spoken.none")
        }
    }

    /// 最大預估 5弱.
    func maxEstimate(_ ordinal: Int?) -> String {
        format("eew.maxEstimate.format", intensity(ordinal))
    }

    func note(_ note: EEWPresentation.Note) -> String {
        switch note {
        case .cancelled(let comment?) where !comment.isEmpty: return comment
        case .cancelled: return lookup("eew.note.cancelled")
        case .finalAlert: return lookup("eew.note.final")
        case .strongShaking: return lookup("eew.note.strongShaking")
        case .alertIssued: return lookup("eew.note.alertIssued")
        case .acceleration(let ordinal): return format("eew.note.acceleration.format", intensity(ordinal))
        case .direct: return lookup("eew.note.direct")
        case .lowPrecision: return lookup("eew.note.lowPrecision")
        }
    }

    var disclaimer: String { lookup("eew.disclaimer") }
}
