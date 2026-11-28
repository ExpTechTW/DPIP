import CoreLocation
import XCTest

@testable import Runner

/// The report heartbeat: one report from a device that has had no successful
/// report for three days plus its jitter, in every mode, from what is stored —
/// never a fix — and never through the real network here.
final class ReportHeartbeatTests: XCTestCase {
  private var suiteName: String!
  private var defaults: UserDefaults!
  private var store: LocationReportStore!

  private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
  private let jitter: TimeInterval = 5 * 60 * 60
  private var threshold: TimeInterval { ReportHeartbeatPolicy.quiet + jitter }
  private let taipei = CLLocationCoordinate2D(latitude: 25.0478, longitude: 121.5319)
  private let hualien = CLLocationCoordinate2D(latitude: 23.97, longitude: 121.6)

  /// What each fake send was asked to report, answered by `answer`.
  private var sent: [CLLocationCoordinate2D] = []
  private var answer: HeartbeatSendResult = .answered(204)

  override func setUp() {
    super.setUp()
    suiteName = "ReportHeartbeatTests-\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)
    store = LocationReportStore(defaults: defaults)
    sent = []
    answer = .answered(204)
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
    defaults = nil
    store = nil
    super.tearDown()
  }

  private func record(at: Date? = nil) -> ReportedFix {
    ReportedFix(at: at ?? t0, latitude: taipei.latitude, longitude: taipei.longitude)
  }

  /// A device that reported once at `t0` and knows what to send as.
  private func reportedDevice() {
    store.saveIdentity(token: "tok", version: "1.2.3", platform: 1)
    store.recordReported(taipei, at: t0)
    defaults.set(jitter, forKey: LocationReportStore.heartbeatJitterKey)
  }

  private func heartbeat() -> ReportHeartbeat {
    ReportHeartbeat(store: store) { [unowned self] coordinate, done in
      self.sent.append(coordinate)
      done(self.answer)
      return nil
    }
  }

  @discardableResult
  private func run(at now: Date) -> String {
    var outcome: String?
    heartbeat().run(now: now) { outcome = $0 }
    return outcome ?? "did not complete"
  }

  // MARK: - The due rule

  func testNoRecordHasNothingToSend() {
    XCTAssertEqual(
      ReportHeartbeatPolicy.decide(now: t0, reported: nil, jitter: jitter, manual: nil),
      .skip("no successful report yet"))
    // In manual mode too: a pinned point is not a record.
    if case .send = ReportHeartbeatPolicy.decide(
      now: t0, reported: nil, jitter: jitter, manual: hualien)
    {
      XCTFail("sent with no record")
    }
  }

  func testDueOnlyOnceOlderThanThreeDaysPlusTheJitter() {
    func decide(age: TimeInterval, jitter: TimeInterval? = nil) -> ReportHeartbeatPolicy.Decision {
      ReportHeartbeatPolicy.decide(
        now: t0.addingTimeInterval(age), reported: record(), jitter: jitter ?? self.jitter,
        manual: nil)
    }
    XCTAssertFalse(isSend(decide(age: threshold - 1)))
    XCTAssertFalse(isSend(decide(age: threshold)))
    XCTAssertTrue(isSend(decide(age: threshold + 1)))
    // The jitter is part of the threshold.
    XCTAssertFalse(isSend(decide(age: threshold + 1, jitter: jitter + 2)))
  }

  func testALastSuccessStampedInTheFutureIsDue() {
    let decision = ReportHeartbeatPolicy.decide(
      now: t0, reported: record(at: t0.addingTimeInterval(60)), jitter: jitter, manual: nil)
    XCTAssertTrue(isSend(decision))
  }

  func testTheJitterIsDrawnOnceInsideADayAndNeverRedrawn() {
    let first = store.heartbeatJitter()
    XCTAssertGreaterThanOrEqual(first, 0)
    XCTAssertLessThan(first, ReportHeartbeatPolicy.jitterRange)
    XCTAssertEqual(store.heartbeatJitter(draw: { 1 }), first)
    XCTAssertEqual(
      LocationReportStore(defaults: defaults).heartbeatJitter(draw: { 2 }), first,
      "a new process reads the same jitter")
  }

  // MARK: - Scheduling

  func testTheNextRunIsAskedForWhenTheDeviceComesDue() {
    let reported = record()
    let due = t0.addingTimeInterval(threshold)
    XCTAssertEqual(
      ReportHeartbeatPolicy.earliestBegin(now: t0, reported: reported, jitter: jitter), due)
    // Already due: about an hour from now, not a moment in the past.
    let late = due.addingTimeInterval(10)
    XCTAssertEqual(
      ReportHeartbeatPolicy.earliestBegin(now: late, reported: reported, jitter: jitter),
      late.addingTimeInterval(ReportHeartbeatPolicy.retryDelay))
    // A future stamp is due now, so the same.
    XCTAssertEqual(
      ReportHeartbeatPolicy.earliestBegin(
        now: t0, reported: record(at: t0.addingTimeInterval(60)), jitter: jitter),
      t0.addingTimeInterval(ReportHeartbeatPolicy.retryDelay))
    // Nothing to resend yet: about a day.
    XCTAssertEqual(
      ReportHeartbeatPolicy.earliestBegin(now: t0, reported: nil, jitter: jitter),
      t0.addingTimeInterval(ReportHeartbeatPolicy.noRecordDelay))
  }

