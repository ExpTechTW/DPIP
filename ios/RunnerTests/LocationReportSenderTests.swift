import CoreLocation
import XCTest

@testable import Runner

final class LocationReportSenderTests: XCTestCase {
  private var suiteName: String!
  private var defaults: UserDefaults!
  private var store: LocationReportStore!
  private let now = Date(timeIntervalSince1970: 1_800_000_000)

  // About 1.1 km apart.
  private let taipei = CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654)
  private let farAway = CLLocationCoordinate2D(latitude: 25.0430, longitude: 121.5654)
  // About 55 m from `taipei`.
  private let nearTaipei = CLLocationCoordinate2D(latitude: 25.0335, longitude: 121.5654)

  override func setUp() {
    super.setUp()
    suiteName = "LocationReportSenderTests-\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)
    store = LocationReportStore(defaults: defaults)
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
    defaults = nil
    store = nil
    super.tearDown()
  }

  func testOnlyA2xxDelivers() {
    XCTAssertEqual(LocationReportPolicy.verdict(status: 200), .delivered)
    XCTAssertEqual(LocationReportPolicy.verdict(status: 202), .delivered)
  }

  func testClientErrorsAreFinalExceptTimeoutAndRateLimit() {
    XCTAssertEqual(LocationReportPolicy.verdict(status: 400), .rejected)
    XCTAssertEqual(LocationReportPolicy.verdict(status: 401), .rejected)
    XCTAssertEqual(LocationReportPolicy.verdict(status: 404), .rejected)
    XCTAssertEqual(LocationReportPolicy.verdict(status: 408), .retry)
    XCTAssertEqual(LocationReportPolicy.verdict(status: 429), .retry)
  }

  func testNoAnswerAndServerErrorsAreRetried() {
    XCTAssertEqual(LocationReportPolicy.verdict(status: nil), .retry)
    XCTAssertEqual(LocationReportPolicy.verdict(status: 500), .retry)
    XCTAssertEqual(LocationReportPolicy.verdict(status: 503), .retry)
  }

  func testBackoffDoublesAndIsCapped() {
    XCTAssertEqual(LocationReportPolicy.backoff(afterFailures: 0), 0)
    XCTAssertEqual(LocationReportPolicy.backoff(afterFailures: 1), 60)
    XCTAssertEqual(LocationReportPolicy.backoff(afterFailures: 2), 120)
    XCTAssertEqual(LocationReportPolicy.backoff(afterFailures: 3), 240)
    XCTAssertEqual(LocationReportPolicy.backoff(afterFailures: 6), 30 * 60)
    XCTAssertEqual(LocationReportPolicy.backoff(afterFailures: 500), 30 * 60)
  }

  func testFirstFixIsSubmitted() {
    XCTAssertEqual(
      LocationReportPolicy.action(for: taipei, lastDelivered: nil, pending: nil), .submit)
  }

  func testAFixNearTheDeliveredOneSendsNothing() {
    XCTAssertEqual(
      LocationReportPolicy.action(for: nearTaipei, lastDelivered: taipei, pending: nil), .none)
  }

  /// The bug: the gate used to measure from a point that was never delivered.
  func testAFailedFixDoesNotMoveTheGate() {
    let pending = store.replacePending(with: farAway, now: now)
    store.recordFailure(of: pending, now: now)

    XCTAssertNil(store.lastDelivered)
    XCTAssertEqual(
      LocationReportPolicy.action(for: farAway, lastDelivered: store.lastDelivered, pending: store.pending),
      .retryPending)
  }

  func testComingBackToTheDeliveredFixDropsThePendingOne() {
    let pending = store.replacePending(with: farAway, now: now)
    XCTAssertEqual(
      LocationReportPolicy.action(for: nearTaipei, lastDelivered: taipei, pending: pending),
      .discardPending)
  }

  func testAMoveAwayFromBothIsANewFix() {
    let pending = store.replacePending(with: farAway, now: now)
    let elsewhere = CLLocationCoordinate2D(latitude: 25.0530, longitude: 121.5654)
    XCTAssertEqual(
      LocationReportPolicy.action(for: elsewhere, lastDelivered: taipei, pending: pending), .submit)
  }

  func testOnlyDeliveryMovesTheDeliveredPoint() {
    store.markDelivered(taipei, at: now, status: 200)
    let pending = store.replacePending(with: farAway, now: now)
    store.recordFailure(of: pending, now: now)

    XCTAssertEqual(store.lastDelivered?.latitude, taipei.latitude)
    XCTAssertEqual(store.lastSuccessAt, now)
  }

  func testFailuresScheduleTheNextAttempt() {
    let pending = store.replacePending(with: taipei, now: now)
    XCTAssertEqual(pending.failures, 0)
    XCTAssertEqual(pending.notBefore, now)

    let once = store.recordFailure(of: pending, now: now)
    XCTAssertEqual(once.failures, 1)
    XCTAssertEqual(once.notBefore, now.addingTimeInterval(60))
    let twice = store.recordFailure(of: once, now: now)
    XCTAssertEqual(twice.notBefore, now.addingTimeInterval(120))
    XCTAssertEqual(store.pending, twice)
  }

  /// A new fix must not let a rate-limited client ask again early.
  func testANewFixKeepsARunningBackoff() {
    let first = store.replacePending(with: taipei, now: now)
    let failed = store.recordFailure(of: first, now: now)

    let next = store.replacePending(with: farAway, now: now.addingTimeInterval(10))
    XCTAssertNotEqual(next.id, first.id)
    XCTAssertEqual(next.latitude, farAway.latitude)
    XCTAssertEqual(next.failures, failed.failures)
    XCTAssertEqual(next.notBefore, failed.notBefore)
  }

  func testANewFixAfterTheBackoffStartsClean() {
    let first = store.replacePending(with: taipei, now: now)
    store.recordFailure(of: first, now: now)

    let later = now.addingTimeInterval(3600)
    let next = store.replacePending(with: farAway, now: later)
    XCTAssertEqual(next.failures, 0)
    XCTAssertEqual(next.notBefore, later)
  }

  func testAPendingFixExpiresAfterADay() {
    let pending = store.replacePending(with: taipei, now: now)
    XCTAssertFalse(LocationReportPolicy.isExpired(pending, now: now.addingTimeInterval(23 * 3600)))
    XCTAssertTrue(LocationReportPolicy.isExpired(pending, now: now.addingTimeInterval(25 * 3600)))
  }

  /// The system transfer carries this across processes.
  func testWireRoundTrips() {
    let pending = store.replacePending(with: taipei, now: now)
    let failed = store.recordFailure(of: pending, now: now)
    XCTAssertEqual(PendingLocationReport(wire: failed.wire), failed)
    XCTAssertNil(PendingLocationReport(wire: "not a fix"))
  }

  func testTheURLUsesTheTokenStoredWhenItIsSent() {
    let pending = store.replacePending(with: taipei, now: now)
    XCTAssertNil(store.url(for: pending), "no token yet: the fix waits")

    defaults.set("old", forKey: LocationReportStore.tokenKey)
    defaults.set("26.4", forKey: LocationReportStore.versionKey)
    defaults.set(1, forKey: LocationReportStore.platformKey)
    defaults.set("new", forKey: LocationReportStore.tokenKey)

    XCTAssertEqual(
      store.url(for: pending)?.absoluteString,
      "https://api.core-tnn1.exptech.dev/api/v2/location/1/new/26.4/25.033,121.5654")
  }

  func testClearingForgetsOnlyThePendingFix() {
    store.markDelivered(taipei, at: now, status: 200)
    store.replacePending(with: farAway, now: now)
    store.clearPending()

    XCTAssertNil(store.pending)
    XCTAssertNotNil(store.lastDelivered)
  }
}
