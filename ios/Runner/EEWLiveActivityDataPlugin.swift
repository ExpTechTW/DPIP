import Flutter
import Foundation

/// Writes what the EEW Live Activity widget reads from the App Group: the
/// packed S-wave table and the observer (`EEWLiveActivityStore`). The Dart
/// side is `lib/core/platform/eew_live_activity_data.dart`; it decides what
/// and when, this only stores.
public final class EEWLiveActivityDataPlugin: NSObject, FlutterPlugin {
    private let writeQueue = DispatchQueue(label: "com.exptech.dpip.eew-live-activity-data")
    private let store: () -> EEWLiveActivityStore?

    init(store: @escaping () -> EEWLiveActivityStore? = { EEWLiveActivityStore() }) {
        self.store = store
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.exptech.dpip/eew_live_activity_data",
            binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(EEWLiveActivityDataPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        let write: (EEWLiveActivityStore) throws -> Any?
        switch call.method {
        case "travelTimeVersion":
            write = { $0.tableVersion() }
        case "writeTravelTime":
            guard let table = arguments?["table"] as? FlutterStandardTypedData,
                  let version = arguments?["version"] as? Int else {
                return result(Self.invalid)
            }
            write = { store in
                try store.writeTable(table.data, version: version)
                return true
            }
        case "writeFix":
            guard let lat = arguments?["lat"] as? Double, let lng = arguments?["lng"] as? Double else {
                return result(Self.invalid)
            }
            write = { store in
                try store.updateObserver { $0.fix = .init(lat: lat, lng: lng) }
                return true
            }
        case "writeTown":
            let town: EEWObserver.Town?
            if let code = arguments?["code"] as? String, let lat = arguments?["lat"] as? Double,
               let lng = arguments?["lng"] as? Double {
                town = .init(code: code, lat: lat, lng: lng)
            } else {
                town = nil
            }
            write = { store in
                try store.updateObserver { $0.town = town }
                return true
            }
        default:
            return result(FlutterMethodNotImplemented)
        }

        // Files off the main thread; the observer read-modify-write is
        // serialised by the queue.
        writeQueue.async { [store] in
            let response: Any?
            if let store = store() {
                do {
                    response = try write(store)
                } catch {
                    response = FlutterError(code: "write_failed", message: "\(error)", details: nil)
                }
            } else {
                response = FlutterError(code: "app_group_unavailable", message: nil, details: nil)
            }
            DispatchQueue.main.async { result(response) }
        }
    }

    private static let invalid = FlutterError(code: "invalid_arguments", message: nil, details: nil)
}
