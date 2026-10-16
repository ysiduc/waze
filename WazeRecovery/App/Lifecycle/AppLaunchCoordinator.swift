import UIKit

public final class AppLaunchCoordinator: WelcomeViewControllerDelegate {
    private let window: UIWindow

    public init(window: UIWindow) {
        self.window = window
    }

    public func start() {
        if UserPreferencesService.shared.hasCompletedOnboarding {
            showMainCanvas()
        } else {
            showWelcome()
        }
    }

    public func showWelcome() {
        let welcomeVC = WelcomeViewController()
        welcomeVC.delegate = self
        window.rootViewController = welcomeVC
        window.makeKeyAndVisible()
    }

    public func showMainCanvas() {
        let mainVC = MainCanvasContainerViewController()
        window.rootViewController = mainVC
        window.makeKeyAndVisible()
    }

    // MARK: - WelcomeViewControllerDelegate
    public func welcomeViewControllerDidCompleteOnboarding(_ vc: WelcomeViewController) {
        showMainCanvas()
    }
}
