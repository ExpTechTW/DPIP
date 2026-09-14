import Flutter
import Foundation
import WidgetKit

/// The native allowlist provides storage and WidgetKit identities.
enum WidgetSnapshotKind: String {
  case weatherForecast

  var filename: String {
    switch self {
    case .weatherForecast:
      return "weather-forecast.json"
    }
  }

  var widgetKind: String {
    switch self {
    case .weatherForecast:
      return "DPIPWidgets"
    }
  }
}

enum WidgetSnapshotError: Error, Equatable {
  case invalidKind
  case invalidPayload
  case appGroupUnavailable
  case writeFailed

  var flutterCode: String {
    switch self {
    case .invalidKind: return "invalid_kind"
    case .invalidPayload: return "invalid_payload"
    case .appGroupUnavailable: return "app_group_unavailable"
    case .writeFailed: return "write_failed"
    }
  }
}

/// File operations are separate so RunnerTests can exercise them in a sandbox.
enum WidgetSnapshotFile {
  static let maximumPayloadBytes = 128 * 1024

  static func kind(_ rawValue: String) throws -> WidgetSnapshotKind {
    guard let kind = WidgetSnapshotKind(rawValue: rawValue) else {
      throw WidgetSnapshotError.invalidKind
    }
    return kind
  }

  static func payload(_ json: String) throws -> Data {
    let data = Data(json.utf8)
    guard !data.isEmpty, data.count <= maximumPayloadBytes,
      let object = try? JSONSerialization.jsonObject(with: data),
      object is [String: Any]
    else {
      throw WidgetSnapshotError.invalidPayload
    }
    return data
  }

  static func replace(_ data: Data, kind: WidgetSnapshotKind, in container: URL) throws {
    let directory = container.appendingPathComponent("WidgetSnapshots", isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      // Foundation stages the complete bytes in this directory and renames the
      // temporary file over the destination. Readers see an old or new inode.
      try data.write(to: directory.appendingPathComponent(kind.filename), options: .atomic)
    } catch {
      throw WidgetSnapshotError.writeFailed
    }
  }
}

/// Infrastructure-only Flutter bridge. It never interprets domain JSON.
public final class WidgetSnapshotPlugin: NSObject, FlutterPlugin {
  private let writeQueue = DispatchQueue(label: "com.exptech.dpip.widget-snapshot.write")

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/widget_snapshot",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(WidgetSnapshotPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "write" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard let arguments = call.arguments as? [String: Any],
      let rawKind = arguments["kind"] as? String,
      let json = arguments["json"] as? String
    else {
      result(flutterError(.invalidPayload))
      return
    }

    let kind: WidgetSnapshotKind
    let data: Data
    do {
      kind = try WidgetSnapshotFile.kind(rawKind)
      data = try WidgetSnapshotFile.payload(json)
    } catch let error as WidgetSnapshotError {
      result(flutterError(error))
      return
    } catch {
      result(flutterError(.invalidPayload))
      return
    }

    writeQueue.async {
      // An absent key or a profile without this entitlement must fail closed.
      guard let group = Bundle.main.object(forInfoDictionaryKey: "DPIPWidgetAppGroupIdentifier") as? String,
        let container = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: group)
      else {
        DispatchQueue.main.async { result(self.flutterError(.appGroupUnavailable)) }
        return
      }

      do {
        try WidgetSnapshotFile.replace(data, kind: kind, in: container)
        WidgetCenter.shared.reloadTimelines(ofKind: kind.widgetKind)
        DispatchQueue.main.async { result(nil) }
      } catch {
        DispatchQueue.main.async { result(self.flutterError(.writeFailed)) }
      }
    }
  }

  private func flutterError(_ error: WidgetSnapshotError) -> FlutterError {
    FlutterError(code: error.flutterCode, message: error.flutterCode, details: nil)
  }
}
