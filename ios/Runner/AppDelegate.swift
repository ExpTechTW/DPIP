import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
  }
}
