import Flutter
import UIKit

/// Keeps the display awake while a screen asks for it — the mesh conversation,
/// so a radio being watched doesn't go dark mid-exchange.
///
/// `isIdleTimerDisabled` only applies to the foreground app, so backgrounding
/// already neutralises it; the flag is still cleared explicitly when the screen
/// that asked for it goes away, so it can never outlive its reason.
public class ScreenWakePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/screen_wake",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ScreenWakePlugin(), channel: channel)
  }

  public func handle(
    _ call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    switch call.method {
    case "enable", "disable":
      let keepAwake = call.method == "enable"
      // UIApplication is main-thread only.
      DispatchQueue.main.async {
        UIApplication.shared.isIdleTimerDisabled = keepAwake
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
