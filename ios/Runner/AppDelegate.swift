import CoreLocation
import Flutter
import UIKit
import Intents
import Photos
import UserNotifications

@UIApplicationMain
@objc
class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    // MARK: - Properties

    private var locationChannel: FlutterMethodChannel?
    private var locationManager: CLLocationManager!
    private var lastSentLocation: CLLocation?
    private var isLocationEnabled: Bool = false
    private var apnsToken: String?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Application Lifecycle

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        setupFlutterChannels()
        setupLocationManager()
        
        if let locationKey = launchOptions?[
            UIApplication.LaunchOptionsKey.location] as? NSNumber,
            locationKey.boolValue
        {
            startLocationUpdates()
        } else if isLocationEnabled {
            startLocationUpdates()
        }

        return super.application(
            application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Quick Action
    override func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        handleShortcut(shortcutItem)
        completionHandler(true)
    }

    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) {
        UserDefaults.standard.set(shortcutItem.type, forKey: "initialShortcut")
        notifyFlutterShortcut(shortcutItem.type)
    }
    
    // MARK: - NSUserActivity
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == "com.exptech.dpip.monitor" ||
           userActivity.activityType == "OpenMonitorIntentIntent" {
            UserDefaults.standard.set("monitor", forKey: "initialShortcut")
            notifyFlutterShortcut("monitor")
        }
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
    
    private func notifyFlutterShortcut(_ value: String) {
        guard let controller =
            window?.rootViewController as? FlutterViewController
        else { return }

        let channel = FlutterMethodChannel(
            name: "com.exptech.dpip/shortcut",
            binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("onShortcut", arguments: value)
    }

    // MARK: - Background Handling
    override func applicationDidEnterBackground(_ application: UIApplication) {
        startBackgroundTask()
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
    }

    // MARK: - Setup Methods

    private func setupFlutterChannels() {
        guard let controller = window?.rootViewController as? FlutterViewController else { return }

        locationChannel = FlutterMethodChannel(
            name: "com.exptech.dpip/location",
            binaryMessenger: controller.binaryMessenger)

        locationChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handleLocationChannelCall(call, result: result)
        }

        let shortcutChannel = FlutterMethodChannel(
            name: "com.exptech.dpip/shortcut",
            binaryMessenger: controller.binaryMessenger
        )

        shortcutChannel.setMethodCallHandler { call, result in
            if call.method == "getInitialShortcut" {
                let shortcut = UserDefaults.standard.string(forKey: "initialShortcut")
                result(shortcut)
                UserDefaults.standard.removeObject(forKey: "initialShortcut")
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        let imageSaverChannel = FlutterMethodChannel(
            name: "image_saver",
            binaryMessenger: controller.binaryMessenger
        )

        imageSaverChannel.setMethodCallHandler { call, result in
            if call.method == "saveImage",
               let args = call.arguments as? [String: Any],
               let path = args["path"] as? String {

                if let image = UIImage(contentsOfFile: path) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    result(nil)
                } else {
                    result(FlutterError(
                        code: "INVALID_IMAGE",
                        message: "Cannot load image from path",
                        details: nil
                    ))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        isLocationEnabled = UserDefaults.standard.bool(
            forKey: "locationSendingEnabled")
    }
    
    // MARK: - APNS Token Handling
    
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        apnsToken = tokenString
        print("APNS token: \(tokenString)")
    }
    
    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Channel Handlers
    
    private func handleLocationChannelCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "toggleLocation",
              let args = call.arguments as? [String: Any],
              let isEnabled = args["isEnabled"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument", details: nil))
            return
        }

        toggleLocation(isEnabled: isEnabled)
        result("Location toggled")
    }
    
    // MARK: - Location Management
    
    private func toggleLocation(isEnabled: Bool) {
        isLocationEnabled = isEnabled
        UserDefaults.standard.set(isEnabled, forKey: "locationSendingEnabled")
        
        if isEnabled {
            startLocationUpdates()
            if lastSentLocation == nil, let currentLocation = locationManager.location {
                sendLocationToServer(location: currentLocation)
            }
        } else {
            stopLocationUpdates()
        }
    }
    
    private func startLocationUpdates() {
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            print("Significant location change monitoring is not available")
            return
        }
        
        locationManager.startMonitoringSignificantLocationChanges()
        
        if let lastLocation = locationManager.location {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.updateRegionMonitoring(for: lastLocation)
            }
        }
    }
    
    private func stopLocationUpdates() {
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingLocation()
        locationManager.monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
    }
    
    private func updateRegionMonitoring(for location: CLLocation) {
        locationManager.monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
        
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: 250,
            identifier: "currentRegion"
        )
        region.notifyOnEntry = false
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    // MARK: - Location Delegate Methods
    
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
        if let location = manager.location {
            sendLocationToServer(location: location)
        }
    }
    
    // MARK: - Network
    
    private func sendLocationToServer(location: CLLocation) {
        guard isLocationEnabled else { return }
        guard let token = apnsToken else { return }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let appVersion =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "Unknown"

        let urlString =
            "https://api-1.exptech.dev/api/v2/location/1/\(token)/\(appVersion)/\(latitude),\(longitude)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) {
            [weak self] data, response, error in
            guard let self = self, self.isLocationEnabled else { return }

            if let error = error {
                print("Error sending location: \(error)")
                return
            }

            DispatchQueue.main.async {
                self.updateRegionMonitoring(for: location)
            }
        }

        task.resume()
    }
    
    // MARK: - Background Task Management
    
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        DispatchQueue.global().async { [weak self] in
            self?.performExtendedBackgroundTasks()
            self?.endBackgroundTask()
        }
    }
    
    private func performExtendedBackgroundTasks() {
        if let location = locationManager.location {
            sendLocationToServer(location: location)
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // MARK: - URL Session Handling
    
    override func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
