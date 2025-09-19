import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }
        _ = try? RealmProvider.make()

        let window = UIWindow(windowScene: ws)
        self.window = window

        NotificationCenter.default.addObserver(self, selector: #selector(showMainApp), name: .authDidSucceed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showAuth),      name: .didLogout,      object: nil)

        configureNavigationAppearance()

        if isLoggedIn() {
            setRoot(TabBarController(), animated: false)
        } else {
            setRoot(makeAuthFlow(), animated: false)
        }
    }

    // MARK: - Root swapping
    @objc private func showMainApp() { setRoot(TabBarController(), animated: true) }
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
        let login = LoginViewController()
        let nav = UINavigationController(rootViewController: login)
        nav.installLanguagePillForSignupFlow(code: "EN") { newCode in
            // optional: update app language store
        }
        return nav
    }

    // MARK: - Appearance (only NavBar here)
    private func configureNavigationAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = .systemBackground

        let navProxy = UINavigationBar.appearance()
        navProxy.standardAppearance = nav
        navProxy.scrollEdgeAppearance = nav
    }

    // MARK: - Auth state
    private func isLoggedIn() -> Bool {
        UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    private func clearSessionState() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
    }
}
