import UIKit
import CoreLocation
import Firebase

// MARK: - YourLocationManagerClass

class YourLocationManagerClass: NSObject, CLLocationManagerDelegate {
    static let shared = YourLocationManagerClass()

    private var locationManager: CLLocationManager?
    private var lastLocation: CLLocation?
    private var lastRequestTime: Date?

    private override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
    }

    func startMonitoringSignificantLocationChanges() {
        locationManager?.startMonitoringSignificantLocationChanges()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        let now = Date()
        let minInterval = 30.0 // 5 minutes

        if let lastLoc = lastLocation, let lastTime = lastRequestTime {
            let distance = newLocation.distance(from: lastLoc)
            if distance > 250 && now.timeIntervalSince(lastTime) >= minInterval {
                updateLocation(newLocation)
            }
        } else {
            updateLocation(newLocation)
        }
    }

    private func updateLocation(_ location: CLLocation) {
        lastLocation = location
        lastRequestTime = Date()
        sendLocationToServer(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    private func sendLocationToServer(latitude: Double, longitude: Double) {
        FirebaseService.shared.fetchToken { token in
            guard let token = token else {
                print("Error: Token is unavailable")
                return
            }

            let version = FirebaseService.shared.fetchVersion()
            let platform = 1 // iOS
            let urlString = "https://api-1.exptech.dev/v1/notify/location/\(version)/\(platform)/\(latitude),\(longitude)/\(token)"
            guard let url = URL(string: urlString) else {
                print("Error: URL is not valid")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("HTTP Request Failed: \(error.localizedDescription)")
                    return
                }
                guard let data = data else {
                    print("No data received")
                    return
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
            task.resume()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}