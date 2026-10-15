import Flutter
import UIKit
import UserNotifications

/// The link between iOS Settings → DPIP → Notifications and the app's own
/// notification settings page.
///
/// iOS draws a "DPIP Notification Settings" row there only for an app that
/// asked for `.providesAppNotificationSettings`, and tapping it calls the
/// notification-centre delegate's `openSettingsFor`. Both halves are here.
///
/// **Asking.** awesome_notifications builds its authorization options from a
/// fixed permission list that has no entry for this one, so the app adds it
/// itself — once the user has already said yes. Asking while the status is
/// `notDetermined` would show the system prompt outside the onboarding flow
/// that owns it, and asking without `.provisional` while provisional would
/// show the full prompt, so both are left alone. An authorized app asking
/// again is not prompted: iOS records the extra option and answers at once.
///
/// **Answering.** `NotificationDelegateProxy` receives `openSettingsFor` and
/// calls [request]. The request is a flag, not a navigation: on a cold launch
/// from Settings, iOS can call the delegate before Dart has a router, so the
/// flag waits until Dart takes it — either when nudged with `open`, or at
/// startup and on every resume. `take` reads and clears the flag in one step
/// on the main thread, so however those race, the page opens once.
public class NotificationSettingsLinkPlugin: NSObject, FlutterPlugin {
  /// Main thread only, like everything else here.
  private static var pending = false
  private static var channel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/notification_settings_link",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(NotificationSettingsLinkPlugin(), channel: channel)
    NotificationSettingsLinkPlugin.channel = channel
  }

  /// Records that iOS asked for the app's notification settings, and nudges
  /// Dart to come and take it.
  static func request() {
    DispatchQueue.main.async {
      pending = true
      // No handler yet is fine: the flag is what Dart reads at startup.
      channel?.invokeMethod("open", arguments: nil)
    }
  }

  /// Reads and clears the request flag.
  static func take() -> Bool {
    let was = pending
    pending = false
    return was
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "take":
      result(NotificationSettingsLinkPlugin.take())
    case "provide":
      NotificationSettingsLinkPlugin.provide { result($0) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Asks iOS for the Settings row, if the user has already allowed
  /// notifications and the row is not there yet. Completes on the main thread
  /// with whether the row is now provided.
  static func provide(completion: @escaping (Bool) -> Void) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      guard settings.authorizationStatus == .authorized else {
        DispatchQueue.main.async { completion(false) }
        return
      }
      if settings.providesAppNotificationSettings {
        DispatchQueue.main.async { completion(true) }
        return
      }
      // The options the app already holds, plus the one it lacks. Asking for
      // fewer would not revoke anything, but naming them keeps this request
      // the same shape as the one the user answered. Not `.criticalAlert`: if
      // that grant is still undecided, including it would prompt for it here.
      center.requestAuthorization(
        options: [.alert, .sound, .badge, .providesAppNotificationSettings]
      ) { granted, error in
        if let error {
          NSLog("notification settings link request failed: \(error.localizedDescription)")
        }
        DispatchQueue.main.async { completion(granted && error == nil) }
      }
    }
  }
}
