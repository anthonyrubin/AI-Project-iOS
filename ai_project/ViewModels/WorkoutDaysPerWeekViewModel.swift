import Foundation
import Combine

@MainActor
class WorkoutDaysPerWeekViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isWorkoutDaysPerWeekSet = false
    
    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository
    
    // MARK: - Initialization
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    // MARK: - Public Methods
    
    func setWorkoutDaysPerWeek(workoutDaysPerWeek: String) {
        isLoading = true
        errorMessage = nil
        isWorkoutDaysPerWeekSet = false
        
        settingsRepository.setWorkoutDaysPerWeek(
            workoutDaysPerWeek: workoutDaysPerWeek
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success():
                    // TODO: Do something with the response or get rid of this somehow
                    self?.isWorkoutDaysPerWeekSet = true
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

