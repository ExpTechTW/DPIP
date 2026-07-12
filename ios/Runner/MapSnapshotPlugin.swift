import Flutter
import MapLibre
import UIKit

/// MethodChannel plugin that renders a MapLibre style to a PNG **off-screen**
/// via `MLNMapSnapshotter` — no map view is ever shown.
///
/// Flutter cannot capture an on-screen `UiKitView` map (platform views are
/// blank in `RepaintBoundary`), so the home page renders its map backdrop this
/// way instead: a static image that never fights the draggable sheet for
/// gestures and is far lighter than a live map.
public class MapSnapshotPlugin: NSObject, FlutterPlugin {
  /// Snapshotters in flight, retained until their completion handler runs.
  private var pending: [MLNMapSnapshotter] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/map_snapshot",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(MapSnapshotPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capture":
      capture(call.arguments as? [String: Any] ?? [:], result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func capture(_ args: [String: Any], result: @escaping FlutterResult) {
    guard
      let style = args["style"] as? String,
      let latitude = args["latitude"] as? Double,
      let longitude = args["longitude"] as? Double,
      let zoom = args["zoom"] as? Double,
      let width = args["width"] as? Double,
      let height = args["height"] as? Double
    else {
      result(FlutterError(code: "bad_args", message: "Missing snapshot arguments", details: nil))
      return
    }

    // MLNMapSnapshotOptions needs a style URL — write the JSON to a temp file.
    let styleURL: URL
    do {
      styleURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("dpip-snapshot-\(UUID().uuidString).json")
      try style.write(to: styleURL, atomically: true, encoding: .utf8)
    } catch {
      result(FlutterError(code: "style_write", message: error.localizedDescription, details: nil))
      return
    }

    let camera = MLNMapCamera()
    camera.centerCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let options = MLNMapSnapshotOptions(
      styleURL: styleURL,
      camera: camera,
      size: CGSize(width: width, height: height))
    options.zoomLevel = zoom

    let snapshotter = MLNMapSnapshotter(options: options)
    pending.append(snapshotter)
    snapshotter.start { [weak self] snapshot, error in
      try? FileManager.default.removeItem(at: styleURL)
      self?.pending.removeAll { $0 === snapshotter }
      if let error = error {
        result(FlutterError(code: "snapshot_failed", message: error.localizedDescription, details: nil))
        return
      }
      guard let png = snapshot?.image.pngData() else {
        result(FlutterError(code: "no_image", message: "Snapshot produced no image", details: nil))
        return
      }
      result(FlutterStandardTypedData(bytes: png))
    }
  }
}
