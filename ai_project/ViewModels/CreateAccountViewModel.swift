import Foundation
import Combine

@MainActor
class CreateAccountViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAccountCreated = false
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
    }
    
    // MARK: - Public Methods
    
    func createAccount(username: String, email: String, password1: String, password2: String) {
        isLoading = true
        errorMessage = nil
        isAccountCreated = false
        
        networkManager.createAccount(
            username: username,
            email: email,
            password1: password1,
            password2: password2
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success():
                    self?.isAccountCreated = true
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
    
    func resetAccountCreated() {
        isAccountCreated = false
    }
}

