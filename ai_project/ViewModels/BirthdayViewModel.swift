import Foundation
import Combine

@MainActor
class BirthdayViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isBirthdaySet = false
    
    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository
    
    // MARK: - Initialization
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    // MARK: - Public Methods
    
    func setBirthday(birthday: Date) {
        isLoading = true
        errorMessage = nil
        isBirthdaySet = false
        
        settingsRepository.setBirthday(
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

