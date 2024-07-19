import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import CoreLocation
import BackgroundTasks

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate, MessagingDelegate {
    var locationManager: CLLocationManager!
    var lastSentLocation: CLLocation?
    var fcmToken: String?
    var locationChannel: FlutterMethodChannel?
    var isLocationEnabled: Bool = false

    let backgroundTaskIdentifier = "com.exptech.dpip.locationUpdate"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController
        locationChannel = FlutterMethodChannel(name: "com.exptech.dpip/location", binaryMessenger: controller.binaryMessenger)

        locationChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
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

        isLocationEnabled = UserDefaults.standard.bool(forKey: "locationSendingEnabled")
        updateLocationService()

        registerBackgroundTask()

        if let locationKey = launchOptions?[UIApplication.LaunchOptionsKey.location] as? NSNumber,
           locationKey.boolValue {
            print("App launched due to location update")
            startLocationUpdates()
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func toggleLocation(isEnabled: Bool) {
        isLocationEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "locationSendingEnabled")
        updateLocationService()

        if isEnabled && lastSentLocation == nil {
            if let currentLocation = locationManager.location {
                sendLocationToServer(location: currentLocation)
            }
        }
    }

    func updateLocationService() {
        if isLocationEnabled {
            requestLocationAuthorization()
        } else {
            stopLocationUpdates()
        }
    }

    func requestLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            if #available(iOS 14.0, *) {
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    locationManager.requestAlwaysAuthorization()
                case .authorizedWhenInUse, .authorizedAlways:
                    startLocationUpdates()
                case .restricted, .denied:
                    print("Location services are not authorized")
                @unknown default:
                    break
                }
            } else {
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined:
                    locationManager.requestAlwaysAuthorization()
                case .authorizedWhenInUse, .authorizedAlways:
                    startLocationUpdates()
                case .restricted, .denied:
                    print("Location services are not authorized")
                @unknown default:
                    break
                }
            }
        } else {
            print("Location services are not enabled")
        }
    }

    func startLocationUpdates() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
            print("Started monitoring significant location changes")

            scheduleBackgroundLocationTask()
        } else {
            print("Significant location change monitoring is not available")
        }
    }

    func stopLocationUpdates() {
        locationManager.stopMonitoringSignificantLocationChanges()
        print("Stopped monitoring significant location changes")

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isLocationEnabled, let location = locations.last else { return }
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
        return distance > 100
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
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"

        let urlString = "https://api-1.exptech.dev/api/v1/notify/location/\(appVersion)/1/\(latitude),\(longitude)/\(token)"
        print(urlString)
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, self.isLocationEnabled else {
                print("Location services were disabled during the request, discarding result")
                return
            }

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

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundLocationTask(task: task as! BGProcessingTask)
        }
    }

    func scheduleBackgroundLocationTask() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background location task scheduled")
        } catch {
            print("Could not schedule background location task: \(error)")
        }
    }

    func handleBackgroundLocationTask(task: BGProcessingTask) {
        scheduleBackgroundLocationTask() // Schedule the next task

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = BlockOperation {
            if let location = self.locationManager.location {
                if self.shouldSendLocationUpdate(newLocation: location) {
                    self.sendLocationToServer(location: location)
                    self.lastSentLocation = location
                } else {
                    print("Location update not needed based on distance threshold")
                }
            } else {
                print("No location available for background task")
            }
        }

        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        queue.addOperation(operation)
    }
}
