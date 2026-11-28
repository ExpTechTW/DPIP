import ActivityKit
import Foundation

/// The EEW Live Activity contract: what a push's `attributes` and
/// `content-state` carry (notify-server-go `docs/LIVE_ACTIVITY_PAYLOAD.md` §4).
///
/// Never rename this type. A push-to-start token is issued per
/// `ActivityAttributes` type and a push names it in `attributes-type`, so the
/// tokens already collected are bound to this exact name.
@available(iOS 16.1, *)
struct EEWActivityAttributes: ActivityAttributes {
    /// `cwa` or `trem`, in any case: which of the two string formats `d` is.
    let provider: String
    let eventId: String

    /// One report, as the §2 string. Every update replaces it whole; the
    /// widget parses it on each render (`EEWPayload`).
    struct ContentState: Codable, Hashable {
        let d: String
    }
}
