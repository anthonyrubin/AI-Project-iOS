import Foundation
import Combine

@MainActor
class CreateAccountViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var modalError: String?
    @Published var networkError: NetworkError?
    @Published var isAccountCreated = false
    
    // MARK: - Dependencies
    private let signupRepository: SignupRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(signupRepository: SignupRepository) {
        self.signupRepository = signupRepository
    }
    
    // MARK: - Public Methods
    
    func createAccount(username: String, email: String, password1: String, password2: String) {
        isLoading = true
        isAccountCreated = false
        
        signupRepository.createAccount(
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
                    if case .apiError(_) = error {
                        self?.networkError = error
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
        networkError = nil
    }
    
    func resetAccountCreated() {
        isAccountCreated = false
    }
}

