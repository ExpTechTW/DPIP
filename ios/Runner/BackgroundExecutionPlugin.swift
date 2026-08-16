import Flutter
import UIKit

/// Whether iOS will still run this app's background work — the layer below
/// permissions, and the one that fails silently.
///
/// **Background App Refresh is not an optimisation on this app; it is a
/// prerequisite.** With it off, iOS does not relaunch the app for *any* location
/// event — significant-change and region monitoring included — and does not even
/// deliver those events while the app is in the foreground. So a device can hold
/// "Always" location, hold notifications, report `armed: true` from
/// `BackgroundLocationPlugin` (the region really is monitored), and still never
/// report a thing. Nothing else in the app can see that.
///
/// It has no request API: it is a Settings toggle, per-app and also global, so
/// all this can do is read it and take the user to the app's own Settings page.
/// `.restricted` is a separate answer from `.denied` on purpose — under a
/// parental-control or MDM profile the switch is not the user's to flip, and
/// telling them to go and change it would be wrong.
///
/// Deliberately mirrors the shape of Android's `BackgroundExecutionChannel`
/// (`restricted` + a human `detail`) so one Dart facade and one row of UI
/// render both platforms.
public class BackgroundExecutionPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/background_execution",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(BackgroundExecutionPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "status":
      result(status())

    case "openOemSettings":
      // No vendor layer on iOS — there is one Settings page and it is ours.
      guard let url = URL(string: UIApplication.openSettingsURLString) else {
        result("none")
        return
      }
      DispatchQueue.main.async { UIApplication.shared.open(url) }
      result("appDetails")

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func status() -> [String: Any] {
    // Read directly, NOT through `DispatchQueue.main.sync`: Flutter delivers
    // method calls on the platform thread, which is the main thread, so hopping
    // to main synchronously from here deadlocks the app instead of guarding
    // anything. `UIApplication.shared` is main-thread-only state and this is
    // already the main thread.
    let refresh = UIApplication.shared.backgroundRefreshStatus
    return [
      "restricted": refresh != .available,
      // Distinguishes "the user turned it off" from "a profile forbids it",
      // which decide whether the row should offer to open Settings at all.
      "lockedByPolicy": refresh == .restricted,
      "standbyBucket": describe(refresh),
      "manufacturer": "Apple",
      "vendorManaged": false,
    ]
  }

  private func describe(_ status: UIBackgroundRefreshStatus) -> String {
    switch status {
    case .available: return "available"
    case .denied: return "denied"
    case .restricted: return "restricted"
    @unknown default: return "unknown"
    }
  }
}
