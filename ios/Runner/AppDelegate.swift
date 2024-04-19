import UIKit
import Siren
import Flutter
import Firebase
import flutter_local_notifications

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
        minimalCustomizationPresentationExample()
        // hyperCriticalRulesExample()
        Siren.shared.wail() // line 2
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func minimalCustomizationPresentationExample() {
        let siren = Siren.shared
        siren.rulesManager = RulesManager(globalRules: .critical)
        siren.presentationManager = PresentationManager(alertTintColor: .purple, appName: "DPIP")
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
        
        func hyperCriticalRulesExample() {
            let siren = Siren.shared
            siren.rulesManager = RulesManager(globalRules: .critical, showAlertAfterCurrentVersionHasBeenReleasedForDays: 1)
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
}
