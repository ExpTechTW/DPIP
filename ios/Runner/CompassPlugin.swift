import CoreLocation
import Flutter

/// EventChannel plugin streaming device heading via CoreLocation, replacing
/// `flutter_compass` on iOS.
///
/// Emits **magnetic** heading. Location updates are started alongside heading —
/// on modern iOS, `startUpdatingHeading` alone often never delivers samples
/// until the location manager is also running (and when-in-use auth is granted).
/// Registered as a real `FlutterPlugin` for the Flutter 3.44 implicit-engine
/// lifecycle.
public class CompassPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  CLLocationManagerDelegate
{
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterEventChannel(
      name: "com.exptech.dpip/compass",
      binaryMessenger: registrar.messenger())
    channel.setStreamHandler(CompassPlugin())
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard CLLocationManager.headingAvailable() else {
      return FlutterError(
        code: "UNAVAILABLE", message: "Heading not available", details: nil)
    }
    sink = events
    manager.delegate = self
    manager.headingFilter = 1
    // Desired accuracy for the location side-channel that unlocks heading.
    manager.desiredAccuracy = kCLLocationAccuracyKilometer
    manager.startUpdatingLocation()
    manager.startUpdatingHeading()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    manager.stopUpdatingLocation()
    manager.delegate = nil
    sink = nil
    return nil
  }

  public func locationManager(
    _ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading
  ) {
    // Negative accuracy means the reading is invalid / uncalibrated.
    guard newHeading.headingAccuracy >= 0 else { return }
    let heading = newHeading.magneticHeading
    guard heading >= 0, heading <= 360, !heading.isNaN else { return }
    sink?([
      "heading": heading,
      "accuracy": newHeading.headingAccuracy,
    ])
  }

  public func locationManager(
    _ manager: CLLocationManager, didFailWithError error: Error
  ) {
    // Location fail must not tear down heading — ignore.
  }

  public func locationManagerShouldDisplayHeadingCalibration(
    _ manager: CLLocationManager
  ) -> Bool {
    return true
  }
}
