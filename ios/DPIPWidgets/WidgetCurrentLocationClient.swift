import CoreLocation
import Foundation

struct WidgetCurrentLocation: Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    init?(latitude: Double, longitude: Double) {
        guard latitude.isFinite,
              longitude.isFinite,
              (-90...90).contains(latitude),
              (-180...180).contains(longitude)
        else {
            return nil
        }

        self.latitude = latitude
        self.longitude = longitude
    }
}

enum WidgetCurrentLocationResult: Equatable, Sendable {
    case acquired(WidgetCurrentLocation)
    case unavailable
    case timedOut
    case failed
}

enum WidgetLocationAuthorization: Equatable, Sendable {
    case notDetermined
    case restricted
    case denied
    case authorizedAlways
    case authorizedWhenInUse
    case unknown

    init(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorizedAlways:
            self = .authorizedAlways
        case .authorizedWhenInUse:
            self = .authorizedWhenInUse
        @unknown default:
            self = .unknown
        }
    }

    var permitsLocationRequest: Bool {
        self == .authorizedAlways || self == .authorizedWhenInUse
    }

    #if DEBUG
    var diagnosticName: String {
        switch self {
        case .notDetermined:
            return "not-determined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedAlways:
            return "authorized-always"
        case .authorizedWhenInUse:
            return "authorized-when-in-use"
        case .unknown:
            return "unknown"
        }
    }
    #endif
}

struct WidgetLocationSample: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

@MainActor
protocol WidgetLocationManagerDelegate: AnyObject {
    func widgetLocationManager(
        _ manager: any WidgetLocationManaging,
        didUpdate samples: [WidgetLocationSample]
    )

    func widgetLocationManagerDidFail(
        _ manager: any WidgetLocationManaging
    )
}

@MainActor
protocol WidgetLocationManaging: AnyObject {
    var delegate: (any WidgetLocationManagerDelegate)? { get set }
    var authorization: WidgetLocationAuthorization { get }
    var isAuthorizedForWidgetUpdates: Bool { get }
    var desiredAccuracy: Double { get set }

    func startUpdatingLocation()
    func stopUpdatingLocation()
}

@MainActor
protocol WidgetLocationTimeoutCancellable: AnyObject {
    func cancel()
}

@MainActor
protocol WidgetLocationTimeoutScheduling: AnyObject {
    func schedule(
        after interval: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any WidgetLocationTimeoutCancellable
}

@MainActor
final class WidgetCurrentLocationClient {
    typealias ServicesEnabled = @MainActor () -> Bool
    typealias MakeManager = @MainActor () -> any WidgetLocationManaging
    typealias Now = @MainActor () -> Date

    nonisolated static let defaultTimeout: TimeInterval = 10
    nonisolated static let defaultMaximumAge: TimeInterval = 10 * 60
    nonisolated static let defaultRequestStartTolerance: TimeInterval = 1
    nonisolated static let defaultDesiredAccuracy: Double =
        kCLLocationAccuracyKilometer

    private let servicesEnabled: ServicesEnabled
    private let makeManager: MakeManager
    private let timeoutScheduler: any WidgetLocationTimeoutScheduling
    private let timeout: TimeInterval
    private let maximumAge: TimeInterval
    private let requestStartTolerance: TimeInterval
    private let desiredAccuracy: Double
    private let now: Now
    private var activeRequests: [UUID: WidgetCurrentLocationRequest] = [:]

    init(
        servicesEnabled: @escaping ServicesEnabled = {
            CLLocationManager.locationServicesEnabled()
        },
        makeManager: @escaping MakeManager = {
            CoreLocationWidgetLocationManager()
        },
        timeoutScheduler: (any WidgetLocationTimeoutScheduling)? = nil,
        timeout: TimeInterval = defaultTimeout,
        maximumAge: TimeInterval = defaultMaximumAge,
        requestStartTolerance: TimeInterval = defaultRequestStartTolerance,
        desiredAccuracy: Double = defaultDesiredAccuracy,
        now: @escaping Now = Date.init
    ) {
        self.servicesEnabled = servicesEnabled
        self.makeManager = makeManager
        self.timeoutScheduler = timeoutScheduler
            ?? WidgetLocationDispatchTimeoutScheduler()
        self.timeout = timeout
        self.maximumAge = maximumAge
        self.requestStartTolerance = requestStartTolerance
        self.desiredAccuracy = desiredAccuracy
        self.now = now
    }

    func acquireLocation() async -> WidgetCurrentLocationResult {
        guard servicesEnabled() else {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log(
                "current-location authorizationState=services-disabled "
                    + "widgetUpdatesAuthorized=false"
            )
            WidgetWeatherRefreshDiagnostics.log("current location unavailable")
            #endif
            return .unavailable
        }

        let manager = makeManager()
        let authorization = manager.authorization
        let widgetUpdatesAuthorized =
            manager.isAuthorizedForWidgetUpdates

        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "current-location authorizationState="
                + authorization.diagnosticName
                + " widgetUpdatesAuthorized=\(widgetUpdatesAuthorized)"
        )
        #endif

        guard authorization.permitsLocationRequest,
              widgetUpdatesAuthorized
        else {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log("current location unavailable")
            #endif
            return .unavailable
        }

