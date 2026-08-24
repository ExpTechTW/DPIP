import Flutter
import UIKit

/// The device's APNs token, taken from the place iOS actually hands it over.
///
/// The backend keys every iOS registration on the raw APNs device token — not
/// Firebase's FCM registration token, which is a different string it does not
/// recognise (measured: the write 202s and every later lookup 401s, so the
/// mistake is silent). That token has exactly one source,
/// `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`; every
/// SDK that offers to "get" it is reading back what it captured from the same
/// callback. Reading it here removes the middleman, and with it the whole
/// firebase_messaging dependency that existed for this one value.
///
/// Registration itself is not ours to trigger: `awesome_notifications` calls
/// `registerForRemoteNotifications()` once permission is granted. This only
/// listens.
public class ApnsTokenPlugin: NSObject, FlutterPlugin {
  /// Set on the main thread by the delegate callback, read by the channel.
  ///
  /// Static because the token arrives whenever iOS decides — often before Dart
  /// asks, sometimes long after — and the instance answering the channel may
  /// not be the one that was registered when it landed.
  private static var token: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/apns_token",
      binaryMessenger: registrar.messenger())
    let plugin = ApnsTokenPlugin()
    registrar.addMethodCallDelegate(plugin, channel: channel)
    registrar.addApplicationDelegate(plugin)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "token":
      // Null until iOS has registered. Dart treats that as "not yet", not as
      // failure: on a cold launch the callback usually lands a second or two
      // after the engine starts.
      result(ApnsTokenPlugin.token)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Lowercase hex, no separators — the form APNs itself uses and the one the
    // backend already has on file for existing devices.
    ApnsTokenPlugin.token = deviceToken.map { String(format: "%02x", $0) }.joined()
  }

  public func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    // Left visible rather than swallowed: without a token this device can be
    // registered by the backend but never addressed, and nothing else in the
    // app would say so.
    NSLog("APNs registration failed: \(error.localizedDescription)")
  }
}
