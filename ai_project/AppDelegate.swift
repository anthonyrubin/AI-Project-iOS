//
//  AppDelegate.swift
//  ai_project
//
//  Created by Tony Rubin on 8/5/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let networkManager = NetworkManager(
        tokenManager: TokenManager(),
        userService: UserService()
    )

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Set up session expiration handler
        networkManager.onSessionExpired = { [weak self] in
            self?.handleSessionExpired()
        }
        
        return true
    }
    
    private func handleSessionExpired() {
        // Present login screen when session expires
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            // Create and present login view controller
            let loginVC = LoginViewController()
            let navController = UINavigationController(rootViewController: loginVC)
            navController.modalPresentationStyle = .fullScreen
            
            window.rootViewController?.present(navController, animated: true)
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

