import Firebase
import FirebaseMessaging

class FirebaseService {
    static let shared = FirebaseService()

    private init() {
        FirebaseApp.configure()
    }

    func fetchToken(completion: @escaping (String?) -> Void) {
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { token, error in
            if let error = error {
                print("Error fetching token: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(token)
        }
    }

    func fetchVersion() -> String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "Unknown"
        }
        return version
    }
}
