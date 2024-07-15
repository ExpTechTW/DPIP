import UIKit
import CoreLocation
import Flutter
import Firebase

class YourLocationManagerClass: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?

    override init() {
        super.init()
    }

    func startMonitoringSignificantLocationChanges() {
        locationManager?.startMonitoringSignificantLocationChanges()
    }
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
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
