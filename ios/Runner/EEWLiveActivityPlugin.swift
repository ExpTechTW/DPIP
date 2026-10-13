import Flutter
import Foundation

/// Narrow Flutter bridge for manual, local mock controls.
public final class EEWLiveActivityPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.exptech.dpip/eew_live_activity",
            binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(EEWLiveActivityPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else {
            if call.method == "getStatus" {
                result(["supported": false, "enabled": false, "active": false,
                        "reportNo": NSNull(), "waveArrived": false])
            } else {
                result(FlutterError(code: "unavailable", message: "Requires iOS 16.1 or later.", details: nil))
            }
            return
        }

        Task { @MainActor in
            let manager = EEWLiveActivityManager.shared
            do {
                switch call.method {
                case "getStatus":
                    result(manager.status)
                case "mockStart":
                    try manager.start()
                    result(manager.status)
                #if DEBUG
                case "mockStartGeneric":
                    try manager.startGeneric()
                    result(manager.status)
                case "mockWaveArrivedWithAlert":
                    try await manager.markWaveArrivedWithAlert()
                    result(manager.status)
                case "mockScheduleDelayedArrivalAlert":
                    try manager.scheduleDelayedArrivalAlert()
                    result(manager.status)
                #endif
                case "mockUpdate":
                    guard let arguments = call.arguments as? [String: Any],
                          let reportNo = arguments["reportNo"] as? Int else {
                        result(FlutterError(code: "invalid_arguments", message: "reportNo is required.", details: nil))
                        return
                    }
                    try await manager.update(reportNo: reportNo)
                    result(manager.status)
                case "mockWaveArrived":
                    try await manager.markWaveArrived()
                    result(manager.status)
                case "mockEnd":
                    try await manager.end()
                    result(manager.status)
                default:
                    result(FlutterMethodNotImplemented)
                }
            } catch {
                result(FlutterError(
                    code: "activity_error",
                    message: error.localizedDescription,
                    details: nil))
            }
        }
    }
}
