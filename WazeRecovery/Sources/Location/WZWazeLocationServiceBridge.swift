import Foundation
import CoreLocation

public protocol WZWazeLocationServiceDelegate: AnyObject {
    func locationServiceBridge(_ bridge: WZWazeLocationServiceBridge, didUpdateTelemetry telemetry: WSVLocationSpeed)
    func locationServiceBridge(_ bridge: WZWazeLocationServiceBridge, didChangeAuthorization status: CLAuthorizationStatus)
}

/// Reconstructed from WZWazeLocationServiceBridge (0x107f19690) in Waze ARM64 executable.
/// Bridges iOS CoreLocation framework sensor updates to Waze internal telemetry models.
public final class WZWazeLocationServiceBridge: NSObject, CLLocationManagerDelegate {
    public static let shared = WZWazeLocationServiceBridge()

    public weak var delegate: WZWazeLocationServiceDelegate?

    private let locationManager = CLLocationManager()
    private(set) public var lastKnownTelemetry: WSVLocationSpeed?
    private(set) public var isUpdatingLocation: Bool = false

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 1.0 // 1 meter update filter for driving
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    /// Requests When-In-Use or Always authorization.
    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Starts streaming GPS location telemetry.
    public func startUpdatingLocation() {
        guard !isUpdatingLocation else { return }
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    /// Stops streaming GPS telemetry.
    public func stopUpdatingLocation() {
        guard isUpdatingLocation else { return }
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }

        // Method 0x1000a1d28 in Waze binary: extract coordinates and construct telemetry transfer object
        let telemetry = WSVLocationSpeed(clLocation: latest)
        self.lastKnownTelemetry = telemetry
        delegate?.locationServiceBridge(self, didUpdateTelemetry: telemetry)
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        delegate?.locationServiceBridge(self, didChangeAuthorization: manager.authorizationStatus)
    }
}
