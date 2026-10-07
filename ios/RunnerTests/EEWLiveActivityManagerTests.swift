import ActivityKit
import XCTest
@testable import Runner

#if DEBUG
@available(iOS 16.1, *)
@MainActor
final class EEWLiveActivityManagerTests: XCTestCase {
    private let epoch = Date(timeIntervalSince1970: 1_000_000)

    func testNormalArrivalSendsUpdateWithoutAlert() async throws {
        let updater = EEWMockArrivalUpdater()
        var updates = 0
        try await updater.update(activityId: "silent", previous: state(), activityState: .active, mode: .silent) {
            content, alert in
            updates += 1
            XCTAssertTrue(content.waveArrived)
            XCTAssertNil(alert)
        }
        XCTAssertEqual(updates, 1)
    }

    func testExplicitAlertSendsExactlyOneAlertAndBlocksRepeatedArrival() async throws {
        for firstMode in [EEWMockArrivalUpdater.Mode.silent, .alert] {
            let updater = EEWMockArrivalUpdater()
            var updates = 0
            var alerts = 0
            let send: (Runner.EEWActivityAttributes.ContentState, AlertConfiguration?) async -> Void = { content, alert in
                updates += 1
                if alert != nil { alerts += 1 }
                XCTAssertTrue(content.waveArrived)
            }
            try await updater.update(activityId: "mock", previous: state(), activityState: .active,
                                     mode: firstMode, send: send)
            for mode in [EEWMockArrivalUpdater.Mode.silent, .alert] {
                do {
                    // Deliberately supply the old snapshot: ActivityKit may not
                    // have published the new contentState to a second caller yet.
                    try await updater.update(activityId: "mock", previous: state(), activityState: .active,
                                             mode: mode, send: send)
                    XCTFail("Repeated arrival must be rejected")
                } catch {
                    guard case EEWLiveActivityManager.Failure.invalidTransition = error else {
                        return XCTFail("Unexpected error: \(error)")
                    }
                }
            }
            XCTAssertEqual(updates, 1)
            XCTAssertEqual(alerts, firstMode == .alert ? 1 : 0)
        }
    }

