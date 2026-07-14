import Flutter
import UIKit

/// MethodChannel plugin returning basic device identity, replacing
/// `device_info_plus` on iOS.
///
/// Returns only the raw `utsname.machine` code; the marketing-name lookup is
/// resolved in Dart so it can be updated without a native rebuild. Registered
/// as a real `FlutterPlugin` (via the plugin registrar) so the handler is
/// retained under the Flutter 3.44 implicit-engine lifecycle.
public class DeviceInfoPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/device_info",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(DeviceInfoPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDeviceInfo":
      result([
        "manufacturer": "Apple",
        "model": DeviceInfoPlugin.machineCode(),
        "osVersion": UIDevice.current.systemVersion,
        "sdkInt": NSNull(),
        "identifier": UIDevice.current.identifierForVendor?.uuidString as Any,
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// The hardware identifier, e.g. `iPhone16,1`.
  private static func machineCode() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafePointer(to: &systemInfo.machine) { pointer in
      pointer.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
    }
  }
}
