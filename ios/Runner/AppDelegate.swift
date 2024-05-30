import UIKit
import Siren
import background_locator
import Flutter
import Firebase
import flutter_local_notifications

func registerPlugins(registry: FlutterPluginRegistry) -> () {
    if (!registry.hasPlugin("BackgroundLocatorPlugin")) {
        GeneratedPluginRegistrant.register(with: registry)
    } 
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        GeneratedPluginRegistrant.register(with: self)
        BackgroundLocatorPlugin.setPluginRegistrantCallback(registerPlugins)
        hyperCriticalRulesExample()
        Siren.shared.wail() // line 2
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)

        func registerOtherPlugins() {
            if !hasPlugin("io.flutter.plugins.pathprovider") {
                FLTPathProviderPlugin.register(with: registrar(forPlugin: "io.flutter.plugins.pathprovider"))
            }
        }
    }
        
    func hyperCriticalRulesExample() {
        let siren = Siren.shared
        siren.rulesManager = RulesManager(globalRules: .critical, showAlertAfterCurrentVersionHasBeenReleasedForDays: 3)
        siren.wail {results in
            switch results {
            case .success(let updateResults):
                print("AlerAction ", updateResults.alertAction)
                print("Localization ", updateResults.localization)
                print("Model ", updateResults.model)
                print("UPdateType ", updateResults.updateType)
            case.failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
