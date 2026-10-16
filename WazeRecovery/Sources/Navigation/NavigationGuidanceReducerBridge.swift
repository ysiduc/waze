import Foundation

public enum WZGuidanceEvent {
    case locationUpdate(telemetry: WSVLocationSpeed)
    case setRoute(route: WZRoute)
    case turnApproaching(distanceMeters: Double)
    case stepAdvanced(newStepIndex: Int)
    case offRouteDetected
    case destinationArrived
    case cancelNavigation
}

public protocol NavigationGuidanceReducerBridgeProtocol: AnyObject {
    func guidanceReducer(_ bridge: NavigationGuidanceReducerBridge, didUpdateState state: WZNavigationState)
}

/// Reconstructed from NavigationGuidanceReducerBridge (0x107f1ab08) in Waze ARM64 executable.
/// Implements unidirectional event reduction mapping telemetry and route events into navigation state snapshots.
public final class NavigationGuidanceReducerBridge {
    public weak var delegate: NavigationGuidanceReducerBridgeProtocol?

    private(set) public var currentState: WZNavigationState

    public init(initialState: WZNavigationState = WZNavigationState()) {
        self.currentState = initialState
    }

    /// Disassembled method reduceGuidanceEvent: (0x100102264)
    /// Pure state transition function yielding updated immutable navigation state snapshot.
    public func reduce(event: WZGuidanceEvent) {
        var state = currentState

        switch event {
        case .setRoute(let route):
            state.status = .navigating
            state.activeRoute = route
            state.currentStepIndex = 0
            state.remainingDistanceMeters = route.totalDistanceMeters
            state.remainingDurationSeconds = route.totalDurationSeconds
            if let firstStep = route.steps.first {
                state.currentManeuver = firstStep.maneuver
                state.currentInstruction = firstStep.instruction
                state.currentStreetName = firstStep.streetName
                state.distanceToTurnMeters = firstStep.distanceMeters
                state.isApproachingTurn = firstStep.distanceMeters < 150.0
            }

        case .locationUpdate(let telemetry):
            state.currentSpeedKmH = telemetry.speedKmPerHour

            guard state.status == .navigating, let route = state.activeRoute else { break }

            if state.currentStepIndex < route.steps.count {
                let currentStep = route.steps[state.currentStepIndex]
                let distToTurn = haversineDistance(
                    from: WZCoordinate(latitude: telemetry.latitude, longitude: telemetry.longitude),
                    to: currentStep.coordinate
                )

                state.distanceToTurnMeters = distToTurn
                // Approaching turn threshold: <= 150 meters in city, <= 500 meters on highway
                state.isApproachingTurn = distToTurn <= (telemetry.speedKmPerHour > 80.0 ? 500.0 : 150.0)

                // Advance step if within 20 meters of maneuver point
                if distToTurn < 20.0 && state.currentStepIndex + 1 < route.steps.count {
                    state.currentStepIndex += 1
                    let nextStep = route.steps[state.currentStepIndex]
                    state.currentManeuver = nextStep.maneuver
                    state.currentInstruction = nextStep.instruction
                    state.currentStreetName = nextStep.streetName
                    state.distanceToTurnMeters = nextStep.distanceMeters
                    state.isApproachingTurn = false
                }
            }

        case .turnApproaching(let distanceMeters):
            state.distanceToTurnMeters = distanceMeters
            state.isApproachingTurn = true

        case .stepAdvanced(let newStepIndex):
            guard let route = state.activeRoute, newStepIndex < route.steps.count else { break }
            state.currentStepIndex = newStepIndex
            let step = route.steps[newStepIndex]
            state.currentManeuver = step.maneuver
            state.currentInstruction = step.instruction
            state.currentStreetName = step.streetName
            state.distanceToTurnMeters = step.distanceMeters
            state.isApproachingTurn = false

        case .offRouteDetected:
            state.status = .rerouting
            state.currentInstruction = "Recalculating route..."
            state.isApproachingTurn = false

        case .destinationArrived:
            state.status = .arrived
            state.currentManeuver = .arrive
            state.currentInstruction = "You have arrived at your destination"
            state.distanceToTurnMeters = 0.0
            state.isApproachingTurn = false
            state.remainingDistanceMeters = 0.0
            state.remainingDurationSeconds = 0.0

        case .cancelNavigation:
            state.status = .idle
            state.activeRoute = nil
            state.currentStepIndex = 0
            state.distanceToTurnMeters = 0.0
            state.isApproachingTurn = false
            state.currentInstruction = ""
            state.currentStreetName = ""
        }

        self.currentState = state
        delegate?.guidanceReducer(self, didUpdateState: state)
    }
}
