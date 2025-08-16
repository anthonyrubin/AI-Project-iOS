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
    
    // MARK: - Initialization
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
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
                    // TODO: Do something with the response or get rid of this somehow
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

