import Flutter
import MapLibre
import UIKit

/// MethodChannel plugin for MapLibre's shared **ambient tile-cache**:
/// raise the size ceiling and preload resources fetched by the Flutter HTTP
/// stack (ETag-aware) so MapLibre tile requests hit ambient at the same URL.
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
    case "preload":
      guard
        let args = call.arguments as? [String: Any],
        let urlString = args["url"] as? String,
        let url = URL(string: urlString),
        let typed = args["data"] as? FlutterStandardTypedData
      else {
        result(FlutterError(code: "bad_args", message: "Missing url/data", details: nil))
        return
      }
      let etag = args["etag"] as? String
      let modifiedSec = (args["modified"] as? NSNumber)?.doubleValue ?? 0
      let expiresSec = (args["expires"] as? NSNumber)?.doubleValue ?? 0
      let mustRevalidate = args["mustRevalidate"] as? Bool ?? false
      let modified: Date? = modifiedSec > 0
        ? Date(timeIntervalSince1970: modifiedSec) : nil
      let expires: Date? = expiresSec > 0
        ? Date(timeIntervalSince1970: expiresSec) : nil
      MLNOfflineStorage.shared.preload(
        typed.data,
        for: url,
        modificationDate: modified,
        expirationDate: expires,
        eTag: etag,
        mustRevalidate: mustRevalidate,
        completionHandler: { _, error in
          if let error = error {
            result(FlutterError(
              code: "preload_failed",
              message: error.localizedDescription,
              details: nil))
          } else {
            result(nil)
          }
        }
      )
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
