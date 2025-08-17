import Foundation
import Combine

@MainActor
class CreateAccountViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var modalError: String?
    @Published var fieldError: NetworkError?
    @Published var isAccountCreated = false
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    // MARK: - Public Methods
    
    func createAccount(username: String, email: String, password1: String, password2: String) {
        isLoading = true
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
                    if let fieldError = error as? NetworkError {
                        self?.fieldError = fieldError
                        self?.modalError = fieldError.localizedDescription
                    } else {
                        self?.modalError = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    func clearModalError() {
        modalError = nil
    }
    
    func clearFieldError() {
        fieldError = nil
    }
    
    func resetAccountCreated() {
        isAccountCreated = false
    }
}

