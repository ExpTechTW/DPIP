import Foundation
import XCTest

@MainActor
final class WidgetCurrentLocationClientTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    func testServicesDisabledReturnsUnavailable() async {
        let manager = FakeWidgetLocationManager()
        var managerWasCreated = false
        let client = makeClient(
            servicesEnabled: false,
            manager: manager,
            onMakeManager: { managerWasCreated = true }
        )

        let result = await client.acquireLocation()

        XCTAssertEqual(result, .unavailable)
        XCTAssertFalse(managerWasCreated)
        XCTAssertEqual(manager.requestCount, 0)
    }

    func testNotDeterminedReturnsUnavailable() async {
        let manager = FakeWidgetLocationManager(
            authorization: .notDetermined,
            widgetUpdatesAuthorized: true
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(manager.requestCount, 0)
    }

    func testDeniedReturnsUnavailable() async {
        let manager = FakeWidgetLocationManager(
            authorization: .denied,
            widgetUpdatesAuthorized: true
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(manager.requestCount, 0)
    }

    func testRestrictedReturnsUnavailable() async {
        let manager = FakeWidgetLocationManager(
            authorization: .restricted,
            widgetUpdatesAuthorized: true
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(manager.requestCount, 0)
    }

    func testWidgetAuthorizationFalseReturnsUnavailable() async {
        let manager = FakeWidgetLocationManager(
            authorization: .authorizedWhenInUse,
            widgetUpdatesAuthorized: false
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(manager.requestCount, 0)
    }

    func testAuthorizedWhenInUseMayAcquireLocation() async {
        let expected = WidgetCurrentLocation(
            latitude: 25.033,
            longitude: 121.5654
        )!
        let manager = successfulManager(
            authorization: .authorizedWhenInUse,
            location: expected
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .acquired(expected))
        XCTAssertEqual(manager.requestCount, 1)
    }

    func testAuthorizedAlwaysMayAcquireLocation() async {
        let expected = WidgetCurrentLocation(
            latitude: 22.6273,
            longitude: 120.3014
        )!
        let manager = successfulManager(
            authorization: .authorizedAlways,
            location: expected
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .acquired(expected))
        XCTAssertEqual(manager.requestCount, 1)
    }

    func testValidFreshLocationIsReturned() async {
        let manager = FakeWidgetLocationManager(
            event: .samples([
                WidgetLocationSample(
                    latitude: 24.1477,
                    longitude: 120.6736,
                    timestamp: now.addingTimeInterval(-599)
                ),
            ])
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(
            result,
            .acquired(
                WidgetCurrentLocation(
                    latitude: 24.1477,
                    longitude: 120.6736
                )!
            )
        )
    }

    func testStaleLocationIsRejected() async {
        let manager = FakeWidgetLocationManager(
            event: .samples([
                WidgetLocationSample(
                    latitude: 25.033,
                    longitude: 121.5654,
                    timestamp: now.addingTimeInterval(-601)
                ),
            ])
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .failed)
    }

    func testInvalidAndNonFiniteCoordinatesAreRejected() async {
        let manager = FakeWidgetLocationManager(
            event: .samples([
                WidgetLocationSample(
                    latitude: 91,
                    longitude: 121.5654,
                    timestamp: now
                ),
                WidgetLocationSample(
                    latitude: .nan,
                    longitude: 121.5654,
                    timestamp: now
                ),
            ])
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .failed)
    }

    func testCoreLocationFailureReturnsFailure() async {
        let manager = FakeWidgetLocationManager(event: .failure)

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .failed)
    }

    func testTimeoutIgnoresLateLocationAndCompletesOnlyOnce() async {
        let manager = FakeWidgetLocationManager()
        let scheduler = FakeWidgetLocationTimeoutScheduler()
        let client = makeClient(manager: manager, scheduler: scheduler)
        let task = Task { @MainActor in
            await client.acquireLocation()
        }
        await waitForRequest(on: manager)

        scheduler.fireLast()
        let result = await task.value
        manager.send(
            samples: [
                WidgetLocationSample(
                    latitude: 25.033,
                    longitude: 121.5654,
                    timestamp: now
                ),
            ]
        )

        XCTAssertEqual(result, .timedOut)
        XCTAssertEqual(manager.stopCount, 1)
        XCTAssertNil(manager.delegate)
        XCTAssertEqual(scheduler.lastCancellation?.cancelCount, 1)
    }

    func testSuccessCancelsTimeoutAndCompletesOnlyOnce() async {
        let expected = WidgetCurrentLocation(
            latitude: 25.033,
            longitude: 121.5654
        )!
        let manager = successfulManager(
            authorization: .authorizedWhenInUse,
            location: expected
        )
        let scheduler = FakeWidgetLocationTimeoutScheduler()
        let client = makeClient(manager: manager, scheduler: scheduler)

        let result = await client.acquireLocation()
        scheduler.fireLast()

        XCTAssertEqual(result, .acquired(expected))
        XCTAssertEqual(manager.stopCount, 1)
        XCTAssertNil(manager.delegate)
        XCTAssertEqual(scheduler.lastCancellation?.cancelCount, 1)
    }

    func testUnavailableDoesNotRequestFallbackLocation() async {
        let manager = FakeWidgetLocationManager(
            authorization: .authorizedWhenInUse,
            widgetUpdatesAuthorized: false,
            event: .samples([
                WidgetLocationSample(
                    latitude: 25.033,
                    longitude: 121.5654,
                    timestamp: now
                ),
            ])
        )

        let result = await makeClient(manager: manager).acquireLocation()

        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(manager.requestCount, 0)
        XCTAssertEqual(manager.stopCount, 0)
    }

    func testRequestUsesTownshipAppropriateAccuracyAndTenSecondTimeout() async {
        let expected = WidgetCurrentLocation(
            latitude: 25.033,
            longitude: 121.5654
        )!
        let manager = successfulManager(
            authorization: .authorizedWhenInUse,
            location: expected
        )
        let scheduler = FakeWidgetLocationTimeoutScheduler()

        _ = await makeClient(
            manager: manager,
            scheduler: scheduler
        ).acquireLocation()

        XCTAssertEqual(
            manager.desiredAccuracy,
            WidgetCurrentLocationClient.defaultDesiredAccuracy
        )
        XCTAssertEqual(
            scheduler.scheduledIntervals,
            [WidgetCurrentLocationClient.defaultTimeout]
        )
    }

    private func makeClient(
        servicesEnabled: Bool = true,
        manager: FakeWidgetLocationManager,
        scheduler: FakeWidgetLocationTimeoutScheduler? = nil,
        onMakeManager: @escaping @MainActor () -> Void = {}
    ) -> WidgetCurrentLocationClient {
        WidgetCurrentLocationClient(
            servicesEnabled: { servicesEnabled },
            makeManager: {
                onMakeManager()
                return manager
            },
            timeoutScheduler: scheduler
                ?? FakeWidgetLocationTimeoutScheduler(),
            now: { self.now }
        )
    }

    private func successfulManager(
        authorization: WidgetLocationAuthorization,
        location: WidgetCurrentLocation
    ) -> FakeWidgetLocationManager {
        FakeWidgetLocationManager(
            authorization: authorization,
            event: .samples([
                WidgetLocationSample(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    timestamp: now
                ),
            ])
        )
    }

    private func waitForRequest(
        on manager: FakeWidgetLocationManager
    ) async {
        for _ in 0..<100 where manager.requestCount == 0 {
            await Task.yield()
        }
        XCTAssertEqual(manager.requestCount, 1)
    }
}

@MainActor
private final class FakeWidgetLocationManager: WidgetLocationManaging {
    enum Event {
        case none
        case samples([WidgetLocationSample])
        case failure
    }

    weak var delegate: (any WidgetLocationManagerDelegate)?
    let authorization: WidgetLocationAuthorization
    let isAuthorizedForWidgetUpdates: Bool
    var desiredAccuracy: Double = 0
    private(set) var requestCount = 0
    private(set) var stopCount = 0
    private let event: Event

    init(
        authorization: WidgetLocationAuthorization = .authorizedWhenInUse,
        widgetUpdatesAuthorized: Bool = true,
        event: Event = .none
    ) {
        self.authorization = authorization
        self.isAuthorizedForWidgetUpdates = widgetUpdatesAuthorized
        self.event = event
    }

    func requestLocation() {
        requestCount += 1
        switch event {
        case .none:
            break
        case .samples(let samples):
            send(samples: samples)
        case .failure:
            delegate?.widgetLocationManagerDidFail(self)
        }
    }

    func stopUpdatingLocation() {
        stopCount += 1
    }

    func send(samples: [WidgetLocationSample]) {
        delegate?.widgetLocationManager(self, didUpdate: samples)
    }
}

@MainActor
private final class FakeWidgetLocationTimeoutScheduler:
    WidgetLocationTimeoutScheduling
{
    private(set) var scheduledIntervals: [TimeInterval] = []
    private(set) var cancellations: [FakeWidgetLocationTimeoutCancellation] = []

    var lastCancellation: FakeWidgetLocationTimeoutCancellation? {
        cancellations.last
    }

    func schedule(
        after interval: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any WidgetLocationTimeoutCancellable {
        scheduledIntervals.append(interval)
        let cancellation = FakeWidgetLocationTimeoutCancellation(action: action)
        cancellations.append(cancellation)
        return cancellation
    }

    func fireLast() {
        lastCancellation?.fire()
    }
}

@MainActor
private final class FakeWidgetLocationTimeoutCancellation:
    WidgetLocationTimeoutCancellable
{
    private var action: (@MainActor () -> Void)?
    private(set) var cancelCount = 0

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    func cancel() {
        cancelCount += 1
        action = nil
    }

    func fire() {
        action?()
    }
}