        return await withCheckedContinuation { continuation in
            let requestID = UUID()
            let request = WidgetCurrentLocationRequest(
                manager: manager,
                timeoutScheduler: timeoutScheduler,
                timeout: timeout,
                maximumAge: maximumAge,
                requestStartTolerance: requestStartTolerance,
                desiredAccuracy: desiredAccuracy,
                now: now
            ) { [weak self] result in
                self?.activeRequests[requestID] = nil
                continuation.resume(returning: result)
            }
            activeRequests[requestID] = request
            request.start()
        }
    }
}

@MainActor
private final class WidgetCurrentLocationRequest:
    WidgetLocationManagerDelegate
{
    typealias Completion = @MainActor (WidgetCurrentLocationResult) -> Void

    private let manager: any WidgetLocationManaging
    private let timeoutScheduler: any WidgetLocationTimeoutScheduling
    private let timeout: TimeInterval
    private let maximumAge: TimeInterval
    private let requestStartTolerance: TimeInterval
    private let desiredAccuracy: Double
    private let now: WidgetCurrentLocationClient.Now
    private var completion: Completion?
    private var timeoutCancellation: (
        any WidgetLocationTimeoutCancellable
    )?
    private var startedAt: Date?
    private var hasFinished = false

    init(
        manager: any WidgetLocationManaging,
        timeoutScheduler: any WidgetLocationTimeoutScheduling,
        timeout: TimeInterval,
        maximumAge: TimeInterval,
        requestStartTolerance: TimeInterval,
        desiredAccuracy: Double,
        now: @escaping WidgetCurrentLocationClient.Now,
        completion: @escaping Completion
    ) {
        self.manager = manager
        self.timeoutScheduler = timeoutScheduler
        self.timeout = timeout
        self.maximumAge = maximumAge
        self.requestStartTolerance = requestStartTolerance
        self.desiredAccuracy = desiredAccuracy
        self.now = now
        self.completion = completion
    }

    func start() {
        manager.delegate = self
        manager.desiredAccuracy = desiredAccuracy
        startedAt = now()
        timeoutCancellation = timeoutScheduler.schedule(
            after: timeout
        ) { [weak self] in
            self?.finish(.timedOut)
        }

        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log("current location request started")
        #endif
        manager.startUpdatingLocation()
    }

    func widgetLocationManager(
        _ manager: any WidgetLocationManaging,
        didUpdate samples: [WidgetLocationSample]
    ) {
        guard !hasFinished else {
            return
        }

        guard let startedAt else {
            return
        }

        let requestNow = now()
        let earliestAcceptedTimestamp = startedAt.addingTimeInterval(
            -requestStartTolerance
        )
        let location: WidgetCurrentLocation? = samples.reversed().compactMap {
            sample -> WidgetCurrentLocation? in
            let age = requestNow.timeIntervalSince(sample.timestamp)
            guard age >= -requestStartTolerance,
                  age <= maximumAge,
                  sample.timestamp >= earliestAcceptedTimestamp
            else {
                return nil
            }
            return WidgetCurrentLocation(
                latitude: sample.latitude,
                longitude: sample.longitude
            )
        }.first

        guard let location else {
            return
        }
        finish(.acquired(location))
    }

    func widgetLocationManagerDidFail(
        _ manager: any WidgetLocationManaging
    ) {
        finish(.failed)
    }

    private func finish(_ result: WidgetCurrentLocationResult) {
        guard !hasFinished else {
            return
        }
        hasFinished = true

        timeoutCancellation?.cancel()
        timeoutCancellation = nil
        manager.stopUpdatingLocation()
        manager.delegate = nil

        #if DEBUG
        switch result {
        case .acquired:
            WidgetWeatherRefreshDiagnostics.log("current location acquired")
        case .unavailable:
            WidgetWeatherRefreshDiagnostics.log("current location unavailable")
        case .timedOut:
            WidgetWeatherRefreshDiagnostics.log("current location timeout")
        case .failed:
            WidgetWeatherRefreshDiagnostics.log("current location failed")
        }
        #endif

        let completion = completion
        self.completion = nil
        completion?(result)
    }
}

@MainActor
private final class CoreLocationWidgetLocationManager: NSObject,
    WidgetLocationManaging,
    CLLocationManagerDelegate
{
    weak var delegate: (any WidgetLocationManagerDelegate)?

    var authorization: WidgetLocationAuthorization {
        WidgetLocationAuthorization(manager.authorizationStatus)
    }

    var isAuthorizedForWidgetUpdates: Bool {
        manager.isAuthorizedForWidgetUpdates
    }

    var desiredAccuracy: Double {
        get { manager.desiredAccuracy }
        set { manager.desiredAccuracy = newValue }
    }

    private let manager: CLLocationManager

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let samples = locations.map { location in
            WidgetLocationSample(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: location.timestamp
            )
        }
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            delegate?.widgetLocationManager(self, didUpdate: samples)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: any Error
    ) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            delegate?.widgetLocationManagerDidFail(self)
        }
    }
}

@MainActor
private final class WidgetLocationDispatchTimeoutScheduler:
    WidgetLocationTimeoutScheduling
{
    func schedule(
        after interval: TimeInterval,
        action: @escaping @MainActor () -> Void
    ) -> any WidgetLocationTimeoutCancellable {
        let workItem = DispatchWorkItem {
            action()
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + interval,
            execute: workItem
        )
        return WidgetLocationDispatchTimeoutCancellation(workItem: workItem)
    }
}

@MainActor
private final class WidgetLocationDispatchTimeoutCancellation:
    WidgetLocationTimeoutCancellable
{
    private var workItem: DispatchWorkItem?

    init(workItem: DispatchWorkItem) {
        self.workItem = workItem
    }

    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}
