import Foundation
import CoreLocation
import MapKit
import Combine

public class NavigationSessionManager: ObservableObject {
    @Published public var status: NavigationStatus = .idle
    @Published public var availableRoutes: [RouteModel] = []
    @Published public var selectedRoute: RouteModel?
    @Published public var destination: SearchResult?
    @Published public var currentStepIndex: Int = 0
    @Published public var currentStep: GuidanceStep?
    @Published public var metrics: NavigationMetrics = NavigationMetrics()
    @Published public var isDemoMode: Bool = false
    @Published public var demoProgress: Double = 0.0
    @Published public var errorMessage: String?
    
    public let locationService: LocationService
    public let routingService: RoutingService
    public let searchService: SearchService
    
    private var cancellables = Set<AnyCancellable>()
    private var demoTimer: Timer?
    
    public init(locationService: LocationService = LocationService(),
                routingService: RoutingService = RoutingService(),
                searchService: SearchService = SearchService()) {
        self.locationService = locationService
        self.routingService = routingService
        self.searchService = searchService
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self = self else { return }
                if !self.isDemoMode && self.status == .navigating {
                    self.processLocationUpdate(location)
                }
            }
            .store(in: &cancellables)
    }
    
    public func selectDestination(_ destination: SearchResult) {
        self.destination = destination
        self.status = .searching
        self.errorMessage = nil
        
        guard let userLoc = locationService.currentLocation?.coordinate else {
            // Default reference coordinate (San Francisco default fallback for Simulator)
            let fallbackSource = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            calculateRoutes(from: fallbackSource, to: destination.coordinate)
            return
        }
        calculateRoutes(from: userLoc, to: destination.coordinate)
    }
    
    public func calculateRoutes(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        routingService.calculateRoutes(from: source, to: destination) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let routes):
                    self.availableRoutes = routes
                    self.selectedRoute = routes.first
                    self.status = .previewingRoute
                    if let primary = routes.first {
                        self.updateMetricsForRoute(primary)
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to calculate route: \(error.localizedDescription)"
                    self.status = .idle
                }
            }
        }
    }
    
    public func selectRoute(_ route: RouteModel) {
        self.selectedRoute = route
        updateMetricsForRoute(route)
    }
    
    public func startNavigation() {
        guard let route = selectedRoute else { return }
        self.status = .navigating
        self.currentStepIndex = 0
        self.currentStep = route.steps.first
        self.updateMetricsForRoute(route)
        
        if isDemoMode {
            startDemoSimulation()
        }
    }
    
    public func stopNavigation() {
        stopDemoSimulation()
        self.status = .idle
        self.selectedRoute = nil
        self.availableRoutes = []
        self.destination = nil
        self.currentStep = nil
        self.currentStepIndex = 0
        self.metrics = NavigationMetrics()
        self.demoProgress = 0.0
    }
    
    public func updateMetricsForRoute(_ route: RouteModel) {
        let eta = Date().addingTimeInterval(route.totalExpectedTimeSeconds)
        self.metrics = NavigationMetrics(
            remainingDistanceMeters: route.totalDistanceMeters,
            remainingTimeSeconds: route.totalExpectedTimeSeconds,
            estimatedArrivalTime: eta,
            currentSpeedKph: locationService.currentLocation?.speedKph ?? 0
        )
    }
    
    public func processLocationUpdate(_ location: LocationModel) {
        guard let route = selectedRoute, currentStepIndex < route.steps.count else { return }
        
        let targetStep = route.steps[currentStepIndex]
        let userCoord = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let stepCoord = CLLocation(latitude: targetStep.coordinate.latitude, longitude: targetStep.coordinate.longitude)
        let distanceToStep = userCoord.distance(from: stepCoord)
        
        // Step progression check: within 30 meters of step junction
        if distanceToStep < 30.0 && currentStepIndex + 1 < route.steps.count {
            currentStepIndex += 1
            currentStep = route.steps[currentStepIndex]
        } else if distanceToStep < 30.0 && currentStepIndex + 1 >= route.steps.count {
            self.status = .arrived
            return
        }
        
        // Update live metrics
        var remainingDist = distanceToStep
        for i in (currentStepIndex + 1)..<route.steps.count {
            remainingDist += route.steps[i].distanceMeters
        }
        
        let estSeconds = (remainingDist / max(5.0, location.speedMps))
        self.metrics = NavigationMetrics(
            remainingDistanceMeters: remainingDist,
            remainingTimeSeconds: estSeconds,
            estimatedArrivalTime: Date().addingTimeInterval(estSeconds),
            currentSpeedKph: location.speedKph
        )
    }
    
    // MARK: - Simulation / Demo Mode for Testing & Simulator
    public func toggleDemoMode() {
        self.isDemoMode.toggle()
        if !isDemoMode {
            stopDemoSimulation()
        } else if status == .navigating {
            startDemoSimulation()
        }
    }
    
    private func startDemoSimulation() {
        demoTimer?.invalidate()
        demoProgress = 0.0
        
        demoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let route = self.selectedRoute, !route.steps.isEmpty else { return }
            
            self.demoProgress += 0.05
            if self.demoProgress >= 1.0 {
                self.status = .arrived
                self.stopDemoSimulation()
                return
            }
            
            let totalSteps = Double(route.steps.count)
            let rawIndex = Int(self.demoProgress * totalSteps)
            let newIndex = min(route.steps.count - 1, rawIndex)
            
            if newIndex != self.currentStepIndex {
                self.currentStepIndex = newIndex
                self.currentStep = route.steps[newIndex]
            }
            
            let remDistance = route.totalDistanceMeters * (1.0 - self.demoProgress)
            let remTime = route.totalExpectedTimeSeconds * (1.0 - self.demoProgress)
            
            self.metrics = NavigationMetrics(
                remainingDistanceMeters: remDistance,
                remainingTimeSeconds: remTime,
                estimatedArrivalTime: Date().addingTimeInterval(remTime),
                currentSpeedKph: 55.0 // Simulated speed
            )
        }
    }
    
    private func stopDemoSimulation() {
        demoTimer?.invalidate()
        demoTimer = nil
    }
}
