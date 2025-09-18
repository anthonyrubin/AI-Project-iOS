import Foundation
import Combine

@MainActor
class HeightAndWeightViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isHeightAndWeightSet = false
    
    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository
    
    // MARK: - Initialization
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    // MARK: - Public Methods
    
    func setBodyMetrics(height: Double, weight: Double, isMetric: Bool) {
        isLoading = true
        errorMessage = nil
        isHeightAndWeightSet = false
        
        settingsRepository.setBodyMetrics(
            height: height,
            weight: weight,
            isMetric: isMetric
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success():
                    // TODO: Do isHeightAndWeightSet with the response or get rid of this somehow
                    self?.isHeightAndWeightSet = true
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

