import ActivityKit
import Flutter

/// EventChannel plugin handing Dart the Live Activity push-to-start token and
/// the system's Live Activities switch, so `LiveActivityRegistration` can report
/// them to the notify backend.
///
/// Each event is `{"token": <lowercase hex or null>, "enabled": <bool>}`: one on
/// listen with the current values, and one more whenever either changes. The
/// token belongs to `EEWActivityAttributes` — a push-to-start token is issued
/// per attributes type, which is why that type's name can no longer change once
/// tokens have been collected for it.
///
/// iOS 18 and later only; earlier systems get no events at all, so Dart never
/// reports. A remotely started activity is updated and ended over a broadcast
/// channel (`input-push-channel`), which needs iOS 18 — on iOS 17 it could be
/// started and then never touched again.
///
/// `pushToStartToken` can be nil on the first read and arrive a moment later
/// through `pushToStartTokenUpdates`, and the update sequence does not replay a
/// token issued before it was observed — both are read here for that reason.
public class LiveActivityTokenPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var tasks: [Task<Void, Never>] = []
  private var token: String?
  private var enabled = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterEventChannel(
      name: "com.exptech.dpip/live_activity_token",
      binaryMessenger: registrar.messenger())
    channel.setStreamHandler(LiveActivityTokenPlugin())
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard #available(iOS 18.0, *) else { return nil }
    sink = events
    let authorization = ActivityAuthorizationInfo()
    token = Activity<EEWActivityAttributes>.pushToStartToken.map(LiveActivityTokenPlugin.hex)
    enabled = authorization.areActivitiesEnabled
    emit()
    // Both sequences run until cancelled; the event sink must be called on the
    // main thread, hence the main actor.
    tasks.append(
      Task { @MainActor [weak self] in
        for await data in Activity<EEWActivityAttributes>.pushToStartTokenUpdates {
          self?.token = LiveActivityTokenPlugin.hex(data)
          self?.emit()
        }
      })
    tasks.append(
      Task { @MainActor [weak self] in
        for await on in authorization.activityEnablementUpdates {
          self?.enabled = on
          self?.emit()
        }
      })
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    tasks.forEach { $0.cancel() }
    tasks = []
    sink = nil
    return nil
  }

  private func emit() {
    let value: Any
    if let token { value = token } else { value = NSNull() }
    sink?(["token": value, "enabled": enabled])
  }

  /// Lowercase hex, no separators — the form APNs and the backend use.
  static func hex(_ data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
  }
}
