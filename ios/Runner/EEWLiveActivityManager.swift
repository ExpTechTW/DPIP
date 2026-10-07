import ActivityKit
import Foundation

/// Local developer prototype only. The fixed event identity lets us find the
/// activity after an app restart without touching any future production EEW.
@available(iOS 16.1, *)
@MainActor
final class EEWLiveActivityManager {
    static let shared = EEWLiveActivityManager()
    private static let mockEventId = "dpip-local-mock-eew"
    #if DEBUG
    private static let genericMockEventId = "dpip-local-generic-mock-eew"
    #endif

    enum Failure: LocalizedError {
        case unavailable
        case disabled
        case alreadyActive
        case notActive
        case duplicateActivities
        case invalidTransition

        var errorDescription: String? {
            switch self {
            case .unavailable: "Live Activities are unavailable on this device."
            case .disabled: "Live Activities are disabled in iOS settings."
            case .alreadyActive: "The mock EEW activity is already active."
            case .notActive: "Start the mock EEW activity first."
            case .duplicateActivities: "Multiple mock EEW activities exist; end them before retrying."
            case .invalidTransition: "The mock EEW activity has already reached wave arrival."
            }
        }
    }

    private init() {}

    var status: [String: Any] {
        let supported = ActivityAuthorizationInfo().areActivitiesEnabled
        return [
            "supported": true,
            "enabled": supported,
            "active": !mockActivities.isEmpty,
            "reportNo": mockActivities.first?.contentState.reportNo as Any? ?? NSNull(),
            "waveArrived": mockActivities.first?.contentState.waveArrived ?? false,
            "generic": mockActivities.first?.contentState.estimatedLocalIntensity == nil
                && !mockActivities.isEmpty,
        ]
    }

    private var mockActivities: [Activity<EEWActivityAttributes>] {
        Activity<EEWActivityAttributes>.activities.filter {
            #if DEBUG
            if $0.attributes.eventId == Self.genericMockEventId { return true }
            #endif
            return $0.attributes.eventId == Self.mockEventId
        }
    }

    private func checkEnabled() throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw Failure.disabled
        }
    }

    private func current() throws -> Activity<EEWActivityAttributes> {
        guard mockActivities.count <= 1 else { throw Failure.duplicateActivities }
        guard let activity = mockActivities.first else { throw Failure.notActive }
        return activity
    }

    func start() throws {
        try checkEnabled()
        guard mockActivities.isEmpty else { throw Failure.alreadyActive }
        let now = Date()
        let attributes = EEWActivityAttributes(provider: "CWA", eventId: Self.mockEventId)
        let state = EEWActivityAttributes.ContentState(
            reportNo: 1,
            originAt: now,
            magnitude: 5.7,
            depthKm: 20,
            epicenter: "臺東縣近海",
            reportMaxIntensity: 4,
            estimatedLocalIntensity: 2,
            estimatedSArrivalAt: now.addingTimeInterval(25),
            waveArrived: false
        )
        _ = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
    }

    #if DEBUG
    /// Exercise the existing fallback UI without any location-derived values.
    func startGeneric() throws {
        try checkEnabled()
        guard mockActivities.isEmpty else { throw Failure.alreadyActive }
        let attributes = EEWActivityAttributes(provider: "CWA", eventId: Self.genericMockEventId)
        let state = EEWActivityAttributes.ContentState(
            reportNo: 1,
            originAt: Date(),
            magnitude: 5.7,
            depthKm: 20,
            epicenter: "臺東縣近海",
            reportMaxIntensity: 4,
            estimatedLocalIntensity: nil,
            estimatedSArrivalAt: nil,
            waveArrived: false
        )
        _ = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
    }
    #endif

    func update(reportNo: Int) async throws {
        try checkEnabled()
        let activity = try current()
        guard activity.attributes.eventId == Self.mockEventId else { throw Failure.invalidTransition }
        guard !activity.contentState.waveArrived else { throw Failure.invalidTransition }
        guard reportNo == 2 || reportNo == 4 else { throw Failure.invalidTransition }
        let previous = activity.contentState
        guard reportNo > previous.reportNo else { throw Failure.invalidTransition }
        let state = EEWActivityAttributes.ContentState(
            reportNo: reportNo,
            originAt: previous.originAt,
            magnitude: reportNo == 2 ? 5.9 : 6.1,
            depthKm: 20,
            epicenter: "臺東縣近海",
            reportMaxIntensity: reportNo == 2 ? 4 : 5,
            estimatedLocalIntensity: 3,
            estimatedSArrivalAt: Date().addingTimeInterval(reportNo == 2 ? 18 : 10),
            waveArrived: false
        )
        await activity.update(using: state)
    }

    func markWaveArrived() async throws {
        try checkEnabled()
        let activity = try current()
        guard activity.attributes.eventId == Self.mockEventId else { throw Failure.invalidTransition }
        let previous = activity.contentState
        guard !previous.waveArrived else { throw Failure.invalidTransition }
        let state = EEWActivityAttributes.ContentState(
            reportNo: previous.reportNo,
            originAt: previous.originAt,
            magnitude: previous.magnitude,
            depthKm: previous.depthKm,
            epicenter: previous.epicenter,
            reportMaxIntensity: previous.reportMaxIntensity,
            estimatedLocalIntensity: previous.estimatedLocalIntensity,
            estimatedSArrivalAt: previous.estimatedSArrivalAt,
            waveArrived: true
        )
        await activity.update(using: state)
    }

    func end() async throws {
        let activity = try current()
        await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
    }
}
