import UIKit

extension Notification.Name {
    static let authDidSucceed = Notification.Name("authDidSucceed")
    static let didLogout      = Notification.Name("didLogout")
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: ws)
        self.window = window

        NotificationCenter.default.addObserver(self, selector: #selector(showMainApp), name: .authDidSucceed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showAuth),      name: .didLogout,      object: nil)

        configureAppearance()

//        if isLoggedIn() {
            setRoot(makeTabBar(), animated: false)
//        } else {
//            setRoot(makeAuthFlow(), animated: false)
//        }
    }

    // MARK: - Root swapping

    @objc private func showMainApp() {
        setRoot(makeTabBar(), animated: true)
    }

    @objc private func showAuth() {
        clearSessionState()
        setRoot(makeAuthFlow(), animated: true)
    }

    private func setRoot(_ vc: UIViewController, animated: Bool) {
        guard let window = window else { return }
        if animated {
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: { window.rootViewController = vc },
                              completion: { _ in window.makeKeyAndVisible() })
        } else {
            window.rootViewController = vc
            window.makeKeyAndVisible()
        }
    }

    // MARK: - Builders

    private func makeAuthFlow() -> UIViewController {
        let login = LoginViewController() // replace with your VC
        return UINavigationController(rootViewController: login)
    }

    private func makeTabBar() -> UITabBarController {
        let tab = UITabBarController()
        tab.viewControllers = [
            nav(LessonsViewController(), "LessonsTabIcon"),
            nav(SessionViewController(), "SessionTabIcon"),
            nav(ProfileViewController(), "ProfileTabIcon")
        ]
        return tab
    }

    private func nav(_ root: UIViewController, _ assetName: String) -> UINavigationController {
        root.tabBarItem = UITabBarItem(title: nil,
                                       image: UIImage(named: assetName),
                                       selectedImage: UIImage(named: assetName))
        return UINavigationController(rootViewController: root)
    }

    // MARK: - Appearance

    private func configureAppearance() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .systemBackground
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .systemBackground
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    // MARK: - Auth state

    private func isLoggedIn() -> Bool {
        UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    private func clearSessionState() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
    }
}

