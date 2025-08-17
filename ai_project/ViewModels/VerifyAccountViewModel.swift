import Foundation
import Combine

@MainActor
class VerifyAccountViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAccountVerified = false
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    
    // MARK: - Initialization
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    // MARK: - Public Methods
    
    func verifyAccount(email: String, code: String) {
        isLoading = true
        errorMessage = nil
        isAccountVerified = false
        
        networkManager.verifyAccount(
            email: email,
            code: code
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success():
                    self?.isAccountVerified = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    func resetVerificationState() {
        isAccountVerified = false
    }
}

