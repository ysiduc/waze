import Foundation

public protocol AlternateRoutesStateMachineBridgeProtocol: AnyObject {
    func stateMachine(_ bridge: AlternateRoutesStateMachineBridge, didUpdateCurrentRoute route: WZRoute)
    func stateMachine(_ bridge: AlternateRoutesStateMachineBridge, didSuggestReroute alternativeRoute: WZRoute, timeSavedSeconds: Double)
    func stateMachine(_ bridge: AlternateRoutesStateMachineBridge, didUpdateScheduleInterval seconds: TimeInterval)
}

/// Reconstructed from AlternateRoutesStateMachineBridge (0x107f17048) in Waze ARM64 executable.
/// Coordinates state transitions for primary route updates, alternative route suggestions, and poll schedules.
public final class AlternateRoutesStateMachineBridge {
    public weak var delegate: AlternateRoutesStateMachineBridgeProtocol?

    private(set) public var currentRoute: WZRoute?
    private(set) public var alternativeRoutes: [WZRoute] = []
    private(set) public var nextScheduleIntervalSeconds: TimeInterval = 30.0

    public init() {}

    /// Disassembled method ParseToRoutingUpdateResponse: (0x10001a718)
    /// Parses server routing payload branches and triggers state machine transitions.
    public func parseRoutingUpdateResponse(currentRouteUpdate: WZRoute?,
                                           rerouteSuggestion: WZRoute?,
                                           nextUpdateScheduleSeconds: TimeInterval?) {
        // 1. Process CurrentRouteUpdate branch (assertion: "Failed to parse CurrentRouteUpdate")
        if let current = currentRouteUpdate {
            self.currentRoute = current
            delegate?.stateMachine(self, didUpdateCurrentRoute: current)
        }

        // 2. Process RerouteSuggestion branch (assertion: "Failed to parse RerouteSuggestion")
        if let alternative = rerouteSuggestion, let current = currentRoute {
            let timeSaved = max(0.0, current.totalDurationSeconds - alternative.totalDurationSeconds)
            if timeSaved >= 60.0 { // Suggest only if saving >= 1 minute
                self.alternativeRoutes = [alternative]
                delegate?.stateMachine(self, didSuggestReroute: alternative, timeSavedSeconds: timeSaved)
            }
        }

        // 3. Process NextUpdateSchedule branch (assertion: "Failed to parse NextUpdateSchedule")
        if let schedule = nextUpdateScheduleSeconds {
            self.nextScheduleIntervalSeconds = max(5.0, schedule)
            delegate?.stateMachine(self, didUpdateScheduleInterval: self.nextScheduleIntervalSeconds)
        }
    }

    /// Selects an alternative route to become the active route.
    public func selectAlternativeRoute(at index: Int) -> WZRoute? {
        guard index >= 0 && index < alternativeRoutes.count else { return nil }
        let selected = alternativeRoutes[index]
        self.currentRoute = selected
        self.alternativeRoutes.remove(at: index)
        delegate?.stateMachine(self, didUpdateCurrentRoute: selected)
        return selected
    }
}
