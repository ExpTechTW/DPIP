import UIKit
import Siren
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
      FirebaseApp.configure()
      GeneratedPluginRegistrant.register(with: self)
        hyperCriticalRulesExample()
        Siren.shared.wail()
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
