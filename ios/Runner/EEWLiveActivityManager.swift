import ActivityKit
import Foundation
#if DEBUG
import UIKit
#endif

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
        #if DEBUG
        case delayedAlertPending
        case backgroundUnavailable
        #endif

        var errorDescription: String? {
            switch self {
            case .unavailable: "Live Activities are unavailable on this device."
            case .disabled: "Live Activities are disabled in iOS settings."
            case .alreadyActive: "The mock EEW activity is already active."
            case .notActive: "Start the mock EEW activity first."
            case .duplicateActivities: "Multiple mock EEW activities exist; end them before retrying."
            case .invalidTransition: "The mock EEW activity has already reached wave arrival."
            #if DEBUG
            case .delayedAlertPending: "A delayed arrival alert is already scheduled."
            case .backgroundUnavailable: "Unable to obtain background execution time for the delayed test."
            #endif
            }
        }
    }

    private init() {}

    private let arrivalUpdater = EEWMockArrivalUpdater()
    #if DEBUG
    private let delayedAlert = EEWDelayedArrivalAlertQA()
    #endif

    var status: [String: Any] {
        let supported = ActivityAuthorizationInfo().areActivitiesEnabled
        var result: [String: Any] = [
            "supported": true,
            "enabled": supported,
            "active": !mockActivities.isEmpty,
            "reportNo": mockActivities.first.flatMap(Self.payload)?.serial as Any? ?? NSNull(),
            "waveArrived": mockActivities.first.map { arrivalUpdater.hasArrived($0.id) } ?? false,
            "generic": mockActivities.first?.attributes.provider == "trem",
        ]
        #if DEBUG
        result["delayedAlertStatus"] = delayedAlert.status.rawValue
        #endif
        return result
    }

    private var mockActivities: [Activity<EEWActivityAttributes>] {
        Activity<EEWActivityAttributes>.activities.filter {
            guard EEWMockArrivalUpdater.canUpdate($0.activityState) else { return false }
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
        let attributes = EEWActivityAttributes(provider: "cwa", eventId: Self.mockEventId)
        try Self.request(attributes, Self.mockReport(serial: 1, origin: Date()))
    }

    #if DEBUG
    /// A TREM report with no source parameters, local intensity from nsspe:
    /// 假定震源, the white ring and 未提供, with no location-derived values.
    func startGeneric() throws {
        try checkEnabled()
        guard mockActivities.isEmpty else { throw Failure.alreadyActive }
        let attributes = EEWActivityAttributes(provider: "trem", eventId: Self.genericMockEventId)
        let origin = Int(Date().timeIntervalSince1970)
        try Self.request(attributes, .init(d: "1|1|8|\(origin)|23.99|121.60|花蓮縣|1.0|10|2|3||3"))
    }
    #endif

    /// A CWA report off 花蓮 (§2.2), the format a push carries.
    static func mockReport(serial: Int, origin: Date) -> EEWActivityAttributes.ContentState {
        let magnitude = [1: "5.7", 2: "5.9", 4: "6.1"][serial] ?? "5.7"
        let maximum = serial >= 4 ? 5 : 4
        return .init(d: "1|\(serial)|0|\(Int(origin.timeIntervalSince1970))|23.95|121.71|花蓮縣近海|\(magnitude)|20|\(maximum)")
    }

    private static func payload(_ activity: Activity<EEWActivityAttributes>) -> EEWPayload? {
        EEWPayload(activity.contentState.d, provider: activity.attributes.provider)
    }

    /// The stale-date the server would send (§4): its arrival + 2 s, here from
    /// the same estimate the widget makes; origin + 180 s without one.
    static func staleDate(
        for state: EEWActivityAttributes.ContentState, provider: String,
        store: EEWLiveActivityStore? = EEWLiveActivityStore()
    ) -> Date? {
        guard let payload = EEWPayload(state.d, provider: provider) else { return nil }
        let estimate = EEWPresentation.localEstimate(
            for: payload, observer: store?.observer()?.point, table: store?.table())
        if let arrival = EEWPresentation.arrivalDate(for: payload, estimate: estimate) {
            return arrival.addingTimeInterval(2)
        }
        return payload.origin?.addingTimeInterval(180)
    }

    private static func request(
        _ attributes: EEWActivityAttributes, _ state: EEWActivityAttributes.ContentState
    ) throws {
        if #available(iOS 16.2, *) {
            _ = try Activity.request(
                attributes: attributes,
                content: ActivityContent(
                    state: state, staleDate: staleDate(for: state, provider: attributes.provider)),
                pushType: nil)
        } else {
            _ = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
        }
    }

    func update(reportNo: Int) async throws {
        #if DEBUG
        delayedAlert.cancel()
        #endif
        try checkEnabled()
        let activity = try current()
        guard activity.attributes.eventId == Self.mockEventId else { throw Failure.invalidTransition }
        guard !arrivalUpdater.hasArrived(activity.id) else { throw Failure.invalidTransition }
        guard reportNo == 2 || reportNo == 4 else { throw Failure.invalidTransition }
        guard let previous = Self.payload(activity), reportNo > previous.serial ?? 0 else {
            throw Failure.invalidTransition
        }
        let state = Self.mockReport(serial: reportNo, origin: previous.origin ?? Date())
        if #available(iOS 16.2, *) {
            await activity.update(ActivityContent(
                state: state, staleDate: Self.staleDate(for: state, provider: activity.attributes.provider)))
        } else {
            await activity.update(using: state)
        }
    }

    func markWaveArrived() async throws {
        #if DEBUG
        delayedAlert.cancel()
        #endif
        try await markWaveArrived(mode: .silent)
    }

    #if DEBUG
    func markWaveArrivedWithAlert() async throws {
        delayedAlert.cancel()
        try await markWaveArrived(mode: .alert)
    }

    func scheduleDelayedArrivalAlert() throws {
        try checkEnabled()
        let activity = try current()
        guard activity.attributes.eventId == Self.mockEventId,
              !arrivalUpdater.hasArrived(activity.id) else { throw Failure.invalidTransition }
        let activityId = activity.id
        try delayedAlert.schedule { [weak self] in
            guard let self, let current = try? self.current(), current.id == activityId else {
                throw Failure.notActive
            }
            try await self.markWaveArrived(mode: .alert)
        }
        Task { @MainActor [weak self] in
            for await state in activity.activityStateUpdates {
                if !EEWMockArrivalUpdater.canUpdate(state) {
                    self?.delayedAlert.cancel()
                    break
                }
            }
        }
    }
    #endif

    private func markWaveArrived(mode: EEWMockArrivalUpdater.Mode) async throws {
        try checkEnabled()
        let activity = try current()
        guard activity.attributes.eventId == Self.mockEventId else { throw Failure.invalidTransition }
        try await arrivalUpdater.update(
            activityId: activity.id, previous: activity.contentState,
            activityState: activity.activityState, mode: mode
        ) { state, alert in
            // What the server's stale-date does: mark the content stale now,
            // which the widget shows as 抵達.
            if #available(iOS 16.2, *) {
                await activity.update(ActivityContent(state: state, staleDate: Date()), alertConfiguration: alert)
            } else {
                await activity.update(using: state, alertConfiguration: alert)
            }
        }
    }

    func end() async throws {
        #if DEBUG
        delayedAlert.cancel()
        #endif
        let activity = try current()
        await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
    }
}

