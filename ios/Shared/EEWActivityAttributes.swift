import ActivityKit
import Foundation

/// The EEW Live Activity contract: what a push's `attributes` and
/// `content-state` must carry.
///
/// Never rename this type. A push-to-start token is issued per
/// `ActivityAttributes` type and a push names it in `attributes-type`, so the
/// tokens already collected are bound to this exact name.
@available(iOS 16.1, *)
struct EEWActivityAttributes: ActivityAttributes {
    /// `cwa` or `trem`, in any case. Anything else is drawn as CWA.
    let provider: String
    let eventId: String

    /// One report. ActivityKit decodes a push's `content-state` with a default
    /// `JSONDecoder`, so every `Date` here travels as seconds since
    /// 2001-01-01 (`timeIntervalSinceReferenceDate`), not Unix seconds.
    ///
    /// Every intensity is DPIP's 0–9 ordinal (5 = 5弱, 6 = 5強, 7 = 6弱,
    /// 8 = 6強, 9 = 7); 0 is "not determined" and is drawn as "—".
    struct ContentState: Codable, Hashable {
        // Phase 1 (#610). Required: a payload without one does not decode.
        let reportNo: Int
        let originAt: Date
        let magnitude: Double
        let depthKm: Double
        let epicenter: String
        /// The model's maximum estimate (`eq.max`).
        let reportMaxIntensity: Int
        /// The model's estimate for the user's township.
        let estimatedLocalIntensity: Int?
        let estimatedSArrivalAt: Date?
        /// Explicit arrival. Reaching the ETA does not imply it.
        let waveArrived: Bool

        // The redesign. All optional, so a Phase 1 payload still decodes and
        // reads exactly as an alert-0, non-final, uncancelled report.
        /// 1 = 緊急地震速報, 0 = 地震速報. The event's sticky value: once a
        /// report of the event had 1, every later one sends 1.
        let alert: Int?
        let isFinal: Bool?
        let cancelled: Bool?
        /// TREM's precision code. Its first digit 1–2 is low, 3–4 usable.
        let rk: String?
        /// TREM sent placeholder source parameters (M1.0, 10 km): there is no
        /// source-parameter estimate, only observed intensities.
        let noSource: Bool?
        /// nsspe's level for the user's township; absent when the township is
        /// not in the nsspe list.
        let localNsspeIntensity: Int?
        /// The highest level in the nsspe list; absent when the list is empty.
        let nsspeMaxIntensity: Int?
        /// This report is the event's first with alert 1, judged on the raw
        /// alert before it is made sticky. Only the TREM note reads it.
        let firstAlert: Bool?
        /// The feed's own cancellation text, shown instead of the default one.
        let cancelComment: String?

        /// The wire names, spelled in this one place. They are not agreed with
        /// the server yet; renaming one here renames it on the wire, and
        /// `EEWContentStateTests` pins the full set.
        enum CodingKeys: String, CodingKey {
            case reportNo = "reportNo"
            case originAt = "originAt"
            case magnitude = "magnitude"
            case depthKm = "depthKm"
            case epicenter = "epicenter"
            case reportMaxIntensity = "reportMaxIntensity"
            case estimatedLocalIntensity = "estimatedLocalIntensity"
            case estimatedSArrivalAt = "estimatedSArrivalAt"
            case waveArrived = "waveArrived"
            case alert = "alert"
            case isFinal = "isFinal"
            case cancelled = "cancelled"
            case rk = "rk"
            case noSource = "noSource"
            case localNsspeIntensity = "localNsspeIntensity"
            case nsspeMaxIntensity = "nsspeMaxIntensity"
            case firstAlert = "firstAlert"
            case cancelComment = "cancelComment"
        }

        init(
            reportNo: Int,
            originAt: Date,
            magnitude: Double,
            depthKm: Double,
            epicenter: String,
            reportMaxIntensity: Int,
            estimatedLocalIntensity: Int?,
            estimatedSArrivalAt: Date?,
            waveArrived: Bool,
            alert: Int? = nil,
            isFinal: Bool? = nil,
            cancelled: Bool? = nil,
            rk: String? = nil,
            noSource: Bool? = nil,
            localNsspeIntensity: Int? = nil,
            nsspeMaxIntensity: Int? = nil,
            firstAlert: Bool? = nil,
            cancelComment: String? = nil
        ) {
            self.reportNo = reportNo
            self.originAt = originAt
            self.magnitude = magnitude
            self.depthKm = depthKm
            self.epicenter = epicenter
            self.reportMaxIntensity = reportMaxIntensity
            self.estimatedLocalIntensity = estimatedLocalIntensity
            self.estimatedSArrivalAt = estimatedSArrivalAt
            self.waveArrived = waveArrived
            self.alert = alert
            self.isFinal = isFinal
            self.cancelled = cancelled
            self.rk = rk
            self.noSource = noSource
            self.localNsspeIntensity = localNsspeIntensity
            self.nsspeMaxIntensity = nsspeMaxIntensity
            self.firstAlert = firstAlert
            self.cancelComment = cancelComment
        }

        /// The same report with the wave marked as arrived; every other field,
        /// including the redesign's, is carried over.
        func markingWaveArrived() -> ContentState {
            ContentState(
                reportNo: reportNo, originAt: originAt, magnitude: magnitude, depthKm: depthKm,
                epicenter: epicenter, reportMaxIntensity: reportMaxIntensity,
                estimatedLocalIntensity: estimatedLocalIntensity, estimatedSArrivalAt: estimatedSArrivalAt,
                waveArrived: true, alert: alert, isFinal: isFinal, cancelled: cancelled, rk: rk,
                noSource: noSource, localNsspeIntensity: localNsspeIntensity,
                nsspeMaxIntensity: nsspeMaxIntensity, firstAlert: firstAlert, cancelComment: cancelComment)
        }
    }
}
