import Foundation
import Combine

@MainActor
class LiftingExperienceViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isExperienceSet = false
    
    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository
    
    // MARK: - Initialization
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    // MARK: - Public Methods
    
    func setExperience(experience: String) {
        isLoading = true
        errorMessage = nil
        isExperienceSet = false
        
        settingsRepository.setExperience(
            experience: experience
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success():
                    // TODO: Do something with the response or get rid of this somehow
                    self?.isExperienceSet = true
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

