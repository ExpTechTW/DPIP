import Flutter
import MapLibre
import UIKit

/// MethodChannel plugin that raises MapLibre's shared **ambient tile-cache**
/// ceiling via `MLNOfflineStorage` — `maplibre_gl` exposes no size bound and the
/// native default is only ~50 MB. It writes to `MLNOfflineStorage.shared`, the
/// same storage the live map view and the home snapshot read, so more radar
/// frames stay cached and scrubbing re-fetches less.
public class MapCachePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/map_cache",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(MapCachePlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setMaximumAmbientCacheSize":
      guard
        let args = call.arguments as? [String: Any],
        let bytes = args["bytes"] as? Int, bytes >= 0
      else {
        result(FlutterError(code: "bad_args", message: "Missing bytes", details: nil))
        return
      }
      // Lowering the ceiling trims (LRU) immediately; raising it just lifts the
      // cap. Completion runs on the main queue.
      MLNOfflineStorage.shared.setMaximumAmbientCacheSize(UInt(bytes)) { error in
        if let error = error {
          result(FlutterError(code: "cache_failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
