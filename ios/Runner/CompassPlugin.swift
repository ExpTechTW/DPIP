import CoreLocation
import Flutter

/// EventChannel plugin streaming device heading via CoreLocation, replacing
/// `flutter_compass` on iOS.
///
/// Emits **magnetic** heading so it agrees with the Android rotation-vector
/// output; magnetic heading needs no location authorization. (True north would
/// require active location updates and a usage-description key.) Registered as a
/// real `FlutterPlugin` for the Flutter 3.44 implicit-engine lifecycle.
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
    manager.startUpdatingHeading()
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    manager.delegate = nil
    sink = nil
    return nil
  }

  public func locationManager(
    _ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading
  ) {
    sink?([
      "heading": newHeading.magneticHeading,
      "accuracy": newHeading.headingAccuracy,
    ])
  }

  public func locationManagerShouldDisplayHeadingCalibration(
    _ manager: CLLocationManager
  ) -> Bool {
    return true
  }
}
