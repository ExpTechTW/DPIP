import UIKit
import CoreLocation
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?

    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launch options: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
      FirebaseApp.configure()
      GeneratedPluginRegistrant.register(with: self)

      locationManager = CLLocationManager()
      locationManager?.delegate = self
      locationManager?.desiredAccuracy = kCLLocationAccuracyBest
      locationManager?.requestAlwaysAuthorization()

      if CLLocationManager.locationServicesEnabled() {
          locationManager?.startUpdatingLocation()
      }

      return super.application(application, didFinishLaunchingWithOptions: launch options)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("獲得新位置：緯度 \(location.coordinate.latitude), 經度 \(location.coordinate.longitude)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置更新失敗：\(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager?.startUpdatingLocation()
        default:
            print("位置權限被拒絕或未開啟")
        }
    }
}
