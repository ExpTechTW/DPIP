import Firebase
import FirebaseMessaging

class FirebaseService {
    static func fetchToken(completion: @escaping (String?) -> Void) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
                completion(nil)
            } else {
                completion(token)
            }
        }
    }

    static func fetchVersion() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}