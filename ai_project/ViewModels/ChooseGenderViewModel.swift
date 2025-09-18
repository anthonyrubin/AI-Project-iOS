import Foundation
import Combine

@MainActor
class ChooseGenderViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGenderSet = false
    
    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository
    
    // MARK: - Initialization
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    // MARK: - Public Methods
    
    func setGender(gender: String) {
        isLoading = true
        errorMessage = nil
        isGenderSet = false
        
        settingsRepository.setGender(
            gender: gender
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success():
                    // TODO: Do something with the response or get rid of this somehow
                    self?.isGenderSet = true
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

