import Foundation
import SwiftUI

/// Every rule that decides what the EEW Live Activity shows, kept out of the
/// views so the widget, the app and the native tests share one copy. The
/// rules are notify-server-go `docs/LIVE_ACTIVITY_PAYLOAD.md` §3.
///
/// The layout is fixed: every value has one place and keeps it, with "—" when
/// the value is missing, because people read this during an earthquake and
/// must not have to search for anything. So these rules choose values and
/// colours, never which slots exist.
enum EEWPresentation {
    enum Kind: Equatable {
        /// alert flag: 緊急地震速報.
        case emergency
        /// 地震速報.
        case standard
        /// 取消報.
        case cancelled
    }

    /// TREM's three precision kinds; CWA has none.
    enum Precision: Equatable {
        /// 假定震源: no source-parameter estimate (M1.0, 10 km placeholders).
        case assumed
        /// 精度低: rk 1–2.
        case low
        /// 精度可用: rk 3–4.
        case usable
    }

    enum Arrival: Equatable {
        case countdown(Date)
        case arrived
        case unavailable
        case cancelled
    }

    /// The TREM note (§3.1, trem-monitor's eew-note order with this
    /// format's fields), one per report, first match wins.
    enum Note: Equatable {
        /// ⓪ — always the fixed text; the feed's comment is not sent (§8-2).
        case cancelled
        /// ① 最終報 of an alert.
        case finalAlert
        /// ② The maximum estimate is 6弱 or above.
        case strongShaking
        /// ③ The event's first alert report, and ⑧ any other alert.
        case alertIssued
        /// ④ The local nsspe is above the app's own local estimate; carries
        /// the local nsspe.
        case acceleration(Int)
        /// ⑤ an nsspe list exists, or ⑥ rk 1–2 with a maximum estimate.
        case direct
        /// ⑦ rk 1–2 and no maximum estimate.
        case lowPrecision
    }

    struct Style: Equatable {
        let background: EEWRGB
        let foreground: EEWRGB
        /// `activityBackgroundTint`.
        let tint: EEWRGB
    }

    static func kind(for payload: EEWPayload) -> Kind {
        if payload.isCancelled { return .cancelled }
        return payload.isAlert ? .emergency : .standard
    }

    /// nil for CWA, a cancellation, and a TREM report without rk.
    static func precision(for payload: EEWPayload) -> Precision? {
        guard payload.source == .trem, !payload.isCancelled else { return nil }
        if payload.hasNoSource { return .assumed }
        switch payload.rk {
        case 1, 2: return .low
        case 3, 4: return .usable
        default: return nil
        }
    }

    static func style(for payload: EEWPayload) -> Style {
        switch kind(for: payload) {
        case .cancelled:
            return Style(background: 0x48484A, foreground: 0xE5E5EA, tint: 0x1C1C1E)
        case .emergency:
            return Style(background: 0xFF0000, foreground: .white, tint: 0x3A0808)
        case .standard where payload.source == .cwa:
            return Style(background: 0xFFAA00, foreground: .black, tint: 0x211B04)
        case .standard where precision(for: payload) == .usable:
            return Style(background: 0xFFC800, foreground: .black, tint: 0x211B04)
        case .standard:
            // 精度低, 假定震源, and a TREM report with no rk at all.
            return Style(background: 0x003264, foreground: .white, tint: 0x07162A)
        }
    }

    static func precisionDot(_ precision: Precision) -> EEWRGB {
        precision == .usable ? 0xFFC800 : 0x0064C8
    }

    /// The report has source parameters to show and estimate from.
    static func hasSource(_ payload: EEWPayload) -> Bool {
        !payload.isCancelled && !payload.hasNoSource
    }

    /// `estimateLocalShaking` for the observer, or nil when it cannot be made:
    /// a cancellation, no source parameters, no epicentre, no observer, or no
    /// table in the App Group (the app has not run since it was installed).
    static func localEstimate(
        for payload: EEWPayload, observer: EEWLocalShaking.Point?, table: EEWSWaveTable?
    ) -> EEWLocalShaking.Estimate? {
        guard hasSource(payload), let epicenter = payload.epicenterCoordinate,
              let magnitude = payload.magnitude, let depth = payload.depthKm,
              let observer, let table else { return nil }
        return EEWLocalShaking.estimate(
            magnitude: magnitude, depth: depth,
            epicenter: .init(latitude: epicenter.latitude, longitude: epicenter.longitude),
            observer: observer, table: table)
    }

    /// When the S wave reaches the observer.
    static func arrivalDate(for payload: EEWPayload, estimate: EEWLocalShaking.Estimate?) -> Date? {
        guard let origin = payload.origin, let estimate else { return nil }
        return origin.addingTimeInterval(TimeInterval(estimate.sArrivalMs) / 1000)
    }

    /// The local intensity, nil while not determined (「—」); 0 is "not felt".
    ///
    /// CWA: the estimate. TREM: max(estimate, local nsspe); without source
    /// parameters the local nsspe alone. A local nsspe of 0 means the township
    /// is not listed, never "0級".
    static func localIntensity(for payload: EEWPayload, estimate: EEWLocalShaking.Estimate?) -> Int? {
        guard !payload.isCancelled else { return nil }
        let nsspe = payload.localNsspe.flatMap { $0 > 0 ? $0 : nil }
        if payload.hasNoSource { return EEWIntensity.determined(nsspe) }
        return EEWIntensity.determined([estimate?.scale, nsspe].compactMap { $0 }.max())
    }

