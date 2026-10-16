import UIKit
import CoreLocation

/// Primary container view controller reconstructing Waze Main Screen Implementation.
/// Coordinates the vector map canvas, navigation guidance banner, search drawer, route preview, and speedometer.
public final class MainCanvasContainerViewController: UIViewController,
    WZWazeLocationServiceDelegate,
    NavigationGuidanceReducerBridgeProtocol,
    SearchDrawerDelegate,
    RoutePreviewViewDelegate {

    private let canvasHolder = MainCanvasViewHolder()
    private let locationBridge = WZWazeLocationServiceBridge.shared
    private let guidanceReducer = NavigationGuidanceReducerBridge()
    private let routingService = LocalSimulatedRoutingService.shared

    // Subviews
    private var canvasVC: UIViewController?
    private let searchPillButton = UIButton(type: .system)
    private let navigationBanner = NavigationBannerView()
    private let speedometer = SpeedometerView()
    private let routePreview = RoutePreviewView()
    private let centerLocationButton = UIButton(type: .system)
    private let stopNavButton = UIButton(type: .system)

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WazeTheme.canvasGrey

        setupCanvas()
        setupUI()
        setupBindings()
    }

    private func setupCanvas() {
        let vc = canvasHolder.createMetalViewController()
        addChild(vc)
        view.addSubview(vc.view)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.didMove(toParent: self)
        self.canvasVC = vc
    }

    private func setupUI() {
        // 1. Search Pill ("Where to?")
        searchPillButton.backgroundColor = .white
        searchPillButton.layer.cornerRadius = 24.0
        searchPillButton.layer.shadowColor = UIColor.black.cgColor
        searchPillButton.layer.shadowOpacity = 0.12
        searchPillButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        searchPillButton.layer.shadowRadius = 8.0
        searchPillButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchPillButton.setTitle(" Where to?", for: .normal)
        searchPillButton.setTitleColor(WazeTheme.textSecondary, for: .normal)
        searchPillButton.tintColor = WazeTheme.cyan
        searchPillButton.titleLabel?.font = WazeTheme.headlineFont(size: 16)
        searchPillButton.contentHorizontalAlignment = .left
        searchPillButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        searchPillButton.translatesAutoresizingMaskIntoConstraints = false
        searchPillButton.addTarget(self, action: #selector(handleOpenSearch), for: .touchUpInside)

        // 2. Navigation Banner (Hidden by default until route active)
        navigationBanner.translatesAutoresizingMaskIntoConstraints = false
        navigationBanner.isHidden = true

        // 3. Speedometer
        speedometer.translatesAutoresizingMaskIntoConstraints = false

        // 4. Route Preview Card (Hidden by default)
        routePreview.delegate = self
        routePreview.translatesAutoresizingMaskIntoConstraints = false
        routePreview.isHidden = true

        // 5. Center-on-location Button
        centerLocationButton.backgroundColor = .white
        centerLocationButton.layer.cornerRadius = 25.0
        centerLocationButton.layer.shadowColor = UIColor.black.cgColor
        centerLocationButton.layer.shadowOpacity = 0.12
        centerLocationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        centerLocationButton.layer.shadowRadius = 6.0
        centerLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        centerLocationButton.tintColor = WazeTheme.cyan
        centerLocationButton.translatesAutoresizingMaskIntoConstraints = false
        centerLocationButton.addTarget(self, action: #selector(handleCenterLocation), for: .touchUpInside)

        // 6. Stop Nav Button
        stopNavButton.backgroundColor = WazeTheme.alertRed
        stopNavButton.layer.cornerRadius = 25.0
        stopNavButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        stopNavButton.tintColor = .white
        stopNavButton.translatesAutoresizingMaskIntoConstraints = false
        stopNavButton.isHidden = true
        stopNavButton.addTarget(self, action: #selector(handleStopNavigation), for: .touchUpInside)

        view.addSubview(searchPillButton)
        view.addSubview(navigationBanner)
        view.addSubview(speedometer)
        view.addSubview(routePreview)
        view.addSubview(centerLocationButton)
        view.addSubview(stopNavButton)

        NSLayoutConstraint.activate([
            // Banner at top
            navigationBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            navigationBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            navigationBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            navigationBanner.heightAnchor.constraint(equalToConstant: 72),

            // Search pill at bottom
            searchPillButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            searchPillButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchPillButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchPillButton.heightAnchor.constraint(equalToConstant: 52),

            // Speedometer at bottom-left
            speedometer.bottomAnchor.constraint(equalTo: searchPillButton.topAnchor, constant: -16),
            speedometer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            // Center button at bottom-right
            centerLocationButton.bottomAnchor.constraint(equalTo: searchPillButton.topAnchor, constant: -16),
            centerLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            centerLocationButton.widthAnchor.constraint(equalToConstant: 50),
            centerLocationButton.heightAnchor.constraint(equalToConstant: 50),

            // Stop nav button
            stopNavButton.bottomAnchor.constraint(equalTo: centerLocationButton.topAnchor, constant: -12),
            stopNavButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stopNavButton.widthAnchor.constraint(equalToConstant: 50),
            stopNavButton.heightAnchor.constraint(equalToConstant: 50),

            // Route Preview at bottom
            routePreview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            routePreview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            routePreview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBindings() {
        locationBridge.delegate = self
        locationBridge.requestAuthorization()
        locationBridge.startUpdatingLocation()

        guidanceReducer.delegate = self
    }

    @objc private func handleOpenSearch() {
        let drawer = SearchDrawerViewController()
        drawer.delegate = self
        if let sheet = drawer.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(drawer, animated: true)
    }

    @objc private func handleCenterLocation() {
        if let loc = locationBridge.lastKnownTelemetry {
            canvasHolder.setCamera(center: WZCoordinate(latitude: loc.latitude, longitude: loc.longitude), zoom: 16.0)
        }
    }

    @objc private func handleStopNavigation() {
        guidanceReducer.reduce(event: .cancelNavigation)
        canvasHolder.clearRoute()
        navigationBanner.isHidden = true
        stopNavButton.isHidden = true
        searchPillButton.isHidden = false
    }

    // MARK: - SearchDrawerDelegate
    public func searchDrawer(_ drawer: SearchDrawerViewController, didSelectDestination destination: WZDestination) {
        let origin = locationBridge.lastKnownTelemetry.map {
            WZCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        } ?? WZCoordinate(latitude: 37.7749, longitude: -122.4194)

        routingService.calculateRoutes(from: origin, to: destination.coordinate) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let routes):
                if let primary = routes.first {
                    self.canvasHolder.setRoutePolyline(primary.polylineCoordinates)
                    self.routePreview.configure(with: primary)
                    self.routePreview.isHidden = false
                    self.searchPillButton.isHidden = true
                }
            case .failure(let error):
                let alert = UIAlertController(title: "Routing Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    // MARK: - RoutePreviewViewDelegate
    public func routePreviewViewDidTapStartNavigation(_ view: RoutePreviewView) {
        guard let route = view.currentRoute else { return }
        routePreview.isHidden = true
        navigationBanner.isHidden = false
        stopNavButton.isHidden = false

        guidanceReducer.reduce(event: .setRoute(route: route))
    }

    public func routePreviewViewDidTapClose(_ view: RoutePreviewView) {
        routePreview.isHidden = true
        searchPillButton.isHidden = false
        canvasHolder.clearRoute()
    }

    public func routePreviewViewDidSelectAlternative(_ view: RoutePreviewView, at index: Int) {}

    // MARK: - WZWazeLocationServiceDelegate
    public func locationServiceBridge(_ bridge: WZWazeLocationServiceBridge, didUpdateTelemetry telemetry: WSVLocationSpeed) {
        speedometer.updateSpeed(kmH: telemetry.speedKmPerHour)
        guidanceReducer.reduce(event: .locationUpdate(telemetry: telemetry))
    }

    public func locationServiceBridge(_ bridge: WZWazeLocationServiceBridge, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            bridge.startUpdatingLocation()
        }
    }

    // MARK: - NavigationGuidanceReducerBridgeProtocol
    public func guidanceReducer(_ bridge: NavigationGuidanceReducerBridge, didUpdateState state: WZNavigationState) {
        navigationBanner.update(
            maneuver: state.currentManeuver,
            distanceText: state.formattedDistanceToTurn,
            instruction: state.currentInstruction,
            street: state.currentStreetName
        )
    }
}
