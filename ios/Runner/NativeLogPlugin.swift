import Flutter
import Foundation

/// Hands the native log buffer to Dart and clears it in the same call.
///
/// `take` reads the file and replaces it with an empty array only after that
/// read returns. An I/O error is returned to Dart with the file untouched.
public class NativeLogPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/native_log",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(NativeLogPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "take":
      guard let log = FileNativeLog.appGroup() else {
        result([])
        return
      }
      do {
        result(try log.take().map(\.wire))
      } catch {
        result(
          FlutterError(
            code: "native_log_io",
            message: "native log handoff failed",
            details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
