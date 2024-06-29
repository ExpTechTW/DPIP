import UIKit
import CoreLocation
import Flutter
import Firebase

class YourLocationManagerClass: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    
    func requestLocationPermission() {
            locationManager = CLLocationManager()
        }
}

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
      locationManager?.requestLocationPermission()
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
