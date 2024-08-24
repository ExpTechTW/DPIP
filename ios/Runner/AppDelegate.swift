import CoreLocation
import Firebase
import FirebaseMessaging
import Flutter
import UIKit

@UIApplicationMain
@objc
class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate,
    MessagingDelegate
{
    var locationManager: CLLocationManager!
    var lastSentLocation: CLLocation?
    var fcmToken: String?
    var locationChannel: FlutterMethodChannel?
    var methodChannel: FlutterMethodChannel?
    var isLocationEnabled: Bool = false
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController
        locationChannel = FlutterMethodChannel(
            name: "com.exptech.dpip/location",
            binaryMessenger: controller.binaryMessenger)

        locationChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            if call.method == "toggleLocation" {
                if let args = call.arguments as? [String: Any],
                    let isEnabled = args["isEnabled"] as? Bool
                {
                    self.toggleLocation(isEnabled: isEnabled)
                    result("Location toggled")
                } else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGUMENT",
                            message: "Invalid argument", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        methodChannel = FlutterMethodChannel(
            name: "com.exptech.dpip/data",
            binaryMessenger: controller.binaryMessenger)

        methodChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void
            in
            if call.method == "getSavedLocation" {
                self.handleGetSavedLocation(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false

        Messaging.messaging().delegate = self

        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
            } else if let token = token {
                print("FCM token: \(token)")
                self.fcmToken = token
            }
        }

        isLocationEnabled = UserDefaults.standard.bool(
            forKey: "locationSendingEnabled")

        if let locationKey = launchOptions?[
            UIApplication.LaunchOptionsKey.location] as? NSNumber,
            locationKey.boolValue
        {
            print("App launched due to location update")
            startLocationUpdates()
        } else {
            if isLocationEnabled {
                startLocationUpdates()
            }
        }

        return super.application(
            application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func handleGetSavedLocation(result: FlutterResult) {
        let latitude = UserDefaults.standard.double(forKey: "user-lat")
        let longitude = UserDefaults.standard.double(forKey: "user-lon")
        if latitude != 0 && longitude != 0 {
            result(["lat": latitude, "lon": longitude])
        } else {
            result(nil)
        }
    }

    func toggleLocation(isEnabled: Bool) {
        isLocationEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "locationSendingEnabled")
        startLocationUpdates()

        if isEnabled {
            if lastSentLocation == nil {
                if let currentLocation = locationManager.location {
                    sendLocationToServer(location: currentLocation)
                }
            }
        } else {
            stopLocationUpdates()
        }
    }

    func startLocationUpdates() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
            print("Started monitoring significant location changes")

            if let lastLocation = locationManager.location {
                updateRegionMonitoring(for: lastLocation)
            }
        } else {
            print("Significant location change monitoring is not available")
        }
    }

    func stopLocationUpdates() {
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingLocation()
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        print("Stopped all location updates")
    }

    func updateRegionMonitoring(for location: CLLocation) {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }

        let region = CLCircularRegion(
            center: location.coordinate, radius: 250,
            identifier: "currentRegion")
        region.notifyOnEntry = false
        region.notifyOnExit = true

        locationManager.startMonitoring(for: region)

        print(
            "Updated region monitoring for location: \(location.coordinate.latitude), \(location.coordinate.longitude)"
        )
    }

    func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        guard isLocationEnabled, let location = locations.last else { return }
        sendLocationToServer(location: location)
        lastSentLocation = location
    }

    func locationManager(
        _ manager: CLLocationManager, didExitRegion region: CLRegion
    ) {
        print("Exited region: \(region.identifier)")
        if let location = manager.location {
            sendLocationToServer(location: location)
        }
    }

    func sendLocationToServer(location: CLLocation) {
        guard isLocationEnabled else {
            print("Location services are disabled, skipping location update")
            return
        }

        guard let token = fcmToken else {
            print("FCM token not available")
            return
        }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let appVersion =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "Unknown"

        let deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let urlString = "https://api-1.exptech.dev/api/v1/notify/location/\(appVersion)/1/\(latitude),\(longitude)/\(token)/\(deviceIdentifier)"
        print(urlString)
        guard let url = URL(string: urlString) else { return }
        UserDefaults.standard.set(latitude, forKey: "user-lat")
        UserDefaults.standard.set(longitude, forKey: "user-lon")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) {
            [weak self] data, response, error in
            guard let self = self, self.isLocationEnabled else {
                print(
                    "Location services were disabled during the request, discarding result"
                )
                return
            }

            if let error = error {
                print("Error sending location: \(error)")
                return
            }
            print("Location sent successfully")

            DispatchQueue.main.async {
                self.updateRegionMonitoring(for: location)
            }
        }

        task.resume()
    }

    func messaging(
        _ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?
    ) {
        self.fcmToken = fcmToken
        print("FCM token received: \(String(describing: fcmToken))")
    }

    override func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        print("Handling background URL session events")
        completionHandler()
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        let backgroundTask = application.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }

        self.backgroundTask = backgroundTask

        DispatchQueue.global().async {
            self.performExtendedBackgroundTasks()
            self.endBackgroundTask()
        }
    }

    func performExtendedBackgroundTasks() {
        if let location = locationManager.location {
            sendLocationToServer(location: location)
        }
    }

    func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
