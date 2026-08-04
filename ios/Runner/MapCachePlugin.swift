import Flutter
import MapLibre
import UIKit

/// MethodChannel plugin for MapLibre's shared **ambient tile-cache**.
///
/// Only sizes it. The app disables ambient caching (`MapCache.disabledBytes`)
/// and serves those bytes from its own store through the MapLibre tile bridge,
/// so there is nothing to preload here.
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
