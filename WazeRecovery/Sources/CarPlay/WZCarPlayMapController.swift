import Foundation
import UIKit

/// Reconstructed from WZCarPlayMapController (0x107f17e30) in Waze ARM64 executable.
/// Coordinates CarPlay navigation map templates, HUD banners, and dashboard scenes.
public final class WZCarPlayMapController: NSObject {
    public static let shared = WZCarPlayMapController()

    private(set) public var isCarPlayConnected: Bool = false
    private(set) public var activeNavigationSession: WZNavigationState?

    public override init() {
        super.init()
    }

    public func connectCarPlaySession() {
        self.isCarPlayConnected = true
    }

    public func disconnectCarPlaySession() {
        self.isCarPlayConnected = false
        self.activeNavigationSession = nil
    }

    public func updateGuidanceState(_ state: WZNavigationState) {
        self.activeNavigationSession = state
    }
}
