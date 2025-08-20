import Foundation
import Combine

@MainActor
class SetBirthdayViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isBirthdaySet = false
    
    // MARK: - Dependencies
    private let signupRepository: SignupRepository
    
    // MARK: - Initialization
    init(signupRepository: SignupRepository) {
        self.signupRepository = signupRepository
    }
    
    // MARK: - Public Methods
    
    func setBirthday(birthday: Date) {
        isLoading = true
        errorMessage = nil
        isBirthdaySet = false
        
        signupRepository.setBirthday(
            birthday: birthday
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success():
                    // TODO: Do something with the response or get rid of this somehow
                    self?.isBirthdaySet = true
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
}

