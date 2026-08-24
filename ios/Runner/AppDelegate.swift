import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // Re-assert: firebase_messaging's proxy can claim the delegate again from
    // its own launch observer, and whoever is last wins.
    NotificationDelegateProxy.shared.install()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let registry = engineBridge.pluginRegistry
    // Firebase and other pub plugins.
    GeneratedPluginRegistrant.register(with: registry)

    // App-owned native channels. Registered as real FlutterPlugins through the
    // same registry so their handlers are retained under the implicit-engine
    // lifecycle (registering a bare channel here can silently stop firing).
    DeviceInfoPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlugin")!)
    CompassPlugin.register(with: registry.registrar(forPlugin: "CompassPlugin")!)
    MapSnapshotPlugin.register(with: registry.registrar(forPlugin: "MapSnapshotPlugin")!)
    MapCachePlugin.register(with: registry.registrar(forPlugin: "MapCachePlugin")!)
    StorageScanPlugin.register(with: registry.registrar(forPlugin: "StorageScanPlugin")!)
    ScreenWakePlugin.register(with: registry.registrar(forPlugin: "ScreenWakePlugin")!)
    BackgroundLocationPlugin.register(
      with: registry.registrar(forPlugin: "BackgroundLocationPlugin")!)
    BackgroundExecutionPlugin.register(
      with: registry.registrar(forPlugin: "BackgroundExecutionPlugin")!)

    // Re-post the launch notification the plugins just missed.
    //
    // This callback is *deferred* registration — Flutter's own header calls it
    // that. Under the UISceneDelegate lifecycle the implicit engine is built
    // lazily, so plugins are registered here, well after UIKit has already
    // posted `UIApplication.didFinishLaunchingNotification`. A plugin that
    // waits for that notification instead of implementing
    // `application:didFinishLaunchingWithOptions:` therefore never hears it.
    //
    // awesome_notifications is one: it observes the notification
    // (AwesomeNotifications.swift:156) and only inside the handler does it set
    // `UNUserNotificationCenter.current().delegate = self` (:508). Miss it and
    // the app runs with **no notification-centre delegate at all** — which iOS
    // reads as "never present a notification while the app is in the
    // foreground". Background delivery is unaffected because it needs no
    // delegate, which is exactly the shape of the bug: pushes arrived normally
    // with the app closed and vanished with it open.
    //
    // Posting it again is narrow by construction: the only observers that can
    // be here are ones registered moments ago in this very method, and they
    // have not seen it once.
    NotificationDelegateProxy.shared.install()
  }
}

/// Answers iOS for pushes that no plugin will answer for.
///
/// The app's pushes are published straight to APNs by AWS SNS — no FCM, no
/// `mutable-content`, no Notification Service Extension. awesome_notifications
/// cannot render such a push: its own README requires all three. That is why
/// they arrive correctly in the background — awesome is bypassed entirely and
/// iOS presents `aps` itself — and vanish in the foreground, where Apple hands
/// the decision to whatever holds the notification-centre delegate.
///
/// awesome holds it, and for these pushes it answers nothing at all: its
/// `willPresent` calls `showNotificationOnStatusBar`, which throws when the
/// channel is not in its native registry, and the surrounding `catch`
/// (AwesomeNotifications.swift:666) never calls the completion handler.
/// `StatusBarManager.swift:118` has the same shape — a bare `return` past the
/// handler. Apple's contract has no timeout for that: "if the handler is not
/// called in a timely manner then the notification will not be presented".
/// No banner, no sound, no log.
///
/// This proxy sits in front and restores the documented default for exactly
/// those pushes — the same presentation the background already gets — while
/// forwarding everything else, taps included, to awesome untouched.
final class NotificationDelegateProxy: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationDelegateProxy()

  /// The delegate awesome installed, kept so its own notifications still work.
  ///
  /// Strongly held on purpose: `UNUserNotificationCenter.delegate` is `weak`,
  /// so a proxy nobody retains would be released the moment `install()`
  /// returns — leaving the delegate nil and the bug apparently "fixed" for the
  /// wrong reason.
  private var wrapped: UNUserNotificationCenterDelegate?

  /// Takes the delegate, remembering whoever had it.
  ///
  /// Idempotent, and safe to call repeatedly: installing over ourselves would
  /// otherwise make `wrapped` point at this proxy and every forward recurse.
  func install() {
    let center = UNUserNotificationCenter.current()
    if center.delegate === self { return }
    wrapped = center.delegate
    center.delegate = self
  }

  /// Whether this notification is one the server sent straight to APNs.
  ///
  /// FCM stamps every message it delivers with `gcm.message_id`; ours has none
  /// and carries the `content` object the backend sends instead. Anything else
  /// — including notifications awesome created locally — is not ours to answer.
  private func isServerPush(_ notification: UNNotification) -> Bool {
    let info = notification.request.content.userInfo
    return info["gcm.message_id"] == nil && info["content"] != nil
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if isServerPush(notification) {
      #if DEBUG
        // stderr, not NSLog: `flutter run` on a device relays only the former.
        fputs("DPIP-NOTIF [proxy] presenting server push\n", stderr)
        fflush(stderr)
      #endif
      completionHandler([.banner, .list, .badge, .sound])
      return
    }
    guard
      let wrapped,
      wrapped.responds(
        to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)))
    else {
      completionHandler([.banner, .list, .badge, .sound])
      return
    }
    wrapped.userNotificationCenter?(
      center, willPresent: notification, withCompletionHandler: completionHandler)
  }

  /// Taps are never ours. awesome owns action routing and `getInitialAction`,
  /// and intercepting here would break deep links from a notification.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    guard
      let wrapped,
      wrapped.responds(
        to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)))
    else {
      completionHandler()
      return
    }
    wrapped.userNotificationCenter?(
      center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
