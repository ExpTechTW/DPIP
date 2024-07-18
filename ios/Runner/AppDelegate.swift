import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import CoreLocation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate, MessagingDelegate {
    var locationManager: CLLocationManager!
    var lastSentLocation: CLLocation?
    var fcmToken: String?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController
        let locationChannel = FlutterMethodChannel(name: "com.exptech.dpip/location", binaryMessenger: controller.binaryMessenger)

        locationChannel.setMethodCallHandler { (call, result) in
            if call.method == "toggleLocation" {
                if let args = call.arguments as? [String: Any], let isEnabled = args["isEnabled"] as? Bool {
                    self.toggleLocation(isEnabled: isEnabled)
                    result("Location toggled")
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()

        Messaging.messaging().delegate = self

        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
            } else if let token = token {
                print("FCM token: \(token)")
                self.fcmToken = token
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func toggleLocation(isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: "locationSendingEnabled")
        if isEnabled {
            if CLLocationManager.locationServicesEnabled() {
                locationManager.startMonitoringSignificantLocationChanges()
            }
        } else {
            locationManager.stopMonitoringSignificantLocationChanges()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if shouldSendLocationUpdate(newLocation: location) {
            sendLocationToServer(location: location)
            lastSentLocation = location
        }
    }

    func shouldSendLocationUpdate(newLocation: CLLocation) -> Bool {
        guard let lastLocation = lastSentLocation else {
            return true
        }
        let distance = newLocation.distance(from: lastLocation)
        return distance > 100 && isSendingEnabled()
    }

    func isSendingEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "locationSendingEnabled")
    }

    func sendLocationToServer(location: CLLocation) {
        guard let token = fcmToken else {
            print("FCM token not available")
            return
        }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"

        let urlString = "https://api-1.exptech.dev/api/v1/notify/location/\(appVersion)/1/\(latitude),\(longitude)/\(token)"
        print(urlString)
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending location: \(error)")
                return
            }
            print("Location sent successfully")
        }

        task.resume()
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
        print("FCM token received: \(String(describing: fcmToken))")
    }
}

//// 設置開關狀態
//UserDefaults.standard.set(true, forKey: "locationSendingEnabled") // 開啟發送
//UserDefaults.standard.set(false, forKey: "locationSendingEnabled") // 關閉發送
//
//// 讀取開關狀態
//let isEnabled = UserDefaults.standard.bool(forKey: "locationSendingEnabled")
//print("Location sending is enabled: \(isEnabled)")
