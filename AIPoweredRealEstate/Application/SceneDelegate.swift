//
//  SceneDelegate.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let launchColor = UIColor(red: 0.98, green: 0.976, blue: 0.965, alpha: 1)
        let window = UIWindow(windowScene: windowScene)
        window.frame = windowScene.coordinateSpace.bounds
        window.backgroundColor = launchColor
        window.tintColor = .darkThemeColor
        window.rootViewController = LaunchSplashViewController()
        window.makeKeyAndVisible()
        self.window = window

        let destination = makeRootViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let window = self?.window else { return }
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                window.rootViewController = destination
            }
        }
    }

    private func makeRootViewController() -> UIViewController {
        let token = KeyChainManager.shared.getValue(key: "token") ?? ""
        let role = KeyChainManager.shared.getValue(key: "UserRole") ?? ""

        if token != "" {
            if role == "buyer" {
                return UIStoryboard(name: "TenantSB", bundle: nil)
                    .instantiateViewController(withIdentifier: "TenantTabBarController")
            }
            return UIStoryboard(name: "AgentSB", bundle: nil)
                .instantiateViewController(withIdentifier: "AgentTabBarController")
        }

        let onboarding = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "OnboardingVC")
        let nav = UINavigationController(rootViewController: onboarding)
        nav.setNavigationBarHidden(true, animated: false)
        return nav
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

private final class LaunchSplashViewController: UIViewController {
    override func loadView() {
        let imageView = UIImageView(image: UIImage(named: "launchSpeedyPop"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor(red: 0.98, green: 0.976, blue: 0.965, alpha: 1)
        view = imageView
    }

    override var prefersStatusBarHidden: Bool { true }
}

