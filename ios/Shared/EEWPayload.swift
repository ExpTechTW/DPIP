import Foundation

/// One EEW report as the push carries it: `content-state.d`, a `|`-separated
/// string in a fixed field order (notify-server-go
/// `docs/LIVE_ACTIVITY_PAYLOAD.md` §2). The one parser of that string; the
/// widget runs it on every render.
///
/// - Field 1 is the format version. Only `1` is understood; anything else
///   parses to nil and the activity shows nothing.
/// - An empty field is "no value". For an intensity that is "not determined"
///   (「—」), which is not the same as `0`, "not felt" (「0級」).
/// - Missing trailing fields read as empty, so an older sender still parses;
///   extra trailing fields are ignored, so a newer sender does too.
///
/// TREM, 13 fields:
/// `version|serial|flags|origin|lat|lng|epicentre|mag|depth|rk|maxEstimate|firstAlertSerial|localNsspe`
///
/// CWA, 10 fields (only the alert flag; CWA has no final or cancel report):
/// `version|serial|flags|origin|lat|lng|epicentre|mag|depth|maxEstimate`
struct EEWPayload: Equatable {
    enum Source: Equatable {
        case cwa
        case trem

        /// Only `trem` is TREM; CWA is the official source and the default.
        init(provider: String) {
            self = provider.lowercased() == "trem" ? .trem : .cwa
        }
    }

    struct Flags: OptionSet, Equatable {
        let rawValue: Int

        static let alert = Flags(rawValue: 1)
        static let finalReport = Flags(rawValue: 2)
        static let cancelled = Flags(rawValue: 4)
        /// TREM: the report carries an nsspe list (note ⑤).
        static let hasNsspe = Flags(rawValue: 8)
    }

    static let version = "1"

    let source: Source
    let serial: Int?
    let flags: Flags
    /// Unix seconds.
    let origin: Date?
    let latitude: Double?
    let longitude: Double?
    let epicenter: String?
    let magnitude: Double?
    let depthKm: Double?
    /// TREM: the first digit of rk (1–4).
    let rk: Int?
    /// The report's maximum estimate anywhere (TREM: already max(model,
    /// nsspe, oeew)), shown as is.
    let maxIntensity: Int?
    /// TREM: the serial of the event's first alert report.
    let firstAlertSerial: Int?
    /// TREM: nsspe's level for this township; `0` when it is not listed.
    let localNsspe: Int?

    init(
        source: Source, serial: Int?, flags: Flags, origin: Date?, latitude: Double?, longitude: Double?,
        epicenter: String?, magnitude: Double?, depthKm: Double?, rk: Int? = nil, maxIntensity: Int?,
        firstAlertSerial: Int? = nil, localNsspe: Int? = nil
    ) {
        self.source = source
        self.serial = serial
        self.flags = flags
        self.origin = origin
        self.latitude = latitude
        self.longitude = longitude
        self.epicenter = epicenter
        self.magnitude = magnitude
        self.depthKm = depthKm
        self.rk = rk
        self.maxIntensity = maxIntensity
        self.firstAlertSerial = firstAlertSerial
        self.localNsspe = localNsspe
    }

    /// Parses `d` for [provider]; nil when its version is not understood.
    init?(_ d: String, provider: String) {
        let fields = d.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard fields.first == Self.version else { return nil }
        func field(_ number: Int) -> String? {
            let index = number - 1
            guard index < fields.count, !fields[index].isEmpty else { return nil }
            return fields[index]
        }
        func int(_ number: Int) -> Int? { field(number).flatMap { Int($0) } }
        func double(_ number: Int) -> Double? {
            field(number).flatMap { Double($0) }.flatMap { $0.isFinite ? $0 : nil }
        }

        let source = Source(provider: provider)
        self.init(
            source: source,
            serial: int(2),
            flags: Flags(rawValue: int(3) ?? 0),
            origin: int(4).map { Date(timeIntervalSince1970: TimeInterval($0)) },
            latitude: double(5),
            longitude: double(6),
            epicenter: field(7),
            magnitude: double(8),
            depthKm: double(9),
            rk: source == .trem ? int(10) : nil,
            maxIntensity: int(source == .trem ? 11 : 10),
            firstAlertSerial: source == .trem ? int(12) : nil,
            localNsspe: source == .trem ? int(13) : nil)
    }

    var isCancelled: Bool { flags.contains(.cancelled) }
    var isAlert: Bool { flags.contains(.alert) }
    var isFinal: Bool { flags.contains(.finalReport) }

    /// TREM's M1.0 / 10 km are placeholders: there is no source-parameter
    /// estimate, only observed intensities (§3; a dedicated flag is §8-2).
    var hasNoSource: Bool { source == .trem && magnitude == 1.0 }

    /// The epicentre, when the report has one to estimate from.
    var epicenterCoordinate: (latitude: Double, longitude: Double)? {
        guard let latitude, let longitude else { return nil }
        return (latitude, longitude)
    }
}