    func testArrivalIsReservedBeforeAwaitingActivityKit() async throws {
        let updater = EEWMockArrivalUpdater()
        try await updater.update(activityId: "mock", previous: state(), activityState: .active, mode: .alert) {
            _, alert in
            XCTAssertNotNil(alert)
            do {
                try await updater.update(activityId: "mock", previous: self.state(), activityState: .active,
                                         mode: .alert) { _, _ in XCTFail("Must not send another update") }
                XCTFail("In-flight arrival must be rejected")
            } catch {
                guard case EEWLiveActivityManager.Failure.invalidTransition = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
        }
    }

    func testAlreadyArrivedAndEndedActivitiesAreNotUpdated() async {
        for (lifecycle, arrived) in [(ActivityState.active, true), (.ended, false), (.dismissed, false)] {
            let updater = EEWMockArrivalUpdater()
            do {
                try await updater.update(activityId: "mock", previous: state(arrived: arrived),
                                         activityState: lifecycle, mode: .alert) { _, _ in
                    XCTFail("Must not update arrived or ended activities")
                }
                XCTFail("Invalid activity must be rejected")
            } catch {
                XCTAssertTrue(error is EEWLiveActivityManager.Failure)
            }
            XCTAssertFalse(updater.hasArrived("mock"))
        }
    }

    func testExpiredCountdownDoesNotInferArrivalOrRequestAnAlert() {
        let updater = EEWMockArrivalUpdater()
        for eta in [epoch, epoch.addingTimeInterval(-5)] {
            let content = state(eta: eta)
            XCTAssertFalse(content.waveArrived)
            XCTAssertFalse(updater.hasArrived("mock"))
            XCTAssertEqual(Runner.EEWPresentation.arrival(for: content), .countdown(eta))
        }
        // There is no clock/timer input to the updater; only the explicit
        // update method can reach the ActivityKit send closure.
        XCTAssertNil(EEWMockArrivalUpdater.Mode.silent.alertConfiguration)
    }

    @available(iOS 16.2, *)
    func testArrivalPreservesGenericAndPersonalizedFieldsAndAllowsNewActivities() async throws {
        let updater = EEWMockArrivalUpdater()
        for local in [nil, 3] as [Int?] {
            for eta in [nil, epoch] as [Date?] {
                let previous = state(local: local, eta: eta)
                try await updater.update(activityId: "local=\(String(describing: local)),eta=\(String(describing: eta))", previous: previous,
                                         activityState: .stale, mode: .alert) { content, alert in
                    XCTAssertEqual(content.reportNo, previous.reportNo)
                    XCTAssertEqual(content.originAt, previous.originAt)
                    XCTAssertEqual(content.magnitude, previous.magnitude)
                    XCTAssertEqual(content.depthKm, previous.depthKm)
                    XCTAssertEqual(content.epicenter, previous.epicenter)
                    XCTAssertEqual(content.reportMaxIntensity, previous.reportMaxIntensity)
                    XCTAssertEqual(content.estimatedLocalIntensity, local)
                    XCTAssertEqual(content.estimatedSArrivalAt, eta)
                    XCTAssertEqual(Runner.EEWPresentation.intensity(for: content), local ?? 5)
                    XCTAssertEqual(Runner.EEWPresentation.arrival(for: content), .arrived)
                    XCTAssertNotNil(alert)
                }
            }
        }
    }

    func testAlertResourcesAreBundledAndLocalized() throws {
        let bundle = Bundle(for: EEWLiveActivityManager.self)
        for (language, title, body) in [
            ("en", "TEST · Earthquake Early Warning", "Mock seismic wave arrived. This is a developer test."),
            ("zh-Hant", "測試 · 地震速報", "模擬地震波已抵達。此為開發測試。")
        ] {
            let path = try XCTUnwrap(bundle.path(forResource: language, ofType: "lproj"))
            let localized = try XCTUnwrap(Bundle(path: path))
            XCTAssertEqual(localized.localizedString(forKey: "eew.alert.title", value: nil,
                                                     table: "EEWLiveActivityAlerts"), title)
            XCTAssertEqual(localized.localizedString(forKey: "eew.alert.arrived", value: nil,
                                                     table: "EEWLiveActivityAlerts"), body)
        }
    }

    func testDelayedTriggerUsesExistingAlertPathOnlyAfterRelease() async throws {
        let gate = DelayGate()
        var ended = 0
        let completed = expectation(description: "background task ended")
        var submissions = 0
        let scheduler = EEWDelayedArrivalAlertQA(
            begin: { _ in { ended += 1; completed.fulfill() } },
            wait: { try await gate.wait() }
        )
        let updater = EEWMockArrivalUpdater()
        try scheduler.schedule {
            try await updater.update(activityId: "mock", previous: self.state(), activityState: .active,
                                     mode: .alert) { content, alert in
                XCTAssertTrue(content.waveArrived)
                XCTAssertNotNil(alert)
                submissions += 1
            }
        }
        await fulfillment(of: [gate.entered], timeout: 2)
        XCTAssertEqual(scheduler.status, .scheduled)
        XCTAssertEqual(submissions, 0)
        XCTAssertFalse(updater.hasArrived("mock"))
        gate.release()
        await fulfillment(of: [gate.finished], timeout: 2)
        await fulfillment(of: [completed], timeout: 2)
        XCTAssertEqual(scheduler.status, .triggered)
        XCTAssertEqual(submissions, 1)
        XCTAssertEqual(ended, 1)
    }

    func testDuplicateSchedulingAndCancellationPreventUpdate() async throws {
        let gate = DelayGate()
        var ended = 0
        let completed = expectation(description: "background task ended")
        var submissions = 0
        let scheduler = EEWDelayedArrivalAlertQA(
            begin: { _ in { ended += 1; completed.fulfill() } },
            wait: { try await gate.wait() }
        )
        try scheduler.schedule { submissions += 1 }
        await fulfillment(of: [gate.entered], timeout: 2)
        XCTAssertThrowsError(try scheduler.schedule { submissions += 1 }) {
            guard case EEWLiveActivityManager.Failure.delayedAlertPending = $0 else {
                return XCTFail("Unexpected error: \($0)")
            }
        }
        scheduler.cancel()
        gate.release()
        await fulfillment(of: [gate.finished], timeout: 2)
        await fulfillment(of: [completed], timeout: 2)
        XCTAssertEqual(scheduler.status, .cancelled)
        XCTAssertEqual(submissions, 0)
        XCTAssertEqual(ended, 1)
    }

    func testBackgroundExpirationCancelsAndEndsTaskOnce() async throws {
        let gate = DelayGate()
        var expire: (@Sendable () -> Void)?
        var ended = 0
        let completed = expectation(description: "background task ended")
        var submissions = 0
        let scheduler = EEWDelayedArrivalAlertQA(
            begin: { callback in
                expire = callback
                return { ended += 1; completed.fulfill() }
            },
            wait: { try await gate.wait() }
        )
        try scheduler.schedule { submissions += 1 }
        await fulfillment(of: [gate.entered], timeout: 2)
        let expiration = try XCTUnwrap(expire)
        await Task.detached { expiration() }.value
        await fulfillment(of: [completed], timeout: 2)
        gate.release()
        await fulfillment(of: [gate.finished], timeout: 2)
        XCTAssertEqual(scheduler.status, .expired)
        XCTAssertEqual(submissions, 0)
        XCTAssertEqual(ended, 1)
        scheduler.cancel()
        expiration()
        XCTAssertEqual(ended, 1)
    }

    func testEndedActivityCannotSubmitDelayedAlert() async throws {
        let gate = DelayGate()
        var ended = 0
        let completed = expectation(description: "background task ended")
        var submissions = 0
        var active = true
        let scheduler = EEWDelayedArrivalAlertQA(
            begin: { _ in { ended += 1; completed.fulfill() } },
            wait: { try await gate.wait() }
        )
        try scheduler.schedule {
            guard active else { throw EEWLiveActivityManager.Failure.notActive }
            submissions += 1
        }
        await fulfillment(of: [gate.entered], timeout: 2)
        active = false
        gate.release()
        await fulfillment(of: [gate.finished, completed], timeout: 2)
        XCTAssertEqual(scheduler.status, .expired)
        XCTAssertEqual(submissions, 0)
        XCTAssertEqual(ended, 1)
    }

    func testUnavailableBackgroundTimeDoesNotSchedule() {
        let scheduler = EEWDelayedArrivalAlertQA(begin: { _ in nil })
        XCTAssertThrowsError(try scheduler.schedule { XCTFail("Must not execute") })
        XCTAssertEqual(scheduler.status, .expired)
    }

    @MainActor
    private final class DelayGate {
        let entered = XCTestExpectation(description: "delay entered")
        let finished = XCTestExpectation(description: "delay returned")
        private var continuation: CheckedContinuation<Void, Error>?

        func wait() async throws {
            defer { finished.fulfill() }
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                entered.fulfill()
            }
        }

        func release() {
            continuation?.resume()
            continuation = nil
        }
    }

    private func state(local: Int? = 3, eta: Date? = nil, arrived: Bool = false) -> Runner.EEWActivityAttributes.ContentState {
        .init(reportNo: 4, originAt: epoch, magnitude: 6.1, depthKm: 20,
              epicenter: "Synthetic epicenter", reportMaxIntensity: 5, estimatedLocalIntensity: local,
              estimatedSArrivalAt: eta, waveArrived: arrived)
    }
}
#endif