    /// The township is in the nsspe list: the block gets its white ring and
    /// the label becomes 所在地・即時, with or without a magnitude.
    static func localIsLive(for payload: EEWPayload) -> Bool {
        payload.source == .trem && !payload.isCancelled && (payload.localNsspe ?? 0) > 0
    }

    /// 最大預估: the report's own field, as is; empty is 「—」, 0 is 「0級」.
    static func maxIntensity(for payload: EEWPayload) -> Int? {
        guard !payload.isCancelled else { return nil }
        return EEWIntensity.determined(payload.maxIntensity)
    }

    /// What the countdown slot shows.
    ///
    /// The widget cannot redraw itself at an arbitrary moment, so the server
    /// marks arrival with the push's stale-date (its township-centroid arrival
    /// + 2 s), which ActivityKit reports as `isStale`; a render after the
    /// widget's own computed arrival shows 抵達 as well. Neither applies to a
    /// report with no epicentre or no source parameters: there is no arrival
    /// to compute, and a stale-date then only stands in for a missed end.
    static func arrival(
        for payload: EEWPayload, estimate: EEWLocalShaking.Estimate?, isStale: Bool, now: Date
    ) -> Arrival {
        if payload.isCancelled { return .cancelled }
        guard hasSource(payload), payload.epicenterCoordinate != nil else { return .unavailable }
        if isStale { return .arrived }
        guard let arrival = arrivalDate(for: payload, estimate: estimate) else { return .unavailable }
        return now >= arrival ? .arrived : .countdown(arrival)
    }

    /// The §3.1 note, in trem-monitor's order. CWA reports carry no note.
    ///
    /// An empty maximum estimate counts as 0. ④ compares the township's own
    /// nsspe with the app's own estimate for it — the same pair the ring and
    /// the local intensity show — and counts a missing estimate (no source
    /// parameters, or nothing in the App Group) as 0.
    static func note(for payload: EEWPayload, estimate: EEWLocalShaking.Estimate?) -> Note? {
        guard payload.source == .trem else { return nil }
        if payload.isCancelled { return .cancelled }
        if payload.isFinal && payload.isAlert { return .finalAlert }
        let maximum = payload.maxIntensity ?? 0
        if maximum >= 7 { return .strongShaking }
        if let serial = payload.serial, serial == payload.firstAlertSerial { return .alertIssued }
        let localNsspe = payload.localNsspe ?? 0
        let appEstimate = payload.hasNoSource ? 0 : (estimate?.scale ?? 0)
        if localNsspe > appEstimate { return .acceleration(localNsspe) }
        if payload.flags.contains(.hasNsspe) { return .direct }
        if payload.rk == 1 || payload.rk == 2 { return maximum > 0 ? .direct : .lowPrecision }
        return payload.isAlert ? .alertIssued : nil
    }

    /// Only the TREM cards carry 最終結果應以氣象署發布之內容為準.
    static func showsDisclaimer(_ payload: EEWPayload) -> Bool {
        payload.source == .trem
    }

    static func islandArrivalSymbol(for arrival: Arrival) -> String {
        switch arrival {
        case .arrived: return "checkmark"
        case .countdown: return "clock"
        case .unavailable: return "clock.badge.questionmark"
        case .cancelled: return "xmark"
        }
    }

    static func islandTimerSample(arrival: Date?, now: Date) -> String {
        guard let arrival else { return "8:88" }
        // Reserve the maximum remaining digit count at this render. A countdown
        // can only lose digits while the extension sleeps; an update renders a
        // new envelope. This is not displayed ETA data.
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

    /// 0–9, or nil for "not determined" (missing, or out of range). 0 is a
    /// real value — "not felt", 「0級」 — and is not the same as nil (§2.3).
    static func determined(_ ordinal: Int?) -> Int? {
        guard let ordinal, (0...9).contains(ordinal) else { return nil }
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

    /// #3, #6(最終), #2(取消); #— without a serial.
    func reportNumber(_ payload: EEWPayload) -> String {
        guard let serial = payload.serial else { return "#" + Self.placeholder }
        if payload.isCancelled { return format("eew.report.cancelled.format", serial) }
        if payload.isFinal { return format("eew.report.final.format", serial) }
        return "#\(serial)"
    }

    func source(_ source: EEWPayload.Source) -> String {
        source == .trem ? "TREM" : lookup("eew.source.cwa")
    }

    func precision(_ precision: EEWPresentation.Precision) -> String {
        switch precision {
        case .assumed: return lookup("eew.precision.assumed")
        case .low: return lookup("eew.precision.low")
        case .usable: return lookup("eew.precision.usable")
        }
    }

    /// Origin time as HH:mm:ss in Taiwan, as the app shows earthquake times.
    static func originTime(_ date: Date?) -> String {
        date.map(timeFormatter.string(from:)) ?? placeholder
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

    /// The epicentre's name; 無震源參數推定 when TREM sent placeholders (its
    /// `eq.loc` is still sent, and ignored).
    func epicenter(_ payload: EEWPayload) -> String {
        if payload.isCancelled { return Self.placeholder }
        if payload.hasNoSource { return lookup("eew.noSource") }
        return payload.epicenter ?? Self.placeholder
    }

    func magnitude(_ payload: EEWPayload) -> String {
        guard EEWPresentation.hasSource(payload), let magnitude = payload.magnitude else {
            return "M" + Self.placeholder
        }
        return String(format: "M%.1f", magnitude)
    }

    func depth(_ payload: EEWPayload) -> String {
        guard EEWPresentation.hasSource(payload), let depth = payload.depthKm else {
            return Self.placeholder + " km"
        }
        return String(format: "%.0f km", depth)
    }

    /// 0級, 4級, 5弱, or "—" while not determined.
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
