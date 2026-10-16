import UIKit

@objc(WazeApp)
public final class WazeApp: UIApplication {
    // Reconstructed principal class matching @"WazeApp" from Mach-O entry point (0x1001fb7f8)
    public override init() {
        super.init()
    }
}

@main
public final class AppDelegate: UIResponder, UIApplicationDelegate {
    public var window: UIWindow?
    private var coordinator: AppLaunchCoordinator?

    public func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register core services in SRLRegistry
        SRLRegistry.shared.register(RoutingServiceProtocol.self, instance: LocalSimulatedRoutingService.shared)

        if #available(iOS 13.0, *) {
            // SceneDelegate handles window configuration
        } else {
            let win = UIWindow(frame: UIScreen.main.bounds)
            self.window = win
            let coord = AppLaunchCoordinator(window: win)
            self.coordinator = coord
            coord.start()
        }
        return true
    }

    // MARK: - UISceneSession Lifecycle
    public func application(_ application: UIApplication,
                            configurationForConnecting connectingSceneSession: UISceneSession,
                            options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