#if DEBUG
/// One-shot manual QA only. iOS may suspend the app before the delay completes.
@available(iOS 16.1, *)
@MainActor
final class EEWDelayedArrivalAlertQA {
    enum Status: String {
        case idle = "Idle"
        case scheduled = "Scheduled"
        case triggered = "Triggered"
        case cancelled = "Cancelled"
        case expired = "Expired / Unable to execute"
    }

    typealias Begin = @MainActor (@escaping @Sendable () -> Void) -> (@MainActor () -> Void)?
    typealias Wait = () async throws -> Void

    private struct Pending {
        let id: UUID
        let finishBackgroundTask: @MainActor () -> Void
        let task: Task<Void, Never>
    }

    private let begin: Begin
    private let wait: Wait
    private var pending: Pending?
    private(set) var status = Status.idle

    init(
        begin: Begin? = nil,
        wait: @escaping Wait = { try await Task.sleep(nanoseconds: 8_000_000_000) }
    ) {
        self.begin = begin ?? Self.beginBackgroundTask
        self.wait = wait
    }

    private static func beginBackgroundTask(expired: @escaping @Sendable () -> Void) -> (@MainActor () -> Void)? {
        let application = UIApplication.shared
        let identifier = application.beginBackgroundTask(withName: "EEWDelayedArrivalAlertQA", expirationHandler: expired)
        guard identifier != .invalid else { return nil }
        return { application.endBackgroundTask(identifier) }
    }

