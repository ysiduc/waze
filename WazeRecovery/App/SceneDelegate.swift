import UIKit

public final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?
    private var coordinator: AppLaunchCoordinator?

    public func scene(_ scene: UIScene,
                      willConnectTo session: UISceneSession,
                      options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let win = UIWindow(windowScene: windowScene)
        self.window = win

        let coord = AppLaunchCoordinator(window: win)
        self.coordinator = coord
        coord.start()
    }

    public func sceneDidDisconnect(_ scene: UIScene) {}
    public func sceneDidBecomeActive(_ scene: UIScene) {}
    public func sceneWillResignActive(_ scene: UIScene) {}
    public func sceneWillEnterForeground(_ scene: UIScene) {}
    public func sceneDidEnterBackground(_ scene: UIScene) {}
}
