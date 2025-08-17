import Foundation
import Combine

@MainActor
class SetNameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isNameSet = false
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private var userService: UserService
    
    // MARK: - Initialization
    init(networkManager: NetworkManager, userService: UserService) {
        self.networkManager = networkManager
        self.userService = userService
    }
    
    // MARK: - Public Methods
    
    func setName(firstName: String, lastName: String) {
        isLoading = true
        errorMessage = nil
        isNameSet = false
        
        networkManager.setName(
            firstName: firstName,
            lastName: lastName
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.userService.updateUserName(
                        firstName: firstName,
                        lastName: lastName
                    )
                    self?.isNameSet = true
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
    
    func resetNameSet() {
        isNameSet = false
    }
}

