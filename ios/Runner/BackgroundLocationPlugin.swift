import CoreLocation
import Flutter
import UIKit

/// Native, autonomous background device-location reporting.
///
/// Reports the device's coordinates to `updateDeviceLocation` on significant
/// moves — even while the app is backgrounded or terminated — via Core
/// Location's **Significant Location Change** service, which relaunches the app
/// in the background to deliver a fix. The Dart side (`BackgroundLocationService`)
/// only hands over the push token, app version, and platform code; the request
/// is issued here so it never needs the Flutter isolate alive. Config is
/// persisted to `UserDefaults`, so a terminated relaunch re-arms monitoring in
/// `register(with:)` and keeps reporting without any Dart round-trip.
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
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
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
      manager.startMonitoringSignificantLocationChanges()
      result(nil)
    case "stop":
      defaults.set(false, forKey: Self.enabledKey)
      manager.stopMonitoringSignificantLocationChanges()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func resumeIfEnabled() {
    guard defaults.bool(forKey: Self.enabledKey) else { return }
    manager.startMonitoringSignificantLocationChanges()
  }

  public func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    guard
      let location = locations.last,
      let token = defaults.string(forKey: Self.tokenKey),
      let version = defaults.string(forKey: Self.versionKey)
    else { return }
    report(
      platform: defaults.integer(forKey: Self.platformKey),
      token: token, version: version, location: location)
  }

  private func report(platform: Int, token: String, version: String, location: CLLocation) {
    let lat = location.coordinate.latitude
    let lng = location.coordinate.longitude
    // coreExclusiveApi is tnn1-only (no failover) — matches ApiTier.coreExclusiveApi.
    let urlString =
      "https://api.core-tnn1.exptech.dev/api/v2/location/\(platform)/\(token)/\(version)/\(lat),\(lng)"
    guard let url = URL(string: urlString) else { return }

    // A short-lived background task so the GET can finish after a background
    // relaunch (SLC grants a brief execution window).
    var task = UIBackgroundTaskIdentifier.invalid
    task = UIApplication.shared.beginBackgroundTask {
      UIApplication.shared.endBackgroundTask(task)
      task = .invalid
    }
    URLSession.shared.dataTask(with: url) { _, _, _ in
      if task != .invalid {
        UIApplication.shared.endBackgroundTask(task)
        task = .invalid
      }
    }.resume()
  }
}
