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
    case "capture", "captureWithProjection":
      capture(
        call.arguments as? [String: Any] ?? [:],
        withProjection: call.method == "captureWithProjection",
        result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func capture(
    _ args: [String: Any], withProjection: Bool, result: @escaping FlutterResult
  ) {
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

    let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let scale = args["pixelRatio"] as? Double
    let points: [String: CLLocationCoordinate2D]?
    if withProjection {
      guard
        let coordinates = Self.projectionPoints(args["points"]),
        CLLocationCoordinate2DIsValid(center),
        zoom.isFinite,
        let scale, [1.0, 2.0, 3.0].contains(scale),
        Self.validDimension(width, scale: scale), Self.validDimension(height, scale: scale)
      else {
        result(FlutterError(
          code: "bad_args", message: "Invalid snapshot viewport, camera or points", details: nil))
        return
      }
      points = coordinates
    } else {
      points = nil
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
    camera.centerCoordinate = center
    let options = MLNMapSnapshotOptions(
      styleURL: styleURL,
      camera: camera,
      size: CGSize(width: width, height: height))
    options.zoomLevel = zoom
    // Keep the existing default unless explicitly overridden.
    options.showsLogo = (args["showLogo"] as? Bool) ?? true
    if let scale, scale > 0 {
      options.scale = CGFloat(scale)
    }

    let snapshotter = MLNMapSnapshotter(options: options)
    pending.append(snapshotter)
    snapshotter.start { [weak self] snapshot, error in
      try? FileManager.default.removeItem(at: styleURL)
      self?.pending.removeAll { $0 === snapshotter }
      if let error = error {
        result(FlutterError(code: "snapshot_failed", message: error.localizedDescription, details: nil))
        return
      }
      guard let snapshot, let png = snapshot.image.pngData() else {
        result(FlutterError(code: "no_image", message: "Snapshot produced no image", details: nil))
        return
      }
      let bytes = FlutterStandardTypedData(bytes: png)
      guard let points, let scale else {
        result(bytes)
        return
      }
      guard let response = Self.projectionResponse(
        snapshot, png: bytes, width: width, height: height, scale: scale, points: points)
      else {
        result(FlutterError(
          code: "invalid_projection", message: "Invalid snapshot dimensions or points", details: nil))
        return
      }
      result(response)
    }
  }

  private static func projectionPoints(_ raw: Any?) -> [String: CLLocationCoordinate2D]? {
    guard let entries = raw as? [[String: Any]], !entries.isEmpty else { return nil }
    var points: [String: CLLocationCoordinate2D] = [:]
    for entry in entries {
      guard
        let id = entry["id"] as? String, !id.isEmpty, points[id] == nil,
        let latitude = entry["latitude"] as? Double,
        let longitude = entry["longitude"] as? Double
      else { return nil }
      let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
      points[id] = coordinate
    }
    return points
  }

  private static func validDimension(_ value: Double, scale: Double) -> Bool {
    value >= 1 && value <= Double(Int32.max) / scale && value.rounded(.towardZero) == value
  }

  private static func projectionResponse(
    _ snapshot: MLNMapSnapshot, png: FlutterStandardTypedData,
    width: Double, height: Double, scale: Double,
    points: [String: CLLocationCoordinate2D]
  ) -> [String: Any]? {
    let image = snapshot.image
    guard
      let raster = image.cgImage, raster.width == Int(width * scale),
      raster.height == Int(height * scale), image.scale == CGFloat(scale)
    else { return nil }

    // MapLibre's iOS API takes and returns UIImage points, independent of scale.
    var projected: [String: [Double]] = [:]
    for (id, coordinate) in points {
      let point = snapshot.point(for: coordinate)
      guard point.x.isFinite, point.y.isFinite else { return nil }
      projected[id] = [
        Double(point.x / image.size.width) * width,
        Double(point.y / image.size.height) * height,
      ]
    }
    return [
      "png": png,
      "pngWidth": raster.width, "pngHeight": raster.height,
      "logicalWidth": width, "logicalHeight": height,
      "points": projected,
    ]
  }
}