  // MARK: - The point

  func testSendsThePinnedTownshipWhilePinnedElseTheLastReportedPoint() {
    let now = t0.addingTimeInterval(threshold + 1)
    XCTAssertEqual(
      ReportHeartbeatPolicy.decide(now: now, reported: record(), jitter: jitter, manual: hualien),
      .send(.init(latitude: 23.97, longitude: 121.6), source: "pinned township"))
    XCTAssertEqual(
      ReportHeartbeatPolicy.decide(now: now, reported: record(), jitter: jitter, manual: nil),
      .send(.init(latitude: 25.0478, longitude: 121.5319), source: "last reported point"))
  }

  func testARunResendsTheStoredPointAndTheClearedPinFallsBack() {
    reportedDevice()
    store.setManualPoint(hualien)
    run(at: t0.addingTimeInterval(threshold + 1))
    XCTAssertEqual(sent.map(\.latitude), [23.97])

    store.clearManualPoint()
    store.recordReported(taipei, at: t0)
    run(at: t0.addingTimeInterval(threshold + 1))
    XCTAssertEqual(sent.map(\.latitude), [23.97, 25.0478])
    XCTAssertEqual(sent.last?.longitude, 121.5319)
  }

  // MARK: - What a run does with the answer

  func testA2xxUpdatesTheRecordWithTheTimeAndThePointItSent() {
    reportedDevice()
    store.setManualPoint(hualien)
    let now = t0.addingTimeInterval(threshold + 1)

    let outcome = run(at: now)

    XCTAssertTrue(outcome.contains("sent (204)"), outcome)
    XCTAssertEqual(store.reported, ReportedFix(at: now, latitude: 23.97, longitude: 121.6))
    // Fresh again: a day later nothing is sent.
    run(at: now.addingTimeInterval(24 * 60 * 60))
    XCTAssertEqual(sent.count, 1)
  }

  func testA429OrNoAnswerLeavesTheRecordAloneSoTheNextRunRetries() {
    reportedDevice()
    let now = t0.addingTimeInterval(threshold + 1)
    for (result, expected) in [
      (HeartbeatSendResult.answered(429), "failed (429)"),
      (.answered(nil), "failed (no answer)"),
      (.answered(500), "failed (500)"),
      (.busy("a background report is backing off"), "backing off, not sent"),
      (.noToken, "no push token"),
    ] {
      answer = result
      let outcome = run(at: now)
      XCTAssertTrue(outcome.contains(expected), outcome)
      XCTAssertEqual(store.reported, record(), "\(result)")
    }
    XCTAssertEqual(sent.count, 5)
  }

  func testEveryRunLeavesATrace() {
    run(at: t0)
    XCTAssertEqual(
      defaults.string(forKey: LocationReportStore.heartbeatLastOutcomeKey),
      "no successful report yet")
    reportedDevice()
    run(at: t0.addingTimeInterval(60))
    XCTAssertEqual(
      defaults.double(forKey: LocationReportStore.heartbeatLastRunAtKey),
      t0.addingTimeInterval(60).timeIntervalSince1970)
    XCTAssertTrue(
      defaults.string(forKey: LocationReportStore.heartbeatLastOutcomeKey)?.hasPrefix("not due")
        == true)
    XCTAssertTrue(sent.isEmpty)

    let diagnostics = heartbeat().diagnostics()
    XCTAssertEqual(diagnostics["reportedAt"] as? Int, Int(t0.timeIntervalSince1970 * 1000))
    XCTAssertEqual(
      diagnostics["heartbeatDueAt"] as? Int,
      Int(t0.addingTimeInterval(threshold).timeIntervalSince1970 * 1000))
  }

  // MARK: - Every path's 2xx counts, and `stop` keeps it all

  func testTheBackgroundPathsDeliveryUpdatesTheRecord() {
    XCTAssertNil(store.reported)
    store.markDelivered(hualien, at: t0, status: 204)
    XCTAssertEqual(store.reported, ReportedFix(at: t0, latitude: 23.97, longitude: 121.6))
  }

  func testStopsDiscardKeepsEverythingTheHeartbeatNeeds() {
    reportedDevice()
    store.setManualPoint(hualien)
    store.replacePending(with: taipei, now: t0)
    let sender = LocationReportSender(store: store)

    // What the plugin's `stop` does to the store, besides its own flag.
    defaults.set(false, forKey: LocationReportStore.enabledKey)
    sender.discardPending("background reporting stopped")

    XCTAssertNil(store.pending)
    XCTAssertEqual(store.reported, record())
    XCTAssertEqual(store.manualPoint?.latitude, 23.97)
    XCTAssertEqual(store.heartbeatJitter(draw: { 0 }), jitter)
    XCTAssertEqual(
      store.url(latitude: 1, longitude: 2)?.absoluteString,
      "https://api.core-tnn1.exptech.dev/api/v2/location/1/tok/1.2.3/1.0,2.0")
  }

  func testTheIdentityEnablesNothing() {
    store.saveIdentity(token: "tok", version: "1.2.3", platform: 1)
    XCTAssertFalse(defaults.bool(forKey: LocationReportStore.enabledKey))
    XCTAssertNotNil(store.url(latitude: 1, longitude: 2))
  }

  private func isSend(_ decision: ReportHeartbeatPolicy.Decision) -> Bool {
    if case .send = decision { return true }
    return false
  }
}
