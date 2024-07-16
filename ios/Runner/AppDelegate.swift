import UIKit
import Flutter
import Firebase
import CoreLocation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, URLSessionDelegate {
    var locationManager: YourLocationManagerClass?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        locationManager = YourLocationManagerClass.shared
        locationManager?.startMonitoringSignificantLocationChanges()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        super.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)

        let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: identifier)
        let backgroundSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil)
        // Store the completion handler for later use
//        YourLocationManagerClass.shared.setBackgroundCompletionHandler(completionHandler)
    }
}
