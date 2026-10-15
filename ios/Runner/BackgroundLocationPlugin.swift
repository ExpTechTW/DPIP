import CoreLocation
import Flutter
import UIKit

/// Native, autonomous background device-location reporting.
///
/// Reports the device's coordinates to `updateDeviceLocation` on significant
/// moves — even while the app is backgrounded or terminated — using three
/// low-power, relaunch-capable Core Location services in concert, since iOS
/// gives no time-based background wake and reliability comes from redundancy:
///   • **Significant Location Change** — the always-on relaunch spine (~500 m).
///   • a self-re-centering **exit region** (~250 m) — a finer trigger and a
///     second independent relaunch path.
///   • **visit monitoring** — cheaply catches "settled into a new place".
/// All three run off the low-power cell/Wi-Fi subsystem (no continuous GPS), and
/// `kCLLocationAccuracyKilometer` — still far finer than township targeting —
/// keeps energy minimal. Every trigger funnels into one path that re-centres the
/// region and hands the fix to `LocationReportSender`, which keeps it until the
/// server has confirmed it. Config is persisted to `UserDefaults`, so a
/// terminated relaunch re-arms everything in `register(with:)`.
///
/// `allowsBackgroundLocationUpdates` requires the `location` background mode and
/// an "Always" authorization string in `Info.plist`.
public class BackgroundLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
  private static let shared = BackgroundLocationPlugin()

  private let manager = CLLocationManager()
  private let defaults = UserDefaults.standard
  private let sender = LocationReportSender.shared

  private static let enabledKey = LocationReportStore.enabledKey
  private static let tokenKey = LocationReportStore.tokenKey
  private static let versionKey = LocationReportStore.versionKey
  private static let platformKey = LocationReportStore.platformKey
  private static let regionId = "dpip.bg.region"
  private static let regionRadius: CLLocationDistance = 250

  /// Callers waiting on an "upgrade to Always" prompt — see `requestAlways`.
  private var alwaysWaiters: [FlutterResult] = []
  /// Whether the app went inactive while waiting, i.e. the prompt is showing.
  private var alwaysPromptShown = false
  private var alwaysObservers: [NSObjectProtocol] = []
  private var alwaysTimers: [DispatchWorkItem] = []
  /// How long to wait for the prompt to appear before concluding iOS will not
  /// show it. The system offers the upgrade once per install and, after that,
  /// `requestAlwaysAuthorization` does nothing at all — no callback, no error —
  /// so silence past this point is the only answer there will be.
  private static let alwaysPromptGrace: TimeInterval = 2.5
  /// Backstop for a prompt that is shown and somehow never answered, so the
  /// Dart button awaiting this cannot stay busy forever.
  private static let alwaysPromptCeiling: TimeInterval = 120

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/background_location",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(shared, channel: channel)
    // Re-arm on a (background) relaunch so a terminated app keeps reporting.
    shared.resumeIfEnabled()
  }

  private override init() {
    super.init()
    manager.delegate = self
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = false
    manager.desiredAccuracy = kCLLocationAccuracyKilometer
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      guard
        let args = call.arguments as? [String: Any],
        let token = args["token"] as? String,
        let version = args["version"] as? String,
        let platform = args["platform"] as? Int
      else {
        result(FlutterError(code: "bad_args", message: "Missing start args", details: nil))
        return
      }
      defaults.set(true, forKey: Self.enabledKey)
      defaults.set(token, forKey: Self.tokenKey)
      defaults.set(version, forKey: Self.versionKey)
      defaults.set(platform, forKey: Self.platformKey)
      // A fix that has been waiting for a token — or for this one, after the
      // last was replaced — goes out now, under the token just stored.
      sender.retryPending("start")
      manager.requestAlwaysAuthorization()
      // Only arm once Always is granted; arming before the async authorization
      // resolves silently fails. locationManagerDidChangeAuthorization arms it
      // when the grant lands.
      if manager.authorizationStatus == .authorizedAlways {
        startMonitoring()
      }
      result(nil)
    case "requestAlways":
      requestAlways(result)
    case "stop":
      defaults.set(false, forKey: Self.enabledKey)
      stopMonitoring()
      sender.discardPending("background reporting stopped")
      result(nil)
    case "diagnostics":
      result(diagnostics())
    // Answered only once the delete has run. The developer page re-reads the
    // fix count the moment this returns, and replying early would show it the
    // count it just asked to throw away.
    case "clearTrack":
      LocationTrackStore.shared.clear {
        DispatchQueue.main.async { result(nil) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// A snapshot of whether background reporting is actually working, for the
  /// developer page. Keys are shared with the Android channel so one UI renders
  /// both.
  ///
  /// `armed` is deliberately the *observable* answer rather than a stored flag:
  /// iOS will happily accept `startMonitoringSignificantLocationChanges()`
  /// without Always authorization and simply never deliver, so trusting a
  /// "we called start" bit would report healthy on exactly the broken device.
  /// `monitoredRegions` is the one piece of real evidence Core Location gives
  /// back, so the region is what `armed` is derived from.
  /// Built as `[String: Any]` with absent keys rather than `[String: Any?]`
  /// with nil values: a Swift dictionary holding `Optional.none` has no
  /// well-defined bridge to the NSDictionary the standard method codec encodes.
  /// The Dart side reads a missing key as null, which is the same thing.
  private func diagnostics() -> [String: Any] {
    let status = manager.authorizationStatus
    let region = manager.monitoredRegions.first { $0.identifier == Self.regionId }
    let regionArmed = region != nil
    let always = status == .authorizedAlways
    let store = sender.store
    let lastAttemptAt = defaults.double(forKey: LocationReportStore.lastAttemptAtKey)
    let pending = store.pending

    var out: [String: Any] = [
      "enabled": defaults.bool(forKey: Self.enabledKey),
      "authorization": Self.describe(status),
      // Authorization alone is not evidence: iOS accepts
      // startMonitoringSignificantLocationChanges() without Always and simply
      // never delivers, so a stored "we called start" bit would read healthy on
      // exactly the broken device. monitoredRegions is the one thing Core
      // Location will actually confirm back.
      "armed": always && regionArmed,
      "spine": always ? (regionArmed ? "significant-change+region" : "significant-change") : "none",
      "hasToken": defaults.string(forKey: Self.tokenKey) != nil,
      "detail": [
        CLLocationManager.significantLocationChangeMonitoringAvailable()
          ? "SLC available" : "SLC unavailable",
        CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
          ? "region monitoring available" : "region monitoring unavailable",
        "\(manager.monitoredRegions.count) region(s) monitored",
        manager.allowsBackgroundLocationUpdates
          ? "background updates allowed" : "background updates NOT allowed",
        pending.map {
          "fix pending since \(Int(Date().timeIntervalSince($0.since)))s, \($0.failures) failed"
        } ?? "nothing pending",
      ].joined(separator: ", "),
    ]
    // Attempt and success apart, the same keys Android uses: a device whose
    // last attempt failed can still have delivered an hour ago, and one whose
    // last attempt succeeded may have been failing for a day before it.
    if lastAttemptAt != 0 {
      out["lastAttemptAt"] = Int(lastAttemptAt * 1000)
      out["lastAttemptOk"] = defaults.bool(forKey: LocationReportStore.lastAttemptOkKey)
      out["lastAttemptCode"] = defaults.integer(forKey: LocationReportStore.lastAttemptCodeKey)
    }
    if let lastSuccessAt = store.lastSuccessAt {
      out["lastSuccessAt"] = Int(lastSuccessAt.timeIntervalSince1970 * 1000)
      out["lastSuccessCode"] = defaults.integer(forKey: LocationReportStore.lastSuccessCodeKey)
    }
    // Where the region really sits, read back from Core Location. The stored
    // point is the last *delivered* fix now, which a failed report leaves
    // behind while the region moves on.
    if let centre = (region as? CLCircularRegion)?.center {
      out["centreLat"] = centre.latitude
      out["centreLng"] = centre.longitude
    }
    return out
  }

  private static func describe(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .authorizedAlways: return "always"
    case .authorizedWhenInUse: return "whenInUse"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "unknown"
    }
  }

  /// Upgrades "While Using" to "Always" in the app, answering with the status
  /// the user ends on (`describe`) once they have actually chosen.
  ///
  /// Owned here rather than by `permission_handler` because that plugin builds
  /// a new `CLLocationManager` per request, and Core Location reports the
  /// current status to every new manager immediately: the plugin takes that
  /// "While Using" for the user's answer and replies `denied` while the prompt
  /// is still on screen. This manager has existed since launch, so the only
  /// callbacks it gets are real changes.
  ///
  /// iOS gives no callback when the user keeps "While Using", and none when it
  /// declines to show the prompt at all, so three things end the wait: an
  /// authorization change, the app becoming active again after the prompt took
  /// it inactive, or the grace period passing with no prompt shown.
  private func requestAlways(_ result: @escaping FlutterResult) {
    let status = manager.authorizationStatus
    guard status == .authorizedWhenInUse else {
      result(Self.describe(status))
      return
    }
    alwaysWaiters.append(result)
    // One prompt answers every caller that asked while it was up.
    guard alwaysWaiters.count == 1 else { return }

    alwaysPromptShown = false
    let center = NotificationCenter.default
    let shown: (Notification) -> Void = { [weak self] _ in self?.alwaysPromptShown = true }
    let back: (Notification) -> Void = { [weak self] _ in
      guard let self, self.alwaysPromptShown else { return }
      self.finishAlwaysRequest()
    }
    // Both the app and the scene flavour: which one UIKit posts for a system
    // alert under the scene lifecycle is not documented, and the answer must
    // not depend on it.
    alwaysObservers = [
      center.addObserver(
        forName: UIApplication.willResignActiveNotification, object: nil, queue: .main,
        using: shown),
      center.addObserver(
        forName: UIScene.willDeactivateNotification, object: nil, queue: .main, using: shown),
      center.addObserver(
        forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main,
        using: back),
      center.addObserver(
        forName: UIScene.didActivateNotification, object: nil, queue: .main, using: back),
    ]
    let grace = DispatchWorkItem { [weak self] in
      guard let self, !self.alwaysPromptShown else { return }
      self.finishAlwaysRequest()
    }
    let ceiling = DispatchWorkItem { [weak self] in self?.finishAlwaysRequest() }
    alwaysTimers = [grace, ceiling]
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.alwaysPromptGrace, execute: grace)
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.alwaysPromptCeiling, execute: ceiling)
    manager.requestAlwaysAuthorization()
  }

  private func finishAlwaysRequest() {
    guard !alwaysWaiters.isEmpty else { return }
    alwaysObservers.forEach(NotificationCenter.default.removeObserver)
    alwaysObservers = []
    alwaysTimers.forEach { $0.cancel() }
    alwaysTimers = []
    let answer = Self.describe(manager.authorizationStatus)
    let waiters = alwaysWaiters
    alwaysWaiters = []
    waiters.forEach { $0(answer) }
  }

  private func startMonitoring() {
    manager.startMonitoringSignificantLocationChanges()
    manager.startMonitoringVisits()
    // Kick a one-shot fix to (re)centre the region promptly.
    manager.requestLocation()
  }

  private func stopMonitoring() {
    manager.stopMonitoringSignificantLocationChanges()
    manager.stopMonitoringVisits()
    for region in manager.monitoredRegions where region.identifier == Self.regionId {
      manager.stopMonitoring(for: region)
    }
  }

  private func resumeIfEnabled() {
    guard defaults.bool(forKey: Self.enabledKey),
      manager.authorizationStatus == .authorizedAlways
    else { return }
    startMonitoring()
    sender.retryPending("relaunch")
  }

  // MARK: - CLLocationManagerDelegate

  public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    // Any move off "While Using" answers a pending upgrade request; staying on
    // it is not an answer, because iOS may call this as the prompt goes up.
    if manager.authorizationStatus != .authorizedWhenInUse {
      finishAlwaysRequest()
    }
    // Arm as soon as Always is granted (the async grant after start(), or a
    // later upgrade in Settings).
    if manager.authorizationStatus == .authorizedAlways, defaults.bool(forKey: Self.enabledKey) {
      startMonitoring()
    }
  }

  public func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.last else { return }
    process(location.coordinate)
  }

  public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    guard region.identifier == Self.regionId else { return }
    // One fresh fix drives the single report + re-centre (via
    // didUpdateLocations) — avoids a stale double-report from manager.location.
    manager.requestLocation()
  }

  public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
    // Only an arrival ("still here"); a departure's coordinate is the place left.
    guard visit.departureDate == Date.distantFuture else { return }
    process(visit.coordinate)
  }

  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // Best-effort — SLC / region / visits keep running. The wake itself is
    // still a moment to send a fix that is waiting.
    guard defaults.bool(forKey: Self.enabledKey) else { return }
    sender.retryPending("wake without a fix")
  }

  private func process(_ coordinate: CLLocationCoordinate2D) {
    guard defaults.bool(forKey: Self.enabledKey), CLLocationCoordinate2DIsValid(coordinate) else {
      return
    }
    recenterRegion(coordinate)
    // Before the distance gate on purpose. The gate exists to spare the
    // server, and the local track has no server to spare — dropping a fix the
    // OS took the trouble to deliver, because a report would have been too
    // soon, would put holes in the history for a reason that has nothing to do
    // with it.
    LocationTrackStore.shared.record(
      latitude: coordinate.latitude, longitude: coordinate.longitude)
    // The distance gate, the pending fix and the retries are the sender's.
    sender.process(coordinate)
  }

  private func recenterRegion(_ coordinate: CLLocationCoordinate2D) {
    guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
    for region in manager.monitoredRegions where region.identifier == Self.regionId {
      manager.stopMonitoring(for: region)
    }
    let region = CLCircularRegion(
      center: coordinate, radius: Self.regionRadius, identifier: Self.regionId)
    region.notifyOnEntry = false
    region.notifyOnExit = true
    manager.startMonitoring(for: region)
  }
}
