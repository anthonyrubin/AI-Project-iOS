import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldNavigateToVerify: Bool = false
    @Published var shouldNavigateToName: Bool = false
    @Published var shouldNavigateToBirthday: Bool = false
    @Published var shouldNavigateToHome: Bool = false
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private let tokenManager: TokenManager
    private let userService: UserService
    
    // MARK: - Callbacks
    var onLoginSuccess: ((LoginOrCheckpointResponse) -> Void)?
    var onLoginFailure: ((String) -> Void)?
    
    // MARK: - Initialization
    init(networkManager: NetworkManager = .shared,
         tokenManager: TokenManager = .shared,
         userService: UserService = .shared) {
        self.networkManager = networkManager
        self.tokenManager = tokenManager
        self.userService = userService
    }

    func login(username: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        networkManager.loginOrCheckpoint(username: username, password: password) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.handleLoginResponse(response)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.onLoginFailure?(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleLoginResponse(_ response: LoginOrCheckpointResponse) {
        // Store tokens if available
        if let tokens = response.tokens {
            tokenManager.saveTokens(tokens)
        }
        
        // Store user if available
        if let user = response.user {
            UserDefaults.standard.set(user.id, forKey: "currentUserId")
            userService.storeUser(user)
        }
        
        // Handle routing based on checkpoint
        switch response.checkpoint {
        case .verify_code:
            shouldNavigateToVerify = true
        case .name:
            shouldNavigateToName = true
        case .birthday:
            shouldNavigateToBirthday = true
        case .home:
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            shouldNavigateToHome = true
            NotificationCenter.default.post(name: .authDidSucceed, object: nil)
        }
        
        // Call original callback for backward compatibility
        onLoginSuccess?(response)
    }
    
    // MARK: - Navigation Reset Methods
    
    func resetNavigationFlags() {
        shouldNavigateToVerify = false
        shouldNavigateToName = false
        shouldNavigateToBirthday = false
        shouldNavigateToHome = false
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}
