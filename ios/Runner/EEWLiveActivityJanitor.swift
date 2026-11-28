import ActivityKit
import Foundation

/// The safety net for a missed `end` push: when the app runs, end every EEW
/// Live Activity whose report is long over.
///
/// The display never infers this. A stale-date only means the S wave has
/// arrived (`EEWPresentation.arrival`); an activity the server forgot to end
/// would otherwise stay on the Lock Screen for hours, showing an old report as
/// if it were current.
@available(iOS 16.1, *)
enum EEWLiveActivityJanitor {
    /// How long after its origin an EEW is certainly over. Pending with the
    /// server's own end/dismissal timing (LIVE_ACTIVITY_PAYLOAD.md §8-5); wide
    /// enough that a device clock a few minutes off cannot end a live event.
    static let lifetime: TimeInterval = 10 * 60

    /// Whether [state] is long over at [now]. A report this build cannot read
    /// is left alone: its age is unknown, and the server still owns it.
    static func isExpired(_ state: EEWActivityAttributes.ContentState, provider: String, now: Date) -> Bool {
        guard let origin = EEWPayload(state.d, provider: provider)?.origin else { return false }
        return now.timeIntervalSince(origin) > lifetime
    }

    @MainActor
    static func endExpired(now: Date = Date()) async {
        for activity in Activity<EEWActivityAttributes>.activities
        where isExpired(activity.contentState, provider: activity.attributes.provider, now: now) {
            if #available(iOS 16.2, *) {
                await activity.end(nil, dismissalPolicy: .immediate)
            } else {
                await activity.end(using: nil, dismissalPolicy: .immediate)
            }
        }
    }
}
