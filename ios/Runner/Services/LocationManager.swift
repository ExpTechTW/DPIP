import UIKit
import CoreLocation

class YourLocationManagerClass: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    var lastLocation: CLLocation?
    var lastRequestTime: Date?

    override init() {
        super.init()
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
        let minInterval = 300.0 // seconds

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
        FirebaseService.fetchToken { token in
            guard let token = token, let version = FirebaseService.fetchVersion() else {
                print("Error: Token or Version is unavailable")
                return
            }

            let platform = 1 // iOS
            let urlString = "https://api-1.exptech.dev/v1/notify/location/\(version)/\(platform)/\(latitude),\(longitude)/\(token)"
            guard let url = URL(string: urlString) else {
                print("Error: URL is not valid")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("HTTP Request Failed \(error?.localizedDescription ?? "")")
                    return
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }.resume()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
