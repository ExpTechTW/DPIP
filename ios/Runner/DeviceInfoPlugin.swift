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
  /// The App Store receipt's filename is the first marker: TestFlight (and a
  /// debug build run from Xcode) gets a `sandboxReceipt`, an App Store install
  /// gets `receipt`. A DEBUG build is never a store install, so it is reported
  /// as a sideload rather than as TestFlight, which would otherwise put every
  /// developer on the beta channel.
  ///
  /// On its own `sandboxReceipt` cannot separate TestFlight from a locally
  /// signed install — the GitHub release IPA re-signed by AltStore or
  /// Sideloadly carries one too, and that user must land on the GitHub release
  /// page, not a TestFlight app that holds no DPIP update for them. The
  /// discriminator is the embedded provisioning profile: App Store Connect
  /// strips it from TestFlight builds, while any profile-signed bundle keeps
  /// it.
  private static func installSource() -> String {
    #if DEBUG
      return "development"
    #else
      guard let receipt = Bundle.main.appStoreReceiptURL else { return "github" }
      // A simulator has no App Store; its receipt lives under CoreSimulator
      // and would otherwise read as an App Store install.
      if receipt.path.contains("CoreSimulator") { return "development" }
      guard receipt.lastPathComponent == "sandboxReceipt" else { return "appStore" }
      return Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") == nil
        ? "testFlight"
        : "sideload"
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
