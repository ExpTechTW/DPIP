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
        "totalMemoryMb": ProcessInfo.processInfo.physicalMemory / 1024 / 1024,
      ])
    case "getInstallSource":
      result(DeviceInfoPlugin.installSource())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Where this build came from — which decides where an update prompt sends
  /// the user.
  ///
  /// The App Store receipt's filename is the marker: TestFlight (and a debug
  /// build run from Xcode) gets a `sandboxReceipt`, an App Store install gets
  /// `receipt`. A DEBUG build is never a store install, so it is reported as a
  /// sideload rather than as TestFlight, which would otherwise put every
  /// developer on the beta channel.
  private static func installSource() -> String {
    #if DEBUG
      return "sideload"
    #else
      guard let receipt = Bundle.main.appStoreReceiptURL else { return "sideload" }
      return receipt.lastPathComponent == "sandboxReceipt" ? "testFlight" : "appStore"
    #endif
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
