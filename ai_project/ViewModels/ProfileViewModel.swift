import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private let tokenManager: TokenManager
    private let userService: UserService
    
    // MARK: - Initialization
    init(networkManager: NetworkManager = .shared,
         tokenManager: TokenManager = .shared,
         userService: UserService = .shared) {
        self.networkManager = networkManager
        self.tokenManager = tokenManager
        self.userService = userService
    }
    
    // MARK: - Public Methods
    
    func logout() {
        isLoading = true
        errorMessage = nil
        
        networkManager.logout { [weak self] in
            Task { @MainActor in
                self?.performLocalLogout()
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performLocalLogout() {
        // Clear tokens
        tokenManager.clearTokens()
        
        // Clear user defaults
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        
        // Clear Realm cache
        userService.clearAllData()
        
        // Post notification for app to handle
        NotificationCenter.default.post(name: .didLogout, object: nil)
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    func hasError() -> Bool {
        return errorMessage != nil
    }
}
