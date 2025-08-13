import Foundation
import UIKit

class AuthenticationManager {
    static let shared = AuthenticationManager()
    private init() {}
    
    // MARK: - Session Management
    var onSessionExpired: (() -> Void)?
    
    func handleSessionExpired() {
        // Clear all stored data
        TokenManager.shared.clearTokens()
        UserDefaults.standard.removeObject(forKey: "currentUser")
        
        // Notify app that session has expired
        DispatchQueue.main.async {
            self.onSessionExpired?()
        }
    }
    
    func logout() {
        // Clear tokens and user data
        TokenManager.shared.clearTokens()
        UserDefaults.standard.removeObject(forKey: "currentUser")
        
        // Call logout endpoint (best effort)
        NetworkManager.shared.logout {
            // Logout completed, regardless of network success
        }
    }
}
