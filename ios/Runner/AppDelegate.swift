import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var locationManager: YourLocationManagerClass?

    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
      FirebaseApp.configure()
      GeneratedPluginRegistrant.register(with: self)

      locationManager = YourLocationManagerClass()
      locationManager?.startMonitoringSignificantLocationChanges()

      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
