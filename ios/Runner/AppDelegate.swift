import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Claim the notification-center delegate BEFORE awesome_notifications'
    // own didFinishLaunching observer does. awesome captures whoever is set
    // at that point as its "original delegate" and only forwards to it when
    // its own status-bar presenter declines — which is exactly the cold-start
    // window where that presenter is not ready yet and pushes were swallowed
    // whole (completionHandler([]) with nobody left to ask). Presenting here
    // plays the aps sound exactly once; when the presenter succeeds instead,
    // this is never called.
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Presents pushes awesome's own status-bar presenter declined — the cold-
  /// start window before that presenter is ready. Banner plus the payload's
  /// own sound, played once by the system.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
      -> Void
  ) {
    completionHandler([.list, .banner, .sound])
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
  }
}
