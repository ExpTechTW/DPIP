import Flutter
import Foundation
import WidgetKit

/// The native allowlist provides storage and WidgetKit identities.
enum WidgetSnapshotKind: String {
  case weatherForecast
  case currentWeather
  case locationCatalog

  var filename: String {
    switch self {
    case .weatherForecast:
      return "weather-forecast.json"
    case .currentWeather:
      return "current-weather.json"
    case .locationCatalog:
      return "location-catalog.json"
    }
  }

  var widgetKind: String? {
    switch self {
    case .weatherForecast:
      return "DPIPWidgets"
    case .currentWeather:
      return "DPIPWidgets"
    case .locationCatalog:
      return nil
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

  static func replace(
    _ data: Data,
    kind: WidgetSnapshotKind,
    sourceIdentifier: String? = nil,
    in container: URL
  ) throws {
    do {
      if kind == .currentWeather {
        guard
          let sourceIdentifier,
          let address = CurrentWeatherSnapshotAddress(
            sourceIdentifier: sourceIdentifier
          )
        else {
          throw WidgetSnapshotError.invalidPayload
        }

        try CurrentWeatherSnapshotStorage(
          containerURL: container
        ).replace(
          data,
          for: address
        )
        return
      }

      let destination = try snapshotURL(
        kind: kind,
        sourceIdentifier: sourceIdentifier,
        in: container
      )

      try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )

      try data.write(
        to: destination,
        options: .atomic
      )
    } catch let error as WidgetSnapshotError {
      throw error
    } catch {
      throw WidgetSnapshotError.writeFailed
    }
  }

  static func clear(_ kind: WidgetSnapshotKind, in container: URL) throws {
    let directory = container.appendingPathComponent("WidgetSnapshots", isDirectory: true)
    let snapshot = directory.appendingPathComponent(kind.filename)
    do {
      try FileManager.default.removeItem(at: snapshot)
    } catch let error as CocoaError where error.code == .fileNoSuchFile {
      // Clearing an absent snapshot is intentionally idempotent.
    } catch {
      throw WidgetSnapshotError.writeFailed
    }
  }

  static func snapshotURL(
    kind: WidgetSnapshotKind,
    sourceIdentifier: String?,
    in container: URL
  ) throws -> URL {
    let directory = container.appendingPathComponent(
      "WidgetSnapshots",
      isDirectory: true
    )

    switch kind {
    case .currentWeather:
      guard
        let sourceIdentifier,
        let address = CurrentWeatherSnapshotAddress(
          sourceIdentifier: sourceIdentifier
        )
      else {
        throw WidgetSnapshotError.invalidPayload
      }

      return CurrentWeatherSnapshotStorage(
        containerURL: container
      ).snapshotURL(for: address)

    case .weatherForecast:
      return directory.appendingPathComponent(
        kind.filename
      )

    case .locationCatalog:
      return directory.appendingPathComponent(
        kind.filename
      )
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
    if call.method == "clear" {
      handleClear(call, result: result)
      return
    }

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

    let sourceIdentifier = arguments["sourceIdentifier"] as? String

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
        try WidgetSnapshotFile.replace(
          data,
          kind: kind,
          sourceIdentifier: sourceIdentifier,
          in: container
        )
        if let widgetKind = kind.widgetKind {
          WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        }
        DispatchQueue.main.async { result(nil) }
      } catch let error as WidgetSnapshotError {
        DispatchQueue.main.async { result(self.flutterError(error)) }
      } catch {
        DispatchQueue.main.async { result(self.flutterError(.writeFailed)) }
      }
    }
  }

  private func handleClear(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let rawKind = arguments["kind"] as? String
    else {
      result(flutterError(.invalidKind))
      return
    }

    let kind: WidgetSnapshotKind
    do {
      kind = try WidgetSnapshotFile.kind(rawKind)
    } catch let error as WidgetSnapshotError {
      result(flutterError(error))
      return
    } catch {
      result(flutterError(.invalidKind))
      return
    }

    writeQueue.async {
      guard let group = Bundle.main.object(forInfoDictionaryKey: "DPIPWidgetAppGroupIdentifier") as? String,
        let container = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: group)
      else {
        DispatchQueue.main.async { result(self.flutterError(.appGroupUnavailable)) }
        return
      }

      do {
        try WidgetSnapshotFile.clear(kind, in: container)
        if let widgetKind = kind.widgetKind {
          WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        }
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