    func schedule(execute: @escaping () async throws -> Void) throws {
        guard pending == nil else { throw EEWLiveActivityManager.Failure.delayedAlertPending }
        let id = UUID()
        guard let finish = begin({ [weak self] in
            Task { @MainActor [weak self] in self?.expire(id: id) }
        }) else {
            status = .expired
            throw EEWLiveActivityManager.Failure.backgroundUnavailable
        }
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.wait()
                try Task.checkCancellation()
                guard self.pending?.id == id else { return }
                try await execute()
                guard self.pending?.id == id else { return }
                self.status = .triggered // ActivityKit submission, not visible presentation.
                self.clearPending()
            } catch is CancellationError {
                if self.pending?.id == id { self.cancel() }
            } catch {
                guard self.pending?.id == id else { return }
                self.status = .expired
                self.clearPending()
            }
        }
        pending = Pending(id: id, finishBackgroundTask: finish, task: task)
        status = .scheduled
    }

    func cancel() {
        guard let pending else { return }
        pending.task.cancel()
        status = .cancelled
        clearPending()
    }

    private func expire(id: UUID) {
        guard pending?.id == id else { return }
        pending?.task.cancel()
        status = .expired
        clearPending()
    }

    private func clearPending() {
        guard let pending else { return }
        self.pending = nil
        pending.finishBackgroundTask()
    }
}
#endif

/// Reserves explicit arrivals before suspending, including while ActivityKit's
/// contentState still reflects the previous update. Never driven by the ETA.
@available(iOS 16.1, *)
@MainActor
final class EEWMockArrivalUpdater {
    enum Mode {
        case silent
        #if DEBUG
        case alert
        #endif

        var alertConfiguration: AlertConfiguration? {
            switch self {
            case .silent: return nil
            #if DEBUG
            case .alert:
                return AlertConfiguration(
                    title: LocalizedStringResource("eew.alert.title", table: "EEWLiveActivityAlerts"),
                    body: LocalizedStringResource("eew.alert.arrived", table: "EEWLiveActivityAlerts"),
                    sound: .default)
            #endif
            }
        }
    }

    private var arrivedActivityIds = Set<String>()

    static func canUpdate(_ state: ActivityState) -> Bool {
        if state == .active { return true }
        if #available(iOS 16.2, *) { return state == .stale }
        return false
    }

    func hasArrived(_ activityId: String) -> Bool {
        arrivedActivityIds.contains(activityId)
    }

    func update(
        activityId: String, previous: EEWActivityAttributes.ContentState,
        activityState: ActivityState, mode: Mode,
        send: (EEWActivityAttributes.ContentState, AlertConfiguration?) async -> Void
    ) async throws {
        guard Self.canUpdate(activityState) else {
            throw EEWLiveActivityManager.Failure.notActive
        }
        guard !hasArrived(activityId) else {
            throw EEWLiveActivityManager.Failure.invalidTransition
        }
        // No await between checking and reserving. Both arrival actions share
        // this guard, so a silent arrival cannot later be upgraded to an alert.
        // The report itself is unchanged: arrival is the stale-date, which the
        // caller sets.
        arrivedActivityIds.insert(activityId)
        await send(previous, mode.alertConfiguration)
    }
}
