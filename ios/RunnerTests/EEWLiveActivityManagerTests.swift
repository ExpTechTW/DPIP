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
            XCTAssertEqual(content, self.state())
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
                XCTAssertEqual(content, self.state())
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

    func testEndedActivitiesAreNotUpdated() async {
        for lifecycle in [ActivityState.ended, .dismissed] {
            let updater = EEWMockArrivalUpdater()
            do {
                try await updater.update(activityId: "mock", previous: state(),
                                         activityState: lifecycle, mode: .alert) { _, _ in
                    XCTFail("Must not update ended activities")
                }
                XCTFail("Invalid activity must be rejected")
            } catch {
                XCTAssertTrue(error is EEWLiveActivityManager.Failure)
            }
            XCTAssertFalse(updater.hasArrived("mock"))
        }
    }

    func testUpdaterHasNoClockInput() {
        // There is no clock/timer input to the updater; only the explicit
        // update method can reach the ActivityKit send closure.
        XCTAssertFalse(EEWMockArrivalUpdater().hasArrived("mock"))
        XCTAssertNil(EEWMockArrivalUpdater.Mode.silent.alertConfiguration)
    }

    func testMockReportsAreTheCWAFormat() throws {
        let origin = Date(timeIntervalSince1970: 1_795_888_105)
        for (serial, magnitude, maximum) in [(1, 5.7, 4), (2, 5.9, 4), (4, 6.1, 5)] {
            let state = EEWLiveActivityManager.mockReport(serial: serial, origin: origin)
            let payload = try XCTUnwrap(Runner.EEWPayload(state.d, provider: "cwa"))
            XCTAssertEqual(payload.serial, serial)
            XCTAssertEqual(payload.origin, origin)
            XCTAssertEqual(payload.magnitude, magnitude)
            XCTAssertEqual(payload.maxIntensity, maximum)
            XCTAssertEqual(payload.flags, [])
        }
    }

    /// The server's stale-date (§4): its arrival + 2 s; origin + 180 s when
    /// there is nothing to estimate from.
    func testMockStaleDateFollowsTheServerRule() throws {
        let origin = Date(timeIntervalSince1970: 1_795_888_105)
        let state = EEWLiveActivityManager.mockReport(serial: 1, origin: origin)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = Runner.EEWLiveActivityStore(directory: directory)
        XCTAssertEqual(
            EEWLiveActivityManager.staleDate(for: state, provider: "cwa", store: store), origin.addingTimeInterval(180))
        XCTAssertEqual(
            EEWLiveActivityManager.staleDate(for: state, provider: "cwa", store: nil), origin.addingTimeInterval(180))
        XCTAssertNil(EEWLiveActivityManager.staleDate(for: .init(d: "2|1"), provider: "cwa", store: nil))
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
                XCTAssertEqual(content, self.state())
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

    private func state() -> Runner.EEWActivityAttributes.ContentState {
        EEWLiveActivityManager.mockReport(serial: 4, origin: epoch)
    }
}
#endif
