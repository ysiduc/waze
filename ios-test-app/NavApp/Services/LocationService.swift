import Foundation
import CoreLocation
import Combine

public class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published public var currentLocation: LocationModel?
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var locationError: String?
    
    private let locationManager = CLLocationManager()
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5.0
        authorizationStatus = locationManager.authorizationStatus
    }
    
    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func startUpdating() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    public func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startUpdating()
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = LocationModel.fromCLLocation(location)
            self.locationError = nil
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }
    }
}
