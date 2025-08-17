import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var email: String = ""
    @Published var shouldNavigateToName: Bool = false
    @Published var shouldNavigateToBirthday: Bool = false
    @Published var shouldNavigateToHome: Bool = false
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    
    // MARK: - Initialization
    init(
        networkManager: NetworkManager,
    ) {
        self.networkManager = networkManager
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
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleLoginResponse(_ response: LoginOrCheckpointResponse) {
        // Handle routing based on checkpoint
        switch response.checkpoint {
        case .verify_code:
            email = response.user.email
        case .name:
            shouldNavigateToName = true
        case .birthday:
            shouldNavigateToBirthday = true
        case .home:
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            shouldNavigateToHome = true
            NotificationCenter.default.post(name: .authDidSucceed, object: nil)
        }
    }
    
    // MARK: - Navigation Reset Methods
    
    func resetNavigationFlags() {
        email = ""
        shouldNavigateToName = false
        shouldNavigateToBirthday = false
        shouldNavigateToHome = false
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}
