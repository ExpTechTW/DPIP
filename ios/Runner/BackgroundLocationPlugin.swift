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
/// keeps energy minimal. Every trigger funnels into one report path that POSTs
/// and re-centres the region. Config is persisted to `UserDefaults`, so a
/// terminated relaunch re-arms everything in `register(with:)`.
///
/// `allowsBackgroundLocationUpdates` requires the `location` background mode and
/// an "Always" authorization string in `Info.plist`.
public class BackgroundLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
  private static let shared = BackgroundLocationPlugin()

  private let manager = CLLocationManager()
  private let defaults = UserDefaults.standard

  private static let enabledKey = "dpip.bgloc.enabled"
  private static let tokenKey = "dpip.bgloc.token"
  private static let versionKey = "dpip.bgloc.version"
  private static let platformKey = "dpip.bgloc.platform"
  private static let lastLatKey = "dpip.bgloc.lastLat"
  private static let lastLngKey = "dpip.bgloc.lastLng"
  private static let regionId = "dpip.bg.region"
  private static let regionRadius: CLLocationDistance = 250
  // Skip a report within this distance of the last one, so SLC + region + visit
  // firing for the same move don't produce duplicate POSTs.
  private static let reportThresholdM: CLLocationDistance = 150

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
      manager.requestAlwaysAuthorization()
      // Only arm once Always is granted; arming before the async authorization
      // resolves silently fails. locationManagerDidChangeAuthorization arms it
      // when the grant lands.
      if manager.authorizationStatus == .authorizedAlways {
        startMonitoring()
      }
      result(nil)
    case "stop":
      defaults.set(false, forKey: Self.enabledKey)
      stopMonitoring()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
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
  }

  // MARK: - CLLocationManagerDelegate

  public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
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
    // Best-effort — SLC / region / visits keep running.
  }

  private func process(_ coordinate: CLLocationCoordinate2D) {
    guard defaults.bool(forKey: Self.enabledKey), CLLocationCoordinate2DIsValid(coordinate) else {
      return
    }
    recenterRegion(coordinate)
    guard shouldReport(coordinate) else { return }
    report(coordinate)
    defaults.set(coordinate.latitude, forKey: Self.lastLatKey)
    defaults.set(coordinate.longitude, forKey: Self.lastLngKey)
  }

  // De-dup: skip a report within `reportThresholdM` of the last reported point.
  private func shouldReport(_ coordinate: CLLocationCoordinate2D) -> Bool {
    guard defaults.object(forKey: Self.lastLatKey) != nil else { return true }
    let last = CLLocation(
      latitude: defaults.double(forKey: Self.lastLatKey),
      longitude: defaults.double(forKey: Self.lastLngKey))
    let now = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    return now.distance(from: last) >= Self.reportThresholdM
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

  private func report(_ coordinate: CLLocationCoordinate2D) {
    guard
      let token = defaults.string(forKey: Self.tokenKey),
      let version = defaults.string(forKey: Self.versionKey)
    else { return }
    let platform = defaults.integer(forKey: Self.platformKey)
    // coreExclusiveApi is tnn1-only (no failover) — matches ApiTier.coreExclusiveApi.
    let urlString =
      "https://api.core-tnn1.exptech.dev/api/v2/location/\(platform)/\(token)/\(version)/\(coordinate.latitude),\(coordinate.longitude)"
    guard let url = URL(string: urlString) else { return }

    // A short-lived background task so the GET can finish after a background
    // relaunch (the wake window is brief); cancel it if the window closes first.
    var task = UIBackgroundTaskIdentifier.invalid
    let dataTask = URLSession.shared.dataTask(with: url) { _, _, _ in
      if task != .invalid {
        UIApplication.shared.endBackgroundTask(task)
        task = .invalid
      }
    }
    task = UIApplication.shared.beginBackgroundTask {
      dataTask.cancel()
      if task != .invalid {
        UIApplication.shared.endBackgroundTask(task)
        task = .invalid
      }
    }
    dataTask.resume()
  }
}
