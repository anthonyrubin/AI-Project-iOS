import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let authRepository: AuthRepository
    
    // MARK: - Initialization
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    // MARK: - Public Methods
    
    func logout() {
        isLoading = true
        errorMessage = nil
        
        authRepository.logout { [weak self] in
            Task { @MainActor in
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    func hasError() -> Bool {
        return errorMessage != nil
    }
}


