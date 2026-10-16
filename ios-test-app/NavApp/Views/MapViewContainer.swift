import SwiftUI
import MapKit

public struct MapViewContainer: UIViewRepresentable {
    @ObservedObject var sessionManager: NavigationSessionManager
    
    public init(sessionManager: NavigationSessionManager) {
        self.sessionManager = sessionManager
    }
    
    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.pointOfInterestFilter = .excludingAll
        
        // Initial camera
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(initialRegion, animated: false)
        return mapView
    }
    
    public func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update overlays
        let currentOverlays = mapView.overlays
        mapView.removeOverlays(currentOverlays)
        
        // Render alternate routes first (gray), then selected route (blue)
        for route in sessionManager.availableRoutes {
            guard route != sessionManager.selectedRoute else { continue }
            let polyline = MKPolyline(coordinates: route.polylineCoordinates, count: route.polylineCoordinates.count)
            polyline.title = "alternate"
            mapView.addOverlay(polyline)
        }
        
        if let primaryRoute = sessionManager.selectedRoute {
            let polyline = MKPolyline(coordinates: primaryRoute.polylineCoordinates, count: primaryRoute.polylineCoordinates.count)
            polyline.title = "primary"
            mapView.addOverlay(polyline)
            
            // Adjust camera if previewing
            if sessionManager.status == .previewingRoute && !context.coordinator.hasCenteredOnRoute {
                let rect = polyline.boundingMapRect
                mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 80, left: 40, bottom: 200, right: 40), animated: true)
                context.coordinator.hasCenteredOnRoute = true
            }
        } else {
            context.coordinator.hasCenteredOnRoute = false
        }
        
        // Center on user during active navigation if GPS available
        if sessionManager.status == .navigating, let userLoc = sessionManager.locationService.currentLocation {
            let camera = MKMapCamera(lookingAtCenter: userLoc.coordinate,
                                     fromDistance: 800,
                                     pitch: 45,
                                     heading: userLoc.course >= 0 ? userLoc.course : 0)
            mapView.setCamera(camera, animated: true)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewContainer
        var hasCenteredOnRoute: Bool = false
        
        init(_ parent: MapViewContainer) {
            self.parent = parent
        }
        
        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                if polyline.title == "primary" {
                    renderer.strokeColor = UIColor.systemBlue
                    renderer.lineWidth = 6.0
                } else {
                    renderer.strokeColor = UIColor.systemGray3
                    renderer.lineWidth = 4.0
                }
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
